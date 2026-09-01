import Foundation

/// Entry point for scheduling and observing alarms.
///
/// Linux has no AlarmKit entitlement or system alarm daemon. Authorization
/// remains `.notDetermined` until `requestAuthorization()` fails closed to
/// `.denied`. Scheduler methods throw `AlarmKitUnavailableError`.
public class AlarmManager: @unchecked Sendable {
    public static let shared = AlarmManager()

    private let lock = NSLock()
    private var storedAuthorization: AuthorizationState = .notDetermined

    private init() {}

    public var authorizationState: AuthorizationState {
        lock.lock()
        defer { lock.unlock() }
        return storedAuthorization
    }

    /// Always resolves to `.denied` on Linux. No privacy prompt is shown and
    /// no Apple entitlement is granted.
    public func requestAuthorization() async throws -> AuthorizationState {
        denyAuthorization()
    }

    private func denyAuthorization() -> AuthorizationState {
        lock.lock()
        defer { lock.unlock() }
        storedAuthorization = .denied
        return storedAuthorization
    }

    public var alarms: [Alarm] {
        get throws {
            throw AlarmKitUnavailableError.systemSchedulerUnavailable
        }
    }

    public var alarmUpdates: some AsyncSequence<[Alarm], Never> {
        AlarmUpdates()
    }

    public var authorizationUpdates: some AsyncSequence<AuthorizationState, Never> {
        AlarmAuthorizationStateUpdates(initial: authorizationState)
    }

    public func schedule<Metadata: AlarmMetadata>(
        id: Alarm.ID,
        configuration: AlarmConfiguration<Metadata>
    ) async throws -> Alarm {
        _ = id
        _ = configuration
        throw AlarmKitUnavailableError.entitlementUnavailable
    }

    public func countdown(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitUnavailableError.systemSchedulerUnavailable
    }

    public func cancel(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitUnavailableError.systemSchedulerUnavailable
    }

    public func stop(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitUnavailableError.systemSchedulerUnavailable
    }

    public func pause(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitUnavailableError.systemSchedulerUnavailable
    }

    public func resume(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitUnavailableError.systemSchedulerUnavailable
    }

    public enum AlarmError: Error, Equatable, Hashable, Sendable {
        case maximumLimitReached
    }

    public enum AuthorizationState: String, Equatable, Hashable, Codable, Sendable {
        case notDetermined
        case denied
        case authorized
    }

    public struct AlarmConfiguration<Metadata: AlarmMetadata>: @unchecked Sendable {
        let countdownDuration: Alarm.CountdownDuration?
        let schedule: Alarm.Schedule?
        let attributes: AlarmAttributes<Metadata>
        let stopIntent: (any LiveActivityIntent)?
        let secondaryIntent: (any LiveActivityIntent)?
        let sound: AlertConfiguration.AlertSound

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
        ) -> AlarmConfiguration<Metadata> {
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
        ) -> AlarmConfiguration<Metadata> {
            AlarmConfiguration(
                countdownDuration: Alarm.CountdownDuration(
                    preAlert: duration,
                    postAlert: nil
                ),
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

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }

        public struct Iterator: AsyncIteratorProtocol, Sendable {
            public typealias Element = [Alarm]
            private var emitted = false

            public mutating func next() async -> [Alarm]? {
                if emitted {
                    return nil
                }
                emitted = true
                return []
            }
        }
    }

    public struct AlarmAuthorizationStateUpdates: AsyncSequence, Sendable {
        public typealias Element = AuthorizationState
        public typealias AsyncIterator = Iterator

        private let initial: AuthorizationState

        init(initial: AuthorizationState) {
            self.initial = initial
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator(initial: initial)
        }

        public struct Iterator: AsyncIteratorProtocol, Sendable {
            public typealias Element = AuthorizationState
            private let initial: AuthorizationState
            private var emitted = false

            init(initial: AuthorizationState) {
                self.initial = initial
            }

            public mutating func next() async -> AuthorizationState? {
                if emitted {
                    return nil
                }
                emitted = true
                return initial
            }
        }
    }
}

/// Fail-closed Linux boundary. Not an Apple `AlarmError` case.
public enum AlarmKitUnavailableError: Error, Equatable, Sendable {
    case entitlementUnavailable
    case systemSchedulerUnavailable
}
