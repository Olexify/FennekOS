.pragma library
// Fennek Settings catalog. Each item opens a KDE settings page inside Settings ("kcm"), one of
// Fennek's own pages ("page": /usr/share/fennek/apps/NAME/Page.qml) or runs a command.
// "optional": shown only where that page is installed (KDE version, ARM). test.sh parses the JSON below and
// checks every other kcm and command exists in the image: keep it strict JSON.
var categories = [
 {"name": "System", "icon": "fennek-settings-system", "sub": "Display, sound, notifications, power",
  "items": [
   {"name": "Display", "kcm": "kcm_kscreen", "icon": "fennek-set-display", "desc": "Resolution, scaling, night light"},
   {"name": "Night light", "kcm": "kcm_nightlight", "icon": "fennek-set-nightlight", "desc": "Warmer screen in the evening", "optional": true},
   {"name": "Sound", "kcm": "kcm_pulseaudio", "icon": "fennek-set-sound", "desc": "Speakers, microphones, volume"},
   {"name": "Notifications", "kcm": "kcm_notifications", "icon": "fennek-set-notifications", "desc": "Popups, do not disturb"},
   {"name": "Multitasking", "kcm": "kcm_kwinoptions", "icon": "fennek-set-multitasking", "desc": "Window behaviour, focus, snapping", "optional": true},
   {"name": "Virtual desktops", "kcm": "kcm_kwin_virtualdesktops", "icon": "fennek-set-desktops", "desc": "Several desktops, switching between them", "optional": true},
   {"name": "Task switcher", "kcm": "kcm_kwintabbox", "icon": "fennek-set-switcher", "desc": "Alt+Tab", "optional": true},
   {"name": "Screen edges", "kcm": "kcm_kwinscreenedges", "icon": "fennek-set-edges", "desc": "Corners and edges, touch gestures", "optional": true},
   {"name": "Power & battery", "kcm": "kcm_powerdevilprofilesconfig", "icon": "fennek-set-power", "desc": "Sleep, screen off, battery saving"},
   {"name": "Battery & app usage", "cmd": "fennek-app apphistory", "icon": "fennek-set-apphistory", "desc": "Which apps used the battery"},
   {"name": "Storage", "cmd": "filelight", "icon": "fennek-set-storage", "desc": "What uses space on your disks"},
   {"name": "Removable drives", "kcm": "kcm_device_automounter", "icon": "fennek-set-removable", "desc": "What happens when you plug in a drive", "optional": true},
   {"name": "About this computer", "kcm": "kcm_about-distro", "icon": "fennek-set-about", "desc": "Version, hardware"}
  ]},
 {"name": "Devices", "icon": "fennek-settings-devices", "sub": "Bluetooth, printers, mouse, keyboard",
  "items": [
   {"name": "Bluetooth", "kcm": "kcm_bluetooth", "icon": "fennek-set-bluetooth", "desc": "Pair headphones, mice, phones"},
   {"name": "Printers", "kcm": "kcm_printer_manager", "icon": "fennek-set-printer", "desc": "Add and manage printers"},
   {"name": "Mouse", "kcm": "kcm_mouse", "icon": "fennek-set-mouse", "desc": "Speed, buttons, scrolling"},
   {"name": "Touchpad", "kcm": "kcm_touchpad", "icon": "fennek-set-touchpad", "desc": "Tapping, gestures"},
   {"name": "Keyboard", "kcm": "kcm_keyboard", "icon": "fennek-set-keyboard", "desc": "Layouts, repeat rate"},
   {"name": "Game controllers", "kcm": "kcm_gamecontroller", "icon": "fennek-set-gamepad", "desc": "Test and set up gamepads", "optional": true},
   {"name": "Drawing tablet", "kcm": "kcm_tablet", "icon": "fennek-set-tablet", "desc": "Pen buttons, screen area", "optional": true},
   {"name": "Touchscreen", "kcm": "kcm_touchscreen", "icon": "fennek-set-touchscreen", "desc": "Touch input", "optional": true},
   {"name": "Thunderbolt", "kcm": "kcm_bolt", "icon": "fennek-set-thunderbolt", "desc": "Allow Thunderbolt devices", "optional": true}
  ]},
 {"name": "Network & Internet", "icon": "fennek-settings-network", "sub": "Wi-Fi, VPN, firewall",
  "items": [
   {"name": "Wi-Fi & networks", "kcm": "kcm_networkmanagement", "icon": "fennek-set-wifi", "desc": "Connections, VPN, hotspot"},
   {"name": "Proxy", "kcm": "kcm_proxy", "icon": "fennek-set-proxy", "desc": "Proxy server"},
   {"name": "Phone link", "kcm": "kcm_kdeconnect", "icon": "fennek-set-phone", "desc": "Your phone: files, notifications, clipboard", "optional": true}
  ]},
 {"name": "Appearance", "icon": "fennek-settings-appearance", "sub": "Background, colors, themes, fonts",
  "items": [
   {"name": "Background", "kcm": "kcm_wallpaper", "icon": "fennek-set-background", "desc": "Desktop picture"},
   {"name": "Themes", "kcm": "kcm_lookandfeel", "icon": "fennek-set-themes", "desc": "Whole look of Fennek OS"},
   {"name": "Colors", "kcm": "kcm_colors", "icon": "fennek-set-colors", "desc": "Light, dark, accent color"},
   {"name": "Fonts", "kcm": "kcm_fonts", "icon": "fennek-set-fonts", "desc": "Size and style of text"},
   {"name": "Icons", "kcm": "kcm_icons", "icon": "fennek-set-icons", "desc": "Icon style and size", "optional": true},
   {"name": "App style", "kcm": "kcm_style", "icon": "fennek-set-appstyle", "desc": "How buttons and windows look", "optional": true},
   {"name": "Window frames", "kcm": "kcm_kwindecoration", "icon": "fennek-set-windowframes", "desc": "Title bars and buttons", "optional": true},
   {"name": "Desktop effects", "kcm": "kcm_kwin_effects", "icon": "fennek-set-effects", "desc": "Animations, transparency, zoom", "optional": true},
   {"name": "Animation speed", "kcm": "kcm_workspace", "icon": "fennek-set-animation", "desc": "Animations, clicks, tooltips", "optional": true},
   {"name": "Startup screen", "kcm": "kcm_splashscreen", "icon": "fennek-set-splash", "desc": "The picture while Fennek starts", "optional": true},
   {"name": "Lock screen", "kcm": "kcm_screenlocker", "icon": "fennek-set-lockscreen", "desc": "When and how the screen locks"},
   {"name": "Sign-in screen", "kcm": "kcm_sddm", "icon": "fennek-set-signin", "desc": "The screen where you sign in", "optional": true},
   {"name": "Pointers & launch feedback", "kcm": "kcm_cursortheme", "icon": "fennek-set-pointer", "desc": "Pointer style and size; busy pointer or bouncing icon while an app starts"},
   {"name": "Restore taskbar & Start", "cmd": "/usr/libexec/fennek-reset-layout", "icon": "fennek-set-restore", "desc": "Back to the default layout if something got moved or removed"}
  ]},
 {"name": "Apps", "icon": "fennek-settings-apps", "sub": "Default apps, startup apps",
  "items": [
   {"name": "Default apps", "kcm": "kcm_componentchooser", "icon": "fennek-set-defaultapps", "desc": "Browser, email, music player"},
   {"name": "File types", "kcm": "kcm_filetypes", "icon": "fennek-set-filetypes", "desc": "Which app opens which file", "optional": true},
   {"name": "Startup apps", "kcm": "kcm_autostart", "icon": "fennek-set-startup", "desc": "Apps that start when you sign in"},
   {"name": "Window rules", "kcm": "kcm_kwinrules", "icon": "fennek-set-windowrules", "desc": "Special settings for certain windows", "optional": true},
   {"name": "Spell check", "kcm": "kcm_spellchecking", "icon": "fennek-set-spellcheck", "desc": "Languages, autocorrect", "optional": true},
   {"name": "Search", "kcm": "kcm_plasmasearch", "icon": "fennek-set-search", "desc": "What Start and the Run box find", "optional": true},
   {"name": "Install or remove apps", "cmd": "plasma-discover", "icon": "plasmadiscover", "desc": "Store"}
  ]},
 {"name": "Accounts", "icon": "fennek-settings-accounts", "sub": "Your account, other people",
  "items": [
   {"name": "Your account & others", "kcm": "kcm_users", "icon": "fennek-set-users", "desc": "Picture, password, add people"},
   {"name": "Online accounts", "kcm": "kcm_kaccounts", "icon": "fennek-set-online", "desc": "Cloud and online services", "optional": true},
   {"name": "Saved passwords", "kcm": "kcm_kwallet5", "icon": "fennek-set-passwords", "desc": "The password store apps use", "optional": true}
  ]},
 {"name": "Time & Language", "icon": "fennek-settings-time", "sub": "Date, region, language",
  "items": [
   {"name": "Date & time", "kcm": "kcm_clock", "icon": "fennek-set-clock", "desc": "Time zone, clock"},
   {"name": "Region & language", "kcm": "kcm_regionandlang", "icon": "fennek-set-region", "desc": "Language, formats"}
  ]},
 {"name": "Accessibility", "icon": "fennek-settings-accessibility", "sub": "Assistive features, keyboard shortcuts",
  "items": [
   {"name": "Assistive features", "kcm": "kcm_access", "icon": "fennek-set-access", "desc": "Sticky keys, visual bell"},
   {"name": "Keyboard shortcuts", "kcm": "kcm_keys", "icon": "fennek-set-shortcuts", "desc": "Change shortcuts"},
   {"name": "Activities", "kcm": "kcm_activities", "icon": "fennek-set-activities", "desc": "Separate sets of windows for work and play", "optional": true}
  ]},
 {"name": "Privacy & Security", "icon": "fennek-settings-privacy", "sub": "Firewall, quarantine, permissions",
  "items": [
   {"name": "Firewall", "cmd": "fennek-app firewall", "icon": "fennek-set-firewall", "desc": "Choose which apps may use the internet"},
   {"name": "Quarantine", "cmd": "fennek-quarantine", "icon": "fennek-set-quarantine", "desc": "Downloads the antivirus blocked"},
   {"name": "App permissions", "kcm": "kcm_app-permissions", "icon": "fennek-set-permissions", "desc": "What store apps may access"},
   {"name": "Recent files", "kcm": "kcm_recentFiles", "icon": "fennek-set-recent", "desc": "What Fennek remembers you opened", "optional": true},
   {"name": "Sign out and restart", "kcm": "kcm_smserver", "icon": "fennek-set-signout", "desc": "What happens when you sign out", "optional": true},
   {"name": "Privacy policy", "cmd": "xdg-open https://github.com/Olexify/FennekOS/blob/main/PRIVACY.md", "icon": "fennek-set-privacypolicy", "desc": "Every connection Fennek OS makes"}
  ]},
 {"name": "Update & Recovery", "icon": "fennek-settings-update", "sub": "Updates, backup, previous versions",
  "items": [
   {"name": "Updates", "icon": "fennek-set-updates", "desc": "Status, automatic updates, schedule, pause", "page": "updates"},
   {"name": "Store app updates", "cmd": "plasma-discover --mode update", "icon": "fennek-set-storeupdates", "desc": "Update Store apps now"},
   {"name": "Go back", "cmd": "fennek-go-back", "icon": "fennek-set-goback", "desc": "Undo the last update, keep your files"},
   {"name": "Backup", "cmd": "fennek-app backup", "icon": "fennek-set-backup", "desc": "Copy your folders to a USB drive"}
  ]}
]
