import AudioToolbox
import CoreAudioTypes
import CoreFoundation
import Foundation

/// Central ARM64 identity probe. Isolated host gate does not compile this file;
/// it only requires the import lines. Do not introduce module-local stand-ins
/// for CoreAudioTypes, CoreFoundation, or Foundation types.

func audioToolboxPassCanonicalCoreFoundation(_ url: CFURL) -> Int32 {
    var file: AudioFileID?
    return AudioFileOpenURL(url, .readPermission, 0, &file)
}

func audioToolboxPassCanonicalFoundation(_ url: URL) -> Int32 {
    let cfURL = url as CFURL
    return audioToolboxPassCanonicalCoreFoundation(cfURL)
}

func audioToolboxPassCanonicalCoreAudioTypes(
    _ format: AudioStreamBasicDescription
) -> Int32 {
    var local = format
    return withUnsafePointer(to: &local) { pointer in
        var queue: AudioQueueRef?
        return AudioQueueNewOutput(
            UnsafeRawPointer(pointer),
            Optional<AudioQueueOutputCallback>.none,
            nil,
            nil,
            nil,
            0,
            &queue
        )
    }
}
