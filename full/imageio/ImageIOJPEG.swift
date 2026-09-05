import Foundation

// Portable baseline JPEG (SOF0, 8-bit, 4:4:4). Isolated-host encode/decode
// so a destination written as public.jpeg can be re-read by CGImageSource.
// Huffman/quant tables are ITU-T T.81 Annex K. Not Apple's encoder.

private let imageioJPEGZigzag: [Int] = [
    0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5,
    12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63,
]

private let imageioJPEGLumQuant: [Int] = [
    16, 11, 10, 16, 24, 40, 51, 61,
    12, 12, 14, 19, 26, 58, 60, 55,
    14, 13, 16, 24, 40, 57, 69, 56,
    14, 17, 22, 29, 51, 87, 80, 62,
    18, 22, 37, 56, 68, 109, 103, 77,
    24, 35, 55, 64, 81, 104, 113, 92,
    49, 64, 78, 87, 103, 121, 120, 101,
    72, 92, 95, 98, 112, 100, 103, 99,
]

private let imageioJPEGChrQuant: [Int] = [
    17, 18, 24, 47, 99, 99, 99, 99,
    18, 21, 26, 66, 99, 99, 99, 99,
    24, 26, 56, 99, 99, 99, 99, 99,
    47, 66, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
]

private let imageioJPEGDCLumBits: [UInt8] = [
    0, 1, 5, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0,
]
private let imageioJPEGDCLumVal: [UInt8] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
private let imageioJPEGDCChrBits: [UInt8] = [
    0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0,
]
private let imageioJPEGDCChrVal: [UInt8] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
private let imageioJPEGACLumBits: [UInt8] = [
    0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 125,
]
private let imageioJPEGACLumVal: [UInt8] = [
    0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
    0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08, 0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0,
    0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
    0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
    0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
    0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
    0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
    0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5,
    0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
    0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
    0xf9, 0xfa,
]
private let imageioJPEGACChrBits: [UInt8] = [
    0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 119,
]
private let imageioJPEGACChrVal: [UInt8] = [
    0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21, 0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71,
    0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91, 0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0,
    0x15, 0x62, 0x72, 0xd1, 0x0a, 0x16, 0x24, 0x34, 0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26,
    0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
    0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
    0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
    0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5,
    0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3,
    0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda,
    0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
    0xf9, 0xfa,
]

private struct ImageIOJPEGHuff {
    var encode: [Int: (code: UInt32, bits: Int)] = [:]
    var decode: [Int: (symbol: Int, bits: Int)] = [:]
    var minBits = 1
    var maxBits = 16
}

private func imageioJPEGBuildHuff(_ bits: [UInt8], _ values: [UInt8]) -> ImageIOJPEGHuff {
    var table = ImageIOJPEGHuff()
    var code = 0
    var index = 0
    var minBits = 16
    var maxBits = 1
    for length in 1...16 {
        let count = Int(bits[length - 1])
        if count > 0 {
            minBits = min(minBits, length)
            maxBits = max(maxBits, length)
        }
        for _ in 0..<count {
            guard index < values.count else { break }
            let symbol = Int(values[index])
            table.encode[symbol] = (UInt32(code), length)
            let shift = 16 - length
            let base = code << shift
            for extra in 0..<(1 << shift) {
                table.decode[base + extra] = (symbol, length)
            }
            code += 1
            index += 1
        }
        code <<= 1
    }
    table.minBits = minBits == 16 ? 1 : minBits
    table.maxBits = maxBits
    return table
}

private let imageioJPEGHuffDCLum = imageioJPEGBuildHuff(imageioJPEGDCLumBits, imageioJPEGDCLumVal)
private let imageioJPEGHuffDCChr = imageioJPEGBuildHuff(imageioJPEGDCChrBits, imageioJPEGDCChrVal)
private let imageioJPEGHuffACLum = imageioJPEGBuildHuff(imageioJPEGACLumBits, imageioJPEGACLumVal)
private let imageioJPEGHuffACChr = imageioJPEGBuildHuff(imageioJPEGACChrBits, imageioJPEGACChrVal)

private func imageioJPEGScaleQuant(_ table: [Int], quality: Int) -> [Int] {
    let q = min(100, max(1, quality))
    let scale = q < 50 ? 5000 / q : 200 - q * 2
    return table.map { value in
        max(1, min(255, (value * scale + 50) / 100))
    }
}

