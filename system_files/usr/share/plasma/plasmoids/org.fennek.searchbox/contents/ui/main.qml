// Classic taskbar search box. Clicking it opens KDE's search (KRunner), which also
// queries Fennek's instant file search.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }

    fullRepresentation: MouseArea {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 17
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: run.connectSource("dbus-send --session --dest=org.kde.krunner --type=method_call /App org.kde.krunner.App.display")

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            color: parent.containsMouse ? Qt.lighter(Kirigami.Theme.backgroundColor, 1.6)
                                        : Qt.lighter(Kirigami.Theme.backgroundColor, 1.35)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            radius: 2
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon {
                source: "search"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            PlasmaComponents.Label {
                text: "Search apps and files"
                opacity: 0.75
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
