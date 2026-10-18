// Fennek Updates: everything about updates in one calm window. Status (up to date / update ready / behind), check
// and install now, automatic updates on or off, when they run, pausing, Store apps, and going back.
// Runs as fennek-app updates. Settings change through /usr/libexec/fennek-update-settings (pkexec).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: root
    visible: true
    title: "Updates"
    width: Kirigami.Units.gridUnit * 40
    height: Kirigami.Units.gridUnit * 38
    minimumWidth: Kirigami.Units.gridUnit * 30
    minimumHeight: Kirigami.Units.gridUnit * 26

    readonly property string helper: "/usr/libexec/fennek-update-settings"
    readonly property string settingsCmd: helper + " get"
    readonly property string statusCmd: "rpm-ostree status --json"
    readonly property string checkCmd: "rpm-ostree upgrade --check"
    readonly property string installCmd: "rpm-ostree upgrade"

    property var settings: ({ auto: true, schedule: { kind: "default" }, paused_until: "", apps_auto: true })
    property var booted: null          // the running version
    property var staged: null          // a downloaded update waiting for restart
    property string state: "idle"      // idle | checking | available | uptodate | installing | failed
    property string detail: ""
    readonly property int daysOld: booted && booted.timestamp ? Math.floor((Date.now() / 1000 - booted.timestamp) / 86400) : 0
    readonly property var weekdays: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property var weekdayNames: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    function day(ts) { return new Date(ts * 1000).toLocaleDateString(Qt.locale(), Locale.LongFormat) }
    function set(args) { run.connectSource("pkexec " + helper + " set " + args) }
    function refresh() { run.connectSource(settingsCmd); run.connectSource(statusCmd) }

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            const code = data["exit code"]
            if (source === root.settingsCmd) {
                try { root.settings = JSON.parse(data.stdout) } catch (e) {}
            } else if (source === root.statusCmd) {
                try {
                    const d = JSON.parse(data.stdout).deployments
                    root.booted = d.find(x => x.booted) || null
                    root.staged = d.find(x => x.staged) || null
                } catch (e) {}
            } else if (source === root.checkCmd) {
                root.state = code === 0 ? "available" : code === 77 ? "uptodate" : "failed"
                root.detail = code === 0 || code === 77 ? "" : (data.stderr || data.stdout).trim()
            } else if (source === root.installCmd) {
                root.state = code === 0 ? "idle" : "failed"
                root.detail = code === 0 ? "" : (data.stderr || data.stdout).trim()
                connectSource(root.statusCmd)
            } else {   // a settings change
                connectSource(root.settingsCmd)
            }
            disconnectSource(source)
        }
        Component.onCompleted: root.refresh()
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
                spacing: Kirigami.Units.largeSpacing * 2
                Kirigami.Icon { source: "system-software-update"; Layout.preferredWidth: 48; Layout.preferredHeight: 48 }
                ColumnLayout {
                    spacing: 2
                    Kirigami.Heading { text: "Updates"; level: 1 }
                    QQC2.Label {
                        opacity: 0.75
                        text: root.booted ? "Fennek OS" + (root.booted.version ? " " + root.booted.version : "")
                                            + " · installed " + root.day(root.booted.timestamp) : "Fennek OS"
                    }
                }
            }

            // Status: what matters right now, with the one button for it.
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                implicitHeight: statusRow.implicitHeight + Kirigami.Units.gridUnit * 2
                radius: 10
                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.10)
                RowLayout {
                    id: statusRow
                    anchors { fill: parent; margins: Kirigami.Units.gridUnit }
                    spacing: Kirigami.Units.gridUnit
                    Kirigami.Icon {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        source: root.staged ? "system-reboot" : root.state === "available" ? "update-high"
                              : root.state === "failed" ? "dialog-warning" : "checkmark"
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Kirigami.Heading {
                            level: 3
                            text: root.staged ? "An update is ready"
                                : root.state === "checking" ? "Checking for updates…"
                                : root.state === "installing" ? "Downloading and installing…"
                                : root.state === "available" ? "An update is available"
                                : root.state === "failed" ? "That didn't work"
                                : "You're up to date"
                        }
                        QQC2.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            opacity: 0.8
                            text: root.staged ? "Restart to finish. Your files and apps stay as they are."
                                : root.state === "available" ? "It downloads in the background; you finish it with a restart."
                                : root.state === "failed" ? (root.detail || "Check your internet connection and try again.")
                                : root.state === "uptodate" ? "Checked just now."
                                : root.state === "idle" ? "Updates arrive by themselves; you can also check now." : ""
                        }
                    }
                    QQC2.BusyIndicator { visible: root.state === "checking" || root.state === "installing"; running: visible }
                    QQC2.Button {
                        visible: !(root.state === "checking" || root.state === "installing")
                        highlighted: true
                        text: root.staged ? "Restart now" : root.state === "available" ? "Install now" : "Check for updates"
                        onClicked: {
                            if (root.staged) run.connectSource("systemctl reboot")
                            else if (root.state === "available") { root.state = "installing"; run.connectSource(root.installCmd) }
                            else { root.state = "checking"; run.connectSource(root.checkCmd) }
                        }
                    }
                }
            }
            Kirigami.InlineMessage {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                visible: !root.staged && root.daysOld > 14
                type: Kirigami.MessageType.Warning
                text: "This PC hasn't been updated for " + root.daysOld + " days. Updates bring security fixes: check for updates."
            }
            Kirigami.InlineMessage {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                visible: root.settings.paused_until !== ""
                type: Kirigami.MessageType.Information
                text: "Automatic updates are paused until " + root.settings.paused_until + "."
                actions: [ Kirigami.Action { text: "Resume"; onTriggered: root.set("resume") } ]
            }

            Kirigami.FormLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2

                Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Automatic updates" }
                QQC2.Switch {
                    Kirigami.FormData.label: "Fennek OS:"
                    text: "Download updates by themselves"
                    checked: root.settings.auto
                    onToggled: root.set("auto " + (checked ? "on" : "off"))
                }
                RowLayout {
                    Kirigami.FormData.label: "When:"
                    enabled: root.settings.auto
                    QQC2.ComboBox {
                        id: when
                        model: ["About once a day", "Every day at", "Every week on"]
                        currentIndex: root.settings.schedule.kind === "daily" ? 1 : root.settings.schedule.kind === "weekly" ? 2 : 0
                        onActivated: index => index === 0 ? root.set("schedule default")
                                   : index === 1 ? root.set("schedule daily " + hour.currentText)
                                   : root.set("schedule weekly " + root.weekdays[dayBox.currentIndex] + " " + hour.currentText)
                    }
                    QQC2.ComboBox {
                        id: dayBox
                        visible: when.currentIndex === 2
                        model: root.weekdayNames
                        currentIndex: Math.max(0, root.weekdays.indexOf(root.settings.schedule.day || "Sun"))
                        onActivated: index => root.set("schedule weekly " + root.weekdays[index] + " " + hour.currentText)
                    }
                    QQC2.ComboBox {
                        id: hour
                        visible: when.currentIndex > 0
                        model: Array.from({ length: 24 }, (_, h) => (h < 10 ? "0" : "") + h + ":00")
                        currentIndex: Math.max(0, model.indexOf(root.settings.schedule.time || "03:00"))
                        onActivated: index => when.currentIndex === 1 ? root.set("schedule daily " + model[index])
                                            : root.set("schedule weekly " + root.weekdays[dayBox.currentIndex] + " " + model[index])
                    }
                }
                QQC2.ComboBox {
                    Kirigami.FormData.label: "Pause:"
                    model: ["Don't pause", "For 1 week", "For 2 weeks", "For 4 weeks"]
                    currentIndex: 0
                    onActivated: index => index === 0 ? root.set("resume") : root.set("pause " + [0, 7, 14, 28][index])
                }
                QQC2.Switch {
                    Kirigami.FormData.label: "Store apps:"
                    text: "Update by themselves"
                    checked: root.settings.apps_auto
                    onToggled: root.set("apps " + (checked ? "on" : "off"))
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 24
                    wrapMode: Text.Wrap
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                    text: "Updates download quietly and are installed when you restart; nothing restarts on its own."
                }

                Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Recovery" }
                QQC2.Button {
                    Kirigami.FormData.label: "Something broke after an update:"
                    icon.name: "edit-undo"
                    text: "Go back to the previous version"
                    onClicked: run.connectSource("fennek-go-back")
                }
                QQC2.Button {
                    Kirigami.FormData.label: "Your files:"
                    icon.name: "drive-removable-media"
                    text: "Backup and restore"
                    onClicked: run.connectSource("fennek-app backup")
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 24
                    wrapMode: Text.Wrap
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                    text: "An earlier version of one file: right-click it in Files, then Previous versions."
                }
            }
            Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
        }
    }
}
