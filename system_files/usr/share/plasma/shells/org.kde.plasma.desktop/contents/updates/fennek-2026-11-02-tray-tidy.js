// Fennek OS update for existing desktops (once per user): behind the tray's ^ arrow only what people use: no Vaults,
// no "Set up Weather Report", no Display Configuration (Settings > System > Display has it).
var GONE = ["org.kde.plasma.vault", "org.kde.plasma.weather", "org.kde.kscreen"]
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.systemtray") return
        var tray = desktopById(w.readConfig("SystrayContainmentId"))
        if (!tray) return
        tray.widgets().forEach(function (t) { if (GONE.indexOf(t.type) >= 0) t.remove() })
        tray.currentConfigGroup = ["General"]
        var list = function (key) { var l = tray.readConfig(key); return typeof l === "string" ? (l ? l.split(",") : []) : (l || []) }
        var keep = function (id) { return GONE.indexOf(id) < 0 }
        var extra = list("extraItems")
        if (extra.length) tray.writeConfig("extraItems", extra.filter(keep))   // empty would mean "every tray item there is"
        tray.writeConfig("shownItems", list("shownItems").filter(keep))
        tray.writeConfig("hiddenItems", list("hiddenItems").filter(keep))
    })
})
