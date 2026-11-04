#!/bin/bash
# Inside the test VM, as root (started by the unit tests/vm-test.sh injects). Talks to the host through files in /run/t/out.
out=/run/t/out
user=anna

if [ "${1:-}" = setup ]; then
    if [ -e "$out/phase" ]; then   # a later boot of the rollback test
        systemd-run --unit=fennek-vmtest-rollback --no-block bash /run/t/vm-rollback.sh
        exit 0
    fi
    if [ -e "$out/mok-before" ]; then   # back from the firmware's blue screen
        systemd-run --unit=fennek-vmtest-mok --no-block bash /run/t/vm-inside.sh mok-after
        exit 0
    fi
    exec >"$out/setup.log" 2>&1
    if [ -e /run/t/wizard-wanted ]; then   # only a look at the first start: no account, the wizard isn't skipped
        touch "$out/setup-done"
        exit 0
    fi
    useradd -m -c "Anna" -G wheel "$user" && echo "$user:fennektest" | chpasswd   # the host types this at the sign-in screen
    touch /etc/plasma-setup-done   # the account exists: no first-run account wizard
    touch "$out/setup-done"
    systemd-run --unit=fennek-vmtest-watch --no-block bash /run/t/vm-inside.sh watch
    exit 0
fi

# The Secure Boot key step as a person does it (NVIDIA edition). Between the two halves the host goes through the firmware's
# blue screen. Each half ends by writing "ok", or what went wrong, to the file named after it.
if [ "${1:-}" = mok-before ] || [ "${1:-}" = mok-after ]; then
    half=$1 key=/etc/pki/akmods/certs/akmods-ublue.der
    exec >>"$out/mok.log" 2>&1
    set -x
    no() { echo "$1" > "$out/$half"; exit 1; }
    state() { /usr/libexec/fennek-graphics-check --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["secure_boot"])'; }   # "nvidia" is false in a VM
    if [ "$half" = mok-before ]; then
        said=$(modprobe v4l2loopback 2>&1) && no "v4l2loopback loaded with its key not trusted"
        grep -q 'Key was rejected' <<<"$said" || no "v4l2loopback didn't fail with a key rejection: $said"
        [ "$(state)" = needs-key ] || no "graphics check before the key step: $(state)"
        /usr/libexec/fennek-secure-boot-helper || no "the Secure Boot helper failed"
        mokutil --list-new | tr -d : | grep -qi "$(sha1sum "$key" | cut -d' ' -f1)" || no "mokutil --list-new doesn't show the key"
        [ "$(state)" = pending ] || no "graphics check after the helper: $(state)"
        echo ok > "$out/$half"
        sync; sleep 2
        systemctl reboot
    else
        mokutil --test-key "$key" | grep -q 'already enrolled' || no "the key isn't enrolled: $(mokutil --test-key "$key" 2>&1)"
        modprobe v4l2loopback || no "v4l2loopback doesn't load with its key enrolled"
        lsmod | grep -q '^v4l2loopback ' || no "v4l2loopback isn't in lsmod"
        [ "$(state)" = ok ] || no "graphics check after the key step: $(state)"
        echo ok > "$out/$half"
        if [ -e /run/t/rollback-wanted ]; then
            echo 0 > "$out/phase"
            bash /run/t/vm-rollback.sh
        fi
    fi
    exit 0
fi

