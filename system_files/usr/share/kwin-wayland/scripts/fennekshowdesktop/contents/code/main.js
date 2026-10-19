// Super+D, the classic way: the first press puts every window on this desktop away (minimized) and shows the
// desktop; the second press brings exactly those windows back, in the same order, the same one in front.
// (KWin's own "show desktop" ends by itself as soon as a window takes the focus.) Also behind the thin strip at
// the end of the taskbar and "Desktop" in Super+X (shortcut "Fennek Show Desktop").
var saved = [];
var savedActive = null;

function onThisDesktop(w) {
    return w.onAllDesktops || w.desktops.indexOf(workspace.currentDesktop) >= 0;
}

function shown() {
    return workspace.stackingOrder.filter(function (w) {
        return w.normalWindow && w.minimizable && !w.minimized && !w.skipTaskbar && onThisDesktop(w);
    });
}

registerShortcut("Fennek Show Desktop", "Show the desktop; press again to bring the windows back", "Meta+D", function () {
    var open = shown();
    if (open.length > 0) {                     // put them away, remember them (bottom to top)
        saved = open;
        savedActive = workspace.activeWindow;
        for (var i = 0; i < open.length; i++) open[i].minimized = true;
        return;
    }
    for (var j = 0; j < saved.length; j++) {   // bring back the same ones, same order
        try { if (saved[j].minimized) saved[j].minimized = false; } catch (e) { /* closed meanwhile */ }
    }
    try { if (savedActive && !savedActive.minimized) workspace.activeWindow = savedActive; } catch (e) {}
    saved = [];
    savedActive = null;
});
