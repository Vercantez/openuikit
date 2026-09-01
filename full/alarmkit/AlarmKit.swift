//===----------------------------------------------------------------------===//
// AlarmKit Linux starting point
//
// Nominal types come from Foundation, and from SwiftUI / ActivityKit /
// AppIntents when those modules are actually present. This module never
// defines lookalike Color, LocalizedStringResource, ActivityAttributes,
// AlertConfiguration, or LiveActivityIntent types.
//===----------------------------------------------------------------------===//

#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(AppIntents)
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
