#!/usr/bin/env bash
set -euo pipefail

# umu-launcher (Proton outside Steam) isn't in Fedora repos; pinned upstream RPM, checksum-verified.
UMU_VER=1.4.4
UMU_SHA256=f38dfe05c109a0ebeaecacad2ebe2e60fddc1fb2e50f7755023553ad256f8b32
UMU_RPM=/tmp/umu-launcher.rpm
curl -fsSL -o "$UMU_RPM" \
    "https://github.com/Open-Wine-Components/umu-launcher/releases/download/${UMU_VER}/umu-launcher-${UMU_VER}.fc44.x86_64.rpm"
echo "${UMU_SHA256}  ${UMU_RPM}" | sha256sum -c -

# OpenSnitch (per-app firewall engine) isn't in Fedora repos either: pinned upstream RPM, checksum-verified.
OSN_VER=1.8.0
OSN_SHA256=e06e9119daf764e56455b61c319e496274c0274bb53bb94a0ff1ab72967fea7d
OSN_RPM=/tmp/opensnitch.rpm
curl -fsSL -o "$OSN_RPM" \
    "https://github.com/evilsocket/opensnitch/releases/download/v${OSN_VER}/opensnitch-${OSN_VER}-1.x86_64.rpm"
echo "${OSN_SHA256}  ${OSN_RPM}" | sha256sum -c -

dnf -y install \
    libnetfilter_queue \
    zsh zsh-autosuggestions zsh-syntax-highlighting \
    snapper \
    clamav clamav-freshclam inotify-tools \
    "$UMU_RPM"
# Its scripts only enable+start the daemon (and fail in a container); we want it off until something is
# blocked, so install without them. Its one dependency came with the main install above.
dnf -y install --setopt=tsflags=noscripts "$OSN_RPM"
rm "$UMU_RPM" "$OSN_RPM"

# No-telemetry: umu contacts Valve on every launch even with UMU_RUNTIME_UPDATE=0. Make "0" fully offline
# when the runtime is already installed (fennek-run-exe allows update checks at most once a day).
python3 - <<'EOF'
import glob, os, pathlib
p = pathlib.Path(glob.glob("/usr/lib/python3*/site-packages/umu/umu_runtime.py")[0])
old = '    """Install or update the runtime for the current user."""\n'
new = old + ('    # Fennek OS patch: no network at all when updates are off and the runtime is present.\n'
             '    if os.environ.get("UMU_RUNTIME_UPDATE") == "0" and has_runtime_installed(local):\n'
             '        return\n')
s = p.read_text()
assert s.count(old) == 1, "umu changed upstream: revisit the Fennek OS no-telemetry patch"
p.write_text(s.replace(old, new))
for pyc in glob.glob(str(p.parent / "__pycache__" / "umu_runtime.*.pyc")):
    os.remove(pyc)
EOF

# --- Fennek OS branding ---
# Name + logo. ID stays "fedora" so Fedora repos and tooling keep working.
sed -i -e 's/^NAME=.*/NAME="Fennek OS"/' \
       -e 's/^PRETTY_NAME=.*/PRETTY_NAME="Fennek OS (Fedora 44 base)"/' \
       -e 's/^LOGO=.*/LOGO=fennek/' \
       -e 's/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME="fennek"/' /usr/lib/os-release
dnf -y remove plasma-welcome-fedora   # "Fedora loves KDE" pages
# Wallpaper, generated at build time (no binaries in the repo).
mkdir -p /usr/share/wallpapers/Fennek/contents/images
magick -size 3840x2160 -define gradient:angle=135 gradient:'#0b1a33-#1e5bd8' \
    /usr/share/wallpapers/Fennek/contents/images/3840x2160.png
# Look-and-feel: Fedora's as base; our metadata + taskbar layout (from system_files) win.
lnf=/usr/share/plasma/look-and-feel/org.fennek.desktop
cp -an /usr/share/plasma/look-and-feel/org.fedoraproject.fedora.desktop/contents/. "$lnf/contents/"
sed -i 's/^Image=.*/Image=Fennek/' "$lnf/contents/defaults"
sed -i 's/^LookAndFeelPackage=.*/LookAndFeelPackage=org.fennek.desktop/' \
    /usr/share/kde-settings/kde-profile/default/xdg/kdeglobals
# Login screen wallpaper.
sed -i 's|/usr/share/wallpapers/Fedora/|/usr/share/wallpapers/Fennek/|g' /usr/lib/plasmalogin/defaults.conf
# Boot splash watermark (bgrt theme reads spinner's images). rm first: the file is hardlinked.
wm=/usr/share/plymouth/themes/spinner/watermark.png
(cd /tmp && magick -background none -density 384 /usr/share/icons/hicolor/scalable/apps/fennek.svg -resize 72x72 l.png &&
    magick -background none -fill white -font Noto-Sans-Medium -pointsize 44 label:"Fennek OS" t.png &&
    rm -f "$wm" && magick l.png t.png -background none -gravity center +smush 18 +repage -depth 8 "$wm" && rm l.png t.png)
# The splash lives in the initramfs, so rebuild it.
KVER=$(ls /usr/lib/modules)
dracut --no-hostonly --kver "$KVER" --reproducible --add ostree -f "/usr/lib/modules/$KVER/initramfs.img"
chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"

# Permissions: everything we ship is 644, except our programs.
(cd /tmp/system_files && find . -type f) | while read -r f; do chmod 644 "/${f#./}"; done
chmod 755 /usr/bin/fennek-* /usr/libexec/fennek-*

# Hourly home snapshots (ransomware undo), set up on first boot.
systemctl enable fennek-home-snapshots.service snapper-timeline.timer snapper-cleanup.timer

# Firewall: incoming blocked except what the desktop needs (Fedora's default zone opens ports 1025-65535).
sed -i 's/^DefaultZone=.*/DefaultZone=FennekOS/' /etc/firewalld/firewalld.conf

# Antivirus: daily definitions, every user's Downloads scanned on arrival.
systemctl enable clamav-freshclam-once.timer
systemctl --global enable fennek-download-guard.service

# zsh is the default shell for new users, with suggestions + highlighting + Fennek OS aliases.
sed -i 's|^SHELL=.*|SHELL=/bin/zsh|' /etc/default/useradd
cat >> /etc/zshrc <<'EOF'

# Fennek OS
source /etc/profile.d/fennek-aliases.sh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
EOF

# Updates download + stage in background, apply on next normal reboot. Never forced.
systemctl enable rpm-ostreed-automatic.timer

# Leave no dnf state behind (bootc lint).
dnf clean all
rm -rf /run/dnf /var/log/dnf5.log /var/lib/dnf /var/cache/libdnf5 /var/cache/ldconfig
