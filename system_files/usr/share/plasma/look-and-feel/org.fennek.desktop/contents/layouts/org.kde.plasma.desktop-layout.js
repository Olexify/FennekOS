// Classic taskbar: full width, docked at the bottom, 40 px, no virtual-desktop pager.
var panel = new Panel
panel.location = "bottom"
panel.floating = false   // docked to the screen edge, never floating
panel.hiding = "none"    // always visible
panel.height = 40

// Classic Start menu (Tiled Menu): left rail, A-Z list with "Recently added", tile groups.
var start = panel.addWidget("com.github.zren.tiledmenu")
start.currentConfigGroup = ["General"]
start.writeConfig("icon", "fennek")
// Clean, theme-matched Start: icons in the left strip and the search box follow the system colours (so Power
// and the user picture are always visible), tiles in the Fennek accent violet, app names without descriptions.
start.writeConfig("sidebarFollowsTheme", true)
start.writeConfig("searchFieldFollowsTheme", true)
start.writeConfig("defaultTileColor", "#6d45b8")
start.writeConfig("appDescription", "hidden")
start.writeConfig("sidebarShortcuts", ["xdg:DOCUMENTS", "xdg:DOWNLOAD", "xdg:PICTURES", "xdg:VIDEOS", "fennek-settings.desktop"])
// Default tiles, classic: named groups, big and small tiles (base64 JSON, Tiled Menu's format;
// test.sh checks every tile points to an installed app). Groups: Fennek, Safety.
start.writeConfig("tileModel", "W3sieCI6MCwieSI6MCwidyI6NiwiaCI6MSwidGlsZVR5cGUiOiJncm91cCIsImxhYmVsIjoiRmVubmVrIn0seyJ4IjowLCJ5IjoxLCJ3IjoyLCJoIjoyLCJ1cmwiOiJvcmcubW96aWxsYS5maXJlZm94LmRlc2t0b3AiLCJsYWJlbCI6IkZpcmVmb3gifSx7IngiOjIsInkiOjEsInciOjIsImgiOjIsInVybCI6Im9yZy5rZGUuZG9scGhpbi5kZXNrdG9wIiwibGFiZWwiOiJGaWxlcyJ9LHsieCI6NCwieSI6MSwidyI6MSwiaCI6MSwidXJsIjoiZmVubmVrLXNldHRpbmdzLmRlc2t0b3AiLCJsYWJlbCI6IlNldHRpbmdzIn0seyJ4Ijo1LCJ5IjoxLCJ3IjoxLCJoIjoxLCJ1cmwiOiJvcmcua2RlLmRpc2NvdmVyLmRlc2t0b3AiLCJsYWJlbCI6IlN0b3JlIn0seyJ4Ijo0LCJ5IjoyLCJ3IjoxLCJoIjoxLCJ1cmwiOiJvcmcua2RlLmtvbnNvbGUuZGVza3RvcCIsImxhYmVsIjoiVGVybWluYWwifSx7IngiOjUsInkiOjIsInciOjEsImgiOjEsInVybCI6Im9yZy5rZGUua3dyaXRlLmRlc2t0b3AiLCJsYWJlbCI6IlRleHQgRWRpdG9yIn0seyJ4IjowLCJ5IjozLCJ3Ijo2LCJoIjoxLCJ0aWxlVHlwZSI6Imdyb3VwIiwibGFiZWwiOiJTYWZldHkifSx7IngiOjAsInkiOjQsInciOjIsImgiOjIsInVybCI6Im9yZy5rZGUucGxhc21hLXN5c3RlbW1vbml0b3IuZGVza3RvcCIsImxhYmVsIjoiVGFzayBNYW5hZ2VyIn0seyJ4IjoyLCJ5Ijo0LCJ3IjoyLCJoIjoyLCJ1cmwiOiJmZW5uZWstcXVhcmFudGluZS5kZXNrdG9wIiwibGFiZWwiOiJRdWFyYW50aW5lIn1d")
start.writeConfig("favoriteApps", ["preferred://browser", "org.kde.dolphin.desktop", "fennek-settings.desktop",
                                   "org.kde.konsole.desktop", "org.kde.discover.desktop"])

// Classic order: Start, search box, window overview button, then the app icons.
panel.addWidget("org.fennek.searchbox")
panel.addWidget("org.fennek.taskview")
panel.addWidget("org.kde.plasma.icontasks")
panel.addWidget("org.kde.plasma.marginsseparator")
// Tray: network, sound, battery and language always visible; everything else behind the ^ arrow.
var systray = panel.addWidget("org.kde.plasma.systemtray")
var tray = desktopById(systray.readConfig("SystrayContainmentId"))
if (tray) {
    tray.currentConfigGroup = ["General"]
    tray.writeConfig("shownItems", ["org.kde.plasma.networkmanagement", "org.fennek.volume",
                                    "org.kde.plasma.battery", "org.kde.plasma.keyboardlayout"])
    tray.writeConfig("hiddenItems", ["org.kde.plasma.volume", "org.kde.plasma.clipboard", "org.kde.plasma.devicenotifier", "org.kde.kdeconnect",
                                     "org.kde.plasma.bluetooth", "org.kde.plasma.printmanager", "org.kde.plasma.vault",
                                     "org.kde.plasma.mediacontroller", "org.kde.kscreen", "org.kde.plasma.brightness",
                                     "org.kde.plasma.cameraindicator", "org.kde.plasma.manage-inputmethod",
                                     "org.kde.plasma.keyboardindicator", "org.kde.plasma.weather"])
}
// Clock: time with the date underneath; click for the calendar panel.
panel.addWidget("org.fennek.clock")
panel.addWidget("org.fennek.showdesktop")   // thin strip at the very end, no icon

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
}
