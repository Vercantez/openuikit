import Foundation

// Portable BMP (BI_RGB) and stored-block PNG codecs used when CQuartz is
// unavailable. They never invent pixels for formats they cannot decode.

let imageioTypePNG: CFString = "public.png"
let imageioTypeJPEG: CFString = "public.jpeg"
let imageioTypeGIF: CFString = "com.compuserve.gif"
let imageioTypeBMP: CFString = "com.microsoft.bmp"

func imageioSupportedSourceTypes() -> [CFString] {
    [imageioTypePNG, imageioTypeJPEG, imageioTypeGIF, imageioTypeBMP]
}

func imageioSupportedDestinationTypes() -> [CFString] {
    [imageioTypePNG, imageioTypeBMP]
}

func imageioDetectType(_ data: Data) -> CFString? {
    let bytes = Array(data.prefix(14))
    if bytes.count >= 8,
       bytes[0...7].elementsEqual([137, 80, 78, 71, 13, 10, 26, 10]) {
        return imageioTypePNG
    }
    if bytes.count >= 2, bytes[0] == 0xff, bytes[1] == 0xd8 {
        return imageioTypeJPEG
    }
    if bytes.count >= 6,
       bytes[0] == 0x47, bytes[1] == 0x49, bytes[2] == 0x46,
       bytes[3] == 0x38, (bytes[4] == 0x37 || bytes[4] == 0x39),
       bytes[5] == 0x61 {
        return imageioTypeGIF
    }
    if bytes.count >= 2, bytes[0] == 0x42, bytes[1] == 0x4d {
        return imageioTypeBMP
    }
    return nil
}

func imageioDecodePortable(_ data: Data, type: CFString) -> DecodedImageSet? {
    if type == imageioTypeBMP {
        return imageioDecodeBMP(data)
    }
    if type == imageioTypePNG {
        return imageioDecodePNG(data)
    }
    return nil
}

func imageioEncode(_ image: CGImage, type: CFString) -> Data? {
    if type == imageioTypeBMP {
        return imageioEncodeBMP(image)
    }
    if type == imageioTypePNG {
        return imageioEncodePNG(image)
    }
    return nil
}

// MARK: - BMP (BITMAPINFOHEADER, BI_RGB, 32-bit BGRA, top-down)

private func imageioDecodeBMP(_ data: Data) -> DecodedImageSet? {
    let bytes = Array(data)
    guard bytes.count >= 54, bytes[0] == 0x42, bytes[1] == 0x4d else { return nil }
    let offset = imageioUInt32LE(bytes, 10)
    let headerSize = imageioUInt32LE(bytes, 14)
    guard headerSize >= 40 else { return nil }
    let width32 = Int32(bitPattern: imageioUInt32LE(bytes, 18))
    let height32 = Int32(bitPattern: imageioUInt32LE(bytes, 22))
    let planes = imageioUInt16LE(bytes, 26)
    let bits = imageioUInt16LE(bytes, 28)
    let compression = imageioUInt32LE(bytes, 30)
    guard planes == 1, compression == 0, bits == 32 || bits == 24 else { return nil }
    let width = Int(width32)
    let height = abs(Int(height32))
    let topDown = height32 < 0
    guard width > 0, height > 0 else { return nil }
    let rowStride: Int
    if bits == 32 {
        rowStride = width * 4
    } else {
        let raw = width * 3
        rowStride = (raw + 3) & ~3
    }
    let pixelBytes = rowStride * height
    guard offset <= bytes.count, bytes.count - Int(offset) >= pixelBytes else { return nil }
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    for y in 0..<height {
        let srcRow = topDown ? y : (height - 1 - y)
        let src = Int(offset) + srcRow * rowStride
        for x in 0..<width {
            let dst = (y * width + x) * 4
            if bits == 32 {
                pixels[dst] = bytes[src + x * 4 + 2]
                pixels[dst + 1] = bytes[src + x * 4 + 1]
                pixels[dst + 2] = bytes[src + x * 4]
                pixels[dst + 3] = bytes[src + x * 4 + 3]
            } else {
                pixels[dst] = bytes[src + x * 3 + 2]
                pixels[dst + 1] = bytes[src + x * 3 + 1]
                pixels[dst + 2] = bytes[src + x * 3]
                pixels[dst + 3] = 255
            }
        }
    }
    guard let image = imageioMakeImage(width: width, height: height, pixels: pixels) else {
        return nil
    }
    return DecodedImageSet(images: [image], frameDelays: [0])
}

