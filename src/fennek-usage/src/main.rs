//! Fennek OS usage history: which apps used the CPU (and so the battery) and how much memory, per minute,
//! kept for 7 days. Reads the per-app numbers Linux already keeps (each app runs in its own cgroup), so
//! sampling once a minute costs next to nothing. No network, nothing leaves the computer.
//!
//!   fennek-usage --record          sample every minute (systemd user service)
//!   fennek-usage [HOURS]           top apps over the last HOURS (default 8)
//!   fennek-usage --json HOURS      the same as JSON (for the App history window)
//!   fennek-usage --selftest

use std::collections::HashMap;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime, UNIX_EPOCH};
use std::{env, fs};

const KEEP_SECS: u64 = 7 * 86400;

fn state_file() -> PathBuf {
    let home = env::var("HOME").unwrap_or_else(|_| "/".into());
    let state = env::var("XDG_STATE_HOME").map(PathBuf::from).unwrap_or_else(|_| PathBuf::from(home).join(".local/state"));
    state.join("fennek/usage.tsv")
}

fn now() -> u64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0)
}

/// systemd unit name of an app -> readable app name.
/// "app-org.kde.dolphin-4711.scope" -> "org.kde.dolphin"; "app-flatpak-org.mozilla.firefox-12.scope" ->
/// "org.mozilla.firefox"; "app-firefox@3f2a.service" -> "firefox"; "\x2d" escapes -> "-".
fn app_name(unit: &str) -> Option<String> {
    let u = unit.strip_prefix("app-")?;
    let u = u.strip_suffix(".scope").or_else(|| u.strip_suffix(".service"))?;
    let u = u.split('@').next().unwrap_or(u);
    // drop a trailing "-<number>" (instance id)
    let u = match u.rsplit_once('-') {
        Some((head, tail)) if !tail.is_empty() && tail.chars().all(|c| c.is_ascii_digit()) => head,
        _ => u,
    };
    let u = u.strip_prefix("flatpak-").unwrap_or(u);
    let name = u.replace("\\x2d", "-");
    (!name.is_empty()).then_some(name)
}

/// Every app cgroup under the user's app.slice: (app name, cpu µs total, memory bytes).
fn sample(app_slice: &Path) -> Vec<(String, u64, u64)> {
    let mut out = vec![];
    let Ok(entries) = fs::read_dir(app_slice) else { return out };
    for e in entries.flatten() {
        let unit = e.file_name().to_string_lossy().into_owned();
        let Some(name) = app_name(&unit) else { continue };
        let cpu = fs::read_to_string(e.path().join("cpu.stat"))
            .ok()
            .and_then(|s| s.lines().find_map(|l| l.strip_prefix("usage_usec ").map(|v| v.trim().parse().unwrap_or(0))))
            .unwrap_or(0);
        let mem = fs::read_to_string(e.path().join("memory.current")).ok().and_then(|s| s.trim().parse().ok()).unwrap_or(0);
        out.push((name, cpu, mem));
    }
    out
}

fn app_slice() -> PathBuf {
    let uid = fs::read_to_string("/proc/self/status")
        .ok()
        .and_then(|s| s.lines().find_map(|l| l.strip_prefix("Uid:").and_then(|v| v.split_whitespace().next().map(String::from))))
        .unwrap_or_else(|| "1000".into());
    PathBuf::from(format!("/sys/fs/cgroup/user.slice/user-{uid}.slice/user@{uid}.service/app.slice"))
}

/// Keep only lines newer than `since` (written to a new file, then renamed).
fn prune(file: &Path, since: u64) {
    let Ok(text) = fs::read_to_string(file) else { return };
    let kept: String = text
        .lines()
        .filter(|l| l.split('\t').next().and_then(|t| t.parse::<u64>().ok()).is_some_and(|t| t >= since))
        .map(|l| format!("{l}\n"))
        .collect();
    let tmp = file.with_extension("tsv.new");
    if fs::write(&tmp, kept).is_ok() {
        let _ = fs::rename(&tmp, file);
    }
}

fn record() -> ! {
    let file = state_file();
    if let Some(dir) = file.parent() {
        let _ = fs::create_dir_all(dir);
    }
    prune(&file, now().saturating_sub(KEEP_SECS));
    let slice = app_slice();
    let mut last: HashMap<String, u64> = HashMap::new();
    let mut ticks = 0u64;
    loop {
        let t = now();
        let mut lines = String::new();
        // Several windows of one app = several cgroups: add them up.
        let mut seen: HashMap<String, (u64, u64)> = HashMap::new();
        for (name, cpu, mem) in sample(&slice) {
            let e = seen.entry(name).or_insert((0, 0));
            e.0 += cpu;
            e.1 += mem;
        }
        for (name, (cpu, mem)) in &seen {
            let delta = cpu.saturating_sub(*last.get(name).unwrap_or(cpu));
            if delta > 0 {
                lines.push_str(&format!("{t}\t{name}\t{}\t{mem}\n", delta / 1000));
            }
        }
        last = seen.into_iter().map(|(n, (c, _))| (n, c)).collect();
        if !lines.is_empty() {
            if let Ok(mut f) = fs::OpenOptions::new().create(true).append(true).open(&file) {
                let _ = f.write_all(lines.as_bytes());
            }
        }
        ticks += 1;
        if ticks % 1440 == 0 {
            prune(&file, now().saturating_sub(KEEP_SECS)); // once a day
        }
        std::thread::sleep(Duration::from_secs(60));
    }
}

