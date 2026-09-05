import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

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

