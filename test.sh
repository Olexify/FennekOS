#!/usr/bin/env bash
# Smoke test, run inside the built image: docker run --rm -v ./test.sh:/t.sh fennek:dev bash /t.sh
set -euo pipefail
fail() { echo "FAIL: $*"; exit 1; }
x86() { [ "$(uname -m)" = x86_64 ]; }   # .exe runner (umu): x86-64 only so far (ARM: FEX)

grep -q '^SHELL=/bin/zsh' /etc/default/useradd             || fail "default shell"
[ "$(zsh -ic 'alias dir' 2>/dev/null)" = "dir='ls -lah'" ]  || fail "zsh aliases"
[ "$(bash --rcfile /etc/skel/.bashrc -ic 'alias cls' 2>/dev/null)" = "alias cls='clear'" ] || fail "bash aliases"
[ "$(zsh -ic 'a=$SAVEHIST; history-off >/dev/null; b=$SAVEHIST; history-on >/dev/null; print "$a $b $SAVEHIST"' 2>/dev/null)" = "10000 0 10000" ] \
                                                             || fail "terminal history on/off"
zsh -ic 'typeset -f _zsh_autosuggest_start' >/dev/null 2>&1 || fail "zsh autosuggestions"
if x86; then command -v umu-run >/dev/null || fail "umu-run"; else command -v FEXInterpreter >/dev/null && command -v muvm >/dev/null || fail "FEX (x86-64 programs on ARM)"; fi
grep -q '^Exec=fennek-run-exe %f' /usr/share/applications/fennek-run-exe.desktop || fail "exe launcher"
fennek-run-exe --selftest >/dev/null                           || fail "run-exe selftest"
grep -q '^application/x-ms-dos-executable=fennek-run-exe.desktop' /etc/xdg/mimeapps.list || fail "exe default"
grep -q '^AutomaticUpdatePolicy=stage' /etc/rpm-ostreed.conf || fail "update policy"
[ -L /etc/systemd/system/timers.target.wants/rpm-ostreed-automatic.timer ] || fail "update timer"
grep -q 'Indexing-Enabled=false' /etc/xdg/baloofilerc        || fail "baloo off"
grep -q '^NAME="Fennek OS"' /usr/lib/os-release                 || fail "os-release name"
grep -q '^ID=fedora' /usr/lib/os-release                      || fail "os-release id must stay fedora"
! rpm -q plasma-welcome-fedora >/dev/null                     || fail "fedora welcome pages"
! grep -q "Fennek image build" /etc/dnf/dnf.conf                || fail "build-time dnf settings left in the image"
[ -s /usr/share/wallpapers/Fennek/contents/images/3840x2160.png ] || fail "wallpaper"
[ "$(magick /usr/share/wallpapers/Fennek/contents/images/3840x2160.png -crop 1x1+1920+1290 -format '%[fx:r>b && r>0.6]' info:)" = 1 ] \
                                                              || fail "wallpaper isn't the desert dusk (warm horizon)"
grep -q '^Image=Fennek' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/defaults || fail "lnf wallpaper"
[ "$(kreadconfig6 --file /usr/share/plasma/desktoptheme/fennek-dark/colors --group Colors:Selection --key BackgroundNormal)" = 109,69,184 ] && ! grep -q "29,153,243" /usr/share/plasma/desktoptheme/fennek-dark/colors || fail "panel accent is Fennek violet"
# Desktop update scripts run once and silently: at least check they are well-formed (brackets, quotes).
python3 - <<'PY' || fail "a desktop update script is malformed"
import glob, re
for f in glob.glob("/usr/share/plasma/shells/org.kde.plasma.desktop/contents/updates/fennek-*.js"):
    code = re.sub(r"//[^\n]*", "", open(f).read())
    code = re.sub(r'"(\\.|[^"\\])*"', '""', code)
    stack, pairs = [], {")": "(", "]": "[", "}": "{"}
    for ch in code:
        if ch in "([{": stack.append(ch)
        elif ch in ")]}": assert stack and stack.pop() == pairs[ch], f
    assert not stack and code.count("'") % 2 == 0, f
PY
# Existing desktops follow layout changes by themselves (Plasma update scripts, once per user): no reset needed.
u=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/updates/fennek-2026-10-16-taskbar.js
[ -f "$u" ] && grep -q 'org.fennek.taskview' "$u" && grep -q 'hideSearchField' "$u"   && [ "$(kreadconfig6 --file /etc/xdg/plasmarc --group Theme --key name)" = fennek-dark ]   && grep -q '^name=fennek-dark' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/defaults   && [ -f /usr/share/plasma/desktoptheme/fennek-dark/widgets/tasks.svg ] && python3 -c "import json; assert json.load(open('/usr/share/plasma/desktoptheme/fennek-dark/metadata.json'))['KPlugin']['Id'] == 'fennek-dark'"  || fail "taskbar update for existing desktops / dark panels"
for app in org.kde.kmenuedit systemsettings kdesystemsettings org.kde.khelpcenter org.kde.kinfocenter firewall-config org.kde.kjournaldbrowser org.kde.plasma-welcome; do
    f=/usr/share/applications/$app.desktop; [ ! -f "$f" ] || { [ "$(grep -c '^NoDisplay=' "$f")" = 1 ] && grep -q '^NoDisplay=true' "$f"; } || fail "Start list still shows $app"
