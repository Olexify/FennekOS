// Fennek OS: the classic desktop right-click menu. View / Refresh / Paste / Undo / New / Open Terminal /
// Display settings / Personalize / Edit desktop, instead of Plasma's edit-mode oriented desktop menu.
// Selected for the desktop in the Plasma shell defaults ([Desktop][ContainmentActions], see build.sh).
#include <KPluginFactory>
#include <KTerminalLauncherJob>
#include <Plasma/Containment>
#include <Plasma/ContainmentActions>
#include <Plasma/Corona>
#include <QAction>
#include <QDir>
#include <QIcon>
#include <QMenu>
#include <QMetaObject>
#include <QPointer>
#include <QProcess>
#include <QtAlgorithms>

namespace
{
void openSettings(const QString &page)
{
    QProcess::startDetached(QStringLiteral("fennek-app"), {QStringLiteral("settings"), page});
}
}

class DesktopMenu : public Plasma::ContainmentActions
{
    Q_OBJECT
public:
    // Passes the plugin's metadata on: the desktop's Mouse Actions settings page loads a copy of the plugin by its id.
    DesktopMenu(QObject *parent, const QVariantList &args)
        : Plasma::ContainmentActions(parent, args)
    {
    }

    QList<QAction *> contextualActions() override
    {
        qDeleteAll(m_actions);   // only our own: Folder View's actions stay Folder View's
        m_actions.clear();
        QList<QAction *> items;
        auto add = [this, &items](const char *icon, const QString &text, auto slot) {
            auto *a = new QAction(QIcon::fromTheme(QString::fromLatin1(icon)), text, this);
            connect(a, &QAction::triggered, this, slot);
            m_actions << a;
            items << a;
            return a;
        };
        auto separator = [this, &items] {
            auto *a = new QAction(this);
            a->setSeparator(true);
            m_actions << a;
            items << a;
        };

        // Folder View's actions (none if the desktop isn't a Folder View), told apart by object name, never by their
        // translated text. Its Icons action has no name: it's the one with a submenu that isn't New.
        Plasma::Containment *c = containment();
        QAction *view = nullptr, *paste = nullptr, *undo = nullptr, *newMenu = nullptr;
        QList<QAction *> others;
        const QList<QAction *> folderView = c ? c->contextualActions() : QList<QAction *>();
        for (QAction *a : folderView) {
            if (!a || a->isSeparator())
                continue;
            const QString name = a->objectName();
            if (name == QLatin1String("paste"))
                paste = a;
            else if (name == QLatin1String("undo"))
                undo = a;
            else if (name == QLatin1String("newMenu"))
                newMenu = a;
            else if (!view && a->menu())
                view = a;
            else
                others << a;
        }

        if (view) {
            view->setText(QStringLiteral("View"));
            items << view;
        }
        // Plasma took Refresh off its menus on purpose (only F5 is left), but people look for it here. It runs Folder
        // View's own refresh, the same as F5; Folder View's folder model is the parent of its actions.
        QObject *model = paste ? paste->parent() : nullptr;
        if (model && model->metaObject()->indexOfMethod("refresh()") >= 0)
            add("view-refresh", QStringLiteral("Refresh"), [model = QPointer<QObject>(model)] { QMetaObject::invokeMethod(model.data(), "refresh"); });
        if (paste)
            items << paste;
        if (undo)
            items << undo;
        if (newMenu) {
            newMenu->setText(QStringLiteral("New"));
            items << newMenu;
        }
        items << others;   // what this menu doesn't know yet (and Empty Trash, shown only for the trash folder)
        if (!items.isEmpty())
            separator();

        add("utilities-terminal-symbolic", QStringLiteral("Open Terminal"), [] {
            auto *job = new KTerminalLauncherJob(QString());
            job->setWorkingDirectory(QDir::homePath());
            job->start();
        });
        separator();

        add("preferences-desktop-display", QStringLiteral("Display settings"), [] { openSettings(QStringLiteral("kcm_kscreen")); });
        add("preferences-desktop-wallpaper", QStringLiteral("Personalize"), [] { openSettings(QStringLiteral("personalize")); });
        Plasma::Corona *corona = c ? c->corona() : nullptr;
        if (corona) {
            QAction *edit = corona->action(QStringLiteral("edit mode"));
            auto *a = add("document-edit", QStringLiteral("Edit desktop…"), [edit] {
                if (edit)
                    edit->trigger();
            });
            a->setEnabled(edit && corona->immutability() == Plasma::Types::Mutable);
        }
        return items;
    }

private:
    QList<QAction *> m_actions;
};

K_PLUGIN_CLASS_WITH_JSON(DesktopMenu, "desktopmenu.json")

#include "desktopmenu.moc"
