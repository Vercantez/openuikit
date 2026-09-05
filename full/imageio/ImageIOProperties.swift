import Foundation

// PNG IHDR / pHYs / tEXt / gAMA and JPEG SOF / APP0 JFIF / APP1 Exif
// property dictionaries. Numbers are from Apple ImageIO 2026-09-05
// (macOS 26.1): a raw 2×1 RGB PNG with pHYs 5669 ppm, gAMA 45455, tEXt
// Title=Hello produced DPIWidth/Height=144, Gamma=0.45455, {PNG}.Title
// and {IPTC}.ObjectName; a dest JPEG with orientation 6 produced
// {JFIF}/{Exif}/{TIFF}/{GPS} under those dictionary names.

struct ImageIOParsedFile {
    var type: CFString?
    var width: Int?
    var height: Int?
    var orientation: UInt32 = 1
    var depth: Int = 8
    var hasAlpha: Bool?
    var colorModel: CFString = kCGImagePropertyColorModelRGB
    var dpiWidth: Double?
    var dpiHeight: Double?
    var isProgressiveJPEG = false
    var png: [CFString: Any] = [:]
    var jfif: [CFString: Any] = [:]
    var tiff: [CFString: Any] = [:]
    var exif: [CFString: Any] = [:]
    var gps: [CFString: Any] = [:]
    var gif: [CFString: Any] = [:]
    var iptc: [CFString: Any] = [:]
    var frameCount = 0
    var frameDelays: [Double] = []
}

func imageioParseFile(_ data: Data) -> ImageIOParsedFile {
    var parsed = ImageIOParsedFile()
    parsed.type = imageioDetectType(data)
    guard let type = parsed.type else { return parsed }
    if type == imageioTypePNG {
        imageioParsePNG(data, into: &parsed)
    } else if type == imageioTypeJPEG {
        imageioParseJPEG(data, into: &parsed)
    } else if type == imageioTypeGIF {
        imageioParseGIF(data, into: &parsed)
    } else if type == imageioTypeBMP {
        imageioParseBMP(data, into: &parsed)
    }
    return parsed
}

func imageioProperties(
    _ parsed: ImageIOParsedFile,
    image: CGImage?,
    index: Int,
    fileSize: Int,
    container: Bool
) -> CFDictionary {
    if container {
        var properties: CFDictionary = [
            kCGImagePropertyFileSize: fileSize,
        ]
        if parsed.type == imageioTypeGIF, !parsed.gif.isEmpty {
            properties[kCGImagePropertyGIFDictionary] = parsed.gif
        }
        return properties
    }

    let width = image?.width ?? parsed.width
    let height = image?.height ?? parsed.height
    var properties: CFDictionary = [:]
    if let width { properties[kCGImagePropertyPixelWidth] = width }
    if let height { properties[kCGImagePropertyPixelHeight] = height }
    properties[kCGImagePropertyOrientation] = parsed.orientation
    properties[kCGImagePropertyDepth] = parsed.depth
    properties[kCGImagePropertyColorModel] = parsed.colorModel
    if let hasAlpha = parsed.hasAlpha {
        properties[kCGImagePropertyHasAlpha] = hasAlpha ? 1 : 0
    }
    if let dpi = parsed.dpiWidth {
        properties[kCGImagePropertyDPIWidth] = dpi
    }
    if let dpi = parsed.dpiHeight {
        properties[kCGImagePropertyDPIHeight] = dpi
    }
    if parsed.type == imageioTypePNG || parsed.type == imageioTypeJPEG {
        properties[kCGImagePropertyProfileName] = "sRGB IEC61966-2.1"
    }
    if !parsed.png.isEmpty {
        properties[kCGImagePropertyPNGDictionary] = parsed.png
    }
    if !parsed.jfif.isEmpty {
        properties[kCGImagePropertyJFIFDictionary] = parsed.jfif
    }
    if !parsed.tiff.isEmpty {
        properties[kCGImagePropertyTIFFDictionary] = parsed.tiff
    }
    if !parsed.exif.isEmpty {
        properties[kCGImagePropertyExifDictionary] = parsed.exif
    }
    if !parsed.gps.isEmpty {
        properties[kCGImagePropertyGPSDictionary] = parsed.gps
    }
    if parsed.type == imageioTypeGIF {
        var gif = parsed.gif
        let delay = index < parsed.frameDelays.count ? parsed.frameDelays[index] : 0
        gif[kCGImagePropertyGIFDelayTime] = delay
        gif[kCGImagePropertyGIFUnclampedDelayTime] = delay
        properties[kCGImagePropertyGIFDictionary] = gif
    }
    if !parsed.iptc.isEmpty {
        properties[kCGImagePropertyIPTCDictionary] = parsed.iptc
    }
    return properties
}

