// Fennek Launch (Super+R): a calm card in the middle of the screen. Type a program, a classic command (calc,
// notepad, ncpa.cpl…), a file or folder, or a web address. Below the box: what you can run (what you ran before, the
// classic commands), then files and folders on this PC that match (the fennek-search index, over D-Bus). Options:
// as administrator, in a terminal. Browse picks a file. Enter opens, Escape closes. The fennekwinx KWin script
// centres it. Runs through fennek-run-command.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: root
    visible: true
    title: "Launch"
    flags: Qt.FramelessWindowHint | Qt.Dialog
    color: "transparent"
    width: Kirigami.Units.gridUnit * 34
    height: card.implicitHeight + Kirigami.Units.gridUnit * 2

    readonly property string helper: "/usr/libexec/fennek-run-command"
    readonly property var classic: ["calc", "notepad", "mspaint", "explorer", "cmd", "control", "taskmgr", "snippingtool",
        "msinfo32", "winver", "appwiz.cpl", "diskmgmt.msc", "firewall.cpl", "ncpa.cpl", "timedate.cpl", "mmsys.cpl",
        "powercfg.cpl", "main.cpl", "desk.cpl", "firefox", "dolphin", "konsole"]
    property var past: []
    property var apps: []    // installed apps: [name, id, icon]
    property var files: []   // matching files and folders on this PC: [path, name, folder it is in, icon]
    property string error: ""
    readonly property var commands: {
        const q = field.text.trim().toLowerCase()
        if (q === "") return []
        const seen = {}
        return past.concat(classic).filter(s => {
            const k = s.toLowerCase()
            if (seen[k] || !k.startsWith(q) || k === q) return false
            seen[k] = true
            return true
        }).slice(0, 5)
    }
    // Installed apps whose name starts with (then contains) what you typed.
    readonly property var appMatches: {
        const q = field.text.trim().toLowerCase()
        if (q.length < 2) return []
        const starts = apps.filter(a => a[0].toLowerCase().startsWith(q))
        const has = apps.filter(a => !a[0].toLowerCase().startsWith(q) && a[0].toLowerCase().indexOf(q) >= 0)
        return starts.concat(has).slice(0, 4)
    }
    // One list: apps and commands first, then (under their own heading) files.
    readonly property var suggestions: appMatches.map(a => ({ kind: "Run", text: a[0], sub: "", path: "", app: a[1], icon: a[2] }))
        .concat(commands.map(c => ({ kind: "Run", text: c, sub: "", path: "" })))
        .concat(files.map(f => ({ kind: "On this PC", text: f[1], sub: f[2], path: f[0], icon: f[3] })))
    readonly property string findCmd: "busctl --user --json=short call org.fennek.Search /runner org.kde.krunner1 Match s "
    function find() {
        const t = field.text.trim()
        if (t.length < 2 || /^[a-z]+:\/\//i.test(t)) { files = []; return }
        run.connectSource(findCmd + q(t))
    }
    Timer { id: findLater; interval: 180; onTriggered: root.find() }
    function pick(s) {
        if (s.app) { run.connectSource(helper + " --app " + q(s.app)); return }
        if (s.path) { root.visible = false; run.connectSource("setsid -f xdg-open " + q(s.path)); bye.start() }
        else { field.text = s.text; go() }
    }
    Timer { id: bye; interval: 1500; onTriggered: Qt.quit() }

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
            if (source.startsWith(root.findCmd)) {
                if (source !== root.findCmd + root.q(field.text.trim())) return   // typed on meanwhile
                try {
                    const home = String(StandardPaths.writableLocation(StandardPaths.HomeLocation)).replace("file://", "")
                    root.files = JSON.parse(data.stdout).data[0].slice(0, 6).map(m =>
                        [m[0], m[1], m[0].slice(0, m[0].length - m[1].length - 1).replace(home, "~") || "/", m[2]])
                } catch (e) { root.files = [] }
                return
            }
            if (source === root.helper + " --apps") {
                try { root.apps = JSON.parse(data.stdout) } catch (e) {}
                return
            }
            if (source === root.helper + " --history") {
                try { root.past = JSON.parse(data.stdout) } catch (e) {}
                if (root.past.length) { field.text = root.past[0]; field.selectAll() }   // like the classic box
            } else if (data["exit code"] === 0) {
                Qt.quit()
            } else {
                root.error = data.stdout.trim() || "That didn't open."
            }
        }
        Component.onCompleted: { connectSource(root.helper + " --history"); connectSource(root.helper + " --apps") }
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
                    Kirigami.Icon { anchors.centerIn: parent; source: "system-search"; width: parent.width * .6; height: width }
                }
                ColumnLayout {
                    spacing: 0
                    Kirigami.Heading { text: "Launch"; level: 2 }
                    QQC2.Label { text: "A program, a file or folder on this PC, or a web address."; opacity: 0.7 }
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
                onTextEdited: { root.error = ""; findLater.restart() }
                Keys.onDownPressed: if (root.suggestions.length) { suggestionsList.currentIndex = 0; suggestionsList.forceActiveFocus() }
            }

            // Suggestions: what you can run (what you ran before, the classic commands), then files and folders on this
            // PC (click, or arrow keys + Enter).
            ListView {
                id: suggestionsList
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                visible: root.suggestions.length > 0
                interactive: false
                model: root.suggestions
                // not interactive (no flicking) also turns off its arrow keys: handled here
                Keys.onReturnPressed: root.pick(root.suggestions[currentIndex])
                Keys.onEnterPressed: root.pick(root.suggestions[currentIndex])
                Keys.onUpPressed: currentIndex > 0 ? currentIndex-- : field.forceActiveFocus()
                Keys.onDownPressed: if (currentIndex < count - 1) currentIndex++
                // typing while in the list goes on in the box
                Keys.onPressed: event => {
                    if (event.text.length === 1 && event.text >= " " && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
                        field.forceActiveFocus(); field.insert(field.cursorPosition, event.text); findLater.restart(); event.accepted = true
                    }
                }
                section.property: "kind"
                section.delegate: ColumnLayout {
                    required property string section
                    width: ListView.view.width
                    spacing: 0
                    Kirigami.Separator { Layout.fillWidth: true; visible: section !== "Run"; Layout.topMargin: Kirigami.Units.smallSpacing }
                    QQC2.Label {
                        visible: section !== "Run"
                        text: section
                        opacity: 0.6
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                    }
                }
                delegate: QQC2.ItemDelegate {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    highlighted: ListView.isCurrentItem && suggestionsList.activeFocus
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            source: modelData.path || modelData.app ? (modelData.icon || "application-x-executable")
                                : (root.past.indexOf(modelData.text) >= 0 ? "document-open-recent" : "system-run")
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }
                        QQC2.Label { textFormat: Text.PlainText; text: modelData.text; elide: Text.ElideRight; Layout.fillWidth: !modelData.sub }   // file names: never markup
                        QQC2.Label { textFormat: Text.PlainText; visible: !!modelData.sub; text: modelData.sub; opacity: 0.55; elide: Text.ElideMiddle; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                    }
                    onClicked: root.pick(modelData)
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
                    text: "As administrator"
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: 600
                    QQC2.ToolTip.text: "Runs the command with administrator rights in a terminal (asks for your password)."
                }
                QQC2.CheckBox {
                    id: terminal
                    text: "In a terminal"
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
                QQC2.Button { text: "Open"; icon.name: "media-playback-start"; highlighted: true; enabled: field.text.trim() !== ""; onClicked: root.go() }
            }
        }
    }
}
