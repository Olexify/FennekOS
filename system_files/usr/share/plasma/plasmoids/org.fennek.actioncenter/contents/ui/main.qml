// Fennek action center: a button at the end of the taskbar. Two tabs: your notifications (newest first, clear one
// or all; snips with a preview) and your clipboard (copy again, remove, clear). Below, a grid of quick tiles: Wi-Fi, Bluetooth, Airplane mode, Do not disturb, Battery saver,
// Night light, Screenshot, All settings. Notification history is Plasma's own (pop-ups work as before).
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.private.clipboard as Clip
import org.kde.kquickcontrolsaddons as KQuickAddons
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.bluezqt as BluezQt
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    readonly property int unread: history.unreadNotificationsCount || 0
    toolTipMainText: "Action center"
    toolTipSubText: unread > 0 ? unread + " new" : "No new notifications"

    NotificationManager.Settings { id: notifySettings }
    // Clipboard history (the clipboard service's own list: text, links, images and snips).
    Clip.HistoryModel { id: clipHistory }
    property string page: "notifications"   // or "clipboard"
    onExpandedChanged: if (!expanded) page = "notifications"
    NotificationManager.Notifications {
        id: history
        showExpired: true
        showDismissed: true
        sortMode: NotificationManager.Notifications.SortByDate
        groupMode: NotificationManager.Notifications.GroupDisabled
        urgencies: NotificationManager.Notifications.CriticalUrgency | NotificationManager.Notifications.NormalUrgency
    }
    readonly property bool dndOn: {
        const t = notifySettings.notificationsInhibitedUntil
        return t !== undefined && !isNaN(t) && t.getTime() > Date.now()
    }
    function setDnd(on) {
        notifySettings.notificationsInhibitedUntil = on ? new Date(Date.now() + 365 * 86400000) : new Date(NaN)
        notifySettings.save()
    }

    PlasmaNM.Handler { id: nm }
    PlasmaNM.EnabledConnections { id: nmEnabled }
    PlasmaNM.AvailableDevices { id: nmDevices }

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            if (source === root.profileCmd)
                root.batterySaver = data.stdout.indexOf("power-saver") >= 0
            else if (source === root.nightCmd)
                root.nightLight = data.stdout.trim() === "true"
            else if (source === "/usr/libexec/fennek-brightness get")
                root.brightness = data.stdout.trim() === "" ? -1 : parseInt(data.stdout)
            disconnectSource(source)
        }
    }
    // Battery saver = the power-saver power profile (same as the battery menu), read when the panel opens.
    readonly property string profileCmd: "busctl --system get-property org.freedesktop.UPower.PowerProfiles "
                                         + "/org/freedesktop/UPower/PowerProfiles org.freedesktop.UPower.PowerProfiles ActiveProfile"
    property bool batterySaver: false
    // Night light = KWin's night colour (warmer screen in the evening), on/off like the settings page.
    readonly property string nightCmd: "kreadconfig6 --file kwinrc --group NightColor --key Active --default false"
    property bool nightLight: false
    function setNightLight(on) {
        run.connectSource("kwriteconfig6 --file kwinrc --group NightColor --key Active " + (on ? "true" : "false")
                          + " && dbus-send --session --dest=org.kde.KWin --type=method_call /KWin org.kde.KWin.reconfigure")
        nightLight = on
    }
    // Screen brightness (laptops, monitors with brightness control); -1 = none, slider hidden.
    property int brightness: -1
    Timer { id: setBrightness; interval: 120; onTriggered: run.connectSource("/usr/libexec/fennek-brightness set " + root.brightness) }
    onExpandedChanged: if (expanded) {
        run.connectSource(profileCmd); run.connectSource(nightCmd); run.connectSource("/usr/libexec/fennek-brightness get")
    }
    function setProfile(name) {
        run.connectSource("busctl --system set-property org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles "
                          + "org.freedesktop.UPower.PowerProfiles ActiveProfile s " + name)
        batterySaver = name === "power-saver"
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        Rectangle { anchors.fill: parent; color: Kirigami.Theme.textColor; opacity: parent.containsMouse ? 0.08 : 0; radius: 4 }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.smallMedium; height: width
            source: root.dndOn ? "notifications-disabled" : root.unread > 0 ? "notification-active" : "notification-inactive"
        }
        Rectangle {   // unread count
            visible: root.unread > 0
            anchors { right: parent.right; top: parent.top; margins: 4 }
            width: Math.max(height, count.implicitWidth + 6); height: 16; radius: 8
            color: Kirigami.Theme.highlightColor
            PC3.Label { id: count; anchors.centerIn: parent; text: root.unread > 99 ? "99+" : root.unread
                        color: Kirigami.Theme.highlightedTextColor; font.pixelSize: 10 }
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
        Layout.preferredHeight: Kirigami.Units.gridUnit * 36
        spacing: Kirigami.Units.smallSpacing

        RowLayout {   // two tabs: Notifications | Clipboard
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            Repeater {
                model: [{ id: "notifications", name: "Notifications" }, { id: "clipboard", name: "Clipboard" }]
                PC3.ToolButton {
                    required property var modelData
                    readonly property bool current: root.page === modelData.id
                    text: modelData.name
                    flat: true
                    font.weight: current ? Font.DemiBold : Font.Normal
                    opacity: current ? 1 : 0.65
                    onClicked: root.page = modelData.id
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: parent.width * 0.5; height: 2; radius: 1
                        color: Kirigami.Theme.highlightColor
                        visible: parent.current
                    }
                }
            }
            Item { Layout.fillWidth: true }
            PC3.ToolButton {
                text: "Clear all"
                visible: root.page === "notifications" ? list.count > 0 : clips.count > 0
                onClicked: root.page === "notifications" ? history.clear(NotificationManager.Notifications.ClearExpired) : clipHistory.clearHistory()
            }
        }

        ListView {
            id: list
            visible: root.page === "notifications"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Kirigami.Units.smallSpacing
            model: root.expanded ? history : null
            delegate: Rectangle {
                required property var model
                required property int index
                width: ListView.view.width
                height: card.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: 8
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                RowLayout {
                    id: card
                    anchors { fill: parent; margins: Kirigami.Units.largeSpacing }
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Icon {
                        source: model.applicationIconName || "preferences-desktop-notification"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Layout.preferredWidth
                        Layout.alignment: Qt.AlignTop
                    }
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        PC3.Label { text: model.applicationName || ""; opacity: 0.7; font: Kirigami.Theme.smallFont; Layout.fillWidth: true; elide: Text.ElideRight }
                        PC3.Label { text: model.summary || ""; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.Wrap }
                        PC3.Label { text: model.body || ""; visible: text !== ""; Layout.fillWidth: true; wrapMode: Text.Wrap
                                    maximumLineCount: 3; elide: Text.ElideRight; textFormat: Text.StyledText }
                        // A saved screenshot (or any picture the notification points to): its preview, like the classic snip toast.
                        Image {
                            readonly property string pic: (model.urls || []).map(String).filter(u => /\.(png|jpe?g|webp)$/i.test(u))[0] || ""
                            visible: pic !== ""
                            source: pic
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible ? Kirigami.Units.gridUnit * 7 : 0
                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignLeft
                            asynchronous: true
                            sourceSize.height: Kirigami.Units.gridUnit * 14
                        }
                    }
                    PC3.ToolButton {
                        icon.color: Kirigami.Theme.textColor   // symbolic icons follow the panel's text colour
                        icon.name: "window-close"
                        Layout.alignment: Qt.AlignTop
                        onClicked: history.close(history.index(index, 0))
                    }
                }
            }
            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.gridUnit * 4
                visible: list.count === 0
                iconName: "notification-inactive"
                text: "No new notifications"
            }
        }

        ListView {   // clipboard history: click to copy again
            id: clips
            visible: root.page === "clipboard"
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Kirigami.Units.smallSpacing
            model: root.expanded && root.page === "clipboard" ? clipHistory : null
            delegate: Rectangle {
                id: clipCard
                required property var model
                readonly property var uuid: model.uuid !== undefined ? model.uuid : model.UuidRole
                readonly property bool isImage: model.type === 1 || (!model.display && !!model.decoration)
                width: ListView.view.width
                height: clipRow.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: 8
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, clipMouse.containsMouse ? 0.12 : 0.06)
                MouseArea {
                    id: clipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: { clipHistory.moveToTop(clipCard.uuid); root.expanded = false }
                }
                RowLayout {
                    id: clipRow
                    anchors { fill: parent; margins: Kirigami.Units.largeSpacing }
                    KQuickAddons.QImageItem {
                        visible: clipCard.isImage
                        image: clipCard.isImage ? clipCard.model.decoration : undefined
                        fillMode: KQuickAddons.QImageItem.PreserveAspectFit
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? Kirigami.Units.gridUnit * 6 : 0
                    }
                    PC3.Label {
                        visible: !clipCard.isImage
                        text: (clipCard.model.display || "").trim()
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                    PC3.ToolButton {
                        icon.color: Kirigami.Theme.textColor
                        icon.name: "window-close"
                        Layout.alignment: Qt.AlignTop
                        onClicked: clipHistory.remove(clipCard.uuid)
                    }
                }
            }
            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.gridUnit * 4
                visible: clips.count === 0
                iconName: "edit-paste"
                text: "Nothing copied yet"
                explanation: "Text and pictures you copy, and your snips, show up here"
            }
        }

        GridLayout {   // quick tiles
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            columns: 4
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.smallSpacing
            Repeater {
                model: [
                    { label: "Wi-Fi", icon: "network-wireless", show: nmDevices.wirelessDeviceAvailable, checkable: true,
                      on: () => nmEnabled.wirelessEnabled, act: () => nm.enableWireless(!nmEnabled.wirelessEnabled) },
                    { label: "Bluetooth", icon: "network-bluetooth", show: BluezQt.Manager.adapters.length > 0, checkable: true,
                      on: () => !BluezQt.Manager.bluetoothBlocked, act: () => BluezQt.Manager.bluetoothBlocked = !BluezQt.Manager.bluetoothBlocked },
                    { label: "Airplane mode", icon: "network-flightmode-on", show: true, checkable: true,
                      on: () => PlasmaNM.Configuration.airplaneModeEnabled,
                      act: () => { const v = !PlasmaNM.Configuration.airplaneModeEnabled; nm.enableAirplaneMode(v); PlasmaNM.Configuration.airplaneModeEnabled = v } },
                    { label: "Do not disturb", icon: "notifications-disabled", show: true, checkable: true,
                      on: () => root.dndOn, act: () => root.setDnd(!root.dndOn) },
                    { label: "Battery saver", icon: "battery-profile-powersave", show: true, checkable: true,
                      on: () => root.batterySaver, act: () => root.setProfile(root.batterySaver ? "balanced" : "power-saver") },
                    { label: "Night light", icon: "redshift-status-on", show: true, checkable: true,
                      on: () => root.nightLight, act: () => root.setNightLight(!root.nightLight) },
                    { label: "Screenshot", icon: "camera-photo", show: true, checkable: false,
                      on: () => false, act: () => { root.expanded = false; run.connectSource("spectacle --region") } },
                    { label: "All settings", icon: "configure", show: true, checkable: false,
                      on: () => false, act: () => { root.expanded = false; run.connectSource("fennek-app settings") } }
                ]
                // Quick tile: filled accent when on, soft grey when off; icon over the label.
                delegate: Rectangle {
                    id: tile
                    readonly property bool on: modelData.checkable && modelData.on()
                    visible: modelData.show
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3.6
                    radius: 8
                    color: on ? Kirigami.Theme.highlightColor
                              : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                                        tileMouse.containsMouse ? 0.14 : 0.08)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Accessible.role: modelData.checkable ? Accessible.CheckBox : Accessible.Button
                    Accessible.name: modelData.label
                    Accessible.checked: on
                    activeFocusOnTab: true
                    Keys.onSpacePressed: modelData.act()
                    Keys.onReturnPressed: modelData.act()
                    border.width: activeFocus ? 2 : 0
                    border.color: Kirigami.Theme.focusColor
                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - Kirigami.Units.smallSpacing * 2
                        spacing: Kirigami.Units.smallSpacing
                        Kirigami.Icon {
                            source: modelData.icon
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                            color: tile.on ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                            isMask: true
                        }
                        PC3.Label {
                            text: modelData.label
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font: Kirigami.Theme.smallFont
                            color: tile.on ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        }
                    }
                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.act()
                    }
                }
            }
        }

        RowLayout {   // brightness, only where the screen supports it
            visible: root.brightness >= 0
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon { source: "brightness-high"; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
            PC3.Slider {
                Layout.fillWidth: true
                from: 1; to: 100; stepSize: 1
                value: Math.max(1, root.brightness)
                onMoved: { root.brightness = value; setBrightness.restart() }
            }
        }
    }
}
