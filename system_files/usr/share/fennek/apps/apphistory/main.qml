// apphistory in its own window (fennek-app apphistory); the same page opens inside Settings. See Page.qml.
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    visible: true
    title: "App history"
    width: Kirigami.Units.gridUnit * 40
    height: Kirigami.Units.gridUnit * 32
    minimumWidth: Kirigami.Units.gridUnit * 28
    minimumHeight: Kirigami.Units.gridUnit * 20
    Page { anchors.fill: parent }
}
