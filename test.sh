#!/usr/bin/env bash
# Smoke test, run inside the built image: docker run --rm -v ./test.sh:/t.sh fennek:dev bash /t.sh
set -euo pipefail
fail() { echo "FAIL: $*"; exit 1; }

grep -q '^SHELL=/bin/zsh' /etc/default/useradd             || fail "default shell"
[ "$(zsh -ic 'alias dir' 2>/dev/null)" = "dir='ls -lah'" ]  || fail "zsh aliases"
[ "$(bash --rcfile /etc/skel/.bashrc -ic 'alias cls' 2>/dev/null)" = "alias cls='clear'" ] || fail "bash aliases"
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
[ "$(magick /usr/share/wallpapers/Fennek/contents/images/3840x2160.png -crop 1x1+3839+2159 -format '%[fx:r>b]' info:)" = 1 ] \
                                                              || fail "wallpaper isn't the warm dusk gradient"
grep -q '^Image=Fennek' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/defaults || fail "lnf wallpaper"
grep -q 'panel.height = 40' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "40 px taskbar"
grep -q '^ButtonsOnRight=IAX' /etc/xdg/kwinrc && grep -q '^LayoutName=thumbnail_grid' /etc/xdg/kwinrc || fail "Windows window buttons / Alt+Tab"
grep -q '^TitleAlignment=AlignLeft' /etc/xdg/breezerc                || fail "titles on the left"
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
grep -q '^Exec=fennek-firewall block %f' /usr/share/kio/servicemenus/fennek-firewall.desktop || fail "firewall menu"
[ -f /usr/share/plasma/plasmoids/com.github.zren.tiledmenu/metadata.json ] || fail "Win10 start menu (Tiled Menu)"
grep -q 'com.github.zren.tiledmenu' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "start menu in taskbar"
[ "$(systemctl is-enabled rpm-ostree-countme.timer 2>&1)" = masked ] || fail "countme telemetry timer"
! grep -q '^countme=1' /etc/yum.repos.d/*.repo                || fail "countme in repos"
! systemctl is-enabled -q dnf-makecache.timer 2>/dev/null      || fail "dnf-makecache timer (needless daily download)"
! systemctl is-enabled -q unbound-anchor.timer 2>/dev/null     || fail "unbound-anchor timer"
grep -q '^Name=File Explorer$' /usr/share/applications/org.kde.dolphin.desktop || fail "File Explorer name"
grep -q '^Name=Task Manager$' /usr/share/applications/org.kde.plasma-systemmonitor.desktop || fail "Task Manager name"
grep -q '^X-KDE-Shortcuts=.*Ctrl+Shift+Esc' /usr/share/applications/org.kde.plasma-systemmonitor.desktop || fail "Ctrl+Shift+Esc"
grep -qs '^X-KDE-Shortcuts=.*Meta+R' /usr/share/kglobalaccel/org.kde.krunner.desktop /usr/share/applications/org.kde.krunner.desktop || fail "Win+R"
grep -q '^ViewMode=1' /etc/skel/.local/share/dolphin/view_properties/global/.directory || fail "Explorer details view"
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
echo "--- privacy audit ---"
echo "enabled timers: $(systemctl list-unit-files --type=timer --state=enabled --no-legend 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
echo "user timers:    $(ls /etc/systemd/user/timers.target.wants/ 2>/dev/null | tr '\n' ' ')"
echo "NM connectivity: $(grep -rh '^uri=' /usr/lib/NetworkManager/conf.d/ /etc/NetworkManager/conf.d/ 2>/dev/null | tr '\n' ' ')"
echo "firefox: $(rpm -q firefox 2>/dev/null || echo 'not installed (rpm)')"
echo "--- end audit ---"
echo "all checks passed"