private func imageioJPEGRGBToYCbCr(_ r: Double, _ g: Double, _ b: Double) -> (Double, Double, Double) {
    let y = 0.299 * r + 0.587 * g + 0.114 * b
    let cb = -0.168736 * r - 0.331264 * g + 0.5 * b + 128
    let cr = 0.5 * r - 0.418688 * g - 0.081312 * b + 128
    return (y, cb, cr)
}

private func imageioJPEGYCbCrToRGB(_ y: Double, _ cb: Double, _ cr: Double) -> (UInt8, UInt8, UInt8) {
    let r = y + 1.402 * (cr - 128)
    let g = y - 0.344136 * (cb - 128) - 0.714136 * (cr - 128)
    let b = y + 1.772 * (cb - 128)
    func clamp(_ v: Double) -> UInt8 {
        UInt8(max(0, min(255, v.rounded())))
    }
    return (clamp(r), clamp(g), clamp(b))
}

private func imageioJPEGFDCT(_ block: [Double]) -> [Double] {
    var out = [Double](repeating: 0, count: 64)
    for v in 0..<8 {
        for u in 0..<8 {
            var sum = 0.0
            for y in 0..<8 {
                for x in 0..<8 {
                    let cu = u == 0 ? 1.0 / sqrt(2.0) : 1.0
                    let cv = v == 0 ? 1.0 / sqrt(2.0) : 1.0
                    let ang = Double.pi / 8.0
                    sum += block[y * 8 + x]
                        * cos((2.0 * Double(x) + 1.0) * Double(u) * ang / 2.0)
                        * cos((2.0 * Double(y) + 1.0) * Double(v) * ang / 2.0)
                        * cu * cv
                }
            }
            out[v * 8 + u] = sum * 0.25
        }
    }
    return out
}

private func imageioJPEGIDCT(_ block: [Double]) -> [Double] {
    var out = [Double](repeating: 0, count: 64)
    for y in 0..<8 {
        for x in 0..<8 {
            var sum = 0.0
            for v in 0..<8 {
                for u in 0..<8 {
                    let cu = u == 0 ? 1.0 / sqrt(2.0) : 1.0
                    let cv = v == 0 ? 1.0 / sqrt(2.0) : 1.0
                    let ang = Double.pi / 8.0
                    sum += cu * cv * block[v * 8 + u]
                        * cos((2.0 * Double(x) + 1.0) * Double(u) * ang / 2.0)
                        * cos((2.0 * Double(y) + 1.0) * Double(v) * ang / 2.0)
                }
            }
            out[y * 8 + x] = sum * 0.25
        }
    }
    return out
}

private final class ImageIOJPEGBitWriter {
    var bytes: [UInt8] = []
    private var accum: UInt32 = 0
    private var bits = 0

    func write(_ code: UInt32, _ length: Int) {
        guard length > 0 else { return }
        accum = (accum << length) | (code & ((UInt32(1) << length) - 1))
        bits += length
        while bits >= 8 {
            bits -= 8
            let byte = UInt8((accum >> bits) & 0xff)
            bytes.append(byte)
            if byte == 0xff {
                bytes.append(0)
            }
        }
    }

    func flush() {
        if bits > 0 {
            write(0x7f, 8 - bits)
        }
    }
}

private func imageioJPEGCategory(_ value: Int) -> (cat: Int, bits: UInt32) {
    if value == 0 { return (0, 0) }
    let absv = abs(value)
    var cat = 0
    var tmp = absv
    while tmp > 0 {
        tmp >>= 1
        cat += 1
    }
    let bits: UInt32
    if value < 0 {
        bits = UInt32((1 << cat) + value - 1)
    } else {
        bits = UInt32(value)
    }
    return (cat, bits)
}

private func imageioJPEGEncodeBlock(
    _ spatial: [Double],
    quant: [Int],
    dcTable: ImageIOJPEGHuff,
    acTable: ImageIOJPEGHuff,
    prevDC: inout Int,
    writer: ImageIOJPEGBitWriter
) {
    let freq = imageioJPEGFDCT(spatial.map { $0 - 128 })
    var zz = [Int](repeating: 0, count: 64)
    for i in 0..<64 {
        let src = imageioJPEGZigzag[i]
        zz[i] = Int((freq[src] / Double(quant[src])).rounded())
    }
    let dcDiff = zz[0] - prevDC
    prevDC = zz[0]
    let dc = imageioJPEGCategory(dcDiff)
    guard let dcCode = dcTable.encode[dc.cat] else { return }
    writer.write(dcCode.code, dcCode.bits)
    if dc.cat > 0 {
        writer.write(dc.bits, dc.cat)
    }
    var run = 0
    for i in 1..<64 {
        if zz[i] == 0 {
            run += 1
            continue
        }
        while run >= 16 {
            guard let zrl = acTable.encode[0xf0] else { return }
            writer.write(zrl.code, zrl.bits)
            run -= 16
        }
        let ac = imageioJPEGCategory(zz[i])
        let symbol = (run << 4) | ac.cat
        guard let acCode = acTable.encode[symbol] else { return }
        writer.write(acCode.code, acCode.bits)
        writer.write(ac.bits, ac.cat)
        run = 0
    }
    if run > 0 {
        guard let eob = acTable.encode[0] else { return }
        writer.write(eob.code, eob.bits)
    }
}

