// Super+R Run box (fennek-app run): centred. Super+X quick links (fennek-app winx): placed at the bottom-left, right above Start, on the screen in use;
// kept above other windows and out of the taskbar, like a menu.
workspace.windowAdded.connect(function (w) {
    if (w.resourceClass === "fennek-run") {   // the Run box (Super+R): in the middle of the screen in use, on top
        var c = workspace.clientArea(KWin.PlacementArea, workspace.activeScreen, workspace.currentDesktop);
        var f = w.frameGeometry;
        w.frameGeometry = { x: c.x + Math.round((c.width - f.width) / 2), y: c.y + Math.round((c.height - f.height) * 0.42),
                            width: f.width, height: f.height };
        w.keepAbove = true;
        w.skipTaskbar = true;
        workspace.activeWindow = w;
        return;
    }
    if (w.resourceClass === "fennek-security") {   // Ctrl+Alt+Del: over everything, out of the taskbar
        w.keepAbove = true;
        w.skipTaskbar = true;
        w.skipSwitcher = true;
        workspace.activeWindow = w;
        return;
    }
    if (w.resourceClass !== "fennek-winx") return;
    var a = workspace.clientArea(KWin.PlacementArea, workspace.activeScreen, workspace.currentDesktop);
    var g = w.frameGeometry;
    w.frameGeometry = { x: a.x + 4, y: a.y + a.height - g.height - 4, width: g.width, height: g.height };
    w.keepAbove = true;
    w.skipTaskbar = true;
    w.skipSwitcher = true;
    workspace.activeWindow = w;
});
