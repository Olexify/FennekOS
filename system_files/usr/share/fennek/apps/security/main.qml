// Ctrl+Alt+Del, the classic way: the screen dims and offers Lock, Switch user, Sign out, Change a password and
// Task Manager; the power button at the bottom-right sleeps, shuts down or restarts. Cancel or Escape goes back.
// The fennekwinx KWin script keeps it above everything.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: root
    visible: true
    visibility: Window.FullScreen
    flags: Qt.FramelessWindowHint
    title: "Security options"
    color: Qt.rgba(0.04, 0.04, 0.08, 0.9)

    readonly property string ksm: "dbus-send --session --type=method_call --dest=org.kde.Shutdown /Shutdown org.kde.Shutdown."
    readonly property var actions: [
        ["Lock", "loginctl lock-session"],
        ["Switch user", "dbus-send --session --type=method_call --dest=org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.openSwitchUserDialog"],
        ["Sign out", ksm + "logout"],
        ["Change a password", "fennek-app settings kcm_users"],
        ["Task Manager", "fennek-app taskmanager"]
    ]

    // Started detached, so it keeps running after this screen closes.
    P5Support.DataSource { id: run; engine: "executable"; onNewData: source => { disconnectSource(source); Qt.quit() } }
    function open(cmd) { root.visible = false; bye.start(); run.connectSource("setsid -f " + cmd) }
    Timer { id: bye; interval: 2000; onTriggered: Qt.quit() }   // never lingers hidden
    Shortcut { sequences: ["Escape"]; onActivated: Qt.quit() }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing
        Repeater {
            model: root.actions
            delegate: QQC2.AbstractButton {
                id: action
                required property var modelData
                required property int index
                focus: index === 0
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                implicitHeight: label.implicitHeight + Kirigami.Units.largeSpacing * 2
                onClicked: root.open(modelData[1])
                Keys.onReturnPressed: clicked()
                Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus()
                Keys.onDownPressed: nextItemInFocusChain(true).forceActiveFocus()
                background: Rectangle {
                    radius: 8
                    color: "white"
                    opacity: action.pressed ? 0.22 : (action.hovered || action.activeFocus ? 0.12 : 0)
                    Behavior on opacity { NumberAnimation { duration: 90 } }
                }
                contentItem: Text {
                    id: label
                    text: action.modelData[0]
                    color: "white"
                    font.pixelSize: 22
                    renderType: Text.QtRendering   // smooth on the see-through screen (no colour fringes)
                    leftPadding: Kirigami.Units.largeSpacing * 2
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    QQC2.Button {
        text: "Cancel"
        anchors { right: parent.right; bottom: parent.bottom; margins: Kirigami.Units.gridUnit * 2 }
        anchors.rightMargin: Kirigami.Units.gridUnit * 5
        onClicked: Qt.quit()
    }
    QQC2.RoundButton {
        id: power
        icon.name: "system-shutdown"
        icon.color: "white"
        flat: true
        anchors { right: parent.right; bottom: parent.bottom; margins: Kirigami.Units.gridUnit * 2 }
        QQC2.ToolTip.text: "Power"
        QQC2.ToolTip.visible: hovered
        onClicked: powerMenu.popup(power, 0, -powerMenu.implicitHeight)
        QQC2.Menu {
            id: powerMenu
            QQC2.MenuItem { text: "Sleep"; icon.name: "system-suspend"; onTriggered: root.open("systemctl suspend") }
            QQC2.MenuItem { text: "Shut down"; icon.name: "system-shutdown"; onTriggered: root.open(root.ksm + "logoutAndShutdown") }
            QQC2.MenuItem { text: "Restart"; icon.name: "system-reboot"; onTriggered: root.open(root.ksm + "logoutAndReboot") }
        }
    }
}
