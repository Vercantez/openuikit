import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

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

