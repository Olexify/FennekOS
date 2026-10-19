// Super+X: the classic quick-link menu at the bottom-left (same links as Start's right-click menu).
// Click one, or press Escape / click elsewhere to close. The fennekwinx KWin script puts it above Start.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: root
    visible: true
    title: "Quick links"
    flags: Qt.FramelessWindowHint | Qt.Tool
    width: Kirigami.Units.gridUnit * 15
    height: list.implicitHeight + Kirigami.Units.smallSpacing * 2
    color: Kirigami.Theme.backgroundColor

    readonly property var links: [
        ["Install or remove apps", "plasmadiscover", "plasma-discover"],
        ["Power options", "preferences-system-power-management", "fennek-app settings kcm_powerdevilprofilesconfig"],
        ["System", "hwinfo", "kinfocenter"],
        ["Network connections", "network-wired", "fennek-app settings kcm_networkmanagement"],
        ["Storage", "drive-harddisk", "filelight"],
        ["Disk management", "partitionmanager", "partitionmanager"],
        [],
        ["Terminal", "utilities-terminal", "konsole"],
        ["Task Manager", "utilities-system-monitor", "plasma-systemmonitor"],
        ["Settings", "fennek-settings", "fennek-app settings"],
        ["File Explorer", "system-file-manager", "dolphin"],
        ["Launch", "system-search", "fennek-app run"],
        [],
        ["Shut down or sign out", "system-shutdown", "dbus-send --session --dest=org.kde.LogoutPrompt --type=method_call /LogoutPrompt org.kde.LogoutPrompt.promptAll"],
        ["Desktop", "user-desktop", "dbus-send --session --dest=org.kde.kglobalaccel --type=method_call /component/kwin org.kde.kglobalaccel.Component.invokeShortcut string:'Fennek Show Desktop'"]
    ]

    // Started detached, so it keeps running after this menu closes.
    P5Support.DataSource { id: run; engine: "executable"; onNewData: source => { disconnectSource(source); Qt.quit() } }
    function open(cmd) { root.visible = false; bye.start(); run.connectSource("setsid -f " + cmd) }
    Timer { id: bye; interval: 2000; onTriggered: Qt.quit() }   // never lingers hidden

    property bool wasActive: false   // closes when you click elsewhere (after it had the focus once)
    onActiveChanged: { if (active) wasActive = true; else if (wasActive && visible) Qt.quit() }
    Shortcut { sequences: ["Escape", "Meta+X"]; onActivated: Qt.quit() }

    Rectangle {   // thin frame
        anchors.fill: parent
        color: "transparent"
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
    }
    ColumnLayout {
        id: list
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Kirigami.Units.smallSpacing }
        spacing: 0
        Repeater {
            model: root.links
            delegate: Loader {
                required property var modelData
                Layout.fillWidth: true
                sourceComponent: modelData.length ? item : separator
                Component {
                    id: separator
                    Kirigami.Separator { Layout.fillWidth: true; Layout.margins: Kirigami.Units.smallSpacing }
                }
                Component {
                    id: item
                    QQC2.ItemDelegate {
                        text: modelData[0]
                        icon.name: modelData[1]
                        onClicked: root.open(modelData[2])
                    }
                }
            }
        }
    }
}
