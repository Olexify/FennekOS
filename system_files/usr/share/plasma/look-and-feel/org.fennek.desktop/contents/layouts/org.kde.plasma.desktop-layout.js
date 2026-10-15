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
start.writeConfig("tileModel", "W3sieCI6MCwieSI6MCwidyI6NiwiaCI6MSwidGlsZVR5cGUiOiJncm91cCIsImxhYmVsIjoiRmVubmVrIn0seyJ4IjowLCJ5IjoxLCJ3IjoyLCJoIjoyLCJ1cmwiOiJmaXJlZm94LmRlc2t0b3AiLCJsYWJlbCI6IkZpcmVmb3gifSx7IngiOjIsInkiOjEsInciOjIsImgiOjIsInVybCI6Im9yZy5rZGUuZG9scGhpbi5kZXNrdG9wIiwibGFiZWwiOiJGaWxlIEV4cGxvcmVyIn0seyJ4Ijo0LCJ5IjoxLCJ3IjoxLCJoIjoxLCJ1cmwiOiJmZW5uZWstc2V0dGluZ3MuZGVza3RvcCIsImxhYmVsIjoiU2V0dGluZ3MifSx7IngiOjUsInkiOjEsInciOjEsImgiOjEsInVybCI6Im9yZy5rZGUuZGlzY292ZXIuZGVza3RvcCIsImxhYmVsIjoiU3RvcmUifSx7IngiOjQsInkiOjIsInciOjEsImgiOjEsInVybCI6Im9yZy5rZGUua29uc29sZS5kZXNrdG9wIiwibGFiZWwiOiJUZXJtaW5hbCJ9LHsieCI6NSwieSI6MiwidyI6MSwiaCI6MSwidXJsIjoib3JnLmtkZS5rd3JpdGUuZGVza3RvcCIsImxhYmVsIjoiTm90ZXBhZCJ9LHsieCI6MCwieSI6MywidyI6NiwiaCI6MSwidGlsZVR5cGUiOiJncm91cCIsImxhYmVsIjoiU2FmZXR5In0seyJ4IjowLCJ5Ijo0LCJ3IjoyLCJoIjoyLCJ1cmwiOiJvcmcua2RlLnBsYXNtYS1zeXN0ZW1tb25pdG9yLmRlc2t0b3AiLCJsYWJlbCI6IlRhc2sgTWFuYWdlciJ9LHsieCI6MiwieSI6NCwidyI6MiwiaCI6MiwidXJsIjoiZmVubmVrLXF1YXJhbnRpbmUuZGVza3RvcCIsImxhYmVsIjoiUXVhcmFudGluZSJ9XQ==")
start.writeConfig("favoriteApps", ["preferred://browser", "org.kde.dolphin.desktop", "fennek-settings.desktop",
                                   "org.kde.konsole.desktop", "org.kde.discover.desktop"])

// Classic order: Start, "Type here to search", Task View, then the app icons.
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
