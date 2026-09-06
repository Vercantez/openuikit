import Foundation

public enum MTRCommissioningFlow: UInt, Sendable, Hashable {
    case standard = 0
    case userActionRequired = 1
    case custom = 2
    case invalid = 3
}

public struct MTRDiscoveryCapabilities: OptionSet, Sendable, Hashable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let softAP = MTRDiscoveryCapabilities(rawValue: 1 << 0)
    public static let BLE = MTRDiscoveryCapabilities(rawValue: 1 << 1)
    public static let onNetwork = MTRDiscoveryCapabilities(rawValue: 1 << 2)
    public static let allMask: MTRDiscoveryCapabilities = [.softAP, .BLE, .onNetwork]
}

public enum MTROptionalQRCodeInfoType: UInt, Sendable, Hashable {
    case unknown = 0
    case string = 1
    case int32 = 2
}

public final class MTROptionalQRCodeInfo: NSObject {
    public private(set) var type: MTROptionalQRCodeInfoType
    public private(set) var tag: NSNumber
    public private(set) var integerValue: NSNumber?
    public private(set) var stringValue: String?

    public override init() {
        self.type = .unknown
        self.tag = NSNumber(value: 0)
        super.init()
    }

    public init(tag: NSNumber, stringValue: String) {
        self.type = .string
        self.tag = tag
        self.stringValue = stringValue
        self.integerValue = nil
        super.init()
    }

    public init(tag: NSNumber, int32Value: Int32) {
        self.type = .int32
        self.tag = tag
        self.integerValue = NSNumber(value: int32Value)
        self.stringValue = nil
        super.init()
    }

    public var infoType: NSNumber {
        get { NSNumber(value: type.rawValue) }
        set { /* immutable after iOS 17.6 */ }
    }

    public func setType(_ type: MTROptionalQRCodeInfoType) { _ = type }
    public func setTag(_ tag: NSNumber) { _ = tag }
    public func setIntegerValue(_ integerValue: NSNumber) { _ = integerValue }
    public func setStringValue(_ stringValue: String) { _ = stringValue }
}

public final class MTRSetupPayload: NSObject {
    public var version: NSNumber
    public var vendorID: NSNumber
    public var productID: NSNumber
    public var commissioningFlow: MTRCommissioningFlow
    public var discoveryCapabilities: MTRDiscoveryCapabilities
    public var discriminator: NSNumber
    public var hasShortDiscriminator: Bool
    public var setupPasscode: NSNumber
    public var serialNumber: String?
    private var vendorByTag: [UInt8: MTROptionalQRCodeInfo] = [:]

    public var vendorElements: [MTROptionalQRCodeInfo] {
        vendorByTag.keys.sorted().compactMap { vendorByTag[$0] }
    }

    public var rendezvousInformation: NSNumber? {
        get {
            discoveryCapabilities.rawValue == 0 ? nil : NSNumber(value: discoveryCapabilities.rawValue)
        }
        set {
            if let newValue {
                discoveryCapabilities = MTRDiscoveryCapabilities(rawValue: newValue.uintValue)
            } else {
                discoveryCapabilities = []
            }
        }
    }

    public var setUpPINCode: NSNumber {
        get { setupPasscode }
        set { setupPasscode = newValue }
    }

    public override init() {
        version = 0
        vendorID = 0
        productID = 0
        commissioningFlow = .standard
        discoveryCapabilities = []
        discriminator = 0
        hasShortDiscriminator = false
        setupPasscode = 0
        super.init()
    }

    public init(setupPasscode: NSNumber, discriminator: NSNumber) {
        self.version = 0
        self.vendorID = 0
        self.productID = 0
        self.commissioningFlow = .standard
        self.discoveryCapabilities = []
        self.discriminator = discriminator
        self.hasShortDiscriminator = discriminator.uintValue <= 0xF
        self.setupPasscode = setupPasscode
        super.init()
    }

    public convenience init?(payload: String) {
        do {
            let parsed = try MTRSetupPayload.parseOnboarding(payload)
            self.init(setupPasscode: parsed.setupPasscode, discriminator: parsed.discriminator)
            self.version = parsed.version
            self.vendorID = parsed.vendorID
            self.productID = parsed.productID
            self.commissioningFlow = parsed.commissioningFlow
            self.discoveryCapabilities = parsed.discoveryCapabilities
            self.hasShortDiscriminator = parsed.hasShortDiscriminator
            self.serialNumber = parsed.serialNumber
            self.vendorByTag = parsed.vendorByTag
        } catch {
            return nil
        }
    }

