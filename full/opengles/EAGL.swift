import CoreFoundation
import Foundation

/// OpenGL ES version requested by `EAGLContext`. Raw values match the public
/// `kEAGLRenderingAPIOpenGLES{1,2,3}` enumeration (1 / 2 / 3).
public enum EAGLRenderingAPI: UInt {
    case openGLES1 = 1
    case openGLES2 = 2
    case openGLES3 = 3
}

public let kEAGLColorFormatRGB565: String = "kEAGLColorFormatRGB565"
public let kEAGLColorFormatRGBA8: String = "kEAGLColorFormatRGBA8"
public let kEAGLColorFormatSRGBA8: String = "kEAGLColorFormatSRGBA8"
public let kEAGLDrawablePropertyColorFormat: String = "kEAGLDrawablePropertyColorFormat"
public let kEAGLDrawablePropertyRetainedBacking: String = "kEAGLDrawablePropertyRetainedBacking"

public var EAGL_MAJOR_VERSION: Int32 { 1 }
public var EAGL_MINOR_VERSION: Int32 { 0 }

public func EAGLGetVersion(
    _ major: UnsafeMutablePointer<UInt32>,
    _ minor: UnsafeMutablePointer<UInt32>
) {
    major.pointee = UInt32(EAGL_MAJOR_VERSION)
    minor.pointee = UInt32(EAGL_MINOR_VERSION)
}

public protocol EAGLDrawable: AnyObject {
    var drawableProperties: [String: Any]? { get set }
}

/// Sharegroup for texture/buffer/shader names. Created with a context; there is
/// no public empty initializer (Apple marks the default constructor unavailable).
public final class EAGLSharegroup: @unchecked Sendable {
    public var debugLabel: String?
    let ownerAPI: EAGLRenderingAPI

    init(api: EAGLRenderingAPI) {
        self.ownerAPI = api
    }
}

/// CPU-side EAGL context. Construction succeeds for GLES 1/2/3 as a software
/// state container. Presenting a renderbuffer, allocating drawable storage, and
/// IOSurface texturing return `false` because this host has no CAEAGLLayer
/// compositor or IOSurface.
public final class EAGLContext: @unchecked Sendable {
    public let api: EAGLRenderingAPI
    public let sharegroup: EAGLSharegroup
    public var debugLabel: String?
    public var isMultiThreaded: Bool = false
    let state: GLESState

    private static let tlsKey = "OpenUIKit.OpenGLES.EAGLContext.current"

    static var tlsCurrent: EAGLContext? {
        get { Thread.current.threadDictionary[Self.tlsKey] as? EAGLContext }
        set { Thread.current.threadDictionary[Self.tlsKey] = newValue }
    }

    public class func current() -> EAGLContext? {
        tlsCurrent
    }

    /// Makes `context` current on this thread. Always succeeds on Linux; there is
    /// no GPU driver that can reject the TLS write.
    public class func setCurrent(_ context: EAGLContext?) -> Bool {
        tlsCurrent = context
        return true
    }

    public convenience init?(api: EAGLRenderingAPI) {
        self.init(api: api, sharegroup: EAGLSharegroup(api: api))
    }

    public convenience init?(API api: EAGLRenderingAPI) {
        self.init(api: api)
    }

    public init?(api: EAGLRenderingAPI, sharegroup: EAGLSharegroup) {
        guard sharegroup.ownerAPI == api else { return nil }
        self.api = api
        self.sharegroup = sharegroup
        self.state = GLESState(api: api)
    }

    public convenience init?(API api: EAGLRenderingAPI, sharegroup: EAGLSharegroup) {
        self.init(api: api, sharegroup: sharegroup)
    }

    public func presentRenderbuffer(_ target: UInt) -> Bool {
        _ = target
        return false
    }

    public func presentRenderbuffer(
        _ target: UInt,
        afterMinimumDuration duration: CFTimeInterval
    ) -> Bool {
        _ = target
        _ = duration
        return false
    }

    public func presentRenderbuffer(
        _ target: UInt,
        atTime presentationTime: CFTimeInterval
    ) -> Bool {
        _ = target
        _ = presentationTime
        return false
    }

    public func renderbufferStorage(
        _ target: UInt,
        from drawable: (any EAGLDrawable)?
    ) -> Bool {
        _ = target
        _ = drawable
        return false
    }

    public func texImageIOSurface(
        _ ioSurface: IOSurfaceRef,
        target: UInt,
        internalFormat: UInt,
        width: UInt32,
        height: UInt32,
        format: UInt,
        type: UInt,
        plane: UInt32
    ) -> Bool {
        _ = ioSurface
        _ = target
        _ = internalFormat
        _ = width
        _ = height
        _ = format
        _ = type
        _ = plane
        return false
    }
}
