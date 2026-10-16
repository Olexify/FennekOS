// Fennek OS: "This PC" for Files (thispc:/). Your main folders, then your drives with free space, like the
// classic This PC page. Entries are links: opening one goes to the real folder or drive.
// Grouping ("Folders" / "Storage drives") comes from the two MIME types in fennek-thispc.xml and the
// view settings Files keeps for non-local places (see build.sh).
#include <KIO/WorkerBase>
#include <QCoreApplication>
#include <QDir>
#include <QLocale>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QUrl>
#include <optional>
#include <sys/stat.h>

namespace
{
struct Item {
    QString key, label, icon, mime, target;
};

QList<Item> items()
{
    QList<Item> out;
    const QString home = QDir::homePath();
    const struct {
        QStandardPaths::StandardLocation where;
        const char *icon;
    } folders[] = {{QStandardPaths::DesktopLocation, "user-desktop"},     {QStandardPaths::DocumentsLocation, "folder-documents"},
                   {QStandardPaths::DownloadLocation, "folder-download"}, {QStandardPaths::MusicLocation, "folder-music"},
                   {QStandardPaths::PicturesLocation, "folder-pictures"}, {QStandardPaths::MoviesLocation, "folder-videos"}};
    for (const auto &f : folders) {
        const QString path = QStandardPaths::writableLocation(f.where);
        if (path.isEmpty() || path == home || !QDir(path).exists())
            continue;
        const QString name = QDir(path).dirName(); // already in the user's language (xdg-user-dirs)
        out.append({name, name, QString::fromLatin1(f.icon), QStringLiteral("inode/x-fennek-folder"), path});
    }

    const QLocale locale;
    const auto describe = [&](const QString &label, const QStorageInfo &s) {
        return QStringLiteral("%1 (%2 free of %3)").arg(label, locale.formattedDataSize(s.bytesAvailable()), locale.formattedDataSize(s.bytesTotal()));
    };
    // The disk your files live on, then every other mounted drive (USB sticks, second disks, partitions).
    const QStorageInfo mine(home);
    out.append({QStringLiteral("local-disk"), describe(QStringLiteral("Local Disk"), mine), QStringLiteral("drive-harddisk"),
                QStringLiteral("inode/x-fennek-drive"), home});
    int n = 0;
    const auto volumes = QStorageInfo::mountedVolumes();
    for (const QStorageInfo &s : volumes) {
        const QString root = s.rootPath();
        if (!s.isValid() || !s.isReady() || s.device() == mine.device()
            || !(root.startsWith(QLatin1String("/run/media/")) || root.startsWith(QLatin1String("/media/")) || root.startsWith(QLatin1String("/mnt/"))))
            continue;
        const QString label = s.name().isEmpty() ? QDir(root).dirName() : s.name();
        const bool removable = root.startsWith(QLatin1String("/run/media/"));
        out.append({QStringLiteral("drive-%1").arg(++n), describe(label, s), QLatin1String(removable ? "drive-removable-media" : "drive-harddisk"),
                    QStringLiteral("inode/x-fennek-drive"), root});
    }
    return out;
}

KIO::UDSEntry entry(const Item &i)
{
    KIO::UDSEntry e;
    e.fastInsert(KIO::UDSEntry::UDS_NAME, i.key);
    e.fastInsert(KIO::UDSEntry::UDS_DISPLAY_NAME, i.label);
    e.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, S_IFDIR);
    e.fastInsert(KIO::UDSEntry::UDS_ACCESS, 0500);
    e.fastInsert(KIO::UDSEntry::UDS_ICON_NAME, i.icon);
    e.fastInsert(KIO::UDSEntry::UDS_MIME_TYPE, i.mime);
    e.fastInsert(KIO::UDSEntry::UDS_TARGET_URL, QUrl::fromLocalFile(i.target).toString());
    e.fastInsert(KIO::UDSEntry::UDS_LOCAL_PATH, i.target);
    return e;
}

KIO::UDSEntry rootEntry()
{
    KIO::UDSEntry e;
    e.fastInsert(KIO::UDSEntry::UDS_NAME, QStringLiteral("."));
    e.fastInsert(KIO::UDSEntry::UDS_DISPLAY_NAME, QStringLiteral("This PC"));
    e.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, S_IFDIR);
    e.fastInsert(KIO::UDSEntry::UDS_ACCESS, 0500);
    e.fastInsert(KIO::UDSEntry::UDS_ICON_NAME, QStringLiteral("computer"));
    e.fastInsert(KIO::UDSEntry::UDS_MIME_TYPE, QStringLiteral("inode/directory"));
    return e;
}

// thispc:/<key>[/rest] -> the real folder, or nothing.
std::optional<QUrl> resolve(const QUrl &url)
{
    const QString path = url.path().mid(1);
    const QString key = path.section(QLatin1Char('/'), 0, 0);
    const auto all = items();
    for (const Item &i : all) {
        if (i.key == key) {
            QUrl target = QUrl::fromLocalFile(i.target);
            const QString rest = path.section(QLatin1Char('/'), 1);
            if (!rest.isEmpty())
                target.setPath(target.path() + QLatin1Char('/') + rest);
            return target;
        }
    }
    return std::nullopt;
}
}

class ThisPC : public KIO::WorkerBase
{
public:
    ThisPC(const QByteArray &pool, const QByteArray &app)
        : KIO::WorkerBase("thispc", pool, app)
    {
    }

    KIO::WorkerResult listDir(const QUrl &url) override
    {
        if (url.path().length() > 1) { // inside a folder or drive: hand over to the real place
            if (const auto target = resolve(url)) {
                redirection(*target);
                return KIO::WorkerResult::pass();
            }
            return KIO::WorkerResult::fail(KIO::ERR_DOES_NOT_EXIST, url.toDisplayString());
        }
        const auto all = items();
        for (const Item &i : all)
            listEntry(entry(i));
        listEntry(rootEntry());
        return KIO::WorkerResult::pass();
    }

    KIO::WorkerResult stat(const QUrl &url) override
    {
        if (url.path().length() <= 1) {
            statEntry(rootEntry());
            return KIO::WorkerResult::pass();
        }
        if (const auto target = resolve(url)) {
            redirection(*target);
            return KIO::WorkerResult::pass();
        }
        return KIO::WorkerResult::fail(KIO::ERR_DOES_NOT_EXIST, url.toDisplayString());
    }
};

// Pseudo plugin class to embed the protocol metadata.
class KIOPluginForMetaData : public QObject
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.kde.kio.worker.thispc" FILE "thispc.json")
};

extern "C" Q_DECL_EXPORT int kdemain(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("kio_thispc"));
    if (argc != 4)
        return 1;
    ThisPC worker(argv[2], argv[3]);
    worker.dispatchLoop();
    return 0;
}

#include "thispc.moc"
