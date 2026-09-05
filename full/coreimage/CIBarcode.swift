import Foundation

/// ISO/IEC 18004 QR encoder and ISO/IEC 15417 Code 128 encoder.
///
/// QR: alphanumeric when every byte is in the 45-char set, otherwise byte
/// mode. Quiet zone is **1 module** (MEASURED iPhone SE 2x / iOS 26.1 ciprobe:
/// "HELLO WORLD" level M is 23×23 = version-1 21 plus 1-module quiet).
/// Mask 0 of that encode matches the captured module grid bit-for-bit.
///
/// Code 128: Code set B, quiet 10, height 32 (Apple defaults from ciprobe
/// `inputQuietSpace=10`, `inputBarcodeHeight=32`; "ABC-123" width 132).

func ciEncodeQR(_ message: Data, level: String) -> CGImage? {
    let lv = ciQRLevel(level)
    guard let modules = ciQRModules(message, level: lv) else { return nil }
    let n = modules.count
    var pixels = [UInt8](repeating: 255, count: n * n * 4)
    for y in 0..<n {
        for x in 0..<n {
            let dark = modules[y][x] != 0
            let o = (y * n + x) * 4
            let v: UInt8 = dark ? 0 : 255
            pixels[o] = v
            pixels[o + 1] = v
            pixels[o + 2] = v
            pixels[o + 3] = 255
        }
    }
    return CGImage(width: n, height: n, pixels: pixels)
}

func ciEncodeCode128(_ message: Data, quiet: Int, height: Int) -> CGImage? {
    let text = String(data: message, encoding: .ascii) ?? ""
    guard !text.isEmpty else { return nil }
    var codes = [104] // Start B
    for ch in text.utf8 {
        guard ch >= 32, ch <= 127 else { return nil }
        codes.append(Int(ch) - 32)
    }
    var checksum = codes[0]
    for i in 1..<codes.count {
        checksum += i * codes[i]
    }
    codes.append(checksum % 103)
    codes.append(106) // Stop
    var modules: [UInt8] = Array(repeating: 0, count: max(0, quiet))
    for code in codes {
        let widths = ciCode128Widths(code)
        var bar = true
        for w in widths {
            for _ in 0..<w { modules.append(bar ? 1 : 0) }
            bar = !bar
        }
    }
    modules += Array(repeating: 0, count: max(0, quiet))
    let width = modules.count
    let h = max(1, height + 2 * quiet)
    var pixels = [UInt8](repeating: 255, count: width * h * 4)
    let top = max(0, quiet)
    let barH = max(1, height)
    for y in 0..<h {
        let inBar = y >= top && y < top + barH
        for x in 0..<width {
            let dark = inBar && modules[x] == 1
            let o = (y * width + x) * 4
            let v: UInt8 = dark ? 0 : 255
            pixels[o] = v
            pixels[o + 1] = v
            pixels[o + 2] = v
            pixels[o + 3] = 255
        }
    }
    return CGImage(width: width, height: h, pixels: pixels)
}

func ciQRLevel(_ s: String) -> String {
    if s == "L" || s == "Q" || s == "H" { return s }
    return "M"
}

