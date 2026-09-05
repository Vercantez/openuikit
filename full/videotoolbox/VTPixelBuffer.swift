import Foundation

// Software pixel buffers owned by this isolated VideoToolbox module.
// They stand in for CoreVideo `CVPixelBuffer` because the sealed host gate
// cannot import CoreVideo. FourCC values match kCVPixelFormatType_* /
// kCMPixelFormat_* from the port's CoreVideo/CoreMedia sources.

public let kVTPixelFormat_32ARGB: UInt32 = 0x00000020
public let kVTPixelFormat_32BGRA: UInt32 = 0x42475241
public let kVTPixelFormat_32ABGR: UInt32 = 0x41424752
public let kVTPixelFormat_32RGBA: UInt32 = 0x52474241
public let kVTPixelFormat_24RGB: UInt32 = 0x00000018
public let kVTPixelFormat_24BGR: UInt32 = 0x32344247
public let kVTPixelFormat_420YpCbCr8BiPlanarVideoRange: UInt32 = 0x34323076
public let kVTPixelFormat_420YpCbCr8BiPlanarFullRange: UInt32 = 0x34323066

public let kVTVideoCodecType_JPEG: UInt32 = 0x6A706567
public let kVTVideoCodecType_JPEG_OpenDML: UInt32 = 0x646D6231
public let kVTVideoCodecType_H264: UInt32 = 0x61766331
public let kVTVideoCodecType_HEVC: UInt32 = 0x68766331
public let kVTVideoCodecType_H263: UInt32 = 0x68323633
public let kVTVideoCodecType_MPEG4Video: UInt32 = 0x6D703476

public struct VTMediaTime: Equatable, Hashable, Sendable {
    public var value: Int64
    public var timescale: Int32
    public var flags: UInt32
    public var epoch: Int64

    public init(value: Int64, timescale: Int32, flags: UInt32 = 1, epoch: Int64 = 0) {
        self.value = value
        self.timescale = timescale
        self.flags = flags
        self.epoch = epoch
    }

    public static let invalid = VTMediaTime(value: 0, timescale: 0, flags: 0, epoch: 0)
    public static let zero = VTMediaTime(value: 0, timescale: 1, flags: 1, epoch: 0)

    public var isValid: Bool { flags & 1 != 0 && timescale != 0 }

    public var seconds: Double {
        guard isValid else { return .nan }
        return Double(value) / Double(timescale)
    }
}

public struct VTVideoFormatDescription: Equatable, Hashable, Sendable {
    public var codecType: UInt32
    public var width: Int32
    public var height: Int32
    public var extensions: [String: String]

    public init(codecType: UInt32, width: Int32, height: Int32, extensions: [String: String] = [:]) {
        self.codecType = codecType
        self.width = width
        self.height = height
        self.extensions = extensions
    }

    public var isUncompressed: Bool {
        vtCodecIsUncompressed(codecType)
    }
}

func vtCodecIsUncompressed(_ codecType: UInt32) -> Bool {
    switch codecType {
    case kVTPixelFormat_32ARGB,
         kVTPixelFormat_32BGRA,
         kVTPixelFormat_32ABGR,
         kVTPixelFormat_32RGBA,
         kVTPixelFormat_24RGB,
         kVTPixelFormat_24BGR,
         kVTPixelFormat_420YpCbCr8BiPlanarVideoRange,
         kVTPixelFormat_420YpCbCr8BiPlanarFullRange:
        return true
    default:
        return false
    }
}

func vtJPEGEncoderReachable() -> Bool {
#if canImport(ImageIO)
    return true
#else
    return false
#endif
}

func vtHardwareCodec(_ codecType: UInt32) -> Bool {
    switch codecType {
    case kVTVideoCodecType_H264, kVTVideoCodecType_HEVC, kVTVideoCodecType_H263, kVTVideoCodecType_MPEG4Video:
        return true
    default:
        return false
    }
}

struct VTPackedRGBA {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
}

