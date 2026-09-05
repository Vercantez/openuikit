import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif


func testAVFAudioEnumCases() {
    // Table-driven: every public enum type and case is named.
    _ = AVAudio3DMixingPointSourceInHeadMode.self
    _ = AVAudio3DMixingPointSourceInHeadMode.bypass
    _ = AVAudio3DMixingPointSourceInHeadMode.mono
    precondition(AVAudio3DMixingPointSourceInHeadMode.bypass != AVAudio3DMixingPointSourceInHeadMode.mono)
    _ = AVAudio3DMixingRenderingAlgorithm.self
    _ = AVAudio3DMixingRenderingAlgorithm.auto
    _ = AVAudio3DMixingRenderingAlgorithm.equalPowerPanning
    _ = AVAudio3DMixingRenderingAlgorithm.HRTF
    _ = AVAudio3DMixingRenderingAlgorithm.HRTFHQ
    _ = AVAudio3DMixingRenderingAlgorithm.soundField
    _ = AVAudio3DMixingRenderingAlgorithm.sphericalHead
    _ = AVAudio3DMixingRenderingAlgorithm.stereoPassThrough
    precondition(AVAudio3DMixingRenderingAlgorithm.auto != AVAudio3DMixingRenderingAlgorithm.equalPowerPanning)
    _ = AVAudio3DMixingSourceMode.self
    _ = AVAudio3DMixingSourceMode.ambienceBed
    _ = AVAudio3DMixingSourceMode.bypass
    _ = AVAudio3DMixingSourceMode.pointSource
    _ = AVAudio3DMixingSourceMode.spatializeIfMono
    precondition(AVAudio3DMixingSourceMode.ambienceBed != AVAudio3DMixingSourceMode.bypass)
    _ = AVAudioApplication.MicrophoneInjectionPermission.self
    _ = AVAudioApplication.MicrophoneInjectionPermission.denied
    _ = AVAudioApplication.MicrophoneInjectionPermission.granted
    _ = AVAudioApplication.MicrophoneInjectionPermission.serviceDisabled
    _ = AVAudioApplication.MicrophoneInjectionPermission.undetermined
    precondition(AVAudioApplication.MicrophoneInjectionPermission.denied != AVAudioApplication.MicrophoneInjectionPermission.granted)
    _ = AVAudioApplication.recordPermission.self
    _ = AVAudioApplication.recordPermission.denied
    _ = AVAudioApplication.recordPermission.granted
    _ = AVAudioApplication.recordPermission.undetermined
    precondition(AVAudioApplication.recordPermission.denied != AVAudioApplication.recordPermission.granted)
    _ = AVAudioCommonFormat.self
    _ = AVAudioCommonFormat.otherFormat
    _ = AVAudioCommonFormat.pcmFormatFloat32
    _ = AVAudioCommonFormat.pcmFormatFloat64
    _ = AVAudioCommonFormat.pcmFormatInt16
    _ = AVAudioCommonFormat.pcmFormatInt32
    precondition(AVAudioCommonFormat.otherFormat != AVAudioCommonFormat.pcmFormatFloat32)
    _ = AVAudioContentSource.self
    _ = AVAudioContentSource.av_Spatial_Live
    _ = AVAudioContentSource.av_Spatial_Offline
    _ = AVAudioContentSource.av_Traditional_Live
    _ = AVAudioContentSource.av_Traditional_Offline
    _ = AVAudioContentSource.appleAV_Spatial_Live
    _ = AVAudioContentSource.appleAV_Spatial_Offline
    _ = AVAudioContentSource.appleAV_Traditional_Live
    _ = AVAudioContentSource.appleAV_Traditional_Offline
    _ = AVAudioContentSource.appleCapture_Spatial
    _ = AVAudioContentSource.appleCapture_Spatial_Enhanced
    _ = AVAudioContentSource.appleCapture_Traditional
    _ = AVAudioContentSource.appleMusic_Spatial
    _ = AVAudioContentSource.appleMusic_Traditional
    _ = AVAudioContentSource.applePassthrough
    _ = AVAudioContentSource.capture_Spatial
    _ = AVAudioContentSource.capture_Spatial_Enhanced
    _ = AVAudioContentSource.capture_Traditional
    _ = AVAudioContentSource.music_Spatial
    _ = AVAudioContentSource.music_Traditional
    _ = AVAudioContentSource.passthrough
    _ = AVAudioContentSource.reserved
    _ = AVAudioContentSource.unspecified
    precondition(AVAudioContentSource.av_Spatial_Live != AVAudioContentSource.av_Spatial_Offline)
    _ = AVAudioConverterInputStatus.self
    _ = AVAudioConverterInputStatus.endOfStream
    _ = AVAudioConverterInputStatus.haveData
    _ = AVAudioConverterInputStatus.noDataNow
    precondition(AVAudioConverterInputStatus.endOfStream != AVAudioConverterInputStatus.haveData)
    _ = AVAudioConverterOutputStatus.self
    _ = AVAudioConverterOutputStatus.endOfStream
    _ = AVAudioConverterOutputStatus.error
    _ = AVAudioConverterOutputStatus.haveData
    _ = AVAudioConverterOutputStatus.inputRanDry
    precondition(AVAudioConverterOutputStatus.endOfStream != AVAudioConverterOutputStatus.error)
    _ = AVAudioConverterPrimeMethod.self
    _ = AVAudioConverterPrimeMethod.none
    _ = AVAudioConverterPrimeMethod.normal
    _ = AVAudioConverterPrimeMethod.pre
    precondition(AVAudioConverterPrimeMethod.none != AVAudioConverterPrimeMethod.normal)
    _ = AVAudioDynamicRangeControlConfiguration.self
    _ = AVAudioDynamicRangeControlConfiguration.capture
    _ = AVAudioDynamicRangeControlConfiguration.movie
    _ = AVAudioDynamicRangeControlConfiguration.music
    _ = AVAudioDynamicRangeControlConfiguration.none
    _ = AVAudioDynamicRangeControlConfiguration.speech
    precondition(AVAudioDynamicRangeControlConfiguration.capture != AVAudioDynamicRangeControlConfiguration.movie)
    _ = AVAudioEngineManualRenderingError.self
    _ = AVAudioEngineManualRenderingError.initialized
    _ = AVAudioEngineManualRenderingError.invalidMode
    _ = AVAudioEngineManualRenderingError.notRunning
    precondition(AVAudioEngineManualRenderingError.initialized != AVAudioEngineManualRenderingError.invalidMode)
    _ = AVAudioEngineManualRenderingMode.self
    _ = AVAudioEngineManualRenderingMode.offline
    _ = AVAudioEngineManualRenderingMode.realtime
    precondition(AVAudioEngineManualRenderingMode.offline != AVAudioEngineManualRenderingMode.realtime)
    _ = AVAudioEngineManualRenderingStatus.self
    _ = AVAudioEngineManualRenderingStatus.cannotDoInCurrentContext
    _ = AVAudioEngineManualRenderingStatus.error
    _ = AVAudioEngineManualRenderingStatus.insufficientDataFromInputNode
    _ = AVAudioEngineManualRenderingStatus.success
    precondition(AVAudioEngineManualRenderingStatus.cannotDoInCurrentContext != AVAudioEngineManualRenderingStatus.error)
    _ = AVAudioEnvironmentDistanceAttenuationModel.self
    _ = AVAudioEnvironmentDistanceAttenuationModel.exponential
    _ = AVAudioEnvironmentDistanceAttenuationModel.inverse
    _ = AVAudioEnvironmentDistanceAttenuationModel.linear
    precondition(AVAudioEnvironmentDistanceAttenuationModel.exponential != AVAudioEnvironmentDistanceAttenuationModel.inverse)
    _ = AVAudioEnvironmentOutputType.self
    _ = AVAudioEnvironmentOutputType.auto
    _ = AVAudioEnvironmentOutputType.builtInSpeakers
    _ = AVAudioEnvironmentOutputType.externalSpeakers
    _ = AVAudioEnvironmentOutputType.headphones
    precondition(AVAudioEnvironmentOutputType.auto != AVAudioEnvironmentOutputType.builtInSpeakers)
    _ = AVAudioPlayerNodeCompletionCallbackType.self
    _ = AVAudioPlayerNodeCompletionCallbackType.dataConsumed
    _ = AVAudioPlayerNodeCompletionCallbackType.dataPlayedBack
    _ = AVAudioPlayerNodeCompletionCallbackType.dataRendered
    precondition(AVAudioPlayerNodeCompletionCallbackType.dataConsumed != AVAudioPlayerNodeCompletionCallbackType.dataPlayedBack)
    _ = AVAudioQuality.self
    _ = AVAudioQuality.high
    _ = AVAudioQuality.low
    _ = AVAudioQuality.max
    _ = AVAudioQuality.medium
    _ = AVAudioQuality.min
    precondition(AVAudioQuality.high != AVAudioQuality.low)
    _ = AVAudioSession.IOType.self
    _ = AVAudioSession.IOType.aggregated
    _ = AVAudioSession.IOType.notSpecified
    precondition(AVAudioSession.IOType.aggregated != AVAudioSession.IOType.notSpecified)
    _ = AVAudioSession.InterruptionReason.self
    _ = AVAudioSession.InterruptionReason.appWasSuspended
    _ = AVAudioSession.InterruptionReason.builtInMicMuted
    _ = AVAudioSession.InterruptionReason.`default`
    _ = AVAudioSession.InterruptionReason.routeDisconnected
    precondition(AVAudioSession.InterruptionReason.appWasSuspended != AVAudioSession.InterruptionReason.builtInMicMuted)
    _ = AVAudioSession.InterruptionType.self
    _ = AVAudioSession.InterruptionType.began
    _ = AVAudioSession.InterruptionType.ended
    precondition(AVAudioSession.InterruptionType.began != AVAudioSession.InterruptionType.ended)
    _ = AVAudioSession.MicrophoneInjectionMode.self
    _ = AVAudioSession.MicrophoneInjectionMode.none
    _ = AVAudioSession.MicrophoneInjectionMode.spokenAudio
    precondition(AVAudioSession.MicrophoneInjectionMode.none != AVAudioSession.MicrophoneInjectionMode.spokenAudio)
    _ = AVAudioSession.PortOverride.self
    _ = AVAudioSession.PortOverride.none
    _ = AVAudioSession.PortOverride.speaker
    precondition(AVAudioSession.PortOverride.none != AVAudioSession.PortOverride.speaker)
    _ = AVAudioSession.PromptStyle.self
    _ = AVAudioSession.PromptStyle.none
    _ = AVAudioSession.PromptStyle.normal
    _ = AVAudioSession.PromptStyle.short
    precondition(AVAudioSession.PromptStyle.none != AVAudioSession.PromptStyle.normal)
    _ = AVAudioSession.RecordPermission.self
    _ = AVAudioSession.RecordPermission.denied
    _ = AVAudioSession.RecordPermission.granted
    _ = AVAudioSession.RecordPermission.undetermined
    precondition(AVAudioSession.RecordPermission.denied != AVAudioSession.RecordPermission.granted)
    _ = AVAudioSession.RenderingMode.self
    _ = AVAudioSession.RenderingMode.dolbyAtmos
    _ = AVAudioSession.RenderingMode.dolbyAudio
    _ = AVAudioSession.RenderingMode.monoStereo
    _ = AVAudioSession.RenderingMode.notApplicable
    _ = AVAudioSession.RenderingMode.spatialAudio
    _ = AVAudioSession.RenderingMode.surround
    precondition(AVAudioSession.RenderingMode.dolbyAtmos != AVAudioSession.RenderingMode.dolbyAudio)
    _ = AVAudioSession.RouteChangeReason.self
    _ = AVAudioSession.RouteChangeReason.categoryChange
    _ = AVAudioSession.RouteChangeReason.newDeviceAvailable
    _ = AVAudioSession.RouteChangeReason.noSuitableRouteForCategory
    _ = AVAudioSession.RouteChangeReason.oldDeviceUnavailable
    _ = AVAudioSession.RouteChangeReason.override
    _ = AVAudioSession.RouteChangeReason.routeConfigurationChange
    _ = AVAudioSession.RouteChangeReason.unknown
    _ = AVAudioSession.RouteChangeReason.wakeFromSleep
    precondition(AVAudioSession.RouteChangeReason.categoryChange != AVAudioSession.RouteChangeReason.newDeviceAvailable)
    _ = AVAudioSession.RouteSharingPolicy.self
    _ = AVAudioSession.RouteSharingPolicy.`default`
    _ = AVAudioSession.RouteSharingPolicy.independent
    _ = AVAudioSession.RouteSharingPolicy.longFormAudio
    _ = AVAudioSession.RouteSharingPolicy.longFormVideo
    precondition(AVAudioSession.RouteSharingPolicy.`default` != AVAudioSession.RouteSharingPolicy.independent)
    _ = AVAudioSession.SilenceSecondaryAudioHintType.self
    _ = AVAudioSession.SilenceSecondaryAudioHintType.begin
    _ = AVAudioSession.SilenceSecondaryAudioHintType.end
    precondition(AVAudioSession.SilenceSecondaryAudioHintType.begin != AVAudioSession.SilenceSecondaryAudioHintType.end)
    _ = AVAudioSession.StereoOrientation.self
    _ = AVAudioSession.StereoOrientation.landscapeLeft
    _ = AVAudioSession.StereoOrientation.landscapeRight
    _ = AVAudioSession.StereoOrientation.none
    _ = AVAudioSession.StereoOrientation.portrait
    _ = AVAudioSession.StereoOrientation.portraitUpsideDown
    precondition(AVAudioSession.StereoOrientation.landscapeLeft != AVAudioSession.StereoOrientation.landscapeRight)
    _ = AVAudioUnitDistortionPreset.self
    _ = AVAudioUnitDistortionPreset.drumsBitBrush
    _ = AVAudioUnitDistortionPreset.drumsBufferBeats
    _ = AVAudioUnitDistortionPreset.drumsLoFi
    _ = AVAudioUnitDistortionPreset.multiBrokenSpeaker
    _ = AVAudioUnitDistortionPreset.multiCellphoneConcert
    _ = AVAudioUnitDistortionPreset.multiDecimated1
    _ = AVAudioUnitDistortionPreset.multiDecimated2
    _ = AVAudioUnitDistortionPreset.multiDecimated3
    _ = AVAudioUnitDistortionPreset.multiDecimated4
    _ = AVAudioUnitDistortionPreset.multiDistortedCubed
    _ = AVAudioUnitDistortionPreset.multiDistortedFunk
    _ = AVAudioUnitDistortionPreset.multiDistortedSquared
    _ = AVAudioUnitDistortionPreset.multiEcho1
    _ = AVAudioUnitDistortionPreset.multiEcho2
    _ = AVAudioUnitDistortionPreset.multiEchoTight1
    _ = AVAudioUnitDistortionPreset.multiEchoTight2
    _ = AVAudioUnitDistortionPreset.multiEverythingIsBroken
    _ = AVAudioUnitDistortionPreset.speechAlienChatter
    _ = AVAudioUnitDistortionPreset.speechCosmicInterference
    _ = AVAudioUnitDistortionPreset.speechGoldenPi
    _ = AVAudioUnitDistortionPreset.speechRadioTower
    _ = AVAudioUnitDistortionPreset.speechWaves
    precondition(AVAudioUnitDistortionPreset.drumsBitBrush != AVAudioUnitDistortionPreset.drumsBufferBeats)
    _ = AVAudioUnitEQFilterType.self
    _ = AVAudioUnitEQFilterType.bandPass
    _ = AVAudioUnitEQFilterType.bandStop
    _ = AVAudioUnitEQFilterType.highPass
    _ = AVAudioUnitEQFilterType.highShelf
    _ = AVAudioUnitEQFilterType.lowPass
    _ = AVAudioUnitEQFilterType.lowShelf
    _ = AVAudioUnitEQFilterType.parametric
    _ = AVAudioUnitEQFilterType.resonantHighPass
    _ = AVAudioUnitEQFilterType.resonantHighShelf
    _ = AVAudioUnitEQFilterType.resonantLowPass
    _ = AVAudioUnitEQFilterType.resonantLowShelf
    precondition(AVAudioUnitEQFilterType.bandPass != AVAudioUnitEQFilterType.bandStop)
    _ = AVAudioUnitReverbPreset.self
    _ = AVAudioUnitReverbPreset.cathedral
    _ = AVAudioUnitReverbPreset.largeChamber
    _ = AVAudioUnitReverbPreset.largeHall
    _ = AVAudioUnitReverbPreset.largeHall2
    _ = AVAudioUnitReverbPreset.largeRoom
    _ = AVAudioUnitReverbPreset.largeRoom2
    _ = AVAudioUnitReverbPreset.mediumChamber
    _ = AVAudioUnitReverbPreset.mediumHall
    _ = AVAudioUnitReverbPreset.mediumHall2
    _ = AVAudioUnitReverbPreset.mediumHall3
    _ = AVAudioUnitReverbPreset.mediumRoom
    _ = AVAudioUnitReverbPreset.plate
    _ = AVAudioUnitReverbPreset.smallRoom
    precondition(AVAudioUnitReverbPreset.cathedral != AVAudioUnitReverbPreset.largeChamber)
    _ = AVAudioVoiceProcessingOtherAudioDuckingConfiguration.Level.self
    _ = AVAudioVoiceProcessingOtherAudioDuckingConfiguration.Level.`default`
    _ = AVAudioVoiceProcessingOtherAudioDuckingConfiguration.Level.max
    _ = AVAudioVoiceProcessingOtherAudioDuckingConfiguration.Level.mid
    _ = AVAudioVoiceProcessingOtherAudioDuckingConfiguration.Level.min
    precondition(AVAudioVoiceProcessingOtherAudioDuckingConfiguration.Level.`default` != AVAudioVoiceProcessingOtherAudioDuckingConfiguration.Level.max)
    _ = AVAudioVoiceProcessingSpeechActivityEvent.self
    _ = AVAudioVoiceProcessingSpeechActivityEvent.ended
    _ = AVAudioVoiceProcessingSpeechActivityEvent.started
    precondition(AVAudioVoiceProcessingSpeechActivityEvent.ended != AVAudioVoiceProcessingSpeechActivityEvent.started)
    _ = AVMIDIControlChangeEvent.MessageType.self
    _ = AVMIDIControlChangeEvent.MessageType.allNotesOff
    _ = AVMIDIControlChangeEvent.MessageType.allSoundOff
    _ = AVMIDIControlChangeEvent.MessageType.attackTime
    _ = AVMIDIControlChangeEvent.MessageType.balance
    _ = AVMIDIControlChangeEvent.MessageType.bankSelect
    _ = AVMIDIControlChangeEvent.MessageType.breath
    _ = AVMIDIControlChangeEvent.MessageType.brightness
    _ = AVMIDIControlChangeEvent.MessageType.chorusLevel
    _ = AVMIDIControlChangeEvent.MessageType.dataEntry
    _ = AVMIDIControlChangeEvent.MessageType.decayTime
    _ = AVMIDIControlChangeEvent.MessageType.expression
    _ = AVMIDIControlChangeEvent.MessageType.filterResonance
    _ = AVMIDIControlChangeEvent.MessageType.foot
    _ = AVMIDIControlChangeEvent.MessageType.hold2Pedal
    _ = AVMIDIControlChangeEvent.MessageType.legatoPedal
    _ = AVMIDIControlChangeEvent.MessageType.modWheel
    _ = AVMIDIControlChangeEvent.MessageType.monoModeOff
    _ = AVMIDIControlChangeEvent.MessageType.monoModeOn
    _ = AVMIDIControlChangeEvent.MessageType.omniModeOff
    _ = AVMIDIControlChangeEvent.MessageType.omniModeOn
    _ = AVMIDIControlChangeEvent.MessageType.pan
    _ = AVMIDIControlChangeEvent.MessageType.portamento
    _ = AVMIDIControlChangeEvent.MessageType.portamentoTime
    _ = AVMIDIControlChangeEvent.MessageType.RPN_LSB
    _ = AVMIDIControlChangeEvent.MessageType.RPN_MSB
    _ = AVMIDIControlChangeEvent.MessageType.releaseTime
    _ = AVMIDIControlChangeEvent.MessageType.resetAllControllers
    _ = AVMIDIControlChangeEvent.MessageType.reverbLevel
    _ = AVMIDIControlChangeEvent.MessageType.soft
    _ = AVMIDIControlChangeEvent.MessageType.sostenuto
    _ = AVMIDIControlChangeEvent.MessageType.sustain
    _ = AVMIDIControlChangeEvent.MessageType.vibratoDelay
    _ = AVMIDIControlChangeEvent.MessageType.vibratoDepth
    _ = AVMIDIControlChangeEvent.MessageType.vibratoRate
    _ = AVMIDIControlChangeEvent.MessageType.volume
    precondition(AVMIDIControlChangeEvent.MessageType.allNotesOff != AVMIDIControlChangeEvent.MessageType.allSoundOff)
    _ = AVMIDIMetaEvent.EventType.self
    _ = AVMIDIMetaEvent.EventType.copyright
    _ = AVMIDIMetaEvent.EventType.cuePoint
    _ = AVMIDIMetaEvent.EventType.endOfTrack
    _ = AVMIDIMetaEvent.EventType.instrument
    _ = AVMIDIMetaEvent.EventType.keySignature
    _ = AVMIDIMetaEvent.EventType.lyric
    _ = AVMIDIMetaEvent.EventType.marker
    _ = AVMIDIMetaEvent.EventType.midiChannel
    _ = AVMIDIMetaEvent.EventType.midiPort
    _ = AVMIDIMetaEvent.EventType.proprietaryEvent
    _ = AVMIDIMetaEvent.EventType.sequenceNumber
    _ = AVMIDIMetaEvent.EventType.smpteOffset
    _ = AVMIDIMetaEvent.EventType.tempo
    _ = AVMIDIMetaEvent.EventType.text
    _ = AVMIDIMetaEvent.EventType.timeSignature
    _ = AVMIDIMetaEvent.EventType.trackName
    precondition(AVMIDIMetaEvent.EventType.copyright != AVMIDIMetaEvent.EventType.cuePoint)
    _ = AVMusicTrackLoopCount.self
    _ = AVMusicTrackLoopCount.forever
    _ = AVMusicTrackLoopCount.forever
    _ = AVSpeechBoundary.self
    _ = AVSpeechBoundary.immediate
    _ = AVSpeechBoundary.word
    precondition(AVSpeechBoundary.immediate != AVSpeechBoundary.word)
    _ = AVSpeechSynthesisMarker.Mark.self
    _ = AVSpeechSynthesisMarker.Mark.bookmark
    _ = AVSpeechSynthesisMarker.Mark.paragraph
    _ = AVSpeechSynthesisMarker.Mark.phoneme
    _ = AVSpeechSynthesisMarker.Mark.sentence
    _ = AVSpeechSynthesisMarker.Mark.word
    precondition(AVSpeechSynthesisMarker.Mark.bookmark != AVSpeechSynthesisMarker.Mark.paragraph)
    _ = AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus.self
    _ = AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus.authorized
    _ = AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus.denied
    _ = AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus.notDetermined
    _ = AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus.unsupported
    precondition(AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus.authorized != AVSpeechSynthesizer.PersonalVoiceAuthorizationStatus.denied)
    _ = AVSpeechSynthesisVoiceGender.self
    _ = AVSpeechSynthesisVoiceGender.female
    _ = AVSpeechSynthesisVoiceGender.male
    _ = AVSpeechSynthesisVoiceGender.unspecified
    precondition(AVSpeechSynthesisVoiceGender.female != AVSpeechSynthesisVoiceGender.male)
    _ = AVSpeechSynthesisVoiceQuality.self
    _ = AVSpeechSynthesisVoiceQuality.`default`
    _ = AVSpeechSynthesisVoiceQuality.enhanced
    _ = AVSpeechSynthesisVoiceQuality.premium
    precondition(AVSpeechSynthesisVoiceQuality.`default` != AVSpeechSynthesisVoiceQuality.enhanced)
}


