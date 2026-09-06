import CoreFoundation
import Foundation

// ICC.1 profile parse/serialize and named matrix RGB construction.
// Header field layout and MD5 Profile ID rules follow ICC.1 (profile flags,
// rendering intent, and Profile ID zeroed before the digest).

struct _CSTag {
    var signature: String
    var data: Data
}

struct _CSXYZ {
    var x: Double
    var y: Double
    var z: Double
}

struct _CSPrimaries {
    var rx: Double
    var ry: Double
    var gx: Double
    var gy: Double
    var bx: Double
    var by: Double
    var wx: Double
    var wy: Double
}

enum _CSTRC {
    case gamma(Double)
    case parametric(g: Double, a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)
    case table([Double])
    case identity
}

struct _CSMatrixSpace {
    var r: _CSXYZ
    var g: _CSXYZ
    var b: _CSXYZ
    var white: _CSXYZ
    var rTRC: _CSTRC
    var gTRC: _CSTRC
    var bTRC: _CSTRC
}

final class _CSProfileStorage: @unchecked Sendable {
    var bytes: Data
    var tags: [_CSTag]
    var url: URL?
    var named: String?
    var mutable: Bool
    var properties: [ObjectIdentifier: Any] = [:]

    init(bytes: Data, tags: [_CSTag], url: URL?, named: String?, mutable: Bool) {
        self.bytes = bytes
        self.tags = tags
        self.url = url
        self.named = named
        self.mutable = mutable
    }

    func copy(mutable: Bool) -> _CSProfileStorage {
        _CSProfileStorage(bytes: bytes, tags: tags, url: url, named: named, mutable: mutable)
    }
}

func _csReadU32(_ data: Data, _ offset: Int) -> UInt32? {
    guard offset >= 0, offset + 4 <= data.count else { return nil }
    return UInt32(data[offset]) << 24
        | UInt32(data[offset + 1]) << 16
        | UInt32(data[offset + 2]) << 8
        | UInt32(data[offset + 3])
}

func _csReadI32(_ data: Data, _ offset: Int) -> Int32? {
    guard let value = _csReadU32(data, offset) else { return nil }
    return Int32(bitPattern: value)
}

func _csFourChar(_ data: Data, _ offset: Int) -> String? {
    guard offset >= 0, offset + 4 <= data.count else { return nil }
    let bytes = [data[offset], data[offset + 1], data[offset + 2], data[offset + 3]]
    return String(bytes: bytes, encoding: .isoLatin1)
}

func _csAppendU32(_ data: inout Data, _ value: UInt32) {
    data.append(UInt8((value >> 24) & 0xFF))
    data.append(UInt8((value >> 16) & 0xFF))
    data.append(UInt8((value >> 8) & 0xFF))
    data.append(UInt8(value & 0xFF))
}

func _csAppendFour(_ data: inout Data, _ value: String) {
    let padded = (value + "    ").prefix(4)
    data.append(contentsOf: padded.utf8)
}

func _csS15Fixed16(_ value: Double) -> Int32 {
    Int32((value * 65536.0).rounded())
}

func _csFromS15Fixed16(_ value: Int32) -> Double {
    Double(value) / 65536.0
}

func _csParseICC(_ data: Data) -> _CSProfileStorage? {
    guard data.count >= 132, let size = _csReadU32(data, 0) else { return nil }
    guard size >= 132, Int(size) <= data.count else { return nil }
    guard _csFourChar(data, 36) == "acsp" else { return nil }
    guard let tagCount = _csReadU32(data, 128) else { return nil }
    let tableBytes = Int(tagCount) * 12
    guard 132 + tableBytes <= data.count else { return nil }
    var tags: [_CSTag] = []
    tags.reserveCapacity(Int(tagCount))
    if tagCount > 0 {
        for index in 0..<Int(tagCount) {
            let entry = 132 + index * 12
            guard let signature = _csFourChar(data, entry),
                  let offset = _csReadU32(data, entry + 4),
                  let length = _csReadU32(data, entry + 8) else { return nil }
            let start = Int(offset)
            let end = start + Int(length)
            guard start >= 0, end <= data.count, length > 0 else { return nil }
            tags.append(_CSTag(signature: signature, data: data.subdata(in: start..<end)))
        }
    }
    let sliced = data.prefix(Int(size))
    return _CSProfileStorage(bytes: Data(sliced), tags: tags, url: nil, named: nil, mutable: false)
}

func _csTag(_ storage: _CSProfileStorage, _ signature: String) -> Data? {
    storage.tags.first(where: { $0.signature == signature })?.data
}

func _csContainsTag(_ storage: _CSProfileStorage, _ signature: String) -> Bool {
    storage.tags.contains(where: { $0.signature == signature })
}

