import Foundation
import CoreHaptics

private func bridgedDomain<E: Foundation._BridgedStoredNSError>(_: E.Type) -> String {
    E._nsErrorDomain
}

private func errorTypeName<C: Foundation._ErrorCodeProtocol>(_: C.Type) -> String {
    String(describing: C._ErrorType.self)
}

private func requireCode(_ error: any Error, _ code: CHHapticError.Code) {
    guard let typed = error as? CHHapticError else {
        preconditionFailure("expected CHHapticError, got \(error)")
    }
    precondition(typed.code == code)
}

func testErrorDomain() {
    precondition(CoreHapticsErrorDomain == "CoreHapticsErrorDomain")
    precondition(CHHapticError.errorDomain == "CoreHapticsErrorDomain")
    precondition(CHHapticError.errorDomain == CoreHapticsErrorDomain)
    precondition(CHHapticError._nsErrorDomain == CoreHapticsErrorDomain)
    precondition(bridgedDomain(CHHapticError.self) == CoreHapticsErrorDomain)
}

func testErrorCodes() {
    typealias Code = CHHapticError.Code
    precondition(Code.engineNotRunning.rawValue == -4805)
    precondition(Code.operationNotPermitted.rawValue == -4806)
    precondition(Code.engineStartTimeout.rawValue == -4808)
    precondition(Code.notSupported.rawValue == -4809)
    precondition(Code.serverInitFailed.rawValue == -4810)
    precondition(Code.serverInterrupted.rawValue == -4811)
    precondition(Code.invalidPatternPlayer.rawValue == -4812)
    precondition(Code.invalidPatternData.rawValue == -4813)
    precondition(Code.invalidPatternDictionary.rawValue == -4814)
    precondition(Code.invalidAudioSession.rawValue == -4815)
    precondition(Code.invalidEngineParameter.rawValue == -4816)
    precondition(Code.invalidParameterType.rawValue == -4820)
    precondition(Code.invalidEventType.rawValue == -4821)
    precondition(Code.invalidEventTime.rawValue == -4822)
    precondition(Code.invalidEventDuration.rawValue == -4823)
    precondition(Code.invalidAudioResource.rawValue == -4824)
    precondition(Code.resourceNotAvailable.rawValue == -4825)
    precondition(Code.badEventEntry.rawValue == -4830)
    precondition(Code.badParameterEntry.rawValue == -4831)
    precondition(Code.invalidTime.rawValue == -4840)
    precondition(Code.fileNotFound.rawValue == -4851)
    precondition(Code.insufficientPower.rawValue == -4897)
    precondition(Code.unknownError.rawValue == -4898)
    precondition(Code.memoryError.rawValue == -4899)

    precondition(CHHapticError.engineNotRunning == .engineNotRunning)
    precondition(CHHapticError.operationNotPermitted == .operationNotPermitted)
    precondition(CHHapticError.engineStartTimeout == .engineStartTimeout)
    precondition(CHHapticError.notSupported == .notSupported)
    precondition(CHHapticError.serverInitFailed == .serverInitFailed)
    precondition(CHHapticError.serverInterrupted == .serverInterrupted)
    precondition(CHHapticError.invalidPatternPlayer == .invalidPatternPlayer)
    precondition(CHHapticError.invalidPatternData == .invalidPatternData)
    precondition(CHHapticError.invalidPatternDictionary == .invalidPatternDictionary)
    precondition(CHHapticError.invalidAudioSession == .invalidAudioSession)
    precondition(CHHapticError.invalidEngineParameter == .invalidEngineParameter)
    precondition(CHHapticError.invalidParameterType == .invalidParameterType)
    precondition(CHHapticError.invalidEventType == .invalidEventType)
    precondition(CHHapticError.invalidEventTime == .invalidEventTime)
    precondition(CHHapticError.invalidEventDuration == .invalidEventDuration)
    precondition(CHHapticError.invalidAudioResource == .invalidAudioResource)
    precondition(CHHapticError.resourceNotAvailable == .resourceNotAvailable)
    precondition(CHHapticError.badEventEntry == .badEventEntry)
    precondition(CHHapticError.badParameterEntry == .badParameterEntry)
    precondition(CHHapticError.invalidTime == .invalidTime)
    precondition(CHHapticError.fileNotFound == .fileNotFound)
    precondition(CHHapticError.insufficientPower == .insufficientPower)
    precondition(CHHapticError.unknownError == .unknownError)
    precondition(CHHapticError.memoryError == .memoryError)

    precondition(Code(rawValue: -4805) == .engineNotRunning)
    precondition(Code(rawValue: -4899) == .memoryError)
    precondition(Code(rawValue: 0) == nil)
    precondition(Code.notSupported != .engineNotRunning)
    precondition(errorTypeName(Code.self) == String(describing: CHHapticError.self))
}

