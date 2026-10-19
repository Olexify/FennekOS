// quarantine in its own window (fennek-app quarantine); the same page opens inside Settings. See Page.qml.
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    visible: true
    title: "Quarantine"
    width: Kirigami.Units.gridUnit * 40
    height: Kirigami.Units.gridUnit * 34
    minimumWidth: Kirigami.Units.gridUnit * 30
    minimumHeight: Kirigami.Units.gridUnit * 24
    Page { anchors.fill: parent }
}
