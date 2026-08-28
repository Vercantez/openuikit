// A WebKit stub with TWO CLASSES OF MEMBER, and the split is the whole design.
//
// MEASURED (full/ladder/focus-ios-scope-2026-08-28.md): focus-ios names 28
// WebKit types in 78 places across 6 files. The launch path was TRACED, not
// guessed:
//
//     BrowserViewController.viewDidLoad()                    :169
//       → :189  webViewController.delegate = self            forces the lazy var
//           → WebViewController.init                         :93
//               → :101 setupWebview()
//                   → :168 browserView = WKWebView(frame:configuration:)
//
// so a WKWebView object IS constructed before first render. But viewDidLoad:197
// also sets `webViewContainer.isHidden = true`, and it only unhides at :930 on
// URL submission. **The first interactive screen is the home screen, and it
// needs a web view that EXISTS, not one that WORKS.**
//
// CLASS 1 — INERT BUT REAL (constructible, no engine). These are on the launch
// path. They must not trap, because trapping here means the app never renders.
// They also must not pretend to browse: a `load()` that silently succeeds would
// leave the URL bar in browsing mode with a blank page and no error, which is
// the worst of both. So navigation methods are inert AND the view stays empty.
//
// CLASS 2 — DIE LOUDLY. Everything reachable only once the user actually
// browses: content-rule compilation, data-store purging, JS evaluation,
// back/forward. Each traps with the name of what was called. A plausible return
// value from any of these would be a fabricated browsing result, and this
// project's rule is that a stub which cannot answer must say so at the call
// site rather than hand back something that looks like an answer.
//
// WHAT THIS IS NOT: a web engine, or a step toward one. It is the minimum that
// lets launch-to-first-screen be measured. Everything in class 2 is a marker for
// work that has not been done.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Class 1: inert but real

public class WKWebViewConfiguration: NSObject {
    public var websiteDataStore = WKWebsiteDataStore.default()
    public var allowsInlineMediaPlayback = false
    public var applicationNameForUserAgent: String?
    public var upgradeKnownHostsToHTTPS = false
    public var userContentController = WKUserContentController()
    public var ignoresViewportScaleLimits = false
    public override init() { super.init() }
}

public class WKUserContentController: NSObject {
    public override init() { super.init() }
    public func addUserScript(_ userScript: WKUserScript) {}
    public func removeAllUserScripts() {}
    public func add(_ scriptMessageHandler: WKScriptMessageHandler, name: String) {}
    public func removeScriptMessageHandler(forName name: String) {}
    public func add(_ contentRuleList: WKContentRuleList) {}
    public func removeAllContentRuleLists() {}
}

public class WKUserScript: NSObject {
    public enum InjectionTime: Int { case atDocumentStart = 0, atDocumentEnd = 1 }
    public let source: String
    public init(source: String, injectionTime: InjectionTime, forMainFrameOnly: Bool) {
        self.source = source
        super.init()
    }
}
public typealias WKUserScriptInjectionTime = WKUserScript.InjectionTime

public class WKWebsiteDataStore: NSObject {
    private static let shared = WKWebsiteDataStore()
    public static func `default`() -> WKWebsiteDataStore { shared }
    /// The app's privacy story: every session is non-persistent. Returning a
    /// fresh empty store is not a stand-in — with no engine there is genuinely
    /// nothing persisted.
    public static func nonPersistent() -> WKWebsiteDataStore { WKWebsiteDataStore() }

    public func removeData(ofTypes dataTypes: Set<String>,
                           modifiedSince date: Date,
                           completionHandler: @escaping () -> Void) {
        // Nothing was ever stored, so "it is gone" is true. Calling back is
        // required: the erase flow waits on this and would hang otherwise.
        completionHandler()
    }
}

public let WKWebsiteDataTypeDiskCache = "WKWebsiteDataTypeDiskCache"
public let WKWebsiteDataTypeMemoryCache = "WKWebsiteDataTypeMemoryCache"
public let WKWebsiteDataTypeCookies = "WKWebsiteDataTypeCookies"
public let WKWebsiteDataTypeLocalStorage = "WKWebsiteDataTypeLocalStorage"
public let WKWebsiteDataTypeSessionStorage = "WKWebsiteDataTypeSessionStorage"
public let WKWebsiteDataTypeIndexedDBDatabases = "WKWebsiteDataTypeIndexedDBDatabases"
public let WKWebsiteDataTypeWebSQLDatabases = "WKWebsiteDataTypeWebSQLDatabases"
public let WKWebsiteDataTypeOfflineWebApplicationCache = "WKWebsiteDataTypeOfflineWebApplicationCache"

