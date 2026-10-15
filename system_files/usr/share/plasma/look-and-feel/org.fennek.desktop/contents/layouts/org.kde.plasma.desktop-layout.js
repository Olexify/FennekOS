// Classic taskbar: full width, docked at the bottom, 40 px like Windows, no virtual-desktop pager.
var panel = new Panel
panel.location = "bottom"
panel.floating = false   // docked to the screen edge, never floating
panel.hiding = "none"    // always visible
panel.height = 40

// Classic Start menu (Tiled Menu): left rail, A-Z list with "Recently added", tile groups.
var start = panel.addWidget("com.github.zren.tiledmenu")
start.currentConfigGroup = ["General"]
start.writeConfig("icon", "fennek")
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
panel.addWidget("org.kde.plasma.systemtray")
// Clock like the classic desktop: time with the date underneath.
var clock = panel.addWidget("org.kde.plasma.digitalclock")
clock.currentConfigGroup = ["Appearance"]
clock.writeConfig("showDate", true)
clock.writeConfig("dateDisplayFormat", 2)   // BelowTime
panel.addWidget("org.kde.plasma.showdesktop")

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
}
