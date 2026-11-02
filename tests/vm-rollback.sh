#!/bin/bash
# Inside the test VM: the boot guard for real. Each "update" is the same image deployed again with a marker on the kernel
# command line, so no download is needed and every boot shows which version it is.
#   0: first boot done          -> install a good update
#   1: the good update runs     -> restart cleanly three times before the guard could accept it: that uses up no tries;
#                                  then it must be accepted; install one that brings up no desktop
#   2: the bad one runs         -> the guard must go back by itself
#   3: back on the good one     -> install one that can't even start (the kernel panics)
#   (two failed tries; the boot loader falls back by itself)
#   4: back on the good one     -> done
out=/run/t/out
exec >>"$out/rollback.log" 2>&1
set -x
phase=$(cat "$out/phase")
env() { grub2-editenv /boot/grub2/grubenv list; }
# SELinux denials of the guard's work, which runs in init's context and the finalize unit's: this boot's (0) or the last
# one's, its shutdown included (-1). Every journal line carries the host name, fennek: only look behind "denied".
denials() { journalctl -b "$1" --no-pager -g 'avc:  denied' 2>/dev/null | grep -E 'denied .*(grub2-editenv|grubenv|fennek|/boot|:boot_t:|comm="mount")' >>"$out/selinux-boot-guard.log"; }
this_boot() { journalctl -b --no-pager -u fennek-boot-guard.service >>"$out/guard-$phase.log" 2>&1; denials 0; }
fail() { this_boot; echo "$1" > "$out/rollback-failed"; exit 1; }
booted_first() { rpm-ostree status --json | python3 -c 'import json,sys; d=[x for x in json.load(sys.stdin)["deployments"] if not x.get("staged")]; sys.exit(not d[0].get("booted"))'; }
marker() { grep -q "fennek.vmtest=$1" /proc/cmdline; }
wait_until() { for ((i = 0; i < $1; i++)); do "${@:2}" && return 0; sleep 2; done; return 1; }
no_tries() { ! env | grep -q '^fennek_'; }
watching() { journalctl -b --no-pager -u fennek-boot-guard.service | grep -q 'watching'; }
install_update() {   # marker, more kernel arguments
    local c m=$1; shift
    c=$(rpm-ostree status --json | python3 -c 'import json,sys; print(next(d["checksum"] for d in json.load(sys.stdin)["deployments"] if d.get("booted")))')
    ostree admin deploy --stage "--karg-append=fennek.vmtest=$m" "${@/#/--karg-append=}" "$c" || fail "couldn't install update $m"
    ostree admin status
}
next() { echo "$1" > "$out/phase"; sync; sleep 2; systemctl reboot; exit 0; }

denials -1
journalctl -b -1 --no-pager -u fennek-boot-guard.service -u ostree-finalize-staged.service >>"$out/guard-$phase.log" 2>&1
case $phase in
0)
    wait_until 150 test -e /var/lib/fennek/boot-guard/desktop-worked || fail "the guard never saw the desktop working"
    install_update good
    next 1
    ;;
1)
    marker good || fail "phase 1: not the good update: $(cat /proc/cmdline)"
    env | tee -a "$out/env-1.txt"
    restarts=$(cat "$out/clean-restarts" 2>/dev/null || echo 0)
    if [ "$restarts" -gt 0 ]; then
        journalctl -b -1 --no-pager -u fennek-boot-guard.service | grep -q 'stopped cleanly' || fail "phase 1: restart $restarts didn't count as a clean one"
    fi
    if [ "$restarts" -lt 3 ]; then
        # The guard is watching, and has to see the sign-in screen up for 30 seconds before it accepts: this is well before.
        wait_until 60 watching || fail "phase 1: the guard isn't watching: $(env)"
        env | grep -Eq '^fennek_tries=[12]$' || fail "phase 1: after $restarts clean restarts: $(env)"
        echo $((restarts + 1)) > "$out/clean-restarts"; sync
        next 1
    fi
    wait_until 150 no_tries || fail "phase 1: the good update wasn't accepted: $(env)"
    booted_first || fail "phase 1: not the default"
    [ -e /var/lib/fennek/boot-guard/rolled-back ] && fail "phase 1: clean restarts counted as a failed update"
    findmnt /boot | tee -a "$out/env-1.txt"   # the guard wrote there: for everyone else it stays as it was
    install_update baddesktop systemd.mask=sddm.service
    next 2
    ;;
2)
    marker baddesktop || fail "phase 2: not the bad update: $(cat /proc/cmdline)"
    # The guard waits for the desktop, gives up after 5 minutes and restarts: this boot ends by itself.
    echo 3 > "$out/phase"; sync
    sleep 400
    fail "phase 2: the guard didn't go back: $(env)"
    ;;
3)
    marker good || fail "phase 3: not back on the good one: $(cat /proc/cmdline)"
    marker baddesktop && fail "phase 3: still the bad one"
    booted_first || fail "phase 3: the good one isn't the default"
    no_tries || fail "phase 3: tries left: $(env)"
    [ -s /var/lib/fennek/boot-guard/rolled-back ] || fail "phase 3: nothing remembered for the sign-in notice"
    rm -f /var/lib/fennek/boot-guard/rolled-back   # this test deploys the same image again: it must not count as "the failed one"
    install_update badkernel init=/usr/bin/false panic=5 rd.shell=0 rd.emergency=reboot
    next 4
    ;;
4)
    marker good || fail "phase 4: not back on the good one: $(cat /proc/cmdline)"
    marker badkernel && fail "phase 4: still the bad one"
    env | tee "$out/env-4.txt"
    wait_until 90 booted_first || fail "phase 4: the good one isn't the default: $(ostree admin status)"
    wait_until 30 no_tries || fail "phase 4: tries left: $(env)"
    [ -s /var/lib/fennek/boot-guard/rolled-back ] || fail "phase 4: nothing remembered for the sign-in notice"
    this_boot
    touch "$out/rollback-ok"
    ;;
esac