private func imageioEncodeBMP(_ image: CGImage) -> Data? {
    let width = image.width
    let height = image.height
    guard width > 0, height > 0, image.pixels.count >= width * height * 4 else { return nil }
    let pixelBytes = width * height * 4
    let offset = 54
    var bytes = [UInt8](repeating: 0, count: offset + pixelBytes)
    bytes[0] = 0x42
    bytes[1] = 0x4d
    imageioPutUInt32LE(&bytes, 2, UInt32(bytes.count))
    imageioPutUInt32LE(&bytes, 10, UInt32(offset))
    imageioPutUInt32LE(&bytes, 14, 40)
    imageioPutUInt32LE(&bytes, 18, UInt32(bitPattern: Int32(width)))
    imageioPutUInt32LE(&bytes, 22, UInt32(bitPattern: Int32(-height)))
    imageioPutUInt16LE(&bytes, 26, 1)
    imageioPutUInt16LE(&bytes, 28, 32)
    imageioPutUInt32LE(&bytes, 34, UInt32(pixelBytes))
    for y in 0..<height {
        for x in 0..<width {
            let src = (y * width + x) * 4
            let dst = offset + (y * width + x) * 4
            bytes[dst] = image.pixels[src + 2]
            bytes[dst + 1] = image.pixels[src + 1]
            bytes[dst + 2] = image.pixels[src]
            bytes[dst + 3] = image.pixels[src + 3]
        }
    }
    return Data(bytes)
}

// MARK: - PNG (8-bit RGBA, filter 0, zlib stored blocks)

private func imageioEncodePNG(_ image: CGImage) -> Data? {
    let width = image.width
    let height = image.height
    guard width > 0, height > 0, image.pixels.count >= width * height * 4 else { return nil }
    var raw = [UInt8](repeating: 0, count: height * (1 + width * 4))
    for y in 0..<height {
        let row = y * (1 + width * 4)
        raw[row] = 0
        let src = y * width * 4
        for i in 0..<(width * 4) {
            raw[row + 1 + i] = image.pixels[src + i]
        }
    }
    guard let deflated = imageioZlibStore(raw) else { return nil }
    var png: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    var ihdr = [UInt8](repeating: 0, count: 13)
    imageioPutUInt32BE(&ihdr, 0, UInt32(width))
    imageioPutUInt32BE(&ihdr, 4, UInt32(height))
    ihdr[8] = 8
    ihdr[9] = 6
    imageioAppendPNGChunk(&png, type: [73, 72, 68, 82], payload: ihdr)
    imageioAppendPNGChunk(&png, type: [73, 68, 65, 84], payload: Array(deflated))
    imageioAppendPNGChunk(&png, type: [73, 69, 78, 68], payload: [])
    return Data(png)
}

