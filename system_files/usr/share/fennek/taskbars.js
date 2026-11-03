// fennek-taskbars: a bar for each display that has none: Start, search, the running apps, clock, show desktop, set up like
// the main bar. No second tray or action center: those stay on the main display.
var all = panels()
var main = all.filter(function (p) { return p.screen === 0 && p.widgets("org.kde.plasma.icontasks").length })[0]
    || all.filter(function (p) { return p.widgets("org.kde.plasma.icontasks").length })[0]
var has = function (s) { return all.some(function (p) { return p.screen === s }) }
var missing = []
for (var s = 0; s < screenCount; s++)
    if (!has(s)) missing.push(s)
if (main && missing.length) {
    var was = locked   // a locked desktop refuses new panels
    if (was) lockCorona(false)
    missing.forEach(function (s) {
        var bar = new Panel
        bar.screen = s
        bar.location = "bottom"
        bar.floating = main.floating
        bar.hiding = main.hiding
        bar.height = main.height
        bar.opacity = main.opacity
        ;["com.github.zren.tiledmenu", "org.fennek.searchbox", "org.kde.plasma.icontasks", "org.kde.plasma.marginsseparator",
          "org.fennek.clock", "org.fennek.showdesktop"].forEach(function (type) {
            var w = bar.addWidget(type), from = main.widgets(type)[0]
            if (!from) return
            from.currentConfigGroup = w.currentConfigGroup = ["General"]
            from.configKeys.forEach(function (k) { w.writeConfig(k, from.readConfig(k)) })
        })
    })
    if (was) lockCorona(true)
}
