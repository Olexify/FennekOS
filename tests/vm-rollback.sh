#!/bin/bash
# Inside the test VM: the boot guard for real. Each "update" is the same image deployed again with a marker on the kernel
# command line, so no download is needed and every boot shows which version it is.
#   0: first boot done          -> install a good update
#   1: the good update runs     -> it must be accepted; install one that brings up no desktop
#   2: the bad one runs         -> the guard must go back by itself
#   3: back on the good one     -> install one that can't even start (the kernel panics)
#   (two failed tries; the boot loader falls back by itself)
#   4: back on the good one     -> done
out=/run/t/out
exec >>"$out/rollback.log" 2>&1
set -x
phase=$(cat "$out/phase")
env() { grub2-editenv /boot/grub2/grubenv list; }
fail() { echo "$1" > "$out/rollback-failed"; exit 1; }
booted_first() { rpm-ostree status --json | python3 -c 'import json,sys; d=[x for x in json.load(sys.stdin)["deployments"] if not x.get("staged")]; sys.exit(not d[0].get("booted"))'; }
marker() { grep -q "fennek.vmtest=$1" /proc/cmdline; }
wait_until() { for ((i = 0; i < $1; i++)); do "${@:2}" && return 0; sleep 2; done; return 1; }
no_tries() { ! env | grep -q '^fennek_'; }
install_update() {   # marker, more kernel arguments
    local c m=$1; shift
    c=$(rpm-ostree status --json | python3 -c 'import json,sys; print(next(d["checksum"] for d in json.load(sys.stdin)["deployments"] if d.get("booted")))')
    ostree admin deploy --stage "--karg-append=fennek.vmtest=$m" "${@/#/--karg-append=}" "$c" || fail "couldn't install update $m"
    ostree admin status
}
next() { echo "$1" > "$out/phase"; sync; sleep 2; systemctl reboot; exit 0; }

journalctl -b --no-pager -u fennek-boot-guard.service >"$out/guard-$phase.log" 2>&1
case $phase in
0)
    wait_until 150 test -e /var/lib/fennek/boot-guard/desktop-worked || fail "the guard never saw the desktop working"
    install_update good
    next 1
    ;;
1)
    marker good || fail "phase 1: not the good update: $(cat /proc/cmdline)"
    env | tee "$out/env-1.txt"
    wait_until 150 no_tries || fail "phase 1: the good update wasn't accepted: $(env)"
    booted_first || fail "phase 1: not the default"
    journalctl -b --no-pager -u fennek-boot-guard.service >"$out/guard-1.log" 2>&1
    install_update baddesktop systemd.mask=plasmalogin.service
    next 2
    ;;
2)
    marker baddesktop || fail "phase 2: not the bad update: $(cat /proc/cmdline)"
    # The guard waits for the desktop, gives up after 5 minutes and restarts: this boot ends by itself.
    echo 3 > "$out/phase"; sync
    sleep 400
    journalctl -b --no-pager -u fennek-boot-guard.service >"$out/guard-2.log" 2>&1
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
    touch "$out/rollback-ok"
    ;;
esac
