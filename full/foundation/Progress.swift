// Progress reporting and typed key-value observation for the portable
// Foundation facade. This is a project-owned implementation of the public
// contract; it does not depend on automatic Objective-C KVO, which is absent
// from Linux-built Mach-O code.

#if FOUNDATION_PROGRESS_HOST
import Foundation
public typealias IndexSet = Foundation.IndexSet
#else
import FoundationEssentials
import ObjectiveC
import OpenUIKit
public typealias IndexSet = OpenUIKit.IndexSet
#endif
import Synchronization

public struct NSKeyValueObservingOptions: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let new = Self(rawValue: 1 << 0)
    public static let old = Self(rawValue: 1 << 1)
    public static let initial = Self(rawValue: 1 << 2)
    public static let prior = Self(rawValue: 1 << 3)
}

public enum NSKeyValueChange: UInt, Sendable {
    case setting = 1
    case insertion = 2
    case removal = 3
    case replacement = 4
}

public struct NSKeyValueObservedChange<Value>: @unchecked Sendable {
    public let kind: NSKeyValueChange
    public let newValue: Value?
    public let oldValue: Value?
    public let indexes: IndexSet?
    public let isPrior: Bool

    fileprivate init(
        newValue: Value?, oldValue: Value?, isPrior: Bool
    ) {
        kind = .setting
        self.newValue = newValue
        self.oldValue = oldValue
        indexes = nil
        self.isPrior = isPrior
    }
}

private final class _WeakProgressObservation: @unchecked Sendable {
    weak var value: NSKeyValueObservation?
    init(_ value: NSKeyValueObservation) { self.value = value }
}

public final class NSKeyValueObservation: NSObject, @unchecked Sendable {
    fileprivate let identifier: UInt64
    fileprivate let keyPath: AnyKeyPath
    fileprivate let options: NSKeyValueObservingOptions
    private let handler: (Progress, Any?, Any?, Bool) -> Void
    private let invalidated = Mutex(false)
    fileprivate weak var owner: Progress?

    fileprivate init<Value>(
        identifier: UInt64,
        owner: Progress,
        keyPath: KeyPath<Progress, Value>,
        options: NSKeyValueObservingOptions,
        handler: @escaping (
            Progress, NSKeyValueObservedChange<Value>
        ) -> Void
    ) {
        self.identifier = identifier
        self.owner = owner
        self.keyPath = keyPath
        self.options = options
        self.handler = { object, old, new, isPrior in
            handler(
                object,
                NSKeyValueObservedChange(
                    newValue: !isPrior && options.contains(.new)
                        ? new as? Value : nil,
                    oldValue: options.contains(.old) ? old as? Value : nil,
                    isPrior: isPrior
                )
            )
        }
        super.init()
    }

    public func invalidate() {
        let shouldDetach = invalidated.withLock { state in
            guard !state else { return false }
            state = true
            return true
        }
        guard shouldDetach else { return }
        owner?._removeObservation(identifier)
        owner = nil
    }

    fileprivate func deliver(
        object: Progress, old: Any?, new: Any?, isPrior: Bool
    ) {
        guard !invalidated.withLock({ $0 }) else { return }
        if isPrior && !options.contains(.prior) { return }
        handler(object, old, new, isPrior)
    }

    deinit { invalidate() }
}

open class Progress: NSObject, @unchecked Sendable {
    private struct State {
        var totalUnitCount: Int64
        var completedUnitCount: Int64 = 0
        var isCancelled = false
        var isPaused = false
        var isCancellable = true
        var isPausable = false
        var nextObservationIdentifier: UInt64 = 1
        var observations: [UInt64: _WeakProgressObservation] = [:]
    }

    private struct Snapshot {
        let totalUnitCount: Int64
        let completedUnitCount: Int64
        let fractionCompleted: Double
        let isIndeterminate: Bool
        let isFinished: Bool
        let isCancelled: Bool
        let isPaused: Bool
        let isCancellable: Bool
        let isPausable: Bool
    }

    private let state: Mutex<State>

    public init(totalUnitCount unitCount: Int64) {
        state = Mutex(State(totalUnitCount: unitCount))
        super.init()
    }

    open var totalUnitCount: Int64 {
        get { state.withLock { $0.totalUnitCount } }
        set { _mutate { $0.totalUnitCount = newValue } }
    }
    open var completedUnitCount: Int64 {
        get { state.withLock { $0.completedUnitCount } }
        set { _mutate { $0.completedUnitCount = newValue } }
    }
    open var fractionCompleted: Double {
        state.withLock { Self._fractionCompleted($0) }
    }
    open var isIndeterminate: Bool {
        state.withLock { Self._isIndeterminate($0) }
    }
    open var isFinished: Bool { state.withLock { Self._isFinished($0) } }
    open var isCancelled: Bool { state.withLock { $0.isCancelled } }
    open var isPaused: Bool { state.withLock { $0.isPaused } }
    open var isCancellable: Bool {
        get { state.withLock { $0.isCancellable } }
        set { _mutate { $0.isCancellable = newValue } }
    }
    open var isPausable: Bool {
        get { state.withLock { $0.isPausable } }
        set { _mutate { $0.isPausable = newValue } }
    }

