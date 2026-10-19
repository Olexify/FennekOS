# Fennek icons: squircle app tiles with a soft gradient + white glyph; refined yellow folders.
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
    "archives": ("#d2ab82", "#916b4c", '<path d="M18 20h28v6H18z"/><path d="M20 26h24v16a3 3 0 0 1-3 3H23a3 3 0 0 1-3-3z"/><path d="M29 32h6"/>'),
    "storage": ("#43d0c2", "#159a8f", '<circle cx="32" cy="32" r="12"/><path d="M32 20v12h12"/>'),
    "phone": ("#6fd36f", "#2f9e46", '<rect x="24" y="17" width="16" height="30" rx="3.5"/><path d="M30 42h4"/>'),
    "sharing": ("#7c8cf8", "#4352d6", '<rect x="17" y="20" width="30" height="19" rx="3"/><path d="M27 45h10M32 39v6"/><path d="M28 30l4-4 4 4M32 26v8" stroke-width="3"/>'),
    "pdf": ("#ff7a6b", "#d93a2b", '<path d="M24 17h12l8 8v19a3 3 0 0 1-3 3H24a3 3 0 0 1-3-3V20a3 3 0 0 1 3-3z"/><path d="M36 17v8h8"/><path d="M26 34h12M26 39h8" stroke-width="3"/>'),
    "media": ("#ff6aa0", "#d62f6b", '<path d="M27 22l15 10-15 10z" fill="#fff" stroke="none"/>'),
    "music": ("#ff8a65", "#e8503a", '<path d="M30 42V24l12-3v17"/><circle cx="26.5" cy="42" r="3.5"/><circle cx="38.5" cy="38" r="3.5"/>'),
    "paint": ("#ffb74d", "#f57c00", '<path d="M40 18l6 6-14 14-6-6z"/><path d="M26 32c-4 0-6 3-6 6 0 2-1 4-3 5 5 1 12 0 14-5"/>'),
    "search": ("#8f86a8", "#4d4565", '<circle cx="29" cy="29" r="9.5"/><path d="M36 36l8 8"/>'),
    "apphistory": ("#ffc35a", "#e8901e", '<path d="M19 32a13 13 0 1 0 4-9.4"/><path d="M18 18v6h6"/><path d="M32 25v8l5 3"/>'),
    "scanner": ("#90a4ae", "#546e7a", '<rect x="17" y="30" width="30" height="12" rx="3"/><path d="M20 30l4-8h20"/><path d="M23 36h12" stroke-width="3"/>'),
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
    "archives": ["apps/org.kde.ark", "apps/ark", "apps/utilities-file-archiver"],
    "storage": ["apps/org.kde.filelight", "apps/filelight"],
    "phone": ["apps/org.kde.kdeconnect.app", "apps/kdeconnect", "apps/kdeconnect-app"],
    "sharing": ["apps/org.kde.krfb", "apps/krfb", "apps/preferences-desktop-remote-desktop"],
    "pdf": ["apps/org.kde.okular", "apps/okular"],
    "media": ["apps/org.kde.haruna", "apps/haruna"],
    "music": ["apps/org.kde.elisa", "apps/elisa"],
    "paint": ["apps/org.kde.kolourpaint", "apps/kolourpaint"],
    "search": ["apps/fennek-search"],
    "apphistory": ["apps/fennek-apphistory"],
    "scanner": ["apps/org.kde.skanpage", "apps/skanpage"],
}
for k, ns in names.items():
    s = app(*glyphs[k])
    for n in ns:
        open(f"{base}/{n}.svg", "w", newline="\n").write(s)
# Drives with a usage bar for This PC (fennek-drive-used-0 ... -100): amber from 75 % full, red from 90 %.
for pct in range(0, 101, 10):
    # Thick bar on a bright track: amber from 75 % full, red from 90 % (time to free space), white below.
    fill = "#ff5a5a" if pct >= 90 else "#ffc247" if pct >= 75 else "#fff"
    track = '<rect x="14" y="39" width="36" height="8" rx="4" fill="#fff" fill-opacity=".38" stroke="none"/>'
    bar = track + (f'<rect x="14" y="39" width="{max(8, 36 * pct / 100):.1f}" height="8" rx="4" fill="{fill}" stroke="none"/>' if pct else "")
    glyph = '<rect x="17" y="17" width="30" height="15" rx="4"/><circle cx="40" cy="24.5" r="1.8" fill="#fff" stroke="none"/>' + bar
    open(f"{base}/devices/fennek-drive-used-{pct}.svg", "w", newline="\n").write(app("#9aa3b0", "#5d6674", glyph))