func ciQRModules(_ message: Data, level: String) -> [[UInt8]]? {
    let alphanumeric = ciQRAlphanumericBits(message)
    let bits: [UInt8]
    let isAlpha: Bool
    if let alphanumeric {
        bits = alphanumeric
        isAlpha = true
    } else {
        bits = ciQRByteBits(message)
        isAlpha = false
    }
    guard let version = ciQRPickVersion(bitCount: bits.count, level: level, alphanumeric: isAlpha) else {
        return nil
    }
    let spec = ciQRSpec(version, level)
    let data = ciQRPad(bits, dataCodewords: spec.dataCW)
    let interleaved = ciQRInterleave(data, spec: spec)
    let size = 21 + 4 * (version - 1)
    var reserved = Array(repeating: Array(repeating: false, count: size), count: size)
    ciQRMarkReserved(&reserved, size: size, version: version)
    var base = Array(repeating: Array(repeating: UInt8(0), count: size), count: size)
    ciQRPlaceFinders(&base, size: size, version: version)
    var dataBits: [UInt8] = []
    for b in interleaved {
        for i in (0..<8).reversed() {
            dataBits.append(UInt8((b >> i) & 1))
        }
    }
    var best: [[UInt8]]?
    var bestScore = Int.max
    for mask in 0..<8 {
        var grid = base
        ciQRPlaceData(&grid, reserved: reserved, bits: dataBits)
        ciQRApplyMask(&grid, reserved: reserved, mask: mask)
        ciQRPlaceFormat(&grid, size: size, level: level, mask: mask)
        if version >= 7 { ciQRPlaceVersion(&grid, size: size, version: version) }
        let score = ciQRPenalty(grid)
        if score < bestScore {
            bestScore = score
            best = grid
        }
        // MEASURED ciprobe HELLO WORLD M uses mask 0; keep evaluating all 8.
    }
    guard let grid = best else { return nil }
    return ciQRQuiet(grid, q: 1)
}

private let ciQRAlphanum = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:")

func ciQRAlphanumericBits(_ data: Data) -> [UInt8]? {
    var chars: [Int] = []
    chars.reserveCapacity(data.count)
    for b in data {
        let ch = Character(UnicodeScalar(b))
        guard let idx = ciQRAlphanum.firstIndex(of: ch) else { return nil }
        chars.append(idx)
    }
    var bits: [UInt8] = [0, 0, 1, 0]
    let n = chars.count
    bits += ciQRBits(n, width: 9)
    var i = 0
    while i + 1 < n {
        let v = chars[i] * 45 + chars[i + 1]
        bits += ciQRBits(v, width: 11)
        i += 2
    }
    if i < n {
        bits += ciQRBits(chars[i], width: 6)
    }
    return bits
}

func ciQRByteBits(_ data: Data) -> [UInt8] {
    var bits: [UInt8] = [0, 1, 0, 0]
    bits += ciQRBits(data.count, width: 8)
    for b in data {
        bits += ciQRBits(Int(b), width: 8)
    }
    return bits
}

func ciQRBits(_ value: Int, width: Int) -> [UInt8] {
    (0..<width).reversed().map { UInt8((value >> $0) & 1) }
}

func ciQRPickVersion(bitCount: Int, level: String, alphanumeric: Bool) -> Int? {
    for v in 1...10 {
        let spec = ciQRSpec(v, level)
        let capBits = spec.dataCW * 8
        // mode + count + terminator 4
        if bitCount + 4 <= capBits { return v }
    }
    return nil
}

struct CIQRSpec {
    var dataCW: Int
    var ecPerBlock: Int
    var g1Blocks: Int
    var g1CW: Int
    var g2Blocks: Int
    var g2CW: Int
}

