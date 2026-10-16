//! Fennek OS download guard: scans new files in Downloads with ClamAV; threats are moved to quarantine and
//! you're notified. The virus database is loaded only when a file arrives (no resident 1 GB scanner daemon:
//! battery friendly).
//!
//!   fennek-download-guard            watch Downloads (systemd user service)
//!   fennek-download-guard FILE...    scan these files once
//!   fennek-download-guard --selftest

use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};
use std::{env, fs};

fn home() -> PathBuf {
    PathBuf::from(env::var("HOME").unwrap_or_else(|_| "/".into()))
}

fn quarantine_dir() -> PathBuf {
    let data = env::var("XDG_DATA_HOME").map(PathBuf::from).unwrap_or_else(|_| home().join(".local/share"));
    data.join("fennek/quarantine")
}

fn virus_db() -> PathBuf {
    PathBuf::from(env::var("FENNEK_CLAM_DB").unwrap_or_else(|_| "/var/lib/clamav".into()))
}

/// The user's Downloads folder, in their language. At the first login this may run before the user's
/// folders exist: create them first, so we never make an extra English "Downloads" next to "Завантажене".
fn downloads() -> PathBuf {
    let config = env::var("XDG_CONFIG_HOME").map(PathBuf::from).unwrap_or_else(|_| home().join(".config"));
    if !config.join("user-dirs.dirs").exists() {
        let _ = Command::new("xdg-user-dirs-update").status();
    }
    let out = Command::new("xdg-user-dir").arg("DOWNLOAD").output().ok();
    let dir = out.map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string()).unwrap_or_default();
    // Without a user-dirs config, xdg-user-dir answers $HOME itself: never watch the whole home.
    if dir.is_empty() || Path::new(&dir) == home() {
        home().join("Downloads")
    } else {
        PathBuf::from(dir)
    }
}

/// Still being downloaded by a browser: wait for the final name.
/// Works on raw bytes: a file name that isn't valid UTF-8 must still be scanned.
fn incomplete(name: &[u8]) -> bool {
    [b".part".as_slice(), b".crdownload", b".download", b".tmp"].iter().any(|s| name.ends_with(s))
}

fn have_definitions(db: &Path) -> bool {
    fs::read_dir(db)
        .map(|it| it.flatten().any(|e| matches!(e.path().extension().and_then(|x| x.to_str()), Some("cvd" | "cld" | "hdb"))))
        .unwrap_or(false)
}

/// "…/file.exe: Win.Test.EICAR_HDB-1 FOUND" -> "Win.Test.EICAR_HDB-1"
fn threat_name(clamscan_out: &str) -> String {
    let line = clamscan_out.lines().find(|l| l.ends_with(" FOUND")).unwrap_or("");
    line.rsplit_once(": ").map(|(_, t)| t.trim_end_matches(" FOUND").to_string()).unwrap_or_else(|| "unknown".into())
}

/// Seconds since 1970 -> "YYYYMMDD-HHMMSS" (UTC; only orders the quarantine list).
fn stamp(secs: u64) -> String {
    let (days, rem) = (secs / 86400, secs % 86400);
    // Civil date from days since 1970 (Howard Hinnant's algorithm).
    let z = days as i64 + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = yoe + era * 400 + if m <= 2 { 1 } else { 0 };
    format!("{y:04}{m:02}{d:02}-{:02}{:02}{:02}", rem / 3600, rem % 3600 / 60, rem % 60)
}

/// Move a threat into quarantine (unreadable), with why and from where for fennek-quarantine
/// (NUL-separated: paths may contain newlines). Returns the quarantined path.
fn quarantine(file: &Path, threat: &str, quar: &Path, now: u64) -> std::io::Result<PathBuf> {
    use std::os::unix::ffi::OsStrExt;
    use std::os::unix::fs::PermissionsExt;
    fs::create_dir_all(quar)?;
    fs::set_permissions(quar, fs::Permissions::from_mode(0o700))?;
    let name = file.file_name().map(|n| n.to_owned()).unwrap_or_default();
    let mut dest_name = std::ffi::OsString::from(format!("{}-", stamp(now)));
    dest_name.push(&name);
    let dest = quar.join(dest_name);
    // Downloads may live on another drive than the quarantine (rename can't cross file systems): copy,
    // lock the copy, then delete the original. If even that fails, lock the file where it is.
    if fs::rename(file, &dest).is_err() {
        let moved = fs::copy(file, &dest).and_then(|_| fs::File::open(&dest)?.sync_all()).and_then(|_| fs::remove_file(file));
        if let Err(e) = moved {
            let _ = fs::remove_file(&dest);
            fs::set_permissions(file, fs::Permissions::from_mode(0o000))?;
            return Err(e);
        }
    }
    fs::set_permissions(&dest, fs::Permissions::from_mode(0o000))?;
    let mut info = threat.as_bytes().to_vec();
    info.push(0);
    info.extend_from_slice(file.as_os_str().as_bytes());
    info.push(0);
    let mut info_path = dest.clone().into_os_string();
    info_path.push(".fennek-info");
    fs::write(info_path, info)?;
    Ok(dest)
}

