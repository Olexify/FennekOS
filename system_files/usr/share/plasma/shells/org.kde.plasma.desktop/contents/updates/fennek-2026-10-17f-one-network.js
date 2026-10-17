// Fennek OS update for existing desktops (once per user): one network icon in the tray (the full network panel:
// search, speeds, details, hotspot), not two.
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.systemtray") return
        var tray = desktopById(w.readConfig("SystrayContainmentId"))
        if (!tray) return
        tray.widgets().forEach(function (t) { if (t.type === "org.fennek.network") t.remove() })
        tray.currentConfigGroup = ["General"]
        var swap = function (list, add) {
            if (typeof list === "string") list = list ? list.split(",") : []
            list = (list || []).filter(function (id) { return id !== "org.fennek.network" && id !== "org.kde.plasma.networkmanagement" })
            if (add) list.unshift("org.kde.plasma.networkmanagement")
            return list
        }
        tray.writeConfig("shownItems", swap(tray.readConfig("shownItems"), true))
        tray.writeConfig("hiddenItems", swap(tray.readConfig("hiddenItems"), false))
    })
})
