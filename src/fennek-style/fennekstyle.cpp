// Fennek OS widget style ("Fennek"): Breeze as it is, plus one classic-desktop habit. The mouse wheel over a
// drop-down, number box or slider scrolls the page around it, unless you clicked into that control first.
// (Breeze's own behaviour changes the value of whatever happens to be under the pointer while scrolling.)
// And: an Apply button with changes waiting is filled with the accent colour and pulses twice when it becomes
// available, so nobody misses that a setting still has to be applied.
// Files: no focus box on the first item when a folder opens (only once you move with the keyboard), and the back /
// forward / up buttons without the tiny history arrow under them (hold or right-click still shows the history).
#include <QAbstractSlider>
#include <QDialogButtonBox>
#include <QPushButton>
#include <QVariantAnimation>
#include <QAbstractSpinBox>
#include <QApplication>
#include <QComboBox>
#include <QEvent>
#include <QProxyStyle>
#include <QStyleFactory>
#include <QStylePlugin>
#include <QKeyEvent>
#include <QStyleOption>

// Whether the last thing you did was moving with the keyboard (arrows, Tab...) or a click.
class KeyNavWatcher : public QObject
{
public:
    static bool keyboard;
    bool eventFilter(QObject *, QEvent *e) override
    {
        if (e->type() == QEvent::KeyPress) {
            switch (static_cast<QKeyEvent *>(e)->key()) {
            case Qt::Key_Left: case Qt::Key_Right: case Qt::Key_Up: case Qt::Key_Down: case Qt::Key_Tab: case Qt::Key_Backtab:
            case Qt::Key_Home: case Qt::Key_End: case Qt::Key_PageUp: case Qt::Key_PageDown:
                keyboard = true;
                break;
            default:
                break;
            }
        } else if (e->type() == QEvent::MouseButtonPress) {
            keyboard = false;
        }
        return false;
    }
};
bool KeyNavWatcher::keyboard = false;

class FennekStyle : public QProxyStyle
{
public:
    FennekStyle() : QProxyStyle(QStyleFactory::create(QStringLiteral("Breeze"))) { }

    void polish(QWidget *w) override
    {
        QProxyStyle::polish(w);
        if (isApplyButton(w)) {
            w->installEventFilter(this);
            showApply(static_cast<QPushButton *>(w), false);
        }
        if (qobject_cast<QComboBox *>(w) || qobject_cast<QAbstractSpinBox *>(w) || isValueSlider(w)) {
            if (w->focusPolicy() == Qt::WheelFocus)
                w->setFocusPolicy(Qt::StrongFocus);   // the wheel no longer gives them focus
            w->installEventFilter(this);
        }
    }
    void polish(QApplication *app) override
    {
        QProxyStyle::polish(app);
        static KeyNavWatcher *watcher = nullptr;
        if (!watcher) {
            watcher = new KeyNavWatcher;
            app->installEventFilter(watcher);
        }
    }
    void drawPrimitive(PrimitiveElement pe, const QStyleOption *opt, QPainter *p, const QWidget *w) const override
    {
        if (inFileView(w) && !KeyNavWatcher::keyboard && opt && !(opt->state & State_Selected)) {
            if (pe == PE_FrameFocusRect)
                return;   // the "current" item: no box until you use the keyboard
            if (pe == PE_PanelItemViewItem && (opt->state & State_HasFocus) && !(opt->state & State_MouseOver)) {
                if (const auto *v = qstyleoption_cast<const QStyleOptionViewItem *>(opt)) {
                    QStyleOptionViewItem o(*v);
                    o.state &= ~State_HasFocus;
                    QProxyStyle::drawPrimitive(pe, &o, p, w);
                    return;
                }
            }
        }
        QProxyStyle::drawPrimitive(pe, opt, p, w);
    }
    void drawComplexControl(ComplexControl cc, const QStyleOptionComplex *opt, QPainter *p, const QWidget *w) const override
    {
        if (cc == CC_ToolButton) {
            if (const auto *t = qstyleoption_cast<const QStyleOptionToolButton *>(opt)) {
                QStyleOptionToolButton o(*t);
                o.features &= ~QStyleOptionToolButton::PopupDelay;   // back / forward: no tiny arrow
                QProxyStyle::drawComplexControl(cc, &o, p, w);
                return;
            }
        }
        QProxyStyle::drawComplexControl(cc, opt, p, w);
    }
    QSize sizeFromContents(ContentsType ct, const QStyleOption *opt, const QSize &size, const QWidget *w) const override
    {
        if (ct == CT_ToolButton) {
            if (const auto *t = qstyleoption_cast<const QStyleOptionToolButton *>(opt)) {
                QStyleOptionToolButton o(*t);
                o.features &= ~QStyleOptionToolButton::PopupDelay;
                return QProxyStyle::sizeFromContents(ct, &o, size, w);
            }
        }
        return QProxyStyle::sizeFromContents(ct, opt, size, w);
    }
    void unpolish(QWidget *w) override
    {
        w->removeEventFilter(this);
        QProxyStyle::unpolish(w);
    }
    bool eventFilter(QObject *o, QEvent *e) override
    {
        if (e->type() == QEvent::EnabledChange && isApplyButton(static_cast<QWidget *>(o))) {
            auto *b = static_cast<QPushButton *>(o);
            showApply(b, b->isEnabled());
            return false;
        }
        // Not focused: hand the wheel to the parent (the page scrolls). Focused: the control changes as usual.
        if (e->type() == QEvent::Wheel && !static_cast<QWidget *>(o)->hasFocus()) {
            e->ignore();
            return true;
        }
        return QProxyStyle::eventFilter(o, e);
    }

private:
    // Files' file view (its items are painted on a graphics view inside KItemListContainer).
    static bool inFileView(const QWidget *w)
    {
        for (int i = 0; w && i < 3; ++i, w = w->parentWidget())
            if (w->inherits("KItemListContainer"))
                return true;
        return false;
    }
    static bool isApplyButton(QWidget *w)
    {
        auto *b = qobject_cast<QPushButton *>(w);
        auto *box = b ? qobject_cast<QDialogButtonBox *>(b->parentWidget()) : nullptr;
        return box && box->buttonRole(b) == QDialogButtonBox::ApplyRole;
    }
    // Enabled: accent fill (+ two soft pulses when it just became available). Disabled: the plain button.
    static void showApply(QPushButton *b, bool pulse)
    {
        if (!b->isEnabled()) {
            b->setPalette(QPalette());
            b->setFont(QFont());
            return;
        }
        QFont f = b->font();
        f.setWeight(QFont::DemiBold);
        b->setFont(f);
        const QColor accent = QApplication::palette().color(QPalette::Highlight);
        const auto paint = [b, accent](const QColor &c) {
            QPalette p = b->palette();
            p.setColor(QPalette::Button, c);
            p.setColor(QPalette::ButtonText, QApplication::palette().color(QPalette::HighlightedText));
            b->setPalette(p);
        };
        paint(accent);
        if (!pulse)
            return;
        auto *a = new QVariantAnimation(b);
        a->setStartValue(accent.lighter(150));
        a->setEndValue(accent);
        a->setDuration(450);
        a->setLoopCount(2);
        a->setEasingCurve(QEasingCurve::OutCubic);
        QObject::connect(a, &QVariantAnimation::valueChanged, b, [paint](const QVariant &v) { paint(v.value<QColor>()); });
        a->start(QAbstractAnimation::DeleteWhenStopped);
    }

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