func imageioEncodeJPEG(_ image: CGImage) -> Data? {
    let width = image.width
    let height = image.height
    guard width > 0, height > 0, image.pixels.count >= width * height * 4 else { return nil }
    let lumQ = imageioJPEGScaleQuant(imageioJPEGLumQuant, quality: 90)
    let chrQ = imageioJPEGScaleQuant(imageioJPEGChrQuant, quality: 90)
    let mcuX = (width + 7) / 8
    let mcuY = (height + 7) / 8
    func sample(_ x: Int, _ y: Int, _ plane: Int) -> Double {
        let sx = min(width - 1, max(0, x))
        let sy = min(height - 1, max(0, y))
        let p = image.pixels
        let i = (sy * width + sx) * 4
        let ycbcr = imageioJPEGRGBToYCbCr(Double(p[i]), Double(p[i + 1]), Double(p[i + 2]))
        switch plane {
        case 0: return ycbcr.0
        case 1: return ycbcr.1
        default: return ycbcr.2
        }
    }

    var out: [UInt8] = [0xff, 0xd8]
    // APP0 JFIF 1.01, density unit 1, 72 dpi.
    out += [
        0xff, 0xe0, 0x00, 0x10,
        0x4a, 0x46, 0x49, 0x46, 0x00,
        0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
    ]
    func appendDQT(_ table: [Int], id: UInt8) {
        out += [0xff, 0xdb, 0x00, 0x43, id]
        for i in 0..<64 {
            out.append(UInt8(table[imageioJPEGZigzag[i]]))
        }
    }
    appendDQT(lumQ, id: 0)
    appendDQT(chrQ, id: 1)
    // SOF0, 8-bit, 3 components, 4:4:4 (11).
    out += [
        0xff, 0xc0, 0x00, 0x11, 0x08,
        UInt8((height >> 8) & 0xff), UInt8(height & 0xff),
        UInt8((width >> 8) & 0xff), UInt8(width & 0xff),
        0x03,
        0x01, 0x11, 0x00,
        0x02, 0x11, 0x01,
        0x03, 0x11, 0x01,
    ]
    func appendDHT(_ bits: [UInt8], _ values: [UInt8], cls_id: UInt8) {
        let length = 19 + values.count
        out += [0xff, 0xc4, UInt8((length >> 8) & 0xff), UInt8(length & 0xff), cls_id]
        out += bits
        out += values
    }
    appendDHT(imageioJPEGDCLumBits, imageioJPEGDCLumVal, cls_id: 0x00)
    appendDHT(imageioJPEGACLumBits, imageioJPEGACLumVal, cls_id: 0x10)
    appendDHT(imageioJPEGDCChrBits, imageioJPEGDCChrVal, cls_id: 0x01)
    appendDHT(imageioJPEGACChrBits, imageioJPEGACChrVal, cls_id: 0x11)
    out += [0xff, 0xda, 0x00, 0x0c, 0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00, 0x3f, 0x00]

    let writer = ImageIOJPEGBitWriter()
    var prevDC = [0, 0, 0]
    for my in 0..<mcuY {
        for mx in 0..<mcuX {
            for plane in 0..<3 {
                var block = [Double](repeating: 0, count: 64)
                for y in 0..<8 {
                    for x in 0..<8 {
                        block[y * 8 + x] = sample(mx * 8 + x, my * 8 + y, plane)
                    }
                }
                imageioJPEGEncodeBlock(
                    block,
                    quant: plane == 0 ? lumQ : chrQ,
                    dcTable: plane == 0 ? imageioJPEGHuffDCLum : imageioJPEGHuffDCChr,
                    acTable: plane == 0 ? imageioJPEGHuffACLum : imageioJPEGHuffACChr,
                    prevDC: &prevDC[plane],
                    writer: writer
                )
            }
        }
    }
    writer.flush()
    out += writer.bytes
    out += [0xff, 0xd9]
    return Data(out)
}

