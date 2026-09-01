import Foundation

/// ISO/IEC 7816-4 command APDU. Parsing follows the public command layout;
/// nothing here talks to a card.
open class NFCISO7816APDU: NSObject {
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

    public init?(data apdu: Data) {
        guard apdu.count >= 4 else { return nil }
        self.instructionClass = apdu[0]
        self.instructionCode = apdu[1]
        self.p1Parameter = apdu[2]
        self.p2Parameter = apdu[3]
        let rest = apdu.dropFirst(4)
        if rest.isEmpty {
            self.data = nil
            self.expectedResponseLength = -1
            super.init()
            return
        }
        if rest.count == 1 {
            self.data = nil
            self.expectedResponseLength = _nfcDecodeLe(rest[rest.startIndex], extended: false)
            super.init()
            return
        }
        if rest.first == 0x00 {
            guard rest.count >= 3 else { return nil }
            let lcOrLeHigh = Int(rest[rest.startIndex + 1])
            let lcOrLeLow = Int(rest[rest.startIndex + 2])
            let extended = (lcOrLeHigh << 8) | lcOrLeLow
            if rest.count == 3 {
                self.data = nil
                self.expectedResponseLength = extended == 0 ? 65_536 : extended
                super.init()
                return
            }
            guard rest.count >= 3 + extended else { return nil }
            let payload = Data(rest.dropFirst(3).prefix(extended))
            let tail = rest.dropFirst(3 + extended)
            self.data = payload.isEmpty ? nil : payload
            if tail.isEmpty {
                self.expectedResponseLength = -1
            } else if tail.count == 2 {
                let le = (Int(tail[tail.startIndex]) << 8) | Int(tail[tail.startIndex + 1])
                self.expectedResponseLength = le == 0 ? 65_536 : le
            } else {
                return nil
            }
            super.init()
            return
        }
        let lc = Int(rest[rest.startIndex])
        let afterLc = rest.dropFirst(1)
        if afterLc.count == lc {
            self.data = lc == 0 ? nil : Data(afterLc)
            self.expectedResponseLength = -1
            super.init()
            return
        }
        if afterLc.count == lc + 1 {
            self.data = lc == 0 ? nil : Data(afterLc.prefix(lc))
            self.expectedResponseLength = _nfcDecodeLe(afterLc[afterLc.startIndex + lc], extended: false)
            super.init()
            return
        }
        return nil
    }
}

public struct NFCISO7816ResponseAPDU: Hashable, Sendable {
    public var payload: Data?
    public var statusWord1: UInt8
    public var statusWord2: UInt8

    public init(payload: Data?, statusWord1: UInt8, statusWord2: UInt8) {
        self.payload = payload
        self.statusWord1 = statusWord1
        self.statusWord2 = statusWord2
    }
}

private func _nfcDecodeLe(_ value: UInt8, extended: Bool) -> Int {
    if value == 0 {
        return extended ? 65_536 : 256
    }
    return Int(value)
}
