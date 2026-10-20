//! Settings in Start search: "mouse", "wifi", "dark mode"… find the page in Fennek Settings (not KDE's own window).
//! The list is /usr/share/fennek/settings-index.tsv, made from Settings' catalog during the image build:
//! name, target (kcm_… / a Fennek page / cmd:…), icon, description, category and extra words, tab-separated.

use std::collections::HashMap;

pub const INDEX: &str = "/usr/share/fennek/settings-index.tsv";

#[derive(Clone, Debug)]
pub struct Entry {
    pub name: String,
    pub target: String,
    pub icon: String,
    pub desc: String,
    hay: String,
}

pub fn parse(text: &str) -> Vec<Entry> {
    text.lines()
        .filter_map(|l| {
            let f: Vec<&str> = l.split('\t').collect();
            if f.len() < 6 || f[0].is_empty() || f[1].is_empty() {
                return None;
            }
            let hay = format!("{} {} {} {}", f[0], f[3], f[4], f[5]).to_lowercase();
            Some(Entry { name: f[0].into(), target: f[1].into(), icon: f[2].into(), desc: f[3].into(), hay })
        })
        .collect()
}

pub fn load() -> Vec<Entry> {
    std::fs::read_to_string(INDEX).map(|t| parse(&t)).unwrap_or_default()
}

/// Entries matching every word of the query, best first: name starting with it, name containing it, then the rest.
pub fn find<'a>(entries: &'a [Entry], query: &str, limit: usize) -> Vec<(&'a Entry, f64)> {
    let q = query.trim().to_lowercase();
    if q.chars().count() < 2 {
        return vec![];
    }
    let words: Vec<&str> = q.split_whitespace().collect();
    let mut out: Vec<(&Entry, f64)> = entries
        .iter()
        .filter(|e| words.iter().all(|w| e.hay.contains(w)))
        .map(|e| {
            let n = e.name.to_lowercase();
            (e, if n.starts_with(&q) { 1.0 } else if n.contains(&q) { 0.96 } else { 0.9 })
        })
        .collect();
    out.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap().then(a.0.name.len().cmp(&b.0.name.len())));
    out.truncate(limit);
    out
}

/// What running an entry means: open Settings on it, or a command from the catalog (Fennek's own file).
pub fn command(target: &str) -> Option<Vec<String>> {
    if let Some(cmd) = target.strip_prefix("cmd:") {
        return Some(vec!["sh".into(), "-c".into(), cmd.into()]);
    }
    let ok = !target.is_empty() && target.chars().all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-');
    ok.then(|| vec!["fennek-app".into(), "settings".into(), target.into()])
}

pub struct Runner {
    pub entries: Vec<Entry>,
}

type Match = (String, String, String, i32, f64, HashMap<String, zbus::zvariant::Value<'static>>);

#[zbus::interface(name = "org.kde.krunner1")]
impl Runner {
    #[zbus(name = "Match")]
    fn find(&self, query: &str) -> Vec<Match> {
        find(&self.entries, query, 6)
            .into_iter()
            .map(|(e, rel)| {
                let mut props = HashMap::new();
                props.insert("subtext".to_string(), zbus::zvariant::Value::from(format!("Settings · {}", e.desc)));
                (e.target.clone(), e.name.clone(), e.icon.clone(), if rel >= 1.0 { 100 } else { 70 }, rel, props)
            })
            .collect()
    }

    fn run(&self, match_id: &str, _action_id: &str) {
        if !self.entries.iter().any(|e| e.target == match_id) {
            return; // only what the list offers
        }
        if let Some(c) = command(match_id) {
            let _ = std::process::Command::new(&c[0]).args(&c[1..]).spawn();
        }
    }
}

pub fn selftest() {
    let t = "Mouse\tkcm_mouse\tfennek-set-mouse\tPointer speed, buttons\tDevices\t\n\
             Display\tkcm_kscreen\tfennek-set-display\tResolution, scaling\tSystem\tscreen monitor\n\
             Dark mode\tpersonalize\tfennek-set-themes\tTheme, text size\tAppearance\tdark light theme\n\
             Storage\tcmd:filelight\tfennek-set-storage\tWhat uses space\tSystem\t\n\
             broken line\n";
    let e = parse(t);
    assert_eq!(e.len(), 4, "a short line is skipped");
    let names = |q: &str| find(&e, q, 6).into_iter().map(|(x, _)| x.name.clone()).collect::<Vec<_>>();
    assert_eq!(names("mou"), ["Mouse"]);
    assert_eq!(names("monitor"), ["Display"], "extra words count");
    assert_eq!(names("dark"), ["Dark mode"]);
    assert!(names("m").is_empty(), "one letter: nothing");
    assert_eq!(command("kcm_mouse").unwrap(), ["fennek-app", "settings", "kcm_mouse"]);
    assert_eq!(command("cmd:filelight").unwrap(), ["sh", "-c", "filelight"]);
    assert!(command("x;rm").is_none(), "only plain page names");
}
