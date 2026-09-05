@_exported import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

@preconcurrency @MainActor
open class WKProcessPool: NSObject {
    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }
}

@preconcurrency @MainActor
open class WKContentWorld: NSObject {
    public let name: String?

    private init(name: String?) {
        self.name = name
        super.init()
    }

    public static let page = WKContentWorld(name: nil)
    public static let defaultClient = WKContentWorld(name: nil)

    public static func world(name: String) -> WKContentWorld {
        WKContentWorld(name: name)
    }
}

@preconcurrency @MainActor
open class WKSecurityOrigin: NSObject {
    public let `protocol`: String
    public let host: String
    public let port: Int

    public init(protocol: String = "https", host: String = "", port: Int = 0) {
        self.protocol = `protocol`
        self.host = host
        self.port = port
        super.init()
    }
}

@preconcurrency @MainActor
open class WKWebsiteDataRecord: NSObject {
    public let displayName: String
    public let dataTypes: Set<String>

    public init(displayName: String = "", dataTypes: Set<String> = []) {
        self.displayName = displayName
        self.dataTypes = dataTypes
        super.init()
    }
}

@preconcurrency @MainActor
public protocol WKHTTPCookieStoreObserver: AnyObject {
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore)
}

@MainActor
public extension WKHTTPCookieStoreObserver {
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        _ = cookieStore
    }
}

@preconcurrency @MainActor
open class WKHTTPCookieStore: NSObject {
    public enum CookiePolicy: Int, Hashable, Sendable {
        case allow = 0
        case disallow = 1
    }

    private var cookies: [HTTPCookie] = []
    private var observers: [ObjectIdentifier: WKHTTPCookieStoreObserver] = [:]
    public private(set) var cookiePolicy: CookiePolicy = .allow

    public override init() {
        super.init()
    }

    open func add(_ observer: WKHTTPCookieStoreObserver) {
        observers[ObjectIdentifier(observer)] = observer
    }

    open func remove(_ observer: WKHTTPCookieStoreObserver) {
        observers.removeValue(forKey: ObjectIdentifier(observer))
    }

    open func setCookie(_ cookie: HTTPCookie, completionHandler: (() -> Void)? = nil) {
        _portableSetCookie(cookie)
        completionHandler?()
    }

    open func setCookie(_ cookie: HTTPCookie) async {
        _portableSetCookie(cookie)
    }

    open func setCookies(_ newCookies: [HTTPCookie]) async {
        for cookie in newCookies {
            _portableSetCookie(cookie)
        }
    }

    open func delete(_ cookie: HTTPCookie, completionHandler: (() -> Void)? = nil) {
        cookies.removeAll { $0.name == cookie.name && $0.domain == cookie.domain && $0.path == cookie.path }
        notifyObservers()
        completionHandler?()
    }

    open func getAllCookies(_ completionHandler: @escaping ([HTTPCookie]) -> Void) {
        completionHandler(cookies)
    }

    open func allCookies() async -> [HTTPCookie] {
        cookies
    }

    open func getCookiePolicy(_ completionHandler: @escaping (CookiePolicy) -> Void) {
        completionHandler(cookiePolicy)
    }

    open func setCookiePolicy(_ policy: CookiePolicy, completionHandler: (() -> Void)? = nil) {
        cookiePolicy = policy
        completionHandler?()
    }

    open func setCookiePolicy(_ policy: CookiePolicy) async {
        cookiePolicy = policy
    }

    internal var _portableCookies: [HTTPCookie] { cookies }

    internal func _portableRemoveAll() {
        guard !cookies.isEmpty else { return }
        cookies.removeAll(keepingCapacity: false)
        notifyObservers()
    }

    private func _portableSetCookie(_ cookie: HTTPCookie) {
        guard cookiePolicy == .allow else { return }
        cookies.removeAll { $0.name == cookie.name && $0.domain == cookie.domain && $0.path == cookie.path }
        cookies.append(cookie)
        notifyObservers()
    }

    private func notifyObservers() {
        for observer in observers.values {
            observer.cookiesDidChange(in: self)
        }
    }
}

@preconcurrency @MainActor
public protocol WKURLSchemeTask: AnyObject {
    var request: URLRequest { get }
    func didReceive(_ response: URLResponse)
    func didReceive(_ data: Data)
    func didFinish()
    func didFailWithError(_ error: any Error)
}

@preconcurrency @MainActor
public protocol WKURLSchemeHandler: AnyObject {
    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask)
    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask)
}

