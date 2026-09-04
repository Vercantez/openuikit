@_exported import Foundation
import Dispatch

#if canImport(UIKit)
@_exported import UIKit
#elseif canImport(OpenUIKit)
@_exported import OpenUIKit
#endif

enum SafariServicesHost {
    static let contentBlockerQueue = DispatchQueue(
        label: "SafariServices.SFContentBlockerManager.completion"
    )
    static let settingsQueue = DispatchQueue(
        label: "SafariServices.SFSafariSettings.completion"
    )
    static let dataStoreQueue = DispatchQueue(
        label: "SafariServices.SFSafariViewController.DataStore.completion"
    )
}

public struct SafariServicesPortableError: Error, Equatable, Sendable,
    CustomStringConvertible
{
    public enum Code: Int, Sendable {
        case browserServiceUnavailable = 1
        case contentBlockerServiceUnavailable = 2
    }

    public let code: Code
    public let description: String

    public init(_ code: Code) {
        self.code = code
        switch code {
        case .browserServiceUnavailable:
            description = "Safari browsing service is unavailable on this host"
        case .contentBlockerServiceUnavailable:
            description = "Safari content-blocker service is unavailable on this host"
        }
    }
}

/// Apple `NS_ERROR_ENUM` domain strings. Values match the exported symbol
/// names recorded in `reference/tbd-exports.tsv` and the pinned
/// `dotnet/macios` `[ErrorDomain ("...")]` annotations. They are not an
/// Apple-runtime observation of localized payloads.
public let SFAuthenticationErrorDomain = "SFAuthenticationErrorDomain"
public let SFContentBlockerErrorDomain = "SFContentBlockerErrorDomain"
public let SFErrorDomain = "SFErrorDomain"
public let SSReadingListErrorDomain = "SSReadingListErrorDomain"

/// Safari app-extension `NSExtensionItem.userInfo` keys. Payloads match the
/// pinned `dotnet/macios` `[Field ("...")]` names; Apple's runtime string
/// contents are unobserved.
public let SFExtensionMessageKey = "SFExtensionMessageKey"
public let SFExtensionProfileKey = "SFExtensionProfileKey"

@frozen
public struct SFAuthenticationError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = SFAuthenticationError
        case canceledLogin = 1
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { SFAuthenticationErrorDomain }
    public static var canceledLogin: Code { .canceledLogin }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

/// Deprecated content-blocker error codes. The Swift graph exposes this C
/// enum directly rather than a bridged `SFContentBlockerError` struct.
public enum SFContentBlockerErrorCode: Int, Sendable {
    case noExtensionFound = 1
    case noAttachmentFound = 2
    case loadingInterrupted = 3
}

@frozen
public struct SFError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = SFError
        case noExtensionFound = 1
        case noAttachmentFound = 2
        case loadingInterrupted = 3
        case internalError = 4
        case missingEntitlement = 5
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { SFErrorDomain }
    public static var noExtensionFound: Code { .noExtensionFound }
    public static var noAttachmentFound: Code { .noAttachmentFound }
    public static var loadingInterrupted: Code { .loadingInterrupted }
    public static var internalError: Code { .internalError }
    public static var missingEntitlement: Code { .missingEntitlement }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

@frozen
public struct SSReadingListError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = SSReadingListError
        case urlSchemeNotAllowed = 1
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { SSReadingListErrorDomain }
    public static var urlSchemeNotAllowed: Code { .urlSchemeNotAllowed }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

public final class SFContentBlockerState: NSObject {
    public let isEnabled: Bool

    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
        super.init()
    }
}

