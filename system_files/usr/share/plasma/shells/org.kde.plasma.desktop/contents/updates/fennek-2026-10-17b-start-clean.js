// Fennek OS update for existing desktops (once per user): Start without the "Most Used" block (clean A-Z list,
// as new installs have it).
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type === "com.github.zren.tiledmenu") {
            w.currentConfigGroup = ["General"]
            w.writeConfig("showRecentApps", false)
        }
    })
})
