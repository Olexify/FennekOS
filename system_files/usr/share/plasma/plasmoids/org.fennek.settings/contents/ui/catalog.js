.pragma library
// Fennek Settings catalog. Each item opens a KDE settings page ("kcm": systemsettings <kcm>) or runs a command.
// test.sh parses the JSON below and checks every kcm exists in the image: keep it strict JSON.
var categories = [
 {"name": "System", "icon": "computer", "sub": "Display, sound, notifications, power",
  "items": [
   {"name": "Display", "kcm": "kcm_kscreen", "icon": "video-display", "desc": "Resolution, scaling, night light"},
   {"name": "Sound", "kcm": "kcm_pulseaudio", "icon": "audio-volume-high", "desc": "Speakers, microphones, volume"},
   {"name": "Notifications", "kcm": "kcm_notifications", "icon": "preferences-desktop-notification-bell", "desc": "Popups, do not disturb"},
   {"name": "Power & battery", "kcm": "kcm_powerdevilprofilesconfig", "icon": "preferences-system-power-management", "desc": "Sleep, screen off, battery saving"},
   {"name": "Storage", "cmd": "filelight", "icon": "drive-harddisk", "desc": "What uses space on your disks"},
   {"name": "About this computer", "kcm": "kcm_about-distro", "icon": "help-about", "desc": "Version, hardware"}
  ]},
 {"name": "Devices", "icon": "preferences-devices", "sub": "Bluetooth, printers, mouse, keyboard",
  "items": [
   {"name": "Bluetooth", "kcm": "kcm_bluetooth", "icon": "preferences-system-bluetooth", "desc": "Pair headphones, mice, phones"},
   {"name": "Printers", "kcm": "kcm_printer_manager", "icon": "printer", "desc": "Add and manage printers"},
   {"name": "Mouse", "kcm": "kcm_mouse", "icon": "input-mouse", "desc": "Speed, buttons, scrolling"},
   {"name": "Touchpad", "kcm": "kcm_touchpad", "icon": "input-touchpad", "desc": "Tapping, gestures"},
   {"name": "Keyboard", "kcm": "kcm_keyboard", "icon": "input-keyboard", "desc": "Layouts, repeat rate"}
  ]},
 {"name": "Network & Internet", "icon": "network-wireless", "sub": "Wi-Fi, VPN, firewall",
  "items": [
   {"name": "Wi-Fi & networks", "kcm": "kcm_networkmanagement", "icon": "network-wireless", "desc": "Connections, VPN, hotspot"},
   {"name": "Proxy", "kcm": "kcm_proxy", "icon": "preferences-system-network-proxy", "desc": "Proxy server"}
  ]},
 {"name": "Appearance", "icon": "preferences-desktop-theme-global", "sub": "Background, colors, themes, fonts",
  "items": [
   {"name": "Background", "kcm": "kcm_wallpaper", "icon": "preferences-desktop-wallpaper", "desc": "Desktop picture"},
   {"name": "Themes", "kcm": "kcm_lookandfeel", "icon": "preferences-desktop-theme-global", "desc": "Whole look of Fennek OS"},
   {"name": "Colors", "kcm": "kcm_colors", "icon": "preferences-desktop-color", "desc": "Light, dark, accent color"},
   {"name": "Fonts", "kcm": "kcm_fonts", "icon": "preferences-desktop-font", "desc": "Size and style of text"},
   {"name": "Lock screen", "kcm": "kcm_screenlocker", "icon": "preferences-desktop-user-password", "desc": "When and how the screen locks"}
  ]},
 {"name": "Apps", "icon": "preferences-desktop-default-applications", "sub": "Default apps, startup apps",
  "items": [
   {"name": "Default apps", "kcm": "kcm_componentchooser", "icon": "preferences-desktop-default-applications", "desc": "Browser, email, music player"},
   {"name": "Startup apps", "kcm": "kcm_autostart", "icon": "system-run", "desc": "Apps that start when you sign in"},
   {"name": "Install or remove apps", "cmd": "plasma-discover", "icon": "plasmadiscover", "desc": "Store"}
  ]},
 {"name": "Accounts", "icon": "system-users", "sub": "Your account, other people",
  "items": [
   {"name": "Your account & others", "kcm": "kcm_users", "icon": "system-users", "desc": "Picture, password, add people"}
  ]},
 {"name": "Time & Language", "icon": "preferences-system-time", "sub": "Date, region, language",
  "items": [
   {"name": "Date & time", "kcm": "kcm_clock", "icon": "preferences-system-time", "desc": "Time zone, clock"},
   {"name": "Region & language", "kcm": "kcm_regionandlang", "icon": "preferences-desktop-locale", "desc": "Language, formats"}
  ]},
 {"name": "Accessibility", "icon": "preferences-desktop-accessibility", "sub": "Assistive features, keyboard shortcuts",
  "items": [
   {"name": "Assistive features", "kcm": "kcm_access", "icon": "preferences-desktop-accessibility", "desc": "Sticky keys, visual bell"},
   {"name": "Keyboard shortcuts", "kcm": "kcm_keys", "icon": "preferences-desktop-keyboard-shortcut", "desc": "Change shortcuts"}
  ]},
 {"name": "Privacy & Security", "icon": "security-high", "sub": "Quarantine, file history, permissions",
  "items": [
   {"name": "Quarantine", "cmd": "fennek-quarantine", "icon": "security-medium", "desc": "Downloads the antivirus blocked"},
   {"name": "App permissions", "kcm": "kcm_flatpak", "icon": "preferences-system-privacy", "desc": "What store apps may access"},
   {"name": "Privacy policy", "cmd": "xdg-open https://github.com/Olexify/FennekOS/blob/main/PRIVACY.md", "icon": "help-about", "desc": "Every connection Fennek OS makes"}
  ]},
 {"name": "Update & Recovery", "icon": "system-software-update", "sub": "Updates, previous versions",
  "items": [
   {"name": "Updates", "cmd": "plasma-discover --mode update", "icon": "system-software-update", "desc": "Fennek OS and app updates"}
  ]}
]