func testErrorEqualityAndHash() {
    let empty = CHHapticError(.notSupported)
    precondition(empty.errorCode == -4809)
    precondition(empty.code == .notSupported)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo[NSLocalizedDescriptionKey] == nil || empty.errorCode == -4809)

    let sentinel = CHHapticError(.notSupported, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(empty == CHHapticError(.notSupported))
    precondition(sentinel != empty)
    precondition(empty != CHHapticError(.engineNotRunning))

    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    CHHapticError(.notSupported).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    _ = empty.hashValue

    precondition(CHHapticError.Code.notSupported.hashValue == CHHapticError.Code.notSupported.hashValue)
    var codeHasher = Hasher()
    CHHapticError.Code.invalidTime.hash(into: &codeHasher)
    _ = codeHasher.finalize()
    _ = CHHapticError.Code.notSupported.hashValue
    testErrorNSErrorBridge()
}

func testErrorPatternMatch() {
    let error: any Error = CHHapticError(.operationNotPermitted)
    precondition(CHHapticError.Code.operationNotPermitted ~= error)
    precondition(!(CHHapticError.Code.notSupported ~= error))
    do {
        throw CHHapticError(.engineNotRunning)
    } catch let caught as CHHapticError where caught.code == .engineNotRunning {
        ()
    } catch {
        preconditionFailure("expected Code.engineNotRunning pattern match")
    }
}

func testErrorNSErrorBridge() {
    let userInfo: [String: Any] = ["ch": "bridge"]
    let real = CHHapticError(.serverInitFailed, userInfo: userInfo)
    precondition(real._nsError.domain == CoreHapticsErrorDomain)
    precondition(real._nsError.code == -4810)
    precondition(real._nsError.userInfo["ch"] as? String == "bridge")

    let bridged = real as NSError
    precondition(bridged.domain == CoreHapticsErrorDomain)
    precondition(bridged.code == CHHapticError.Code.serverInitFailed.rawValue)

    let fromStored = CHHapticError(_nsError: real._nsError)
    precondition(fromStored.code == .serverInitFailed)
    precondition(fromStored == real)
}

func testTimeImmediateAndAudioResourceKeys() {
    precondition(CHHapticTimeImmediate == 0)
    precondition(CHHapticAudioResourceKeyLoopEnabled == "CHHapticAudioResourceKeyLoopEnabled")
    precondition(
        CHHapticAudioResourceKeyUseVolumeEnvelope == "CHHapticAudioResourceKeyUseVolumeEnvelope"
    )
    let _: CHHapticAudioResourceKey = CHHapticAudioResourceKeyLoopEnabled as NSString
    let id: CHHapticAudioResourceID = 7
    precondition(id == 7)
}

