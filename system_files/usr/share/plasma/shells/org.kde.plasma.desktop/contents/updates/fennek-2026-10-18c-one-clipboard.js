// Fennek OS update for existing desktops (once per user): the clipboard lives in the action center's Clipboard tab
// now, so its separate tray icon goes away.
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.systemtray") return
        var tray = desktopById(w.readConfig("SystrayContainmentId"))
        if (!tray) return
        tray.widgets().forEach(function (t) { if (t.type === "org.kde.plasma.clipboard") t.remove() })
        tray.currentConfigGroup = ["General"]
        var list = function (key) { var l = tray.readConfig(key); return typeof l === "string" ? (l ? l.split(",") : []) : (l || []) }
        tray.writeConfig("extraItems", list("extraItems").filter(function (id) { return id !== "org.kde.plasma.clipboard" }))
        var known = list("knownItems")
        if (known.indexOf("org.kde.plasma.clipboard") < 0) known.push("org.kde.plasma.clipboard")
        tray.writeConfig("knownItems", known)
    })
})