func testAVFAudioOptionSets() {
    var buffer = AVAudioPlayerNodeBufferOptions()
    precondition(buffer.isEmpty)
    _ = buffer.insert(.loops)
    precondition(buffer.contains(.loops))
    _ = buffer.insert(.interrupts)
    _ = buffer.insert(.interruptsAtLoop)
    precondition(buffer.contains(.interrupts) && buffer.contains(.interruptsAtLoop))
    precondition(buffer.isSuperset(of: .loops))
    precondition(!buffer.isDisjoint(with: .loops))
    precondition(buffer.isSubset(of: buffer))
    precondition(!buffer.isStrictSubset(of: buffer))
    precondition(!buffer.isStrictSuperset(of: buffer))
    let subtracted = buffer.subtracting(.loops)
    precondition(!subtracted.contains(.loops))
    buffer.subtract(.interrupts)
    _ = buffer.remove(.interruptsAtLoop)
    _ = buffer.update(with: .loops)
    buffer.formUnion(.interrupts)
    buffer.formIntersection(.loops)
    buffer.formSymmetricDifference(.interruptsAtLoop)
    let unioned = AVAudioPlayerNodeBufferOptions.loops.union(.interrupts)
    _ = unioned.intersection(.loops)
    _ = unioned.symmetricDifference(.interrupts)
    precondition(AVAudioPlayerNodeBufferOptions.loops != .interrupts)
    _ = AVAudioPlayerNodeBufferOptions(rawValue: 1)
    _ = AVAudioPlayerNodeBufferOptions([.loops])
    _ = AVAudioPlayerNodeBufferOptions()

    var category = AVAudioSession.CategoryOptions()
    _ = category.insert(.mixWithOthers)
    _ = category.insert(.duckOthers)
    _ = category.insert(.allowBluetooth)
    _ = category.insert(.defaultToSpeaker)
    _ = category.insert(.interruptSpokenAudioAndMixWithOthers)
    _ = category.insert(.allowBluetoothA2DP)
    _ = category.insert(.allowAirPlay)
    _ = category.insert(.overrideMutedMicrophoneInterruption)
    _ = category.insert(.allowBluetoothHFP)
    _ = category.insert(.bluetoothHighQualityRecording)
    precondition(category.contains(.mixWithOthers))
    _ = category.union(.duckOthers)
    _ = category.intersection(.mixWithOthers)
    _ = category.symmetricDifference(.allowAirPlay)
    _ = category.subtracting(.duckOthers)
    category.formUnion(.allowBluetooth)
    category.formIntersection(.mixWithOthers)
    category.formSymmetricDifference(.allowAirPlay)
    category.subtract(.duckOthers)
    _ = category.remove(.allowBluetooth)
    _ = category.update(with: .mixWithOthers)
    _ = category.isDisjoint(with: .allowAirPlay)
    _ = category.isSubset(of: category)
    _ = category.isSuperset(of: .mixWithOthers)
    _ = category.isStrictSubset(of: category)
    _ = category.isStrictSuperset(of: .mixWithOthers)
    _ = category.isEmpty
    precondition(AVAudioSession.CategoryOptions.mixWithOthers != .duckOthers)
    _ = AVAudioSession.CategoryOptions(rawValue: 1)
    _ = AVAudioSession.CategoryOptions([.mixWithOthers])

    var active = AVAudioSession.SetActiveOptions()
    _ = active.insert(.notifyOthersOnDeactivation)
    _ = active.union(.notifyOthersOnDeactivation)
    _ = active.intersection(.notifyOthersOnDeactivation)
    _ = active.symmetricDifference(.notifyOthersOnDeactivation)
    _ = active.subtracting(.notifyOthersOnDeactivation)
    active.formUnion(.notifyOthersOnDeactivation)
    active.formIntersection(.notifyOthersOnDeactivation)
    active.formSymmetricDifference(.notifyOthersOnDeactivation)
    active.subtract(.notifyOthersOnDeactivation)
    _ = active.remove(.notifyOthersOnDeactivation)
    _ = active.update(with: .notifyOthersOnDeactivation)
    _ = active.isDisjoint(with: .notifyOthersOnDeactivation)
    _ = active.isSubset(of: active)
    _ = active.isSuperset(of: [])
    _ = active.isStrictSubset(of: [.notifyOthersOnDeactivation])
    _ = active.isStrictSuperset(of: [])
    _ = active.isEmpty
    _ = AVAudioSession.SetActiveOptions(rawValue: 1)
    _ = AVAudioSession.SetActiveOptions([.notifyOthersOnDeactivation])
    _ = AVAudioSession.SetActiveOptions()
    precondition(AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation != [])

    var interruption = AVAudioSession.InterruptionOptions()
    _ = interruption.insert(.shouldResume)
    _ = interruption.union(.shouldResume)
    _ = interruption.intersection(.shouldResume)
    _ = interruption.symmetricDifference(.shouldResume)
    _ = interruption.subtracting(.shouldResume)
    interruption.formUnion(.shouldResume)
    interruption.formIntersection(.shouldResume)
    interruption.formSymmetricDifference(.shouldResume)
    interruption.subtract(.shouldResume)
    _ = interruption.remove(.shouldResume)
    _ = interruption.update(with: .shouldResume)
    _ = interruption.isDisjoint(with: .shouldResume)
    _ = interruption.isSubset(of: interruption)
    _ = interruption.isSuperset(of: [])
    _ = interruption.isStrictSubset(of: [.shouldResume])
    _ = interruption.isStrictSuperset(of: [])
    _ = interruption.isEmpty
    _ = AVAudioSession.InterruptionOptions(rawValue: 1)
    _ = AVAudioSession.InterruptionOptions([.shouldResume])
    precondition(AVAudioSession.InterruptionOptions.shouldResume != [])

    var activation = AVAudioSessionActivationOptions()
    _ = activation.insert(AVAudioSessionActivationOptions(rawValue: 1))
    _ = activation.union([])
    _ = activation.intersection([])
    _ = activation.symmetricDifference([])
    _ = activation.subtracting([])
    activation.formUnion([])
    activation.formIntersection([])
    activation.formSymmetricDifference([])
    activation.subtract([])
    _ = activation.remove(AVAudioSessionActivationOptions(rawValue: 1))
    _ = activation.update(with: AVAudioSessionActivationOptions(rawValue: 1))
    _ = activation.isDisjoint(with: [])
    _ = activation.isSubset(of: activation)
    _ = activation.isSuperset(of: [])
    _ = activation.isStrictSubset(of: activation)
    _ = activation.isStrictSuperset(of: [])
    _ = activation.isEmpty
    _ = AVAudioSessionActivationOptions(rawValue: 0)
    _ = AVAudioSessionActivationOptions([])
    _ = AVAudioSessionActivationOptions()
    precondition(AVAudioSessionActivationOptions() != AVAudioSessionActivationOptions(rawValue: 1))

    var load = AVMusicSequenceLoadOptions()
    _ = load.insert(.smf_ChannelsToTracks)
    _ = load.union(.smf_ChannelsToTracks)
    _ = load.intersection(.smf_ChannelsToTracks)
    _ = load.symmetricDifference(.smf_ChannelsToTracks)
    _ = load.subtracting(.smf_ChannelsToTracks)
    load.formUnion(.smf_ChannelsToTracks)
    load.formIntersection(.smf_ChannelsToTracks)
    load.formSymmetricDifference(.smf_ChannelsToTracks)
    load.subtract(.smf_ChannelsToTracks)
    _ = load.remove(.smf_ChannelsToTracks)
    _ = load.update(with: .smf_ChannelsToTracks)
    _ = load.isDisjoint(with: .smf_ChannelsToTracks)
    _ = load.isSubset(of: load)
    _ = load.isSuperset(of: [])
    _ = load.isStrictSubset(of: [.smf_ChannelsToTracks])
    _ = load.isStrictSuperset(of: [])
    _ = load.isEmpty
    _ = AVMusicSequenceLoadOptions(rawValue: 1)
    _ = AVMusicSequenceLoadOptions([.smf_ChannelsToTracks])
    precondition(AVMusicSequenceLoadOptions.smf_ChannelsToTracks != [])

    var traits = AVSpeechSynthesisVoice.Traits()
    _ = traits.insert(.isNoveltyVoice)
    _ = traits.insert(.isPersonalVoice)
    _ = traits.union(.isNoveltyVoice)
    _ = traits.intersection(.isPersonalVoice)
    _ = traits.symmetricDifference(.isNoveltyVoice)
    _ = traits.subtracting(.isPersonalVoice)
    traits.formUnion(.isNoveltyVoice)
    traits.formIntersection(.isPersonalVoice)
    traits.formSymmetricDifference(.isNoveltyVoice)
    traits.subtract(.isPersonalVoice)
    _ = traits.remove(.isNoveltyVoice)
    _ = traits.update(with: .isPersonalVoice)
    _ = traits.isDisjoint(with: .isNoveltyVoice)
    _ = traits.isSubset(of: traits)
    _ = traits.isSuperset(of: [])
    _ = traits.isStrictSubset(of: traits)
    _ = traits.isStrictSuperset(of: [])
    _ = traits.isEmpty
    _ = AVSpeechSynthesisVoice.Traits(rawValue: 1)
    _ = AVSpeechSynthesisVoice.Traits([.isNoveltyVoice])
    precondition(AVSpeechSynthesisVoice.Traits.isNoveltyVoice != .isPersonalVoice)
}



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



