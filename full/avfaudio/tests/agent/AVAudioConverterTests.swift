import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVAudioConverterPCM() {
    let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 2,
        interleaved: false
    )!
    let intFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 44100,
        channels: 2,
        interleaved: false
    )!
    let mono = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 22050,
        channels: 1,
        interleaved: false
    )!
    guard let converter = AVAudioConverter(from: format, to: intFormat) else {
        preconditionFailure("converter")
    }
    _ = AVAudioConverter(fromFormat: format, toFormat: intFormat)
    converter.bitRate = 128_000
    converter.bitRateStrategy = AVAudioBitRateStrategy_Constant
    converter.sampleRateConverterQuality = AVAudioQuality.medium.rawValue
    converter.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_Normal
    converter.channelMap = [0, 1]
    converter.dither = true
    converter.downmix = false
    converter.primeMethod = .none
    converter.primeInfo = AVAudioConverterPrimeInfo(leadingFrames: 0, trailingFrames: 0)
    converter.contentSource = .unspecified
    converter.dynamicRangeControlConfiguration = .none
    converter.audioSyncPacketFrequency = 0
    converter.magicCookie = Data()
    precondition(converter.inputFormat === format)
    precondition(converter.outputFormat === intFormat)
    precondition(converter.applicableEncodeBitRates == nil)
    precondition(converter.applicableEncodeSampleRates == nil)
    precondition(converter.availableEncodeBitRates == nil)
    precondition(converter.availableEncodeSampleRates == nil)
    precondition(converter.availableEncodeChannelLayoutTags == nil)
    precondition(converter.maximumOutputPacketSize == 0)
    guard
        let src = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4),
        let dst = AVAudioPCMBuffer(pcmFormat: intFormat, frameCapacity: 4)
    else {
        preconditionFailure("convert buffers")
    }
    src.frameLength = 4
    src.floatChannelData?[0][0] = 0.5
    do {
        try converter.convert(to: dst, from: src)
    } catch {
        preconditionFailure("convert: \(error)")
    }
    precondition(dst.frameLength == 4)
    precondition((dst.int16ChannelData?[0][0] ?? 0) > 14000)
    converter.reset()
    guard let rateConverter = AVAudioConverter(from: format, to: mono) else {
        preconditionFailure("rate converter")
    }
    rateConverter.downmix = true
    guard
        let rateSrc = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8),
        let rateDst = AVAudioPCMBuffer(pcmFormat: mono, frameCapacity: 8)
    else {
        preconditionFailure("rate buffers")
    }
    rateSrc.frameLength = 8
    for frame in 0..<8 {
        rateSrc.floatChannelData?[0][frame] = 0.4
        rateSrc.floatChannelData?[1][frame] = 0.4
    }
    do { try rateConverter.convert(to: rateDst, from: rateSrc) } catch {
        preconditionFailure("rate convert: \(error)")
    }
    precondition(rateDst.frameLength == 4)
    var blockError: NSError?
    let status = converter.convert(to: dst, error: &blockError) { _, inputStatus in
        inputStatus.pointee = .haveData
        return src
    }
    precondition(status == .haveData || status == .error)
}

