// Fennek OS update for existing desktops (once per user): a bug measured the taskbar button instead of the open
// Start menu, so Start shrank to its 4-column minimum and cut the default tiles. Back to the default 6 columns.
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type === "com.github.zren.tiledmenu") {
            w.currentConfigGroup = ["General"]
            if (Number(w.readConfig("favGridCols")) <= 4) {
                w.writeConfig("favGridCols", 6)
            }
        }
    })
})
