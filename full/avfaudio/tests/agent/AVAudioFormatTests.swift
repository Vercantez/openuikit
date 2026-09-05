import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVAudioFormatInits() {
    guard let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 2,
        interleaved: false
    ) else {
        preconditionFailure("common format")
    }
    precondition(format.sampleRate == 44100)
    precondition(format.channelCount == 2)
    precondition(format.commonFormat == .pcmFormatFloat32)
    precondition(format.isInterleaved == false)
    precondition(format.isStandard)
    precondition(format.settings[AVSampleRateKey] as? Double == 44100)
    precondition((format.settings[AVFormatIDKey] as? NSNumber)?.uint32Value == 1_819_304_813)
    precondition(format.settings[AVLinearPCMIsBigEndianKey] as? Bool == false)
    precondition(format.settings[AVLinearPCMIsNonInterleaved] as? Bool == true)
    precondition(format.settings[AVLinearPCMBitDepthKey] as? Int == 32)
    guard let standard = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1) else {
        preconditionFailure("standard format")
    }
    precondition(standard.channelCount == 1)
    guard let fromSettings = AVAudioFormat(settings: [
        AVSampleRateKey: 22050,
        AVNumberOfChannelsKey: 2,
        AVLinearPCMIsFloatKey: true,
        AVLinearPCMIsNonInterleaved: true,
        AVLinearPCMBitDepthKey: 32,
    ]) else {
        preconditionFailure("settings format")
    }
    precondition(fromSettings.sampleRate == 22050)
    format.magicCookie = Data([1, 2, 3])
    precondition(format.magicCookie == Data([1, 2, 3]))
    let layout = AVAudioChannelLayout(layoutTag: 0x650002)
    precondition(layout?.channelCount == 2)
    precondition(layout?.layoutTag == 0x650002)
    precondition(layout!.isEqual(layout))
    let layoutFormat = AVAudioFormat(
        standardFormatWithSampleRate: 48000,
        channelLayout: layout!
    )
    precondition(layoutFormat.channelCount == 2)
    precondition(layoutFormat.channelLayout?.layoutTag == 0x650002)
    precondition((layoutFormat.settings[AVChannelLayoutKey] as? NSNumber)?.uint32Value == 0x650002)
    let commonLayout = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 44100,
        interleaved: true,
        channelLayout: layout!
    )
    precondition(commonLayout.isInterleaved)
    precondition(format.isEqual(format))
}

