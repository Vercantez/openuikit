import CoreFoundation
import CoreMedia
import Foundation

private func cmRecoveredSample(pts: Int64, size: Int) -> CMSampleBuffer {
    let timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 1),
        presentationTimeStamp: CMTime(value: pts, timescale: 1),
        decodeTimeStamp: .invalid
    )
    return try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data(repeating: 3, count: size)),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [timing],
        sampleSizes: [size],
        dataReady: true
    )
}

func testCMRecoveredMediaConstants() {
    let aux: CMMediaType = kCMMediaType_AuxiliaryPicture
    precondition(aux == 0x61757876)
    precondition((CMImageDescriptionFlavor.mobile3GPFamily.rawValue as String) == "3GPFamily")
    precondition((CMImageDescriptionFlavor.isoFamily.rawValue as String) == "ISOFamily")
    precondition(
        (CMImageDescriptionFlavor.isoFamilyWithAppleExtensions.rawValue as String)
            == "ISOFamilyWithAppleExtensions"
    )
    precondition((CMImageDescriptionFlavor.quickTimeMovie.rawValue as String) == "QuickTimeMovie")
    precondition((CMSoundDescriptionFlavor.mobile3GPFamily.rawValue as String) == "3GPFamily")
    precondition((CMSoundDescriptionFlavor.isoFamily.rawValue as String) == "ISOFamily")
    precondition((CMSoundDescriptionFlavor.quickTimeMovie.rawValue as String) == "QuickTimeMovie")
    precondition((CMSoundDescriptionFlavor.quickTimeMovieV2.rawValue as String) == "QuickTimeMovieV2")
    precondition(CMImageDescriptionFlavor.mobile3GPFamily == CMImageDescriptionFlavor.mobile3GPFamily)
    precondition(CMSoundDescriptionFlavor.quickTimeMovie != CMSoundDescriptionFlavor.quickTimeMovieV2)
    let halfEqui = kCMTagProjectionTypeHalfEquirectangular
    precondition(halfEqui.rawCategory == 0x70726F6A)
    precondition(halfEqui.rawTagValue == .osType(0x68657175))
    let q = CMBufferQueue(capacity: 4, handlers: .unsortedSampleBuffers)
    let accept: CMBufferValidationCallback = { _, _, _ in 0 }
    precondition(CMBufferQueueSetValidationCallback(q, callback: accept, refcon: nil) == 0)
    let acceptHandler: CMBufferValidationHandler = { _, _ in 0 }
    precondition(CMBufferQueueSetValidationHandler(q, acceptHandler) == 0)
    let sample = cmRecoveredSample(pts: 0, size: 2)
    try! q.enqueue(sample)
    precondition(q.bufferCount == 1)
    let reject: CMBufferValidationCallback = { _, _, _ in kCMBufferQueueError_InvalidBuffer }
    precondition(CMBufferQueueSetValidationCallback(q, callback: reject, refcon: nil) == 0)
    precondition(CMBufferQueueEnqueue(q, buffer: sample) == kCMBufferQueueError_InvalidBuffer)
    precondition(q.bufferCount == 1)
    let url = URL(string: "file:///tmp/media.mov")!
    let ref = CMSampleDataReference(containerLocation: url, byteOffset: 128)
    precondition(ref.byteOffset == 128)
    precondition(ref.containerLocation == url)
    precondition(ref == CMSampleDataReference(containerLocation: url, byteOffset: 128))
    precondition(ref != CMSampleDataReference(containerLocation: url, byteOffset: 129))
    var hasher = Hasher()
    ref.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(ref.hashValue == CMSampleDataReference(containerLocation: url, byteOffset: 128).hashValue)
    let fresh = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [
            CMSampleTimingInfo(
                duration: CMTime(value: 1, timescale: 1),
                presentationTimeStamp: .zero,
                decodeTimeStamp: .invalid
            )
        ],
        sampleSizes: [0],
        dataReady: true
    )
    precondition(fresh.dataBuffer == nil)
    fresh.setDataBuffer(CMBlockBuffer(data: Data([1, 2, 3])))
    precondition(fresh.dataBuffer?.dataLength == 3)
    precondition(CMSampleBufferGetDataBuffer(fresh)?.dataLength == 3)
}
