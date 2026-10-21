// Fennek OS: the classic taskbar right-click menu. Search / Show task view / Show the desktop / Task Manager /
// Lock the taskbar / Taskbar settings, instead of Plasma's edit-mode oriented panel menu.
// Selected for panels in the Plasma shell defaults ([Panel][ContainmentActions], see build.sh).
#include <KPluginFactory>
#include <Plasma/Containment>
#include <Plasma/ContainmentActions>
#include <Plasma/Corona>
#include <QAction>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QIcon>
#include <QProcess>

namespace
{
void kwinShortcut(const QString &name)
{
    auto msg = QDBusMessage::createMethodCall(QStringLiteral("org.kde.kglobalaccel"), QStringLiteral("/component/kwin"),
                                              QStringLiteral("org.kde.kglobalaccel.Component"), QStringLiteral("invokeShortcut"));
    msg << name;
    QDBusConnection::sessionBus().asyncCall(msg);
}
}

class TaskbarMenu : public Plasma::ContainmentActions
{
    Q_OBJECT
public:
    TaskbarMenu(QObject *parent, const QVariantList &)
        : Plasma::ContainmentActions(parent)
    {
    }

    QList<QAction *> contextualActions() override
    {
        qDeleteAll(m_actions);
        m_actions.clear();
        auto add = [this](const char *icon, const QString &text, auto slot) {
            auto *a = new QAction(QIcon::fromTheme(QString::fromLatin1(icon)), text, this);
            connect(a, &QAction::triggered, this, slot);
            m_actions << a;
            return a;
        };
        auto separator = [this] {
            auto *a = new QAction(this);
            a->setSeparator(true);
            m_actions << a;
        };

        add("search", QStringLiteral("Search"), [] {
            QDBusConnection::sessionBus().asyncCall(QDBusMessage::createMethodCall(QStringLiteral("org.kde.krunner"), QStringLiteral("/App"),
                                                                                   QStringLiteral("org.kde.krunner.App"), QStringLiteral("display")));
        });
        add("view-grid", QStringLiteral("Show task view"), [] { kwinShortcut(QStringLiteral("Overview")); });
        add("user-desktop", QStringLiteral("Show the desktop"), [] { kwinShortcut(QStringLiteral("Show Desktop")); });
        separator();
        add("fennek-taskmanager", QStringLiteral("Task Manager"), [] { QProcess::startDetached(QStringLiteral("fennek-app"), {QStringLiteral("taskmanager")}); });
        separator();

        Plasma::Containment *c = containment();
        Plasma::Corona *corona = c ? c->corona() : nullptr;
        if (corona) {
            auto *lock = add("object-locked", QStringLiteral("Lock the taskbar"), [corona](bool locked) {
                corona->setImmutability(locked ? Plasma::Types::UserImmutable : Plasma::Types::Mutable);
            });
            lock->setCheckable(true);
            lock->setChecked(corona->immutability() != Plasma::Types::Mutable);
            lock->setEnabled(corona->immutability() != Plasma::Types::SystemImmutable);

            QAction *edit = corona->action(QStringLiteral("edit mode"));
            auto *settings = add("configure", QStringLiteral("Taskbar settings"), [edit] {
                if (edit)
                    edit->trigger();
            });
            settings->setEnabled(edit && corona->immutability() == Plasma::Types::Mutable);
        }
        return m_actions;
    }

private:
    QList<QAction *> m_actions;
};

K_PLUGIN_CLASS_WITH_JSON(TaskbarMenu, "taskbarmenu.json")

#include "taskbarmenu.moc"