func _csRebuildBytes(_ storage: _CSProfileStorage) -> Data {
    var header = Data(storage.bytes.prefix(128))
    if header.count < 128 {
        header.append(Data(count: 128 - header.count))
    } else if header.count > 128 {
        header = header.prefix(128)
    }
    var body = Data()
    var table = Data()
    _csAppendU32(&table, UInt32(storage.tags.count))
    var offset = 128 + 4 + storage.tags.count * 12
    for tag in storage.tags {
        let start = offset
        let aligned = (tag.data.count + 3) & ~3
        _csAppendFour(&table, tag.signature)
        _csAppendU32(&table, UInt32(start))
        _csAppendU32(&table, UInt32(tag.data.count))
        body.append(tag.data)
        if aligned > tag.data.count {
            body.append(Data(count: aligned - tag.data.count))
        }
        offset += aligned
    }
    var assembled = header + table + body
    let size = UInt32(assembled.count)
    assembled[0] = UInt8((size >> 24) & 0xFF)
    assembled[1] = UInt8((size >> 16) & 0xFF)
    assembled[2] = UInt8((size >> 8) & 0xFF)
    assembled[3] = UInt8(size & 0xFF)
    let digest = _csProfileID(assembled)
    for index in 0..<16 {
        assembled[84 + index] = digest[index]
    }
    return assembled
}

func _csHeaderHostEndian(_ fileHeader: Data) -> Data {
    var header = Data(fileHeader.prefix(128))
    if header.count < 128 {
        header.append(Data(count: 128 - header.count))
    }
    var swapped = Data(count: 128)
    for word in 0..<32 {
        let o = word * 4
        let value = UInt32(header[o]) << 24
            | UInt32(header[o + 1]) << 16
            | UInt32(header[o + 2]) << 8
            | UInt32(header[o + 3])
        let host = value.littleEndian
        swapped[o] = UInt8(host & 0xFF)
        swapped[o + 1] = UInt8((host >> 8) & 0xFF)
        swapped[o + 2] = UInt8((host >> 16) & 0xFF)
        swapped[o + 3] = UInt8((host >> 24) & 0xFF)
    }
    return swapped
}

func _csHeaderFileEndian(_ hostHeader: Data) -> Data? {
    guard hostHeader.count >= 128 else { return nil }
    var file = Data(count: 128)
    for word in 0..<32 {
        let o = word * 4
        let host = UInt32(hostHeader[o])
            | UInt32(hostHeader[o + 1]) << 8
            | UInt32(hostHeader[o + 2]) << 16
            | UInt32(hostHeader[o + 3]) << 24
        file[o] = UInt8((host >> 24) & 0xFF)
        file[o + 1] = UInt8((host >> 16) & 0xFF)
        file[o + 2] = UInt8((host >> 8) & 0xFF)
        file[o + 3] = UInt8(host & 0xFF)
    }
    return file
}

func _csDescription(_ storage: _CSProfileStorage) -> String? {
    guard let data = _csTag(storage, "desc"), data.count >= 12 else { return nil }
    guard let type = _csFourChar(data, 0) else { return nil }
    if type == "desc" {
        guard let count = _csReadU32(data, 8), count > 0 else { return nil }
        let start = 12
        let end = min(start + Int(count) - 1, data.count)
        guard end > start else { return nil }
        return String(bytes: data[start..<end], encoding: .isoLatin1)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }
    if type == "mluc", data.count >= 28, let count = _csReadU32(data, 8), count >= 1 {
        let record = 16
        guard record + 12 <= data.count,
              let stringLength = _csReadU32(data, record + 4),
              let stringOffset = _csReadU32(data, record + 8) else { return nil }
        let start = Int(stringOffset)
        let end = start + Int(stringLength)
        guard start >= 0, end <= data.count else { return nil }
        var utf16: [UInt16] = []
        var cursor = start
        while cursor + 1 < end {
            let unit = UInt16(data[cursor]) << 8 | UInt16(data[cursor + 1])
            utf16.append(unit)
            cursor += 2
        }
        return String(utf16CodeUnits: utf16, count: utf16.count)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }
    return nil
}

func _csParseXYZ(_ data: Data) -> _CSXYZ? {
    guard data.count >= 20, _csFourChar(data, 0) == "XYZ " else { return nil }
    guard let x = _csReadI32(data, 8), let y = _csReadI32(data, 12), let z = _csReadI32(data, 16) else {
        return nil
    }
    return _CSXYZ(x: _csFromS15Fixed16(x), y: _csFromS15Fixed16(y), z: _csFromS15Fixed16(z))
}