func imageioDictInt(_ dict: CFDictionary?, _ key: CFString) -> Int? {
    guard let dict else { return nil }
    if let value = dict[key] as? Int { return value }
    if let value = dict[key] as? NSNumber { return value.intValue }
    return nil
}

func imageioDictDouble(_ dict: CFDictionary?, _ key: CFString) -> Double? {
    guard let dict else { return nil }
    if let value = dict[key] as? Double { return value }
    if let value = dict[key] as? Int { return Double(value) }
    if let value = dict[key] as? NSNumber { return value.doubleValue }
    return nil
}

func imageioDictBool(_ dict: CFDictionary?, _ key: CFString) -> Bool {
    guard let dict else { return false }
    if let value = dict[key] as? Bool { return value }
    if let value = dict[key] as? NSNumber { return value.boolValue }
    return false
}

func imageioDictNested(_ dict: CFDictionary?, _ key: CFString) -> CFDictionary? {
    dict?[key] as? CFDictionary
}

// MARK: - PNG

private func imageioParsePNG(_ data: Data, into parsed: inout ImageIOParsedFile) {
    let bytes = Array(data)
    guard bytes.count >= 10,
          bytes[0] == 137, bytes[1] == 80, bytes[2] == 78, bytes[3] == 71,
          bytes[4] == 13, bytes[5] == 10, bytes[6] == 26, bytes[7] == 10 else {
        return
    }
    parsed.frameCount = 1
    var offset = 8
    while offset + 12 <= bytes.count {
        let length = Int(imageioU32BE(bytes, offset))
        guard length >= 0, offset + 12 + length <= bytes.count else { break }
        let type0 = bytes[offset + 4]
        let type1 = bytes[offset + 5]
        let type2 = bytes[offset + 6]
        let type3 = bytes[offset + 7]
        let payload = Array(bytes[(offset + 8)..<(offset + 8 + length)])
        if type0 == 73, type1 == 72, type2 == 68, type3 == 82, payload.count >= 13 {
            parsed.width = Int(imageioU32BE(payload, 0))
            parsed.height = Int(imageioU32BE(payload, 4))
            parsed.depth = Int(payload[8])
            let colorType = payload[9]
            parsed.png[kCGImagePropertyPNGInterlaceType] = Int(payload[12])
            switch colorType {
            case 0, 4:
                parsed.colorModel = kCGImagePropertyColorModelGray
            default:
                parsed.colorModel = kCGImagePropertyColorModelRGB
            }
            if colorType == 4 || colorType == 6 {
                parsed.hasAlpha = true
            }
        } else if type0 == 112, type1 == 72, type2 == 89, type3 == 115, payload.count >= 9 {
            let xPPM = Int(imageioU32BE(payload, 0))
            let yPPM = Int(imageioU32BE(payload, 4))
            let unit = payload[8]
            parsed.png[kCGImagePropertyPNGXPixelsPerMeter] = xPPM
            parsed.png[kCGImagePropertyPNGYPixelsPerMeter] = yPPM
            if unit == 1 {
                // MEASURED 2026-09-05: pHYs 5669 ppm → DPIWidth 144
                // because 5669 * 0.0254 = 143.9926, rounded to 144.
                parsed.dpiWidth = (Double(xPPM) * 0.0254).rounded()
                parsed.dpiHeight = (Double(yPPM) * 0.0254).rounded()
            }
        } else if type0 == 103, type1 == 65, type2 == 77, type3 == 65, payload.count >= 4 {
            let raw = imageioU32BE(payload, 0)
            let gamma = Double(raw) / 100_000.0
            parsed.png[kCGImagePropertyPNGGamma] = gamma
        } else if type0 == 116, type1 == 69, type2 == 88, type3 == 116 {
            imageioParsePNGText(payload, into: &parsed)
        }
        offset += 12 + length
        if type0 == 73, type1 == 69, type2 == 78, type3 == 68 { break }
    }
    if let width = parsed.width, let height = parsed.height {
        parsed.exif[kCGImagePropertyExifPixelXDimension] = width
        parsed.exif[kCGImagePropertyExifPixelYDimension] = height
        parsed.exif[kCGImagePropertyExifColorSpace] = 1
    }
    if let dpi = parsed.dpiWidth {
        parsed.tiff[kCGImagePropertyTIFFXResolution] = dpi
        parsed.tiff[kCGImagePropertyTIFFResolutionUnit] = 2
    }
    if let dpi = parsed.dpiHeight {
        parsed.tiff[kCGImagePropertyTIFFYResolution] = dpi
        parsed.tiff[kCGImagePropertyTIFFResolutionUnit] = 2
    }
    parsed.tiff[kCGImagePropertyTIFFOrientation] = parsed.orientation
}

