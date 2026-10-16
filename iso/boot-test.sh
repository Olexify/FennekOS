#!/usr/bin/env bash
# Boot smoke test: start the ISO in a UEFI VM and wait until the live system asks for a network address
# (DHCP from NetworkManager = kernel, live root, systemd and services all came up).
# The VM's network card has no boot ROM, so no DHCP can come from the firmware itself.
# Usage: iso/boot-test.sh ISO MINUTES     (runs qemu; x86-64 or aarch64 = this machine's architecture)
set -euo pipefail
iso=$1 minutes=$2 work=$(mktemp -d)
if [ "$(uname -m)" = aarch64 ]; then
    qemu=(qemu-system-aarch64 -M virt -m 4096 -smp 4)
    cp /usr/share/AAVMF/AAVMF_VARS.fd "$work/vars.fd"; code=/usr/share/AAVMF/AAVMF_CODE.fd
else
    qemu=(qemu-system-x86_64 -M q35 -m 4096 -smp 2)
    cp /usr/share/OVMF/OVMF_VARS_4M.fd "$work/vars.fd"; code=/usr/share/OVMF/OVMF_CODE_4M.fd
fi
if [ -w /dev/kvm ]; then qemu+=(-enable-kvm -cpu host); else qemu+=(-cpu max); fi   # no KVM: slow but works

"${qemu[@]}" -display none -serial "file:$work/serial.log" \
    -drive "if=pflash,format=raw,readonly=on,file=$code" -drive "if=pflash,format=raw,file=$work/vars.fd" \
    -device virtio-scsi-pci -drive "if=none,id=cd,media=cdrom,readonly=on,file=$iso" -device scsi-cd,drive=cd,bootindex=0 \
    -netdev user,id=n0 -device virtio-net-pci,netdev=n0,romfile= -object "filter-dump,id=f0,netdev=n0,file=$work/net.pcap" &
vm=$!
trap 'kill $vm 2>/dev/null; true' EXIT

dhcp() { python3 -c 'import sys; sys.exit(b"\x63\x82\x53\x63" not in open(sys.argv[1], "rb").read())' "$work/net.pcap" 2>/dev/null; }
for ((s = 0; s < minutes * 60; s += 10)); do
    if dhcp; then echo "Booted: the live system asked for a network address after ~${s}s."; exit 0; fi
    kill -0 $vm 2>/dev/null || break
    sleep 10
done
echo "No sign of a booted system after $minutes min. Firmware/boot loader output:"
tail -c 4000 "$work/serial.log" | tr -cd '[:print:]\n' || true
exit 1
