// Fennek Live settings (Settings > Background, wallpaper type "Fennek Live"): the picture, the motion, battery.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property string cfg_Image
    property string cfg_Effect
    property alias cfg_OnBattery: battery.checked
    property alias formLayout: root

    readonly property var pictures: [
        ["Sakura", "file:///usr/share/wallpapers/Sakura/contents/images/3840x2160.jpg"],
        ["Amber", "file:///usr/share/wallpapers/Amber/contents/images/3840x2160.jpg"],
        ["Royal", "file:///usr/share/wallpapers/Royal/contents/images/3840x2160.jpg"],
        ["Arcade", "file:///usr/share/wallpapers/Arcade/contents/images/3840x2160.jpg"],
        ["Fennek desert", "file:///usr/share/wallpapers/Fennek/contents/images/3840x2160.jpg"]
    ]
    readonly property var effects: [["auto", "Matches the picture"], ["petals", "Falling petals"], ["lights", "Drifting lights"], ["none", "Still"]]

    QQC2.ComboBox {
        Kirigami.FormData.label: "Picture:"
        wheelEnabled: false
        model: root.pictures.map(p => p[0]).concat(["Your own picture…"])
        currentIndex: Math.max(0, root.pictures.findIndex(p => p[1] === root.cfg_Image))
        onActivated: index => {
            if (index < root.pictures.length) root.cfg_Image = root.pictures[index][1]
            else pick.open()
        }
    }
    QQC2.Label {
        visible: root.pictures.findIndex(p => p[1] === root.cfg_Image) < 0
        text: root.cfg_Image.replace("file://", "")
        elide: Text.ElideMiddle
        opacity: 0.7
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: "Motion:"
        wheelEnabled: false
        model: root.effects.map(e => e[1])
        currentIndex: Math.max(0, root.effects.findIndex(e => e[0] === root.cfg_Effect))
        onActivated: index => root.cfg_Effect = root.effects[index][0]
    }
    QQC2.CheckBox {
        id: battery
        text: "Keep moving on battery"
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: 600
        QQC2.ToolTip.text: "Off: on battery the picture stands still, to save power."
    }

    FileDialog {
        id: pick
        title: "Choose a picture"
        nameFilters: ["Pictures (*.png *.jpg *.jpeg *.webp *.svg)"]
        onAccepted: root.cfg_Image = selectedFile.toString()
    }
}
