#!/usr/bin/env bash
# Smoke test, run inside the built image: docker run --rm -v ./test.sh:/t.sh fennek:dev bash /t.sh
set -euo pipefail
fail() { echo "FAIL: $*"; exit 1; }

grep -q '^SHELL=/bin/zsh' /etc/default/useradd             || fail "default shell"
[ "$(zsh -ic 'alias dir' 2>/dev/null)" = "dir='ls -lah'" ]  || fail "zsh aliases"
[ "$(bash --rcfile /etc/skel/.bashrc -ic 'alias cls' 2>/dev/null)" = "alias cls='clear'" ] || fail "bash aliases"
[ "$(zsh -ic 'a=$SAVEHIST; history-off >/dev/null; b=$SAVEHIST; history-on >/dev/null; print "$a $b $SAVEHIST"' 2>/dev/null)" = "10000 0 10000" ] \
                                                             || fail "terminal history on/off"
zsh -ic 'typeset -f _zsh_autosuggest_start' >/dev/null 2>&1 || fail "zsh autosuggestions"
command -v umu-run >/dev/null                                || fail "umu-run"
grep -q '^Exec=fennek-run-exe %f' /usr/share/applications/fennek-run-exe.desktop || fail "exe launcher"
fennek-run-exe --selftest >/dev/null                           || fail "run-exe selftest"
grep -q '^application/x-ms-dos-executable=fennek-run-exe.desktop' /etc/xdg/mimeapps.list || fail "exe default"
grep -q '^AutomaticUpdatePolicy=stage' /etc/rpm-ostreed.conf || fail "update policy"
[ -L /etc/systemd/system/timers.target.wants/rpm-ostreed-automatic.timer ] || fail "update timer"
grep -q 'Indexing-Enabled=false' /etc/xdg/baloofilerc        || fail "baloo off"
grep -q '^NAME="Fennek OS"' /usr/lib/os-release                 || fail "os-release name"
grep -q '^ID=fedora' /usr/lib/os-release                      || fail "os-release id must stay fedora"
! rpm -q plasma-welcome-fedora >/dev/null                     || fail "fedora welcome pages"
[ -s /usr/share/wallpapers/Fennek/contents/images/3840x2160.png ] || fail "wallpaper"
[ "$(magick /usr/share/wallpapers/Fennek/contents/images/3840x2160.png -crop 1x1+1920+1290 -format '%[fx:r>b && r>0.6]' info:)" = 1 ] \
                                                              || fail "wallpaper isn't the desert dusk (warm horizon)"
grep -q '^Image=Fennek' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/defaults || fail "lnf wallpaper"
grep -q "SystrayContainmentId" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "tray shown/hidden icons"
for p in org.fennek.searchbox org.fennek.taskview org.fennek.showdesktop org.fennek.volume org.fennek.clock org.fennek.network org.fennek.actioncenter; do
    python3 -c "import json; json.load(open('/usr/share/plasma/plasmoids/$p/metadata.json'))" && [ -s /usr/share/plasma/plasmoids/$p/contents/ui/main.qml ] \
        && grep -q "\"$p\"" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js \
        || fail "taskbar widget $p"