exec >"$out/watch.log" 2>&1
uid=$(id -u "$user")
as_user() { runuser -u "$user" -- env XDG_RUNTIME_DIR="/run/user/$uid" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" WAYLAND_DISPLAY=wayland-0 "$@"; }
wait_file() { for ((i = 0; i < $2; i++)); do [ -e "$out/$1" ] && return 0; sleep 1; done; return 1; }

sleep 25; ps -eo user,args | grep -Ev '\[|ps -eo|grep' | grep -E 'plasmalogin|kwin|greeter|wayland' > "$out/greeter-ps.txt"
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
# The tray's lists are the tray widget's own settings.
tray_list() { as_user gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "panels().forEach(function (p) { p.widgets('org.kde.plasma.systemtray').forEach(function (w) { w.currentConfigGroup = ['General']; print(w.readConfig('$1')) }) })"; }
check "tray has its list, without Brightness" bash -c '[[ $1 == *org.kde.plasma.networkmanagement* && $1 != *org.kde.plasma.brightness* ]]' _ "$(tray_list extraItems)"
# Plasma drops a menu plugin it can't load from these settings, and the desktop has no right-click menu then.
check "desktop right-click menu loaded" grep -q '^RightButton;NoModifier=org.fennek.desktopmenu' "/home/$user/.config/plasma-org.kde.plasma.desktop-appletsrc"
check "Secure Boot on" sh -c 'mokutil --sb-state | grep -q "SecureBoot enabled"'
check "/boot is its own ext4, writable, and grub.cfg reads custom.cfg" sh -c 'findmnt -n -o FSTYPE /boot | grep -qx ext4 && [ -w /boot/grub2 ] && grep -q custom.cfg /boot/grub2/grub.cfg'
check "SELinux enforcing" sh -c '[ "$(getenforce)" = Enforcing ]'
# The computer's own Windows drives, closed cleanly: both open by themselves at sign-in, named and writable.
# (Opening a drive takes a person's session for polkit: in_session runs where the sign-in step runs, not here.)
in_session() { as_user systemd-run --user --wait --quiet --collect "$@"; }
opened_as() {   # DEVICE FOLDER rw|ro
    findmnt -n -S "$1" -o TARGET | grep -qxF "/run/media/$user/$2" && case ,$(findmnt -n -S "$1" -o OPTIONS), in *,$3,*) ;; *) false ;; esac
}
marked() { udevadm info -q property "$1" | grep -qx "$2"; }
check "Windows (C:) open and writable" opened_as /dev/vdb1 "Windows (C:)" rw
check "data drive open and writable" opened_as /dev/vdb2 Data rw
check "writing to Windows (C:)" as_user touch "/run/media/$user/Windows (C:)/fennek-vm-test"
check "writing to the data drive" as_user touch "/run/media/$user/Data/fennek-vm-test"
check "told not to wipe a log Windows left unclean" sh -c "journalctl -b -t ntfs-3g | grep 'Cmdline options' | grep -q norecover"
# The drive on an old-style table: not opened at sign-in, and with Windows closed cleanly nothing holds it.
old_drive_alone() { ! findmnt -n -S /dev/vdc1 && ! marked /dev/vdc1 FENNEK_NTFS=1 && ! marked /dev/vdc1 UDISKS_MOUNT_OPTIONS_DEFAULTS=ro; }
check "the drive on an old-style table left alone" old_drive_alone
# Neither of these is the computer's own: a USB disk (the host just plugged it in) and a file this account attaches as a disk.
in_session cp /run/t/loop.raw "/home/$user/loop.raw"
check "a file attached as a disk" in_session udisksctl loop-setup --no-user-interaction -f "/home/$user/loop.raw"
appears() { for ((i = 0; i < 30; i++)); do [ -e "$1" ] && return 0; sleep 1; done; return 1; }
check "USB disk plugged in" appears /dev/disk/by-label/FennekUSB
check "USB disk: what's written reaches it within seconds" sh -c 'sleep 3; [ "$(sysctl -n vm.dirty_expire_centisecs)" = 100 ] && [ "$(sysctl -n vm.dirty_writeback_centisecs)" = 100 ]'
check "attached file's drive there" appears /dev/disk/by-label/FennekLoop
# Fennek's own partition stays out of the drive lists, now that the sidebar shows drives.
# Sharing a folder, in the order the Share tab does it.
net_zone() { nmcli -g connection.zone connection show "$(nmcli -t -f NAME,TYPE connection show --active | grep -v ':loopback$' | head -1 | sed 's/:[^:]*$//')"; }
wait_zone() { for _ in $(seq 20); do [ "$(net_zone)" = "$1" ] && return 0; sleep 1; done; return 1; }
systemctl enable --now smb.service
as_user mkdir -p "/var/home/$user/Public"
check "an admin can share a folder" as_user net usershare add fennektest "/var/home/$user/Public" "" Everyone:F guest_ok=n
check "a share opens this network" wait_zone FennekOS-Sharing
check "guest shares are off" bash -c "! runuser -u $user -- net usershare add fennekguest /var/home/$user/Public '' Everyone:R guest_ok=y"
printf 'fennektest\nfennektest\n' | smbpasswd -s -a "$user"
check "a shared folder opens with the password" smbclient //127.0.0.1/fennektest -U "$user%fennektest" -c ls
check "a shared folder stays shut without it" bash -c "! smbclient //127.0.0.1/fennektest -N -c ls"
wait_listed() { for _ in $(seq 20); do [ "$(systemctl is-active wsdd.service)" = "$1" ] && return 0; sleep 1; done; return 1; }
check "the computer gets listed while sharing" wait_listed active
marked=$(nmcli -t -f NAME,TYPE connection show --active | grep -v ':loopback$' | head -1 | sed 's/:[^:]*$//')
nmcli connection modify "$marked" connection.zone FennekOS-Public
nmcli connection up "$marked" >/dev/null
check "not listed on a public network" wait_listed inactive
nmcli connection modify "$marked" connection.zone FennekOS-Sharing
nmcli connection up "$marked" >/dev/null
check "listed again back home" wait_listed active
as_user net usershare delete fennektest
check "the last share closes the network" wait_zone FennekOS
smbpasswd -x "$user" >/dev/null
systemctl disable --now smb.service
check "listing stops with sharing" wait_listed inactive
check "own partition hidden from the drive lists" sh -c 'udevadm info -q property "$(findmnt -nvo SOURCE /sysroot)" | grep -qx UDISKS_IGNORE=1'
# Windows hibernates (Fast Startup). hiberfil.sys is only on its own drive, but it holds the other one just the same.
closed() { for ((i = 0; i < 10; i++)); do udisksctl unmount --no-user-interaction -b "$1" && return 0; sleep 2; done; return 1; }
hibernate_windows() {
    closed /dev/vdb1 && closed /dev/vdb2 && mkdir -p /var/mnt/fennek-vmtest && mount -t ntfs-3g /dev/vdb1 /var/mnt/fennek-vmtest || return 1
    printf 'HIBR\0\0\0\0' > /var/mnt/fennek-vmtest/hiberfil.sys && umount /var/mnt/fennek-vmtest
}
check "a hibernation file on the Windows drive" hibernate_windows
check "drives looked at again" systemctl restart fennek-windows-scan.service
check "sign-in step run again" as_user systemctl --user restart fennek-windows-drives.service
check "hibernated: Windows (C:) opens read-only" opened_as /dev/vdb1 "Windows (C:)" ro
check "hibernated: the drive without the file opens read-only too" opened_as /dev/vdb2 Data ro
check "hibernated: Windows (C:) read-only in udev" marked /dev/vdb1 UDISKS_MOUNT_OPTIONS_DEFAULTS=ro
check "hibernated: the data drive read-only in udev" marked /dev/vdb2 UDISKS_MOUNT_OPTIONS_DEFAULTS=ro
check "hibernated: the drive on an old-style table read-only in udev" marked /dev/vdc1 UDISKS_MOUNT_OPTIONS_DEFAULTS=ro
# Files asks for no options when someone clicks a drive: read-only has to come from udev.
click_data_drive() { closed /dev/vdb2 && in_session udisksctl mount --no-user-interaction -b /dev/vdb2; }
check "clicking a drive in Files" click_data_drive
check "hibernated: clicked in Files, the drive opens read-only" opened_as /dev/vdb2 Data ro
check "clicking the drive on an old-style table" in_session udisksctl mount --no-user-interaction -b /dev/vdc1
check "hibernated: clicked in Files, the drive on an old-style table opens read-only" opened_as /dev/vdc1 FennekOld ro
# All this time the USB disk and the attached file were there, with the same kind of partition: no mark, not held, not open.
not_ours() {
    local dev props
    dev=$(readlink -f "$1") && props=$(udevadm info -q property "$dev") || return 1
    grep -qx ID_FS_TYPE=ntfs <<<"$props" && grep -qx ID_PART_ENTRY_TYPE=ebd0a0a2-b9e5-4433-87c0-68b6b72699c7 <<<"$props" \
        && ! grep -qx FENNEK_NTFS=1 <<<"$props" && ! grep -q '^UDISKS_MOUNT_OPTIONS_DEFAULTS=' <<<"$props" && ! findmnt -n -S "$dev"
}
check "USB disk really on USB" marked /dev/disk/by-label/FennekUSB 'ID_USB_VENDOR_ID=.*'
check "USB disk not taken for the computer's own, not opened" not_ours /dev/disk/by-label/FennekUSB
check "attached file not taken for the computer's own, not opened" not_ours /dev/disk/by-label/FennekLoop
check "the list holds just the computer's own two drives, read-only" as_user python3 -c 'import json; d = json.load(open("/run/fennek/windows-drives.json")); assert d["read_only"] is True and len(d["drives"]) == 2'
# A dual-boot computer: "Restart to Windows" shows, the clock follows.
efibootmgr -q -c -d /dev/vda -p 2 -L "Windows Boot Manager" -l '\EFI\Microsoft\Boot\bootmgfw.efi' 2>&1
systemctl restart fennek-detect-windows.service
check "Restart to Windows offered" test -e /run/fennek/has-windows
check "clock in step with Windows" sh -c '[ "$(timedatectl show -p LocalRTC --value)" = yes ]'
# An .exe with the executable flag (what a Windows drive or a stick gives every .exe), opened the way Start search does.
printf 'MZ' > "/home/$user/fennek-vm-test.exe"; chown "$user:" "/home/$user/fennek-vm-test.exe"; chmod 755 "/home/$user/fennek-vm-test.exe"
as_user systemd-run --user --quiet --collect kde-open "/home/$user/fennek-vm-test.exe"
exe_opens() { for ((i = 0; i < 20; i++)); do pgrep -u "$user" -f 'fennek-run-exe.*fennek-vm-test' >/dev/null && return 0; sleep 1; done; return 1; }
check "an .exe opens through fennek-run-exe" exe_opens
pkill -u "$user" -f 'fennek-vm-test' ; pkill -u "$user" kdialog
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
    echo "== graphics"; lsmod | grep -E 'nvidia|nouveau|virtio_gpu|v4l2loopback'; ls -l /dev/dri 2>&1; /usr/libexec/fennek-graphics-check --json
    echo "== Windows drives"; cat /run/fennek/windows-drives.json /run/udev/rules.d/90-fennek-windows-drives.rules; findmnt -S /dev/vdb1; findmnt -S /dev/vdb2
    for d in /dev/vdb1 /dev/vdb2 /dev/vdc1 /dev/disk/by-label/FennekUSB /dev/disk/by-label/FennekLoop; do echo "$d"; udevadm info -q property "$d" | grep -E 'FENNEK|ID_FS_LABEL|ID_FS_TYPE|ID_PART_ENTRY_TYPE|ID_BUS|ID_USB_VENDOR_ID|UDISKS'; done
    journalctl -b --no-pager -u fennek-windows-scan.service | tail -30
    echo "== tray"; as_user gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "panels().forEach(function (p) { print(p.widgets().map(function (w) { return w.type }).join(' ')) })"; for k in extraItems shownItems hiddenItems knownItems; do echo "$k: $(tray_list "$k")"; done
    echo "== sign-in processes"; cat "$out/greeter-ps.txt" 2>/dev/null
    echo "== boot"; findmnt /boot; findmnt /boot/efi; ls -la /boot/grub2 | head -20; grub2-editenv list 2>&1; ls /boot/loader/entries 2>&1; efibootmgr 2>&1; bootc status --json 2>/dev/null | head -c 600; echo
} > "$out/report.txt" 2>&1
journalctl -b --no-pager > "$out/journal.txt" 2>&1
as_user journalctl --user -b --no-pager > "$out/journal-user.txt" 2>&1
if [ ${#problems[@]} -eq 0 ]; then echo pass > "$out/result"; else printf '%s; ' "${problems[@]}" > "$out/result"; fi
touch "$out/report-done"
[ -e /run/t/mok-wanted ] && [ ${#problems[@]} -eq 0 ] && exec bash /run/t/vm-inside.sh mok-before
if [ -e /run/t/rollback-wanted ] && [ ${#problems[@]} -eq 0 ]; then
    echo 0 > "$out/phase"
    bash /run/t/vm-rollback.sh
fi
