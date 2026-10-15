// Fennek OS sign-in, classic layout: first a lock screen (wallpaper + big clock bottom-left);
// any key or click reveals the sign-in (blurred wallpaper, round picture, name, password with inline arrow,
// power icons bottom-right). SDDM theme API: sddm, userModel, sessionModel, config.
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import SddmComponents 2.0 as Sddm

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#16122b"

    property bool signIn: false
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property string userName: userModel.data(userModel.index(userIndex, 0), Qt.UserRole + 1) || ""
    property string realName: userModel.data(userModel.index(userIndex, 0), Qt.UserRole + 2) || userName
    property string userIcon: userModel.data(userModel.index(userIndex, 0), Qt.UserRole + 4) || ""

    function reveal() {
        if (!signIn) {
            signIn = true
            password.forceActiveFocus()
        }
    }
    function tryLogin() {
        message.text = ""
        sddm.login(userName, password.text, sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            message.text = "The password is incorrect. Try again."
            password.forceActiveFocus()
        }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: root.signIn
        blur: root.signIn ? 1.0 : 0.0
        blurMax: 48
        brightness: root.signIn ? -0.15 : 0.0
        Behavior on blur { NumberAnimation { duration: 250 } }
    }

    // ---- Lock stage: big clock bottom-left, like the classic desktop ----
    Column {
        visible: !root.signIn
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Math.round(root.height * 0.07)
        Text {
            id: time
            color: "white"
            font.pixelSize: Math.round(root.height * 0.11)
            font.weight: Font.Light
        }
        Text {
            id: date
            color: "white"
            font.pixelSize: Math.round(root.height * 0.035)
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            time.text = Qt.formatTime(now, Qt.locale().timeFormat(Locale.ShortFormat))
            date.text = Qt.formatDate(now, "dddd, MMMM d")
        }
    }

    // ---- Sign-in stage ----
    Column {
        visible: root.signIn
        anchors.centerIn: parent
        spacing: 22

        Rectangle {   // round picture
            anchors.horizontalCenter: parent.horizontalCenter
            width: 192; height: 192; radius: 96
            color: "#3b3155"
            clip: true
            Image {
                id: face
                anchors.fill: parent
                source: root.userIcon
                fillMode: Image.PreserveAspectCrop
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: face
                maskEnabled: true
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle { width: 192; height: 192; radius: 96 }
                }
                visible: face.status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: face.status !== Image.Ready
                text: (root.realName || "?").charAt(0).toUpperCase()
                color: "white"
                font.pixelSize: 84
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.realName
            color: "white"
            font.pixelSize: 36
        }
        Row {   // password box with the arrow inside, like the classic desktop
            anchors.horizontalCenter: parent.horizontalCenter
            TextField {
                id: password
                width: 296; height: 36
                echoMode: TextInput.Password
                placeholderText: "Password"
                leftPadding: 10
                color: "black"
                placeholderTextColor: "#666666"
                background: Rectangle { color: "white"; border.color: password.activeFocus ? "#f2b766" : "#cccccc"; border.width: 2 }
                Keys.onReturnPressed: root.tryLogin()
                Keys.onEnterPressed: root.tryLogin()
            }
            Button {
                width: 36; height: 36
                text: "→"
                font.pixelSize: 18
                onClicked: root.tryLogin()
                background: Rectangle { color: parent.down ? "#c98a3d" : "#f2b766" }
                contentItem: Text { text: parent.text; color: "black"; font: parent.font
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }
        Text {
            id: message
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.pixelSize: 16
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: keyboard.capsLock
            text: "Caps Lock is on"
            color: "#ffd18a"
            font.pixelSize: 14
        }
    }

    // ---- Other users, bottom-left (only when there is more than one) ----
    Column {
        visible: root.signIn && userModel.count > 1
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 6
        Repeater {
            model: userModel
            delegate: Text {
                text: (model.realName || model.name)
                color: index === root.userIndex ? "white" : "#d0c8e0"
                font.pixelSize: 18
                font.bold: index === root.userIndex
                MouseArea { anchors.fill: parent; onClicked: { root.userIndex = index; password.text = ""; password.forceActiveFocus() } }
            }
        }
    }

    // ---- Power, bottom-right ----
    Row {
        visible: root.signIn
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32
        spacing: 18
        Repeater {
            model: [
                { label: "Sleep", glyph: "☾", enabled: sddm.canSuspend, act: function() { sddm.suspend() } },
                { label: "Restart", glyph: "↻", enabled: sddm.canReboot, act: function() { sddm.reboot() } },
                { label: "Shut down", glyph: "⏻", enabled: sddm.canPowerOff, act: function() { sddm.powerOff() } }
            ]
            delegate: Text {
                visible: modelData.enabled
                text: modelData.glyph
                color: "white"
                font.pixelSize: 28
                ToolTip.visible: hover.containsMouse
                ToolTip.text: modelData.label
                MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.act() }
            }
        }
    }

    // Any key or click on the lock stage reveals the sign-in.
    MouseArea {
        anchors.fill: parent
        enabled: !root.signIn
        onClicked: root.reveal()
    }
    focus: true
    Keys.onPressed: event => { if (!root.signIn) { root.reveal(); event.accepted = true } }
    Component.onCompleted: forceActiveFocus()
}
