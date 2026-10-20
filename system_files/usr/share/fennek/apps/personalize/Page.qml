// Personalize: the whole look in one place, as big picture cards: the theme (wallpaper, colours, taskbar), the text
// size with a live sample, and the typeface. Everything applies the moment you pick it (no Apply button).
// Shown inside Settings (fennek-app personalize opens Settings on it).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Item {
    id: root
    signal openSetting(string kcm)   // "More …" links: Settings opens the KDE page in place

    // id, name, wallpaper, taskbar colour, accent
    readonly property var themes: [
        ["org.fennek.desktop", "Light", "Fennek", "#f2f2f5", "#8b5cf6"],
        ["org.fennek.dark.desktop", "Dark", "Fennek", "#1d1d24", "#8b5cf6"],
        ["org.fennek.amber.desktop", "Amber", "Amber", "#221e1c", "#e0a84a"],
        ["org.fennek.sakura.desktop", "Sakura", "Sakura", "#1a2040", "#f096b4"],
        ["org.fennek.royal.desktop", "Royal", "Royal", "#261a3a", "#d9a441"],
        ["org.fennek.arcade.desktop", "Arcade", "Arcade", "#1e1632", "#a970ff"]
    ]
    readonly property var typefaces: ["Inter", "Noto Sans", "Noto Serif", "Cantarell", "DejaVu Sans"]
        .filter(f => Qt.fontFamilies().indexOf(f) >= 0)

    property string look: ""
    property int textSize: 11
    property string family: "Inter"
    property bool loaded: false
    readonly property string getCmd: "kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage; /usr/libexec/fennek-text get"

    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function setText() { run.connectSource("/usr/libexec/fennek-text set " + textSize + " " + q(family)) }

    P5Support.DataSource {
        id: run
        engine: "executable"
        connectedSources: [root.getCmd]
        onNewData: (source, data) => {
            if (source === root.getCmd) {
                const out = data.stdout.split("\n")
                root.look = out[0].trim()
                const m = (out[1] || "").match(/^(\d+) (.+)$/)
                if (m) { root.textSize = parseInt(m[1]); root.family = m[2] }
                root.loaded = true
            }
            disconnectSource(source)
        }
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing * 2

            // Theme
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing * 2
                Layout.bottomMargin: 0
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Heading { text: "Theme"; level: 2 }
                QQC2.Label { text: "Wallpaper, colours and taskbar together."; opacity: 0.7 }
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    Repeater {
                        model: root.themes
                        delegate: QQC2.AbstractButton {
                            id: card
                            required property var modelData
                            readonly property bool current: root.look === modelData[0]
                            width: Kirigami.Units.gridUnit * 10
                            height: width * 9 / 16 + Kirigami.Units.gridUnit * 1.6
                            hoverEnabled: true
                            onClicked: { root.look = modelData[0]; run.connectSource("plasma-apply-lookandfeel --apply " + modelData[0]) }
                            contentItem: ColumnLayout {
                                spacing: Kirigami.Units.smallSpacing
                                Rectangle {   // the picture, with a small taskbar and window drawn on it
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: width * 9 / 16
                                    radius: 10
                                    clip: true
                                    color: card.modelData[3]
                                    border.width: card.current ? 3 : 1
                                    border.color: card.current ? card.modelData[4]
                                        : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, card.hovered ? 0.35 : 0.12)
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: parent.border.width
                                        source: "file:///usr/share/wallpapers/" + card.modelData[2] + "/contents/images/3840x2160.jpg"
                                        sourceSize: Qt.size(384, 216)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                    Rectangle {   // a window
                                        x: parent.width * 0.2; y: parent.height * 0.18
                                        width: parent.width * 0.5; height: parent.height * 0.48
                                        radius: 4
                                        color: card.modelData[3]
                                        opacity: 0.92
                                        Rectangle { x: 6; y: 6; width: parent.width * 0.35; height: 4; radius: 2; color: card.modelData[4] }
                                    }
                                    Rectangle {   // the taskbar
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: parent.border.width }
                                        height: parent.height * 0.12
                                        color: card.modelData[3]
                                        Rectangle { x: 6; anchors.verticalCenter: parent.verticalCenter; width: parent.height * 0.55; height: width; radius: 2; color: card.modelData[4] }
                                    }
                                    Rectangle {   // picked
                                        visible: card.current
                                        anchors { right: parent.right; top: parent.top; margins: 8 }
                                        width: 22; height: 22; radius: 11
                                        color: card.modelData[4]
                                        Kirigami.Icon { anchors.centerIn: parent; width: 14; height: 14; source: "checkmark"; color: "white"; isMask: true }
                                    }
                                }
                                QQC2.Label { text: card.modelData[1]; font.weight: card.current ? Font.DemiBold : Font.Normal }
                            }
                        }
                    }
                }
            }

            // Text size
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                Layout.rightMargin: Kirigami.Units.largeSpacing * 2
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Heading { text: "Text size"; level: 2 }
                Rectangle {   // live sample
                    Layout.fillWidth: true
                    Layout.preferredHeight: sample.implicitHeight + Kirigami.Units.largeSpacing * 3
                    radius: 10
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                    QQC2.Label {
                        id: sample
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Kirigami.Units.largeSpacing * 1.5 }
                        text: "Everything you read on the screen: menus, windows, Files and the taskbar."
                        wrapMode: Text.Wrap
                        font.family: root.family
                        font.pointSize: root.textSize
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    QQC2.Label { text: "A"; font.pointSize: 9 }
                    QQC2.Slider {
                        id: sizeSlider
                        Layout.fillWidth: true
                        from: 9; to: 18; stepSize: 1; snapMode: QQC2.Slider.SnapAlways
                        value: root.textSize
                        onMoved: root.textSize = value
                        onPressedChanged: if (!pressed && root.loaded) root.setText()   // applied when you let go
                        Keys.onReleased: event => { if (!event.isAutoRepeat && root.loaded) root.setText() }
                    }
                    QQC2.Label { text: "A"; font.pointSize: 18 }
                    QQC2.Label {
                        text: Math.round(root.textSize / 11 * 100) + "%"
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                        horizontalAlignment: Text.AlignRight
                        opacity: 0.7
                    }
                }
            }

            // Typeface
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing * 2
                Layout.rightMargin: Kirigami.Units.largeSpacing * 2
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Heading { text: "Typeface"; level: 2 }
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    Repeater {
                        model: root.typefaces
                        delegate: QQC2.AbstractButton {
                            id: face
                            required property string modelData
                            readonly property bool current: root.family === modelData
                            width: Kirigami.Units.gridUnit * 8
                            height: Kirigami.Units.gridUnit * 5
                            hoverEnabled: true
                            onClicked: { root.family = modelData; root.setText() }
                            background: Rectangle {
                                radius: 10
                                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, face.hovered ? 0.08 : 0.04)
                                border.width: face.current ? 2 : 1
                                border.color: face.current ? Kirigami.Theme.highlightColor
                                    : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                            }
                            contentItem: ColumnLayout {
                                spacing: 0
                                QQC2.Label { text: "Aa"; font.family: face.modelData; font.pointSize: 22; Layout.alignment: Qt.AlignHCenter }
                                QQC2.Label { text: face.modelData; font.family: face.modelData; opacity: 0.8; Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }
                }
            }

            // More
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing * 2
                Layout.topMargin: 0
                spacing: 0
                Kirigami.Heading { text: "More"; level: 2; Layout.bottomMargin: Kirigami.Units.smallSpacing }
                Repeater {
                    model: [["Background picture", "fennek-set-background", "kcm_wallpaper"],
                            ["Colors and accent", "fennek-set-colors", "kcm_colors"],
                            ["All font options", "fennek-set-fonts", "kcm_fonts"],
                            ["More themes", "fennek-set-themes", "kcm_lookandfeel"]]
                    delegate: QQC2.ItemDelegate {
                        required property var modelData
                        Layout.fillWidth: true
                        text: modelData[0]
                        icon.name: modelData[1]
                        onClicked: root.openSetting(modelData[2])
                    }
                }
            }
        }
    }
}
