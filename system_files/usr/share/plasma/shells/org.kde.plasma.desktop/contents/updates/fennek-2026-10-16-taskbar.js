// Fennek OS update for existing desktops (Plasma runs each script in this folder once per user, at sign-in).
// Brings an already set-up taskbar in line with the current default, without resetting anything else:
// no window-overview button (Super+Tab does it), Start search field only while typing, Super+A action center,
// dark taskbar and panels with light apps (only if the user never picked a panel style).
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type === "org.fennek.taskview") {
            w.remove()
        } else if (w.type === "com.github.zren.tiledmenu") {
            w.currentConfigGroup = ["General"]
            w.writeConfig("hideSearchField", true)
        } else if (w.type === "org.fennek.actioncenter" && !w.globalShortcut) {
            w.globalShortcut = "Meta+A"
        }
    })
})

var theme = ConfigFile("plasmarc", "Theme")
var name = theme.readEntry("name")
if (name === "" || name === "default") {
    theme.writeEntry("name", "breeze-dark")
}
