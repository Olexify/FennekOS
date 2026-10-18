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
    readonly property string releaseCmd: "cat /usr/lib/os-release"
    readonly property string milestonesCmd: "cat /usr/share/fennek/milestones.json"
    readonly property string tagsCmd: "skopeo list-tags docker://ghcr.io/olexify/fennekos"

    property var release: ({})          // os-release: PRETTY_NAME, IMAGE_VERSION, BUILD_ID
    property var milestones: []
    property var earlier: []            // dated signed builds available (newest first)
    property bool loadingEarlier: false
    readonly property string imageRef: booted ? (booted["container-image-reference"] || "") : ""
    readonly property bool arm: imageRef.indexOf("-arm64") >= 0
    readonly property string runningTag: (imageRef.match(/:([^:/]+)$/) || ["", ""])[1]
    readonly property bool onEarlier: runningTag !== "" && !runningTag.startsWith("latest")

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
    function refresh() {
        run.connectSource(settingsCmd); run.connectSource(statusCmd)
        run.connectSource(releaseCmd); run.connectSource(milestonesCmd)
    }
    // Changing the installed version: a clear question first, then the separate helper (fresh password every time).
    property string pendingTag: ""
    function switchTo(tag) { pendingTag = tag; confirmSwitch.open() }
    Kirigami.PromptDialog {
        id: confirmSwitch
        title: root.pendingTag === "latest" ? "Return to the latest version?" : "Install the build from " + root.tagDate(root.pendingTag) + "?"
        subtitle: root.pendingTag === "latest"
            ? "Fennek OS goes back to the newest version and gets updates again. It takes effect after a restart."
            : "This earlier build misses newer security fixes and gets no updates until you return to the latest. "
              + "Your files and apps are kept. It takes effect after a restart."
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: run.connectSource("pkexec /usr/libexec/fennek-switch-version " + root.pendingTag)
    }
    function tagDate(t) { return t.slice(0, 4) + "-" + t.slice(4, 6) + "-" + t.slice(6, 8) }

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
            } else if (source === root.releaseCmd) {
                const r = {}
                data.stdout.split("\n").forEach(l => { const m = l.match(/^(\w+)="?([^"]*)"?$/); if (m) r[m[1]] = m[2] })
                root.release = r
            } else if (source === root.milestonesCmd) {
                try { root.milestones = JSON.parse(data.stdout) } catch (e) {}
            } else if (source === root.tagsCmd) {
                root.loadingEarlier = false
                try {
                    const want = root.arm ? /^20\d{6}-arm64$/ : /^20\d{6}$/
                    root.earlier = JSON.parse(data.stdout).Tags.filter(t => want.test(t)).sort().reverse().slice(0, 30)
                } catch (e) { root.earlier = [] }
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
                    Kirigami.Heading { text: root.release.PRETTY_NAME || "Fennek OS"; level: 1 }
                    QQC2.Label {
                        opacity: 0.75
                        text: (root.release.IMAGE_VERSION ? "Version " + root.release.IMAGE_VERSION : "")
                              + (root.release.BUILD_ID ? " · build " + root.release.BUILD_ID : "")
                              + (root.booted ? " · installed " + root.day(root.booted.timestamp) : "")
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
                visible: root.onEarlier
                type: Kirigami.MessageType.Warning
                text: "You're on an earlier build (" + root.tagDate(root.runningTag) + "). It gets no updates and misses newer security fixes."
                actions: [ Kirigami.Action { text: "Return to the latest version"; onTriggered: root.switchTo("latest") } ]
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
            // Trails: the milestones of Fennek OS, yours highlighted.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Heading { text: "Your Fennek trail"; level: 2 }
                QQC2.Label { text: "The milestones of Fennek OS, and what each one brought."; opacity: 0.7 }
                Repeater {
                    model: root.milestones
                    delegate: Rectangle {
                        id: stone
                        required property var modelData
                        required property int index
                        readonly property bool current: index === 0
                        Layout.fillWidth: true
                        implicitHeight: card.implicitHeight + Kirigami.Units.gridUnit * 1.5
                        radius: 10
                        color: current ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.14)
                                       : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                        border.width: current ? 1 : 0
                        border.color: Kirigami.Theme.highlightColor
                        ColumnLayout {
                            id: card
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Kirigami.Units.gridUnit * 0.75 }
                            spacing: 4
                            QQC2.Label {
                                text: (stone.modelData.chapter || "").toUpperCase() + (stone.current ? "  ·  YOU ARE HERE" : "")
                                font: Kirigami.Theme.smallFont
                                opacity: 0.6
                            }
                            Kirigami.Heading { level: 3; text: stone.modelData.version + " · " + stone.modelData.name }
                            QQC2.Label { text: stone.modelData.tagline; Layout.fillWidth: true; wrapMode: Text.Wrap }
                            QQC2.Label {
                                visible: (stone.modelData.legacy || "") !== ""
                                text: stone.modelData.legacy || ""
                                font.italic: true
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }
                            Repeater {
                                model: stone.modelData.highlights || []
                                QQC2.Label { required property string modelData; text: "•  " + modelData; opacity: 0.85; Layout.fillWidth: true; wrapMode: Text.Wrap }
                            }
                            QQC2.Label {
                                text: new Date(stone.modelData.date).toLocaleDateString(Qt.locale(), "MMMM yyyy")
                                font: Kirigami.Theme.smallFont
                                opacity: 0.6
                            }
                        }
                    }
                }
            }

            // Advanced: an earlier signed nightly build (last ~30 days). Going back to the latest always works.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Heading { text: "Advanced: install an earlier version"; level: 2 }
                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    opacity: 0.8
                    text: "For when a recent change gets in your way. Earlier builds miss newer security fixes and get no "
                        + "updates until you return to the latest version. Your files and apps are kept; usually "
                        + "Go back to the previous version (above) is all you need."
                }
                RowLayout {
                    QQC2.Button {
                        text: root.earlier.length ? "Refresh the list" : "Show earlier versions"
                        enabled: !root.loadingEarlier
                        onClicked: { root.loadingEarlier = true; run.connectSource(root.tagsCmd) }
                    }
                    QQC2.BusyIndicator { visible: root.loadingEarlier; running: visible }
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: root.earlier
                        QQC2.Button {
                            required property string modelData
                            text: root.tagDate(modelData)
                            enabled: modelData !== root.runningTag
                            onClicked: root.switchTo(modelData.replace("-arm64", ""))
                        }
                    }
                }
            }
            Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
        }
    }
}
