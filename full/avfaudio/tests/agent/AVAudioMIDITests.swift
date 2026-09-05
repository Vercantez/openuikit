import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

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

