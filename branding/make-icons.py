# Fennek icons, Apple-style: squircle app tiles with a soft gradient + white glyph; refined yellow folders.
# Regenerates the SVGs:  python branding/make-icons.py system_files
import sys
base = sys.argv[1] + "/usr/share/icons/Fennek/scalable"
hicolor = sys.argv[1] + "/usr/share/icons/hicolor/scalable/apps"
SQ = "M4 32C4 9.6 9.6 4 32 4s28 5.6 28 28-5.6 28-28 28S4 54.4 4 32z"


def app(top, bottom, glyph):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><defs>'
            f'<linearGradient id="t" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>'
            '<linearGradient id="hl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".22"/><stop offset=".5" stop-color="#fff" stop-opacity="0"/></linearGradient>'
            '<filter id="sh" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="1.2" stdDeviation="1.2" flood-opacity=".28"/></filter>'
            '</defs>'
            f'<path d="{SQ}" fill="url(#t)" filter="url(#sh)"/><path d="{SQ}" fill="url(#hl)"/>'
            f'<g fill="none" stroke="#fff" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round">{glyph}</g></svg>\n')


shield = '<path d="M32 17l12 4.5v9c0 8-5.2 13.6-12 16.5-6.8-2.9-12-8.5-12-16.5v-9z"/>'
trash = '<path d="M21 24h22M28 24v-3h8v3M24 24l2 20h12l2-20"/>'
glyphs = {
    "files": ("#5aa9f8", "#1f6fd6", '<path d="M18 23a3 3 0 0 1 3-3h7l3 3h12a3 3 0 0 1 3 3v15a3 3 0 0 1-3 3H21a3 3 0 0 1-3-3z"/>'),
    "settings": ("#9aa3b0", "#5d6674", '<circle cx="32" cy="32" r="5.5"/><path d="M32 16v5M32 43v5M16 32h5M43 32h5M20.7 20.7l3.6 3.6M39.7 39.7l3.6 3.6M20.7 43.3l3.6-3.6M39.7 24.3l3.6-3.6"/>'),
    "firewall": ("#ff9b55", "#e2561f", shield + '<path d="M26 32h12M32 26v12" stroke-width="3"/>'),
    "quarantine": ("#a77bf3", "#6a35c9", shield + '<rect x="27" y="30.5" width="10" height="8" rx="1.5" fill="#fff" stroke="none"/><path d="M29 30.5v-2.5a3 3 0 0 1 6 0v2.5" stroke-width="2.6"/>'),
    "taskmanager": ("#4ad07f", "#15985a", '<path d="M17 38l7-8 6 5 7-11 10 9"/>'),
    "terminal": ("#4a5160", "#1e222b", '<path d="M20 25l7 7-7 7"/><path d="M31 40h12"/>'),
    "store": ("#b38af7", "#7543d6", '<path d="M21 26h22l-2 18H23z"/><path d="M27 26v-2a5 5 0 0 1 10 0v2"/>'),
    "notepad": ("#ffd36b", "#f0a91e", '<path d="M24 24h16M24 31h16M24 38h10"/>'),
    "calculator": ("#ffa64d", "#f07316", '<path d="M24 25h16M24 32h4M32 32h4M40 32h.01M24 39h4M32 39h4M40 39h.01"/>'),
    "photos": ("#6ec6ff", "#2b86e8", '<rect x="18" y="21" width="28" height="22" rx="4"/><path d="M18 39l8-7 6 5 5-4 9 7" stroke-width="3"/><circle cx="39" cy="27.5" r="2.2" fill="#fff" stroke="none"/>'),
    "screenshot": ("#7d8cff", "#4655e0", '<path d="M19 26v-4a3 3 0 0 1 3-3h4M38 19h4a3 3 0 0 1 3 3v4M45 38v4a3 3 0 0 1-3 3h-4M26 45h-4a3 3 0 0 1-3-3v-4"/><circle cx="32" cy="32" r="5"/>'),
    "trash": ("#c3cad4", "#8b95a3", trash),
    "trashfull": ("#c3cad4", "#8b95a3", trash + '<path d="M29 30v8M35 30v8" stroke-width="2.6"/>'),
    "drive": ("#9aa3b0", "#5d6674", '<rect x="17" y="25" width="30" height="16" rx="4"/><circle cx="40" cy="33" r="1.8" fill="#fff" stroke="none"/>'),
    "pc": ("#5aa9f8", "#1f6fd6", '<rect x="17" y="20" width="30" height="19" rx="3"/><path d="M27 45h10M32 39v6"/>'),
}
names = {
    "files": ["apps/org.kde.dolphin", "apps/system-file-manager", "apps/file-manager"],
    "settings": ["apps/fennek-settings", "apps/preferences-system", "apps/systemsettings"],
    "firewall": ["apps/fennek-firewall"], "quarantine": ["apps/fennek-quarantine"],
    "taskmanager": ["apps/org.kde.plasma-systemmonitor", "apps/utilities-system-monitor", "apps/ksysguard"],
    "terminal": ["apps/org.kde.konsole", "apps/utilities-terminal", "apps/konsole"],
    "store": ["apps/plasmadiscover", "apps/org.kde.discover", "apps/system-software-install"],
    "notepad": ["apps/org.kde.kwrite", "apps/kwrite", "apps/accessories-text-editor", "apps/org.kde.kate"],
    "calculator": ["apps/org.kde.kcalc", "apps/accessories-calculator", "apps/kcalc"],
    "photos": ["apps/org.kde.gwenview", "apps/gwenview", "apps/image-viewer"],
    "screenshot": ["apps/org.kde.spectacle", "apps/spectacle", "apps/applets-screenshooter"],
    "trash": ["places/user-trash", "places/trash-empty"], "trashfull": ["places/user-trash-full", "places/trash-full"],
    "drive": ["devices/drive-harddisk", "devices/drive-harddisk-root"], "pc": ["devices/computer", "places/computer"],
}
for k, ns in names.items():
    s = app(*glyphs[k])
    for n in ns:
        open(f"{base}/{n}.svg", "w", newline="\n").write(s)
