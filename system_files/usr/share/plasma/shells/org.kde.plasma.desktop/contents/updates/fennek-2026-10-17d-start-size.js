// Fennek OS update for existing desktops (once per user): Start big by default (760 px tall, 8 tile columns) so it
// is clear there is room for many tiles. Menus already made larger by hand stay as they are.
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type === "com.github.zren.tiledmenu") {
            w.currentConfigGroup = ["General"]
            if (!(Number(w.readConfig("popupHeight")) > 640)) w.writeConfig("popupHeight", 760)
            if (!(Number(w.readConfig("favGridCols")) > 6)) w.writeConfig("favGridCols", 8)
        }
    })
})
