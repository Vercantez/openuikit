import Foundation

/// An alarm that can alert once or on a repeating schedule.
public struct Alarm: Codable, Sendable {
    public typealias ID = UUID

    public var id: UUID
    public var countdownDuration: CountdownDuration?
    public var state: State
    public var schedule: Schedule?

    @_spi(OpenUIKitHost)
    public init(
        id: UUID,
        countdownDuration: CountdownDuration?,
        state: State,
        schedule: Schedule?
    ) {
        self.id = id
        self.countdownDuration = countdownDuration
        self.state = state
        self.schedule = schedule
    }
}

extension Alarm {
    /// Pre-alert and post-alert (snooze/repeat) durations in seconds.
    public struct CountdownDuration: Equatable, Codable, Sendable {
        public var preAlert: TimeInterval?
        public var postAlert: TimeInterval?

        public init(preAlert: TimeInterval?, postAlert: TimeInterval?) {
            self.preAlert = preAlert
            self.postAlert = postAlert
        }
    }

    /// Lifecycle state of a scheduled alarm.
    public enum State: Equatable, Hashable, Codable, Sendable {
        case scheduled
        case countdown
        case paused
        case alerting
    }

    /// When the alarm should fire.
    public enum Schedule: Equatable, Hashable, Codable, Sendable {
        case fixed(Date)
        case relative(Relative)

        /// A wall-clock time, optionally repeating on weekdays.
        public struct Relative: Equatable, Hashable, Codable, Sendable {
            public var time: Time
            public var repeats: Recurrence

            public init(time: Time, repeats: Recurrence = .never) {
                self.time = time
                self.repeats = repeats
            }

            public struct Time: Equatable, Hashable, Codable, Sendable {
                public var hour: Int
                public var minute: Int

                public init(hour: Int, minute: Int) {
                    self.hour = hour
                    self.minute = minute
                }
            }

            public enum Recurrence: Equatable, Hashable, Codable, Sendable {
                case never
                case weekly([Locale.Weekday])
            }
        }
    }
}

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
