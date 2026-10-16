// Classic taskbar search: a "Type here to search" box. Clicking it opens a search panel above the taskbar with
// filter tabs (All / Apps / Documents / Settings / More), recent items before you type, results grouped by
// kind, and the search field at the bottom. Results come from KDE's search runners (same as KRunner),
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

    onExpandedChanged: if (!expanded) { query = ""; tab = tabs[0] }

    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: root
        mergeResults: true
        runners: root.tab.runners
        query: root.query.length ? (root.tab.prefix || "") + root.query : ""
    }
    Kicker.RecentUsageModel {
        id: recentModel
        shownItems: Kicker.RecentUsageModel.AppsAndDocs
    }
    readonly property var results: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null
    readonly property bool searching: query.length > 0

    function launch(model, row) {
        if (model && model.trigger(row, "", null) !== false)
            root.expanded = false
        root.expanded = false
    }

    // The box on the taskbar.
    compactRepresentation: MouseArea {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 17
        Layout.fillHeight: true
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            color: parent.containsMouse || root.expanded ? Qt.lighter(Kirigami.Theme.backgroundColor, 1.6)
                                                         : Qt.lighter(Kirigami.Theme.backgroundColor, 1.35)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            radius: 2
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon {
                source: "search"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            PlasmaComponents.Label {
                text: "Type here to search"
                opacity: 0.75
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    // The search panel.
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 34
        Layout.preferredHeight: Kirigami.Units.gridUnit * 34
        spacing: Kirigami.Units.smallSpacing

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

        // Search field at the bottom, like the classic search.
        PlasmaExtras.SearchField {
            id: field
            Layout.fillWidth: true
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
    }
}
