// Fennek OS update for existing desktops (once per user): a click on a stacked app shows its windows side by side, not the
// next one; pointing at a preview peeks at that window. Anything already set differently by hand stays.
panels().forEach(function (panel) {
    panel.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.icontasks") return
        w.currentConfigGroup = ["General"]
        if (w.readConfig("groupedTaskVisualization") == 0) w.writeConfig("groupedTaskVisualization", 1)
        if (w.readConfig("highlightWindows") != true) w.writeConfig("highlightWindows", true)
    })
})
