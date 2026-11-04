#!/usr/bin/env bash
# An encrypted install from start to finish: the ISO installs itself onto a blank disk, then the computer starts from that disk,
# the password is typed at the prompt, and a recovery key is made for the real system drive and checked.
# Usage: iso/encrypted-test.sh ISO
set -euo pipefail
iso=$(realpath "$1") here=$(cd "$(dirname "$0")" && pwd) work=$(mktemp -d)
keep=${2:-$PWD/encrypted-test-out}; mkdir -p "$keep"   # what's left to read afterwards
share=$work/share; mkdir -p "$share/out"
cp "$here/encrypted-inside.sh" "$share/"
truncate -s 64G "$work/disk.raw"
cp /usr/share/OVMF/OVMF_VARS_4M.fd "$work/vars.fd"
sudo chmod 666 /dev/kvm

cat >"$work/test.service" <<'EOF'
[Unit]
Description=Fennek encrypted install test
After=local-fs.target livesys-late.service
[Service]
Type=oneshot
TimeoutStartSec=infinity
ExecStart=/bin/sh -c 'modprobe 9pnet_virtio; mkdir -p /run/t && mount -t 9p -o trans=virtio,version=9p2000.L t /run/t && exec bash /run/t/encrypted-inside.sh'
EOF
cred=$(base64 -w0 "$work/test.service")
# Nothing else starts it: the ISO's and the install's kernel lines stay as they ship.
want=$(printf '[Unit]\nWants=fennek-enc-test.service\n' | base64 -w0)
start() {   # extra qemu arguments
    qemu-system-x86_64 -name fennek-enc -machine q35,accel=kvm -cpu host -m 8192 -smp 4 -display none -serial "file:$work/serial.log" -nic none \
        -drive "if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd" \
        -drive "if=pflash,format=raw,unit=1,file=$work/vars.fd" \
        -drive "if=virtio,format=raw,file=$work/disk.raw" -device virtio-vga \
        -virtfs "local,path=$share,mount_tag=t,security_model=none" \
        -smbios "type=11,value=io.systemd.credential.binary:systemd.extra-unit.fennek-enc-test.service=$cred" \
        -smbios "type=11,value=io.systemd.credential.binary:systemd.unit-dropin.multi-user.target=$want" \
        -qmp "unix:$work/qmp.sock,server,nowait" "$@" &
    vm=$!
}
qmp() { python3 "$here/../tests/vm-qmp.py" "$work/qmp.sock" "$@"; }
give_up() {
    echo "FAIL: $1"
    qmp "{\"execute\":\"screendump\",\"arguments\":{\"filename\":\"$keep/stuck.png\",\"format\":\"png\"}}" >/dev/null 2>&1 || true
    sleep 2
    kill "$vm" 2>/dev/null || true
    cp -r "$share/out/." "$keep/" 2>/dev/null || true
    cp "$work/serial.log" "$keep/" 2>/dev/null || true
    ls -la "$keep"
    cat "$keep/started" 2>/dev/null || echo "the test never started inside the VM"
    tail -n 30 "$keep/liveinst.log" "$keep/anaconda.log" 2>/dev/null | cut -c1-200 || true
    exit 1
}
trap 'kill "${vm:-}" 2>/dev/null || true' EXIT

echo "== installing"
start -device virtio-scsi-pci -drive "if=none,id=cd,media=cdrom,readonly=on,file=$iso" -device scsi-cd,drive=cd,bootindex=1
for ((s = 0; s < 1800; s += 10)); do kill -0 "$vm" 2>/dev/null || break; sleep 10; done
kill -0 "$vm" 2>/dev/null && give_up "the install didn't finish in 30 minutes"
wait "$vm" || true
[ "$(cat "$share/out/installed" 2>/dev/null)" = ok ] || give_up "the install didn't finish: $(cat "$share/out/installed" 2>/dev/null)"
echo "installed after ~${s}s"

echo "== starting from the encrypted disk"
start
for ((s = 0; s < 1200; s += 20)); do
    [ -e "$share/out/result" ] && break
    kill -0 "$vm" 2>/dev/null || give_up "the computer stopped before the system was up"
    sleep 20
    # Keys sent before the prompt shows are lost. Once it's unlocked, they go nowhere that matters.
    [ -e "$share/out/result" ] || { qmp --type fennektest >/dev/null; qmp --key ret >/dev/null; } || true
done
[ -e "$share/out/result" ] || give_up "the system didn't come up in 20 minutes"
result=$(cat "$share/out/result")
[ "$result" = ok ] || give_up "$result"
echo "encrypted install ok: started with the password, recovery key made and checked"
