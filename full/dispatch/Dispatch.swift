import OpenCombine
import Synchronization

private typealias _OpenDispatchCallback = @convention(c) (UnsafeMutableRawPointer?) -> Void

@_silgen_name("openui_dispatch_v1_get_global_queue")
private func _openuiDispatchGetGlobalQueue(
    _ identifier: Int64,
    _ flags: UInt64
) -> UnsafeMutableRawPointer?

@_silgen_name("openui_dispatch_v1_async")
private func _openuiDispatchAsync(
    _ queueKind: UInt32,
    _ queue: UnsafeMutableRawPointer?,
    _ context: UnsafeMutableRawPointer?,
    _ callback: _OpenDispatchCallback
)

@_silgen_name("openui_dispatch_v1_after")
private func _openuiDispatchAfter(
    _ queueKind: UInt32,
    _ queue: UnsafeMutableRawPointer?,
    _ delayNanoseconds: UInt64,
    _ context: UnsafeMutableRawPointer?,
    _ callback: _OpenDispatchCallback
)

@_silgen_name("openui_dispatch_v1_monotonic_nanoseconds")
private func _openuiDispatchMonotonicNanoseconds() -> UInt64

private let _openuiDispatchMainQueueKind: UInt32 = 1
private let _openuiDispatchGlobalQueueKind: UInt32 = 2

public enum DispatchTimeInterval: Sendable, Hashable {
    case seconds(Int)
    case milliseconds(Int)
    case microseconds(Int)
    case nanoseconds(Int)
    case never

    fileprivate var nanoseconds: Int64 {
        func product(_ value: Int, _ scale: Int64) -> Int64 {
            let converted = Int64(clamping: value)
            let result = converted.multipliedReportingOverflow(by: scale)
            if !result.overflow { return result.partialValue }
            return converted < 0 ? .min : .max
        }
        switch self {
        case .seconds(let value): return product(value, 1_000_000_000)
        case .milliseconds(let value): return product(value, 1_000_000)
        case .microseconds(let value): return product(value, 1_000)
        case .nanoseconds(let value): return Int64(clamping: value)
        case .never: return .max
        }
    }
}

public struct DispatchTime: RawRepresentable, Sendable, Hashable, Codable {
    public let rawValue: UInt64
    public var uptimeNanoseconds: UInt64 { rawValue }

    public init(rawValue: UInt64) { self.rawValue = rawValue }
    public init(uptimeNanoseconds: UInt64) { rawValue = uptimeNanoseconds }

    public static func now() -> DispatchTime {
        DispatchTime(rawValue: _openuiDispatchMonotonicNanoseconds())
    }

    public static let distantFuture = DispatchTime(rawValue: .max)
}

public func + (time: DispatchTime, interval: DispatchTimeInterval) -> DispatchTime {
    let delta = interval.nanoseconds
    if delta >= 0 {
        let result = time.rawValue.addingReportingOverflow(UInt64(delta))
        return DispatchTime(rawValue: result.overflow ? .max : result.partialValue)
    }
    let magnitude = delta == .min ? UInt64(Int64.max) + 1 : UInt64(-delta)
    return DispatchTime(rawValue: magnitude > time.rawValue ? 0 : time.rawValue - magnitude)
}

public func + (time: DispatchTime, seconds: Double) -> DispatchTime {
    guard seconds.isFinite else { return seconds.sign == .minus ? .init(rawValue: 0) : .distantFuture }
    let scaled = seconds * 1_000_000_000
    if scaled >= Double(Int64.max) { return .distantFuture }
    if scaled <= Double(Int64.min) { return .init(rawValue: 0) }
    return time + .nanoseconds(Int(scaled))
}

public struct DispatchQoS: Sendable, Hashable {
    public enum QoSClass: UInt32, Sendable, Hashable {
        case background = 0x09
        case utility = 0x11
        case `default` = 0x15
        case userInitiated = 0x19
        case userInteractive = 0x21
        case unspecified = 0x00
    }