private func imageioParsePNGText(_ payload: [UInt8], into parsed: inout ImageIOParsedFile) {
    guard let zero = payload.firstIndex(of: 0) else { return }
    let keyword = String(bytes: payload[0..<zero], encoding: .isoLatin1) ?? ""
    let value = String(bytes: payload[(zero + 1)...], encoding: .isoLatin1) ?? ""
    if keyword == "Title" {
        parsed.png[kCGImagePropertyPNGTitle] = value
        parsed.iptc[kCGImagePropertyIPTCObjectName] = value
    } else if keyword == "Author" {
        parsed.png[kCGImagePropertyPNGAuthor] = value
        parsed.iptc[kCGImagePropertyIPTCByline] = [value]
        parsed.tiff[kCGImagePropertyTIFFArtist] = value
    } else if keyword == "Description" {
        parsed.png[kCGImagePropertyPNGDescription] = value
        parsed.iptc[kCGImagePropertyIPTCCaptionAbstract] = value
        parsed.tiff[kCGImagePropertyTIFFImageDescription] = value
    } else if keyword == "Copyright" {
        parsed.png[kCGImagePropertyPNGCopyright] = value
        parsed.iptc[kCGImagePropertyIPTCCopyrightNotice] = value
        parsed.tiff[kCGImagePropertyTIFFCopyright] = value
    } else if keyword == "Software" {
        parsed.png[kCGImagePropertyPNGSoftware] = value
        parsed.tiff[kCGImagePropertyTIFFSoftware] = value
    } else if keyword == "Comment" {
        parsed.png[kCGImagePropertyPNGComment] = value
    } else if keyword == "Disclaimer" {
        parsed.png[kCGImagePropertyPNGDisclaimer] = value
    } else if keyword == "Warning" {
        parsed.png[kCGImagePropertyPNGWarning] = value
    } else if keyword == "Source" {
        parsed.png[kCGImagePropertyPNGSource] = value
    } else if keyword == "Creation Time" {
        parsed.png[kCGImagePropertyPNGCreationTime] = value
    }
}

// MARK: - JPEG