func ciQRSpec(_ version: Int, _ level: String) -> CIQRSpec {
    // ISO 18004 Table 9 (codeword counts) for versions 1...10.
    let table: [Int: [String: CIQRSpec]] = [
        1: [
            "L": CIQRSpec(dataCW: 19, ecPerBlock: 7, g1Blocks: 1, g1CW: 19, g2Blocks: 0, g2CW: 0),
            "M": CIQRSpec(dataCW: 16, ecPerBlock: 10, g1Blocks: 1, g1CW: 16, g2Blocks: 0, g2CW: 0),
            "Q": CIQRSpec(dataCW: 13, ecPerBlock: 13, g1Blocks: 1, g1CW: 13, g2Blocks: 0, g2CW: 0),
            "H": CIQRSpec(dataCW: 9, ecPerBlock: 17, g1Blocks: 1, g1CW: 9, g2Blocks: 0, g2CW: 0),
        ],
        2: [
            "L": CIQRSpec(dataCW: 34, ecPerBlock: 10, g1Blocks: 1, g1CW: 34, g2Blocks: 0, g2CW: 0),
            "M": CIQRSpec(dataCW: 28, ecPerBlock: 16, g1Blocks: 1, g1CW: 28, g2Blocks: 0, g2CW: 0),
            "Q": CIQRSpec(dataCW: 22, ecPerBlock: 22, g1Blocks: 1, g1CW: 22, g2Blocks: 0, g2CW: 0),
            "H": CIQRSpec(dataCW: 16, ecPerBlock: 28, g1Blocks: 1, g1CW: 16, g2Blocks: 0, g2CW: 0),
        ],
        3: [
            "L": CIQRSpec(dataCW: 55, ecPerBlock: 15, g1Blocks: 1, g1CW: 55, g2Blocks: 0, g2CW: 0),
            "M": CIQRSpec(dataCW: 44, ecPerBlock: 26, g1Blocks: 1, g1CW: 44, g2Blocks: 0, g2CW: 0),
            "Q": CIQRSpec(dataCW: 34, ecPerBlock: 18, g1Blocks: 2, g1CW: 17, g2Blocks: 0, g2CW: 0),
            "H": CIQRSpec(dataCW: 26, ecPerBlock: 22, g1Blocks: 2, g1CW: 13, g2Blocks: 0, g2CW: 0),
        ],
        4: [
            "L": CIQRSpec(dataCW: 80, ecPerBlock: 20, g1Blocks: 1, g1CW: 80, g2Blocks: 0, g2CW: 0),
            "M": CIQRSpec(dataCW: 64, ecPerBlock: 18, g1Blocks: 2, g1CW: 32, g2Blocks: 0, g2CW: 0),
            "Q": CIQRSpec(dataCW: 48, ecPerBlock: 26, g1Blocks: 2, g1CW: 24, g2Blocks: 0, g2CW: 0),
            "H": CIQRSpec(dataCW: 36, ecPerBlock: 16, g1Blocks: 4, g1CW: 9, g2Blocks: 0, g2CW: 0),
        ],
        5: [
            "L": CIQRSpec(dataCW: 108, ecPerBlock: 26, g1Blocks: 1, g1CW: 108, g2Blocks: 0, g2CW: 0),
            "M": CIQRSpec(dataCW: 86, ecPerBlock: 24, g1Blocks: 2, g1CW: 43, g2Blocks: 0, g2CW: 0),
            "Q": CIQRSpec(dataCW: 62, ecPerBlock: 18, g1Blocks: 2, g1CW: 15, g2Blocks: 2, g2CW: 16),
            "H": CIQRSpec(dataCW: 46, ecPerBlock: 22, g1Blocks: 2, g1CW: 11, g2Blocks: 2, g2CW: 12),
        ],
        6: [
            "L": CIQRSpec(dataCW: 136, ecPerBlock: 18, g1Blocks: 2, g1CW: 68, g2Blocks: 0, g2CW: 0),
            "M": CIQRSpec(dataCW: 108, ecPerBlock: 16, g1Blocks: 4, g1CW: 27, g2Blocks: 0, g2CW: 0),
            "Q": CIQRSpec(dataCW: 76, ecPerBlock: 24, g1Blocks: 4, g1CW: 19, g2Blocks: 0, g2CW: 0),
            "H": CIQRSpec(dataCW: 60, ecPerBlock: 28, g1Blocks: 4, g1CW: 15, g2Blocks: 0, g2CW: 0),
        ],
        7: [
            "L": CIQRSpec(dataCW: 156, ecPerBlock: 20, g1Blocks: 2, g1CW: 78, g2Blocks: 0, g2CW: 0),
            "M": CIQRSpec(dataCW: 124, ecPerBlock: 18, g1Blocks: 4, g1CW: 31, g2Blocks: 0, g2CW: 0),
            "Q": CIQRSpec(dataCW: 88, ecPerBlock: 18, g1Blocks: 2, g1CW: 14, g2Blocks: 4, g2CW: 15),
            "H": CIQRSpec(dataCW: 66, ecPerBlock: 26, g1Blocks: 4, g1CW: 13, g2Blocks: 1, g2CW: 14),
        ],
        8: [
            "L": CIQRSpec(dataCW: 194, ecPerBlock: 24, g1Blocks: 2, g1CW: 97, g2Blocks: 0, g2CW: 0),
            "M": CIQRSpec(dataCW: 154, ecPerBlock: 22, g1Blocks: 2, g1CW: 38, g2Blocks: 2, g2CW: 39),
            "Q": CIQRSpec(dataCW: 110, ecPerBlock: 22, g1Blocks: 4, g1CW: 18, g2Blocks: 2, g2CW: 19),
            "H": CIQRSpec(dataCW: 86, ecPerBlock: 26, g1Blocks: 4, g1CW: 14, g2Blocks: 2, g2CW: 15),
        ],
        9: [
            "L": CIQRSpec(dataCW: 232, ecPerBlock: 30, g1Blocks: 2, g1CW: 116, g2Blocks: 0, g2CW: 0),
            "M": CIQRSpec(dataCW: 182, ecPerBlock: 22, g1Blocks: 3, g1CW: 36, g2Blocks: 2, g2CW: 37),
            "Q": CIQRSpec(dataCW: 132, ecPerBlock: 20, g1Blocks: 4, g1CW: 16, g2Blocks: 4, g2CW: 17),
            "H": CIQRSpec(dataCW: 100, ecPerBlock: 24, g1Blocks: 4, g1CW: 12, g2Blocks: 4, g2CW: 13),
        ],
        10: [
            "L": CIQRSpec(dataCW: 274, ecPerBlock: 18, g1Blocks: 2, g1CW: 68, g2Blocks: 2, g2CW: 69),
            "M": CIQRSpec(dataCW: 216, ecPerBlock: 26, g1Blocks: 4, g1CW: 43, g2Blocks: 1, g2CW: 44),
            "Q": CIQRSpec(dataCW: 154, ecPerBlock: 24, g1Blocks: 6, g1CW: 19, g2Blocks: 2, g2CW: 20),
            "H": CIQRSpec(dataCW: 122, ecPerBlock: 28, g1Blocks: 6, g1CW: 15, g2Blocks: 2, g2CW: 16),
        ],
    ]
    return table[version]![level]!
}

