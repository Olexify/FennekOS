// Fennek welcome: opens once at a new user's first login (and from Start any time). Four calm pages:
// greeting, pick your look (applied right away), what keeps you safe, a few tips. Runs as
// fennek-app welcome (see fennek-welcome.desktop).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    visible: true
    title: "Welcome"
    width: Kirigami.Units.gridUnit * 44
    height: Kirigami.Units.gridUnit * 30
    minimumWidth: Kirigami.Units.gridUnit * 28
    minimumHeight: Kirigami.Units.gridUnit * 20
    id: root
    property int page: 0
    readonly property bool uk: Qt.locale().name.startsWith("uk")
    readonly property string name: {
        const n = kuser.fullName || kuser.loginName || ""
        return n.charAt(0).toUpperCase() + n.slice(1)
    }
    function t(en, ukr) { return uk ? ukr : en }

    KCoreAddons.KUser { id: kuser }
    P5Support.DataSource { id: run; engine: "executable"; onNewData: source => disconnectSource(source) }

    QQC2.Page {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit * 2.5
            spacing: Kirigami.Units.gridUnit

            StackLayout {
                currentIndex: root.page
                Layout.fillWidth: true
                Layout.fillHeight: true

                // 1. Greeting
                ColumnLayout {
                    spacing: Kirigami.Units.gridUnit
                    Item { Layout.fillHeight: true }
                    Kirigami.Icon { source: "fennek"; Layout.preferredWidth: 128; Layout.preferredHeight: 128; Layout.alignment: Qt.AlignHCenter }
                    Kirigami.Heading {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.t("Welcome to Fennek OS", "Вітаємо у Fennek OS") + (root.name ? ", " + root.name : "")
                        level: 1
                        font.weight: Font.Light
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 30
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        opacity: 0.8
                        text: root.t("Your desktop is ready. A familiar place, private by default, and built to keep you safe. "
                                     + "Let's set it up the way you like.",
                                     "Ваш робочий стіл готовий. Знайоме місце, приватне за замовчуванням і створене, щоб берегти вас. "
                                     + "Налаштуймо його під вас.")
                    }
                    Item { Layout.fillHeight: true }
                }

                // 2. Look
                ColumnLayout {
                    spacing: Kirigami.Units.gridUnit
                    Kirigami.Heading { text: root.t("Pick your look", "Оберіть вигляд"); level: 2 }
                    QQC2.Label { text: root.t("You can change it later in Settings.", "Це можна змінити пізніше в Налаштуваннях."); opacity: 0.7 }
                    RowLayout {
                        spacing: Kirigami.Units.gridUnit * 2
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Kirigami.Units.gridUnit
                        Repeater {
                            model: [
                                { label: root.t("Light", "Світлий"), lnf: "org.fennek.desktop", top: "#f4f2f8", bar: "#2b2733" },
                                { label: root.t("Dark", "Темний"), lnf: "org.fennek.dark.desktop", top: "#26232e", bar: "#18161d" }
                            ]
                            delegate: ColumnLayout {
                                spacing: Kirigami.Units.largeSpacing
                                QQC2.Button {
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 13
                                    Layout.preferredHeight: Kirigami.Units.gridUnit * 8
                                    onClicked: run.connectSource("plasma-apply-lookandfeel --apply " + modelData.lnf)
                                    contentItem: Item {
                                        Rectangle {   // a tiny desktop preview: window + taskbar
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            radius: 6
                                            gradient: Gradient {
                                                GradientStop { position: 0; color: "#2a1f4a" }
                                                GradientStop { position: 1; color: "#c8743a" }
                                            }
                                            Rectangle {
                                                x: parent.width * 0.15; y: parent.height * 0.15
                                                width: parent.width * 0.6; height: parent.height * 0.55
                                                radius: 4; color: modelData.top
                                            }
                                            Rectangle {
                                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                                height: parent.height * 0.12
                                                color: modelData.bar
                                            }
                                        }
                                    }
                                }
                                QQC2.Label { text: modelData.label; Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // 3. Safety
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Heading { text: root.t("What keeps you safe", "Що вас захищає"); level: 2 }
                    Repeater {
                        model: [
                            { icon: "fennek-settings-privacy", title: root.t("No telemetry", "Без телеметрії"),
                              text: root.t("Nothing about you is sent anywhere.", "Нічого про вас нікуди не надсилається."), cmd: "" },
                            { icon: "fennek-firewall", title: root.t("Firewall", "Брандмауер"),
                              text: root.t("Nobody on the network can connect in. Choose which apps may use the internet.",
                                           "Ніхто з мережі не може підключитися. Оберіть, яким застосункам дозволено інтернет."),
                              cmd: "fennek-app firewall" },
                            { icon: "fennek-quarantine", title: root.t("Download guard", "Захист завантажень"),
                              text: root.t("New downloads are checked; threats go to quarantine.",
                                           "Нові завантаження перевіряються; загрози йдуть у карантин."), cmd: "fennek-quarantine" },
                            { icon: "folder-documents", title: root.t("Earlier versions of your files", "Попередні версії файлів"),
                              text: root.t("Kept every hour. Right-click a file: Restore previous versions.",
                                           "Зберігаються щогодини. Клацніть файл правою кнопкою: Відновити попередні версії."), cmd: "" }
                        ]
                        delegate: RowLayout {
                            spacing: Kirigami.Units.gridUnit
                            Layout.fillWidth: true
                            Kirigami.Icon { source: modelData.icon; Layout.preferredWidth: 40; Layout.preferredHeight: 40 }
                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true
                                QQC2.Label { text: modelData.title; font.weight: Font.DemiBold }
                                QQC2.Label { text: modelData.text; opacity: 0.75; wrapMode: Text.Wrap; Layout.fillWidth: true }
                            }
                            QQC2.Button {
                                visible: modelData.cmd !== ""
                                text: root.t("Open", "Відкрити")
                                onClicked: run.connectSource(modelData.cmd)
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                // 4. Tips
                ColumnLayout {
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Heading { text: root.t("You're all set", "Усе готово"); level: 2 }
                    Repeater {
                        model: [
                            ["Super + E", root.t("Files", "Файли")],
                            ["Super + I", root.t("Settings", "Налаштування")],
                            ["Ctrl + Shift + Esc", root.t("Task Manager", "Диспетчер завдань")],
                            ["Super + Shift + S", root.t("Screenshot of a part of the screen", "Знімок частини екрана")],
                            ["Super + Tab", root.t("All open windows", "Усі відкриті вікна")],
                            ["Super + A", root.t("Notifications and quick settings", "Сповіщення та швидкі налаштування")],
                            ["Super + R", root.t("Run a command", "Виконати команду")],
                            [root.t("Double-click a .exe", "Подвійний клік на .exe"),
                             root.t("Unknown programs run in a safe sandbox", "Невідомі програми запускаються в безпечній пісочниці")]
                        ]
                        delegate: RowLayout {
                            spacing: Kirigami.Units.gridUnit
                            QQC2.Label {
                                text: modelData[0]
                                font.weight: Font.DemiBold
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 11
                            }
                            QQC2.Label { text: modelData[1]; opacity: 0.8 }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            RowLayout {   // page dots + navigation
                Layout.fillWidth: true
                Row {
                    spacing: 8
                    Repeater {
                        model: 4
                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: Kirigami.Theme.highlightColor
                            opacity: index === root.page ? 1 : 0.3
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                QQC2.Button {
                    text: root.t("Back", "Назад")
                    visible: root.page > 0
                    onClicked: root.page--
                }
                QQC2.Button {
                    highlighted: true
                    text: root.page < 3 ? root.t("Next", "Далі") : root.t("Start using Fennek OS", "Почати роботу")
                    onClicked: root.page < 3 ? root.page++ : Qt.quit()
                }
            }
        }
    }
}
