import Foundation

public final class AlarmManager: @unchecked Sendable {
    public static let shared = AlarmManager()

    private let queue = DispatchQueue(label: "AlarmKit.AlarmManager")
    private var authorization: AuthorizationState = .notDetermined

    private init() {}

    public var authorizationState: AuthorizationState {
        queue.sync { authorization }
    }

    public var alarms: [Alarm] {
        get throws {
            throw AlarmKitLinuxError.unavailable()
        }
    }

    public var alarmUpdates: some AsyncSequence<[Alarm], Never> {
        AlarmUpdates()
    }

    public var authorizationUpdates: some AsyncSequence<AuthorizationState, Never> {
        AlarmAuthorizationStateUpdates()
    }

    public func requestAuthorization() async throws -> AuthorizationState {
        await withCheckedContinuation { continuation in
            queue.async {
                self.authorization = .denied
                continuation.resume(returning: self.authorization)
            }
        }
    }

    public func schedule<Metadata: AlarmMetadata>(
        id: Alarm.ID,
        configuration: AlarmConfiguration<Metadata>
    ) async throws -> Alarm {
        _ = id
        _ = configuration
        throw AlarmKitLinuxError.unavailable()
    }

    public func stop(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitLinuxError.unavailable()
    }

    public func pause(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitLinuxError.unavailable()
    }

    public func cancel(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitLinuxError.unavailable()
    }

    public func resume(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitLinuxError.unavailable()
    }

    public func countdown(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitLinuxError.unavailable()
    }
}

extension AlarmManager {
    public enum AuthorizationState: String, Codable, Hashable, Sendable {
        case notDetermined
        case denied
        case authorized
    }

    public enum AlarmError: Error, Hashable, Sendable {
        case maximumLimitReached
    }

    public struct AlarmConfiguration<Metadata: AlarmMetadata>: Sendable {
        public var countdownDuration: Alarm.CountdownDuration?
        public var schedule: Alarm.Schedule?
        public var attributes: AlarmAttributes<Metadata>
        public var stopIntent: (any LiveActivityIntent)?
        public var secondaryIntent: (any LiveActivityIntent)?
        public var sound: AlertConfiguration.AlertSound

        public init(
            countdownDuration: Alarm.CountdownDuration? = nil,
            schedule: Alarm.Schedule? = nil,
            attributes: AlarmAttributes<Metadata>,
            stopIntent: (any LiveActivityIntent)? = nil,
            secondaryIntent: (any LiveActivityIntent)? = nil,
            sound: AlertConfiguration.AlertSound = .default
        ) {
            self.countdownDuration = countdownDuration
            self.schedule = schedule
            self.attributes = attributes
            self.stopIntent = stopIntent
            self.secondaryIntent = secondaryIntent
            self.sound = sound
        }

        public static func alarm(
            schedule: Alarm.Schedule? = nil,
            attributes: AlarmAttributes<Metadata>,
            stopIntent: (any LiveActivityIntent)? = nil,
            secondaryIntent: (any LiveActivityIntent)? = nil,
            sound: AlertConfiguration.AlertSound = .default
        ) -> AlarmManager.AlarmConfiguration<Metadata> {
            AlarmConfiguration(
                countdownDuration: nil,
                schedule: schedule,
                attributes: attributes,
                stopIntent: stopIntent,
                secondaryIntent: secondaryIntent,
                sound: sound
            )
        }

        public static func timer(
            duration: TimeInterval,
            attributes: AlarmAttributes<Metadata>,
            stopIntent: (any LiveActivityIntent)? = nil,
            secondaryIntent: (any LiveActivityIntent)? = nil,
            sound: AlertConfiguration.AlertSound = .default
        ) -> AlarmManager.AlarmConfiguration<Metadata> {
            AlarmConfiguration(
                countdownDuration: Alarm.CountdownDuration(preAlert: duration, postAlert: nil),
                schedule: nil,
                attributes: attributes,
                stopIntent: stopIntent,
                secondaryIntent: secondaryIntent,
                sound: sound
            )
        }
    }

    public struct AlarmUpdates: AsyncSequence, Sendable {
        public typealias Element = [Alarm]
        public typealias AsyncIterator = Iterator
        public typealias Failure = Never

        public struct Iterator: AsyncIteratorProtocol, Sendable {
            public typealias Element = [Alarm]
            public typealias Failure = Never

            public init() {}

            public mutating func next() async -> [Alarm]? {
                nil
            }
        }

        public init() {}

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }
    }

    public struct AlarmAuthorizationStateUpdates: AsyncSequence, Sendable {
        public typealias Element = AlarmManager.AuthorizationState
        public typealias AsyncIterator = Iterator
        public typealias Failure = Never

        public struct Iterator: AsyncIteratorProtocol, Sendable {
            public typealias Element = AlarmManager.AuthorizationState
            public typealias Failure = Never

            public init() {}

            public mutating func next() async -> AlarmManager.AuthorizationState? {
                nil
            }
        }

        public init() {}

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }
    }
}