done
grep -q 'panel.hiding = "none"' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "taskbar always visible"
grep -q 'panel.height = 40' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "40 px taskbar"
grep -q '^ButtonsOnRight=IAX' /etc/xdg/kwinrc && grep -q '^LayoutName=thumbnail_grid' /etc/xdg/kwinrc || fail "classic window buttons / Alt+Tab"
grep -q '^TitleAlignment=AlignLeft' /etc/xdg/breezerc                || fail "titles on the left"
a=/usr/share/aurorae/themes/FennekClassic
grep -q '^theme=__aurorae__svg__FennekClassic' /etc/xdg/kwinrc && [ -f "$a/FennekClassicrc" ] || fail "Fennek Classic window frame"
lib=$(sed -n 's/^library=//p' /etc/xdg/kwinrc)
[ -f "/usr/lib64/qt6/plugins/org.kde.kdecoration3/$lib.so" ]      || fail "window frame engine $lib not installed"
grep -q '^Shadow=true' "$a/FennekClassicrc" && grep -q 'id="decoration-bottomright"' "$a/decoration.svg" || fail "window shadow"
for b in minimize maximize restore close; do grep -q 'id="hover-center"' "$a/$b.svg" || fail "frame button $b"; done
grep -q 'id="decoration-top"' "$a/decoration.svg" && grep -q 'id="decoration-inactive-top"' "$a/decoration.svg" || fail "frame svg"
grep -q '^BorderlessMaximizedWindows=false' /etc/xdg/kwinrc       || fail "title bar on maximized windows"
r=/usr/share/kxmlgui5/dolphin/dolphinui.rc
grep -q 'name="go_up"' "$r" && grep -q 'version="10[0-9][0-9]"' "$r" && grep -q '<Menu' "$r" || fail "Files toolbar (Back/Forward/Up)"
python3 -c "import sys, xml.dom.minidom as x; x.parse(sys.argv[1])" "$r"   || fail "Files toolbar file is not valid XML"
grep -q '"Id": "org.fennek.firewall"' /usr/share/plasma/plasmoids/org.fennek.firewall/metadata.json && grep -q '^Exec=plasmawindowed org.fennek.firewall' /usr/share/applications/fennek-firewall.desktop || fail "Firewall window"
fennek-firewall list --json | python3 -c 'import json,sys; assert json.load(sys.stdin) == []' || fail "firewall list --json"
grep -qF "fennek-firewall profile [home|public]" /usr/bin/fennek-firewall || fail "firewall network profile command"
[ -x /usr/libexec/fennek-first-login ] && grep -q '^Exec=/usr/libexec/fennek-first-login' /etc/xdg/autostart/fennek-first-login.desktop || fail "first-login Fennek look"
cmp -s /usr/share/plasma/look-and-feel/org.fennek.{desktop,dark.desktop}/contents/layouts/org.kde.plasma.desktop-layout.js || fail "Fennek Dark has the Fennek layout"
grep -q "^startPage=applications.page" /etc/xdg/systemmonitorrc || fail "Task Manager opens on apps"
[ -f /usr/share/icons/Fennek/scalable/places/folder.svg ] && [ -f /usr/share/icons/Fennek/scalable/apps/org.kde.dolphin.svg ] && [ -f /usr/share/icons/hicolor/scalable/apps/fennek-firewall.svg ] && [ "$(kreadconfig6 --file /etc/xdg/kdeglobals --group Icons --key Theme)" = Fennek ] && grep -q "^Theme=Fennek" /usr/share/plasma/look-and-feel/org.fennek.dark.desktop/contents/defaults || fail "Fennek icons"
grep -q "Ctrl+Shift+V; Ctrl+V" /usr/share/kxmlgui5/konsole/sessionui.rc && grep -q "hidden=\"true\" name=\"sessionToolbar\"" /usr/share/kxmlgui5/konsole/sessionui.rc && grep -q "hidden=\"true\" name=\"mainToolBar\"" /usr/share/kxmlgui5/konsole/konsoleui.rc && grep -q "^TabBarVisibility=AlwaysShowTabBar" /etc/xdg/konsolerc || fail "Terminal: classic tabs, no toolbars"
ls /usr/lib64/qt6/plugins/plasma/containmentactions/org.fennek.taskbarmenu.so /usr/lib64/qt6/plugins/kf6/kio/kio_thispc.so >/dev/null && grep -q "^RightButton;NoModifier=org.fennek.taskbarmenu" /usr/share/plasma/shells/org.kde.plasma.desktop/contents/defaults && ! rpm -q gcc-c++ >/dev/null || fail "taskbar menu + This PC plugins (and no compiler left in the image)"
grep -q "^AccentColor=109,69,184" /etc/xdg/kdeglobals && grep -q "sidebarFollowsTheme\", true" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "Fennek accent colour + visible Start strip"
grep -q "^ExpandableFolders=false" /etc/xdg/dolphinrc && grep -q "browser.tabs.inTitlebar" /etc/firefox/policies/policies.json || fail "classic details rows + Firefox system title bar"
[ -f /usr/share/icons/Bibata-Modern-Ice/cursors/left_ptr ] && grep -q "^cursorTheme=Bibata-Modern-Ice" /etc/xdg/kcminputrc && grep -q "^CursorTheme=Bibata-Modern-Ice" /etc/sddm.conf.d/10-fennek.conf || fail "Bibata cursor default"
grep -q "^font=Inter,10" /etc/xdg/kdeglobals && grep -q "^fixed=Cascadia Mono" /etc/xdg/kdeglobals && [ -n "$(fc-list :family=Inter)" ] && [ -n "$(fc-list ':family=Cascadia Mono')" ] || fail "Inter + Cascadia Mono fonts"
grep -q "^DefaultProfile=Fennek.profile" /etc/xdg/konsolerc && grep -q "^ColorScheme=Fennek" /usr/share/konsole/Fennek.profile && [ -s /usr/share/konsole/Fennek.colorscheme ] || fail "Fennek terminal profile"
grep -q "Fennek OS: a personal greeting" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/lockscreen/LockScreenUi.qml && grep -q "Fennek" /etc/xdg/kscreenlockerrc || fail "lock screen greeting + wallpaper"
grep -q "^LastSeenVersion=99" /etc/xdg/plasma-welcomerc || fail "only one welcome window"
[ -s /usr/share/plasma/plasmoids/org.fennek.welcome/contents/ui/main.qml ] && grep -q "^Exec=plasmawindowed org.fennek.welcome" /usr/share/applications/fennek-welcome.desktop && grep -q "org.fennek.welcome" /usr/libexec/fennek-first-login || fail "welcome app"
grep -q "^ColorScheme=BreezeDark" /usr/share/plasma/look-and-feel/org.fennek.dark.desktop/contents/defaults || fail "Fennek Dark colors"
grep -q "^theme=__aurorae__svg__FennekClassicDark" /usr/share/plasma/look-and-feel/org.fennek.dark.desktop/contents/defaults && grep -q "^theme=__aurorae__svg__FennekClassic$" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/defaults && grep -q "fill=\"#202020\"" /usr/share/aurorae/themes/FennekClassicDark/decoration.svg && [ -s /usr/share/aurorae/themes/FennekClassicDark/FennekClassicDarkrc ] || fail "window frame follows light/dark theme"
! ls -d /usr/share/plasma/look-and-feel/org.fedoraproject.* 2>/dev/null || fail "Fedora global themes still listed"
! ls /usr/share/plasma/look-and-feel/org.kde.breeze*/contents/defaults 2>/dev/null || fail "KDE global themes still listed"
grep -q '^HomeUrl=thispc:/' /etc/xdg/dolphinrc && grep -q 'GroupedSorting=true' /etc/skel/.local/share/dolphin/view_properties/remote/.directory \
    && grep -q 'inode/x-fennek-drive' /usr/share/mime/types || fail "This PC page"