func _csParseTRC(_ data: Data) -> _CSTRC? {
    guard data.count >= 12, let type = _csFourChar(data, 0) else { return nil }
    if type == "curv" {
        guard let count = _csReadU32(data, 8) else { return nil }
        if count == 0 { return .identity }
        if count == 1 {
            guard data.count >= 14 else { return nil }
            let encoded = UInt16(data[12]) << 8 | UInt16(data[13])
            return .gamma(Double(encoded) / 256.0)
        }
        var table: [Double] = []
        table.reserveCapacity(Int(count))
        for index in 0..<Int(count) {
            let o = 12 + index * 2
            guard o + 1 < data.count else { return nil }
            let encoded = UInt16(data[o]) << 8 | UInt16(data[o + 1])
            table.append(Double(encoded) / 65535.0)
        }
        return .table(table)
    }
    if type == "para", data.count >= 16, let function = _csReadU16(data, 8) {
        func param(_ index: Int) -> Double? {
            let o = 12 + index * 4
            guard let raw = _csReadI32(data, o) else { return nil }
            return _csFromS15Fixed16(raw)
        }
        switch function {
        case 0:
            guard let g = param(0) else { return nil }
            return .parametric(g: g, a: 1, b: 0, c: 0, d: 0, e: 0, f: 0)
        case 1:
            guard let g = param(0), let a = param(1), let b = param(2) else { return nil }
            return .parametric(g: g, a: a, b: b, c: 0, d: 0, e: 0, f: 0)
        case 2:
            guard let g = param(0), let a = param(1), let b = param(2), let c = param(3) else { return nil }
            return .parametric(g: g, a: a, b: b, c: c, d: 0, e: 0, f: 0)
        case 3:
            guard let g = param(0), let a = param(1), let b = param(2), let c = param(3), let d = param(4) else {
                return nil
            }
            return .parametric(g: g, a: a, b: b, c: c, d: d, e: 0, f: 0)
        case 4:
            guard let g = param(0), let a = param(1), let b = param(2), let c = param(3),
                  let d = param(4), let e = param(5), let f = param(6) else { return nil }
            return .parametric(g: g, a: a, b: b, c: c, d: d, e: e, f: f)
        default:
            return nil
        }
    }
    return nil
}

func _csReadU16(_ data: Data, _ offset: Int) -> UInt16? {
    guard offset >= 0, offset + 2 <= data.count else { return nil }
    return UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
}

func _csApplyTRC(_ trc: _CSTRC, _ x: Double) -> Double {
    let t = min(max(x, 0), 1)
    switch trc {
    case .identity:
        return t
    case .gamma(let g):
        return pow(t, g)
    case .parametric(let g, let a, let b, let c, let d, let e, let f):
        if t >= d {
            return pow(a * t + b, g) + e
        }
        return c * t + f
    case .table(let table):
        guard !table.isEmpty else { return t }
        if table.count == 1 { return pow(t, table[0]) }
        let scaled = t * Double(table.count - 1)
        let lo = Int(scaled)
        let hi = min(lo + 1, table.count - 1)
        let frac = scaled - Double(lo)
        return table[lo] * (1 - frac) + table[hi] * frac
    }
}

func _csInvertTRC(_ trc: _CSTRC, _ y: Double) -> Double {
    let target = min(max(y, 0), 1)
    switch trc {
    case .identity:
        return target
    case .gamma(let g):
        guard g > 0 else { return target }
        return pow(target, 1 / g)
    case .parametric, .table:
        var lo = 0.0
        var hi = 1.0
        for _ in 0..<24 {
            let mid = (lo + hi) / 2
            if _csApplyTRC(trc, mid) < target {
                lo = mid
            } else {
                hi = mid
            }
        }
        return (lo + hi) / 2
    }
}

func _csEstimateGamma(_ trc: _CSTRC) -> Float? {
    switch trc {
    case .gamma(let g):
        return Float(g)
    case .parametric(let g, _, _, _, let d, _, _):
        if abs(d) > 0.001 {
            return 2.2
        }
        return Float(g)
    case .identity:
        return 1.0
    case .table:
        return 2.2
    }
}

func _csIsMatrixBased(_ storage: _CSProfileStorage) -> Bool {
    _csContainsTag(storage, "rXYZ")
        && _csContainsTag(storage, "gXYZ")
        && _csContainsTag(storage, "bXYZ")
        && _csContainsTag(storage, "rTRC")
        && _csContainsTag(storage, "gTRC")
        && _csContainsTag(storage, "bTRC")
}

func _csMatrixSpace(_ storage: _CSProfileStorage) -> _CSMatrixSpace? {
    guard let r = _csParseXYZ(_csTag(storage, "rXYZ") ?? Data()),
          let g = _csParseXYZ(_csTag(storage, "gXYZ") ?? Data()),
          let b = _csParseXYZ(_csTag(storage, "bXYZ") ?? Data()),
          let rTRC = _csParseTRC(_csTag(storage, "rTRC") ?? Data()),
          let gTRC = _csParseTRC(_csTag(storage, "gTRC") ?? Data()),
          let bTRC = _csParseTRC(_csTag(storage, "bTRC") ?? Data()) else { return nil }
    let white = _csParseXYZ(_csTag(storage, "wtpt") ?? Data()) ?? _CSXYZ(x: 0.9642, y: 1.0, z: 0.8249)
    return _CSMatrixSpace(r: r, g: g, b: b, white: white, rTRC: rTRC, gTRC: gTRC, bTRC: bTRC)
}

func _csColorSpace(_ storage: _CSProfileStorage) -> String {
    _csFourChar(storage.bytes, 16) ?? "    "
}

func _csProfileClass(_ storage: _CSProfileStorage) -> String {
    _csFourChar(storage.bytes, 12) ?? "    "
}

