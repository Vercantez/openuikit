import CoreFoundation
import CoreMedia
import Foundation

func testCMSimpleQueueCreateEnqueueDequeue() {
    var queue: CMSimpleQueue?
    precondition(CMSimpleQueueCreate(allocator: nil, capacity: 2, queueOut: &queue) == 0)
    let q = queue!
    precondition(CMSimpleQueueGetTypeID() == CMSimpleQueue.typeID)
    precondition(CMSimpleQueueGetCapacity(q) == 2)
    precondition(CMSimpleQueueGetCount(q) == 0)
    precondition(CMSimpleQueueGetHead(q) == nil)
    var first = 11
    var second = 22
    withUnsafePointer(to: &first) { a in
        withUnsafePointer(to: &second) { b in
            precondition(CMSimpleQueueEnqueue(q, element: UnsafeRawPointer(a)) == 0)
            precondition(CMSimpleQueueGetCount(q) == 1)
            precondition(CMSimpleQueueGetHead(q) == UnsafeRawPointer(a))
            precondition(CMSimpleQueueEnqueue(q, element: UnsafeRawPointer(b)) == 0)
            precondition(CMSimpleQueueGetCount(q) == 2)
            precondition(CMSimpleQueueEnqueue(q, element: UnsafeRawPointer(a)) == kCMSimpleQueueError_QueueIsFull)
            precondition(CMSimpleQueueDequeue(q) == UnsafeRawPointer(a))
            precondition(CMSimpleQueueDequeue(q) == UnsafeRawPointer(b))
            precondition(CMSimpleQueueDequeue(q) == nil)
        }
    }
}

func testCMSimpleQueueResetAndFullness() {
    let q = try! CMSimpleQueue(capacity: 4)
    precondition(q.capacity == 4)
    precondition(q.count == 0)
    precondition(q.fullness == 0)
    var value = 3
    withUnsafePointer(to: &value) { pointer in
        try! q.enqueue(UnsafeRawPointer(pointer))
        precondition(q.head == UnsafeRawPointer(pointer))
        precondition(q.fullness > 0)
        precondition(q.dequeue() == UnsafeRawPointer(pointer))
    }
    try! q.reset()
    precondition(q.count == 0)
    precondition(CMSimpleQueueReset(q) == 0)
    let copy = CMSimpleQueue(referencing: q)
    precondition(copy.capacity == 4)
}

func testCMSimpleQueueErrorConstants() {
    precondition(kCMSimpleQueueError_AllocationFailed == -12770)
    precondition(kCMSimpleQueueError_RequiredParameterMissing == -12771)
    precondition(kCMSimpleQueueError_ParameterOutOfRange == -12772)
    precondition(kCMSimpleQueueError_QueueIsFull == -12773)
    precondition(CMSimpleQueue.Error.queueIsFull.code == -12773)
    precondition(CMSimpleQueue.Error.parameterOutOfRange.code == -12772)
    precondition(CMSimpleQueue.Error.allocationFailed.code == -12770)
    precondition(CMSimpleQueue.Error.requiredParameterMissing.code == -12771)
    var queue: CMSimpleQueue?
    precondition(
        CMSimpleQueueCreate(allocator: nil, capacity: -1, queueOut: &queue)
            == kCMSimpleQueueError_ParameterOutOfRange
    )
}

func testCMBufferQueueUnsortedEnqueueDequeue() {
    let callbacks = CMBufferQueueGetCallbacksForUnsortedSampleBuffers()
    var queue: CMBufferQueue?
    precondition(CMBufferQueueCreate(allocator: nil, capacity: 8, callbacks: callbacks, queueOut: &queue) == 0)
    let q = queue!
    precondition(CMBufferQueueGetTypeID() == CMBufferQueue.typeID)
    precondition(CMBufferQueueIsEmpty(q))
    precondition(CMBufferQueueGetBufferCount(q) == 0)
    precondition(CMBufferQueueGetHead(q) == nil)
    let first = cmQueueTestSample(pts: 1, duration: 2, size: 4)
    let second = cmQueueTestSample(pts: 3, duration: 2, size: 8)
    precondition(CMBufferQueueEnqueue(q, buffer: first) == 0)
    precondition(CMBufferQueueEnqueue(q, buffer: second) == 0)
    precondition(CMBufferQueueGetBufferCount(q) == 2)
    precondition(CMBufferQueueCopyHead(q) === first)
    precondition(CMBufferQueueDequeue(q) === first)
    precondition(CMBufferQueueDequeueAndRetain(q) === second)
    precondition(CMBufferQueueDequeue(q) == nil)
}

