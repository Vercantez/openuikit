import CoreFoundation
import Foundation

public struct CMBufferCallbacks {
    public var version: UInt32
    public var refcon: UnsafeMutableRawPointer?
    public var getDecodeTimeStamp: CMBufferGetTimeCallback?
    public var getPresentationTimeStamp: CMBufferGetTimeCallback?
    public var getDuration: CMBufferGetTimeCallback
    public var isDataReady: CMBufferGetBooleanCallback?
    public var compare: CMBufferCompareCallback?
    public var dataBecameReadyNotification: Unmanaged<CFString>?
    public var getSize: CMBufferGetSizeCallback?

    public init(
        version: UInt32,
        refcon: UnsafeMutableRawPointer?,
        getDecodeTimeStamp: CMBufferGetTimeCallback?,
        getPresentationTimeStamp: CMBufferGetTimeCallback?,
        getDuration: @escaping CMBufferGetTimeCallback,
        isDataReady: CMBufferGetBooleanCallback?,
        compare: CMBufferCompareCallback?,
        dataBecameReadyNotification: Unmanaged<CFString>?,
        getSize: CMBufferGetSizeCallback?
    ) {
        self.version = version
        self.refcon = refcon
        self.getDecodeTimeStamp = getDecodeTimeStamp
        self.getPresentationTimeStamp = getPresentationTimeStamp
        self.getDuration = getDuration
        self.isDataReady = isDataReady
        self.compare = compare
        self.dataBecameReadyNotification = dataBecameReadyNotification
        self.getSize = getSize
    }
}

public final class CMSimpleQueue: @unchecked Sendable {
    public typealias T = CMSimpleQueue

    public struct Error {
        public static let allocationFailed = cmNSError(code: Int(kCMSimpleQueueError_AllocationFailed))
        public static let requiredParameterMissing = cmNSError(code: Int(kCMSimpleQueueError_RequiredParameterMissing))
        public static let parameterOutOfRange = cmNSError(code: Int(kCMSimpleQueueError_ParameterOutOfRange))
        public static let queueIsFull = cmNSError(code: Int(kCMSimpleQueueError_QueueIsFull))
    }

    private static let processTypeID: CFTypeID = 0x434D_5351
    public static var typeID: CFTypeID { processTypeID }

    private let lock = CMUnfairLock()
    private let maxCapacity: Int
    private var storage: [UnsafeRawPointer] = []

    public init(capacity: Int) throws {
        if capacity < 0 { throw Error.parameterOutOfRange }
        self.maxCapacity = capacity
    }

    public init(referencing object: CMSimpleQueue) {
        self.maxCapacity = object.maxCapacity
        self.storage = object.lock.locked { object.storage }
    }

    public var capacity: Int { maxCapacity }
    public var count: Int { lock.locked { storage.count } }
    public var fullness: Float {
        if maxCapacity == 0 { return 1 }
        return Float(count) / Float(maxCapacity)
    }
    public var head: UnsafeRawPointer? { lock.locked { storage.first } }

    public func enqueue(_ element: UnsafeRawPointer) throws {
        try lock.locked {
            if storage.count >= maxCapacity { throw Error.queueIsFull }
            storage.append(element)
        }
    }

    public func dequeue() -> UnsafeRawPointer? {
        lock.locked {
            guard !storage.isEmpty else { return nil }
            return storage.removeFirst()
        }
    }

    public func reset() throws {
        lock.locked { storage.removeAll() }
    }
}

public func CMSimpleQueueGetTypeID() -> CFTypeID { CMSimpleQueue.typeID }

public func CMSimpleQueueCreate(
    allocator: CFAllocator?,
    capacity: Int32,
    queueOut: UnsafeMutablePointer<CMSimpleQueue?>
) -> OSStatus {
    _ = allocator
    if capacity < 0 {
        queueOut.pointee = nil
        return kCMSimpleQueueError_ParameterOutOfRange
    }
    do {
        queueOut.pointee = try CMSimpleQueue(capacity: Int(capacity))
        return 0
    } catch {
        queueOut.pointee = nil
        return kCMSimpleQueueError_AllocationFailed
    }
}

public func CMSimpleQueueEnqueue(_ queue: CMSimpleQueue, element: UnsafeRawPointer) -> OSStatus {
    do {
        try queue.enqueue(element)
        return 0
    } catch let error as NSError {
        return OSStatus(error.code)
    } catch {
        return kCMSimpleQueueError_QueueIsFull
    }
}

public func CMSimpleQueueDequeue(_ queue: CMSimpleQueue) -> UnsafeRawPointer? {
    queue.dequeue()
}

public func CMSimpleQueueGetHead(_ queue: CMSimpleQueue) -> UnsafeRawPointer? {
    queue.head
}

public func CMSimpleQueueGetCapacity(_ queue: CMSimpleQueue) -> Int32 {
    Int32(queue.capacity)
}

public func CMSimpleQueueGetCount(_ queue: CMSimpleQueue) -> Int32 {
    Int32(queue.count)
}

public func CMSimpleQueueReset(_ queue: CMSimpleQueue) -> OSStatus {
    do {
        try queue.reset()
        return 0
    } catch {
        return kCMSimpleQueueError_RequiredParameterMissing
    }
}

internal final class CMBufferQueueTriggerBox {
    let condition: CMBufferQueueTriggerCondition
    let time: CMTime
    let threshold: CMItemCount
    var callback: CMBufferQueueTriggerCallback?
    var handler: CMBufferQueueTriggerHandler?
    var refcon: UnsafeMutableRawPointer?
    var lastTrue = false

