import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

func testAVFAudioConstants() {
    precondition(AVAudioBitRateStrategy_Constant.contains("Constant"))
    precondition(AVAudioBitRateStrategy_LongTermAverage.contains("LongTerm"))
    precondition(AVAudioBitRateStrategy_Variable.contains("Variable"))
    precondition(AVAudioBitRateStrategy_VariableConstrained.contains("Constrained"))
    precondition(AVAudioFileTypeKey == "AVAudioFileTypeKey")
    _ = AVAudioSessionInterruptionOptionKey
    _ = AVAudioSessionInterruptionReasonKey
    _ = AVAudioSessionInterruptionTypeKey
    _ = AVAudioSessionInterruptionWasSuspendedKey
    _ = AVAudioSessionMicrophoneInjectionIsAvailableKey
    _ = AVAudioSessionRenderingModeNewRenderingModeKey
    _ = AVAudioSessionRouteChangePreviousRouteKey
    _ = AVAudioSessionRouteChangeReasonKey
    _ = AVAudioSessionSilenceSecondaryAudioHintTypeKey
    _ = AVAudioSessionSpatialAudioEnabledKey
    _ = AVAudioUnitManufacturerNameApple
    _ = AVAudioUnitTypeEffect
    _ = AVAudioUnitTypeFormatConverter
    _ = AVAudioUnitTypeGenerator
    _ = AVAudioUnitTypeMIDIProcessor
    _ = AVAudioUnitTypeMixer
    _ = AVAudioUnitTypeMusicDevice
    _ = AVAudioUnitTypeMusicEffect
    _ = AVAudioUnitTypeOfflineEffect
    _ = AVAudioUnitTypeOutput
    _ = AVAudioUnitTypePanner
    _ = AVChannelLayoutKey
    _ = AVEncoderASPFrequencyKey
    _ = AVEncoderAudioQualityForVBRKey
    _ = AVEncoderAudioQualityKey
    _ = AVEncoderBitDepthHintKey
    _ = AVEncoderBitRateKey
    _ = AVEncoderBitRatePerChannelKey
    _ = AVEncoderBitRateStrategyKey
    _ = AVEncoderContentSourceKey
    _ = AVEncoderDynamicRangeControlConfigurationKey
    _ = AVFormatIDKey
    _ = AVLinearPCMBitDepthKey
    _ = AVLinearPCMIsBigEndianKey
    _ = AVLinearPCMIsFloatKey
    _ = AVLinearPCMIsNonInterleaved
    _ = AVNumberOfChannelsKey
    _ = AVSampleRateConverterAlgorithmKey
    _ = AVSampleRateConverterAlgorithm_Mastering
    _ = AVSampleRateConverterAlgorithm_MinimumPhase
    _ = AVSampleRateConverterAlgorithm_Normal
    _ = AVSampleRateConverterAudioQualityKey
    _ = AVSampleRateKey
    _ = AVSpeechSynthesisIPANotationAttribute
    _ = AVSpeechSynthesisVoiceIdentifierAlex
    precondition(AVSpeechUtteranceMinimumSpeechRate == 0)
    precondition(AVSpeechUtteranceMaximumSpeechRate == 1)
    precondition(AVSpeechUtteranceDefaultSpeechRate == 0.5)
    precondition(AVMusicTimeStampEndOfTrack == Double(Int64.max))
    precondition(
        Notification.Name.AVAudioEngineConfigurationChange.rawValue
            == "AVAudioEngineConfigurationChangeNotification"
    )
}

func testAVFAudioTypealiases() {
    precondition(MemoryLayout<AVAudioChannelCount>.size == MemoryLayout<UInt32>.size)
    precondition(MemoryLayout<AVAudioFrameCount>.size == MemoryLayout<UInt32>.size)
    precondition(MemoryLayout<AVAudioFramePosition>.size == MemoryLayout<Int64>.size)
    precondition(MemoryLayout<AVAudioPacketCount>.size == MemoryLayout<UInt32>.size)
    precondition(MemoryLayout<AVAudioNodeBus>.size == MemoryLayout<Int>.size)
    precondition(MemoryLayout<AVMusicTimeStamp>.size == MemoryLayout<Double>.size)
    let point: AVAudio3DVector = AVAudio3DPoint(x: 0, y: 1, z: 0)
    precondition(point.y == 1)
    let range: AVBeatRange = AVMakeBeatRange(1, 4)
    precondition(range.start == 1 && range.length == 4)
    let empty = AVAudioBeatRange()
    precondition(empty.length == 0)
    let _: AVAudioNodeCompletionHandler = {}
    let _: AVAudioNodeTapBlock = { _, _ in }
    let _: AVAudioPlayerNodeCompletionHandler = { _ in }
    let _: AVAudioConverterInputBlock = { _, status in
        status.pointee = .endOfStream
        return nil
    }
    let _: AVAudioSequencerUserCallback = { _, _, _ in }
    let _: AVMIDIPlayerCompletionHandler = {}
    let _: AVMusicEventEnumerationBlock = { _, _, stop in
        stop.pointee = true
    }
    let _: AVSpeechSynthesizer.BufferCallback = { _ in }
    let _: AVSpeechSynthesizer.MarkerCallback = { _ in }
    let _: AVSpeechSynthesisProviderOutputBlock = { _, _ in }
}