func testEventParameterIDs() {
    typealias ID = CHHapticEvent.ParameterID
    precondition(ID.hapticIntensity.rawValue == "HapticIntensity")
    precondition(ID.hapticSharpness.rawValue == "HapticSharpness")
    precondition(ID.attackTime.rawValue == "AttackTime")
    precondition(ID.decayTime.rawValue == "DecayTime")
    precondition(ID.releaseTime.rawValue == "ReleaseTime")
    precondition(ID.sustained.rawValue == "Sustained")
    precondition(ID.audioVolume.rawValue == "AudioVolume")
    precondition(ID.audioPitch.rawValue == "AudioPitch")
    precondition(ID.audioPan.rawValue == "AudioPan")
    precondition(ID.audioBrightness.rawValue == "AudioBrightness")
    precondition(ID(rawValue: "HapticIntensity") == .hapticIntensity)
    precondition(ID.hapticIntensity != .hapticSharpness)
    var hasher = Hasher()
    ID.audioVolume.hash(into: &hasher)
    _ = hasher.finalize()
    _ = ID.hapticIntensity.hashValue
}

func testDynamicParameterIDs() {
    typealias ID = CHHapticDynamicParameter.ID
    precondition(ID.hapticIntensityControl.rawValue == "HapticIntensityControl")
    precondition(ID.hapticSharpnessControl.rawValue == "HapticSharpnessControl")
    precondition(ID.hapticAttackTimeControl.rawValue == "HapticAttackTimeControl")
    precondition(ID.hapticDecayTimeControl.rawValue == "HapticDecayTimeControl")
    precondition(ID.hapticReleaseTimeControl.rawValue == "HapticReleaseTimeControl")
    precondition(ID.audioVolumeControl.rawValue == "AudioVolumeControl")
    precondition(ID.audioPanControl.rawValue == "AudioPanControl")
    precondition(ID.audioBrightnessControl.rawValue == "AudioBrightnessControl")
    precondition(ID.audioPitchControl.rawValue == "AudioPitchControl")
    precondition(ID.audioAttackTimeControl.rawValue == "AudioAttackTimeControl")
    precondition(ID.audioDecayTimeControl.rawValue == "AudioDecayTimeControl")
    precondition(ID.audioReleaseTimeControl.rawValue == "AudioReleaseTimeControl")
    precondition(ID(rawValue: "HapticIntensityControl") == .hapticIntensityControl)
    precondition(ID.hapticIntensityControl != .audioVolumeControl)
    var hasher = Hasher()
    ID.audioPitchControl.hash(into: &hasher)
    _ = hasher.finalize()
    _ = ID.hapticSharpnessControl.hashValue
}

func testEventTypes() {
    typealias T = CHHapticEvent.EventType
    precondition(T.hapticTransient.rawValue == "HapticTransient")
    precondition(T.hapticContinuous.rawValue == "HapticContinuous")
    precondition(T.audioContinuous.rawValue == "AudioContinuous")
    precondition(T.audioCustom.rawValue == "AudioCustom")
    precondition(T(rawValue: "HapticTransient") == .hapticTransient)
    precondition(T.hapticTransient != .hapticContinuous)
    var hasher = Hasher()
    T.audioCustom.hash(into: &hasher)
    _ = hasher.finalize()
    _ = T.hapticContinuous.hashValue
}

func testPatternKeys() {
    typealias Key = CHHapticPattern.Key
    precondition(Key.version.rawValue == "Version")
    precondition(Key.pattern.rawValue == "Pattern")
    precondition(Key.event.rawValue == "Event")
    precondition(Key.eventType.rawValue == "EventType")
    precondition(Key.time.rawValue == "Time")
    precondition(Key.eventDuration.rawValue == "EventDuration")
    precondition(Key.eventWaveformPath.rawValue == "EventWaveformPath")
    precondition(Key.eventParameters.rawValue == "EventParameters")
    precondition(Key.parameter.rawValue == "Parameter")
    precondition(Key.parameterID.rawValue == "ParameterID")
    precondition(Key.parameterValue.rawValue == "ParameterValue")
    precondition(Key.parameterCurve.rawValue == "ParameterCurve")
    precondition(Key.parameterCurveControlPoints.rawValue == "ParameterCurveControlPoints")
    precondition(Key.eventWaveformUseVolumeEnvelope.rawValue == "EventWaveformUseVolumeEnvelope")
    precondition(Key.eventWaveformLoopEnabled.rawValue == "EventWaveformLoopEnabled")
    precondition(Key(rawValue: "Version") == .version)
    precondition(Key.event != .parameter)
    var hasher = Hasher()
    Key.pattern.hash(into: &hasher)
    _ = hasher.finalize()
    _ = Key.time.hashValue
}