    public convenience init(onboardingPayload: String) throws {
        guard let parsed = MTRSetupPayload(payload: onboardingPayload) else {
            throw MTRMakeError(.invalidArgument, reason: "invalid onboarding payload")
        }
        self.init(setupPasscode: parsed.setupPasscode, discriminator: parsed.discriminator)
        self.version = parsed.version
        self.vendorID = parsed.vendorID
        self.productID = parsed.productID
        self.commissioningFlow = parsed.commissioningFlow
        self.discoveryCapabilities = parsed.discoveryCapabilities
        self.hasShortDiscriminator = parsed.hasShortDiscriminator
        self.serialNumber = parsed.serialNumber
        self.vendorByTag = parsed.vendorByTag
        self.setupPasscode = parsed.setupPasscode
        self.discriminator = parsed.discriminator
    }

    public class func setupPayload(forOnboardingPayload onboardingPayload: String) throws -> MTRSetupPayload {
        try MTRSetupPayload(onboardingPayload: onboardingPayload)
    }

    public class func `new`() -> MTRSetupPayload {
        MTRSetupPayload()
    }

    public class func isValidSetupPasscode(_ setupPasscode: NSNumber) -> Bool {
        MTRPasscode.isValid(setupPasscode.uint32Value)
    }

    public class func generateRandomSetupPasscode() -> NSNumber {
        mtrPasscodeSeed = mtrPasscodeSeed &* 1_664_525 &+ 1_013_904_223
        if mtrPasscodeSeed == 0 { mtrPasscodeSeed = 1 }
        for _ in 0..<64 {
            mtrPasscodeSeed = mtrPasscodeSeed &* 1_664_525 &+ 1_013_904_223
            let candidate = 1 + (mtrPasscodeSeed % 99_999_998)
            if MTRPasscode.isValid(candidate) {
                return NSNumber(value: candidate)
            }
        }
        return NSNumber(value: 20_202_021)
    }

    public class func generateRandomPIN() -> Int {
        generateRandomSetupPasscode().intValue
    }

    public func addOrReplaceVendorElement(_ element: MTROptionalQRCodeInfo) {
        vendorByTag[element.tag.uint8Value] = element
    }

    public func removeVendorElement(withTag tag: NSNumber) {
        vendorByTag.removeValue(forKey: tag.uint8Value)
    }

    public func vendorElement(withTag tag: NSNumber) -> MTROptionalQRCodeInfo? {
        vendorByTag[tag.uint8Value]
    }

    public func getAllOptionalVendorData() throws -> [MTROptionalQRCodeInfo] {
        vendorElements
    }

    public func manualEntryCode() -> String? {
        MTRManualCode.encode(self)
    }

    public func qrCodeString() -> String? {
        MTRQRCode.encode(self)
    }

    public func qrCodeString(_ error: UnsafeMutablePointer<NSError?>?) -> String? {
        guard let qr = qrCodeString() else {
            error?.pointee = MTRFailClosed(.invalidArgument) as NSError
            return nil
        }
        return qr
    }

    fileprivate static func parseOnboarding(_ payload: String) throws -> MTRSetupPayload {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.uppercased().hasPrefix("MT:") {
            return try MTRQRCode.decode(trimmed)
        }
        if let decoded = MTRManualCode.decode(trimmed) {
            return decoded
        }
        MTREmitLog(.error, "unrecognized onboarding payload")
        throw MTRMakeError(.invalidArgument, reason: "unrecognized onboarding payload")
    }
}

public final class MTRManualSetupPayloadParser: NSObject {
    private let decimalString: String
    public init(decimalStringRepresentation: String) {
        self.decimalString = decimalStringRepresentation
        super.init()
    }

    public func populatePayload() throws -> MTRSetupPayload {
        guard let payload = MTRManualCode.decode(decimalString) else {
            throw MTRMakeError(.invalidArgument, reason: "invalid manual pairing code")
        }
        return payload
    }
}

public final class MTRQRCodeSetupPayloadParser: NSObject {
    private let qr: String
    public init(base38Representation: String) {
        self.qr = base38Representation
        super.init()
    }

    public func populatePayload() throws -> MTRSetupPayload {
        try MTRQRCode.decode(qr)
    }
}

public final class MTROnboardingPayloadParser: NSObject {
    public class func setupPayload(forOnboardingPayload onboardingPayload: String) throws -> MTRSetupPayload {
        try MTRSetupPayload(onboardingPayload: onboardingPayload)
    }
}

private var mtrPasscodeSeed: UInt32 = 0xC0FF_EE11

enum MTRPasscode {
    static let invalid: Set<UInt32> = [
        0, 11_111_111, 22_222_222, 33_333_333, 44_444_444, 55_555_555,
        66_666_666, 77_777_777, 88_888_888, 99_999_999, 12_345_678, 87_654_321,
    ]

