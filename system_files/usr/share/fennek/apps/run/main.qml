// Fennek Run (Super+R): a calm card in the middle of the screen, like the classic Run box but prettier. Type a
// program, a classic command (calc, notepad, ncpa.cpl…), a file or folder, or a web address; suggestions come from
// what you ran before and the classic commands. Options: run as administrator, run in a terminal. Browse picks a
// file. Enter runs, Escape closes. The fennekwinx KWin script centres it. Runs through fennek-run-command.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: root
    visible: true
    title: "Run"
    flags: Qt.FramelessWindowHint | Qt.Dialog
    color: "transparent"
    width: Kirigami.Units.gridUnit * 34
    height: card.implicitHeight + Kirigami.Units.gridUnit * 2

    readonly property string helper: "/usr/libexec/fennek-run-command"
    readonly property var classic: ["calc", "notepad", "mspaint", "explorer", "cmd", "control", "taskmgr", "snippingtool",
        "msinfo32", "winver", "appwiz.cpl", "diskmgmt.msc", "firewall.cpl", "ncpa.cpl", "timedate.cpl", "mmsys.cpl",
        "powercfg.cpl", "main.cpl", "desk.cpl", "firefox", "dolphin", "konsole"]
    property var past: []
    property string error: ""
    readonly property var suggestions: {
        const q = field.text.trim().toLowerCase()
        if (q === "") return []
        const seen = {}
        return past.concat(classic).filter(s => {
            const k = s.toLowerCase()
            if (seen[k] || !k.startsWith(q) || k === q) return false
            seen[k] = true
            return true
        }).slice(0, 6)
    }

    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function go() {
        if (field.text.trim() === "") return
        error = ""
        const opts = (admin.checked ? " --admin" : "") + (terminal.checked ? " --terminal" : "")
        run.connectSource(helper + opts + " -- " + q(field.text))
    }

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source)
            if (source === root.helper + " --history") {
                try { root.past = JSON.parse(data.stdout) } catch (e) {}
                if (root.past.length) { field.text = root.past[0]; field.selectAll() }   // like the classic box
            } else if (data["exit code"] === 0) {
                Qt.quit()
            } else {
                root.error = data.stdout.trim() || "That didn't open."
            }
        }
        Component.onCompleted: connectSource(root.helper + " --history")
    }

    FileDialog {
        id: browse
        title: "Browse"
        onAccepted: field.text = selectedFile.toString().replace(/^file:\/\//, "")
    }

    Shortcut { sequences: ["Escape"]; onActivated: Qt.quit() }
    // Clicking elsewhere closes it (once it had the focus; not while Browse is open).
    property bool wasActive: false
    onActiveChanged: { if (active) wasActive = true; else if (wasActive && !browse.visible) Qt.quit() }

    Rectangle {
        id: card
        anchors { fill: parent; margins: Kirigami.Units.gridUnit }
        implicitHeight: body.implicitHeight + Kirigami.Units.gridUnit * 2.4
        radius: 16
        color: Kirigami.Theme.backgroundColor
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)
        border.width: 1

        ColumnLayout {
            id: body
            anchors { fill: parent; margins: Kirigami.Units.gridUnit * 1.2 }
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                spacing: Kirigami.Units.largeSpacing
                Rectangle {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.6
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: 12
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
                    Kirigami.Icon { anchors.centerIn: parent; source: "system-run"; width: parent.width * .6; height: width }
                }
                ColumnLayout {
                    spacing: 0
                    Kirigami.Heading { text: "Run"; level: 2 }
                    QQC2.Label { text: "Open a program, folder, document or web address."; opacity: 0.7 }
                }
                Item { Layout.fillWidth: true }
                QQC2.ToolButton { icon.name: "window-close"; onClicked: Qt.quit(); QQC2.ToolTip.visible: hovered; QQC2.ToolTip.text: "Close" }
            }

            QQC2.TextField {
                id: field
                Layout.fillWidth: true
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.25
                placeholderText: "calc, notepad, ~/Documents, kitsumi.org…"
                focus: true
                onAccepted: root.go()
                onTextEdited: root.error = ""
                Keys.onDownPressed: if (root.suggestions.length) { suggestionsList.currentIndex = 0; suggestionsList.forceActiveFocus() }
            }

            // Suggestions: what you ran before and the classic commands (click or arrow keys + Enter).
            ListView {
                id: suggestionsList
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                visible: root.suggestions.length > 0
                interactive: false
                model: root.suggestions
                keyNavigationWraps: true
                Keys.onReturnPressed: { field.text = root.suggestions[currentIndex]; root.go() }
                Keys.onUpPressed: currentIndex > 0 ? decrementCurrentIndex() : field.forceActiveFocus()
                delegate: QQC2.ItemDelegate {
                    required property string modelData
                    required property int index
                    width: ListView.view.width
                    highlighted: ListView.isCurrentItem && suggestionsList.activeFocus
                    text: modelData
                    icon.name: root.past.indexOf(modelData) >= 0 ? "document-open-recent" : "system-run"
                    onClicked: { field.text = modelData; root.go() }
                }
            }

            Kirigami.InlineMessage {
                Layout.fillWidth: true
                visible: root.error !== ""
                type: Kirigami.MessageType.Warning
                text: root.error
            }

            RowLayout {
                spacing: Kirigami.Units.gridUnit
                QQC2.CheckBox {
                    id: admin
                    text: "Run as administrator"
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: 600
                    QQC2.ToolTip.text: "Runs the command with administrator rights in a terminal (asks for your password)."
                }
                QQC2.CheckBox {
                    id: terminal
                    text: "Run in a terminal"
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: 600
                    QQC2.ToolTip.text: "Shows the command's output in a terminal that stays open."
                }
            }

            RowLayout {
                Layout.topMargin: Kirigami.Units.smallSpacing
                QQC2.Button { text: "Browse…"; icon.name: "document-open"; onClicked: browse.open() }
                Item { Layout.fillWidth: true }
                QQC2.Button { text: "Cancel"; onClicked: Qt.quit() }
                QQC2.Button { text: "Run"; icon.name: "media-playback-start"; highlighted: true; enabled: field.text.trim() !== ""; onClicked: root.go() }
            }
        }
    }
}
