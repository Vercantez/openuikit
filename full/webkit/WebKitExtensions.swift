@_exported import Foundation

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

@preconcurrency @MainActor
open class WKWebExtension: NSObject {
    public struct Error: Swift.Error, Equatable, Hashable, Sendable, CustomNSError {
        public static let errorDomain = "WKWebExtensionErrorDomain"
        public enum Code: Int, Hashable, Sendable {
            case unknown = 1
            case resourceNotFound = 2
            case invalidResourceCodeSignature = 3
            case invalidManifest = 4
            case unsupportedManifestVersion = 5
            case invalidManifestEntry = 6
            case invalidDeclarativeNetRequestEntry = 7
            case invalidBackgroundPersistence = 8
            case invalidArchive = 9
        }
        public let code: Code
        public let userInfo: [String: String]
        public init(_ code: Code, userInfo: [String: Any] = [:]) {
            self.code = code
            self.userInfo = userInfo.mapValues { String(describing: $0) }
        }
        public var errorCode: Int { code.rawValue }
        public var errorUserInfo: [String: Any] {
            Dictionary(uniqueKeysWithValues: userInfo.map { ($0, $1 as Any) })
        }
        public var localizedDescription: String { "\(Self.errorDomain) \(code.rawValue)" }
        public static let unknown = Code.unknown
        public static let resourceNotFound = Code.resourceNotFound
        public static let invalidResourceCodeSignature = Code.invalidResourceCodeSignature
        public static let invalidManifest = Code.invalidManifest
        public static let unsupportedManifestVersion = Code.unsupportedManifestVersion
        public static let invalidManifestEntry = Code.invalidManifestEntry
        public static let invalidDeclarativeNetRequestEntry = Code.invalidDeclarativeNetRequestEntry
        public static let invalidBackgroundPersistence = Code.invalidBackgroundPersistence
        public static let invalidArchive = Code.invalidArchive
        public func hash(into hasher: inout Hasher) {
            hasher.combine(Self.errorDomain)
            hasher.combine(code)
        }
    }

