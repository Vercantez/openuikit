// Reusable first-party WebKit configuration and data-store surface.
//
// The portable framework deliberately has no network or rendering engine.
// These objects nevertheless have real identity, copying, mutation, and
// completion semantics so an application can construct its first screen and
// configure a future engine without receiving fabricated browsing results.

@_exported import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
// UIKit/OpenUIKit types come from WebKit.swift (real import or Linux lookalikes).

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

@preconcurrency @MainActor
open class WKPreferences: NSObject {
    public enum InactiveSchedulingPolicy: Int, Hashable, Sendable {
        case suspend = 0
        case throttle = 1
        case none = 2
    }

    open var minimumFontSize: CGFloat = 0
    open var javaScriptCanOpenWindowsAutomatically = false
    open var javaScriptEnabled = true
    open var fraudulentWebsiteWarningEnabled = true
    open var shouldPrintBackgrounds = false
    open var textInteractionEnabled = true
    open var siteSpecificQuirksModeEnabled = true
    open var elementFullscreenEnabled = false
    open var inactiveSchedulingPolicy: InactiveSchedulingPolicy = .suspend

    open var isFraudulentWebsiteWarningEnabled: Bool {
        get { fraudulentWebsiteWarningEnabled }
        set { fraudulentWebsiteWarningEnabled = newValue }
    }
    open var isTextInteractionEnabled: Bool {
        get { textInteractionEnabled }
        set { textInteractionEnabled = newValue }
    }
    open var isSiteSpecificQuirksModeEnabled: Bool {
        get { siteSpecificQuirksModeEnabled }
        set { siteSpecificQuirksModeEnabled = newValue }
    }
    open var isElementFullscreenEnabled: Bool {
        get { elementFullscreenEnabled }
        set { elementFullscreenEnabled = newValue }
    }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }
}

@preconcurrency @MainActor
open class WKWebpagePreferences: NSObject {
    public enum ContentMode: Int, Hashable, Sendable {
        case recommended = 0
        case mobile = 1
        case desktop = 2
    }

    public enum UpgradeToHTTPSPolicy: Int, Hashable, Sendable {
        case keepAsRequested = 0
        case automaticFallbackToHTTP = 1
        case userMediatedFallbackToHTTP = 2
        case errorOnFailure = 3
    }

    open var preferredContentMode: ContentMode = .recommended
    open var allowsContentJavaScript = true
    open var isLockdownModeEnabled = false
    open var preferredHTTPSNavigationPolicy: UpgradeToHTTPSPolicy = .keepAsRequested

    public override init() {
        super.init()
    }

    internal func _portableCopy() -> WKWebpagePreferences {
        let result = WKWebpagePreferences()
        result.preferredContentMode = preferredContentMode
        result.allowsContentJavaScript = allowsContentJavaScript
        result.isLockdownModeEnabled = isLockdownModeEnabled
        result.preferredHTTPSNavigationPolicy = preferredHTTPSNavigationPolicy
        return result
    }
}

@preconcurrency @MainActor
open class WKWebsiteDataStore: NSObject {
    private static let persistentStore = WKWebsiteDataStore(isPersistent: true)

    public let isPersistent: Bool
    public let identifier: UUID?
    public let httpCookieStore = WKHTTPCookieStore()

    private init(isPersistent: Bool, identifier: UUID? = nil) {
        self.isPersistent = isPersistent
        self.identifier = identifier
        super.init()
    }

    public static func `default`() -> WKWebsiteDataStore {
        persistentStore
    }

    public static func nonPersistent() -> WKWebsiteDataStore {
        WKWebsiteDataStore(isPersistent: false)
    }

