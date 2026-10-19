// KcmView: one KDE settings page (kcm_mouse, kcm_nightlight...) inside a Fennek window, without Apply: a change is
// saved by itself a moment after you make it. Sub-pages the page opens stack up; back() returns. Pages built the
// old way (widgets, not QML) can't be shown inside: then `failed` is set and the caller opens them in fennek-kcm.
#pragma once
#include <QPointer>
#include <QQuickItem>
#include <QTimer>
#include <memory>

class KQuickConfigModule;
class QQmlEngine;

class KcmView : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QString kcm READ kcm WRITE setKcm NOTIFY kcmChanged)
    Q_PROPERTY(QString title READ title NOTIFY kcmChanged)
    Q_PROPERTY(bool failed READ failed NOTIFY kcmChanged)
    Q_PROPERTY(int depth READ depth NOTIFY depthChanged)
public:
    explicit KcmView(QQuickItem *parent = nullptr);
    ~KcmView() override;

    static std::shared_ptr<QQmlEngine> engine;   // the app's engine: the page's QML lives in it

    QString kcm() const { return m_kcm; }
    void setKcm(const QString &id);
    QString title() const { return m_title; }
    bool failed() const { return m_failed; }
    int depth() const;
    Q_INVOKABLE void back();
    Q_INVOKABLE void saveNow();
    Q_INVOKABLE bool has(const QString &id) const;   // is this settings page installed?

Q_SIGNALS:
    void kcmChanged();
    void depthChanged();

protected:
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    void unload();
    void showTop();
    QString m_kcm, m_title;
    bool m_failed = false;
    QPointer<KQuickConfigModule> m_module;
    QPointer<QQuickItem> m_shown;
    QTimer m_saveSoon;
};
