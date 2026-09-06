import MediaToolbox
import CoreFoundation
import CoreMedia

/// Identity probe for the later clean EC2 integration build. Isolated host
/// compilation does not execute this file.
func mediaToolboxPassCanonicalCoreMedia(_ mediaType: CMMediaType) -> CFString? {
    MTCopyLocalizedNameForMediaType(mediaType)
}

func mediaToolboxPassCanonicalCoreFoundation(_ allocator: CFAllocator?) -> OSStatus {
    let callbacks = MTAudioProcessingTapCallbacks(
        version: kMTAudioProcessingTapCallbacksVersion_0,
        clientInfo: nil,
        init: nil,
        finalize: nil,
        prepare: nil,
        unprepare: nil,
        process: { _, frames, flags, _, framesOut, flagsOut in
            framesOut.pointee = frames
            flagsOut.pointee = flags
        }
    )
    var tap: MTAudioProcessingTap?
    return withUnsafePointer(to: callbacks) { pointer in
        withUnsafeMutablePointer(to: &tap) { tapOut in
            MTAudioProcessingTapCreate(
                allocator,
                pointer,
                kMTAudioProcessingTapCreationFlag_PreEffects,
                tapOut
            )
        }
    }
}
