// Fennek Task Manager (Ctrl+Shift+Esc), with the classic tabs:
//   Processes    what runs, grouped the way people think about it (Apps, Background services, Desktop, System
//                services), each row opening to show its processes; End task for your apps and background services,
//                End for one process of yours
//   Performance  processor, memory, disk and network: live graphs and the numbers behind them
//   App history  which apps used the processor (and so the battery) and memory lately (the App history page)
//   Startup      the apps that start when you sign in (KDE's Autostart page)
//   Users        who is signed in, and what their processes use
//   Details      every process: PID, status, user, processor, memory, command; End process for yours
//   Services     every service of the computer and of your account: start, stop, restart (the computer's ask
//                for an administrator)
// Data: /usr/libexec/fennek-tasks. Each tab refreshes only while it is shown.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import Fennek

QQC2.ApplicationWindow {
    id: root
    visible: true
    title: "Task Manager"
    width: Kirigami.Units.gridUnit * 52
    height: Kirigami.Units.gridUnit * 36
    minimumWidth: Kirigami.Units.gridUnit * 36
    minimumHeight: Kirigami.Units.gridUnit * 22

    readonly property string helper: "/usr/libexec/fennek-tasks"
    readonly property int tab: tabs.currentIndex
    property var data: ({ groups: [], mem_total: 0, mem_used: 0 })
    property var procs: []          // Details
    property var people: []         // Users
    property var units: []          // Services
    property var open: ({})         // unit -> true: Processes rows showing their processes
    property string selected: ""    // Processes: a unit that can end
    property int selectedPid: 0     // Details
    property var selectedService: null
    property string filter: ""
    property string message: ""
    property string sortKey: "cpu"
    property bool sortDown: true

    // Performance: the last minute, one point a second
    property var perfPrev: null
    property var perfNow: ({ cores: 0, cpu_name: "", mem_total: 0, mem_used: 0, mem_cached: 0, swap_total: 0, swap_used: 0,
                             procs: 0, threads: 0, uptime: 0 })
    property real cpuPct: 0
    property real diskRate: 0
    property real diskRead: 0
    property real diskWrite: 0
    property real netRate: 0
    property real netIn: 0
    property real netOut: 0
    property var cpuHist: []
    property var memHist: []
    property var diskHist: []
    property var netHist: []
    property int perfView: 0        // 0 processor, 1 memory, 2 disk, 3 network

    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function size(b) {
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576) return (b / 1048576).toFixed(b >= 104857600 ? 0 : 1) + " MB"
        return Math.round(b / 1024) + " KB"
    }
    function rate(b) { return b < 1024 ? Math.round(b) + " B/s" : size(b) + "/s" }
    function upTime(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d ? d + " d " : "") + h + " h " + m + " min"
    }
    function push(list, v) { const l = list.concat([v]); return l.length > 60 ? l.slice(l.length - 60) : l }
    function matches(text) { return root.filter === "" || String(text).toLowerCase().indexOf(root.filter.toLowerCase()) >= 0 }
    function shown(items) {
        return items.filter(i => matches(i.name + " " + i.desc + " " + i.procs.map(p => p.name).join(" ")))
    }
    function sortedProcs() {
        const k = sortKey, dir = sortDown ? -1 : 1
        return procs.filter(p => matches(p.name + " " + p.cmd + " " + p.pid + " " + p.user)).sort((a, b) => {
            const x = a[k], y = b[k]
            return (typeof x === "string" ? x.localeCompare(y) : x - y) * dir
        })
    }
    function shownUnits() {
        const order = { active: 0, activating: 1, deactivating: 1, failed: 2, inactive: 3 }
        return units.filter(u => matches(u.desc + " " + u.unit)).sort((a, b) =>
            (order[a.active] ?? 4) - (order[b.active] ?? 4) || a.desc.localeCompare(b.desc))
    }
    function stateText(u) {
        return u.active === "active" ? (u.sub === "running" ? "Running" : "Done") : u.active === "failed" ? "Failed"
             : u.active === "activating" ? "Starting" : u.active === "deactivating" ? "Stopping" : "Stopped"
    }
    function ask(what) { if (!run.busy[what]) { const b = Object.assign({}, run.busy); b[what] = true; run.busy = b; run.connectSource(helper + " " + what) } }
    function refresh() {
        if (tab === 0) ask("list")
        else if (tab === 4) ask("users")
        else if (tab === 5) ask("details")
        else if (tab === 6) ask("services")
    }
    function act(args) { root.message = ""; run.connectSource(helper + " " + args) }

    P5Support.DataSource {
        id: run
        property var busy: ({})
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source)
            const what = source.slice(root.helper.length + 1)
            if (what in busy) { const b = Object.assign({}, busy); delete b[what]; busy = b }
            let d = null
            try { d = JSON.parse(data.stdout) } catch (e) {}
            if (what === "list") { if (d) root.data = d }
            else if (what === "details") { if (d) root.procs = d }
            else if (what === "users") { if (d) root.people = d }
            else if (what === "services") { if (d) root.units = d }
            else if (what === "perf") { if (d) root.takePerf(d) }
            else {   // an action: say what went wrong, show what is now
                root.message = data["exit code"] === 0 ? "" : ((data.stderr || "").trim().split("\n").pop() || "That didn't work.")
                root.refresh()
            }
        }
    }
    function takePerf(d) {
        const p = perfPrev
        perfNow = d
        if (p) {
            const dt = Math.max(1, d.cpu[0] - p.cpu[0])
            cpuPct = Math.max(0, Math.min(100, 100 * (1 - (d.cpu[1] - p.cpu[1]) / dt)))
            const secs = perfTimer.interval / 1000
            diskRead = Math.max(0, (d.disk[0] - p.disk[0]) / secs); diskWrite = Math.max(0, (d.disk[1] - p.disk[1]) / secs)
            netIn = Math.max(0, (d.net[0] - p.net[0]) / secs); netOut = Math.max(0, (d.net[1] - p.net[1]) / secs)
            diskRate = diskRead + diskWrite; netRate = netIn + netOut
            cpuHist = push(cpuHist, cpuPct)
            memHist = push(memHist, d.mem_total ? 100 * d.mem_used / d.mem_total : 0)
            diskHist = push(diskHist, diskRate)
            netHist = push(netHist, netRate)
        }
        perfPrev = d
    }
    // The graphs keep going while the window is open (one quick read a second; two while on another tab)
    Timer { id: perfTimer; interval: root.tab === 1 ? 1000 : 2000; running: root.visible; repeat: true; triggeredOnStart: true
            onTriggered: root.ask("perf") }
    Timer { interval: root.tab === 6 || root.tab === 4 ? 5000 : 2000; running: root.visible; repeat: true; triggeredOnStart: true
            onTriggered: root.refresh() }
    property var seen: [0]          // tabs shown so far (their pages are loaded then)
    // fennek-app taskmanager performance|app-history|startup|users|details|services: opens on that tab
    Component.onCompleted: {
        const i = ["processes", "performance", "app-history", "startup", "users", "details", "services"].indexOf(Qt.application.arguments[2] || "")
        if (i > 0) tabs.currentIndex = i
    }
    onTabChanged: { message = ""; if (seen.indexOf(tab) < 0) seen = seen.concat([tab]); refresh() }

    header: QQC2.ToolBar {
        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing
            QQC2.TabBar {
                id: tabs
                Layout.fillWidth: true
                Repeater {
                    model: ["Processes", "Performance", "App history", "Startup", "Users", "Details", "Services"]
                    QQC2.TabButton { required property string modelData; text: modelData; width: implicitWidth }
                }
            }
            Kirigami.SearchField {
                visible: root.tab === 0 || root.tab === 5 || root.tab === 6
                Layout.preferredWidth: Kirigami.Units.gridUnit * 11
                placeholderText: root.tab === 6 ? "Find a service" : "Find an app or process"
                onTextChanged: root.filter = text
            }
        }
    }

    footer: QQC2.ToolBar {
        visible: root.tab === 0 || root.tab === 5 || root.tab === 6
        RowLayout {
            anchors.fill: parent
            QQC2.Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: root.message !== "" ? root.message
                    : root.tab === 0 ? "Click a row to see what's inside it."
                    : root.tab === 5 ? root.procs.length + " processes"
                    : "The computer's services ask for an administrator's password to start or stop."
                opacity: root.message !== "" ? 1 : 0.6
                color: root.message !== "" ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
            }
            QQC2.Button {
                visible: root.tab === 0
                text: "End task"
                icon.name: "process-stop"
                enabled: root.selected !== ""
                onClicked: { root.act("end " + root.q(root.selected)); root.selected = "" }
            }
            QQC2.Button {
                visible: root.tab === 5
                text: "End process"
                icon.name: "process-stop"
                enabled: root.selectedPid > 0 && !!root.procs.find(p => p.pid === root.selectedPid && p.own)
                onClicked: { root.act("kill " + root.selectedPid); root.selectedPid = 0 }
            }
            Repeater {
                model: root.tab === 6 ? [["start", "Start", "media-playback-start"], ["stop", "Stop", "media-playback-stop"],
                                         ["restart", "Restart", "view-refresh"]] : []
                QQC2.Button {
                    required property var modelData
                    text: modelData[1]
                    icon.name: modelData[2]
                    enabled: !!root.selectedService && (modelData[0] === "start" ? root.selectedService.active !== "active"
                                                                                  : root.selectedService.active === "active")
                    onClicked: root.act("service " + modelData[0] + " " + root.selectedService.scope + " " + root.q(root.selectedService.unit))
                }
            }
        }
    }

    // A column title that sorts (Details)
    component SortTitle: QQC2.ToolButton {
        property string key
        property string label
        text: label + (root.sortKey === key ? (root.sortDown ? " ▾" : " ▴") : "")
        flat: true
        onClicked: { if (root.sortKey === key) root.sortDown = !root.sortDown; else { root.sortKey = key; root.sortDown = key === "cpu" || key === "mem" } }
    }
    // A line graph of the last minute
    component Graph: Canvas {
        property var values: []
        property real ceiling: 100      // 0: scale to the highest value
        property color lineColor: Kirigami.Theme.highlightColor
        onValuesChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"), w = width, h = height
            c.reset()
            c.strokeStyle = Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.25); c.lineWidth = 1
            for (let i = 1; i < 4; i++) { c.beginPath(); c.moveTo(0, h * i / 4); c.lineTo(w, h * i / 4); c.stroke() }
            if (values.length < 2) return
            const max = ceiling > 0 ? ceiling : Math.max(1024, ...values) * 1.2
            const x = i => w - (values.length - 1 - i) * w / 59, y = v => h - Math.min(1, v / max) * (h - 2) - 1
            c.beginPath(); c.moveTo(x(0), h)
            for (let i = 0; i < values.length; i++) c.lineTo(x(i), y(values[i]))
            c.lineTo(x(values.length - 1), h); c.closePath()
            c.fillStyle = Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.18); c.fill()
            c.beginPath()
            for (let i = 0; i < values.length; i++) i ? c.lineTo(x(i), y(values[i])) : c.moveTo(x(i), y(values[i]))
            c.strokeStyle = lineColor; c.lineWidth = 1.6; c.stroke()
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: root.tab

        // ---- Processes ----
        QQC2.ScrollView {
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.largeSpacing
                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                    QQC2.Label { text: "Name"; opacity: 0.6; Layout.fillWidth: true }
                    // like the classic columns: the computer's total above its name
                    QQC2.Label { text: Math.round(root.cpuPct) + "%\nProcessor"; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
                    QQC2.Label { text: Math.round(root.perfNow.mem_total ? 100 * root.perfNow.mem_used / root.perfNow.mem_total : 0) + "%\nMemory"; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
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
                                    highlighted: root.selected !== "" && root.selected === row.modelData.unit
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
                                // its processes; yours can be ended one by one
                                Repeater {
                                    model: row.expanded ? row.modelData.procs : []
                                    delegate: RowLayout {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.leftMargin: Kirigami.Units.gridUnit * 3
                                        Layout.rightMargin: Kirigami.Units.largeSpacing
                                        QQC2.Label { textFormat: Text.PlainText; text: modelData.name; opacity: 0.8; Layout.fillWidth: true; elide: Text.ElideRight }
                                        QQC2.Label { text: "PID " + modelData.pid; opacity: 0.45; font: Kirigami.Theme.smallFont }
                                        QQC2.ToolButton {
                                            visible: !!modelData.own
                                            text: "End"
                                            icon.name: "process-stop"
                                            display: QQC2.AbstractButton.TextBesideIcon
                                            onClicked: root.act("kill " + modelData.pid)
                                            QQC2.ToolTip.visible: hovered
                                            QQC2.ToolTip.text: "End just this process"
                                        }
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

        // ---- Performance ----
        RowLayout {
            spacing: 0
            // the four, each with its little graph
            ColumnLayout {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 13
                Layout.fillHeight: true
                Layout.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: [["Processor", root.cpuHist, 100, Math.round(root.cpuPct) + "%"],
                            ["Memory", root.memHist, 100, root.size(root.perfNow.mem_used) + " of " + root.size(root.perfNow.mem_total)],
                            ["Disk", root.diskHist, 0, root.rate(root.diskRate)],
                            ["Network", root.netHist, 0, root.rate(root.netRate)]]
                    QQC2.ItemDelegate {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        highlighted: root.perfView === index
                        onClicked: root.perfView = index
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing
                            Rectangle {
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.4
                                color: "transparent"
                                border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5)
                                Graph { anchors.fill: parent; anchors.margins: 1; values: modelData[1]; ceiling: modelData[2] }
                            }
                            ColumnLayout {
                                spacing: 0
                                QQC2.Label { text: modelData[0]; font.weight: Font.DemiBold }
                                QQC2.Label { text: modelData[3]; opacity: 0.7; font: Kirigami.Theme.smallFont }
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                QQC2.Button {
                    text: "More detail…"
                    icon.name: "utilities-system-monitor"
                    flat: true
                    onClicked: run.connectSource("setsid -f plasma-systemmonitor --page-name overview")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: "KDE's System Monitor: per-core graphs, sensors, history"
                }
            }
            Kirigami.Separator { Layout.fillHeight: true }
            // the one picked, big, with its numbers
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Kirigami.Units.largeSpacing * 2
                spacing: Kirigami.Units.largeSpacing
                RowLayout {
                    Kirigami.Heading { level: 1; text: ["Processor", "Memory", "Disk", "Network"][root.perfView] }
                    Item { Layout.fillWidth: true }
                    QQC2.Label {
                        opacity: 0.7
                        elide: Text.ElideRight
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
                        text: root.perfView === 0 ? root.perfNow.cpu_name
                            : root.perfView === 1 ? root.size(root.perfNow.mem_total) + " in all" : ""
                    }
                }
                QQC2.Label {
                    opacity: 0.6
                    font: Kirigami.Theme.smallFont
                    text: ["% used, the last 60 seconds", "% in use, the last 60 seconds", "Read and write speed, the last 60 seconds",
                           "Send and receive speed, the last 60 seconds"][root.perfView]
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5)
                    Graph {
                        anchors.fill: parent
                        anchors.margins: 1
                        values: [root.cpuHist, root.memHist, root.diskHist, root.netHist][root.perfView]
                        ceiling: root.perfView < 2 ? 100 : 0
                    }
                }
                GridLayout {
                    columns: 4
                    columnSpacing: Kirigami.Units.gridUnit * 2
                    rowSpacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: root.perfView === 0 ? [["Utilisation", Math.round(root.cpuPct) + "%"], ["Cores", root.perfNow.cores],
                                                      ["Processes", root.perfNow.procs], ["Threads", root.perfNow.threads],
                                                      ["Up time", root.upTime(root.perfNow.uptime)]]
                             : root.perfView === 1 ? [["In use", root.size(root.perfNow.mem_used)],
                                                      ["Available", root.size(root.perfNow.mem_total - root.perfNow.mem_used)],
                                                      ["Cached", root.size(root.perfNow.mem_cached)],
                                                      ["Swap in use", root.size(root.perfNow.swap_used) + " of " + root.size(root.perfNow.swap_total)]]
                             : root.perfView === 2 ? [["Read", root.rate(root.diskRead)], ["Write", root.rate(root.diskWrite)]]
                             : [["Receive", root.rate(root.netIn)], ["Send", root.rate(root.netOut)]]
                        ColumnLayout {
                            required property var modelData
                            spacing: 0
                            QQC2.Label { text: modelData[0]; opacity: 0.6; font: Kirigami.Theme.smallFont }
                            QQC2.Label { text: String(modelData[1]); font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.3 }
                        }
                    }
                }
            }
        }

        // ---- App history ----
        Loader { active: root.seen.indexOf(2) >= 0; source: "file:///usr/share/fennek/apps/apphistory/Page.qml" }

        // ---- Startup ----
        Loader {
            active: root.seen.indexOf(3) >= 0   // loaded when first shown
            sourceComponent: KcmView { kcm: "kcm_autostart" }
        }

        // ---- Users ----
        QQC2.ScrollView {
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.largeSpacing
                    QQC2.Label { text: "Signed in"; opacity: 0.6; Layout.fillWidth: true }
                    QQC2.Label { text: "Processes"; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
                    QQC2.Label { text: "Processor"; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
                    QQC2.Label { text: "Memory"; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
                }
                Repeater {
                    model: root.people
                    QQC2.ItemDelegate {
                        required property var modelData
                        Layout.fillWidth: true
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing
                            Kirigami.Icon { source: "user-identity"; Layout.preferredWidth: Kirigami.Units.iconSizes.medium; Layout.preferredHeight: Kirigami.Units.iconSizes.medium }
                            QQC2.Label { textFormat: Text.PlainText; text: modelData.name + (modelData.you ? " (you)" : ""); Layout.fillWidth: true; elide: Text.ElideRight }
                            QQC2.Label { text: modelData.procs; Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
                            QQC2.Label { text: modelData.cpu.toFixed(1) + "%"; Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
                            QQC2.Label { text: root.size(modelData.mem); Layout.preferredWidth: Kirigami.Units.gridUnit * 5; horizontalAlignment: Text.AlignRight }
                        }
                    }
                }
            }
        }

        // ---- Details ----
        ColumnLayout {
            spacing: 0
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.largeSpacing * 2
                spacing: 0
                SortTitle { key: "name"; label: "Name"; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
                SortTitle { key: "pid"; label: "PID"; Layout.preferredWidth: Kirigami.Units.gridUnit * 4 }
                SortTitle { key: "status"; label: "Status"; Layout.preferredWidth: Kirigami.Units.gridUnit * 5 }
                SortTitle { key: "user"; label: "User"; Layout.preferredWidth: Kirigami.Units.gridUnit * 6 }
                SortTitle { key: "cpu"; label: "Processor"; Layout.preferredWidth: Kirigami.Units.gridUnit * 5 }
                SortTitle { key: "mem"; label: "Memory"; Layout.preferredWidth: Kirigami.Units.gridUnit * 5 }
                SortTitle { key: "cmd"; label: "Command"; Layout.fillWidth: true }
            }
            Kirigami.Separator { Layout.fillWidth: true }
            ListView {
                id: detailList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.tab === 5 ? root.sortedProcs() : []
                reuseItems: true
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
                delegate: QQC2.ItemDelegate {
                    required property var modelData
                    width: ListView.view.width
                    highlighted: root.selectedPid === modelData.pid
                    onClicked: root.selectedPid = modelData.pid
                    contentItem: RowLayout {
                        spacing: 0
                        QQC2.Label { textFormat: Text.PlainText; text: modelData.name; elide: Text.ElideRight; Layout.preferredWidth: Kirigami.Units.gridUnit * 10 }
                        QQC2.Label { text: modelData.pid; Layout.preferredWidth: Kirigami.Units.gridUnit * 4 }
                        QQC2.Label { text: modelData.status; Layout.preferredWidth: Kirigami.Units.gridUnit * 5 }
                        QQC2.Label { textFormat: Text.PlainText; text: modelData.user; elide: Text.ElideRight; Layout.preferredWidth: Kirigami.Units.gridUnit * 6 }
                        QQC2.Label { text: modelData.cpu.toFixed(1) + "%"; Layout.preferredWidth: Kirigami.Units.gridUnit * 5 }
                        QQC2.Label { text: root.size(modelData.mem); Layout.preferredWidth: Kirigami.Units.gridUnit * 5 }
                        QQC2.Label { textFormat: Text.PlainText; text: modelData.cmd; elide: Text.ElideRight; opacity: 0.6; Layout.fillWidth: true }
                    }
                }
            }
        }

        // ---- Services ----
        ColumnLayout {
            spacing: 0
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                QQC2.Label { text: "Service"; opacity: 0.6; Layout.fillWidth: true }
                QQC2.Label { text: "For"; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 7 }
                QQC2.Label { text: "Status"; opacity: 0.6; Layout.preferredWidth: Kirigami.Units.gridUnit * 5 }
            }
            Kirigami.Separator { Layout.fillWidth: true }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.tab === 6 ? root.shownUnits() : []
                reuseItems: true
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
                delegate: QQC2.ItemDelegate {
                    required property var modelData
                    width: ListView.view.width
                    highlighted: !!root.selectedService && root.selectedService.unit === modelData.unit && root.selectedService.scope === modelData.scope
                    onClicked: root.selectedService = modelData
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            QQC2.Label { textFormat: Text.PlainText; text: modelData.desc || modelData.unit; elide: Text.ElideRight; Layout.fillWidth: true }
                            QQC2.Label { textFormat: Text.PlainText; text: modelData.unit; opacity: 0.5; font: Kirigami.Theme.smallFont; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        QQC2.Label { text: modelData.scope === "user" ? "Your account" : "The computer"; opacity: 0.7; Layout.preferredWidth: Kirigami.Units.gridUnit * 7 }
                        QQC2.Label {
                            text: root.stateText(modelData)
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                            color: modelData.active === "failed" ? Kirigami.Theme.negativeTextColor
                                 : modelData.active === "active" ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                        }
                    }
                }
            }
        }
    }
}
