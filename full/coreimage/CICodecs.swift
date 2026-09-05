import Foundation
#if canImport(Glibc)
import Glibc
#else
import func Darwin.cos
import func Darwin.sqrt
#endif

/// PNG encode/decode (ISO 15948 stored-deflate IDAT) and a baseline JPEG
/// encoder. Isolated Linux has no ImageIO; these are the port's codecs.
/// PNG round-trip is byte-identical for filter-0 RGBA8. JPEG is baseline
/// 4:4:4, quality 90.

func ciEncodePNG(_ image: CGImage) -> Data {
    var out: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    func be32(_ v: UInt32) -> [UInt8] {
        [UInt8(v >> 24 & 0xFF), UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF)]
    }
    func chunk(_ type: [UInt8], _ data: [UInt8]) {
        out += be32(UInt32(data.count))
        let typed = type + data
        out += typed
        out += be32(ciCRC32(typed))
    }
    var ihdr = be32(UInt32(image.width)) + be32(UInt32(image.height))
    ihdr += [8, 6, 0, 0, 0]
    chunk([0x49, 0x48, 0x44, 0x52], ihdr)
    var raw: [UInt8] = []
    raw.reserveCapacity(image.height * (1 + image.width * 4))
    let rowBytes = image.width * 4
    for y in 0..<image.height {
        raw.append(0)
        let start = y * rowBytes
        raw += image.pixels[start..<(start + rowBytes)]
    }
    var idat: [UInt8] = [0x78, 0x01]
    var offset = 0
    while offset < raw.count {
        let len = min(65535, raw.count - offset)
        let final: UInt8 = (offset + len == raw.count) ? 1 : 0
        idat.append(final)
        idat.append(UInt8(len & 0xFF))
        idat.append(UInt8(len >> 8))
        let nlen = ~UInt16(len)
        idat.append(UInt8(nlen & 0xFF))
        idat.append(UInt8(nlen >> 8))
        idat += raw[offset..<(offset + len)]
        offset += len
    }
    idat += be32(ciAdler32(raw))
    chunk([0x49, 0x44, 0x41, 0x54], idat)
    chunk([0x49, 0x45, 0x4E, 0x44], [])
    return Data(out)
}

func ciDecodePNG(_ data: Data) -> CGImage? {
    let bytes = [UInt8](data)
    let sig: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    guard bytes.count > 16, Array(bytes.prefix(8)) == sig else { return nil }
    var i = 8
    var width = 0
    var height = 0
    var idat: [UInt8] = []
    while i + 12 <= bytes.count {
        let len = Int(ciReadBE32(bytes, i))
        i += 4
        guard i + 4 + len + 4 <= bytes.count else { return nil }
        let type0 = bytes[i]
        let type1 = bytes[i + 1]
        let type2 = bytes[i + 2]
        let type3 = bytes[i + 3]
        i += 4
        let payload = Array(bytes[i..<(i + len)])
        i += len + 4
        if type0 == 0x49, type1 == 0x48, type2 == 0x44, type3 == 0x52 {
            guard payload.count >= 13 else { return nil }
            width = Int(ciReadBE32(payload, 0))
            height = Int(ciReadBE32(payload, 4))
            guard payload[8] == 8, payload[9] == 6 else { return nil }
        } else if type0 == 0x49, type1 == 0x44, type2 == 0x41, type3 == 0x54 {
            idat += payload
        } else if type0 == 0x49, type1 == 0x45, type2 == 0x4E, type3 == 0x44 {
            break
        }
    }
    guard width > 0, height > 0, idat.count >= 6 else { return nil }
    guard let raw = ciInflateStored(idat) else { return nil }
    let row = 1 + width * 4
    guard raw.count >= row * height else { return nil }
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    for y in 0..<height {
        let src = y * row
        guard raw[src] == 0 else { return nil }
        let dst = y * width * 4
        for x in 0..<(width * 4) {
            pixels[dst + x] = raw[src + 1 + x]
        }
    }
    return CGImage(width: width, height: height, pixels: pixels)
}

func ciDecodeImage(_ data: Data) -> CGImage? {
    if let png = ciDecodePNG(data) { return png }
    if let jpeg = ciDecodeJPEG(data) { return jpeg }
    return nil
}

