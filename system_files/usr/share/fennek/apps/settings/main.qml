// Fennek Settings: a sidebar ("Find a setting" + categories with their icons) and, on the right, the chosen
// category's settings as rounded cards. Home shows the categories as large cards. A setting opens its KDE settings
// page right here, on the right (saved by itself, no Apply; back arrow to return), or runs a tool.
// Runs as a normal window: fennek-app settings (see fennek-settings.desktop).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import Fennek
import "catalog.js" as Catalog

QQC2.ApplicationWindow {
    visible: true
    title: "Settings"
    width: Kirigami.Units.gridUnit * 60
    height: Kirigami.Units.gridUnit * 38
    minimumWidth: Kirigami.Units.gridUnit * 28
    minimumHeight: Kirigami.Units.gridUnit * 20
    id: root

    property var category: null          // open category, or null for Home
    property string query: ""
    property var page: null              // the setting whose page is open on the right, or null
    onCategoryChanged: page = null
    onQueryChanged: if (query !== "") page = null
    // fennek-app settings kcm_NAME: open right on that page (the action center's right-click, links elsewhere).
    Component.onCompleted: {
        const want = Qt.application.arguments[2] || ""
        for (const c of Catalog.categories)
            for (const i of c.items)
                if (want !== "" && (i.kcm === want || i.page === want)) { category = c; page = i }
        // A KDE page that isn't in the catalog: shown inside anyway (its own name in the header).
        if (page === null && /^kcm_[a-z0-9_-]+$/.test(want) && pageView.has(want))
            page = { name: "", kcm: want, icon: "" }
    }

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }

    // Home header: who you are and how this PC is doing (update waiting, firewall network profile).
    KCoreAddons.KUser { id: kuser }
    property string netProfile: ""
    property bool updateWaiting: false
    readonly property string statusCmd: "fennek-firewall profile; test -e /run/ostree/staged-deployment && echo staged"
    P5Support.DataSource {
        id: status
        engine: "executable"
        connectedSources: [root.statusCmd]
        interval: 30000
        onNewData: (source, data) => {
            const out = data.stdout.split("\n")
            root.netProfile = out[0].trim()
            root.updateWaiting = out.indexOf("staged") >= 0
        }
    }
    function open(item) {
        if (item.kcm || item.page) page = item   // shown on the right (KDE page saved by itself, no Apply; or a Fennek page)
        else run.connectSource(item.cmd)
    }
    function openPage(name) {                    // a Fennek page by name (the Home status chips)
        for (const c of Catalog.categories)
            for (const i of c.items)
                if (i.page === name) { category = c; page = i }
    }
    // Optional pages only where they are installed (KDE version, ARM).
    function shown(items) { return items.filter(i => !i.optional || pageView.has(i.kcm)) }
    // The KDE page's own search words too ("dpi" finds Display, "wallpaper" finds Background); looked up once.
    property var wordCache: ({})
    function words(i) {
        if (!i.kcm) return ""
        if (wordCache[i.kcm] === undefined) wordCache[i.kcm] = pageView.keywords(i.kcm)
        return wordCache[i.kcm]
    }
    function matches() {
        const q = query.toLowerCase().trim()
        const out = []
        for (const c of Catalog.categories)
            for (const i of shown(c.items))
                if ((i.name + " " + i.desc + " " + c.name + " " + words(i)).toLowerCase().includes(q)) out.push(i)
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

    QQC2.Page {
        anchors.fill: parent

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

                    // Search first, then Home like any other row (the window title already says "Settings").
                    Kirigami.SearchField {
                        id: search
                        Layout.fillWidth: true
                        Layout.bottomMargin: Kirigami.Units.largeSpacing
                        placeholderText: "Find a setting"
                        onTextChanged: root.query = text
                    }
                    QQC2.ItemDelegate {
                        readonly property bool current: root.category === null && root.query === ""
                        Layout.fillWidth: true
                        onClicked: { root.category = null; root.page = null; search.text = "" }
                        background: Rectangle {
                            radius: 8
                            color: parent.current ? root.cardHover : parent.hovered ? root.cardColor : "transparent"
                            Rectangle {
                                visible: parent.parent.current
                                width: 3; radius: 2
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 8; bottomMargin: 8 }
                                color: Kirigami.Theme.highlightColor
                            }
                        }
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing
                            Kirigami.Icon { source: "go-home"; Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
                            QQC2.Label { text: "Home"; Layout.fillWidth: true }
                        }
                    }
                    Repeater {
                        model: Catalog.categories
                        delegate: QQC2.ItemDelegate {
                            required property var modelData
                            readonly property bool current: root.category === modelData && root.query === ""
                            Layout.fillWidth: true
                            onClicked: { root.category = modelData; root.page = null; search.text = "" }
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
                        text: "All KDE settings"   // everything else, in KDE's own window
                        icon.name: "preferences-system"
                        onClicked: run.connectSource("systemsettings")
                        background: Rectangle { radius: 8; color: parent.hovered ? root.cardColor : "transparent" }
                    }
                }
            }

            // ---- An open settings page ----
            ColumnLayout {
                visible: root.page !== null
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.largeSpacing
                    QQC2.ToolButton {
                        icon.name: "go-previous"
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: "Back"
                        onClicked: root.page && root.page.kcm && pageView.depth > 1 ? pageView.back() : (root.page = null)
                    }
                    Kirigami.Icon {
                        source: root.page ? root.page.icon : ""
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Layout.preferredWidth
                    }
                    Kirigami.Heading { text: root.page ? (root.page.name || pageView.title) : ""; level: 2; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                Kirigami.Separator { Layout.fillWidth: true }
                // Fennek's own pages (Updates...): the same page its own window shows.
                Loader {
                    visible: !!(root.page && root.page.page)
                    Layout.fillWidth: true
                    Layout.fillHeight: visible
                    source: root.page && root.page.page ? "file:///usr/share/fennek/apps/" + root.page.page + "/Page.qml" : ""
                }
                KcmView {
                    id: pageView
                    visible: !!(root.page && root.page.kcm)
                    Layout.fillWidth: true
                    Layout.fillHeight: visible
                    kcm: root.page && root.page.kcm ? root.page.kcm : ""
                    // An old-style page can't be shown inside: its own window (also without Apply).
                    onKcmChanged: if (failed && kcm !== "") { run.connectSource("fennek-kcm " + kcm); root.page = null }
                }
            }

            // ---- Content ----
            QQC2.ScrollView {
                visible: root.page === null
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

                    // Home: your account and this PC's state, then the categories as large cards.
                    Rectangle {
                        visible: root.category === null && root.query === ""
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit * 2
                        Layout.rightMargin: Kirigami.Units.gridUnit * 2
                        implicitHeight: header.implicitHeight + Kirigami.Units.gridUnit * 2
                        radius: 12
                        color: root.cardColor
                        RowLayout {
                            id: header
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.gridUnit
                            spacing: Kirigami.Units.largeSpacing * 2
                            Kirigami.Icon {   // your account picture, or the generic one
                                source: kuser.faceIconUrl.toString() !== "" ? kuser.faceIconUrl : "user-identity"
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                                Layout.preferredHeight: Layout.preferredWidth
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Kirigami.Heading { text: kuser.fullName || kuser.loginName; level: 2; Layout.fillWidth: true; elide: Text.ElideRight }
                                QQC2.Label { text: "Local account · Fennek OS"; opacity: 0.7 }
                            }
                            // Status chips: click to open the matching place.
                            Repeater {
                                model: [
                                    { icon: root.updateWaiting ? "system-reboot" : "update-none",
                                      text: root.updateWaiting ? "Restart to finish the update" : "Updates are automatic",
                                      page: "updates" },
                                    { icon: "security-high",
                                      text: root.netProfile === "public" ? "Firewall: public network" : "Firewall: home network",
                                      page: "firewall" }
                                ]
                                delegate: QQC2.ItemDelegate {
                                    required property var modelData
                                    onClicked: modelData.page ? root.openPage(modelData.page) : run.connectSource(modelData.cmd)
                                    background: Rectangle { radius: 8; color: parent.hovered ? root.cardHover : "transparent" }
                                    contentItem: ColumnLayout {
                                        spacing: Kirigami.Units.smallSpacing
                                        Kirigami.Icon { source: modelData.icon; Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
                                        QQC2.Label {
                                            text: modelData.text
                                            font: Kirigami.Theme.smallFont
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.Wrap
                                            Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                                        }
                                    }
                                }
                            }
                        }
                    }

                    GridLayout {
                        visible: root.category === null && root.query === ""
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit * 2
                        Layout.rightMargin: Kirigami.Units.gridUnit * 2
                        columns: root.width > Kirigami.Units.gridUnit * 46 ? 2 : 1   // one column in a narrow window
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
                            model: root.query !== "" ? root.matches() : (root.category ? root.shown(root.category.items) : [])
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
