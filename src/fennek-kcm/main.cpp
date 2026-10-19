// fennek-kcm ID: one KDE settings page (kcm_mouse, kcm_nightlight...) in its own window, without Apply: a change
// is saved by itself a moment after you make it, like the classic settings (the mouse wheel never changes a value in
// Fennek OS, so nothing changes by accident). Fennek Settings opens its pages through this; "All settings
// (advanced)" keeps KDE's full window with its Apply button.
#include <KCModule>
#include <KCModuleLoader>
#include <KPluginMetaData>
#include <QApplication>
#include <QCloseEvent>
#include <QIcon>
#include <QRegularExpression>
#include <QTimer>
#include <QVBoxLayout>
#include <QWidget>

namespace {
KPluginMetaData find(const QString &id)
{
    for (const auto dir : {"plasma/kcms/systemsettings", "plasma/kcms/systemsettings_qwidgets", "plasma/kcms"}) {
        const KPluginMetaData md = KPluginMetaData::findPluginById(QString::fromLatin1(dir), id);
        if (md.isValid())
            return md;
    }
    return {};
}

class Window : public QWidget
{
public:
    KCModule *module = nullptr;

protected:
    void closeEvent(QCloseEvent *e) override
    {
        if (module && module->needsSave())   // the last change, if its moment hadn't come yet
            module->save();
        e->accept();
    }
};
}

int main(int argc, char *argv[])
{
    const QString id = argc > 1 ? QString::fromLocal8Bit(argv[1]) : QString();
    if (!QRegularExpression(QStringLiteral("^kcm_[a-z0-9_-]+$")).match(id).hasMatch()) {   // a page id, never a path
        qWarning("usage: fennek-kcm kcm_NAME");
        return 2;
    }
    QApplication app(argc, argv);
    const KPluginMetaData md = find(id);
    if (!md.isValid()) {
        qWarning("fennek-kcm: no settings page %s", qPrintable(id));
        return 3;
    }
    app.setApplicationName(QStringLiteral("fennek-settings"));
    app.setDesktopFileName(QStringLiteral("fennek-settings"));   // grouped with Settings on the taskbar
    app.setWindowIcon(QIcon::fromTheme(md.iconName(), QIcon::fromTheme(QStringLiteral("fennek-settings"))));

    Window win;
    win.setWindowTitle(md.name());
    auto *layout = new QVBoxLayout(&win);
    layout->setContentsMargins(0, 0, 0, 0);
    KCModule *kcm = KCModuleLoader::loadModule(md, &win);
    win.module = kcm;
    layout->addWidget(kcm->widget());
    kcm->load();

    // Saved a moment after the last change (typing a name or dragging a slider saves once, at the end).
    QTimer saveSoon;
    saveSoon.setSingleShot(true);
    saveSoon.setInterval(700);
    QObject::connect(&saveSoon, &QTimer::timeout, kcm, [kcm] {
        if (kcm->needsSave())
            kcm->save();
    });
    QObject::connect(kcm, &KCModule::needsSaveChanged, &saveSoon, [kcm, &saveSoon] {
        if (kcm->needsSave())
            saveSoon.start();
    });

    win.resize(900, 680);
    win.show();
    return app.exec();
}
