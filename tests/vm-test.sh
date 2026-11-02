#!/usr/bin/env bash
# The real thing before anything is published: installs IMAGE to a disk, boots it in a VM with Secure Boot on (the
# Microsoft-signed firmware keys of a normal PC), signs in like a person and checks the desktop that comes up.
#   tests/vm-test.sh IMAGE OUTPUT_DIR [EXPECT_EDITION]
# Also, when set to 1: FENNEK_VM_ROLLBACK a bad update undoes itself; FENNEK_VM_MOK the Secure Boot key step, from the
# failing driver through the firmware's blue screen to the loaded driver (NVIDIA edition); FENNEK_VM_WIZARD only a picture
# of what a first start shows with no account yet.
# Needs: podman (image in root's storage), qemu-system-x86, ovmf, gdisk, KVM. Test settings reach the VM only through
# systemd credentials and kernel arguments of this test install; the image itself isn't touched.
set -uo pipefail
image=$1 out=$2 edition=${3:-}
here=$(cd "$(dirname "$0")" && pwd)
work=${FENNEK_VM_WORK:-/mnt/vmtest}
sudo mkdir -p "$work" "$out" && sudo chown -R "$(id -u)" "$work" "$out"
share=$work/share; rm -rf "$share"; mkdir -p "$share/out"
cp "$here/vm-inside.sh" "$here/vm-rollback.sh" "$share/"; printf '%s' "$edition" > "$share/edition"
[ -n "${FENNEK_VM_ROLLBACK:-}" ] && touch "$share/rollback-wanted"
[ -n "${FENNEK_VM_MOK:-}" ] && [ "$edition" = nvidia ] && touch "$share/mok-wanted"
[ -n "${FENNEK_VM_MOK:-}" ] && [ "$edition" != nvidia ] && echo "::warning::The Secure Boot key step only runs on the NVIDIA edition: skipped"
[ -n "${FENNEK_VM_WIZARD:-}" ] && touch "$share/wizard-wanted"
stage() { echo "::group::$*"; }
end() { echo "::endgroup::"; }
die() { echo "::error::VM test: $*"; cp -a "$share/out/." "$out/" 2>/dev/null; [ -f "$work/serial.log" ] && tail -c 6000 "$work/serial.log" | tr -cd '[:print:]\n'; exit 1; }

stage "Install to a disk"
# The installer compares this folder through /proc/1/root: a symlink (CI moves container storage to the big disk)
# would point nowhere from inside its container, a bind mount doesn't.
if [ -L /var/lib/containers ]; then
    t=$(readlink -f /var/lib/containers)
    sudo rm /var/lib/containers && sudo mkdir /var/lib/containers && sudo mount --bind "$t" /var/lib/containers
fi
# The layout the installer makes: EFI system partition, /boot on ext4, the system on btrfs. The 1 MB partition is only for
# --generic-image: bootupd then also installs the BIOS boot loader, and grub2-install refuses a GPT disk without one.
rm -f "$work/disk.raw"; truncate -s 40G "$work/disk.raw"
sgdisk -n 1:0:+1M -t 1:ef02 -n 2:0:+600M -t 2:ef00 -n 3:0:+1G -t 3:8300 -n 4:0:0 -t 4:8300 "$work/disk.raw" >/dev/null \
    || die "couldn't partition the disk"
loop=$(sudo losetup -Pf --show "$work/disk.raw") || die "no loop device for the disk"
sudo udevadm settle
# The image's own mkfs tools: what the installer runs. bootc and bootupd read UUIDs and partition types from udev's data.
sudo podman run --rm --privileged -v /dev:/dev "$image" \
    sh -c "mkfs.vfat -F 32 '${loop}p2' && mkfs.ext4 -q '${loop}p3' && mkfs.btrfs -q '${loop}p4'" || die "couldn't make the filesystems"
sudo udevadm trigger --settle "${loop}p2" "${loop}p3" "${loop}p4"
target=$work/target
mkdir -p "$target"
sudo mount "${loop}p4" "$target" && sudo mkdir "$target/boot" && sudo mount "${loop}p3" "$target/boot" \
    && sudo mkdir "$target/boot/efi" && sudo mount "${loop}p2" "$target/boot/efi" || die "couldn't mount the new filesystems"