    open func cancel() { _mutate { $0.isCancelled = true } }
    open func pause() { _mutate { $0.isPaused = true } }
    open func resume() { _mutate { $0.isPaused = false } }

    open func observe<Value>(
        _ keyPath: KeyPath<Progress, Value>,
        options: NSKeyValueObservingOptions = [],
        changeHandler: @escaping (
            Progress, NSKeyValueObservedChange<Value>
        ) -> Void
    ) -> NSKeyValueObservation {
        let observation = state.withLock { state -> NSKeyValueObservation in
            let identifier = state.nextObservationIdentifier
            state.nextObservationIdentifier &+= 1
            let observation = NSKeyValueObservation(
                identifier: identifier,
                owner: self,
                keyPath: keyPath,
                options: options,
                handler: changeHandler
            )
            state.observations[identifier] = _WeakProgressObservation(observation)
            return observation
        }
        if options.contains(.initial) {
            let value = self[keyPath: keyPath]
            observation.deliver(object: self, old: nil, new: value, isPrior: false)
        }
        return observation
    }

    fileprivate func _removeObservation(_ identifier: UInt64) {
        _ = state.withLock { state in
            state.observations.removeValue(forKey: identifier)
        }
    }

    private func _mutate(_ body: (inout State) -> Void) {
        let delivery: (Snapshot, Snapshot, [NSKeyValueObservation]) =
            state.withLock { state in
                let old = Self._snapshot(state)
                body(&state)
                let new = Self._snapshot(state)
                var retained: [NSKeyValueObservation] = []
                state.observations = state.observations.filter { _, weakValue in
                    guard let value = weakValue.value else { return false }
                    retained.append(value)
                    return true
                }
                return (old, new, retained)
            }
        _deliver(delivery.2, old: delivery.0, new: delivery.1, prior: true)
        _deliver(delivery.2, old: delivery.0, new: delivery.1, prior: false)
    }

    private func _deliver(
        _ observations: [NSKeyValueObservation],
        old: Snapshot,
        new: Snapshot,
        prior: Bool
    ) {
        func changed<Value: Equatable>(
            _ keyPath: KeyPath<Progress, Value>, _ oldValue: Value, _ newValue: Value
        ) {
            guard oldValue != newValue else { return }
            for observation in observations where observation.keyPath == keyPath {
                observation.deliver(
                    object: self, old: oldValue, new: newValue, isPrior: prior
                )
            }
        }

        changed(\Progress.totalUnitCount, old.totalUnitCount, new.totalUnitCount)
        changed(\Progress.completedUnitCount, old.completedUnitCount, new.completedUnitCount)
        changed(\Progress.fractionCompleted, old.fractionCompleted, new.fractionCompleted)
        changed(\Progress.isIndeterminate, old.isIndeterminate, new.isIndeterminate)
        changed(\Progress.isFinished, old.isFinished, new.isFinished)
        changed(\Progress.isCancelled, old.isCancelled, new.isCancelled)
        changed(\Progress.isPaused, old.isPaused, new.isPaused)
        changed(\Progress.isCancellable, old.isCancellable, new.isCancellable)
        changed(\Progress.isPausable, old.isPausable, new.isPausable)
    }

    private static func _snapshot(_ state: State) -> Snapshot {
        Snapshot(
            totalUnitCount: state.totalUnitCount,
            completedUnitCount: state.completedUnitCount,
            fractionCompleted: _fractionCompleted(state),
            isIndeterminate: _isIndeterminate(state),
            isFinished: _isFinished(state),
            isCancelled: state.isCancelled,
            isPaused: state.isPaused,
            isCancellable: state.isCancellable,
            isPausable: state.isPausable
        )
    }

    private static func _isIndeterminate(_ state: State) -> Bool {
        state.totalUnitCount < 0 || state.completedUnitCount < 0 ||
            (state.totalUnitCount == 0 && state.completedUnitCount == 0)
    }
    private static func _fractionCompleted(_ state: State) -> Double {
        guard state.totalUnitCount >= 0, state.completedUnitCount > 0 else { return 0 }
        guard state.totalUnitCount > 0 else { return 1 }
        return Double(state.completedUnitCount) / Double(state.totalUnitCount)
    }
    private static func _isFinished(_ state: State) -> Bool {
        !_isIndeterminate(state) && state.completedUnitCount >= state.totalUnitCount
    }
}
