// Super+Up / Super+Down, the classic way: Up maximizes the window; Down brings a maximized window back to its
// normal size, and minimizes one that isn't maximized. (Super+Left / Super+Right keep snapping to the halves.)
// KWin's own Super+Up / Super+Down tile to the top / bottom half instead; they are set to none for these.
function target() {
    var w = workspace.activeWindow;
    return w && w.normalWindow && !w.desktopWindow && !w.dock ? w : null;
}

registerShortcut("Fennek Maximize", "Maximize the window", "Meta+Up", function () {
    var w = target();
    if (w && w.maximizable) w.setMaximize(true, true);
});

registerShortcut("Fennek Restore or Minimize", "Restore a maximized window, or minimize it", "Meta+Down", function () {
    var w = target();
    if (!w) return;
    if (w.maximizeMode !== 0) w.setMaximize(false, false);
    else if (w.minimizable) w.minimized = true;
});

// Super+Ctrl+D: a new virtual desktop, switched to. Super+Ctrl+F4: close this one (its windows move to the
// neighbour). Super+Ctrl+Left / Right switch between them (KWin's own).
registerShortcut("Fennek New Desktop", "Add a virtual desktop and switch to it", "Meta+Ctrl+D", function () {
    var n = workspace.desktops.length;
    workspace.createDesktop(n, "Desktop " + (n + 1));
    workspace.currentDesktop = workspace.desktops[n];
});

registerShortcut("Fennek Close Desktop", "Close this virtual desktop", "Meta+Ctrl+F4", function () {
    if (workspace.desktops.length > 1) workspace.removeDesktop(workspace.currentDesktop);
});
