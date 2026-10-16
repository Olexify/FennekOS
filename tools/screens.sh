#!/usr/bin/env bash
# Design review: starts the Fennek desktop on a virtual screen inside the image and saves screenshots to /out.
# Runs in CI (.github/workflows/screens.yml) as a fresh user, the way a new installation first looks.
set -u
out=/out; mkdir -p "$out"; chmod 777 "$out"
# Test-container only (never in the image): a virtual X screen to photograph, and an image tool.
dnf -y -q install xorg-x11-server-Xvfb ImageMagick >/dev/null 2>&1 || echo "tools install failed"
id anna >/dev/null 2>&1 || useradd -m -c "Anna" anna
uid=$(id -u anna); export XDG_RUNTIME_DIR=/run/user/$uid
mkdir -p "$XDG_RUNTIME_DIR" && chown anna: "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"

cat >/tmp/session.sh <<'EOF'
set -u
export LANG=C.UTF-8 XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true QT_FORCE_STDERR_LOGGING=1 QT_LOGGING_RULES="spectacle*.debug=true;kwin_screenshot*.debug=true"
# Photograph the virtual X screen KWin draws into (KWin's own screenshot needs a GPU).
shot() { sleep "${2:-3}"; timeout 20 magick import -display :99 -window root "/out/$1.png" >>/out/shot.log 2>&1 || echo "no screenshot: $1 (exit $?)"; }
call() { timeout 10 gdbus call --session --dest "$1" --object-path "$2" --method "$3" "${@:4}" >/dev/null 2>&1; }
script() { timeout 10 gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "$1" 2>/dev/null; }
widget() {   # open a taskbar widget's popup by plugin id
    local id; id=$(script "panels().forEach(p => p.widgets('$1').forEach(w => print(w.id)))" | grep -o '[0-9]\+' | head -1)
    [ -n "$id" ] && call org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.invokeShortcut "activate widget $id"
}
close() { kill $! 2>/dev/null; sleep 1; }   # the app just started in the background

# KWin first, without client display variables; its own test switch lets spectacle take screenshots here.
Xvfb :99 -screen 0 1600x900x24 -nolisten tcp >/out/xvfb.log 2>&1 &
sleep 2
{ env DISPLAY=:99 QT_LOGGING_RULES="kwin_*.debug=true" kwin_wayland --x11-display :99 --width 1600 --height 900 --no-lockscreen --socket wayland-fennek; echo "kwin exited: $?"; } >/out/kwin.log 2>&1 &
sleep 6
export QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=wayland-fennek
{ echo "runtime dir:"; ls -la "$XDG_RUNTIME_DIR"; echo "processes:"; ps -eo pid,user,args | grep -E "kwin|dbus" | grep -v grep; } >/out/diag.log 2>&1
/usr/libexec/fennek-first-login-places >/dev/null 2>&1
# Normally started by systemd (not in a container): activities (plasmashell refuses to start without), kded.
/usr/libexec/kactivitymanagerd >/out/kactivitymanagerd.log 2>&1 &
kded6 >/out/kded.log 2>&1 &
sleep 2
plasmashell >/out/plasma.log 2>&1 &
shot 01-desktop 30
call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu; shot 02-start
call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu; sleep 1
widget org.fennek.searchbox; shot 03-search; widget org.fennek.searchbox
widget org.fennek.actioncenter; shot 04-action-center; widget org.fennek.actioncenter
widget org.fennek.clock; shot 05-calendar; widget org.fennek.clock
widget org.fennek.volume; shot 06-sound; widget org.fennek.volume
widget org.fennek.network; shot 07-network; widget org.fennek.network
dolphin thispc:/ >/dev/null 2>&1 & shot 08-file-explorer 6; close
fennek-app settings >/dev/null 2>&1 & shot 09-settings 6; close
fennek-app firewall >/dev/null 2>&1 & shot 10-firewall 6; close
konsole >/dev/null 2>&1 & shot 11-terminal 5; close
plasma-systemmonitor >/dev/null 2>&1 & shot 12-task-manager 8; close
fennek-app welcome >/dev/null 2>&1 & shot 13-welcome 6; close
ps -eo pid,user,args >>/out/diag.log 2>&1
kill $(jobs -p) 2>/dev/null; exit 0
EOF
chmod 755 /tmp/session.sh
timeout 900 runuser -u anna -- env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" HOME=/home/anna dbus-run-session -- bash /tmp/session.sh
ls -la "$out"
