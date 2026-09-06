import Foundation
import MediaToolbox

func testCallbacksStructFields() {
    var initCalled = false
    var finalizeCalled = false
    var prepareCalled = false
    var unprepareCalled = false
    var processCalled = false
    var capturedClient: UnsafeMutableRawPointer? = nil

    var token: Int = 42
    let client = UnsafeMutableRawPointer(&token)

    let callbacks = MTAudioProcessingTapCallbacks(
        version: kMTAudioProcessingTapCallbacksVersion_0,
        clientInfo: client,
        init: { tap, info, storage in
            initCalled = true
            capturedClient = info
            _ = tap
            storage.pointee = info
        },
        finalize: { tap in
            finalizeCalled = true
            _ = tap
        },
        prepare: { tap, maxFrames, format in
            prepareCalled = true
            mtExpect(maxFrames == 1024, "prepare maxFrames")
            mtExpect(format.pointee.mSampleRate == 44100, "prepare sample rate")
            _ = tap
        },
        unprepare: { tap in
            unprepareCalled = true
            _ = tap
        },
        process: { tap, frames, flags, buffers, framesOut, flagsOut in
            processCalled = true
            mtExpect(frames == 512, "process frames")
            mtExpect(flags == kMTAudioProcessingTapFlag_StartOfStream, "process flags")
            mtExpect(buffers.pointee.mNumberBuffers == 1, "buffer count")
            framesOut.pointee = frames
            flagsOut.pointee = flags
            _ = tap
        }
    )

    mtExpect(callbacks.version == 0, "version field")
    mtExpect(callbacks.clientInfo == client, "clientInfo field")
    mtExpect(callbacks.`init` != nil, "init callback present")
    mtExpect(callbacks.finalize != nil, "finalize callback present")
    mtExpect(callbacks.prepare != nil, "prepare callback present")
    mtExpect(callbacks.unprepare != nil, "unprepare callback present")

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
    mtExpect(createStatus == 0, "create for field probe")
    mtExpect(tap != nil, "tap created")
    mtExpect(initCalled, "init ran at create")
    mtExpect(capturedClient == client, "init received clientInfo")

    let format = AudioStreamBasicDescription(mSampleRate: 44100, mChannelsPerFrame: 2)
    withUnsafePointer(to: format) { formatPointer in
        MTAudioProcessingTapHostPrepare(tap!, maxFrames: 1024, processingFormat: formatPointer)
    }
    mtExpect(prepareCalled, "prepare ran")

    var buffers = AudioBufferList(
        mNumberBuffers: 1,
        mBuffers: AudioBuffer(mNumberChannels: 2, mDataByteSize: 0, mData: nil)
    )
    var framesOut: CMItemCount = 0
    var flagsOut: MTAudioProcessingTapFlags = 0
    withUnsafeMutablePointer(to: &buffers) { bufferPointer in
        withUnsafeMutablePointer(to: &framesOut) { framesPointer in
            withUnsafeMutablePointer(to: &flagsOut) { flagsPointer in
                MTAudioProcessingTapHostProcess(
                    tap!,
                    numberFrames: 512,
                    flags: kMTAudioProcessingTapFlag_StartOfStream,
                    bufferList: bufferPointer,
                    numberFramesOut: framesPointer,
                    flagsOut: flagsPointer
                )
            }
        }
    }
    mtExpect(processCalled, "process ran")
    mtExpect(framesOut == 512, "process wrote framesOut")
    mtExpect(flagsOut == kMTAudioProcessingTapFlag_StartOfStream, "process wrote flagsOut")

    MTAudioProcessingTapHostUnprepare(tap!)
    mtExpect(unprepareCalled, "unprepare ran")

    tap = nil
    mtExpect(finalizeCalled, "finalize ran on release")
}