@preconcurrency @MainActor
open class WKFindConfiguration: NSObject {
    open var backwards = false
    open var caseSensitive = false
    open var wraps = true

    public override init() {
        super.init()
    }
}

@preconcurrency @MainActor
open class WKFindResult: NSObject {
    public let matchFound: Bool

    public init(matchFound: Bool = false) {
        self.matchFound = matchFound
        super.init()
    }
}

@preconcurrency @MainActor
open class WKSnapshotConfiguration: NSObject {
    open var rect: CGRect = .zero
    open var snapshotWidth: NSNumber?
    open var afterScreenUpdates = true

    public override init() {
        super.init()
    }
}

@preconcurrency @MainActor
open class WKPDFConfiguration: NSObject {
    open var rect: CGRect = .null
    open var allowTransparentBackground = false

    public override init() {
        super.init()
    }
}

@preconcurrency @MainActor
open class WKOpenPanelParameters: NSObject {
    public let allowsMultipleSelection: Bool
    public let allowsDirectories: Bool

    public init(allowsMultipleSelection: Bool = false, allowsDirectories: Bool = false) {
        self.allowsMultipleSelection = allowsMultipleSelection
        self.allowsDirectories = allowsDirectories
        super.init()
    }
}

@preconcurrency @MainActor
open class WKPreviewElementInfo: NSObject {
    public let linkURL: URL?

    public init(linkURL: URL? = nil) {
        self.linkURL = linkURL
        super.init()
    }
}

@preconcurrency @MainActor
open class WKDownload: NSObject {
    public enum PlaceholderPolicy: Int, Hashable, Sendable {
        case disable = 0
        case enable = 1
    }

    public enum RedirectPolicy: Int, Hashable, Sendable {
        case cancel = 0
        case allow = 1
    }

    public private(set) var originalRequest: URLRequest?
    public private(set) weak var webView: WKWebView?
    public weak var delegate: WKDownloadDelegate?
    public private(set) var isUserInitiated = false
    public private(set) var originatingFrame = WKFrameInfo()

    internal init(request: URLRequest?, webView: WKWebView?, userInitiated: Bool = false) {
        self.originalRequest = request
        self.webView = webView
        self.isUserInitiated = userInitiated
        if let request {
            self.originatingFrame = WKFrameInfo(isMainFrame: true, request: request)
        }
        super.init()
    }

    open func cancel(_ completionHandler: ((Data?) -> Void)? = nil) {
        completionHandler?(nil)
    }
}

@preconcurrency @MainActor
public protocol WKDownloadDelegate: AnyObject {
    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    )
    func download(
        _ download: WKDownload,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest: URLRequest,
        decisionHandler: @escaping (WKDownload.RedirectPolicy) -> Void
    )
    func downloadDidFinish(_ download: WKDownload)
    func download(_ download: WKDownload, didFailWithError error: any Error, resumeData: Data?)
    func download(
        _ download: WKDownload,
        decidePlaceholderPolicy completionHandler: @escaping (WKDownload.PlaceholderPolicy, URL?) -> Void
    )
    func download(
        _ download: WKDownload,
        didReceivePlaceholderURL url: URL,
        completionHandler: @escaping () -> Void
    )
    func download(_ download: WKDownload, didReceiveFinalURL url: URL)
}

@MainActor
public extension WKDownloadDelegate {
    func download(
        _ download: WKDownload,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest: URLRequest,
        decisionHandler: @escaping (WKDownload.RedirectPolicy) -> Void
    ) {
        _ = (download, response, newRequest)
        decisionHandler(.cancel)
    }

    func downloadDidFinish(_ download: WKDownload) {
        _ = download
    }

    func download(_ download: WKDownload, didFailWithError error: any Error, resumeData: Data?) {
        _ = (download, error, resumeData)
    }

    func download(
        _ download: WKDownload,
        decidePlaceholderPolicy completionHandler: @escaping (WKDownload.PlaceholderPolicy, URL?) -> Void
    ) {
        completionHandler(.disable, nil)
    }

    func download(
        _ download: WKDownload,
        didReceivePlaceholderURL url: URL,
        completionHandler: @escaping () -> Void
    ) {
        _ = url
        completionHandler()
    }

    func download(_ download: WKDownload, didReceiveFinalURL url: URL) {
        _ = (download, url)
    }
}

@preconcurrency @MainActor
public protocol WKScriptMessageHandlerWithReply: AnyObject {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    )
}

@MainActor
public extension WKScriptMessageHandlerWithReply {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    ) {
        _ = (userContentController, message)
        replyHandler(nil, "WKErrorDomain")
    }
}
