// Installed apps: what you installed, how big it is, one button to remove it. Behind it: /usr/libexec/fennek-installed-apps.
// Shown inside Settings (fennek-app installedapps opens Settings on it).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Item {
    id: root

    readonly property string helper: "/usr/libexec/fennek-installed-apps"
    readonly property string listCmd: helper + " list"
    property var apps: []
    property bool loaded: false
    property string busy: ""        // the app being removed
    property string error: ""
    property string search: ""
    property string sortBy: "name"
    property var pending: null

    function size(b) {
        if (b >= 1000000000) return (b / 1000000000).toFixed(1) + " GB"
        if (b >= 1000000) return Math.round(b / 1000000) + " MB"
        if (b > 0) return Math.max(1, Math.round(b / 1000)) + " KB"
        return ""
    }
    readonly property var shown: {
        const q = search.trim().toLowerCase()
        const out = apps.filter(a => q === "" || a.name.toLowerCase().indexOf(q) >= 0)
        return sortBy === "size" ? out.sort((a, b) => (b.size + (b.data || 0)) - (a.size + (a.data || 0))) : out
    }
    function quoted(s) { return "'" + s.replace(/'/g, "'\\''") + "'" }
    function remove(app, withData) {
        busy = app.id
        error = ""
        run.connectSource(helper + " uninstall " + app.kind + " " + quoted(app.id) + (withData ? " --data" : ""))
    }

    P5Support.DataSource {
        id: run
        engine: "executable"
        connectedSources: [root.listCmd]
        onNewData: (source, data) => {
            disconnectSource(source)
            if (source === root.listCmd) {
                try { root.apps = JSON.parse(data.stdout) } catch (e) {}
                root.loaded = true
            } else {
                if (data["exit code"] !== 0) root.error = "It wasn't removed. " + (data.stderr || "").trim()
                root.busy = ""
                connectSource(root.listCmd)
            }
        }
    }

    Kirigami.PromptDialog {
        id: confirm
        parent: QQC2.Overlay.overlay
        title: root.pending ? "Remove " + root.pending.name + "?" : ""
        subtitle: !root.pending ? ""
            : root.pending.kind === "classic" ? "Its own files and settings go, with anything you saved from inside it. Your files in its folder under Sandbox stay."
            : root.pending.kind === "store" && root.pending.data > 0 ? "It takes up " + root.size(root.pending.size) + ", and its saved data " + root.size(root.pending.data) + "."
            : "This takes it off the computer."
        standardButtons: Kirigami.Dialog.Cancel
        customFooterActions: [
            Kirigami.Action {
                text: "Remove"
                icon.name: "edit-delete"
                onTriggered: { confirm.close(); root.remove(root.pending, deleteData.checked) }
            }
        ]
        QQC2.CheckBox {
            id: deleteData
            visible: !!root.pending && root.pending.kind === "store" && root.pending.data > 0
            text: "Also delete its settings and saved data"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.margins: Kirigami.Units.largeSpacing * 2
            Layout.bottomMargin: 0
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Heading {
                text: !root.loaded ? "Looking…" : root.apps.length === 1 ? "1 app" : root.apps.length + " apps"
                level: 1
            }
            QQC2.Label { text: "Apps you added. What Fennek OS itself needs doesn't show here and can't be removed by accident."; opacity: 0.7; wrapMode: Text.Wrap; Layout.fillWidth: true }
            QQC2.Label { visible: root.error !== ""; text: root.error; color: Kirigami.Theme.negativeTextColor; wrapMode: Text.Wrap; Layout.fillWidth: true }
        }

        RowLayout {
            Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            Layout.rightMargin: Kirigami.Units.largeSpacing * 2
            Kirigami.SearchField {
                Layout.fillWidth: true
                placeholderText: "Find an app"
                onTextChanged: root.search = text
            }
            QQC2.ComboBox {
                model: ["Sort by name", "Sort by size"]
                onActivated: index => root.sortBy = index === 1 ? "size" : "name"
            }
            QQC2.Button {
                text: "Get more apps"
                icon.name: "plasmadiscover"
                onClicked: run.connectSource("setsid -f plasma-discover")
            }
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                spacing: Kirigami.Units.smallSpacing
                Repeater {
                    model: root.shown
                    delegate: RowLayout {
                        id: row
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                        Layout.rightMargin: Kirigami.Units.largeSpacing * 2
                        spacing: Kirigami.Units.largeSpacing
                        Kirigami.Icon {
                            source: row.modelData.icon
                            fallback: "application-x-executable"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                        }
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            QQC2.Label { text: row.modelData.name; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                            QQC2.Label {
                                text: row.modelData.kind === "classic" ? "Classic program, in its sandbox" : row.modelData.kind === "extra" ? "Added by Fennek OS on request" : "From the Store"
                                opacity: 0.6
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        QQC2.Label { text: root.size(row.modelData.size + (row.modelData.data || 0)); opacity: 0.85 }
                        QQC2.Button {
                            text: root.busy === row.modelData.id ? "Removing…" : "Remove"
                            enabled: root.busy === ""
                            onClicked: { deleteData.checked = false; root.pending = row.modelData; confirm.open() }
                        }
                    }
                }
                Kirigami.PlaceholderMessage {
                    visible: root.loaded && root.shown.length === 0
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.gridUnit * 2
                    icon.name: "fennek-set-defaultapps"
                    text: root.search === "" ? "No apps added yet" : "No app by that name"
                }
            }
        }
    }
}
