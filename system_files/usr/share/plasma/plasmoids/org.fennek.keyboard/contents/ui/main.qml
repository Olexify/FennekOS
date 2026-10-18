// Fennek input language: the current language on the taskbar (ENG, УКР...). Click: a compact list of your languages
// with their flags (pick one) and "Language preferences". Right-click: next language, keyboard layout settings.
// Mouse wheel over it switches too; switching keys (e.g. Alt+Shift) work as before.
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
    // Flag from the layout's country code (us -> 🇺🇸, ua -> 🇺🇦); none for codes that are not a country (e.g. ara).
    function flag(l) {
        const c = l ? l.shortName.toUpperCase() : ""
        return /^[A-Z]{2}$/.test(c) ? String.fromCodePoint(0x1F1E6 + c.charCodeAt(0) - 65, 0x1F1E6 + c.charCodeAt(1) - 65) : ""
    }
    readonly property string current: label(layouts[kb.layout])
    function next() { kb.layout = (kb.layout + 1) % Math.max(1, layouts.length) }
    function settings() { run.connectSource("systemsettings kcm_keyboard"); root.expanded = false }

    // Only one language: nothing to switch, nothing to show.
    Plasmoid.status: layouts.length > 1 ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    toolTipMainText: layouts[kb.layout] ? layouts[kb.layout].longName : ""
    toolTipSubText: "Click to choose a language"
    Plasmoid.contextualActions: [
        PlasmaCore.Action { text: "Next language"; icon.name: "go-next"; onTriggered: root.next() },
        PlasmaCore.Action { text: "Configure keyboard layouts…"; icon.name: "configure"; onTriggered: root.settings() }
    ]

    P5Support.DataSource { id: run; engine: "executable"; onNewData: source => disconnectSource(source) }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: lbl.implicitWidth + Kirigami.Units.largeSpacing * 2
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        onWheel: wheel => { kb.layout = (kb.layout + (wheel.angleDelta.y < 0 ? 1 : root.layouts.length - 1)) % root.layouts.length }
        Rectangle { anchors.fill: parent; color: Kirigami.Theme.textColor; opacity: parent.containsMouse || root.expanded ? 0.08 : 0; radius: 4 }
        PC3.Label { id: lbl; anchors.centerIn: parent; text: root.current }
    }

    fullRepresentation: Item {
        // Compact: exactly as tall as its rows (the popup used to stretch them over its whole height).
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredHeight: list.implicitHeight
        Layout.maximumHeight: list.implicitHeight
        ColumnLayout {
            id: list
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 2
            Repeater {
                model: root.layouts
                delegate: PC3.ItemDelegate {
                    id: row
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    highlighted: index === kb.layout
                    onClicked: { kb.layout = index; root.expanded = false }
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        PC3.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                            horizontalAlignment: Text.AlignHCenter
                            text: root.flag(row.modelData)
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.3
                        }
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
            Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing; Layout.bottomMargin: Kirigami.Units.smallSpacing }
            PC3.ItemDelegate {
                Layout.fillWidth: true
                onClicked: root.settings()
                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        source: "preferences-desktop-locale-symbolic"
                        isMask: true
                        color: Kirigami.Theme.textColor
                    }
                    PC3.Label { Layout.fillWidth: true; text: "Language preferences" }
                }
            }
        }
    }
}
