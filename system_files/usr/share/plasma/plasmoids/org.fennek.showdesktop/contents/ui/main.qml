// Show desktop: a thin strip at the very end of the taskbar, no icon. Click: show the desktop / bring the
// windows back (KWin's own toggle). A faint divider on its left, a soft highlight on hover.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: "Show desktop"

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }

    fullRepresentation: MouseArea {
        Layout.preferredWidth: 8
        Layout.minimumWidth: 8
        Layout.maximumWidth: 8
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: run.connectSource("dbus-send --session --dest=org.kde.kglobalaccel --type=method_call "
                                     + "/component/kwin org.kde.kglobalaccel.Component.invokeShortcut string:'Fennek Show Desktop'")
        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.textColor
            opacity: parent.containsMouse ? 0.18 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Rectangle {
            width: 1
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 8; bottomMargin: 8 }
            color: Kirigami.Theme.textColor
            opacity: 0.25
        }
    }
}
