//===----------------------------------------------------------------------===//
// AlarmKit Linux starting point
//
// Nominal types come from Foundation, and from SwiftUI / ActivityKit /
// AppIntents when those modules are actually present. This module never
// defines lookalike Color, LocalizedStringResource, ActivityAttributes,
// AlertConfiguration, or LiveActivityIntent types.
//
// canImport is not enough: ActivityKit and AppIntents can import on macOS
// while ActivityAttributes, AlertConfiguration, and LiveActivityIntent stay
// unavailable. The live-activity surface is compiled only on
// os(iOS) || os(watchOS) || os(visionOS) || os(Linux), plus canImport of
// each real module. macOS/tvOS keep a reduced module. No fallback types.
//===----------------------------------------------------------------------===//

#if canImport(ActivityKit) && (os(iOS) || os(watchOS) || os(visionOS) || os(Linux))
import ActivityKit
#endif

#if canImport(AppIntents) && (os(iOS) || os(watchOS) || os(visionOS) || os(Linux))
import AppIntents
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

import Foundation

/// Custom metadata attached to an alarm's live-activity attributes.
public protocol AlarmMetadata: Codable, Hashable, Sendable {}

/// Linux host boundary used when an Apple entitlement, scheduler, or
/// unobserved Codable payload cannot be produced. Not an Apple `AlarmError`.
@_spi(OpenUIKitHost)
public enum AlarmKitHostBoundary: Error, Equatable, Sendable {
    case authorizationPromptUnavailable
    case systemSchedulerUnavailable
    case unobservedColorCoding
}
