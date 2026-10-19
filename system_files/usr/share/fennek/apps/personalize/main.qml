// Personalize in its own window (fennek-app personalize); the same page opens inside Settings. See Page.qml.
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    visible: true
    title: "Personalize"
    width: Kirigami.Units.gridUnit * 44
    height: Kirigami.Units.gridUnit * 36
    minimumWidth: Kirigami.Units.gridUnit * 28
    minimumHeight: Kirigami.Units.gridUnit * 20
    P5Support.DataSource { id: run; engine: "executable"; onNewData: source => disconnectSource(source) }
    Page {
        anchors.fill: parent
        onOpenSetting: kcm => run.connectSource("fennek-app settings " + kcm)
    }
}