    init(
        condition: CMBufferQueueTriggerCondition,
        time: CMTime,
        threshold: CMItemCount
    ) {
        self.condition = condition
        self.time = time
        self.threshold = threshold
    }

    var token: CMBufferQueueTriggerToken {
        CMBufferQueueTriggerToken(Unmanaged.passUnretained(self).toOpaque())
    }
}

public final class CMBufferQueue: @unchecked Sendable {
    public typealias T = CMBufferQueue
    public typealias TriggerToken = CMBufferQueueTriggerToken

    public struct Error {
        public static let allocationFailed = cmNSError(code: Int(kCMBufferQueueError_AllocationFailed))
        public static let requiredParameterMissing = cmNSError(code: Int(kCMBufferQueueError_RequiredParameterMissing))
        public static let invalidCMBufferCallbacksStruct = cmNSError(
            code: Int(kCMBufferQueueError_InvalidCMBufferCallbacksStruct)
        )
        public static let enqueueAfterEndOfData = cmNSError(code: Int(kCMBufferQueueError_EnqueueAfterEndOfData))
        public static let queueIsFull = cmNSError(code: Int(kCMBufferQueueError_QueueIsFull))
        public static let badTriggerDuration = cmNSError(code: Int(kCMBufferQueueError_BadTriggerDuration))
        public static let cannotModifyQueueFromTriggerCallback = cmNSError(
            code: Int(kCMBufferQueueError_CannotModifyQueueFromTriggerCallback)
        )
        public static let invalidTriggerCondition = cmNSError(code: Int(kCMBufferQueueError_InvalidTriggerCondition))
        public static let invalidTriggerToken = cmNSError(code: Int(kCMBufferQueueError_InvalidTriggerToken))
        public static let invalidBuffer = cmNSError(code: Int(kCMBufferQueueError_InvalidBuffer))
    }

    public enum TriggerCondition: Equatable {
        case whenDurationBecomesLessThan(CMTime)
        case whenDurationBecomesLessThanOrEqualTo(CMTime)
        case whenDurationBecomesGreaterThan(CMTime)
        case whenDurationBecomesGreaterThanOrEqualTo(CMTime)
        case whenMinPresentationTimeStampChanges
        case whenMaxPresentationTimeStampChanges
        case whenDataBecomesReady
        case whenEndOfDataReached
        case whenReset
        case whenBufferCountBecomesLessThan(CMItemCount)
        case whenBufferCountBecomesGreaterThan(CMItemCount)
    }

    public struct Handlers {
        public let getDecodeTimeStamp: CMBufferGetTimeHandler?
        public let getPresentationTimeStamp: CMBufferGetTimeHandler?
        public let getDuration: CMBufferGetTimeHandler
        public let isDataReady: CMBufferGetBooleanHandler?
        public let compare: CMBufferCompareHandler?
        public let dataBecameReadyNotification: String?
        public let getSize: CMBufferGetSizeHandler?

        public struct Builder {
            public var getDecodeTimeStampHandler: CMBufferGetTimeHandler?
            public var getPresentationTimeStampHandler: CMBufferGetTimeHandler?
            public var getDurationHandler: CMBufferGetTimeHandler?
            public var isDataReadyHandler: CMBufferGetBooleanHandler?
            public var compareHandler: CMBufferCompareHandler?
            public var dataBecameReadyNotification: String?
            public var getSizeHandler: CMBufferGetSizeHandler?

            public init() {}

            public mutating func getDuration(_ body: @escaping CMBufferGetTimeHandler) {
                getDurationHandler = body
            }
            public mutating func isDataReady(_ body: @escaping CMBufferGetBooleanHandler) {
                isDataReadyHandler = body
            }
            public mutating func getDecodeTimeStamp(_ body: @escaping CMBufferGetTimeHandler) {
                getDecodeTimeStampHandler = body
            }
            public mutating func getPresentationTimeStamp(_ body: @escaping CMBufferGetTimeHandler) {
                getPresentationTimeStampHandler = body
            }
            public mutating func compare(_ body: @escaping CMBufferCompareHandler) {
                compareHandler = body
            }
            public mutating func getSize(_ body: @escaping CMBufferGetSizeHandler) {
                getSizeHandler = body
            }
        }

        public init(withHandlers body: (inout Builder) -> Void) {
            var builder = Builder()
            body(&builder)
            self.getDecodeTimeStamp = builder.getDecodeTimeStampHandler
            self.getPresentationTimeStamp = builder.getPresentationTimeStampHandler
            self.getDuration = builder.getDurationHandler ?? { _ in .invalid }
            self.isDataReady = builder.isDataReadyHandler
            self.compare = builder.compareHandler
            self.dataBecameReadyNotification = builder.dataBecameReadyNotification
            self.getSize = builder.getSizeHandler
        }

        public func withHandlers(_ body: (inout Builder) -> Void) -> Handlers {
            Handlers(withHandlers: body)
        }

        public static let unsortedSampleBuffers = Handlers(withHandlers: { builder in
            builder.getDuration { ($0 as? CMSampleBuffer)?.duration ?? .invalid }
            builder.getPresentationTimeStamp { ($0 as? CMSampleBuffer)?.presentationTimeStamp ?? .invalid }
            builder.getDecodeTimeStamp { ($0 as? CMSampleBuffer)?.decodeTimeStamp ?? .invalid }
            builder.isDataReady { ($0 as? CMSampleBuffer)?.dataIsReady ?? true }
            builder.getSize { ($0 as? CMSampleBuffer)?.totalSampleSize ?? 0 }
        })

