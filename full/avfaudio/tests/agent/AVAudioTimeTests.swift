import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

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

