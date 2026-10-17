// Fennek clock: time with the date underneath on the taskbar. Click: a calm calendar panel with a big clock
// (with seconds), today's date in the accent colour and a month grid. Everything in the user's language.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    property date now: new Date()
    property date shown: new Date(now.getFullYear(), now.getMonth(), 1)   // month on display
    readonly property var locale: Qt.locale()

    Timer {
        // Seconds only while the panel is open; once a minute otherwise (battery).
        interval: root.expanded ? 1000 : (60 - root.now.getSeconds()) * 1000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
    onExpandedChanged: if (expanded) { now = new Date(); shown = new Date(now.getFullYear(), now.getMonth(), 1) }

    P5Support.DataSource { id: run; engine: "executable"; onNewData: source => disconnectSource(source) }

    toolTipMainText: now.toLocaleDateString(locale, Locale.LongFormat)
    toolTipSubText: ""

    compactRepresentation: MouseArea {
        Layout.minimumWidth: col.implicitWidth + Kirigami.Units.largeSpacing * 2
        onClicked: root.expanded = !root.expanded
        hoverEnabled: true
        Rectangle { anchors.fill: parent; color: Kirigami.Theme.textColor; opacity: parent.containsMouse ? 0.08 : 0; radius: 4 }
        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 0
            PC3.Label { Layout.alignment: Qt.AlignHCenter; text: root.now.toLocaleTimeString(root.locale, Locale.ShortFormat) }
            // The locale's short date, always with the full year (16.10.2026, not 16.10.26).
            PC3.Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.now.toLocaleDateString(root.locale, root.locale.dateFormat(Locale.ShortFormat).replace(/y+/, "yyyy"))
                font: Kirigami.Theme.smallFont
            }
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: implicitHeight
        spacing: Kirigami.Units.smallSpacing

        PC3.Label {
            Layout.leftMargin: Kirigami.Units.largeSpacing
            text: root.now.toLocaleTimeString(root.locale, "HH:mm:ss")
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 3.6
            font.weight: Font.Light
        }
        PC3.Label {
            Layout.leftMargin: Kirigami.Units.largeSpacing
            text: root.now.toLocaleDateString(root.locale, Locale.LongFormat)
            color: Kirigami.Theme.highlightColor
        }
        Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.largeSpacing }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            PC3.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                // Standalone month name ("Жовтень 2026", not "жовтня"), first letter capitalised.
                text: { const m = root.locale.standaloneMonthName(root.shown.getMonth(), Locale.LongFormat); return m.charAt(0).toUpperCase() + m.slice(1) + " " + root.shown.getFullYear() }
                font.weight: Font.DemiBold
            }
            PC3.ToolButton { icon.name: "go-up"; icon.color: Kirigami.Theme.textColor; onClicked: root.shown = new Date(root.shown.getFullYear(), root.shown.getMonth() - 1, 1) }
            PC3.ToolButton { icon.name: "go-down"; icon.color: Kirigami.Theme.textColor; onClicked: root.shown = new Date(root.shown.getFullYear(), root.shown.getMonth() + 1, 1) }
        }

        GridLayout {
            id: grid
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            columns: 7
            rowSpacing: 2; columnSpacing: 2
            readonly property int firstDay: root.locale.firstDayOfWeek   // 0 = Sunday … 6
            // Weekday names, starting with the locale's first day of the week.
            Repeater {
                model: 7
                PC3.Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2   // equal columns
                    horizontalAlignment: Text.AlignHCenter
                    text: root.locale.dayName((grid.firstDay + index) % 7, Locale.ShortFormat)
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                }
            }
            // 6 weeks of days; the previous / next month's days are dimmed.
            Repeater {
                model: 42
                delegate: Item {
                    readonly property int lead: (root.shown.getDay() - grid.firstDay + 7) % 7
                    readonly property date day: new Date(root.shown.getFullYear(), root.shown.getMonth(), 1 - lead + index)
                    readonly property bool inMonth: day.getMonth() === root.shown.getMonth()
                    readonly property bool today: day.toDateString() === root.now.toDateString()
                    Layout.fillWidth: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2   // equal columns
                    implicitHeight: Kirigami.Units.gridUnit * 2
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height); height: width
                        radius: width / 2
                        color: Kirigami.Theme.highlightColor
                        visible: today
                    }
                    PC3.Label {
                        anchors.centerIn: parent
                        text: day.getDate()
                        opacity: inMonth ? 1 : 0.35
                        color: today ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        font.weight: today ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }

        PC3.ToolButton {
            Layout.margins: Kirigami.Units.smallSpacing
            text: "Date and time settings"
            icon.name: "preferences-system-time"
            onClicked: { run.connectSource("systemsettings kcm_clock"); root.expanded = false }
        }
    }
}
