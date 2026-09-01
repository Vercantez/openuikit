#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(ActivityKit)
import ActivityKit
#endif

import Foundation

#if canImport(SwiftUI)
/// A button shown on alarm presentation surfaces.
public struct AlarmButton: Sendable, Decodable, Encodable {
    public var text: LocalizedStringResource
    public var textColor: Color
    public var systemImageName: String

    public init(
        text: LocalizedStringResource,
        textColor: Color,
        systemImageName: String
    ) {
        self.text = text
        self.textColor = textColor
        self.systemImageName = systemImageName
    }

    public init(from decoder: Decoder) throws {
        throw AlarmKitHostBoundary.unobservedColorCoding
    }

    public func encode(to encoder: Encoder) throws {
        _ = encoder
        throw AlarmKitHostBoundary.unobservedColorCoding
    }
}

/// Visual configuration for an alarm's alert, countdown, and paused UI.
public struct AlarmPresentation: Sendable, Decodable, Encodable {
    public var alert: Alert
    public var countdown: Countdown?
    public var paused: Paused?

    public init(
        alert: Alert,
        countdown: Countdown? = nil,
        paused: Paused? = nil
    ) {
        self.alert = alert
        self.countdown = countdown
        self.paused = paused
    }

    public init(from decoder: Decoder) throws {
        throw AlarmKitHostBoundary.unobservedColorCoding
    }

    public func encode(to encoder: Encoder) throws {
        _ = encoder
        throw AlarmKitHostBoundary.unobservedColorCoding
    }

    public struct Alert: Sendable, Decodable, Encodable {
        public var title: LocalizedStringResource
        public var stopButton: AlarmButton
        public var secondaryButton: AlarmButton?
        public var secondaryButtonBehavior: SecondaryButtonBehavior?

        public init(
            title: LocalizedStringResource,
            stopButton: AlarmButton,
            secondaryButton: AlarmButton? = nil,
            secondaryButtonBehavior: SecondaryButtonBehavior? = nil
        ) {
            self.title = title
            self.stopButton = stopButton
            self.secondaryButton = secondaryButton
            self.secondaryButtonBehavior = secondaryButtonBehavior
        }

        public init(from decoder: Decoder) throws {
            throw AlarmKitHostBoundary.unobservedColorCoding
        }

        public func encode(to encoder: Encoder) throws {
            _ = encoder
            throw AlarmKitHostBoundary.unobservedColorCoding
        }

        public enum SecondaryButtonBehavior: Equatable, Hashable, Codable, Sendable {
            case countdown
            case custom
        }
    }

    public struct Countdown: Sendable, Decodable, Encodable {
        public var title: LocalizedStringResource
        public var pauseButton: AlarmButton?

        public init(title: LocalizedStringResource, pauseButton: AlarmButton? = nil) {
            self.title = title
            self.pauseButton = pauseButton
        }

        public init(from decoder: Decoder) throws {
            throw AlarmKitHostBoundary.unobservedColorCoding
        }

        public func encode(to encoder: Encoder) throws {
            _ = encoder
            throw AlarmKitHostBoundary.unobservedColorCoding
        }
    }

    public struct Paused: Sendable, Decodable, Encodable {
        public var title: LocalizedStringResource
        public var resumeButton: AlarmButton

        public init(title: LocalizedStringResource, resumeButton: AlarmButton) {
            self.title = title
            self.resumeButton = resumeButton
        }

        public init(from decoder: Decoder) throws {
            throw AlarmKitHostBoundary.unobservedColorCoding
        }

        public func encode(to encoder: Encoder) throws {
            _ = encoder
            throw AlarmKitHostBoundary.unobservedColorCoding
        }
    }
}

#if canImport(ActivityKit)
/// Presentation plus optional metadata used to request an alarm.
public struct AlarmAttributes<Metadata: AlarmMetadata>: Sendable, Decodable, Encodable {
    public typealias ContentState = AlarmPresentationState

    public var presentation: AlarmPresentation
    public var metadata: Metadata?
    public var tintColor: Color

    public init(
        presentation: AlarmPresentation,
        metadata: Metadata? = nil,
        tintColor: Color
    ) {
        self.presentation = presentation
        self.metadata = metadata
        self.tintColor = tintColor
    }

    public init(from decoder: Decoder) throws {
        throw AlarmKitHostBoundary.unobservedColorCoding
    }

    public func encode(to encoder: Encoder) throws {
        _ = encoder
        throw AlarmKitHostBoundary.unobservedColorCoding
    }
}

extension AlarmAttributes: ActivityAttributes {}
#endif
#endif
