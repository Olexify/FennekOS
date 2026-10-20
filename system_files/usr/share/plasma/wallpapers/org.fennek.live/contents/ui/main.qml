// Fennek Live: a picture with gentle motion on top. Sakura petals on the wind (Sakura), or soft lights drifting upward
// (Amber, Royal, Arcade, any other picture). Light on the computer: a few dozen GPU-drawn shapes, and on battery it
// stands still unless "Keep moving on battery" is on. Also still when animations are turned off.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

WallpaperItem {
    id: root

    // Fennek's wallpapers became JPEG (2026-10): a picture chosen before still points at the old .png name.
    readonly property string picture: String(root.configuration.Image || "file:///usr/share/wallpapers/Sakura/contents/images/3840x2160.jpg")
        .replace(/^(file:\/\/\/usr\/share\/wallpapers\/.*\/3840x2160)\.png$/, "$1.jpg")
    readonly property string effect: root.configuration.Effect === "auto" || !root.configuration.Effect
        ? (picture.indexOf("Sakura") >= 0 ? "petals" : "lights") : root.configuration.Effect
    // Colours of the lights follow the picture.
    readonly property var glow: picture.indexOf("Amber") >= 0 ? ["#ffd98c", "#e0a84a"]
        : picture.indexOf("Royal") >= 0 ? ["#f4cf7e", "#b79cff"]
        : picture.indexOf("Arcade") >= 0 ? ["#ff7ad9", "#58d6ff", "#ffd166"]
        : ["#ffffff", "#c8b6ff"]

    property bool pluggedIn: true            // a desktop without a battery counts as plugged in
    readonly property bool moving: effect !== "none" && (root.configuration.OnBattery || pluggedIn)
                                   && Kirigami.Units.longDuration > 0

    P5Support.DataSource {
        engine: "powermanagement"
        connectedSources: ["AC Adapter"]
        onNewData: (source, data) => { if (data["Plugged in"] !== undefined) root.pluggedIn = data["Plugged in"] }
    }

    Image {
        anchors.fill: parent
        source: root.picture
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(root.width, root.height)
        onStatusChanged: if (status === Image.Ready) root.accentColorChanged()
    }

    // Petals on the wind: real sakura petals (petal.svg) blown across from left to right, rising and dipping with
    // the breeze, tumbling as they go; each starts again on the left when it leaves the screen.
    Repeater {
        model: root.effect === "petals" ? 26 : 0
        delegate: Image {
            id: petal
            readonly property real size: 16 + Math.random() * 18
            readonly property real lane: root.height * (0.1 + Math.random() * 0.75)
            readonly property int cross: 18000 + Math.random() * 16000
            source: "petal.svg"
            sourceSize: Qt.size(64, 64)
            width: size
            height: size
            opacity: 0.55 + Math.random() * 0.35
            x: -60
            y: lane
            NumberAnimation on x {
                running: root.moving
                loops: Animation.Infinite
                from: -60 - Math.random() * root.width
                to: root.width + 60
                duration: petal.cross
            }
            SequentialAnimation on y {   // the breeze lifts and drops them
                running: root.moving
                loops: Animation.Infinite
                NumberAnimation { to: petal.lane - 60 - Math.random() * 90; duration: 2600 + Math.random() * 2000; easing.type: Easing.InOutSine }
                NumberAnimation { to: petal.lane + 40 + Math.random() * 70; duration: 2600 + Math.random() * 2000; easing.type: Easing.InOutSine }
            }
            RotationAnimation on rotation {
                running: root.moving
                loops: Animation.Infinite
                from: 0
                to: 360 * (index % 2 ? 1 : -1)
                duration: 7000 + Math.random() * 7000
            }
        }
    }

    // Drifting lights: soft glowing dots rising slowly and breathing, like fireflies or embers.
    Repeater {
        model: root.effect === "lights" ? 22 : 0
        delegate: Item {
            id: light
            readonly property real size: 6 + Math.random() * 16
            x: Math.random() * root.width
            y: root.height * (0.2 + Math.random() * 0.8)
            width: size * 4
            height: size * 4
            Rectangle {   // the halo
                anchors.fill: parent
                radius: width / 2
                color: root.glow[index % root.glow.length]
                opacity: 0.10
            }
            Rectangle {   // the core
                anchors.centerIn: parent
                width: light.size
                height: width
                radius: width / 2
                color: root.glow[index % root.glow.length]
            }
            NumberAnimation on y {
                running: root.moving
                loops: Animation.Infinite
                from: root.height + 60
                to: -80
                duration: 40000 + Math.random() * 40000
            }
            SequentialAnimation on opacity {
                running: root.moving
                loops: Animation.Infinite
                NumberAnimation { from: 0.15; to: 0.85; duration: 2500 + Math.random() * 3000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.85; to: 0.15; duration: 2500 + Math.random() * 3000; easing.type: Easing.InOutSine }
            }
        }
    }
}
