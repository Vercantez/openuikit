import CoreVideo
import Foundation

private final class ProbeMTLDevice: MTLDevice {}

private func makeImage() -> CVPixelBuffer {
    var buffer: CVPixelBuffer?
    precondition(
        CVPixelBufferCreate(nil, 8, 8, kCVPixelFormatType_32BGRA, nil, &buffer)
            == kCVReturnSuccess
    )
    return buffer!
}

func testMetalBufferCacheFailClosed() {
    let device = ProbeMTLDevice()
    var cache: CVMetalBufferCache?
    precondition(
        CVMetalBufferCacheCreate(nil, nil, device, &cache) == kCVReturnUnsupported
    )
    precondition(cache == nil)
    let local = CVMetalBufferCache()
    CVMetalBufferCacheFlush(local, 0)
    var bufferOut: CVMetalBuffer?
    precondition(
        CVMetalBufferCacheCreateBufferFromImage(nil, local, makeImage(), &bufferOut)
            == kCVReturnUnsupported
    )
    precondition(bufferOut == nil)
    precondition(CVMetalBufferGetBuffer(makeImage()) == nil)
}

func testMetalTextureCacheFailClosed() {
    let device = ProbeMTLDevice()
    var cache: CVMetalTextureCache?
    precondition(
        CVMetalTextureCacheCreate(nil, nil, device, nil, &cache) == kCVReturnUnsupported
    )
    precondition(cache == nil)
    let local = CVMetalTextureCache()
    CVMetalTextureCacheFlush(local, 0)
    var textureOut: CVMetalTexture?
    precondition(
        CVMetalTextureCacheCreateTextureFromImage(
            nil,
            local,
            makeImage(),
            nil,
            MTLPixelFormat(rawValue: 80),
            8,
            8,
            0,
            &textureOut
        ) == kCVReturnUnsupported
    )
    precondition(textureOut == nil)
    precondition(CVMetalTextureGetTexture(makeImage()) == nil)
}

func testOpenGLESTextureCacheFailClosed() {
    let context = EAGLContext()
    let aliased: CVEAGLContext = context
    var cache: CVOpenGLESTextureCache?
    precondition(
        CVOpenGLESTextureCacheCreate(nil, nil, aliased, nil, &cache) == kCVReturnUnsupported
    )
    precondition(cache == nil)
    let local = CVOpenGLESTextureCache()
    CVOpenGLESTextureCacheFlush(local, 0)
    var textureOut: CVOpenGLESTexture?
    precondition(
        CVOpenGLESTextureCacheCreateTextureFromImage(
            nil,
            local,
            makeImage(),
            nil,
            0,
            0,
            8,
            8,
            0,
            0,
            0,
            &textureOut
        ) == kCVReturnUnsupported
    )
    precondition(textureOut == nil)
}

func testMetalTextureCoordsAndFlip() {
    let image = makeImage()
    precondition(CVMetalTextureIsFlipped(image) == false)
    var lowerLeft: [Float] = [0, 0]
    var lowerRight: [Float] = [0, 0]
    var upperRight: [Float] = [0, 0]
    var upperLeft: [Float] = [0, 0]
    CVMetalTextureGetCleanTexCoords(
        image,
        &lowerLeft,
        &lowerRight,
        &upperRight,
        &upperLeft
    )
    precondition(lowerLeft[0] == 0 && lowerLeft[1] == 1)
    precondition(upperLeft[0] == 0 && upperLeft[1] == 0)
}

func testOpenGLESTextureQueries() {
    let image = makeImage()
    precondition(CVOpenGLESTextureIsFlipped(image) == false)
    precondition(CVOpenGLESTextureGetName(image) == 0)
    precondition(CVOpenGLESTextureGetTarget(image) == 0)
    var lowerLeft: [GLfloat] = [0, 0]
    var lowerRight: [GLfloat] = [0, 0]
    var upperRight: [GLfloat] = [0, 0]
    var upperLeft: [GLfloat] = [0, 0]
    CVOpenGLESTextureGetCleanTexCoords(
        image,
        &lowerLeft,
        &lowerRight,
        &upperRight,
        &upperLeft
    )
    precondition(lowerLeft[0] == 0 && lowerLeft[1] == 1)
}

func testCVEAGLContextAlias() {
    precondition(CVEAGLContext.self == EAGLContext.self)
    _ = EAGLContext()
}

func testMetalCacheIdentityHashable() {
    let a = CVMetalBufferCache()
    let b = CVMetalBufferCache()
    precondition(a == a)
    precondition(a != b)
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = a.hashValue
    let ta = CVMetalTextureCache()
    let tb = CVMetalTextureCache()
    precondition(ta == ta && ta != tb)
    ta.hash(into: &hasher)
    _ = ta.hashValue
    let ga = CVOpenGLESTextureCache()
    let gb = CVOpenGLESTextureCache()
    precondition(ga == ga && ga != gb)
    ga.hash(into: &hasher)
    _ = ga.hashValue
}

func testTypeIDs() {
    precondition(CVPixelBufferGetTypeID() != 0)
    precondition(CVPixelBufferPoolGetTypeID() != CVPixelBufferGetTypeID())
    precondition(CVMetalBufferGetTypeID() != 0)
    precondition(CVMetalTextureGetTypeID() != 0)
    precondition(CVMetalBufferCacheGetTypeID() != 0)
    precondition(CVMetalTextureCacheGetTypeID() != 0)
    precondition(CVOpenGLESTextureGetTypeID() != 0)
    precondition(CVOpenGLESTextureCacheGetTypeID() != 0)
}
