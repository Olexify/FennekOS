// Fennek OS update for existing desktops (once per user): Start back to its big default (it could get stuck
// narrow, showing a single column of tiles). Resizing it from its edge still works and is remembered.
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type === "com.github.zren.tiledmenu") {
            w.currentConfigGroup = ["General"]
            w.writeConfig("favGridCols", 8)
            if (!(Number(w.readConfig("popupHeight")) > 700)) w.writeConfig("popupHeight", 760)
        }
    })
})