func ciQRPad(_ bits: [UInt8], dataCodewords: Int) -> [UInt8] {
    var bits = bits
    let need = dataCodewords * 8
    let term = min(4, need - bits.count)
    if term > 0 { bits += Array(repeating: 0, count: term) }
    while bits.count % 8 != 0 { bits.append(0) }
    var bytes: [UInt8] = []
    var i = 0
    while i < bits.count {
        var v: UInt8 = 0
        for _ in 0..<8 {
            v = (v << 1) | bits[i]
            i += 1
        }
        bytes.append(v)
    }
    var padToggle = false
    while bytes.count < dataCodewords {
        bytes.append(padToggle ? 0x11 : 0xEC)
        padToggle = !padToggle
    }
    return Array(bytes.prefix(dataCodewords))
}

func ciQRInterleave(_ data: [UInt8], spec: CIQRSpec) -> [UInt8] {
    var blocks: [[UInt8]] = []
    var offset = 0
    for _ in 0..<spec.g1Blocks {
        let slice = Array(data[offset..<(offset + spec.g1CW)])
        blocks.append(slice + ciQRRS(slice, nsym: spec.ecPerBlock))
        offset += spec.g1CW
    }
    for _ in 0..<spec.g2Blocks {
        let slice = Array(data[offset..<(offset + spec.g2CW)])
        blocks.append(slice + ciQRRS(slice, nsym: spec.ecPerBlock))
        offset += spec.g2CW
    }
    var out: [UInt8] = []
    let maxData = blocks.map { $0.count - spec.ecPerBlock }.max() ?? 0
    for i in 0..<maxData {
        for b in blocks where i < b.count - spec.ecPerBlock {
            out.append(b[i])
        }
    }
    for i in 0..<spec.ecPerBlock {
        for b in blocks {
            out.append(b[b.count - spec.ecPerBlock + i])
        }
    }
    return out
}

