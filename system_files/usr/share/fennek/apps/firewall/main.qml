// Fennek Firewall: which apps may use the internet, and what they're doing right now. A window over fennek-firewall
// (block / allow / list --json / active --json / profile); blocking and allowing ask for the admin password (pkexec).
// Apps online can be opened up: where the program lives, its processes, each connection. Runs as fennek-app firewall.
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: root
    visible: true
    title: "Firewall"
    width: Kirigami.Units.gridUnit * 42
    height: Kirigami.Units.gridUnit * 40
    minimumWidth: Kirigami.Units.gridUnit * 30
    minimumHeight: Kirigami.Units.gridUnit * 24

    property var blocked: []
    property var online: []                // apps with connections right now (refreshed while the window is open)
    property var open: ({})                // apps whose details are shown
    property bool busy: false
    readonly property string listCmd: "fennek-firewall list --json"
    readonly property string activeCmd: "fennek-firewall active --json"
    readonly property string profileCmd: "fennek-firewall profile"
    property string profile: ""            // "home" or "public" (current connection)

    // Shell-quote one argument (the engine runs commands through sh).
    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function change(action, program) {
        if (!program.trim()) return
        busy = true
        run.connectSource("fennek-firewall " + action + " " + q(program.trim()))
    }
    function toggle(p) { const o = Object.assign({}, open); o[p] = !o[p]; open = o }
    function iconFor(name) { return name.toLowerCase().replace(/\.exe$/, "") }
    function card(alpha) { return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, alpha) }

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            if (source === root.listCmd) {
                try { root.blocked = JSON.parse(data.stdout) } catch (e) { root.blocked = [] }
            } else if (source === root.activeCmd) {
                try { root.online = JSON.parse(data.stdout) } catch (e) { root.online = [] }
            } else if (source === root.profileCmd) {
                root.profile = data.stdout.trim()
            } else if (source.startsWith(root.profileCmd)) {
                root.busy = false
                connectSource(root.profileCmd)     // re-read: the change may have been cancelled
            } else {
                root.busy = false
                program.text = ""
                connectSource(root.listCmd)        // refresh after block / allow
                connectSource(root.activeCmd)
            }
            disconnectSource(source)
        }
        Component.onCompleted: { connectSource(root.listCmd); connectSource(root.profileCmd); connectSource(root.activeCmd) }
    }

    // Only runs while this window is open: no background cost.
    Timer { interval: 4000; repeat: true; running: true; onTriggered: run.connectSource(root.activeCmd) }

    FileDialog {
        id: picker
        title: "Choose an app"
        onAccepted: program.text = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""))
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing * 2

            Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
            RowLayout {
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.largeSpacing * 2
                Kirigami.Icon { source: "fennek-firewall"; Layout.preferredWidth: 48; Layout.preferredHeight: 48 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Kirigami.Heading { text: "Firewall"; level: 1 }
                    QQC2.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        opacity: 0.75
                        text: "Nothing on the network can reach this PC unless the desktop needs it. You choose which apps may use the internet."
                    }
                }
            }

            // At a glance.
            RowLayout {
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.largeSpacing
                Repeater {
                    model: [
                        { icon: root.profile === "public" ? "network-wireless-hotspot" : "go-home", title: "This network",
                          text: root.profile === "public" ? "Public: nothing can connect" : root.profile === "home" ? "Home or work" : "…" },
                        { icon: "network-connect", title: "Online now",
                          text: root.online.length + (root.online.length === 1 ? " app" : " apps") },
                        { icon: "network-disconnect", title: "Blocked",
                          text: root.blocked.length === 0 ? "No app" : root.blocked.length + (root.blocked.length === 1 ? " app" : " apps") }
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: tile.implicitHeight + Kirigami.Units.gridUnit
                        radius: 10
                        color: root.card(0.05)
                        RowLayout {
                            id: tile
                            anchors { fill: parent; margins: Kirigami.Units.gridUnit * 0.5 }
                            Kirigami.Icon { source: modelData.icon; Layout.preferredWidth: 28; Layout.preferredHeight: 28 }
                            ColumnLayout {
                                spacing: 0
                                QQC2.Label { text: modelData.title; font.weight: Font.DemiBold }
                                QQC2.Label { text: modelData.text; opacity: 0.75; font: Kirigami.Theme.smallFont }
                            }
                        }
                    }
                }
            }

            // Network profile.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Heading { text: "This network"; level: 2 }
                QQC2.RadioButton {
                    text: "Home or work: other devices can find printers and pair your phone"
                    checked: root.profile === "home"
                    enabled: !root.busy
                    onClicked: if (root.profile !== "home") { root.busy = true; run.connectSource(root.profileCmd + " home") }
                }
                QQC2.RadioButton {
                    text: "Public (café, airport, hotel): nothing can connect to this PC"
                    checked: root.profile === "public"
                    enabled: !root.busy
                    onClicked: if (root.profile !== "public") { root.busy = true; run.connectSource(root.profileCmd + " public") }
                }
            }

            // Apps online, each can be opened up.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Heading { text: "Using the internet now"; level: 2 }
                QQC2.Label { text: "Click an app to see where it lives, its processes and each connection."; opacity: 0.7; font: Kirigami.Theme.smallFont }
                Kirigami.PlaceholderMessage {
                    Layout.fillWidth: true
                    visible: root.online.length === 0
                    icon.name: "network-connect"
                    text: "No app is online right now"
                }
                Repeater {
                    model: root.online
                    delegate: Rectangle {
                        id: app
                        required property var modelData
                        readonly property bool expanded: !!root.open[modelData.program]
                        Layout.fillWidth: true
                        implicitHeight: appCol.implicitHeight + Kirigami.Units.gridUnit
                        radius: 10
                        color: root.card(expanded ? 0.08 : 0.04)
                        ColumnLayout {
                            id: appCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Kirigami.Units.gridUnit * 0.5 }
                            spacing: Kirigami.Units.smallSpacing
                            RowLayout {
                                Layout.fillWidth: true
                                MouseArea {
                                    Layout.fillWidth: true
                                    implicitHeight: head.implicitHeight
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggle(app.modelData.program)
                                    RowLayout {
                                        id: head
                                        anchors.fill: parent
                                        Kirigami.Icon { source: app.expanded ? "go-down" : "go-next"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
                                        Kirigami.Icon { source: root.iconFor(app.modelData.name); fallback: "application-x-executable"; Layout.preferredWidth: 28; Layout.preferredHeight: 28 }
                                        QQC2.Label { text: app.modelData.name; font.weight: Font.DemiBold; elide: Text.ElideMiddle; Layout.fillWidth: true; textFormat: Text.PlainText }
                                        QQC2.Label { text: app.modelData.connections === 1 ? "1 connection" : app.modelData.connections + " connections"; opacity: 0.7 }
                                    }
                                }
                                QQC2.Button { text: "Block"; icon.name: "network-disconnect"; enabled: !root.busy; onClicked: root.change("block", app.modelData.program) }
                            }
                            // Details.
                            GridLayout {
                                visible: app.expanded
                                Layout.fillWidth: true
                                Layout.leftMargin: Kirigami.Units.gridUnit * 2.5
                                columns: 2
                                columnSpacing: Kirigami.Units.largeSpacing
                                QQC2.Label { text: "Program"; opacity: 0.7 }
                                QQC2.Label { text: app.modelData.program; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere; textFormat: Text.PlainText }
                                QQC2.Label { text: (app.modelData.pids || []).length === 1 ? "Process" : "Processes"; opacity: 0.7 }
                                QQC2.Label { text: (app.modelData.pids || []).join(", "); Layout.fillWidth: true; wrapMode: Text.Wrap }
                            }
                            Repeater {
                                model: app.expanded ? (app.modelData.details || []) : []
                                RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Kirigami.Units.gridUnit * 2.5
                                    QQC2.Label { text: modelData.proto; font.family: "monospace"; opacity: 0.7; Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5 }
                                    QQC2.Label { text: modelData.peer; font.family: "monospace"; Layout.fillWidth: true; elide: Text.ElideMiddle; textFormat: Text.PlainText }
                                    QQC2.Label { text: modelData.state; opacity: 0.7 }
                                }
                            }
                            QQC2.Label {
                                visible: app.expanded && app.modelData.connections > (app.modelData.details || []).length
                                Layout.leftMargin: Kirigami.Units.gridUnit * 2.5
                                text: "… and " + (app.modelData.connections - (app.modelData.details || []).length) + " more"
                                opacity: 0.6
                                font: Kirigami.Theme.smallFont
                            }
                        }
                    }
                }
            }

            // Blocked apps.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Heading { text: "Apps without internet"; level: 2 }
                Kirigami.PlaceholderMessage {
                    Layout.fillWidth: true
                    visible: root.blocked.length === 0
                    icon.name: "security-high"
                    text: "No app is blocked"
                    explanation: "Every app can use the internet. Block one above, or by name below."
                }
                Repeater {
                    model: root.blocked
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: brow.implicitHeight + Kirigami.Units.gridUnit
                        radius: 10
                        color: root.card(0.04)
                        RowLayout {
                            id: brow
                            anchors { fill: parent; margins: Kirigami.Units.gridUnit * 0.5 }
                            Kirigami.Icon { source: "network-disconnect"; Layout.preferredWidth: 28; Layout.preferredHeight: 28 }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                QQC2.Label { text: modelData.name; font.weight: Font.DemiBold; elide: Text.ElideMiddle; Layout.fillWidth: true; textFormat: Text.PlainText }
                                QQC2.Label { text: modelData.program; opacity: 0.6; font: Kirigami.Theme.smallFont; elide: Text.ElideMiddle; Layout.fillWidth: true; textFormat: Text.PlainText }
                            }
                            QQC2.Button { text: "Allow internet"; icon.name: "network-connect"; enabled: !root.busy; onClicked: root.change("allow", modelData.program) }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    QQC2.TextField {
                        id: program
                        Layout.fillWidth: true
                        placeholderText: "App name (for example firefox) or a .exe file"
                        onAccepted: root.change("block", text)
                    }
                    QQC2.Button { text: "Browse…"; icon.name: "document-open"; onClicked: picker.open() }
                    QQC2.Button {
                        text: "Block internet"
                        icon.name: "network-disconnect"
                        enabled: !root.busy && program.text.trim() !== ""
                        onClicked: root.change("block", program.text)
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: 600
                        QQC2.ToolTip.text: "In a terminal: fennek-firewall block NAME"
                    }
                }
            }
            Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
        }
    }
}
