#!/usr/bin/env bash
set -euo pipefail
files=${1:?usage: build.sh SYSTEM_FILES_DIR}   # the shipped tree, used as the list for permission fixes

# umu-launcher (Proton outside Steam) isn't in Fedora repos; pinned upstream RPM, checksum-verified.
UMU_VER=1.4.4
UMU_SHA256=f38dfe05c109a0ebeaecacad2ebe2e60fddc1fb2e50f7755023553ad256f8b32
UMU_RPM=/tmp/umu-launcher.rpm
curl -fsSL -o "$UMU_RPM" \
    "https://github.com/Open-Wine-Components/umu-launcher/releases/download/${UMU_VER}/umu-launcher-${UMU_VER}.fc44.x86_64.rpm"
echo "${UMU_SHA256}  ${UMU_RPM}" | sha256sum -c -

# OpenSnitch (per-app firewall engine) isn't in Fedora repos either: pinned upstream RPM, checksum-verified.
OSN_VER=1.8.0
OSN_SHA256=e06e9119daf764e56455b61c319e496274c0274bb53bb94a0ff1ab72967fea7d
OSN_RPM=/tmp/opensnitch.rpm
curl -fsSL -o "$OSN_RPM" \
    "https://github.com/evilsocket/opensnitch/releases/download/v${OSN_VER}/opensnitch-${OSN_VER}-1.x86_64.rpm"
echo "${OSN_SHA256}  ${OSN_RPM}" | sha256sum -c -

# Firefox as a regular app: the base leaves the browser out, but a fresh install needs one from the first
# minute, and the system privacy policy in /etc/firefox applies to it.
dnf -y install \
    libnetfilter_queue \
    firefox \
    flatpak-kcm \
    zsh zsh-autosuggestions zsh-syntax-highlighting \
    snapper \
    clamav clamav-freshclam inotify-tools \
    "$UMU_RPM"
# Its scripts only enable+start the daemon (and fail in a container); we want it off until something is
# blocked, so install without them. Its one dependency came with the main install above.
dnf -y install --setopt=tsflags=noscripts "$OSN_RPM"
rm "$UMU_RPM" "$OSN_RPM"

# No-telemetry: umu contacts Valve on every launch even with UMU_RUNTIME_UPDATE=0. Make "0" fully offline
# when the runtime is already installed (fennek-run-exe allows update checks at most once a day).
python3 - <<'EOF'
import glob, os, pathlib
def replace_file(p, text):
    """New file + atomic rename, never an in-place write: in-place edits of (hardlinked) base-image files can
    come out as old bytes padded with zeros on some overlay storage (seen with podman-in-docker)."""
    tmp = p.with_name(p.name + ".fennek-new")
    tmp.write_text(text)
    os.chmod(tmp, p.stat().st_mode & 0o7777)
    os.replace(tmp, p)
p = pathlib.Path(glob.glob("/usr/lib/python3*/site-packages/umu/umu_runtime.py")[0])
old = '    """Install or update the runtime for the current user."""\n'
new = old + ('    # Fennek OS patch: no network at all when updates are off and the runtime is present.\n'
             '    if os.environ.get("UMU_RUNTIME_UPDATE") == "0" and has_runtime_installed(local):\n'
             '        return\n')
s = p.read_text()
assert s.count(old) == 1, "umu changed upstream: revisit the Fennek OS no-telemetry patch"
replace_file(p, s.replace(old, new))
for pyc in glob.glob(str(p.parent / "__pycache__" / "umu_runtime.*.pyc")):
    os.remove(pyc)
EOF

# --- Fennek OS branding ---
# Name + logo. ID stays "fedora" so Fedora repos and tooling keep working.
sed -i -e 's/^NAME=.*/NAME="Fennek OS"/' \
       -e 's/^PRETTY_NAME=.*/PRETTY_NAME="Fennek OS (Fedora 44 base)"/' \
       -e 's/^LOGO=.*/LOGO=fennek/' \
       -e 's/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME="fennek"/' /usr/lib/os-release
