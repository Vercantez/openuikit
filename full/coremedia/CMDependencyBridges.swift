#if canImport(CoreAudioTypes)
import CoreAudioTypes
import Foundation

extension CMFormatDescription {
    /// Accepts a genuine CoreAudioTypes `AudioStreamBasicDescription`.
    /// Compiled only when that module is present in the central build.
    public convenience init(
        audioStreamBasicDescription: AudioStreamBasicDescription,
        layoutSize: Int,
        layout: UnsafePointer<AudioChannelLayout>?,
        magicCookie: Data?,
        extensions: Extensions?
    ) throws {
        _ = (layoutSize, layout, magicCookie)
        try self.init(
            mediaType: .audio,
            mediaSubType: MediaSubType(rawValue: audioStreamBasicDescription.mFormatID),
            extensions: extensions
        )
        self.extraIdentity = audioStreamBasicDescription
        if let magicCookie {
            storeMagicCookie(magicCookie)
        }
    }

    public var audioStreamBasicDescription: AudioStreamBasicDescription? {
        extraIdentity as? AudioStreamBasicDescription
    }
}
#endif

#if canImport(CoreVideo)
import CoreVideo
import Foundation

extension CMFormatDescription {
    public func matchesImageBuffer(_ imageBuffer: CVImageBuffer) -> Bool {
        _ = imageBuffer
        return false
    }
}

extension CMSampleBuffer {
    public var imageBuffer: CVImageBuffer? { nil }
}
#endif