# This PC's main folders, in the app-tile style (each its own colour and symbol).
special = {
    "desktop":   ("#46c6d3", "#1d8a9c", '<rect x="18" y="20" width="28" height="18" rx="3"/><path d="M27 45h10M32 38v7"/>'),
    "documents": ("#5aa0ff", "#2f6fe0", '<path d="M24 16h11l7 7v22a3 3 0 0 1-3 3H24a3 3 0 0 1-3-3V19a3 3 0 0 1 3-3z"/><path d="M35 16v7h7M27 32h10M27 38h7"/>'),
    "downloads": ("#4fd08a", "#1e9c58", '<path d="M32 17v20M24 30l8 8 8-8M20 46h24"/>'),
    "music":     ("#ff7eae", "#df4483", '<path d="M29 42V22l13-3v18"/><circle cx="25.5" cy="42" r="3.5"/><circle cx="38.5" cy="37" r="3.5"/>'),
    "pictures":  ("#ad8cfb", "#6c45e3", '<rect x="17" y="20" width="30" height="24" rx="4"/><circle cx="26" cy="28" r="3"/><path d="M19 41l9-8 6 5 4-3 8 6"/>'),
    "videos":    ("#ff8f6a", "#e3523c", '<rect x="16" y="21" width="32" height="22" rx="4"/><path d="M29 27l8 5-8 5z" fill="#fff"/>'),
}
for k, (top, bot, g) in special.items():
    open(f"{base}/places/fennek-folder-{k}.svg", "w", newline="\n").write(app(top, bot, g))
for n in ("fennek-firewall", "fennek-quarantine", "fennek-settings", "fennek-apphistory"):
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
# The main folders look the same everywhere (sidebar, file dialogs, the home folder) as on This PC.
same = {"documents": "documents", "download": "downloads", "pictures": "pictures", "music": "music", "videos": "videos",
        "desktop": "desktop"}
for k, ns in fn.items():
    for n in ns:
        icon = (open(f"{base}/places/fennek-folder-{same[k]}.svg").read() if k in same
                else svg(BACK + FRONT + f"<g {G}>{sym[k]}</g>"))
        open(f"{base}/places/{n}.svg", "w", newline="\n").write(icon)
print("ok")

