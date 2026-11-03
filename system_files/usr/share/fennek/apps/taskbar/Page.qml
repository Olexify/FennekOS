// Taskbar: the classic switches, saved at once, also while the taskbar is locked. Behind it: /usr/libexec/fennek-taskbar.
// Shown inside Settings (fennek-app taskbar opens Settings on it; the taskbar's right-click menu leads here).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Item {
    id: root

    readonly property string helper: "/usr/libexec/fennek-taskbar"
    readonly property string getCmd: helper + " get"
    property var state: ({})
    property bool loaded: false

    function set(key, on) {
        const s = Object.assign({}, state)
        s[key] = on
        state = s
        run.connectSource(helper + " set " + key + (on ? " on" : " off"))
    }

    P5Support.DataSource {
        id: run
        engine: "executable"
        connectedSources: [root.getCmd]
        onNewData: (source, data) => {
            disconnectSource(source)
            if (source === root.getCmd) {
                try { root.state = JSON.parse(data.stdout); root.loaded = true } catch (e) {}
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing * 2
        spacing: Kirigami.Units.largeSpacing
        Repeater {
            model: [
                ["autohide", "Automatically hide the taskbar", "It comes back when the pointer reaches the bottom of the screen"],
                ["small", "Small taskbar buttons", "A thinner taskbar, more room for your windows"],
                ["combine", "Combine taskbar buttons", "One button for all the windows of an app. Off: a button for each window"],
                ["peek", "Peek at a window", "Pointing at a button's preview shows that window for a moment"]
            ]
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    QQC2.Label { text: modelData[1]; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.Wrap }
                    QQC2.Label { text: modelData[2]; opacity: 0.7; Layout.fillWidth: true; wrapMode: Text.Wrap }
                }
                QQC2.Switch {
                    enabled: root.loaded
                    checked: !!root.state[modelData[0]]
                    onToggled: root.set(modelData[0], checked)
                }
            }
        }
        RowLayout {
            visible: root.state.displays > 1
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                QQC2.Label { text: "Show taskbar on all displays"; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.Wrap }
                QQC2.Label { text: "Off: only the main display has one"; opacity: 0.7; Layout.fillWidth: true; wrapMode: Text.Wrap }
            }
            QQC2.Switch {
                checked: !!root.state.all_displays
                onToggled: root.set("all_displays", checked)
            }
        }
        QQC2.Button {
            text: "Move and arrange what's on the taskbar"
            icon.name: "document-edit"
            onClicked: run.connectSource("gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.setEditMode true")
        }
        Item { Layout.fillHeight: true }
    }
}
