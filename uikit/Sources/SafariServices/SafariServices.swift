// SafariServices — first-party module covering the ladder-corpus call sites
// (16 of 20 apps import it). Chrome is painted under the iOS cut from
// PresentProbe captures on iPhone SE 2x and iPhone 16 3x / iOS 26.1.
//
// Corpus surface (grep scratch/ladder-corpus):
//   SFSafariViewController.init(url:), init(url:configuration:),
//   Configuration.entersReaderIfAvailable / barCollapsingEnabled,
//   dismissButtonStyle (.done, .close, .cancel),
//   SFSafariViewControllerDelegate (didFinish, didCompleteInitialLoad),
//   SSReadingList.default()?.addItem(with:title:previewText:),
//   SFContentBlockerManager.getStateOfContentBlocker / reloadContentBlocker,
//   SFContentBlockerState.isEnabled, SFAuthenticationSession.start()
//
// GAPS (fail closed, listed):
//   - Address field: unobserved when http://127.0.0.1/ fails to load
//     (PresentProbe safari, SE 2x + iPhone 16 3x). OPEN.
//   - preferredBarTintColor / preferredControlTintColor / ActivityButton:
//     not in the corpus; not painted.
//   - .close / .cancel glyphs: unmeasured (element-ios / Pocket Casts set
//     the style; only .done = checkmark was on the PNG). xmark is used.
//   - Reading List never persists; content-blocker never enables; auth
//     session never starts (no Safari service).
//   - Glass on the remote `_UISceneHostingView` platters: geometry is
//     painted with `_UIBarMetrics.platterFill`; the iOS 26 glass mix is
//     OPEN (same class as docs/KNOWN_GAPS.md bar glass).
import UIKit

// MARK: - Content blocker

public final class SFContentBlockerState: NSObject {
    public let isEnabled: Bool
    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
        super.init()
    }
}

public final class SFContentBlockerManager: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("SFContentBlockerManager is not instantiable")
    }

    /// Fail closed: Linux / the port has no Safari content-blocker service.
    /// Focus (a2832521) reads `(state, error)` and treats a nil state as off.
    public static func getStateOfContentBlocker(
        withIdentifier identifier: String,
        completionHandler: @escaping (SFContentBlockerState?, Error?) -> Void
    ) {
        _ = identifier
        completionHandler(nil, SafariServicesUnavailableError.contentBlocker)
    }

    public static func reloadContentBlocker(
        withIdentifier identifier: String,
        completionHandler: @escaping (Error?) -> Void
    ) {
        _ = identifier
        completionHandler(SafariServicesUnavailableError.contentBlocker)
    }
}

public enum SafariServicesUnavailableError: Error, Equatable {
    case contentBlocker
    case readingList
    case authenticationSession
}

// MARK: - Reading List

public struct SSReadingListError: Error, Equatable {
    public enum Code: Int, Equatable, Sendable {
        case urlSchemeNotAllowed = 1
    }
    public let code: Code
    public init(_ code: Code) { self.code = code }
}

public final class SSReadingList: NSObject {
    private static let shared = SSReadingList()
    private override init() { super.init() }

    public static func `default`() -> SSReadingList? { shared }

    /// Publicly documented Safari Reading List schemes are `http` and `https`.
    public static func supportsURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }

    public func addItem(with url: URL, title: String?, previewText: String?) throws {
        _ = title
        _ = previewText
        if !Self.supportsURL(url) {
            throw SSReadingListError(.urlSchemeNotAllowed)
        }
        throw SafariServicesUnavailableError.readingList
    }
}

// MARK: - Authentication session (mentioned, not constructed, in the corpus)

public final class SFAuthenticationSession: NSObject {
    public typealias CompletionHandler = (URL?, (any Error)?) -> Void
    private let completionHandler: CompletionHandler

    public init(
        url: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping CompletionHandler
    ) {
        _ = url
        _ = callbackURLScheme
        self.completionHandler = completionHandler
        super.init()
    }

    /// Fail closed: no Safari / ASWebAuthenticationSession host.
    @discardableResult
    public func start() -> Bool { false }

    public func cancel() {}
}

// MARK: - Safari view controller

@MainActor
public protocol SFSafariViewControllerDelegate: NSObjectProtocol {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController)
    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    )
}

public extension SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {}
    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    ) {}
}

open class SFSafariViewController: UIViewController {

    open class Configuration: NSObject {
        open var entersReaderIfAvailable = false
        /// Apple's default is true. Pocket Casts sets it false
        /// (`SFSafariViewController+Creation.swift`).
        open var barCollapsingEnabled = true

        public override init() { super.init() }

        public func copy() -> Configuration {
            let copied = Configuration()
            copied.entersReaderIfAvailable = entersReaderIfAvailable
            copied.barCollapsingEnabled = barCollapsingEnabled
            return copied
        }
    }

    public enum DismissButtonStyle: Int, Sendable {
        case done = 0
        case close = 1
        case cancel = 2
    }

    public let configuration: Configuration
    public weak var delegate: SFSafariViewControllerDelegate?
    open var dismissButtonStyle: DismissButtonStyle = .done {
        didSet { dismissPlatter?.symbolName = Self.symbolName(for: dismissButtonStyle) }
    }

