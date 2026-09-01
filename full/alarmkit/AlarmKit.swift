//===----------------------------------------------------------------------===//
// Portable AlarmKit (Linux starting point)
//
// Public value types, presentation models, and AlarmManager APIs are real
// source-compatible declarations from the Xcode 26.1 iPhoneOS symbol graph.
// Linux has no AlarmKit entitlement, alarm daemon, Lock Screen UI, or
// Dynamic Island presentation. Authorization never becomes `.authorized`,
// and every scheduler mutation fails closed.
//
// Isolated `swiftc` has no SwiftUI, ActivityKit, or AppIntents modules.
// The shims below preserve the Apple type names used by this surface.
//===----------------------------------------------------------------------===//

import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(AppIntents)
import AppIntents
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Isolated-compile shims

#if !canImport(SwiftUI)
/// Process-local stand-in for `SwiftUI.Color` used by `AlarmButton` and
/// `AlarmAttributes`. This is not Apple's adaptive color type.
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

    public static let black = Color(red: 0, green: 0, blue: 0)
    public static let white = Color(red: 1, green: 1, blue: 1)
    public static let red = Color(red: 1, green: 0, blue: 0)
    public static let green = Color(red: 0, green: 1, blue: 0)
    public static let blue = Color(red: 0, green: 0, blue: 1)
    public static let orange = Color(red: 1, green: 0.58, blue: 0)
    public static let yellow = Color(red: 1, green: 0.8, blue: 0)
    public static let pink = Color(red: 1, green: 0.41, blue: 0.71)
    public static let purple = Color(red: 0.5, green: 0, blue: 0.5)
    public static let indigo = Color(red: 0.29, green: 0.0, blue: 0.51)
    public static let gray = Color(red: 0.56, green: 0.56, blue: 0.58)
    public static let primary = Color.black
    public static let secondary = Color.gray
}
#endif

/// Process-local stand-in for `Foundation.LocalizedStringResource`.
/// Isolated toolchain Foundation does not include the Apple type.
public struct LocalizedStringResource: Hashable, Codable, Sendable,
    ExpressibleByStringLiteral, ExpressibleByStringInterpolation
{
    public var key: String
    public var defaultValue: String

    public init(stringLiteral value: String) {
        key = value
        defaultValue = value
    }

    public init(stringInterpolation: StringInterpolation) {
        key = stringInterpolation.storage
        defaultValue = stringInterpolation.storage
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        var storage = ""

        public init(literalCapacity: Int, interpolationCount: Int) {
            storage.reserveCapacity(literalCapacity + interpolationCount * 8)
        }

        public mutating func appendLiteral(_ literal: String) {
            storage += literal
        }

        public mutating func appendInterpolation<T>(_ value: T) {
            storage += String(describing: value)
        }
    }
}

#if !canImport(ActivityKit)
/// Minimal `ActivityAttributes` surface required for `AlarmAttributes`.
public protocol ActivityAttributes: Decodable, Encodable {
    associatedtype ContentState: Decodable, Encodable, Hashable
}

/// Isolated stand-in for `ActivityKit.AlertConfiguration`.
public struct AlertConfiguration: Equatable, Sendable {
    public struct AlertSound: Equatable, Hashable, Codable, Sendable {
        private enum Kind: Equatable, Hashable, Codable, Sendable {
            case `default`
            case silent
            case named(String)
        }

        private var kind: Kind

        public static var `default`: AlertSound {
            AlertSound(kind: .default)
        }

        public static var silent: AlertSound {
            AlertSound(kind: .silent)
        }

        public static func named(_ name: String) -> AlertSound {
            AlertSound(kind: .named(name))
        }
    }
}
#endif

#if !canImport(AppIntents)
/// Isolated stand-in for `AppIntents.LiveActivityIntent`.
public protocol LiveActivityIntent: Sendable {}
#endif

/// Custom metadata attached to an alarm's live-activity attributes.
public protocol AlarmMetadata: Codable, Hashable, Sendable {}