final class VTHostPixelBuffer {
    let width: Int
    let height: Int
    let pixelFormat: UInt32
    let bytesPerRow: Int
    var data: [UInt8]
    var plane1: [UInt8]
    let plane1BytesPerRow: Int
    let isPlanar: Bool
    var lockCount: Int = 0

    init(width: Int, height: Int, pixelFormat: UInt32, fill: VTPackedRGBA = VTPackedRGBA(r: 0, g: 0, b: 0, a: 255)) {
        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat
        self.isPlanar = pixelFormat == kVTPixelFormat_420YpCbCr8BiPlanarVideoRange
            || pixelFormat == kVTPixelFormat_420YpCbCr8BiPlanarFullRange
        if isPlanar {
            self.bytesPerRow = width
            self.plane1BytesPerRow = width
            self.data = [UInt8](repeating: 0, count: width * height)
            self.plane1 = [UInt8](repeating: 128, count: width * (height / 2))
            vtFillYUV(buffer: self, fill: fill)
        } else {
            let bpp = vtBytesPerPixel(pixelFormat)
            self.bytesPerRow = width * bpp
            self.plane1BytesPerRow = 0
            self.data = [UInt8](repeating: 0, count: height * width * bpp)
            self.plane1 = []
            vtFillPacked(buffer: self, fill: fill)
        }
    }

    init(copying other: VTHostPixelBuffer) {
        self.width = other.width
        self.height = other.height
        self.pixelFormat = other.pixelFormat
        self.bytesPerRow = other.bytesPerRow
        self.data = other.data
        self.plane1 = other.plane1
        self.plane1BytesPerRow = other.plane1BytesPerRow
        self.isPlanar = other.isPlanar
        self.lockCount = 0
    }
}

final class VTHostSampleBuffer {
    var format: VTVideoFormatDescription
    var pixelBuffer: OpaquePointer?
    var encoded: [UInt8]
    var pts: VTMediaTime
    var duration: VTMediaTime
    var valid: Bool = true

    init(
        format: VTVideoFormatDescription,
        pixelBuffer: OpaquePointer?,
        encoded: [UInt8] = [],
        pts: VTMediaTime,
        duration: VTMediaTime
    ) {
        self.format = format
        self.pixelBuffer = pixelBuffer
        self.encoded = encoded
        self.pts = pts
        self.duration = duration
    }
}

final class VTHostCGImage {
    let width: Int
    let height: Int
    let bitsPerPixel: Int
    let bytesPerRow: Int
    let rgba: [UInt8]

    init(width: Int, height: Int, rgba: [UInt8]) {
        self.width = width
        self.height = height
        self.bitsPerPixel = 32
        self.bytesPerRow = width * 4
        self.rgba = rgba
    }
}

func vtBytesPerPixel(_ format: UInt32) -> Int {
    switch format {
    case kVTPixelFormat_24RGB, kVTPixelFormat_24BGR:
        return 3
    default:
        return 4
    }
}

func vtSupportedPixelFormat(_ format: UInt32) -> Bool {
    switch format {
    case kVTPixelFormat_32ARGB,
         kVTPixelFormat_32BGRA,
         kVTPixelFormat_32ABGR,
         kVTPixelFormat_32RGBA,
         kVTPixelFormat_24RGB,
         kVTPixelFormat_24BGR,
         kVTPixelFormat_420YpCbCr8BiPlanarVideoRange,
         kVTPixelFormat_420YpCbCr8BiPlanarFullRange:
        return true
    default:
        return false
    }
}