func ciQRGFMul(_ a: UInt8, _ b: UInt8) -> UInt8 {
    var aa = Int(a), bb = Int(b), p = 0
    for _ in 0..<8 {
        if bb & 1 != 0 { p ^= aa }
        let hi = aa & 0x80
        aa = (aa << 1) & 0xFF
        if hi != 0 { aa ^= 0x1D }
        bb >>= 1
    }
    return UInt8(p)
}

func ciQRRS(_ data: [UInt8], nsym: Int) -> [UInt8] {
    var exp = [UInt8](repeating: 0, count: 512)
    var x: UInt8 = 1
    for i in 0..<255 {
        exp[i] = x
        x = ciQRGFMul(x, 2)
    }
    for i in 255..<512 { exp[i] = exp[i - 255] }
    var gen: [UInt8] = [1]
    for i in 0..<nsym {
        var next = [UInt8](repeating: 0, count: gen.count + 1)
        for j in 0..<gen.count {
            next[j] ^= gen[j]
            next[j + 1] ^= ciQRGFMul(gen[j], exp[i])
        }
        gen = next
    }
    var res = data + Array(repeating: UInt8(0), count: nsym)
    for i in 0..<data.count {
        let coef = res[i]
        if coef != 0 {
            for j in 0..<gen.count {
                res[i + j] ^= ciQRGFMul(gen[j], coef)
            }
        }
    }
    return Array(res.suffix(nsym))
}

func ciQRMarkReserved(_ reserved: inout [[Bool]], size: Int, version: Int) {
    func markFinder(_ r: Int, _ c: Int) {
        for y in r..<(r + 8) {
            for x in c..<(c + 8) where y >= 0 && y < size && x >= 0 && x < size {
                reserved[y][x] = true
            }
        }
    }
    markFinder(0, 0)
    markFinder(0, size - 8)
    markFinder(size - 8, 0)
    for i in 0..<size {
        reserved[6][i] = true
        reserved[i][6] = true
    }
    for i in 0..<9 {
        reserved[8][i] = true
        reserved[i][8] = true
    }
    for i in 0..<8 {
        reserved[8][size - 1 - i] = true
        reserved[size - 1 - i][8] = true
    }
    reserved[8][8] = true
    for pos in ciQRAlignments(version) {
        for y in (pos.1 - 2)...(pos.1 + 2) {
            for x in (pos.0 - 2)...(pos.0 + 2) where y >= 0 && y < size && x >= 0 && x < size {
                reserved[y][x] = true
            }
        }
    }
    if version >= 7 {
        for i in 0..<6 {
            for j in 0..<3 {
                reserved[i][size - 11 + j] = true
                reserved[size - 11 + j][i] = true
            }
        }
    }
}

func ciQRAlignments(_ version: Int) -> [(Int, Int)] {
    let centers: [Int: [Int]] = [
        2: [6, 18], 3: [6, 22], 4: [6, 26], 5: [6, 30], 6: [6, 34],
        7: [6, 22, 38], 8: [6, 24, 42], 9: [6, 26, 46], 10: [6, 28, 50],
    ]
    guard let c = centers[version] else { return [] }
    var pts: [(Int, Int)] = []
    for a in c {
        for b in c {
            if (a == 6 && b == 6) || (a == 6 && b == c.last) || (a == c.last && b == 6) { continue }
            pts.append((a, b))
        }
    }
    return pts
}