done
grep -q '^Name=Terminal$' /usr/share/applications/org.kde.konsole.desktop && grep -q '^Name=Store$' /usr/share/applications/org.kde.discover.desktop && ! grep -q '^Name\[en_GB\]=' /usr/share/applications/org.kde.konsole.desktop || fail "plain app names in Start"
grep -q "SystrayContainmentId" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "tray shown/hidden icons"
for p in org.fennek.searchbox org.fennek.showdesktop org.fennek.volume org.fennek.clock org.fennek.network org.fennek.actioncenter; do
    python3 -c "import json; json.load(open('/usr/share/plasma/plasmoids/$p/metadata.json'))" && [ -s /usr/share/plasma/plasmoids/$p/contents/ui/main.qml ] \
        && grep -q "\"$p\"" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js \
        || fail "taskbar widget $p"
done
grep -q 'panel.hiding = "none"' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "taskbar always visible"
grep -q 'panel.height = 40' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "40 px taskbar"
grep -q '^ButtonsOnRight=IAX' /etc/xdg/kwinrc && grep -q '^LayoutName=thumbnail_grid' /etc/xdg/kwinrc || fail "classic window buttons / Alt+Tab"
grep -q '^TitleAlignment=AlignLeft' /etc/xdg/breezerc                || fail "titles on the left"
a=/usr/share/aurorae/themes/FennekClassic
grep -q '^theme=__aurorae__svg__FennekClassic' /etc/xdg/kwinrc && [ -f "$a/FennekClassicrc" ] || fail "Fennek Classic window frame"
lib=$(sed -n 's/^library=//p' /etc/xdg/kwinrc)
[ -f "/usr/lib64/qt6/plugins/org.kde.kdecoration3/$lib.so" ]      || fail "window frame engine $lib not installed"
grep -q '^Shadow=true' "$a/FennekClassicrc" && grep -q 'id="decoration-bottomright"' "$a/decoration.svg" || fail "window shadow"
for b in minimize maximize restore close; do grep -q 'id="hover-center"' "$a/$b.svg" || fail "frame button $b"; done
grep -q 'id="decoration-top"' "$a/decoration.svg" && grep -q 'id="decoration-inactive-top"' "$a/decoration.svg" || fail "frame svg"
grep -q '^BorderlessMaximizedWindows=false' /etc/xdg/kwinrc       || fail "title bar on maximized windows"
r=/usr/share/kxmlgui5/dolphin/dolphinui.rc
grep -q 'name="go_up"' "$r" && grep -q 'version="10[0-9][0-9]"' "$r" && grep -q '<Menu' "$r" || fail "Files toolbar (Back/Forward/Up)"
python3 -c "import sys, xml.dom.minidom as x; x.parse(sys.argv[1])" "$r"   || fail "Files toolbar file is not valid XML"
[ -s /usr/share/fennek/apps/firewall/main.qml ] && grep -q '^Exec=fennek-app firewall' /usr/share/applications/fennek-firewall.desktop || fail "Firewall window"
fennek-firewall list --json | python3 -c 'import json,sys; assert json.load(sys.stdin) == []' || fail "firewall list --json"
# Go back (undo last update): stand-in rpm-ostree/pkexec, so only the decision logic runs.
gb=$(mktemp -d) && printf '#!/bin/sh\necho "$GB_JSON"\n' >"$gb/rpm-ostree" && printf '#!/bin/sh\necho "pkexec $*"\n' >"$gb/pkexec" && chmod +x "$gb"/* \
  && [[ $(GB_JSON='{"deployments":[{"booted":true,"timestamp":1760000000}]}' PATH="$gb:$PATH" fennek-go-back --yes 2>&1) == *"no previous version"* ]] \
  && [[ $(GB_JSON='{"deployments":[{"staged":true},{"booted":true},{"timestamp":1760000000}]}' PATH="$gb:$PATH" fennek-go-back --yes) == *"pkexec bootc rollback"* ]] \
  && ! GB_JSON='{"deployments":[{"booted":true},{"timestamp":1}]}' PATH="$gb:$PATH" fennek-go-back >/dev/null 2>&1 || fail "go back (rollback) logic"
rm -rf "$gb"
# Everyday apps: installed once after the first start (never in the live session); --list = what's still missing.
ea=$(/usr/libexec/fennek-essential-apps --list) && echo "everyday apps to fetch: $ea" | tr '\n' ' ' && echo \
  && [ -L /etc/systemd/system/multi-user.target.wants/fennek-essential-apps.service ] \
  && grep -q '^ConditionKernelCommandLine=!rd.live.image' /usr/lib/systemd/system/fennek-essential-apps.service \
  && [ -z "$(grep -vx 'org\.kde\.[a-z]*' <<<"$ea")" ] || fail "everyday apps installer"
# Alt+F4 script (desktop: Shut down) + shortcut update for existing users (runs before the window manager).
# It must sit where KWin's own scripts are, or Alt+F4 would do nothing at all.
kd=$(ls -d /usr/share/kwin*/scripts/minimizeall 2>/dev/null | head -1)
[ -n "$kd" ] && [ -f "${kd%/minimizeall}/fennekaltf4/contents/code/main.js" ] && [ -f "${kd%/minimizeall}/fenneksnapassist/contents/code/main.js" ] || fail "Alt+F4 script not where KWin loads scripts (${kd:-none found})"
python3 -c "import json; d=json.load(open('/usr/share/kwin-wayland/scripts/fennekaltf4/metadata.json')); assert d['KPlugin']['Id']=='fennekaltf4'"   && grep -q 'registerShortcut("Fennek Close or Shut Down"' /usr/share/kwin-wayland/scripts/fennekaltf4/contents/code/main.js   && [ "$(kreadconfig6 --file /etc/xdg/kwinrc --group Plugins --key fennekaltf4Enabled)" = true ]   && [ "$(kreadconfig6 --file /etc/xdg/kglobalshortcutsrc --group kwin --key 'Window Close')" = "none,Alt+F4,Close Window" ] || fail "Alt+F4 on the desktop"
sh=$(mktemp -d) && printf '[kwin]\nOverview=Meta+W,Meta+W,Toggle Overview\nWindow Close=Alt+F4,Alt+F4,Close Window\n' >"$sh/kglobalshortcutsrc" \
  &&XDG_CONFIG_HOME=$sh XDG_STATE_HOME=$sh /usr/libexec/fennek-shortcuts-update   && [ "$(kreadconfig6 --file "$sh/kglobalshortcutsrc" --group kwin --key 'Window Close')" = "none,Alt+F4,Close Window" ]   && [ "$(kreadconfig6 --file "$sh/kglobalshortcutsrc" --group kwin --key Overview | cut -f1)" = Meta+Tab ]   && [ -L /etc/systemd/user/plasma-workspace.target.wants/fennek-shortcuts-update.service ] || fail "shortcut update for existing users"