    public struct Permission: Hashable, Sendable, RawRepresentable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let activeTab = Self("activeTab")
        public static let alarms = Self("alarms")
        public static let clipboardWrite = Self("clipboardWrite")
        public static let contextMenus = Self("contextMenus")
        public static let cookies = Self("cookies")
        public static let declarativeNetRequest = Self("declarativeNetRequest")
        public static let declarativeNetRequestFeedback = Self("declarativeNetRequestFeedback")
        public static let declarativeNetRequestWithHostAccess = Self("declarativeNetRequestWithHostAccess")
        public static let menus = Self("menus")
        public static let nativeMessaging = Self("nativeMessaging")
        public static let scripting = Self("scripting")
        public static let storage = Self("storage")
        public static let tabs = Self("tabs")
        public static let unlimitedStorage = Self("unlimitedStorage")
        public static let webNavigation = Self("webNavigation")
        public static let webRequest = Self("webRequest")
        public func hash(into hasher: inout Hasher) { hasher.combine(rawValue) }
        public var hashValue: Int { rawValue.hashValue }
    }

    public struct DataType: Hashable, Sendable, RawRepresentable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let local = Self("WKWebExtensionDataTypeLocal")
        public static let session = Self("WKWebExtensionDataTypeSession")
        public static let synchronized = Self("WKWebExtensionDataTypeSynchronized")
        public func hash(into hasher: inout Hasher) { hasher.combine(rawValue) }
        public var hashValue: Int { rawValue.hashValue }
    }

    public struct TabChangedProperties: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let loading = Self(rawValue: 1 << 1)
        public static let muted = Self(rawValue: 1 << 2)
        public static let pinned = Self(rawValue: 1 << 3)
        public static let playingAudio = Self(rawValue: 1 << 4)
        public static let readerMode = Self(rawValue: 1 << 5)
        public static let size = Self(rawValue: 1 << 6)
        public static let title = Self(rawValue: 1 << 7)
        public static let URL = Self(rawValue: 1 << 8)
        public static let zoomFactor = Self(rawValue: 1 << 9)
    }

    public enum WindowType: Int, Hashable, Sendable {
        case normal = 0
        case popup = 1
    }

    public enum WindowState: Int, Hashable, Sendable {
        case normal = 0
        case minimized = 1
        case maximized = 2
        case fullscreen = 3
    }

    public final class MatchPattern: NSObject {
        public struct Error: Swift.Error, Equatable, Hashable, Sendable, CustomNSError {
            public static let errorDomain = "WKWebExtensionMatchPatternErrorDomain"
            public enum Code: Int, Hashable, Sendable {
                case unknown = 1
                case invalidScheme = 2
                case invalidHost = 3
                case invalidPath = 4
            }
            public let code: Code
            public let userInfo: [String: String]
            public init(_ code: Code, userInfo: [String: Any] = [:]) {
                self.code = code
                self.userInfo = userInfo.mapValues { String(describing: $0) }
            }
            public var errorCode: Int { code.rawValue }
            public var errorUserInfo: [String: Any] {
                Dictionary(uniqueKeysWithValues: userInfo.map { ($0, $1 as Any) })
            }
            public var localizedDescription: String { "\(Self.errorDomain) \(code.rawValue)" }
            public static let unknown = Code.unknown
            public static let invalidScheme = Code.invalidScheme
            public static let invalidHost = Code.invalidHost
            public static let invalidPath = Code.invalidPath
            public func hash(into hasher: inout Hasher) {
                hasher.combine(Self.errorDomain)
                hasher.combine(code)
            }
        }

        public struct Options: OptionSet, Hashable, Sendable {
            public let rawValue: UInt
            public init(rawValue: UInt) { self.rawValue = rawValue }
            public static let ignoreSchemes = Self(rawValue: 1 << 0)
            public static let ignorePaths = Self(rawValue: 1 << 1)
            public static let matchBidirectionally = Self(rawValue: 1 << 2)
        }

        public let scheme: String
        public let host: String
        public let path: String
        public var string: String { "\(scheme)://\(host)\(path)" }
        public var matchesAllHosts: Bool { host == "*" || host == "*." }
        public var matchesAllURLs: Bool { scheme == "*" && matchesAllHosts }

        public init?(string: String) {
            let parts = string.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            self.scheme = parts[0]
            let rest = parts[1].hasPrefix("//") ? String(parts[1].dropFirst(2)) : parts[1]
            if let slash = rest.firstIndex(of: "/") {
                self.host = String(rest[..<slash])
                self.path = String(rest[slash...])
            } else {
                self.host = rest
                self.path = "/"
            }
            super.init()
        }

        public init?(scheme: String, host: String, path: String) {
            guard !scheme.isEmpty, !host.isEmpty, path.hasPrefix("/") else { return nil }
            self.scheme = scheme
            self.host = host
            self.path = path
            super.init()
        }

        public required init?(coder: NSCoder) {
            self.scheme = "*"
            self.host = "*"
            self.path = "/*"
            super.init()
        }

        public static func allURLs() -> WKWebExtension.MatchPattern {
            WKWebExtension.MatchPattern(string: "*://*/*")!
        }

        public static func allHostsAndSchemes() -> WKWebExtension.MatchPattern {
            WKWebExtension.MatchPattern(string: "*://*/*")!
        }

        public static func registerCustomURLScheme(_ urlScheme: String) {
            _ = urlScheme
        }

        public func matches(_ url: URL) -> Bool {
            matches(url, options: [])
        }

        public func matches(_ url: URL, options: Options) -> Bool {
            _ = options
            if matchesAllURLs { return true }
            if !matchesAllHosts, url.host != host { return false }
            return url.scheme == scheme || scheme == "*"
        }

        public func matches(_ pattern: WKWebExtension.MatchPattern) -> Bool {
            matches(pattern, options: [])
        }

        public func matches(_ pattern: WKWebExtension.MatchPattern, options: Options) -> Bool {
            _ = options
            return scheme == pattern.scheme && host == pattern.host && path == pattern.path
        }
    }

    public final class DataRecord: NSObject {
        public struct Error: Swift.Error, Equatable, Hashable, Sendable, CustomNSError {
            public static let errorDomain = "WKWebExtensionDataRecordErrorDomain"
            public enum Code: Int, Hashable, Sendable {
                case unknown = 1
                case localStorageFailed = 2
                case sessionStorageFailed = 3
                case synchronizedStorageFailed = 4
            }
            public let code: Code
            public let userInfo: [String: String]
            public init(_ code: Code, userInfo: [String: Any] = [:]) {
                self.code = code
                self.userInfo = userInfo.mapValues { String(describing: $0) }
            }
            public var errorCode: Int { code.rawValue }
            public var errorUserInfo: [String: Any] {
                Dictionary(uniqueKeysWithValues: userInfo.map { ($0, $1 as Any) })
            }
            public var localizedDescription: String { "\(Self.errorDomain) \(code.rawValue)" }
            public static let unknown = Code.unknown
            public static let localStorageFailed = Code.localStorageFailed
            public static let sessionStorageFailed = Code.sessionStorageFailed
            public static let synchronizedStorageFailed = Code.synchronizedStorageFailed
            public func hash(into hasher: inout Hasher) {
                hasher.combine(Self.errorDomain)
                hasher.combine(code)
            }
        }

        public let displayName: String
        public let uniqueIdentifier: String
        public let containedDataTypes: Set<WKWebExtension.DataType>
        public let errors: [WKWebExtension.DataRecord.Error]
        public let totalSizeInBytes: Int

        public init(
            displayName: String = "",
            uniqueIdentifier: String = "",
            containedDataTypes: Set<WKWebExtension.DataType> = [],
            errors: [WKWebExtension.DataRecord.Error] = [],
            totalSizeInBytes: Int = 0
        ) {
            self.displayName = displayName
            self.uniqueIdentifier = uniqueIdentifier
            self.containedDataTypes = containedDataTypes
            self.errors = errors
            self.totalSizeInBytes = totalSizeInBytes
            super.init()
        }

        public func sizeInBytes(ofTypes types: Set<WKWebExtension.DataType>) -> Int {
            _ = types
            return 0
        }
    }

    public final class MessagePort: NSObject {
        public struct Error: Swift.Error, Equatable, Hashable, Sendable, CustomNSError {
            public static let errorDomain = "WKWebExtensionMessagePortErrorDomain"
            public enum Code: Int, Hashable, Sendable {
                case unknown = 1
                case notConnected = 2
                case messageInvalid = 3
            }
            public let code: Code
            public let userInfo: [String: String]
            public init(_ code: Code, userInfo: [String: Any] = [:]) {
                self.code = code
                self.userInfo = userInfo.mapValues { String(describing: $0) }
            }
            public var errorCode: Int { code.rawValue }
            public var errorUserInfo: [String: Any] {
                Dictionary(uniqueKeysWithValues: userInfo.map { ($0, $1 as Any) })
            }
            public var localizedDescription: String { "\(Self.errorDomain) \(code.rawValue)" }
            public static let unknown = Code.unknown
            public static let notConnected = Code.notConnected
            public static let messageInvalid = Code.messageInvalid
            public func hash(into hasher: inout Hasher) {
                hasher.combine(Self.errorDomain)
                hasher.combine(code)
            }
        }

        public let applicationIdentifier: String?
        public var isDisconnected = false
        public var disconnectHandler: ((WKWebExtension.MessagePort.Error?) -> Void)?
        public var messageHandler: ((Any, ((Any?, WKWebExtension.MessagePort.Error?) -> Void)?) -> Void)?

        public init(applicationIdentifier: String? = nil) {
            self.applicationIdentifier = applicationIdentifier
            super.init()
        }

        public func disconnect() {
            disconnect(throwing: nil)
        }

        public func disconnect(throwing error: WKWebExtension.MessagePort.Error?) {
            isDisconnected = true
            disconnectHandler?(error)
        }

        public func sendMessage(_ message: Any) throws {
            _ = message
            throw WKWebExtension.MessagePort.Error(.notConnected)
        }
    }

    public final class Action: NSObject {
        public weak var associatedTab: (any WKWebExtensionTab)?
        public weak var webExtensionContext: WKWebExtensionContext?
        public var badgeText: String?
        public var isEnabled = true
        public var hasUnreadBadgeText = false
        public var inspectionName: String?
        public var label: String?
        public var presentsPopup = false
        public var popupWebView: WKWebView?
        public var popupViewController: UIViewController?

        public func closePopup() {}

        public func icon(for size: CGSize) -> UIImage? {
            _ = size
            return nil
        }
    }

    public final class Command: NSObject {
        public let id: String
        public var title: String?
        public var activationKey: String?
        public var modifierFlags: UInt = 0
        public weak var webExtensionContext: WKWebExtensionContext?

        public init(id: String) {
            self.id = id
            super.init()
        }
    }

    public final class TabConfiguration: NSObject {
        public var url: URL?
        public var window: (any WKWebExtensionWindow)?
        public var index: Int = 0
        public var parentTab: (any WKWebExtensionTab)?
        public var shouldAddToSelection = false
        public var shouldBeActive = true
        public var shouldBeMuted = false
        public var shouldBePinned = false
        public var shouldReaderModeBeActive = false
    }

    public final class WindowConfiguration: NSObject {
        public var frame: CGRect = .zero
        public var shouldBeFocused = true
        public var shouldBePrivate = false
        public var tabURLs: [URL] = []
        public var tabs: [any WKWebExtensionTab] = []
        public var windowState: WindowState = .normal
        public var windowType: WindowType = .normal
    }

    public static let errorDomain = Error.errorDomain

    public private(set) var errors: [WKWebExtension.Error] = []
    public private(set) var manifest: [String: Any] = [:]
    public private(set) var manifestVersion: Double = 0
    public private(set) var defaultLocale: Locale?
    public private(set) var displayName: String?
    public private(set) var displayShortName: String?
    public private(set) var displayVersion: String?
    public private(set) var displayDescription: String?
    public private(set) var displayActionLabel: String?
    public private(set) var version: String?
    public private(set) var hasBackgroundContent = false
    public private(set) var hasPersistentBackgroundContent = false
    public private(set) var hasCommands = false
    public private(set) var hasContentModificationRules = false
    public private(set) var hasInjectedContent = false
    public private(set) var hasOptionsPage = false
    public private(set) var hasOverrideNewTabPage = false
    public private(set) var requestedPermissions: Set<Permission> = []
    public private(set) var optionalPermissions: Set<Permission> = []
    public private(set) var requestedPermissionMatchPatterns: Set<MatchPattern> = []
    public private(set) var optionalPermissionMatchPatterns: Set<MatchPattern> = []
    public private(set) var allRequestedMatchPatterns: Set<MatchPattern> = []

    public override init() {
        super.init()
        errors = [WKWebExtension.Error(.unknown, userInfo: ["WKPortableOperation": "no-extension-archive"])]
    }

    public convenience init(appExtensionBundle: Any) async throws {
        _ = appExtensionBundle
        self.init()
        throw WKWebExtension.Error(.resourceNotFound)
    }

    public convenience init(resourceBaseURL: URL) async throws {
        _ = resourceBaseURL
        self.init()
        throw WKWebExtension.Error(.resourceNotFound)
    }

    public func supportsManifestVersion(_ manifestVersion: Double) -> Bool {
        manifestVersion >= 2 && manifestVersion <= 3
    }

    public func icon(for size: CGSize) -> UIImage? {
        _ = size
        return nil
    }

    public func actionIcon(for size: CGSize) -> UIImage? {
        _ = size
        return nil
    }
}