func _csIsWideGamut(_ storage: _CSProfileStorage) -> Bool {
    // Named Display P3 / Adobe RGB / BT.2020 / ACES / DCI-P3 / ROMM are
    // wide. sRGB-family names are not. Parsed ICC files compare D50-relative
    // XYZ chromaticities against D50-adapted sRGB (not the D65 xy set).
    if let named = storage.named {
        switch named {
        case "com.apple.ColorSync.DisplayP3",
             "com.apple.ColorSync.AdobeRGB1998",
             "com.apple.ColorSync.ITUR2020",
             "com.apple.ColorSync.ACESCGLinear",
             "com.apple.ColorSync.DCIP3",
             "com.apple.ColorSync.ROMMRGB":
            return true
        default:
            return false
        }
    }
    guard let matrix = _csMatrixSpace(storage) else { return false }
    func xy(_ xyz: _CSXYZ) -> (Double, Double) {
        let sum = xyz.x + xyz.y + xyz.z
        guard sum > 0 else { return (0, 0) }
        return (xyz.x / sum, xyz.y / sum)
    }
    let r = xy(matrix.r)
    let g = xy(matrix.g)
    let b = xy(matrix.b)
    // D50-adapted sRGB primaries (ICC PCS), not the D65 xy set.
    let sR = (0.6484, 0.3309)
    let sG = (0.3212, 0.5978)
    let sB = (0.1559, 0.0660)
    func outside(_ p: (Double, Double), _ s: (Double, Double)) -> Bool {
        hypot(p.0 - s.0, p.1 - s.1) > 0.04
    }
    return outside(r, sR) || outside(g, sG) || outside(b, sB)
}

func _csIsPQBased(_ storage: _CSProfileStorage) -> Bool {
    if let named = storage.named, named.contains("PQ") { return true }
    return false
}

func _csIsHLGBased(_ storage: _CSProfileStorage) -> Bool {
    if let named = storage.named, named.contains("HLG") { return true }
    return false
}

func _csVerify(_ storage: _CSProfileStorage) -> (ok: Bool, errors: [String], warnings: [String]) {
    var errors: [String] = []
    var warnings: [String] = []
    if storage.bytes.count < 128 {
        errors.append("header too small")
    }
    if _csFourChar(storage.bytes, 36) != "acsp" {
        errors.append("missing acsp signature")
    }
    if let size = _csReadU32(storage.bytes, 0), Int(size) != storage.bytes.count {
        warnings.append("size field does not match byte count")
    }
    if storage.tags.isEmpty {
        warnings.append("no tags")
    }
    return (errors.isEmpty, errors, warnings)
}

func _csTextType(_ signature: String, _ text: String) -> _CSTag {
    var data = Data()
    _csAppendFour(&data, "desc")
    _csAppendU32(&data, 0)
    let ascii = Array(text.utf8) + [0]
    _csAppendU32(&data, UInt32(ascii.count))
    data.append(contentsOf: ascii)
    // Unicode language code + count (empty) and scriptcode count (empty).
    _csAppendU32(&data, 0)
    _csAppendU32(&data, 0)
    data.append(0)
    _csAppendFour(&data, "\u{0}\u{0}\u{0}\u{0}")
    return _CSTag(signature: signature, data: data)
}

func _csXYZType(_ signature: String, _ xyz: _CSXYZ) -> _CSTag {
    var data = Data()
    _csAppendFour(&data, "XYZ ")
    _csAppendU32(&data, 0)
    _csAppendU32(&data, UInt32(bitPattern: _csS15Fixed16(xyz.x)))
    _csAppendU32(&data, UInt32(bitPattern: _csS15Fixed16(xyz.y)))
    _csAppendU32(&data, UInt32(bitPattern: _csS15Fixed16(xyz.z)))
    return _CSTag(signature: signature, data: data)
}

func _csParaTRC(_ signature: String, _ trc: _CSTRC) -> _CSTag {
    var data = Data()
    switch trc {
    case .gamma(let g):
        _csAppendFour(&data, "curv")
        _csAppendU32(&data, 0)
        _csAppendU32(&data, 1)
        let encoded = UInt16((g * 256.0).rounded())
        data.append(UInt8(encoded >> 8))
        data.append(UInt8(encoded & 0xFF))
    case .parametric(let g, let a, let b, let c, let d, let e, let f):
        _csAppendFour(&data, "para")
        _csAppendU32(&data, 0)
        data.append(0)
        data.append(4) // function type 4
        data.append(0)
        data.append(0)
        for value in [g, a, b, c, d, e, f] {
            _csAppendU32(&data, UInt32(bitPattern: _csS15Fixed16(value)))
        }
    case .identity:
        _csAppendFour(&data, "curv")
        _csAppendU32(&data, 0)
        _csAppendU32(&data, 0)
    case .table(let table):
        _csAppendFour(&data, "curv")
        _csAppendU32(&data, 0)
        _csAppendU32(&data, UInt32(table.count))
        for value in table {
            let encoded = UInt16(min(max(value, 0), 1) * 65535.0)
            data.append(UInt8(encoded >> 8))
            data.append(UInt8(encoded & 0xFF))
        }
    }
    return _CSTag(signature: signature, data: data)
}