rm -rf "$sh"
[ "$(kreadconfig6 --file /etc/xdg/ksmserverrc --group General --key confirmLogout)" = false ] || fail "power menu acts without a second confirmation"
grep -q 'Fennek OS: no line over an open button' /usr/share/plasma/shells/org.kde.plasma.desktop/contents/applet/CompactApplet.qml || fail "no line over open taskbar buttons"
# Everyday apps get plain names in Start (Okular -> PDF Reader); the copy goes when the app goes.
an=$(mktemp -d) && mkdir -p "$an/exp" && printf '[Desktop Entry]\nName=Okular\nExec=x\n' >"$an/exp/org.kde.okular.desktop" \
  && FENNEK_FLATPAK_EXPORTS="$an/exp" XDG_DATA_HOME="$an" /usr/libexec/fennek-app-names \
  && grep -q '^Name=PDF Reader$' "$an/applications/org.kde.okular.desktop" && rm "$an/exp/org.kde.okular.desktop" \
  && FENNEK_FLATPAK_EXPORTS="$an/exp" XDG_DATA_HOME="$an" /usr/libexec/fennek-app-names && [ ! -e "$an/applications/org.kde.okular.desktop" ] \
  && [ -L /etc/systemd/user/graphical-session.target.wants/fennek-app-names.service ] || fail "plain names for everyday apps"
rm -rf "$an"
# Fennek colour schemes: violet instead of Breeze blue; system default for new users; existing users switched once.
grep -q '^Name=Fennek Light$' /usr/share/color-schemes/FennekLight.colors && ! grep -q '61,174,233' /usr/share/color-schemes/FennekLight.colors   && grep -q '^Name=Fennek Dark$' /usr/share/color-schemes/FennekDark.colors && ! grep -q '61,174,233' /usr/share/color-schemes/FennekDark.colors   && [ "$(kreadconfig6 --file /etc/xdg/kdeglobals --group Colors:Selection --key BackgroundNormal)" = 109,69,184 ]   && grep -q '^ColorScheme=FennekDark' /usr/share/plasma/look-and-feel/org.fennek.dark.desktop/contents/defaults || fail "Fennek colour schemes"
cs=$(mktemp -d) && mkdir -p "$cs/bin" && printf '#!/bin/sh\necho "$1" >"%s/applied"\n' "$cs" >"$cs/bin/plasma-apply-colorscheme" \
  && chmod +x "$cs/bin/plasma-apply-colorscheme" && printf '[General]\nColorScheme=BreezeDark\n' >"$cs/kdeglobals" \
  && PATH="$cs/bin:$PATH" XDG_CONFIG_HOME="$cs" XDG_STATE_HOME="$cs" /usr/libexec/fennek-shortcuts-update \
  && [ "$(cat "$cs/applied")" = FennekDark ] || fail "existing users move to the Fennek colour scheme"
# A stock theme that took over (Breeze Dark via the Dark mode switch) is replaced by Fennek Dark, once.
lf=$(mktemp -d) && mkdir -p "$lf/bin" && cp "$cs/bin/plasma-apply-colorscheme" "$lf/bin/" \
  && printf '#!/bin/sh\necho "$2" >"%s/lnf"\n' "$lf" >"$lf/bin/plasma-apply-lookandfeel" && chmod +x "$lf/bin/plasma-apply-lookandfeel" \
  && printf '[KDE]\nLookAndFeelPackage=org.kde.breezedark.desktop\nDefaultDarkLookAndFeel=org.kde.breezedark.desktop\n' >"$lf/kdeglobals" \
  && PATH="$lf/bin:$PATH" XDG_CONFIG_HOME="$lf" XDG_STATE_HOME="$lf" XDG_DATA_HOME="$lf" /usr/libexec/fennek-shortcuts-update \
  && [ "$(cat "$lf/lnf")" = org.fennek.dark.desktop ] \
  && [ "$(kreadconfig6 --file "$lf/kdeglobals" --group KDE --key DefaultDarkLookAndFeel)" = org.fennek.dark.desktop ] || fail "stock theme replaced by Fennek's"
