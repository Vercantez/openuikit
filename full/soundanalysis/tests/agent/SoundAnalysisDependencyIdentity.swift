import Foundation
#if canImport(AVFAudio)
import AVFAudio
#endif
import SoundAnalysis

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation or
// guest-AVFAudio success.
//
// Expected EC2 steps:
// 1. Build guest Foundation and AVFAudio dylibs.
// 2. Build SoundAnalysis against those modules.
// 3. Compile this probe with the real `import AVFAudio` path taken.
// 4. Pass a genuine `AVAudioFormat` through `SNAudioStreamAnalyzer.init(format:)`
//    and a genuine Foundation `URL` through `SNAudioFileAnalyzer.init(url:)`.
// 5. Print `SOUNDANALYSIS_DEPENDENCY_IDENTITY_OK` only after those assertions.

private func assertNotSoundAnalysisType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("SoundAnalysis."))
}

func soundAnalysisDependencyIdentityProbe() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("soundanalysis-identity-\(UUID().uuidString).bin")
    try! Data([0x00]).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    assertNotSoundAnalysisType(url)

    let analyzer = try! SNAudioFileAnalyzer(url: url)
    precondition(analyzer.url == url)

#if canImport(AVFAudio)
    let format = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)
    precondition(format != nil)
    assertNotSoundAnalysisType(format!)
    let stream = SNAudioStreamAnalyzer(format: format!)
    _ = stream
#else
    // Isolated host has no AVFAudio module. The EC2 probe must take the
    // real-import path above rather than a SoundAnalysis lookalike.
#endif
}

#if SOUNDANALYSIS_IDENTITY_MAIN
soundAnalysisDependencyIdentityProbe()
print("SOUNDANALYSIS_DEPENDENCY_IDENTITY_OK")
#endif