extension WKWebExtension.Error.Code {
    public static func ~= (match: Self, error: any Swift.Error) -> Bool {
        (error as? WKWebExtension.Error)?.code == match
    }
}

extension WKWebExtension.MatchPattern.Error.Code {
    public static func ~= (match: Self, error: any Swift.Error) -> Bool {
        (error as? WKWebExtension.MatchPattern.Error)?.code == match
    }
}

extension WKWebExtension.DataRecord.Error.Code {
    public static func ~= (match: Self, error: any Swift.Error) -> Bool {
        (error as? WKWebExtension.DataRecord.Error)?.code == match
    }
}

extension WKWebExtension.MessagePort.Error.Code {
    public static func ~= (match: Self, error: any Swift.Error) -> Bool {
        (error as? WKWebExtension.MessagePort.Error)?.code == match
    }
}

@preconcurrency @MainActor
open class WKWebExtensionContext: NSObject {
    public static let errorDomain = Error.errorDomain
    public static let errorsDidUpdateNotification = Notification.Name(
        "WKWebExtensionContextErrorsDidUpdate"
    )
    public static let permissionsWereGrantedNotification = Notification.Name(
        "WKWebExtensionContextPermissionsWereGranted"
    )
    public static let permissionsWereDeniedNotification = Notification.Name(
        "WKWebExtensionContextPermissionsWereDenied"
    )
    public static let grantedPermissionsWereRemovedNotification = Notification.Name(
        "WKWebExtensionContextGrantedPermissionsWereRemoved"
    )
    public static let deniedPermissionsWereRemovedNotification = Notification.Name(
        "WKWebExtensionContextDeniedPermissionsWereRemoved"
    )
    public static let permissionMatchPatternsWereGrantedNotification = Notification.Name(
        "WKWebExtensionContextPermissionMatchPatternsWereGranted"
    )
    public static let permissionMatchPatternsWereDeniedNotification = Notification.Name(
        "WKWebExtensionContextPermissionMatchPatternsWereDenied"
    )
    public static let grantedPermissionMatchPatternsWereRemovedNotification = Notification.Name(
        "WKWebExtensionContextGrantedPermissionMatchPatternsWereRemoved"
    )
    public static let deniedPermissionMatchPatternsWereRemovedNotification = Notification.Name(
        "WKWebExtensionContextDeniedPermissionMatchPatternsWereRemoved"
    )

