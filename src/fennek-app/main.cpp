// fennek-app NAME: runs one of Fennek's own apps (Settings, Firewall, Welcome, App history) as a normal window:
// system look (light or dark like other apps), its own icon in the taskbar, its own size.
// The apps are QML files in /usr/share/fennek/apps/NAME/main.qml. They can show KDE settings pages inside
// (import Fennek; KcmView), saved without Apply. A page with no window of its own (Updates, Firewall, Quarantine,
// Backup, App history: only Page.qml) opens in Settings: fennek-app firewall = fennek-app settings firewall.
// One window per app: opened again, the open one comes forward and gets the new arguments (openArguments in its QML).
#include "kcmview.h"
#include <KDBusService>
#include <KWindowSystem>
#include <QApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QFile>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QRegularExpression>
#include <QTimer>
#include <QWindow>

int main(int argc, char *argv[])
{
    QString name = argc > 1 ? QString::fromLocal8Bit(argv[1]) : QString();
    if (!QRegularExpression(QStringLiteral("^[a-z]+$")).match(name).hasMatch()) {   // a name, never a path
        qWarning("usage: fennek-app settings|firewall|welcome|apphistory");
        return 2;
    }
    const QString dir = QStringLiteral("/usr/share/fennek/apps/%1/").arg(name);
    QByteArray settingsArg("settings"), pageArg = name.toLatin1();
    char *redirected[] = {argv[0], settingsArg.data(), pageArg.data(), nullptr};
    if (!QFile::exists(dir + QStringLiteral("main.qml")) && QFile::exists(dir + QStringLiteral("Page.qml"))) {
        argc = 3;   // a page of Settings: Settings, opened on it
        argv = redirected;
        name = QStringLiteral("settings");
    }
    QApplication app(argc, argv);
    const QString id = QStringLiteral("fennek-") + name;   // = the app's .desktop file: taskbar icon + grouping
    app.setApplicationName(id);
    app.setDesktopFileName(id);
    app.setWindowIcon(QIcon::fromTheme(id, QIcon::fromTheme(QStringLiteral("fennek"))));
    KDBusService service(KDBusService::Unique | KDBusService::NoExitOnFailure);   // already open: hands over and ends here
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));

    qmlRegisterType<KcmView>("Fennek", 1, 0, "KcmView");
    auto engine = std::make_shared<QQmlApplicationEngine>();
    KcmView::engine = engine;   // settings pages are built in the same engine as the window showing them
    engine->load(QUrl::fromLocalFile(QStringLiteral("/usr/share/fennek/apps/%1/main.qml").arg(name)));
    if (engine->rootObjects().isEmpty())
        return 1;
    QObject::connect(&service, &KDBusService::activateRequested, &app, [engine](const QStringList &args) {
        QObject *root = engine->rootObjects().constFirst();
        if (root->metaObject()->indexOfMethod("openArguments(QVariant)") >= 0)
            QMetaObject::invokeMethod(root, "openArguments", Q_ARG(QVariant, QVariant(args)));
        if (auto *window = qobject_cast<QWindow *>(root)) {
            KWindowSystem::updateStartupId(window);
            KWindowSystem::activateWindow(window);
            // Without a token from whoever opened it, that only flashes in the taskbar: KWin's part in fennekarrows.
            QTimer::singleShot(200, [] {
                auto call = QDBusMessage::createMethodCall(QStringLiteral("org.kde.kglobalaccel"), QStringLiteral("/component/kwin"),
                                                           QStringLiteral("org.kde.kglobalaccel.Component"), QStringLiteral("invokeShortcut"));
                call << QStringLiteral("Fennek Bring Forward");
                QDBusConnection::sessionBus().asyncCall(call);
            });
        }
    });
    const int code = app.exec();
    KcmView::engine.reset();
    return code;
}
