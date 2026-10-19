// Fennek input language: the current language on the taskbar next to the clock (ENG, УКР...), outside the tray so its
// panel fits its rows exactly. Click: a fixed-size panel like the classic
// one: each language as a two-line row (code, language, keyboard), then "Language preferences". Right-click: your
// languages to switch to, and keyboard layout settings. Mouse wheel over it switches too; Alt+Shift etc. as before.
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
    function settings() { run.connectSource("fennek-app settings kcm_keyboard"); root.expanded = false }

    // Only one language: nothing to switch, nothing to show.
    Plasmoid.status: layouts.length > 1 ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus
    toolTipMainText: layouts[kb.layout] ? layouts[kb.layout].longName : ""
    toolTipSubText: "Click to choose a language"

    // Right-click menu: one entry per language (flag, name; the current one in bold, no tick boxes), then the settings.
    property var layoutActions: []
    Instantiator {
        model: root.layouts
        delegate: PlasmaCore.Action {
            required property var modelData
            required property int index
            text: (root.flag(modelData) ? root.flag(modelData) + "  " : "") + modelData.longName
            font.bold: index === kb.layout
            onTriggered: kb.layout = index
        }
        onObjectAdded: (i, o) => { const a = root.layoutActions.slice(); a.splice(i, 0, o); root.layoutActions = a }
        onObjectRemoved: (i, o) => { const a = root.layoutActions.slice(); a.splice(i, 1); root.layoutActions = a }
    }
    property PlasmaCore.Action separator: PlasmaCore.Action { isSeparator: true }
    property PlasmaCore.Action configure: PlasmaCore.Action {
        text: "Configure keyboard layouts…"
        icon.name: "configure"
        onTriggered: root.settings()
    }
    Plasmoid.contextualActions: root.layoutActions.concat([separator, configure])

    P5Support.DataSource { id: run; engine: "executable"; onNewData: source => disconnectSource(source) }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: lbl.implicitWidth + Kirigami.Units.largeSpacing * 2
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        onWheel: wheel => { kb.layout = (kb.layout + (wheel.angleDelta.y < 0 ? 1 : root.layouts.length - 1)) % root.layouts.length }
        Rectangle { anchors.fill: parent; color: Kirigami.Theme.textColor; opacity: parent.containsMouse || root.expanded ? 0.08 : 0; radius: 4 }
        PC3.Label {
            id: lbl
            anchors.centerIn: parent
            text: root.current
            // As large as the clock's time: readable at a glance (it was the small font).
            font.pixelSize: Math.max(Kirigami.Theme.defaultFont.pixelSize * 1.15, Math.round(parent.height * 0.42))
            font.weight: Font.DemiBold
        }
    }

    fullRepresentation: Item {
        // Fixed size, fitted to its rows (not resizable): what you need, nothing more.
        readonly property int w: Kirigami.Units.gridUnit * 21
        Layout.minimumWidth: w
        Layout.maximumWidth: w
        Layout.preferredWidth: w
        Layout.minimumHeight: list.implicitHeight
        Layout.maximumHeight: list.implicitHeight
        Layout.preferredHeight: list.implicitHeight
        ColumnLayout {
            id: list
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 0
            Repeater {
                model: root.layouts
                delegate: PC3.ItemDelegate {
                    id: row
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    topPadding: Kirigami.Units.largeSpacing * 1.5
                    bottomPadding: Kirigami.Units.largeSpacing * 1.5
                    leftPadding: Kirigami.Units.largeSpacing * 2
                    highlighted: index === kb.layout
                    onClicked: { kb.layout = index; root.expanded = false }
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.gridUnit
                        PC3.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            Layout.alignment: Qt.AlignTop
                            text: root.label(row.modelData)
                            font.weight: Font.DemiBold
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.25
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            PC3.Label {
                                Layout.fillWidth: true
                                text: row.modelData.longName
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                                elide: Text.ElideRight
                            }
                            PC3.Label {
                                Layout.fillWidth: true
                                text: row.modelData.shortName.toUpperCase() + " keyboard"
                                opacity: 0.7
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
            Kirigami.Separator { Layout.fillWidth: true; Layout.leftMargin: Kirigami.Units.largeSpacing; Layout.rightMargin: Kirigami.Units.largeSpacing }
            PC3.ItemDelegate {
                Layout.fillWidth: true
                topPadding: Kirigami.Units.largeSpacing * 1.5
                bottomPadding: Kirigami.Units.largeSpacing * 1.5
                leftPadding: Kirigami.Units.largeSpacing * 2
                onClicked: root.settings()
                contentItem: RowLayout {
                    spacing: Kirigami.Units.gridUnit
                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        source: "preferences-desktop-locale-symbolic"
                        isMask: true
                        color: Kirigami.Theme.textColor
                    }
                    PC3.Label { Layout.fillWidth: true; text: "Language preferences"; font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1 }
                }
            }
        }
    }
}