# Settings home categories (own names, so system-wide icons like the tray's Wi-Fi stay untouched).
settings = {
    "system": ("#5aa9f8", "#1f6fd6", '<rect x="17" y="20" width="30" height="19" rx="3"/><path d="M27 45h10M32 39v6"/>'),
    "devices": ("#9aa3b0", "#5d6674", '<rect x="18" y="20" width="16" height="24" rx="3"/><path d="M38 26h8v18h-8z"/>'),
    "network": ("#4fc3f7", "#1e88e5", '<path d="M19 29a19 19 0 0 1 26 0M23.5 34a12.5 12.5 0 0 1 17 0M28 39a6 6 0 0 1 8 0"/><circle cx="32" cy="43.5" r="1.6" fill="#fff" stroke="none"/>'),
    "appearance": ("#ff8fb1", "#e04883", '<path d="M32 18a14 14 0 1 0 0 28c2 0 3-1.5 3-3s-1-2.2-1-3.6c0-1.6 1.3-2.4 3-2.4h3a6 6 0 0 0 6-6c0-7.4-6.3-13-14-13z"/><circle cx="25" cy="30" r="1.6" fill="#fff" stroke="none"/><circle cx="31" cy="25" r="1.6" fill="#fff" stroke="none"/><circle cx="38" cy="27" r="1.6" fill="#fff" stroke="none"/>'),
    "apps": ("#b38af7", "#7543d6", '<rect x="19" y="19" width="10" height="10" rx="2.5"/><rect x="35" y="19" width="10" height="10" rx="2.5"/><rect x="19" y="35" width="10" height="10" rx="2.5"/><rect x="35" y="35" width="10" height="10" rx="2.5"/>'),
    "accounts": ("#ffb84d", "#f08a16", '<circle cx="32" cy="27" r="6"/><path d="M21 45c1.5-6 6-9 11-9s9.5 3 11 9"/>'),
    "time": ("#4ad07f", "#15985a", '<circle cx="32" cy="32" r="13"/><path d="M32 24v8l5 4"/>'),
    "accessibility": ("#5aa9f8", "#1f6fd6", '<circle cx="32" cy="20" r="2.5" fill="#fff" stroke="none"/><path d="M21 26l11 2 11-2M32 28v8l-5 9M32 36l5 9"/>'),
    "privacy": ("#a77bf3", "#6a35c9", '<path d="M32 17l12 4.5v9c0 8-5.2 13.6-12 16.5-6.8-2.9-12-8.5-12-16.5v-9z"/><path d="M27 32l4 4 7-8"/>'),
    "update": ("#4fc3f7", "#1e88e5", '<path d="M44 30a12 12 0 0 0-22-5M20 34a12 12 0 0 0 22 5"/><path d="M22 19v6h6M42 45v-6h-6"/>'),
}
for k, g in settings.items():
    s = app(*g)
    for d in (f"{base}/apps", hicolor):
        open(f"{d}/fennek-settings-{k}.svg", "w", newline="\n").write(s)
print("settings icons ok")

