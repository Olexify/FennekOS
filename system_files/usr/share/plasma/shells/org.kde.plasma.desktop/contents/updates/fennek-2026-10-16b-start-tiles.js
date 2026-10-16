// Fennek OS update for existing desktops (once per user): Start menus resized too narrow lost their tiles
// (0 columns, kept for good). Bring them back at the default 6 columns.
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type === "com.github.zren.tiledmenu") {
            w.currentConfigGroup = ["General"]
            var cols = Number(w.readConfig("favGridCols"))
            if (!(cols >= 4)) {   // 0-3, or unreadable: back to the default
                w.writeConfig("favGridCols", 6)
            }
        }
    })
})