func testEventAndParameterStorage() {
    let parameter = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
    precondition(parameter.parameterID == .hapticIntensity)
    parameter.value = 0.9
    precondition(parameter.value == 0.9)

    let dynamic = CHHapticDynamicParameter(
        parameterID: .hapticSharpnessControl,
        value: 0.2,
        relativeTime: 0.15
    )
    precondition(dynamic.parameterID == .hapticSharpnessControl)
    dynamic.value = 0.3
    dynamic.relativeTime = 0.2
    precondition(dynamic.value == 0.3)
    precondition(dynamic.relativeTime == 0.2)

    let transient = CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [parameter],
        relativeTime: CHHapticTimeImmediate
    )
    precondition(transient.type == .hapticTransient)
    precondition(transient.eventParameters.count == 1)
    precondition(transient.relativeTime == 0)
    precondition(transient.duration == 0)
    transient.relativeTime = 0.05
    transient.duration = 0.1
    precondition(transient.relativeTime == 0.05)
    precondition(transient.duration == 0.1)

    let continuous = CHHapticEvent(
        eventType: .hapticContinuous,
        parameters: [],
        relativeTime: 0.25,
        duration: 0.5
    )
    precondition(continuous.type == .hapticContinuous)
    precondition(continuous.duration == 0.5)

    let custom = CHHapticEvent(
        audioResourceID: 11,
        parameters: [],
        relativeTime: 0
    )
    precondition(custom.type == .audioCustom)
    precondition(custom.audioResourceID == 11)

    let customTimed = CHHapticEvent(
        audioResourceID: 12,
        parameters: [],
        relativeTime: 0.1,
        duration: 0.4
    )
    precondition(customTimed.duration == 0.4)
    precondition(customTimed.audioResourceID == 12)
}

func testParameterCurveStorage() {
    let point = CHHapticParameterCurve.ControlPoint(relativeTime: 0.1, value: 0.5)
    point.relativeTime = 0.2
    point.value = 0.7
    precondition(point.relativeTime == 0.2)
    precondition(point.value == 0.7)

    let curve = CHHapticParameterCurve(
        parameterID: .hapticIntensityControl,
        controlPoints: [point],
        relativeTime: 0.05
    )
    precondition(curve.parameterID == .hapticIntensityControl)
    precondition(curve.controlPoints.count == 1)
    curve.relativeTime = 0.08
    precondition(curve.relativeTime == 0.08)
}

func testPatternFromEventsAndCurves() {
    let event = CHHapticEvent(
        eventType: .hapticContinuous,
        parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)],
        relativeTime: 0.25,
        duration: 0.5
    )
    let parameter = CHHapticDynamicParameter(
        parameterID: .hapticIntensityControl,
        value: 0.5,
        relativeTime: 0.125
    )
    let pattern: CHHapticPattern
    do {
        pattern = try CHHapticPattern(events: [event], parameters: [parameter])
    } catch {
        preconditionFailure("pattern(events:parameters:) failed: \(error)")
    }
    precondition(pattern.duration == 0.75)
    precondition(pattern.events.count == 1)
    precondition(pattern.parameters.count == 1)

    let curve = CHHapticParameterCurve(
        parameterID: .hapticSharpnessControl,
        controlPoints: [
            CHHapticParameterCurve.ControlPoint(relativeTime: 0.0, value: 0.1),
            CHHapticParameterCurve.ControlPoint(relativeTime: 1.0, value: 0.9),
        ],
        relativeTime: 0.25
    )
    let curved: CHHapticPattern
    do {
        curved = try CHHapticPattern(events: [event], parameterCurves: [curve])
    } catch {
        preconditionFailure("pattern(events:parameterCurves:) failed: \(error)")
    }
    precondition(curved.duration == 1.25)
    precondition(curved.parameterCurves.count == 1)
    testPatternRejectsNegativeTimes()
}