        public static let outputPTSSortedSampleBuffers = Handlers(withHandlers: { builder in
            builder.getDuration { ($0 as? CMSampleBuffer)?.outputDuration ?? .invalid }
            builder.getPresentationTimeStamp { ($0 as? CMSampleBuffer)?.outputPresentationTimeStamp ?? .invalid }
            builder.getDecodeTimeStamp { ($0 as? CMSampleBuffer)?.outputDecodeTimeStamp ?? .invalid }
            builder.isDataReady { ($0 as? CMSampleBuffer)?.dataIsReady ?? true }
            builder.getSize { ($0 as? CMSampleBuffer)?.totalSampleSize ?? 0 }
            builder.compare { left, right in
                let a = (left as? CMSampleBuffer)?.outputPresentationTimeStamp ?? .invalid
                let b = (right as? CMSampleBuffer)?.outputPresentationTimeStamp ?? .invalid
                let cmp = CMTimeCompare(a, b)
                if cmp < 0 { return .compareLessThan }
                if cmp > 0 { return .compareGreaterThan }
                return .compareEqualTo
            }
        })
    }

    public struct Buffers: Sequence {
        public typealias Element = CMBuffer
        fileprivate var items: [CMBuffer]

        public func makeIterator() -> Iterator {
            Iterator(items: items)
        }

        public struct Iterator: IteratorProtocol {
            public typealias Element = AnyObject
            fileprivate var items: [CMBuffer]
            fileprivate var index = 0

            public mutating func next() -> CMBuffer? {
                guard index < items.count else { return nil }
                let value = items[index]
                index += 1
                return value
            }
        }
    }

    private static let processTypeID: CFTypeID = 0x434D_4251
    public static var typeID: CFTypeID { processTypeID }

    private let lock = CMUnfairLock()
    private let maxCapacity: CMItemCount
    fileprivate var callbacks: CMBufferCallbacks
    private var items: [CMBuffer] = []
    private var endOfData = false
    private var triggers: [CMBufferQueueTriggerBox] = []
    private var inTrigger = false
    private var validationCallback: CMBufferValidationCallback?
    private var validationHandler: CMBufferValidationHandler?
    private var validationRefcon: UnsafeMutableRawPointer?
    private var lastMinPTS: CMTime = .invalid
    private var lastMaxPTS: CMTime = .invalid

    public init(capacity: CMItemCount, callbacks: CMBufferCallbacks) {
        self.maxCapacity = capacity
        self.callbacks = callbacks
    }

    public convenience init(capacity: CMItemCount, handlers: Handlers) {
        let callbacks = CMBufferCallbacks(
            version: 1,
            refcon: nil,
            getDecodeTimeStamp: handlers.getDecodeTimeStamp.map { handler in
                { buffer, _ in handler(buffer) }
            },
            getPresentationTimeStamp: handlers.getPresentationTimeStamp.map { handler in
                { buffer, _ in handler(buffer) }
            },
            getDuration: { buffer, _ in handlers.getDuration(buffer) },
            isDataReady: handlers.isDataReady.map { handler in
                { buffer, _ in DarwinBoolean(handler(buffer)) }
            },
            compare: handlers.compare.map { handler in
                { left, right, _ in handler(left, right) }
            },
            dataBecameReadyNotification: nil,
            getSize: handlers.getSize.map { handler in
                { buffer, _ in handler(buffer) }
            }
        )
        self.init(capacity: capacity, callbacks: callbacks)
    }

    public init(referencing object: CMBufferQueue) {
        self.maxCapacity = object.maxCapacity
        self.callbacks = object.callbacks
        self.items = object.lock.locked { object.items }
        self.endOfData = object.endOfData
    }

    public var bufferCount: CMItemCount { CMBufferQueueGetBufferCount(self) }
    public var isEmpty: Bool { CMBufferQueueIsEmpty(self) }
    public var duration: CMTime { CMBufferQueueGetDuration(self) }
    public var totalSize: Int { CMBufferQueueGetTotalSize(self) }
    public var head: CMBuffer? { CMBufferQueueGetHead(self) }
    public var containsEndOfData: Bool { CMBufferQueueContainsEndOfData(self) }
    public var isAtEndOfData: Bool { CMBufferQueueIsAtEndOfData(self) }
    public var firstDecodeTimeStamp: CMTime { CMBufferQueueGetFirstDecodeTimeStamp(self) }
    public var firstPresentationTimeStamp: CMTime { CMBufferQueueGetFirstPresentationTimeStamp(self) }
    public var minDecodeTimeStamp: CMTime { CMBufferQueueGetMinDecodeTimeStamp(self) }
    public var minPresentationTimeStamp: CMTime { CMBufferQueueGetMinPresentationTimeStamp(self) }
    public var maxPresentationTimeStamp: CMTime { CMBufferQueueGetMaxPresentationTimeStamp(self) }
    public var endPresentationTimeStamp: CMTime { CMBufferQueueGetEndPresentationTimeStamp(self) }
    public var buffers: Buffers {
        Buffers(items: lock.locked { items })
    }

    public func enqueue(_ buffer: CMBuffer) throws {
        let status = CMBufferQueueEnqueue(self, buffer: buffer)
        if status != 0 { throw cmNSError(code: Int(status)) }
    }

