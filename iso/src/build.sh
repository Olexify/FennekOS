#!/usr/bin/env bash
# Turns the Fennek OS image into a live session with the Anaconda installer (modeled on Universal Blue's
# Titanoboa example for Bazzite). Runs inside iso/Containerfile. FENNEK_IMAGE = the exact image installed.
set -euxo pipefail
: "${FENNEK_IMAGE:?}"
UPDATES_FROM=ghcr.io/olexify/fennekos:latest   # where installed systems take signed updates from

mkdir -p "$(realpath /root)" /var/lib/rpm-state
mount -o remount,rw /proc/sys || true

# 1. The image to install travels inside the ISO (offline install). It was signature-verified before this build.
podman pull "$FENNEK_IMAGE"
podman tag "$FENNEK_IMAGE" "$UPDATES_FROM"

# 2. Live boot: initramfs that can boot from the ISO, KDE live session.
dnf install -y dracut-live livesys-scripts
kernel=$(kernel-install list --json pretty | jq -r '.[] | select(.has_kernel == true) | .version')
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"
sed -i 's/^livesys_session=.*/livesys_session=kde/' /etc/sysconfig/livesys
systemctl enable livesys.service livesys-late.service

# 3. Installer: Anaconda (web UI). Interactive: language, disk (incl. next to Windows), your own user account.
dnf install -y --allowerasing anaconda-live libblockdev-btrfs libblockdev-lvm libblockdev-dm
mkdir -p /etc/anaconda/profile.d
cat >/etc/anaconda/profile.d/fennek.conf <<'EOF'
[Profile]
profile_id = fennek

[Profile Detection]
os_id = fedora

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = fedora
menu_auto_hide = True

[Storage]
# Btrfs with separate subvolumes: /var/home on its own subvolume is what Fennek's hourly snapshots need.
default_scheme = BTRFS
btrfs_compression = zstd:1
default_partitioning =
    /     (min 1 GiB, max 70 GiB)
    /home (min 500 MiB, free 50 GiB)
    /var  (btrfs)

[User Interface]
hidden_spokes =
    NetworkSpoke
    PasswordSpoke
hidden_webui_pages =
    root-password
    network

[Localization]
use_geolocation = False
EOF

# Install exactly the bundled image; afterwards updates come from the registry WITH signature enforcement
# (ostree-image-signed + /etc/containers/policy.json requiring Fennek's key).
mkdir -p /usr/share/anaconda/post-scripts
cat >>/usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=$UPDATES_FROM --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/fennek-signed-updates.ks
EOF
cat >/usr/share/anaconda/post-scripts/fennek-signed-updates.ks <<EOF
%post --erroronfail --log=/tmp/fennek-signed-updates.log
# Same effect as: bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $UPDATES_FROM
sed -i 's|container-image-reference=.*|container-image-reference=ostree-image-signed:docker://$UPDATES_FROM|' /ostree/deploy/default/deploy/*.origin
grep -q 'ostree-image-signed:docker://$UPDATES_FROM' /ostree/deploy/default/deploy/*.origin
%end
EOF

# Installer branding: our name instead of Fedora's.
echo "Fennek OS (installer)" >/etc/system-release

# 4. Boot files the ISO needs.
dnf install -y grub2-efi-x64-cdboot xorriso isomd5sum
mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/
cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi

# 5. Live-session housekeeping (from the Titanoboa example).
rm -f /etc/localtime
systemd-firstboot --timezone UTC
rm -rf /var/tmp && mkdir -p /var/tmp
cat >/etc/systemd/system/var-tmp.mount <<'EOF'
[Unit]
Description=Larger tmpfs for /var/tmp on the live system
[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%%,nr_inodes=1m
[Install]
WantedBy=local-fs.target
EOF
systemctl enable var-tmp.mount

mkdir -p /usr/lib/bootc-image-builder
cp /src/iso.yaml /usr/lib/bootc-image-builder/iso.yaml
dnf clean all
