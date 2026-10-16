// Fennek volume: a compact panel for the current output device. Device name, mute button, one slider, the
// number. Live from the sound server (no polling). Scroll over the tray icon to change the volume.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.private.volume
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    readonly property var sink: PreferredDevice.sink
    readonly property int percent: sink ? Math.round(sink.volume / PulseAudio.NormalVolume * 100) : 0
    readonly property bool muted: sink ? sink.muted : true

    function setPercent(p) {
        if (!sink) return
        sink.volume = Math.round(Math.max(0, Math.min(100, p)) / 100 * PulseAudio.NormalVolume)
        if (p > 0 && sink.muted) sink.muted = false
    }

    Plasmoid.icon: AudioIcon.forVolume(percent, muted, "")
    toolTipMainText: sink ? (sink.description || "Sound") : "No sound device"
    toolTipSubText: muted ? "Muted" : percent + "%"
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    compactRepresentation: MouseArea {
        onClicked: root.expanded = !root.expanded
        onWheel: wheel => root.setPercent(root.percent + (wheel.angleDelta.y > 0 ? 2 : -2))
        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: parent.containsMouse
        }
        hoverEnabled: true
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.minimumHeight: implicitHeight
        spacing: Kirigami.Units.largeSpacing

        PC3.Label {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            text: root.sink ? (root.sink.description || "Sound") : "No sound device"
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing
            PC3.ToolButton {
                icon.name: AudioIcon.forVolume(root.percent, root.muted, "")
                onClicked: if (root.sink) root.sink.muted = !root.sink.muted
                PC3.ToolTip.text: root.muted ? "Unmute" : "Mute"
                PC3.ToolTip.visible: hovered
            }
            PC3.Slider {
                id: slider
                Layout.fillWidth: true
                from: 0; to: 100; stepSize: 1
                value: root.percent
                enabled: root.sink !== null
                onMoved: root.setPercent(value)
            }
            PC3.Label {
                text: root.percent
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.6
                font.weight: Font.Light
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