    public func dequeue() -> CMBuffer? { CMBufferQueueDequeue(self) }
    public func dequeueIfDataReady() -> CMBuffer? { CMBufferQueueDequeueIfDataReady(self) }

    public func reset() throws {
        let status = CMBufferQueueReset(self)
        if status != 0 { throw cmNSError(code: Int(status)) }
    }

    public func reset(_ body: (CMBuffer) throws -> Void) throws {
        let snapshot = lock.locked { items }
        let status = CMBufferQueueReset(self)
        if status != 0 { throw cmNSError(code: Int(status)) }
        for item in snapshot {
            try body(item)
        }
    }

    public func markEndOfData() throws {
        let status = CMBufferQueueMarkEndOfData(self)
        if status != 0 { throw cmNSError(code: Int(status)) }
    }

    public func setValidationHandler(_ body: @escaping (CMBufferQueue, CMBuffer) throws -> Void) {
        validationHandler = { queue, buffer in
            do {
                try body(queue, buffer)
                return 0
            } catch {
                return kCMBufferQueueError_InvalidBuffer
            }
        }
    }

    public func installTrigger(
        condition: TriggerCondition,
        _ body: CMBufferQueueTriggerHandler? = nil
    ) throws -> TriggerToken {
        var token: CMBufferQueueTriggerToken?
        let (code, time, threshold) = cmTriggerParts(condition)
        let status = CMBufferQueueInstallTrigger(
            self,
            callback: nil,
            refcon: nil,
            condition: code,
            time: time,
            triggerTokenOut: &token
        )
        if status != 0 { throw cmNSError(code: Int(status)) }
        guard let token else { throw Error.invalidTriggerToken }
        if let body {
            if let box = cmTriggerBox(token, in: self) {
                box.handler = body
            }
        }
        _ = threshold
        return token
    }

    public func removeTrigger(_ triggerToken: TriggerToken) throws {
        let status = CMBufferQueueRemoveTrigger(self, triggerToken: triggerToken)
        if status != 0 { throw cmNSError(code: Int(status)) }
    }

    public func testTrigger(_ triggerToken: TriggerToken) -> Bool {
        CMBufferQueueTestTrigger(self, triggerToken: triggerToken)
    }

    fileprivate func snapshotItems() -> [CMBuffer] {
        lock.locked { items }
    }

    fileprivate func withLockedQueue<T>(_ body: (CMBufferQueue) -> T) -> T {
        lock.locked { body(self) }
    }

    fileprivate func mutateEnqueue(_ buffer: CMBuffer) -> OSStatus {
        if inTrigger { return kCMBufferQueueError_CannotModifyQueueFromTriggerCallback }
        if endOfData { return kCMBufferQueueError_EnqueueAfterEndOfData }
        if maxCapacity > 0 && CMItemCount(items.count) >= maxCapacity {
            return kCMBufferQueueError_QueueIsFull
        }
        if let validationCallback {
            let status = validationCallback(self, buffer, validationRefcon)
            if status != 0 { return status }
        }
        if let validationHandler {
            let status = validationHandler(self, buffer)
            if status != 0 { return status }
        }
        items.append(buffer)
        if let compare = callbacks.compare {
            items.sort { left, right in
                compare(left, right, callbacks.refcon) == .compareLessThan
            }
        }
        return 0
    }

    fileprivate func mutateDequeue(onlyIfReady: Bool) -> CMBuffer? {
        if inTrigger { return nil }
        guard !items.isEmpty else { return nil }
        if onlyIfReady {
            let ready = callbacks.isDataReady?(items[0], callbacks.refcon).boolValue ?? true
            if !ready { return nil }
        }
        return items.removeFirst()
    }

    fileprivate func mutateReset() -> [CMBuffer] {
        let removed = items
        items.removeAll()
        endOfData = false
        return removed
    }

    fileprivate func mutateMarkEnd() {
        endOfData = true
    }

    fileprivate var hasEndOfData: Bool { endOfData }
    fileprivate var itemCount: CMItemCount { CMItemCount(items.count) }

    fileprivate func installTriggerBox(_ box: CMBufferQueueTriggerBox) {
        triggers.append(box)
    }

    fileprivate func removeTriggerBox(_ token: CMBufferQueueTriggerToken) -> OSStatus {
        let before = triggers.count
        triggers.removeAll { $0.token == token }
        return triggers.count == before ? kCMBufferQueueError_InvalidTriggerToken : 0
    }

    fileprivate func triggerBoxes() -> [CMBufferQueueTriggerBox] { triggers }

    fileprivate func setValidation(
        callback: CMBufferValidationCallback?,
        handler: CMBufferValidationHandler?,
        refcon: UnsafeMutableRawPointer?
    ) {
        validationCallback = callback
        validationHandler = handler
        validationRefcon = refcon
    }

    fileprivate func fireTriggers(resetEvent: Bool = false, ptsChanged: Bool = false) {
        let duration = cmQueueDurationUnlocked(self)
        let count = CMItemCount(items.count)
        let minPTS = cmQueueMinPTSUnlocked(self)
        let maxPTS = cmQueueMaxPTSUnlocked(self)
        let ready = items.contains { callbacks.isDataReady?($0, callbacks.refcon).boolValue ?? true }
        var toFire: [CMBufferQueueTriggerBox] = []
        for box in triggers {
            let isTrue = cmEvaluateTrigger(
                box,
                duration: duration,
                count: count,
                minPTS: minPTS,
                maxPTS: maxPTS,
                dataReady: ready,
                endOfData: endOfData && items.isEmpty,
                resetEvent: resetEvent,
                ptsChanged: ptsChanged,
                lastMin: lastMinPTS,
                lastMax: lastMaxPTS
            )
            if isTrue && !box.lastTrue {
                toFire.append(box)
            }
            if !cmEventTrigger(box.condition) {
                box.lastTrue = isTrue
            } else {
                box.lastTrue = false
            }
        }
        lastMinPTS = minPTS
        lastMaxPTS = maxPTS
        if toFire.isEmpty { return }
        inTrigger = true
        for box in toFire {
            box.callback?(box.refcon, box.token)
            box.handler?(box.token)
        }
        inTrigger = false
    }
}

