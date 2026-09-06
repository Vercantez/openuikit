#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(Intents)
@preconcurrency import Intents
#endif
import Foundation

// MARK: - Locations, mounting, accent, relevance, push

public struct WidgetLocation: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let homeScreen = Self(0)
    public static let lockScreen = Self(1)
    public static let iPhoneWidgetsOnMac = Self(2)
    public static let carPlay = Self(3)
    public static let standBy = Self(4)
}

public struct WidgetMountingStyle: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let elevated = Self(0)
    public static let recessed = Self(1)
}

public struct WidgetAccentedRenderingMode: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let fullColor = Self(0)
    public static let accented = Self(1)
    public static let accentedDesaturated = Self(2)
    public static let desaturated = Self(3)
}

public struct WidgetRelevanceGroup: Hashable, Sendable {
    private let name: String?
    private let kind: UInt8

    private init(kind: UInt8, name: String?) {
        self.kind = kind
        self.name = name
    }

    public static let automatic = Self(kind: 0, name: nil)
    public static let ungrouped = Self(kind: 1, name: nil)

    public static func named(_ name: String) -> WidgetRelevanceGroup {
        Self(kind: 2, name: name)
    }
}

public struct WidgetRelevanceAttribute<Configuration>: @unchecked Sendable {
    @_spi(OpenUIKitHost) public let portableGroup: WidgetRelevanceGroup?
    @_spi(OpenUIKitHost) public let portableHasContext: Bool
    @_spi(OpenUIKitHost) public let portableHasConfiguration: Bool

    public init(configuration: Configuration, group: WidgetRelevanceGroup) {
        _ = configuration
        portableGroup = group
        portableHasContext = false
        portableHasConfiguration = true
    }

    public init(configuration: Configuration, context: RelevantContext) {
        _ = configuration
        _ = context
        portableGroup = nil
        portableHasContext = true
        portableHasConfiguration = true
    }

    public init(group: WidgetRelevanceGroup) {
        portableGroup = group
        portableHasContext = false
        portableHasConfiguration = false
    }

    public init(context: RelevantContext) {
        _ = context
        portableGroup = nil
        portableHasContext = true
        portableHasConfiguration = false
    }
}

public struct WidgetRelevance<Intent>: @unchecked Sendable {
    @_spi(OpenUIKitHost) public let portableAttributeCount: Int
    @_spi(OpenUIKitHost) public let portableGroups: [WidgetRelevanceGroup]

    public init(_ attributes: [WidgetRelevanceAttribute<Intent>] = []) {
        portableAttributeCount = attributes.count
        portableGroups = attributes.compactMap(\.portableGroup)
    }
}

public struct WidgetPushInfo: Hashable, Sendable {
    public var token: Data

    public init(token: Data = Data()) {
        self.token = token
    }
}

public protocol WidgetPushHandler {
    init()
    func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo])
}

public struct IntentRecommendation<T: INIntent>: @unchecked Sendable {
    public let intent: T
    public let description: Text

    public init(intent: T, description: Text) {
        self.intent = intent
        self.description = description
    }

    public init(intent: T, description: LocalizedStringKey) {
        self.init(intent: intent, description: Text(description))
    }

    public init(intent: T, description: LocalizedStringResource) {
        self.init(intent: intent, description: Text(String(describing: description)))
    }

    @_disfavoredOverload
    public init<S: StringProtocol>(intent: T, description: S) {
        self.init(intent: intent, description: Text(String(description)))
    }
}

public struct LevelOfDetail: Equatable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let `default` = Self(0)
    public static let simplified = Self(1)
}

public struct SupportedActivityFamiliesEnvironmentKey: EnvironmentKey {
    public typealias Value = Set<ActivityFamily>
    public static var defaultValue: Set<ActivityFamily> { [] }
}

public struct WidgetPreviewContext {
    public let family: WidgetFamily

    public init(family: WidgetFamily) {
        self.family = family
    }
}
