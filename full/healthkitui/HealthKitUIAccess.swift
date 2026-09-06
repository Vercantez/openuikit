import Foundation

#if canImport(HealthKit)
import HealthKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Snapshot of one `View.healthDataAccessRequest` application.
/// Completions are not part of the snapshot: they fire only through
/// `HealthKitUIHostControl.failClosedPendingAccessRequests()`.
public struct HealthKitUIAccessRequestRecord: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case shareAndRead
        case readOnly
        case perObject
    }

    public var kind: Kind
    public var shareCount: Int
    public var readCount: Int
    public var objectTypeIdentifier: String?
    public var hasPredicate: Bool
}

final class HealthKitUIAccessRequestRegistry: @unchecked Sendable {
    static let shared = HealthKitUIAccessRequestRegistry()

    private let lock = NSLock()
    private var storedRecords: [HealthKitUIAccessRequestRecord] = []
    private var completions: [(Result<Bool, any Error>) -> Void] = []

    var records: [HealthKitUIAccessRequestRecord] {
        lock.lock()
        defer { lock.unlock() }
        return storedRecords
    }

    func record(
        _ record: HealthKitUIAccessRequestRecord,
        completion: @escaping (Result<Bool, any Error>) -> Void
    ) {
        lock.lock()
        storedRecords.append(record)
        completions.append(completion)
        lock.unlock()
    }

    func failClosed() -> Int {
        lock.lock()
        let pending = completions
        completions = []
        storedRecords = []
        lock.unlock()
        let error = HealthKitUIUnavailable.linuxHost(
            operation: "View.healthDataAccessRequest"
        )
        for completion in pending {
            completion(.failure(error))
        }
        return pending.count
    }

    func reset() {
        lock.lock()
        storedRecords = []
        completions = []
        lock.unlock()
    }
}

#if canImport(HealthKit)

private final class HealthKitUIPresenterBox {
    static let lock = NSLock()
    static var map: [ObjectIdentifier: WeakPresenter] = [:]
}

private struct WeakPresenter {
    weak var value: UIViewController?
}

extension HKHealthStore {
    /// A view controller used to present HealthKit's authorization sheet.
    ///
    /// Darwin uses this as the presenter for the system prompt. Linux stores
    /// a weak reference and never presents a sheet.
    ///
    /// https://developer.apple.com/documentation/healthkit/hkhealthstore/authorizationviewcontrollerpresenter
    public weak var authorizationViewControllerPresenter: UIViewController? {
        get {
            HealthKitUIPresenterBox.lock.lock()
            defer { HealthKitUIPresenterBox.lock.unlock() }
            let key = ObjectIdentifier(self)
            if let presenter = HealthKitUIPresenterBox.map[key]?.value {
                return presenter
            }
            HealthKitUIPresenterBox.map[key] = nil
            return nil
        }
        set {
            HealthKitUIPresenterBox.lock.lock()
            defer { HealthKitUIPresenterBox.lock.unlock() }
            let key = ObjectIdentifier(self)
            if let presenter = newValue {
                HealthKitUIPresenterBox.map[key] = WeakPresenter(value: presenter)
            } else {
                HealthKitUIPresenterBox.map[key] = nil
            }
        }
    }
}

#endif

extension View {
    /// Requests permission to save and read the specified HealthKit data types.
    ///
    /// Darwin shows the authorization sheet when `trigger` changes. Linux
    /// records the request, returns `self`, and does not invoke `completion`
    /// until `HealthKitUIHostControl.failClosedPendingAccessRequests()`.
    @preconcurrency
    nonisolated public func healthDataAccessRequest(
        store: HKHealthStore,
        shareTypes: Set<HKSampleType>,
        readTypes: Set<HKObjectType>? = nil,
        trigger: some Equatable,
        completion: @escaping (Result<Bool, any Error>) -> Void
    ) -> some View {
        _ = store
        _ = trigger
        HealthKitUIAccessRequestRegistry.shared.record(
            HealthKitUIAccessRequestRecord(
                kind: .shareAndRead,
                shareCount: shareTypes.count,
                readCount: readTypes?.count ?? 0,
                objectTypeIdentifier: nil,
                hasPredicate: false
            ),
            completion: completion
        )
        return self
    }

    /// Requests permission to read the specified HealthKit data types.
    @preconcurrency
    nonisolated public func healthDataAccessRequest(
        store: HKHealthStore,
        readTypes: Set<HKObjectType>,
        trigger: some Equatable,
        completion: @escaping (Result<Bool, any Error>) -> Void
    ) -> some View {
        _ = store
        _ = trigger
        HealthKitUIAccessRequestRegistry.shared.record(
            HealthKitUIAccessRequestRecord(
                kind: .readOnly,
                shareCount: 0,
                readCount: readTypes.count,
                objectTypeIdentifier: nil,
                hasPredicate: false
            ),
            completion: completion
        )
        return self
    }

    /// Asynchronously requests permission to read a data type that requires
    /// per-object authorization (such as vision prescriptions).
    @preconcurrency
    nonisolated public func healthDataAccessRequest(
        store: HKHealthStore,
        objectType: HKObjectType,
        predicate: NSPredicate? = nil,
        trigger: some Equatable,
        completion: @escaping (Result<Bool, any Error>) -> Void
    ) -> some View {
        _ = store
        _ = trigger
        HealthKitUIAccessRequestRegistry.shared.record(
            HealthKitUIAccessRequestRecord(
                kind: .perObject,
                shareCount: 0,
                readCount: 0,
                objectTypeIdentifier: objectType.identifier,
                hasPredicate: predicate != nil
            ),
            completion: completion
        )
        return self
    }
}

extension UIScene.ConnectionOptions {
    /// Whether this scene connection should recover an active workout session.
    ///
    /// Darwin inspects connection-option payload. Linux has no workout-session
    /// daemon and no documented payload key, so this is always `false`.
    public var shouldHandleActiveWorkoutRecovery: Bool {
        false
    }
}
