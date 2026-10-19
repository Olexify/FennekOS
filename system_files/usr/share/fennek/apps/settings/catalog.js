.pragma library
// Fennek Settings catalog. Each item opens a KDE settings page inside Settings ("kcm") or runs a command.
// "optional": shown only where that page is installed (KDE version, ARM). test.sh parses the JSON below and
// checks every other kcm and command exists in the image: keep it strict JSON.
var categories = [
 {"name": "System", "icon": "fennek-settings-system", "sub": "Display, sound, notifications, power",
  "items": [
   {"name": "Display", "kcm": "kcm_kscreen", "icon": "video-display", "desc": "Resolution, scaling, night light"},
   {"name": "Night light", "kcm": "kcm_nightlight", "icon": "redshift-status-on", "desc": "Warmer screen in the evening", "optional": true},
   {"name": "Sound", "kcm": "kcm_pulseaudio", "icon": "audio-volume-high", "desc": "Speakers, microphones, volume"},
   {"name": "Notifications", "kcm": "kcm_notifications", "icon": "preferences-desktop-notification-bell", "desc": "Popups, do not disturb"},
   {"name": "Multitasking", "kcm": "kcm_kwinoptions", "icon": "preferences-system-windows-actions", "desc": "Window behaviour, focus, snapping", "optional": true},
   {"name": "Virtual desktops", "kcm": "kcm_kwin_virtualdesktops", "icon": "preferences-virtual-desktops", "desc": "Several desktops, switching between them", "optional": true},
   {"name": "Task switcher", "kcm": "kcm_kwintabbox", "icon": "preferences-system-tabbox", "desc": "Alt+Tab", "optional": true},
   {"name": "Screen edges", "kcm": "kcm_kwinscreenedges", "icon": "preferences-desktop-screen-edges", "desc": "Corners and edges, touch gestures", "optional": true},
   {"name": "Power & battery", "kcm": "kcm_powerdevilprofilesconfig", "icon": "preferences-system-power-management", "desc": "Sleep, screen off, battery saving"},
   {"name": "Battery & app usage", "cmd": "fennek-app apphistory", "icon": "fennek-apphistory", "desc": "Which apps used the battery"},
   {"name": "Storage", "cmd": "filelight", "icon": "drive-harddisk", "desc": "What uses space on your disks"},
   {"name": "Removable drives", "kcm": "kcm_device_automounter", "icon": "drive-removable-media", "desc": "What happens when you plug in a drive", "optional": true},
   {"name": "About this computer", "kcm": "kcm_about-distro", "icon": "help-about", "desc": "Version, hardware"}
  ]},
 {"name": "Devices", "icon": "fennek-settings-devices", "sub": "Bluetooth, printers, mouse, keyboard",
  "items": [
   {"name": "Bluetooth", "kcm": "kcm_bluetooth", "icon": "preferences-system-bluetooth", "desc": "Pair headphones, mice, phones"},
   {"name": "Printers", "kcm": "kcm_printer_manager", "icon": "printer", "desc": "Add and manage printers"},
   {"name": "Mouse", "kcm": "kcm_mouse", "icon": "input-mouse", "desc": "Speed, buttons, scrolling"},
   {"name": "Touchpad", "kcm": "kcm_touchpad", "icon": "input-touchpad", "desc": "Tapping, gestures"},
   {"name": "Keyboard", "kcm": "kcm_keyboard", "icon": "input-keyboard", "desc": "Layouts, repeat rate"},
   {"name": "Game controllers", "kcm": "kcm_gamecontroller", "icon": "input-gaming", "desc": "Test and set up gamepads", "optional": true},
   {"name": "Drawing tablet", "kcm": "kcm_tablet", "icon": "input-tablet", "desc": "Pen buttons, screen area", "optional": true},
   {"name": "Touchscreen", "kcm": "kcm_touchscreen", "icon": "input-touchscreen", "desc": "Touch input", "optional": true},
   {"name": "Thunderbolt", "kcm": "kcm_bolt", "icon": "preferences-desktop-thunderbolt", "desc": "Allow Thunderbolt devices", "optional": true}
  ]},
 {"name": "Network & Internet", "icon": "fennek-settings-network", "sub": "Wi-Fi, VPN, firewall",
  "items": [
   {"name": "Wi-Fi & networks", "kcm": "kcm_networkmanagement", "icon": "network-wireless", "desc": "Connections, VPN, hotspot"},
   {"name": "Proxy", "kcm": "kcm_proxy", "icon": "preferences-system-network-proxy", "desc": "Proxy server"},
   {"name": "Phone link", "kcm": "kcm_kdeconnect", "icon": "kdeconnect", "desc": "Your phone: files, notifications, clipboard", "optional": true}
  ]},
 {"name": "Appearance", "icon": "fennek-settings-appearance", "sub": "Background, colors, themes, fonts",
  "items": [
   {"name": "Background", "kcm": "kcm_wallpaper", "icon": "preferences-desktop-wallpaper", "desc": "Desktop picture"},
   {"name": "Themes", "kcm": "kcm_lookandfeel", "icon": "preferences-desktop-theme-global", "desc": "Whole look of Fennek OS"},
   {"name": "Colors", "kcm": "kcm_colors", "icon": "preferences-desktop-color", "desc": "Light, dark, accent color"},
   {"name": "Fonts", "kcm": "kcm_fonts", "icon": "preferences-desktop-font", "desc": "Size and style of text"},
   {"name": "Icons", "kcm": "kcm_icons", "icon": "preferences-desktop-icons", "desc": "Icon style and size", "optional": true},
   {"name": "App style", "kcm": "kcm_style", "icon": "preferences-desktop-theme-applications", "desc": "How buttons and windows look", "optional": true},
   {"name": "Window frames", "kcm": "kcm_kwindecoration", "icon": "preferences-desktop-theme-windowdecorations", "desc": "Title bars and buttons", "optional": true},
   {"name": "Desktop effects", "kcm": "kcm_kwin_effects", "icon": "preferences-desktop-effects", "desc": "Animations, transparency, zoom", "optional": true},
   {"name": "Animation speed", "kcm": "kcm_workspace", "icon": "preferences-desktop", "desc": "Animations, clicks, tooltips", "optional": true},
   {"name": "Startup screen", "kcm": "kcm_splashscreen", "icon": "preferences-desktop-splash", "desc": "The picture while Fennek starts", "optional": true},
   {"name": "Lock screen", "kcm": "kcm_screenlocker", "icon": "preferences-desktop-user-password", "desc": "When and how the screen locks"},
   {"name": "Sign-in screen", "kcm": "kcm_sddm", "icon": "preferences-system-login", "desc": "The screen where you sign in", "optional": true},
   {"name": "Pointers & launch feedback", "kcm": "kcm_cursortheme", "icon": "preferences-desktop-cursors", "desc": "Pointer style and size; busy pointer or bouncing icon while an app starts"},
   {"name": "Restore taskbar & Start", "cmd": "/usr/libexec/fennek-reset-layout", "icon": "edit-undo", "desc": "Back to the default layout if something got moved or removed"}
  ]},
 {"name": "Apps", "icon": "fennek-settings-apps", "sub": "Default apps, startup apps",
  "items": [
   {"name": "Default apps", "kcm": "kcm_componentchooser", "icon": "preferences-desktop-default-applications", "desc": "Browser, email, music player"},
   {"name": "File types", "kcm": "kcm_filetypes", "icon": "preferences-desktop-filetype-association", "desc": "Which app opens which file", "optional": true},
   {"name": "Startup apps", "kcm": "kcm_autostart", "icon": "system-run", "desc": "Apps that start when you sign in"},
   {"name": "Window rules", "kcm": "kcm_kwinrules", "icon": "preferences-system-windows-actions", "desc": "Special settings for certain windows", "optional": true},
   {"name": "Spell check", "kcm": "kcm_spellchecking", "icon": "tools-check-spelling", "desc": "Languages, autocorrect", "optional": true},
   {"name": "Search", "kcm": "kcm_plasmasearch", "icon": "preferences-desktop-search", "desc": "What Start and the Run box find", "optional": true},
   {"name": "Install or remove apps", "cmd": "plasma-discover", "icon": "plasmadiscover", "desc": "Store"}
  ]},
 {"name": "Accounts", "icon": "fennek-settings-accounts", "sub": "Your account, other people",
  "items": [
   {"name": "Your account & others", "kcm": "kcm_users", "icon": "system-users", "desc": "Picture, password, add people"},
   {"name": "Online accounts", "kcm": "kcm_kaccounts", "icon": "preferences-online-accounts", "desc": "Cloud and online services", "optional": true},
   {"name": "Saved passwords", "kcm": "kcm_kwallet5", "icon": "kwalletmanager", "desc": "The password store apps use", "optional": true}
  ]},
 {"name": "Time & Language", "icon": "fennek-settings-time", "sub": "Date, region, language",
  "items": [
   {"name": "Date & time", "kcm": "kcm_clock", "icon": "preferences-system-time", "desc": "Time zone, clock"},
   {"name": "Region & language", "kcm": "kcm_regionandlang", "icon": "preferences-desktop-locale", "desc": "Language, formats"}
  ]},
 {"name": "Accessibility", "icon": "fennek-settings-accessibility", "sub": "Assistive features, keyboard shortcuts",
  "items": [
   {"name": "Assistive features", "kcm": "kcm_access", "icon": "preferences-desktop-accessibility", "desc": "Sticky keys, visual bell"},
   {"name": "Keyboard shortcuts", "kcm": "kcm_keys", "icon": "preferences-desktop-keyboard-shortcut", "desc": "Change shortcuts"},
   {"name": "Activities", "kcm": "kcm_activities", "icon": "preferences-activities", "desc": "Separate sets of windows for work and play", "optional": true}
  ]},
 {"name": "Privacy & Security", "icon": "fennek-settings-privacy", "sub": "Firewall, quarantine, permissions",
  "items": [
   {"name": "Firewall", "cmd": "fennek-app firewall", "icon": "security-high", "desc": "Choose which apps may use the internet"},
   {"name": "Quarantine", "cmd": "fennek-quarantine", "icon": "security-medium", "desc": "Downloads the antivirus blocked"},
   {"name": "App permissions", "kcm": "kcm_app-permissions", "icon": "preferences-system-privacy", "desc": "What store apps may access"},
   {"name": "Recent files", "kcm": "kcm_recentFiles", "icon": "document-open-recent", "desc": "What Fennek remembers you opened", "optional": true},
   {"name": "Sign out and restart", "kcm": "kcm_smserver", "icon": "system-log-out", "desc": "What happens when you sign out", "optional": true},
   {"name": "Privacy policy", "cmd": "xdg-open https://github.com/Olexify/FennekOS/blob/main/PRIVACY.md", "icon": "help-about", "desc": "Every connection Fennek OS makes"}
  ]},
 {"name": "Update & Recovery", "icon": "fennek-settings-update", "sub": "Updates, backup, previous versions",
  "items": [
   {"name": "Updates", "cmd": "fennek-app updates", "icon": "system-software-update", "desc": "Status, automatic updates, schedule, pause"},
   {"name": "Store app updates", "cmd": "plasma-discover --mode update", "icon": "plasmadiscover", "desc": "Update Store apps now"},
   {"name": "Go back", "cmd": "fennek-go-back", "icon": "edit-undo", "desc": "Undo the last update, keep your files"},
   {"name": "Backup", "cmd": "fennek-app backup", "icon": "drive-removable-media", "desc": "Copy your folders to a USB drive"}
  ]}
]
