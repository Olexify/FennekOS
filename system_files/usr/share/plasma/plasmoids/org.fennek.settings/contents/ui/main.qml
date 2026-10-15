// Fennek Settings: a classic Settings home. "Find a setting" search and a grid of categories; each category
// lists its settings, each setting opens the matching KDE settings page (so everything stays in sync).
// Runs as a normal window: plasmawindowed org.fennek.settings (see fennek-settings.desktop).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "catalog.js" as Catalog

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation

    property var category: null          // open category, or null for the home grid
    property string query: ""

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }
    function open(item) {
        run.connectSource(item.kcm ? "systemsettings " + item.kcm : item.cmd)
    }
    function matches() {
        const q = query.toLowerCase().trim()
        const out = []
        for (const c of Catalog.categories)
            for (const i of c.items)
                if ((i.name + " " + i.desc + " " + c.name).toLowerCase().includes(q)) out.push(i)
        return out
    }

    fullRepresentation: QQC2.Page {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 56
        Layout.preferredHeight: Kirigami.Units.gridUnit * 38

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit * 2
            spacing: Kirigami.Units.largeSpacing * 2

            RowLayout {
                QQC2.ToolButton {
                    visible: root.category !== null || root.query !== ""
                    icon.name: "go-previous"
                    onClicked: { root.category = null; search.text = "" }
                }
                Kirigami.Heading {
                    text: root.category ? root.category.name : "Settings"
                    level: 1
                    Layout.fillWidth: true
                }
            }

            Kirigami.SearchField {
                id: search
                placeholderText: "Find a setting"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 22
                Layout.alignment: Qt.AlignHCenter
                onTextChanged: root.query = text
            }

            // Home: grid of categories
            GridLayout {
                visible: root.category === null && root.query === ""
                columns: 4
                columnSpacing: Kirigami.Units.gridUnit
                rowSpacing: Kirigami.Units.gridUnit
                Layout.fillWidth: true
                Repeater {
                    model: Catalog.categories
                    delegate: QQC2.ItemDelegate {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                        onClicked: root.category = modelData
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing
                            Kirigami.Icon {
                                source: modelData.icon
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Layout.preferredWidth
                                Layout.alignment: Qt.AlignTop
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                QQC2.Label { text: modelData.name; font.bold: true; Layout.fillWidth: true; wrapMode: Text.Wrap }
                                QQC2.Label { text: modelData.sub; opacity: 0.7; Layout.fillWidth: true; wrapMode: Text.Wrap }
                            }
                        }
                    }
                }
            }

            // A category's settings, or search results
            ListView {
                visible: root.category !== null || root.query !== ""
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.query !== "" ? root.matches() : (root.category ? root.category.items : [])
                delegate: QQC2.ItemDelegate {
                    width: ListView.view.width
                    onClicked: root.open(modelData)
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            source: modelData.icon
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Layout.preferredWidth
                        }
                        ColumnLayout {
                            spacing: 2
                            QQC2.Label { text: modelData.name; font.bold: true }
                            QQC2.Label { text: modelData.desc; opacity: 0.7 }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: root.category === null && root.query === "" }

            QQC2.Button {
                text: "All settings (advanced)"
                icon.name: "preferences-system"
                flat: true
                Layout.alignment: Qt.AlignRight
                onClicked: run.connectSource("systemsettings")
            }
        }
    }
}
