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

    // Local-only navigation completes synchronously on the host and buffers
    // its events. No Web Content process, script execution, or fetch is implied.
    // Native 26.1 oracle: simulated A emits started/committed/finished, title
    // Alpha, progress 1, and one history entry; plain HTML/data add no entry.
    @discardableResult
    public func load(simulatedRequest request: URLRequest, responseHTML htmlString: String)
        -> some AsyncSequence<NavigationEvent, any Error> {
        guard let url = request.url else { return failedNavigation(.invalidURL) }
        return commitLocal(htmlString, mimeType: "text/html", url: url, addsHistory: true)
    }

    @discardableResult
    public func load(simulatedRequest request: URLRequest, response: URLResponse, responseData: Data)
        -> some AsyncSequence<NavigationEvent, any Error> {
        guard let url = request.url else { return failedNavigation(.invalidURL) }
        let encoding: String.Encoding
        switch response.textEncodingName?.lowercased() {
        case "utf-8", "utf8": encoding = .utf8
        case "utf-16", "utf16": encoding = .utf16
        case nil, "iso-8859-1", "windows-1252": encoding = .windowsCP1252
        default: return unavailableNavigation("WebPage.load unsupported text encoding")
        }
        guard let document = decodeLocalText(responseData, encoding: encoding) else {
            return unavailableNavigation("WebPage.load invalid text data")
        }
        // The native response-URL mismatch probe retains the request URL in
        // page.url, Item.url, and Item.initialURL (A, not response URL B).
        return commitLocal(document, mimeType: response.mimeType ?? "application/octet-stream",
                           url: url, addsHistory: true)
    }

    @discardableResult
    public func load(html: String, baseURL: URL = URL(string: "about:blank")!)
        -> some AsyncSequence<NavigationEvent, any Error> {
        commitLocal(html, mimeType: "text/html", url: baseURL, addsHistory: false)
    }

    @discardableResult
    public func load(_ data: Data, mimeType: String, characterEncoding: String.Encoding, baseURL: URL)
        -> some AsyncSequence<NavigationEvent, any Error> {
        guard let document = decodeLocalText(data, encoding: characterEncoding) else {
            return unavailableNavigation("WebPage.load invalid text data")
        }
        return commitLocal(document, mimeType: mimeType, url: baseURL, addsHistory: false)
    }

    @discardableResult
    public func load(_ item: BackForwardList.Item)
        -> some AsyncSequence<NavigationEvent, any Error> {
        guard let storage = backForwardList.storage,
              let index = storage.entries.firstIndex(where: { $0.token == item.entryToken }) else {
            return failedNavigation(.invalidURL)
        }
        storage.index = index
        let entry = storage.entries[index]
        return commitLocal(entry.document, mimeType: entry.mimeType, url: entry.url, addsHistory: false)
    }

    @discardableResult
    public func load(_ request: URLRequest) -> some AsyncSequence<NavigationEvent, any Error> {
        guard request.url != nil else { return failedNavigation(.invalidURL) }
        return unavailableNavigation("WebPage.load requires a Web Content process")
    }

    @discardableResult
    public func load(_ url: URL?) -> some AsyncSequence<NavigationEvent, any Error> {
        guard url != nil else { return failedNavigation(.invalidURL) }
        return unavailableNavigation("WebPage.load requires a Web Content process")
    }

    @discardableResult
    public func reload(fromOrigin: Bool = false) -> some AsyncSequence<NavigationEvent, any Error> {
        unavailableNavigation("WebPage.reload requires a Web Content process")
    }

    public func goBack() {
        if let item = backForwardList[-1] { load(item) }
    }
    public func goForward() {
        if let item = backForwardList[1] { load(item) }
    }

    private func failedNavigation(_ error: NavigationError) -> AsyncThrowingStream<NavigationEvent, any Error> {
        AsyncThrowingStream { $0.finish(throwing: error) }
    }

    private func unavailableNavigation(_ operation: String) -> AsyncThrowingStream<NavigationEvent, any Error> {
        failedNavigation(.failedProvisionalNavigation(WKPortableUnknown(operation)))
    }

    private func decodeLocalText(_ data: Data, encoding: String.Encoding) -> String? {
        guard encoding == .isoLatin1 || encoding == .windowsCP1252 else {
            return String(data: data, encoding: encoding)
        }
        // iPhone 17 Pro / iOS 26.1 legacy encoding probe: nil, iso-8859-1,
        // and windows-1252 all map bytes 0x80...0x9f to these 32 scalars.
        // Undefined CP1252 positions retain C1 controls; Linux Foundation's
        // strict decoder rejects those bytes, so preserve the measured values.
        let c1: [UInt32] = [
            8364, 129, 8218, 402, 8222, 8230, 8224, 8225,
            710, 8240, 352, 8249, 338, 141, 381, 143,
            144, 8216, 8217, 8220, 8221, 8226, 8211, 8212,
            732, 8482, 353, 8250, 339, 157, 382, 376
        ]
        var result = ""
        for byte in data {
            let scalar = (0x80...0x9f).contains(byte) ? c1[Int(byte) - 0x80] : UInt32(byte)
            result.unicodeScalars.append(UnicodeScalar(scalar)!)
        }
        return result
    }

    private func commitLocal(_ document: String, mimeType: String, url: URL, addsHistory: Bool)
        -> AsyncThrowingStream<NavigationEvent, any Error> {
        let mime = mimeType.lowercased()
        guard mime == "text/html" || mime == "text/plain" else {
            return unavailableNavigation("WebPage.load unsupported MIME type")
        }
        let parsedTitle = mime == "text/html" ? WKPortableHTMLTitle(document) : nil
        self.url = url
        title = parsedTitle ?? ""
        estimatedProgress = 1
        isLoading = false
        // Only the supplied local document is modelled. Subresource loading,
        // redirects, JavaScript, and rendering remain unsupported.
        hasOnlySecureContent = url.scheme?.lowercased() == "https"
        if addsHistory {
            let entry = WebPageHistoryEntry(url: url, title: parsedTitle,
                                            document: document, mimeType: mime)
            if let storage = backForwardList.storage {
                storage.append(entry)
            } else {
                backForwardList = BackForwardList(storage: WebPageHistoryStorage(first: entry))
            }
        } else if let storage = backForwardList.storage {
            // Native HTML-after-back probe: keep history URL/forward entries,
            // update its title, and restore the original document on revisit.
            storage.entries[storage.index].title = parsedTitle
        }
        return AsyncThrowingStream { continuation in
            continuation.yield(.startedProvisionalNavigation)
            continuation.yield(.committed)
            continuation.yield(.finished)
            continuation.finish()
        }
    }

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
