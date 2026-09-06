@_exported import Foundation

#if canImport(CoreGraphics)
@_exported import CoreGraphics
#endif
#if canImport(UIKit)
@_exported import UIKit
#elseif canImport(OpenUIKit)
@_exported import OpenUIKit
#endif
#if canImport(PencilKit)
@_exported import PencilKit
#endif
#if canImport(UniformTypeIdentifiers)
@_exported import UniformTypeIdentifiers
#endif

/// Linux starting point for Apple's public `PaperKit` module.
///
/// Value types (`FeatureSet`, `PaperMarkup`, `ShapeConfiguration`,
/// `RenderingOptions`, `MarkupError`) implement documented defaults, set
/// algebra, and a Linux-native markup archive. View controllers keep
/// documented property defaults and fail closed: they never present Apple
/// Pencil / markup chrome or rasterize into a real CoreGraphics context.

/// Linux `PaperMarkup` archive magic (`OPKM`). Apple PaperKit bytes are
/// rejected by `PaperMarkup.init(dataRepresentation:)` rather than decoded
/// as a guess.
public let PaperMarkupOpenUIKitMagic = Data([0x4F, 0x50, 0x4B, 0x4D])

/// Current Linux archive version stored after the magic as a big-endian
/// `UInt32`. Newer versions throw `MarkupError.incompatibleFormatTooNew`.
public let PaperMarkupOpenUIKitArchiveVersion: UInt32 = 1

extension UTType {
    /// The UTType for storing paper data.
    ///
    /// Linux uses the filename-extension form `public.paperkit`. Apple's
    /// exact UTI bytes are an oracle question.
    public static let paperkit = UTType(filenameExtension: "paperkit")
}

/// The error thrown for encoding / decoding data models.
public enum MarkupError: Error, Equatable, Hashable, Sendable {
    /// Incorrect format or header.
    case incorrectFormat
    /// The binary data was malformed in some way.
    case malformedData
    /// The data being decoded has a newer format that cannot be decoded.
    case incompatibleFormatTooNew

    public var localizedDescription: String {
        switch self {
        case .incorrectFormat:
            return "Incorrect format or header."
        case .malformedData:
            return "The binary data was malformed in some way."
        case .incompatibleFormatTooNew:
            return "The data being decoded has a newer format that cannot be decoded."
        }
    }
}

/// The rendering options for drawing paper data models.
public struct RenderingOptions: Equatable, Sendable {
    /// Use a dark user interface style for rendering.
    public var darkUserInterfaceStyle: Bool
    /// Use a right to left layout direction for rendering.
    public var rightToLeftLayoutDirection: Bool

    /// Creates a new rendering options value.
    public init(darkUserInterfaceStyle: Bool = false, layoutRightToLeft: Bool = false) {
        self.darkUserInterfaceStyle = darkUserInterfaceStyle
        self.rightToLeftLayoutDirection = layoutRightToLeft
    }

    /// Creates the most suitable options for rendering on a device with the
    /// specified traits.
    public init(traitCollection: UITraitCollection) {
        self.darkUserInterfaceStyle = traitCollection.userInterfaceStyle == .dark
        self.rightToLeftLayoutDirection = traitCollection.layoutDirection == .rightToLeft
    }
}