private func imageioParseJPEG(_ data: Data, into parsed: inout ImageIOParsedFile) {
    let bytes = Array(data)
    guard bytes.count >= 2, bytes[0] == 0xff, bytes[1] == 0xd8 else { return }
    parsed.frameCount = 1
    var offset = 2
    while offset + 1 < bytes.count {
        guard bytes[offset] == 0xff else { offset += 1; continue }
        let marker = bytes[offset + 1]
        if marker == 0xd9 || marker == 0xda { break }
        if marker == 0x00 || marker == 0xff {
            offset += 1
            continue
        }
        guard offset + 3 < bytes.count else { break }
        let length = Int(imageioU16BE(bytes, offset + 2))
        guard length >= 2, offset + 2 + length <= bytes.count else { break }
        let payload = Array(bytes[(offset + 4)..<(offset + 2 + length)])
        let isSOF = (0xc0...0xc3).contains(marker)
            || (0xc5...0xc7).contains(marker)
            || (0xc9...0xcb).contains(marker)
            || (0xcd...0xcf).contains(marker)
        if isSOF, payload.count >= 6 {
            parsed.depth = Int(payload[0])
            parsed.height = Int(imageioU16BE(payload, 1))
            parsed.width = Int(imageioU16BE(payload, 3))
            let components = Int(payload[5])
            parsed.colorModel = components == 1
                ? kCGImagePropertyColorModelGray
                : kCGImagePropertyColorModelRGB
            parsed.isProgressiveJPEG = marker == 0xc2
            parsed.jfif[kCGImagePropertyJFIFIsProgressive] = parsed.isProgressiveJPEG
        } else if marker == 0xe0, payload.count >= 14,
                  payload.count >= 5,
                  payload[0] == 74, payload[1] == 70, payload[2] == 73, payload[3] == 70, payload[4] == 0 {
            parsed.jfif[kCGImagePropertyJFIFVersion] = [Int(payload[5]), Int(payload[6])]
            let unit = Int(payload[7])
            let xDen = Int(imageioU16BE(payload, 8))
            let yDen = Int(imageioU16BE(payload, 10))
            parsed.jfif[kCGImagePropertyJFIFDensityUnit] = unit
            parsed.jfif[kCGImagePropertyJFIFXDensity] = xDen
            parsed.jfif[kCGImagePropertyJFIFYDensity] = yDen
            if unit == 1 {
                parsed.dpiWidth = Double(xDen)
                parsed.dpiHeight = Double(yDen)
            } else if unit == 2 {
                parsed.dpiWidth = (Double(xDen) * 2.54).rounded()
                parsed.dpiHeight = (Double(yDen) * 2.54).rounded()
            } else {
                parsed.dpiWidth = Double(xDen)
                parsed.dpiHeight = Double(yDen)
            }
        } else if marker == 0xe1 {
            imageioParseExif(payload, into: &parsed)
        }
        offset += 2 + length
    }
    if parsed.jfif[kCGImagePropertyJFIFVersion] == nil, parsed.type == imageioTypeJPEG {
        parsed.jfif[kCGImagePropertyJFIFIsProgressive] = parsed.isProgressiveJPEG
    }
    if let width = parsed.width {
        parsed.exif[kCGImagePropertyExifPixelXDimension] = width
    }
    if let height = parsed.height {
        parsed.exif[kCGImagePropertyExifPixelYDimension] = height
    }
}