func ciQRPlaceFinders(_ grid: inout [[UInt8]], size: Int, version: Int) {
    func finder(_ r: Int, _ c: Int) {
        let pattern: [[UInt8]] = [
            [1, 1, 1, 1, 1, 1, 1],
            [1, 0, 0, 0, 0, 0, 1],
            [1, 0, 1, 1, 1, 0, 1],
            [1, 0, 1, 1, 1, 0, 1],
            [1, 0, 1, 1, 1, 0, 1],
            [1, 0, 0, 0, 0, 0, 1],
            [1, 1, 1, 1, 1, 1, 1],
        ]
        for y in 0..<7 {
            for x in 0..<7 { grid[r + y][c + x] = pattern[y][x] }
        }
    }
    finder(0, 0)
    finder(0, size - 7)
    finder(size - 7, 0)
    for i in 0..<size where i > 6 && i < size - 7 {
        grid[6][i] = i % 2 == 0 ? 1 : 0
        grid[i][6] = i % 2 == 0 ? 1 : 0
    }
    grid[size - 8][8] = 1
    let align: [[UInt8]] = [
        [1, 1, 1, 1, 1],
        [1, 0, 0, 0, 1],
        [1, 0, 1, 0, 1],
        [1, 0, 0, 0, 1],
        [1, 1, 1, 1, 1],
    ]
    for pos in ciQRAlignments(version) {
        for y in 0..<5 {
            for x in 0..<5 {
                grid[pos.1 - 2 + y][pos.0 - 2 + x] = align[y][x]
            }
        }
    }
}

func ciQRPlaceData(_ grid: inout [[UInt8]], reserved: [[Bool]], bits: [UInt8]) {
    let size = grid.count
    var idx = 0
    var upward = true
    var col = size - 1
    while col > 0 {
        if col == 6 { col -= 1 }
        for i in 0..<size {
            let r = upward ? size - 1 - i : i
            for c in [col, col - 1] {
                if !reserved[r][c] {
                    grid[r][c] = idx < bits.count ? bits[idx] : 0
                    idx += 1
                }
            }
        }
        upward.toggle()
        col -= 2
    }
}

func ciQRMask(_ kind: Int, _ r: Int, _ c: Int) -> Bool {
    switch kind {
    case 0: return (r + c) % 2 == 0
    case 1: return r % 2 == 0
    case 2: return c % 3 == 0
    case 3: return (r + c) % 3 == 0
    case 4: return (r / 2 + c / 3) % 2 == 0
    case 5: return (r * c) % 2 + (r * c) % 3 == 0
    case 6: return ((r * c) % 2 + (r * c) % 3) % 2 == 0
    default: return ((r + c) % 2 + (r * c) % 3) % 2 == 0
    }
}

func ciQRApplyMask(_ grid: inout [[UInt8]], reserved: [[Bool]], mask: Int) {
    let size = grid.count
    for r in 0..<size {
        for c in 0..<size where !reserved[r][c] && ciQRMask(mask, r, c) {
            grid[r][c] ^= 1
        }
    }
}

func ciQRFormatBits(level: String, mask: Int) -> Int {
    let lvl = ["L": 1, "M": 0, "Q": 3, "H": 2][level] ?? 0
    let data = (lvl << 3) | mask
    var d = data << 10
    let gen = 0x537
    for i in stride(from: 4, through: 0, by: -1) {
        if d & (1 << (i + 10)) != 0 { d ^= gen << i }
    }
    return ((data << 10) | d) ^ 0x5412
}