    public let qosClass: QoSClass
    public let relativePriority: Int

    public init(qosClass: QoSClass, relativePriority: Int = 0) {
        self.qosClass = qosClass
        self.relativePriority = relativePriority
    }

    public static let background = DispatchQoS(qosClass: .background)
    public static let utility = DispatchQoS(qosClass: .utility)
    public static let `default` = DispatchQoS(qosClass: .default)
    public static let userInitiated = DispatchQoS(qosClass: .userInitiated)
    public static let userInteractive = DispatchQoS(qosClass: .userInteractive)
    public static let unspecified = DispatchQoS(qosClass: .unspecified)
}

public struct DispatchWorkItemFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let barrier = Self(rawValue: 1 << 0)
    public static let detached = Self(rawValue: 1 << 1)
    public static let assignCurrentContext = Self(rawValue: 1 << 2)
    public static let noQoS = Self(rawValue: 1 << 3)
    public static let inheritQoS = Self(rawValue: 1 << 4)
    public static let enforceQoS = Self(rawValue: 1 << 5)
}

private final class _OpenDispatchClosure: @unchecked Sendable {
    let body: @Sendable () -> Void
    init(_ body: @escaping @Sendable () -> Void) { self.body = body }
}

@_cdecl("openui_dispatch_swift_invoke_v1")
private func _openuiDispatchSwiftInvoke(_ context: UnsafeMutableRawPointer?) {
    guard let context else { fatalError("Dispatch callback lost its retained context") }
    Unmanaged<_OpenDispatchClosure>.fromOpaque(context).takeRetainedValue().body()
}

public final class DispatchQueue: @unchecked Sendable {
    private let queueKind: UInt32
    private let opaqueQueue: UnsafeMutableRawPointer?

    private init(queueKind: UInt32, opaqueQueue: UnsafeMutableRawPointer?) {
        self.queueKind = queueKind
        self.opaqueQueue = opaqueQueue
    }

    public static let main = DispatchQueue(
        queueKind: _openuiDispatchMainQueueKind,
        opaqueQueue: nil
    )

    public static func global(qos: DispatchQoS.QoSClass = .default) -> DispatchQueue {
        var queue = _openuiDispatchGetGlobalQueue(Int64(qos.rawValue), 4)
        if queue == nil {
            queue = _openuiDispatchGetGlobalQueue(Int64(qos.rawValue), 0)
        }
        guard let queue else {
            fatalError("Linux libdispatch refused a global queue for QoS \(qos.rawValue)")
        }
        return DispatchQueue(
            queueKind: _openuiDispatchGlobalQueueKind,
            opaqueQueue: queue
        )
    }

    public func async(execute work: @escaping @Sendable () -> Void) {
        let context = Unmanaged.passRetained(_OpenDispatchClosure(work)).toOpaque()
        _openuiDispatchAsync(
            queueKind,
            opaqueQueue,
            context,
            _openuiDispatchSwiftInvoke
        )
    }

    public func asyncAfter(
        deadline: DispatchTime,
        execute work: @escaping @Sendable () -> Void
    ) {
        let now = _openuiDispatchMonotonicNanoseconds()
        let delay = deadline.rawValue > now ? deadline.rawValue - now : 0
        let context = Unmanaged.passRetained(_OpenDispatchClosure(work)).toOpaque()
        _openuiDispatchAfter(
            queueKind,
            opaqueQueue,
            delay,
            context,
            _openuiDispatchSwiftInvoke
        )
    }
}

// MARK: - OpenCombine scheduler identity

extension DispatchQueue: OpenCombine.Scheduler {
    public struct SchedulerTimeType: Strideable, Hashable, Sendable {
        public var dispatchTime: DispatchTime

        public init(_ dispatchTime: DispatchTime) {
            self.dispatchTime = dispatchTime
        }

