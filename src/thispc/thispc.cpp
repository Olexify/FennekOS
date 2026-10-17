// Fennek OS: "This PC" for Files (thispc:/), the page Files opens on. Your main folders and the ones you pinned
// to the sidebar, the folders you use most, then your drives with free space, like the classic This PC page.
// Entries are links: opening one goes to the real folder or drive.
// Grouping ("Folders" / "Frequent folders" / "Storage drives") comes from the MIME types in fennek-thispc.xml.
#include <KIO/WorkerBase>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QXmlStreamReader>
#include <algorithm>
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

// Local folders behind the file:// entries of an XBEL file (sidebar places, recently used files).
// For recently used files: the folder of each file, weighted by how often it was opened.
QHash<QString, int> xbelFolders(const QString &file, bool parentsOfFiles)
{
    QHash<QString, int> out;
    QFile f(file);
    if (!f.open(QIODevice::ReadOnly))
        return out;
    QXmlStreamReader x(&f);
    QString current;
    while (!x.atEnd()) {
        if (x.readNext() != QXmlStreamReader::StartElement)
            continue;
        if (x.name() == QLatin1String("bookmark")) {
            const QUrl u(x.attributes().value(QLatin1String("href")).toString());
            current = u.isLocalFile() ? u.toLocalFile() : QString();
            if (parentsOfFiles && !current.isEmpty())
                current = QFileInfo(current).absolutePath();
            if (!current.isEmpty())
                out[current] += 1;
        } else if (parentsOfFiles && x.name() == QLatin1String("application") && !current.isEmpty()) {
            out[current] += qMax(0, x.attributes().value(QLatin1String("count")).toInt() - 1);   // opened N times
        }
    }
    return out;
}

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
    QStringList shown{home};
    for (const Item &i : std::as_const(out))
        shown << i.target;

    // Folders you pinned to the sidebar join them.
    const QString data = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    int n = 0;
    // Stable order (alphabetical): an entry's key must name the same folder each time the page is read.
    QStringList pinned = xbelFolders(data + QStringLiteral("/user-places.xbel"), false).keys();
    pinned.sort();
    for (const QString &p : std::as_const(pinned)) {
        if (shown.contains(p) || !QFileInfo(p).isDir())
            continue;
        out.append({QStringLiteral("pin-%1").arg(++n), QDir(p).dirName(), QStringLiteral("folder"), QStringLiteral("inode/x-fennek-folder"), p});
        shown << p;
    }

    // Frequent folders: where the files you open live (recently used files, weighted by use). Up to six.
    const auto used = xbelFolders(data + QStringLiteral("/recently-used.xbel"), true);
    QList<QPair<int, QString>> ranked;
    for (auto it = used.cbegin(); it != used.cend(); ++it) {
        const QString &p = it.key();
        if (shown.contains(p) || p.contains(QLatin1String("/.")) || !p.startsWith(home + QLatin1Char('/')) || !QFileInfo(p).isDir())
            continue;
        ranked.append({it.value(), p});
    }
    std::sort(ranked.begin(), ranked.end(), [](const auto &a, const auto &b) {   // most used first; ties by path (stable)
        return a.first != b.first ? a.first > b.first : a.second < b.second;
    });
    n = 0;
    for (const auto &r : std::as_const(ranked)) {
        if (n == 6)
            break;
        out.append({QStringLiteral("frequent-%1").arg(++n), QDir(r.second).dirName(), QStringLiteral("folder"),
                    QStringLiteral("inode/x-fennek-frequent"), r.second});
    }

    const QLocale locale;
    const auto describe = [&](const QString &label, const QStorageInfo &s) {
        // "Local Disk · 50.4 GB free": short enough for the icon view (one decimal, GB, base 1024).
        const auto size = [&](qint64 b) { return locale.formattedDataSize(b, 1, QLocale::DataSizeTraditionalFormat); };
        return QStringLiteral("%1 · %2 free").arg(label, size(s.bytesAvailable()));
    };
    // The disk your files live on, then every other mounted drive (USB sticks, second disks, partitions).
    const QStorageInfo mine(home);
    out.append({QStringLiteral("local-disk"), describe(QStringLiteral("Local Disk"), mine), QStringLiteral("drive-harddisk"),
                QStringLiteral("inode/x-fennek-drive"), home});
    n = 0;
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