rm -rf "$lf"
rm -rf "$cs"
# "Update ready" note: once per downloaded update, enabled for every user.
ur=$(mktemp -d) && echo one >"$ur/staged" && export FENNEK_STAGED="$ur/staged" XDG_STATE_HOME="$ur" FENNEK_DRY_RUN=1 \
  && [ "$(/usr/libexec/fennek-update-ready)" = "would notify" ] && [ -z "$(/usr/libexec/fennek-update-ready)" ] \
  && echo two >"$ur/staged" && [ "$(/usr/libexec/fennek-update-ready)" = "would notify" ] \
  && [ -L /etc/systemd/user/graphical-session.target.wants/fennek-update-ready.path ] \
  && [ -L /etc/systemd/user/graphical-session.target.wants/fennek-update-ready.service ] || fail "update ready notification"
unset FENNEK_STAGED XDG_STATE_HOME FENNEK_DRY_RUN; rm -rf "$ur"
command -v ss >/dev/null && fennek-firewall active --json | python3 -c 'import json,sys; assert isinstance(json.load(sys.stdin), list)' || fail "firewall active --json"
grep -qF "fennek-firewall profile [home|public]" /usr/bin/fennek-firewall || fail "firewall network profile command"
[ -x /usr/libexec/fennek-first-login ] && grep -q '^Exec=/usr/libexec/fennek-first-login' /etc/xdg/autostart/fennek-first-login.desktop || fail "first-login Fennek look"
cmp -s /usr/share/plasma/look-and-feel/org.fennek.{desktop,dark.desktop}/contents/layouts/org.kde.plasma.desktop-layout.js || fail "Fennek Dark has the Fennek layout"
grep -q "^startPage=applications.page" /etc/xdg/systemmonitorrc || fail "Task Manager opens on apps"
[ -f /usr/share/icons/Fennek/scalable/places/folder.svg ] && [ -f /usr/share/icons/Fennek/scalable/apps/org.kde.dolphin.svg ] && [ -f /usr/share/icons/hicolor/scalable/apps/fennek-firewall.svg ] && [ "$(kreadconfig6 --file /etc/xdg/kdeglobals --group Icons --key Theme)" = Fennek ] && grep -q "^Theme=Fennek" /usr/share/plasma/look-and-feel/org.fennek.dark.desktop/contents/defaults || fail "Fennek icons"
grep -q "Ctrl+Shift+V; Ctrl+V" /usr/share/kxmlgui5/konsole/sessionui.rc && grep -q "hidden=\"true\" name=\"sessionToolbar\"" /usr/share/kxmlgui5/konsole/sessionui.rc && grep -q "hidden=\"true\" name=\"mainToolBar\"" /usr/share/kxmlgui5/konsole/konsoleui.rc && grep -q "^TabBarVisibility=AlwaysShowTabBar" /etc/xdg/konsolerc || fail "Terminal: classic tabs, no toolbars"
ls /usr/lib64/qt6/plugins/plasma/containmentactions/org.fennek.taskbarmenu.so /usr/lib64/qt6/plugins/kf6/kio/kio_thispc.so >/dev/null && grep -q "^RightButton;NoModifier=org.fennek.taskbarmenu" /usr/share/plasma/shells/org.kde.plasma.desktop/contents/defaults && ! rpm -q gcc-c++ >/dev/null || fail "taskbar menu + This PC plugins (and no compiler left in the image)"
grep -q "^AccentColor=109,69,184" /etc/xdg/kdeglobals && grep -q "sidebarFollowsTheme\", true" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "Fennek accent colour + visible Start strip"
grep -q "^ExpandableFolders=false" /etc/xdg/dolphinrc && grep -q "browser.tabs.inTitlebar" /etc/firefox/policies/policies.json || fail "classic details rows + Firefox system title bar"
[ -f /usr/share/icons/Bibata-Modern-Ice/cursors/left_ptr ] && grep -q "^cursorTheme=Bibata-Modern-Ice" /etc/xdg/kcminputrc && grep -q "^CursorTheme=Bibata-Modern-Ice" /etc/sddm.conf.d/10-fennek.conf || fail "Bibata cursor default"
grep -q "^font=Inter,10" /etc/xdg/kdeglobals && grep -q "^fixed=Cascadia Mono" /etc/xdg/kdeglobals && [ -n "$(fc-list :family=Inter)" ] && [ -n "$(fc-list ':family=Cascadia Mono')" ] || fail "Inter + Cascadia Mono fonts"
grep -q "^DefaultProfile=Fennek.profile" /etc/xdg/konsolerc && grep -q "^ColorScheme=Fennek" /usr/share/konsole/Fennek.profile && [ -s /usr/share/konsole/Fennek.colorscheme ] || fail "Fennek terminal profile"
grep -q "Fennek OS: a personal greeting" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/lockscreen/LockScreenUi.qml && grep -q "Fennek" /etc/xdg/kscreenlockerrc || fail "lock screen greeting + wallpaper"
grep -q "^LastSeenVersion=99" /etc/xdg/plasma-welcomerc || fail "only one welcome window"
[ -s /usr/share/fennek/apps/welcome/main.qml ] && grep -q "^Exec=fennek-app welcome" /usr/share/applications/fennek-welcome.desktop && grep -q "fennek-app welcome" /usr/libexec/fennek-first-login || fail "welcome app"
grep -q "Fennek OS splash" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/splash/Splash.qml && grep -q "Fennek OS splash" /usr/share/plasma/look-and-feel/org.fennek.dark.desktop/contents/splash/Splash.qml || fail "Fennek splash"
grep -q "nmi_watchdog=0" /usr/lib/bootc/kargs.d/20-fennek-battery.toml && grep -q "^vm.dirty_writeback_centisecs = 1500" /usr/lib/sysctl.d/60-fennek-battery.conf || fail "battery kernel settings"
grep -q "^ColorScheme=FennekDark" /usr/share/plasma/look-and-feel/org.fennek.dark.desktop/contents/defaults || fail "Fennek Dark colors"
grep -q "^theme=__aurorae__svg__FennekClassicDark" /usr/share/plasma/look-and-feel/org.fennek.dark.desktop/contents/defaults && grep -q "^theme=__aurorae__svg__FennekClassic$" /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/defaults && grep -q "fill=\"#202020\"" /usr/share/aurorae/themes/FennekClassicDark/decoration.svg && [ -s /usr/share/aurorae/themes/FennekClassicDark/FennekClassicDarkrc ] || fail "window frame follows light/dark theme"
! ls -d /usr/share/plasma/look-and-feel/org.fedoraproject.* 2>/dev/null || fail "Fedora global themes still listed"
! ls /usr/share/plasma/look-and-feel/org.kde.breeze*/contents/defaults 2>/dev/null || fail "KDE global themes still listed"
grep -q '^HomeUrl=thispc:/' /etc/xdg/dolphinrc && grep -q 'GroupedSorting=true' /etc/skel/.local/share/dolphin/view_properties/remote/.directory \
    && grep -q 'inode/x-fennek-drive' /usr/share/mime/types || fail "This PC page"