func testAVAudioPCMBufferLayout() {
    guard let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 2,
        interleaved: false
    ) else {
        preconditionFailure("pcm format")
    }
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512) else {
        preconditionFailure("pcm buffer")
    }
    buffer.frameLength = 256
    precondition(buffer.frameCapacity == 512)
    precondition(buffer.stride == 1)
    precondition(buffer.format === format)
    guard let planes = buffer.floatChannelData else {
        preconditionFailure("float planes")
    }
    planes[0][0] = 0.5
    planes[1][0] = -0.25
    precondition(planes[0][0] == 0.5)
    precondition(planes[1][0] == -0.25)
    guard let copied = buffer.copy() as? AVAudioPCMBuffer else {
        preconditionFailure("pcm copy")
    }
    precondition(copied !== buffer)
    precondition(
        copied.frameCapacity
            == buffer.frameCapacity * AVAudioFrameCount(MemoryLayout<Float>.stride)
    )
    precondition(copied.frameLength == buffer.frameLength)
    precondition(copied.floatChannelData?[0][0] == 0.5)
    planes[0][0] = 0.75
    precondition(copied.floatChannelData?[0][0] == 0.5)
    guard let mutableCopied = buffer.mutableCopy() as? AVAudioPCMBuffer else {
        preconditionFailure("pcm mutable copy")
    }
    precondition(mutableCopied.floatChannelData?[0][0] == 0.75)
    _ = AVAudioPCMBuffer(PCMFormat: format, frameCapacity: 8)

    let interleaved = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 2,
        interleaved: true
    )!
    guard let interleavedBuffer = AVAudioPCMBuffer(pcmFormat: interleaved, frameCapacity: 8) else {
        preconditionFailure("interleaved pcm")
    }
    precondition(interleavedBuffer.stride == 2)
    interleavedBuffer.frameLength = 2
    interleavedBuffer.floatChannelData?[0][0] = 0.125
    interleavedBuffer.floatChannelData?[1][0] = -0.5
    interleavedBuffer.floatChannelData?[0][interleavedBuffer.stride] = 0.25
    precondition(interleavedBuffer.floatChannelData?[0][0] == 0.125)
    precondition(interleavedBuffer.floatChannelData?[1][0] == -0.5)
    precondition(interleavedBuffer.floatChannelData?[0][interleavedBuffer.stride] == 0.25)
    guard let interleavedCopy = interleavedBuffer.copy() as? AVAudioPCMBuffer else {
        preconditionFailure("interleaved copy")
    }
    precondition(
        interleavedCopy.frameCapacity
            == interleavedBuffer.frameCapacity
                * AVAudioFrameCount(MemoryLayout<Float>.stride)
                * AVAudioFrameCount(interleavedBuffer.stride)
    )

    let int16Format = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 44_100,
        channels: 2,
        interleaved: false
    )!
    guard let int16Buffer = AVAudioPCMBuffer(pcmFormat: int16Format, frameCapacity: 3) else {
        preconditionFailure("int16 pcm")
    }
    precondition(int16Buffer.int16ChannelData != nil)
    int16Buffer.frameLength = 1
    int16Buffer.int16ChannelData?[0][0] = 1024
    int16Buffer.int16ChannelData?[1][0] = -2048
    guard let int16Copy = int16Buffer.copy() as? AVAudioPCMBuffer else {
        preconditionFailure("int16 copy")
    }
    precondition(int16Copy.frameCapacity == 6)

    let int32Format = AVAudioFormat(
        commonFormat: .pcmFormatInt32,
        sampleRate: 48_000,
        channels: 1,
        interleaved: true
    )!
    guard let int32Buffer = AVAudioPCMBuffer(pcmFormat: int32Format, frameCapacity: 4) else {
        preconditionFailure("int32 pcm")
    }
    precondition(int32Buffer.stride == 1)
    precondition(int32Buffer.int32ChannelData != nil)
    int32Buffer.frameLength = 1
    int32Buffer.int32ChannelData?[0][0] = 100_000

    let compressed = AVAudioCompressedBuffer(format: format, packetCapacity: 3, maximumPacketSize: 8)
    compressed.packetCount = 1
    compressed.byteLength = 4
    precondition(compressed.byteCapacity > 0)
    _ = compressed.data
    _ = AVAudioCompressedBuffer(format: format, packetCapacity: 2)
    guard let compressedCopy = compressed.copy() as? AVAudioBuffer else {
        preconditionFailure("compressed copy")
    }
    precondition(!(compressedCopy is AVAudioCompressedBuffer))
    guard let compressedMutable = compressed.mutableCopy() as? AVAudioBuffer else {
        preconditionFailure("compressed mutable")
    }
    precondition(!(compressedMutable is AVAudioCompressedBuffer))
    precondition(compressedCopy.format === compressed.format)
}