func _csXYZtoxy(_ xyz: _CSXYZ) -> (Double, Double) {
    let sum = xyz.x + xyz.y + xyz.z
    guard sum > 0 else { return (0, 0) }
    return (xyz.x / sum, xyz.y / sum)
}

func _csxyY(_ x: Double, _ y: Double, _ Y: Double) -> _CSXYZ {
    guard y != 0 else { return _CSXYZ(x: 0, y: 0, z: 0) }
    return _CSXYZ(x: x * Y / y, y: Y, z: (1 - x - y) * Y / y)
}

func _csInvert3x3(_ m: [[Double]]) -> [[Double]]? {
    let a = m[0][0], b = m[0][1], c = m[0][2]
    let d = m[1][0], e = m[1][1], f = m[1][2]
    let g = m[2][0], h = m[2][1], i = m[2][2]
    let det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
    guard abs(det) > 1e-12 else { return nil }
    let inv = 1 / det
    return [
        [(e * i - f * h) * inv, (c * h - b * i) * inv, (b * f - c * e) * inv],
        [(f * g - d * i) * inv, (a * i - c * g) * inv, (c * d - a * f) * inv],
        [(d * h - e * g) * inv, (b * g - a * h) * inv, (a * e - b * d) * inv]
    ]
}

func _csMul3(_ m: [[Double]], _ v: _CSXYZ) -> _CSXYZ {
    _CSXYZ(
        x: m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z,
        y: m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z,
        z: m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z
    )
}

func _csBradford(from src: _CSXYZ, to dst: _CSXYZ) -> [[Double]] {
    let ma = [
        [0.8951, 0.2664, -0.1614],
        [-0.7502, 1.7135, 0.0367],
        [0.0389, -0.0685, 1.0296]
    ]
    let srcLMS = _csMul3(ma, src)
    let dstLMS = _csMul3(ma, dst)
    let scale = [
        [dstLMS.x / srcLMS.x, 0, 0],
        [0, dstLMS.y / srcLMS.y, 0],
        [0, 0, dstLMS.z / srcLMS.z]
    ]
    let inv = _csInvert3x3(ma)!
    func mul(_ a: [[Double]], _ b: [[Double]]) -> [[Double]] {
        var out = Array(repeating: Array(repeating: 0.0, count: 3), count: 3)
        for i in 0..<3 {
            for j in 0..<3 {
                out[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j] + a[i][2] * b[2][j]
            }
        }
        return out
    }
    return mul(inv, mul(scale, ma))
}

func _csBuildRGBProfile(
    name: String,
    primaries: _CSPrimaries,
    trc: _CSTRC,
    copyright: String = "OpenUIKit ColorSync Linux"
) -> _CSProfileStorage {
    let rxy = _csxyY(primaries.rx, primaries.ry, 1)
    let gxy = _csxyY(primaries.gx, primaries.gy, 1)
    let bxy = _csxyY(primaries.bx, primaries.by, 1)
    let wxy = _csxyY(primaries.wx, primaries.wy, 1)
    let prim = [
        [rxy.x, gxy.x, bxy.x],
        [rxy.y, gxy.y, bxy.y],
        [rxy.z, gxy.z, bxy.z]
    ]
    let inv = _csInvert3x3(prim)!
    let scale = _csMul3(inv, wxy)
    let rXYZ = _CSXYZ(x: rxy.x * scale.x, y: rxy.y * scale.x, z: rxy.z * scale.x)
    let gXYZ = _CSXYZ(x: gxy.x * scale.y, y: gxy.y * scale.y, z: gxy.z * scale.y)
    let bXYZ = _CSXYZ(x: bxy.x * scale.z, y: bxy.y * scale.z, z: bxy.z * scale.z)
    let d50 = _CSXYZ(x: 0.9642, y: 1.0, z: 0.8249)
    let adapt = _csBradford(from: wxy, to: d50)
    let rPCS = _csMul3(adapt, rXYZ)
    let gPCS = _csMul3(adapt, gXYZ)
    let bPCS = _csMul3(adapt, bXYZ)

    var header = Data(count: 128)
    func setU32(_ offset: Int, _ value: UInt32) {
        header[offset] = UInt8((value >> 24) & 0xFF)
        header[offset + 1] = UInt8((value >> 16) & 0xFF)
        header[offset + 2] = UInt8((value >> 8) & 0xFF)
        header[offset + 3] = UInt8(value & 0xFF)
    }
    func setFour(_ offset: Int, _ value: String) {
        let padded = Array((value + "    ").prefix(4).utf8)
        for i in 0..<4 { header[offset + i] = padded[i] }
    }
    setFour(4, "linx")
    setU32(8, UInt32(bitPattern: Int32(icVersion4Number)))
    setFour(12, "mntr")
    setFour(16, "RGB ")
    setFour(20, "XYZ ")
    setFour(36, "acsp")
    setU32(64, 1) // relative colorimetric
    setU32(68, UInt32(bitPattern: _csS15Fixed16(d50.x)))
    setU32(72, UInt32(bitPattern: _csS15Fixed16(d50.y)))
    setU32(76, UInt32(bitPattern: _csS15Fixed16(d50.z)))
    setFour(80, "linx")

    var chad = Data()
    _csAppendFour(&chad, "sf32")
    _csAppendU32(&chad, 0)
    for row in adapt {
        for value in row {
            _csAppendU32(&chad, UInt32(bitPattern: _csS15Fixed16(value)))
        }
    }

    let tags: [_CSTag] = [
        _csTextType("desc", name),
        _csTextType("cprt", copyright),
        _csXYZType("wtpt", d50),
        _csXYZType("rXYZ", rPCS),
        _csXYZType("gXYZ", gPCS),
        _csXYZType("bXYZ", bPCS),
        _csParaTRC("rTRC", trc),
        _csParaTRC("gTRC", trc),
        _csParaTRC("bTRC", trc),
        _CSTag(signature: "chad", data: chad)
    ]
    let storage = _CSProfileStorage(bytes: header, tags: tags, url: nil, named: name, mutable: false)
    storage.bytes = _csRebuildBytes(storage)
    return storage
}

