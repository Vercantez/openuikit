#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(ImageIO)
import ImageIO
#endif
#if canImport(PencilKit)
import PencilKit
#endif
import Foundation

/// Concepts that describe the expected contents of a generated image.
///
/// Text factories store caller strings and do not run Apple's on-device
/// extraction. `CGImage` and `PKDrawing` factories exist only when those
/// modules can be imported. There is no module-local substitute for either type.
public struct ImagePlaygroundConcept: @unchecked Sendable {
    enum Storage: @unchecked Sendable {
        case text(String)
        case extracted(text: String, title: String?)
        case imageURL(URL)
        #if canImport(CoreGraphics)
        case cgImage(CGImage)
        #endif
        #if canImport(PencilKit)
        case drawing(PKDrawing)
        #endif
    }

    let storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    public static func text(_ text: String) -> ImagePlaygroundConcept {
        ImagePlaygroundConcept(storage: .text(text))
    }

    public static func extracted(from text: String, title: String? = nil) -> ImagePlaygroundConcept {
        ImagePlaygroundConcept(storage: .extracted(text: text, title: title))
    }

    /// Wraps a file URL as an image concept when ImageIO can decode it.
    ///
    /// Without ImageIO this returns `nil` rather than guessing Apple's
    /// file-existence or content-type rules.
    public static func image(_ url: URL) -> ImagePlaygroundConcept? {
        #if canImport(ImageIO)
        guard url.isFileURL else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let cfData = data as CFData
        guard let source = CGImageSourceCreateWithData(cfData, nil) else { return nil }
        guard CGImageSourceGetCount(source) > 0 else { return nil }
        return ImagePlaygroundConcept(storage: .imageURL(url))
        #else
        _ = url
        return nil
        #endif
    }

    #if canImport(CoreGraphics)
    public static func image(_ image: CGImage) -> ImagePlaygroundConcept {
        ImagePlaygroundConcept(storage: .cgImage(image))
    }
    #endif

    #if canImport(PencilKit)
    public static func drawing(_ drawing: PKDrawing) -> ImagePlaygroundConcept {
        ImagePlaygroundConcept(storage: .drawing(drawing))
    }
    #endif
}
