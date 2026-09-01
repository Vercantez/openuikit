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

/// Entry point for scheduling and observing alarms.
///
/// Linux has no AlarmKit entitlement prompt or system alarm daemon.
/// `authorizationState` stays `.notDetermined` until a future observed
/// authorization path exists. Scheduler mutations throw a host boundary
/// error. Observation sequences stay open until cancelled or the manager
/// is deallocated.
public class AlarmManager: @unchecked Sendable {
    public static let shared = AlarmManager()

    private let lock = NSLock()
    private var storedAuthorization: AuthorizationState = .notDetermined
    private let alarmBroker = AlarmKitUpdateBroker<[Alarm]>(initial: [])
    private let authorizationBroker = AlarmKitUpdateBroker<AuthorizationState>(
        initial: .notDetermined
    )

    private init() {}

    deinit {
        alarmBroker.finish()
        authorizationBroker.finish()
    }

    @_spi(OpenUIKitHost)
    public static func hostIsolated() -> AlarmManager {
        AlarmManager()
    }

    public var authorizationState: AuthorizationState {
        lock.lock()
        defer { lock.unlock() }
        return storedAuthorization
    }

    /// No usage-description prompt or entitlement decision is available.
    /// The stored state is left unchanged.
    public func requestAuthorization() async throws -> AuthorizationState {
        throw AlarmKitHostBoundary.authorizationPromptUnavailable
    }

    public var alarms: [Alarm] {
        get throws {
            throw AlarmKitHostBoundary.systemSchedulerUnavailable
        }
    }

    /// Ongoing snapshot sequence. Yields the current alarms, then remains
    /// open until cancelled or this manager is deallocated. Values resume
    /// the iterating task; there is no extra callback queue.
    public var alarmUpdates: AlarmUpdates {
        AlarmUpdates(broker: alarmBroker)
    }

    /// Ongoing snapshot sequence. Yields the current authorization state,
    /// then remains open until cancelled or this manager is deallocated.
    public var authorizationUpdates: AlarmAuthorizationStateUpdates {
        AlarmAuthorizationStateUpdates(broker: authorizationBroker)
    }

    public func countdown(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitHostBoundary.systemSchedulerUnavailable
    }

    public func cancel(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitHostBoundary.systemSchedulerUnavailable
    }

    public func stop(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitHostBoundary.systemSchedulerUnavailable
    }

    public func pause(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitHostBoundary.systemSchedulerUnavailable
    }

    public func resume(id: Alarm.ID) throws {
        _ = id
        throw AlarmKitHostBoundary.systemSchedulerUnavailable
    }

    @_spi(OpenUIKitHost)
    public func hostPublishAuthorization(_ state: AuthorizationState) {
        lock.lock()
        storedAuthorization = state
        lock.unlock()
        authorizationBroker.publish(state)
    }

    @_spi(OpenUIKitHost)
    public func hostPublishAlarms(_ alarms: [Alarm]) {
        alarmBroker.publish(alarms)
    }

#if canImport(SwiftUI) && canImport(ActivityKit) && canImport(AppIntents)
    public func schedule<Metadata: AlarmMetadata>(
        id: Alarm.ID,
        configuration: AlarmConfiguration<Metadata>
    ) async throws -> Alarm {
        _ = id
        _ = configuration
        throw AlarmKitHostBoundary.authorizationPromptUnavailable
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
    }
#endif

    public enum AlarmError: Error, Equatable, Hashable, Sendable {
        case maximumLimitReached
    }

    public enum AuthorizationState: Equatable, Hashable, Codable, Sendable {
        case notDetermined
        case denied
        case authorized
    }

    public struct AlarmUpdates: AsyncSequence, Sendable {
        public typealias Element = [Alarm]
        public typealias AsyncIterator = Iterator

        let broker: AlarmKitUpdateBroker<[Alarm]>

        public func makeAsyncIterator() -> Iterator {
            Iterator(stream: broker.subscribe())
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = [Alarm]
            var iterator: AsyncStream<[Alarm]>.Iterator

            init(stream: AsyncStream<[Alarm]>) {
                iterator = stream.makeAsyncIterator()
            }

            public mutating func next() async -> [Alarm]? {
                await iterator.next()
            }
        }
    }

    public struct AlarmAuthorizationStateUpdates: AsyncSequence, Sendable {
        public typealias Element = AuthorizationState
        public typealias AsyncIterator = Iterator

        let broker: AlarmKitUpdateBroker<AuthorizationState>

        public func makeAsyncIterator() -> Iterator {
            Iterator(stream: broker.subscribe())
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = AuthorizationState
            var iterator: AsyncStream<AuthorizationState>.Iterator

            init(stream: AsyncStream<AuthorizationState>) {
                iterator = stream.makeAsyncIterator()
            }

            public mutating func next() async -> AuthorizationState? {
                await iterator.next()
            }
        }
    }
}
