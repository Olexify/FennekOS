// Fennek Task Manager (Ctrl+Shift+Esc): what runs right now, grouped the way people think about it: Apps, Background
// services, Desktop, System services. Each row has a real name (an app's name and icon, a service's description), its
// CPU and memory, and opens to show the processes inside it. End task for your apps and background services; the
// desktop and system services are shown but not ended here. Detailed graphs: KDE's System Monitor (Performance).
// Data: /usr/libexec/fennek-tasks (cgroups; refreshed every 2 seconds while the window is visible).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: root
    visible: true
    title: "Task Manager"
    width: Kirigami.Units.gridUnit * 46
    height: Kirigami.Units.gridUnit * 34
    minimumWidth: Kirigami.Units.gridUnit * 30
    minimumHeight: Kirigami.Units.gridUnit * 20

    readonly property string helper: "/usr/libexec/fennek-tasks"
    property var data: ({ groups: [], mem_total: 0, mem_used: 0 })
    property var open: ({})         // unit -> true: rows showing their processes
    property string selected: ""
    property string filter: ""
    property string message: ""

    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function size(b) {
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576) return Math.round(b / 1048576) + " MB"
        return Math.round(b / 1024) + " KB"
    }
    function cpuTotal() {
        let t = 0
        for (const g of data.groups) for (const i of g.items) t += i.cpu
        return Math.min(100, t)
    }
    function shown(items) {
        const f = filter.toLowerCase()
        return f ? items.filter(i => (i.name + " " + i.desc + " " + i.procs.map(p => p.name).join(" ")).toLowerCase().indexOf(f) >= 0) : items
    }
    function refresh() { if (root.visible && !run.busy) { run.busy = true; run.connectSource(helper + " list") } }

    P5Support.DataSource {
        id: run
        property bool busy: false
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source)
            if (source === root.helper + " list") {
                busy = false
                try { root.data = JSON.parse(data.stdout) } catch (e) {}
            } else {
                root.message = data["exit code"] === 0 ? "" : ((data.stderr || "").trim() || "That didn't end.")
                root.refresh()
            }
        }
    }
    Timer { interval: 2000; running: root.visible && root.active !== undefined; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    header: QQC2.ToolBar {
        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing
            Kirigami.SearchField {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                placeholderText: "Find an app or service"
                onTextChanged: root.filter = text
            }
            // CPU and memory of the whole computer
            ColumnLayout {
                spacing: 2
                QQC2.Label { text: "Processor " + Math.round(root.cpuTotal()) + "%"; font: Kirigami.Theme.smallFont }
                QQC2.ProgressBar { from: 0; to: 100; value: root.cpuTotal(); Layout.preferredWidth: Kirigami.Units.gridUnit * 7 }
            }
            ColumnLayout {
                spacing: 2
                QQC2.Label { text: "Memory " + root.size(root.data.mem_used) + " of " + root.size(root.data.mem_total); font: Kirigami.Theme.smallFont }
                QQC2.ProgressBar { from: 0; to: root.data.mem_total || 1; value: root.data.mem_used; Layout.preferredWidth: Kirigami.Units.gridUnit * 9 }
            }
            Item { Layout.fillWidth: true }
            QQC2.ToolButton {
                text: "Performance"
                icon.name: "utilities-system-monitor"
                onClicked: run.connectSource("setsid -f plasma-systemmonitor --page-name overview")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: "Detailed graphs of processor, memory, disks and network"
            }
        }
    }

    footer: QQC2.ToolBar {
        RowLayout {
            anchors.fill: parent
            QQC2.Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: root.message !== "" ? root.message : "Click a row to see what's inside it."
                opacity: root.message !== "" ? 1 : 0.6
                color: root.message !== "" ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
            }
            QQC2.Button {
                text: "End task"
                icon.name: "process-stop"
                enabled: root.selected !== ""
                onClicked: { run.connectSource(root.helper + " end " + root.q(root.selected)); root.selected = "" }
            }
        }
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: 0
            // column titles
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                QQC2.Label { text: "Name"; opacity: 0.6; Layout.fillWidth: true }
                QQC2.Label { text: "Processor"; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
                QQC2.Label { text: "Memory"; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
            }
            Repeater {
                model: root.data.groups
                delegate: ColumnLayout {
                    id: group
                    required property var modelData
                    readonly property var items: root.shown(modelData.items)
                    Layout.fillWidth: true
                    spacing: 0
                    visible: items.length > 0
                    QQC2.Label {
                        text: group.modelData.name + " (" + group.items.length + ")"
                        font.weight: Font.DemiBold
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                        Layout.topMargin: Kirigami.Units.largeSpacing
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                    }
                    Repeater {
                        model: group.items
                        delegate: ColumnLayout {
                            id: row
                            required property var modelData
                            readonly property bool expanded: !!root.open[modelData.unit]
                            Layout.fillWidth: true
                            spacing: 0
                            QQC2.ItemDelegate {
                                Layout.fillWidth: true
                                highlighted: root.selected === row.modelData.unit
                                onClicked: {
                                    const o = Object.assign({}, root.open)
                                    if (o[row.modelData.unit]) delete o[row.modelData.unit]; else o[row.modelData.unit] = true
                                    root.open = o
                                    root.selected = row.modelData.can_end ? row.modelData.unit : ""
                                }
                                contentItem: RowLayout {
                                    spacing: Kirigami.Units.largeSpacing
                                    Kirigami.Icon {
                                        source: row.expanded ? "go-down" : "go-next"
                                        Layout.preferredWidth: 12; Layout.preferredHeight: 12; opacity: 0.5
                                    }
                                    Kirigami.Icon {
                                        source: row.modelData.icon || (group.modelData.key === "system" ? "preferences-system" : "system-run")
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                    }
                                    ColumnLayout {
                                        spacing: 0
                                        Layout.fillWidth: true
                                        QQC2.Label { textFormat: Text.PlainText; text: row.modelData.name; elide: Text.ElideRight; Layout.fillWidth: true }
                                        QQC2.Label {
                                            textFormat: Text.PlainText
                                            visible: row.modelData.desc !== "" && row.modelData.desc !== row.modelData.name
                                            text: row.modelData.desc + " · " + row.modelData.procs.length + (row.modelData.procs.length === 1 ? " process" : " processes")
                                            opacity: 0.55
                                            font: Kirigami.Theme.smallFont
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                    QQC2.Label {
                                        text: row.modelData.cpu.toFixed(1) + "%"
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                                        horizontalAlignment: Text.AlignRight
                                        color: row.modelData.cpu >= 25 ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.textColor
                                    }
                                    QQC2.Label {
                                        text: root.size(row.modelData.mem)
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                            // its processes
                            Repeater {
                                model: row.expanded ? row.modelData.procs : []
                                delegate: RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Kirigami.Units.gridUnit * 3
                                    Layout.rightMargin: Kirigami.Units.largeSpacing
                                    QQC2.Label { textFormat: Text.PlainText; text: modelData.name; opacity: 0.8; Layout.fillWidth: true; elide: Text.ElideRight }
                                    QQC2.Label { text: "PID " + modelData.pid; opacity: 0.45; font: Kirigami.Theme.smallFont }
                                    QQC2.Label {
                                        text: root.size(modelData.mem)
                                        opacity: 0.8
                                        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
