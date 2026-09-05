import CoreVideo
import Foundation

func fail(_ message: String) -> Never {
    fputs("COREVIDEO_AGENT_RUNTIME_FAIL: \(message)\n", stderr)
    exit(1)
}

func expect(_ condition: Bool, _ message: String) {
    if !condition { fail(message) }
}

final class RuntimeProbeMTLDevice: MTLDevice {}

expect(kCVReturnSuccess == 0, "success is 0")
expect(kCVReturnInvalidArgument == -6661, "invalid argument code")
expect(kCVReturnUnsupported == -6663, "unsupported code")
expect(COREVIDEO_SUPPORTS_METAL == false, "metal fail-closed")
expect(COREVIDEO_SUPPORTS_IOSURFACE == false, "iosurface fail-closed")
expect(COREVIDEO_SUPPORTS_OPENGLES == false, "opengles fail-closed")
expect(COREVIDEO_SUPPORTS_DISPLAYLINK == false, "displaylink fail-closed")

expect(kCVPixelFormatType_32BGRA == 0x4247_5241, "BGRA fourcc")
expect(kCVPixelFormatType_32ARGB == 32, "ARGB numeric")
expect(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == 0x3432_3076, "420v fourcc")
expect(
    (CVPixelFormatTypeCopyFourCharCodeString(kCVPixelFormatType_32BGRA) as String) == "BGRA",
    "fourcc string"
)
expect(CVIsCompressedPixelFormatAvailable(kCVPixelFormatType_Lossless_32BGRA) == false,
       "compressed formats unavailable")

expect(kCVZeroTime.timeValue == 0 && kCVZeroTime.timeScale == 1, "zero time")
expect(
    kCVIndefiniteTime.flagOptions.contains(.isIndefinite),
    "indefinite time flag"
)
expect(CVAttachmentMode.shouldPropagate.rawValue == 1, "propagate mode")
expect(CVPixelBufferLockFlags.readOnly.rawValue == 1, "readonly lock")
expect(
    CVTimeStampFlags.videoHostTimeValid == [.videoTimeValid, .hostTimeValid],
    "videoHostTimeValid composition"
)

var stamp = CVTimeStamp(hostTime: 42, topField: true)
expect(stamp.flagOptions.contains(.hostTimeValid), "host time valid")
expect(stamp.flagOptions.contains(.topField), "top field")

try! CVError.check(kCVReturnSuccess)
do {
    try CVError.check(kCVReturnUnsupported)
    fail("check must throw")
} catch {
    expect(error == .unsupported, "typed unsupported")
}
expect(CVError(rawValue: kCVReturnSuccess) == nil, "success is not an error")
expect(CVError.invalidPixelFormat.rawValue == kCVReturnInvalidPixelFormat, "invalid pixel format")

var buffer: CVPixelBuffer?
let create = CVPixelBufferCreate(
    nil,
    16,
    8,
    kCVPixelFormatType_32BGRA,
    nil,
    &buffer
)
expect(create == kCVReturnSuccess, "create 32BGRA")
guard let buffer else { fail("missing buffer") }
expect(CVPixelBufferGetWidth(buffer) == 16, "width")
expect(CVPixelBufferGetHeight(buffer) == 8, "height")
expect(CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA, "format")
expect(CVPixelBufferIsPlanar(buffer) == false, "packed")
expect(CVPixelBufferGetPlaneCount(buffer) == 0, "nonplanar plane count")
expect(CVPixelBufferGetBytesPerRow(buffer) >= 16 * 4, "row bytes")
expect(CVPixelBufferLockBaseAddress(buffer, []) == kCVReturnSuccess, "lock")
guard let base = CVPixelBufferGetBaseAddress(buffer) else { fail("base address") }
base.storeBytes(of: UInt32(0xAABB_CCDD), as: UInt32.self)
expect(base.load(as: UInt32.self) == 0xAABB_CCDD, "pixel roundtrip")
expect(CVPixelBufferUnlockBaseAddress(buffer, []) == kCVReturnSuccess, "unlock")

CVBufferSetAttachment(
    buffer,
    kCVImageBufferYCbCrMatrixKey,
    kCVImageBufferYCbCrMatrix_ITU_R_709_2,
    .shouldPropagate
)
expect(CVBufferHasAttachment(buffer, kCVImageBufferYCbCrMatrixKey), "has attachment")
var mode = CVAttachmentMode.shouldNotPropagate
let copied = CVBufferCopyAttachment(buffer, kCVImageBufferYCbCrMatrixKey, &mode)
expect(mode == .shouldPropagate, "attachment mode")
expect(
    (copied as? NSString) as String? == (kCVImageBufferYCbCrMatrix_ITU_R_709_2 as String),
    "attachment value"
)

var dest: CVPixelBuffer?
expect(
    CVPixelBufferCreate(nil, 16, 8, kCVPixelFormatType_32BGRA, nil, &dest) == kCVReturnSuccess,
    "second buffer"
)
CVBufferPropagateAttachments(buffer, dest!)
expect(CVBufferHasAttachment(dest!, kCVImageBufferYCbCrMatrixKey), "propagated")

var yuv: CVPixelBuffer?
expect(
    CVPixelBufferCreate(
        nil,
        32,
        16,
        kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
        nil,
        &yuv
    ) == kCVReturnSuccess,
    "create 420v"
)
expect(CVPixelBufferIsPlanar(yuv!) == true, "planar")
expect(CVPixelBufferGetPlaneCount(yuv!) == 2, "two planes")
expect(CVPixelBufferGetWidthOfPlane(yuv!, 0) == 32, "y width")
expect(CVPixelBufferGetWidthOfPlane(yuv!, 1) == 16, "uv width")
expect(CVPixelBufferGetHeightOfPlane(yuv!, 1) == 8, "uv height")
expect(CVPixelBufferGetBaseAddressOfPlane(yuv!, 0) != nil, "y plane")
expect(CVPixelBufferGetBaseAddressOfPlane(yuv!, 1) != nil, "uv plane")

