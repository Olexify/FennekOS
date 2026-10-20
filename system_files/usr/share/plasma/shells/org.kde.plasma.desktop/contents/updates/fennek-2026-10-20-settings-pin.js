// Fennek OS update for existing desktops (once per user): the Settings pinned on the taskbar opens Fennek Settings, not
// KDE's full settings window. A taskbar still on the built-in pins (which include that window) gets Fennek's pins.
var FENNEK = ["applications:fennek-settings.desktop", "applications:org.kde.discover.desktop",
              "preferred://filemanager", "preferred://browser"]
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.icontasks" && w.type !== "org.kde.plasma.taskmanager") return
        w.currentConfigGroup = ["General"]
        var l = w.readConfig("launchers")
        l = typeof l === "string" ? (l ? l.split(",") : []) : (l || [])
        if (l.length === 0) {
            w.writeConfig("launchers", FENNEK)
            return
        }
        var changed = false
        l = l.map(function (id) {
            if (id === "applications:systemsettings.desktop" || id === "applications:kdesystemsettings.desktop") { changed = true; return "applications:fennek-settings.desktop" }
            return id
        })
        if (changed) w.writeConfig("launchers", l.filter(function (id, i) { return l.indexOf(id) === i }))
    })
})
