// Super+X quick links (fennek-app winx): placed at the bottom-left, right above Start, on the screen in use;
// kept above other windows and out of the taskbar, like a menu.
workspace.windowAdded.connect(function (w) {
    if (w.resourceClass !== "fennek-winx") return;
    var a = workspace.clientArea(KWin.PlacementArea, workspace.activeScreen, workspace.currentDesktop);
    var g = w.frameGeometry;
    w.frameGeometry = { x: a.x + 4, y: a.y + a.height - g.height - 4, width: g.width, height: g.height };
    w.keepAbove = true;
    w.skipTaskbar = true;
    w.skipSwitcher = true;
    workspace.activeWindow = w;
});
