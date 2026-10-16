// Fennek Backup: your folders on a USB drive, refreshed every hour while it is connected, older versions kept
// for a year. A window over fennek-backup (status / drives / use / off / run). Runs as fennek-app backup.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: root
    visible: true
    title: "Backup"
    width: Kirigami.Units.gridUnit * 36
    height: Kirigami.Units.gridUnit * 30
    minimumWidth: Kirigami.Units.gridUnit * 28
    minimumHeight: Kirigami.Units.gridUnit * 20

    property var status: ({ on: false, label: "", connected: false, last: 0, folder: "" })
    property var drives: []
    property bool busy: false
    property string message: ""
    readonly property string statusCmd: "fennek-backup status --json"
    readonly property string drivesCmd: "fennek-backup drives --json"

    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function act(cmd) { busy = true; message = ""; run.connectSource(cmd) }
    function lastText() {
        if (!status.last) return "Not backed up yet"
        return "Last backup: " + new Date(status.last * 1000).toLocaleString(Qt.locale(), Locale.ShortFormat)
    }

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            if (source === root.statusCmd) {
                try { root.status = JSON.parse(data.stdout) } catch (e) {}
            } else if (source === root.drivesCmd) {
                try { root.drives = JSON.parse(data.stdout) } catch (e) { root.drives = [] }
            } else {
                root.busy = false
                root.message = (data.stdout || data.stderr).trim()
                connectSource(root.statusCmd)
            }
            disconnectSource(source)
        }
        Component.onCompleted: { connectSource(root.statusCmd); connectSource(root.drivesCmd) }
    }
    // Drives come and go: look again every few seconds while the window is open.
    Timer { interval: 4000; repeat: true; running: true; onTriggered: { run.connectSource(root.drivesCmd); run.connectSource(root.statusCmd) } }

    QQC2.Page {
        anchors.fill: parent
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit * 2
            spacing: Kirigami.Units.largeSpacing * 2

            RowLayout {
                spacing: Kirigami.Units.largeSpacing * 2
                Kirigami.Icon { source: "drive-removable-media"; Layout.preferredWidth: 48; Layout.preferredHeight: 48 }
                ColumnLayout {
                    spacing: 2
                    Kirigami.Heading { text: "Backup"; level: 1 }
                    QQC2.Label {
                        text: root.status.on ? (root.status.label + (root.status.connected ? " · connected" : " · not connected"))
                                             : "Off"
                        opacity: 0.75
                    }
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Keeps a copy of your Documents, Pictures, Music, Videos and Desktop on a USB drive. Every hour while "
                    + "the drive is connected, the copy is brought up to date. Files you change or delete are not lost: "
                    + "their earlier versions are kept on the drive for a year."
            }

            // On: last backup + actions.
            ColumnLayout {
                visible: root.status.on
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                QQC2.Label { text: root.lastText(); font.weight: Font.DemiBold }
                RowLayout {
                    QQC2.Button {
                        text: "Back up now"
                        icon.name: "view-refresh"
                        enabled: !root.busy && root.status.connected
                        onClicked: root.act("fennek-backup run")
                    }
                    QQC2.Button {
                        text: "Open backup"
                        icon.name: "document-open-folder"
                        enabled: root.status.folder !== ""
                        onClicked: run.connectSource("xdg-open " + root.q(root.status.folder))
                    }
                    Item { Layout.fillWidth: true }
                    QQC2.Button {
                        text: "Turn off"
                        enabled: !root.busy
                        onClicked: root.act("fennek-backup off")
                    }
                }
            }

            // Pick a drive (also to switch drives).
            Kirigami.Heading { text: root.status.on ? "Back up to another drive" : "Choose a drive"; level: 3 }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.drives
                delegate: QQC2.ItemDelegate {
                    width: ListView.view.width
                    enabled: !root.busy
                    onClicked: root.act("fennek-backup use " + root.q(modelData.uuid))
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon { source: "drive-removable-media"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            QQC2.Label { text: modelData.label; font.weight: Font.DemiBold }
                            QQC2.Label {
                                text: Qt.locale().formattedDataSize(modelData.free, 1) + " free of " + Qt.locale().formattedDataSize(modelData.size, 1)
                                opacity: 0.7
                            }
                        }
                        QQC2.Label { text: modelData.uuid === root.status.uuid ? "In use" : "Use this drive"; opacity: 0.8 }
                    }
                }
                QQC2.Label {
                    anchors.centerIn: parent
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: root.drives.length === 0
                    opacity: 0.7
                    text: "Connect a USB drive to back up to."
                }
            }
            RowLayout {
                visible: root.busy
                QQC2.BusyIndicator { running: root.busy; Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5 }
                QQC2.Label { text: "Backing up… this can take a while the first time." }
            }
            QQC2.Label {
                visible: root.message !== "" && !root.busy
                text: root.message
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
        }
    }
}