private func imageioParseExif(_ payload: [UInt8], into parsed: inout ImageIOParsedFile) {
    guard payload.count >= 14,
          payload[0] == 69, payload[1] == 120, payload[2] == 105,
          payload[3] == 102, payload[4] == 0, payload[5] == 0 else { return }
    let tiff = 6
    let little = payload[tiff] == 0x49 && payload[tiff + 1] == 0x49
    let big = payload[tiff] == 0x4d && payload[tiff + 1] == 0x4d
    guard little || big else { return }
    func u16(_ index: Int) -> Int? {
        guard index + 1 < payload.count else { return nil }
        if little {
            return Int(payload[index]) | (Int(payload[index + 1]) << 8)
        }
        return (Int(payload[index]) << 8) | Int(payload[index + 1])
    }
    func u32(_ index: Int) -> Int? {
        guard index + 3 < payload.count else { return nil }
        if little {
            return Int(payload[index])
                | (Int(payload[index + 1]) << 8)
                | (Int(payload[index + 2]) << 16)
                | (Int(payload[index + 3]) << 24)
        }
        return (Int(payload[index]) << 24)
            | (Int(payload[index + 1]) << 16)
            | (Int(payload[index + 2]) << 8)
            | Int(payload[index + 3])
    }
    guard u16(tiff + 2) == 42, let relative = u32(tiff + 4) else { return }
    let ifd = tiff + relative
    guard let count = u16(ifd) else { return }
    for entry in 0..<count {
        let item = ifd + 2 + entry * 12
        guard let tag = u16(item), let typ = u16(item + 2), let num = u32(item + 4) else {
            break
        }
        if tag == 0x0112, typ == 3, num == 1, let value = u16(item + 8),
           (1...8).contains(value) {
            parsed.orientation = UInt32(value)
            parsed.tiff[kCGImagePropertyTIFFOrientation] = value
        } else if tag == 0x010F, let s = imageioTIFFString(payload, tiff: tiff, little: little, item: item, typ: typ, num: num, u32: u32) {
            parsed.tiff[kCGImagePropertyTIFFMake] = s
        } else if tag == 0x0110, let s = imageioTIFFString(payload, tiff: tiff, little: little, item: item, typ: typ, num: num, u32: u32) {
            parsed.tiff[kCGImagePropertyTIFFModel] = s
        } else if tag == 0x011A, let r = imageioTIFFRational(payload, tiff: tiff, little: little, item: item, u32: u32) {
            parsed.tiff[kCGImagePropertyTIFFXResolution] = r
            parsed.dpiWidth = r
        } else if tag == 0x011B, let r = imageioTIFFRational(payload, tiff: tiff, little: little, item: item, u32: u32) {
            parsed.tiff[kCGImagePropertyTIFFYResolution] = r
            parsed.dpiHeight = r
        } else if tag == 0x0128, let value = u16(item + 8) {
            parsed.tiff[kCGImagePropertyTIFFResolutionUnit] = value
        } else if tag == 0x0132, let s = imageioTIFFString(payload, tiff: tiff, little: little, item: item, typ: typ, num: num, u32: u32) {
            parsed.tiff[kCGImagePropertyTIFFDateTime] = s
        } else if tag == 0x013B, let s = imageioTIFFString(payload, tiff: tiff, little: little, item: item, typ: typ, num: num, u32: u32) {
            parsed.tiff[kCGImagePropertyTIFFArtist] = s
        } else if tag == 0x8298, let s = imageioTIFFString(payload, tiff: tiff, little: little, item: item, typ: typ, num: num, u32: u32) {
            parsed.tiff[kCGImagePropertyTIFFCopyright] = s
        } else if tag == 0x8769, let exifOff = u32(item + 8) {
            imageioParseExifIFD(
                payload, tiff: tiff, ifd: tiff + exifOff, little: little,
                u16: u16, u32: u32, into: &parsed
            )
        } else if tag == 0x8825, let gpsOff = u32(item + 8) {
            imageioParseGPSIFD(
                payload, tiff: tiff, ifd: tiff + gpsOff, little: little,
                u16: u16, u32: u32, into: &parsed
            )
        }
    }
}

private func imageioParseExifIFD(
    _ payload: [UInt8],
    tiff: Int,
    ifd: Int,
    little: Bool,
    u16: (Int) -> Int?,
    u32: (Int) -> Int?,
    into parsed: inout ImageIOParsedFile
) {
    guard let count = u16(ifd) else { return }
    for entry in 0..<count {
        let item = ifd + 2 + entry * 12
        guard let tag = u16(item), let typ = u16(item + 2), let num = u32(item + 4) else {
            break
        }
        if tag == 0x9003, let s = imageioTIFFString(payload, tiff: tiff, little: little, item: item, typ: typ, num: num, u32: u32) {
            parsed.exif[kCGImagePropertyExifDateTimeOriginal] = s
        } else if tag == 0x9004, let s = imageioTIFFString(payload, tiff: tiff, little: little, item: item, typ: typ, num: num, u32: u32) {
            parsed.exif[kCGImagePropertyExifDateTimeDigitized] = s
        } else if tag == 0x9286, let s = imageioTIFFString(payload, tiff: tiff, little: little, item: item, typ: typ, num: num, u32: u32) {
            parsed.exif[kCGImagePropertyExifUserComment] = s
        } else if tag == 0xA002, let value = u16(item + 8) {
            parsed.exif[kCGImagePropertyExifPixelXDimension] = value
        } else if tag == 0xA003, let value = u16(item + 8) {
            parsed.exif[kCGImagePropertyExifPixelYDimension] = value
        } else if tag == 0xA001, let value = u16(item + 8) {
            parsed.exif[kCGImagePropertyExifColorSpace] = value
        }
    }
}

