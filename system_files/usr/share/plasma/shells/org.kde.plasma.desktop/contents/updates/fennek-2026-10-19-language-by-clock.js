// Fennek OS update for existing desktops (once per user): the input language (ENG, УКР) sits next to the clock, like
// the classic taskbar; its panel fits its rows.
panels().forEach(function (panel) {
    var hasTray = false, hasLang = false
    panel.widgets().forEach(function (w) {
        if (w.type === "org.fennek.keyboard") hasLang = true
        if (w.type === "org.kde.plasma.systemtray") hasTray = true
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
