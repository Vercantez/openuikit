import Foundation
import OpenCoreGraphics
#if canImport(CoreGraphics)
import CoreGraphics
#endif

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
    var png: [String: Any] = [:]
    var jfif: [String: Any] = [:]
    var tiff: [String: Any] = [:]
    var exif: [String: Any] = [:]
    var gps: [String: Any] = [:]
    var gif: [String: Any] = [:]
    var iptc: [String: Any] = [:]
    var frameCount = 0
}

func imageioParseFile(_ data: Data) -> ImageIOParsedFile {
    var parsed = ImageIOParsedFile()
    parsed.type = imageioDetectType(data)
    guard let type = parsed.type else { return parsed }
    let bytes = Array(data)
    if typeEquals(type, kUTTypePNG) {
        imageioParsePNG(bytes, into: &parsed)
    } else if typeEquals(type, kUTTypeJPEG) {
        imageioParseJPEG(bytes, into: &parsed)
    } else if typeEquals(type, kUTTypeGIF) {
        imageioParseGIF(bytes, into: &parsed)
    }
    return parsed
}

func imageioMakeProperties(
    _ parsed: ImageIOParsedFile,
    image: CGImage?,
    index: Int,
    fileSize: Int,
    container: Bool
) -> CFDictionary {
    if container {
        var properties: [CFString: Any] = [kCGImagePropertyFileSize: fileSize]
        if !parsed.gif.isEmpty {
            properties[kCGImagePropertyGIFDictionary] = parsed.gif as CFDictionary
        }
        return properties as CFDictionary
    }
    var properties: [CFString: Any] = [:]
    let width = image?.width ?? parsed.width
    let height = image?.height ?? parsed.height
    if let width { properties[kCGImagePropertyPixelWidth] = width }
    if let height { properties[kCGImagePropertyPixelHeight] = height }
    properties[kCGImagePropertyOrientation] = parsed.orientation
    properties[kCGImagePropertyDepth] = parsed.depth
    properties[kCGImagePropertyColorModel] = parsed.colorModel
    if let hasAlpha = parsed.hasAlpha {
        properties[kCGImagePropertyHasAlpha] = hasAlpha
    }
    if let dpi = parsed.dpiWidth { properties[kCGImagePropertyDPIWidth] = dpi }
    if let dpi = parsed.dpiHeight { properties[kCGImagePropertyDPIHeight] = dpi }
    if parsed.type != nil, typeEquals(parsed.type!, kUTTypePNG) || typeEquals(parsed.type!, kUTTypeJPEG) {
        properties[kCGImagePropertyProfileName] = "sRGB IEC61966-2.1"
    }
    if !parsed.png.isEmpty { properties[kCGImagePropertyPNGDictionary] = parsed.png as CFDictionary }
    if !parsed.jfif.isEmpty { properties[kCGImagePropertyJFIFDictionary] = parsed.jfif as CFDictionary }
    if !parsed.tiff.isEmpty { properties[kCGImagePropertyTIFFDictionary] = parsed.tiff as CFDictionary }
    if !parsed.exif.isEmpty { properties[kCGImagePropertyExifDictionary] = parsed.exif as CFDictionary }
    if !parsed.gps.isEmpty { properties[kCGImagePropertyGPSDictionary] = parsed.gps as CFDictionary }
    if !parsed.gif.isEmpty { properties[kCGImagePropertyGIFDictionary] = parsed.gif as CFDictionary }
    if !parsed.iptc.isEmpty { properties[kCGImagePropertyIPTCDictionary] = parsed.iptc as CFDictionary }
    _ = index
    return properties as CFDictionary
}

private func u32BE(_ b: [UInt8], _ i: Int) -> UInt32 {
    (UInt32(b[i]) << 24) | (UInt32(b[i + 1]) << 16) | (UInt32(b[i + 2]) << 8) | UInt32(b[i + 3])
}

private func u16BE(_ b: [UInt8], _ i: Int) -> UInt16 {
    (UInt16(b[i]) << 8) | UInt16(b[i + 1])
}

