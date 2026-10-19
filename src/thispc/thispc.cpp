// Fennek OS: the Home page for Files (thispc:/). Files shows it whenever the folder is your home folder (the
// Dolphin patch in src/dolphin-fennek): everything in your home as big tiles (the main folders with their own icons
// and names in your language), folders you pinned to the sidebar, the folders you use most, then your drives with
// free space. Home's own entries are your real files and folders (UDS_URL: rename, delete, drag and drop work as
// anywhere); frequent folders and drives are links (opening one goes there; deleting one does nothing).
// Grouping ("Folders" / "Frequent folders" / "Storage drives", files by type) comes from the MIME types in
// fennek-thispc.xml.
#include <cmath>
#include <KIO/WorkerBase>
#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QXmlStreamReader>
#include <algorithm>
#include <QLocale>
#include <QMimeDatabase>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QUrl>
#include <optional>
#include <sys/stat.h>

namespace
{
struct Item {
    QString key, label, icon, mime, target;
    bool real = false;   // a real entry of the home folder (its file:// URL), not a link
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
    // Names in the language you use now, like the sidebar (the folders keep the names they were made with: switching
    // the language later does not rename them). Other languages: the folder's own name.
    const QString lang = QLocale::system().uiLanguages().value(0).left(2);
    const struct {
        QStandardPaths::StandardLocation where;
        const char *icon, *en, *uk;
    } folders[] = {{QStandardPaths::DesktopLocation, "fennek-folder-desktop", "Desktop", "Стільниця"},
                   {QStandardPaths::DocumentsLocation, "fennek-folder-documents", "Documents", "Документи"},
                   {QStandardPaths::DownloadLocation, "fennek-folder-downloads", "Downloads", "Завантаження"},
                   {QStandardPaths::MusicLocation, "fennek-folder-music", "Music", "Музика"},
                   {QStandardPaths::PicturesLocation, "fennek-folder-pictures", "Pictures", "Зображення"},
                   {QStandardPaths::MoviesLocation, "fennek-folder-videos", "Videos", "Відео"}};
    QHash<QString, QPair<QString, QString>> main;   // path -> (label, icon)
    for (const auto &f : folders) {
        const QString path = QStandardPaths::writableLocation(f.where);
        if (path.isEmpty() || path == home)
            continue;
        const QString label = lang == QLatin1String("en") ? QString::fromUtf8(f.en)
            : lang == QLatin1String("uk")                  ? QString::fromUtf8(f.uk)
                                                            : QDir(path).dirName();
        main.insert(path, {label, QString::fromLatin1(f.icon)});
    }

    // Everything in your home folder (hidden ones too: Files hides names starting with a dot unless you show them).
    QStringList shown{home};
    const QMimeDatabase mimes;
    const auto entries = QDir(home).entryInfoList(QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System, QDir::Name);
    for (const QFileInfo &fi : entries) {
        const QString path = fi.absoluteFilePath();
        Item i{fi.fileName(), fi.fileName(), QString(), QString(), path, true};
        if (fi.isDir()) {
            i.mime = QStringLiteral("inode/x-fennek-folder");
            const auto m = main.value(path);
            if (!m.first.isEmpty()) {
                i.label = m.first;
                i.icon = m.second;
            } else {
                i.icon = QStringLiteral("folder");
            }
        } else {
            i.mime = mimes.mimeTypeForFile(fi).name();   // grouped by type; its own icon
        }
        out.append(i);
        shown << path;
    }

    // Folders you pinned to the sidebar (outside your home) join them.
    const QString data = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    int n = 0;
    // Stable order (alphabetical): an entry's key must name the same folder each time the page is read.
    QStringList pinned = xbelFolders(data + QStringLiteral("/user-places.xbel"), false).keys();
    pinned.sort();
    for (const QString &p : std::as_const(pinned)) {
        if (shown.contains(p) || p.startsWith(home + QLatin1Char('/')) || !QFileInfo(p).isDir())
            continue;
        out.append({QStringLiteral("@pin-%1").arg(++n), QDir(p).dirName(), QStringLiteral("folder"), QStringLiteral("inode/x-fennek-folder"), p});
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
        out.append({QStringLiteral("@frequent-%1").arg(++n), QDir(r.second).dirName(), QStringLiteral("folder"),
                    QStringLiteral("inode/x-fennek-frequent"), r.second});
    }

