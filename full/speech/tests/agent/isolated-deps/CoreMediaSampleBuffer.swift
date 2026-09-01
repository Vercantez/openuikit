import Foundation

/// Isolated-only CoreMedia addition. Production Speech must not define
/// `CMSampleBuffer`; this file is compiled into the staged CoreMedia module
/// for the isolated fan-out gate and is never part of `libSpeech.dylib`.
open class CMSampleBuffer: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