func _csBuildGrayProfile(name: String, gamma: Double) -> _CSProfileStorage {
    var header = Data(count: 128)
    func setU32(_ offset: Int, _ value: UInt32) {
        header[offset] = UInt8((value >> 24) & 0xFF)
        header[offset + 1] = UInt8((value >> 16) & 0xFF)
        header[offset + 2] = UInt8((value >> 8) & 0xFF)
        header[offset + 3] = UInt8(value & 0xFF)
    }
    func setFour(_ offset: Int, _ value: String) {
        let padded = Array((value + "    ").prefix(4).utf8)
        for i in 0..<4 { header[offset + i] = padded[i] }
    }
    setFour(4, "linx")
    setU32(8, UInt32(bitPattern: Int32(icVersion4Number)))
    setFour(12, "mntr")
    setFour(16, "GRAY")
    setFour(20, "XYZ ")
    setFour(36, "acsp")
    setU32(64, 1)
    let d50 = _CSXYZ(x: 0.9642, y: 1.0, z: 0.8249)
    setU32(68, UInt32(bitPattern: _csS15Fixed16(d50.x)))
    setU32(72, UInt32(bitPattern: _csS15Fixed16(d50.y)))
    setU32(76, UInt32(bitPattern: _csS15Fixed16(d50.z)))
    let tags = [
        _csTextType("desc", name),
        _csTextType("cprt", "OpenUIKit ColorSync Linux"),
        _csXYZType("wtpt", d50),
        _csParaTRC("kTRC", .gamma(gamma))
    ]
    let storage = _CSProfileStorage(bytes: header, tags: tags, url: nil, named: name, mutable: false)
    storage.bytes = _csRebuildBytes(storage)
    return storage
}

func _csBuildXYZProfile(name: String) -> _CSProfileStorage {
    var header = Data(count: 128)
    func setU32(_ offset: Int, _ value: UInt32) {
        header[offset] = UInt8((value >> 24) & 0xFF)
        header[offset + 1] = UInt8((value >> 16) & 0xFF)
        header[offset + 2] = UInt8((value >> 8) & 0xFF)
        header[offset + 3] = UInt8(value & 0xFF)
    }
    func setFour(_ offset: Int, _ value: String) {
        let padded = Array((value + "    ").prefix(4).utf8)
        for i in 0..<4 { header[offset + i] = padded[i] }
    }
    setFour(4, "linx")
    setU32(8, UInt32(bitPattern: Int32(icVersion4Number)))
    setFour(12, "spac")
    setFour(16, "XYZ ")
    setFour(20, "XYZ ")
    setFour(36, "acsp")
    let d50 = _CSXYZ(x: 0.9642, y: 1.0, z: 0.8249)
    setU32(68, UInt32(bitPattern: _csS15Fixed16(d50.x)))
    setU32(72, UInt32(bitPattern: _csS15Fixed16(d50.y)))
    setU32(76, UInt32(bitPattern: _csS15Fixed16(d50.z)))
    let tags = [
        _csTextType("desc", name),
        _csTextType("cprt", "OpenUIKit ColorSync Linux"),
        _csXYZType("wtpt", d50)
    ]
    let storage = _CSProfileStorage(bytes: header, tags: tags, url: nil, named: name, mutable: false)
    storage.bytes = _csRebuildBytes(storage)
    return storage
}

