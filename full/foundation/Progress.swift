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

private struct _PortableKVOValue: @unchecked Sendable {
    let value: Any

    init<Value>(_ value: Value) {
        self.value = value as Any
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
    private let handler: (
        AnyObject, _PortableKVOValue?, _PortableKVOValue?, Bool
    ) -> Void
    private let invalidation: @Sendable () -> Void
    private let invalidated = Mutex(false)
    fileprivate weak var owner: AnyObject?

    fileprivate init<Object: AnyObject, Value>(
        identifier: UInt64,
        owner: Object,
        keyPath: KeyPath<Object, Value>,
        options: NSKeyValueObservingOptions,
        invalidation: @escaping @Sendable () -> Void,
        handler: @escaping (
            Object, NSKeyValueObservedChange<Value>
        ) -> Void
    ) {
        self.identifier = identifier
        self.owner = owner
        self.keyPath = keyPath
        self.options = options
        self.invalidation = invalidation
        self.handler = { object, old, new, isPrior in
            guard let object = object as? Object else { return }
            handler(
                object,
                NSKeyValueObservedChange(
                    newValue: !isPrior && options.contains(.new)
                        ? new.map { $0.value as! Value } : nil,
                    oldValue: options.contains(.old)
                        ? old.map { $0.value as! Value } : nil,
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
        invalidation()
        owner = nil
    }

    fileprivate func deliver(
        object: AnyObject,
        old: _PortableKVOValue?,
        new: _PortableKVOValue?,
        isPrior: Bool
    ) {
        guard !invalidated.withLock({ $0 }) else { return }
        if isPrior && !options.contains(.prior) { return }
        handler(object, old, new, isPrior)
    }

    deinit { invalidate() }
}

#if !FOUNDATION_PROGRESS_HOST
/// Process-local typed observation storage for portable Objective-C objects.
///
/// Linux-built Mach-O code has no Objective-C KVO runtime. The facade keeps
/// the public typed-Foundation contract while requiring framework owners to
/// bracket real mutations explicitly. Tokens are held weakly, as on Darwin:
/// dropping or invalidating the token immediately stops delivery.
private final class _PortableKVORegistry: @unchecked Sendable {
    private struct State {
        var nextIdentifier: UInt64 = 1
        var observations: [
            ObjectIdentifier: [UInt64: _WeakProgressObservation]
        ] = [:]
    }

    static let shared = _PortableKVORegistry()
    private let state = Mutex(State())

    func observe<Object: NSObject, Value>(
        object: Object,
        keyPath: KeyPath<Object, Value>,
        options: NSKeyValueObservingOptions,
        handler: @escaping @Sendable (
            Object, NSKeyValueObservedChange<Value>
        ) -> Void
    ) -> NSKeyValueObservation {
        let objectIdentifier = ObjectIdentifier(object)
        let identifier = state.withLock { state in
            let identifier = state.nextIdentifier
            state.nextIdentifier &+= 1
            return identifier
        }
        let observation = NSKeyValueObservation(
            identifier: identifier,
            owner: object,
            keyPath: keyPath,
            options: options,
            invalidation: { [objectIdentifier] in
                Self.shared.remove(
                    objectIdentifier: objectIdentifier,
                    identifier: identifier
                )
            },
            handler: handler
        )
        state.withLock { state in
            state.observations[objectIdentifier, default: [:]][identifier] =
                _WeakProgressObservation(observation)
        }
        if options.contains(.initial) {
            observation.deliver(
                object: object,
                old: nil,
                new: _PortableKVOValue(object[keyPath: keyPath]),
                isPrior: false
            )
        }
        return observation
    }

    func deliver<Object: NSObject, Value>(
        object: Object,
        keyPath: KeyPath<Object, Value>,
        oldValue: Value,
        newValue: Value,
        isPrior: Bool
    ) {
        let objectIdentifier = ObjectIdentifier(object)
        let retained = state.withLock { state -> [NSKeyValueObservation] in
            guard let values = state.observations[objectIdentifier] else {
                return []
            }
            var live: [UInt64: _WeakProgressObservation] = [:]
            var matching: [NSKeyValueObservation] = []
            for (identifier, weakValue) in values {
                guard let observation = weakValue.value else { continue }
                guard observation.owner === object else { continue }
                live[identifier] = weakValue
                if observation.keyPath == keyPath {
                    matching.append(observation)
                }
            }
            if live.isEmpty {
                state.observations.removeValue(forKey: objectIdentifier)
            } else {
                state.observations[objectIdentifier] = live
            }
            matching.sort { $0.identifier < $1.identifier }
            return matching
        }
        let old = _PortableKVOValue(oldValue)
        let new = _PortableKVOValue(newValue)
        for observation in retained {
            observation.deliver(
                object: object, old: old, new: new, isPrior: isPrior
            )
        }
    }

    private func remove(
        objectIdentifier: ObjectIdentifier, identifier: UInt64
    ) {
        state.withLock { state in
            state.observations[objectIdentifier]?.removeValue(
                forKey: identifier
            )
            if state.observations[objectIdentifier]?.isEmpty == true {
                state.observations.removeValue(forKey: objectIdentifier)
            }
        }
    }
}

/// Foundation's typed-observation capability. A protocol extension is used so
/// `Self` retains the concrete subclass in key paths and callbacks, matching
/// the native Foundation declaration rather than erasing to `NSObject`.
public protocol _KeyValueCodingAndObserving: AnyObject {}

extension NSObject: _KeyValueCodingAndObserving {}

public extension _KeyValueCodingAndObserving where Self: NSObject {
    /// Creates a lifetime-bound typed observation of a portable Objective-C
    /// object. Framework implementations must emit the matching explicit
    /// mutation brackets below because automatic Objective-C KVO is absent.
    @preconcurrency
    func observe<Value>(
        _ keyPath: KeyPath<Self, Value>,
        options: NSKeyValueObservingOptions = [],
        changeHandler: @escaping @Sendable (
            Self, NSKeyValueObservedChange<Value>
        ) -> Void
    ) -> NSKeyValueObservation {
        _PortableKVORegistry.shared.observe(
            object: self,
            keyPath: keyPath,
            options: options,
            handler: changeHandler
        )
    }

    /// Delivers `.prior` observations immediately before a real mutation.
    func _portableWillChangeValue<Value>(
        for keyPath: KeyPath<Self, Value>, oldValue: Value
    ) {
        _PortableKVORegistry.shared.deliver(
            object: self,
            keyPath: keyPath,
            oldValue: oldValue,
            newValue: oldValue,
            isPrior: true
        )
    }

    /// Delivers the post-mutation observation with requested old/new values.
    func _portableDidChangeValue<Value>(
        for keyPath: KeyPath<Self, Value>,
        oldValue: Value,
        newValue: Value
    ) {
        _PortableKVORegistry.shared.deliver(
            object: self,
            keyPath: keyPath,
            oldValue: oldValue,
            newValue: newValue,
            isPrior: false
        )
    }
}
#endif

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
                invalidation: { [weak self] in
                    self?._removeObservation(identifier)
                },
                handler: changeHandler
            )
            state.observations[identifier] = _WeakProgressObservation(observation)
            return observation
        }
        if options.contains(.initial) {
            let value = self[keyPath: keyPath]
            observation.deliver(
                object: self,
                old: nil,
                new: _PortableKVOValue(value),
                isPrior: false
            )
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
                    object: self,
                    old: _PortableKVOValue(oldValue),
                    new: _PortableKVOValue(newValue),
                    isPrior: prior
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

#if !FOUNDATION_PROGRESS_HOST
extension UIDropSession {
    /// Guest-only overlay for OpenUIKit's Foundation-hidden library boundary.
    /// MEASURED verify88 x86 rungs b/c: BrowserViewController.swift:1193 could
    /// not call loadObjects through any UIDropSession. Payload extraction lives
    /// in OpenUIKit; Progress retains its canonical Foundation identity here.
    @discardableResult
    public func loadObjects<T>(ofClass type: T.Type,
                               completion: @escaping ([T]) -> Void) -> Progress {
        let objects = _openUIKitLoadObjects(ofClass: type)
        let progress = Progress(totalUnitCount: Int64(objects.count))
        completion(objects)
        progress.completedUnitCount = progress.totalUnitCount
        return progress
    }
}
#endif
