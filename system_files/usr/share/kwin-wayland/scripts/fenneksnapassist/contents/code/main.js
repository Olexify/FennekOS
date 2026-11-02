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
        return o !== w && o.normalWindow && !o.skipTaskbar && o.output === w.output
            && (o.onAllDesktops || o.desktops.indexOf(workspace.currentDesktop) >= 0);
    });
}

// Is the window view up? Esc and clicking elsewhere send a script nothing, so ask KWin.
function viewOpen(then) {
    callDBus("org.kde.KWin", "/Effects", "org.freedesktop.DBus.Properties", "Get", "org.kde.kwin.Effects", "activeEffects",
        function (list) { then(list.indexOf("windowview") >= 0); });
}
function toggleView() {
    callDBus("org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component", "invokeShortcut", "Expose");
}

function watch(w) {
    if (!w.normalWindow || !w.tileChanged) return;
    w.tileChanged.connect(function () {
        if (w === placed) { placed = null; return; }
        var side = w.tile ? halfOf(w) : null;
        if (side && others(w).length > 0) {
            pending = { win: w, left: side === "left", at: Date.now() };
            viewOpen(function (open) { if (!open) toggleView(); });   // already up after Super+Left, Super+Right
        } else if (pending && pending.win === w) {                    // made a quarter or left its tile inside the view
            pending = null;
            viewOpen(function (open) { if (open) toggleView(); });
        }
    });
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(watch);

workspace.windowActivated.connect(function (w) {
    if (!pending) return;
    var p = pending;
    pending = null;   // one choice per snap
    if (!w || w === p.win || !w.normalWindow || Date.now() - p.at > 20000) return;
    viewOpen(function (open) {
        if (!open || workspace.activeWindow !== w) return;
        placed = w;
        if (p.left) workspace.slotWindowQuickTileRight(); else workspace.slotWindowQuickTileLeft();
    });
});
