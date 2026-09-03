@_exported import Foundation

// Linux starting point for Apple's public AlarmKit module, reconstructed from
// the pinned Xcode 26.1 iPhoneOS public surface. Isolated host compilation
// cannot import SwiftUI, AppIntents, or ActivityKit, so the Darwin types those
// modules own are replaced here by fail-closed stand-ins with the same names
// the graph spells. They are not Apple's types.

/// Linux stand-in for `SwiftUI.Color`. RGBA payload is a local encoding; Darwin
/// `Color` Codable representation is unobserved.
public struct Color: Hashable, Codable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double

    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    public static let clear = Color(red: 0, green: 0, blue: 0, opacity: 0)
    public static let primary = Color(red: 0, green: 0, blue: 0, opacity: 1)
}

/// Linux stand-in for `Foundation.LocalizedStringResource`, which is absent
/// from this Swift 6.2.4 Linux Foundation. Stores the resource key only;
/// Darwin bundle/locale lookup is unobserved.
public struct LocalizedStringResource: Hashable, Codable, Sendable,
    ExpressibleByStringLiteral
{
    public var key: String

    public init(_ key: String) {
        self.key = key
    }

    public init(stringLiteral value: String) {
        self.key = value
    }
}

/// Linux stand-in for `AppIntents.LiveActivityIntent`. Intents are stored and
/// never performed; Linux has no Live Activity runtime.
public protocol LiveActivityIntent: Sendable {}

/// Linux stand-in for `ActivityKit.AlertConfiguration` so
/// `AlarmConfiguration` can name `AlertSound` without importing ActivityKit.
public enum AlertConfiguration {
    public struct AlertSound: Hashable, Codable, Sendable {
        public var identifier: String

        public static let `default` = AlertSound(identifier: "default")

        public init(named name: String) {
            self.identifier = name
        }

        init(identifier: String) {
            self.identifier = identifier
        }
    }
}

/// Public metadata attached to an alarm's live-activity attributes.
public protocol AlarmMetadata: Decodable, Encodable, Hashable, Sendable {}

/// NSError domain used when Linux refuses Apple alarm-service operations.
public let AlarmKitLinuxErrorDomain = "AlarmKit.linux"

enum AlarmKitLinuxError {
    static let unavailableCode = 1

    static func unavailable(
        _ message: String = "Linux has no Apple alarm service, entitlement prompt, or scheduling daemon"
    ) -> NSError {
        NSError(
            domain: AlarmKitLinuxErrorDomain,
            code: unavailableCode,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
