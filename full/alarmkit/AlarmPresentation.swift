import Foundation

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

public struct AlarmPresentation: Codable, Sendable {
    public var alert: Alert
    public var countdown: Countdown?
    public var paused: Paused?

    public init(alert: Alert, countdown: Countdown? = nil, paused: Paused? = nil) {
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

        /// Darwin's default stop button artwork is unobserved. Linux fills a
        /// local placeholder so this overload compiles and stays fail-closed.
        public init(
            title: LocalizedStringResource,
            secondaryButton: AlarmButton? = nil,
            secondaryButtonBehavior: SecondaryButtonBehavior? = nil
        ) {
            self.init(
                title: title,
                stopButton: AlarmPresentation.linuxPlaceholderStopButton,
                secondaryButton: secondaryButton,
                secondaryButtonBehavior: secondaryButtonBehavior
            )
        }

        public enum SecondaryButtonBehavior: String, Codable, Hashable, Sendable {
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

    static let linuxPlaceholderStopButton = AlarmButton(
        text: LocalizedStringResource("Stop"),
        textColor: .primary,
        systemImageName: "stop.circle"
    )
}

public struct AlarmPresentationState: Codable, Hashable, Sendable {
    public var alarmID: Alarm.ID
    public var mode: Mode

    public init(alarmID: Alarm.ID, mode: Mode) {
        self.alarmID = alarmID
        self.mode = mode
    }

    public enum Mode: Codable, Hashable, Sendable {
        case alert(Alert)
        case countdown(Countdown)
        case paused(Paused)

        public struct Alert: Codable, Hashable, Sendable {
            public var time: Alarm.Schedule.Relative.Time

            public init(time: Alarm.Schedule.Relative.Time) {
                self.time = time
            }
        }

        public struct Countdown: Codable, Hashable, Sendable {
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

        public struct Paused: Codable, Hashable, Sendable {
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