private final class ImageIOJPEGBitReader {
    let bytes: [UInt8]
    var index: Int
    var accum: UInt32 = 0
    var bits = 0

    init(bytes: [UInt8], start: Int) {
        self.bytes = bytes
        self.index = start
    }

    private func fill(atLeast length: Int) -> Bool {
        while bits < length {
            if index >= bytes.count {
                accum = (accum << 1) | 1
                bits += 1
                continue
            }
            let byte = bytes[index]
            index += 1
            if byte == 0xff {
                guard index < bytes.count else {
                    accum = (accum << 1) | 1
                    bits += 1
                    continue
                }
                let next = bytes[index]
                if next == 0x00 {
                    index += 1
                } else if next == 0xff {
                    continue
                } else {
                    index -= 1
                    accum = (accum << 1) | 1
                    bits += 1
                    continue
                }
            }
            accum = (accum << 8) | UInt32(byte)
            bits += 8
        }
        return true
    }

    func peek(_ length: Int) -> Int? {
        guard fill(atLeast: length) else { return nil }
        return Int((accum >> (bits - length)) & ((UInt32(1) << length) - 1))
    }

    func consume(_ length: Int) {
        bits -= length
        if bits == 0 {
            accum = 0
        } else {
            accum &= (UInt32(1) << bits) - 1
        }
    }

    func read(_ length: Int) -> Int? {
        guard let value = peek(length) else { return nil }
        consume(length)
        return value
    }
}

private func imageioJPEGDecodeSymbol(_ reader: ImageIOJPEGBitReader, _ table: ImageIOJPEGHuff) -> Int? {
    guard let peek = reader.peek(table.maxBits) else { return nil }
    guard let decoded = table.decode[peek] else { return nil }
    reader.consume(decoded.bits)
    return decoded.symbol
}

private func imageioJPEGExtend(_ bits: Int, _ cat: Int) -> Int {
    if cat == 0 { return 0 }
    let vt = 1 << (cat - 1)
    if bits < vt {
        return bits + ((-1) << cat) + 1
    }
    return bits
}

private func imageioJPEGDecodeBlock(
    _ reader: ImageIOJPEGBitReader,
    quant: [Int],
    dcTable: ImageIOJPEGHuff,
    acTable: ImageIOJPEGHuff,
    prevDC: inout Int
) -> [Double]? {
    guard let dcCat = imageioJPEGDecodeSymbol(reader, dcTable) else { return nil }
    var dcBits = 0
    if dcCat > 0 {
        guard let value = reader.read(dcCat) else { return nil }
        dcBits = value
    }
    prevDC += imageioJPEGExtend(dcBits, dcCat)
    var zz = [Int](repeating: 0, count: 64)
    zz[0] = prevDC
    var k = 1
    while k < 64 {
        guard let symbol = imageioJPEGDecodeSymbol(reader, acTable) else { return nil }
        if symbol == 0 { break }
        if symbol == 0xf0 {
            k += 16
            continue
        }
        let run = symbol >> 4
        let cat = symbol & 0x0f
        k += run
        guard k < 64 else { return nil }
        var acBits = 0
        if cat > 0 {
            guard let value = reader.read(cat) else { return nil }
            acBits = value
        }
        zz[k] = imageioJPEGExtend(acBits, cat)
        k += 1
    }
    var freq = [Double](repeating: 0, count: 64)
    for i in 0..<64 {
        let dst = imageioJPEGZigzag[i]
        freq[dst] = Double(zz[i] * quant[dst])
    }
    return imageioJPEGIDCT(freq).map { $0 + 128 }
}

