//! Fennek OS instant file search (Everything-style), one per user.
//!
//! Keeps every file name under your home and plugged-in drives in memory, kept live with inotify: no
//! rescans, no CPU while idle. Answers the Start menu / search panel / KRunner over D-Bus (org.kde.krunner1).
//! Never sees other users' files: it runs as you and only indexes what you can read.
//!
//! Query: words must all appear in the file name (any order, case-insensitive). Filters:
//!   ext:pdf;docx   type:image|video|audio|doc|archive|exe|folder   path:projects
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
}

/// "report ext:pdf;docx type:doc path:work" -> words, extensions, folders only, path words.
fn parse(query: &str) -> Query {
    let mut q = Query { words: vec![], exts: None, folders: false, paths: vec![] };
    for tok in query.to_lowercase().split_whitespace() {
        let (key, val) = tok.split_once(':').unwrap_or((tok, ""));
        match (key, val) {
            ("ext", v) if !v.is_empty() => {
                q.exts.get_or_insert_with(Vec::new).extend(v.split(';').filter(|e| !e.is_empty()).map(|e| e.trim_start_matches('.').to_string()))
            }
            ("type", "folder") => q.folders = true,
            ("type", v) if types(v).is_some() => q.exts.get_or_insert_with(Vec::new).extend(types(v).unwrap().iter().map(|s| s.to_string())),
            ("path", v) if !v.is_empty() => q.paths.push(v.to_string()),
            _ => q.words.push(tok.to_string()),
        }
    }
    q
}

pub fn search<'a>(paths: impl Iterator<Item = &'a String>, query: &str, history: &[String], limit: usize) -> Vec<String> {
    let q = parse(query);
    if q.words.is_empty() && q.exts.is_none() && !q.folders && q.paths.is_empty() {
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
            .collect()
    }

    fn run(&self, match_id: &str, action_id: &str) {
        remember(match_id);
        let _ = if action_id == "folder" {
            std::process::Command::new("dolphin").args(["--select", match_id]).spawn()
        } else {
            std::process::Command::new("xdg-open").arg(match_id).spawn()
        };
    }
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
        .build()?;
    // The inotify fd is shared through the index; wait for events without holding the lock.
    let mut buf = vec![0u8; 64 * 1024];
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
    println!("selftest ok");
}

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    if args == ["--selftest"] {
        selftest();
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
