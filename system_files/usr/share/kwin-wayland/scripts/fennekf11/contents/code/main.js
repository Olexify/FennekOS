// F11 for every window (apps and games), one key, two directions:
//  - a normal window (also a windowed game with its title bar) becomes full screen: no title bar, no taskbar;
//  - a full-screen window, or a borderless one covering the whole screen (games that fake full screen),
//    becomes a normal window: borders back, 80% of the screen, centred, free to move and resize.
// Apps no longer receive F11 themselves (the system takes it for this).

function coversScreen(w) {
    var s = workspace.clientArea(KWin.FullScreenArea, w);
    var g = w.frameGeometry;
    return g.x <= s.x && g.y <= s.y && g.x + g.width >= s.x + s.width && g.y + g.height >= s.y + s.height;
}

function toWindow(w) {
    w.fullScreen = false;
    w.noBorder = false;
    if (w.resizeable && coversScreen(w)) {   // still the whole screen (borderless games): a normal size
        var a = workspace.clientArea(KWin.PlacementArea, w);
        var width = Math.round(a.width * 0.8), height = Math.round(a.height * 0.8);
        w.frameGeometry = { x: a.x + Math.round((a.width - width) / 2), y: a.y + Math.round((a.height - height) / 2),
                            width: width, height: height };
    }
}

registerShortcut("Fennek F11", "F11: full screen, or back to a normal window", "F11", function () {
    var w = workspace.activeWindow;
    if (!w || w.desktopWindow || w.dock || w.specialWindow) return;
    if (w.fullScreen || (w.noBorder && coversScreen(w))) {
        toWindow(w);
    } else if (w.fullScreenable) {
        w.fullScreen = true;
    }
});
