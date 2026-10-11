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
grep -q '^Image=Fennek' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/defaults || fail "lnf wallpaper"
grep -q 'panel.floating = false' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "taskbar layout"
grep -q '^LookAndFeelPackage=org.fennek.desktop' /usr/share/kde-settings/kde-profile/default/xdg/kdeglobals || fail "default lnf"
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
echo "all checks passed"
