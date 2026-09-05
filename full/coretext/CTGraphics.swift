import CoreFoundation
import Foundation

#if canImport(CoreGraphics)
@_exported import CoreGraphics
#else
/// Isolated-host lookalike. Not CoreGraphics identity. Darwin / EC2 builds
/// import the real module via `canImport(CoreGraphics)`.
public typealias CGGlyph = UInt16
public typealias CGFontIndex = UInt16

public struct CGAffineTransform: Equatable, Sendable {
    public var a: CGFloat
    public var b: CGFloat
    public var c: CGFloat
    public var d: CGFloat
    public var tx: CGFloat
    public var ty: CGFloat

    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }

    public static var identity: CGAffineTransform {
        CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
    }
}

public final class CGPath: Hashable, @unchecked Sendable {
    public let boundingBoxOfPath: CGRect

    public init(rect: CGRect, transform: UnsafePointer<CGAffineTransform>?) {
        _ = transform
        boundingBoxOfPath = rect
    }

    public static func == (left: CGPath, right: CGPath) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

public final class CGContext: @unchecked Sendable {
    public var textMatrix = CGAffineTransform.identity
    public var textPosition = CGPoint.zero
    var recordedLineCount = 0
    var recordedRunCount = 0

    public init() {}
}

public final class CGFont: Hashable, @unchecked Sendable {
    public let postScriptName: String

    init(postScriptName: String) {
        self.postScriptName = postScriptName
    }

    public init?(fontName: CFString) {
        self.postScriptName = unsafeBitCast(fontName, to: NSString.self) as String
    }

    public static func == (left: CGFont, right: CGFont) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}
#endif

func _ctIdentityTransform() -> CGAffineTransform { .identity }

func _ctPathBounds(_ path: CGPath) -> CGRect {
    path.boundingBoxOfPath
}

func _ctRecordLineDraw(_ context: CGContext) {
#if canImport(CoreGraphics)
    _ = context
#else
    context.recordedLineCount += 1
#endif
}

func _ctRecordRunDraw(_ context: CGContext) {
#if canImport(CoreGraphics)
    _ = context
#else
    context.recordedRunCount += 1
#endif
}

func _ctMakeGraphicsFont(named name: String) -> CGFont {
#if canImport(CoreGraphics)
    if let font = CGFont(name as CFString) {
        return font
    }
    return CGFont("Helvetica" as CFString)!
#else
    return CGFont(postScriptName: name)
#endif
}

func _ctGraphicsFontName(_ font: CGFont) -> String {
#if canImport(CoreGraphics)
    if let name = font.postScriptName as String? {
        return name
    }
    return "Helvetica"
#else
    return font.postScriptName
#endif
}