    public struct NotificationUserInfoKey: Hashable, Sendable, RawRepresentable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let permissions = Self("permissions")
        public static let matchPatterns = Self("matchPatterns")
        public func hash(into hasher: inout Hasher) { hasher.combine(rawValue) }
        public var hashValue: Int { rawValue.hashValue }
    }

    public enum PermissionStatus: Int, Hashable, Sendable {
        case deniedExplicitly = -3
        case deniedImplicitly = -2
        case requestedImplicitly = -1
        case unknown = 0
        case requestedExplicitly = 1
        case grantedImplicitly = 2
        case grantedExplicitly = 3
    }

    public struct Error: Swift.Error, Equatable, Hashable, Sendable, CustomNSError {
        public static let errorDomain = "WKWebExtensionContextErrorDomain"
        public enum Code: Int, Hashable, Sendable {
            case unknown = 1
            case alreadyLoaded = 2
            case notLoaded = 3
            case baseURLAlreadyInUse = 4
            case noBackgroundContent = 5
            case backgroundContentFailedToLoad = 6
        }
        public let code: Code
        public let userInfo: [String: String]
        public init(_ code: Code, userInfo: [String: Any] = [:]) {
            self.code = code
            self.userInfo = userInfo.mapValues { String(describing: $0) }
        }
        public var errorCode: Int { code.rawValue }
        public var errorUserInfo: [String: Any] {
            Dictionary(uniqueKeysWithValues: userInfo.map { ($0, $1 as Any) })
        }
        public var localizedDescription: String { "\(Self.errorDomain) \(code.rawValue)" }
        public static let unknown = Code.unknown
        public static let alreadyLoaded = Code.alreadyLoaded
        public static let notLoaded = Code.notLoaded
        public static let baseURLAlreadyInUse = Code.baseURLAlreadyInUse
        public static let noBackgroundContent = Code.noBackgroundContent
        public static let backgroundContentFailedToLoad = Code.backgroundContentFailedToLoad
        public func hash(into hasher: inout Hasher) {
            hasher.combine(Self.errorDomain)
            hasher.combine(code)
        }
    }

    public let webExtension: WKWebExtension
    public private(set) weak var webExtensionController: WKWebExtensionController?
    public private(set) var isLoaded = false
    public private(set) var errors: [WKWebExtensionContext.Error] = []
    public var baseURL = URL(string: "webkit-extension://portable/")!
    public var uniqueIdentifier = UUID().uuidString
    public var isInspectable = false
    public var inspectionName: String?
    public var unsupportedAPIs: Set<String> = []
    public private(set) var webViewConfiguration = WKWebViewConfiguration()
    public private(set) var optionsPageURL: URL?
    public private(set) var overrideNewTabPageURL: URL?
    public var grantedPermissions: [WKWebExtension.Permission: Date] = [:]
    public var deniedPermissions: [WKWebExtension.Permission: Date] = [:]
    public var grantedPermissionMatchPatterns: [WKWebExtension.MatchPattern: Date] = [:]
    public var deniedPermissionMatchPatterns: [WKWebExtension.MatchPattern: Date] = [:]
    public var currentPermissions: Set<WKWebExtension.Permission> { Set(grantedPermissions.keys) }
    public var currentPermissionMatchPatterns: Set<WKWebExtension.MatchPattern> {
        Set(grantedPermissionMatchPatterns.keys)
    }
    public var hasAccessToAllHosts = false
    public var hasAccessToAllURLs = false
    public var hasAccessToPrivateData = false
    public var hasContentModificationRules = false
    public var hasInjectedContent = false
    public var hasRequestedOptionalAccessToAllHosts = false
    public private(set) var commands: [WKWebExtension.Command] = []
    public private(set) var openTabs: [any WKWebExtensionTab] = []
    public private(set) var openWindows: [any WKWebExtensionWindow] = []
    public private(set) var focusedWindow: (any WKWebExtensionWindow)?

    public init(for webExtension: WKWebExtension) {
        self.webExtension = webExtension
        super.init()
    }

    public convenience init(forExtension webExtension: WKWebExtension) {
        self.init(for: webExtension)
    }

    public func action(for tab: (any WKWebExtensionTab)?) -> WKWebExtension.Action {
        let action = WKWebExtension.Action()
        action.associatedTab = tab
        action.webExtensionContext = self
        return action
    }

    public func clearUserGesture(in tab: any WKWebExtensionTab) { _ = tab }
    public func userGesturePerformed(in tab: any WKWebExtensionTab) { _ = tab }
    public func hasActiveUserGesture(in tab: any WKWebExtensionTab) -> Bool {
        _ = tab
        return false
    }

    public func didChangeTabProperties(
        _ properties: WKWebExtension.TabChangedProperties,
        for tab: any WKWebExtensionTab
    ) { _ = (properties, tab) }
    public func didCloseWindow(_ window: any WKWebExtensionWindow) { _ = window }
    public func didDeselectTabs(_ tabs: [any WKWebExtensionTab]) { _ = tabs }
    public func didFocusWindow(_ window: (any WKWebExtensionWindow)?) { focusedWindow = window }
    public func didOpenTab(_ tab: any WKWebExtensionTab) { openTabs.append(tab) }
    public func didOpenWindow(_ window: any WKWebExtensionWindow) { openWindows.append(window) }
    public func didReplaceTab(_ oldTab: any WKWebExtensionTab, with newTab: any WKWebExtensionTab) {
        _ = (oldTab, newTab)
    }
    public func didSelectTabs(_ tabs: [any WKWebExtensionTab]) { _ = tabs }
    public func didMoveTab(_ tab: any WKWebExtensionTab, from index: Int, in window: (any WKWebExtensionWindow)?) {
        _ = (tab, index, window)
    }
    public func didCloseTab(_ tab: any WKWebExtensionTab, windowIsClosing: Bool) {
        _ = (tab, windowIsClosing)
    }
    public func didActivateTab(
        _ tab: any WKWebExtensionTab,
        previousActiveTab: (any WKWebExtensionTab)?
    ) { _ = (tab, previousActiveTab) }

    public func hasAccess(to url: URL) -> Bool { hasAccess(to: url, in: nil) }
    public func hasAccess(to url: URL, in tab: (any WKWebExtensionTab)?) -> Bool {
        _ = (url, tab)
        return false
    }
    public func hasInjectedContent(for url: URL) -> Bool {
        _ = url
        return false
    }
    public func hasPermission(_ permission: WKWebExtension.Permission) -> Bool {
        hasPermission(permission, in: nil)
    }
    public func hasPermission(
        _ permission: WKWebExtension.Permission,
        in tab: (any WKWebExtensionTab)?
    ) -> Bool {
        _ = tab
        return grantedPermissions[permission] != nil
    }

    public func loadBackgroundContent(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(WKWebExtensionContext.Error(.noBackgroundContent))
    }

    public func menuItems(for tab: (any WKWebExtensionTab)?) -> [Any] {
        _ = tab
        return []
    }

    public func performAction(for tab: (any WKWebExtensionTab)?) { _ = tab }
    public func performCommand(_ command: WKWebExtension.Command) { _ = command }
    public func performCommand(for event: Any) { _ = event }

    public func permissionStatus(for permission: WKWebExtension.Permission) -> PermissionStatus {
        permissionStatus(for: permission, in: nil)
    }
    public func permissionStatus(
        for permission: WKWebExtension.Permission,
        in tab: (any WKWebExtensionTab)?
    ) -> PermissionStatus {
        _ = tab
        if grantedPermissions[permission] != nil { return .grantedExplicitly }
        if deniedPermissions[permission] != nil { return .deniedExplicitly }
        return .unknown
    }

    public func permissionStatus(for url: URL) -> PermissionStatus {
        permissionStatus(for: url, in: nil)
    }
    public func permissionStatus(for url: URL, in tab: (any WKWebExtensionTab)?) -> PermissionStatus {
        _ = (url, tab)
        return .unknown
    }

    public func permissionStatus(for pattern: WKWebExtension.MatchPattern) -> PermissionStatus {
        permissionStatus(for: pattern, in: nil)
    }
    public func permissionStatus(
        for pattern: WKWebExtension.MatchPattern,
        in tab: (any WKWebExtensionTab)?
    ) -> PermissionStatus {
        _ = tab
        if grantedPermissionMatchPatterns[pattern] != nil { return .grantedExplicitly }
        if deniedPermissionMatchPatterns[pattern] != nil { return .deniedExplicitly }
        return .unknown
    }

    public func setPermissionStatus(_ status: PermissionStatus, for permission: WKWebExtension.Permission) {
        setPermissionStatus(status, for: permission, expirationDate: nil)
    }
    public func setPermissionStatus(
        _ status: PermissionStatus,
        for permission: WKWebExtension.Permission,
        expirationDate: Date?
    ) {
        let expiry = expirationDate ?? .distantFuture
        grantedPermissions[permission] = nil
        deniedPermissions[permission] = nil
        switch status {
        case .grantedExplicitly, .grantedImplicitly:
            grantedPermissions[permission] = expiry
        case .deniedExplicitly, .deniedImplicitly:
            deniedPermissions[permission] = expiry
        default:
            break
        }
    }

    public func setPermissionStatus(_ status: PermissionStatus, for url: URL) {
        setPermissionStatus(status, for: url, expirationDate: nil)
    }
    public func setPermissionStatus(
        _ status: PermissionStatus,
        for url: URL,
        expirationDate: Date?
    ) {
        _ = (status, url, expirationDate)
    }

    public func setPermissionStatus(
        _ status: PermissionStatus,
        for pattern: WKWebExtension.MatchPattern
    ) {
        setPermissionStatus(status, for: pattern, expirationDate: nil)
    }
    public func setPermissionStatus(
        _ status: PermissionStatus,
        for pattern: WKWebExtension.MatchPattern,
        expirationDate: Date?
    ) {
        let expiry = expirationDate ?? .distantFuture
        grantedPermissionMatchPatterns[pattern] = nil
        deniedPermissionMatchPatterns[pattern] = nil
        switch status {
        case .grantedExplicitly, .grantedImplicitly:
            grantedPermissionMatchPatterns[pattern] = expiry
        case .deniedExplicitly, .deniedImplicitly:
            deniedPermissionMatchPatterns[pattern] = expiry
        default:
            break
        }
    }
}