func _csBuildLabProfile(name: String) -> _CSProfileStorage {
    var header = Data(count: 128)
    func setU32(_ offset: Int, _ value: UInt32) {
        header[offset] = UInt8((value >> 24) & 0xFF)
        header[offset + 1] = UInt8((value >> 16) & 0xFF)
        header[offset + 2] = UInt8((value >> 8) & 0xFF)
        header[offset + 3] = UInt8(value & 0xFF)
    }
    func setFour(_ offset: Int, _ value: String) {
        let padded = Array((value + "    ").prefix(4).utf8)
        for i in 0..<4 { header[offset + i] = padded[i] }
    }
    setFour(4, "linx")
    setU32(8, UInt32(bitPattern: Int32(icVersion4Number)))
    setFour(12, "spac")
    setFour(16, "Lab ")
    setFour(20, "XYZ ")
    setFour(36, "acsp")
    let d50 = _CSXYZ(x: 0.9642, y: 1.0, z: 0.8249)
    setU32(68, UInt32(bitPattern: _csS15Fixed16(d50.x)))
    setU32(72, UInt32(bitPattern: _csS15Fixed16(d50.y)))
    setU32(76, UInt32(bitPattern: _csS15Fixed16(d50.z)))
    let tags = [
        _csTextType("desc", name),
        _csTextType("cprt", "OpenUIKit ColorSync Linux"),
        _csXYZType("wtpt", d50)
    ]
    let storage = _CSProfileStorage(bytes: header, tags: tags, url: nil, named: name, mutable: false)
    storage.bytes = _csRebuildBytes(storage)
    return storage
}

func _csBuildCMYKProfile(name: String) -> _CSProfileStorage {
    var header = Data(count: 128)
    func setU32(_ offset: Int, _ value: UInt32) {
        header[offset] = UInt8((value >> 24) & 0xFF)
        header[offset + 1] = UInt8((value >> 16) & 0xFF)
        header[offset + 2] = UInt8((value >> 8) & 0xFF)
        header[offset + 3] = UInt8(value & 0xFF)
    }
    func setFour(_ offset: Int, _ value: String) {
        let padded = Array((value + "    ").prefix(4).utf8)
        for i in 0..<4 { header[offset + i] = padded[i] }
    }
    setFour(4, "linx")
    setU32(8, UInt32(bitPattern: Int32(icVersion4Number)))
    setFour(12, "prtr")
    setFour(16, "CMYK")
    setFour(20, "Lab ")
    setFour(36, "acsp")
    let d50 = _CSXYZ(x: 0.9642, y: 1.0, z: 0.8249)
    setU32(68, UInt32(bitPattern: _csS15Fixed16(d50.x)))
    setU32(72, UInt32(bitPattern: _csS15Fixed16(d50.y)))
    setU32(76, UInt32(bitPattern: _csS15Fixed16(d50.z)))
    let tags = [
        _csTextType("desc", name),
        _csTextType("cprt", "OpenUIKit ColorSync Linux"),
        _csXYZType("wtpt", d50)
    ]
    let storage = _CSProfileStorage(bytes: header, tags: tags, url: nil, named: name, mutable: false)
    storage.bytes = _csRebuildBytes(storage)
    return storage
}

let _sRGBTRC: _CSTRC = .parametric(
    g: 2.4,
    a: 1.0 / 1.055,
    b: 0.055 / 1.055,
    c: 1.0 / 12.92,
    d: 0.04045,
    e: 0,
    f: 0
)

let _sRGBPrimaries = _CSPrimaries(rx: 0.64, ry: 0.33, gx: 0.30, gy: 0.60, bx: 0.15, by: 0.06, wx: 0.3127, wy: 0.3290)
let _p3Primaries = _CSPrimaries(rx: 0.680, ry: 0.320, gx: 0.265, gy: 0.690, bx: 0.150, by: 0.060, wx: 0.3127, wy: 0.3290)
let _adobePrimaries = _CSPrimaries(rx: 0.6400, ry: 0.3300, gx: 0.2100, gy: 0.7100, bx: 0.1500, by: 0.0600, wx: 0.3127, wy: 0.3290)
let _bt2020Primaries = _CSPrimaries(rx: 0.708, ry: 0.292, gx: 0.170, gy: 0.797, bx: 0.131, by: 0.046, wx: 0.3127, wy: 0.3290)
let _dciP3Primaries = _CSPrimaries(rx: 0.680, ry: 0.320, gx: 0.265, gy: 0.690, bx: 0.150, by: 0.060, wx: 0.314, wy: 0.351)
let _acesPrimaries = _CSPrimaries(rx: 0.7347, ry: 0.2653, gx: 0.0, gy: 1.0, bx: 0.0001, by: -0.0770, wx: 0.32168, wy: 0.33767)
let _rommPrimaries = _CSPrimaries(rx: 0.7347, ry: 0.2653, gx: 0.1596, gy: 0.8404, bx: 0.0366, by: 0.0001, wx: 0.3457, wy: 0.3585)

