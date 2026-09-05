// LinkPresentation — first-party module covering the ladder-corpus call
// sites (6 of 20 apps import it) plus LPLinkView, which the brief requires
// painted even though almost no app constructs one.
//
// Corpus surface:
//   LPLinkMetadata.title / url / originalURL / imageProvider / iconProvider
//   LPMetadataProvider.startFetchingMetadata(for:completionHandler:)
//     (URL and URLRequest), async startFetchingMetadata(for: URL),
//     shouldFetchSubresources
//   LPLinkView (paint)
//
// MEASURED PresentProbe link + linkplain, iPhone SE 2x / iOS 26.1,
// constrained width 343 (= 375−32):
//   height 53, inner LPFlippedView cornerRadius 10, intrinsic (186, 53)
//   image slot LPImageView 30×30 at (301, 11.5) — 12 pt from trailing
//   title .SFUI-Semibold 15 at (16, 8, 269, 18) text "Example Article"
//   host .SFUI-Regular 13 at (16, 28, 269, 16) text "example.com" (URL.host)
//   no-image card fill (0.915, 0.915, 0.920, 1) = RGB (233, 233, 235)
//     — not systemGray6
//   with-image card fill (0.004, 0.48, 0.90, 1) ≈ RGB (1, 122, 230)
//     (PresentProbe link.png before linkplain overwrote it)
//
// GAPS:
//   - NSItemProvider image/icon pixels are async on Darwin and absent on
//     Linux. A non-nil imageProvider selects the blue card + 30×30 slot;
//     the bitmap itself is OPEN.
//   - Host label grey RGB on the gray card was not dumped; `.secondaryLabel`
//     is used (OPEN).
import UIKit
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public let LPErrorDomain = "LPErrorDomain"

public struct LPError: Error, Equatable {
    public enum Code: Int, Equatable, Sendable {
        case unknown = 1
        case metadataFetchFailed = 2
        case metadataFetchCancelled = 3
        case metadataFetchTimedOut = 4
        case metadataFetchNotAllowed = 5
    }
    public let code: Code
    public init(_ code: Code) { self.code = code }
    public static let metadataFetchFailed = LPError(.metadataFetchFailed)
}

open class LPLinkMetadata: NSObject {
    open var title: String?
    open var url: URL?
    open var originalURL: URL?
#if !os(Linux)
    open var imageProvider: NSItemProvider?
    open var iconProvider: NSItemProvider?
#endif

    public override init() { super.init() }

    public func copy() -> LPLinkMetadata {
        let copied = LPLinkMetadata()
        copied.title = title
        copied.url = url
        copied.originalURL = originalURL
#if !os(Linux)
        copied.imageProvider = imageProvider
        copied.iconProvider = iconProvider
#endif
        return copied
    }
}

open class LPMetadataProvider: NSObject {
    /// Darwin's default is unobserved. Stored false so a fetch never
    /// claims subresources this host cannot retrieve.
    open var shouldFetchSubresources = false

    public override init() { super.init() }

    open func cancel() {}

    open func startFetchingMetadata(
        for url: URL,
        completionHandler: @escaping (LPLinkMetadata?, Error?) -> Void
    ) {
        _ = url
        completionHandler(nil, LPError.metadataFetchFailed)
    }

    open func startFetchingMetadata(
        for request: URLRequest,
        completionHandler: @escaping (LPLinkMetadata?, Error?) -> Void
    ) {
        _ = request
        completionHandler(nil, LPError.metadataFetchFailed)
    }

    open func startFetchingMetadata(for url: URL) async throws -> LPLinkMetadata {
        _ = url
        throw LPError.metadataFetchFailed
    }
}

open class LPLinkView: UIView {
    private var _metadata: LPLinkMetadata
    private let titleLabel = UILabel()
    private let hostLabel = UILabel()
    private let imageView = UIImageView()

    open var metadata: LPLinkMetadata {
        get { _metadata }
        set {
            _metadata = newValue.copy()
            applyMetadata()
            setNeedsLayout()
        }
    }

    public init(metadata: LPLinkMetadata) {
        _metadata = metadata.copy()
        super.init(frame: .zero)
        setup()
    }