/// Lines "ts \t app \t cpu_ms \t mem" since `since` -> [(app, cpu_ms, peak mem)], most CPU first.
fn top(text: &str, since: u64) -> Vec<(String, u64, u64)> {
    let mut by: HashMap<String, (u64, u64)> = HashMap::new();
    for l in text.lines() {
        let f: Vec<&str> = l.split('\t').collect();
        if f.len() != 4 {
            continue;
        }
        let (Ok(t), Ok(cpu), Ok(mem)) = (f[0].parse::<u64>(), f[2].parse::<u64>(), f[3].parse::<u64>()) else { continue };
        if t < since {
            continue;
        }
        let e = by.entry(f[1].to_string()).or_insert((0, 0));
        e.0 += cpu;
        e.1 = e.1.max(mem);
    }
    let mut v: Vec<_> = by.into_iter().map(|(n, (c, m))| (n, c, m)).collect();
    v.sort_by(|a, b| b.1.cmp(&a.1).then(a.0.cmp(&b.0)));
    v
}

fn report(hours: u64) {
    let text = fs::read_to_string(state_file()).unwrap_or_default();
    let rows = top(&text, now().saturating_sub(hours * 3600));
    if rows.is_empty() {
        println!("No usage recorded in the last {hours} h yet.");
        return;
    }
    let total: u64 = rows.iter().map(|r| r.1).sum::<u64>().max(1);
    println!("{:<36} {:>9} {:>6} {:>10}", format!("Last {hours} h"), "CPU time", "share", "peak RAM");
    for (name, cpu, mem) in rows.iter().take(15) {
        println!("{:<36} {:>8}s {:>5}% {:>8} MB", name, cpu / 1000, cpu * 100 / total, mem / 1_048_576);
    }
}

/// [{"app": .., "cpu_ms": .., "mem": ..}, ...] (app names are cgroup unit names: no quotes or backslashes
/// survive app_name(), but escape them anyway).
fn json(rows: &[(String, u64, u64)]) -> String {
    let esc = |s: &str| s.replace('\\', "\\\\").replace('"', "\\\"");
    let items: Vec<String> = rows.iter().map(|(n, c, m)| format!("{{\"app\":\"{}\",\"cpu_ms\":{c},\"mem\":{m}}}", esc(n))).collect();
    format!("[{}]", items.join(","))
}

fn selftest() {
    assert_eq!(app_name("app-org.kde.dolphin-4711.scope").as_deref(), Some("org.kde.dolphin"));
    assert_eq!(app_name("app-flatpak-org.mozilla.firefox-12.scope").as_deref(), Some("org.mozilla.firefox"));
    assert_eq!(app_name("app-firefox@3f2a.service").as_deref(), Some("firefox"));
    assert_eq!(app_name("app-kde\\x2dconnect-3.scope").as_deref(), Some("kde-connect"));
    assert_eq!(app_name("app-org.kde.konsole-2.0.scope").as_deref(), Some("org.kde.konsole-2.0"), "only a numeric suffix is an id");
    assert_eq!(app_name("session-2.scope"), None);
    let text = "100\tfirefox\t5000\t300000000\n200\tfirefox\t3000\t400000000\n150\tdolphin\t1000\t50000000\nbad line\n50\told\t9999\t1\n";
    assert_eq!(top(text, 100), vec![("firefox".into(), 8000, 400000000), ("dolphin".into(), 1000, 50000000)]);
    assert_eq!(json(&[("a\"b".into(), 5, 6)]), "[{\"app\":\"a\\\"b\",\"cpu_ms\":5,\"mem\":6}]");
    let dir = env::temp_dir().join(format!("fennek-usage-test-{}", std::process::id()));
    fs::create_dir_all(&dir).unwrap();
    let f = dir.join("usage.tsv");
    fs::write(&f, text).unwrap();
    prune(&f, 150);
    assert_eq!(fs::read_to_string(&f).unwrap(), "200\tfirefox\t3000\t400000000\n150\tdolphin\t1000\t50000000\n");
    let _ = fs::remove_dir_all(&dir);
    println!("selftest ok");
}

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    match args.first().map(String::as_str) {
        Some("--selftest") => selftest(),
        Some("--record") => record(),
        Some("--json") => {
            let hours: u64 = args.get(1).and_then(|h| h.parse().ok()).unwrap_or(8);
            let text = fs::read_to_string(state_file()).unwrap_or_default();
            println!("{}", json(&top(&text, now().saturating_sub(hours * 3600))));
        }
        Some(h) => report(h.parse().unwrap_or(8)),
        None => report(8),
    }
}