grep -q '^MenuBar=Enabled' /etc/xdg/dolphinrc                     || fail "Files menu bar"
grep -q 'panel.floating = false' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "taskbar layout"
grep -q '^LookAndFeelPackage=org.fennek.desktop' /usr/share/kde-settings/kde-profile/default/xdg/kdeglobals || fail "default lnf"
# What a fresh user actually gets: every kdeglobals in the system lookup must agree on Fennek's look.
for f in /etc/xdg/kdeglobals /usr/share/kde-settings/kde-profile/default/xdg/kdeglobals; do
    v=$(grep -h '^LookAndFeelPackage=' "$f" 2>/dev/null | tail -1)
    [ -z "$v" ] || [ "$v" = "LookAndFeelPackage=org.fennek.desktop" ] || fail "$f overrides the look: $v"
done
[ "$(XDG_CONFIG_DIRS=/etc/xdg:/usr/share/kde-settings/kde-profile/default/xdg HOME=$(mktemp -d) kreadconfig6 --group KDE --key LookAndFeelPackage)" = org.fennek.desktop ] \
                                                              || fail "a new user wouldn't get the Fennek look"
[ -x /usr/bin/fennek-vt-check ]                               || fail "vt-check executable"
fennek-vt-check --selftest >/dev/null                          || fail "vt-check selftest"
grep -q '^Exec=fennek-vt-check %F' /usr/share/kio/servicemenus/fennek-virustotal.desktop || fail "vt service menu"
command -v snapper >/dev/null                                || fail "snapper"
[ -x /usr/libexec/fennek-home-snapshots ]                      || fail "snapshot setup script"
bash -n /usr/libexec/fennek-home-snapshots                     || fail "snapshot script syntax"
for u in fennek-home-snapshots.service snapper-timeline.timer snapper-cleanup.timer; do
    systemctl is-enabled -q "$u"                              || fail "$u not enabled"