func testAVAudioTimeExtrapolation() {
    let host = AVAudioTime.hostTime(forSeconds: 1.5)
    let seconds = AVAudioTime.seconds(forHostTime: host)
    precondition(abs(seconds - 1.5) < 0.000_001)
    precondition(AVAudioTime.hostTime(forSeconds: -1.5) == 0)
    precondition(AVAudioTime.hostTime(forSeconds: .nan) == 0)
    let sampleTime = AVAudioTime(sampleTime: 44100, atRate: 44100)
    precondition(sampleTime.isSampleTimeValid)
    precondition(!sampleTime.isHostTimeValid)
    precondition(sampleTime.sampleRate == 44100)
    precondition(sampleTime.sampleTime == 44100)
    let both = AVAudioTime(hostTime: host, sampleTime: 0, atRate: 44100)
    precondition(both.extrapolateTime(fromAnchor: sampleTime) != nil)
    let hostOnly = AVAudioTime(hostTime: 42)
    precondition(hostOnly.isHostTimeValid)
    precondition(hostOnly.hostTime == 42)
    let after = AVAudioTime(hostTime: 1_000_000_000, sampleTime: 88200, atRate: 44100)
    let anchor = AVAudioTime(hostTime: 1_000_000_000, sampleTime: 44100, atRate: 44100)
    precondition(after.extrapolateTime(fromAnchor: anchor)?.hostTime == 2_000_000_000)
    let before = AVAudioTime(hostTime: 9, sampleTime: 0, atRate: 44100)
    precondition(before.extrapolateTime(fromAnchor: anchor)?.hostTime == 0)
    let overflowAnchor = AVAudioTime(hostTime: UInt64.max - 5, sampleTime: 0, atRate: 1)
    let overflowSample = AVAudioTime(hostTime: 0, sampleTime: 1, atRate: 1)
    precondition(overflowSample.extrapolateTime(fromAnchor: overflowAnchor) == nil)
    #if canImport(CoreAudioTypes) || canImport(AudioToolbox)
    var stamp = AudioTimeStamp()
    stamp.mHostTime = 99
    stamp.mFlags = [.hostTimeValid]
    let decoded = AVAudioTime(audioTimeStamp: &stamp, sampleRate: 44100)
    precondition(decoded.isHostTimeValid)
    _ = decoded.audioTimeStamp
    #endif
}



