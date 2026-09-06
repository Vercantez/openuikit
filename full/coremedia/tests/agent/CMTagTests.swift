import CoreFoundation
import CoreMedia
import Foundation

func testCMTagIdentityAndValueCases() {
    let tag = CMTag(rawCategory: cmFourCC("stvw"), rawTagValue: .flags(1))
    precondition(tag.rawCategory == cmFourCC("stvw"))
    if case .flags(let bits) = tag.rawTagValue {
        precondition(bits == 1)
    } else {
        preconditionFailure("expected flags")
    }
    let os = CMTag.Value.osType(kCMPixelFormat_32BGRA)
    let intValue = CMTag.Value.int64(9)
    let floatValue = CMTag.Value.float64(1.5)
    precondition(os != intValue)
    precondition(intValue != floatValue)
    precondition(tag.description.contains("CMTag"))
    let same = CMTag(rawCategory: tag.rawCategory, rawTagValue: tag.rawTagValue)
    precondition(tag == same)
    precondition(tag != CMTag(rawCategory: cmFourCC("pack"), rawTagValue: .flags(1)))
    var hasher = Hasher()
    tag.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCMTagFactoryAndTypedCategories() {
    let stereo = CMTag.stereoView([.leftEye])
    precondition(stereo.typedValue.contains(.leftEye))
    precondition(stereo.value(onlyIfMatching: .stereoView) == stereo.typedValue)
    let packing = CMTag.packingType(.sideBySide)
    precondition(packing.typedValue == .sideBySide)
    let pixel = CMTag.pixelFormat(kCMPixelFormat_32BGRA)
    precondition(pixel.typedValue == kCMPixelFormat_32BGRA)
    let subType = CMTag.mediaSubType(.h264)
    precondition(subType.typedValue == .h264)
    let layer = CMTag.videoLayerID(3)
    precondition(layer.typedValue == 3)
    let projection = CMTag.projectionType(.equirectangular)
    precondition(projection.typedValue == .equirectangular)
    let interpretation = CMTag.stereoViewInterpretation([.additionalViews])
    precondition(interpretation.typedValue.contains(.additionalViews))
    let track = CMTag.trackID(12)
    precondition(track.typedValue == 12)
    let channel = CMTag.channelID(4)
    precondition(channel.typedValue == 4)
    let media = CMTag.mediaType(.video)
    precondition(media.typedValue == .video)
    precondition(CMTypedTag<CMStereoViewComponents>.Category.stereoView.rawCategory == cmFourCC("stvw"))
    precondition(CMTypedTag<CMPackingType>.Category.packingType.rawCategory == cmFourCC("pack"))
    precondition(CMTypedTag<UInt32>.Category.pixelFormat.rawCategory == cmFourCC("pixf"))
    precondition(CMTypedTag<CMFormatDescription.MediaSubType>.Category.mediaSubType.rawCategory == cmFourCC("msub"))
    precondition(CMTypedTag<Int64>.Category.videoLayerID.rawCategory == cmFourCC("vlyr"))
    precondition(CMTypedTag<CMProjectionType>.Category.projectionType.rawCategory == cmFourCC("proj"))
    precondition(
        CMTypedTag<CMStereoViewInterpretationOptions>.Category.stereoViewInterpretation.rawCategory == cmFourCC("svi ")
    )
    precondition(CMTypedTag<CMPersistentTrackID>.Category.trackID.rawCategory == cmFourCC("trak"))
    precondition(CMTypedTag<Int64>.Category.channelID.rawCategory == cmFourCC("chnl"))
    precondition(CMTypedTag<CMFormatDescription.MediaType>.Category.mediaType.rawCategory == cmFourCC("mdia"))
}

func testCMTagSequenceMatchingAndTaggedBuffer() {
    let stereo = CMTag.stereoView([.rightEye])
    let packing = CMTag.packingType(.overUnder)
    let tags: [CMTag] = [stereo, packing]
    precondition(tags.first(matchingCategory: .stereoView)?.typedValue.contains(.rightEye) == true)
    precondition(tags.firstValue(matchingCategory: .packingType) == .overUnder)
    let filtered = tags.filter(matchingCategory: .stereoView)
    precondition(filtered.count == 1)
    let sample = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1, 2])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [2],
        dataReady: true
    )
    let tagged = CMTaggedBuffer(tags: tags, sampleBuffer: sample)
    precondition(tagged.tags.count == 2)
    if case .sampleBuffer(let stored) = tagged.buffer {
        precondition(stored === sample)
    } else {
        preconditionFailure("expected sample buffer")
    }
    let wrapped = CMTaggedBuffer(tags: tags, buffer: .sampleBuffer(sample))
    precondition(wrapped.description.contains("CMTaggedBuffer"))
}

private func cmFourCC(_ literal: String) -> UInt32 {
    let bytes = Array(literal.utf8)
    return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
}
