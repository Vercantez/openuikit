import CoreAudio
import Foundation

func testAudioBufferInitFromTypedBuffer() {
    var samples = [Float](repeating: 0.5, count: 8)
    samples.withUnsafeMutableBufferPointer { typed in
        let buffer = AudioBuffer(typed, numberOfChannels: 2)
        coreAudioExpect(buffer.mNumberChannels == 2, "typed init channel count")
        coreAudioExpect(
            buffer.mDataByteSize == UInt32(8 * MemoryLayout<Float>.stride),
            "typed init byte size"
        )
        coreAudioExpect(buffer.mData == UnsafeMutableRawPointer(typed.baseAddress), "typed init pointer")
    }
}

func testUnsafeBufferPointerInitFromAudioBuffer() {
    var samples = [Int16](repeating: 7, count: 4)
    samples.withUnsafeMutableBufferPointer { typed in
        let audioBuffer = AudioBuffer(typed, numberOfChannels: 1)
        let view = UnsafeBufferPointer<Int16>(audioBuffer)
        coreAudioExpect(view.count == 4, "immutable view count")
        coreAudioExpect(view[0] == 7, "immutable view contents")
        coreAudioExpect(view[3] == 7, "immutable view last")
    }
}

func testUnsafeMutableBufferPointerInitFromAudioBuffer() {
    var samples = [Float](repeating: 0.25, count: 6)
    samples.withUnsafeMutableBufferPointer { typed in
        let audioBuffer = AudioBuffer(typed, numberOfChannels: 2)
        let view = UnsafeMutableBufferPointer<Float>(audioBuffer)
        coreAudioExpect(view.count == 6, "mutable view count")
        view[1] = 9.0
        coreAudioExpect(typed[1] == 9.0, "mutable view writes through")
    }
}
