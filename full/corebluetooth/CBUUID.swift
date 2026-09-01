import Foundation
import CoreFoundation

private let _cbBluetoothBaseSuffix: [UInt8] = [
    0x00, 0x00, 0x10, 0x00, 0x80, 0x00, 0x00, 0x80, 0x5F, 0x9B, 0x34, 0xFB,
]

/// Bluetooth SIG 16/32/128-bit UUID wrapper. Parsing, compacting, and
/// equality are implemented in software and do not require a radio.
@available(iOS 5.0, *)
open class CBUUID: NSObject {
    private let _data: Data

    open var data: Data { _data }

    open var uuidString: String {
        switch _data.count {
        case 2:
            return _hex(_data).uppercased()
        case 4:
            return _hex(_data).uppercased()
        default:
            let b = [UInt8](_expandedBytes())
            let hex = _hex(Data(b)).uppercased()
            let chars = Array(hex)
            func slice(_ range: Range<Int>) -> String {
                String(chars[range])
            }
            return "\(slice(0..<8))-\(slice(8..<12))-\(slice(12..<16))-\(slice(16..<20))-\(slice(20..<32))"
        }
    }

    public init(string theString: String) {
        _data = CBUUID._parse(theString)
        super.init()
    }

    public init(data theData: Data) {
        let bytes: [UInt8]
        switch theData.count {
        case 2, 4, 16:
            bytes = Array(theData)
        default:
            bytes = Array(theData.prefix(16))
        }
        _data = CBUUID._compact(CBUUID._expand(bytes))
        super.init()
    }

    public init(nsuuid theUUID: UUID) {
        let t = theUUID.uuid
        let bytes: [UInt8] = [
            t.0, t.1, t.2, t.3, t.4, t.5, t.6, t.7,
            t.8, t.9, t.10, t.11, t.12, t.13, t.14, t.15,
        ]
        _data = CBUUID._compact(bytes)
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
        _data = CBUUID._compact(bytes)
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
        CBUUID._expand(Array(_data))
    }

    private static func _parse(_ string: String) -> Data {
        var filtered = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
        if filtered.lowercased().hasPrefix("0x") {
            filtered = String(filtered.dropFirst(2))
        }
        let hex = filtered.filter { $0.isHexDigit }
        let bytes = _bytes(fromHex: hex)
        switch bytes.count {
        case 2, 4, 16:
            return _compact(_expand(bytes))
        default:
            return _compact(_expand(bytes))
        }
    }

    private static func _bytes(fromHex hex: String) -> [UInt8] {
        var padded = hex
        if padded.count % 2 == 1 {
            padded = "0" + padded
        }
        var bytes: [UInt8] = []
        var index = padded.startIndex
        while index < padded.endIndex {
            let next = padded.index(index, offsetBy: 2, limitedBy: padded.endIndex) ?? padded.endIndex
            let slice = padded[index..<next]
            bytes.append(UInt8(slice, radix: 16) ?? 0)
            index = next
        }
        return bytes
    }

    private static func _expand(_ bytes: [UInt8]) -> [UInt8] {
        switch bytes.count {
        case 2:
            return [0, 0, bytes[0], bytes[1]] + _cbBluetoothBaseSuffix
        case 4:
            return bytes + _cbBluetoothBaseSuffix
        case 16:
            return bytes
        default:
            var padded = bytes
            if padded.count > 16 {
                padded = Array(padded.suffix(16))
            }
            while padded.count < 16 {
                padded.insert(0, at: 0)
            }
            return padded
        }
    }

    private static func _compact(_ expanded: [UInt8]) -> Data {
        guard expanded.count == 16 else { return Data(expanded) }
        let suffix = Array(expanded[4..<16])
        if suffix == _cbBluetoothBaseSuffix {
            if expanded[0] == 0 && expanded[1] == 0 {
                return Data([expanded[2], expanded[3]])
            }
            return Data(expanded[0..<4])
        }
        return Data(expanded)
    }
}

private func _hex(_ data: Data) -> String {
    data.map { String(format: "%02x", $0) }.joined()
}
