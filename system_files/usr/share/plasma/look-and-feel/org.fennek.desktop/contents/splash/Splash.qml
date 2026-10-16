// Fennek OS splash after signing in: the dusk wallpaper, the logo fading in, a greeting, and a thin violet
// line that fills up while the desktop starts. KSplash API: `stage` goes up to 6, then the splash closes.
import QtQuick

Rectangle {
    id: root
    color: "#140c2a"
    property int stage
    readonly property bool uk: Qt.locale().name.startsWith("uk")
    readonly property int hour: new Date().getHours()

    Image {
        anchors.fill: parent
        source: "file:///usr/share/wallpapers/Fennek/contents/images/3840x2160.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: 0.55
    }

    Column {
        id: content
        anchors.centerIn: parent
        spacing: 28
        opacity: 0
        Component.onCompleted: fadeIn.start()
        NumberAnimation on opacity { id: fadeIn; running: false; to: 1; duration: 600; easing.type: Easing.OutCubic }

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "file:///usr/share/icons/hicolor/scalable/apps/fennek.svg"
            sourceSize.width: 132
            sourceSize.height: 132
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.family: "Inter"
            font.pixelSize: 28
            font.weight: Font.Light
            text: root.hour < 5 ? (root.uk ? "Доброї ночі" : "Good night")
                : root.hour < 12 ? (root.uk ? "Доброго ранку" : "Good morning")
                : root.hour < 18 ? (root.uk ? "Добрий день" : "Good afternoon")
                : (root.uk ? "Добрий вечір" : "Good evening")
        }
        Rectangle {   // progress: fills with the start-up stages
            anchors.horizontalCenter: parent.horizontalCenter
            width: 220; height: 3; radius: 2
            color: Qt.rgba(1, 1, 1, 0.18)
            Rectangle {
                height: parent.height; radius: 2
                color: "#9b7be0"
                width: parent.width * Math.min(root.stage, 6) / 6
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }
}
