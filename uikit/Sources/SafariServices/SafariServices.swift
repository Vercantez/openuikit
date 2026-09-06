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
//   - preferredBarTintColor / preferredControlTintColor / ActivityButton:
//     not in the corpus; not painted.
//   - Reading List never persists; content-blocker never enables; auth
//     session never starts (no Safari service).
//   - Glass on the remote `_UISceneHostingView` platters: geometry is
//     painted with `_UIBarMetrics.platterFill`; the iOS 26 glass mix is
//     OPEN (same class as docs/KNOWN_GAPS.md bar glass).
//   - Loading progress under the address (blue left cap) is clock-
//     dependent across captures; not painted.
//   - Failed-load body copy ("Safari can't open the page…") lives in
//     the remote scene. Present t1200.dark paints it at
//     [54, 181.5, 267.5, 34.5] ink (133,133,133); light t1200 LTR and
//     iPad y=150–250 are all 255; RTL/ax1/xxxl/landscape light show it.
//     No single visibility rule; a guessed string dropped t1200.dark
//     95.279 → 94.781. OPEN.
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
    func safariViewController(_ controller: SFSafariViewController,
                              activityItemsFor URL: URL, title: String?) -> [UIActivity]
    func safariViewController(_ controller: SFSafariViewController,
                              excludedActivityTypesFor URL: URL, title: String?) -> [UIActivity.ActivityType]
    func safariViewController(_ controller: SFSafariViewController,
                              initialLoadDidRedirectTo URL: URL)
    func safariViewControllerWillOpenInBrowser(_ controller: SFSafariViewController)
}

