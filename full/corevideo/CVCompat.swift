import Foundation

// Linux Swift Foundation does not currently expose CoreFoundation's CF* names.
// These aliases match the imported CoreVideo C surface so the public functions
// can be spelled as on Apple. They are not claimed as CoreVideo identifiers.

public typealias CFString = NSString
public typealias CFDictionary = NSDictionary
public typealias CFArray = NSArray
public typealias CFTypeRef = AnyObject
public typealias CFTypeID = UInt
public typealias CFIndex = Int
public typealias CFAllocator = AnyObject
public typealias OSType = UInt32
public typealias DarwinBoolean = Bool
public typealias CVOptionFlags = UInt64
public typealias CVReturn = Int32
public typealias CVImageBuffer = CVBuffer
public typealias CVPixelBuffer = CVImageBuffer
public typealias CVMetalBuffer = CVBuffer
public typealias CVMetalTexture = CVImageBuffer
public typealias CVOpenGLESTexture = CVImageBuffer
public typealias IOSurfaceRef = IOSurface

public typealias CVPixelBufferReleaseBytesCallback = (
    UnsafeMutableRawPointer?, UnsafeRawPointer?
) -> Void

public typealias CVPixelBufferReleasePlanarBytesCallback = (
    UnsafeMutableRawPointer?,
    UnsafeRawPointer?,
    Int,
    Int,
    UnsafeMutablePointer<UnsafeRawPointer?>?
) -> Void

public typealias CVFillExtendedPixelsCallBack = (
    CVPixelBuffer, UnsafeMutableRawPointer?
) -> DarwinBoolean

/// Linux has no IOSurface. Overlay APIs that mention this type fail closed
/// (return nil / throw `CVError.unsupported`) and never fabricate a surface.
open class IOSurface: NSObject, @unchecked Sendable {}

/// Module-local Metal lookalikes so the public CoreVideo Metal entry points
/// compile without importing the Metal module. They are not CoreVideo
/// identifiers. GPU create/wrap APIs fail closed and never invent a device.
public protocol MTLDevice: AnyObject {}
public protocol MTLBuffer: AnyObject {}
public protocol MTLTexture: AnyObject {}

public struct MTLPixelFormat: RawRepresentable, Hashable, Sendable {
    public typealias RawValue = UInt
    public var rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
}

/// Module-local EAGL/OpenGL ES lookalikes. `CVEAGLContext` is the CoreVideo
/// alias; `EAGLContext` itself is not a CoreVideo precise identifier.
open class EAGLContext: NSObject, @unchecked Sendable {}
public typealias CVEAGLContext = EAGLContext

public typealias GLenum = UInt32
public typealias GLuint = UInt32
public typealias GLint = Int32
public typealias GLsizei = Int32
public typealias GLfloat = Float

/// Linux has no ColorSync/`CGColorSpace`. Image-buffer color-space queries
/// return nil rather than inventing a profile.
open class CGColorSpace: NSObject, @unchecked Sendable {}

/// Minimal stand-in for CoreGraphics' bitmap-info mask so pixel-format
/// descriptions can mention it without importing CoreGraphics.
public struct CGBitmapInfo: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

func _cvCFString(_ value: String) -> CFString {
    value as NSString
}

func _cvStringKey(_ key: CFString) -> String {
    key as String
}

func _cvCopyDictionary(_ dictionary: NSDictionary) -> NSDictionary {
    let copy = NSMutableDictionary()
    dictionary.enumerateKeysAndObjects { key, value, _ in
        if let key = key as? NSString {
            copy[key] = value
        }
    }
    return copy
}

func _cvNumber(_ value: Int) -> NSNumber { NSNumber(value: value) }
func _cvNumber(_ value: Bool) -> NSNumber { NSNumber(value: value) }
func _cvNumber(_ value: OSType) -> NSNumber { NSNumber(value: value) }
