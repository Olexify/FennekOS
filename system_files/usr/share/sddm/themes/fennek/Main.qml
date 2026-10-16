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

    readonly property bool uk: Qt.locale().name.startsWith("uk")
    property int hour: new Date().getHours()
    readonly property string greeting: hour < 5 ? (uk ? "Доброї ночі" : "Good night")
                                     : hour < 12 ? (uk ? "Доброго ранку" : "Good morning")
                                     : hour < 18 ? (uk ? "Добрий день" : "Good afternoon")
                                     : (uk ? "Добрий вечір" : "Good evening")
    readonly property string font: "Inter"

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
            message.text = root.uk ? "Неправильний пароль. Спробуйте ще раз." : "The password is incorrect. Try again."
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
            font.family: root.font
            font.pixelSize: Math.round(root.height * 0.11)
            font.weight: Font.Light
        }
        Text {
            id: date
            color: "white"
            font.family: root.font
            font.pixelSize: Math.round(root.height * 0.035)
        }
        Text {
            text: root.greeting
            color: "white"
            opacity: 0.85
            font.family: root.font
            font.weight: Font.Light
            font.pixelSize: Math.round(root.height * 0.028)
            topPadding: Math.round(root.height * 0.012)
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            time.text = Qt.formatTime(now, Qt.locale().timeFormat(Locale.ShortFormat))
            date.text = now.toLocaleDateString(Qt.locale(), "dddd, d MMMM")
            root.hour = now.getHours()
        }
    }

    // ---- Sign-in stage ----
    Column {
        visible: root.signIn
        anchors.centerIn: parent
        spacing: 22

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.greeting
            color: "white"
            opacity: 0.85
            font.family: root.font
            font.weight: Font.Light
            font.pixelSize: 26
        }
        Rectangle {   // round picture
            anchors.horizontalCenter: parent.horizontalCenter
            width: 192; height: 192; radius: 96
            color: "#3b3155"
            border.color: Qt.rgba(1, 1, 1, 0.35)
            border.width: 2
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
            font.family: root.font
            font.weight: Font.DemiBold
            font.pixelSize: 34
        }
        Item {   // rounded frosted password field, arrow inside
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320; height: 44
            Rectangle {   // soft violet glow while typing
                anchors.fill: parent
                anchors.margins: -3
                radius: 25
                color: "transparent"
                border.color: "#9b7be0"
                border.width: 3
                opacity: password.activeFocus ? 0.6 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
            TextField {
                id: password
                anchors.fill: parent
                echoMode: TextInput.Password
                placeholderText: root.uk ? "Пароль" : "Password"
                leftPadding: 18
                rightPadding: 48
                color: "white"
                font.family: root.font
                font.pixelSize: 16
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.6)
                background: Rectangle { radius: 22; color: Qt.rgba(1, 1, 1, 0.16); border.color: Qt.rgba(1, 1, 1, 0.3); border.width: 1 }
                Keys.onReturnPressed: root.tryLogin()
                Keys.onEnterPressed: root.tryLogin()
            }
            Button {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 5
                width: 34; height: 34
                text: "→"
                font.pixelSize: 18
                onClicked: root.tryLogin()
                background: Rectangle { radius: 17; color: parent.down ? "#5a3a9c" : "#6d45b8" }
                contentItem: Text { text: parent.text; color: "white"; font: parent.font
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