done
[ "$(stat -c %a /usr/lib/systemd/system/fennek-home-snapshots.service)" = 644 ] || fail "unit file perms"
grep -q 'wallpapers/Fennek/' /usr/lib/plasmalogin/defaults.conf || fail "login wallpaper"
wm=usr/share/plymouth/themes/spinner/watermark.png; img=$(ls /usr/lib/modules/*/initramfs.img)
[ "$(lsinitrd -f "$wm" "$img" | md5sum)" = "$(md5sum < "/$wm")" ] || fail "initramfs has Fennek OS splash"
{ rpm -V fedora-logos 2>/dev/null || true; } | grep -q "/$wm$" || fail "watermark still Fedora's"
/usr/libexec/fennek-download-guard --selftest >/dev/null    || fail "download guard selftest"
fennek-usage --selftest >/dev/null && [ -L /etc/systemd/user/default.target.wants/fennek-usage.service ] || fail "usage history"
grep -q "^Exec=fennek-app apphistory" /usr/share/applications/fennek-apphistory.desktop && [ -s /usr/share/fennek/apps/apphistory/main.qml ] || fail "App history window"
bash -n /usr/libexec/fennek-brightness && [ -x /usr/libexec/fennek-brightness ] || fail "brightness helper"
# Download guard: a sample matching a custom signature goes to quarantine, a clean file stays.
t=$(mktemp -d); mkdir -p "$t/db"
echo "Fennek OS fake malware sample" > "$t/evil.bin"; echo "harmless" > "$t/ok.txt"
sigtool --md5 "$t/evil.bin" > "$t/db/test.hdb"
HOME=$t XDG_DATA_HOME=$t/share FENNEK_CLAM_DB=$t/db /usr/libexec/fennek-download-guard "$t/evil.bin" "$t/ok.txt" >/dev/null
[ ! -e "$t/evil.bin" ] && compgen -G "$t/share/fennek/quarantine/*-evil.bin" >/dev/null || fail "threat not quarantined"
[ -e "$t/ok.txt" ]                                            || fail "clean file was touched"
tr '\0' '\n' < "$(compgen -G "$t/share/fennek/quarantine/*-evil.bin.fennek-info")" | grep -q "$t/evil.bin" \
                                                              || fail "quarantine doesn't record where the file came from"
rm -rf "$t"
# Watch mode: a file landing in Downloads gets scanned, even with a newline in its name.
t=$(mktemp -d); mkdir -p "$t/db" "$t/Downloads"
echo "Fennek fake malware sample" > "$t/sample"; sigtool --md5 "$t/sample" > "$t/db/test.hdb"
HOME=$t XDG_DATA_HOME=$t/share FENNEK_CLAM_DB=$t/db timeout 20 /usr/libexec/fennek-download-guard >/dev/null &
sleep 2; cp "$t/sample" "$t/Downloads/evil"$'\n'"name.bin"
for _ in $(seq 30); do compgen -G "$t/share/fennek/quarantine/*evil*" >/dev/null && break; sleep 0.5; done
compgen -G "$t/share/fennek/quarantine/*evil*" >/dev/null     || fail "watch mode didn't quarantine"
kill %1 2>/dev/null; wait 2>/dev/null; rm -rf "$t"
systemctl is-enabled -q clamav-freshclam-once.timer          || fail "freshclam timer"
[ -L /etc/systemd/user/default.target.wants/fennek-download-guard.service ] || fail "download guard not enabled"
if x86; then
    grep -q "Fennek OS patch: no network" /usr/lib/python3*/site-packages/umu/umu_runtime.py || fail "umu no-telemetry patch"
    python3 -c "import umu.umu_runtime" 2>/dev/null || fail "patched umu imports"
fi
[ "$(firewall-offline-cmd --get-default-zone 2>/dev/null)" = FennekOS ] || fail "default firewall zone"
[ -z "$(firewall-offline-cmd --zone=FennekOS --list-ports 2>/dev/null)" ] || fail "FennekOS zone opens ports"
[ "$(firewall-offline-cmd --zone=FennekOS-Public --list-services 2>/dev/null)" = dhcpv6-client ] || fail "public zone"
command -v opensnitchd >/dev/null                            || fail "opensnitchd"
! systemctl is-enabled -q opensnitch.service                  || fail "opensnitch must start only when something is blocked"
fennek-firewall --selftest >/dev/null                         || fail "firewall selftest"
/usr/libexec/fennek-first-login-places --selftest >/dev/null || fail "classic Files sidebar"
/usr/libexec/fennek-first-login-keyboard --selftest >/dev/null || fail "language switcher labels"
/usr/libexec/fennek-pin-quick-access --selftest >/dev/null && grep -q "^Exec=/usr/libexec/fennek-pin-quick-access" /usr/share/kio/servicemenus/fennek-pin-quick-access.desktop || fail "Pin to Quick access"
/usr/libexec/fennek-previous-versions-helper --selftest >/dev/null && command -v kdialog numfmt >/dev/null && grep -q "exec.path\">/usr/libexec/fennek-previous-versions-helper" /usr/share/polkit-1/actions/org.fennek.previous-versions.policy || fail "Restore previous versions"
grep -q '^Exec=fennek-firewall block %f' /usr/share/kio/servicemenus/fennek-firewall.desktop || fail "firewall menu"
[ -f /usr/share/plasma/plasmoids/com.github.zren.tiledmenu/metadata.json ] || fail "classic start menu (Tiled Menu)"
grep -q 'com.github.zren.tiledmenu' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "start menu in taskbar"
[ "$(systemctl is-enabled rpm-ostree-countme.timer 2>&1)" = masked ] || fail "countme telemetry timer"
! grep -q '^countme=1' /etc/yum.repos.d/*.repo                || fail "countme in repos"
! systemctl is-enabled -q dnf-makecache.timer 2>/dev/null      || fail "dnf-makecache timer (needless daily download)"
! systemctl is-enabled -q unbound-anchor.timer 2>/dev/null     || fail "unbound-anchor timer"
rpm -q firefox >/dev/null && grep -q '"DisableTelemetry": true' /etc/firefox/policies/policies.json || fail "Firefox + privacy policy"
grep -q '^Name=Files$' /usr/share/applications/org.kde.dolphin.desktop || fail "Files name"
grep -q '^Name=Task Manager$' /usr/share/applications/org.kde.plasma-systemmonitor.desktop || fail "Task Manager name"
grep -q '^X-KDE-Shortcuts=.*Ctrl+Shift+Esc' /usr/share/applications/org.kde.plasma-systemmonitor.desktop || fail "Ctrl+Shift+Esc"
grep -qs '^X-KDE-Shortcuts=.*Meta+R' /usr/share/kglobalaccel/org.kde.krunner.desktop /usr/share/applications/org.kde.krunner.desktop || fail "Win+R"
grep -q '^X-KDE-Shortcuts=.*Meta+E' /usr/share/kglobalaccel/org.kde.dolphin.desktop || fail "Super+E opens File Explorer"
grep -q '^X-KDE-Shortcuts=Meta+Shift+S,' /usr/share/applications/org.kde.spectacle.desktop || fail "Super+Shift+S snips a region"
[ "$(kreadconfig6 --file /etc/xdg/kglobalshortcutsrc --group kwin --key Overview | cut -f1)" = Meta+Tab ] || fail "Super+Tab task view"
grep -q 'actioncenter").globalShortcut = "Meta+A"' /usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js || fail "Super+A action center"
grep -q '^ViewMode=1' /etc/skel/.local/share/dolphin/view_properties/global/.directory || fail "Files details view"
q=$(ls -d /usr/lib*/qt6/qml/org/kde/desktop | head -1)
grep -q "wheelEnabled: false  // Fennek" "$q/ComboBox.qml" && grep -q "wheelEnabled: false  // Fennek" "$q/SpinBox.qml" \
    && grep -q "wheel.accepted = false; return;  // Fennek" "$q/Slider.qml" || fail "mouse-wheel comfort patch"