extension WKWebExtensionContext.Error.Code {
    public static func ~= (match: Self, error: any Swift.Error) -> Bool {
        (error as? WKWebExtensionContext.Error)?.code == match
    }
}

@preconcurrency @MainActor
public protocol WKWebExtensionTab: AnyObject {
    func window(for context: WKWebExtensionContext) -> (any WKWebExtensionWindow)?
    func indexInWindow(for context: WKWebExtensionContext) -> Int
    func parentTab(for context: WKWebExtensionContext) -> (any WKWebExtensionTab)?
    func setParentTab(_ tab: (any WKWebExtensionTab)?, for context: WKWebExtensionContext) async throws
    func title(for context: WKWebExtensionContext) -> String?
    func isPinned(for context: WKWebExtensionContext) -> Bool
    func setPinned(_ pinned: Bool, for context: WKWebExtensionContext) async throws
    func isReaderModeActive(for context: WKWebExtensionContext) -> Bool
    func isPlayingAudio(for context: WKWebExtensionContext) -> Bool
    func isMuted(for context: WKWebExtensionContext) -> Bool
    func setMuted(_ muted: Bool, for context: WKWebExtensionContext) async throws
    func size(for context: WKWebExtensionContext) -> CGSize
    func zoomFactor(for context: WKWebExtensionContext) -> Double
    func setZoomFactor(_ zoomFactor: Double, for context: WKWebExtensionContext) async throws
    func url(for context: WKWebExtensionContext) -> URL?
    func pendingURL(for context: WKWebExtensionContext) -> URL?
    func isLoadingComplete(for context: WKWebExtensionContext) -> Bool
    func detectWebpageLocale(for context: WKWebExtensionContext) async throws -> Locale?
    func takeSnapshot(for context: WKWebExtensionContext) async throws -> UIImage
    func loadURL(_ url: URL, for context: WKWebExtensionContext) async throws
    func reload(fromOrigin: Bool, for context: WKWebExtensionContext) async throws
    func goBack(for context: WKWebExtensionContext) async throws
    func goForward(for context: WKWebExtensionContext) async throws
    func activate(for context: WKWebExtensionContext) async throws
    func select(for context: WKWebExtensionContext) async throws
    func duplicate(_ configuration: WKWebExtension.TabConfiguration, for context: WKWebExtensionContext) async throws -> (any WKWebExtensionTab)?
    func close(for context: WKWebExtensionContext) async throws
    func shouldGrantPermissionsOnUserGesture(for context: WKWebExtensionContext) -> Bool
}

