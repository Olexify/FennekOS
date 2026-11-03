#!/usr/bin/env bash
# Turns the Fennek OS image into a live session with the Anaconda installer (modeled on Universal Blue's
# Titanoboa example for Bazzite). Runs inside iso/Containerfile. FENNEK_IMAGE = the exact image installed.
set -euxo pipefail
: "${FENNEK_IMAGE:?}"
# Where installed systems take signed updates from: this image's own edition (the NVIDIA edition has its own image),
# x86-64: latest, ARM64: latest-arm64.
repo=ghcr.io/olexify/fennekos
[ "$(cat /usr/share/fennek/edition 2>/dev/null)" = nvidia ] && repo=ghcr.io/olexify/fennekos-nvidia
UPDATES_FROM=$repo:latest
[ "$(uname -m)" = aarch64 ] && UPDATES_FROM=$repo:latest-arm64

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
# A drop-in, read after the profile Anaconda detects (fedora-kinoite): a profile of our own would lose to that one.
mkdir -p /etc/anaconda/conf.d
cat >/etc/anaconda/conf.d/90-fennek.conf <<'EOF'
[Timezone]
# Empty: no location lookup. The first-run wizard asks for the time zone.
geolocation_provider =
EOF
python3 -c 'from pyanaconda.core.configuration.anaconda import conf; conf.set_from_detected_profile("fedora", "kinoite"); conf.set_from_files(); assert not conf.timezone.geolocation_provider'
# What the screens ask you to free, and what Review checks: one number, 500 MB as it comes, while the system takes 8.5 GB and
# the apps more. 24 GB shows as 30 GB on screen (it adds a fifth).
# ponytail: tied to upstream's literal, the grep fails this build when it changes. A setting for it would need upstream.
f=$(rpm -ql anaconda-core | grep '/payloads/source/rpm_ostree/rpm_ostree\.py$')
grep -q 'Size("500 MB")' "$f"
sed -i 's/Size("500 MB")/Size("24 GB")/' "$f"
rm -f "${f%/*}"/__pycache__/rpm_ostree.*.pyc
# Shrinking a drive that's hibernated (a normal Shut down with Fast Startup) damages it: every route into the installer ends here.
resize=$(command -v ntfsresize)
mv "$resize" "$resize.real"
cat >"$resize" <<EOF
#!/bin/sh
case " \$* " in
    *" -s "* | *" --size"*)
        for dev; do :; done
        case "\$(ntfscat -f "\$dev" hiberfil.sys 2>/dev/null | head -c 4 | tr A-Z a-z)" in
            hibr)
                echo "Your current system isn't fully shut down, so its drive can't be shrunk safely. Nothing was changed. Start it, hold Shift and click Shut down, then start from the stick again." >&2
                exit 1 ;;
        esac ;;
esac
exec "$resize.real" "\$@"
EOF
chmod 755 "$resize"
"$resize" --version >/dev/null

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

# Installer branding: our name and fox icon instead of Fedora's (the live Welcome window shows this launcher).
echo "Fennek OS (installer)" >/etc/system-release
sed -i -e 's/^Icon=.*/Icon=fennek/' -e 's/^Name=.*/Name=Install Fennek OS/' /usr/share/applications/liveinst.desktop
grep -q '^Icon=fennek' /usr/share/applications/liveinst.desktop

# 4. Boot files the ISO needs.
efi=x64; [ "$(uname -m)" = aarch64 ] && efi=aa64   # boot loader file names differ per architecture
dnf install -y "grub2-efi-$efi-cdboot" xorriso isomd5sum
mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/
cp -v "/boot/efi/EFI/fedora/grub$efi.efi" "/boot/efi/EFI/BOOT/fb$efi.efi"

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