private func imageioDecodePNG(_ data: Data) -> DecodedImageSet? {
    let bytes = Array(data)
    guard bytes.count >= 8,
          bytes[0...7].elementsEqual([137, 80, 78, 71, 13, 10, 26, 10]) else { return nil }
    var offset = 8
    var width = 0
    var height = 0
    var bitDepth: UInt8 = 0
    var colorType: UInt8 = 0
    var idat = [UInt8]()
    while offset + 12 <= bytes.count {
        let length = Int(imageioUInt32BE(bytes, offset))
        guard length >= 0, offset + 12 + length <= bytes.count else { return nil }
        let type = Array(bytes[(offset + 4)..<(offset + 8)])
        let payload = Array(bytes[(offset + 8)..<(offset + 8 + length)])
        if type == [73, 72, 68, 82] {
            guard payload.count >= 13 else { return nil }
            width = Int(imageioUInt32BE(payload, 0))
            height = Int(imageioUInt32BE(payload, 4))
            bitDepth = payload[8]
            colorType = payload[9]
            let compression = payload[10]
            let filter = payload[11]
            let interlace = payload[12]
            guard bitDepth == 8, compression == 0, filter == 0, interlace == 0,
                  colorType == 2 || colorType == 6 else { return nil }
        } else if type == [73, 68, 65, 84] {
            idat.append(contentsOf: payload)
        } else if type == [73, 69, 78, 68] {
            break
        }
        offset += 12 + length
    }
    guard width > 0, height > 0, let inflated = imageioZlibInflateStored(idat) else { return nil }
    let components = colorType == 6 ? 4 : 3
    let stride = 1 + width * components
    guard inflated.count >= stride * height else { return nil }
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    for y in 0..<height {
        let row = y * stride
        guard inflated[row] == 0 else { return nil }
        for x in 0..<width {
            let src = row + 1 + x * components
            let dst = (y * width + x) * 4
            pixels[dst] = inflated[src]
            pixels[dst + 1] = inflated[src + 1]
            pixels[dst + 2] = inflated[src + 2]
            pixels[dst + 3] = components == 4 ? inflated[src + 3] : 255
        }
    }
    guard let image = imageioMakeImage(width: width, height: height, pixels: pixels) else {
        return nil
    }
    return DecodedImageSet(images: [image], frameDelays: [0])
}

private func imageioZlibStore(_ raw: [UInt8]) -> Data? {
    // CMF/FLG = 0x78 0x01 is a valid zlib header (CM=8, CINFO=7, FCHECK).
    var out: [UInt8] = [0x78, 0x01]
    var index = 0
    while index < raw.count {
        let remaining = raw.count - index
        let block = min(remaining, 65535)
        let final: UInt8 = index + block == raw.count ? 0x01 : 0x00
        out.append(final)
        let len = UInt16(block)
        out.append(UInt8(len & 0xff))
        out.append(UInt8(len >> 8))
        out.append(UInt8((~len) & 0xff))
        out.append(UInt8((~len) >> 8))
        out.append(contentsOf: raw[index..<(index + block)])
        index += block
    }
    let adler = imageioAdler32(raw)
    out.append(UInt8((adler >> 24) & 0xff))
    out.append(UInt8((adler >> 16) & 0xff))
    out.append(UInt8((adler >> 8) & 0xff))
    out.append(UInt8(adler & 0xff))
    return Data(out)
}

private func imageioZlibInflateStored(_ data: [UInt8]) -> [UInt8]? {
    guard data.count >= 6 else { return nil }
    let cmf = data[0]
    let flg = data[1]
    guard cmf & 0x0f == 8, ((Int(cmf) << 8) + Int(flg)) % 31 == 0, flg & 0x20 == 0 else {
        return nil
    }
    var index = 2
    var raw = [UInt8]()
    while true {
        guard index < data.count else { return nil }
        let header = data[index]
        index += 1
        let bfinal = header & 1
        let btype = (header >> 1) & 3
        guard btype == 0 else { return nil }
        guard index + 4 <= data.count else { return nil }
        let len = Int(data[index]) | (Int(data[index + 1]) << 8)
        let nlen = Int(data[index + 2]) | (Int(data[index + 3]) << 8)
        index += 4
        guard (len ^ 0xffff) == nlen else { return nil }
        guard index + len + 4 <= data.count else { return nil }
        raw.append(contentsOf: data[index..<(index + len)])
        index += len
        if bfinal == 1 {
            guard index + 4 <= data.count else { return nil }
            let adler = (UInt32(data[index]) << 24)
                | (UInt32(data[index + 1]) << 16)
                | (UInt32(data[index + 2]) << 8)
                | UInt32(data[index + 3])
            guard adler == imageioAdler32(raw) else { return nil }
            return raw
        }
    }
}

