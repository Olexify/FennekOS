// Fennek Firewall: which apps may use the internet. A window over fennek-firewall (block / allow / list --json);
// blocking and allowing ask for the admin password (pkexec). Runs as plasmawindowed org.fennek.firewall.
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation

    property var blocked: []
    property bool busy: false
    readonly property string listCmd: "fennek-firewall list --json"
    readonly property string profileCmd: "fennek-firewall profile"
    property string profile: ""            // "home" or "public" (current connection)

    // Shell-quote one argument (the engine runs commands through sh).
    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function change(action, program) {
        if (!program.trim()) return
        busy = true
        run.connectSource("fennek-firewall " + action + " " + q(program.trim()))
    }

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            if (source === root.listCmd) {
                try { root.blocked = JSON.parse(data.stdout) } catch (e) { root.blocked = [] }
            } else if (source === root.profileCmd) {
                root.profile = data.stdout.trim()
            } else if (source.startsWith(root.profileCmd)) {
                root.busy = false
                connectSource(root.profileCmd)     // re-read: the change may have been cancelled
            } else {
                root.busy = false
                program.text = ""
                connectSource(root.listCmd)        // refresh after block / allow
            }
            disconnectSource(source)
        }
        Component.onCompleted: { connectSource(root.listCmd); connectSource(root.profileCmd) }
    }

    FileDialog {
        id: picker
        title: "Choose an app"
        onAccepted: program.text = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""))
    }

    fullRepresentation: QQC2.Page {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 36
        Layout.preferredHeight: Kirigami.Units.gridUnit * 30

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit * 2
            spacing: Kirigami.Units.largeSpacing * 2

            Kirigami.Heading { text: "Firewall"; level: 1 }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Nothing on the network can connect to this PC, except what the desktop needs (finding printers, "
                    + "pairing your phone). Below you choose which apps may not use the internet."
            }

            Kirigami.Heading { text: "This network"; level: 3 }
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

            Kirigami.Heading { text: "Apps without internet"; level: 3 }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.blocked
                delegate: QQC2.ItemDelegate {
                    width: ListView.view.width
                    contentItem: RowLayout {
                        Kirigami.Icon { source: "network-disconnect"; Layout.preferredWidth: Kirigami.Units.iconSizes.medium; Layout.preferredHeight: Layout.preferredWidth }
                        QQC2.Label { text: modelData.name; font.bold: true; Layout.fillWidth: true; elide: Text.ElideMiddle }
                        QQC2.Button { text: "Allow internet"; icon.name: "network-connect"; enabled: !root.busy; onClicked: root.change("allow", modelData.program) }
                    }
                }
                QQC2.Label {
                    anchors.centerIn: parent
                    visible: root.blocked.length === 0
                    opacity: 0.7
                    text: "No app is blocked: every app can use the internet."
                }
            }

            RowLayout {
                Layout.fillWidth: true
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
                }
            }
        }
    }
}