for f in "$q/ComboBox.qml" "$q/SpinBox.qml" "$q/Slider.qml" /etc/zshrc $(x86 && ls /usr/lib/python3*/site-packages/umu/umu_runtime.py); do
    [ "$(tr -d '\000' < "$f" | wc -c)" = "$(wc -c < "$f")" ] || fail "$f has zero bytes (broken in-place edit)"
done
id fsearch >/dev/null 2>&1 || useradd -m fsearch >/dev/null 2>&1
su fsearch -c "/usr/libexec/fennek-search --selftest" >/dev/null || fail "search selftest"
[ -L /etc/systemd/user/graphical-session.target.wants/fennek-search.service ] || fail "search service not enabled"
grep -q '^X-Plasma-DBusRunner-Service=org.fennek.Search' /usr/share/krunner/dbusplugins/fennek-search.desktop || fail "search runner"
for f in /usr/bin/fennek-* /usr/libexec/fennek-* /usr/lib/systemd/system/fennek-* /usr/share/plasma/plasmoids/com.github.zren.tiledmenu; do
    [ "$(stat -c %u:%g "$f")" = 0:0 ] || fail "$f not owned by root"
done
python3 -c "
import json; d = json.load(open('/etc/containers/policy.json'))['transports']['docker']['ghcr.io/olexify/fennekos'][0]
assert d['type'] == 'sigstoreSigned' and d['keyPath'] == '/etc/pki/containers/fennek-cosign.pub'
" 2>/dev/null                                                 || fail "updates must require Fennek's signature"
grep -q 'BEGIN PUBLIC KEY' /etc/pki/containers/fennek-cosign.pub || fail "Fennek public key"
grep -q '"rhgb", "quiet"' /usr/lib/bootc/kargs.d/10-fennek-splash.toml || fail "boot splash kernel args"
python3 -c "import json; p=json.load(open('/etc/firefox/policies/policies.json'))['policies']; assert p['DisableTelemetry'] and p['DisableFirefoxStudies']" \
                                                              || fail "Firefox telemetry policy"

# Privacy audit (informational, printed in CI logs): everything that could connect out. Keep PRIVACY.md in sync.
id fquar >/dev/null 2>&1 || useradd -m fquar >/dev/null 2>&1
su fquar -c "fennek-quarantine --selftest" >/dev/null           || fail "quarantine selftest"
command -v efibootmgr >/dev/null                             || fail "efibootmgr (Restart to Windows)"
/usr/libexec/fennek-reboot-windows-helper --selftest >/dev/null || fail "reboot-windows selftest"
systemctl is-enabled -q fennek-detect-windows.service         || fail "windows detection not enabled"
grep -q 'exec.path">/usr/libexec/fennek-reboot-windows-helper' /usr/share/polkit-1/actions/org.fennek.reboot-windows.policy \
                                                              || fail "reboot-windows polkit action"
# Sign-in screen: SDDM is THE display manager, uses the Fennek theme, and the theme loads without QML errors
# (a broken greeter means nobody can log in).
[ "$(readlink -f /etc/systemd/system/display-manager.service)" = /usr/lib/systemd/system/sddm.service ] || fail "display manager isn't SDDM"
grep -q '^Current=fennek' /etc/sddm.conf.d/10-fennek.conf                || fail "SDDM theme not selected"
greeter=$(command -v sddm-greeter-qt6 || command -v sddm-greeter)
# The test-mode greeter runs until stopped: timeout (exit 124) is expected; only QML errors count.
out=$(QT_QPA_PLATFORM=offscreen timeout 15 "$greeter" --test-mode --theme /usr/share/sddm/themes/fennek 2>&1 || true)
! grep -iE "qml.*(error|is not a type|not installed|unavailable|ReferenceError|TypeError)|file:///usr/share/sddm/themes/fennek/.*:[0-9]+" <<<"$out" \
                                                              || { echo "$out" | grep -iE "qml|fennek" | head; fail "SDDM theme has QML errors"; }
