// Windows 10-style taskbar: full width, docked at the bottom, no virtual-desktop pager.
var panel = new Panel
panel.location = "bottom"
panel.floating = false
panel.height = 2 * Math.ceil(gridUnit * 2.5 / 2)

var start = panel.addWidget("org.kde.plasma.kickoff")
start.currentConfigGroup = ["General"]
start.writeConfig("icon", "fennek")

panel.addWidget("org.kde.plasma.icontasks")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.digitalclock")
panel.addWidget("org.kde.plasma.showdesktop")

var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
}
