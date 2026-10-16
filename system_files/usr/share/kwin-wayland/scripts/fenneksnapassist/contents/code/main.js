// Snap assist: snap a window to the left or right half (drag to the edge, or Super+Left/Right) and the other
// windows are shown; the one you click fills the other half. Esc or clicking elsewhere just ends it.
// If any of this isn't available, the script stays silent: normal snapping is never affected.
var pending = null;   // { win, left, at }
var placed = null;    // the window snap assist itself just tiled: not a new snap

function halfOf(w) {
    var area = workspace.clientArea(KWin.MaximizeArea, w);
    var g = (w.tile && w.tile.absoluteGeometry) || w.frameGeometry;
    var near = function (a, b) { return Math.abs(a - b) < 12; };
    if (!near(g.width, area.width / 2) || !near(g.height, area.height)) return null;
    if (near(g.x, area.x)) return "left";
    if (near(g.x + g.width, area.x + area.width)) return "right";
    return null;
}

function others(w) {
    return workspace.windowList().filter(function (o) {
        return o !== w && o.normalWindow && !o.skipTaskbar && o.output === w.output;
    });
}

function watch(w) {
    if (!w.normalWindow || !w.tileChanged) return;
    w.tileChanged.connect(function () {
        if (w === placed) { placed = null; return; }
        if (!w.tile) return;
        var side = halfOf(w);
        if (!side || others(w).length === 0) return;
        pending = { win: w, left: side === "left", at: Date.now() };
        callDBus("org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component", "invokeShortcut", "Expose");
    });
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(watch);

workspace.windowActivated.connect(function (w) {
    if (!pending) return;
    var p = pending;
    pending = null;   // one choice per snap
    if (!w || w === p.win || !w.normalWindow || Date.now() - p.at > 20000) return;
    // The picked window is now active: tile it to the opposite half.
    placed = w;
    if (p.left) workspace.slotWindowQuickTileRight(); else workspace.slotWindowQuickTileLeft();
});