fn scan(file: &Path) {
    use std::os::unix::ffi::OsStrExt;
    let Some(raw) = file.file_name() else { return };
    let name = raw.to_string_lossy().into_owned(); // display only
    let db = virus_db();
    if !file.is_file() || incomplete(raw.as_bytes()) || !have_definitions(&db) {
        return;
    }
    let Ok(out) = Command::new("clamscan").args(["--no-summary", "--infected", "-d"]).arg(&db).arg("--").arg(file).output() else { return };
    if out.status.code() != Some(1) {
        return; // 0 = clean, 2 = scan error
    }
    let threat = threat_name(&String::from_utf8_lossy(&out.stdout));
    let now = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0);
    let text = match quarantine(file, &threat, &quarantine_dir(), now) {
        Ok(_) => format!("{name} contains {threat}. It was moved to quarantine."),
        Err(_) => format!("{name} contains {threat}. It couldn't be moved to quarantine, so it was locked where it is. Delete it."),
    };
    let _ = Command::new("notify-send").args(["-u", "critical", "-a", "Fennek OS Security", "Threat blocked"]).arg(&text).status();
    println!("{text}");
}

#[cfg(target_os = "linux")]
fn watch(dir: &Path) -> std::io::Result<()> {
    use inotify::{Inotify, WatchMask};
    fs::create_dir_all(dir)?;
    let mut inotify = Inotify::init()?;
    inotify.watches().add(dir, WatchMask::CLOSE_WRITE | WatchMask::MOVED_TO)?;
    let mut buf = [0u8; 16 * 1024];
    loop {
        for e in inotify.read_events_blocking(&mut buf)? {
            if let Some(name) = e.name {
                scan(&dir.join(name));
            }
        }
    }
}

fn selftest() {
    assert_eq!(threat_name("/home/u/Downloads/x.exe: Win.Test.EICAR_HDB-1 FOUND\n"), "Win.Test.EICAR_HDB-1");
    assert_eq!(threat_name("/a: b/c.zip: Eicar-Signature FOUND"), "Eicar-Signature", "colons in the path");
    assert!(incomplete(b"setup.exe.part") && incomplete(b"a.crdownload") && !incomplete(b"setup.exe"));
    assert!(!incomplete(b"\xff\xfeevil.exe"), "names that aren't UTF-8 are scanned too");
    assert_eq!(stamp(0), "19700101-000000");
    assert_eq!(stamp(1_792_156_000), "20261016-130640");
    assert_eq!(stamp(951_782_400), "20000229-000000", "leap day");
    let t = env::temp_dir().join(format!("fennek-guard-test-{}", std::process::id()));
    let (dl, quar) = (t.join("Downloads"), t.join("q"));
    fs::create_dir_all(&dl).unwrap();
    let f = dl.join("evil file.exe");
    fs::write(&f, "x").unwrap();
    let q = quarantine(&f, "Win.Test", &quar, 0).unwrap();
    assert!(!f.exists() && q.ends_with("19700101-000000-evil file.exe"));
    {
        use std::os::unix::fs::PermissionsExt;
        assert_eq!(fs::metadata(&q).unwrap().permissions().mode() & 0o777, 0, "unreadable in quarantine");
    }
    let info = fs::read(quar.join("19700101-000000-evil file.exe.fennek-info")).unwrap();
    assert_eq!(info, [b"Win.Test\0".as_slice(), f.as_os_str().as_encoded_bytes(), b"\0"].concat());
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = fs::set_permissions(&q, fs::Permissions::from_mode(0o600));
    }
    let _ = fs::remove_dir_all(&t);
    println!("selftest ok");
}

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    if args == ["--selftest"] {
        return selftest();
    }
    if !args.is_empty() {
        for f in &args {
            scan(Path::new(f));
        }
        return;
    }
    #[cfg(target_os = "linux")]
    if let Err(e) = watch(&downloads()) {
        eprintln!("fennek-download-guard: {e}");
        std::process::exit(1);
    }
}