public class WKNavigation: NSObject {}
public class WKBackForwardListItem: NSObject { public var url = URL(string: "about:blank")! }
public class WKWebpagePreferences: NSObject {
    public var preferredContentMode: ContentMode = .recommended
    public var allowsContentJavaScript = true
    public enum ContentMode: Int { case recommended = 0, mobile = 1, desktop = 2 }
    public override init() { super.init() }
}
public class WKWindowFeatures: NSObject {}
public class WKContextMenuElementInfo: NSObject { public var linkURL: URL? }

public class WKNavigationAction: NSObject {
    public var request = URLRequest(url: URL(string: "about:blank")!)
    public var navigationType: WKNavigationType = .other
    public var targetFrame: WKFrameInfo?
}
public enum WKNavigationType: Int { case linkActivated = 0, formSubmitted, backForward, reload, formResubmitted, other = -1 }
public class WKFrameInfo: NSObject { public var isMainFrame = true }
public class WKNavigationResponse: NSObject {
    public var response: URLResponse = URLResponse()
    public var canShowMIMEType = true
}
public enum WKNavigationActionPolicy: Int { case cancel = 0, allow = 1, download = 2 }
public enum WKNavigationResponsePolicy: Int { case cancel = 0, allow = 1, download = 2 }

public class WKScriptMessage: NSObject {
    public var name: String = ""
    public var body: Any = [:]
}

public protocol WKScriptMessageHandler: AnyObject {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage)
}

#if canImport(UIKit)
/// The object the launch path constructs. A real UIView so it can be added to
/// the container hierarchy, sized and hidden exactly as the app expects.
open class WKWebView: UIView {
    public let configuration: WKWebViewConfiguration
    public weak var navigationDelegate: WKNavigationDelegate?
    public weak var uiDelegate: WKUIDelegate?
    public var allowsBackForwardNavigationGestures = false
    public var allowsLinkPreview = false
    public var customUserAgent: String?

    /// Deliberately empty and NOT nil: the app reads `url` to drive the URL bar,
    /// and there is no page, so there is no URL. `nil` is the honest answer.
    public var url: URL?
    public var title: String?
    public var estimatedProgress: Double = 0
    public var isLoading = false
    public var canGoBack = false
    public var canGoForward = false
    public var scrollView = UIScrollView()

    public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        self.configuration = configuration
        super.init(frame: frame)
    }
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not used by focus-ios") }

    // Navigation entry points are INERT, not fake-successful. Nothing loads and
    // no delegate callback is synthesised, so the app stays on its home screen
    // rather than entering browsing mode against a blank page.
    @discardableResult public func load(_ request: URLRequest) -> WKNavigation? { nil }
    @discardableResult public func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? { nil }
    public func stopLoading() {}

    // Class 2 on an otherwise class-1 object.
    @discardableResult public func reload() -> WKNavigation? {
        _wkUnimplemented("WKWebView.reload()")
    }
    @discardableResult public func goBack() -> WKNavigation? {
        _wkUnimplemented("WKWebView.goBack()")
    }
    @discardableResult public func goForward() -> WKNavigation? {
        _wkUnimplemented("WKWebView.goForward()")
    }
    public func evaluateJavaScript(_ javaScriptString: String,
                                   completionHandler: ((Any?, Error?) -> Void)? = nil) {
        _wkUnimplemented("WKWebView.evaluateJavaScript(\(javaScriptString.prefix(40)))")
    }
}

public protocol WKNavigationDelegate: AnyObject {}
public protocol WKUIDelegate: AnyObject {}
#endif

// MARK: - Class 2: die loudly

@inline(never)
public func _wkUnimplemented(_ what: String) -> Never {
    fatalError("WebKit stub: \(what) was reached. This build has NO web engine — "
             + "it exists to prove launch-to-first-screen, and anything that "
             + "actually browses is unimplemented rather than faked. "
             + "See full/focus-ios/README.md.")
}

public class WKContentRuleList: NSObject {
    public var identifier: String = ""
}

public class WKContentRuleListStore: NSObject {
    public static func `default`() -> WKContentRuleListStore { WKContentRuleListStore() }

    public func compileContentRuleList(forIdentifier identifier: String,
                                       encodedContentRuleList: String?,
                                       completionHandler: @escaping (WKContentRuleList?, Error?) -> Void) {
        _wkUnimplemented("WKContentRuleListStore.compileContentRuleList(\(identifier))")
    }
    public func lookUpContentRuleList(forIdentifier identifier: String,
                                      completionHandler: @escaping (WKContentRuleList?, Error?) -> Void) {
        _wkUnimplemented("WKContentRuleListStore.lookUpContentRuleList(\(identifier))")
    }
    public func removeContentRuleList(forIdentifier identifier: String,
                                      completionHandler: @escaping (Error?) -> Void) {
        _wkUnimplemented("WKContentRuleListStore.removeContentRuleList(\(identifier))")
    }
    public func getAvailableContentRuleListIdentifiers(_ completionHandler: @escaping ([String]?) -> Void) {
        _wkUnimplemented("WKContentRuleListStore.getAvailableContentRuleListIdentifiers()")
    }
}