func testPatternRejectsNegativeTimes() {
    let badTime = CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [],
        relativeTime: -0.1
    )
    do {
        _ = try CHHapticPattern(events: [badTime], parameters: [])
        preconditionFailure("negative event time must fail")
    } catch {
        requireCode(error, .invalidEventTime)
    }

    let badDuration = CHHapticEvent(
        eventType: .hapticContinuous,
        parameters: [],
        relativeTime: 0,
        duration: -1
    )
    do {
        _ = try CHHapticPattern(events: [badDuration], parameters: [])
        preconditionFailure("negative duration must fail")
    } catch {
        requireCode(error, .invalidEventDuration)
    }

    let badParameter = CHHapticDynamicParameter(
        parameterID: .hapticIntensityControl,
        value: 1,
        relativeTime: -2
    )
    do {
        _ = try CHHapticPattern(
            events: [
                CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)
            ],
            parameters: [badParameter]
        )
        preconditionFailure("negative parameter time must fail")
    } catch {
        requireCode(error, .invalidTime)
    }
}

func testPatternDictionaryRoundTrip() {
    let event = CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
        ],
        relativeTime: 0.05
    )
    let parameter = CHHapticDynamicParameter(
        parameterID: .hapticIntensityControl,
        value: 0.4,
        relativeTime: 0.1
    )
    let original: CHHapticPattern
    do {
        original = try CHHapticPattern(events: [event], parameters: [parameter])
    } catch {
        preconditionFailure("original pattern failed: \(error)")
    }
    let exported: [CHHapticPattern.Key: Any]
    do {
        exported = try original.exportDictionary()
    } catch {
        preconditionFailure("export failed: \(error)")
    }
    precondition(exported[.version] as? Double == 1.0)
    let restored: CHHapticPattern
    do {
        restored = try CHHapticPattern(dictionary: exported)
    } catch {
        preconditionFailure("restore failed: \(error)")
    }
    precondition(restored.events.count == 1)
    precondition(restored.events[0].type == .hapticTransient)
    precondition(restored.events[0].eventParameters.count == 2)
    precondition(restored.parameters.count == 1)
    precondition(restored.parameters[0].parameterID == .hapticIntensityControl)
    testPatternInvalidDictionary()
}

func testPatternInvalidDictionary() {
    do {
        _ = try CHHapticPattern(dictionary: [:])
        preconditionFailure("empty dictionary must fail")
    } catch {
        requireCode(error, .invalidPatternDictionary)
    }

    do {
        _ = try CHHapticPattern(dictionary: [.pattern: "not-an-array"])
        preconditionFailure("non-array pattern must fail")
    } catch {
        requireCode(error, .invalidPatternDictionary)
    }
}

