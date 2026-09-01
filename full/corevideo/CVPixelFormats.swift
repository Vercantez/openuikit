import Foundation

// Pixel-format OSType constants reconstructed from Apple's public CVPixelBuffer
// four-character codes. Compressed (lossy/lossless) codes are recorded for
// identification only; software allocation of those formats fails closed.

public func CVPixelFormatTypeCopyFourCharCodeString(_ pixelFormat: OSType) -> CFString {
    let bytes: [UInt8] = [
        UInt8((pixelFormat >> 24) & 0xFF),
        UInt8((pixelFormat >> 16) & 0xFF),
        UInt8((pixelFormat >> 8) & 0xFF),
        UInt8(pixelFormat & 0xFF),
    ]
    if bytes.allSatisfy({ (0x20...0x7E).contains($0) }) {
        return String(bytes: bytes, encoding: .ascii)! as NSString
    }
    return String(format: "%u", pixelFormat) as NSString
}

/// 1-bit monochrome
public let kCVPixelFormatType_1Monochrome: OSType = 0x00000001

/// 2-bit indexed
public let kCVPixelFormatType_2Indexed: OSType = 0x00000002

/// 4-bit indexed
public let kCVPixelFormatType_4Indexed: OSType = 0x00000004

/// 8-bit indexed
public let kCVPixelFormatType_8Indexed: OSType = 0x00000008

/// 16-bit BE RGB 555
public let kCVPixelFormatType_16BE555: OSType = 0x00000010

/// 24-bit RGB
public let kCVPixelFormatType_24RGB: OSType = 0x00000018

/// 32-bit ARGB
public let kCVPixelFormatType_32ARGB: OSType = 0x00000020

/// 1-bit indexed gray, white is zero
public let kCVPixelFormatType_1IndexedGray_WhiteIsZero: OSType = 0x00000021

/// 2-bit indexed gray, white is zero
public let kCVPixelFormatType_2IndexedGray_WhiteIsZero: OSType = 0x00000022

/// 4-bit indexed gray, white is zero
public let kCVPixelFormatType_4IndexedGray_WhiteIsZero: OSType = 0x00000024

/// 8-bit indexed gray, white is zero
public let kCVPixelFormatType_8IndexedGray_WhiteIsZero: OSType = 0x00000028

/// 16-bit LE RGB 555
public let kCVPixelFormatType_16LE555: OSType = 0x4C353535

/// 16-bit LE RGB 5551
public let kCVPixelFormatType_16LE5551: OSType = 0x35353531

/// 16-bit BE RGB 565
public let kCVPixelFormatType_16BE565: OSType = 0x42353635

/// 16-bit LE RGB 565
public let kCVPixelFormatType_16LE565: OSType = 0x4C353635

/// 24-bit BGR
public let kCVPixelFormatType_24BGR: OSType = 0x32344247

/// 32-bit BGRA
public let kCVPixelFormatType_32BGRA: OSType = 0x42475241

/// 32-bit ABGR
public let kCVPixelFormatType_32ABGR: OSType = 0x41424752

/// 32-bit RGBA
public let kCVPixelFormatType_32RGBA: OSType = 0x52474241

/// 64-bit ARGB 16-bit BE samples
public let kCVPixelFormatType_64ARGB: OSType = 0x62363461

/// 64-bit RGBA 16-bit LE samples
public let kCVPixelFormatType_64RGBALE: OSType = 0x6C363472

/// 48-bit RGB 16-bit BE samples
public let kCVPixelFormatType_48RGB: OSType = 0x62343872

/// 32-bit AlphaGray 16-bit BE
public let kCVPixelFormatType_32AlphaGray: OSType = 0x62333261

/// 16-bit gray BE
public let kCVPixelFormatType_16Gray: OSType = 0x62313667

/// 30-bit RGB, 10-bit BE samples
public let kCVPixelFormatType_30RGB: OSType = 0x5231306B

/// 30-bit RGB r210
public let kCVPixelFormatType_30RGB_r210: OSType = 0x72323130

/// 8-bit 4:2:2 Cb Y Cr Y
public let kCVPixelFormatType_422YpCbCr8: OSType = 0x32767579

/// 8-bit 4:4:4:4 Cb Y Cr A
public let kCVPixelFormatType_4444YpCbCrA8: OSType = 0x76343038

/// 8-bit 4:4:4:4 A Y Cb Cr
public let kCVPixelFormatType_4444YpCbCrA8R: OSType = 0x72343038

/// 8-bit 4:4:4:4 A Y Cb Cr
public let kCVPixelFormatType_4444AYpCbCr8: OSType = 0x79343038

/// 16-bit 4:4:4:4 A Y Cb Cr
public let kCVPixelFormatType_4444AYpCbCr16: OSType = 0x79343136

/// float 4:4:4:4 A Y Cb Cr
public let kCVPixelFormatType_4444AYpCbCrFloat: OSType = 0x7234666C

/// 8-bit 4:4:4
public let kCVPixelFormatType_444YpCbCr8: OSType = 0x76333038

