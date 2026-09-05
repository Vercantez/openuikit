import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

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

