// Fennek OS update for existing desktops (once per user): the input language (ENG, УКР) moves out of the tray to
// sit next to the clock, like the classic taskbar; its panel then fits its rows. The stock indicator goes for good.
panels().forEach(function (panel) {
    var hasTray = false, hasLang = false
    panel.widgets().forEach(function (w) {
        if (w.type === "org.fennek.keyboard") hasLang = true
        if (w.type !== "org.kde.plasma.systemtray") return
        hasTray = true
        var tray = desktopById(w.readConfig("SystrayContainmentId"))
        if (!tray) return
        var gone = ["org.fennek.keyboard", "org.kde.plasma.keyboardlayout"]
        tray.widgets().forEach(function (t) { if (gone.indexOf(t.type) >= 0) t.remove() })
        tray.currentConfigGroup = ["General"]
        ;["shownItems", "hiddenItems", "extraItems"].forEach(function (key) {
            var l = tray.readConfig(key)
            if (typeof l === "string") l = l ? l.split(",") : []
            tray.writeConfig(key, (l || []).filter(function (id) { return gone.indexOf(id) < 0 }))
        })
    })
    if (!hasTray || hasLang) return
    // Panels add at the end: add the language, then put the widgets after the tray back behind it (they have no
    // settings of their own besides the action center's shortcut).
    var after = ["org.fennek.clock", "org.fennek.actioncenter", "org.fennek.showdesktop"]
    var present = panel.widgets().filter(function (w) { return after.indexOf(w.type) >= 0 }).map(function (w) { return w.type })
    panel.widgets().forEach(function (w) { if (after.indexOf(w.type) >= 0) w.remove() })
    panel.addWidget("org.fennek.keyboard")
    present.forEach(function (type) {
        var w = panel.addWidget(type)
        if (type === "org.fennek.actioncenter") w.globalShortcut = "Meta+A"
    })
})
