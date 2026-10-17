// Fennek OS update for existing desktops (once per user): the language indicator opens a list of your languages
// (and Language preferences) instead of switching on every click.
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.systemtray") return
        var tray = desktopById(w.readConfig("SystrayContainmentId"))
        if (!tray) return
        tray.currentConfigGroup = ["General"]
        var list = function (key) { var l = tray.readConfig(key); return typeof l === "string" ? (l ? l.split(",") : []) : (l || []) }
        var shown = list("shownItems").filter(function (id) { return id !== "org.kde.plasma.keyboardlayout" && id !== "org.fennek.keyboard" })
        shown.push("org.fennek.keyboard")
        var hidden = list("hiddenItems").filter(function (id) { return id !== "org.fennek.keyboard" && id !== "org.kde.plasma.keyboardlayout" })
        hidden.push("org.kde.plasma.keyboardlayout")
        tray.writeConfig("shownItems", shown)
        tray.writeConfig("hiddenItems", hidden)
    })
})
