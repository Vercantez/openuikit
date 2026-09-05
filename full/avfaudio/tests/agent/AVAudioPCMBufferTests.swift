import Foundation
import AVFAudio
@_spi(OpenUIKitHost) import AVFAudio
#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

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

