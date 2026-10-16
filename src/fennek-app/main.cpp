// fennek-app NAME: runs one of Fennek's own apps (Settings, Firewall, Welcome, App history) as a normal window:
// system look (light or dark like other apps), its own icon in the taskbar, its own size.
// The apps are QML files in /usr/share/fennek/apps/NAME/main.qml.
#include <QApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QRegularExpression>

int main(int argc, char *argv[])
{
    const QString name = argc > 1 ? QString::fromLocal8Bit(argv[1]) : QString();
    if (!QRegularExpression(QStringLiteral("^[a-z]+$")).match(name).hasMatch()) {   // a name, never a path
        qWarning("usage: fennek-app settings|firewall|welcome|apphistory");
        return 2;
    }
    QApplication app(argc, argv);
    const QString id = QStringLiteral("fennek-") + name;   // = the app's .desktop file: taskbar icon + grouping
    app.setApplicationName(id);
    app.setDesktopFileName(id);
    app.setWindowIcon(QIcon::fromTheme(id, QIcon::fromTheme(QStringLiteral("fennek"))));
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));

    QQmlApplicationEngine engine;
    engine.load(QUrl::fromLocalFile(QStringLiteral("/usr/share/fennek/apps/%1/main.qml").arg(name)));
    if (engine.rootObjects().isEmpty())
        return 1;
    return app.exec();
}