@MainActor
public extension WKWebExtensionTab {
    func window(for context: WKWebExtensionContext) -> (any WKWebExtensionWindow)? {
        _ = context
        return nil
    }
    func indexInWindow(for context: WKWebExtensionContext) -> Int {
        _ = context
        return 0
    }
    func parentTab(for context: WKWebExtensionContext) -> (any WKWebExtensionTab)? {
        _ = context
        return nil
    }
    func setParentTab(_ tab: (any WKWebExtensionTab)?, for context: WKWebExtensionContext) async throws {
        _ = (tab, context)
        throw WKPortableUnknown("WKWebExtensionTab.setParentTab")
    }
    func title(for context: WKWebExtensionContext) -> String? {
        _ = context
        return nil
    }
    func isPinned(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return false
    }
    func setPinned(_ pinned: Bool, for context: WKWebExtensionContext) async throws {
        _ = (pinned, context)
        throw WKPortableUnknown("WKWebExtensionTab.setPinned")
    }
    func isReaderModeActive(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return false
    }
    func isPlayingAudio(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return false
    }
    func isMuted(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return false
    }
    func setMuted(_ muted: Bool, for context: WKWebExtensionContext) async throws {
        _ = (muted, context)
        throw WKPortableUnknown("WKWebExtensionTab.setMuted")
    }
    func size(for context: WKWebExtensionContext) -> CGSize {
        _ = context
        return .zero
    }
    func zoomFactor(for context: WKWebExtensionContext) -> Double {
        _ = context
        return 1
    }
    func setZoomFactor(_ zoomFactor: Double, for context: WKWebExtensionContext) async throws {
        _ = (zoomFactor, context)
        throw WKPortableUnknown("WKWebExtensionTab.setZoomFactor")
    }
    func url(for context: WKWebExtensionContext) -> URL? {
        _ = context
        return nil
    }
    func pendingURL(for context: WKWebExtensionContext) -> URL? {
        _ = context
        return nil
    }
    func isLoadingComplete(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return true
    }
    func detectWebpageLocale(for context: WKWebExtensionContext) async throws -> Locale? {
        _ = context
        throw WKPortableUnknown("WKWebExtensionTab.detectWebpageLocale")
    }
    func takeSnapshot(for context: WKWebExtensionContext) async throws -> UIImage {
        _ = context
        throw WKPortableUnknown("WKWebExtensionTab.takeSnapshot")
    }
    func loadURL(_ url: URL, for context: WKWebExtensionContext) async throws {
        _ = (url, context)
        throw WKPortableUnknown("WKWebExtensionTab.loadURL")
    }
    func reload(fromOrigin: Bool, for context: WKWebExtensionContext) async throws {
        _ = (fromOrigin, context)
        throw WKPortableUnknown("WKWebExtensionTab.reload")
    }
    func goBack(for context: WKWebExtensionContext) async throws {
        _ = context
        throw WKPortableUnknown("WKWebExtensionTab.goBack")
    }
    func goForward(for context: WKWebExtensionContext) async throws {
        _ = context
        throw WKPortableUnknown("WKWebExtensionTab.goForward")
    }
    func activate(for context: WKWebExtensionContext) async throws {
        _ = context
        throw WKPortableUnknown("WKWebExtensionTab.activate")
    }
    func select(for context: WKWebExtensionContext) async throws {
        _ = context
        throw WKPortableUnknown("WKWebExtensionTab.select")
    }
    func duplicate(
        _ configuration: WKWebExtension.TabConfiguration,
        for context: WKWebExtensionContext
    ) async throws -> (any WKWebExtensionTab)? {
        _ = (configuration, context)
        throw WKPortableUnknown("WKWebExtensionTab.duplicate")
    }
    func close(for context: WKWebExtensionContext) async throws {
        _ = context
        throw WKPortableUnknown("WKWebExtensionTab.close")
    }
    func shouldGrantPermissionsOnUserGesture(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return false
    }
}

