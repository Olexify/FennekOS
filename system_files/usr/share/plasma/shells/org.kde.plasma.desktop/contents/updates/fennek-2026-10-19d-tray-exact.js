// Fennek OS update for existing desktops (once per user): the tray keeps exactly Fennek's items: no second, stock
// language indicator (Fennek's sits next to the clock), no Brightness & Color (brightness, Night light and Dark mode
// are in the action center, Super+A). An earlier update could leave the tray's list empty, which brought them back.
var FENNEK = ["org.kde.plasma.networkmanagement", "org.kde.plasma.volume", "org.kde.plasma.battery",
              "org.kde.plasma.notifications", "org.kde.plasma.clipboard", "org.kde.plasma.devicenotifier", "org.kde.kdeconnect",
              "org.kde.plasma.bluetooth", "org.kde.plasma.printmanager", "org.kde.plasma.vault",
              "org.kde.plasma.mediacontroller", "org.kde.kscreen", "org.kde.plasma.cameraindicator",
              "org.kde.plasma.manage-inputmethod", "org.kde.plasma.keyboardindicator", "org.kde.plasma.weather"]
var GONE = ["org.kde.plasma.brightness", "org.kde.plasma.keyboardlayout"]
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.systemtray") return
        var tray = desktopById(w.readConfig("SystrayContainmentId"))
        if (!tray) return
        tray.widgets().forEach(function (t) { if (GONE.indexOf(t.type) >= 0) t.remove() })
        tray.currentConfigGroup = ["General"]
        var list = function (key) { var l = tray.readConfig(key); return typeof l === "string" ? (l ? l.split(",") : []) : (l || []) }
        var extra = list("extraItems")
        // An empty list would mean "every tray item there is": write Fennek's list instead.
        tray.writeConfig("extraItems", (extra.length ? extra : FENNEK).filter(function (id) { return GONE.indexOf(id) < 0 }))
        tray.writeConfig("shownItems", list("shownItems").filter(function (id) { return GONE.indexOf(id) < 0 }))
        tray.writeConfig("hiddenItems", list("hiddenItems").filter(function (id) { return GONE.indexOf(id) < 0 }))
    })
})
