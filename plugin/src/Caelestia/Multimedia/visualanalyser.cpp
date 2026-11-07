#include "visualanalyser.hpp"

#include <qdir.h>
#include <qdiriterator.h>
#include <qicon.h>
#include <qimage.h>
#include <qimagereader.h>
#include <qqmlengine.h>
#include <qquickimageprovider.h>
#include <qsize.h>
#include <qtconcurrentrun.h>

#include "remotecache.hpp"

namespace caelestia::shell::multimedia {

namespace {

constexpr QSize k_providerSize(64, 64);

// Load an icon by name from the icon theme using QImage (software path).
// Avoids QIcon::pixmap → QPlatformPixmap::fromFile which can SIGSEGV
// on certain GPU/platform configurations (e.g. NVIDIA + Wayland).
QImage loadThemeIconImage(const QString& name, const QSize& size) {
    static const QStringList exts = {
        QStringLiteral(".svg"), QStringLiteral(".svgz"),
        QStringLiteral(".png"), QStringLiteral(".xpm"),
    };

    QStringList themes = {QIcon::themeName()};
    if (auto fb = QIcon::fallbackThemeName(); !fb.isEmpty() && fb != themes.first())
        themes << fb;
    themes << QStringLiteral("hicolor");

    for (const auto& searchPath : QIcon::themeSearchPaths()) {
        for (const auto& theme : themes) {
            const auto base = searchPath + u'/' + theme;
            if (!QDir(base).exists()) continue;

            for (const auto& ext : exts) {
                QDirIterator it(base, {name + ext}, QDir::Files, QDirIterator::Subdirectories);
                if (it.hasNext()) {
                    QImageReader reader(it.next());
                    reader.setScaledSize(size);
                    auto image = reader.read();
                    if (!image.isNull()) return image;
                }
            }
        }
    }
    return {};
}

} // namespace

VisualAnalyser::VisualAnalyser(QObject* parent)
    : QObject(parent) {
    QObject::connect(RemoteCache::instance(), &RemoteCache::updated, this, [this](const QUrl& url, const QUrl& file) {
        if (QUrl(m_source) == url)
            analyse(file.toLocalFile());
    });
}

QString VisualAnalyser::source() const {
    return m_source;
}

void VisualAnalyser::setSource(const QString& source) {
    if (m_source == source)
        return;

    m_source = source;
    emit sourceChanged();

    if (m_complete)
        resolve();
}

void VisualAnalyser::classBegin() {}

void VisualAnalyser::componentComplete() {
    m_complete = true;
    resolve();
}

void VisualAnalyser::resolve() {
    const QUrl url(m_source);
    if (RemoteCache::isRemote(url)) {
        RemoteCache::instance()->fetch(url).then(this, [this, url](const QUrl& file) {
            if (QUrl(m_source) == url)
                analyse(file.toLocalFile());
        });
    } else if (url.scheme() == u"image") {
        analyseProvider(url);
    } else {
        analyse(url.isLocalFile() ? url.toLocalFile() : m_source);
    }
}

void VisualAnalyser::analyse(const QString& path) {
    apply(media::analyseForPath(path));
}

void VisualAnalyser::analyseProvider(const QUrl& url) {
    // For icon providers, load the file directly via QImage (software path)
    // to avoid SIGSEGV in QPlatformPixmap::fromFile
    if (url.host() == u"icon") {
        auto id = url.toString(QUrl::RemoveScheme | QUrl::RemoveAuthority).mid(1);

        QString iconName;
        QString filePath;

        auto splitIdx = id.indexOf(u"?path=");
        if (splitIdx != -1) {
            iconName = id.left(splitIdx);
            auto path = id.mid(splitIdx + 6);
            filePath = QStringLiteral("/%1/%2").arg(path, iconName.mid(iconName.lastIndexOf(u'/') + 1));
        } else {
            splitIdx = id.indexOf(u"?fallback=");
            iconName = splitIdx != -1 ? id.left(splitIdx) : id;
        }

        if (iconName.isEmpty()) return;

        apply(QtConcurrent::run([iconName, filePath, size = k_providerSize]() -> media::Analysis {
            if (!filePath.isEmpty()) {
                QImageReader reader(filePath);
                reader.setScaledSize(size);
                auto image = reader.read();
                if (!image.isNull()) return media::analyseImage(image);
            }

            auto image = loadThemeIconImage(iconName, size);
            if (image.isNull()) return {};
            return media::analyseImage(image);
        }));
        return;
    }

    const auto* engine = qmlEngine(this);
    if (!engine)
        return;

    auto* const base = engine->imageProvider(url.host());
    if (!base)
        return;

    const auto id = url.toString(QUrl::RemoveScheme | QUrl::RemoveAuthority).mid(1);

    if (base->imageType() == QQmlImageProviderBase::Image) {
        auto* const provider = static_cast<QQuickImageProvider*>(base);
        apply(QtConcurrent::run([provider, id] {
            QSize size;
            return media::analyseImage(provider->requestImage(id, &size, k_providerSize));
        }));
    } else if (base->imageType() == QQmlImageProviderBase::Pixmap) {
        auto* const provider = static_cast<QQuickImageProvider*>(base);
        QSize size;
        auto image = provider->requestPixmap(id, &size, k_providerSize).toImage();
        apply(QtConcurrent::run([image = std::move(image)] {
            return media::analyseImage(image);
        }));
    }
}

void VisualAnalyser::apply(QFuture<media::Analysis> future) {
    future.then(this, [this, source = m_source](media::Analysis analysis) {
        if (source != m_source)
            return;

        m_analysis = std::move(analysis);
        emit dominantColourChanged();
        emit luminanceChanged();
    });
}

QColor VisualAnalyser::dominantColour() const {
    return m_analysis.dominant;
}

qreal VisualAnalyser::luminance() const {
    return m_analysis.luminance;
}

} // namespace caelestia::shell::multimedia
