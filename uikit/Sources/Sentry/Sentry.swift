// Fail-closed Sentry Swift surface Focus uses.
//
// Pin: sentry-cocoa 8.20.0 (b847a202a517a90763e8fd0656d8028aeee7b78d),
// Focus a2832521 Package.resolved. sentry-cocoa is 33.5 % ObjC
// (full/ladder/dep-classes-2026-08-27.json); this module is not that SDK.
// Call sites grepped from focus-ios Blockzilla:
//   SentrySDK.start { options in options.dsn = … }  AppDelegate.swift:333
//   SentrySDK.crash()                               InternalCrashReportingSettingsView.swift:12
//   SentrySDK.capture(message:)                     :15
//   SentrySDK.capture(exception:)                   :18
//   SentrySDK.capture(error:)                       :21
// Brief also names configureScope. Every path is a no-op: there is no
// network and no crash reporter on this host.

import Foundation

#if os(Linux)
/// corelibs Foundation has no NSException (MEASURED swift:6.2-noble Sentry.swift:99).
public struct NSExceptionName: RawRepresentable, Hashable, Sendable {
    public var rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let genericException = NSExceptionName(rawValue: "NSGenericException")
}

open class NSException: NSObject {
    public var name: NSExceptionName
    public var reason: String?
    public var userInfo: [AnyHashable: Any]?
    public init(name: NSExceptionName, reason: String?, userInfo: [AnyHashable: Any]? = nil) {
        self.name = name
        self.reason = reason
        self.userInfo = userInfo
        super.init()
    }
}
#endif

public final class SentryOptions: NSObject {
    public var dsn: String?
    public override init() { super.init() }
}

public final class SentryId: NSObject {
    public static let empty = SentryId()
    public override init() { super.init() }
}

public final class SentryScope: NSObject {
    public override init() { super.init() }
    public func setTag(value: String, key: String) { _ = (value, key) }
    public func setExtra(value: Any, key: String) { _ = (value, key) }
    public func setUser(_ user: SentryUser?) { _ = user }
}

public final class SentryUser: NSObject {
    public var userId: String?
    public override init() { super.init() }
    public init(userId: String) {
        self.userId = userId
        super.init()
    }
}

public final class SentryEvent: NSObject {
    public override init() { super.init() }
}

public final class SentrySDK: NSObject {
    public static var isEnabled: Bool { false }
    public static var crashedLastRun: Bool { false }

    @available(*, unavailable)
    override public init() { fatalError("SentrySDK is not instantiable") }

    public static func start(options: SentryOptions) { _ = options }

    public static func start(configureOptions: (SentryOptions) -> Void) {
        configureOptions(SentryOptions())
    }

    @discardableResult
    public static func capture(message: String) -> SentryId {
        _ = message
        return .empty
    }

    @discardableResult
    public static func capture(message: String, scope: SentryScope) -> SentryId {
        _ = (message, scope)
        return .empty
    }

    @discardableResult
    public static func capture(message: String, block: (SentryScope) -> Void) -> SentryId {
        _ = message
        block(SentryScope())
        return .empty
    }

    @discardableResult
    public static func capture(error: Error) -> SentryId {
        _ = error
        return .empty
    }

    @discardableResult
    public static func capture(error: Error, scope: SentryScope) -> SentryId {
        _ = (error, scope)
        return .empty
    }

    @discardableResult
    public static func capture(error: Error, block: (SentryScope) -> Void) -> SentryId {
        _ = error
        block(SentryScope())
        return .empty
    }

    @discardableResult
    public static func capture(exception: NSException) -> SentryId {
        _ = exception
        return .empty
    }

    @discardableResult
    public static func capture(exception: NSException, scope: SentryScope) -> SentryId {
        _ = (exception, scope)
        return .empty
    }

    @discardableResult
    public static func capture(exception: NSException, block: (SentryScope) -> Void) -> SentryId {
        _ = exception
        block(SentryScope())
        return .empty
    }

    @discardableResult
    public static func capture(event: SentryEvent) -> SentryId {
        _ = event
        return .empty
    }

    public static func configureScope(_ callback: (SentryScope) -> Void) {
        callback(SentryScope())
    }

    /// Fail closed: do not abort the process. Focus's internal settings
    /// button calls this as a diagnostic; a real crash reporter is absent.
    public static func crash() {}

    public static func close() {}
}