if rpm -q plasma-welcome-fedora >/dev/null; then dnf -y remove plasma-welcome-fedora; fi   # "Fedora loves KDE" pages
# Wallpaper, generated at build time (no binaries in the repo).
mkdir -p /usr/share/wallpapers/Fennek/contents/images
magick -size 3840x2160 -define gradient:angle=135 gradient:'#16122b-#c8743a' \
    /usr/share/wallpapers/Fennek/contents/images/3840x2160.png
# Look-and-feel: Fedora's as base; our metadata + taskbar layout (from system_files) win.
lnf=/usr/share/plasma/look-and-feel/org.fennek.desktop
cp -an /usr/share/plasma/look-and-feel/org.fedoraproject.fedora.desktop/contents/. "$lnf/contents/"
sed -i 's/^Image=.*/Image=Fennek/' "$lnf/contents/defaults"
sed -i 's/^LookAndFeelPackage=.*/LookAndFeelPackage=org.fennek.desktop/' \
    /usr/share/kde-settings/kde-profile/default/xdg/kdeglobals
# /etc/xdg comes first in the lookup: Universal Blue's own default there silently won before (the VM showed
# KDE's stock panel, Kickoff and wallpaper). Merge our value into it (kwriteconfig6 writes new file + rename).
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key LookAndFeelPackage org.fennek.desktop
# Fennek icons (classic folders, own app icons; the rest inherits Breeze), also set by both Fennek themes.
kwriteconfig6 --file /etc/xdg/kdeglobals --group Icons --key Theme Fennek
printf '\n[kdeglobals][Icons]\nTheme=Fennek\n' >> "$lnf/contents/defaults"
gtk-update-icon-cache -f -t /usr/share/icons/Fennek 2>/dev/null || true
# Fennek OS Dark: same taskbar/Start layout, dark colors. Fedora's global themes go: picking one replaces the
# Fennek taskbar and Start menu with Fedora's layout (looks like the desktop got "erased").
dark=/usr/share/plasma/look-and-feel/org.fennek.dark.desktop
cp -a "$lnf/contents/." "$dark/contents/"
{ sed '/^ColorScheme=/d' "$lnf/contents/defaults"; printf '\n[kdeglobals][General]\nColorScheme=BreezeDark\n'; } \
    > "$dark/contents/defaults"
rm -rf /usr/share/plasma/look-and-feel/org.fedoraproject.*
# Window frame per theme: Fennek Classic (white title bar) / Fennek Classic Dark, generated from it by color swap.
fc=/usr/share/aurorae/themes/FennekClassic; fcd=/usr/share/aurorae/themes/FennekClassicDark
mkdir -p "$fcd"
for f in decoration minimize maximize restore close; do
    # title/background white -> near black; glyphs black -> white; hover/pressed grays darker. Close stays red.
    sed -e 's/fill="#fff"/fill="#202020"/g' -e 's/stroke="#000000"/stroke="#ffffff"/g' \
        -e 's/fill="#e5e5e5"/fill="#3a3a3a"/g' -e 's/fill="#cccccc"/fill="#505050"/g' "$fc/$f.svg" > "$fcd/$f.svg"
done
sed -e 's/^ActiveTextColor=.*/ActiveTextColor=255,255,255,255/' "$fc/FennekClassicrc" > "$fcd/FennekClassicDarkrc"
sed -e 's/^Name=.*/Name=Fennek Classic Dark/' -e 's/^X-KDE-PluginInfo-Name=.*/X-KDE-PluginInfo-Name=FennekClassicDark/' \
    "$fc/metadata.desktop" > "$fcd/metadata.desktop"
for t in "$lnf:FennekClassic" "$dark:FennekClassicDark"; do
    printf '\n[kwinrc][org.kde.kdecoration2]\nlibrary=org.kde.kwin.aurorae.v2\ntheme=__aurorae__svg__%s\n' "${t#*:}" \
        >> "${t%%:*}/contents/defaults"