# --skip-finalize: bootc would leave the filesystems read-only, and the file below is still to be written.
sudo podman run --rm --privileged --pid=host --security-opt label=disable \
    -v /var/lib/containers:/var/lib/containers -v /dev:/dev -v "$target:/target:rbind" "$image" \
    bootc install to-filesystem --generic-image --skip-fetch-check --skip-finalize \
    --source-imgref "containers-storage:$image" \
    --karg console=tty0 --karg console=ttyS0,115200 --karg systemd.wants=fennek-vmtest.service \
    /target || die "the image doesn't install"
# bootc's fstab mounts /boot read-only, and the boot guard writes there. These are the lines the installer writes.
# Through tee, in place: the file keeps its SELinux label.
fstab=$(sudo sh -c "ls '$target'/ostree/deploy/*/deploy/*.0/etc/fstab") \
    && boot=$(sudo blkid -p -o value -s UUID "${loop}p3") && esp=$(sudo blkid -p -o value -s UUID "${loop}p2") \
    && printf 'UUID=%s /boot ext4 defaults 1 2\nUUID=%s /boot/efi vfat umask=0077,shortname=winnt 0 2\n' "$boot" "$esp" | sudo tee "$fstab" \
    || die "couldn't write the new system's fstab"
sudo umount -R "$target" && sudo losetup -d "$loop" || die "couldn't let go of the disk"
end

# A second disk as if Windows lived on this computer: the Windows drive, closed cleanly, and a data drive it left
# hibernated (Fast Startup).
stage "Windows-like disk"
truncate -s 400M "$work/ntfs.raw"
sgdisk -n 1:0:+180M -t 1:0700 -n 2:0:+180M -t 2:0700 "$work/ntfs.raw" >/dev/null
loop=$(sudo losetup -Pf --show "$work/ntfs.raw") && sudo mkntfs -Q -L OS "${loop}p1" >/dev/null && sudo mkntfs -Q -L Data "${loop}p2" >/dev/null \
    || die "couldn't make the test disk"
mkdir -p "$work/m"
sudo mount -t ntfs-3g "${loop}p1" "$work/m" && sudo mkdir -p "$work/m/Windows/System32" && sudo umount "$work/m" || die "test disk: Windows folder"
sudo mount -t ntfs-3g "${loop}p2" "$work/m" && printf 'HIBR\0\0\0\0' | sudo tee "$work/m/hiberfil.sys" >/dev/null && sudo umount "$work/m" || die "test disk: hibernation file"
sudo losetup -d "$loop"
end

cat > "$work/vmtest.service" <<'EOF'
[Unit]
Description=Fennek VM test
Before=display-manager.service plasmalogin.service plasma-setup.service
After=local-fs.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'modprobe 9pnet_virtio; mkdir -p /run/t && mount -t 9p -o trans=virtio,version=9p2000.L t /run/t && exec bash /run/t/vm-inside.sh setup'
EOF
cp /usr/share/OVMF/OVMF_VARS_4M.ms.fd "$work/vars.fd"
sudo chmod 666 /dev/kvm
cred=$(base64 -w0 "$work/vmtest.service")
qemu-system-x86_64 -name fennek-vm -machine q35,smm=on,accel=kvm -global driver=cfi.pflash01,property=secure,value=on \
    -cpu host -m 8192 -smp 4 -display none -serial "file:$work/serial.log" -nic none \
    -drive "if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd" \
    -drive "if=pflash,format=raw,unit=1,file=$work/vars.fd" \
    -drive "if=virtio,format=raw,file=$work/disk.raw" -drive "if=virtio,format=raw,file=$work/ntfs.raw" \
    -device virtio-vga,xres=1600,yres=900,edid=on -device qemu-xhci -device usb-tablet -device usb-kbd \
    -virtfs "local,path=$share,mount_tag=t,security_model=none" \
    -smbios "type=11,value=io.systemd.credential.binary:systemd.extra-unit.fennek-vmtest.service=$cred" \
    -qmp "unix:$work/qmp.sock,server,nowait" &
