// Fennek OS update for existing desktops (once per user): one language indicator (Fennek's, with the list of
// languages, flags and settings); the second, stock indicator goes away.
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.systemtray") return
        var tray = desktopById(w.readConfig("SystrayContainmentId"))
        if (!tray) return
        tray.widgets().forEach(function (t) { if (t.type === "org.kde.plasma.keyboardlayout") t.remove() })
        tray.currentConfigGroup = ["General"]
        var list = function (key) { var l = tray.readConfig(key); return typeof l === "string" ? (l ? l.split(",") : []) : (l || []) }
        tray.writeConfig("extraItems", list("extraItems").filter(function (id) { return id !== "org.kde.plasma.keyboardlayout" }))
        var known = list("knownItems")
        if (known.indexOf("org.kde.plasma.keyboardlayout") < 0) known.push("org.kde.plasma.keyboardlayout")
        tray.writeConfig("knownItems", known)
    })
})
