// Fennek input language: the current language on the taskbar (ENG, УКР...). Click: the list of your languages
// (pick one) and "Language preferences". Switching keys (e.g. Alt+Shift) work as before.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.workspace.keyboardlayout as KeyboardLayouts
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    KeyboardLayouts.KeyboardLayout { id: kb }
    readonly property var layouts: kb.layoutsList || []
    function label(l) { return l ? (l.displayName || l.shortName.toUpperCase()) : "" }
    readonly property string current: label(layouts[kb.layout])

    // Only one language: nothing to switch, nothing to show.
    Plasmoid.status: layouts.length > 1 ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    toolTipMainText: layouts[kb.layout] ? layouts[kb.layout].longName : ""
    toolTipSubText: "Click to choose a language"

    P5Support.DataSource { id: run; engine: "executable"; onNewData: source => disconnectSource(source) }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: lbl.implicitWidth + Kirigami.Units.largeSpacing * 2
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        onWheel: wheel => { kb.layout = (kb.layout + (wheel.angleDelta.y < 0 ? 1 : root.layouts.length - 1)) % root.layouts.length }
        Rectangle { anchors.fill: parent; color: Kirigami.Theme.textColor; opacity: parent.containsMouse || root.expanded ? 0.08 : 0; radius: 4 }
        PC3.Label { id: lbl; anchors.centerIn: parent; text: root.current }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: implicitHeight
        spacing: 0
        Repeater {
            model: root.layouts
            delegate: PC3.ItemDelegate {
                id: row
                required property var modelData
                required property int index
                readonly property bool active: index === kb.layout
                Layout.fillWidth: true
                highlighted: active
                onClicked: { kb.layout = index; root.expanded = false }
                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing * 2
                    PC3.Label {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                        text: root.label(row.modelData)
                        font.weight: Font.DemiBold
                    }
                    PC3.Label {
                        Layout.fillWidth: true
                        text: row.modelData.longName
                        elide: Text.ElideRight
                    }
                }
            }
        }
        Kirigami.Separator { Layout.fillWidth: true; Layout.margins: Kirigami.Units.smallSpacing }
        PC3.ItemDelegate {
            Layout.fillWidth: true
            onClicked: { run.connectSource("systemsettings kcm_keyboard"); root.expanded = false }
            contentItem: RowLayout {
                spacing: Kirigami.Units.largeSpacing * 2
                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    source: "preferences-desktop-locale-symbolic"
                    isMask: true
                    color: Kirigami.Theme.textColor
                }
                PC3.Label { Layout.fillWidth: true; text: "Language preferences" }
            }
        }
    }
}
