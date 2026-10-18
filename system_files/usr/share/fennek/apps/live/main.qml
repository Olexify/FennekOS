// Fennek live session (the installer USB): one calm window. Install Fennek OS, or try it first; everything you
// try here is gone after a restart. Shown instead of the Welcome window when started from the USB (fennek-first-login).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: root
    visible: true
    title: "Fennek OS"
    width: Kirigami.Units.gridUnit * 40
    height: Kirigami.Units.gridUnit * 26
    minimumWidth: Kirigami.Units.gridUnit * 28
    minimumHeight: Kirigami.Units.gridUnit * 22
    readonly property bool uk: Qt.locale().name.startsWith("uk")
    function t(en, ukr) { return uk ? ukr : en }

    P5Support.DataSource { id: run; engine: "executable"; onNewData: source => disconnectSource(source) }
    Timer { id: bye; interval: 3000; onTriggered: Qt.quit() }   // the installer is detached; leave after it started

    QQC2.Page {
        anchors.fill: parent
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit * 2.5
            spacing: Kirigami.Units.gridUnit
            Item { Layout.fillHeight: true }
            Kirigami.Icon { source: "fennek"; Layout.preferredWidth: 112; Layout.preferredHeight: 112; Layout.alignment: Qt.AlignHCenter }
            Kirigami.Heading {
                Layout.alignment: Qt.AlignHCenter
                text: root.t("Welcome to Fennek OS", "Вітаємо у Fennek OS")
                level: 1
                font.weight: Font.Light
            }
            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: Kirigami.Units.gridUnit * 28
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                opacity: 0.8
                text: root.t("Install it on this PC (next to your current system, or instead of it), or look around first. "
                             + "Nothing is changed until you choose Install; what you try here is gone after a restart.",
                             "Встановіть її на цей ПК (поруч із поточною системою або замість неї) чи спершу роздивіться. "
                             + "Нічого не змінюється, доки ви не оберете «Встановити»; усе, що ви спробуєте тут, зникне після перезапуску.")
            }
            Item { Layout.preferredHeight: Kirigami.Units.gridUnit }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.gridUnit
                QQC2.Button {
                    text: root.t("Try it first", "Спершу спробувати")
                    onClicked: Qt.quit()
                }
                QQC2.Button {
                    highlighted: true
                    icon.name: "fennek"
                    text: root.t("Install Fennek OS", "Встановити Fennek OS")
                    onClicked: { run.connectSource("setsid -f liveinst"); root.hide(); bye.start() }
                }
            }
            Item { Layout.fillHeight: true }
            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                font: Kirigami.Theme.smallFont
                opacity: 0.6
                text: root.t("You can start the installer later from the desktop or Start.",
                             "Інсталятор можна запустити пізніше зі стільниці або з меню «Пуск».")
            }
        }
    }
}