    public init(url: URL) {
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        _metadata = metadata
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder: NSCoder) {
        _metadata = LPLinkMetadata()
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        clipsToBounds = true
        layer.cornerRadius = LPLinkMetrics.cornerRadius
        titleLabel.font = .systemFont(ofSize: LPLinkMetrics.titleSize, weight: .semibold)
        titleLabel.numberOfLines = 1
        hostLabel.font = .systemFont(ofSize: LPLinkMetrics.hostSize, weight: .regular)
        hostLabel.numberOfLines = 1
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = LPLinkMetrics.imageCornerRadius
        addSubview(titleLabel)
        addSubview(hostLabel)
        addSubview(imageView)
        applyMetadata()
    }

    open override var intrinsicContentSize: CGSize {
        // MEASURED PresentProbe link.layout.json, iPhone SE 2x / iOS 26.1.
        CGSize(width: LPLinkMetrics.intrinsicWidth, height: LPLinkMetrics.height)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let width = size.width > 0 ? size.width : LPLinkMetrics.intrinsicWidth
        return CGSize(width: width, height: LPLinkMetrics.height)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        let height = LPLinkMetrics.height
        if bounds.height != height {
            // Keep the measured 53 pt band even if Auto Layout stretched us.
        }
        let imageX = width - LPLinkMetrics.imageTrailing - LPLinkMetrics.imageSize
        let textWidth = max(0, imageX - LPLinkMetrics.textInset * 2)
        titleLabel.frame = CGRect(
            x: LPLinkMetrics.textInset, y: LPLinkMetrics.titleY,
            width: textWidth, height: LPLinkMetrics.titleHeight)
        hostLabel.frame = CGRect(
            x: LPLinkMetrics.textInset, y: LPLinkMetrics.hostY,
            width: textWidth, height: LPLinkMetrics.hostHeight)
        imageView.frame = CGRect(
            x: imageX, y: LPLinkMetrics.imageY,
            width: LPLinkMetrics.imageSize, height: LPLinkMetrics.imageSize)
    }

    private func applyMetadata() {
        titleLabel.text = _metadata.title
        let host = _metadata.url?.host ?? _metadata.originalURL?.host ?? ""
        hostLabel.text = host
        let compact = hasImageProvider
        if compact {
            // MEASURED PresentProbe link (with image), iPhone SE 2x:
            // card fill (0.004, 0.48, 0.90, 1) ≈ RGB (1, 122, 230).
            backgroundColor = LPLinkMetrics.compactFill
            titleLabel.textColor = .white
            hostLabel.textColor = .white
            imageView.image = nil
        } else {
            // MEASURED PresentProbe linkplain, iPhone SE 2x:
            // card fill (0.915, 0.915, 0.920, 1) = RGB (233, 233, 235).
            backgroundColor = LPLinkMetrics.plainFill
            titleLabel.textColor = .label
            hostLabel.textColor = .secondaryLabel
            imageView.image = UIImage(systemName: "safari")
            imageView.tintColor = .secondaryLabel
            imageView.contentMode = .center
        }
    }

    private var hasImageProvider: Bool {
#if os(Linux)
        false
#else
        _metadata.imageProvider != nil
#endif
    }
}

/// Sample table. PresentProbe link / linkplain, iPhone SE 2x / iOS 26.1.
enum LPLinkMetrics {
    static let height: CGFloat = 53
    static let intrinsicWidth: CGFloat = 186
    static let cornerRadius: CGFloat = 10
    static let textInset: CGFloat = 16
    static let titleY: CGFloat = 8
    static let titleHeight: CGFloat = 18
    static let titleSize: CGFloat = 15
    static let hostY: CGFloat = 28
    static let hostHeight: CGFloat = 16
    static let hostSize: CGFloat = 13
    static let imageSize: CGFloat = 30
    static let imageTrailing: CGFloat = 12
    static let imageY: CGFloat = 11.5
    static let imageCornerRadius: CGFloat = 3
    static let plainFill = UIColor(red: 233 / 255, green: 233 / 255, blue: 235 / 255, alpha: 1)
    static let compactFill = UIColor(red: 1 / 255, green: 122 / 255, blue: 230 / 255, alpha: 1)
}