/// 16-bit 4:2:2
public let kCVPixelFormatType_422YpCbCr16: OSType = 0x76323136

/// 10-bit 4:2:2 packed
public let kCVPixelFormatType_422YpCbCr10: OSType = 0x76323130

/// 10-bit 4:4:4
public let kCVPixelFormatType_444YpCbCr10: OSType = 0x76343130

/// 8-bit 4:2:0 planar video range
public let kCVPixelFormatType_420YpCbCr8Planar: OSType = 0x79343230

/// 8-bit 4:2:0 planar full range
public let kCVPixelFormatType_420YpCbCr8PlanarFullRange: OSType = 0x66343230

/// 8-bit 4:2:2 + alpha biplanar
public let kCVPixelFormatType_422YpCbCr_4A_8BiPlanar: OSType = 0x61327679

/// 8-bit 4:2:0 biplanar video range
public let kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange: OSType = 0x34323076

/// 8-bit 4:2:0 biplanar full range
public let kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: OSType = 0x34323066

/// 8-bit 4:2:2 biplanar video range
public let kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange: OSType = 0x34323276

/// 8-bit 4:2:2 biplanar full range
public let kCVPixelFormatType_422YpCbCr8BiPlanarFullRange: OSType = 0x34323266

/// 8-bit 4:4:4 biplanar video range
public let kCVPixelFormatType_444YpCbCr8BiPlanarVideoRange: OSType = 0x34343476

/// 8-bit 4:4:4 biplanar full range
public let kCVPixelFormatType_444YpCbCr8BiPlanarFullRange: OSType = 0x34343466

/// 8-bit 4:2:2 Y Cb Y Cr
public let kCVPixelFormatType_422YpCbCr8_yuvs: OSType = 0x79757673

/// 8-bit 4:2:2 full range Y Cb Y Cr
public let kCVPixelFormatType_422YpCbCr8FullRange: OSType = 0x79757666

/// 8-bit one component
public let kCVPixelFormatType_OneComponent8: OSType = 0x4C303038

/// 8-bit two component
public let kCVPixelFormatType_TwoComponent8: OSType = 0x32433038

/// 30-bit RGB LE packed wide gamut
public let kCVPixelFormatType_30RGBLEPackedWideGamut: OSType = 0x77333072

/// ARGB 2-10-10-10 LE packed
public let kCVPixelFormatType_ARGB2101010LEPacked: OSType = 0x6C313072

/// 40-bit ARGB LE wide gamut
public let kCVPixelFormatType_40ARGBLEWideGamut: OSType = 0x77343061

/// 40-bit ARGB LE wide gamut premultiplied
public let kCVPixelFormatType_40ARGBLEWideGamutPremultiplied: OSType = 0x7734306D

/// 10-bit one component
public let kCVPixelFormatType_OneComponent10: OSType = 0x4C303130

/// 12-bit one component
public let kCVPixelFormatType_OneComponent12: OSType = 0x4C303132

/// 16-bit one component
public let kCVPixelFormatType_OneComponent16: OSType = 0x4C303136

/// 16-bit two component
public let kCVPixelFormatType_TwoComponent16: OSType = 0x32433136

/// 16-bit half one component
public let kCVPixelFormatType_OneComponent16Half: OSType = 0x4C303068

/// 32-bit float one component
public let kCVPixelFormatType_OneComponent32Float: OSType = 0x4C303066

/// 16-bit half two component
public let kCVPixelFormatType_TwoComponent16Half: OSType = 0x32433068

/// 32-bit float two component
public let kCVPixelFormatType_TwoComponent32Float: OSType = 0x32433066

/// 64-bit RGBA half
public let kCVPixelFormatType_64RGBAHalf: OSType = 0x52476841

/// 128-bit RGBA float
public let kCVPixelFormatType_128RGBAFloat: OSType = 0x52476641

/// 14-bit Bayer GRBG
public let kCVPixelFormatType_14Bayer_GRBG: OSType = 0x67726234

/// 14-bit Bayer RGGB
public let kCVPixelFormatType_14Bayer_RGGB: OSType = 0x72676734

/// 14-bit Bayer BGGR
public let kCVPixelFormatType_14Bayer_BGGR: OSType = 0x62676734

/// 14-bit Bayer GBRG
public let kCVPixelFormatType_14Bayer_GBRG: OSType = 0x67627234

/// disparity float16
public let kCVPixelFormatType_DisparityFloat16: OSType = 0x68646973

/// disparity float32
public let kCVPixelFormatType_DisparityFloat32: OSType = 0x66646973

/// depth float16
public let kCVPixelFormatType_DepthFloat16: OSType = 0x68646570

/// depth float32
public let kCVPixelFormatType_DepthFloat32: OSType = 0x66646570

/// 10-bit 4:2:0 biplanar video range
public let kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange: OSType = 0x78343230

/// 10-bit 4:2:2 biplanar video range
public let kCVPixelFormatType_422YpCbCr10BiPlanarVideoRange: OSType = 0x78343232