func testCMBufferQueueDurationSizeAndPTS() {
    let q = CMBufferQueue(capacity: 4, handlers: .unsortedSampleBuffers)
    try! q.enqueue(cmQueueTestSample(pts: 10, duration: 5, size: 3, dts: 8))
    try! q.enqueue(cmQueueTestSample(pts: 20, duration: 5, size: 7, dts: 18))
    precondition(CMBufferQueueGetDuration(q) == CMTime(value: 10, timescale: 1))
    precondition(CMBufferQueueGetTotalSize(q) == 10)
    precondition(CMBufferQueueGetFirstPresentationTimeStamp(q) == CMTime(value: 10, timescale: 1))
    precondition(CMBufferQueueGetFirstDecodeTimeStamp(q) == CMTime(value: 8, timescale: 1))
    precondition(CMBufferQueueGetMinPresentationTimeStamp(q) == CMTime(value: 10, timescale: 1))
    precondition(CMBufferQueueGetMinDecodeTimeStamp(q) == CMTime(value: 8, timescale: 1))
    precondition(CMBufferQueueGetMaxPresentationTimeStamp(q) == CMTime(value: 20, timescale: 1))
    precondition(CMTimeCompare(CMBufferQueueGetEndPresentationTimeStamp(q), CMTime(value: 25, timescale: 1)) == 0)
    precondition(q.duration == CMBufferQueueGetDuration(q))
    precondition(q.totalSize == 10)
    precondition(q.bufferCount == 2)
}

func testCMBufferQueueEndOfDataAndReset() {
    let q = CMBufferQueue(capacity: 2, handlers: .unsortedSampleBuffers)
    try! q.enqueue(cmQueueTestSample(pts: 1, duration: 1, size: 1))
    precondition(!CMBufferQueueContainsEndOfData(q))
    precondition(!CMBufferQueueIsAtEndOfData(q))
    precondition(CMBufferQueueMarkEndOfData(q) == 0)
    precondition(CMBufferQueueContainsEndOfData(q))
    precondition(!CMBufferQueueIsAtEndOfData(q))
    precondition(CMBufferQueueEnqueue(q, buffer: cmQueueTestSample(pts: 2, duration: 1, size: 1))
        == kCMBufferQueueError_EnqueueAfterEndOfData)
    _ = CMBufferQueueDequeue(q)
    precondition(CMBufferQueueIsAtEndOfData(q))
    var visited = 0
    precondition(
        CMBufferQueueResetWithCallback(q, callback: { _, _ in visited += 1 }, refcon: nil) == 0
    )
    precondition(!CMBufferQueueContainsEndOfData(q))
    precondition(CMBufferQueueReset(q) == 0)
    try! q.markEndOfData()
    precondition(q.containsEndOfData)
}

func testCMBufferQueueCallForEachAndValidation() {
    let q = CMBufferQueue(capacity: 4, handlers: .unsortedSampleBuffers)
    try! q.enqueue(cmQueueTestSample(pts: 1, duration: 1, size: 1))
    try! q.enqueue(cmQueueTestSample(pts: 2, duration: 1, size: 1))
    var count = 0
    precondition(
        CMBufferQueueCallForEachBuffer(q, callback: { _, _ in
            count += 1
            return 0
        }, refcon: nil) == 0
    )
    precondition(count == 2)
    precondition(
        CMBufferQueueSetValidationCallback(q, callback: { _, _, _ in
            kCMBufferQueueError_InvalidBuffer
        }, refcon: nil) == 0
    )
    precondition(
        CMBufferQueueEnqueue(q, buffer: cmQueueTestSample(pts: 3, duration: 1, size: 1))
            == kCMBufferQueueError_InvalidBuffer
    )
    precondition(
        CMBufferQueueSetValidationHandler(q) { _, _ in 0 } == 0
    )
    q.setValidationHandler { _, _ in }
    try! q.enqueue(cmQueueTestSample(pts: 4, duration: 1, size: 1))
}

func testCMBufferQueueTriggerCountAndReset() {
    let q = CMBufferQueue(capacity: 8, handlers: .unsortedSampleBuffers)
    var countFires = 0
    var token: CMBufferQueueTriggerToken?
    precondition(
        CMBufferQueueInstallTriggerWithIntegerThreshold(
            q,
            callback: { _, _ in countFires += 1 },
            refcon: nil,
            condition: kCMBufferQueueTrigger_WhenBufferCountBecomesGreaterThan,
            threshold: 0,
            triggerTokenOut: &token
        ) == 0
    )
    precondition(token != nil)
    precondition(!CMBufferQueueTestTrigger(q, triggerToken: token!))
    try! q.enqueue(cmQueueTestSample(pts: 1, duration: 1, size: 1))
    precondition(countFires == 1)
    precondition(CMBufferQueueTestTrigger(q, triggerToken: token!))
    var resetFires = 0
    var resetToken: CMBufferQueueTriggerToken?
    precondition(
        CMBufferQueueInstallTriggerHandler(
            q,
            kCMBufferQueueTrigger_WhenReset,
            .invalid,
            &resetToken,
            { _ in resetFires += 1 }
        ) == 0
    )
    precondition(CMBufferQueueReset(q) == 0)
    precondition(resetFires == 1)
    precondition(CMBufferQueueRemoveTrigger(q, triggerToken: token!) == 0)
}