        public func distance(to other: SchedulerTimeType) -> Stride {
            let start = dispatchTime.uptimeNanoseconds
            let end = other.dispatchTime.uptimeNanoseconds
            if end >= start {
                return Stride(nanoseconds: _openDispatchClampedSigned(end - start))
            }
            let distance = start - end
            if distance >= UInt64(Int64.max) + 1 {
                return Stride(nanoseconds: .min)
            }
            return Stride(nanoseconds: -Int64(distance))
        }

        public func advanced(by stride: Stride) -> SchedulerTimeType {
            let current = dispatchTime.uptimeNanoseconds
            if stride.nanoseconds >= 0 {
                let delta = UInt64(stride.nanoseconds)
                let result = current.addingReportingOverflow(delta)
                return .init(
                    DispatchTime(
                        uptimeNanoseconds: result.overflow
                            ? .max
                            : result.partialValue
                    )
                )
            }
            let delta = stride.nanoseconds == .min
                ? UInt64(Int64.max) + 1
                : UInt64(-stride.nanoseconds)
            return .init(
                DispatchTime(
                    uptimeNanoseconds: delta > current ? 0 : current - delta
                )
            )
        }

        public struct Stride:
            OpenCombine.SchedulerTimeIntervalConvertible,
            Comparable,
            SignedNumeric,
            Hashable,
            Sendable {
            public typealias IntegerLiteralType = Int
            public typealias Magnitude = UInt64

            fileprivate var nanoseconds: Int64

            fileprivate init(nanoseconds: Int64) {
                self.nanoseconds = nanoseconds
            }

            public init(integerLiteral value: Int) {
                self = .seconds(value)
            }

            public init?<Source: BinaryInteger>(exactly source: Source) {
                guard let seconds = Int64(exactly: source) else { return nil }
                self.init(
                    nanoseconds: _openDispatchClampedProduct(
                        seconds,
                        1_000_000_000
                    )
                )
            }

            public var magnitude: UInt64 {
                nanoseconds == .min
                    ? UInt64(Int64.max) + 1
                    : UInt64(Swift.abs(nanoseconds))
            }

            public static prefix func - (operand: Stride) -> Stride {
                operand.nanoseconds == .min
                    ? Stride(nanoseconds: .max)
                    : Stride(nanoseconds: -operand.nanoseconds)
            }

            public static func + (lhs: Stride, rhs: Stride) -> Stride {
                .init(
                    nanoseconds: _openDispatchClampedAdd(
                        lhs.nanoseconds,
                        rhs.nanoseconds
                    )
                )
            }

            public static func - (lhs: Stride, rhs: Stride) -> Stride {
                lhs + (-rhs)
            }

            public static func * (lhs: Stride, rhs: Stride) -> Stride {
                .init(
                    nanoseconds: _openDispatchClampedProduct(
                        lhs.nanoseconds,
                        rhs.nanoseconds
                    )
                )
            }

            public static func += (lhs: inout Stride, rhs: Stride) {
                lhs = lhs + rhs
            }

            public static func -= (lhs: inout Stride, rhs: Stride) {
                lhs = lhs - rhs
            }

            public static func *= (lhs: inout Stride, rhs: Stride) {
                lhs = lhs * rhs
            }

            public static func < (lhs: Stride, rhs: Stride) -> Bool {
                lhs.nanoseconds < rhs.nanoseconds
            }

            public static func seconds(_ value: Int) -> Stride {
                .init(
                    nanoseconds: _openDispatchClampedProduct(
                        Int64(clamping: value),
                        1_000_000_000
                    )
                )
            }

            public static func seconds(_ value: Double) -> Stride {
                guard value.isFinite else {
                    return .init(nanoseconds: value.sign == .minus ? .min : .max)
                }
                let nanoseconds = value * 1_000_000_000
                if nanoseconds >= Double(Int64.max) {
                    return .init(nanoseconds: .max)
                }
                if nanoseconds <= Double(Int64.min) {
                    return .init(nanoseconds: .min)
                }
                return .init(nanoseconds: Int64(nanoseconds))
            }

            public static func milliseconds(_ value: Int) -> Stride {
                .init(
                    nanoseconds: _openDispatchClampedProduct(
                        Int64(clamping: value),
                        1_000_000
                    )
                )
            }

            public static func microseconds(_ value: Int) -> Stride {
                .init(
                    nanoseconds: _openDispatchClampedProduct(
                        Int64(clamping: value),
                        1_000
                    )
                )
            }

            public static func nanoseconds(_ value: Int) -> Stride {
                .init(nanoseconds: Int64(clamping: value))
            }
        }
    }

