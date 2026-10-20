// Fennek OS update for existing desktops (once per user): settings found in Start open in Fennek Settings (the
// fennek-settings search), not KDE's full settings window (krunner_systemsettings).
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "com.github.zren.tiledmenu") return
        w.currentConfigGroup = ["General"]
        var l = w.readConfig("searchDefaultFilters")
        l = typeof l === "string" ? (l ? l.split(",") : []) : (l || [])
        if (l.length === 0) return   // the built-in default already uses fennek-settings
        var out = []
        l.forEach(function (id) {
            var n = id === "krunner_systemsettings" ? "fennek-settings" : id
            if (out.indexOf(n) < 0) out.push(n)
        })
        w.writeConfig("searchDefaultFilters", out)
    })
})