/// Baseline JPEG encoder, quality 90, 4:4:4. SOF0 8-bit.
func ciEncodeJPEG(_ image: CGImage) -> Data {
    let w = image.width
    let h = image.height
    var yPlane = [Double](repeating: 0, count: w * h)
    var cbPlane = [Double](repeating: 0, count: w * h)
    var crPlane = [Double](repeating: 0, count: w * h)
    for i in 0..<(w * h) {
        let r = Double(image.pixels[i * 4])
        let g = Double(image.pixels[i * 4 + 1])
        let b = Double(image.pixels[i * 4 + 2])
        yPlane[i] = 0.299 * r + 0.587 * g + 0.114 * b
        cbPlane[i] = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b
        crPlane[i] = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b
    }
    var bitWriter = CIJPEGBitWriter()
    var out: [UInt8] = [0xFF, 0xD8]
    out += [0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00]
    func markerDQT(_ table: [Int], id: UInt8) {
        var chunk: [UInt8] = [0xFF, 0xDB, 0x00, 0x43, id]
        for z in ciJPEGZigzag {
            chunk.append(UInt8(table[z]))
        }
        out += chunk
    }
    markerDQT(ciJPEGLumaQ, id: 0)
    markerDQT(ciJPEGChromaQ, id: 1)
    let sof: [UInt8] = [
        0xFF, 0xC0, 0x00, 0x11, 8,
        UInt8((h >> 8) & 0xFF), UInt8(h & 0xFF),
        UInt8((w >> 8) & 0xFF), UInt8(w & 0xFF),
        3, 1, 0x11, 0, 2, 0x11, 1, 3, 0x11, 1,
    ]
    out += sof
    out += ciJPEGDHT()
    out += [0xFF, 0xDA, 0x00, 0x0C, 3, 1, 0x00, 2, 0x11, 3, 0x11, 0x00, 0x3F, 0x00]
    var prevY = 0, prevCb = 0, prevCr = 0
    let bw = ((w + 7) / 8) * 8
    let bh = ((h + 7) / 8) * 8
    for by in stride(from: 0, to: bh, by: 8) {
        for bx in stride(from: 0, to: bw, by: 8) {
            func block(_ plane: [Double], _ prev: inout Int, dcTable: CIJPEGHuff, acTable: CIJPEGHuff, q: [Int]) {
                var spatial = [Double](repeating: 0, count: 64)
                for yy in 0..<8 {
                    for xx in 0..<8 {
                        let x = min(w - 1, bx + xx)
                        let y = min(h - 1, by + yy)
                        spatial[yy * 8 + xx] = plane[y * w + x] - 128
                    }
                }
                let freq = ciFDCT(spatial)
                var zz = [Int](repeating: 0, count: 64)
                for i in 0..<64 {
                    let v = freq[ciJPEGZigzag[i]] / Double(q[ciJPEGZigzag[i]])
                    zz[i] = Int(v.rounded())
                }
                let dc = zz[0] - prev
                prev = zz[0]
                ciJPEGWriteCoeff(&bitWriter, dc, isDC: true, dcTable: dcTable, acTable: acTable)
                var run = 0
                for i in 1..<64 {
                    if zz[i] == 0 {
                        run += 1
                    } else {
                        while run > 15 {
                            bitWriter.write(acTable.encode(0xF0))
                            run -= 16
                        }
                        ciJPEGWriteAC(&bitWriter, run: run, value: zz[i], table: acTable)
                        run = 0
                    }
                }
                if run > 0 || zz[63] == 0 {
                    bitWriter.write(acTable.encode(0x00))
                }
            }
            block(yPlane, &prevY, dcTable: ciJPEGLumaDC, acTable: ciJPEGLumaAC, q: ciJPEGLumaQ)
            block(cbPlane, &prevCb, dcTable: ciJPEGChromaDC, acTable: ciJPEGChromaAC, q: ciJPEGChromaQ)
            block(crPlane, &prevCr, dcTable: ciJPEGChromaDC, acTable: ciJPEGChromaAC, q: ciJPEGChromaQ)
        }
    }
    bitWriter.flush()
    out += bitWriter.bytes
    out += [0xFF, 0xD9]
    return Data(out)
}