private func imageioParsePNG(_ bytes: [UInt8], into parsed: inout ImageIOParsedFile) {
    guard bytes.count >= 10 else { return }
    parsed.frameCount = 1
    var offset = 8
    while offset + 12 <= bytes.count {
        let length = Int(u32BE(bytes, offset))
        guard length >= 0, offset + 12 + length <= bytes.count else { break }
        let t0 = bytes[offset + 4], t1 = bytes[offset + 5], t2 = bytes[offset + 6], t3 = bytes[offset + 7]
        let payload = Array(bytes[(offset + 8)..<(offset + 8 + length)])
        if t0 == 73, t1 == 72, t2 == 68, t3 == 82, payload.count >= 13 {
            parsed.width = Int(u32BE(payload, 0))
            parsed.height = Int(u32BE(payload, 4))
            parsed.depth = Int(payload[8])
            parsed.png["InterlaceType"] = Int(payload[12])
            if payload[9] == 4 || payload[9] == 6 { parsed.hasAlpha = true }
            if payload[9] == 0 || payload[9] == 4 {
                parsed.colorModel = kCGImagePropertyColorModelGray
            }
        } else if t0 == 112, t1 == 72, t2 == 89, t3 == 115, payload.count >= 9 {
            let xPPM = Int(u32BE(payload, 0))
            let yPPM = Int(u32BE(payload, 4))
            parsed.png["XPixelsPerMeter"] = xPPM
            parsed.png["YPixelsPerMeter"] = yPPM
            if payload[8] == 1 {
                // MEASURED 2026-09-05: pHYs 5669 ppm → DPI 144.
                parsed.dpiWidth = (Double(xPPM) * 0.0254).rounded()
                parsed.dpiHeight = (Double(yPPM) * 0.0254).rounded()
            }
        } else if t0 == 103, t1 == 65, t2 == 77, t3 == 65, payload.count >= 4 {
            parsed.png["Gamma"] = Double(u32BE(payload, 0)) / 100_000.0
        } else if t0 == 116, t1 == 69, t2 == 88, t3 == 116, let z = payload.firstIndex(of: 0) {
            let keyword = String(bytes: payload[0..<z], encoding: .isoLatin1) ?? ""
            let value = String(bytes: payload[(z + 1)...], encoding: .isoLatin1) ?? ""
            if keyword == "Title" {
                parsed.png["Title"] = value
                parsed.iptc["ObjectName"] = value
            } else if keyword == "Author" {
                parsed.png["Author"] = value
            } else if keyword == "Description" {
                parsed.png["Description"] = value
            } else if keyword == "Copyright" {
                parsed.png["Copyright"] = value
            } else if keyword == "Software" {
                parsed.png["Software"] = value
            } else if keyword == "Comment" {
                parsed.png["Comment"] = value
            }
        }
        offset += 12 + length
        if t0 == 73, t1 == 69, t2 == 78, t3 == 68 { break }
    }
}