/// 10-bit 4:4:4 biplanar video range
public let kCVPixelFormatType_444YpCbCr10BiPlanarVideoRange: OSType = 0x78343434

/// 10-bit 4:2:0 biplanar full range
public let kCVPixelFormatType_420YpCbCr10BiPlanarFullRange: OSType = 0x78663230

/// 10-bit 4:2:2 biplanar full range
public let kCVPixelFormatType_422YpCbCr10BiPlanarFullRange: OSType = 0x78663232

/// 10-bit 4:4:4 biplanar full range
public let kCVPixelFormatType_444YpCbCr10BiPlanarFullRange: OSType = 0x78663434

/// 8-bit 4:2:0 + alpha triplanar
public let kCVPixelFormatType_420YpCbCr8VideoRange_8A_TriPlanar: OSType = 0x76306138

/// 16-bit versatile Bayer
public let kCVPixelFormatType_16VersatileBayer: OSType = 0x62703136

/// 96-bit versatile Bayer packed 12
public let kCVPixelFormatType_96VersatileBayerPacked12: OSType = 0x62747032

/// downscaled ProRes RAW RGBA
public let kCVPixelFormatType_64RGBA_DownscaledProResRAW: OSType = 0x62703634

/// 16-bit 4:2:2 biplanar video range
public let kCVPixelFormatType_422YpCbCr16BiPlanarVideoRange: OSType = 0x73763232

/// 16-bit 4:4:4 biplanar video range
public let kCVPixelFormatType_444YpCbCr16BiPlanarVideoRange: OSType = 0x73763434

/// 16-bit 4:4:4 + alpha triplanar
public let kCVPixelFormatType_444YpCbCr16VideoRange_16A_TriPlanar: OSType = 0x73346173

/// 30-bit RGB LE + 8-bit alpha biplanar
public let kCVPixelFormatType_30RGBLE_8A_BiPlanar: OSType = 0x62336138

/// lossless-compressed 32BGRA
public let kCVPixelFormatType_Lossless_32BGRA: OSType = 0x26424741

/// lossless-compressed 64RGBAHalf
public let kCVPixelFormatType_Lossless_64RGBAHalf: OSType = 0x26526841

/// lossless-compressed 420v
public let kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange: OSType = 0x26387630

/// lossless-compressed 420f
public let kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarFullRange: OSType = 0x26386630

/// lossless-compressed 10-bit 420v
public let kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarVideoRange: OSType = 0x26787630

/// lossless-compressed 10-bit 422v
public let kCVPixelFormatType_Lossless_422YpCbCr10PackedBiPlanarVideoRange: OSType = 0x26787632

/// lossless-compressed 10-bit 420f
public let kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarFullRange: OSType = 0x26786630

/// lossless-compressed 30RGBLE+A
public let kCVPixelFormatType_Lossless_30RGBLE_8A_BiPlanar: OSType = 0x26623338

/// lossless-compressed wide-gamut 30RGB
public let kCVPixelFormatType_Lossless_30RGBLEPackedWideGamut: OSType = 0x26773372

/// lossy-compressed 32BGRA
public let kCVPixelFormatType_Lossy_32BGRA: OSType = 0x2D424741

/// lossy-compressed 420v
public let kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarVideoRange: OSType = 0x2D387630

/// lossy-compressed 420f
public let kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarFullRange: OSType = 0x2D386630

/// lossy-compressed 10-bit 420v
public let kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarVideoRange: OSType = 0x2D787630

/// lossy-compressed 10-bit 422v
public let kCVPixelFormatType_Lossy_422YpCbCr10PackedBiPlanarVideoRange: OSType = 0x2D787632

func _cvIsCompressedPixelFormat(_ pixelFormat: OSType) -> Bool {
    switch pixelFormat {
    case kCVPixelFormatType_Lossless_32BGRA,
        kCVPixelFormatType_Lossless_64RGBAHalf,
        kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange,
        kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarFullRange,
        kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarVideoRange,
        kCVPixelFormatType_Lossless_422YpCbCr10PackedBiPlanarVideoRange,
        kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarFullRange,
        kCVPixelFormatType_Lossless_30RGBLE_8A_BiPlanar,
        kCVPixelFormatType_Lossless_30RGBLEPackedWideGamut,
        kCVPixelFormatType_Lossy_32BGRA,
        kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarVideoRange,
        kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarFullRange,
        kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarVideoRange,
        kCVPixelFormatType_Lossy_422YpCbCr10PackedBiPlanarVideoRange:
        return true
    default:
        return false
    }
}

public func CVIsCompressedPixelFormatAvailable(_ pixelFormatType: OSType) -> Bool {
    // Linux has no Apple video compressor for these FourCCs.
    _ = pixelFormatType
    return false
}

public let kCVVersatileBayer_BayerPattern_RGGB: Int = 0
public let kCVVersatileBayer_BayerPattern_GRBG: Int = 1
public let kCVVersatileBayer_BayerPattern_GBRG: Int = 2
public let kCVVersatileBayer_BayerPattern_BGGR: Int = 3

