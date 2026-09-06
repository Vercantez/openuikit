import Foundation
import MediaToolbox

func testTypealiases() {
    let creation: MTAudioProcessingTapCreationFlags = kMTAudioProcessingTapCreationFlag_PostEffects
    mtExpect(creation == 2, "MTAudioProcessingTapCreationFlags")

    let flags: MTAudioProcessingTapFlags = kMTAudioProcessingTapFlag_EndOfStream
    mtExpect(flags == 512, "MTAudioProcessingTapFlags")

    let initialize: MTAudioProcessingTapInitCallback = { _, _, storage in
        storage.pointee = nil
    }
    let finalize: MTAudioProcessingTapFinalizeCallback = { _ in }
    let prepare: MTAudioProcessingTapPrepareCallback = { _, _, _ in }
    let unprepare: MTAudioProcessingTapUnprepareCallback = { _ in }
    let process: MTAudioProcessingTapProcessCallback = mtNoopProcess

    let callbacks = MTAudioProcessingTapCallbacks(
        version: kMTAudioProcessingTapCallbacksVersion_0,
        clientInfo: nil,
        init: initialize,
        finalize: finalize,
        prepare: prepare,
        unprepare: unprepare,
        process: process
    )
    mtExpect(callbacks.`init` != nil, "init typealias stored")
    mtExpect(callbacks.finalize != nil, "finalize typealias stored")
    mtExpect(callbacks.prepare != nil, "prepare typealias stored")
    mtExpect(callbacks.unprepare != nil, "unprepare typealias stored")

    var tap: MTAudioProcessingTap?
    let status = withUnsafePointer(to: callbacks) { pointer in
        withUnsafeMutablePointer(to: &tap) { tapOut in
            MTAudioProcessingTapCreate(
                nil,
                pointer,
                kMTAudioProcessingTapCreationFlag_PostEffects,
                tapOut
            )
        }
    }
    mtExpect(status == 0, "typealias callbacks create")
    mtExpect(tap != nil, "typealias tap")
    _ = MTAudioProcessingTapGetStorage(tap!)
}