func vtReadPackedPixel(_ buffer: VTHostPixelBuffer, x: Int, y: Int) -> VTPackedRGBA {
    if buffer.isPlanar {
        return vtReadYUV(buffer, x: x, y: y)
    }
    let bpp = vtBytesPerPixel(buffer.pixelFormat)
    let offset = y * buffer.bytesPerRow + x * bpp
    let bytes = buffer.data
    switch buffer.pixelFormat {
    case kVTPixelFormat_32BGRA:
        return VTPackedRGBA(r: bytes[offset + 2], g: bytes[offset + 1], b: bytes[offset], a: bytes[offset + 3])
    case kVTPixelFormat_32RGBA:
        return VTPackedRGBA(r: bytes[offset], g: bytes[offset + 1], b: bytes[offset + 2], a: bytes[offset + 3])
    case kVTPixelFormat_32ARGB:
        return VTPackedRGBA(r: bytes[offset + 1], g: bytes[offset + 2], b: bytes[offset + 3], a: bytes[offset])
    case kVTPixelFormat_32ABGR:
        return VTPackedRGBA(r: bytes[offset + 3], g: bytes[offset + 2], b: bytes[offset + 1], a: bytes[offset])
    case kVTPixelFormat_24RGB:
        return VTPackedRGBA(r: bytes[offset], g: bytes[offset + 1], b: bytes[offset + 2], a: 255)
    case kVTPixelFormat_24BGR:
        return VTPackedRGBA(r: bytes[offset + 2], g: bytes[offset + 1], b: bytes[offset], a: 255)
    default:
        return VTPackedRGBA(r: 0, g: 0, b: 0, a: 255)
    }
}

func vtWritePackedPixel(_ buffer: VTHostPixelBuffer, x: Int, y: Int, pixel: VTPackedRGBA) {
    if buffer.isPlanar {
        vtWriteYUV(buffer, x: x, y: y, pixel: pixel)
        return
    }
    let bpp = vtBytesPerPixel(buffer.pixelFormat)
    let offset = y * buffer.bytesPerRow + x * bpp
    switch buffer.pixelFormat {
    case kVTPixelFormat_32BGRA:
        buffer.data[offset] = pixel.b
        buffer.data[offset + 1] = pixel.g
        buffer.data[offset + 2] = pixel.r
        buffer.data[offset + 3] = pixel.a
    case kVTPixelFormat_32RGBA:
        buffer.data[offset] = pixel.r
        buffer.data[offset + 1] = pixel.g
        buffer.data[offset + 2] = pixel.b
        buffer.data[offset + 3] = pixel.a
    case kVTPixelFormat_32ARGB:
        buffer.data[offset] = pixel.a
        buffer.data[offset + 1] = pixel.r
        buffer.data[offset + 2] = pixel.g
        buffer.data[offset + 3] = pixel.b
    case kVTPixelFormat_32ABGR:
        buffer.data[offset] = pixel.a
        buffer.data[offset + 1] = pixel.b
        buffer.data[offset + 2] = pixel.g
        buffer.data[offset + 3] = pixel.r
    case kVTPixelFormat_24RGB:
        buffer.data[offset] = pixel.r
        buffer.data[offset + 1] = pixel.g
        buffer.data[offset + 2] = pixel.b
    case kVTPixelFormat_24BGR:
        buffer.data[offset] = pixel.b
        buffer.data[offset + 1] = pixel.g
        buffer.data[offset + 2] = pixel.r
    default:
        break
    }
}

func vtClampU8(_ value: Int) -> UInt8 {
    if value < 0 { return 0 }
    if value > 255 { return 255 }
    return UInt8(value)
}

func vtReadYUV(_ buffer: VTHostPixelBuffer, x: Int, y: Int) -> VTPackedRGBA {
    let yValue = Int(buffer.data[y * buffer.bytesPerRow + x])
    let uvIndex = (y / 2) * buffer.plane1BytesPerRow + (x & ~1)
    let cb = Int(buffer.plane1[uvIndex]) - 128
    let cr = Int(buffer.plane1[uvIndex + 1]) - 128
    let fullRange = buffer.pixelFormat == kVTPixelFormat_420YpCbCr8BiPlanarFullRange
    let y2: Int
    if fullRange {
        y2 = yValue
    } else {
        y2 = ((yValue - 16) * 255) / 219
    }
    let r = y2 + (359 * cr) / 256
    let g = y2 - (88 * cb) / 256 - (183 * cr) / 256
    let b = y2 + (454 * cb) / 256
    return VTPackedRGBA(r: vtClampU8(r), g: vtClampU8(g), b: vtClampU8(b), a: 255)
}

