// Fennek Live settings (Settings > Background, wallpaper type "Fennek Live"): the picture, the motion, battery.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property string cfg_Image
    property string cfg_Effect
    property alias cfg_OnBattery: battery.checked
    property alias formLayout: root

    // The Fennek desert is part of the system; the theme pictures are fetched the first time they are picked
    // (fennek-wallpaper-get) into the account's own wallpapers.
    readonly property string userWalls: String(StandardPaths.writableLocation(StandardPaths.GenericDataLocation)) + "/wallpapers/"
    readonly property var pictures: [
        ["Fennek desert", "file:///usr/share/wallpapers/Fennek/contents/images/3840x2160.jpg"],
        ["Sakura", userWalls + "Sakura/contents/images/3840x2160.jpg", "Sakura"],
        ["Amber", userWalls + "Amber/contents/images/3840x2160.jpg", "Amber"],
        ["Royal", userWalls + "Royal/contents/images/3840x2160.jpg", "Royal"],
        ["Arcade", userWalls + "Arcade/contents/images/3840x2160.jpg", "Arcade"]
    ]
    property string fetching: ""
    P5Support.DataSource {
        id: get
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source)
            const i = root.pictures.findIndex(p => p[2] === root.fetching)
            if (data["exit code"] === 0 && i >= 0) root.cfg_Image = root.pictures[i][1]
            root.fetching = ""
        }
    }
    readonly property var effects: [["auto", "Matches the picture"], ["petals", "Falling petals"], ["lights", "Drifting lights"], ["none", "Still"]]

    QQC2.ComboBox {
        Kirigami.FormData.label: "Picture:"
        wheelEnabled: false
        model: root.pictures.map(p => p[0]).concat(["Your own picture…"])
        currentIndex: Math.max(0, root.pictures.findIndex(p => p[1] === root.cfg_Image))
        enabled: root.fetching === ""
        onActivated: index => {
            if (index >= root.pictures.length) { pick.open(); return }
            const p = root.pictures[index]
            if (!p[2]) { root.cfg_Image = p[1]; return }
            root.fetching = p[2]   // downloaded once, then it is there (nothing happens if it already is)
            get.connectSource("/usr/libexec/fennek-wallpaper-get " + p[2])
        }
    }
    QQC2.Label {
        visible: root.fetching !== ""
        text: "Downloading " + root.fetching + "…"
        opacity: 0.7
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
