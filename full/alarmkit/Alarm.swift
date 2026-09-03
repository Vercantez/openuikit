import Foundation

/// An alarm or timer record returned by `AlarmManager`. Linux never creates
/// these through `schedule`; the Codable path is the public construction
/// surface and uses local keys. Darwin's Codable layout is unobserved.
public struct Alarm: Codable, Sendable {
    public typealias ID = UUID

    public var id: UUID
    public var state: State
    public var schedule: Schedule?
    public var countdownDuration: CountdownDuration?

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        state = try container.decode(State.self, forKey: .state)
        schedule = try container.decodeIfPresent(Schedule.self, forKey: .schedule)
        countdownDuration = try container.decodeIfPresent(
            CountdownDuration.self,
            forKey: .countdownDuration
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(state, forKey: .state)
        try container.encodeIfPresent(schedule, forKey: .schedule)
        try container.encodeIfPresent(countdownDuration, forKey: .countdownDuration)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case state
        case schedule
        case countdownDuration
    }
}

extension Alarm {
    public enum State: String, Codable, Hashable, Sendable {
        case scheduled
        case countdown
        case paused
        case alerting
    }

    public struct CountdownDuration: Codable, Equatable, Sendable {
        public var preAlert: TimeInterval?
        public var postAlert: TimeInterval?

        public init(preAlert: TimeInterval?, postAlert: TimeInterval?) {
            self.preAlert = preAlert
            self.postAlert = postAlert
        }
    }

    public enum Schedule: Hashable, Sendable {
        case fixed(Date)
        case relative(Relative)

        public struct Relative: Codable, Hashable, Sendable {
            public var time: Time
            public var repeats: Recurrence

            public init(time: Time, repeats: Recurrence = .never) {
                self.time = time
                self.repeats = repeats
            }

            public struct Time: Codable, Hashable, Sendable {
                public var hour: Int
                public var minute: Int

                public init(hour: Int, minute: Int) {
                    self.hour = hour
                    self.minute = minute
                }
            }

            public enum Recurrence: Hashable, Sendable {
                case never
                case weekly([Locale.Weekday])
            }
        }
    }
}

extension Alarm.Schedule: Codable {
    enum CodingKeys: String, CodingKey {
        case fixed
        case relative
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.fixed) {
            self = .fixed(try container.decode(Date.self, forKey: .fixed))
        } else if container.contains(.relative) {
            self = .relative(try container.decode(Relative.self, forKey: .relative))
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Alarm.Schedule requires fixed or relative"
                )
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fixed(let date):
            try container.encode(date, forKey: .fixed)
        case .relative(let relative):
            try container.encode(relative, forKey: .relative)
        }
    }
}

extension Alarm.Schedule.Relative.Recurrence: Codable {
    enum CodingKeys: String, CodingKey {
        case never
        case weekly
    }

    public init(from decoder: any Decoder) throws {
        if let single = try? decoder.singleValueContainer(),
           let label = try? single.decode(String.self),
           label == "never"
        {
            self = .never
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.weekly) {
            self = .weekly(try container.decode([Locale.Weekday].self, forKey: .weekly))
        } else if container.contains(.never) {
            self = .never
        } else if let single = try? decoder.singleValueContainer(),
                  let label = try? single.decode(String.self),
                  label == "never"
        {
            self = .never
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Alarm.Schedule.Relative.Recurrence requires never or weekly"
                )
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .never:
            var container = encoder.singleValueContainer()
            try container.encode("never")
        case .weekly(let days):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(days, forKey: .weekly)
        }
    }
}