private func cmEventTrigger(_ condition: CMBufferQueueTriggerCondition) -> Bool {
    condition == kCMBufferQueueTrigger_WhenReset
        || condition == kCMBufferQueueTrigger_WhenEndOfDataReached
        || condition == kCMBufferQueueTrigger_WhenMinPresentationTimeStampChanges
        || condition == kCMBufferQueueTrigger_WhenMaxPresentationTimeStampChanges
}

private func cmTriggerParts(
    _ condition: CMBufferQueue.TriggerCondition
) -> (CMBufferQueueTriggerCondition, CMTime, CMItemCount) {
    switch condition {
    case .whenDurationBecomesLessThan(let time):
        return (kCMBufferQueueTrigger_WhenDurationBecomesLessThan, time, 0)
    case .whenDurationBecomesLessThanOrEqualTo(let time):
        return (kCMBufferQueueTrigger_WhenDurationBecomesLessThanOrEqualTo, time, 0)
    case .whenDurationBecomesGreaterThan(let time):
        return (kCMBufferQueueTrigger_WhenDurationBecomesGreaterThan, time, 0)
    case .whenDurationBecomesGreaterThanOrEqualTo(let time):
        return (kCMBufferQueueTrigger_WhenDurationBecomesGreaterThanOrEqualTo, time, 0)
    case .whenMinPresentationTimeStampChanges:
        return (kCMBufferQueueTrigger_WhenMinPresentationTimeStampChanges, .invalid, 0)
    case .whenMaxPresentationTimeStampChanges:
        return (kCMBufferQueueTrigger_WhenMaxPresentationTimeStampChanges, .invalid, 0)
    case .whenDataBecomesReady:
        return (kCMBufferQueueTrigger_WhenDataBecomesReady, .invalid, 0)
    case .whenEndOfDataReached:
        return (kCMBufferQueueTrigger_WhenEndOfDataReached, .invalid, 0)
    case .whenReset:
        return (kCMBufferQueueTrigger_WhenReset, .invalid, 0)
    case .whenBufferCountBecomesLessThan(let count):
        return (kCMBufferQueueTrigger_WhenBufferCountBecomesLessThan, .invalid, count)
    case .whenBufferCountBecomesGreaterThan(let count):
        return (kCMBufferQueueTrigger_WhenBufferCountBecomesGreaterThan, .invalid, count)
    }
}

private func cmTriggerBox(_ token: CMBufferQueueTriggerToken, in queue: CMBufferQueue) -> CMBufferQueueTriggerBox? {
    queue.triggerBoxes().first { $0.token == token }
}

private func cmEvaluateTrigger(
    _ box: CMBufferQueueTriggerBox,
    duration: CMTime,
    count: CMItemCount,
    minPTS: CMTime,
    maxPTS: CMTime,
    dataReady: Bool,
    endOfData: Bool,
    resetEvent: Bool,
    ptsChanged: Bool,
    lastMin: CMTime,
    lastMax: CMTime
) -> Bool {
    switch box.condition {
    case kCMBufferQueueTrigger_WhenDurationBecomesLessThan:
        return duration.isNumeric && box.time.isNumeric && CMTimeCompare(duration, box.time) < 0
    case kCMBufferQueueTrigger_WhenDurationBecomesLessThanOrEqualTo:
        return duration.isNumeric && box.time.isNumeric && CMTimeCompare(duration, box.time) <= 0
    case kCMBufferQueueTrigger_WhenDurationBecomesGreaterThan:
        return duration.isNumeric && box.time.isNumeric && CMTimeCompare(duration, box.time) > 0
    case kCMBufferQueueTrigger_WhenDurationBecomesGreaterThanOrEqualTo:
        return duration.isNumeric && box.time.isNumeric && CMTimeCompare(duration, box.time) >= 0
    case kCMBufferQueueTrigger_WhenDurationBecomesGreaterThanOrEqualToAndBufferCountBecomesGreaterThan:
        return duration.isNumeric && box.time.isNumeric
            && CMTimeCompare(duration, box.time) >= 0 && count > box.threshold
    case kCMBufferQueueTrigger_WhenBufferCountBecomesLessThan:
        return count < box.threshold
    case kCMBufferQueueTrigger_WhenBufferCountBecomesGreaterThan:
        return count > box.threshold
    case kCMBufferQueueTrigger_WhenDataBecomesReady:
        return dataReady
    case kCMBufferQueueTrigger_WhenEndOfDataReached:
        return endOfData
    case kCMBufferQueueTrigger_WhenReset:
        return resetEvent
    case kCMBufferQueueTrigger_WhenMinPresentationTimeStampChanges:
        return ptsChanged && CMTimeCompare(minPTS, lastMin) != 0
    case kCMBufferQueueTrigger_WhenMaxPresentationTimeStampChanges:
        return ptsChanged && CMTimeCompare(maxPTS, lastMax) != 0
    default:
        return false
    }
}

