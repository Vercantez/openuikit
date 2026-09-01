/// Concepts that describe the expected contents of a generated image.
///
/// Text and extracted-text wrappers store the caller-supplied strings. They
/// do not run Apple's on-device concept extraction. The PencilKit drawing
/// and CoreGraphics image factories are omitted until those modules can be
/// imported by this isolated compile.
public struct ImagePlaygroundConcept: Sendable {
    enum Storage: Sendable {
        case text(String)
        case extracted(text: String, title: String?)
        case imageFile(URL)
    }

    let storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    /// A short text description of the image.
    public static func text(_ text: String) -> ImagePlaygroundConcept {
        ImagePlaygroundConcept(storage: .text(text))
    }

    /// Long-form text plus an optional title that would guide extraction on
    /// Apple platforms. Linux stores both strings unchanged.
    public static func extracted(from text: String, title: String? = nil) -> ImagePlaygroundConcept {
        ImagePlaygroundConcept(storage: .extracted(text: text, title: title))
    }

    /// A local file URL that the caller intends as a source image.
    ///
    /// Returns `nil` when `url` is not a file URL or the file does not exist.
    /// This starting point does not decode or validate image bytes (ImageIO
    /// is not part of the isolated compile).
    public static func image(_ url: URL) -> ImagePlaygroundConcept? {
        guard url.isFileURL else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return ImagePlaygroundConcept(storage: .imageFile(url))
    }
}