func avfaudioTestWAVE(frames: Int = 8, sampleRate: UInt32 = 44100, channels: UInt16 = 2) -> Data {
    let blockAlign = channels * 2
    let dataBytes = UInt32(frames) * UInt32(blockAlign)
    var data = Data()
    func ascii(_ text: String) { data.append(contentsOf: text.utf8) }
    func u16(_ value: UInt16) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    func u32(_ value: UInt32) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
    ascii("RIFF"); u32(36 + dataBytes); ascii("WAVE"); ascii("fmt "); u32(16)
    u16(1); u16(channels); u32(sampleRate)
    u32(sampleRate * UInt32(blockAlign)); u16(blockAlign); u16(16)
    ascii("data"); u32(dataBytes)
    data.append(contentsOf: Array(repeating: 0, count: Int(dataBytes)))
    return data
}

func avfaudioTestAIFF() -> Data {
    var data = Data()
    func ascii(_ text: String) { data.append(contentsOf: text.utf8) }
    func u16(_ value: UInt16) {
        var big = value.bigEndian
        withUnsafeBytes(of: &big) { data.append(contentsOf: $0) }
    }
    func u32(_ value: UInt32) {
        var big = value.bigEndian
        withUnsafeBytes(of: &big) { data.append(contentsOf: $0) }
    }
    ascii("FORM"); u32(4 + 8 + 18 + 8 + 8 + 8); ascii("AIFF")
    ascii("COMM"); u32(18); u16(1); u32(4); u16(16)
    data.append(contentsOf: [0x40, 0x0e, 0xac, 0x44, 0, 0, 0, 0, 0, 0])
    ascii("SSND"); u32(16); u32(0); u32(0)
    data.append(contentsOf: [0, 0, 0x10, 0, 0x20, 0, 0x30, 0])
    return data
}

func testAVAudioFileContainers() {
    let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 2,
        interleaved: false
    )!
    let directory = FileManager.default.temporaryDirectory
    let wavURL = directory.appendingPathComponent("avfaudio-cov-\(UUID().uuidString).wav")
    let cafURL = directory.appendingPathComponent("avfaudio-cov-\(UUID().uuidString).caf")
    let aiffURL = directory.appendingPathComponent("avfaudio-cov-\(UUID().uuidString).aiff")
    defer {
        try? FileManager.default.removeItem(at: wavURL)
        try? FileManager.default.removeItem(at: cafURL)
        try? FileManager.default.removeItem(at: aiffURL)
    }
    guard let source = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16) else {
        preconditionFailure("file source")
    }
    source.frameLength = 16
    source.floatChannelData?[0][0] = 0.25
    source.floatChannelData?[1][1] = -0.5
    do {
        let writer = try AVAudioFile(forWriting: wavURL, settings: format.settings)
        precondition(writer.fileFormat.sampleRate == 44100)
        try writer.write(from: source)
        precondition(writer.length == 16)
        precondition(writer.framePosition == 16)
        writer.close()
        precondition(!writer.isOpen)
        let reader = try AVAudioFile(forReading: wavURL)
        precondition(reader.length == 16)
        precondition(reader.url == wavURL)
        precondition(reader.processingFormat.isStandard)
        guard let wavBuffer = AVAudioPCMBuffer(pcmFormat: reader.processingFormat, frameCapacity: 16) else {
            preconditionFailure("wav buffer")
        }
        try reader.read(into: wavBuffer)
        precondition(wavBuffer.frameLength == 16)
        precondition(abs((wavBuffer.floatChannelData?[0][0] ?? 0) - 0.25) < 0.01)
        reader.framePosition = 0
        try reader.read(into: wavBuffer, frameCount: 4)
        precondition(wavBuffer.frameLength == 4)
        let processingWriter = try AVAudioFile(
            forWriting: cafURL,
            settings: format.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        try processingWriter.write(from: source)
        processingWriter.close()
        let cafReader = try AVAudioFile(
            forReading: cafURL,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        precondition(cafReader.length == 16)
        guard let cafBuffer = AVAudioPCMBuffer(pcmFormat: cafReader.processingFormat, frameCapacity: 16) else {
            preconditionFailure("caf buffer")
        }
        try cafReader.read(into: cafBuffer)
        precondition(abs((cafBuffer.floatChannelData?[0][0] ?? 0) - 0.25) < 0.01)
        try avfaudioTestAIFF().write(to: aiffURL)
        let aiff = try AVAudioFile(forReading: aiffURL)
        precondition(aiff.fileFormat.channelCount == 1)
        precondition(aiff.length == 4)
        _ = AVAudioFile()
    } catch {
        preconditionFailure("file containers: \(error)")
    }
    do {
        _ = try AVAudioFile(forReading: URL(fileURLWithPath: "/no/such/avfaudio-file.wav"))
        preconditionFailure("missing file must throw")
    } catch {}
}



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



func testAVAudioEngineManualRendering() {
    let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 2,
        interleaved: false
    )!
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: format)
    precondition(engine.attachedNodes.contains(player))
    precondition(
        engine.outputConnectionPoints(for: player, outputBus: 0).contains(where: {
            $0.node === engine.mainMixerNode
        })
    )
    precondition(!engine.isRunning)
    do {
        try engine.start()
        preconditionFailure("hardware start must throw")
    } catch {}
    precondition(!engine.isRunning)
    do {
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 512)
    } catch {
        preconditionFailure("enable manual: \(error)")
    }
    precondition(engine.isInManualRenderingMode)
    precondition(engine.manualRenderingMode == .offline)
    precondition(engine.manualRenderingMaximumFrameCount == 512)
    precondition(engine.manualRenderingFormat.sampleRate == format.sampleRate)
    do {
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 256)
        preconditionFailure("second enable must throw")
    } catch {}
    do { try engine.start() } catch { preconditionFailure("manual start: \(error)") }
    precondition(engine.isRunning)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 256) else {
        preconditionFailure("schedule buffer")
    }
    buffer.frameLength = 256
    buffer.floatChannelData?[0][0] = 0.75
    buffer.floatChannelData?[1][0] = -0.25
    player.scheduleBuffer(buffer, completionHandler: {})
    player.volume = 1
    player.pan = 0
    player.play()
    precondition(player.isPlaying)
    guard let rendered = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 256) else {
        preconditionFailure("render buffer")
    }
    do {
        let status = try engine.renderOffline(256, to: rendered)
        precondition(status == .success)
    } catch {
        preconditionFailure("render: \(error)")
    }
    precondition(rendered.frameLength == 256)
    precondition(abs((rendered.floatChannelData?[0][0] ?? 0) - 0.75) < 0.000_1)
    precondition(abs((rendered.floatChannelData?[1][0] ?? 0) + 0.25) < 0.000_1)
    precondition(engine.manualRenderingSampleTime == 256)
    engine.pause()
    engine.stop()
    precondition(!engine.isRunning)
    engine.disableManualRenderingMode()
    precondition(!engine.isInManualRenderingMode)
    engine.prepare()
    engine.reset()
    _ = engine.inputNode
    _ = engine.outputNode
    engine.isAutoShutdownEnabled = true
    precondition(engine.isAutoShutdownEnabled)
}

