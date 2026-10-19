// Fennek power feedback: the moment Shut down / Restart / Sign out is chosen, the screen dims with a spinner and
// what is happening, so a slow computer never leaves you wondering whether the click worked. Clicks pass through
// (an app asking "save your changes?" stays usable). Started by fennek-power-feedback: fennek-app power MODE.
import QtQuick
import QtQuick.Controls as QQC2

Window {
    id: root
    readonly property string mode: Qt.application.arguments[2] || "shutdown"
    visible: true
    visibility: Window.FullScreen
    flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowDoesNotAcceptFocus
    color: "transparent"
    title: "Fennek OS"

    Rectangle {
        id: dim
        anchors.fill: parent
        color: "#000000"
        opacity: 0
        Component.onCompleted: opacity = 0.45
        Behavior on opacity { NumberAnimation { duration: 250 } }
    }
    Column {
        anchors.centerIn: parent
        spacing: 24
        opacity: dim.opacity > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        QQC2.BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            running: true
            implicitWidth: 64
            implicitHeight: 64
            palette.dark: "white"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.pixelSize: 26
            text: root.mode === "restart" ? "Restarting…" : root.mode === "signout" ? "Signing out…" : "Shutting down…"
        }
    }
    // If nothing happened after two minutes (cancelled somewhere we didn't hear about), get out of the way.
    Timer { interval: 120000; running: true; onTriggered: Qt.quit() }
}