grep -q '^MenuBar=Enabled' /etc/xdg/dolphinrc                     || fail "Files menu bar"
grep -q 'panel.floating = false' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "taskbar layout"
grep -q '^LookAndFeelPackage=org.fennek.desktop' /usr/share/kde-settings/kde-profile/default/xdg/kdeglobals || fail "default lnf"
# What a fresh user actually gets: every kdeglobals in the system lookup must agree on Fennek's look.
for f in /etc/xdg/kdeglobals /usr/share/kde-settings/kde-profile/default/xdg/kdeglobals; do
    v=$(grep -h '^LookAndFeelPackage=' "$f" 2>/dev/null | tail -1)
    [ -z "$v" ] || [ "$v" = "LookAndFeelPackage=org.fennek.desktop" ] || fail "$f overrides the look: $v"
done
[ "$(XDG_CONFIG_DIRS=/etc/xdg:/usr/share/kde-settings/kde-profile/default/xdg HOME=$(mktemp -d) kreadconfig6 --group KDE --key LookAndFeelPackage)" = org.fennek.desktop ] \
                                                              || fail "a new user wouldn't get the Fennek look"
[ -x /usr/bin/fennek-vt-check ]                               || fail "vt-check executable"
fennek-vt-check --selftest >/dev/null                          || fail "vt-check selftest"
grep -q '^Exec=fennek-vt-check %F' /usr/share/kio/servicemenus/fennek-virustotal.desktop || fail "vt service menu"
command -v snapper >/dev/null                                || fail "snapper"
[ -x /usr/libexec/fennek-home-snapshots ]                      || fail "snapshot setup script"
bash -n /usr/libexec/fennek-home-snapshots                     || fail "snapshot script syntax"
for u in fennek-home-snapshots.service snapper-timeline.timer snapper-cleanup.timer; do
    systemctl is-enabled -q "$u"                              || fail "$u not enabled"