private func imageioAdler32(_ bytes: [UInt8]) -> UInt32 {
    var s1: UInt32 = 1
    var s2: UInt32 = 0
    for byte in bytes {
        s1 = (s1 + UInt32(byte)) % 65521
        s2 = (s2 + s1) % 65521
    }
    return (s2 << 16) | s1
}

private func imageioAppendPNGChunk(_ png: inout [UInt8], type: [UInt8], payload: [UInt8]) {
    imageioPutUInt32BEAppend(&png, UInt32(payload.count))
    let start = png.count
    png.append(contentsOf: type)
    png.append(contentsOf: payload)
    let crc = imageioCRC32(png[start..<png.count])
    imageioPutUInt32BEAppend(&png, crc)
}

private func imageioCRC32(_ bytes: ArraySlice<UInt8>) -> UInt32 {
    var crc: UInt32 = 0xffff_ffff
    for byte in bytes {
        let index = Int((crc ^ UInt32(byte)) & 0xff)
        crc = imageioCRCTable[index] ^ (crc >> 8)
    }
    return crc ^ 0xffff_ffff
}

private let imageioCRCTable: [UInt32] = {
    (0..<256).map { index -> UInt32 in
        var crc = UInt32(index)
        for _ in 0..<8 {
            if crc & 1 != 0 {
                crc = 0xedb8_8320 ^ (crc >> 1)
            } else {
                crc >>= 1
            }
        }
        return crc
    }
}()

private func imageioUInt16LE(_ bytes: [UInt8], _ offset: Int) -> UInt16 {
    UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
}

private func imageioUInt32LE(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    UInt32(bytes[offset])
        | (UInt32(bytes[offset + 1]) << 8)
        | (UInt32(bytes[offset + 2]) << 16)
        | (UInt32(bytes[offset + 3]) << 24)
}

private func imageioUInt32BE(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    (UInt32(bytes[offset]) << 24)
        | (UInt32(bytes[offset + 1]) << 16)
        | (UInt32(bytes[offset + 2]) << 8)
        | UInt32(bytes[offset + 3])
}

private func imageioPutUInt16LE(_ bytes: inout [UInt8], _ offset: Int, _ value: UInt16) {
    bytes[offset] = UInt8(value & 0xff)
    bytes[offset + 1] = UInt8(value >> 8)
}

private func imageioPutUInt32LE(_ bytes: inout [UInt8], _ offset: Int, _ value: UInt32) {
    bytes[offset] = UInt8(value & 0xff)
    bytes[offset + 1] = UInt8((value >> 8) & 0xff)
    bytes[offset + 2] = UInt8((value >> 16) & 0xff)
    bytes[offset + 3] = UInt8((value >> 24) & 0xff)
}

private func imageioPutUInt32BE(_ bytes: inout [UInt8], _ offset: Int, _ value: UInt32) {
    bytes[offset] = UInt8((value >> 24) & 0xff)
    bytes[offset + 1] = UInt8((value >> 16) & 0xff)
    bytes[offset + 2] = UInt8((value >> 8) & 0xff)
    bytes[offset + 3] = UInt8(value & 0xff)
}

private func imageioPutUInt32BEAppend(_ bytes: inout [UInt8], _ value: UInt32) {
    bytes.append(UInt8((value >> 24) & 0xff))
    bytes.append(UInt8((value >> 16) & 0xff))
    bytes.append(UInt8((value >> 8) & 0xff))
    bytes.append(UInt8(value & 0xff))
}
