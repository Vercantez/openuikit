/// Extra focused test compiled with product sources so internal fail-closed
/// flexible-array arithmetic is exercised. Not part of the sealed host-gate
/// runtime probe.

@main
enum CoreAudioTypesFlexibleArrayRuntime {
    static func expect(_ condition: Bool, _ message: String) {
        if !condition {
            fatalError(message)
        }
    }

    static func main() {
        do {
            let zero = try CoreAudioTypesFlexibleArray.audioBufferListByteCount(bufferCount: 0)
            let one = try CoreAudioTypesFlexibleArray.audioBufferListByteCount(bufferCount: 1)
            let four = try CoreAudioTypesFlexibleArray.audioBufferListByteCount(bufferCount: 4)
            expect(zero == 8, "internal zero buffers")
            expect(one == MemoryLayout<AudioBufferList>.size, "internal one buffer matches struct")
            expect(four == 72, "internal four buffers")
        } catch {
            fatalError("unexpected buffer byte-count error \(error)")
        }

        do {
            _ = try CoreAudioTypesFlexibleArray.audioBufferListByteCount(bufferCount: -1)
            fatalError("negative buffer count must throw")
        } catch CoreAudioTypesFlexibleArray.Problem.negativeCount {
        } catch {
            fatalError("wrong error for negative buffer count")
        }

        let lead = MemoryLayout<AudioBufferList>.offset(of: \.mBuffers)!
        let stride = MemoryLayout<AudioBuffer>.stride
        let overflowCount = ((Int.max - lead) / stride) + 1
        do {
            _ = try CoreAudioTypesFlexibleArray.audioBufferListByteCount(bufferCount: overflowCount)
            fatalError("overflow buffer count must throw")
        } catch CoreAudioTypesFlexibleArray.Problem.overflow {
        } catch {
            fatalError("wrong error for overflow buffer count")
        }

        do {
            let four = try CoreAudioTypesFlexibleArray.audioChannelLayoutByteCount(descriptionCount: 4)
            expect(four == 92, "internal four descriptions")
        } catch {
            fatalError("unexpected channel layout byte-count error \(error)")
        }

        do {
            _ = try CoreAudioTypesFlexibleArray.audioChannelLayoutByteCount(descriptionCount: -3)
            fatalError("negative description count must throw")
        } catch CoreAudioTypesFlexibleArray.Problem.negativeCount {
        } catch {
            fatalError("wrong error for negative description count")
        }

        print("COREAUDIOTYPES_FLEXIBLE_ARRAY_OK")
    }
}