done
[ "$(stat -c %a /usr/lib/systemd/system/fennek-home-snapshots.service)" = 644 ] || fail "unit file perms"
grep -q 'wallpapers/Fennek/' /usr/lib/plasmalogin/defaults.conf || fail "login wallpaper"
wm=usr/share/plymouth/themes/spinner/watermark.png; img=$(ls /usr/lib/modules/*/initramfs.img)
[ "$(lsinitrd -f "$wm" "$img" | md5sum)" = "$(md5sum < "/$wm")" ] || fail "initramfs has Fennek OS splash"
{ rpm -V fedora-logos 2>/dev/null || true; } | grep -q "/$wm$" || fail "watermark still Fedora's"
/usr/libexec/fennek-download-guard --selftest >/dev/null    || fail "download guard selftest"
fennek-usage --selftest >/dev/null && [ -L /etc/systemd/user/default.target.wants/fennek-usage.service ] || fail "usage history"
grep -q "^Exec=plasmawindowed org.fennek.apphistory" /usr/share/applications/fennek-apphistory.desktop && [ -s /usr/share/plasma/plasmoids/org.fennek.apphistory/contents/ui/main.qml ] || fail "App history window"
bash -n /usr/libexec/fennek-brightness && [ -x /usr/libexec/fennek-brightness ] || fail "brightness helper"
# Download guard: a sample matching a custom signature goes to quarantine, a clean file stays.
t=$(mktemp -d); mkdir -p "$t/db"
echo "Fennek OS fake malware sample" > "$t/evil.bin"; echo "harmless" > "$t/ok.txt"
sigtool --md5 "$t/evil.bin" > "$t/db/test.hdb"
HOME=$t XDG_DATA_HOME=$t/share FENNEK_CLAM_DB=$t/db /usr/libexec/fennek-download-guard "$t/evil.bin" "$t/ok.txt" >/dev/null
[ ! -e "$t/evil.bin" ] && compgen -G "$t/share/fennek/quarantine/*-evil.bin" >/dev/null || fail "threat not quarantined"
[ -e "$t/ok.txt" ]                                            || fail "clean file was touched"
tr '\0' '\n' < "$(compgen -G "$t/share/fennek/quarantine/*-evil.bin.fennek-info")" | grep -q "$t/evil.bin" \
                                                              || fail "quarantine doesn't record where the file came from"
rm -rf "$t"
# Watch mode: a file landing in Downloads gets scanned, even with a newline in its name.
t=$(mktemp -d); mkdir -p "$t/db" "$t/Downloads"
echo "Fennek fake malware sample" > "$t/sample"; sigtool --md5 "$t/sample" > "$t/db/test.hdb"
HOME=$t XDG_DATA_HOME=$t/share FENNEK_CLAM_DB=$t/db timeout 20 /usr/libexec/fennek-download-guard >/dev/null &
sleep 2; cp "$t/sample" "$t/Downloads/evil"$'\n'"name.bin"
for _ in $(seq 30); do compgen -G "$t/share/fennek/quarantine/*evil*" >/dev/null && break; sleep 0.5; done
compgen -G "$t/share/fennek/quarantine/*evil*" >/dev/null     || fail "watch mode didn't quarantine"
kill %1 2>/dev/null; wait 2>/dev/null; rm -rf "$t"
systemctl is-enabled -q clamav-freshclam-once.timer          || fail "freshclam timer"
[ -L /etc/systemd/user/default.target.wants/fennek-download-guard.service ] || fail "download guard not enabled"
grep -q "Fennek OS patch: no network" /usr/lib/python3*/site-packages/umu/umu_runtime.py || fail "umu no-telemetry patch"
python3 -c "import umu.umu_runtime" 2>/dev/null                || fail "patched umu imports"
[ "$(firewall-offline-cmd --get-default-zone 2>/dev/null)" = FennekOS ] || fail "default firewall zone"
[ -z "$(firewall-offline-cmd --zone=FennekOS --list-ports 2>/dev/null)" ] || fail "FennekOS zone opens ports"
[ "$(firewall-offline-cmd --zone=FennekOS-Public --list-services 2>/dev/null)" = dhcpv6-client ] || fail "public zone"
command -v opensnitchd >/dev/null                            || fail "opensnitchd"
! systemctl is-enabled -q opensnitch.service                  || fail "opensnitch must start only when something is blocked"
fennek-firewall --selftest >/dev/null                         || fail "firewall selftest"
/usr/libexec/fennek-first-login-places --selftest >/dev/null || fail "classic Files sidebar"
/usr/libexec/fennek-first-login-keyboard --selftest >/dev/null || fail "language switcher labels"
/usr/libexec/fennek-pin-quick-access --selftest >/dev/null && grep -q "^Exec=/usr/libexec/fennek-pin-quick-access" /usr/share/kio/servicemenus/fennek-pin-quick-access.desktop || fail "Pin to Quick access"
/usr/libexec/fennek-previous-versions-helper --selftest >/dev/null && command -v kdialog numfmt >/dev/null && grep -q "exec.path\">/usr/libexec/fennek-previous-versions-helper" /usr/share/polkit-1/actions/org.fennek.previous-versions.policy || fail "Restore previous versions"
grep -q '^Exec=fennek-firewall block %f' /usr/share/kio/servicemenus/fennek-firewall.desktop || fail "firewall menu"
[ -f /usr/share/plasma/plasmoids/com.github.zren.tiledmenu/metadata.json ] || fail "classic start menu (Tiled Menu)"
grep -q 'com.github.zren.tiledmenu' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "start menu in taskbar"
[ "$(systemctl is-enabled rpm-ostree-countme.timer 2>&1)" = masked ] || fail "countme telemetry timer"
! grep -q '^countme=1' /etc/yum.repos.d/*.repo                || fail "countme in repos"
! systemctl is-enabled -q dnf-makecache.timer 2>/dev/null      || fail "dnf-makecache timer (needless daily download)"
! systemctl is-enabled -q unbound-anchor.timer 2>/dev/null     || fail "unbound-anchor timer"
rpm -q firefox >/dev/null && grep -q '"DisableTelemetry": true' /etc/firefox/policies/policies.json || fail "Firefox + privacy policy"
grep -q '^Name=Files$' /usr/share/applications/org.kde.dolphin.desktop || fail "Files name"
grep -q '^Name=Task Manager$' /usr/share/applications/org.kde.plasma-systemmonitor.desktop || fail "Task Manager name"
grep -q '^X-KDE-Shortcuts=.*Ctrl+Shift+Esc' /usr/share/applications/org.kde.plasma-systemmonitor.desktop || fail "Ctrl+Shift+Esc"
grep -qs '^X-KDE-Shortcuts=.*Meta+R' /usr/share/kglobalaccel/org.kde.krunner.desktop /usr/share/applications/org.kde.krunner.desktop || fail "Win+R"
grep -q '^X-KDE-Shortcuts=.*Meta+E' /usr/share/kglobalaccel/org.kde.dolphin.desktop || fail "Super+E opens File Explorer"
grep -q '^ViewMode=1' /etc/skel/.local/share/dolphin/view_properties/global/.directory || fail "Files details view"
q=$(ls -d /usr/lib*/qt6/qml/org/kde/desktop | head -1)
grep -q "wheelEnabled: false  // Fennek" "$q/ComboBox.qml" && grep -q "wheelEnabled: false  // Fennek" "$q/SpinBox.qml" \
    && grep -q "wheel.accepted = false; return;  // Fennek" "$q/Slider.qml" || fail "mouse-wheel comfort patch"
