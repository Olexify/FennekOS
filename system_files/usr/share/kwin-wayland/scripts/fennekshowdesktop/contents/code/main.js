// Super+D, the classic way: the first press puts every window on this desktop away (minimized) and shows the
// desktop; the second press brings exactly those windows back, in the same order, the same one in front.
// (KWin's own "show desktop" ends by itself as soon as a window takes the focus.) Also behind the thin strip at
// the end of the taskbar and "Desktop" in Super+X (shortcut "Fennek Show Desktop").
// Dialogs that can't be minimized on their own (a settings dialog of the desktop itself, say) are hidden with
// KWin's show-desktop on top, so nothing stays in front.
var saved = [];
var savedActive = null;
var away = false;

function onThisDesktop(w) {
    return w.onAllDesktops || w.desktops.indexOf(workspace.currentDesktop) >= 0;
}

function shown() {
    return workspace.stackingOrder.filter(function (w) {
        return (w.normalWindow || w.dialog || w.utility) && !w.minimized && onThisDesktop(w);
    });
}

registerShortcut("Fennek Show Desktop", "Show the desktop; press again to bring the windows back", "Meta+D", function () {
    var open = shown();
    var minimizable = open.filter(function (w) { return w.minimizable; });
    if (!away || minimizable.length > 0) {     // put them away, remember them (bottom to top)
        saved = minimizable;
        savedActive = workspace.activeWindow;
        for (var i = 0; i < minimizable.length; i++) minimizable[i].minimized = true;
        if (minimizable.length < open.length) workspace.showingDesktop = true;
        away = true;
        return;
    }
    if (workspace.showingDesktop) workspace.showingDesktop = false;
    for (var j = 0; j < saved.length; j++) {   // bring back the same ones, same order
        try { if (saved[j].minimized) saved[j].minimized = false; } catch (e) { /* closed meanwhile */ }
    }
    try { if (savedActive && !savedActive.minimized) workspace.activeWindow = savedActive; } catch (e) {}
    saved = [];
    savedActive = null;
    away = false;
});