public extension SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {}
    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    ) {}
    func safariViewController(_ controller: SFSafariViewController,
                              activityItemsFor URL: URL, title: String?) -> [UIActivity] { [] }
    func safariViewController(_ controller: SFSafariViewController,
                              excludedActivityTypesFor URL: URL, title: String?) -> [UIActivity.ActivityType] { [] }
    func safariViewController(_ controller: SFSafariViewController,
                              initialLoadDidRedirectTo URL: URL) {}
    func safariViewControllerWillOpenInBrowser(_ controller: SFSafariViewController) {}
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
    private var pageMenuPlatter: _SFPlatterView?
    private var trailingCapsule: UIView?
    private var addressLabel: UILabel?

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
        if OpenUIKitRuntime.systemFontCut == .iOS {
            // MEASURED Present t1200 / t1200.dark, iPhone SE 2x / iOS 26.1:
            // page fill is systemBackground (light 255 / dark 0). Catalyst
            // stays white so fixture goldens do not move.
            view.backgroundColor = .systemBackground
            // MEASURED Present t1200.rtl: dismiss X stays at leading x=16,
            // address "127.0.0.1" stays centred; chrome does not mirror.
            view.semanticContentAttribute = .forceLeftToRight
            installIOSChrome()
        } else {
            view.backgroundColor = .white
        }
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
        // MEASURED Present t1200.dark back chevron: dimmed (no history).
        // tertiaryLabel over platterFill (25,25,25), not .label white.
        back.symbolTint = .tertiaryLabel
        view.addSubview(back)
        backPlatter = back

        // MEASURED Present t1200.dark / .rtl / .ax1 / .landscape trailing-top
        // 44 pt circle, x = W − 16 − 44. Glyph is harvested `doc.text`
        // (rounded rect + two lines = page menu). Light t1200 LTR has no
        // ink there (all-255 centre/trailing-top); other axes do.
        let pageMenu = _SFPlatterView(symbolName: "doc.text")
        pageMenu.tag = 1004
        view.addSubview(pageMenu)
        pageMenuPlatter = pageMenu

        let address = UILabel()
        address.tag = 1005
        address.textAlignment = .center
        address.textColor = .label
        address.numberOfLines = 1
        // MEASURED Present t1200.dark / .rtl / .ax1 address ink: "127.0.0.1"
        // (URL.host). Light t1200 LTR centre band is all 255 — listed OPEN.
        address.text = initialURL.host ?? initialURL.absoluteString
        view.addSubview(address)
        addressLabel = address

        let capsule = UIView()
        capsule.tag = 1003
        capsule.backgroundColor = _UIBarMetrics.platterFill
        capsule.clipsToBounds = true
        let names = ["square.and.arrow.up", "arrow.clockwise", "safari"]
        for name in names {
            let icon = UIImageView(image: UIImage(systemName: name))
            // MEASURED Present t1200.dark capsule: share + safari are .label
            // (white); reload is dimmed (no document yet).
            icon.tintColor = name == "arrow.clockwise" ? .tertiaryLabel : .label
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
        let compact = traitCollection.verticalSizeClass == .compact
        let (navH, toolH, capW) = safariPlatterSizes(compact: compact)

        // MEASURED Present t1200 family, iPhone SE 2x / iOS 26.1:
        // dismiss X in a 44 pt circle, origin (16, SA.top + 8). Same
        // leading edge in RTL (t1200.rtl X bbox [29.5, 16.5, 17, 17]).
        let navY = sa.top + 8
        dismissPlatter?.frame = CGRect(x: side, y: navY, width: navH, height: navH)
        dismissPlatter?.layer.cornerRadius = navH / 2

        // MEASURED Present t1200.landscape page-menu fill [117, 4, 42, 42]
        // = 16 + 44 + 57. Portrait / regular-height: trailing (W − 16 − 44).
        let pageMenuX = compact
            ? side + navH + 57
            : bounds.width - side - navH
        pageMenuPlatter?.frame = CGRect(
            x: pageMenuX, y: navY, width: navH, height: navH)
        pageMenuPlatter?.layer.cornerRadius = navH / 2

        let addressX = compact ? pageMenuX + navH : side + navH
        let addressRight = compact
            ? bounds.width - side - capW
            : bounds.width - side - navH
        addressLabel?.frame = CGRect(
            x: addressX, y: navY,
            width: max(0, addressRight - addressX), height: navH)
        addressLabel?.font = safariAddressFont()
        addressLabel?.isUserInteractionEnabled = false

        // MEASURED Present t1200.landscape (window 667×375, vclass compact):
        // no bottom toolbar. Back + share capsule sit on the top row
        // (capsule fill bbox [520, 4, 130, 42], trailing 16 → width 130).
        // Portrait: back y = H − max(16, SA.bottom − 16) − toolH
        // (SE 603 / 48; iPhone 16 786).
        let toolY: CGFloat
        let backX: CGFloat
        if compact {
            toolY = navY
            backX = side + navH + _UIBarMetrics.gap
            backPlatter?.showsPlatter = false
        } else {
            let bottomMargin = max(16, sa.bottom - 16)
            toolY = bounds.height - bottomMargin - toolH
            backX = side
            backPlatter?.showsPlatter = true
        }
        backPlatter?.frame = CGRect(x: backX, y: toolY, width: toolH, height: toolH)

        trailingCapsule?.frame = CGRect(
            x: bounds.width - side - capW, y: toolY, width: capW, height: toolH)
        trailingCapsule?.layer.cornerRadius = toolH / 2
        // MEASURED Present t1200.landscape page-menu + capsule interiors
        // (198, 198, 198) over white, bbox [117, 4, 42, 42] / [520, 4, 130, 42].
        // Portrait platters stay `_UIBarMetrics.platterFill`. Dark compact is
        // unmeasured (no Present.dark.landscape capture).
        if compact, traitCollection.userInterfaceStyle != .dark {
            let compactFill = UIColor(red: 198 / 255, green: 198 / 255, blue: 198 / 255, alpha: 1)
            trailingCapsule?.backgroundColor = compactFill
            pageMenuPlatter?.backgroundColor = compactFill
        } else {
            trailingCapsule?.backgroundColor = _UIBarMetrics.platterFill
            pageMenuPlatter?.backgroundColor = _UIBarMetrics.platterFill
        }
        if let capsule = trailingCapsule {
            let slot = capW / CGFloat(max(1, capsule.subviews.count))
            for (i, sub) in capsule.subviews.enumerated() {
                sub.frame = CGRect(x: CGFloat(i) * slot, y: 0, width: slot, height: toolH)
            }
        }
    }

    /// MEASURED Present t1200.ax1 vs t1200.xxxl, iPhone SE 2x / iOS 26.1:
    /// dismiss glass, X bbox and address ink bbox are identical, so every
    /// category above extraExtraLarge caps there (same xxxl floor as
    /// nav-bar `iOSBarCapped`).
    private func safariCappedCategory() -> UIContentSizeCategory {
        let cat = traitCollection.preferredContentSizeCategory
        if cat.isAccessibilityCategory || cat == .extraExtraExtraLarge {
            return .extraExtraLarge
        }
        return cat
    }

    private func safariPlatterSizes(compact: Bool) -> (CGFloat, CGFloat, CGFloat) {
        let cap = UITraitCollection(preferredContentSizeCategory: safariCappedCategory())
        let metrics = UIFontMetrics(forTextStyle: .body)
        let navH = metrics.scaledValue(for: _UIBarMetrics.platterHeight, compatibleWith: cap)
        if compact {
            // MEASURED Present t1200.landscape capsule fill width 130
            // (= 667 − 16 − 521). Height shares the 44 pt dismiss row.
            return (navH, navH, 130)
        }
        let toolH = metrics.scaledValue(
            for: _UIBarMetrics.toolbarPlatterHeight, compatibleWith: cap)
        return (navH, toolH, 174)
    }

    private func safariAddressFont() -> UIFont {
        let cap = UITraitCollection(preferredContentSizeCategory: safariCappedCategory())
        // MEASURED Present t1200.dark address glyph bbox h=13 at y=12.5
        // (footnote 13 semibold). ax1 bbox h=15 after the extraExtraLarge cap.
        let size = UIFontMetrics(forTextStyle: .footnote)
            .scaledValue(for: 13, compatibleWith: cap)
        return .systemFont(ofSize: size, weight: .semibold)
    }

    private func handleDismiss() {
        delegate?.safariViewControllerDidFinish(self)
        dismiss(animated: true, completion: nil)
    }

    private static func symbolName(for style: DismissButtonStyle) -> String {
        // MEASURED Present t1200 / t1200.dark / t1200.ax1 / t1200.rtl,
        // iPhone SE 2x / iOS 26.1: default `.done` paints `xmark`, not
        // checkmark (light dismiss ink bbox [29.5, 16.5, 17, 17]; dark
        // X in the 44 pt platter at (16, 8)).
        _ = style
        return "xmark"
    }
}

// MARK: - Platter

/// 44/48 pt circle filled with the measured bar platter colour, symbol centred.
final class _SFPlatterView: UIView {
    var symbolName: String {
        didSet { imageView.image = UIImage(systemName: symbolName) }
    }
    var symbolTint: UIColor = .label {
        didSet { imageView.tintColor = symbolTint }
    }
    var showsPlatter = true {
        didSet {
            backgroundColor = showsPlatter ? _UIBarMetrics.platterFill : .clear
            setNeedsLayout()
        }
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
        layer.cornerRadius = showsPlatter ? bounds.height / 2 : 0
    }
}
