import Foundation
import CoreFoundation
import MediaToolbox

func mtExpect(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError("MEDIATOOLBOX_RUNTIME_FAIL \(message)")
    }
}

func mtFourCC(_ literal: String) -> UInt32 {
    let bytes = Array(literal.utf8)
    precondition(bytes.count == 4)
    return (UInt32(bytes[0]) << 24)
        | (UInt32(bytes[1]) << 16)
        | (UInt32(bytes[2]) << 8)
        | UInt32(bytes[3])
}

func mtString(_ value: CFString) -> String {
    unsafeBitCast(value, to: NSString.self) as String
}

func mtNoopProcess(
    _ tap: MTAudioProcessingTap,
    _ frames: CMItemCount,
    _ flags: MTAudioProcessingTapFlags,
    _ buffers: UnsafeMutablePointer<AudioBufferList>,
    _ framesOut: UnsafeMutablePointer<CMItemCount>,
    _ flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>
) {
    _ = tap
    _ = flags
    _ = buffers
    framesOut.pointee = frames
    flagsOut.pointee = 0
}