done
# Comfort: the mouse wheel scrolls the page; it never changes a dropdown, number box or slider you happen to
# pass over (KDE's default). Values change by click, drag or keyboard only. Patches KDE's control style.
python3 - <<'EOF'
import glob, os, pathlib
def replace_file(p, text):
    """New file + atomic rename, never an in-place write: in-place edits of (hardlinked) base-image files can
    come out as old bytes padded with zeros on some overlay storage (seen with podman-in-docker)."""
    tmp = p.with_name(p.name + ".fennek-new")
    tmp.write_text(text)
    os.chmod(tmp, p.stat().st_mode & 0o7777)
    os.replace(tmp, p)
d = pathlib.Path(glob.glob("/usr/lib*/qt6/qml/org/kde/desktop")[0])
for name in ("ComboBox.qml", "SpinBox.qml", "DoubleSpinBox.qml"):
    p = d / name
    if name == "DoubleSpinBox.qml" and not p.exists():   # newer KDE dropped it; the other two are required
        continue
    s = p.read_text()
    assert s.count("    wheelEnabled: true\n") == 1, f"{name} changed upstream: revisit the Fennek wheel patch"
    replace_file(p, s.replace("    wheelEnabled: true\n", "    wheelEnabled: false  // Fennek OS: wheel scrolls the page\n"))
p = d / "Slider.qml"; s = p.read_text()
old = "onWheel: wheel => {\n"
assert s.count(old) == 1, "Slider.qml changed upstream: revisit the Fennek wheel patch"
replace_file(p, s.replace(old, old + "                wheel.accepted = false; return;  // Fennek OS: wheel scrolls the page\n"))
EOF

# familiar shortcuts, added to KDE's own: Ctrl+Shift+Esc = Task Manager (System Monitor, renamed), Super+R = Run,
# Super+E = File Explorer.
python3 - <<'EOF'
import os, pathlib, re
def replace_file(p, text):
    tmp = p.with_name(p.name + ".fennek-new"); tmp.write_text(text); os.chmod(tmp, 0o644); os.replace(tmp, p)
def add_shortcut(name, shortcut, rename=None):
    # Plasma 6 keeps global-shortcut owners in kglobalaccel/, launchable apps in applications/.
    found = [p for d in ("/usr/share/kglobalaccel", "/usr/share/applications") if (p := pathlib.Path(d, name)).exists()]
    assert found, f"{name} missing: revisit the Fennek shortcuts patch"
    for p in found:
        _add(p, shortcut, rename)
def _add(p, shortcut, rename):
    head, sep, rest = p.read_text().partition("\n[Desktop Action")   # only touch the main [Desktop Entry] group
    m = re.search(r"^X-KDE-Shortcuts=(.*)$", head, re.M)
    if m:
        keys = [k for k in m.group(1).split(",") if k]
        if shortcut not in keys:
            head = head[:m.start()] + "X-KDE-Shortcuts=" + ",".join([shortcut] + keys) + head[m.end():]
    else:
        head = head.replace("[Desktop Entry]\n", f"[Desktop Entry]\nX-KDE-Shortcuts={shortcut}\n", 1)
    if rename:
        head = re.sub(r"^Name=.*$", f"Name={rename}", head, count=1, flags=re.M)
    replace_file(p, head + sep + rest)
add_shortcut("org.kde.plasma-systemmonitor.desktop", "Ctrl+Shift+Esc", rename="Task Manager")
add_shortcut("org.kde.krunner.desktop", "Meta+R")
add_shortcut("org.kde.dolphin.desktop", "Meta+E")
# Super+I opens Fennek Settings (fennek-settings.desktop) instead of KDE's System Settings.
for name in ("systemsettings.desktop",):
    for d in ("/usr/share/kglobalaccel", "/usr/share/applications"):
        p = pathlib.Path(d, name)
        if p.exists():
            t = p.read_text()
            t = re.sub(r"^(X-KDE-Shortcuts=.*)$", lambda m: m.group(1).replace("Meta+I", "").replace(",,", ",").rstrip(",").replace("=,", "="), t, flags=re.M)
            replace_file(p, t)
