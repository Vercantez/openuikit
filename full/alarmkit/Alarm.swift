import Foundation

/// An alarm that can alert once or on a repeating schedule.
public struct Alarm: Identifiable, Codable, Sendable {
    public typealias ID = UUID

    public var id: UUID
    public var countdownDuration: CountdownDuration?
    public var state: State
    public var schedule: Schedule?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        countdownDuration = try container.decodeIfPresent(
            CountdownDuration.self,
            forKey: .countdownDuration
        )
        state = try container.decode(State.self, forKey: .state)
        schedule = try container.decodeIfPresent(Schedule.self, forKey: .schedule)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(countdownDuration, forKey: .countdownDuration)
        try container.encode(state, forKey: .state)
        try container.encodeIfPresent(schedule, forKey: .schedule)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case countdownDuration
        case state
        case schedule
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
    public enum State: String, Equatable, Hashable, Codable, Sendable {
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
