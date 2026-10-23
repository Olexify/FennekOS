//! Fennek OS instant file search, one per user.
//!
//! Keeps every file name under your home and plugged-in drives in memory, kept live with inotify: no
//! rescans, no CPU while idle. Answers the Start menu / search panel / KRunner over D-Bus (org.kde.krunner1).
//! Never sees other users' files: it runs as you and only indexes what you can read.
//!
//! Query: words must all appear in the file name (any order, case-insensitive). Filters:
//!   ext:pdf;docx   type:image|video|audio|doc|archive|exe|folder   path:projects
//!   size:>10mb  size:<500kb   dm:today|week|month|year (changed in the last 24 h / 7 / 30 / 365 days)
//! History: files you open from search rank higher (~/.local/share/fennek/search-history, delete to clear).
//!
//!   fennek-search             run the service
//!   fennek-search QUERY...    one-off search from a terminal (scans, prints, exits)
//!   fennek-search --selftest

use std::collections::{BTreeSet, HashMap};
use std::path::Path;
use std::sync::{Arc, Mutex};
use std::{env, fs};

const MAX_RESULTS: usize = 20;
/// The search window (fennek-app search) lists more than Start does.
const MAX_ALL: usize = 500;

mod settings;

fn types(kind: &str) -> Option<&'static [&'static str]> {
    Some(match kind {
        "image" => &["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "heic", "tif", "tiff", "raw", "avif"],
        "video" => &["mp4", "mkv", "webm", "avi", "mov", "wmv", "flv", "m4v"],
        "audio" => &["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac", "wma"],
        "doc" => &["pdf", "doc", "docx", "odt", "txt", "md", "rtf", "xls", "xlsx", "ods", "ppt", "pptx", "odp", "csv"],
        "archive" => &["zip", "7z", "rar", "tar", "gz", "xz", "zst", "bz2", "iso"],
        "exe" => &["exe", "msi", "appimage", "sh", "bat"],
        _ => return None,
    })
}

fn home() -> String {
    env::var("HOME").unwrap_or_else(|_| "/".into())
}

fn data_dir() -> String {
    env::var("XDG_DATA_HOME").unwrap_or_else(|_| format!("{}/.local/share", home()))
}

fn history_file() -> String {
    format!("{}/fennek/search-history", data_dir())
}

/// Folders never indexed: caches, trash, sandboxes, game prefixes.
fn skip_dirs() -> Vec<String> {
    let (h, d) = (home(), data_dir());
    let mut v: Vec<String> = ["Trash", "fennek/sandboxes", "umu", "Steam", "flatpak"].iter().map(|s| format!("{d}/{s}")).collect();
    v.extend([".cache", ".var", ".local/share/Trash"].iter().map(|s| format!("{h}/{s}")));
    v
}

/// All indexed paths, sorted: deleting a folder removes its whole subtree with one range scan.
pub struct Index {
    pub paths: BTreeSet<String>,
    skip: Vec<String>,
    #[cfg(target_os = "linux")]
    watch: Option<watch::Watcher>,
}

impl Index {
    pub fn new(skip: Vec<String>, live: bool) -> Self {
        #[cfg(not(target_os = "linux"))]
        let _ = live;
        Index {
            paths: BTreeSet::new(),
            skip,
            #[cfg(target_os = "linux")]
            watch: if live { watch::Watcher::new().ok() } else { None },
        }
    }

    pub fn scan(&mut self, top: &str) {
        let mut stack = vec![top.to_string()];
        while let Some(dir) = stack.pop() {
            if self.skip.iter().any(|s| *s == dir) || !self.watch_dir(&dir) {
                continue;
            }
            let Ok(entries) = fs::read_dir(&dir) else { continue };
            for e in entries.flatten() {
                let name = e.file_name();
                let Some(name) = name.to_str() else { continue };
                if name.starts_with('.') {
                    continue; // hidden: config clutter, not what people search
                }
                let path = format!("{dir}/{name}");
                if e.file_type().map(|t| t.is_dir()).unwrap_or(false) {
                    stack.push(path.clone());
                }
                self.paths.insert(path);
            }
        }
    }

    fn watch_dir(&mut self, _dir: &str) -> bool {
        #[cfg(target_os = "linux")]
        if let Some(w) = self.watch.as_mut() {
            return w.add(_dir);
        }
        true
    }

    pub fn rebuild(&mut self, roots: &[String]) {
        self.paths.clear();
        #[cfg(target_os = "linux")]
        if let Some(w) = self.watch.as_mut() {
            w.clear();
        }
        for r in roots {
            if Path::new(r).is_dir() {
                self.scan(r);
            }
        }
    }

    pub fn drop_tree(&mut self, path: &str) {
        self.paths.remove(path);
        let prefix = format!("{path}/");
        let doomed: Vec<String> = self.paths.range(prefix.clone()..).take_while(|p| p.starts_with(&prefix)).cloned().collect();
        for p in doomed {
            self.paths.remove(&p);
        }
        #[cfg(target_os = "linux")]
        if let Some(w) = self.watch.as_mut() {
            w.forget_tree(path);
        }
    }
}

struct Query {
    words: Vec<String>,
    exts: Option<Vec<String>>,
    folders: bool,
    paths: Vec<String>,
    size: Option<(bool, u64)>, // (larger than?, bytes)
    age: Option<u64>,          // changed within this many seconds
}

/// ">10mb" / "<500kb" / "2g" -> (larger than?, bytes).
fn parse_size(v: &str) -> Option<(bool, u64)> {
    let (larger, rest) = match v.as_bytes().first()? {
        b'<' => (false, &v[1..]),
        b'>' => (true, &v[1..]),
        _ => (true, v),
    };
    let i = rest.find(|c: char| !c.is_ascii_digit() && c != '.').unwrap_or(rest.len());
    let n: f64 = rest[..i].parse().ok()?;
    let unit: u64 = match &rest[i..] {
        "" | "b" => 1,
        "k" | "kb" => 1 << 10,
        "m" | "mb" => 1 << 20,
        "g" | "gb" => 1 << 30,
        _ => return None,
    };
    Some((larger, (n * unit as f64) as u64))
}

// ponytail: rolling windows (today = last 24 h), not calendar days; calendar days need local-time rules.
fn parse_age(v: &str) -> Option<u64> {
    Some(86_400 * match v {
        "today" => 1,
        "week" => 7,
        "month" => 30,
        "year" => 365,
        _ => return None,
    })
}

/// "report ext:pdf;docx type:doc path:work" -> words, extensions, folders only, path words.
fn parse(query: &str) -> Query {
    let mut q = Query { words: vec![], exts: None, folders: false, paths: vec![], size: None, age: None };
    for tok in query.to_lowercase().split_whitespace() {
        let (key, val) = tok.split_once(':').unwrap_or((tok, ""));
        match (key, val) {
            ("ext", v) if !v.is_empty() => {
                q.exts.get_or_insert_with(Vec::new).extend(v.split(';').filter(|e| !e.is_empty()).map(|e| e.trim_start_matches('.').to_string()))
            }
            ("type", "folder") => q.folders = true,
            ("type", v) if types(v).is_some() => q.exts.get_or_insert_with(Vec::new).extend(types(v).unwrap().iter().map(|s| s.to_string())),
            ("path", v) if !v.is_empty() => q.paths.push(v.to_string()),
            ("size", v) if parse_size(v).is_some() => q.size = parse_size(v),
            ("dm", v) if parse_age(v).is_some() => q.age = parse_age(v),
            _ => q.words.push(tok.to_string()),
        }
    }
    q
}

pub fn search<'a>(paths: impl Iterator<Item = &'a String>, query: &str, history: &[String], limit: usize) -> Vec<String> {
    let q = parse(query);
    if q.words.is_empty() && q.exts.is_none() && !q.folders && q.paths.is_empty() && q.size.is_none() && q.age.is_none() {
        return vec![];
    }
    let recent: HashMap<&str, usize> = history.iter().rev().enumerate().map(|(i, p)| (p.as_str(), i)).collect();
    let joined = q.words.join(" ");
    let mut hits: Vec<((u8, usize, u8, usize, usize), &String)> = vec![];
    for p in paths {
        let name = p.rsplit('/').next().unwrap_or(p).to_lowercase();
        if !q.words.iter().all(|w| name.contains(w.as_str())) {
            continue;
        }
        if let Some(exts) = &q.exts {
            let ext = name.rsplit_once('.').map(|(_, e)| e).unwrap_or("");
            if !exts.iter().any(|e| e == ext) {
                continue;
            }
        }
        if !q.paths.is_empty() {
            let lower = p.to_lowercase();
            if !q.paths.iter().all(|w| lower.contains(w.as_str())) {
                continue;
            }
        }
        if q.folders && !Path::new(p).is_dir() {
            continue;
        }
        if q.size.is_some() || q.age.is_some() {
            // Only files that passed the name filters get a stat() call.
            let Ok(md) = fs::metadata(p) else { continue };
            if let Some((larger, n)) = q.size {
                if md.is_dir() || (larger && md.len() <= n) || (!larger && md.len() >= n) {
                    continue;
                }
            }
            if let Some(max) = q.age {
                if !md.modified().ok().and_then(|m| m.elapsed().ok()).is_some_and(|e| e.as_secs() <= max) {
                    continue;
                }
            }
        }
        let stem = name.rsplit_once('.').map(|(s, _)| s).unwrap_or(&name);
        let closeness = if stem == joined { 0 } else if name.starts_with(&joined) { 1 } else { 2 };
        let (seen, when) = recent.get(p.as_str()).map(|i| (0, *i)).unwrap_or((1, 0));
        hits.push(((seen, when, closeness, p.matches('/').count(), name.len()), p));
    }
    hits.sort();
    hits.into_iter().take(limit).map(|(_, p)| p.clone()).collect()
}

