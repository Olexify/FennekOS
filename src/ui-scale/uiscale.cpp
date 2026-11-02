// Fennek OS: Ctrl + mouse wheel over the empty desktop makes everything bigger or smaller (the display scale, in
// 25% steps). Inside apps Ctrl + wheel stays theirs (zoom). Bound for the desktop in the Plasma shell defaults
// ([Desktop][ContainmentActions] wheel:Vertical;ControlModifier, see build.sh); the work is /usr/libexec/fennek-ui-scale.
#include <KPluginFactory>
#include <Plasma/ContainmentActions>
#include <QProcess>

class UiScale : public Plasma::ContainmentActions
{
    Q_OBJECT
public:
    // Passes the plugin's metadata on: the desktop's Mouse Actions settings page loads a copy of the plugin by its id.
    UiScale(QObject *parent, const QVariantList &args)
        : Plasma::ContainmentActions(parent, args)
    {
    }
    // Wheel up = bigger, wheel down = smaller.
    void performPreviousAction() override { step(QStringLiteral("up")); }
    void performNextAction() override { step(QStringLiteral("down")); }

private:
    static void step(const QString &direction)
    {
        QProcess::startDetached(QStringLiteral("/usr/libexec/fennek-ui-scale"), {direction});
    }
};

K_PLUGIN_CLASS_WITH_JSON(UiScale, "uiscale.json")

#include "uiscale.moc"
