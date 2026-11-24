// Fennek Quarantine: what the download guard blocked, and the tools around it. Opens also when nothing is blocked.
// Status (guard on, virus definitions), the blocked files (delete, or restore a false alarm), and checks: scan a folder
// with the built-in scanner, check a file with VirusTotal. Runs as fennek-app quarantine over fennek-quarantine.
// The page itself, shown inside Settings (fennek-app quarantine opens Settings on it).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.ki18n

Item {
    id: root
    KI18nContext { id: tr; translationDomain: "fennek" }   // Fennek's own words in the person's language

    readonly property string listCmd: "fennek-quarantine --json"
    readonly property string guardCmd: "systemctl --user is-active fennek-download-guard"
    readonly property string defsCmd: "sh -c 'stat -c %Y /var/lib/clamav/daily.c?d 2>/dev/null | sort -n | tail -1'"
    readonly property string scanCmd: "sh -c 'd=$(kdialog --title Scan --getexistingdirectory \"$HOME\") && [ -n \"$d\" ] "
                                    + "&& clamscan -r --infected --no-summary -- \"$d\"; echo \"exit=$?\"'"
    readonly property string vtCmd: "sh -c 'f=$(kdialog --title VirusTotal --getopenfilename \"$HOME\") && [ -n \"$f\" ] && fennek-vt-check \"$f\"'"

    property var items: []
    property var selected: ({})
    property bool guardOn: false
    property real defsTime: 0
    property bool scanning: false
    property string scanResult: ""
    property string restoredTo: ""
    readonly property int selectedCount: Object.keys(selected).filter(k => selected[k]).length

    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function chosen() { return Object.keys(selected).filter(k => selected[k]).map(q).join(" ") }
    function refresh() { run.connectSource(listCmd); run.connectSource(guardCmd); run.connectSource(defsCmd) }

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            if (source === root.listCmd) {
                try { root.items = JSON.parse(data.stdout) } catch (e) { root.items = [] }
                root.selected = ({})
            } else if (source === root.guardCmd) {
                root.guardOn = data.stdout.trim() === "active"
            } else if (source === root.defsCmd) {
                root.defsTime = parseFloat(data.stdout) || 0
            } else if (source === root.scanCmd) {
                root.scanning = false
                const out = data.stdout.trim()
                const code = (out.match(/exit=(\d+)$/) || [, "x"])[1]
                const found = out.replace(/\n?exit=\d+$/, "").trim()
                root.scanResult = code === "0" ? tr.i18n("Nothing harmful found.")
                                : code === "1" ? tr.i18n("Harmful files found:") + "\n" + found
                                : code === "x" ? "" : tr.i18n("The scan didn't finish.")
            } else if (source.indexOf("--restore") >= 0) {
                try { root.restoredTo = JSON.parse(data.stdout).join("\n") } catch (e) {}
                connectSource(root.listCmd)
            } else {
                connectSource(root.listCmd)
            }
            disconnectSource(source)
        }
        Component.onCompleted: root.refresh()
    }

    Kirigami.PromptDialog {
        parent: QQC2.Overlay.overlay   // over the whole window, also inside Settings
        id: confirmRestore
        title: tr.i18np("Restore %1 file?", "Restore %1 files?", root.selectedCount)
        subtitle: tr.i18n("These were flagged as harmful. Restore only if you're sure it's a false alarm: opening real malware can damage your files.")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
        onAccepted: run.connectSource("fennek-quarantine --restore " + root.chosen())
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
                Kirigami.Icon { source: "fennek-quarantine"; Layout.preferredWidth: 48; Layout.preferredHeight: 48 }
                ColumnLayout {
                    spacing: 2
                    Kirigami.Heading { text: tr.i18n("Quarantine"); level: 1 }
                    QQC2.Label { text: tr.i18n("Downloads that were blocked as harmful, kept where they can't do anything."); opacity: 0.75 }
                }
            }

            // Protection status at a glance.
            RowLayout {
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.largeSpacing
                Repeater {
                    model: [
                        { icon: root.guardOn ? "security-high" : "security-low", title: tr.i18n("Download guard"),
                          text: root.guardOn ? tr.i18n("On: new downloads are checked") : tr.i18n("Off") },
                        { icon: "view-calendar-day", title: tr.i18n("Virus definitions"),
                          text: root.defsTime ? tr.i18n("Updated %1", new Date(root.defsTime * 1000).toLocaleDateString(Qt.locale(), Locale.ShortFormat)) : tr.i18n("Not downloaded yet") },
                        { icon: "fennek-quarantine", title: tr.i18n("In quarantine"),
                          text: root.items.length === 0 ? tr.i18n("Nothing") : tr.i18np("%1 file", "%1 files", root.items.length) }
                    ]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: tile.implicitHeight + Kirigami.Units.gridUnit
                        radius: 10
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
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

            // The blocked files.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Heading { text: tr.i18n("Blocked files"); level: 2 }
                Kirigami.PlaceholderMessage {
                    Layout.fillWidth: true
                    visible: root.items.length === 0
                    icon.name: "security-high"
                    text: tr.i18n("Nothing in quarantine")
                    explanation: tr.i18n("No downloads were blocked. If one is, it lands here, harmless, until you decide.")
                }
                Repeater {
                    model: root.items
                    delegate: QQC2.CheckDelegate {
                        required property var modelData
                        Layout.fillWidth: true
                        checked: !!root.selected[modelData.id]
                        onToggled: { const s = Object.assign({}, root.selected); s[modelData.id] = checked; root.selected = s }
                        contentItem: ColumnLayout {
                            spacing: 2
                            QQC2.Label { text: modelData.name; font.weight: Font.DemiBold; elide: Text.ElideMiddle; Layout.fillWidth: true; textFormat: Text.PlainText }
                            QQC2.Label {
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                                opacity: 0.75
                                font: Kirigami.Theme.smallFont
                                textFormat: Text.PlainText   // names come from downloads: never markup
                                text: modelData.threat + " · " + new Date(modelData.when * 1000).toLocaleString(Qt.locale(), Locale.ShortFormat)
                                      + (modelData.origin ? " · " + tr.i18n("from %1", modelData.origin) : "")
                            }
                        }
                    }
                }
                RowLayout {
                    visible: root.items.length > 0
                    QQC2.Button {
                        icon.name: "edit-delete"
                        text: tr.i18n("Delete permanently")
                        enabled: root.selectedCount > 0
                        onClicked: run.connectSource("fennek-quarantine --delete " + root.chosen())
                    }
                    QQC2.Button {
                        icon.name: "edit-undo"
                        text: tr.i18n("Restore…")
                        enabled: root.selectedCount > 0
                        onClicked: confirmRestore.open()
                    }
                }
                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: root.restoredTo !== ""
                    type: Kirigami.MessageType.Information
                    text: tr.i18n("Restored to: %1", root.restoredTo)
                    // (InlineMessage shows plain text for its text)
                }
            }

            // Checks you can run yourself.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Heading { text: tr.i18n("Check something now"); level: 2 }
                RowLayout {
                    QQC2.Button {
                        icon.name: "folder-open"
                        text: tr.i18n("Scan a folder…")
                        enabled: !root.scanning
                        onClicked: { root.scanning = true; root.scanResult = ""; run.connectSource(root.scanCmd) }
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: 600
                        QQC2.ToolTip.text: tr.i18n("With the built-in scanner. In a terminal: clamscan -r FOLDER")
                    }
                    QQC2.Button {
                        icon.name: "virustotal"
                        text: tr.i18n("Check a file with VirusTotal…")
                        onClicked: run.connectSource(root.vtCmd)
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: 600
                        QQC2.ToolTip.text: tr.i18n("Looks up the file's fingerprint at VirusTotal (70+ scanners). The file itself is never uploaded.")
                    }
                    QQC2.BusyIndicator { visible: root.scanning; running: visible }
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    visible: root.scanResult !== ""
                    text: root.scanResult
                    textFormat: Text.PlainText   // file names from the scan: never markup
                    wrapMode: Text.Wrap
                }
            }
            Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
        }
    }
}