func _csNamedProfileStorage(_ name: String) -> _CSProfileStorage? {
    switch name {
    case "com.apple.ColorSync.sRGB", "com.apple.ColorSync.ITUR709", "com.apple.ColorSync.WebSafeColors":
        return _csBuildRGBProfile(name: name, primaries: _sRGBPrimaries, trc: _sRGBTRC)
    case "com.apple.ColorSync.DisplayP3":
        return _csBuildRGBProfile(name: name, primaries: _p3Primaries, trc: _sRGBTRC)
    case "com.apple.ColorSync.AdobeRGB1998":
        return _csBuildRGBProfile(name: name, primaries: _adobePrimaries, trc: .gamma(2.19921875))
    case "com.apple.ColorSync.GenericRGB":
        return _csBuildRGBProfile(name: name, primaries: _sRGBPrimaries, trc: .gamma(1.8))
    case "com.apple.ColorSync.ITUR2020":
        return _csBuildRGBProfile(name: name, primaries: _bt2020Primaries, trc: _sRGBTRC)
    case "com.apple.ColorSync.DCIP3":
        return _csBuildRGBProfile(name: name, primaries: _dciP3Primaries, trc: .gamma(2.6))
    case "com.apple.ColorSync.ACESCGLinear":
        return _csBuildRGBProfile(name: name, primaries: _acesPrimaries, trc: .identity)
    case "com.apple.ColorSync.ROMMRGB":
        return _csBuildRGBProfile(name: name, primaries: _rommPrimaries, trc: .gamma(1.8))
    case "com.apple.ColorSync.GenericGray":
        return _csBuildGrayProfile(name: name, gamma: 1.8)
    case "com.apple.ColorSync.GenericGrayGamma2.2":
        return _csBuildGrayProfile(name: name, gamma: 2.2)
    case "com.apple.ColorSync.GenericXYZ":
        return _csBuildXYZProfile(name: name)
    case "com.apple.ColorSync.GenericLab":
        return _csBuildLabProfile(name: name)
    case "com.apple.ColorSync.GenericCMYK":
        return _csBuildCMYKProfile(name: name)
    default:
        return nil
    }
}

func _csAllNamedProfileKeys() -> [String] {
    [
        "com.apple.ColorSync.sRGB",
        "com.apple.ColorSync.DisplayP3",
        "com.apple.ColorSync.AdobeRGB1998",
        "com.apple.ColorSync.GenericRGB",
        "com.apple.ColorSync.GenericGray",
        "com.apple.ColorSync.GenericGrayGamma2.2",
        "com.apple.ColorSync.GenericLab",
        "com.apple.ColorSync.GenericXYZ",
        "com.apple.ColorSync.GenericCMYK",
        "com.apple.ColorSync.ACESCGLinear",
        "com.apple.ColorSync.DCIP3",
        "com.apple.ColorSync.ITUR709",
        "com.apple.ColorSync.ITUR2020",
        "com.apple.ColorSync.ROMMRGB",
        "com.apple.ColorSync.WebSafeColors"
    ]
}

func _csProfileID(_ bytes: Data) -> [UInt8] {
    var copy = Data(bytes)
    if copy.count >= 100 {
        for index in 44..<48 { copy[index] = 0 }
        for index in 64..<68 { copy[index] = 0 }
        for index in 84..<100 { copy[index] = 0 }
    }
    return _csMD5(copy)
}

func _csMD5(_ data: Data) -> [UInt8] {
    var a0: UInt32 = 0x67452301
    var b0: UInt32 = 0xEFCDAB89
    var c0: UInt32 = 0x98BADCFE
    var d0: UInt32 = 0x10325476
    var message = Data(data)
    let bitCount = UInt64(data.count) * 8
    message.append(0x80)
    while (message.count % 64) != 56 {
        message.append(0)
    }
    for shift in [0, 8, 16, 24, 32, 32 + 8, 32 + 16, 32 + 24] {
        message.append(UInt8((bitCount >> shift) & 0xFF))
    }
    let s: [UInt32] = [
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
    ]
    let k: [UInt32] = (0..<64).map { index in
        UInt32(abs(sin(Double(index + 1))) * 4294967296.0)
    }
    func leftRotate(_ x: UInt32, _ c: UInt32) -> UInt32 {
        (x << c) | (x >> (32 - c))
    }
    var offset = 0
    while offset < message.count {
        var m = [UInt32](repeating: 0, count: 16)
        for i in 0..<16 {
            let o = offset + i * 4
            m[i] = UInt32(message[o])
                | UInt32(message[o + 1]) << 8
                | UInt32(message[o + 2]) << 16
                | UInt32(message[o + 3]) << 24
        }
        var a = a0
        var b = b0
        var c = c0
        var d = d0
        for i in 0..<64 {
            var f: UInt32
            var g: Int
            switch i {
            case 0..<16:
                f = (b & c) | ((~b) & d)
                g = i
            case 16..<32:
                f = (d & b) | ((~d) & c)
                g = (5 * i + 1) % 16
            case 32..<48:
                f = b ^ c ^ d
                g = (3 * i + 5) % 16
            default:
                f = c ^ (b | (~d))
                g = (7 * i) % 16
            }
            let temp = d
            d = c
            c = b
            b = b &+ leftRotate(a &+ f &+ k[i] &+ m[g], s[i])
            a = temp
        }
        a0 = a0 &+ a
        b0 = b0 &+ b
        c0 = c0 &+ c
        d0 = d0 &+ d
        offset += 64
    }
    func bytes(_ value: UInt32) -> [UInt8] {
        [
            UInt8(value & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 24) & 0xFF)
        ]
    }
    return bytes(a0) + bytes(b0) + bytes(c0) + bytes(d0)
}
