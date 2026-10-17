#!/usr/bin/env bash
# Design review: starts the Fennek desktop on a virtual screen inside the image and saves screenshots to /out.
# Runs in CI (.github/workflows/screens.yml) as a fresh user, the way a new installation first looks.
set -u
out=/out; mkdir -p "$out"; chmod 777 "$out"
# Test-container only (never in the image): a virtual X screen to photograph, and an image tool.
dnf -y -q install xorg-x11-server-Xvfb ImageMagick xdotool >/dev/null 2>&1 || echo "tools install failed"
id anna >/dev/null 2>&1 || useradd -m -c "Anna" anna
uid=$(id -u anna); export XDG_RUNTIME_DIR=/run/user/$uid
mkdir -p "$XDG_RUNTIME_DIR" && chown anna: "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"

cat >/tmp/session.sh <<'EOF'
set -u
export SHELL=/bin/zsh LANG=C.UTF-8 XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true QT_FORCE_STDERR_LOGGING=1 QT_LOGGING_RULES="spectacle*.debug=true;kwin_screenshot*.debug=true"
# Photograph the virtual X screen KWin draws into (KWin's own screenshot needs a GPU).
shot() { sleep "${2:-3}"; timeout 20 magick import -display :99 -window root "/out/$1.png" >>/out/shot.log 2>&1 || echo "no screenshot: $1 (exit $?)"; }
call() { timeout 10 gdbus call --session --dest "$1" --object-path "$2" --method "$3" "${@:4}" >/dev/null 2>&1; }
script() { timeout 10 gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "$1" 2>/dev/null; }
widget() {   # open a taskbar widget's popup by plugin id
    local id; id=$(script "panels().forEach(p => p.widgets('$1').forEach(w => print(w.id)))" | grep -o '[0-9]\+' | head -1)
    [ -n "$id" ] && call org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.invokeShortcut "activate widget $id"
}
click() { DISPLAY=:99 xdotool mousemove "$1" "$2" click 1; }   # on the 1600x900 virtual screen
close() { kill $! 2>/dev/null; sleep 1; }   # the app just started in the background

# KWin first, without client display variables; its own test switch lets spectacle take screenshots here.
Xvfb :99 -screen 0 1600x900x24 -nolisten tcp >/out/xvfb.log 2>&1 &
sleep 2
{ env DISPLAY=:99 QT_LOGGING_RULES="kwin_*.debug=true" kwin_wayland --x11-display :99 --width 1600 --height 900 --no-lockscreen --socket wayland-fennek; echo "kwin exited: $?"; } >/out/kwin.log 2>&1 &
sleep 6
export QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=wayland-fennek
{ echo "runtime dir:"; ls -la "$XDG_RUNTIME_DIR"; echo "processes:"; ps -eo pid,user,args | grep -E "kwin|dbus" | grep -v grep; } >/out/diag.log 2>&1
xdg-user-dirs-update >/dev/null 2>&1
/usr/libexec/fennek-first-login >/out/first-login.log 2>&1   # what a new user's first sign-in does
# Normally started by systemd (not in a container): activities (plasmashell refuses to start without), kded.
/usr/libexec/kactivitymanagerd >/out/kactivitymanagerd.log 2>&1 &
kded6 >/out/kded.log 2>&1 &
sleep 2
plasmashell >/out/plasma.log 2>&1 &
sleep 6; pkill -f 'fennek-app welcome'   # first login opens Welcome; it gets its own shot below
shot 01-desktop 24
call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu; shot 02-start
call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu; sleep 1
click 60 880; shot 03-search; click 60 880; sleep 1
click 1560 880; shot 04-action-center; click 1560 880; sleep 1
click 1498 880; shot 05-calendar; click 1498 880; sleep 1
click 1390 880; shot 06-sound; click 1390 880; sleep 1
click 1360 880; shot 07-network; click 1360 880; sleep 1
click 1447 880; shot 18-hidden-icons; click 1447 880; sleep 1
# Files' own first start (panels closed), quit normally: its saved window layout, for the new-user template.
dolphin >/dev/null 2>&1 & sleep 7; DISPLAY=:99 xdotool key ctrl+q; sleep 3
cp ~/.local/state/dolphinstaterc /out/dolphinstaterc-firstrun 2>/dev/null; cp ~/.config/dolphinrc /out/dolphinrc-firstrun 2>/dev/null
dolphin thispc:/ >/dev/null 2>&1 & shot 08-file-explorer 6; close
fennek-app settings >/dev/null 2>&1 & shot 09-settings 6; close
fennek-app firewall >/dev/null 2>&1 & shot 10-firewall 6; close
konsole >/dev/null 2>&1 & shot 11-terminal 5; close
plasma-systemmonitor >/dev/null 2>&1 & shot 12-task-manager 8; close
fennek-app welcome >/dev/null 2>&1 & shot 13-welcome 6; close
# Start with a search typed in (results, not the list).
call org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu; sleep 2
DISPLAY=:99 xdotool type --delay 80 "fire"; shot 14-start-search 3
DISPLAY=:99 xdotool key Escape; sleep 1
# A notification popup and the volume on-screen display.
notify-send -a "Fennek OS" -i system-software-update "Update ready" "It's installed on the next restart." ; shot 15-notification 2
call org.kde.plasmashell /org/kde/osdService org.kde.osdService.volumeChanged 60 100; shot 16-volume-osd 1
# File Explorer from the sidebar's This PC, with the classic menu bar.
dolphin >/dev/null 2>&1 & shot 17-file-explorer-home 6; close
ps -eo pid,user,args >>/out/diag.log 2>&1
kill $(jobs -p) 2>/dev/null; exit 0
EOF
chmod 755 /tmp/session.sh
timeout 900 runuser -u anna -- env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" HOME=/home/anna dbus-run-session -- bash /tmp/session.sh
chmod -R a+rX "$out"   # files written as the test user must be readable for the upload
ls -la "$out"