    const QLocale locale;
    const auto describe = [&](const QString &label, const QStorageInfo &s) {
        // Like the classic This PC page: the name, then "50.4 GB free of 98.0 GB" on its own line (U+2028 is a
        // line break inside one name; one decimal, GB, base 1024).
        // From 10 GB on, whole numbers ("99 GB free of 144 GB" fits one line under the icon).
        const auto size = [&](qint64 b) { return locale.formattedDataSize(b, b >= (qint64(10) << 30) ? 0 : 1, QLocale::DataSizeTraditionalFormat); };
        return QStringLiteral("%1\u2028%2 free of %3").arg(label, size(s.bytesAvailable()), size(s.bytesTotal()));
    };
    // Drive icon with a usage bar (like the classic This PC page): fennek-drive-used-0 ... -100 in steps of 10.
    const auto usageIcon = [](const QStorageInfo &s) {
        const qint64 total = s.bytesTotal();
        const int used = total > 0 ? int(std::lround(10.0 * double(total - s.bytesAvailable()) / double(total))) * 10 : 0;
        return QStringLiteral("fennek-drive-used-%1").arg(std::clamp(used, 0, 100));
    };
    // The disk your files live on (opens at its top, like the classic drive), then every other mounted drive (USB
    // sticks, second disks, partitions).
    const QStorageInfo mine(home);
    out.append({QStringLiteral("@local-disk"), describe(QStringLiteral("Local Disk"), mine), usageIcon(mine),
                QStringLiteral("inode/x-fennek-drive"), QStringLiteral("/")});
    n = 0;
    const auto volumes = QStorageInfo::mountedVolumes();
    for (const QStorageInfo &s : volumes) {
        const QString root = s.rootPath();
        if (!s.isValid() || !s.isReady() || s.device() == mine.device()
            || !(root.startsWith(QLatin1String("/run/media/")) || root.startsWith(QLatin1String("/media/")) || root.startsWith(QLatin1String("/mnt/"))))
            continue;
        const QString label = s.name().isEmpty() ? QDir(root).dirName() : s.name();
        out.append({QStringLiteral("@drive-%1").arg(++n), describe(label, s), usageIcon(s),
                    QStringLiteral("inode/x-fennek-drive"), root});
    }
    return out;
}

KIO::UDSEntry entry(const Item &i)
{
    KIO::UDSEntry e;
    e.fastInsert(KIO::UDSEntry::UDS_NAME, i.key);
    e.fastInsert(KIO::UDSEntry::UDS_DISPLAY_NAME, i.label);
    if (i.real) { // the real file or folder: its own URL, type, size, dates and permissions
        const QFileInfo fi(i.target);
        e.fastInsert(KIO::UDSEntry::UDS_URL, QUrl::fromLocalFile(i.target).toString());
        e.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, fi.isDir() ? S_IFDIR : S_IFREG);
        struct stat st;
        e.fastInsert(KIO::UDSEntry::UDS_ACCESS, ::stat(QFile::encodeName(i.target).constData(), &st) == 0 ? int(st.st_mode & 07777) : 0700);
        if (!fi.isDir())
            e.fastInsert(KIO::UDSEntry::UDS_SIZE, fi.size());
        e.fastInsert(KIO::UDSEntry::UDS_MODIFICATION_TIME, fi.lastModified().toSecsSinceEpoch());
        if (fi.isSymLink())
            e.fastInsert(KIO::UDSEntry::UDS_LINK_DEST, fi.symLinkTarget());
    } else {
        e.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, S_IFDIR);
        e.fastInsert(KIO::UDSEntry::UDS_ACCESS, 0500);
        e.fastInsert(KIO::UDSEntry::UDS_TARGET_URL, QUrl::fromLocalFile(i.target).toString());
    }
    if (!i.icon.isEmpty())
        e.fastInsert(KIO::UDSEntry::UDS_ICON_NAME, i.icon);
    e.fastInsert(KIO::UDSEntry::UDS_MIME_TYPE, i.mime);
    e.fastInsert(KIO::UDSEntry::UDS_LOCAL_PATH, i.target);
    return e;
}

KIO::UDSEntry rootEntry()
{
    KIO::UDSEntry e;
    e.fastInsert(KIO::UDSEntry::UDS_NAME, QStringLiteral("."));
    e.fastInsert(KIO::UDSEntry::UDS_DISPLAY_NAME, QStringLiteral("Home"));
    e.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, S_IFDIR);
    e.fastInsert(KIO::UDSEntry::UDS_ACCESS, 0500);
    e.fastInsert(KIO::UDSEntry::UDS_ICON_NAME, QStringLiteral("user-home"));
    e.fastInsert(KIO::UDSEntry::UDS_MIME_TYPE, QStringLiteral("inode/directory"));
    return e;
}

// thispc:/<key>[/rest] -> the real folder, or nothing. Keys starting with @ are the page's links (pinned, frequent,
// drives); any other key is a name in your home folder.
std::optional<QUrl> resolve(const QUrl &url)
{
    const QString path = url.path().mid(1);
    const QString key = path.section(QLatin1Char('/'), 0, 0);
    if (!key.startsWith(QLatin1Char('@'))) {
        const QString target = QDir::homePath() + QLatin1Char('/') + path;
        if (QFileInfo::exists(target))
            return QUrl::fromLocalFile(target);
        return std::nullopt;
    }
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