for f in "$q/ComboBox.qml" "$q/SpinBox.qml" "$q/Slider.qml" /usr/lib/python3*/site-packages/umu/umu_runtime.py /etc/zshrc; do
    [ "$(tr -d '\000' < "$f" | wc -c)" = "$(wc -c < "$f")" ] || fail "$f has zero bytes (broken in-place edit)"
done
id fsearch >/dev/null 2>&1 || useradd -m fsearch >/dev/null 2>&1
su fsearch -c "/usr/libexec/fennek-search --selftest" >/dev/null || fail "search selftest"
[ -L /etc/systemd/user/graphical-session.target.wants/fennek-search.service ] || fail "search service not enabled"
grep -q '^X-Plasma-DBusRunner-Service=org.fennek.Search' /usr/share/krunner/dbusplugins/fennek-search.desktop || fail "search runner"
for f in /usr/bin/fennek-* /usr/libexec/fennek-* /usr/lib/systemd/system/fennek-* /usr/share/plasma/plasmoids/com.github.zren.tiledmenu; do
    [ "$(stat -c %u:%g "$f")" = 0:0 ] || fail "$f not owned by root"
done
python3 -c "
import json; d = json.load(open('/etc/containers/policy.json'))['transports']['docker']['ghcr.io/olexify/fennekos'][0]
assert d['type'] == 'sigstoreSigned' and d['keyPath'] == '/etc/pki/containers/fennek-cosign.pub'
" 2>/dev/null                                                 || fail "updates must require Fennek's signature"
grep -q 'BEGIN PUBLIC KEY' /etc/pki/containers/fennek-cosign.pub || fail "Fennek public key"
grep -q '"rhgb", "quiet"' /usr/lib/bootc/kargs.d/10-fennek-splash.toml || fail "boot splash kernel args"
python3 -c "import json; p=json.load(open('/etc/firefox/policies/policies.json'))['policies']; assert p['DisableTelemetry'] and p['DisableFirefoxStudies']" \
                                                              || fail "Firefox telemetry policy"