private func cmQueueDurationUnlocked(_ queue: CMBufferQueue) -> CMTime {
    var total = CMTime.zero
    var any = false
    for item in queue.snapshotItems() {
        let duration = queue.callbacks.getDuration(item, queue.callbacks.refcon)
        if duration.isNumeric {
            total = CMTimeAdd(total, duration)
            any = true
        }
    }
    return any ? total : .zero
}

private func cmQueueMinPTSUnlocked(_ queue: CMBufferQueue) -> CMTime {
    var best: CMTime = .invalid
    for item in queue.snapshotItems() {
        let pts = queue.callbacks.getPresentationTimeStamp?(item, queue.callbacks.refcon) ?? .invalid
        if pts.isNumeric {
            if !best.isNumeric || CMTimeCompare(pts, best) < 0 { best = pts }
        }
    }
    return best
}

private func cmQueueMaxPTSUnlocked(_ queue: CMBufferQueue) -> CMTime {
    var best: CMTime = .invalid
    for item in queue.snapshotItems() {
        let pts = queue.callbacks.getPresentationTimeStamp?(item, queue.callbacks.refcon) ?? .invalid
        if pts.isNumeric {
            if !best.isNumeric || CMTimeCompare(pts, best) > 0 { best = pts }
        }
    }
    return best
}

private var cmUnsortedSampleBufferCallbacks = CMBufferCallbacks(
    version: 1,
    refcon: nil,
    getDecodeTimeStamp: { buffer, _ in (buffer as? CMSampleBuffer)?.decodeTimeStamp ?? .invalid },
    getPresentationTimeStamp: { buffer, _ in (buffer as? CMSampleBuffer)?.presentationTimeStamp ?? .invalid },
    getDuration: { buffer, _ in (buffer as? CMSampleBuffer)?.duration ?? .invalid },
    isDataReady: { buffer, _ in DarwinBoolean((buffer as? CMSampleBuffer)?.dataIsReady ?? true) },
    compare: nil,
    dataBecameReadyNotification: nil,
    getSize: { buffer, _ in (buffer as? CMSampleBuffer)?.totalSampleSize ?? 0 }
)

private var cmSortedSampleBufferCallbacks = CMBufferCallbacks(
    version: 1,
    refcon: nil,
    getDecodeTimeStamp: { buffer, _ in (buffer as? CMSampleBuffer)?.outputDecodeTimeStamp ?? .invalid },
    getPresentationTimeStamp: { buffer, _ in (buffer as? CMSampleBuffer)?.outputPresentationTimeStamp ?? .invalid },
    getDuration: { buffer, _ in (buffer as? CMSampleBuffer)?.outputDuration ?? .invalid },
    isDataReady: { buffer, _ in DarwinBoolean((buffer as? CMSampleBuffer)?.dataIsReady ?? true) },
    compare: { left, right, _ in
        let a = (left as? CMSampleBuffer)?.outputPresentationTimeStamp ?? .invalid
        let b = (right as? CMSampleBuffer)?.outputPresentationTimeStamp ?? .invalid
        let cmp = CMTimeCompare(a, b)
        if cmp < 0 { return .compareLessThan }
        if cmp > 0 { return .compareGreaterThan }
        return .compareEqualTo
    },
    dataBecameReadyNotification: nil,
    getSize: { buffer, _ in (buffer as? CMSampleBuffer)?.totalSampleSize ?? 0 }
)

public func CMBufferQueueGetTypeID() -> CFTypeID { CMBufferQueue.typeID }

public func CMBufferQueueGetCallbacksForUnsortedSampleBuffers() -> UnsafePointer<CMBufferCallbacks> {
    withUnsafePointer(to: &cmUnsortedSampleBufferCallbacks) { $0 }
}

public func CMBufferQueueGetCallbacksForSampleBuffersSortedByOutputPTS() -> UnsafePointer<CMBufferCallbacks> {
    withUnsafePointer(to: &cmSortedSampleBufferCallbacks) { $0 }
}

public func CMBufferQueueCreate(
    allocator: CFAllocator?,
    capacity: CMItemCount,
    callbacks: UnsafePointer<CMBufferCallbacks>,
    queueOut: UnsafeMutablePointer<CMBufferQueue?>
) -> OSStatus {
    _ = allocator
    queueOut.pointee = CMBufferQueue(capacity: capacity, callbacks: callbacks.pointee)
    return 0
}

public func CMBufferQueueCreateWithHandlers(
    _ allocator: CFAllocator?,
    _ capacity: CMItemCount,
    _ handlers: OpaquePointer,
    _ queueOut: UnsafeMutablePointer<CMBufferQueue?>
) -> OSStatus {
    _ = (allocator, capacity, handlers)
    // The C overlay passes an Apple-internal handlers blob. Linux has no ABI
    // for that pointer; use CMBufferQueue(capacity:handlers:) instead.
    queueOut.pointee = nil
    return kCMBufferQueueError_InvalidCMBufferCallbacksStruct
}

public func CMBufferQueueEnqueue(_ queue: CMBufferQueue, buffer buf: CMBuffer) -> OSStatus {
    let status = queue.withLockedQueue { $0.mutateEnqueue(buf) }
    if status == 0 {
        queue.withLockedQueue { $0.fireTriggers(ptsChanged: true) }
    }
    return status
}