for n in ("fennek-firewall", "fennek-quarantine", "fennek-settings"):
    open(f"{hicolor}/{n}.svg", "w", newline="\n").write(open(f"{base}/apps/{n}.svg").read())

DEFS = ('<defs><linearGradient id="b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f2b43a"/><stop offset="1" stop-color="#df9a1e"/></linearGradient>'
        '<linearGradient id="f" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffd76e"/><stop offset="1" stop-color="#ffc23d"/></linearGradient>'
        '<filter id="sh" x="-10%" y="-10%" width="120%" height="130%"><feDropShadow dx="0" dy="1" stdDeviation="1" flood-opacity=".22"/></filter></defs>')
BACK = '<path d="M6 15a4 4 0 0 1 4-4h12.5l5 5H54a4 4 0 0 1 4 4v29a4 4 0 0 1-4 4H10a4 4 0 0 1-4-4z" fill="url(#b)"/>'
FRONT = ('<path d="M6 23a4 4 0 0 1 4-4h44a4 4 0 0 1 4 4v26a4 4 0 0 1-4 4H10a4 4 0 0 1-4-4z" fill="url(#f)" filter="url(#sh)"/>'
         '<path d="M10 20h44" stroke="#fff" stroke-opacity=".55" stroke-width="1.2"/>')
OPEN = '<path d="M12 23a4 4 0 0 1 3.8-3h42a2.4 2.4 0 0 1 2.3 3l-5 27a4 4 0 0 1-4 3H9.8A2.4 2.4 0 0 1 7.5 50z" fill="url(#f)" filter="url(#sh)"/>'
G = 'fill="none" stroke="#fff" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round" opacity=".95"'
sym = {
    "documents": '<path d="M26 31h12M26 36h12M26 41h8"/>',
    "download": '<path d="M32 29v12M27 36l5 5 5-5"/>',
    "pictures": '<path d="M24 42l6-6 4 4 3-3 4 4"/><circle cx="37" cy="31" r="1.6" fill="#fff" stroke="none"/>',
    "music": '<path d="M30 42v-11l9-2v10"/><circle cx="27.5" cy="42" r="2.4"/><circle cx="36.5" cy="40" r="2.4"/>',
    "videos": '<path d="M29 30v12l10-6z" fill="#fff" stroke="none"/>',
    "desktop": '<rect x="24" y="29" width="16" height="10" rx="1.5"/><path d="M29 43h6"/>',
    "home": '<path d="M24 36l8-7 8 7M27 34v8h10v-8"/>',
    "public": '<circle cx="28" cy="33" r="2.4"/><circle cx="36" cy="33" r="2.4"/><path d="M23 42c0-3 2.4-5 5-5s5 2 5 5M31 42c0-3 2.4-5 5-5s5 2 5 5"/>',
    "templates": '<rect x="25" y="29" width="14" height="13" rx="1.5" stroke-dasharray="3 2.5"/>',
}
fn = {"documents": ["folder-documents"], "download": ["folder-download", "folder-downloads"],
      "pictures": ["folder-pictures", "folder-image", "folder-images"], "music": ["folder-music", "folder-sound"],
      "videos": ["folder-videos", "folder-video"], "desktop": ["folder-desktop", "user-desktop"],
      "home": ["user-home", "folder-home"], "public": ["folder-publicshare", "folder-public"], "templates": ["folder-templates"]}
svg = lambda b: f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">{DEFS}{b}</svg>\n'
for n in ("folder", "inode-directory"):
    open(f"{base}/places/{n}.svg", "w", newline="\n").write(svg(BACK + FRONT))
open(f"{base}/places/folder-open.svg", "w", newline="\n").write(svg(BACK + OPEN))
for k, ns in fn.items():
    for n in ns:
        open(f"{base}/places/{n}.svg", "w", newline="\n").write(svg(BACK + FRONT + f"<g {G}>{sym[k]}</g>"))
print("ok")
