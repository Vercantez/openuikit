import Foundation

/// Visual configuration for an alarm's alert, countdown, and paused UI.
public struct AlarmPresentation: Codable, Sendable {
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

    public struct Alert: Codable, Sendable {
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

        /// Linux uses a placeholder stop button. Apple's default stop control
        /// is not recorded in the public graph.
        public init(
            title: LocalizedStringResource,
            secondaryButton: AlarmButton? = nil,
            secondaryButtonBehavior: SecondaryButtonBehavior? = nil
        ) {
            self.init(
                title: title,
                stopButton: AlarmButton(
                    text: "Stop",
                    textColor: .white,
                    systemImageName: "stop.circle.fill"
                ),
                secondaryButton: secondaryButton,
                secondaryButtonBehavior: secondaryButtonBehavior
            )
        }

        public enum SecondaryButtonBehavior: String, Equatable, Hashable, Codable, Sendable {
            case countdown
            case custom
        }
    }

    public struct Countdown: Codable, Sendable {
        public var title: LocalizedStringResource
        public var pauseButton: AlarmButton?

        public init(title: LocalizedStringResource, pauseButton: AlarmButton? = nil) {
            self.title = title
            self.pauseButton = pauseButton
        }
    }

    public struct Paused: Codable, Sendable {
        public var title: LocalizedStringResource
        public var resumeButton: AlarmButton

        public init(title: LocalizedStringResource, resumeButton: AlarmButton) {
            self.title = title
            self.resumeButton = resumeButton
        }
    }
}

/// A button shown on alarm presentation surfaces.
public struct AlarmButton: Codable, Sendable {
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
}

/// Presentation plus optional metadata used to request an alarm.
public struct AlarmAttributes<Metadata: AlarmMetadata>: Codable, Sendable {
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
}

extension AlarmAttributes: ActivityAttributes {}

/// Snapshot of an alarm as presented in a Live Activity.
public struct AlarmPresentationState: Equatable, Hashable, Codable, Sendable {
    public var alarmID: Alarm.ID
    public var mode: Mode

    public init(alarmID: Alarm.ID, mode: Mode) {
        self.alarmID = alarmID
        self.mode = mode
    }

    public enum Mode: Equatable, Hashable, Codable, Sendable {
        case alert(Alert)
        case countdown(Countdown)
        case paused(Paused)

        public struct Alert: Equatable, Hashable, Codable, Sendable {
            public var time: Alarm.Schedule.Relative.Time

            public init(time: Alarm.Schedule.Relative.Time) {
                self.time = time
            }
        }

        public struct Countdown: Equatable, Hashable, Codable, Sendable {
            public var totalCountdownDuration: TimeInterval
            public var previouslyElapsedDuration: TimeInterval
            public var startDate: Date
            public var fireDate: Date

            public init(
                totalCountdownDuration: TimeInterval,
                previouslyElapsedDuration: TimeInterval,
                startDate: Date,
                fireDate: Date
            ) {
                self.totalCountdownDuration = totalCountdownDuration
                self.previouslyElapsedDuration = previouslyElapsedDuration
                self.startDate = startDate
                self.fireDate = fireDate
            }
        }

        public struct Paused: Equatable, Hashable, Codable, Sendable {
            public var totalCountdownDuration: TimeInterval
            public var previouslyElapsedDuration: TimeInterval

            public init(
                totalCountdownDuration: TimeInterval,
                previouslyElapsedDuration: TimeInterval
            ) {
                self.totalCountdownDuration = totalCountdownDuration
                self.previouslyElapsedDuration = previouslyElapsedDuration
            }
        }
    }
}