    static func isValid(_ value: UInt32) -> Bool {
        value >= 1 && value <= 99_999_998 && !invalid.contains(value)
    }
}

enum MTRVerhoeff10 {
    private static let op: [[Int]] = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
        [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
        [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
        [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
        [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
        [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
        [7, 8, 5, 9, 6, 2, 1, 0, 4, 3],
        [8, 6, 7, 5, 9, 3, 2, 1, 0, 4],
        [9, 7, 6, 5, 8, 4, 3, 2, 1, 0],
    ]
    private static let perm: [[Int]] = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
        [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
        [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
        [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
        [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
        [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
        [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
    ]
    private static let inv = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9]

    static func checkDigit(_ digits: String) -> Int {
        var checksum = 0
        let chars = Array(digits)
        for i in 0..<chars.count {
            let c = chars[chars.count - 1 - i]
            guard let d = c.wholeNumberValue else { return 0 }
            checksum = op[checksum][perm[i % 8][d]]
        }
        return inv[checksum]
    }

    static func validate(_ digits: String) -> Bool {
        guard let last = digits.last, let d = last.wholeNumberValue else { return false }
        return checkDigit(String(digits.dropLast())) == d
    }
}

enum MTRManualCode {
    static func encode(_ payload: MTRSetupPayload) -> String? {
        guard MTRPasscode.isValid(payload.setupPasscode.uint32Value) else { return nil }
        let shortDisc: UInt32
        if payload.hasShortDiscriminator {
            shortDisc = payload.discriminator.uint32Value & 0xF
        } else {
            shortDisc = (payload.discriminator.uint32Value >> 8) & 0xF
        }
        let vidPid = payload.commissioningFlow != .standard
        let chunk1 = ((shortDisc >> 2) & 0x3) | ((vidPid ? 1 : 0) << 2)
        let pin = payload.setupPasscode.uint32Value
        let chunk2 = (pin & 0x3FFF) | (((shortDisc & 0x3) << 14))
        let chunk3 = (pin >> 14) & 0x1FFF
        var body = String(format: "%01u%05u%04u", chunk1, chunk2, chunk3)
        if vidPid {
            body += String(format: "%05u%05u", payload.vendorID.uintValue, payload.productID.uintValue)
        }
        let check = MTRVerhoeff10.checkDigit(body)
        return body + String(check)
    }

    static func decode(_ code: String) -> MTRSetupPayload? {
        let digits = code.filter(\.isNumber)
        guard digits.count == 11 || digits.count == 21 else { return nil }
        guard MTRVerhoeff10.validate(digits) else { return nil }
        let body = String(digits.dropLast())
        guard let chunk1 = UInt32(body.prefix(1)),
              let chunk2 = UInt32(body.dropFirst(1).prefix(5)),
              let chunk3 = UInt32(body.dropFirst(6).prefix(4))
        else { return nil }
        let vidPid = ((chunk1 >> 2) & 1) != 0
        let discMs = chunk1 & 0x3
        let discLs = (chunk2 >> 14) & 0x3
        let shortDisc = (discMs << 2) | discLs
        let pinLs = chunk2 & 0x3FFF
        let pinMs = chunk3 & 0x1FFF
        let pin = pinLs | (pinMs << 14)
        guard MTRPasscode.isValid(pin) else { return nil }
        let payload = MTRSetupPayload(
            setupPasscode: NSNumber(value: pin),
            discriminator: NSNumber(value: shortDisc)
        )
        payload.hasShortDiscriminator = true
        payload.discoveryCapabilities = []
        if vidPid {
            guard digits.count == 21,
                  let vendor = UInt32(body.dropFirst(10).prefix(5)),
                  let product = UInt32(body.dropFirst(15).prefix(5))
            else { return nil }
            payload.vendorID = NSNumber(value: vendor)
            payload.productID = NSNumber(value: product)
            payload.commissioningFlow = .userActionRequired
        }
        return payload
    }
}

enum MTRQRCode {
    static let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-.")
    static let totalBits = 88

    static func encode(_ payload: MTRSetupPayload) -> String? {
        guard MTRPasscode.isValid(payload.setupPasscode.uint32Value) else { return nil }
        guard !payload.hasShortDiscriminator else { return nil }
        guard payload.discoveryCapabilities.rawValue != 0 else { return nil }
        var bits = [UInt8](repeating: 0, count: 11)
        var offset = 0
        func put(_ value: UInt64, _ width: Int) {
            var input = value
            var index = offset
            offset += width
            while input != 0 {
                if input & 1 != 0 {
                    bits[index / 8] |= UInt8(1 << (index % 8))
                }
                index += 1
                input >>= 1
            }
        }
        put(payload.version.uint64Value, 3)
        put(payload.vendorID.uint64Value, 16)
        put(payload.productID.uint64Value, 16)
        put(UInt64(payload.commissioningFlow.rawValue), 2)
        put(UInt64(payload.discoveryCapabilities.rawValue), 8)
        put(payload.discriminator.uint64Value, 12)
        put(payload.setupPasscode.uint64Value, 27)
        put(0, 4)
        return "MT:" + base38Encode(bits)
    }

    static func decode(_ qr: String) throws -> MTRSetupPayload {
        var s = qr.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.uppercased().hasPrefix("MT:") {
            s = String(s.dropFirst(3))
        }
        guard let bits = base38Decode(s), bits.count >= 11 else {
            throw MTRMakeError(.invalidArgument, reason: "invalid QR payload")
        }
        var offset = 0
        func take(_ width: Int) -> UInt64 {
            var result: UInt64 = 0
            var shift = 0
            for i in 0..<width {
                let bitIndex = offset + i
                let byte = bits[bitIndex / 8]
                if (byte & UInt8(1 << (bitIndex % 8))) != 0 {
                    result |= 1 << shift
                }
                shift += 1
            }
            offset += width
            return result
        }
        let version = take(3)
        let vendor = take(16)
        let product = take(16)
        let flowRaw = take(2)
        let caps = take(8)
        let disc = take(12)
        let pin = take(27)
        _ = take(4)
        guard MTRPasscode.isValid(UInt32(pin)) else {
            throw MTRMakeError(.invalidIntegerValue, reason: "invalid setup passcode")
        }
        let payload = MTRSetupPayload(
            setupPasscode: NSNumber(value: pin),
            discriminator: NSNumber(value: disc)
        )
        payload.version = NSNumber(value: version)
        payload.vendorID = NSNumber(value: vendor)
        payload.productID = NSNumber(value: product)
        payload.commissioningFlow = MTRCommissioningFlow(rawValue: UInt(flowRaw)) ?? .standard
        payload.discoveryCapabilities = MTRDiscoveryCapabilities(rawValue: UInt(caps))
        payload.hasShortDiscriminator = false
        return payload
    }

    static func base38Encode(_ bytes: [UInt8]) -> String {
        var out = ""
        var i = 0
        while i < bytes.count {
            if i + 2 < bytes.count {
                let value = UInt32(bytes[i]) | (UInt32(bytes[i + 1]) << 8) | (UInt32(bytes[i + 2]) << 16)
                out.append(charset[Int(value % 38)])
                var rest = value / 38
                out.append(charset[Int(rest % 38)])
                rest /= 38
                out.append(charset[Int(rest % 38)])
                rest /= 38
                out.append(charset[Int(rest % 38)])
                rest /= 38
                out.append(charset[Int(rest)])
                i += 3
            } else if i + 1 < bytes.count {
                let value = UInt32(bytes[i]) | (UInt32(bytes[i + 1]) << 8)
                out.append(charset[Int(value % 38)])
                var rest = value / 38
                out.append(charset[Int(rest % 38)])
                rest /= 38
                out.append(charset[Int(rest)])
                i += 2
            } else {
                let value = UInt32(bytes[i])
                out.append(charset[Int(value % 38)])
                out.append(charset[Int(value / 38)])
                i += 1
            }
        }
        return out
    }

    static func base38Decode(_ encoded: String) -> [UInt8]? {
        var map = [Character: Int]()
        for (idx, ch) in charset.enumerated() { map[ch] = idx }
        let chars = Array(encoded)
        var bytes: [UInt8] = []
        var i = 0
        while i < chars.count {
            func val(_ n: Int) -> Int? { map[chars[n]] }
            if i + 4 < chars.count {
                guard let a = val(i), let b = val(i + 1), let c = val(i + 2), let d = val(i + 3), let e = val(i + 4) else {
                    return nil
                }
                var value = a
                value += b * 38
                value += c * 38 * 38
                value += d * 38 * 38 * 38
                value += e * 38 * 38 * 38 * 38
                bytes.append(UInt8(value & 0xFF))
                bytes.append(UInt8((value >> 8) & 0xFF))
                bytes.append(UInt8((value >> 16) & 0xFF))
                i += 5
            } else if i + 2 < chars.count {
                guard let a = val(i), let b = val(i + 1), let c = val(i + 2) else { return nil }
                var value = a
                value += b * 38
                value += c * 38 * 38
                bytes.append(UInt8(value & 0xFF))
                bytes.append(UInt8((value >> 8) & 0xFF))
                i += 3
            } else if i + 1 < chars.count {
                guard let a = val(i), let b = val(i + 1) else { return nil }
                let value = a + b * 38
                bytes.append(UInt8(value & 0xFF))
                i += 2
            } else {
                return nil
            }
        }
        return bytes
    }
}