fn load_history() -> Vec<String> {
    let all: Vec<String> = fs::read_to_string(history_file()).unwrap_or_default().lines().filter(|l| !l.is_empty()).map(String::from).collect();
    let skip = all.len().saturating_sub(200);
    all.into_iter().skip(skip).collect()
}

fn remember(path: &str) {
    let mut h: Vec<String> = load_history().into_iter().filter(|p| p != path).collect();
    h.push(path.to_string());
    let skip = h.len().saturating_sub(200);
    let file = history_file();
    if let Some(dir) = Path::new(&file).parent() {
        let _ = fs::create_dir_all(dir);
    }
    let _ = fs::write(&file, h[skip..].join("\n") + "\n");
}

fn roots() -> Vec<String> {
    let mut v = vec![home()];
    let user = env::var("USER").unwrap_or_default();
    if let Ok(media) = fs::read_dir(format!("/run/media/{user}")) {
        v.extend(media.flatten().map(|e| e.path().to_string_lossy().into_owned()));
    }
    v
}

#[cfg(target_os = "linux")]
mod watch {
    //! inotify: one watch per folder; events keep the index live.
    use inotify::{EventMask, Inotify, WatchDescriptor, WatchMask};
    use std::collections::HashMap;

    pub struct Watcher {
        pub inotify: Inotify,
        pub wd_dir: HashMap<WatchDescriptor, String>,
        dir_wd: HashMap<String, WatchDescriptor>,
    }