private func imageioParseGPSIFD(
    _ payload: [UInt8],
    tiff: Int,
    ifd: Int,
    little: Bool,
    u16: (Int) -> Int?,
    u32: (Int) -> Int?,
    into parsed: inout ImageIOParsedFile
) {
    guard let count = u16(ifd) else { return }
    for entry in 0..<count {
        let item = ifd + 2 + entry * 12
        guard let tag = u16(item), let typ = u16(item + 2), let num = u32(item + 4) else {
            break
        }
        if tag == 1, let s = imageioTIFFString(payload, tiff: tiff, little: little, item: item, typ: typ, num: num, u32: u32) {
            parsed.gps[kCGImagePropertyGPSLatitudeRef] = s
        } else if tag == 2, let r = imageioTIFFRational(payload, tiff: tiff, little: little, item: item, u32: u32) {
            parsed.gps[kCGImagePropertyGPSLatitude] = r
        } else if tag == 3, let s = imageioTIFFString(payload, tiff: tiff, little: little, item: item, typ: typ, num: num, u32: u32) {
            parsed.gps[kCGImagePropertyGPSLongitudeRef] = s
        } else if tag == 4, let r = imageioTIFFRational(payload, tiff: tiff, little: little, item: item, u32: u32) {
            parsed.gps[kCGImagePropertyGPSLongitude] = r
        } else if tag == 5, let value = u16(item + 8) {
            parsed.gps[kCGImagePropertyGPSAltitudeRef] = value
        } else if tag == 6, let r = imageioTIFFRational(payload, tiff: tiff, little: little, item: item, u32: u32) {
            parsed.gps[kCGImagePropertyGPSAltitude] = r
        }
    }
}

private func imageioTIFFString(
    _ payload: [UInt8],
    tiff: Int,
    little: Bool,
    item: Int,
    typ: Int,
    num: Int,
    u32: (Int) -> Int?
) -> String? {
    _ = little
    guard typ == 2, num > 0 else { return nil }
    let start: Int
    if num <= 4 {
        start = item + 8
    } else {
        guard let off = u32(item + 8) else { return nil }
        start = tiff + off
    }
    let end = min(start + num, payload.count)
    guard start < end else { return nil }
    var bytes = Array(payload[start..<end])
    if let z = bytes.firstIndex(of: 0) {
        bytes = Array(bytes[0..<z])
    }
    return String(bytes: bytes, encoding: .utf8) ?? String(bytes: bytes, encoding: .isoLatin1)
}

private func imageioTIFFRational(
    _ payload: [UInt8],
    tiff: Int,
    little: Bool,
    item: Int,
    u32: (Int) -> Int?
) -> Double? {
    guard let off = u32(item + 8) else { return nil }
    let start = tiff + off
    guard let num = u32(start), let den = u32(start + 4), den != 0 else { return nil }
    _ = little
    return Double(num) / Double(den)
}

// MARK: - GIF