func testPatternFromURLAndPlayPattern() {
    let event = CHHapticEvent(
        eventType: .audioContinuous,
        parameters: [CHHapticEventParameter(parameterID: .audioVolume, value: 0.5)],
        relativeTime: 0,
        duration: 0.2
    )
    let pattern: CHHapticPattern
    do {
        pattern = try CHHapticPattern(events: [event], parameters: [])
    } catch {
        preconditionFailure("pattern failed: \(error)")
    }
    let exported = try! pattern.exportDictionary()
    var jsonObject: [String: Any] = [:]
    jsonObject["Version"] = exported[.version]
    jsonObject["Pattern"] = [
        [
            "Event": [
                "EventType": "AudioContinuous",
                "Time": 0.0,
                "EventDuration": 0.2,
                "EventParameters": [
                    ["ParameterID": "AudioVolume", "ParameterValue": 0.5]
                ],
            ]
        ]
    ]
    let data = try! JSONSerialization.data(withJSONObject: jsonObject)
    let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let fileURL = directory.appendingPathComponent("corehaptics-host.ahap")
    try! data.write(to: fileURL)

    let fromURL: CHHapticPattern
    do {
        fromURL = try CHHapticPattern(contentsOf: fileURL)
    } catch {
        preconditionFailure("contentsOf failed: \(error)")
    }
    precondition(fromURL.events.count == 1)
    precondition(fromURL.events[0].type == .audioContinuous)

    let fromURLAlias: CHHapticPattern
    do {
        fromURLAlias = try CHHapticPattern(contentsOfURL: fileURL)
    } catch {
        preconditionFailure("contentsOfURL failed: \(error)")
    }
    precondition(fromURLAlias.events.count == 1)

    let engine = try! CHHapticEngine()
    do {
        try engine.playPattern(from: data)
        preconditionFailure("playPattern(data) must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }
    do {
        try engine.playPattern(from: fileURL)
        preconditionFailure("playPattern(url) must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }

    do {
        try engine.playPattern(from: Data())
        preconditionFailure("empty playPattern data must fail")
    } catch {
        requireCode(error, .invalidPatternData)
    }

    do {
        _ = try CHHapticPattern(contentsOf: URL(fileURLWithPath: "/tmp/missing-corehaptics.ahap"))
        preconditionFailure("missing file must fail")
    } catch {
        requireCode(error, .fileNotFound)
    }
}

func testEngineFailClosed() {
    let engine = try! CHHapticEngine()
    precondition(!engine.isRunning)
    precondition(engine.currentTime == 0)
    precondition(!engine.playsHapticsOnly)
    precondition(!engine.playsAudioOnly)
    precondition(!engine.isMutedForAudio)
    precondition(!engine.isMutedForHaptics)
    precondition(!engine.isAutoShutdownEnabled)

    engine.playsHapticsOnly = true
    engine.playsAudioOnly = true
    engine.isMutedForAudio = true
    engine.isMutedForHaptics = true
    engine.isAutoShutdownEnabled = true
    precondition(engine.playsHapticsOnly)
    precondition(engine.playsAudioOnly)
    precondition(engine.isMutedForAudio)
    precondition(engine.isMutedForHaptics)
    precondition(engine.isAutoShutdownEnabled)

    var stopped: CHHapticEngine.StoppedReason?
    engine.stoppedHandler = { reason in stopped = reason }
    var resetCount = 0
    engine.resetHandler = { resetCount += 1 }
    engine.stoppedHandler(.idleTimeout)
    engine.resetHandler()
    precondition(stopped == .idleTimeout)
    precondition(resetCount == 1)

    do {
        try engine.start()
        preconditionFailure("start() must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }
    precondition(engine.startAttempts == 1)
    precondition(!engine.isRunning)

    var completion: (any Error)?
    var completionCalls = 0
    engine.start { error in
        completion = error
        completionCalls += 1
    }
    precondition(completionCalls == 1)
    requireCode(completion!, .notSupported)
    precondition(engine.startAttempts == 2)

    engine.start(completionHandler: nil)
    precondition(engine.startAttempts == 3)

    var stopCalls = 0
    engine.stop { error in
        precondition(error == nil)
        stopCalls += 1
    }
    precondition(stopCalls == 1)

    var finishedCalls = 0
    engine.notifyWhenPlayersFinished { error in
        finishedCalls += 1
        requireCode(error!, .notSupported)
        return .stopEngine
    }
    precondition(finishedCalls == 1)

    do {
        _ = try engine.registerAudioResource(
            URL(fileURLWithPath: "/tmp/tone.wav"),
            options: [CHHapticAudioResourceKeyLoopEnabled: false]
        )
        preconditionFailure("registerAudioResource must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }
    do {
        try engine.unregisterAudioResource(1)
        preconditionFailure("unregisterAudioResource must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }

    let viaSynthesized = try! CHHapticEngine(andReturnError: ())
    precondition(!viaSynthesized.isRunning)
}

func testCapabilities() {
    let capability = CHHapticEngine.capabilitiesForHardware()
    precondition(!capability.supportsHaptics)
    precondition(!capability.supportsAudio)
    do {
        _ = try capability.attributes(forDynamicParameter: .hapticIntensityControl)
        preconditionFailure("dynamic attributes must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }
    do {
        _ = try capability.attributes(
            forEventParameter: .hapticIntensity,
            eventType: .hapticTransient
        )
        preconditionFailure("event attributes must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }
}

func testPlayersFailClosed() {
    let event = CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)],
        relativeTime: 0
    )
    let pattern = try! CHHapticPattern(events: [event], parameters: [])
    let engine = try! CHHapticEngine()
    let player = try! engine.makePlayer(with: pattern)
    precondition(!player.isMuted)
    player.isMuted = true
    precondition(player.isMuted)

    do {
        try player.start(atTime: CHHapticTimeImmediate)
        preconditionFailure("player start must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }
    try! player.stop(atTime: 0)
    try! player.cancel()
    do {
        try player.sendParameters(
            [
                CHHapticDynamicParameter(
                    parameterID: .hapticIntensityControl,
                    value: 0.5,
                    relativeTime: 0
                )
            ],
            atTime: 0
        )
        preconditionFailure("sendParameters must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }
    do {
        try player.scheduleParameterCurve(
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1)
                ],
                relativeTime: 0
            ),
            atTime: 0
        )
        preconditionFailure("scheduleParameterCurve must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }

    let advanced = try! engine.makeAdvancedPlayer(with: pattern)
    advanced.loopEnabled = true
    advanced.loopEnd = 0.4
    advanced.playbackRate = 1.5
    var completions = 0
    advanced.completionHandler = { _ in completions += 1 }
    advanced.completionHandler(nil)
    precondition(advanced.loopEnabled)
    precondition(advanced.loopEnd == 0.4)
    precondition(advanced.playbackRate == 1.5)
    precondition(completions == 1)
    do {
        try advanced.pause(atTime: 0)
        preconditionFailure("pause must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }
    do {
        try advanced.resume(atTime: 0)
        preconditionFailure("resume must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }
    do {
        try advanced.seek(toOffset: 0.1)
        preconditionFailure("seek must stay fail-closed")
    } catch {
        requireCode(error, .notSupported)
    }

    let portable = CHHapticPortablePatternPlayer(pattern: pattern)
    precondition(portable.startAttempts == 0)
}

func testStoppedReasonAndFinishedAction() {
    typealias Reason = CHHapticEngine.StoppedReason
    typealias Action = CHHapticEngine.FinishedAction
    precondition(Reason.audioSessionInterrupt.rawValue == 1)
    precondition(Reason.applicationSuspended.rawValue == 2)
    precondition(Reason.idleTimeout.rawValue == 3)
    precondition(Reason.notifyWhenFinished.rawValue == 4)
    precondition(Reason.engineDestroyed.rawValue == 5)
    precondition(Reason.gameControllerDisconnect.rawValue == 6)
    precondition(Reason.systemError.rawValue == -1)
    precondition(Reason(rawValue: 3) == .idleTimeout)
    precondition(Reason(rawValue: 99) == nil)
    precondition(Reason.idleTimeout != .systemError)
    var reasonHasher = Hasher()
    Reason.notifyWhenFinished.hash(into: &reasonHasher)
    _ = reasonHasher.finalize()
    _ = Reason.engineDestroyed.hashValue

    precondition(Action.stopEngine.rawValue == 1)
    precondition(Action.leaveEngineRunning.rawValue == 2)
    precondition(Action(rawValue: 1) == .stopEngine)
    precondition(Action(rawValue: 0) == nil)
    precondition(Action.stopEngine != .leaveEngineRunning)
    var actionHasher = Hasher()
    Action.leaveEngineRunning.hash(into: &actionHasher)
    _ = actionHasher.finalize()
    _ = Action.stopEngine.hashValue
}