private func imageioParseJPEG(_ bytes: [UInt8], into parsed: inout ImageIOParsedFile) {
    guard bytes.count >= 2, bytes[0] == 0xff, bytes[1] == 0xd8 else { return }
    parsed.frameCount = 1
    var offset = 2
    while offset + 3 < bytes.count {
        guard bytes[offset] == 0xff else { offset += 1; continue }
        let marker = bytes[offset + 1]
        if marker == 0xd9 || marker == 0xda { break }
        let length = Int(u16BE(bytes, offset + 2))
        guard length >= 2, offset + 2 + length <= bytes.count else { break }
        let payload = Array(bytes[(offset + 4)..<(offset + 2 + length)])
        let sof = (0xc0...0xc3).contains(marker) || (0xc5...0xc7).contains(marker)
            || (0xc9...0xcb).contains(marker) || (0xcd...0xcf).contains(marker)
        if sof, payload.count >= 6 {
            parsed.depth = Int(payload[0])
            parsed.height = Int(u16BE(payload, 1))
            parsed.width = Int(u16BE(payload, 3))
            parsed.isProgressiveJPEG = marker == 0xc2
            parsed.jfif["IsProgressive"] = parsed.isProgressiveJPEG
        } else if marker == 0xe0, payload.count >= 14,
                  payload[0] == 74, payload[1] == 70, payload[2] == 73, payload[3] == 70, payload[4] == 0 {
            parsed.jfif["JFIFVersion"] = [Int(payload[5]), Int(payload[6])]
            parsed.jfif["DensityUnit"] = Int(payload[7])
            parsed.jfif["XDensity"] = Int(u16BE(payload, 8))
            parsed.jfif["YDensity"] = Int(u16BE(payload, 10))
            if payload[7] == 1 {
                parsed.dpiWidth = Double(u16BE(payload, 8))
                parsed.dpiHeight = Double(u16BE(payload, 10))
            }
        } else if marker == 0xe1 {
            imageioParseExif(payload, into: &parsed)
        }
        offset += 2 + length
    }
    if let width = parsed.width {
        parsed.exif["PixelXDimension"] = width
    }
    if let height = parsed.height {
        parsed.exif["PixelYDimension"] = height
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
    func u16(_ i: Int) -> Int? {
        guard i + 1 < payload.count else { return nil }
        return little
            ? Int(payload[i]) | (Int(payload[i + 1]) << 8)
            : (Int(payload[i]) << 8) | Int(payload[i + 1])
    }
    func u32(_ i: Int) -> Int? {
        guard i + 3 < payload.count else { return nil }
        if little {
            return Int(payload[i]) | (Int(payload[i + 1]) << 8)
                | (Int(payload[i + 2]) << 16) | (Int(payload[i + 3]) << 24)
        }
        return (Int(payload[i]) << 24) | (Int(payload[i + 1]) << 16)
            | (Int(payload[i + 2]) << 8) | Int(payload[i + 3])
    }
    guard u16(tiff + 2) == 42, let rel = u32(tiff + 4) else { return }
    let ifd = tiff + rel
    guard let count = u16(ifd) else { return }
    for entry in 0..<count {
        let item = ifd + 2 + entry * 12
        guard let tag = u16(item), let typ = u16(item + 2), u32(item + 4) != nil else { break }
        if tag == 0x0112, typ == 3, let value = u16(item + 8),
           (1...8).contains(value) {
            parsed.orientation = UInt32(value)
            parsed.tiff["Orientation"] = value
        } else if tag == 0x8769, let exifOff = u32(item + 8) {
            imageioParseExifIFD(
                payload, tiff: tiff, ifd: tiff + exifOff, u16: u16, u32: u32, into: &parsed
            )
        } else if tag == 0x8825, let gpsOff = u32(item + 8) {
            imageioParseGPSIFD(
                payload, tiff: tiff, ifd: tiff + gpsOff, u16: u16, u32: u32, into: &parsed
            )
        }
    }
}

private func imageioParseExifIFD(
    _ payload: [UInt8],
    tiff: Int,
    ifd: Int,
    u16: (Int) -> Int?,
    u32: (Int) -> Int?,
    into parsed: inout ImageIOParsedFile
) {
    guard let count = u16(ifd) else { return }
    for entry in 0..<count {
        let item = ifd + 2 + entry * 12
        guard let tag = u16(item), let typ = u16(item + 2), let num = u32(item + 4) else { break }
        if tag == 0x9003, let s = imageioTIFFString(payload, tiff: tiff, item: item, typ: typ, num: num, u32: u32) {
            parsed.exif["DateTimeOriginal"] = s
        } else if tag == 0x9286, let s = imageioTIFFString(payload, tiff: tiff, item: item, typ: typ, num: num, u32: u32) {
            parsed.exif["UserComment"] = s
        } else if tag == 0xA001, let value = u16(item + 8) {
            parsed.exif["ColorSpace"] = value
        }
    }
}

private func imageioParseGPSIFD(
    _ payload: [UInt8],
    tiff: Int,
    ifd: Int,
    u16: (Int) -> Int?,
    u32: (Int) -> Int?,
    into parsed: inout ImageIOParsedFile
) {
    guard let count = u16(ifd) else { return }
    for entry in 0..<count {
        let item = ifd + 2 + entry * 12
        guard let tag = u16(item), let typ = u16(item + 2), let num = u32(item + 4) else { break }
        if tag == 1, let s = imageioTIFFString(payload, tiff: tiff, item: item, typ: typ, num: num, u32: u32) {
            parsed.gps["LatitudeRef"] = s
        } else if tag == 3, let s = imageioTIFFString(payload, tiff: tiff, item: item, typ: typ, num: num, u32: u32) {
            parsed.gps["LongitudeRef"] = s
        } else if tag == 5, let value = u16(item + 8) {
            parsed.gps["AltitudeRef"] = value
        }
    }
}

private func imageioTIFFString(
    _ payload: [UInt8],
    tiff: Int,
    item: Int,
    typ: Int,
    num: Int,
    u32: (Int) -> Int?
) -> String? {
    guard typ == 2, num > 0 else { return nil }
    let inline = num <= 4
    let start: Int
    if inline {
        start = item + 8
    } else {
        guard let offset = u32(item + 8) else { return nil }
        start = tiff + offset
    }
    let end = start + num
    guard start >= 0, end <= payload.count else { return nil }
    var bytes = Array(payload[start..<end])
    if bytes.last == 0 { bytes.removeLast() }
    return String(bytes: bytes, encoding: .ascii)
}

private func imageioParseGIF(_ bytes: [UInt8], into parsed: inout ImageIOParsedFile) {
    guard bytes.count >= 13 else { return }
    parsed.width = Int(bytes[6]) | (Int(bytes[7]) << 8)
    parsed.height = Int(bytes[8]) | (Int(bytes[9]) << 8)
    parsed.gif["CanvasPixelWidth"] = parsed.width
    parsed.gif["CanvasPixelHeight"] = parsed.height
    parsed.gif["HasGlobalColorMap"] = (bytes[10] & 0x80) != 0 ? 1 : 0
    var offset = 13
    if bytes[10] & 0x80 != 0 {
        offset += 3 * (1 << ((bytes[10] & 7) + 1))
    }
    var frames = 0
    while offset < bytes.count {
        let b = bytes[offset]
        if b == 0x3b { break }
        if b == 0x2c {
            frames += 1
            guard offset + 10 <= bytes.count else { break }
            let local = bytes[offset + 9]
            offset += 10
            if local & 0x80 != 0 { offset += 3 * (1 << ((local & 7) + 1)) }
            offset += 1
            while offset < bytes.count {
                let sz = Int(bytes[offset]); offset += 1
                if sz == 0 { break }
                offset += sz
            }
            continue
        }
        if b == 0x21 {
            guard offset + 2 <= bytes.count else { break }
            let label = bytes[offset + 1]
            offset += 2
            if label == 0xff {
                var netscape: [UInt8] = []
                var look = offset
                while look < bytes.count {
                    let sz = Int(bytes[look]); look += 1
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
                    parsed.gif["LoopCount"] = raw == 0 ? 0 : raw + 1
                }
            }
            while offset < bytes.count {
                let sz = Int(bytes[offset]); offset += 1
                if sz == 0 { break }
                offset += sz
            }
            continue
        }
        offset += 1
    }
    parsed.frameCount = frames
}

func imageioThumbnail(
    _ image: CGImage,
    options: CFDictionary?,
    orientation: UInt32
) -> CGImage? {
    let always = imageioOptionBool(options, kCGImageSourceCreateThumbnailFromImageAlways)
    let ifAbsent = imageioOptionBool(options, kCGImageSourceCreateThumbnailFromImageIfAbsent)
    let withTransform = imageioOptionBool(options, kCGImageSourceCreateThumbnailWithTransform)
    let maxPixel = imageioOptionInt(options, kCGImageSourceThumbnailMaxPixelSize)
    if !always && !ifAbsent && maxPixel == nil { return image }
    guard let rgba = imageioReadRGBA(image) else { return image }
    var bitmap = Bitmap(width: rgba.width, height: rgba.height)
    bitmap.pixels = rgba.rgba
    if withTransform, orientation != 1 {
        bitmap = imageioOrientBitmap(bitmap, orientation)
    }
    guard let maxPixel, maxPixel > 0 else {
        return imageioMakeCGImage(width: bitmap.width, height: bitmap.height, rgba: bitmap.pixels)
    }
    let longSide = max(bitmap.width, bitmap.height)
    if longSide <= maxPixel {
        return imageioMakeCGImage(width: bitmap.width, height: bitmap.height, rgba: bitmap.pixels)
    }
    let w = imageioScaleDim(bitmap.width, maxPixel: maxPixel, longSide: longSide)
    let h = imageioScaleDim(bitmap.height, maxPixel: maxPixel, longSide: longSide)
    let scaled = imageioResampleBitmap(bitmap, width: w, height: h)
    return imageioMakeCGImage(width: scaled.width, height: scaled.height, rgba: scaled.pixels)
}

private func imageioScaleDim(_ dim: Int, maxPixel: Int, longSide: Int) -> Int {
    let scaled = (Double(dim) * Double(maxPixel) / Double(longSide)).rounded(.toNearestOrEven)
    return max(1, Int(scaled))
}

private func imageioResampleBitmap(_ src: Bitmap, width: Int, height: Int) -> Bitmap {
    let out = Bitmap(width: width, height: height)
    for y in 0..<height {
        let sy = min(src.height - 1, y * src.height / height)
        for x in 0..<width {
            let sx = min(src.width - 1, x * src.width / width)
            let di = (y * width + x) * 4
            let si = (sy * src.width + sx) * 4
            out.pixels[di] = src.pixels[si]
            out.pixels[di + 1] = src.pixels[si + 1]
            out.pixels[di + 2] = src.pixels[si + 2]
            out.pixels[di + 3] = src.pixels[si + 3]
        }
    }
    return out
}

private func imageioOrientBitmap(_ src: Bitmap, _ orientation: UInt32) -> Bitmap {
    let swap = orientation >= 5
    let outW = swap ? src.height : src.width
    let outH = swap ? src.width : src.height
    let out = Bitmap(width: outW, height: outH)
    for y in 0..<src.height {
        for x in 0..<src.width {
            let (nx, ny): (Int, Int)
            switch orientation {
            case 2: nx = src.width - 1 - x; ny = y
            case 3: nx = src.width - 1 - x; ny = src.height - 1 - y
            case 4: nx = x; ny = src.height - 1 - y
            case 5: nx = y; ny = x
            case 6: nx = src.height - 1 - y; ny = x
            case 7: nx = src.height - 1 - y; ny = src.width - 1 - x
            case 8: nx = y; ny = src.width - 1 - x
            default: nx = x; ny = y
            }
            let si = (y * src.width + x) * 4
            let di = (ny * outW + nx) * 4
            out.pixels[di] = src.pixels[si]
            out.pixels[di + 1] = src.pixels[si + 1]
            out.pixels[di + 2] = src.pixels[si + 2]
            out.pixels[di + 3] = src.pixels[si + 3]
        }
    }
    return out
}
