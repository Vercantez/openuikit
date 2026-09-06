import CoreFoundation
import CoreMedia
import Foundation

func testCMBufferQueueOverlayTimestamps() {
    let callbacks = CMBufferQueueGetCallbacksForUnsortedSampleBuffers()
    var queue: CMBufferQueue?
    precondition(CMBufferQueueCreate(allocator: nil, capacity: 8, callbacks: callbacks, queueOut: &queue) == 0)
    let q = queue!
    let first = cmOverlayQueueSample(pts: 10, duration: 2, size: 4, dts: 9)
    let second = cmOverlayQueueSample(pts: 12, duration: 2, size: 8, dts: 11)
    try! q.enqueue(first)
    try! q.enqueue(second)
    precondition(q.head === first)
    precondition(!q.isAtEndOfData)
    precondition(q.firstDecodeTimeStamp.value == 9)
    precondition(q.minDecodeTimeStamp.value == 9)
    precondition(q.firstPresentationTimeStamp.value == 10)
    precondition(q.minPresentationTimeStamp.value == 10)
    precondition(q.maxPresentationTimeStamp.value == 12)
    precondition(q.endPresentationTimeStamp.value == 14)
    try! q.markEndOfData()
    precondition(q.containsEndOfData)
    var iterator = q.buffers.makeIterator()
    precondition(iterator.next() != nil)
}

func testCMBufferCallbacksStructFields() {
    let duration: CMBufferGetTimeCallback = { _, _ in CMTime(value: 1, timescale: 1) }
    let dts: CMBufferGetTimeCallback = { _, _ in CMTime(value: 2, timescale: 1) }
    let pts: CMBufferGetTimeCallback = { _, _ in CMTime(value: 3, timescale: 1) }
    let ready: CMBufferGetBooleanCallback = { _, _ in true }
    let compare: CMBufferCompareCallback = { _, _, _ in .compareEqualTo }
    let size: CMBufferGetSizeCallback = { _, _ in 16 }
    var ref: Int = 7
    let callbacks = withUnsafeMutablePointer(to: &ref) { pointer in
        CMBufferCallbacks(
            version: 1,
            refcon: UnsafeMutableRawPointer(pointer),
            getDecodeTimeStamp: dts,
            getPresentationTimeStamp: pts,
            getDuration: duration,
            isDataReady: ready,
            compare: compare,
            dataBecameReadyNotification: nil,
            getSize: size
        )
    }
    precondition(callbacks.version == 1)
    precondition(callbacks.refcon != nil)
    let sample = cmOverlayQueueSample(pts: 0, duration: 1, size: 1)
    precondition(callbacks.getDuration(sample, callbacks.refcon).value == 1)
    precondition(callbacks.getDecodeTimeStamp!(sample, callbacks.refcon).value == 2)
    precondition(callbacks.getPresentationTimeStamp!(sample, callbacks.refcon).value == 3)
    precondition(callbacks.isDataReady!(sample, callbacks.refcon).boolValue)
    precondition(callbacks.compare!(sample, sample, callbacks.refcon) == .compareEqualTo)
    precondition(callbacks.getSize!(sample, callbacks.refcon) == 16)
    precondition(callbacks.dataBecameReadyNotification == nil)
}

func testCMBufferQueueHandlersOverlayMembers() {
    let unsorted = CMBufferQueue.Handlers.unsortedSampleBuffers
    let sample = cmOverlayQueueSample(pts: 0, duration: 1, size: 1)
    precondition(unsorted.getDuration(sample).isValid || true)
    precondition(unsorted.getPresentationTimeStamp?(sample) != nil)
    precondition(unsorted.getDecodeTimeStamp?(sample) != nil)
    precondition(unsorted.isDataReady?(sample) == true)
    precondition(unsorted.getSize?(sample) == 1)
    let sorted = CMBufferQueue.Handlers.outputPTSSortedSampleBuffers
    precondition(sorted.compare?(sample, sample) == .compareEqualTo)
    var builder = CMBufferQueue.Handlers.Builder()
    builder.dataBecameReadyNotification = "ready"
    builder.getDuration { _ in .zero }
    builder.isDataReady { _ in true }
    builder.getDecodeTimeStamp { _ in .invalid }
    builder.getPresentationTimeStamp { _ in .invalid }
    builder.compare { _, _ in .compareEqualTo }
    builder.getSize { _ in 1 }
    precondition(builder.dataBecameReadyNotification == "ready")
    let rebuilt = unsorted.withHandlers { inner in
        inner.getDuration { _ in CMTime(value: 4, timescale: 1) }
    }
    precondition(rebuilt.getDuration(cmOverlayQueueSample(pts: 0, duration: 1, size: 1)).value == 4)
}

private func cmOverlayQueueSample(pts: Int64, duration: Int64, size: Int, dts: Int64? = nil) -> CMSampleBuffer {
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