public func CMBufferQueueDequeue(_ queue: CMBufferQueue) -> CMBuffer? {
    let item = queue.withLockedQueue { $0.mutateDequeue(onlyIfReady: false) }
    queue.withLockedQueue { $0.fireTriggers(ptsChanged: true) }
    return item
}

public func CMBufferQueueDequeueAndRetain(_ queue: CMBufferQueue) -> CMBuffer? {
    CMBufferQueueDequeue(queue)
}

public func CMBufferQueueDequeueIfDataReady(_ queue: CMBufferQueue) -> CMBuffer? {
    let item = queue.withLockedQueue { $0.mutateDequeue(onlyIfReady: true) }
    queue.withLockedQueue { $0.fireTriggers(ptsChanged: true) }
    return item
}

public func CMBufferQueueDequeueIfDataReadyAndRetain(_ queue: CMBufferQueue) -> CMBuffer? {
    CMBufferQueueDequeueIfDataReady(queue)
}

public func CMBufferQueueGetBufferCount(_ queue: CMBufferQueue) -> CMItemCount {
    queue.withLockedQueue { $0.itemCount }
}

public func CMBufferQueueIsEmpty(_ queue: CMBufferQueue) -> Bool {
    CMBufferQueueGetBufferCount(queue) == 0
}

public func CMBufferQueueGetHead(_ queue: CMBufferQueue) -> CMBuffer? {
    queue.snapshotItems().first
}

public func CMBufferQueueCopyHead(_ queue: CMBufferQueue) -> CMBuffer? {
    CMBufferQueueGetHead(queue)
}

public func CMBufferQueueGetDuration(_ queue: CMBufferQueue) -> CMTime {
    queue.withLockedQueue { cmQueueDurationUnlocked($0) }
}

public func CMBufferQueueGetTotalSize(_ queue: CMBufferQueue) -> Int {
    queue.withLockedQueue { current in
        var total = 0
        for item in current.snapshotItems() {
            total += current.callbacks.getSize?(item, current.callbacks.refcon) ?? 0
        }
        return total
    }
}

public func CMBufferQueueGetFirstDecodeTimeStamp(_ queue: CMBufferQueue) -> CMTime {
    guard let first = queue.snapshotItems().first else { return .invalid }
    return queue.callbacks.getDecodeTimeStamp?(first, queue.callbacks.refcon) ?? .invalid
}

public func CMBufferQueueGetFirstPresentationTimeStamp(_ queue: CMBufferQueue) -> CMTime {
    guard let first = queue.snapshotItems().first else { return .invalid }
    return queue.callbacks.getPresentationTimeStamp?(first, queue.callbacks.refcon) ?? .invalid
}

public func CMBufferQueueGetMinDecodeTimeStamp(_ queue: CMBufferQueue) -> CMTime {
    var best: CMTime = .invalid
    for item in queue.snapshotItems() {
        let dts = queue.callbacks.getDecodeTimeStamp?(item, queue.callbacks.refcon) ?? .invalid
        if dts.isNumeric && (!best.isNumeric || CMTimeCompare(dts, best) < 0) {
            best = dts
        }
    }
    return best
}

public func CMBufferQueueGetMinPresentationTimeStamp(_ queue: CMBufferQueue) -> CMTime {
    cmQueueMinPTSUnlocked(queue)
}

public func CMBufferQueueGetMaxPresentationTimeStamp(_ queue: CMBufferQueue) -> CMTime {
    cmQueueMaxPTSUnlocked(queue)
}

public func CMBufferQueueGetEndPresentationTimeStamp(_ queue: CMBufferQueue) -> CMTime {
    guard let last = queue.snapshotItems().last else { return .invalid }
    let pts = queue.callbacks.getPresentationTimeStamp?(last, queue.callbacks.refcon) ?? .invalid
    let duration = queue.callbacks.getDuration(last, queue.callbacks.refcon)
    if pts.isNumeric && duration.isNumeric {
        return CMTimeAdd(pts, duration)
    }
    return pts
}

public func CMBufferQueueContainsEndOfData(_ queue: CMBufferQueue) -> Bool {
    queue.withLockedQueue { $0.hasEndOfData }
}

public func CMBufferQueueIsAtEndOfData(_ queue: CMBufferQueue) -> Bool {
    queue.withLockedQueue { $0.hasEndOfData && $0.itemCount == 0 }
}

public func CMBufferQueueMarkEndOfData(_ queue: CMBufferQueue) -> OSStatus {
    queue.withLockedQueue {
        $0.mutateMarkEnd()
        $0.fireTriggers()
    }
    return 0
}

public func CMBufferQueueReset(_ queue: CMBufferQueue) -> OSStatus {
    queue.withLockedQueue {
        _ = $0.mutateReset()
        $0.fireTriggers(resetEvent: true)
    }
    return 0
}

public func CMBufferQueueResetWithCallback(
    _ queue: CMBufferQueue,
    callback: (CMBuffer, UnsafeMutableRawPointer?) -> Void,
    refcon: UnsafeMutableRawPointer?
) -> OSStatus {
    let removed = queue.withLockedQueue { $0.mutateReset() }
    for item in removed {
        callback(item, refcon)
    }
    queue.withLockedQueue { $0.fireTriggers(resetEvent: true) }
    return 0
}

public func CMBufferQueueCallForEachBuffer(
    _ queue: CMBufferQueue,
    callback: (CMBuffer, UnsafeMutableRawPointer?) -> OSStatus,
    refcon: UnsafeMutableRawPointer?
) -> OSStatus {
    for item in queue.snapshotItems() {
        let status = callback(item, refcon)
        if status != 0 { return status }
    }
    return 0
}

