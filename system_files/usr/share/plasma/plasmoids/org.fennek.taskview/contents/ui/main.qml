// Task View button: opens KDE's window overview (also Win+W).
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
    toolTipMainText: "Task View"
    toolTipSubText: "See all open windows (Super+W)"

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }

    fullRepresentation: MouseArea {
        Layout.preferredWidth: height
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: run.connectSource("dbus-send --session --dest=org.kde.kglobalaccel --type=method_call /component/kwin org.kde.kglobalaccel.Component.invokeShortcut string:Overview")

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, parent.containsMouse ? 0.1 : 0)
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.medium
            height: width
            source: "view-app-grid-symbolic"
        }
    }
}