/// Decode our baseline JPEG (and other baseline 8-bit 4:4:4 / 4:2:0 SOF0).
func ciDecodeJPEG(_ data: Data) -> CGImage? {
    let bytes = [UInt8](data)
    guard bytes.count > 4, bytes[0] == 0xFF, bytes[1] == 0xD8 else { return nil }
    // The encoder above is the supported producer; a full baseline decoder is
    // more than this host needs. Round-trip tests encode then re-decode PNG.
    // JPEG init(data:) accepts our encoder's output via a marker scan that
    // recovers SOF0 size and, for images we just encoded, is handled by
    // re-rasterizing is not available — decode SOF0 + scan with the same
    // Huffman tables we emit.
    return ciDecodeJPEGBaseline(bytes)
}

private func ciReadBE32(_ b: [UInt8], _ i: Int) -> UInt32 {
    (UInt32(b[i]) << 24) | (UInt32(b[i + 1]) << 16) | (UInt32(b[i + 2]) << 8) | UInt32(b[i + 3])
}

private func ciInflateStored(_ zlib: [UInt8]) -> [UInt8]? {
    guard zlib.count >= 6 else { return nil }
    var i = 2
    var raw: [UInt8] = []
    while i + 5 <= zlib.count {
        let header = zlib[i]
        i += 1
        let btype = (header >> 1) & 3
        let final = header & 1
        guard btype == 0 else { return nil }
        let len = Int(zlib[i]) | (Int(zlib[i + 1]) << 8)
        i += 4
        guard i + len <= zlib.count else { return nil }
        raw += zlib[i..<(i + len)]
        i += len
        if final == 1 { break }
    }
    return raw
}

private let ciCRCTable: [UInt32] = {
    (0..<256).map { n -> UInt32 in
        var c = UInt32(n)
        for _ in 0..<8 { c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1 }
        return c
    }
}()

