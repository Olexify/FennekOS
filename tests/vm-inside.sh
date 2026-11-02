#!/bin/bash
# Inside the test VM, as root (started by the unit tests/vm-test.sh injects). Talks to the host through files in /run/t/out.
out=/run/t/out
user=anna

if [ "${1:-}" = setup ]; then
    exec >"$out/setup.log" 2>&1
    useradd -m -c "Anna" "$user" && echo "$user:fennek-vm-test" | chpasswd
    touch /etc/plasma-setup-done   # the account exists: no first-run account wizard
    mkdir -p /etc/plasmalogin.conf.d
    printf '[Autologin]\nUser=%s\nSession=plasma\n' "$user" > /etc/plasmalogin.conf.d/10-vmtest.conf
    touch "$out/setup-done"
    systemd-run --unit=fennek-vmtest-watch --no-block bash /run/t/vm-inside.sh watch
    exit 0
fi

exec >"$out/watch.log" 2>&1
uid=$(id -u "$user")
as_user() { runuser -u "$user" -- env XDG_RUNTIME_DIR="/run/user/$uid" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" WAYLAND_DISPLAY=wayland-0 "$@"; }
wait_file() { for ((i = 0; i < $2; i++)); do [ -e "$out/$1" ] && return 0; sleep 1; done; return 1; }

for ((i = 0; i < 280; i++)); do
    pgrep -u "$user" -x plasmashell >/dev/null && { touch "$out/session-up"; break; }
    sleep 1
done
# The first sign-in's own steps, then Welcome opens by itself.
for ((i = 0; i < 180; i++)); do
    [ -e "/home/$user/.config/fennek/first-login-done" ] && pgrep -u "$user" -f 'fennek-app welcome' >/dev/null && { sleep 15; touch "$out/desktop-settled"; break; }
    sleep 1
done
wait_file go-start 120
pkill -u "$user" -f 'fennek-app welcome'
sleep 3
as_user gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.activateLauncherMenu
touch "$out/start-open"
wait_file go-report 120

problems=()
check() { "${@:2}" >/dev/null 2>&1 || problems+=("$1"); }
check "window manager running" pgrep -u "$user" -x kwin_wayland
check "desktop running" pgrep -u "$user" -x plasmashell
check "first sign-in finished" test -e "/home/$user/.config/fennek/first-login-done"
check "dark look saved" grep -q '^LookAndFeelPackage=org.fennek.dark.desktop' "/home/$user/.config/kdeglobals"
check "edition" test "$(cat /usr/share/fennek/edition 2>/dev/null)" = "$(cat /run/t/edition)"
check "file search running" as_user systemctl --user is-active -q fennek-search.service
check "Secure Boot on" sh -c 'mokutil --sb-state | grep -q "SecureBoot enabled"'
check "SELinux enforcing" sh -c '[ "$(getenforce)" = Enforcing ]'
crashes=$(coredumpctl --no-pager --no-legend list 2>/dev/null)
echo "$crashes" | grep -Eq 'kwin_wayland|plasmashell|plasmalogin|startplasma' && problems+=("the desktop crashed")

{
    echo "== problems: ${#problems[@]}"; printf '%s\n' "${problems[@]}"
    echo "== boot time"; systemd-analyze 2>&1 | head -3
    echo "== version"; bootc status 2>&1 | head -20; uname -r; mokutil --sb-state 2>&1; getenforce
    echo "== failed units"; systemctl --failed --no-pager --no-legend; as_user systemctl --user --failed --no-pager --no-legend
    echo "== crashes"; echo "$crashes"
    echo "== SELinux denials"; journalctl -b --no-pager -g 'avc:  denied' 2>/dev/null | tail -30
    echo "== errors"; journalctl -b -p err --no-pager | tail -60
    echo "== graphics"; lsmod | grep -E 'nvidia|nouveau|virtio_gpu|v4l2loopback'; ls -l /dev/dri 2>&1
} > "$out/report.txt" 2>&1
journalctl -b --no-pager > "$out/journal.txt" 2>&1
as_user journalctl --user -b --no-pager > "$out/journal-user.txt" 2>&1
if [ ${#problems[@]} -eq 0 ]; then echo pass > "$out/result"; else printf '%s; ' "${problems[@]}" > "$out/result"; fi
touch "$out/report-done"
