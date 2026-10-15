// Windows 10-style taskbar: full width, docked at the bottom, 40 px like Windows, no virtual-desktop pager.
var panel = new Panel
panel.location = "bottom"
panel.floating = false   // docked to the screen edge, never floating
panel.hiding = "none"    // always visible
panel.height = 40

// Windows 10 Start menu (Tiled Menu): left rail, A-Z list with "Recently added", tile groups.
var start = panel.addWidget("com.github.zren.tiledmenu")
start.currentConfigGroup = ["General"]
start.writeConfig("icon", "fennek")
start.writeConfig("sidebarShortcuts", ["xdg:DOCUMENTS", "xdg:DOWNLOAD", "xdg:PICTURES", "xdg:VIDEOS", "systemsettings.desktop"])
// Default tiles, Windows 10 style: named groups, big and small tiles (base64 JSON, Tiled Menu's format;
// test.sh checks every tile points to an installed app). Groups: Fennek, Safety.
start.writeConfig("tileModel", "W3sieCI6MCwieSI6MCwidyI6NiwiaCI6MSwidGlsZVR5cGUiOiJncm91cCIsImxhYmVsIjoiRmVubmVrIn0seyJ4IjowLCJ5IjoxLCJ3IjoyLCJoIjoyLCJ1cmwiOiJmaXJlZm94LmRlc2t0b3AiLCJsYWJlbCI6IkZpcmVmb3gifSx7IngiOjIsInkiOjEsInciOjIsImgiOjIsInVybCI6Im9yZy5rZGUuZG9scGhpbi5kZXNrdG9wIiwibGFiZWwiOiJGaWxlIEV4cGxvcmVyIn0seyJ4Ijo0LCJ5IjoxLCJ3IjoxLCJoIjoxLCJ1cmwiOiJzeXN0ZW1zZXR0aW5ncy5kZXNrdG9wIiwibGFiZWwiOiJTZXR0aW5ncyJ9LHsieCI6NSwieSI6MSwidyI6MSwiaCI6MSwidXJsIjoib3JnLmtkZS5kaXNjb3Zlci5kZXNrdG9wIiwibGFiZWwiOiJTdG9yZSJ9LHsieCI6NCwieSI6MiwidyI6MSwiaCI6MSwidXJsIjoib3JnLmtkZS5rb25zb2xlLmRlc2t0b3AiLCJsYWJlbCI6IlRlcm1pbmFsIn0seyJ4Ijo1LCJ5IjoyLCJ3IjoxLCJoIjoxLCJ1cmwiOiJvcmcua2RlLmt3cml0ZS5kZXNrdG9wIiwibGFiZWwiOiJOb3RlcGFkIn0seyJ4IjowLCJ5IjozLCJ3Ijo2LCJoIjoxLCJ0aWxlVHlwZSI6Imdyb3VwIiwibGFiZWwiOiJTYWZldHkifSx7IngiOjAsInkiOjQsInciOjIsImgiOjIsInVybCI6Im9yZy5rZGUucGxhc21hLXN5c3RlbW1vbml0b3IuZGVza3RvcCIsImxhYmVsIjoiVGFzayBNYW5hZ2VyIn0seyJ4IjoyLCJ5Ijo0LCJ3IjoyLCJoIjoyLCJ1cmwiOiJmZW5uZWstcXVhcmFudGluZS5kZXNrdG9wIiwibGFiZWwiOiJRdWFyYW50aW5lIn1d")
start.writeConfig("favoriteApps", ["preferred://browser", "org.kde.dolphin.desktop", "systemsettings.desktop",
                                   "org.kde.konsole.desktop", "org.kde.discover.desktop"])

// Windows 10 order: Start, "Type here to search", Task View, then the app icons.
panel.addWidget("org.fennek.searchbox")
panel.addWidget("org.fennek.taskview")
panel.addWidget("org.kde.plasma.icontasks")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.systemtray")
// Clock like Windows 10: time with the date underneath.
var clock = panel.addWidget("org.kde.plasma.digitalclock")
clock.currentConfigGroup = ["Appearance"]
clock.writeConfig("showDate", true)
clock.writeConfig("dateDisplayFormat", 2)   // BelowTime
panel.addWidget("org.kde.plasma.showdesktop")

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
}
