import Foundation
import MediaToolbox

func testTapCreateInitStorageAndIdentity() {
    var stored: UnsafeMutableRawPointer? = nil
    let client = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<UInt>.stride, alignment: MemoryLayout<UInt>.alignment)
    defer { client.deallocate() }
    client.storeBytes(of: UInt(0x4D545450), as: UInt.self)

    let callbacks = MTAudioProcessingTapCallbacks(
        version: kMTAudioProcessingTapCallbacksVersion_0,
        clientInfo: client,
        init: { _, info, storage in
            storage.pointee = info
        },
        finalize: nil,
        prepare: nil,
        unprepare: nil,
        process: mtNoopProcess
    )

    var tap: MTAudioProcessingTap?
    let status = withUnsafePointer(to: callbacks) { pointer in
        withUnsafeMutablePointer(to: &tap) { tapOut in
            MTAudioProcessingTapCreate(
                nil,
                pointer,
                kMTAudioProcessingTapCreationFlag_PreEffects,
                tapOut
            )
        }
    }
    mtExpect(status == 0, "create pre-effects")
    guard let created = tap else {
        fatalError("MEDIATOOLBOX_RUNTIME_FAIL expected tap")
    }
    stored = MTAudioProcessingTapGetStorage(created)
    mtExpect(stored == client, "storage is clientInfo from init")
    mtExpect(type(of: created) == MTAudioProcessingTap.self, "class identity")

    var rejected: MTAudioProcessingTap? = Optional(created)
    let bothFlags = kMTAudioProcessingTapCreationFlag_PreEffects
        | kMTAudioProcessingTapCreationFlag_PostEffects
    let bothStatus = withUnsafePointer(to: callbacks) { pointer in
        withUnsafeMutablePointer(to: &rejected) { tapOut in
            MTAudioProcessingTapCreate(nil, pointer, bothFlags, tapOut)
        }
    }
    mtExpect(bothStatus == kMTAudioProcessingTapInvalidArgumentErr, "both flags rejected")
    mtExpect(rejected == nil, "tapOut nil after both-flags reject")

    var zeroTap: MTAudioProcessingTap? = Optional(created)
    let zeroStatus = withUnsafePointer(to: callbacks) { pointer in
        withUnsafeMutablePointer(to: &zeroTap) { tapOut in
            MTAudioProcessingTapCreate(nil, pointer, 0, tapOut)
        }
    }
    mtExpect(zeroStatus == kMTAudioProcessingTapInvalidArgumentErr, "zero flags rejected")
    mtExpect(zeroTap == nil, "tapOut nil after zero-flags reject")

    var badVersion = callbacks
    badVersion.version = 1
    var versionTap: MTAudioProcessingTap? = Optional(created)
    let versionStatus = withUnsafePointer(to: badVersion) { pointer in
        withUnsafeMutablePointer(to: &versionTap) { tapOut in
            MTAudioProcessingTapCreate(
                nil,
                pointer,
                kMTAudioProcessingTapCreationFlag_PostEffects,
                tapOut
            )
        }
    }
    mtExpect(versionStatus == kMTAudioProcessingTapInvalidArgumentErr, "bad version rejected")
    mtExpect(versionTap == nil, "tapOut nil after version reject")
}

func testTapEqualityAndHash() {
    let callbacks = MTAudioProcessingTapCallbacks(
        version: kMTAudioProcessingTapCallbacksVersion_0,
        clientInfo: nil,
        init: nil,
        finalize: nil,
        prepare: nil,
        unprepare: nil,
        process: mtNoopProcess
    )

    var first: MTAudioProcessingTap?
    var second: MTAudioProcessingTap?
    let firstStatus = withUnsafePointer(to: callbacks) { pointer in
        withUnsafeMutablePointer(to: &first) { tapOut in
            MTAudioProcessingTapCreate(
                nil,
                pointer,
                kMTAudioProcessingTapCreationFlag_PreEffects,
                tapOut
            )
        }
    }
    let secondStatus = withUnsafePointer(to: callbacks) { pointer in
        withUnsafeMutablePointer(to: &second) { tapOut in
            MTAudioProcessingTapCreate(
                nil,
                pointer,
                kMTAudioProcessingTapCreationFlag_PostEffects,
                tapOut
            )
        }
    }
    mtExpect(firstStatus == 0 && secondStatus == 0, "two taps created")
    guard let left = first, let right = second else {
        fatalError("MEDIATOOLBOX_RUNTIME_FAIL expected two taps")
    }

    mtExpect(left == left, "identity equality")
    mtExpect(!(left != left), "identity not-unequal")
    mtExpect(left != right, "distinct taps unequal")
    mtExpect(!(left == right), "distinct taps not equal")

    var hasherA = Hasher()
    var hasherB = Hasher()
    left.hash(into: &hasherA)
    left.hash(into: &hasherB)
    mtExpect(hasherA.finalize() == hasherB.finalize(), "hash(into:) stable pair")
    mtExpect(left.hashValue == left.hashValue, "hashValue stable")
    mtExpect(left.hashValue != right.hashValue, "distinct taps distinct hashes")
}

