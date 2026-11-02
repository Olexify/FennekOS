// Fennek OS update for existing desktops (once per user): the tray settings finally reach the tray (they are its own;
// the earlier updates looked for them elsewhere and did nothing). Network, sound and battery always visible. No Brightness
// & Color (brightness, Night light and Dark mode are in the action center, Super+A), no second language indicator (Fennek's
// sits next to the clock), no Vaults, no "Set up Weather Report", no Display Configuration (Settings has it). The rest,
// and anything added by hand, stays as it is.
var VISIBLE = ["org.kde.plasma.networkmanagement", "org.kde.plasma.volume", "org.kde.plasma.battery"]
var ARROW = ["org.kde.plasma.notifications", "org.kde.plasma.clipboard", "org.kde.plasma.devicenotifier", "org.kde.kdeconnect",
             "org.kde.plasma.bluetooth", "org.kde.plasma.printmanager", "org.kde.plasma.mediacontroller",
             "org.kde.plasma.cameraindicator", "org.kde.plasma.manage-inputmethod", "org.kde.plasma.keyboardindicator"]
var GONE = ["org.kde.plasma.brightness", "org.kde.plasma.keyboardlayout", "org.kde.plasma.vault", "org.kde.plasma.weather",
            "org.kde.kscreen"]
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.systemtray") return
        w.currentConfigGroup = ["General"]
        var list = function (key) { var l = w.readConfig(key); return typeof l === "string" ? (l ? l.split(",") : []) : (l || []) }
        var keep = function (id) { return GONE.indexOf(id) < 0 }
        var add = function (l, ids) { ids.forEach(function (id) { if (l.indexOf(id) < 0) l.push(id) }); return l }
        // Known items don't come back by themselves at the next sign-in; leaving extraItems unloads them right away.
        w.writeConfig("knownItems", add(list("knownItems"), GONE))
        var extra = list("extraItems").filter(keep)
        // An empty list would leave the tray with nothing in it: Fennek's list instead.
        w.writeConfig("extraItems", add(extra.length ? extra : ARROW.slice(), VISIBLE))
        w.writeConfig("shownItems", add(list("shownItems").filter(keep), VISIBLE))
        w.writeConfig("hiddenItems", list("hiddenItems").filter(function (id) { return keep(id) && VISIBLE.indexOf(id) < 0 }))
    })
})