/// Linux has no Safari content-blocker service or app-extension host.
/// Manager APIs fail closed and never report an enabled blocker.
public final class SFContentBlockerManager: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("SFContentBlockerManager is not instantiable")
    }

    public static func getStateOfContentBlocker(
        withIdentifier identifier: String,
        completionHandler: @escaping (SFContentBlockerState?, Error?) -> Void
    ) {
        _ = identifier
        SafariServicesHost.contentBlockerQueue.async {
            completionHandler(
                nil,
                SafariServicesPortableError(.contentBlockerServiceUnavailable)
            )
        }
    }

    public static func reloadContentBlocker(
        withIdentifier identifier: String,
        completionHandler: @escaping (Error?) -> Void
    ) {
        _ = identifier
        SafariServicesHost.contentBlockerQueue.async {
            completionHandler(
                SafariServicesPortableError(.contentBlockerServiceUnavailable)
            )
        }
    }

    public static func reloadContentBlocker(withIdentifier identifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reloadContentBlocker(withIdentifier: identifier) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

public final class SFSafariSettings: NSObject {
    @available(*, unavailable)
    public override init() {
        fatalError("SFSafariSettings is not instantiable")
    }

    public static func openExportBrowsingDataSettings(
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        guard let completionHandler else { return }
        SafariServicesHost.settingsQueue.async {
            completionHandler(
                SafariServicesPortableError(.browserServiceUnavailable)
            )
        }
    }
}

@MainActor
public protocol SFSafariViewControllerDelegate: AnyObject {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController)
    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    )
    func safariViewController(
        _ controller: SFSafariViewController,
        initialLoadDidRedirectTo URL: URL
    )
    func safariViewControllerWillOpenInBrowser(_ controller: SFSafariViewController)
}

public extension SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {}

    func safariViewController(
        _ controller: SFSafariViewController,
        didCompleteInitialLoad didLoadSuccessfully: Bool
    ) {}

    func safariViewController(
        _ controller: SFSafariViewController,
        initialLoadDidRedirectTo URL: URL
    ) {}

    func safariViewControllerWillOpenInBrowser(_ controller: SFSafariViewController) {}
}

#if canImport(UIKit) || canImport(OpenUIKit)
public typealias SFSafariViewControllerBase = UIViewController
#else
public typealias SFSafariViewControllerBase = NSObject
#endif

/// A constructible presentation shell. It preserves the requested URL and
/// copied configuration but deliberately never claims that Safari loaded it.
@MainActor
open class SFSafariViewController: SFSafariViewControllerBase {
    public typealias Configuration = SFSafariViewControllerConfiguration

    public let initialURL: URL
    public let configuration: Configuration
    public weak var delegate: SFSafariViewControllerDelegate?
    public var dismissButtonStyle: DismissButtonStyle = .done
    public let portableError = SafariServicesPortableError(
        .browserServiceUnavailable
    )

#if canImport(UIKit) || canImport(OpenUIKit)
    public var preferredBarTintColor: UIColor?
    public var preferredControlTintColor: UIColor?
#endif

    public enum DismissButtonStyle: Int, Sendable {
        case done = 0
        case close = 1
        case cancel = 2
    }

    public final class DataStore: NSObject {
        public static let `default` = DataStore()

        private override init() {
            super.init()
        }

        /// Linux has no Safari website-data store. The completion runs after
        /// return on a private serial queue; no cookies or caches are touched.
        public func clearWebsiteData(completionHandler completion: (() -> Void)? = nil) {
            SafariServicesHost.dataStoreQueue.async {
                completion?()
            }
        }
    }

    public final class PrewarmingToken: NSObject {
        public private(set) var isInvalidated = false

        fileprivate override init() {
            super.init()
        }

        public func invalidate() {
            isInvalidated = true
        }
    }

    public convenience init(url URL: URL) {
        self.init(url: URL, configuration: Configuration())
    }

    public convenience init(URL: URL) {
        self.init(url: URL)
    }

    public init(url URL: URL, entersReaderIfAvailable: Bool) {
        initialURL = URL
        let configuration = Configuration()
        configuration.entersReaderIfAvailable = entersReaderIfAvailable
        self.configuration = configuration.copy()
#if canImport(UIKit) || canImport(OpenUIKit)
        super.init(nibName: nil, bundle: nil)
#else
        super.init()
#endif
    }

