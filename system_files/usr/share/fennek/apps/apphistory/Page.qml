// Fennek App history: which apps used the processor (and so the battery) and how much memory, over the last
// hour / 8 hours / day / week. Data from fennek-usage (sampled once a minute, kept 7 days, never leaves the PC).
// Runs as fennek-app apphistory (see fennek-apphistory.desktop).
// The page itself, shown inside Settings (fennek-app apphistory opens Settings on it).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Item {
    id: root
    property int hours: 8
    property var rows: []
    readonly property real total: rows.reduce((s, r) => s + r.cpu_ms, 0) || 1

    function load() { run.connectSource("fennek-usage --json " + hours) }
    onHoursChanged: load()
    Component.onCompleted: load()

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            try { root.rows = JSON.parse(data.stdout) } catch (e) { root.rows = [] }
            disconnectSource(source)
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.load() }

    function nice(name) {   // org.kde.dolphin -> Dolphin, org.mozilla.firefox -> Firefox
        const last = name.split(".").pop()
        return last.charAt(0).toUpperCase() + last.slice(1)
    }
    function duration(ms) {
        const s = Math.round(ms / 1000)
        return s < 60 ? s + " s" : s < 3600 ? Math.round(s / 60) + " min" : (s / 3600).toFixed(1) + " h"
    }

    QQC2.Page {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit * 1.5
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Kirigami.Heading { text: "App history"; level: 1; Layout.fillWidth: true }
                Repeater {
                    model: [[1, "1 hour"], [8, "8 hours"], [24, "24 hours"], [168, "7 days"]]
                    QQC2.Button {
                        text: modelData[1]
                        checkable: true
                        checked: root.hours === modelData[0]
                        onClicked: root.hours = modelData[0]
                    }
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                opacity: 0.7
                text: "Processor time is what uses the battery most. Recorded once a minute on this computer only."
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: root.rows
                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: Kirigami.Units.gridUnit * 2.6
                    radius: 8
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        anchors.rightMargin: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            source: modelData.app
                            fallback: "application-x-executable"
                            Layout.preferredWidth: 24; Layout.preferredHeight: 24
                        }
                        QQC2.Label { text: root.nice(modelData.app); Layout.preferredWidth: Kirigami.Units.gridUnit * 10; elide: Text.ElideRight }
                        Rectangle {   // share of processor time
                            Layout.fillWidth: true
                            height: 6; radius: 3
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                            Rectangle {
                                width: parent.width * modelData.cpu_ms / root.total
                                height: parent.height; radius: 3
                                color: Kirigami.Theme.highlightColor
                            }
                        }
                        QQC2.Label { text: root.duration(modelData.cpu_ms); Layout.preferredWidth: Kirigami.Units.gridUnit * 4; horizontalAlignment: Text.AlignRight }
                        QQC2.Label {
                            text: Math.round(modelData.mem / 1048576) + " MB"
                            opacity: 0.7
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
                QQC2.Label {
                    anchors.centerIn: parent
                    visible: root.rows.length === 0
                    opacity: 0.7
                    text: "Nothing recorded yet. Check back in a few minutes."
                }
            }
        }
    }
}
