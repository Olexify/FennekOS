#include "kcmview.h"
#include <KPluginMetaData>
#include <QQmlEngine>
#include <QRegularExpression>
#include <kquickconfigmodule.h>
#include <kquickconfigmoduleloader.h>

std::shared_ptr<QQmlEngine> KcmView::engine;

static KPluginMetaData findPage(const QString &id)
{
    for (const auto dir : {"plasma/kcms/systemsettings", "plasma/kcms/systemsettings_qwidgets", "plasma/kcms"}) {
        const KPluginMetaData md = KPluginMetaData::findPluginById(QString::fromLatin1(dir), id);
        if (md.isValid())
            return md;
    }
    return {};
}

KcmView::KcmView(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, false);
    // Saved a moment after the last change (typing a name or dragging a slider saves once, at the end).
    m_saveSoon.setSingleShot(true);
    m_saveSoon.setInterval(700);
    connect(&m_saveSoon, &QTimer::timeout, this, &KcmView::saveNow);
}

KcmView::~KcmView()
{
    unload();
}

void KcmView::saveNow()
{
    if (m_module && m_module->needsSave())
        m_module->save();
}

void KcmView::unload()
{
    if (!m_module)
        return;
    saveNow();   // the last change, if its moment hadn't come yet
    if (m_shown)
        m_shown->setVisible(false);
    m_module->deleteLater();
    m_module = nullptr;
    m_shown = nullptr;
}

void KcmView::setKcm(const QString &id)
{
    if (id == m_kcm)
        return;
    unload();
    m_kcm = id;
    m_title.clear();
    m_failed = false;
    if (!id.isEmpty()) {
        const KPluginMetaData md = QRegularExpression(QStringLiteral("^kcm_[a-z0-9_-]+$")).match(id).hasMatch() ? findPage(id) : KPluginMetaData();
        auto result = md.isValid() ? KQuickConfigModuleLoader::loadModule(md, this, {}, engine) : KPluginFactory::Result<KQuickConfigModule>();
        if (result && result.plugin->mainUi()) {
            m_module = result.plugin;
            m_title = md.name();
            m_module->load();
            connect(m_module, &KQuickConfigModule::needsSaveChanged, this, [this] {
                if (m_module && m_module->needsSave())
                    m_saveSoon.start();
            });
            connect(m_module, &KQuickConfigModule::depthChanged, this, [this] {
                showTop();
                Q_EMIT depthChanged();
            });
            showTop();
        } else {
            if (result.plugin)
                result.plugin->deleteLater();
            m_failed = true;   // a widget page (or missing): the caller opens it in its own window
            qWarning("KcmView: %s can't be shown inside (%s)", qPrintable(id), qPrintable(result.errorString));
        }
    }
    Q_EMIT kcmChanged();
    Q_EMIT depthChanged();
}

bool KcmView::has(const QString &id) const
{
    return findPage(id).isValid();
}

QString KcmView::keywords(const QString &id) const
{
    const KPluginMetaData md = findPage(id);
    return md.isValid() ? md.description() + QLatin1Char(' ') + md.value(QStringLiteral("X-KDE-Keywords")) : QString();
}

int KcmView::depth() const
{
    return m_module ? m_module->depth() : 0;
}

void KcmView::back()
{
    if (m_module && m_module->depth() > 1)
        m_module->pop();
}

// The deepest open page is the one shown; the ones below wait hidden.
void KcmView::showTop()
{
    if (!m_module)
        return;
    const int d = m_module->depth();
    QQuickItem *top = d <= 1 ? m_module->mainUi() : m_module->subPage(d - 2);
    if (!top || top == m_shown)
        return;
    if (m_shown)
        m_shown->setVisible(false);
    m_shown = top;
    top->setParentItem(this);
    top->setPosition({0, 0});
    top->setSize(size());
    top->setVisible(true);
}

void KcmView::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    if (m_shown)
        m_shown->setSize(newGeometry.size());
}