    public convenience init(URL: URL, entersReaderIfAvailable: Bool) {
        self.init(url: URL, entersReaderIfAvailable: entersReaderIfAvailable)
    }

    public init(url URL: URL, configuration: Configuration) {
        initialURL = URL
        self.configuration = configuration.copy()
#if canImport(UIKit) || canImport(OpenUIKit)
        super.init(nibName: nil, bundle: nil)
#else
        super.init()
#endif
    }

    public convenience init(URL: URL, configuration: Configuration) {
        self.init(url: URL, configuration: configuration)
    }

    public override init() {
        initialURL = URL(string: "about:blank")!
        configuration = Configuration()
#if canImport(UIKit) || canImport(OpenUIKit)
        super.init()
#else
        super.init()
#endif
    }

    /// Hosts call this when presentation begins. The callback is explicitly a
    /// failed initial load; no network request or renderer is started.
    public func reportPortableInitialLoadFailure() {
        delegate?.safariViewController(self, didCompleteInitialLoad: false)
    }

    /// Records the requested URLs but never opens sockets. Linux has no Safari
    /// process to prewarm.
    public static func prewarmConnections(to URLs: [URL]) -> PrewarmingToken {
        _ = URLs
        return PrewarmingToken()
    }
}

public final class SFSafariViewControllerConfiguration: NSObject {
    public var entersReaderIfAvailable = false
    public var barCollapsingEnabled = true

    public override init() {
        super.init()
    }

    public func copy() -> SFSafariViewControllerConfiguration {
        let copy = SFSafariViewControllerConfiguration()
        copy.entersReaderIfAvailable = entersReaderIfAvailable
        copy.barCollapsingEnabled = barCollapsingEnabled
        return copy
    }
}

/// Safari Reading List write access. Linux never persists an item.
public final class SSReadingList: NSObject {
    private static let shared = SSReadingList()

    private override init() {
        super.init()
    }

    public static func `default`() -> SSReadingList? {
        shared
    }

    /// Publicly documented Safari Reading List schemes are `http` and `https`.
    public static func supportsURL(_ URL: URL) -> Bool {
        guard let scheme = URL.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    public func addItem(with URL: URL, title: String?, previewText: String?) throws {
        _ = title
        _ = previewText
        if !Self.supportsURL(URL) {
            throw SSReadingListError(.urlSchemeNotAllowed)
        }
        throw SafariServicesPortableError(.browserServiceUnavailable)
    }
}

public final class SFAuthenticationSession: NSObject {
    public typealias CompletionHandler = (URL?, (any Error)?) -> Void

    private let url: URL
    private let callbackURLScheme: String?
    private let completionHandler: CompletionHandler
    private var didStart = false
    private var didCancel = false

    public init(
        url URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping CompletionHandler
    ) {
        self.url = URL
        self.callbackURLScheme = callbackURLScheme
        self.completionHandler = completionHandler
        super.init()
    }

    public convenience init(
        URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping CompletionHandler
    ) {
        self.init(
            url: URL,
            callbackURLScheme: callbackURLScheme,
            completionHandler: completionHandler
        )
    }

    /// Linux cannot present Safari authentication UI. `start` returns `false`
    /// and does not invoke the completion handler.
    public func start() -> Bool {
        didStart = true
        return false
    }

    public func cancel() {
        didCancel = true
        _ = url
        _ = callbackURLScheme
        _ = didStart
        _ = didCancel
        _ = completionHandler
    }
}

/// Protocol for Add to Home Screen activity items. Methods that require
/// BrowserEngineKit `BEWebAppManifest` or `NSItemProvider` are omitted on
/// this isolated host.
public protocol SFAddToHomeScreenActivityItem: AnyObject {
    var url: URL { get }
    var title: String { get }
}
