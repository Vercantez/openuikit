import Foundation

/// Linux starting implementation of Apple's public CoreVideo module.
///
/// Real: software `CVPixelBuffer` allocation, locking, plane access,
/// attachments, pixel-buffer pools, public OSType / `CVReturn` constants,
/// time structures, and the iOS 26 Swift overlay around those buffers.
///
/// Fail-closed: Metal, OpenGL ES, IOSurface, DisplayLink, ColorSync, and
/// Apple compressed (lossy/lossless) pixel formats. Those paths return
/// `kCVReturnUnsupported` / nil / `false` rather than fabricating GPU or
/// hardware objects.

public let COREVIDEO_TRUE: Bool = true
public let COREVIDEO_FALSE: Bool = false
public let COREVIDEO_DECLARE_NULLABILITY: Bool = true
public let COREVIDEO_USE_DERIVED_ENUMS_FOR_CONSTANTS: Bool = true
public let COREVIDEO_INCLUDED_IOSURFACE_HEADER_FILE: Int32 = 0
public let COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API: Int32 = 0
public let COREVIDEO_USE_IOSURFACEREF: Bool = false
public let COREVIDEO_SUPPORTS_COLORSPACE: Bool = false
public let COREVIDEO_SUPPORTS_DIRECT3D: Bool = false
public let COREVIDEO_SUPPORTS_DISPLAYLINK: Bool = false
public let COREVIDEO_SUPPORTS_GLES_TEX_IMAGE_IOSURFACE: Bool = false
public let COREVIDEO_SUPPORTS_IOSURFACE: Bool = false
public let COREVIDEO_SUPPORTS_IOSURFACE_PREFETCH: Bool = false
public let COREVIDEO_SUPPORTS_METAL: Bool = false
public let COREVIDEO_SUPPORTS_OPENGL: Bool = false
public let COREVIDEO_SUPPORTS_OPENGLES: Bool = false
public let COREVIDEO_SUPPORTS_PERMANENT_ALLOCATOR: Bool = false
public let COREVIDEO_SUPPORTS_PREFETCH: Bool = false

let _cvPixelBufferTypeID: CFTypeID = 0xC0DE_0001
let _cvPixelBufferPoolTypeID: CFTypeID = 0xC0DE_0002
let _cvMetalBufferTypeID: CFTypeID = 0xC0DE_0003
let _cvMetalTextureTypeID: CFTypeID = 0xC0DE_0004
let _cvMetalBufferCacheTypeID: CFTypeID = 0xC0DE_0005
let _cvMetalTextureCacheTypeID: CFTypeID = 0xC0DE_0006
let _cvOpenGLESTextureTypeID: CFTypeID = 0xC0DE_0007
let _cvOpenGLESTextureCacheTypeID: CFTypeID = 0xC0DE_0008

public func CVPixelBufferGetTypeID() -> CFTypeID { _cvPixelBufferTypeID }
public func CVPixelBufferPoolGetTypeID() -> CFTypeID { _cvPixelBufferPoolTypeID }
public func CVMetalBufferGetTypeID() -> CFTypeID { _cvMetalBufferTypeID }
public func CVMetalTextureGetTypeID() -> CFTypeID { _cvMetalTextureTypeID }
public func CVMetalBufferCacheGetTypeID() -> CFTypeID { _cvMetalBufferCacheTypeID }
public func CVMetalTextureCacheGetTypeID() -> CFTypeID { _cvMetalTextureCacheTypeID }
public func CVOpenGLESTextureGetTypeID() -> CFTypeID { _cvOpenGLESTextureTypeID }
public func CVOpenGLESTextureCacheGetTypeID() -> CFTypeID { _cvOpenGLESTextureCacheTypeID }

public func CVMetalBufferCacheFlush(_ bufferCache: CVMetalBufferCache, _ options: CVOptionFlags) {
    _ = bufferCache
    _ = options
}

public func CVMetalTextureCacheFlush(_ textureCache: CVMetalTextureCache, _ options: CVOptionFlags) {
    _ = textureCache
    _ = options
}

public func CVOpenGLESTextureCacheFlush(
    _ textureCache: CVOpenGLESTextureCache,
    _ options: CVOptionFlags
) {
    _ = textureCache
    _ = options
}

public func CVMetalTextureIsFlipped(_ image: CVMetalTexture) -> Bool {
    CVImageBufferIsFlipped(image)
}

public func CVOpenGLESTextureIsFlipped(_ image: CVOpenGLESTexture) -> Bool {
    CVImageBufferIsFlipped(image)
}

public func CVMetalTextureGetCleanTexCoords(
    _ image: CVMetalTexture,
    _ lowerLeft: UnsafeMutablePointer<Float>,
    _ lowerRight: UnsafeMutablePointer<Float>,
    _ upperRight: UnsafeMutablePointer<Float>,
    _ upperLeft: UnsafeMutablePointer<Float>
) {
    _cvFillCleanTexCoords(
        image,
        lowerLeft: lowerLeft,
        lowerRight: lowerRight,
        upperRight: upperRight,
        upperLeft: upperLeft
    )
}

func _cvFillCleanTexCoords(
    _ image: CVImageBuffer,
    lowerLeft: UnsafeMutablePointer<Float>,
    lowerRight: UnsafeMutablePointer<Float>,
    upperRight: UnsafeMutablePointer<Float>,
    upperLeft: UnsafeMutablePointer<Float>
) {
    let flipped = CVImageBufferIsFlipped(image)
    if flipped {
        lowerLeft.pointee = 0
        (lowerLeft + 1).pointee = 0
        lowerRight.pointee = 1
        (lowerRight + 1).pointee = 0
        upperRight.pointee = 1
        (upperRight + 1).pointee = 1
        upperLeft.pointee = 0
        (upperLeft + 1).pointee = 1
    } else {
        lowerLeft.pointee = 0
        (lowerLeft + 1).pointee = 1
        lowerRight.pointee = 1
        (lowerRight + 1).pointee = 1
        upperRight.pointee = 1
        (upperRight + 1).pointee = 0
        upperLeft.pointee = 0
        (upperLeft + 1).pointee = 0
    }
}
