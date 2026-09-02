import Foundation
import CoreFoundation

/// Bluetooth Core Specification base UUID:
/// `00000000-0000-1000-8000-00805F9B34FB`.
/// 16-bit `XXXX` maps to `0000XXXX-0000-1000-8000-00805F9B34FB`.
/// 32-bit `XXXXXXXX` maps to `XXXXXXXX-0000-1000-8000-00805F9B34FB`.
private let _cbBluetoothBaseSuffix: [UInt8] = [
    0x00, 0x00, 0x10, 0x00, 0x80, 0x00, 0x00, 0x80, 0x5F, 0x9B, 0x34, 0xFB,
]

enum _CBUUIDExact {
    static func data(fromString string: String) -> Data? {
        if let bytes = _fixedHexBytes(string, byteCount: 2)
            ?? _fixedHexBytes(string, byteCount: 4)
            ?? _fixedHexBytes(string, byteCount: 16)
        {
            return compact(expand(bytes))
        }
        if let bytes = _hyphenated128(string) {
            return compact(bytes)
        }
        return nil
    }

    static func data(fromBytes data: Data) -> Data? {
        switch data.count {
        case 2, 4, 16:
            return compact(expand(Array(data)))
        default:
            return nil
        }
    }

    static func expand(_ bytes: [UInt8]) -> [UInt8] {
        switch bytes.count {
        case 2:
            return [0, 0, bytes[0], bytes[1]] + _cbBluetoothBaseSuffix
        case 4:
            return bytes + _cbBluetoothBaseSuffix
        case 16:
            return bytes
        default:
            return bytes
        }
    }

    static func compact(_ expanded: [UInt8]) -> Data {
        guard expanded.count == 16 else { return Data(expanded) }
        let suffix = Array(expanded[4..<16])
        guard suffix == _cbBluetoothBaseSuffix else {
            return Data(expanded)
        }
        if expanded[0] == 0 && expanded[1] == 0 {
            return Data([expanded[2], expanded[3]])
        }
        return Data(expanded[0..<4])
    }
}

private func _isHex(_ character: Character) -> Bool {
    switch character {
    case "0"..."9", "a"..."f", "A"..."F":
        return true
    default:
        return false
    }
}

private func _fixedHexBytes(_ string: String, byteCount: Int) -> [UInt8]? {
    let expected = byteCount * 2
    guard string.count == expected, string.allSatisfy(_isHex) else {
        return nil
    }
    var bytes: [UInt8] = []
    bytes.reserveCapacity(byteCount)
    var index = string.startIndex
    for _ in 0..<byteCount {
        let next = string.index(index, offsetBy: 2)
        guard let byte = UInt8(string[index..<next], radix: 16) else {
            return nil
        }
        bytes.append(byte)
        index = next
    }
    return bytes
}

private func _hyphenated128(_ string: String) -> [UInt8]? {
    let groups = string.split(separator: "-", omittingEmptySubsequences: false)
    guard groups.count == 5 else { return nil }
    let widths = [8, 4, 4, 4, 12]
    var hex = ""
    hex.reserveCapacity(32)
    for (group, width) in zip(groups, widths) {
        guard group.count == width, group.allSatisfy(_isHex) else {
            return nil
        }
        hex += group
    }
    return _fixedHexBytes(hex, byteCount: 16)
}

/// Bluetooth SIG 16/32/128-bit UUID wrapper. String and `Data` initializers
/// accept only exact 2-, 4-, or 16-byte encodings; malformed input does not
/// strip, pad, or truncate.
@available(iOS 5.0, *)
open class CBUUID: NSObject {
    private let _data: Data

    open var data: Data { _data }

    open var uuidString: String {
        switch _data.count {
        case 2, 4:
            return _hex(_data)
        default:
            let hex = _hex(Data(_expandedBytes()))
            let chars = Array(hex)
            func slice(_ range: Range<Int>) -> String {
                String(chars[range])
            }
            return "\(slice(0..<8))-\(slice(8..<12))-\(slice(12..<16))-\(slice(16..<20))-\(slice(20..<32))"
        }
    }

    public init(string theString: String) {
        guard let data = _CBUUIDExact.data(fromString: theString) else {
            fatalError("CBUUID string is not a 16-, 32-, or 128-bit UUID")
        }
        _data = data
        super.init()
    }

    public init(data theData: Data) {
        guard let data = _CBUUIDExact.data(fromBytes: theData) else {
            fatalError("CBUUID data must be 2, 4, or 16 bytes")
        }
        _data = data
        super.init()
    }

    public init(nsuuid theUUID: UUID) {
        let t = theUUID.uuid
        let bytes: [UInt8] = [
            t.0, t.1, t.2, t.3, t.4, t.5, t.6, t.7,
            t.8, t.9, t.10, t.11, t.12, t.13, t.14, t.15,
        ]
        _data = _CBUUIDExact.compact(bytes)
        super.init()
    }

    public convenience init(NSUUID theUUID: UUID) {
        self.init(nsuuid: theUUID)
    }

    public init(cfuuid theUUID: CFUUID) {
        let b = CFUUIDGetUUIDBytes(theUUID)
        let bytes: [UInt8] = [
            b.byte0, b.byte1, b.byte2, b.byte3,
            b.byte4, b.byte5, b.byte6, b.byte7,
            b.byte8, b.byte9, b.byte10, b.byte11,
            b.byte12, b.byte13, b.byte14, b.byte15,
        ]
        _data = _CBUUIDExact.compact(bytes)
        super.init()
    }

    public convenience init(CFUUID theUUID: CFUUID) {
        self.init(cfuuid: theUUID)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CBUUID else { return false }
        return _expandedBytes() == other._expandedBytes()
    }

    open override var hash: Int {
        var hasher = Hasher()
        _expandedBytes().forEach { hasher.combine($0) }
        return hasher.finalize()
    }

    open override var description: String { uuidString }

    func _expandedBytes() -> [UInt8] {
        _CBUUIDExact.expand(Array(_data))
    }

    @_spi(OpenUIKitHost)
    public static func _hostData(fromString string: String) -> Data? {
        _CBUUIDExact.data(fromString: string)
    }

    @_spi(OpenUIKitHost)
    public static func _hostData(fromBytes data: Data) -> Data? {
        _CBUUIDExact.data(fromBytes: data)
    }
}

private func _hex(_ data: Data) -> String {
    data.map { String(format: "%02X", $0) }.joined()
}