vm=$!
trap 'kill $vm 2>/dev/null; true' EXIT
qmp() { python3 "$here/vm-qmp.py" "$work/qmp.sock" "$@"; }
shot() { qmp "{\"execute\":\"screendump\",\"arguments\":{\"filename\":\"$out/$1.png\",\"format\":\"png\"}}" >/dev/null; qmp "{\"execute\":\"screendump\",\"arguments\":{\"filename\":\"$work/$1.ppm\"}}" >/dev/null; }
wait_for() {   # FILE SECONDS: until the VM says so
    for ((s = 0; s < $2; s += 5)); do
        [ -e "$share/out/$1" ] && return 0
        kill -0 $vm 2>/dev/null || die "the VM stopped before: $1"
        sleep 5
    done
    return 1
}
vm_says_ok() {   # FILE SECONDS: the VM writes "ok" there, or what went wrong
    wait_for "$1" "$2" || { shot "$1-stuck"; die "no answer from the VM: $1"; }
    sleep 1
    [ "$(cat "$share/out/$1")" = ok ] || die "$(cat "$share/out/$1")"
}

stage "Boot and sign in"
wait_for setup-done 300 || { sleep 1; shot boot-stuck; die "no sign of a booted system after 5 minutes"; }
echo "System up"
if [ -e "$share/wizard-wanted" ]; then
    sleep 90
    shot wizard-1
    cp -a "$share/out/." "$out/"
    end
    echo "VM test passed: the system booted, wizard-1.png shows what it brings up."
    exit 0
fi
# Sign in like a person: any key on the clock screen, then the password.
sleep 60
shot 0-sign-in-clock
for try in 1 2 3; do
    python3 "$here/vm-qmp.py" "$work/qmp.sock" --key ret >/dev/null
    sleep 4
    [ "$try" = 1 ] && shot 0-sign-in
    python3 "$here/vm-qmp.py" "$work/qmp.sock" --type fennektest >/dev/null
    python3 "$here/vm-qmp.py" "$work/qmp.sock" --key ret >/dev/null
    wait_for session-up 90 && break
    shot "no-session-$try"
done
[ -e "$share/out/session-up" ] || die "no desktop after signing in"
echo "Desktop up"
wait_for desktop-settled 240 || { shot not-settled; die "the first sign-in didn't finish"; }
shot 1-first-sign-in
touch "$share/out/go-start"
end

stage "Start menu"
wait_for start-open 60 || die "Start didn't open"
sleep 6
shot 2-start
python3 "$here/vm-check-start.py" "$work/2-start.ppm" "$work/1-first-sign-in.ppm" || { touch "$share/out/go-report"; wait_for report-done 120; die "Start's tiles have no icons"; }
touch "$share/out/go-report"
end

stage "Report"
wait_for report-done 180 || die "no report from the VM"
cp -a "$share/out/." "$out/"
cat "$out/report.txt"
end
[ "$(cat "$out/result" 2>/dev/null)" = pass ] || die "$(cat "$out/result" 2>/dev/null || echo 'no result')"

if [ -e "$share/mok-wanted" ]; then
    stage "Secure Boot key step"
    vm_says_ok mok-before 120
    qmp --wait-blue "$work/now.ppm" 300 >/dev/null || { shot mok-no-blue-screen; die "no blue screen after the restart"; }
    sleep 3
    shot mok-1
    # The order shim really has (MokManager.c). Each menu starts on its top line: "Continue boot" above "Enroll MOK", then
    # "View key 0" above "Continue", then "No" above "Yes". After them the password, and the first menu with "Reboot" on top.
    n=1
    for k in down ret down ret down ret; do
        qmp --key "$k" >/dev/null
        sleep 4
        n=$((n + 1))
        shot "mok-$n"
        cmp -s "$work/mok-$((n - 1)).ppm" "$work/mok-$n.ppm" && die "the blue screen didn't react to step $n ($k)"
    done
    qmp --type fennek >/dev/null
    qmp --key ret >/dev/null
    sleep 6
    shot mok-8
    qmp --key ret >/dev/null
    sleep 2
    shot mok-9
    vm_says_ok mok-after 300
    cp -a "$share/out/." "$out/"
    cat "$out/mok.log"
    end
fi

if [ -n "${FENNEK_VM_ROLLBACK:-}" ]; then
    stage "A bad update undoes itself"
    for ((s = 0; s < 2400; s += 15)); do
        [ -e "$share/out/rollback-ok" ] && break
        [ -e "$share/out/rollback-failed" ] && { shot rollback-failed; die "$(cat "$share/out/rollback-failed")"; }
        kill -0 $vm 2>/dev/null || die "the VM stopped during the rollback test"
        sleep 15
    done
    [ -e "$share/out/rollback-ok" ] || { shot rollback-stuck; die "rollback test stuck at phase $(cat "$share/out/phase")"; }
    cp -a "$share/out/." "$out/"
    end
fi
echo "VM test passed."