@preconcurrency @MainActor
public protocol WKWebExtensionWindow: AnyObject {
    func tabs(for context: WKWebExtensionContext) -> [any WKWebExtensionTab]
    func activeTab(for context: WKWebExtensionContext) -> (any WKWebExtensionTab)?
    func windowType(for context: WKWebExtensionContext) -> WKWebExtension.WindowType
    func windowState(for context: WKWebExtensionContext) -> WKWebExtension.WindowState
    func setWindowState(_ state: WKWebExtension.WindowState, for context: WKWebExtensionContext) async throws
    func isPrivate(for context: WKWebExtensionContext) -> Bool
    func frame(for context: WKWebExtensionContext) -> CGRect
    func setFrame(_ frame: CGRect, for context: WKWebExtensionContext) async throws
    func focus(for context: WKWebExtensionContext) async throws
    func close(for context: WKWebExtensionContext) async throws
}

@MainActor
public extension WKWebExtensionWindow {
    func tabs(for context: WKWebExtensionContext) -> [any WKWebExtensionTab] {
        _ = context
        return []
    }
    func activeTab(for context: WKWebExtensionContext) -> (any WKWebExtensionTab)? {
        _ = context
        return nil
    }
    func windowType(for context: WKWebExtensionContext) -> WKWebExtension.WindowType {
        _ = context
        return .normal
    }
    func windowState(for context: WKWebExtensionContext) -> WKWebExtension.WindowState {
        _ = context
        return .normal
    }
    func setWindowState(
        _ state: WKWebExtension.WindowState,
        for context: WKWebExtensionContext
    ) async throws {
        _ = (state, context)
        throw WKPortableUnknown("WKWebExtensionWindow.setWindowState")
    }
    func isPrivate(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return false
    }
    func frame(for context: WKWebExtensionContext) -> CGRect {
        _ = context
        return .zero
    }
    func setFrame(_ frame: CGRect, for context: WKWebExtensionContext) async throws {
        _ = (frame, context)
        throw WKPortableUnknown("WKWebExtensionWindow.setFrame")
    }
    func focus(for context: WKWebExtensionContext) async throws {
        _ = context
        throw WKPortableUnknown("WKWebExtensionWindow.focus")
    }
    func close(for context: WKWebExtensionContext) async throws {
        _ = context
        throw WKPortableUnknown("WKWebExtensionWindow.close")
    }
}

@preconcurrency @MainActor
open class WKWebExtensionController: NSObject {
    public weak var delegate: WKWebExtensionControllerDelegate?
    public private(set) var extensions: [WKWebExtension] = []
    public private(set) var extensionContexts: [WKWebExtensionContext] = []

    public override init() {
        super.init()
    }

