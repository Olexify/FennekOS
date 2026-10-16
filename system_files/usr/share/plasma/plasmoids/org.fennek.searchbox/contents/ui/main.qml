// Taskbar search: one search icon. Clicking it opens a large search panel: the search field on top, filter tabs
// (All / Apps / Documents / Settings / More), file filters (changed when, large files), top apps and recent
// files before you type, results grouped by kind. Results come from KDE's search runners (same as KRunner),
// including Fennek's instant file search (runner "fennek-search").
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation
    // The taskbar's own tooltip (an in-place tooltip sat under the pointer and swallowed the click).
    toolTipMainText: "Search"
    toolTipSubText: "Apps, files and settings"

    // Filter tabs: runner ids ([] = all runners).
    readonly property var tabs: [
        { name: "All", runners: [] },
        { name: "Apps", runners: ["krunner_services"] },
        { name: "Documents", runners: ["fennek-search", "krunner_recentdocuments"] },
        { name: "Settings", runners: ["krunner_systemsettings"] }
    ]
    readonly property var moreTabs: [
        { name: "Folders", runners: ["fennek-search", "krunner_placesrunner"], prefix: "type:folder " },
        { name: "Calculator", runners: ["calculator", "unitconverter"] },
        { name: "Web", runners: ["krunner_webshortcuts", "krunner_bookmarksrunner"] },
        { name: "Commands", runners: ["krunner_shell"] }
    ]
    property var tab: tabs[0]
    property string query: ""
    // File filters (Documents / Folders tabs): changed when, large files only. Understood by fennek-search.
    readonly property var whenChips: [
        { name: "Any time", filter: "" }, { name: "Today", filter: "dm:today " },
        { name: "This week", filter: "dm:week " }, { name: "This month", filter: "dm:month " }
    ]
    property string when: ""
    property bool large: false
    readonly property bool fileTab: tab.runners.indexOf("fennek-search") >= 0
    readonly property string filters: fileTab ? when + (large ? "size:>100mb " : "") : ""

    onExpandedChanged: if (!expanded) { query = ""; tab = tabs[0]; when = ""; large = false }

    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: root
        mergeResults: true
        runners: root.tab.runners
        query: root.query.length ? (root.tab.prefix || "") + root.filters + root.query : ""
    }
    Kicker.RecentUsageModel {
        id: recentModel
        shownItems: Kicker.RecentUsageModel.OnlyDocs
    }
    Kicker.RecentUsageModel {
        id: topApps
        shownItems: Kicker.RecentUsageModel.OnlyApps
    }
    readonly property var results: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
    readonly property bool searching: query.length > 0

    function launch(model, row) {
        if (model && model.trigger(row, "", null) !== false)
            root.expanded = false
        root.expanded = false
    }

    // On the taskbar: one bright search icon, the size of an app icon. Click opens the search panel.
    compactRepresentation: MouseArea {
        Layout.preferredWidth: height
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 6
            color: Kirigami.Theme.textColor
            opacity: parent.containsMouse || root.expanded ? 0.12 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.smallMedium
            height: width
            source: "search"
            color: "white"
            isMask: true
        }
    }

    // The search panel.
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 44
        Layout.preferredHeight: Kirigami.Units.gridUnit * 40
        spacing: Kirigami.Units.smallSpacing

        // Search field on top, large and calm.
        PlasmaExtras.SearchField {
            id: field
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15
            placeholderText: "Type here to search"
            text: root.query
            onTextChanged: { root.query = text; list.currentIndex = 0 }
            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onEscapePressed: root.expanded = false
            onAccepted: if (list.count > 0) root.launch(list.model, Math.max(list.currentIndex, 0))
            Connections {
                target: root
                function onExpandedChanged() { if (root.expanded) field.forceActiveFocus() }
            }
        }

        // Filter tabs.
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: root.tabs
                delegate: PlasmaComponents.TabButton {
                    text: modelData.name
                    checked: root.tab === modelData
                    onClicked: root.tab = modelData
                }
            }
            PlasmaComponents.TabButton {
                id: moreButton
                text: root.moreTabs.indexOf(root.tab) >= 0 ? root.tab.name + " ▾" : "More ▾"
                checked: root.moreTabs.indexOf(root.tab) >= 0
                onClicked: moreMenu.open()
                PlasmaExtras.ModelContextMenu {
                    id: moreMenu
                    visualParent: moreButton
                    model: root.moreTabs.map(t => ({ display: t.name }))
                    onClicked: (index) => root.tab = root.moreTabs[index]
                }
            }
            Item { Layout.fillWidth: true }
        }
        Kirigami.Separator { Layout.fillWidth: true }

        Flow {
            visible: root.fileTab
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing
            Repeater {
                model: root.whenChips
                delegate: Kirigami.Chip {
                    text: modelData.name
                    closable: false
                    checkable: false   // "checked" follows the filter (a click must not break the binding)
                    checked: root.when === modelData.filter
                    onClicked: root.when = modelData.filter
                }
            }
            Kirigami.Chip {
                text: "Large files"
                icon.name: "drive-harddisk"
                closable: false
                checkable: false   // "checked" follows the filter (a click must not break the binding)
                checked: root.large
                onClicked: root.large = !root.large
            }
        }

        // Before typing: the apps you use most, as big tiles.
        PlasmaComponents.Label {
            visible: !root.searching && topApps.count > 0
            text: "Top apps"
            font.bold: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.topMargin: Kirigami.Units.largeSpacing
        }
        RowLayout {
            visible: !root.searching && topApps.count > 0
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing
            Repeater {
                model: topApps
                delegate: PlasmaComponents.ItemDelegate {
                    visible: index < 6
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 6.6
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5.5
                    onClicked: root.launch(topApps, index)
                    contentItem: ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing
                        Kirigami.Icon {
                            source: model.decoration
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: Kirigami.Units.iconSizes.large
                            Layout.preferredHeight: Kirigami.Units.iconSizes.large
                        }
                        PlasmaComponents.Label {
                            text: model.display
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        PlasmaComponents.Label {
            visible: !root.searching
            text: "Recent"
            font.bold: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            currentIndex: 0
            model: root.searching ? root.results : recentModel
            highlight: PlasmaExtras.Highlight {}
            highlightMoveDuration: 0
            section.property: root.searching ? "group" : ""
            section.delegate: PlasmaComponents.Label {
                required property string section
                text: section
                font.bold: true
                topPadding: Kirigami.Units.largeSpacing
                leftPadding: Kirigami.Units.largeSpacing
                bottomPadding: Kirigami.Units.smallSpacing
            }
            delegate: PlasmaComponents.ItemDelegate {
                width: ListView.view.width
                onClicked: root.launch(list.model, index)
                onHoveredChanged: if (hovered) list.currentIndex = index
                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Icon {
                        source: model.decoration
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        PlasmaComponents.Label { text: model.display; elide: Text.ElideRight; Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            text: model.description || ""
                            visible: text !== ""
                            opacity: 0.7
                            font: Kirigami.Theme.smallFont
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }
                }
            }
            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.gridUnit * 4
                visible: list.count === 0
                text: root.searching ? "No results for \"" + root.query + "\"" : "Nothing opened recently"
            }
        }
    }
}
