// Fennek network panel: the current connection on top, then available networks; click one to connect (asks
// for the password of a new secured Wi-Fi inline). Wi-Fi and Airplane mode tiles, a link to network settings.
// Uses Plasma's network module: the same connect / disconnect / password logic as the stock network applet.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.icon: iconProvider.connectionIcon + "-symbolic"
    Plasmoid.busy: iconProvider.connecting
    toolTipMainText: "Network"
    toolTipSubText: status.activeConnections

    PlasmaNM.NetworkStatus { id: status }
    PlasmaNM.ConnectionIcon { id: iconProvider; connectivity: status.connectivity }
    PlasmaNM.Handler { id: handler }
    PlasmaNM.EnabledConnections { id: enabledConnections }
    PlasmaNM.AvailableDevices { id: devices }
    PlasmaNM.NetworkModel { id: networks }
    PlasmaNM.AppletProxyModel { id: shown; sourceModel: networks }

    Timer {   // look for networks only while the panel is open (battery)
        interval: 10000; repeat: true; triggeredOnStart: true
        running: root.expanded && !PlasmaNM.Configuration.airplaneModeEnabled
        onTriggered: handler.requestScan()
    }

    compactRepresentation: MouseArea {
        onClicked: root.expanded = !root.expanded
        hoverEnabled: true
        Kirigami.Icon { anchors.fill: parent; source: Plasmoid.icon; active: parent.containsMouse }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredHeight: Kirigami.Units.gridUnit * 30
        spacing: Kirigami.Units.smallSpacing

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: shown
            currentIndex: -1
            delegate: ColumnLayout {
                id: row
                required property var model
                required property int index
                readonly property bool connected: model.ConnectionState === PlasmaNM.Enums.Activated
                readonly property bool busy: model.ConnectionState === PlasmaNM.Enums.Activating
                readonly property bool isOpen: list.currentIndex === index
                readonly property bool staticPassword: model.SecurityType === PlasmaNM.Enums.StaticWep
                    || model.SecurityType === PlasmaNM.Enums.WpaPsk || model.SecurityType === PlasmaNM.Enums.Wpa2Psk
                    || model.SecurityType === PlasmaNM.Enums.SAE
                readonly property bool needsPassword: !model.Uuid && model.Type === PlasmaNM.Enums.Wireless && staticPassword
                width: ListView.view.width
                spacing: Kirigami.Units.smallSpacing

                function toggle() {
                    if (connected || busy) {
                        handler.deactivateConnection(model.ConnectionPath, model.DevicePath)
                    } else if (model.Uuid) {
                        handler.activateConnection(model.ConnectionPath, model.DevicePath, model.SpecificPath)
                    } else if (needsPassword) {
                        if (password.text === "")
                            return
                        handler.addAndActivateConnection(model.DevicePath, model.SpecificPath, password.text)
                    } else {
                        handler.addAndActivateConnection(model.DevicePath, model.SpecificPath)
                    }
                    list.currentIndex = -1
                }

                PC3.ItemDelegate {
                    Layout.fillWidth: true
                    highlighted: row.isOpen
                    onClicked: list.currentIndex = row.isOpen ? -1 : row.index
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            source: row.model.ConnectionIcon
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Layout.preferredWidth
                        }
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            PC3.Label {
                                text: row.model.ItemUniqueName
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                font.weight: row.connected ? Font.DemiBold : Font.Normal
                            }
                            PC3.Label {
                                text: row.connected ? "Connected" : row.busy ? "Connecting…"
                                    : row.model.SecurityType > 0 ? "Secured"
                                    : row.model.Type === PlasmaNM.Enums.Wireless ? "Open" : ""
                                visible: text !== ""
                                opacity: 0.7
                                font: Kirigami.Theme.smallFont
                            }
                        }
                    }
                }
                ColumnLayout {   // opened: password (new secured Wi-Fi) + Connect / Disconnect
                    visible: row.isOpen
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.gridUnit * 2.5
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    Layout.bottomMargin: Kirigami.Units.largeSpacing
                    PlasmaExtras.PasswordField {
                        id: password
                        visible: row.needsPassword && !row.connected
                        Layout.fillWidth: true
                        placeholderText: "Network password"
                        onAccepted: row.toggle()
                    }
                    PC3.Button {
                        Layout.alignment: Qt.AlignRight
                        text: row.connected || row.busy ? "Disconnect" : "Connect"
                        enabled: !(row.needsPassword && !row.connected && password.text === "")
                        onClicked: row.toggle()
                    }
                }
            }
            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.gridUnit * 4
                visible: list.count === 0
                text: PlasmaNM.Configuration.airplaneModeEnabled ? "Airplane mode is on" : "No networks found"
            }
        }

        PC3.ToolButton {
            text: "Network settings"
            icon.name: "configure"
            onClicked: { KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement"); root.expanded = false }
        }

        RowLayout {   // quick tiles
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            PC3.Button {
                visible: devices.wirelessDeviceAvailable
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6.5
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3.5
                checkable: true
                checked: enabledConnections.wirelessEnabled
                icon.name: "network-wireless"
                text: "Wi-Fi"
                display: PC3.AbstractButton.TextUnderIcon
                onClicked: handler.enableWireless(!enabledConnections.wirelessEnabled)
            }
            PC3.Button {
                visible: devices.wirelessDeviceAvailable || devices.modemDeviceAvailable
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6.5
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3.5
                checkable: true
                checked: PlasmaNM.Configuration.airplaneModeEnabled
                icon.name: "network-flightmode-on"
                text: "Airplane mode"
                display: PC3.AbstractButton.TextUnderIcon
                onClicked: {
                    const on = !PlasmaNM.Configuration.airplaneModeEnabled
                    handler.enableAirplaneMode(on)
                    PlasmaNM.Configuration.airplaneModeEnabled = on
                }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