private func imageioParseGIF(_ data: Data, into parsed: inout ImageIOParsedFile) {
    let bytes = Array(data)
    guard bytes.count >= 13 else { return }
    parsed.width = Int(bytes[6]) | (Int(bytes[7]) << 8)
    parsed.height = Int(bytes[8]) | (Int(bytes[9]) << 8)
    parsed.gif[kCGImagePropertyGIFCanvasPixelWidth] = parsed.width
    parsed.gif[kCGImagePropertyGIFCanvasPixelHeight] = parsed.height
    let packed = bytes[10]
    parsed.gif[kCGImagePropertyGIFHasGlobalColorMap] = (packed & 0x80) != 0 ? 1 : 0
    var offset = 13
    if packed & 0x80 != 0 {
        let table = 3 * (1 << ((packed & 7) + 1))
        offset += table
    }
    var loop: Int?
    var delays: [Double] = []
    var pendingDelay: Double = 0
    var frames = 0
    while offset < bytes.count {
        let b = bytes[offset]
        if b == 0x3b { break }
        if b == 0x2c {
            frames += 1
            delays.append(pendingDelay)
            pendingDelay = 0
            guard offset + 10 <= bytes.count else { break }
            let local = bytes[offset + 9]
            offset += 10
            if local & 0x80 != 0 {
                offset += 3 * (1 << ((local & 7) + 1))
            }
            offset += 1
            while offset < bytes.count {
                let sz = Int(bytes[offset])
                offset += 1
                if sz == 0 { break }
                offset += sz
            }
            continue
        }
        if b == 0x21 {
            guard offset + 2 <= bytes.count else { break }
            let label = bytes[offset + 1]
            offset += 2
            if label == 0xf9, offset + 6 <= bytes.count, bytes[offset] == 4 {
                let delay = Double(Int(bytes[offset + 2]) | (Int(bytes[offset + 3]) << 8)) / 100.0
                pendingDelay = delay
            } else if label == 0xff {
                var netscape: [UInt8] = []
                var look = offset
                while look < bytes.count {
                    let sz = Int(bytes[look])
                    look += 1
                    if sz == 0 { break }
                    if look + sz <= bytes.count {
                        netscape.append(contentsOf: bytes[look..<(look + sz)])
                    }
                    look += sz
                }
                if netscape.count >= 14,
                   Array(netscape[0..<11]) == Array("NETSCAPE2.0".utf8),
                   netscape[11] == 1 {
                    let raw = Int(netscape[12]) | (Int(netscape[13]) << 8)
                    // MEASURED 2026-09-05: NETSCAPE loop field 3 → LoopCount 4.
                    loop = raw == 0 ? 0 : raw + 1
                }
            }
            while offset < bytes.count {
                let sz = Int(bytes[offset])
                offset += 1
                if sz == 0 { break }
                offset += sz
            }
            continue
        }
        offset += 1
    }
    parsed.frameCount = frames
    parsed.frameDelays = delays
    if let loop {
        parsed.gif[kCGImagePropertyGIFLoopCount] = loop
    }
}

private func imageioParseBMP(_ data: Data, into parsed: inout ImageIOParsedFile) {
    let bytes = Array(data)
    guard bytes.count >= 26 else { return }
    parsed.frameCount = 1
    parsed.width = Int(Int32(bitPattern: imageioU32LE(bytes, 18)))
    let height32 = Int32(bitPattern: imageioU32LE(bytes, 22))
    parsed.height = abs(Int(height32))
    if bytes.count >= 28 {
        parsed.depth = Int(Int(bytes[28]) | (Int(bytes[29]) << 8))
    }
}

func imageioU16BE(_ bytes: [UInt8], _ offset: Int) -> UInt16 {
    (UInt16(bytes[offset]) << 8) | UInt16(bytes[offset + 1])
}

func imageioU32BE(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    (UInt32(bytes[offset]) << 24)
        | (UInt32(bytes[offset + 1]) << 16)
        | (UInt32(bytes[offset + 2]) << 8)
        | UInt32(bytes[offset + 3])
}

func imageioU32LE(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    UInt32(bytes[offset])
        | (UInt32(bytes[offset + 1]) << 8)
        | (UInt32(bytes[offset + 2]) << 16)
        | (UInt32(bytes[offset + 3]) << 24)
}