func testCMBufferQueueTriggerDurationHandler() {
    let q = CMBufferQueue(capacity: 8, handlers: .unsortedSampleBuffers)
    var fires = 0
    var token: CMBufferQueueTriggerToken?
    precondition(
        CMBufferQueueInstallTriggerHandlerWithIntegerThreshold(
            q,
            kCMBufferQueueTrigger_WhenBufferCountBecomesGreaterThan,
            1,
            &token,
            { _ in fires += 1 }
        ) == 0
    )
    try! q.enqueue(cmQueueTestSample(pts: 1, duration: 1, size: 1))
    precondition(fires == 0)
    try! q.enqueue(cmQueueTestSample(pts: 2, duration: 1, size: 1))
    precondition(fires == 1)
    var durationToken: CMBufferQueueTriggerToken?
    precondition(
        CMBufferQueueInstallTrigger(
            q,
            callback: { _, _ in },
            refcon: nil,
            condition: kCMBufferQueueTrigger_WhenDurationBecomesGreaterThan,
            time: CMTime(value: 1, timescale: 1),
            triggerTokenOut: &durationToken
        ) == 0
    )
    precondition(durationToken != nil)
    let overlayToken = try! q.installTrigger(condition: .whenEndOfDataReached)
    try! q.markEndOfData()
    _ = CMBufferQueueDequeue(q)
    _ = CMBufferQueueDequeue(q)
    precondition(q.testTrigger(overlayToken) || q.isAtEndOfData)
    try! q.removeTrigger(overlayToken)
}

func testCMBufferQueueCreateWithHandlersFailClosed() {
    var queue: CMBufferQueue?
    let bogus = OpaquePointer(bitPattern: 1)!
    precondition(
        CMBufferQueueCreateWithHandlers(nil, 1, bogus, &queue)
            == kCMBufferQueueError_InvalidCMBufferCallbacksStruct
    )
    precondition(queue == nil)
    let overlay = CMBufferQueue(capacity: 1, handlers: .outputPTSSortedSampleBuffers)
    try! overlay.enqueue(cmQueueTestSample(pts: 5, duration: 1, size: 2))
    precondition(overlay.dequeueIfDataReady() != nil)
}

func testCMBufferQueueSortedCallbacksAndNotReady() {
    let callbacks = CMBufferQueueGetCallbacksForSampleBuffersSortedByOutputPTS()
    var queue: CMBufferQueue?
    precondition(CMBufferQueueCreate(allocator: nil, capacity: 4, callbacks: callbacks, queueOut: &queue) == 0)
    let late = cmQueueTestSample(pts: 20, duration: 1, size: 1)
    let early = cmQueueTestSample(pts: 5, duration: 1, size: 1)
    precondition(CMBufferQueueEnqueue(queue!, buffer: late) == 0)
    precondition(CMBufferQueueEnqueue(queue!, buffer: early) == 0)
    precondition(CMBufferQueueDequeueIfDataReady(queue!) === early)
    let notReady = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [1],
        dataReady: false
    )
    let unsorted = CMBufferQueue(capacity: 2, handlers: .unsortedSampleBuffers)
    try! unsorted.enqueue(notReady)
    precondition(CMBufferQueueDequeueIfDataReadyAndRetain(unsorted) == nil)
    precondition(unsorted.dequeue() === notReady)
}