    impl Watcher {
        pub fn new() -> std::io::Result<Self> {
            Ok(Watcher { inotify: Inotify::init()?, wd_dir: HashMap::new(), dir_wd: HashMap::new() })
        }
        pub fn add(&mut self, dir: &str) -> bool {
            let mask = WatchMask::CREATE | WatchMask::DELETE | WatchMask::MOVED_FROM | WatchMask::MOVED_TO | WatchMask::DELETE_SELF | WatchMask::ONLYDIR;
            match self.inotify.watches().add(dir, mask) {
                Ok(wd) => {
                    self.wd_dir.insert(wd.clone(), dir.to_string());
                    self.dir_wd.insert(dir.to_string(), wd);
                    true
                }
                Err(_) => false,
            }
        }
        pub fn clear(&mut self) {
            for (wd, _) in self.wd_dir.drain() {
                let _ = self.inotify.watches().remove(wd);
            }
            self.dir_wd.clear();
        }
        pub fn forget_tree(&mut self, path: &str) {
            let prefix = format!("{path}/");
            let gone: Vec<String> = self.dir_wd.keys().filter(|d| *d == path || d.starts_with(&prefix)).cloned().collect();
            for d in gone {
                if let Some(wd) = self.dir_wd.remove(&d) {
                    self.wd_dir.remove(&wd);
                }
            }
        }
    }