EOF

# Dolphin shows up as "Files" (English name; translations keep their own).
sed -i 's/^Name=Dolphin$/Name=Files/' /usr/share/applications/org.kde.dolphin.desktop
# Toolbar layouts. KDE apps compile their menu/toolbar layout (KXMLGUI .rc) into the program; take that copy,
# change only a toolbar and install it with a higher version (KXMLGUI loads the newest), so the menus always
# stay the ones the installed app ships.
#   Files: Back, Forward, Up, address bar, search.
#   Terminal: no "New tab / Split view / Copy / Paste" toolbars; tabs on top like a classic terminal app.
cat > /tmp/xmlgui.py <<'PYEOF'
import pathlib, re, sys, zlib
component, guiname, rcfile, edit, *binaries = sys.argv[1:]
gui = rf'<gui name="{re.escape(guiname)}" version="(\d+)"'.encode()
def candidates(raw):
    data = memoryview(raw)  # slices without copying
    try:
        from compression import zstd
        for m in re.finditer(rb"\x28\xb5\x2f\xfd", data):
            try: yield zstd.ZstdDecompressor().decompress(data[m.start():m.start() + 4_000_000])
            except Exception: pass
    except ImportError:
        pass
    for m in re.finditer(rb"\x78[\x01\x5e\x9c\xda]", data):
        try: yield zlib.decompressobj().decompress(data[m.start():m.start() + 4_000_000])
        except zlib.error: pass
    m = re.search(gui, raw)
    if m: yield raw[raw.rfind(b"<?xml", 0, m.start()):raw.find(b"</gui>", m.start()) + 6]
# Some apps also embed a phone layout (lower version): the desktop one has the highest version.
found = [c for b in binaries for c in candidates(pathlib.Path(b).read_bytes()) if re.search(gui, c) and b"</gui>" in c]
assert found, f"{component} layout ({rcfile}) not found in {binaries}"
rc = max(found, key=lambda c: int(re.search(gui, c).group(1)))
s = rc[:rc.find(b"</gui>") + 6].decode()
if edit == "files-toolbar":
    m = re.search(r'(<ToolBar[^>]*name="mainToolBar"[^>]*>\s*<text[^<]*</text>)(.*?)(\s*</ToolBar>)', s, re.S)
    assert m and 'name="go_back"' in m.group(2), "Files main toolbar changed upstream"
    acts = ("go_back", "go_forward", "go_up", "url_navigators", "toggle_search", "hamburger_menu")
    s = s[:m.start(2)] + "".join(f'\n        <Action name="{a}" />' for a in acts) + s[m.end(2):]
elif edit == "hide-toolbars":
    s, n = re.subn(r'<ToolBar(?![^>]*hidden=)', '<ToolBar hidden="true"', s)
    assert n, f"no toolbar in {rcfile}"
else:
    sys.exit(f"unknown edit {edit}")