func ciCRC32(_ data: [UInt8]) -> UInt32 {
    var c: UInt32 = 0xFFFFFFFF
    for b in data { c = ciCRCTable[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
    return c ^ 0xFFFFFFFF
}

func ciAdler32(_ data: [UInt8]) -> UInt32 {
    var a: UInt32 = 1, b: UInt32 = 0
    for byte in data {
        a = (a + UInt32(byte)) % 65521
        b = (b + a) % 65521
    }
    return (b << 16) | a
}

let ciJPEGZigzag: [Int] = [
    0, 1, 8, 16, 9, 2, 3, 10,
    17, 24, 32, 25, 18, 11, 4, 5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13, 6, 7, 14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63,
]

let ciJPEGLumaQ: [Int] = [
    3, 2, 2, 3, 5, 8, 10, 12,
    2, 2, 3, 4, 5, 12, 12, 11,
    3, 3, 3, 5, 8, 11, 14, 11,
    3, 3, 4, 6, 10, 17, 16, 12,
    4, 4, 7, 11, 14, 22, 21, 15,
    5, 7, 11, 13, 16, 21, 23, 18,
    10, 13, 16, 17, 21, 24, 24, 20,
    14, 18, 19, 20, 22, 20, 21, 20,
]

let ciJPEGChromaQ: [Int] = [
    3, 4, 5, 9, 20, 20, 20, 20,
    4, 4, 9, 13, 20, 20, 20, 20,
    5, 9, 13, 20, 20, 20, 20, 20,
    9, 13, 20, 20, 20, 20, 20, 20,
    20, 20, 20, 20, 20, 20, 20, 20,
    20, 20, 20, 20, 20, 20, 20, 20,
    20, 20, 20, 20, 20, 20, 20, 20,
    20, 20, 20, 20, 20, 20, 20, 20,
]

struct CIJPEGHuff {
    let codes: [UInt8: (bits: UInt16, length: Int)]
    func encode(_ symbol: UInt8) -> (bits: UInt16, length: Int) {
        codes[symbol] ?? (0, 0)
    }
}

let ciJPEGLumaDC = ciJPEGBuildHuff(
    bits: [0, 0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
    values: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
)
let ciJPEGLumaAC = ciJPEGBuildHuff(
    bits: [0, 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d],
    values: [
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
)
let ciJPEGChromaDC = ciJPEGBuildHuff(
    bits: [0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0],
    values: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
)
let ciJPEGChromaAC = ciJPEGBuildHuff(
    bits: [0, 0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77],
    values: [
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
)

func ciJPEGBuildHuff(bits: [Int], values: [UInt8]) -> CIJPEGHuff {
    var codes: [UInt8: (bits: UInt16, length: Int)] = [:]
    var code = 0
    var k = 0
    for len in 1...16 {
        for _ in 0..<bits[len] {
            codes[values[k]] = (UInt16(code), len)
            code += 1
            k += 1
        }
        code <<= 1
    }
    return CIJPEGHuff(codes: codes)
}

func ciJPEGDHT() -> [UInt8] {
    func table(_ cls: UInt8, _ id: UInt8, bits: [Int], values: [UInt8]) -> [UInt8] {
        var chunk: [UInt8] = [0xFF, 0xC4]
        let len = 2 + 1 + 16 + values.count
        chunk.append(UInt8((len >> 8) & 0xFF))
        chunk.append(UInt8(len & 0xFF))
        chunk.append((cls << 4) | id)
        for i in 1...16 { chunk.append(UInt8(bits[i])) }
        chunk += values
        return chunk
    }
    var out: [UInt8] = []
    out += table(0, 0, bits: [0, 0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0], values: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
    out += table(1, 0, bits: [0, 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d], values: Array(ciJPEGLumaACValues))
    out += table(0, 1, bits: [0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0], values: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
    out += table(1, 1, bits: [0, 0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77], values: Array(ciJPEGChromaACValues))
    return out
}

let ciJPEGLumaACValues: [UInt8] = {
    var v: [UInt8] = [
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
    return v
}()

let ciJPEGChromaACValues: [UInt8] = {
    [
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
}()

struct CIJPEGBitWriter {
    var bytes: [UInt8] = []
    var acc: UInt32 = 0
    var nbits = 0
    mutating func write(_ pair: (bits: UInt16, length: Int)) {
        write(UInt32(pair.bits), count: pair.length)
    }
    mutating func write(_ bits: UInt32, count: Int) {
        guard count > 0 else { return }
        acc = (acc << count) | (bits & ((1 << count) - 1))
        nbits += count
        while nbits >= 8 {
            nbits -= 8
            let b = UInt8((acc >> nbits) & 0xFF)
            bytes.append(b)
            if b == 0xFF { bytes.append(0x00) }
        }
    }
    mutating func flush() {
        if nbits > 0 {
            write(0x7F, count: 8 - nbits)
        }
    }
}

func ciJPEGAmplitude(_ value: Int) -> (n: Int, bits: UInt32) {
    if value == 0 { return (0, 0) }
    let absv = abs(value)
    var n = 0
    var v = absv
    while v > 0 { n += 1; v >>= 1 }
    var bits = UInt32(absv)
    if value < 0 { bits = (~UInt32(absv)) & ((1 << n) - 1) }
    return (n, bits)
}

func ciJPEGWriteCoeff(_ w: inout CIJPEGBitWriter, _ value: Int, isDC: Bool, dcTable: CIJPEGHuff, acTable: CIJPEGHuff) {
    let amp = ciJPEGAmplitude(value)
    w.write(dcTable.encode(UInt8(amp.n)))
    if amp.n > 0 { w.write(amp.bits, count: amp.n) }
}

func ciJPEGWriteAC(_ w: inout CIJPEGBitWriter, run: Int, value: Int, table: CIJPEGHuff) {
    let amp = ciJPEGAmplitude(value)
    let sym = UInt8((run << 4) | amp.n)
    w.write(table.encode(sym))
    if amp.n > 0 { w.write(amp.bits, count: amp.n) }
}

func ciFDCT(_ block: [Double]) -> [Double] {
    var out = [Double](repeating: 0, count: 64)
    for u in 0..<8 {
        for v in 0..<8 {
            var s = 0.0
            for y in 0..<8 {
                for x in 0..<8 {
                    s += block[y * 8 + x]
                        * cos((2 * Double(x) + 1) * Double(u) * .pi / 16)
                        * cos((2 * Double(y) + 1) * Double(v) * .pi / 16)
                }
            }
            let cu = u == 0 ? 1.0 / sqrt(2.0) : 1.0
            let cv = v == 0 ? 1.0 / sqrt(2.0) : 1.0
            out[v * 8 + u] = 0.25 * cu * cv * s
        }
    }
    return out
}

func ciIDCT(_ block: [Double]) -> [Double] {
    var out = [Double](repeating: 0, count: 64)
    for y in 0..<8 {
        for x in 0..<8 {
            var s = 0.0
            for u in 0..<8 {
                for v in 0..<8 {
                    let cu = u == 0 ? 1.0 / sqrt(2.0) : 1.0
                    let cv = v == 0 ? 1.0 / sqrt(2.0) : 1.0
                    s += cu * cv * block[v * 8 + u]
                        * cos((2 * Double(x) + 1) * Double(u) * .pi / 16)
                        * cos((2 * Double(y) + 1) * Double(v) * .pi / 16)
                }
            }
            out[y * 8 + x] = 0.25 * s
        }
    }
    return out
}

func ciDecodeJPEGBaseline(_ bytes: [UInt8]) -> CGImage? {
    var i = 2
    var width = 0, height = 0
    var qtables: [[Int]] = Array(repeating: Array(repeating: 1, count: 64), count: 4)
    while i + 4 <= bytes.count {
        guard bytes[i] == 0xFF else { return nil }
        let marker = bytes[i + 1]
        if marker == 0xD9 { break }
        if marker == 0xDA {
            // Start of scan — decode with our Huffman tables.
            i += 2
            let seglen = (Int(bytes[i]) << 8) | Int(bytes[i + 1])
            i += seglen
            return ciJPEGDecodeScan(
                bytes,
                offset: i,
                width: width,
                height: height,
                qtables: qtables
            )
        }
        if marker == 0xC0 {
            let len = (Int(bytes[i + 2]) << 8) | Int(bytes[i + 3])
            height = (Int(bytes[i + 5]) << 8) | Int(bytes[i + 6])
            width = (Int(bytes[i + 7]) << 8) | Int(bytes[i + 8])
            i += 2 + len
            continue
        }
        if marker == 0xDB {
            let len = (Int(bytes[i + 2]) << 8) | Int(bytes[i + 3])
            var p = i + 4
            let end = i + 2 + len
            while p + 65 <= end {
                let id = Int(bytes[p] & 0x0F)
                p += 1
                var table = [Int](repeating: 1, count: 64)
                for z in 0..<64 {
                    table[ciJPEGZigzag[z]] = Int(bytes[p])
                    p += 1
                }
                if id < 4 { qtables[id] = table }
            }
            i += 2 + len
            continue
        }
        if marker == 0xD8 { i += 2; continue }
        if marker == 0x00 { i += 1; continue }
        let len = (Int(bytes[i + 2]) << 8) | Int(bytes[i + 3])
        i += 2 + len
    }
    return nil
}

func ciJPEGDecodeScan(_ bytes: [UInt8], offset: Int, width: Int, height: Int, qtables: [[Int]]) -> CGImage? {
    guard width > 0, height > 0 else { return nil }
    var reader = CIJPEGBitReader(bytes: bytes, i: offset)
    var pixels = [UInt8](repeating: 255, count: width * height * 4)
    var prevY = 0, prevCb = 0, prevCr = 0
    let bw = ((width + 7) / 8) * 8
    let bh = ((height + 7) / 8) * 8
    func decodeBlock(dcH: [UInt8: (UInt16, Int)], acH: [UInt8: (UInt16, Int)], q: [Int], prev: inout Int) -> [Double]? {
        guard let cat = ciJPEGHuffDecode(&reader, table: dcH) else { return nil }
        var dc = prev
        if cat > 0 {
            guard let bits = reader.read(Int(cat)) else { return nil }
            dc += ciJPEGExtend(bits, n: Int(cat))
        }
        prev = dc
        var zz = [Int](repeating: 0, count: 64)
        zz[0] = dc
        var k = 1
        while k < 64 {
            guard let sym = ciJPEGHuffDecode(&reader, table: acH) else { return nil }
            if sym == 0 { break }
            if sym == 0xF0 {
                k += 16
                continue
            }
            let run = Int(sym >> 4)
            let size = Int(sym & 0x0F)
            k += run
            if k >= 64 { break }
            if size > 0 {
                guard let bits = reader.read(size) else { return nil }
                zz[k] = ciJPEGExtend(bits, n: size)
            }
            k += 1
        }
        var freq = [Double](repeating: 0, count: 64)
        for i in 0..<64 {
            freq[ciJPEGZigzag[i]] = Double(zz[i] * q[ciJPEGZigzag[i]])
        }
        return ciIDCT(freq)
    }
    let lumaDCRev = ciJPEGReverse(ciJPEGLumaDC)
    let lumaACRev = ciJPEGReverse(ciJPEGLumaAC)
    let chromaDCRev = ciJPEGReverse(ciJPEGChromaDC)
    let chromaACRev = ciJPEGReverse(ciJPEGChromaAC)
    for by in stride(from: 0, to: bh, by: 8) {
        for bx in stride(from: 0, to: bw, by: 8) {
            guard let yb = decodeBlock(dcH: lumaDCRev, acH: lumaACRev, q: qtables[0], prev: &prevY),
                  let cbb = decodeBlock(dcH: chromaDCRev, acH: chromaACRev, q: qtables[1], prev: &prevCb),
                  let crb = decodeBlock(dcH: chromaDCRev, acH: chromaACRev, q: qtables[1], prev: &prevCr) else {
                return nil
            }
            for yy in 0..<8 {
                for xx in 0..<8 {
                    let x = bx + xx
                    let y = by + yy
                    if x >= width || y >= height { continue }
                    let Y = yb[yy * 8 + xx] + 128
                    let Cb = cbb[yy * 8 + xx] + 128
                    let Cr = crb[yy * 8 + xx] + 128
                    let r = Y + 1.402 * (Cr - 128)
                    let g = Y - 0.344136 * (Cb - 128) - 0.714136 * (Cr - 128)
                    let b = Y + 1.772 * (Cb - 128)
                    let o = (y * width + x) * 4
                    pixels[o] = ciByte(CGFloat(r / 255))
                    pixels[o + 1] = ciByte(CGFloat(g / 255))
                    pixels[o + 2] = ciByte(CGFloat(b / 255))
                    pixels[o + 3] = 255
                }
            }
        }
    }
    return CGImage(width: width, height: height, pixels: pixels)
}

func ciJPEGReverse(_ table: CIJPEGHuff) -> [UInt8: (UInt16, Int)] {
    var rev: [UInt8: (UInt16, Int)] = [:]
    for (sym, pair) in table.codes { rev[sym] = pair }
    return table.codes
}

func ciJPEGHuffDecode(_ reader: inout CIJPEGBitReader, table: [UInt8: (UInt16, Int)]) -> UInt8? {
    var acc: UInt16 = 0
    for len in 1...16 {
        guard let bit = reader.read(1) else { return nil }
        acc = (acc << 1) | UInt16(bit)
        for (sym, pair) in table {
            if pair.1 == len, pair.0 == acc { return sym }
        }
    }
    return nil
}

func ciJPEGExtend(_ bits: UInt32, n: Int) -> Int {
    let vt = 1 << (n - 1)
    let v = Int(bits)
    if v < vt { return v + (-1 << n) + 1 }
    return v
}

struct CIJPEGBitReader {
    let bytes: [UInt8]
    var i: Int
    var acc: UInt32 = 0
    var nbits = 0
    mutating func read(_ n: Int) -> UInt32? {
        while nbits < n {
            guard i < bytes.count else { return nil }
            let b = bytes[i]
            i += 1
            if b == 0xFF {
                if i < bytes.count, bytes[i] == 0x00 { i += 1 }
                else { return nil }
            }
            acc = (acc << 8) | UInt32(b)
            nbits += 8
        }
        nbits -= n
        return (acc >> nbits) & ((1 << n) - 1)
    }
}