    private let initialURL: URL
    private var dismissPlatter: _SFPlatterView?
    private var backPlatter: _SFPlatterView?
    private var trailingCapsule: UIView?

    public convenience init(url: URL) {
        self.init(url: url, configuration: Configuration())
    }

    public init(url: URL, configuration: Configuration) {
        initialURL = url
        self.configuration = configuration.copy()
        super.init()
        // MEASURED PresentProbe safari, iPhone SE 2x + iPhone 16 3x / iOS 26.1:
        // modalPresentationStyle rawValue 0 = .fullScreen. View fills the
        // window (SE [0,0,375,667]; iPhone 16 [0,0,393,852]).
        modalPresentationStyle = .fullScreen
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        guard OpenUIKitRuntime.systemFontCut == .iOS else { return }
        installIOSChrome()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutIOSChrome()
    }

    private func installIOSChrome() {
        let dismiss = _SFPlatterView(symbolName: Self.symbolName(for: dismissButtonStyle))
        dismiss.tag = 1001
        dismiss.onTap = { [weak self] in self?.handleDismiss() }
        view.addSubview(dismiss)
        dismissPlatter = dismiss

        let back = _SFPlatterView(symbolName: "chevron.backward")
        back.tag = 1002
        view.addSubview(back)
        backPlatter = back

        let capsule = UIView()
        capsule.tag = 1003
        capsule.backgroundColor = _UIBarMetrics.platterFill
        capsule.clipsToBounds = true
        let names = ["square.and.arrow.up", "arrow.clockwise", "safari"]
        for name in names {
            let icon = UIImageView(image: UIImage(systemName: name))
            icon.tintColor = .label
            icon.contentMode = .center
            capsule.addSubview(icon)
        }
        view.addSubview(capsule)
        trailingCapsule = capsule
    }

    private func layoutIOSChrome() {
        guard OpenUIKitRuntime.systemFontCut == .iOS else { return }
        let sa = view.safeAreaInsets
        let bounds = view.bounds
        let side = _UIBarMetrics.sideMargin
        let navH = _UIBarMetrics.platterHeight
        let toolH = _UIBarMetrics.toolbarPlatterHeight

        // MEASURED PresentProbe safari PNG + dump, iOS 26.1:
        // dismiss checkmark in a 44 pt circle, origin (16, SA.top + 8).
        // SE hidden status bar: SA.top 0 → y=8. iPhone 16: SA.top 59 → y=67;
        // platter centre x ≈ 37.8 = 16+22.
        dismissPlatter?.frame = CGRect(x: side, y: sa.top + 8, width: navH, height: navH)
        dismissPlatter?.layer.cornerRadius = navH / 2

        // MEASURED same captures: back chevron in a 48 pt circle.
        // y = H − max(16, SA.bottom − 16) − 48.
        // SE SA.bottom 0 → y=603. iPhone 16 SA.bottom 34 → y=786
        // (centre ≈ 809).
        let bottomMargin = max(16, sa.bottom - 16)
        let toolY = bounds.height - bottomMargin - toolH
        backPlatter?.frame = CGRect(x: side, y: toolY, width: toolH, height: toolH)
        backPlatter?.layer.cornerRadius = toolH / 2

        // MEASURED iPhone 16 3x PNG: trailing share+reload+compass capsule
        // height 48, trailing margin 16, width 174 pt (peak 174.33).
        let capW: CGFloat = 174
        trailingCapsule?.frame = CGRect(
            x: bounds.width - side - capW, y: toolY, width: capW, height: toolH)
        trailingCapsule?.layer.cornerRadius = toolH / 2
        if let capsule = trailingCapsule {
            let slot = capW / CGFloat(max(1, capsule.subviews.count))
            for (i, sub) in capsule.subviews.enumerated() {
                sub.frame = CGRect(x: CGFloat(i) * slot, y: 0, width: slot, height: toolH)
            }
        }
    }

    private func handleDismiss() {
        delegate?.safariViewControllerDidFinish(self)
        dismiss(animated: true, completion: nil)
    }

    private static func symbolName(for style: DismissButtonStyle) -> String {
        switch style {
        case .done: return "checkmark"
        case .close, .cancel: return "xmark"
        }
    }
}

// MARK: - Platter

/// 44/48 pt circle filled with the measured bar platter colour, symbol centred.
final class _SFPlatterView: UIView {
    var symbolName: String {
        didSet { imageView.image = UIImage(systemName: symbolName) }
    }
    var onTap: (() -> Void)?
    private let imageView = UIImageView()

    init(symbolName: String) {
        self.symbolName = symbolName
        super.init(frame: .zero)
        backgroundColor = _UIBarMetrics.platterFill
        clipsToBounds = true
        imageView.image = UIImage(systemName: symbolName)
        imageView.tintColor = .label
        imageView.contentMode = .center
        addSubview(imageView)
        let tap = UITapGestureRecognizer { [weak self] _ in self?.onTap?() }
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        layer.cornerRadius = bounds.height / 2
    }
}