func vtWriteYUV(_ buffer: VTHostPixelBuffer, x: Int, y: Int, pixel: VTPackedRGBA) {
    let r = Int(pixel.r)
    let g = Int(pixel.g)
    let b = Int(pixel.b)
    var yValue = (77 * r + 150 * g + 29 * b) / 256
    let fullRange = buffer.pixelFormat == kVTPixelFormat_420YpCbCr8BiPlanarFullRange
    if !fullRange {
        yValue = (yValue * 219) / 255 + 16
    }
    buffer.data[y * buffer.bytesPerRow + x] = vtClampU8(yValue)
    if (x & 1) == 0 && (y & 1) == 0 {
        let cb = ((-43 * r - 85 * g + 128 * b) / 256) + 128
        let cr = ((128 * r - 107 * g - 21 * b) / 256) + 128
        let uvIndex = (y / 2) * buffer.plane1BytesPerRow + x
        buffer.plane1[uvIndex] = vtClampU8(cb)
        buffer.plane1[uvIndex + 1] = vtClampU8(cr)
    }
}

func vtFillPacked(buffer: VTHostPixelBuffer, fill: VTPackedRGBA) {
    for y in 0..<buffer.height {
        for x in 0..<buffer.width {
            vtWritePackedPixel(buffer, x: x, y: y, pixel: fill)
        }
    }
}

func vtFillYUV(buffer: VTHostPixelBuffer, fill: VTPackedRGBA) {
    for y in 0..<buffer.height {
        for x in 0..<buffer.width {
            vtWriteYUV(buffer, x: x, y: y, pixel: fill)
        }
    }
}

enum VTScaleMode {
    case normal
    case letterbox
    case trim
    case cropSourceToCleanAperture
}

func vtParseScaleMode(_ value: String?) -> VTScaleMode {
    switch value {
    case kVTScalingMode_Letterbox, "Letterbox":
        return .letterbox
    case kVTScalingMode_Trim, "Trim":
        return .trim
    case kVTScalingMode_CropSourceToCleanAperture, "CropSourceToCleanAperture":
        return .cropSourceToCleanAperture
    default:
        return .normal
    }
}

func vtMapDestinationToSource(
    destX: Int,
    destY: Int,
    destWidth: Int,
    destHeight: Int,
    sourceWidth: Int,
    sourceHeight: Int,
    mode: VTScaleMode
) -> (sx: Double, sy: Double)? {
    let dw = Double(destWidth)
    let dh = Double(destHeight)
    let sw = Double(sourceWidth)
    let sh = Double(sourceHeight)
    switch mode {
    case .normal, .cropSourceToCleanAperture:
        return (Double(destX) * sw / dw, Double(destY) * sh / dh)
    case .letterbox:
        let scale = min(dw / sw, dh / sh)
        let contentW = sw * scale
        let contentH = sh * scale
        let offX = (dw - contentW) / 2
        let offY = (dh - contentH) / 2
        let fx = Double(destX) - offX
        let fy = Double(destY) - offY
        if fx < 0 || fy < 0 || fx >= contentW || fy >= contentH {
            return nil
        }
        return (fx / scale, fy / scale)
    case .trim:
        let scale = max(dw / sw, dh / sh)
        let contentW = sw * scale
        let contentH = sh * scale
        let offX = (contentW - dw) / 2
        let offY = (dh - contentH) / 2
        return ((Double(destX) + offX) / scale, (Double(destY) + offY) / scale)
    }
}