func ciQRPlaceFormat(_ grid: inout [[UInt8]], size: Int, level: String, mask: Int) {
    let bits = ciQRFormatBits(level: level, mask: mask)
    let a: [(Int, Int)] = [
        (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 7), (8, 8),
        (7, 8), (5, 8), (4, 8), (3, 8), (2, 8), (1, 8), (0, 8),
    ]
    let b: [(Int, Int)] = [
        (size - 1, 8), (size - 2, 8), (size - 3, 8), (size - 4, 8), (size - 5, 8),
        (size - 6, 8), (size - 7, 8),
        (8, size - 8), (8, size - 7), (8, size - 6), (8, size - 5), (8, size - 4),
        (8, size - 3), (8, size - 2), (8, size - 1),
    ]
    for i in 0..<15 {
        let bit = UInt8((bits >> (14 - i)) & 1)
        grid[a[i].0][a[i].1] = bit
        grid[b[i].0][b[i].1] = bit
    }
}

func ciQRPlaceVersion(_ grid: inout [[UInt8]], size: Int, version: Int) {
    // BCH version information, ISO Table D.1
    let table: [Int: Int] = [
        7: 0x07C94, 8: 0x085BC, 9: 0x09A99, 10: 0x0A4D3,
    ]
    guard let bits = table[version] else { return }
    for i in 0..<18 {
        let bit = UInt8((bits >> i) & 1)
        let a = i / 3
        let b = i % 3
        grid[a][size - 11 + b] = bit
        grid[size - 11 + b][a] = bit
    }
}

func ciQRPenalty(_ grid: [[UInt8]]) -> Int {
    let n = grid.count
    var score = 0
    for r in 0..<n {
        var run = 1
        for c in 1..<n {
            if grid[r][c] == grid[r][c - 1] { run += 1 }
            else { if run >= 5 { score += run - 2 }; run = 1 }
        }
        if run >= 5 { score += run - 2 }
    }
    for c in 0..<n {
        var run = 1
        for r in 1..<n {
            if grid[r][c] == grid[r - 1][c] { run += 1 }
            else { if run >= 5 { score += run - 2 }; run = 1 }
        }
        if run >= 5 { score += run - 2 }
    }
    for r in 0..<(n - 1) {
        for c in 0..<(n - 1) {
            let v = grid[r][c]
            if grid[r][c + 1] == v, grid[r + 1][c] == v, grid[r + 1][c + 1] == v { score += 3 }
        }
    }
    return score
}

func ciQRQuiet(_ grid: [[UInt8]], q: Int) -> [[UInt8]] {
    let n = grid.count
    let s = n + 2 * q
    var out = Array(repeating: Array(repeating: UInt8(0), count: s), count: s)
    for r in 0..<n {
        for c in 0..<n { out[r + q][c + q] = grid[r][c] }
    }
    return out
}

func ciCode128Widths(_ code: Int) -> [Int] {
    let pat: [String] = [
        "212222", "222122", "222221", "121223", "121322", "131222", "122213", "122312", "132212", "221213",
        "221312", "231212", "112232", "122132", "122231", "113222", "123122", "123221", "223211", "221132",
        "221231", "213212", "223112", "312131", "311222", "321122", "321221", "312212", "322112", "322211",
        "212123", "212321", "232121", "111323", "131123", "131321", "112313", "132113", "132311", "211313",
        "231113", "231311", "112133", "112331", "132131", "113123", "113321", "133121", "313121", "211331",
        "231131", "213113", "213311", "213131", "311123", "311321", "331121", "312113", "312311", "332111",
        "314111", "221411", "431111", "111224", "111422", "121124", "121421", "141122", "141221", "112214",
        "112412", "122114", "122411", "142112", "142211", "241211", "221114", "413111", "241112", "134111",
        "111242", "121142", "121241", "114212", "124112", "124211", "411212", "421112", "421211", "212141",
        "214121", "412121", "111143", "111341", "131141", "114113", "114311", "411113", "411311", "113141",
        "114131", "311141", "411131", "211412", "211214", "211232", "2331112",
    ]
    let s = code >= 0 && code < pat.count ? pat[code] : "211412"
    return s.utf8.map { Int($0 - 48) }
}