func imageioDecodeJPEG(_ data: Data) -> DecodedImageSet? {
    let bytes = Array(data)
    guard bytes.count >= 4, bytes[0] == 0xff, bytes[1] == 0xd8 else { return nil }
    var offset = 2
    var width = 0
    var height = 0
    var components = 0
    var sampling = [Int](repeating: 0x11, count: 4)
    var quantId = [Int](repeating: 0, count: 4)
    var quant: [[Int]] = Array(repeating: [Int](repeating: 1, count: 64), count: 4)
    var dcHuff = [imageioJPEGHuffDCLum, imageioJPEGHuffDCChr, imageioJPEGHuffDCLum, imageioJPEGHuffDCChr]
    var acHuff = [imageioJPEGHuffACLum, imageioJPEGHuffACChr, imageioJPEGHuffACLum, imageioJPEGHuffACChr]
    var scanStart = 0
    while offset + 1 < bytes.count {
        guard bytes[offset] == 0xff else { offset += 1; continue }
        var marker = bytes[offset + 1]
        while marker == 0xff, offset + 2 < bytes.count {
            offset += 1
            marker = bytes[offset + 1]
        }
        if marker == 0xd9 { break }
        if marker == 0xda {
            guard offset + 3 < bytes.count else { return nil }
            let length = Int(bytes[offset + 2]) << 8 | Int(bytes[offset + 3])
            scanStart = offset + 2 + length
            break
        }
        if marker == 0xd8 {
            offset += 2
            continue
        }
        guard offset + 3 < bytes.count else { return nil }
        let length = Int(bytes[offset + 2]) << 8 | Int(bytes[offset + 3])
        guard length >= 2, offset + 2 + length <= bytes.count else { return nil }
        let payload = Array(bytes[(offset + 4)..<(offset + 2 + length)])
        if marker == 0xc0 {
            guard payload.count >= 6 else { return nil }
            height = Int(payload[1]) << 8 | Int(payload[2])
            width = Int(payload[3]) << 8 | Int(payload[4])
            components = Int(payload[5])
            guard components == 1 || components == 3, payload.count >= 6 + components * 3 else {
                return nil
            }
            for c in 0..<components {
                sampling[c] = Int(payload[6 + c * 3 + 1])
                quantId[c] = Int(payload[6 + c * 3 + 2])
                if sampling[c] != 0x11 {
                    return nil
                }
            }
        } else if marker == 0xdb {
            var i = 0
            while i + 65 <= payload.count {
                let info = Int(payload[i])
                let dest = info & 0x0f
                guard dest < 4, (info >> 4) == 0 else { return nil }
                var table = [Int](repeating: 1, count: 64)
                for z in 0..<64 {
                    table[imageioJPEGZigzag[z]] = Int(payload[i + 1 + z])
                }
                quant[dest] = table
                i += 65
            }
        } else if marker == 0xc4 {
            var i = 0
            while i + 17 <= payload.count {
                let info = payload[i]
                let cls = Int(info >> 4)
                let dest = Int(info & 0x0f)
                var counts = [UInt8](repeating: 0, count: 16)
                var total = 0
                for b in 0..<16 {
                    counts[b] = payload[i + 1 + b]
                    total += Int(counts[b])
                }
                i += 17
                guard i + total <= payload.count else { return nil }
                let values = Array(payload[i..<(i + total)])
                i += total
                let built = imageioJPEGBuildHuff(counts, values)
                if cls == 0, dest < 4 {
                    dcHuff[dest] = built
                } else if dest < 4 {
                    acHuff[dest] = built
                }
            }
        }
        offset += 2 + length
    }
    guard width > 0, height > 0, scanStart > 0, components == 3 else { return nil }
    let reader = ImageIOJPEGBitReader(bytes: bytes, start: scanStart)
    let mcuX = (width + 7) / 8
    let mcuY = (height + 7) / 8
    var planes = [
        [Double](repeating: 0, count: mcuX * 8 * mcuY * 8),
        [Double](repeating: 0, count: mcuX * 8 * mcuY * 8),
        [Double](repeating: 0, count: mcuX * 8 * mcuY * 8),
    ]
    var prevDC = [0, 0, 0]
    let stride = mcuX * 8
    for my in 0..<mcuY {
        for mx in 0..<mcuX {
            for plane in 0..<3 {
                let qid = quantId[plane]
                guard qid < 4,
                      let spatial = imageioJPEGDecodeBlock(
                        reader,
                        quant: quant[qid],
                        dcTable: dcHuff[plane == 0 ? 0 : 1],
                        acTable: acHuff[plane == 0 ? 0 : 1],
                        prevDC: &prevDC[plane]
                      ) else { return nil }
                for y in 0..<8 {
                    for x in 0..<8 {
                        planes[plane][(my * 8 + y) * stride + mx * 8 + x] = spatial[y * 8 + x]
                    }
                }
            }
        }
    }
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    for y in 0..<height {
        for x in 0..<width {
            let i = y * stride + x
            let rgb = imageioJPEGYCbCrToRGB(planes[0][i], planes[1][i], planes[2][i])
            let dst = (y * width + x) * 4
            pixels[dst] = rgb.0
            pixels[dst + 1] = rgb.1
            pixels[dst + 2] = rgb.2
            pixels[dst + 3] = 255
        }
    }
    guard let image = imageioMakeImage(width: width, height: height, pixels: pixels) else {
        return nil
    }
    return DecodedImageSet(images: [image], frameDelays: [0])
}