var rejected: CVPixelBuffer?
expect(
    CVPixelBufferCreate(nil, 8, 8, kCVPixelFormatType_Lossless_32BGRA, nil, &rejected)
        == kCVReturnInvalidPixelFormat,
    "compressed create fails closed"
)

var surfaceOut: Unmanaged<CVPixelBuffer>?
expect(
    CVPixelBufferCreateWithIOSurface(nil, IOSurface(), nil, &surfaceOut) == kCVReturnUnsupported,
    "IOSurface create unsupported"
)
expect(CVPixelBufferGetIOSurface(buffer) == nil, "no IOSurface backing")

var pool: CVPixelBufferPool?
let poolAttrs: NSDictionary = [kCVPixelBufferPoolMinimumBufferCountKey: 1]
let pbAttrs: NSDictionary = [
    kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey: 8,
    kCVPixelBufferHeightKey: 8,
]
expect(
    CVPixelBufferPoolCreate(nil, poolAttrs, pbAttrs, &pool) == kCVReturnSuccess,
    "pool create"
)
var pooled: CVPixelBuffer?
expect(
    CVPixelBufferPoolCreatePixelBuffer(nil, pool!, &pooled) == kCVReturnSuccess,
    "pool allocate"
)
expect(CVPixelBufferGetWidth(pooled!) == 8, "pooled width")
var limited: CVPixelBuffer?
let aux: NSDictionary = [kCVPixelBufferPoolAllocationThresholdKey: 1]
let limitedStatus = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
    nil,
    pool!,
    aux,
    &limited
)
expect(
    limitedStatus == kCVReturnWouldExceedAllocationThreshold || limitedStatus == kCVReturnSuccess,
    "threshold path is defined"
)

let overlay = try! CVMutablePixelBuffer(
    CVPixelBufferCreationAttributes(
        pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
        size: CVImageSize(width: 4, height: 4)
    )
)
expect(overlay.size == CVImageSize(width: 4, height: 4), "overlay size")
expect(overlay.pixelFormatType.rawValue == kCVPixelFormatType_32BGRA, "overlay format")
expect(overlay.isPlanar == false, "overlay packed")
overlay.accessUnsafeRawPlaneBytes { planes in
    expect(planes.count == 1, "one packed plane")
    expect(planes[0].bytes.count >= 4 * 4, "plane bytes")
}
do {
    _ = try CVMutablePixelBuffer(
        CVPixelBufferCreationAttributes(
            pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
            size: CVImageSize(width: 2, height: 2),
            backing: .ioSurface
        )
    )
    fail("ioSurface backing must fail closed")
} catch {
    expect((error as? CVError) == .unsupported, "iosurface backing unsupported")
}

let readonly = CVReadOnlyPixelBuffer(overlay)
expect(readonly.withUnsafeBackingIOSurfaceIfPresent { _ in 1 } == nil, "no surface")
expect(CGSize(readonly.size) == CGSize(width: 4, height: 4), "cgsize conversion")

var metalCache: CVMetalBufferCache?
expect(
    CVMetalBufferCacheCreate(nil, nil, RuntimeProbeMTLDevice(), &metalCache)
        == kCVReturnUnsupported,
    "metal buffer cache create unsupported"
)
expect(metalCache == nil, "metal buffer cache remains nil")
expect(CVMetalBufferGetBuffer(buffer) == nil, "no MTLBuffer wrap")
var metalTextureCache: CVMetalTextureCache?
expect(
    CVMetalTextureCacheCreate(nil, nil, RuntimeProbeMTLDevice(), nil, &metalTextureCache)
        == kCVReturnUnsupported,
    "metal texture cache create unsupported"
)
var metalTexture: CVMetalTexture?
expect(
    CVMetalTextureCacheCreateTextureFromImage(
        nil,
        CVMetalTextureCache(),
        buffer,
        nil,
        MTLPixelFormat(rawValue: 80),
        16,
        8,
        0,
        &metalTexture
    ) == kCVReturnUnsupported,
    "metal texture from image unsupported"
)
expect(CVMetalTextureGetTexture(buffer) == nil, "no MTLTexture wrap")
var glesCache: CVOpenGLESTextureCache?
expect(
    CVOpenGLESTextureCacheCreate(nil, nil, EAGLContext(), nil, &glesCache)
        == kCVReturnUnsupported,
    "opengles cache create unsupported"
)
expect(CVOpenGLESTextureGetName(buffer) == 0, "no GL name")
expect(CVOpenGLESTextureGetTarget(buffer) == 0, "no GL target")
expect(CVEAGLContext.self == EAGLContext.self, "EAGL alias")

let registry = CVPixelFormatDescription.Registry.shared
registry.register(
    CVPixelFormatDescription(
        pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
        name: "BGRA",
        components: [.rgb, .alpha],
        planeConfiguration: .nonPlanar(
            .init(bitsPerBlock: 32, bitsPerComponent: 8)
        )
    )
)
expect(registry[CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA)] != nil, "registry")
expect(
    CVPixelFormatDescriptionCreateWithPixelFormatType(nil, kCVPixelFormatType_32BGRA) != nil,
    "c description"
)
expect(
    CVColorPrimariesGetIntegerCodePointForString(kCVImageBufferColorPrimaries_ITU_R_709_2) == 1,
    "709 primaries"
)
expect(
    (kCVPixelBufferWidthKey as String) == "Width",
    "width key"
)

print("COREVIDEO_AGENT_RUNTIME_OK")
