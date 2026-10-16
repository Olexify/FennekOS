// Fennek Settings: a sidebar ("Find a setting" + categories with their icons) and, on the right, the chosen
// category's settings as rounded cards. Home shows the categories as large cards. Each setting opens the
// matching KDE settings page (so everything stays in sync) or runs a tool.
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

    property var category: null          // open category, or null for Home
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
    readonly property color cardColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
    readonly property color cardHover: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10)

    // One setting as a rounded card: icon, title, description, chevron.
    component SettingCard: QQC2.ItemDelegate {
        id: card
        required property var item
        Layout.fillWidth: true
        implicitHeight: Kirigami.Units.gridUnit * 3.6
        onClicked: root.open(item)
        background: Rectangle { radius: 10; color: card.hovered ? root.cardHover : root.cardColor }
        contentItem: RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon {
                source: card.item.icon
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Layout.preferredWidth
                Layout.leftMargin: Kirigami.Units.smallSpacing
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                QQC2.Label { text: card.item.name; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                QQC2.Label { text: card.item.desc; opacity: 0.7; Layout.fillWidth: true; elide: Text.ElideRight }
            }
            Kirigami.Icon { source: "go-next-symbolic"; Layout.preferredWidth: 16; Layout.preferredHeight: 16; opacity: 0.5 }
        }
    }

    fullRepresentation: QQC2.Page {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 60
        Layout.preferredHeight: Kirigami.Units.gridUnit * 38

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ---- Sidebar ----
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 17
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03)
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing * 2
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.ItemDelegate {   // Home: "Settings" title
                        Layout.fillWidth: true
                        onClicked: { root.category = null; search.text = "" }
                        background: Rectangle { radius: 8; color: parent.hovered ? root.cardHover : "transparent" }
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing
                            Kirigami.Icon { source: "fennek-settings"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
                            Kirigami.Heading { text: "Settings"; level: 2 }
                        }
                    }
                    Kirigami.SearchField {
                        id: search
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.largeSpacing
                        Layout.bottomMargin: Kirigami.Units.largeSpacing
                        placeholderText: "Find a setting"
                        onTextChanged: root.query = text
                    }
                    Repeater {
                        model: Catalog.categories
                        delegate: QQC2.ItemDelegate {
                            required property var modelData
                            readonly property bool current: root.category === modelData && root.query === ""
                            Layout.fillWidth: true
                            onClicked: { root.category = modelData; search.text = "" }
                            background: Rectangle {
                                radius: 8
                                color: parent.current ? root.cardHover : parent.hovered ? root.cardColor : "transparent"
                                Rectangle {   // accent marker for the open category
                                    visible: parent.parent.current
                                    width: 3; radius: 2
                                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 8; bottomMargin: 8 }
                                    color: Kirigami.Theme.highlightColor
                                }
                            }
                            contentItem: RowLayout {
                                spacing: Kirigami.Units.largeSpacing
                                Kirigami.Icon { source: modelData.icon; Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
                                QQC2.Label { text: modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                    QQC2.ItemDelegate {
                        Layout.fillWidth: true
                        text: "All settings (advanced)"
                        icon.name: "preferences-system"
                        onClicked: run.connectSource("systemsettings")
                        background: Rectangle { radius: 8; color: parent.hovered ? root.cardColor : "transparent" }
                    }
                }
            }

            // ---- Content ----
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Heading {
                        Layout.topMargin: Kirigami.Units.gridUnit * 1.5
                        Layout.leftMargin: Kirigami.Units.gridUnit * 2
                        text: root.query !== "" ? "Results" : root.category ? root.category.name : "Home"
                        level: 1
                    }

                    // Home: categories as large cards.
                    GridLayout {
                        visible: root.category === null && root.query === ""
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit * 2
                        Layout.rightMargin: Kirigami.Units.gridUnit * 2
                        columns: 2
                        columnSpacing: Kirigami.Units.largeSpacing
                        rowSpacing: Kirigami.Units.largeSpacing
                        Repeater {
                            model: Catalog.categories
                            delegate: QQC2.ItemDelegate {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: Kirigami.Units.gridUnit * 4.5
                                onClicked: root.category = modelData
                                background: Rectangle { radius: 12; color: parent.hovered ? root.cardHover : root.cardColor }
                                contentItem: RowLayout {
                                    spacing: Kirigami.Units.largeSpacing
                                    Kirigami.Icon { source: modelData.icon; Layout.preferredWidth: 44; Layout.preferredHeight: 44; Layout.leftMargin: 4 }
                                    ColumnLayout {
                                        spacing: 2
                                        Layout.fillWidth: true
                                        QQC2.Label { text: modelData.name; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                        QQC2.Label { text: modelData.sub; opacity: 0.7; wrapMode: Text.Wrap; Layout.fillWidth: true }
                                    }
                                }
                            }
                        }
                    }

                    // A category's settings, or search results, as cards.
                    ColumnLayout {
                        visible: root.category !== null || root.query !== ""
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit * 2
                        Layout.rightMargin: Kirigami.Units.gridUnit * 2
                        spacing: Kirigami.Units.smallSpacing
                        Repeater {
                            model: root.query !== "" ? root.matches() : (root.category ? root.category.items : [])
                            delegate: SettingCard { required property var modelData; item: modelData }
                        }
                        QQC2.Label {
                            visible: root.query !== "" && root.matches().length === 0
                            text: "No settings match \"" + root.query + "\""
                            opacity: 0.7
                        }
                    }
                    Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
                }
            }
        }
    }
}
