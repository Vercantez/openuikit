import CoreMedia
import Dispatch
import Foundation

func testCMBlockBufferCopyOwnedBytes() {
    let payload = Data([0x10, 0x20, 0x30, 0x40])
    let buffer = CMBlockBuffer(data: payload)
    precondition(CMBlockBufferGetDataLength(buffer) == 4)
    precondition(!CMBlockBufferIsEmpty(buffer))
    let copied = try! buffer.dataBytes()
    precondition(copied == payload)
    var sink = [UInt8](repeating: 0, count: 4)
    sink.withUnsafeMutableBytes { dest in
        try! buffer.copyDataBytes(to: dest)
    }
    precondition(sink == [0x10, 0x20, 0x30, 0x40])
}

func testCMBlockBufferEmptyAndMalformed() {
    let empty = CMBlockBuffer()
    precondition(CMBlockBufferIsEmpty(empty))
    precondition(empty.dataLength == 0)
    let buffer = CMBlockBuffer(data: Data([1, 2, 3]))
    do {
        var dest = [UInt8](repeating: 0, count: 1)
        try dest.withUnsafeMutableBytes { raw in
            try buffer.copyDataBytes(to: raw)
        }
        preconditionFailure("short destination must fail")
    } catch {
        precondition((error as NSError).code == -12708)
    }
    do {
        var dest: UInt8 = 0
        try withUnsafeMutablePointer(to: &dest) { pointer in
            try buffer.copyDataBytes(atOffset: 8, dataLength: 1, destination: pointer)
        }
        preconditionFailure("bad offset must fail")
    } catch {
        precondition((error as NSError).code == -12703)
    }
}

func testCMBlockBufferAliasAndMutationIsolation() {
    let original = CMBlockBuffer(data: Data([9, 8, 7]))
    let alias = original
    precondition(alias.dataLength == 3)
    try! original.withUnsafeMutableBytes { bytes in
        bytes[0] = 1
    }
    let after = try! alias.dataBytes()
    precondition(after.first == 1)
}

func testCMSampleBufferTimingAndDataRead() {
    let format = try! CMFormatDescription(
        videoCodecType: .h264,
        width: 16,
        height: 16,
        extensions: nil
    )
    let data = CMBlockBuffer(data: Data([0x00, 0x00, 0x00, 0x01, 0x67]))
    let timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 30),
        presentationTimeStamp: CMTime(value: 10, timescale: 30),
        decodeTimeStamp: CMTime(value: 8, timescale: 30)
    )
    let sample = try! CMSampleBuffer(
        dataBuffer: data,
        formatDescription: format,
        numSamples: 1,
        sampleTimings: [timing],
        sampleSizes: [5],
        dataReady: true
    )
    precondition(CMSampleBufferIsValid(sample))
    precondition(CMSampleBufferDataIsReady(sample))
    precondition(CMSampleBufferGetNumSamples(sample) == 1)
    precondition(CMSampleBufferGetPresentationTimeStamp(sample) == timing.presentationTimeStamp)
    precondition(CMSampleBufferGetDecodeTimeStamp(sample) == timing.decodeTimeStamp)
    precondition(CMSampleBufferGetDuration(sample) == timing.duration)
    precondition(CMSampleBufferGetTotalSampleSize(sample) == 5)
    precondition(CMSampleBufferGetFormatDescription(sample) === format)
    let bytes = try! sample.copyDataBytes()
    precondition(bytes.count == 5)
    precondition(bytes != Data([0xff, 0xff, 0xff, 0xff, 0xff]))
}

func testCMSampleBufferDoesNotTreatArbitraryBytesAsValidMedia() {
    let garbage = CMBlockBuffer(data: Data((0..<32).map { UInt8($0) }))
    let format = try! CMFormatDescription(
        mediaType: .video,
        mediaSubType: .h264,
        extensions: nil
    )
    let sample = try! CMSampleBuffer(
        dataBuffer: garbage,
        formatDescription: format,
        numSamples: 1,
        sampleTimings: [
            CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        ],
        sampleSizes: [32]
    )
    let payload = try! sample.copyDataBytes()
    precondition(payload.count == 32)
    precondition(sample.formatDescription?.mediaSubType == .h264)
}

func testCMSampleBufferInvalidateCallbackExactlyOnce() {
    let sample = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(),
        formatDescription: nil,
        numSamples: 0,
        sampleTimings: [],
        sampleSizes: []
    )
    var fires = 0
    sample.setInvalidateHandler { _ in fires += 1 }
    sample.invalidate()
    sample.invalidate()
    precondition(fires == 1)
    precondition(!CMSampleBufferIsValid(sample))
    do {
        _ = try sample.copyDataBytes()
        preconditionFailure("invalidated buffer must fail closed")
    } catch {
        precondition((error as NSError).code == -12744)
    }
}

func testCMSampleBufferNotReadyAndMakeReady() {
    let data = CMBlockBuffer(data: Data([1, 2]))
    let sample = try! CMSampleBuffer(
        dataBuffer: data,
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [
            CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 1), presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        ],
        sampleSizes: [2],
        dataReady: false
    )
    precondition(!sample.dataIsReady)
    do {
        _ = try sample.copyDataBytes()
        preconditionFailure("not-ready buffer must fail")
    } catch {
        precondition((error as NSError).code == -12733)
    }
    try! sample.makeDataReady()
    precondition(sample.dataIsReady)
    precondition(try! sample.copyDataBytes().count == 2)
}

func testCMSampleBufferInvalidateBeforeReadyCancels() {
    let sample = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [
            CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        ],
        sampleSizes: [1],
        dataReady: false
    )
    sample.invalidate()
    do {
        try sample.makeDataReady()
        preconditionFailure("invalidated not-ready buffer must not become ready")
    } catch {
        precondition((error as NSError).code == -12744)
    }
}

func testCMSampleBufferConcurrentAccess() {
    let sample = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([7, 7])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [
            CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 1), presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        ],
        sampleSizes: [2]
    )
    let group = DispatchGroup()
    for _ in 0..<8 {
        group.enter()
        DispatchQueue.global().async {
            _ = CMSampleBufferIsValid(sample)
            _ = CMSampleBufferGetPresentationTimeStamp(sample)
            group.leave()
        }
    }
    group.wait()
    sample.invalidate()
    precondition(!sample.isValid)
}

func testCMAttachmentPropagateAndNonPropagate() {
    let source = CMBlockBuffer()
    source.attachments["propagate"] = .shouldPropagate("keep")
    source.attachments["local"] = .shouldNotPropagate("drop")
    let dest = CMBlockBuffer()
    source.propagateAttachments(to: dest)
    precondition(dest.attachments.propagated["propagate"] as? String == "keep")
    precondition(dest.attachments["local"] == nil)
}

func testSampleBufferErrorContracts() {
    precondition(CMSampleBuffer.Error.allocationFailed.code == -12730)
    precondition(CMSampleBuffer.Error.requiredParameterMissing.code == -12731)
    precondition(CMSampleBuffer.Error.invalidated.code == -12744)
    precondition(CMBlockBuffer.Error.structureAllocationFailed.code == -12700)
    precondition(CMFormatDescription.Error.invalidParameter.code == -12710)
    precondition(CMSampleBuffer.Error.invalidated.domain == NSOSStatusErrorDomain)
}

func testCMPersistentTrackIDInvalid() {
    precondition(kCMPersistentTrackID_Invalid == 0)
}