func testCMBufferQueueErrorAndTriggerConstants() {
    precondition(kCMBufferQueueError_AllocationFailed == -12760)
    precondition(kCMBufferQueueError_RequiredParameterMissing == -12761)
    precondition(kCMBufferQueueError_InvalidCMBufferCallbacksStruct == -12762)
    precondition(kCMBufferQueueError_EnqueueAfterEndOfData == -12763)
    precondition(kCMBufferQueueError_QueueIsFull == -12764)
    precondition(kCMBufferQueueError_BadTriggerDuration == -12765)
    precondition(kCMBufferQueueError_CannotModifyQueueFromTriggerCallback == -12766)
    precondition(kCMBufferQueueError_InvalidTriggerCondition == -12767)
    precondition(kCMBufferQueueError_InvalidTriggerToken == -12768)
    precondition(kCMBufferQueueError_InvalidBuffer == -12769)
    let whenDurationBecomesLessThan: CMBufferQueueTriggerCondition =
        kCMBufferQueueTrigger_WhenDurationBecomesLessThan
    precondition(whenDurationBecomesLessThan == 1)
    precondition(kCMBufferQueueTrigger_WhenDurationBecomesLessThan == 1)
    precondition(kCMBufferQueueTrigger_WhenDurationBecomesLessThanOrEqualTo == 2)
    precondition(kCMBufferQueueTrigger_WhenDurationBecomesGreaterThan == 3)
    precondition(kCMBufferQueueTrigger_WhenDurationBecomesGreaterThanOrEqualTo == 4)
    precondition(kCMBufferQueueTrigger_WhenMinPresentationTimeStampChanges == 5)
    precondition(kCMBufferQueueTrigger_WhenMaxPresentationTimeStampChanges == 6)
    precondition(kCMBufferQueueTrigger_WhenDataBecomesReady == 7)
    precondition(kCMBufferQueueTrigger_WhenEndOfDataReached == 8)
    precondition(kCMBufferQueueTrigger_WhenReset == 9)
    precondition(kCMBufferQueueTrigger_WhenBufferCountBecomesLessThan == 10)
    precondition(kCMBufferQueueTrigger_WhenBufferCountBecomesGreaterThan == 11)
    precondition(
        kCMBufferQueueTrigger_WhenDurationBecomesGreaterThanOrEqualToAndBufferCountBecomesGreaterThan == 12
    )
    precondition(CMBufferQueue.Error.queueIsFull.code == -12764)
    precondition(CMBufferQueue.Error.invalidTriggerToken.code == -12768)
    precondition(CMBufferQueue.Error.allocationFailed.code == -12760)
    precondition(CMBufferQueue.Error.requiredParameterMissing.code == -12761)
    precondition(CMBufferQueue.Error.invalidCMBufferCallbacksStruct.code == -12762)
    precondition(CMBufferQueue.Error.enqueueAfterEndOfData.code == -12763)
    precondition(CMBufferQueue.Error.badTriggerDuration.code == -12765)
    precondition(CMBufferQueue.Error.cannotModifyQueueFromTriggerCallback.code == -12766)
    precondition(CMBufferQueue.Error.invalidTriggerCondition.code == -12767)
    precondition(CMBufferQueue.Error.invalidBuffer.code == -12769)
}

func testCMBufferQueueCapacityAndOverlayReset() {
    let q = CMBufferQueue(capacity: 1, handlers: .unsortedSampleBuffers)
    try! q.enqueue(cmQueueTestSample(pts: 1, duration: 1, size: 1))
    do {
        try q.enqueue(cmQueueTestSample(pts: 2, duration: 1, size: 1))
        preconditionFailure("full queue must fail")
    } catch {
        precondition((error as NSError).code == Int(kCMBufferQueueError_QueueIsFull))
    }
    var seen = 0
    try! q.reset { _ in seen += 1 }
    precondition(seen == 1)
    precondition(q.isEmpty)
    let copy = CMBufferQueue(referencing: q)
    precondition(copy.isEmpty)
    _ = q.buffers.makeIterator()
}

func testCMBufferQueueHandlersBuilder() {
    let handlers = CMBufferQueue.Handlers { builder in
        builder.getDuration { _ in CMTime(value: 1, timescale: 1) }
        builder.getPresentationTimeStamp { _ in CMTime(value: 2, timescale: 1) }
        builder.getDecodeTimeStamp { _ in CMTime(value: 3, timescale: 1) }
        builder.isDataReady { _ in true }
        builder.getSize { _ in 4 }
        builder.compare { _, _ in .compareEqualTo }
    }
    precondition(handlers.getDuration(cmQueueTestSample(pts: 0, duration: 1, size: 1)).value == 1)
    precondition(handlers.getSize?(cmQueueTestSample(pts: 0, duration: 1, size: 1)) == 4)
    let queue = CMBufferQueue(capacity: 1, handlers: handlers)
    try! queue.enqueue(cmQueueTestSample(pts: 0, duration: 1, size: 1))
    precondition(queue.duration.value == 1)
}

private func cmQueueTestSample(pts: Int64, duration: Int64, size: Int, dts: Int64? = nil) -> CMSampleBuffer {
    let timing = CMSampleTimingInfo(
        duration: CMTime(value: duration, timescale: 1),
        presentationTimeStamp: CMTime(value: pts, timescale: 1),
        decodeTimeStamp: dts.map { CMTime(value: $0, timescale: 1) } ?? .invalid
    )
    return try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data(repeating: 1, count: size)),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [timing],
        sampleSizes: [size],
        dataReady: true
    )
}