    public init(configuration: WKWebExtensionController.Configuration) {
        _ = configuration
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    open func load(_ context: WKWebExtensionContext) throws {
        if context.isLoaded {
            throw WKWebExtensionContext.Error(.alreadyLoaded)
        }
        extensionContexts.append(context)
        extensions.append(context.webExtension)
    }

    open func unload(_ context: WKWebExtensionContext) throws {
        guard extensionContexts.contains(where: { $0 === context }) else {
            throw WKWebExtensionContext.Error(.notLoaded)
        }
        extensionContexts.removeAll { $0 === context }
    }

    @MainActor
    public final class Configuration: NSObject {
        public var webViewConfiguration: WKWebViewConfiguration
        public var defaultWebsiteDataStore: WKWebsiteDataStore
        public override init() {
            self.webViewConfiguration = WKWebViewConfiguration()
            self.defaultWebsiteDataStore = WKWebsiteDataStore.default()
            super.init()
        }
    }
}

@preconcurrency @MainActor
public protocol WKWebExtensionControllerDelegate: AnyObject {
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewTabWith configuration: WKWebExtension.TabConfiguration,
        for extensionContext: WKWebExtensionContext
    ) async throws -> (any WKWebExtensionTab)?
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewWindowWith configuration: WKWebExtension.WindowConfiguration,
        for extensionContext: WKWebExtensionContext
    ) async throws -> (any WKWebExtensionWindow)?
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openOptionsPageFor extensionContext: WKWebExtensionContext
    ) async throws
    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissions permissions: Set<WKWebExtension.Permission>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext
    ) async -> (Set<WKWebExtension.Permission>, Date?)
    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissionMatchPatterns matchPatterns: Set<WKWebExtension.MatchPattern>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext
    ) async -> (Set<WKWebExtension.MatchPattern>, Date?)
    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissionToAccessURLs urls: Set<URL>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext
    ) async -> (Set<URL>, Date?)
    func webExtensionController(
        _ controller: WKWebExtensionController,
        presentPopupFor action: WKWebExtension.Action,
        for extensionContext: WKWebExtensionContext
    ) async throws
    func webExtensionController(
        _ controller: WKWebExtensionController,
        sendMessage message: Any,
        to relatedApplicationIdentifier: String?,
        for extensionContext: WKWebExtensionContext
    ) async throws -> Any?
    func webExtensionController(
        _ controller: WKWebExtensionController,
        connectUsingMessagePort port: WKWebExtension.MessagePort,
        for extensionContext: WKWebExtensionContext
    ) async throws
    func webExtensionControllerDidUpdateExtensions(_ controller: WKWebExtensionController)
}

@MainActor
public extension WKWebExtensionControllerDelegate {
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewTabWith configuration: WKWebExtension.TabConfiguration,
        for extensionContext: WKWebExtensionContext
    ) async throws -> (any WKWebExtensionTab)? {
        _ = (controller, configuration, extensionContext)
        throw WKPortableUnknown("WKWebExtensionControllerDelegate.openNewTab")
    }
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openNewWindowWith configuration: WKWebExtension.WindowConfiguration,
        for extensionContext: WKWebExtensionContext
    ) async throws -> (any WKWebExtensionWindow)? {
        _ = (controller, configuration, extensionContext)
        throw WKPortableUnknown("WKWebExtensionControllerDelegate.openNewWindow")
    }
    func webExtensionController(
        _ controller: WKWebExtensionController,
        openOptionsPageFor extensionContext: WKWebExtensionContext
    ) async throws {
        _ = (controller, extensionContext)
        throw WKPortableUnknown("WKWebExtensionControllerDelegate.openOptionsPage")
    }
    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissions permissions: Set<WKWebExtension.Permission>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext
    ) async -> (Set<WKWebExtension.Permission>, Date?) {
        _ = (controller, tab, extensionContext)
        return (permissions, nil)
    }
    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissionMatchPatterns matchPatterns: Set<WKWebExtension.MatchPattern>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext
    ) async -> (Set<WKWebExtension.MatchPattern>, Date?) {
        _ = (controller, tab, extensionContext)
        return (matchPatterns, nil)
    }
    func webExtensionController(
        _ controller: WKWebExtensionController,
        promptForPermissionToAccessURLs urls: Set<URL>,
        in tab: (any WKWebExtensionTab)?,
        for extensionContext: WKWebExtensionContext
    ) async -> (Set<URL>, Date?) {
        _ = (controller, tab, extensionContext)
        return (urls, nil)
    }
    func webExtensionController(
        _ controller: WKWebExtensionController,
        presentPopupFor action: WKWebExtension.Action,
        for extensionContext: WKWebExtensionContext
    ) async throws {
        _ = (controller, action, extensionContext)
        throw WKPortableUnknown("WKWebExtensionControllerDelegate.presentPopup")
    }
    func webExtensionController(
        _ controller: WKWebExtensionController,
        sendMessage message: Any,
        to relatedApplicationIdentifier: String?,
        for extensionContext: WKWebExtensionContext
    ) async throws -> Any? {
        _ = (controller, message, relatedApplicationIdentifier, extensionContext)
        throw WKPortableUnknown("WKWebExtensionControllerDelegate.sendMessage")
    }
    func webExtensionController(
        _ controller: WKWebExtensionController,
        connectUsingMessagePort port: WKWebExtension.MessagePort,
        for extensionContext: WKWebExtensionContext
    ) async throws {
        _ = (controller, port, extensionContext)
        throw WKPortableUnknown("WKWebExtensionControllerDelegate.connectUsingMessagePort")
    }
    func webExtensionControllerDidUpdateExtensions(_ controller: WKWebExtensionController) {
        _ = controller
    }
}
