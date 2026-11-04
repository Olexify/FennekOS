#!/bin/bash
# Runs inside the VM of iso/encrypted-test.sh, as root: from the installer it installs, from the disk it checks.
out=/run/t/out
pass=fennektest
echo "$(date) $(cat /proc/cmdline)" >>"$out/started"

if grep -qw rd.live.image /proc/cmdline; then
    # The USB has to reach the desktop by itself: that's where Install is.
    for _ in $(seq 60); do loginctl list-sessions --no-legend | grep -q liveuser && break; sleep 5; done
    loginctl list-sessions >"$out/live-sessions.log"
    if ! grep -q liveuser "$out/live-sessions.log"; then
        echo "the USB stayed at the sign-in screen" >"$out/installed"
        journalctl -b --no-pager >"$out/journal.log"
        sync
        systemctl poweroff
        exit 0
    fi
    cat >/run/ks.cfg <<EOF
%include /usr/share/anaconda/interactive-defaults.ks
lang en_US.UTF-8
keyboard us
timezone UTC --utc
rootpw --lock
user --name=anna --groups=wheel --password=$pass --plaintext
ignoredisk --only-use=vda
zerombr
clearpart --all --initlabel --drives=vda
autopart --type=btrfs --encrypted --passphrase=$pass --luks-version=luks2
poweroff
%post --nochroot
cp /tmp/*.log $out/ 2>/dev/null
lsblk -nro FSTYPE /dev/vda | grep -qx crypto_LUKS && echo ok >$out/installed || echo "no encrypted partition after the install" >$out/installed
sync
%end
EOF
    # The logs as it goes: if it hangs, they show where.
    (while sleep 20; do cp /tmp/*.log "$out/" 2>/dev/null; journalctl -b --no-pager >"$out/journal.log"; ps axf >"$out/ps.log"; loginctl list-sessions >"$out/sessions.log"; done) &
    keep=$!
    # Not liveinst: from there Anaconda reads only its own defaults, not a kickstart.
    dbus-run-session -- anaconda --cmdline --kickstart=/run/ks.cfg >"$out/liveinst.log" 2>&1 </dev/null
    echo "installer exit $?" >>"$out/started"
    # Only when something went wrong: a finished install has powered off by now.
    kill "$keep"
    cp /tmp/*.log "$out/" 2>/dev/null
    [ -e "$out/installed" ] || echo "the installer stopped early" >"$out/installed"
    sync
    systemctl poweroff
    exit 0
fi

# Started from the disk: the password worked.
no() { echo "$1" >"$out/result"; sync; systemctl poweroff; exit 0; }
dev=$(/usr/libexec/fennek-encryption --device)
[ -n "$dev" ] || no "the page doesn't find the encrypted partition"
[ -b "$dev" ] || no "not a partition: $dev"
key=$(printf '%s\n' "$pass" | /usr/libexec/fennek-encryption-helper) || no "no recovery key was made for the system drive"
printf '%s' "$key" | cryptsetup open --test-passphrase "$dev" - || no "the recovery key doesn't open the system drive"
printf '%s' "$pass" | cryptsetup open --test-passphrase "$dev" - || no "the password stopped working after the key was made"
udevadm info -q property "$dev" | grep -qx UDISKS_IGNORE=1 || no "the encrypted partition shows in the drive lists"
echo ok >"$out/result"
sync
systemctl poweroff
