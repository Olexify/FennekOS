// Fennek OS update for existing desktops (once per user): the 760 px default again; the menu had remembered the
// small size it passes through while opening (fixed), which undid the first update.
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type === "com.github.zren.tiledmenu") {
            w.currentConfigGroup = ["General"]
            if (!(Number(w.readConfig("popupHeight")) > 640)) w.writeConfig("popupHeight", 760)
            if (!(Number(w.readConfig("favGridCols")) > 6)) w.writeConfig("favGridCols", 8)
        }
    })
})