# Privacy audit (informational, printed in CI logs): everything that could connect out. Keep PRIVACY.md in sync.
id fquar >/dev/null 2>&1 || useradd -m fquar >/dev/null 2>&1
su fquar -c "fennek-quarantine --selftest" >/dev/null           || fail "quarantine selftest"
command -v efibootmgr >/dev/null                             || fail "efibootmgr (Restart to Windows)"
/usr/libexec/fennek-reboot-windows-helper --selftest >/dev/null || fail "reboot-windows selftest"
systemctl is-enabled -q fennek-detect-windows.service         || fail "windows detection not enabled"
grep -q 'exec.path">/usr/libexec/fennek-reboot-windows-helper' /usr/share/polkit-1/actions/org.fennek.reboot-windows.policy \
                                                              || fail "reboot-windows polkit action"
# Sign-in screen: SDDM is THE display manager, uses the Fennek theme, and the theme loads without QML errors
# (a broken greeter means nobody can log in).
[ "$(readlink -f /etc/systemd/system/display-manager.service)" = /usr/lib/systemd/system/sddm.service ] || fail "display manager isn't SDDM"
grep -q '^Current=fennek' /etc/sddm.conf.d/10-fennek.conf                || fail "SDDM theme not selected"
greeter=$(command -v sddm-greeter-qt6 || command -v sddm-greeter)
# The test-mode greeter runs until stopped: timeout (exit 124) is expected; only QML errors count.
out=$(QT_QPA_PLATFORM=offscreen timeout 15 "$greeter" --test-mode --theme /usr/share/sddm/themes/fennek 2>&1 || true)
! grep -iE "qml.*(error|is not a type|not installed|unavailable|ReferenceError|TypeError)|file:///usr/share/sddm/themes/fennek/.*:[0-9]+" <<<"$out" \
                                                              || { echo "$out" | grep -iE "qml|fennek" | head; fail "SDDM theme has QML errors"; }
