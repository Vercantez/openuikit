// Fail-closed stand-in for Segment (segmentio/analytics-swift 1.8.0,
// 5d3a762d). Surface = what ios-oss touches:
//   Library/Tracking/Segment.swift: Configuration(writeKey:).flushAt(_:)
//     .flushInterval(_:).setTrackedApplicationLifecycleEvents([...]),
//     Analytics(configuration:), and `extension Analytics:
//     IdentifyingTrackingClient, TrackingClientType` — i.e.
//     track(name:properties:), identify(userId:traits:), reset(),
//     anonymousId, userId
//   Library/Tracking/Vendor/BrazeDebounceMiddleware.swift: EventPlugin,
//     PluginType.before, IdentifyEvent (.userId/.anonymousId/.traits/
//     .integrations), JSON.add(value:forKey:), `weak var analytics`
//   Kickstarter-iOS/AppDelegate.swift:282-300: add(plugin:), .enabled
//
// Behaviour: there is no Segment backend and no event pipeline. track /
// identify / reset are dropped — nothing is queued, nothing is flushed, and
// identify does NOT adopt the user id (`userId` stays nil). No anonymous id
// is minted (`anonymousId` is ""). add(plugin:) attaches the plugin and
// calls its `configure(analytics:)` as the SDK does, but no event and no
// settings ever reach a plugin, so a destination never activates.
// `queuedEventCount` is not SDK API; it lets a test prove nothing was queued.
import Foundation

// MARK: - JSON

public enum JSONError: Error {
    case incorrectType
    case nonJSONType(type: String)
}

public enum JSON: Equatable {
    case null
    case bool(Bool)
    case number(Decimal)
    case string(String)
    case array([JSON])
    case object([String: JSON])

    public init(_ value: Any) throws {
        switch value {
        case is NSNull: self = .null
        case let v as Bool: self = .bool(v)
        case let v as Int: self = .number(Decimal(v))
        case let v as Double: self = .number(Decimal(v))
        case let v as Decimal: self = .number(v)
        case let v as String: self = .string(v)
        case let v as [Any]: self = .array(try v.map { try JSON($0) })
        case let v as [String: Any]: self = .object(try v.mapValues { try JSON($0) })
        case let v as JSON: self = v
        default: throw JSONError.nonJSONType(type: String(describing: type(of: value)))
        }
    }

    /// Adds `value` under `key` to an object, as the SDK's `JSON.add(value:forKey:)`.
    public func add(value: Any, forKey key: String) throws -> JSON {
        guard case var .object(dict) = self else { throw JSONError.incorrectType }
        dict[key] = try JSON(value)
        return .object(dict)
    }
}

// MARK: - Events

public protocol RawEvent {
    var type: String? { get set }
    var anonymousId: String? { get set }
    var messageId: String? { get set }
    var userId: String? { get set }
    var timestamp: String? { get set }
    var context: JSON? { get set }
    var integrations: JSON? { get set }
}

public struct IdentifyEvent: RawEvent {
    public var type: String? = "identify"
    public var anonymousId: String?
    public var messageId: String?
    public var userId: String?
    public var timestamp: String?
    public var context: JSON?
    public var integrations: JSON?
    public var traits: JSON?

    public init(userId: String? = nil, traits: JSON? = nil) {
        self.userId = userId
        self.traits = traits
    }
}

public struct TrackEvent: RawEvent {
    public var type: String? = "track"
    public var anonymousId: String?
    public var messageId: String?
    public var userId: String?
    public var timestamp: String?
    public var context: JSON?
    public var integrations: JSON?
    public var event: String
    public var properties: JSON?

    public init(event: String, properties: JSON?) {
        self.event = event
        self.properties = properties
    }
}

// MARK: - Plugins

public enum PluginType: Int {
    case before
    case enrichment
    case destination
    case after
    case utility
}

public protocol Plugin: AnyObject {
    var type: PluginType { get }
    var analytics: Analytics? { get set }
    func configure(analytics: Analytics)
    func execute<T: RawEvent>(event: T?) -> T?
    func shutdown()
}

extension Plugin {
    public func configure(analytics: Analytics) { self.analytics = analytics }
    public func execute<T: RawEvent>(event: T?) -> T? { event }
    public func shutdown() {}
}

public protocol EventPlugin: Plugin {
    func identify(event: IdentifyEvent) -> IdentifyEvent?
    func track(event: TrackEvent) -> TrackEvent?
    func reset()
    func flush()
}

extension EventPlugin {
    public func identify(event: IdentifyEvent) -> IdentifyEvent? { event }
    public func track(event: TrackEvent) -> TrackEvent? { event }
    public func reset() {}
    public func flush() {}
}

public protocol DestinationPlugin: EventPlugin {
    var key: String { get }
}

// MARK: - Configuration

public struct TrackedLifecycleEvent: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let applicationInstalled = TrackedLifecycleEvent(rawValue: 1 << 0)
    public static let applicationUpdated = TrackedLifecycleEvent(rawValue: 1 << 1)
    public static let applicationOpened = TrackedLifecycleEvent(rawValue: 1 << 2)
    public static let applicationBackgrounded = TrackedLifecycleEvent(rawValue: 1 << 3)
    public static let applicationForegrounded = TrackedLifecycleEvent(rawValue: 1 << 4)
    public static let applicationTerminated = TrackedLifecycleEvent(rawValue: 1 << 5)
    public static let none: TrackedLifecycleEvent = []
    public static let all: TrackedLifecycleEvent = [
        .applicationInstalled, .applicationUpdated, .applicationOpened,
        .applicationBackgrounded, .applicationForegrounded, .applicationTerminated,
    ]
}

public final class Configuration {
    public let writeKey: String
    public private(set) var flushAtCount = 20
    public private(set) var flushIntervalSeconds: TimeInterval = 30
    public private(set) var trackedApplicationLifecycleEvents: TrackedLifecycleEvent = .all

    public init(writeKey: String) { self.writeKey = writeKey }

    @discardableResult
    public func flushAt(_ count: Int) -> Configuration { flushAtCount = count; return self }

    @discardableResult
    public func flushInterval(_ interval: TimeInterval) -> Configuration { flushIntervalSeconds = interval; return self }

    @discardableResult
    public func setTrackedApplicationLifecycleEvents(_ events: TrackedLifecycleEvent) -> Configuration {
        trackedApplicationLifecycleEvents = events
        return self
    }
}

// MARK: - Analytics

public final class Analytics {
    public let configuration: Configuration
    public var enabled = true
    public private(set) var plugins: [Plugin] = []

    public init(configuration: Configuration) { self.configuration = configuration }

    /// No anonymous id is minted: there is no Segment identity on OpenUIKit.
    public var anonymousId: String { "" }

    /// Never set: `identify` is dropped.
    public var userId: String? { nil }

    /// Not SDK API. Always 0: no event is ever queued.
    public var queuedEventCount: Int { 0 }

    /// Dropped.
    public func track(name: String, properties: [String: Any]? = nil) {}

    /// Dropped; the user id is not adopted.
    public func identify(userId: String, traits: [String: Any]? = nil) {}

    /// Dropped (there is no stored identity to reset).
    public func reset() {}

    /// Dropped.
    public func flush(completion: (() -> Void)? = nil) { completion?() }

    @discardableResult
    public func add(plugin: Plugin) -> Plugin {
        plugin.configure(analytics: self)
        plugins.append(plugin)
        return plugin
    }
}
