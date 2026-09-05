@_exported import Foundation

#if canImport(CoreGraphics)
@_exported import CoreGraphics
#elseif canImport(OpenCoreGraphics)
@_exported import OpenCoreGraphics
#endif

#if canImport(UIKit)
@_exported import UIKit
#elseif canImport(OpenUIKit)
@_exported import OpenUIKit
#endif

/// Uniform-type identifier used by Apple PencilKit for drawing payloads.
/// The exact Darwin `CFString` bytes are an oracle question; Linux stores the
/// documented UTI string on `NSString` (CoreFoundation is not importable here).
public let PKAppleDrawingTypeIdentifier: NSString = "com.apple.pkdrawing" as NSString

/// Linux-native drawing archive magic (`OPK1`). Apple `PKDrawing` bytes are
/// rejected by `PKDrawing.init(data:)` rather than decoded as a guess.
public let PKDrawingOpenUIKitMagic = Data([0x4F, 0x50, 0x4B, 0x31])

public enum PKDrawingDataError: Error, Equatable, Sendable {
    case appleFormatUnsupported
    case malformedOpenUIKitDrawing
}

/// Marker protocol for PencilKit tools. Swift value types (`PKInkingTool`,
/// `PKEraserTool`, `PKLassoTool`) and their ObjC reference classes conform.
public protocol PKTool {}
