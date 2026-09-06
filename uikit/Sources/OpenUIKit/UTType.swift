// Portable UTType for UIDocumentPicker / UIDocumentBrowser.
//
// OpenUIKit does not import UniformTypeIdentifiers: that module re-exports
// CoreGraphics and collides with OpenCoreGraphics' CGAffineTransform (same
// class of clash as NSAttributedString). The identifiers are the UTI strings
// the iOS 26.1 document-picker headers name.

public struct UTType: Hashable, Sendable {
    public let identifier: String

    public init(_ identifier: String) {
        self.identifier = identifier
    }

    public init(importedAs identifier: String, conformingTo parentType: UTType? = nil) {
        _ = parentType
        self.identifier = identifier
    }

    public init(exportedAs identifier: String, conformingTo parentType: UTType? = nil) {
        _ = parentType
        self.identifier = identifier
    }

    public static let item = UTType("public.item")
    public static let content = UTType("public.content")
    public static let data = UTType("public.data")
    public static let text = UTType("public.text")
    public static let plainText = UTType("public.plain-text")
    public static let image = UTType("public.image")
    public static let jpeg = UTType("public.jpeg")
    public static let png = UTType("public.png")
    public static let movie = UTType("public.movie")
    public static let video = UTType("public.video")
    public static let audio = UTType("public.audio")
    public static let pdf = UTType("com.adobe.pdf")
    public static let folder = UTType("public.folder")
    public static let directory = UTType("public.directory")
    public static let zip = UTType("public.zip-archive")
    public static let json = UTType("public.json")
}