func testAVAudioEngineGraphConnections() {
    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    let engine = AVAudioEngine()
    let sourceA = AVAudioPlayerNode()
    let sourceB = AVAudioPlayerNode()
    let destination = AVAudioMixerNode()
    let unrelated = AVAudioMixerNode()
    engine.attach(sourceA)
    engine.attach(sourceB)
    engine.attach(destination)
    engine.attach(unrelated)
    engine.connect(sourceA, to: destination, fromBus: 0, toBus: 0, format: format)
    engine.connect(sourceB, to: destination, fromBus: 0, toBus: 0, format: format)
    precondition(engine.inputConnectionPoint(for: destination, inputBus: 0)?.node === sourceB)
    precondition(engine.outputConnectionPoints(for: sourceA, outputBus: 0).isEmpty)
    engine.connect(sourceA, to: unrelated, fromBus: 0, toBus: 0, format: format)
    engine.connect(sourceA, to: destination, fromBus: 0, toBus: 1, format: format)
    precondition(engine.inputConnectionPoint(for: destination, inputBus: 1)?.node === sourceA)
    engine.disconnectNodeOutput(sourceA)
    engine.disconnectNodeOutput(sourceB, bus: 0)
    engine.disconnectNodeInput(destination, bus: 0)
    engine.disconnectNodeInput(unrelated)
    engine.disconnectMIDI(sourceA, from: destination)
    engine.disconnectMIDI(sourceA, from: [destination])
    engine.disconnectMIDIInput(destination)
    engine.disconnectMIDIOutput(sourceA)
    engine.detach(unrelated)
    let points = [AVAudioConnectionPoint(node: engine.mainMixerNode, bus: 1)]
    engine.connect(sourceA, to: points, fromBus: 0, format: nil)
    _ = destination.nextAvailableInputBus
    destination.outputVolume = 0.5
    sourceA.prepare(withFrameCount: 128)
    _ = sourceA.nodeTime(forPlayerTime: AVAudioTime(hostTime: 1))
    _ = sourceA.playerTime(forNodeTime: AVAudioTime(sampleTime: 0, atRate: 44100))
    sourceA.installTap(onBus: 0, bufferSize: 256, format: nil) { _, _ in }
    sourceA.removeTap(onBus: 0)
    _ = sourceA.numberOfInputs
    _ = sourceA.numberOfOutputs
    _ = sourceA.latency
    _ = sourceA.outputPresentationLatency
    _ = sourceA.name(forInputBus: 0)
    _ = sourceA.name(forOutputBus: 0)
    _ = sourceA.inputFormat(forBus: 0)
    _ = sourceA.outputFormat(forBus: 0)
    _ = sourceA.engine
    sourceA.reset()
}



func testAVAudioMixingPanGain() {
    let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 2,
        interleaved: false
    )!
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let eq = AVAudioUnitEQ(numberOfBands: 2)
    eq.globalGain = 0
    engine.attach(player)
    engine.attach(eq)
    engine.connect(player, to: eq, format: format)
    engine.connect(eq, to: engine.mainMixerNode, format: format)
    engine.mainMixerNode.outputVolume = 0.5
    player.volume = 1
    player.pan = -1
    do {
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 64)
        try engine.start()
    } catch {
        preconditionFailure("mix engine: \(error)")
    }
    guard let source = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8) else {
        preconditionFailure("mix source")
    }
    source.frameLength = 8
    source.floatChannelData?[0][0] = 1
    source.floatChannelData?[1][0] = 1
    player.scheduleBuffer(source, completionHandler: {})
    player.play()
    guard let rendered = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 8) else {
        preconditionFailure("mix dest")
    }
    do {
        let status = try engine.renderOffline(8, to: rendered)
        precondition(status == .success)
    } catch {
        preconditionFailure("mix render: \(error)")
    }
    precondition(abs((rendered.floatChannelData?[0][0] ?? 0) - 0.5) < 0.000_1)
    precondition(abs(rendered.floatChannelData?[1][0] ?? 1) < 0.000_1)
    engine.stop()
    engine.disableManualRenderingMode()
    let dest = AVAudioMixingDestination(
        connectionPoint: AVAudioConnectionPoint(node: engine.mainMixerNode, bus: 0)
    )
    precondition(dest.connectionPoint.bus == 0)
    _ = player.destination(forMixer: engine.mainMixerNode, bus: 0)
}



func testAVAudioSessionCategoryAndFailClosed() {
    let session = AVAudioSession.sharedInstance()
    do {
        try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
        try session.setCategory(.playback)
        try session.setCategory(.playback, options: [.mixWithOthers])
        try session.setMode(.moviePlayback)
    } catch {
        preconditionFailure("category store: \(error)")
    }
    precondition(session.category == .playback || session.category == .playAndRecord)
    precondition(session.mode == .moviePlayback)
    precondition(session.categoryOptions.contains(.mixWithOthers))
    do {
        try session.setActive(true)
        preconditionFailure("setActive must throw")
    } catch {}
    do { try session.setActive(true, options: [.notifyOthersOnDeactivation]); preconditionFailure("setActive options") } catch {}
    precondition(session.sampleRate == 0)
    precondition(session.outputVolume == 0)
    precondition(session.outputNumberOfChannels == 0)
    precondition(session.currentRoute.outputs.isEmpty)
    precondition(session.recordPermission == .denied)
    precondition(!session.isInputAvailable)
    do { try session.setPreferredSampleRate(48000); preconditionFailure("preferred rate") } catch {}
    do { try session.overrideOutputAudioPort(.speaker); preconditionFailure("port override") } catch {}
    do { try session.setAggregatedIOPreference(.aggregated); preconditionFailure("aggregated") } catch {}
    precondition(!session.availableCategories.isEmpty)
    precondition(!session.availableModes.isEmpty)
    precondition(session.promptStyle == .none)
    precondition(session.renderingMode == .notApplicable)
    precondition(session.inputLatency == 0 && session.outputLatency == 0)
    precondition(session.maximumInputNumberOfChannels == 0)
    precondition(session.preferredOutputNumberOfChannels == 2)
    precondition(session.inputNumberOfChannels == 0)
    precondition(session.maximumOutputNumberOfChannels == 0)
    precondition(!session.isInputGainSettable)
    precondition(session.inputGain == 0)
    precondition(!session.isOtherAudioPlaying)
    precondition(!session.secondaryAudioShouldBeSilencedHint)
    _ = session.preferredInputNumberOfChannels
    _ = session.inputOrientation
    _ = session.preferredInputOrientation
    _ = session.preferredInput
    _ = session.availableInputs
    _ = session.isOutputMuted
    _ = session.preferredIOBufferDuration
    var permissionCalls = 0
    var granted = true
    let sem = DispatchSemaphore(value: 0)
    AVFAudioHostAvailability.callbackQueue.sync {
        session.requestRecordPermission { value in
            permissionCalls += 1
            granted = value
            sem.signal()
        }
    }
    precondition(sem.wait(timeout: .now() + 2) == .success)
    precondition(permissionCalls == 1 && granted == false)
}

func testAVAudioSessionPortsAndNotifications() {
    _ = AVAudioSession.Category.ambient
    _ = AVAudioSession.Category.soloAmbient
    _ = AVAudioSession.Category.playback
    _ = AVAudioSession.Category.record
    _ = AVAudioSession.Category.playAndRecord
    _ = AVAudioSession.Category.multiRoute
    _ = AVAudioSession.Category.audioProcessing
    _ = AVAudioSession.Mode.default
    _ = AVAudioSession.Mode.voiceChat
    _ = AVAudioSession.Mode.videoChat
    _ = AVAudioSession.Mode.gameChat
    _ = AVAudioSession.Mode.videoRecording
    _ = AVAudioSession.Mode.measurement
    _ = AVAudioSession.Mode.moviePlayback
    _ = AVAudioSession.Mode.spokenAudio
    _ = AVAudioSession.Mode.voicePrompt
    _ = AVAudioSession.Mode.shortFormVideo
    _ = AVAudioSession.Port.lineIn
    _ = AVAudioSession.Port.lineOut
    _ = AVAudioSession.Port.builtInMic
    _ = AVAudioSession.Port.builtInSpeaker
    _ = AVAudioSession.Port.headphones
    _ = AVAudioSession.Port.headsetMic
    _ = AVAudioSession.Port.bluetoothA2DP
    _ = AVAudioSession.Port.bluetoothLE
    _ = AVAudioSession.Port.bluetoothHFP
    _ = AVAudioSession.Port.usbAudio
    _ = AVAudioSession.Port.carAudio
    _ = AVAudioSession.Port.airPlay
    _ = AVAudioSession.Port.HDMI
    _ = AVAudioSession.Port.displayPort
    _ = AVAudioSession.Port.fireWire
    _ = AVAudioSession.Port.PCI
    _ = AVAudioSession.Port.thunderbolt
    _ = AVAudioSession.Port.AVB
    _ = AVAudioSession.Port.virtual
    _ = AVAudioSession.Port.builtInReceiver
    _ = AVAudioSession.Port.continuityMicrophone
    _ = AVAudioSession.Location.upper
    _ = AVAudioSession.Location.lower
    _ = AVAudioSession.Location.orientationTop
    _ = AVAudioSession.Location.orientationBottom
    _ = AVAudioSession.Location.orientationFront
    _ = AVAudioSession.Location.orientationBack
    _ = AVAudioSession.Location.orientationLeft
    _ = AVAudioSession.Location.orientationRight
    _ = AVAudioSession.Location.polarPatternOmnidirectional
    _ = AVAudioSession.Location.polarPatternCardioid
    _ = AVAudioSession.Location.polarPatternSubcardioid
    _ = AVAudioSession.Orientation.front
    _ = AVAudioSession.Orientation.back
    _ = AVAudioSession.Orientation.top
    _ = AVAudioSession.Orientation.bottom
    _ = AVAudioSession.Orientation.left
    _ = AVAudioSession.Orientation.right
    _ = AVAudioSession.PolarPattern.cardioid
    _ = AVAudioSession.PolarPattern.omnidirectional
    _ = AVAudioSession.PolarPattern.subcardioid
    _ = AVAudioSession.PolarPattern.stereo
    _ = AVAudioSession.interruptionNotification
    _ = AVAudioSession.routeChangeNotification
    _ = AVAudioSession.mediaServicesWereLostNotification
    _ = AVAudioSession.mediaServicesWereResetNotification
    _ = AVAudioSession.silenceSecondaryAudioHintNotification
    _ = AVAudioSession.spatialPlaybackCapabilitiesChangedNotification
    _ = AVAudioSession.availableInputsChangeNotification
    _ = AVAudioSession.renderingModeChangeNotification
    _ = AVAudioSession.renderingCapabilitiesChangeNotification
    _ = AVAudioSession.microphoneInjectionCapabilitiesChangeNotification
    _ = AVAudioSession.outputMuteStateChangeNotification
    _ = AVAudioSession.userIntentToUnmuteOutputNotification
    _ = AVAudioSession.muteStateKey
    precondition(AVAudioSession.RouteSharingPolicy.longForm == .longFormAudio)
    let port = AVAudioSessionPortDescription(portType: .builtInSpeaker, portName: "Speaker", uid: "spk")
    precondition(port.portType == .builtInSpeaker)
    do { try port.setPreferredDataSource(nil) } catch {}
    let channel = AVAudioSessionChannelDescription(
        channelName: "Left",
        channelNumber: 1,
        owningPortUID: "spk",
        channelLabel: 1
    )
    precondition(channel.channelNumber == 1)
    _ = channel.channelName
    _ = channel.owningPortUID
    _ = channel.channelLabel
    let source = AVAudioSessionDataSourceDescription(
        dataSourceID: 1,
        dataSourceName: "Mic",
        location: .upper,
        orientation: .front
    )
    do { try source.setPreferredPolarPattern(.cardioid) } catch {
        preconditionFailure("polar")
    }
    precondition(source.preferredPolarPattern == .cardioid)
    _ = AVAudioSessionCapability()
    _ = AVAudioSessionPortExtensionBluetoothMicrophone().highQualityRecording.isSupported
    _ = AVAudioSessionRouteDescription()
}