s, n = re.subn(r'(<gui[^>]*\bversion=")(\d+)', lambda v: v.group(1) + str(int(v.group(2)) + 1000), s, count=1)
assert n == 1, f"{rcfile}: version not found"
out = pathlib.Path("/usr/share/kxmlgui5", component, rcfile)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(s)
PYEOF
python3 /tmp/xmlgui.py dolphin dolphin dolphinui.rc files-toolbar /usr/bin/dolphin
konsole_bins=(/usr/bin/konsole /usr/lib64/libkonsole*.so.*)
python3 /tmp/xmlgui.py konsole konsole konsoleui.rc hide-toolbars "${konsole_bins[@]}"
python3 /tmp/xmlgui.py konsole session sessionui.rc hide-toolbars "${konsole_bins[@]}"
rm /tmp/xmlgui.py
# Login screen wallpaper.
sed -i 's|/usr/share/wallpapers/Fedora/|/usr/share/wallpapers/Fennek/|g' /usr/lib/plasmalogin/defaults.conf
# Boot splash watermark (bgrt theme reads spinner's images). rm first: the file is hardlinked.
wm=/usr/share/plymouth/themes/spinner/watermark.png
(cd /tmp && magick -background none -density 384 /usr/share/icons/hicolor/scalable/apps/fennek.svg -resize 72x72 l.png &&
    magick -background none -fill white -font Noto-Sans-Medium -pointsize 44 label:"Fennek OS" t.png &&
    rm -f "$wm" && magick l.png t.png -background none -gravity center +smush 18 +repage -depth 8 "$wm" && rm l.png t.png)
# The splash lives in the initramfs, so rebuild it.
KVER=$(ls /usr/lib/modules)
dracut --no-hostonly --kver "$KVER" --reproducible --add ostree -f "/usr/lib/modules/$KVER/initramfs.img"
chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"

# Permissions: everything we ship is 644, except our programs.
(cd "$files" && find . -type f) | while read -r f; do chmod 644 "/${f#./}"; chown root:root "/${f#./}"; done
# Belt and braces: everything we ship belongs to root (a build-context owner would be a local root hole).
(cd "$files" && find . -mindepth 1 -type d) | while read -r d; do chown root:root "/${d#./}"; done
chmod 755 /usr/bin/fennek-* /usr/libexec/fennek-*

# Hourly home snapshots (ransomware undo), set up on first boot.
systemctl enable fennek-home-snapshots.service snapper-timeline.timer snapper-cleanup.timer

# Firewall: incoming blocked except what the desktop needs (Fedora's default zone opens ports 1025-65535).
sed -i 's/^DefaultZone=.*/DefaultZone=FennekOS/' /etc/firewalld/firewalld.conf

# Antivirus: daily definitions, every user's Downloads scanned on arrival.
systemctl enable clamav-freshclam-once.timer
systemctl --global enable fennek-download-guard.service

# Battery: switch to the power-saver profile when unplugged (back to balanced on AC), dim and turn the screen
# off sooner on battery. System-wide PowerDevil defaults, merged (kwriteconfig6), users can still change them.
# Power profiles need a provider (Fedora's default is tuned-ppd); add it if the base has none.
rpm -q tuned-ppd >/dev/null || rpm -q power-profiles-daemon >/dev/null || dnf -y install tuned-ppd
pd() { kwriteconfig6 --file /etc/xdg/powerdevilrc --group "$1" --group "$2" --key "$3" "$4"; }
for p in Battery LowBattery; do
    pd "$p" Performance PowerProfile power-saver
    pd "$p" Display DimDisplayWhenIdle true
    pd "$p" Display DimDisplayIdleTimeoutSec 120
    pd "$p" Display TurnOffDisplayWhenIdle true
    pd "$p" Display TurnOffDisplayIdleTimeoutSec 300
done
pd AC Performance PowerProfile balanced
pd AC Display TurnOffDisplayWhenIdle true
pd AC Display TurnOffDisplayIdleTimeoutSec 600

# Sign-in screen like the classic desktop. Plasma Login Manager's screens are compiled into the program; SDDM (KDE's
# long-standing login manager) takes QML themes: /usr/share/sddm/themes/fennek. Wayland greeter via KWin.
dnf -y install sddm sddm-wayland-plasma
systemctl disable plasmalogin.service 2>/dev/null || true
systemctl enable -f sddm.service
mkdir -p /etc/sddm.conf.d
cat >/etc/sddm.conf.d/10-fennek.conf <<'EOF'
[Theme]
Current=fennek
EOF

# Dual boot: "Restart to Windows" appears when a Windows boot entry exists.
systemctl enable fennek-detect-windows.service

