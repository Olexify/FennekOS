// Free up space: what can be cleaned safely in your account, with sizes, each with its own Clean button (Recycle Bin,
// thumbnails, old temporary files, unused app parts); Downloads shown with an Open button, never cleaned for you.
// Behind it: /usr/libexec/fennek-cleanup. Shown inside Settings (fennek-app cleanup opens Settings on it).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Item {
    id: root
    signal openSetting(string kcm)

    readonly property string helper: "/usr/libexec/fennek-cleanup"
    readonly property string sizesCmd: helper + " sizes"
    property var items: []
    property bool loaded: false
    property string busy: ""        // the key being cleaned

    function size(b) {
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576) return Math.round(b / 1048576) + " MB"
        if (b >= 1024) return Math.round(b / 1024) + " KB"
        return b > 0 ? b + " bytes" : "Nothing"
    }
    readonly property real total: items.filter(i => i.action === "clean").reduce((a, i) => a + i.bytes, 0)

    P5Support.DataSource {
        id: run
        engine: "executable"
        connectedSources: [root.sizesCmd]
        onNewData: (source, data) => {
            disconnectSource(source)
            if (source === root.sizesCmd) {
                try { root.items = JSON.parse(data.stdout) } catch (e) {}
                root.loaded = true
            } else {
                root.busy = ""
                connectSource(root.sizesCmd)
            }
        }
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.margins: Kirigami.Units.largeSpacing * 2
                Layout.bottomMargin: 0
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Heading { text: root.loaded ? root.size(root.total) + " can be freed" : "Looking…"; level: 1 }
                QQC2.Label { text: "Only things that are safe to remove. Your own files are never touched here."; opacity: 0.7 }
            }

            Repeater {
                model: root.items
                delegate: RowLayout {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                    Layout.rightMargin: Kirigami.Units.largeSpacing * 2
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Icon {
                        source: ({ trash: "user-trash-full", thumbnails: "image-x-generic", cache: "folder-temp",
                                   apps: "fennek-set-storeupdates", downloads: "folder-download" })[row.modelData.key] || "folder"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        QQC2.Label { text: row.modelData.name; font.weight: Font.DemiBold }
                        QQC2.Label { text: row.modelData.desc; opacity: 0.6; wrapMode: Text.Wrap; Layout.fillWidth: true }
                    }
                    QQC2.Label {
                        text: row.modelData.key === "apps"
                              ? (row.modelData.count ? row.modelData.count + (row.modelData.count === 1 ? " part" : " parts") : "Nothing")
                              : root.size(row.modelData.bytes)
                        opacity: 0.85
                    }
                    QQC2.Button {
                        visible: row.modelData.action === "clean"
                        text: root.busy === row.modelData.key ? "Cleaning…" : "Clean"
                        enabled: root.busy === "" && (row.modelData.bytes > 0 || row.modelData.count > 0)
                        onClicked: { root.busy = row.modelData.key; run.connectSource(root.helper + " clean " + row.modelData.key) }
                    }
                    QQC2.Button {
                        visible: row.modelData.action === "open"
                        text: "Open"
                        onClicked: run.connectSource("xdg-open \"$(xdg-user-dir DOWNLOAD)\"")
                    }
                }
            }

            QQC2.Button {
                Layout.margins: Kirigami.Units.largeSpacing * 2
                text: "See what uses space on your disks…"
                icon.name: "fennek-set-storage"
                flat: true
                onClicked: run.connectSource("setsid -f filelight")
            }
        }
    }
}