    pub enum Change {
        Added(String, bool),
        Removed(String),
        Overflow,
    }

    /// Wait for (block = true) or poll file system events and turn them into index changes.
    pub fn changes(w: &mut Watcher, block: bool, buf: &mut [u8]) -> Vec<Change> {
        let events = if block { w.inotify.read_events_blocking(buf) } else { w.inotify.read_events(buf) };
        let Ok(events) = events else { return vec![] };
        let mut out = vec![];
        for e in events {
            if e.mask.contains(EventMask::Q_OVERFLOW) {
                return vec![Change::Overflow];
            }
            let Some(dir) = w.wd_dir.get(&e.wd).cloned() else { continue };
            let name = e.name.and_then(|n| n.to_str()).unwrap_or("");
            if name.starts_with('.') {
                continue;
            }
            let path = if name.is_empty() { dir.clone() } else { format!("{dir}/{name}") };
            if e.mask.intersects(EventMask::CREATE | EventMask::MOVED_TO) {
                out.push(Change::Added(path, e.mask.contains(EventMask::ISDIR)));
            } else if e.mask.intersects(EventMask::DELETE | EventMask::MOVED_FROM) {
                out.push(Change::Removed(path));
            } else if e.mask.intersects(EventMask::DELETE_SELF | EventMask::IGNORED) {
                w.wd_dir.remove(&e.wd);
                w.dir_wd.remove(&dir);
            }
        }
        out
    }

    pub fn apply(index: &mut super::Index, changes: Vec<Change>, roots: &[String]) {
        for c in changes {
            match c {
                Change::Overflow => return index.rebuild(roots),
                Change::Added(p, is_dir) => {
                    index.paths.insert(p.clone());
                    if is_dir {
                        index.scan(&p);
                    }
                }
                Change::Removed(p) => index.drop_tree(&p),
            }
        }
    }
}

/// Ransomware guard, from the changes the index sees anyway (no extra watching, nothing scanned): a file that
/// disappears and comes back with an extra ending (report.docx -> report.docx.locked), by renaming or by writing an
/// encrypted copy and deleting the original. Many of those within a minute = an alert. Endings that ordinary tools
/// add (compressing, backups, downloads in progress) don't count.
struct Guard {
    removed: std::collections::VecDeque<(u64, String)>,   // (second, path), the last minute
    hits: std::collections::VecDeque<(u64, String)>,      // (second, folder) replacements, the last minute
    last_alert: u64,
}

const GUARD_WINDOW: u64 = 60;
const GUARD_LIMIT: usize = 20;
const GUARD_QUIET: u64 = 600;
const HARMLESS_ENDINGS: [&str; 15] =
    ["gz", "xz", "bz2", "zst", "lz4", "zip", "7z", "bak", "old", "orig", "tmp", "part", "crdownload", "sig", "asc"];

impl Guard {
    fn new() -> Self {
        Guard { removed: Default::default(), hits: Default::default(), last_alert: 0 }
    }