# Instant file search (Everything-style), feeds the Start menu / KRunner.
systemctl --global enable fennek-search.service

# zsh is the default shell for new users, with suggestions + highlighting + Fennek OS aliases.
sed -i 's|^SHELL=.*|SHELL=/bin/zsh|' /etc/default/useradd
# New file + rename, not an in-place append (see replace_file above).
{ cat /etc/zshrc; cat <<'EOF'

# Fennek OS
source /etc/profile.d/fennek-aliases.sh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
EOF
} > /etc/zshrc.fennek-new && chmod 644 /etc/zshrc.fennek-new && mv /etc/zshrc.fennek-new /etc/zshrc

# Updates: only accept Fennek images signed with our key (public key: /etc/pki/containers/fennek-cosign.pub).
python3 - <<'EOF'
import json, os, pathlib
p = pathlib.Path("/etc/containers/policy.json")
policy = json.loads(p.read_text())
policy.setdefault("transports", {}).setdefault("docker", {})["ghcr.io/olexify/fennekos"] = [{
    "type": "sigstoreSigned",
    "keyPath": "/etc/pki/containers/fennek-cosign.pub",
    "signedIdentity": {"type": "matchRepository"},
}]
tmp = p.with_name(p.name + ".fennek-new")      # new file + rename, never in place
tmp.write_text(json.dumps(policy, indent=2) + "\n")
os.chmod(tmp, 0o644)
os.replace(tmp, p)
EOF

# No telemetry: Fedora's weekly anonymous "countme" install counting (rpm-ostree timer + repo flag).
systemctl mask rpm-ostree-countme.timer rpm-ostree-countme.service
# Daily Fedora repo metadata download (unused on an atomic system: updates come as images) and the
# DNSSEC root-anchor refresh for unbound (not Fennek's resolver): needless connections, battery.
systemctl disable dnf-makecache.timer unbound-anchor.timer 2>/dev/null || true
sed -i 's/^countme=1/countme=0/' /etc/yum.repos.d/*.repo

# Updates download + stage in background, apply on next normal reboot. Never forced.
systemctl enable rpm-ostreed-automatic.timer

# Classic taskbar right-click menu (src/taskbar-menu): compiled here, build tools removed again.
tools=(cmake extra-cmake-modules gcc-c++ libplasma-devel kf6-kcoreaddons-devel kf6-kconfig-devel kf6-kwindowsystem-devel
       kf6-kpackage-devel kf6-kservice-devel qt6-qtbase-devel qt6-qtdeclarative-devel)
missing=(); for p in "${tools[@]}"; do rpm -q "$p" >/dev/null 2>&1 || missing+=("$p"); done
dnf -y install "${missing[@]}"
cmake -S "$files/../src/taskbar-menu" -B /tmp/taskbar-menu -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
cmake --build /tmp/taskbar-menu -j"$(nproc)"
cmake --install /tmp/taskbar-menu
rm -rf /tmp/taskbar-menu
[ ${#missing[@]} -eq 0 ] || dnf -y remove "${missing[@]}"
# Panels use it instead of Plasma's own panel menu (new file + rename, see replace_file).
shell=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/defaults
python3 - "$shell" <<'EOF'
import os, sys
p = sys.argv[1]; s = open(p).read()
old = "[Panel][ContainmentActions]\nRightButton;NoModifier=org.kde.contextmenu"
assert old in s, "Plasma shell defaults changed: revisit the taskbar menu"
open(p + ".fennek-new", "w").write(s.replace(old, "[Panel][ContainmentActions]\nRightButton;NoModifier=org.fennek.taskbarmenu"))
os.chmod(p + ".fennek-new", 0o644); os.replace(p + ".fennek-new", p)
EOF

# Leave no dnf state behind (bootc lint).
dnf clean all
rm -rf /run/dnf /var/log/dnf5.log /var/lib/dnf /var/cache/libdnf5 /var/cache/ldconfig
