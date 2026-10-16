// Alt+F4: close the active window, or, on the desktop (no window active), open the Shut down dialog.
// KWin's own "Close Window" gives up Alt+F4 for this (/etc/xdg/kglobalshortcutsrc).
registerShortcut("Fennek Close or Shut Down", "Close the window, or shut down from the desktop", "Alt+F4", function () {
    var w = workspace.activeWindow;
    if (w && !w.desktopWindow && !w.dock) {
        w.closeWindow();
    } else {
        callDBus("org.kde.LogoutPrompt", "/LogoutPrompt", "org.kde.LogoutPrompt", "promptAll");
    }
});