    /// Feed one batch of changes at time NOW (seconds). Returns (how many, the folder most hit) when it's time to warn.
    fn observe(&mut self, changes: &[watch::Change], now: u64) -> Option<(usize, String)> {
        while self.removed.front().is_some_and(|(t, _)| now.saturating_sub(*t) > GUARD_WINDOW) {
            self.removed.pop_front();
        }
        while self.hits.front().is_some_and(|(t, _)| now.saturating_sub(*t) > GUARD_WINDOW) {
            self.hits.pop_front();
        }
        for c in changes {
            match c {
                watch::Change::Removed(p) => {
                    self.removed.push_back((now, p.clone()));
                    if self.removed.len() > 5000 {
                        self.removed.pop_front();
                    }
                }
                watch::Change::Added(p, false) => {
                    let Some((stem, ending)) = p.rsplit_once('.') else { continue };
                    if ending.is_empty() || ending.len() > 16 || ending.contains('/')
                        || HARMLESS_ENDINGS.contains(&ending.to_ascii_lowercase().as_str()) {
                        continue;
                    }
                    // the file it replaces had an ending of its own: report.docx -> report.docx.locked
                    if !stem.rsplit('/').next().is_some_and(|n| n.contains('.')) {
                        continue;
                    }
                    if self.removed.iter().any(|(_, r)| r == stem) {
                        let folder = stem.rsplit_once('/').map(|(d, _)| d.to_string()).unwrap_or_default();
                        self.hits.push_back((now, folder));
                    }
                }
                _ => {}
            }
        }
        if self.hits.len() >= GUARD_LIMIT && now.saturating_sub(self.last_alert) > GUARD_QUIET {
            self.last_alert = now;
            let mut count: HashMap<&str, usize> = HashMap::new();
            for (_, f) in &self.hits {
                *count.entry(f.as_str()).or_default() += 1;
            }
            let folder = count.into_iter().max_by_key(|(_, n)| *n).map(|(f, _)| f.to_string()).unwrap_or_default();
            return Some((self.hits.len(), folder));
        }
        None
    }
}