func testAVAudioPlayerFailClosed() {
    do {
        _ = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/no/such/avfaudio-player.wav"))
        preconditionFailure("missing URL")
    } catch {}
    do {
        _ = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))
        preconditionFailure("directory URL")
    } catch {}
    do { _ = try AVAudioPlayer(data: Data()); preconditionFailure("empty data") } catch {}
    do { _ = try AVAudioPlayer(data: Data([0, 1, 2, 3, 4, 5, 6, 7])); preconditionFailure("garbage") } catch {}
    let wave = avfaudioTestWAVE()
    do {
        let fromData = try AVAudioPlayer(data: wave)
        precondition(fromData.format.sampleRate == 44100)
        precondition(fromData.format.channelCount == 2)
        precondition(abs(fromData.duration - (8.0 / 44100.0)) < 0.000_000_1)
        precondition(fromData.prepareToPlay() == false)
        precondition(fromData.play() == false)
        precondition(!fromData.isPlaying)
        fromData.volume = 0.5
        precondition(fromData.volume == 0.5)
        fromData.pan = 0.1
        fromData.rate = 1
        fromData.enableRate = true
        fromData.numberOfLoops = 0
        fromData.isMeteringEnabled = false
        fromData.currentTime = 0
        _ = fromData.data
        _ = fromData.settings
        _ = fromData.numberOfChannels
        _ = fromData.deviceCurrentTime
        _ = fromData.channelAssignments
        fromData.pause()
        fromData.stop()
        fromData.updateMeters()
        _ = fromData.averagePower(forChannel: 0)
        _ = fromData.peakPower(forChannel: 0)
        fromData.setVolume(0.2, fadeDuration: 0)
        _ = fromData.play(atTime: 0)
        let hinted = try AVAudioPlayer(data: wave, fileTypeHint: "public.wav")
        precondition(hinted.duration == fromData.duration)
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(
            "avfaudio-valid-\(UUID().uuidString).wav"
        )
        defer { try? FileManager.default.removeItem(at: tmp) }
        try wave.write(to: tmp)
        let fromURL = try AVAudioPlayer(contentsOf: tmp)
        precondition(fromURL.url == tmp)
        _ = try AVAudioPlayer(contentsOf: tmp, fileTypeHint: "public.wav")
        _ = try AVAudioPlayer(contentsOfURL: tmp)
        _ = try AVAudioPlayer(contentsOfURL: tmp, fileTypeHint: "public.wav")
    } catch {
        preconditionFailure("player fixtures: \(error)")
    }
}



func testAVAudioRecorderFailClosed() {
    let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
        "avfaudio-rec-\(UUID().uuidString).caf"
    )
    defer { try? FileManager.default.removeItem(at: url) }
    do {
        let recorder = try AVAudioRecorder(url: url, format: format)
        precondition(recorder.prepareToRecord() == false)
        precondition(recorder.record() == false)
        precondition(!recorder.isRecording)
        _ = recorder.record(atTime: 0)
        _ = recorder.record(forDuration: 0.1)
        _ = recorder.record(atTime: 0, forDuration: 0.1)
        recorder.pause()
        recorder.stop()
        _ = recorder.deleteRecording()
        recorder.updateMeters()
        _ = recorder.averagePower(forChannel: 0)
        _ = recorder.peakPower(forChannel: 0)
        _ = recorder.url
        _ = recorder.format
        _ = recorder.settings
        _ = recorder.currentTime
        _ = recorder.deviceCurrentTime
        _ = recorder.channelAssignments
        recorder.isMeteringEnabled = false
        _ = try AVAudioRecorder(URL: url, format: format)
        _ = try AVAudioRecorder(url: url, settings: format.settings)
        _ = try AVAudioRecorder(URL: url, settings: format.settings)
    } catch {
        preconditionFailure("recorder: \(error)")
    }
}