    public init(forIdentifier identifier: UUID) {
        self.isPersistent = true
        self.identifier = identifier
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.isPersistent = true
        self.identifier = nil
        super.init()
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
            WKWebsiteDataTypeHashSalt,
            WKWebsiteDataTypeMediaKeys,
            WKWebsiteDataTypeScreenTime,
            WKWebsiteDataTypeSearchFieldRecentSearches,
        ]
    }

    public static func fetchAllDataStoreIdentifiers(
        _ completionHandler: @escaping @MainActor ([UUID]) -> Void
    ) {
        completionHandler([])
    }

    public static func remove(forIdentifier identifier: UUID) async throws {
        _ = identifier
        throw WKPortableUnknown("WKWebsiteDataStore.remove(forIdentifier:)")
    }

    open func removeData(
        ofTypes dataTypes: Set<String>,
        modifiedSince date: Date,
        completionHandler: @escaping () -> Void
    ) {
        // No engine means this store has never persisted website data.  The
        // requested postcondition is therefore already true; completing once
        // is honest and prevents privacy/erase flows from hanging.
        _ = (dataTypes, date)
        completionHandler()
    }

    open func removeData(ofTypes dataTypes: Set<String>, modifiedSince date: Date) async {
        await withCheckedContinuation { continuation in
            removeData(ofTypes: dataTypes, modifiedSince: date) {
                continuation.resume()
            }
        }
    }

    open func removeData(
        ofTypes dataTypes: Set<String>,
        for dataRecords: [WKWebsiteDataRecord]
    ) async {
        _ = (dataTypes, dataRecords)
    }

    open func dataRecords(ofTypes dataTypes: Set<String>) async -> [WKWebsiteDataRecord] {
        _ = dataTypes
        return []
    }

    open func fetchData(of dataTypes: Set<String>) async throws -> Data {
        _ = dataTypes
        throw WKPortableUnknown("WKWebsiteDataStore.fetchData(of:)")
    }

    open func restoreData(_ data: Data) async throws {
        _ = data
        throw WKPortableUnknown("WKWebsiteDataStore.restoreData")
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
    open var processPool = WKProcessPool()
    open var suppressesIncrementalRendering = false
    open var applicationNameForUserAgent: String? = "Mobile/15E148"
    open var allowsAirPlayForMediaPlayback = true
    open var mediaPlaybackAllowsAirPlay = true
    open var upgradeKnownHostsToHTTPS = true
    open var limitsNavigationsToAppBoundDomains = false
    open var allowsInlineMediaPlayback = false
    open var ignoresViewportScaleLimits = false
    open var allowsInlinePredictions = false
    open var allowsPictureInPictureMediaPlayback = true
    open var mediaPlaybackRequiresUserAction = false
    open var requiresUserActionForMediaPlayback = false
    open var dataDetectorTypes: WKDataDetectorTypes = []
    open var mediaTypesRequiringUserActionForPlayback: WKAudiovisualMediaTypes = []
    open var selectionGranularity: WKSelectionGranularity = .dynamic
    open var showsSystemScreenTimeBlockingView = true
    open var supportsAdaptiveImageGlyph = false
    open var webExtensionController: WKWebExtensionController?
    private var urlSchemeHandlers: [String: any WKURLSchemeHandler] = [:]

    public override init() {
        self.preferences = WKPreferences()
        self.userContentController = WKUserContentController()
        self.websiteDataStore = .default()
        self.defaultWebpagePreferences = WKWebpagePreferences()
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.preferences = WKPreferences()
        self.userContentController = WKUserContentController()
        self.websiteDataStore = .default()
        self.defaultWebpagePreferences = WKWebpagePreferences()
        super.init()
    }

    open func setURLSchemeHandler(
        _ urlSchemeHandler: (any WKURLSchemeHandler)?,
        forURLScheme urlScheme: String
    ) {
        if let urlSchemeHandler {
            urlSchemeHandlers[urlScheme] = urlSchemeHandler
        } else {
            urlSchemeHandlers.removeValue(forKey: urlScheme)
        }
    }

    open func urlSchemeHandler(forURLScheme urlScheme: String) -> (any WKURLSchemeHandler)? {
        urlSchemeHandlers[urlScheme]
    }

    internal func _portableCopyForWebView() -> WKWebViewConfiguration {
        let result = WKWebViewConfiguration()
        // iOS 26.1 copies the configuration shell but keeps these configured
        // objects by identity.  A simulator oracle pins that distinction.
        result.preferences = preferences
        result.userContentController = userContentController
        result.websiteDataStore = websiteDataStore
        result.defaultWebpagePreferences = defaultWebpagePreferences
        result.processPool = processPool
        result.suppressesIncrementalRendering = suppressesIncrementalRendering
        result.applicationNameForUserAgent = applicationNameForUserAgent
        result.allowsAirPlayForMediaPlayback = allowsAirPlayForMediaPlayback
        result.mediaPlaybackAllowsAirPlay = mediaPlaybackAllowsAirPlay
        result.upgradeKnownHostsToHTTPS = upgradeKnownHostsToHTTPS
        result.limitsNavigationsToAppBoundDomains = limitsNavigationsToAppBoundDomains
        result.allowsInlineMediaPlayback = allowsInlineMediaPlayback
        result.ignoresViewportScaleLimits = ignoresViewportScaleLimits
        result.allowsInlinePredictions = allowsInlinePredictions
        result.allowsPictureInPictureMediaPlayback = allowsPictureInPictureMediaPlayback
        result.mediaPlaybackRequiresUserAction = mediaPlaybackRequiresUserAction
        result.requiresUserActionForMediaPlayback = requiresUserActionForMediaPlayback
        result.dataDetectorTypes = dataDetectorTypes
        result.mediaTypesRequiringUserActionForPlayback = mediaTypesRequiringUserActionForPlayback
        result.selectionGranularity = selectionGranularity
        result.showsSystemScreenTimeBlockingView = showsSystemScreenTimeBlockingView
        result.supportsAdaptiveImageGlyph = supportsAdaptiveImageGlyph
        result.webExtensionController = webExtensionController
        result.urlSchemeHandlers = urlSchemeHandlers
        return result
    }
}