public func CMBufferQueueInstallTrigger(
    _ queue: CMBufferQueue,
    callback: CMBufferQueueTriggerCallback?,
    refcon: UnsafeMutableRawPointer?,
    condition: CMBufferQueueTriggerCondition,
    time: CMTime,
    triggerTokenOut: UnsafeMutablePointer<CMBufferQueueTriggerToken?>?
) -> OSStatus {
    if condition < 1 || condition > 12 {
        triggerTokenOut?.pointee = nil
        return kCMBufferQueueError_InvalidTriggerCondition
    }
    if (condition == kCMBufferQueueTrigger_WhenDurationBecomesLessThan
        || condition == kCMBufferQueueTrigger_WhenDurationBecomesGreaterThan)
        && time.isNumeric && CMTimeCompare(time, .zero) < 0
    {
        return kCMBufferQueueError_BadTriggerDuration
    }
    let box = CMBufferQueueTriggerBox(condition: condition, time: time, threshold: 0)
    box.callback = callback
    box.refcon = refcon
    queue.withLockedQueue { $0.installTriggerBox(box) }
    triggerTokenOut?.pointee = box.token
    queue.withLockedQueue { $0.fireTriggers() }
    return 0
}

public func CMBufferQueueInstallTriggerHandler(
    _ queue: CMBufferQueue,
    _ condition: CMBufferQueueTriggerCondition,
    _ time: CMTime,
    _ triggerTokenOut: UnsafeMutablePointer<CMBufferQueueTriggerToken?>?,
    _ handler: CMBufferQueueTriggerHandler?
) -> OSStatus {
    let status = CMBufferQueueInstallTrigger(
        queue,
        callback: nil,
        refcon: nil,
        condition: condition,
        time: time,
        triggerTokenOut: triggerTokenOut
    )
    if status == 0, let token = triggerTokenOut?.pointee, let handler {
        cmTriggerBox(token, in: queue)?.handler = handler
    }
    return status
}

public func CMBufferQueueInstallTriggerWithIntegerThreshold(
    _ queue: CMBufferQueue,
    callback: CMBufferQueueTriggerCallback?,
    refcon: UnsafeMutableRawPointer?,
    condition: CMBufferQueueTriggerCondition,
    threshold: CMItemCount,
    triggerTokenOut: UnsafeMutablePointer<CMBufferQueueTriggerToken?>?
) -> OSStatus {
    if condition < 1 || condition > 12 {
        triggerTokenOut?.pointee = nil
        return kCMBufferQueueError_InvalidTriggerCondition
    }
    let box = CMBufferQueueTriggerBox(condition: condition, time: .invalid, threshold: threshold)
    box.callback = callback
    box.refcon = refcon
    queue.withLockedQueue { $0.installTriggerBox(box) }
    triggerTokenOut?.pointee = box.token
    queue.withLockedQueue { $0.fireTriggers() }
    return 0
}

public func CMBufferQueueInstallTriggerHandlerWithIntegerThreshold(
    _ queue: CMBufferQueue,
    _ condition: CMBufferQueueTriggerCondition,
    _ threshold: CMItemCount,
    _ triggerTokenOut: UnsafeMutablePointer<CMBufferQueueTriggerToken?>?,
    _ handler: CMBufferQueueTriggerHandler?
) -> OSStatus {
    let status = CMBufferQueueInstallTriggerWithIntegerThreshold(
        queue,
        callback: nil,
        refcon: nil,
        condition: condition,
        threshold: threshold,
        triggerTokenOut: triggerTokenOut
    )
    if status == 0, let token = triggerTokenOut?.pointee, let handler {
        cmTriggerBox(token, in: queue)?.handler = handler
    }
    return status
}

public func CMBufferQueueRemoveTrigger(
    _ queue: CMBufferQueue,
    triggerToken: CMBufferQueueTriggerToken
) -> OSStatus {
    queue.withLockedQueue { $0.removeTriggerBox(triggerToken) }
}

public func CMBufferQueueTestTrigger(
    _ queue: CMBufferQueue,
    triggerToken: CMBufferQueueTriggerToken
) -> Bool {
    guard let box = cmTriggerBox(triggerToken, in: queue) else { return false }
    return queue.withLockedQueue { current in
        cmEvaluateTrigger(
            box,
            duration: cmQueueDurationUnlocked(current),
            count: current.itemCount,
            minPTS: cmQueueMinPTSUnlocked(current),
            maxPTS: cmQueueMaxPTSUnlocked(current),
            dataReady: current.snapshotItems().contains {
                current.callbacks.isDataReady?($0, current.callbacks.refcon).boolValue ?? true
            },
            endOfData: current.hasEndOfData && current.itemCount == 0,
            resetEvent: false,
            ptsChanged: false,
            lastMin: .invalid,
            lastMax: .invalid
        )
    }
}

public func CMBufferQueueSetValidationCallback(
    _ queue: CMBufferQueue,
    callback: @escaping CMBufferValidationCallback,
    refcon: UnsafeMutableRawPointer?
) -> OSStatus {
    queue.withLockedQueue { $0.setValidation(callback: callback, handler: nil, refcon: refcon) }
    return 0
}

public func CMBufferQueueSetValidationHandler(
    _ queue: CMBufferQueue,
    _ handler: @escaping CMBufferValidationHandler
) -> OSStatus {
    queue.withLockedQueue { $0.setValidation(callback: nil, handler: handler, refcon: nil) }
    return 0
}