# Start menu default tiles: every tile must point to an installed app (no blank tiles).
python3 - <<'PY' || fail "Start menu tile points to a missing app"
import base64, json, os, re
js = open("/usr/share/plasma/look-and-feel/org.fennek.desktop/contents/layouts/org.kde.plasma.desktop-layout.js").read()
tiles = json.loads(base64.b64decode(re.search(r'writeConfig\("tileModel", "([^"]+)"\)', js).group(1)))
missing = [t["url"] for t in tiles if "url" in t and not os.path.exists("/usr/share/applications/" + t["url"])]
assert not missing, missing
assert sum(1 for t in tiles if t.get("tileType") == "group") >= 2
PY
# Fennek Settings: every page it links to exists (no dead buttons); Super+I belongs to it alone.
# Fennek's own apps run as normal windows (system look, own taskbar icon) through fennek-app.
rc=0; fennek-app ../etc 2>/dev/null || rc=$?; [ $rc -eq 2 ] && ! command -v g++ >/dev/null || fail "fennek-app launcher (rejects paths; no compiler left)"
for a in settings firewall welcome apphistory; do   # starts off-screen and keeps running = the QML loads
    rc=0; QT_QPA_PLATFORM=offscreen HOME=$(mktemp -d) timeout 8 fennek-app "$a" >/tmp/app-$a.log 2>&1 || rc=$?
    [ $rc -eq 124 ] || { tail -5 /tmp/app-$a.log; fail "app $a does not start (exit $rc)"; }
done
python3 - <<'PY' || fail "Fennek Settings links to something that isn't installed"
import glob, json, os, re, shutil
src = open("/usr/share/fennek/apps/settings/catalog.js").read()
cats = json.loads(src[src.index("["):])
kcms = {os.path.basename(p)[:-3] for p in glob.glob("/usr/lib64/qt6/plugins/plasma/kcms/**/*.so", recursive=True)}
bad = []
for c in cats:
    for i in c["items"]:
        if "kcm" in i and i["kcm"] not in kcms: bad.append(i["kcm"])
        if "cmd" in i and not shutil.which(i["cmd"].split()[0]): bad.append(i["cmd"])
assert not bad, bad
PY
python3 - <<'PY' || fail "Start right-click menu runs something that isn't installed"
import glob, os, re, shutil
src = open("/usr/share/plasma/plasmoids/com.github.zren.tiledmenu/contents/ui/main.qml").read()
cmds = re.findall(r'run\("([^"]+)"\)', src)
kcms = {os.path.basename(p)[:-3] for p in glob.glob("/usr/lib64/qt6/plugins/plasma/kcms/**/*.so", recursive=True)}
bad = [c for c in cmds if not shutil.which(c.split()[0]) or (c.startswith("systemsettings ") and c.split()[1] not in kcms)]
assert len(cmds) >= 10 and not bad, (len(cmds), bad)
PY
grep -q '^X-KDE-Shortcuts=Meta+I' /usr/share/applications/fennek-settings.desktop || fail "Super+I for Settings"
! grep -hs '^X-KDE-Shortcuts=.*Meta+I' /usr/share/kglobalaccel/systemsettings.desktop /usr/share/applications/systemsettings.desktop \
                                                              || fail "Super+I still on KDE System Settings too"
# Battery defaults: power-saver on battery, balanced on AC (needs a power-profiles provider, e.g. tuned-ppd).
[ "$(kreadconfig6 --file /etc/xdg/powerdevilrc --group Battery --group Performance --key PowerProfile)" = power-saver ] \
                                                              || fail "power-saver profile on battery"
[ "$(kreadconfig6 --file /etc/xdg/powerdevilrc --group AC --group Performance --key PowerProfile)" = balanced ] || fail "balanced on AC"
{ rpm -q tuned-ppd >/dev/null || rpm -q power-profiles-daemon >/dev/null; } || fail "no power-profiles provider"
[ "$(kreadconfig6 --file /etc/xdg/powerdevilrc --group BatteryManagement --key BatteryCriticalAction)" = 1 ] || fail "sleep on critical battery"
echo "--- privacy audit ---"
echo "enabled timers: $(systemctl list-unit-files --type=timer --state=enabled --no-legend 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
echo "user timers:    $(ls /etc/systemd/user/timers.target.wants/ 2>/dev/null | tr '\n' ' ')"
echo "NM connectivity: $(grep -rh '^uri=' /usr/lib/NetworkManager/conf.d/ /etc/NetworkManager/conf.d/ 2>/dev/null | tr '\n' ' ')"
echo "services:       $(systemctl list-unit-files --type=service --state=enabled --no-legend 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
echo "user services:  $(systemctl --global list-unit-files --type=service --state=enabled --no-legend 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
echo "start menu apps: $(grep -L -E '^(NoDisplay|Hidden)=true' /usr/share/applications/*.desktop | xargs -n1 basename | tr '\n' ' ')"
echo "time zone map assets: $(rpm -ql plasma-workspace kf6-kitemmodels plasma-desktop 2>/dev/null | grep -iE 'zone|world|map' | grep -viE 'locale|\.mo$|keymap' | head -20 | tr '\n' ' ')"
echo "firefox: $(rpm -q firefox 2>/dev/null || echo 'not installed (rpm)')"
echo "--- end audit ---"
echo "all checks passed"