# Settings: one icon per setting (fennek-set-NAME), same tile style, each its own colour and symbol.
setting_icons = {
    "display": ("#5aa9f8", "#1f6fd6", '<rect x="17" y="20" width="30" height="19" rx="3"/><path d="M27 45h10M32 39v6"/>'),
    "nightlight": ("#7c8cf8", "#4251d6", '<path d="M38 20a12 12 0 1 0 6 18 10 10 0 0 1-6-18z"/>'),
    "sound": ("#46c6d3", "#1d8a9c", '<path d="M20 28h6l8-7v22l-8-7h-6z"/><path d="M39 26a8 8 0 0 1 0 12M43 22a14 14 0 0 1 0 20"/>'),
    "notifications": ("#ffb84d", "#f08a16", '<path d="M24 38V29a8 8 0 0 1 16 0v9l3 3H21z"/><path d="M29 44a3 3 0 0 0 6 0"/>'),
    "multitasking": ("#5aa9f8", "#1f6fd6", '<rect x="17" y="20" width="20" height="15" rx="2.5"/><rect x="27" y="29" width="20" height="15" rx="2.5"/>'),
    "desktops": ("#b38af7", "#7543d6", '<rect x="18" y="19" width="12" height="11" rx="2"/><rect x="34" y="19" width="12" height="11" rx="2"/><rect x="18" y="34" width="12" height="11" rx="2"/><rect x="34" y="34" width="12" height="11" rx="2"/>'),
    "switcher": ("#7c8cf8", "#4251d6", '<rect x="22" y="24" width="20" height="16" rx="2.5"/><path d="M18 36V22a2 2 0 0 1 2-2h18M46 28v14a2 2 0 0 1-2 2H26"/>'),
    "edges": ("#46c6d3", "#1d8a9c", '<path d="M19 27v-6a2 2 0 0 1 2-2h6M45 37v6a2 2 0 0 1-2 2h-6"/><rect x="25" y="25" width="14" height="14" rx="2.5"/>'),
    "power": ("#4ad07f", "#15985a", '<path d="M32 18v12M24 23a12 12 0 1 0 16 0"/>'),
    "storage": ("#9aa3b0", "#5d6674", '<rect x="17" y="24" width="30" height="16" rx="4"/><circle cx="40" cy="32" r="1.8" fill="#fff" stroke="none"/><path d="M22 32h10"/>'),
    "removable": ("#ffb84d", "#f08a16", '<rect x="25" y="25" width="14" height="20" rx="2.5"/><path d="M28 25v-6h8v6M30 21h1M33 21h1"/>'),
    "about": ("#5aa9f8", "#1f6fd6", '<circle cx="32" cy="32" r="13"/><path d="M32 30v9"/><circle cx="32" cy="25" r="1.6" fill="#fff" stroke="none"/>'),
    "bluetooth": ("#5aa9f8", "#1f6fd6", '<path d="M25 25l14 13-7 6V20l7 6-14 13"/>'),
    "printer": ("#9aa3b0", "#5d6674", '<path d="M24 26v-7h16v7"/><rect x="18" y="26" width="28" height="12" rx="3"/><path d="M24 34h16v10H24z"/>'),
    "mouse": ("#9aa3b0", "#5d6674", '<rect x="24" y="17" width="16" height="30" rx="8"/><path d="M32 17v9"/>'),
    "touchpad": ("#9aa3b0", "#5d6674", '<rect x="17" y="20" width="30" height="24" rx="4"/><path d="M17 38h30M32 38v6"/>'),
    "keyboard": ("#9aa3b0", "#5d6674", '<rect x="15" y="23" width="34" height="19" rx="3"/><path d="M20 29h2M26 29h2M32 29h2M38 29h2M44 29h0M20 34h2M44 34h0M26 37h12"/>'),
    "gamepad": ("#7c8cf8", "#4251d6", '<path d="M22 24h20a7 7 0 0 1 6.6 9.3l-2.6 8a4 4 0 0 1-6.7 1.4L36 39H28l-3.3 3.7a4 4 0 0 1-6.7-1.4l-2.6-8A7 7 0 0 1 22 24z"/><path d="M24 30v6M21 33h6"/><circle cx="40" cy="31" r="1.5" fill="#fff" stroke="none"/><circle cx="43" cy="35" r="1.5" fill="#fff" stroke="none"/>'),
    "tablet": ("#ff8fb1", "#e04883", '<path d="M40 18l6 6-18 18-8 2 2-8z"/><path d="M36 22l6 6"/>'),
    "touchscreen": ("#46c6d3", "#1d8a9c", '<rect x="20" y="16" width="24" height="32" rx="4"/><circle cx="32" cy="32" r="4"/>'),
    "thunderbolt": ("#ffd45c", "#e8a512", '<path d="M35 16L22 35h9l-2 13 13-19h-9z"/>'),
    "wifi": ("#5aa9f8", "#1f6fd6", '<path d="M19 29a19 19 0 0 1 26 0M23.5 34a12.5 12.5 0 0 1 17 0M28 39a6 6 0 0 1 8 0"/><circle cx="32" cy="43.5" r="1.6" fill="#fff" stroke="none"/>'),
    "proxy": ("#46c6d3", "#1d8a9c", '<circle cx="32" cy="32" r="13"/><path d="M19 32h26M32 19c4 4 5 9 5 13s-1 9-5 13c-4-4-5-9-5-13s1-9 5-13z"/>'),
    "phone": ("#4ad07f", "#15985a", '<rect x="24" y="16" width="16" height="32" rx="4"/><path d="M30 43h4"/>'),
    "background": ("#ff8fb1", "#e04883", '<rect x="17" y="20" width="30" height="24" rx="4"/><circle cx="26" cy="28" r="3"/><path d="M19 41l9-8 6 5 4-3 8 6"/>'),
    "themes": ("#b38af7", "#7543d6", '<circle cx="32" cy="32" r="13"/><path d="M32 19a13 13 0 0 1 0 26z" fill="#fff"/>'),
    "colors": ("#ff8fb1", "#e04883", '<path d="M32 18a14 14 0 1 0 0 28c2 0 3-1.5 3-3s-1-2.2-1-3.6c0-1.6 1.3-2.4 3-2.4h3a6 6 0 0 0 6-6c0-7.4-6.3-13-14-13z"/><circle cx="25" cy="30" r="1.6" fill="#fff" stroke="none"/><circle cx="31" cy="25" r="1.6" fill="#fff" stroke="none"/><circle cx="38" cy="27" r="1.6" fill="#fff" stroke="none"/>'),
    "fonts": ("#ffb84d", "#f08a16", '<path d="M19 44l9-24 9 24M22.5 36h11M38 44V33a5 5 0 0 1 9 0v11M38 38h9"/>'),
    "icons": ("#5aa9f8", "#1f6fd6", '<rect x="19" y="19" width="10" height="10" rx="3"/><circle cx="40" cy="24" r="5"/><path d="M19 45l5-9 5 9z"/><rect x="35" y="35" width="10" height="10" rx="5"/>'),
    "appstyle": ("#7c8cf8", "#4251d6", '<rect x="17" y="20" width="30" height="24" rx="3"/><path d="M17 27h30M21 23.5h0M25 23.5h0M23 34h10M23 39h6"/>'),
    "windowframes": ("#5aa9f8", "#1f6fd6", '<rect x="17" y="20" width="30" height="24" rx="3"/><path d="M17 27h30M37 23.5h1M41 23.5h1"/>'),
    "effects": ("#b38af7", "#7543d6", '<path d="M32 17l3 8 8 3-8 3-3 8-3-8-8-3 8-3z"/><path d="M43 37l1.5 4 4 1.5-4 1.5-1.5 4-1.5-4-4-1.5 4-1.5z"/>'),
    "animation": ("#46c6d3", "#1d8a9c", '<path d="M18 40c6 0 6-16 14-16s8 16 14 16"/><circle cx="32" cy="24" r="2" fill="#fff" stroke="none"/>'),
    "splash": ("#ffb84d", "#f08a16", '<circle cx="32" cy="32" r="13" stroke-dasharray="6 4"/><circle cx="32" cy="32" r="4"/>'),
    "lockscreen": ("#7c8cf8", "#4251d6", '<rect x="21" y="29" width="22" height="16" rx="3"/><path d="M26 29v-4a6 6 0 0 1 12 0v4"/><path d="M32 35v4"/>'),
    "signin": ("#b38af7", "#7543d6", '<circle cx="32" cy="26" r="6"/><path d="M22 44c1.5-6 5.5-8 10-8s8.5 2 10 8"/><path d="M17 18h4M43 18h4"/>'),
    "pointer": ("#9aa3b0", "#5d6674", '<path d="M24 17v26l7-6 5 10 4-2-5-10h9z"/>'),
    "defaultapps": ("#ffd45c", "#e8a512", '<path d="M32 17l4.4 9 9.6 1.4-7 6.8 1.7 9.6L32 39.3l-8.7 4.5 1.7-9.6-7-6.8 9.6-1.4z"/>'),
    "filetypes": ("#5aa9f8", "#1f6fd6", '<path d="M24 16h11l7 7v22a3 3 0 0 1-3 3H24a3 3 0 0 1-3-3V19a3 3 0 0 1 3-3z"/><path d="M35 16v7h7M26 36l4 4 8-8"/>'),
    "startup": ("#4ad07f", "#15985a", '<circle cx="32" cy="32" r="13"/><path d="M29 26l9 6-9 6z" fill="#fff"/>'),
    "windowrules": ("#9aa3b0", "#5d6674", '<rect x="17" y="20" width="30" height="24" rx="3"/><path d="M17 27h30M23 33h18M23 38h12"/>'),
    "spellcheck": ("#4ad07f", "#15985a", '<path d="M18 36l6-16 6 16M20 31h8"/><path d="M33 38l5 5 9-12"/>'),
    "search": ("#46c6d3", "#1d8a9c", '<circle cx="29" cy="29" r="9"/><path d="M36 36l9 9"/>'),
    "users": ("#ffb84d", "#f08a16", '<circle cx="27" cy="26" r="5"/><path d="M18 43c1.2-5 4.6-7.5 9-7.5s7.8 2.5 9 7.5"/><circle cx="39" cy="24" r="4"/><path d="M38 33c4 0 7 2 8 6"/>'),
    "online": ("#5aa9f8", "#1f6fd6", '<path d="M24 41h17a8 8 0 0 0 1-16 11 11 0 0 0-21 3 7 7 0 0 0 3 13z"/>'),
    "passwords": ("#ffd45c", "#e8a512", '<circle cx="25" cy="32" r="7"/><path d="M32 32h15M42 32v6M46 32v4"/>'),
    "clock": ("#4ad07f", "#15985a", '<circle cx="32" cy="32" r="13"/><path d="M32 24v8l5 4"/>'),
    "region": ("#46c6d3", "#1d8a9c", '<circle cx="32" cy="32" r="13"/><path d="M19 32h26M32 19c4 4 5 9 5 13s-1 9-5 13c-4-4-5-9-5-13s1-9 5-13z"/>'),
    "access": ("#5aa9f8", "#1f6fd6", '<circle cx="32" cy="20" r="2.5" fill="#fff" stroke="none"/><path d="M21 26l11 2 11-2M32 28v8l-5 9M32 36l5 9"/>'),
    "shortcuts": ("#9aa3b0", "#5d6674", '<rect x="17" y="22" width="13" height="13" rx="3"/><rect x="34" y="22" width="13" height="13" rx="3"/><path d="M21 40h22"/><path d="M23.5 31v-5M38 26l4 4"/>'),
    "activities": ("#b38af7", "#7543d6", '<circle cx="24" cy="24" r="5"/><circle cx="40" cy="24" r="5"/><circle cx="24" cy="40" r="5"/><circle cx="40" cy="40" r="5"/>'),
    "firewall": ("#ff8a80", "#e04848", '<path d="M17 22h30v20H17zM17 29h30M17 36h30M27 22v7M37 29v7M27 36v6"/>'),
    "quarantine": ("#b38af7", "#7543d6", '<path d="M32 17l12 4.5v9c0 8-5.2 13.6-12 16.5-6.8-2.9-12-8.5-12-16.5v-9z"/><path d="M27 29l10 10M37 29L27 39"/>'),
    "permissions": ("#7c8cf8", "#4251d6", '<rect x="21" y="29" width="22" height="16" rx="3"/><path d="M26 29v-4a6 6 0 0 1 11.5-2.5"/>'),
    "recent": ("#46c6d3", "#1d8a9c", '<path d="M20 32a12 12 0 1 0 4-9"/><path d="M19 20v6h6M32 25v7l5 3"/>'),
    "signout": ("#ff8a80", "#e04848", '<path d="M30 20h-8a3 3 0 0 0-3 3v18a3 3 0 0 0 3 3h8"/><path d="M28 32h18M40 26l6 6-6 6"/>'),
    "privacypolicy": ("#b38af7", "#7543d6", '<path d="M24 16h11l7 7v22a3 3 0 0 1-3 3H24a3 3 0 0 1-3-3V19a3 3 0 0 1 3-3z"/><path d="M35 16v7h7M26 32h12M26 37h12M26 42h7"/>'),
    "updates": ("#5aa9f8", "#1f6fd6", '<path d="M44 30a12 12 0 0 0-22-5M20 34a12 12 0 0 0 22 5"/><path d="M22 19v6h6M42 45v-6h-6"/>'),
    "storeupdates": ("#b38af7", "#7543d6", '<path d="M22 26h20l-2 18H24z"/><path d="M27 26a5 5 0 0 1 10 0M32 32v7M29 36l3 3 3-3"/>'),
    "goback": ("#ffb84d", "#f08a16", '<path d="M24 26h13a8 8 0 0 1 0 16h-9"/><path d="M29 20l-6 6 6 6"/>'),
    "backup": ("#4ad07f", "#15985a", '<rect x="17" y="30" width="30" height="14" rx="4"/><path d="M32 16v12M27 23l5 5 5-5M23 37h6"/>'),
    "restore": ("#ff8fb1", "#e04883", '<rect x="17" y="34" width="30" height="10" rx="3"/><path d="M24 30V18h16v12M28 24h8"/>'),
    "apphistory": ("#ffb84d", "#f08a16", '<path d="M18 44V22M18 44h28M24 38v-8M31 38V26M38 38v-5"/>'),
}
for k, (top, bot, g) in setting_icons.items():
    s = app(top, bot, g)
    for d in (f"{base}/apps", hicolor):
        open(f"{d}/fennek-set-{k}.svg", "w", newline="\n").write(s)
print("setting icons ok")