# Start menu default tiles: every tile must point to an installed app (no blank tiles).
python3 - <<'PY' || fail "Start menu tile points to a missing app"
import base64, json, os, re
js = open("/usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js").read()
tiles = json.loads(base64.b64decode(re.search(r'writeConfig\("tileModel", "([^"]+)"\)', js).group(1)))
missing = [t["url"] for t in tiles if "url" in t and not os.path.exists("/usr/share/applications/" + t["url"])]
assert not missing, missing
assert sum(1 for t in tiles if t.get("tileType") == "group") >= 2
PY
# Fennek Settings: every page it links to exists (no dead buttons); Super+I belongs to it alone.
command -v plasmawindowed >/dev/null                          || fail "plasmawindowed (runs Fennek Settings)"
python3 - <<'PY' || fail "Fennek Settings links to something that isn't installed"
import glob, json, os, re, shutil
src = open("/usr/share/plasma/plasmoids/org.fennek.settings/contents/ui/catalog.js").read()
cats = json.loads(src[src.index("["):])
kcms = {os.path.basename(p)[:-3] for p in glob.glob("/usr/lib64/qt6/plugins/plasma/kcms/**/*.so", recursive=True)}
bad = []
for c in cats:
    for i in c["items"]:
        if "kcm" in i and i["kcm"] not in kcms: bad.append(i["kcm"])
        if "cmd" in i and not shutil.which(i["cmd"].split()[0]): bad.append(i["cmd"])
assert not bad, bad
PY
grep -q '^X-KDE-Shortcuts=Meta+I' /usr/share/applications/fennek-settings.desktop || fail "Super+I for Settings"
! grep -hs '^X-KDE-Shortcuts=.*Meta+I' /usr/share/kglobalaccel/systemsettings.desktop /usr/share/applications/systemsettings.desktop \
                                                              || fail "Super+I still on KDE System Settings too"
# Battery defaults: power-saver on battery, balanced on AC (needs a power-profiles provider, e.g. tuned-ppd).
[ "$(kreadconfig6 --file /etc/xdg/powerdevilrc --group Battery --group Performance --key PowerProfile)" = power-saver ] \
                                                              || fail "power-saver profile on battery"
[ "$(kreadconfig6 --file /etc/xdg/powerdevilrc --group AC --group Performance --key PowerProfile)" = balanced ] || fail "balanced on AC"
{ rpm -q tuned-ppd >/dev/null || rpm -q power-profiles-daemon >/dev/null; } || fail "no power-profiles provider"
echo "--- privacy audit ---"
echo "enabled timers: $(systemctl list-unit-files --type=timer --state=enabled --no-legend 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
echo "user timers:    $(ls /etc/systemd/user/timers.target.wants/ 2>/dev/null | tr '\n' ' ')"
echo "NM connectivity: $(grep -rh '^uri=' /usr/lib/NetworkManager/conf.d/ /etc/NetworkManager/conf.d/ 2>/dev/null | tr '\n' ' ')"
echo "firefox: $(rpm -q firefox 2>/dev/null || echo 'not installed (rpm)')"
echo "--- end audit ---"
echo "all checks passed"
