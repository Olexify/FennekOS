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
