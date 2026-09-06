@_exported import Foundation

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

@preconcurrency @MainActor
public final class WebPage {
    public struct CSSMediaType: Hashable, Sendable, RawRepresentable {
        public typealias RawValue = String
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let all = CSSMediaType(rawValue: "all")
        public static let print = CSSMediaType(rawValue: "print")
        public static let screen = CSSMediaType(rawValue: "screen")
    }

    public struct DeviceSensorAuthorization: Hashable, Sendable {
        public enum Permission: Hashable, Sendable {
            case deviceOrientationAndMotion
            case mediaCapture(WKMediaCaptureType)
        }

        public enum PermissionPolicy: Int, Hashable, Sendable {
            case prompt = 0
            case grant = 1
            case deny = 2
        }
        public var permissionPolicy: PermissionPolicy
        public init(permissionPolicy: PermissionPolicy = .prompt) {
            self.permissionPolicy = permissionPolicy
        }
    }

    // Exact case names and Hashable conformance: Xcode 26.1 graph and digester.
    public enum NavigationEvent: Hashable, Sendable {
        case startedProvisionalNavigation
        case receivedServerRedirect
        case committed
        case finished
    }

    public struct BackForwardList {
        public var currentItem: WKBackForwardListItem? { nil }
        public var backList: [WKBackForwardListItem] { [] }
        public var forwardList: [WKBackForwardListItem] { [] }
    }

    @MainActor
    public struct Configuration {
        public enum MediaPlaybackBehavior: Hashable, Sendable {
            case automatic
            case alwaysFullscreen
            case allowsInlinePlayback
        }

        public var websiteDataStore = WKWebsiteDataStore.default()
        public var dataDetectorTypes: WKDataDetectorTypes = []
        public var loadsSubresources = true
        public var urlSchemeHandlers: [URLScheme: any URLSchemeHandler] = [:]
        public var mediaPlaybackBehavior: MediaPlaybackBehavior = .automatic
        public var userContentController = WKUserContentController()
        public var webExtensionController: WKWebExtensionController?
        public var allowsInlinePredictions = false
        public var upgradeKnownHostsToHTTPS = true
        public var deviceSensorAuthorization = DeviceSensorAuthorization()
        public var ignoresViewportScaleLimits = false
        public var supportsAdaptiveImageGlyph = false
        public var applicationNameForUserAgent: String?
        public var defaultNavigationPreferences = NavigationPreferences()
        public var allowsAirPlayForMediaPlayback = true
        public var suppressesIncrementalRendering = false
        public var showsSystemScreenTimeBlockingView = true
        public var limitsNavigationsToAppBoundDomains = false

        public init() {}
    }

    public var configuration: Configuration
    public var isInspectable = false
    private var storedCustomUserAgent = ""
    // Private iPhone 17 Pro / iOS 26.1 value probe: initial and nil-reset
    // both read Optional(""); explicit nonempty strings round-trip unchanged.
    public var customUserAgent: String? {
        get { storedCustomUserAgent }
        set { storedCustomUserAgent = newValue ?? "" }
    }
    public var mediaType: CSSMediaType?
    public private(set) var isLoading = false
    public private(set) var title: String = ""
    public private(set) var url: URL?
    public private(set) var estimatedProgress: Double = 0
    public private(set) var hasOnlySecureContent = false
    public private(set) var backForwardList = BackForwardList()
    public var navigations: some AsyncSequence<NavigationEvent, any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public convenience init() {
        self.init(configuration: Configuration())
    }

    public convenience init(configuration: Configuration, navigationDecider: Any?) {
        _ = navigationDecider
        self.init(configuration: configuration)
    }

    public convenience init(configuration: Configuration, dialogPresenter: Any?) {
        _ = dialogPresenter
        self.init(configuration: configuration)
    }

    public convenience init(
        configuration: Configuration,
        navigationDecider: Any?,
        dialogPresenter: Any?
    ) {
        _ = (navigationDecider, dialogPresenter)
        self.init(configuration: configuration)
    }

    public func stopLoading() {
        isLoading = false
    }

    public func load(_ request: URLRequest) {
        url = request.url
        isLoading = false
    }

    public func reload() {}
    public func goBack() {}
    public func goForward() {}

    public func callJavaScript(
        _ javaScriptString: String,
        arguments: [String: Any] = [:],
        in frame: WKFrameInfo? = nil,
        contentWorld: WKContentWorld? = nil
    ) async throws -> Any? {
        _ = (javaScriptString, arguments, frame, contentWorld ?? .page)
        throw WKPortableUnknown("WebPage.callJavaScript")
    }
}

@preconcurrency @MainActor
public protocol URLSchemeHandler: AnyObject {
    associatedtype Result
    func reply(for request: URLRequest) async -> Result
}

public enum URLSchemeTaskResult: Sendable {
    case response(URLResponse, Data)
    case failure(any Error)
}
