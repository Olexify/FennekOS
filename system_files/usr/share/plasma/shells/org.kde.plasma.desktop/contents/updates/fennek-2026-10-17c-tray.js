// Fennek OS update for existing desktops (once per user): the tray as new installs have it. Network, sound,
// battery and language always visible; everything else (clipboard, brightness, displays...) behind the ^ arrow.
// Brightness, night light and the rest are in the action center (Super+A).
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.systemtray") return
        var tray = desktopById(w.readConfig("SystrayContainmentId"))
        if (!tray) return
        tray.currentConfigGroup = ["General"]
        tray.writeConfig("shownItems", ["org.kde.plasma.networkmanagement", "org.kde.plasma.volume",
                                        "org.kde.plasma.battery", "org.fennek.keyboard"])
        tray.writeConfig("hiddenItems", ["org.kde.plasma.notifications",
                                         "org.kde.plasma.clipboard", "org.kde.plasma.devicenotifier", "org.kde.kdeconnect",
                                         "org.kde.plasma.bluetooth", "org.kde.plasma.printmanager", "org.kde.plasma.vault",
                                         "org.kde.plasma.mediacontroller", "org.kde.kscreen", "org.kde.plasma.brightness",
                                         "org.kde.plasma.cameraindicator", "org.kde.plasma.manage-inputmethod",
                                         "org.kde.plasma.keyboardindicator", "org.kde.plasma.weather"])
    })
})
