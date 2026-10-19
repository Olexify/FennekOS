// firewall in its own window (fennek-app firewall); the same page opens inside Settings. See Page.qml.
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    visible: true
    title: "Firewall"
    width: Kirigami.Units.gridUnit * 42
    height: Kirigami.Units.gridUnit * 40
    minimumWidth: Kirigami.Units.gridUnit * 30
    minimumHeight: Kirigami.Units.gridUnit * 24
    Page { anchors.fill: parent }
}
