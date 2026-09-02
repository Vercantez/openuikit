import CoreAudioTypes
import CoreFoundation
import CoreMedia
import CoreVideo
import Foundation

/// Integration-build probe: import every declared dependency and pass genuine
/// values through public CoreMedia APIs. The isolated host gate does not compile
/// this file.

func coreMediaDependencyIdentityProbe() {
    let time = CMTime(value: 1, timescale: 600)
    _ = CMTimeCopyDescription(allocator: kCFAllocatorDefault, time: time)
    _ = CMTimeCopyAsDictionary(time, allocator: kCFAllocatorDefault)

    let data = Data([0x00, 0x01, 0x02, 0x03])
    let buffer = CMBlockBuffer(data: data)
    _ = try? buffer.dataBytes()

    let error = CMSampleBuffer.Error.invalidated
    _ = error.domain
    _ = error.code
    _ = NSOSStatusErrorDomain

#if canImport(CoreAudioTypes)
    var asbd = AudioStreamBasicDescription()
    asbd.mSampleRate = 48_000
    asbd.mFormatID = kCMAudioCodecType_AAC_LCProtected
    asbd.mChannelsPerFrame = 2
    asbd.mBitsPerChannel = 0
    if let description = try? CMFormatDescription(
        audioStreamBasicDescription: asbd,
        layoutSize: 0,
        layout: nil,
        magicCookie: nil,
        extensions: nil
    ) {
        _ = description.audioStreamBasicDescription
        _ = description.mediaSubType
    }
#endif

#if canImport(CoreVideo)
    // CV pixel/image buffers are supplied by the real CoreVideo module. Until a
    // buffer exists, format matching fails closed rather than synthesizing one.
    if let description = try? CMFormatDescription(
        videoCodecType: .h264,
        width: 16,
        height: 16,
        extensions: nil
    ) {
        _ = description.dimensions
    }
#endif
}