#[cfg(target_os = "linux")]
fn warn_replaced(n: usize, folder: &str) {
    let shown = folder.replacen(&home(), "~", 1);
    let text = format!(
        "{n} files in {shown} were just replaced by copies with an extra ending (like .locked). If you didn't do this, \
         a program may be encrypting your files: close programs you don't know, then get the files back with \
         right-click on the folder > Restore previous versions."
    );
    let _ = std::process::Command::new("sh")
        .args(["-c", r#"[ "$(notify-send -a "Fennek Security" -i dialog-warning -u critical --action=show="Show the folder" --wait "Many files were just replaced" "$1")" = show ] && exec dolphin "$2""#, "sh", &text, folder])
        .spawn();
}

struct Runner {
    index: Arc<Mutex<Index>>,
}

type Match = (String, String, String, i32, f64, HashMap<String, zbus::zvariant::Value<'static>>);

#[zbus::interface(name = "org.kde.krunner1")]
impl Runner {
    fn actions(&self) -> Vec<(String, String, String)> {
        vec![("folder".into(), "Open containing folder".into(), "document-open-folder".into())]
    }

    #[zbus(name = "Match")]
    fn find(&self, query: &str) -> Vec<Match> {
        let found = {
            let index = self.index.lock().unwrap();
            search(index.paths.iter(), query, &load_history(), MAX_RESULTS)
        };
        let home = home();
        found
            .into_iter()
            .enumerate()
            .map(|(i, p)| {
                let is_dir = Path::new(&p).is_dir();
                let parent = Path::new(&p).parent().map(|d| d.to_string_lossy().replacen(&home, "~", 1)).unwrap_or_default();
                let name = Path::new(&p).file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default();
                let mut props = HashMap::new();
                props.insert("subtext".to_string(), zbus::zvariant::Value::from(parent));
                props.insert("urls".to_string(), zbus::zvariant::Value::from(vec![format!("file://{p}")]));
                (p, name, (if is_dir { "folder" } else { "text-x-generic" }).to_string(), 30, 0.9 - i as f64 * 0.01, props)
            })
            // last: the whole list in the Search window (match ids are paths, so "all:" can't be one)
            .chain((!query.trim().is_empty()).then(|| {
                (format!("all:{query}"), format!("See all results for \u{201c}{}\u{201d}", query.trim()),
                 "fennek-search".to_string(), 30, 0.05, HashMap::new())
            }))
            .collect()
    }

    fn run(&self, match_id: &str, action_id: &str) {
        if let Some(q) = match_id.strip_prefix("all:") {
            let _ = std::process::Command::new("fennek-app").args(["search", q]).spawn();
            return;
        }
        remember(match_id);
        let _ = if action_id == "folder" {
            std::process::Command::new("dolphin").args(["--select", match_id]).spawn()
        } else {
            std::process::Command::new("xdg-open").arg(match_id).spawn()
        };
    }
}

/// Every match for the search window: org.fennek.Search /search FindAll(query) -> paths (best first).
struct Finder {
    index: Arc<Mutex<Index>>,
}

#[zbus::interface(name = "org.fennek.Search")]
impl Finder {
    fn find_all(&self, query: &str) -> Vec<String> {
        let index = self.index.lock().unwrap();
        search(index.paths.iter(), query, &load_history(), MAX_ALL)
    }
}

/// One line per match for the window: path, size in bytes, modified (seconds since 1970), folder (1/0), tab-separated.
/// Paths with a tab or a line break in their name are left out (they couldn't be told apart in this format).
fn describe(paths: &[String]) -> Vec<String> {
    paths
        .iter()
        .filter(|p| !p.contains('\t') && !p.contains('\n'))
        .filter_map(|p| {
            let m = std::fs::metadata(p).ok()?;
            let t = m.modified().ok().and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok()).map(|d| d.as_secs()).unwrap_or(0);
            Some(format!("{p}\t{}\t{t}\t{}", if m.is_dir() { 0 } else { m.len() }, if m.is_dir() { 1 } else { 0 }))
        })
        .collect()
}

#[cfg(target_os = "linux")]
fn ask(query: &str) -> zbus::Result<Vec<String>> {
    let conn = zbus::blocking::Connection::session()?;
    let reply = conn.call_method(Some("org.fennek.Search"), "/search", Some("org.fennek.Search"), "FindAll", &(query,))?;
    reply.body().deserialize::<Vec<String>>()
}

#[cfg(target_os = "linux")]
fn serve() -> zbus::Result<()> {
    let roots = roots();
    let mut index = Index::new(skip_dirs(), true);
    index.rebuild(&roots);
    let index = Arc::new(Mutex::new(index));
    let _conn = zbus::blocking::connection::Builder::session()?
        .name("org.fennek.Search")?
        .serve_at("/runner", Runner { index: index.clone() })?
        .serve_at("/settings", settings::Runner { entries: settings::load() })?
        .serve_at("/search", Finder { index: index.clone() })?
        .build()?;
    // The inotify fd is shared through the index; wait for events without holding the lock.
    let mut buf = vec![0u8; 64 * 1024];
    let mut guard = Guard::new();
    let fd = {
        use std::os::fd::AsRawFd;
        index.lock().unwrap().watch.as_ref().map(|w| w.inotify.as_raw_fd())
    };
    loop {
        if let Some(fd) = fd {
            let mut pfd = libc_poll::PollFd { fd, events: 1, revents: 0 };
            libc_poll::wait(&mut pfd);
        }
        let mut ix = index.lock().unwrap();
        let Some(w) = ix.watch.as_mut() else { break };
        let changes = watch::changes(w, false, &mut buf);
        let now = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0);
        if let Some((n, folder)) = guard.observe(&changes, now) {
            warn_replaced(n, &folder);
        }
        watch::apply(&mut ix, changes, &roots);
    }
    Ok(())
}

#[cfg(target_os = "linux")]
mod libc_poll {
    //! poll(2) on the inotify fd, so events are read only when there are some (no busy loop, no lock held).
    #[repr(C)]
    pub struct PollFd {
        pub fd: i32,
        pub events: i16,
        pub revents: i16,
    }
    extern "C" {
        fn poll(fds: *mut PollFd, n: u64, timeout: i32) -> i32;
    }
    pub fn wait(p: &mut PollFd) {
        // SAFETY: one valid pollfd, infinite timeout.
        unsafe { poll(p, 1, -1) };
    }
}

fn selftest() {
    settings::selftest();
    let t = env::temp_dir().join(format!("fennek-search-test-{}", std::process::id()));
    let t = t.to_string_lossy().into_owned();
    let mk = |f: &str| {
        let p = format!("{t}/{f}");
        fs::create_dir_all(Path::new(&p).parent().unwrap()).unwrap();
        fs::write(&p, "").unwrap();
    };
    for f in ["Work/Report 2026.pdf", "Work/report-draft.docx", "Photos/cat.jpg", "skip/secret.pdf", ".config/hidden.pdf", "Music/song.mp3"] {
        mk(f);
    }
    let roots = vec![t.clone()];
    let mut ix = Index::new(vec![format!("{t}/skip")], true);
    ix.rebuild(&roots);
    let names = |ix: &Index, q: &str, h: &[String]| -> Vec<String> {
        search(ix.paths.iter(), q, h, MAX_RESULTS).into_iter().map(|p| p[t.len() + 1..].to_string()).collect()
    };
    assert_eq!(names(&ix, "report", &[]), ["Work/Report 2026.pdf", "Work/report-draft.docx"], "shorter name first");
    assert_eq!(names(&ix, "report ext:pdf", &[]), ["Work/Report 2026.pdf"]);
    assert_eq!(names(&ix, "type:image", &[]), ["Photos/cat.jpg"]);
    assert_eq!(names(&ix, "type:audio", &[]), ["Music/song.mp3"]);
    assert_eq!(names(&ix, "type:folder work", &[]), ["Work"]);
    assert_eq!(names(&ix, "pdf path:work", &[]), ["Work/Report 2026.pdf"]);
    assert!(names(&ix, "secret", &[]).is_empty() && names(&ix, "hidden", &[]).is_empty(), "skipped/hidden never indexed");
    assert_eq!(names(&ix, "report", &[format!("{t}/Work/report-draft.docx")])[0], "Work/report-draft.docx", "history first");
    assert!(names(&ix, "", &[]).is_empty() && names(&ix, "zzz", &[]).is_empty());
    fs::write(format!("{t}/Work/big.bin"), vec![0u8; 2 << 20]).unwrap();
    mk("Work/old notes.txt");
    let month_ago = std::time::SystemTime::now() - std::time::Duration::from_secs(40 * 86_400);
    fs::File::options().write(true).open(format!("{t}/Work/old notes.txt")).unwrap().set_modified(month_ago).unwrap();
    ix.rebuild(&roots);
    assert_eq!(names(&ix, "size:>1mb", &[]), ["Work/big.bin"]);
    assert_eq!(names(&ix, "report size:<1kb ext:pdf", &[]), ["Work/Report 2026.pdf"]);
    assert!(names(&ix, "notes dm:week", &[]).is_empty() && names(&ix, "notes dm:year", &[]) == ["Work/old notes.txt"]);
    assert!(names(&ix, "dm:week", &[]).contains(&"Work/big.bin".to_string()) && parse_size("1.5kb") == Some((true, 1536)));
    assert!(parse_size("<2g") == Some((false, 2 << 30)) && parse_size("lots").is_none() && parse_age("someday").is_none());
    fs::remove_file(format!("{t}/Work/big.bin")).unwrap();
    fs::remove_file(format!("{t}/Work/old notes.txt")).unwrap();
    ix.rebuild(&roots);
    #[cfg(target_os = "linux")]
    {
        let mut buf = vec![0u8; 64 * 1024];
        let mut live = |ix: &mut Index| {
            std::thread::sleep(std::time::Duration::from_millis(200));
            let ch = watch::changes(ix.watch.as_mut().unwrap(), false, &mut buf);
            watch::apply(ix, ch, &roots);
        };
        mk("Work/new invoice.pdf");
        mk("Projects/Deep/plan.txt");
        live(&mut ix);
        assert_eq!(names(&ix, "invoice", &[]), ["Work/new invoice.pdf"], "new file found without rescanning");
        assert_eq!(names(&ix, "plan", &[]), ["Projects/Deep/plan.txt"], "new folder tree indexed and watched");
        mk("Projects/Deep/later.txt");
        live(&mut ix);
        assert_eq!(names(&ix, "later", &[]), ["Projects/Deep/later.txt"], "files in a new folder are tracked too");
        fs::remove_file(format!("{t}/Work/new invoice.pdf")).unwrap();
        fs::rename(format!("{t}/Photos"), format!("{t}/Pictures")).unwrap();
        live(&mut ix);
        assert!(names(&ix, "invoice", &[]).is_empty(), "deleted file gone");
        assert_eq!(names(&ix, "cat", &[]), ["Pictures/cat.jpg"], "renamed folder: old paths gone, new ones found");
    }
    let _ = fs::remove_dir_all(&t);
    // ransomware guard: 20 files replaced by .locked copies in a minute -> one alert, then quiet
    use watch::Change::{Added, Removed};
    let mut g = Guard::new();
    let mut alerts = 0;
    for i in 0..25 {
        let f = format!("/h/u/Documents/report{i}.docx");
        let batch = [Removed(f.clone()), Added(format!("{f}.locked"), false)];
        if g.observe(&batch, 1000 + i).is_some() {
            alerts += 1;
        }
    }
    assert_eq!(alerts, 1, "one alert for a burst");
    assert_eq!(Guard::new().observe(&[], 0), None);
    let mut calm = Guard::new();
    for i in 0..30 {   // compressing, a big download finishing, new files, slow changes: no alert
        let f = format!("/h/u/logs/day{i}.txt");
        assert!(calm.observe(&[Removed(f.clone()), Added(format!("{f}.gz"), false)], 10 + i).is_none());
        assert!(calm.observe(&[Added(format!("/h/u/new{i}.docx.copy"), false)], 10 + i).is_none());
        let s = format!("/h/u/slow/r{i}.pdf");
        assert!(calm.observe(&[Removed(s.clone()), Added(format!("{s}.x9"), false)], 10_000 + i * 120).is_none());
    }
    let d = std::env::temp_dir().join(format!("fennek-search-describe-{}", std::process::id()));   // own per run
    let _ = std::fs::create_dir_all(&d);
    std::fs::write(d.join("a.txt"), "12345").unwrap();
    let lines = describe(&[d.join("a.txt").to_string_lossy().into_owned(), d.to_string_lossy().into_owned(),
                           "/nonexistent/x".into(), "/tmp/odd\tname".into()]);
    assert_eq!(lines.len(), 2, "missing files and odd names left out");
    assert_eq!(lines[0].split('\t').nth(1), Some("5"), "size");
    assert!(lines[0].ends_with("\t0"), "a file");
    assert!(lines[1].ends_with("\t1"), "a folder");
    let _ = std::fs::remove_dir_all(&d);
    println!("selftest ok");
}

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    if args == ["--selftest"] {
        selftest();
    } else if args.first().map(String::as_str) == Some("--ask") {
        // the search window: ask the running index (no scan of its own)
        #[cfg(target_os = "linux")]
        match ask(&args[1..].join(" ")) {
            Ok(found) => describe(&found).iter().for_each(|l| println!("{l}")),
            Err(e) => {
                eprintln!("fennek-search: {e}");
                std::process::exit(1);
            }
        }
    } else if !args.is_empty() {
        let mut ix = Index::new(skip_dirs(), false);
        ix.rebuild(&roots());
        for p in search(ix.paths.iter(), &args.join(" "), &load_history(), MAX_RESULTS) {
            println!("{p}");
        }
    } else {
        #[cfg(target_os = "linux")]
        if let Err(e) = serve() {
            eprintln!("fennek-search: {e}");
            std::process::exit(1);
        }
    }
}