func testTapGetTypeID() {
    let first = MTAudioProcessingTapGetTypeID()
    let second = MTAudioProcessingTapGetTypeID()
    mtExpect(first == second, "type id stable")
    mtExpect(first != 0, "host type id is nonzero")
    mtExpect(first == 0x4D54_4150, "host 'MTAP' marker")
}

func testGetSourceAudioFailClosed() {
    let callbacks = MTAudioProcessingTapCallbacks(
        version: kMTAudioProcessingTapCallbacksVersion_0,
        clientInfo: nil,
        init: nil,
        finalize: nil,
        prepare: nil,
        unprepare: nil,
        process: { tap, frames, flags, buffers, framesOut, flagsOut in
            var flagsSentinel: MTAudioProcessingTapFlags = 0xFFFF
            var timeSentinel = CMTimeRange(
                start: CMTime(value: 7, timescale: 1, flags: 1, epoch: 0),
                duration: CMTime(value: 3, timescale: 1, flags: 1, epoch: 0)
            )
            var framesSentinel: CMItemCount = 99
            let status = withUnsafeMutablePointer(to: &flagsSentinel) { flagsPointer in
                withUnsafeMutablePointer(to: &timeSentinel) { timePointer in
                    withUnsafeMutablePointer(to: &framesSentinel) { framesPointer in
                        MTAudioProcessingTapGetSourceAudio(
                            tap,
                            frames,
                            buffers,
                            flagsPointer,
                            timePointer,
                            framesPointer
                        )
                    }
                }
            }
            mtExpect(status == kMTAudioProcessingTapInvalidArgumentErr, "no source during process")
            mtExpect(flagsSentinel == 0xFFFF, "flagsOut unchanged on error")
            mtExpect(framesSentinel == 99, "framesOut unchanged on error")
            mtExpect(timeSentinel.start.value == 7, "timeRangeOut unchanged on error")
            framesOut.pointee = 0
            flagsOut.pointee = flags
        }
    )

    var tap: MTAudioProcessingTap?
    let createStatus = withUnsafePointer(to: callbacks) { pointer in
        withUnsafeMutablePointer(to: &tap) { tapOut in
            MTAudioProcessingTapCreate(
                nil,
                pointer,
                kMTAudioProcessingTapCreationFlag_PreEffects,
                tapOut
            )
        }
    }
    mtExpect(createStatus == 0, "create for source-audio probe")
    guard let created = tap else {
        fatalError("MEDIATOOLBOX_RUNTIME_FAIL expected tap")
    }

    var buffers = AudioBufferList(
        mNumberBuffers: 1,
        mBuffers: AudioBuffer(mNumberChannels: 1, mDataByteSize: 0, mData: nil)
    )
    var flagsOut: MTAudioProcessingTapFlags = 1
    var timeOut = CMTimeRange.zero
    var framesOut: CMItemCount = 5
    let outsideStatus = withUnsafeMutablePointer(to: &buffers) { bufferPointer in
        withUnsafeMutablePointer(to: &flagsOut) { flagsPointer in
            withUnsafeMutablePointer(to: &timeOut) { timePointer in
                withUnsafeMutablePointer(to: &framesOut) { framesPointer in
                    MTAudioProcessingTapGetSourceAudio(
                        created,
                        256,
                        bufferPointer,
                        flagsPointer,
                        timePointer,
                        framesPointer
                    )
                }
            }
        }
    }
    mtExpect(outsideStatus == kMTAudioProcessingTapInvalidArgumentErr, "no source outside process")
    mtExpect(flagsOut == 1, "outside flags unchanged")
    mtExpect(framesOut == 5, "outside frames unchanged")

    var processFrames: CMItemCount = 0
    var processFlags: MTAudioProcessingTapFlags = 0
    withUnsafeMutablePointer(to: &buffers) { bufferPointer in
        withUnsafeMutablePointer(to: &processFrames) { framesPointer in
            withUnsafeMutablePointer(to: &processFlags) { flagsPointer in
                MTAudioProcessingTapHostProcess(
                    created,
                    numberFrames: 64,
                    flags: kMTAudioProcessingTapFlag_EndOfStream,
                    bufferList: bufferPointer,
                    numberFramesOut: framesPointer,
                    flagsOut: flagsPointer
                )
            }
        }
    }
}