    public struct SchedulerOptions: Sendable, Hashable {
        public var qos: DispatchQoS
        public var flags: DispatchWorkItemFlags

        public init(
            qos: DispatchQoS = .unspecified,
            flags: DispatchWorkItemFlags = []
        ) {
            self.qos = qos
            self.flags = flags
        }
    }

    public var now: SchedulerTimeType { .init(.now()) }
    public var minimumTolerance: SchedulerTimeType.Stride { .nanoseconds(0) }

    public func schedule(
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) {
        _ = options
        let action = _OpenDispatchSchedulerAction(action)
        async { action.invoke() }
    }

    public func schedule(
        after date: SchedulerTimeType,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) {
        _ = tolerance
        _ = options
        let action = _OpenDispatchSchedulerAction(action)
        asyncAfter(deadline: date.dispatchTime) { action.invoke() }
    }

    public func schedule(
        after date: SchedulerTimeType,
        interval: SchedulerTimeType.Stride,
        tolerance: SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) -> any OpenCombine.Cancellable {
        _ = tolerance
        _ = options
        let schedule = _OpenDispatchRepeatingSchedule(
            queue: self,
            intervalNanoseconds: max(1, interval.nanoseconds),
            action: action
        )
        schedule.start(at: date.dispatchTime)
        return schedule
    }
}

private final class _OpenDispatchSchedulerAction: @unchecked Sendable {
    private let body: () -> Void

    init(_ body: @escaping () -> Void) {
        self.body = body
    }

    func invoke() { body() }
}

private final class _OpenDispatchRepeatingSchedule:
    OpenCombine.Cancellable,
    @unchecked Sendable {
    private let queue: DispatchQueue
    private let intervalNanoseconds: Int64
    private let action: _OpenDispatchSchedulerAction
    private let cancelled = Mutex<Bool>(false)

    init(
        queue: DispatchQueue,
        intervalNanoseconds: Int64,
        action: @escaping () -> Void
    ) {
        self.queue = queue
        self.intervalNanoseconds = intervalNanoseconds
        self.action = _OpenDispatchSchedulerAction(action)
    }

    func start(at date: DispatchTime) {
        queue.asyncAfter(deadline: date) { [self] in fire() }
    }

    func cancel() {
        cancelled.withLock { $0 = true }
    }

    private func fire() {
        guard !cancelled.withLock({ $0 }) else { return }
        action.invoke()
        guard !cancelled.withLock({ $0 }) else { return }
        queue.asyncAfter(
            deadline: .now() + .nanoseconds(Int(clamping: intervalNanoseconds))
        ) { [self] in
            fire()
        }
    }
}

private func _openDispatchClampedSigned(_ value: UInt64) -> Int64 {
    value > UInt64(Int64.max) ? .max : Int64(value)
}

private func _openDispatchClampedAdd(_ lhs: Int64, _ rhs: Int64) -> Int64 {
    let result = lhs.addingReportingOverflow(rhs)
    guard result.overflow else { return result.partialValue }
    return lhs >= 0 && rhs >= 0 ? .max : .min
}

private func _openDispatchClampedProduct(_ lhs: Int64, _ rhs: Int64) -> Int64 {
    let result = lhs.multipliedReportingOverflow(by: rhs)
    guard result.overflow else { return result.partialValue }
    return (lhs < 0) == (rhs < 0) ? .max : .min
}