func vtSampleBilinear(_ source: VTHostPixelBuffer, sx: Double, sy: Double) -> VTPackedRGBA {
    let x0 = max(0, min(source.width - 1, Int(floor(sx))))
    let y0 = max(0, min(source.height - 1, Int(floor(sy))))
    let x1 = max(0, min(source.width - 1, x0 + 1))
    let y1 = max(0, min(source.height - 1, y0 + 1))
    let fx = sx - floor(sx)
    let fy = sy - floor(sy)
    let p00 = vtReadPackedPixel(source, x: x0, y: y0)
    let p10 = vtReadPackedPixel(source, x: x1, y: y0)
    let p01 = vtReadPackedPixel(source, x: x0, y: y1)
    let p11 = vtReadPackedPixel(source, x: x1, y: y1)
    func mix(_ a: UInt8, _ b: UInt8, _ t: Double) -> Double {
        Double(a) + (Double(b) - Double(a)) * t
    }
    func mixRow(_ a: VTPackedRGBA, _ b: VTPackedRGBA) -> (r: Double, g: Double, b: Double, a: Double) {
        (mix(a.r, b.r, fx), mix(a.g, b.g, fx), mix(a.b, b.b, fx), mix(a.a, b.a, fx))
    }
    let top = mixRow(p00, p10)
    let bot = mixRow(p01, p11)
    return VTPackedRGBA(
        r: vtClampU8(Int((top.r + (bot.r - top.r) * fy).rounded())),
        g: vtClampU8(Int((top.g + (bot.g - top.g) * fy).rounded())),
        b: vtClampU8(Int((top.b + (bot.b - top.b) * fy).rounded())),
        a: vtClampU8(Int((top.a + (bot.a - top.a) * fy).rounded()))
    )
}

func vtTransferPixels(
    source: VTHostPixelBuffer,
    destination: VTHostPixelBuffer,
    scalingMode: VTScaleMode
) -> OSStatus {
    if source.width <= 0 || source.height <= 0 || destination.width <= 0 || destination.height <= 0 {
        return kVTParameterErr
    }
    for y in 0..<destination.height {
        for x in 0..<destination.width {
            if let mapped = vtMapDestinationToSource(
                destX: x,
                destY: y,
                destWidth: destination.width,
                destHeight: destination.height,
                sourceWidth: source.width,
                sourceHeight: source.height,
                mode: scalingMode
            ) {
                let pixel = vtSampleBilinear(source, sx: mapped.sx, sy: mapped.sy)
                vtWritePackedPixel(destination, x: x, y: y, pixel: pixel)
            } else {
                vtWritePackedPixel(destination, x: x, y: y, pixel: VTPackedRGBA(r: 0, g: 0, b: 0, a: 255))
            }
        }
    }
    return 0
}

func vtRotatePixels(
    source: VTHostPixelBuffer,
    destination: VTHostPixelBuffer,
    rotation: String,
    flipHorizontal: Bool,
    flipVertical: Bool
) -> OSStatus {
    let turns: Int
    switch rotation {
    case kVTRotation_CW90, "CW90":
        turns = 1
    case kVTRotation_180, "180":
        turns = 2
    case kVTRotation_CCW90, "CCW90":
        turns = 3
    default:
        turns = 0
    }
    let expectedWidth = (turns == 1 || turns == 3) ? source.height : source.width
    let expectedHeight = (turns == 1 || turns == 3) ? source.width : source.height
    if destination.width != expectedWidth || destination.height != expectedHeight {
        return kVTPixelRotationNotSupportedErr
    }
    for y in 0..<source.height {
        for x in 0..<source.width {
            var dx = x
            var dy = y
            switch turns {
            case 1:
                dx = source.height - 1 - y
                dy = x
            case 2:
                dx = source.width - 1 - x
                dy = source.height - 1 - y
            case 3:
                dx = y
                dy = source.width - 1 - x
            default:
                break
            }
            if flipHorizontal {
                dx = destination.width - 1 - dx
            }
            if flipVertical {
                dy = destination.height - 1 - dy
            }
            let pixel = vtReadPackedPixel(source, x: x, y: y)
            vtWritePackedPixel(destination, x: dx, y: dy, pixel: pixel)
        }
    }
    return 0
}

func vtRGBABytes(from buffer: VTHostPixelBuffer) -> [UInt8] {
    var out = [UInt8](repeating: 0, count: buffer.width * buffer.height * 4)
    for y in 0..<buffer.height {
        for x in 0..<buffer.width {
            let pixel = vtReadPackedPixel(buffer, x: x, y: y)
            let offset = (y * buffer.width + x) * 4
            out[offset] = pixel.r
            out[offset + 1] = pixel.g
            out[offset + 2] = pixel.b
            out[offset + 3] = pixel.a
        }
    }
    return out
}