func testAVSpeechFailClosed() {
    let utterance = AVSpeechUtterance(string: "hello openuikit")
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    utterance.pitchMultiplier = 1.1
    utterance.volume = 0.8
    utterance.preUtteranceDelay = 0.01
    utterance.postUtteranceDelay = 0.02
    utterance.prefersAssistiveTechnologySettings = true
    precondition(utterance.speechString == "hello openuikit")
    let attributed = AVSpeechUtterance(attributedString: NSAttributedString(string: "depth"))
    precondition(attributed.attributedSpeechString.string == "depth")
    precondition(AVSpeechUtterance(ssmlRepresentation: "") == nil)
    let ssml = AVSpeechUtterance(SSMLRepresentation: "<speak>hi</speak>")
    precondition(ssml?.speechString.contains("hi") == true)
    let synth = AVSpeechSynthesizer()
    synth.speak(utterance)
    precondition(!synth.isSpeaking)
    precondition(!synth.isPaused)
    precondition(!synth.pauseSpeaking(at: .immediate))
    precondition(!synth.continueSpeaking())
    _ = synth.stopSpeaking(at: .word)
    synth.usesApplicationAudioSession = false
    synth.mixToTelephonyUplink = false
    synth.write(utterance) { _ in }
    synth.write(utterance, toBufferCallback: { _ in }, toMarkerCallback: { _ in })
    precondition(AVSpeechSynthesizer.personalVoiceAuthorizationStatus == .unsupported)
    precondition(AVSpeechSynthesisVoice.speechVoices().isEmpty)
    precondition(AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri") == nil)
    _ = AVSpeechSynthesisVoice(language: "en")
    _ = AVSpeechSynthesizer.availableVoicesDidChangeNotification
    precondition(!AVSpeechSynthesisVoice.currentLanguageCode().isEmpty)
    let marker = AVSpeechSynthesisMarker(wordRange: NSRange(location: 0, length: 1), atByteSampleOffset: 0)
    precondition(marker.mark == .word)
    _ = AVSpeechSynthesisMarker(sentenceRange: NSRange(location: 0, length: 1), atByteSampleOffset: 0)
    _ = AVSpeechSynthesisMarker(paragraphRange: NSRange(location: 0, length: 1), atByteSampleOffset: 0)
    _ = AVSpeechSynthesisMarker(phonemeString: "AH", atByteSampleOffset: 0)
    _ = AVSpeechSynthesisMarker(bookmarkName: "b", atByteSampleOffset: 0)
    let provider = AVSpeechSynthesisProviderVoice(
        name: "x",
        identifier: "id",
        primaryLanguages: ["en"],
        supportedLanguages: ["en"]
    )
    provider.age = 30
    provider.gender = .male
    AVSpeechSynthesisProviderVoice.updateSpeechVoices()
    let request = AVSpeechSynthesisProviderRequest(
        ssmlRepresentation: "<speak>a</speak>",
        voice: provider
    )
    precondition(request.voice.identifier == "id")
    var voiceCount = 0
    let sem = DispatchSemaphore(value: 0)
    AVFAudioHostAvailability.callbackQueue.sync {
        AVSpeechSynthesizer.requestPersonalVoiceAuthorization { _ in
            voiceCount += 1
            sem.signal()
        }
    }
    precondition(sem.wait(timeout: .now() + 2) == .success)
    precondition(voiceCount == 1)
}



func testAVAudioApplicationFailClosed() {
    precondition(AVAudioApplication.shared.recordPermission == .denied)
    precondition(AVAudioApplication.shared.microphoneInjectionPermission == .serviceDisabled)
    precondition(AVAudioApplication.shared.isInputMuted)
    do {
        try AVAudioApplication.shared.setInputMuted(true)
        preconditionFailure("setInputMuted")
    } catch {}
    _ = AVAudioApplication.inputMuteStateChangeNotification
    _ = AVAudioApplication.muteStateKey
    var count = 0
    let sem = DispatchSemaphore(value: 0)
    AVFAudioHostAvailability.callbackQueue.sync {
        AVAudioApplication.requestRecordPermission { _ in
            count += 1
            sem.signal()
        }
    }
    precondition(sem.wait(timeout: .now() + 2) == .success)
    precondition(count == 1)
}



func testAVAudio3DHelpers() {
    let point = AVAudioMake3DPoint(1, 2, 3)
    precondition(point.x == 1 && point.y == 2 && point.z == 3)
    let orientation = AVAudioMake3DAngularOrientation(0.1, 0.2, 0.3)
    precondition(orientation.pitch == 0.2)
    let vector = AVAudioMake3DVectorOrientation(
        AVAudioMake3DVector(0, 0, 1),
        AVAudioMake3DVector(0, 1, 0)
    )
    precondition(vector.up.y == 1)
    let env = AVAudioEnvironmentNode()
    env.outputVolume = 0.8
    env.outputType = .headphones
    env.listenerPosition = AVAudioMake3DPoint(0, 0, 0)
    env.listenerAngularOrientation = AVAudioMake3DAngularOrientation(0, 0, 0)
    env.listenerVectorOrientation = vector
    env.distanceAttenuationParameters.rolloffFactor = 2
    env.reverbParameters.enable = true
    env.reverbParameters.loadFactoryReverbPreset(.plate)
    precondition(env.applicableRenderingAlgorithms.isEmpty)
}



func testAVAudioUnitsAndSampler() {
    let delay = AVAudioUnitDelay()
    delay.delayTime = 0.2
    delay.feedback = 20
    delay.lowPassCutoff = 8000
    delay.wetDryMix = 40
    precondition(delay.delayTime == 0.2)
    let eq = AVAudioUnitEQ(numberOfBands: 3)
    precondition(eq.bands.count == 3)
    let distortion = AVAudioUnitDistortion()
    distortion.preGain = -3
    distortion.wetDryMix = 25
    distortion.loadFactoryPreset(.drumsLoFi)
    let reverb = AVAudioUnitReverb()
    reverb.wetDryMix = 30
    reverb.loadFactoryPreset(.mediumHall)
    let pitch = AVAudioUnitTimePitch()
    pitch.rate = 1.1
    pitch.pitch = 50
    pitch.overlap = 4
    let vari = AVAudioUnitVarispeed()
    vari.rate = 0.9
    let sampler = AVAudioUnitSampler()
    sampler.masterGain = -3
    sampler.globalTuning = 10
    sampler.stereoPan = 0.1
    sampler.startNote(60, withVelocity: 100, onChannel: 0)
    sampler.stopNote(60, onChannel: 0)
    sampler.sendController(1, withValue: 64, onChannel: 0)
    sampler.sendPitchBend(8192, onChannel: 0)
    sampler.sendPressure(10, onChannel: 0)
    sampler.sendPressure(forKey: 60, withValue: 20, onChannel: 0)
    sampler.sendProgramChange(0, onChannel: 0)
    sampler.sendProgramChange(0, bankMSB: 0, bankLSB: 0, onChannel: 0)
    sampler.sendMIDIEvent(0x90, data1: 60)
    sampler.sendMIDIEvent(0x90, data1: 60, data2: 100)
    sampler.sendMIDISysExEvent(Data([0xf0, 0xf7]))
    do {
        try sampler.loadSoundBankInstrument(
            at: URL(fileURLWithPath: "/tmp/missing.sf2"),
            program: 0,
            bankMSB: 0x79,
            bankLSB: 0
        )
        preconditionFailure("sampler bank")
    } catch {}
    do { try sampler.loadInstrument(at: URL(fileURLWithPath: "/tmp/missing.aupreset")); preconditionFailure("instrument") } catch {}
    do { try sampler.loadAudioFiles(at: [URL(fileURLWithPath: "/tmp/missing.wav")]); preconditionFailure("files") } catch {}
    let component = AVAudioUnitComponent(name: "test", typeName: AVAudioUnitTypeEffect)
    precondition(component.isSandboxSafe)
    precondition(AVAudioUnitComponentManager.shared().tagNames.isEmpty)
    precondition(AVAudioUnitComponentManager.shared().components(matching: NSPredicate(value: true)).isEmpty)
    _ = AVAudioUnitComponentManager.registrationsChangedNotification
    _ = delay.name
    _ = delay.manufacturerName
    _ = delay.version
    do { try delay.loadPreset(at: URL(fileURLWithPath: "/tmp/missing.aupreset")) } catch {}
}



func testAVAudioMIDISequencer() {
    let sequencer = AVAudioSequencer()
    let track = sequencer.createAndAppendTrack()
    track.isLoopingEnabled = true
    track.isMuted = false
    track.numberOfLoops = AVMusicTrackLoopCount.forever.rawValue
    track.loopRange = AVMakeBeatRange(0, 4)
    track.addEvent(AVMIDINoteEvent(channel: 0, key: 64, velocity: 80, duration: 0.5), at: 1)
    track.addEvent(AVMIDIControlChangeEvent(channel: 0, messageType: .volume, value: 100), at: 0)
    track.addEvent(AVMIDIPitchBendEvent(channel: 0, value: 0), at: 0)
    track.addEvent(AVMIDIProgramChangeEvent(channel: 0, programNumber: 1), at: 0)
    track.addEvent(AVMIDIChannelPressureEvent(channel: 0, pressure: 1), at: 0)
    track.addEvent(AVMIDIPolyPressureEvent(channel: 0, key: 60, pressure: 1), at: 0)
    track.addEvent(AVMIDIMetaEvent(type: .tempo, data: Data([1, 2, 3])), at: 0)
    track.addEvent(AVMIDISysexEvent(data: Data([0xf0, 0xf7])), at: 0)
    track.addEvent(AVMusicUserEvent(data: Data([1])), at: 0)
    track.addEvent(AVParameterEvent(parameterID: 1, scope: 0, element: 0, value: 0.5), at: 0)
    track.addEvent(AVExtendedTempoEvent(tempo: 120), at: 0)
    track.addEvent(
        AVExtendedNoteOnEvent(midiNote: 60, velocity: 100, instrumentID: 0, groupID: 0, duration: 1),
        at: 0
    )
    precondition(AVExtendedNoteOnEvent.defaultInstrument != 0)
    track.addEvent(AVAUPresetEvent(scope: 0, element: 0, dictionary: [:]), at: 0)
    track.enumerateEvents(in: AVMakeBeatRange(0, 16)) { _, _, stop in
        stop.pointee = true
    }
    track.moveEvents(in: AVMakeBeatRange(0, 1), by: 0.5)
    let other = sequencer.createAndAppendTrack()
    other.copyEvents(in: AVMakeBeatRange(0, 16), from: track, insertAt: 0)
    other.copyAndMergeEvents(in: AVMakeBeatRange(0, 16), from: track, mergeAt: 0)
    track.clearEvents(in: AVMakeBeatRange(0, 16))
    precondition(sequencer.removeTrack(other))
    sequencer.reverseEvents()
    sequencer.setUserCallback(nil)
    _ = sequencer.beats(forSeconds: 1)
    _ = sequencer.seconds(forBeats: 1)
    _ = AVAudioSequencer.InfoDictionaryKey.album
    _ = AVAudioSequencer.InfoDictionaryKey.approximateDurationInSeconds
    _ = AVAudioSequencer.InfoDictionaryKey.artist
    _ = AVAudioSequencer.InfoDictionaryKey.channelLayout
    _ = AVAudioSequencer.InfoDictionaryKey.comments
    _ = AVAudioSequencer.InfoDictionaryKey.composer
    _ = AVAudioSequencer.InfoDictionaryKey.copyright
    _ = AVAudioSequencer.InfoDictionaryKey.encodingApplication
    _ = AVAudioSequencer.InfoDictionaryKey.genre
    _ = AVAudioSequencer.InfoDictionaryKey.ISRC
    _ = AVAudioSequencer.InfoDictionaryKey.keySignature
    _ = AVAudioSequencer.InfoDictionaryKey.lyricist
    _ = AVAudioSequencer.InfoDictionaryKey.nominalBitRate
    _ = AVAudioSequencer.InfoDictionaryKey.recordedDate
    _ = AVAudioSequencer.InfoDictionaryKey.sourceBitDepth
    _ = AVAudioSequencer.InfoDictionaryKey.sourceEncoder
    _ = AVAudioSequencer.InfoDictionaryKey.subTitle
    _ = AVAudioSequencer.InfoDictionaryKey.tempo
    _ = AVAudioSequencer.InfoDictionaryKey.timeSignature
    _ = AVAudioSequencer.InfoDictionaryKey.title
    _ = AVAudioSequencer.InfoDictionaryKey.trackNumber
    _ = AVAudioSequencer.InfoDictionaryKey.year
    do {
        try sequencer.start()
        preconditionFailure("sequencer start")
    } catch {}
    precondition(!sequencer.isPlaying)
    sequencer.stop()
    do {
        _ = try AVMIDIPlayer(contentsOf: URL(fileURLWithPath: "/tmp/missing.mid"), soundBankURL: nil)
        preconditionFailure("midi player")
    } catch {}
}



func testAVFAudioHostAvailability() {
    precondition(!AVFAudioHostAvailability.audioOutputAvailable)
    precondition(!AVFAudioHostAvailability.audioInputAvailable)
    precondition(!AVFAudioHostAvailability.appleSpeechVoicesAvailable)
    _ = AVFAudioHostAvailability.callbackQueue
}

func avfaudioRunAllFocusedTests() {
    testAVFAudioEnumCases()
    testAVFAudioOptionSets()
    testAVFAudioConstants()
    testAVFAudioTypealiases()
    testAVAudioFormatInits()
    testAVAudioPCMBufferLayout()
    testAVAudioTimeExtrapolation()
    testAVAudioFileContainers()
    testAVAudioConverterPCM()
    testAVAudioEngineManualRendering()
    testAVAudioEngineGraphConnections()
    testAVAudioMixingPanGain()
    testAVAudioSessionCategoryAndFailClosed()
    testAVAudioSessionPortsAndNotifications()
    testAVAudioPlayerFailClosed()
    testAVAudioRecorderFailClosed()
    testAVSpeechFailClosed()
    testAVAudioApplicationFailClosed()
    testAVAudio3DHelpers()
    testAVAudioUnitsAndSampler()
    testAVAudioMIDISequencer()
    testAVFAudioHostAvailability()
}

avfaudioRunAllFocusedTests()
print("AVFAUDIO_AGENT_RUNTIME_OK")
