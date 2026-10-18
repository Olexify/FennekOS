// Fennek OS widget style ("Fennek"): Breeze as it is, plus one classic-desktop habit. The mouse wheel over a
// drop-down, number box or slider scrolls the page around it, unless you clicked into that control first.
// (Breeze's own behaviour changes the value of whatever happens to be under the pointer while scrolling.)
#include <QAbstractSlider>
#include <QAbstractSpinBox>
#include <QComboBox>
#include <QEvent>
#include <QProxyStyle>
#include <QStyleFactory>
#include <QStylePlugin>

class FennekStyle : public QProxyStyle
{
public:
    FennekStyle() : QProxyStyle(QStyleFactory::create(QStringLiteral("Breeze"))) { }

    void polish(QWidget *w) override
    {
        QProxyStyle::polish(w);
        if (qobject_cast<QComboBox *>(w) || qobject_cast<QAbstractSpinBox *>(w) || isValueSlider(w)) {
            if (w->focusPolicy() == Qt::WheelFocus)
                w->setFocusPolicy(Qt::StrongFocus);   // the wheel no longer gives them focus
            w->installEventFilter(this);
        }
    }
    void unpolish(QWidget *w) override
    {
        w->removeEventFilter(this);
        QProxyStyle::unpolish(w);
    }
    bool eventFilter(QObject *o, QEvent *e) override
    {
        // Not focused: hand the wheel to the parent (the page scrolls). Focused: the control changes as usual.
        if (e->type() == QEvent::Wheel && !static_cast<QWidget *>(o)->hasFocus()) {
            e->ignore();
            return true;
        }
        return QProxyStyle::eventFilter(o, e);
    }

private:
    // Scroll bars are sliders too, but they must keep scrolling.
    static bool isValueSlider(QWidget *w)
    {
        return qobject_cast<QAbstractSlider *>(w) && !w->inherits("QScrollBar") && !w->inherits("QDial");
    }
};

class FennekStylePlugin : public QStylePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QStyleFactoryInterface" FILE "fennekstyle.json")
public:
    QStyle *create(const QString &key) override
    {
        return key.compare(QLatin1String("Fennek"), Qt::CaseInsensitive) == 0 ? new FennekStyle : nullptr;
    }
};

#include "fennekstyle.moc"
