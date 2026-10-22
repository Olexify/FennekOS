// Fennek Search: every file and folder that matches, in a list with columns (Name, Folder, Date modified, Size),
// sortable, like the classic search results. Instant: it asks the running index (fennek-search --ask), never scans
// itself. The same filters as Start work here: ext:pdf  type:image  size:>10mb  dm:week  path:Work
// Run as fennek-app search [QUERY].
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: root
    visible: true
    title: query.text ? "Search: " + query.text : "Search"
    width: Kirigami.Units.gridUnit * 52
    height: Kirigami.Units.gridUnit * 34
    minimumWidth: Kirigami.Units.gridUnit * 30
    minimumHeight: Kirigami.Units.gridUnit * 18

    readonly property string helper: "/usr/libexec/fennek-search --ask "
    property var rows: []           // {path, name, folder, size, mtime, dir}
    property string sortKey: ""     // "" = best match first
    property bool sortDown: false
    property bool searching: false
    property bool failed: false

    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function size(b) {
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB"
        if (b >= 1024) return Math.round(b / 1024) + " KB"
        return b + " bytes"
    }
    function when(t) { return t ? Qt.formatDateTime(new Date(t * 1000), "dd.MM.yyyy HH:mm") : "" }
    function shown() {
        if (!sortKey) return rows
        const k = sortKey, dir = sortDown ? -1 : 1
        return rows.slice().sort((a, b) => (a.dir !== b.dir && k === "name" ? b.dir - a.dir
            : (typeof a[k] === "string" ? a[k].localeCompare(b[k]) : a[k] - b[k]) * dir))
    }
    function run() {
        const t = query.text.trim()
        if (t === "") { rows = []; return }
        searching = true
        ds.connectSource(helper + q(t))
    }

    P5Support.DataSource {
        id: ds
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source)
            if (source !== root.helper + root.q(query.text.trim())) return   // an older search
            root.searching = false
            root.failed = data["exit code"] !== 0
            const out = []
            for (const line of (data.stdout || "").split("\n")) {
                const f = line.split("\t")
                if (f.length !== 4) continue
                const cut = f[0].lastIndexOf("/")
                out.push({ path: f[0], name: f[0].slice(cut + 1), folder: f[0].slice(0, cut).replace(/^\/var\/home\/[^/]+|^\/home\/[^/]+/, "~"),
                           size: Number(f[1]), mtime: Number(f[2]), dir: f[3] === "1" })
            }
            root.rows = out
        }
    }
    Timer { id: later; interval: 220; onTriggered: root.run() }
    Component.onCompleted: {
        const start = Qt.application.arguments.slice(2).join(" ")
        if (start) { query.text = start; run() }
        query.forceActiveFocus()
    }

    header: QQC2.ToolBar {
        RowLayout {
            anchors.fill: parent
            Kirigami.SearchField {
                id: query
                Layout.fillWidth: true
                placeholderText: "Search your files and folders   (filters: ext:pdf  type:image  size:>10mb  dm:week)"
                onTextChanged: later.restart()
                Keys.onDownPressed: { list.forceActiveFocus(); list.currentIndex = 0 }
                onAccepted: if (list.count) Qt.openUrlExternally("file://" + list.model[0].path)
            }
        }
    }
    footer: QQC2.ToolBar {
        QQC2.Label {
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0.6
            text: root.failed ? "Search isn't running yet. It starts with your session; try again in a moment."
                : root.searching ? "Searching…"
                : query.text.trim() === "" ? "Type to search. Your home folder and plugged-in drives."
                : root.rows.length >= 500 ? "The first 500 matches. Type more to narrow it down."
                : root.rows.length + (root.rows.length === 1 ? " match" : " matches")
        }
    }

    component Title: QQC2.Label {
        property string key
        property string label
        text: label + (root.sortKey === key ? (root.sortDown ? " ▾" : " ▴") : "")
        opacity: titleMouse.containsMouse ? 1 : 0.75
        elide: Text.ElideRight
        leftPadding: Kirigami.Units.largeSpacing
        topPadding: Kirigami.Units.smallSpacing * 2
        bottomPadding: Kirigami.Units.smallSpacing * 2
        MouseArea {
            id: titleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { if (root.sortKey === key) root.sortDown = !root.sortDown; else { root.sortKey = key; root.sortDown = key === "mtime" || key === "size" } }
        }
    }
    QQC2.Menu {
        id: menu
        property string path: ""
        QQC2.MenuItem { text: "Open"; icon.name: "document-open"; onTriggered: Qt.openUrlExternally("file://" + menu.path) }
        QQC2.MenuItem { text: "Open file location"; icon.name: "folder-open"; onTriggered: ds.connectSource("setsid -f dolphin --select " + root.q(menu.path)) }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: Kirigami.Units.largeSpacing * 2
            spacing: 0
            Title { key: "name"; label: "Name"; Layout.fillWidth: true; Layout.minimumWidth: Kirigami.Units.gridUnit * 12 }
            Title { key: "folder"; label: "Folder"; Layout.preferredWidth: Kirigami.Units.gridUnit * 16 }
            Title { key: "mtime"; label: "Date modified"; Layout.preferredWidth: Kirigami.Units.gridUnit * 8 }
            Title { key: "size"; label: "Size"; Layout.preferredWidth: Kirigami.Units.gridUnit * 5 }
        }
        Kirigami.Separator { Layout.fillWidth: true }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.shown()
            reuseItems: true
            QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
            Keys.onReturnPressed: if (currentIndex >= 0) Qt.openUrlExternally("file://" + model[currentIndex].path)
            Keys.onUpPressed: currentIndex > 0 ? currentIndex-- : query.forceActiveFocus()
            Keys.onDownPressed: if (currentIndex < count - 1) currentIndex++
            delegate: QQC2.ItemDelegate {
                required property var modelData
                required property int index
                width: ListView.view.width
                highlighted: ListView.isCurrentItem && list.activeFocus
                onClicked: Qt.openUrlExternally("file://" + modelData.path)
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: { menu.path = modelData.path; menu.popup() }
                }
                contentItem: RowLayout {
                    spacing: 0
                    Kirigami.Icon {
                        source: modelData.dir ? "folder" : "text-x-generic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        Layout.rightMargin: Kirigami.Units.smallSpacing
                    }
                    QQC2.Label { textFormat: Text.PlainText; text: modelData.name; elide: Text.ElideRight; Layout.fillWidth: true; Layout.minimumWidth: Kirigami.Units.gridUnit * 11 }
                    QQC2.Label { textFormat: Text.PlainText; text: modelData.folder; elide: Text.ElideMiddle; opacity: 0.7; Layout.preferredWidth: Kirigami.Units.gridUnit * 16 }
                    QQC2.Label { text: root.when(modelData.mtime); opacity: 0.8; Layout.preferredWidth: Kirigami.Units.gridUnit * 8 }
                    QQC2.Label { text: modelData.dir ? "" : root.size(modelData.size); opacity: 0.8; Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
                }
            }
        }
    }
}
