#!/usr/bin/python3
"""Fennek OS change to the taskbar (Plasma's task manager), applied to Fedora's source during the image build
(build.sh): a taskbar button's right-click menu gets "App permissions", which opens Settings on that app's
switches (fennek-permissions:APP-ID, handled by fennek-permissions-link.desktop).

If a new Plasma version changed the piece looked for, the build stops here with the piece named.

  patch.py PLASMA_DESKTOP_SOURCE_DIR
"""
import pathlib, sys

p = pathlib.Path(sys.argv[1]) / "applets" / "taskmanager" / "qml" / "ContextMenu.qml"
t = p.read_text(encoding="utf-8")
old = """    PlasmaExtras.MenuItem { separator: true }

    PlasmaExtras.MenuItem {
        property PlasmaCore.Action configureAction: null
"""
new = """    PlasmaExtras.MenuItem {   // Fennek OS: this app's permissions in Settings
        visible: menu.visualParent && menu.get(TaskManager.AbstractTasksModel.IsStartup) !== true
                 && /^[A-Za-z0-9._-]+$/.test(String(menu.get(TaskManager.AbstractTasksModel.AppId) || ""))
        text: "App permissions"
        icon: "fennek-set-permissions"
        onClicked: Qt.openUrlExternally("fennek-permissions:" + menu.get(TaskManager.AbstractTasksModel.AppId))
    }

""" + old
assert t.count(old) == 1, f"ContextMenu.qml: expected 1 of: {old[:80]!r}"
p.write_text(t.replace(old, new), encoding="utf-8")
