// Reusable first-party WebKit configuration and data-store surface.
//
// The portable framework deliberately has no network or rendering engine.
// These objects nevertheless have real identity, copying, mutation, and
// completion semantics so an application can construct its first screen and
// configure a future engine without receiving fabricated browsing results.

@_exported import Foundation
#if canImport(UIKit)
@_exported import UIKit
#elseif canImport(OpenUIKit)
@_exported import OpenUIKit
#else
#error("WebKit requires UIKit or OpenUIKit")
#endif

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

@preconcurrency @MainActor
open class WKPreferences: NSObject {
    open var minimumFontSize: CGFloat = 0
    open var javaScriptCanOpenWindowsAutomatically = false
    open var fraudulentWebsiteWarningEnabled = true
    open var shouldPrintBackgrounds = false
    open var textInteractionEnabled = true
    open var siteSpecificQuirksModeEnabled = true
    open var elementFullscreenEnabled = false

    public override init() {
        super.init()
    }
}

@preconcurrency @MainActor
open class WKWebpagePreferences: NSObject {
    public enum ContentMode: Int, Sendable {
        case recommended = 0
        case mobile = 1
        case desktop = 2
    }

    open var preferredContentMode: ContentMode = .recommended
    open var allowsContentJavaScript = true

    public override init() {
        super.init()
    }

    internal func _portableCopy() -> WKWebpagePreferences {
        let result = WKWebpagePreferences()
        result.preferredContentMode = preferredContentMode
        result.allowsContentJavaScript = allowsContentJavaScript
        return result
    }
}

@preconcurrency @MainActor
open class WKWebsiteDataStore: NSObject {
    private static let persistentStore = WKWebsiteDataStore(isPersistent: true)

    public let isPersistent: Bool

    private init(isPersistent: Bool) {
        self.isPersistent = isPersistent
        super.init()
    }

    public static func `default`() -> WKWebsiteDataStore {
        persistentStore
    }

    public static func nonPersistent() -> WKWebsiteDataStore {
        WKWebsiteDataStore(isPersistent: false)
    }

    public static func allWebsiteDataTypes() -> Set<String> {
        [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeFetchCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeOfflineWebApplicationCache,
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeWebSQLDatabases,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeServiceWorkerRegistrations,
            WKWebsiteDataTypeFileSystem,
        ]
    }

    open func removeData(
        ofTypes dataTypes: Set<String>,
        modifiedSince date: Date,
        completionHandler: @escaping () -> Void
    ) {
        // No engine means this store has never persisted website data.  The
        // requested postcondition is therefore already true; completing once
        // is honest and prevents privacy/erase flows from hanging.
        completionHandler()
    }
}

public let WKWebsiteDataTypeFetchCache = "WKWebsiteDataTypeFetchCache"
public let WKWebsiteDataTypeDiskCache = "WKWebsiteDataTypeDiskCache"
public let WKWebsiteDataTypeMemoryCache = "WKWebsiteDataTypeMemoryCache"
public let WKWebsiteDataTypeOfflineWebApplicationCache =
    "WKWebsiteDataTypeOfflineWebApplicationCache"
public let WKWebsiteDataTypeCookies = "WKWebsiteDataTypeCookies"
public let WKWebsiteDataTypeSessionStorage = "WKWebsiteDataTypeSessionStorage"
public let WKWebsiteDataTypeLocalStorage = "WKWebsiteDataTypeLocalStorage"
public let WKWebsiteDataTypeWebSQLDatabases = "WKWebsiteDataTypeWebSQLDatabases"
public let WKWebsiteDataTypeIndexedDBDatabases =
    "WKWebsiteDataTypeIndexedDBDatabases"
public let WKWebsiteDataTypeServiceWorkerRegistrations =
    "WKWebsiteDataTypeServiceWorkerRegistrations"
public let WKWebsiteDataTypeFileSystem = "WKWebsiteDataTypeFileSystem"

@preconcurrency @MainActor
open class WKWebViewConfiguration: NSObject {
    open var preferences: WKPreferences
    open var userContentController: WKUserContentController
    open var websiteDataStore: WKWebsiteDataStore
    open var defaultWebpagePreferences: WKWebpagePreferences
    open var suppressesIncrementalRendering = false
    open var applicationNameForUserAgent: String? = "Mobile/15E148"
    open var allowsAirPlayForMediaPlayback = true
    open var upgradeKnownHostsToHTTPS = true
    open var limitsNavigationsToAppBoundDomains = false
    open var allowsInlineMediaPlayback = false
    open var ignoresViewportScaleLimits = false

    public override init() {
        self.preferences = WKPreferences()
        self.userContentController = WKUserContentController()
        self.websiteDataStore = .default()
        self.defaultWebpagePreferences = WKWebpagePreferences()
        super.init()
    }

    internal func _portableCopyForWebView() -> WKWebViewConfiguration {
        let result = WKWebViewConfiguration()
        // iOS 26.1 copies the configuration shell but keeps these configured
        // objects by identity.  A simulator oracle pins that distinction.
        result.preferences = preferences
        result.userContentController = userContentController
        result.websiteDataStore = websiteDataStore
        result.defaultWebpagePreferences = defaultWebpagePreferences
        result.suppressesIncrementalRendering = suppressesIncrementalRendering
        result.applicationNameForUserAgent = applicationNameForUserAgent
        result.allowsAirPlayForMediaPlayback = allowsAirPlayForMediaPlayback
        result.upgradeKnownHostsToHTTPS = upgradeKnownHostsToHTTPS
        result.limitsNavigationsToAppBoundDomains = limitsNavigationsToAppBoundDomains
        result.allowsInlineMediaPlayback = allowsInlineMediaPlayback
        result.ignoresViewportScaleLimits = ignoresViewportScaleLimits
        return result
    }
}
