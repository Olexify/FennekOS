// App permissions: what each app may do outside its own box, in plain switches. Store apps (Flatpak) and classic
// programs (.exe, run by fennek-run-exe) on one page. Changes are saved at once and count from the app's next start.
// Behind it: /usr/libexec/fennek-permissions. Shown inside Settings (fennek-app permissions opens Settings on it).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Item {
    id: root
    signal openSetting(string kcm)

    readonly property string helper: "/usr/libexec/fennek-permissions"
    readonly property string listCmd: helper + " list"
    property var apps: []
    property var programs: []
    property bool loaded: false
    property string open: ""        // the app or program whose switches are shown

    // [key, label, explanation]
    readonly property var appSwitches: [
        ["network", "Internet", "Can go online"],
        ["sound", "Sound and microphone", "Can play sound and hear the microphone"],
        ["devices", "Camera, controllers and other devices", "Webcam, game controllers, USB devices"],
        ["launch", "Start other programs on this PC", "For launchers: find and start emulators, games and tools outside its box"]
    ]
    readonly property var folders: [["documents", "Documents"], ["downloads", "Downloads"], ["pictures", "Pictures"],
                                    ["music", "Music"], ["videos", "Videos"], ["home", "Everything in your home"],
                                    ["host", "The whole computer"]]
    readonly property var runModes: [["ask", "Ask each time"], ["sandbox", "In a sandbox"],
                                     ["sandbox-sound", "In a sandbox, with sound"], ["trusted", "Without a sandbox (you trust it)"]]

    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function act(args) { run.connectSource(helper + " " + args) }
    function summary(p) {
        const parts = []
        if (p.network) parts.push("Internet")
        if (p.host) parts.push("Whole computer")
        else if (p.home) parts.push("Your home")
        else root.folders.slice(0, 5).forEach(f => { if (p[f[0]]) parts.push(f[1]) })
        if (p.sound) parts.push("Sound")
        if (p.devices) parts.push("Devices")
        if (p.launch) parts.push("Starts programs")
        return parts.length ? parts.join(" · ") : "Nothing outside its box"
    }

    P5Support.DataSource {
        id: run
        engine: "executable"
        connectedSources: [root.listCmd]
        onNewData: (source, data) => {
            disconnectSource(source)
            if (source === root.listCmd) {
                try {
                    const d = JSON.parse(data.stdout)
                    root.apps = d.apps
                    root.programs = d.programs
                } catch (e) {}
                root.loaded = true
            } else {
                connectSource(root.listCmd)   // a change: read back what really applies
            }
        }
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing * 2
                Layout.bottomMargin: 0
                wrapMode: Text.Wrap
                opacity: 0.75
                text: "Apps run in their own box. Here you choose what each one may reach outside it. "
                    + "Changes are saved at once and count from the app's next start."
            }

            // ---- Store apps ----
            Kirigami.Heading { text: "Apps"; level: 2; Layout.leftMargin: Kirigami.Units.largeSpacing * 2 }
            QQC2.Label {
                visible: root.loaded && root.apps.length === 0
                text: "No apps from the Store yet."
                opacity: 0.6
                Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            }
            Repeater {
                model: root.apps
                delegate: ColumnLayout {
                    id: appRow
                    required property var modelData
                    readonly property bool expanded: root.open === modelData.id
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                    Layout.rightMargin: Kirigami.Units.largeSpacing * 2
                    spacing: 0
                    QQC2.ItemDelegate {
                        Layout.fillWidth: true
                        onClicked: root.open = appRow.expanded ? "" : appRow.modelData.id
                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing
                            Kirigami.Icon {
                                source: appRow.modelData.id
                                fallback: "application-x-executable"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            }
                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true
                                QQC2.Label { text: appRow.modelData.name; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                                QQC2.Label { text: root.summary(appRow.modelData.perms); opacity: 0.65; elide: Text.ElideRight; Layout.fillWidth: true }
                            }
                            Kirigami.Icon { source: appRow.expanded ? "go-up" : "go-down"; Layout.preferredWidth: 16; Layout.preferredHeight: 16; opacity: 0.6 }
                        }
                    }
                    ColumnLayout {   // its switches
                        visible: appRow.expanded
                        Layout.fillWidth: true
                        Layout.leftMargin: Kirigami.Units.gridUnit * 3
                        spacing: Kirigami.Units.smallSpacing
                        Repeater {
                            model: root.appSwitches
                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                ColumnLayout {
                                    spacing: 0
                                    Layout.fillWidth: true
                                    QQC2.Label { text: modelData[1] }
                                    QQC2.Label { text: modelData[2]; opacity: 0.6; font: Kirigami.Theme.smallFont; wrapMode: Text.Wrap; Layout.fillWidth: true }
                                }
                                QQC2.Switch {
                                    checked: !!appRow.modelData.perms[modelData[0]]
                                    onToggled: root.act("app " + root.q(appRow.modelData.id) + " " + modelData[0] + (checked ? " on" : " off"))
                                }
                            }
                        }
                        QQC2.Label { text: "Files it can see"; Layout.topMargin: Kirigami.Units.smallSpacing }
                        Flow {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            Repeater {
                                model: root.folders
                                delegate: QQC2.CheckBox {
                                    required property var modelData
                                    readonly property var p: appRow.modelData.perms
                                    // a wider choice already covers the folder: shown ticked, changed there
                                    readonly property bool covered: (modelData[0] !== "host" && p.host) || (modelData[0] !== "home" && modelData[0] !== "host" && p.home)
                                    text: modelData[1]
                                    checked: !!p[modelData[0]] || covered
                                    enabled: !covered
                                    onToggled: root.act("app " + root.q(appRow.modelData.id) + " " + modelData[0] + (checked ? " on" : " off"))
                                }
                            }
                        }
                        QQC2.Button {
                            visible: appRow.modelData.changed
                            text: "Back to the app's own settings"
                            icon.name: "edit-undo"
                            flat: true
                            onClicked: root.act("reset " + root.q(appRow.modelData.id))
                        }
                    }
                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.4 }
                }
            }

            // ---- Classic programs ----
            Kirigami.Heading {
                text: "Classic programs"
                level: 2
                Layout.topMargin: Kirigami.Units.largeSpacing
                Layout.leftMargin: Kirigami.Units.largeSpacing * 2
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                Layout.rightMargin: Kirigami.Units.largeSpacing * 2
                wrapMode: Text.Wrap
                opacity: 0.6
                text: root.programs.length ? "Programs (.exe) you have run. In a sandbox they see only their own folder in Sandbox."
                                           : "Programs (.exe) appear here after you run them once."
            }
            Repeater {
                model: root.programs
                delegate: RowLayout {
                    id: progRow
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                    Layout.rightMargin: Kirigami.Units.largeSpacing * 2
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Icon { source: "application-x-ms-dos-executable"; fallback: "application-x-executable"; Layout.preferredWidth: Kirigami.Units.iconSizes.medium; Layout.preferredHeight: Kirigami.Units.iconSizes.medium }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        QQC2.Label { text: progRow.modelData.name; font.weight: Font.DemiBold; elide: Text.ElideMiddle; Layout.fillWidth: true }
                        QQC2.Label { text: progRow.modelData.path.replace(/^\/(var\/)?home\/[^\/]+/, "~"); opacity: 0.6; elide: Text.ElideMiddle; Layout.fillWidth: true; visible: text !== "" }
                    }
                    QQC2.ComboBox {
                        model: root.runModes.map(m => m[1])
                        currentIndex: Math.max(0, root.runModes.findIndex(m => m[0] === progRow.modelData.run))
                        onActivated: index => root.act("program " + progRow.modelData.sha256 + " run " + root.runModes[index][0])
                    }
                    QQC2.Switch {
                        text: "Internet"
                        visible: progRow.modelData.run === "sandbox" || progRow.modelData.run === "sandbox-sound"
                        checked: progRow.modelData.internet
                        onToggled: root.act("program " + progRow.modelData.sha256 + " internet " + (checked ? "on" : "off"))
                    }
                }
            }

            QQC2.Button {
                Layout.margins: Kirigami.Units.largeSpacing * 2
                text: "Every permission, in detail…"
                icon.name: "configure"
                flat: true
                onClicked: root.openSetting("kcm_app-permissions")
            }
        }
    }
}
