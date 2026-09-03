import Foundation

/// ISO/IEC 7816-4 command APDU. Short-length encoding and decoding is
/// implemented from the public APDU layout. Extended-length APDUs are not
/// claimed; `init(data:)` returns nil when the bytes cannot be parsed as a
/// short command APDU.
public class NFCISO7816APDU: NSObject {
    public let instructionClass: UInt8
    public let instructionCode: UInt8
    public let p1Parameter: UInt8
    public let p2Parameter: UInt8
    public let data: Data?
    public let expectedResponseLength: Int

    public init(
        instructionClass: UInt8,
        instructionCode: UInt8,
        p1Parameter: UInt8,
        p2Parameter: UInt8,
        data: Data,
        expectedResponseLength: Int
    ) {
        self.instructionClass = instructionClass
        self.instructionCode = instructionCode
        self.p1Parameter = p1Parameter
        self.p2Parameter = p2Parameter
        self.data = data.isEmpty ? nil : data
        self.expectedResponseLength = expectedResponseLength
        super.init()
    }

    public init?(data raw: Data) {
        guard raw.count >= 4 else {
            return nil
        }
        instructionClass = raw[0]
        instructionCode = raw[1]
        p1Parameter = raw[2]
        p2Parameter = raw[3]
        let rest = raw.dropFirst(4)
        if rest.isEmpty {
            data = nil
            expectedResponseLength = -1
            super.init()
            return
        }
        if rest.count == 1 {
            data = nil
            expectedResponseLength = decodeShortLe(rest[rest.startIndex])
            super.init()
            return
        }
        let lc = Int(rest[rest.startIndex])
        let afterLc = rest.dropFirst()
        if afterLc.count == lc {
            data = Data(afterLc)
            expectedResponseLength = -1
            super.init()
            return
        }
        if afterLc.count == lc + 1 {
            data = Data(afterLc.dropLast())
            expectedResponseLength = decodeShortLe(afterLc.last!)
            super.init()
            return
        }
        return nil
    }

    public func encodedBytes() -> Data {
        var bytes = Data([instructionClass, instructionCode, p1Parameter, p2Parameter])
        if let payload = data, !payload.isEmpty {
            bytes.append(UInt8(clamping: payload.count))
            bytes.append(payload)
        }
        if expectedResponseLength >= 0 {
            bytes.append(encodeShortLe(expectedResponseLength))
        }
        return bytes
    }
}

private func decodeShortLe(_ value: UInt8) -> Int {
    value == 0 ? 256 : Int(value)
}

private func encodeShortLe(_ length: Int) -> UInt8 {
    if length >= 256 {
        return 0
    }
    return UInt8(clamping: max(0, length))
}

public struct NFCISO7816ResponseAPDU: Equatable, Sendable {
    public var statusWord1: UInt8
    public var statusWord2: UInt8
    public var payload: Data?

    public init(statusWord1: UInt8, statusWord2: UInt8, payload: Data? = nil) {
        self.statusWord1 = statusWord1
        self.statusWord2 = statusWord2
        self.payload = payload
    }
}
