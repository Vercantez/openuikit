import Foundation

// MARK: - PIN format

/// PIN block layout used by secure PIN verify/change. Properties are
/// stored fields; ObjC zero-init defaults apply (enums 0, integers 0).
open class TKSmartCardPINFormat: NSObject {
    public var charset: TKSmartCardPINFormat.Charset = .numeric
    public var encoding: TKSmartCardPINFormat.Encoding = .binary
    public var minPINLength: Int = 0
    public var maxPINLength: Int = 0
    public var pinBlockByteLength: Int = 0
    public var pinJustification: TKSmartCardPINFormat.Justification = .left
    public var pinBitOffset: Int = 0
    public var pinLengthBitOffset: Int = 0
    public var pinLengthBitSize: Int = 0
}

// MARK: - ATR (ISO/IEC 7816-3)

/// One interface-byte group (TAi/TBi/TCi and the T protocol from TDi).
open class TKSmartCardATRInterfaceGroup: NSObject {
    public let ta: NSNumber?
    public let tb: NSNumber?
    public let tc: NSNumber?
    public let `protocol`: NSNumber?

    init(ta: NSNumber?, tb: NSNumber?, tc: NSNumber?, protocol protocolNumber: NSNumber?) {
        self.ta = ta
        self.tb = tb
        self.tc = tc
        self.protocol = protocolNumber
        super.init()
    }
}

private struct TKParsedATR {
    var bytes: Data
    var historicalBytes: Data
    var protocols: [NSNumber]
    var groups: [TKSmartCardATRInterfaceGroup]
}

private func tkParseATR(_ data: Data) -> TKParsedATR? {
    let bytes = [UInt8](data)
    guard bytes.count >= 2 else { return nil }
    let ts = bytes[0]
    guard ts == 0x3B || ts == 0x3F else { return nil }
    let t0 = bytes[1]
    let historicalCount = Int(t0 & 0x0F)
    var offset = 2
    var y = t0 >> 4
    var groups: [TKSmartCardATRInterfaceGroup] = []
    var protocolNumbers: [UInt8] = []
    var sawNonT0 = false

    while y != 0 {
        var ta: NSNumber?
        var tb: NSNumber?
        var tc: NSNumber?
        if y & 0x01 != 0 {
            guard offset < bytes.count else { return nil }
            ta = NSNumber(value: bytes[offset])
            offset += 1
        }
        if y & 0x02 != 0 {
            guard offset < bytes.count else { return nil }
            tb = NSNumber(value: bytes[offset])
            offset += 1
        }
        if y & 0x04 != 0 {
            guard offset < bytes.count else { return nil }
            tc = NSNumber(value: bytes[offset])
            offset += 1
        }
        var protocolNumber: NSNumber?
        if y & 0x08 != 0 {
            guard offset < bytes.count else { return nil }
            let td = bytes[offset]
            offset += 1
            let t = td & 0x0F
            protocolNumber = NSNumber(value: t)
            protocolNumbers.append(t)
            if t != 0 {
                sawNonT0 = true
            }
            y = td >> 4
        } else {
            y = 0
        }
        groups.append(
            TKSmartCardATRInterfaceGroup(ta: ta, tb: tb, tc: tc, protocol: protocolNumber)
        )
        if groups.count > 16 {
            return nil
        }
    }

    if protocolNumbers.isEmpty {
        protocolNumbers = [0]
    }
    guard offset + historicalCount <= bytes.count else { return nil }
    let historical = Data(bytes[offset..<(offset + historicalCount)])
    offset += historicalCount
        if sawNonT0 {
        guard offset < bytes.count else { return nil }
        offset += 1
        guard offset == bytes.count else { return nil }
    } else if offset < bytes.count {
        guard offset + 1 == bytes.count else { return nil }
        offset += 1
    }
    let protocolNS = protocolNumbers.map { NSNumber(value: $0) }
    return TKParsedATR(
        bytes: Data(bytes.prefix(offset)),
        historicalBytes: historical,
        protocols: protocolNS,
        groups: groups
    )
}

private func tkATRIsComplete(_ data: Data) -> Bool {
    tkParseATR(data) != nil
}

/// Answer-to-Reset parser. `init?(bytes:)` rejects a TS other than 0x3B/0x3F
/// or a truncated interface/historical field.
open class TKSmartCardATR: NSObject {
    public typealias InterfaceGroup = TKSmartCardATRInterfaceGroup

    public let bytes: Data
    public let historicalBytes: Data
    public let protocols: [NSNumber]
    public let historicalRecords: [TKCompactTLVRecord]?
    private let groups: [TKSmartCardATRInterfaceGroup]

    public init?(bytes: Data) {
        guard let parsed = tkParseATR(bytes) else { return nil }
        self.bytes = parsed.bytes
        self.historicalBytes = parsed.historicalBytes
        self.protocols = parsed.protocols
        self.groups = parsed.groups
        if let compact = TKTLVCodec.parseCompactSequence(parsed.historicalBytes) {
            self.historicalRecords = compact.map { item in
                TKCompactTLVRecord(tag: UInt8(truncatingIfNeeded: item.tag), value: item.value)
            }
        } else if parsed.historicalBytes.count > 1,
                  let compact = TKTLVCodec.parseCompactSequence(parsed.historicalBytes.dropFirst()) {
            self.historicalRecords = compact.map { item in
                TKCompactTLVRecord(tag: UInt8(truncatingIfNeeded: item.tag), value: item.value)
            }
        } else {
            self.historicalRecords = nil
        }
        super.init()
    }

    public init?(source: @escaping () -> Int32) {
        var collected = Data()
        for _ in 0..<33 {
            let next = source()
            if next < 0 {
                break
            }
            collected.append(UInt8(truncatingIfNeeded: UInt32(bitPattern: next)))
            if tkATRIsComplete(collected) {
                break
            }
        }
        guard let parsed = tkParseATR(collected) else { return nil }
        self.bytes = parsed.bytes
        self.historicalBytes = parsed.historicalBytes
        self.protocols = parsed.protocols
        self.groups = parsed.groups
        if let compact = TKTLVCodec.parseCompactSequence(parsed.historicalBytes) {
            self.historicalRecords = compact.map { item in
                TKCompactTLVRecord(tag: UInt8(truncatingIfNeeded: item.tag), value: item.value)
            }
        } else {
            self.historicalRecords = nil
        }
        super.init()
    }

    /// Interface groups are 1-based, matching Apple's `interfaceGroupAtIndex:`.
    public func interfaceGroup(at index: Int) -> TKSmartCardATR.InterfaceGroup? {
        guard index >= 1, index <= groups.count else { return nil }
        return groups[index - 1]
    }

    public func interfaceGroup(for protocol: TKSmartCardProtocol) -> TKSmartCardATR.InterfaceGroup? {
        let wanted: UInt8?
        if `protocol` == .t0 {
            wanted = 0
        } else if `protocol` == .t1 {
            wanted = 1
        } else if `protocol` == .t15 {
            wanted = 15
        } else {
            return groups.first
        }
        return groups.first { group in
            group.protocol?.uint8Value == wanted
        }
    }
}

// MARK: - Slot / manager / NFC

open class TKSmartCardSlot: NSObject {
    public let name: String
    public private(set) var state: TKSmartCardSlot.State
    public private(set) var atr: TKSmartCardATR?
    public let maxInputLength: Int
    public let maxOutputLength: Int

    public override init() {
        self.name = ""
        self.state = .missing
        self.atr = nil
        self.maxInputLength = 0
        self.maxOutputLength = 0
        super.init()
    }

    public init(name: String, state: TKSmartCardSlot.State = .missing) {
        self.name = name
        self.state = state
        self.atr = nil
        self.maxInputLength = 0
        self.maxOutputLength = 0
        super.init()
    }

    public func makeSmartCard() -> TKSmartCard? {
        // No reader hardware on Linux.
        nil
    }
}

open class TKSmartCardSlotManager: NSObject {
    public static let `default`: TKSmartCardSlotManager? = TKSmartCardSlotManager()

    public var slotNames: [String] { [] }

    public func slotNamed(_ name: String) -> TKSmartCardSlot? {
        _ = name
        return nil
    }

    public func getSlot(withName name: String) async -> TKSmartCardSlot? {
        slotNamed(name)
    }

    public func isNFCSupported() -> Bool {
        false
    }

    public func createNFCSlot(message: String?) async throws -> TKSmartCardSlotNFCSession {
        _ = message
        throw tkMakeError(.notImplemented, reason: "NFC smart-card slot requires Apple NFC hardware")
    }
}

open class TKSmartCardSlotNFCSession: NSObject {
    public private(set) var slotName: String?
    private var ended = false

    public override init() {
        self.slotName = nil
        super.init()
    }

    public func update(message: String) throws {
        _ = message
        throw tkMakeError(.notImplemented, reason: "NFC slot UI requires the system NFC sheet")
    }

    public func end() {
        ended = true
        slotName = nil
    }
}

// MARK: - Smart card

open class TKSmartCard: NSObject {
    public let slot: TKSmartCardSlot
    public private(set) var isValid: Bool = false
    public var allowedProtocols: TKSmartCardProtocol = []
    public private(set) var currentProtocol: TKSmartCardProtocol = []
    public var isSensitive: Bool = false
    public var context: Any?
    public var cla: UInt8 = 0
    public var useExtendedLength: Bool = false
    public var useCommandChaining: Bool = false
    private var sessionOpen = false

    public override init() {
        self.slot = TKSmartCardSlot()
        super.init()
    }

    public init(slot: TKSmartCardSlot) {
        self.slot = slot
        super.init()
    }

    public func beginSession(reply: @escaping (Bool, (any Error)?) -> Void) {
        reply(false, tkMakeError(.communicationError, reason: "no smart-card reader on Linux"))
    }

    public func endSession() {
        sessionOpen = false
        isValid = false
        currentProtocol = []
        if isSensitive {
            context = nil
        }
    }

    public func transmit(_ request: Data) async throws -> Data {
        _ = request
        throw tkMakeError(.communicationError, reason: "no smart-card reader on Linux")
    }

    public func userInteractionForSecurePINChange(
        _ PINFormat: TKSmartCardPINFormat,
        apdu APDU: Data,
        currentPINByteOffset: Int,
        newPINByteOffset: Int
    ) -> TKSmartCardUserInteractionForSecurePINChange? {
        _ = (PINFormat, APDU, currentPINByteOffset, newPINByteOffset)
        return nil
    }

    public func userInteractionForSecurePINVerification(
        _ PINFormat: TKSmartCardPINFormat,
        apdu APDU: Data,
        pinByteOffset PINByteOffset: Int
    ) -> TKSmartCardUserInteractionForSecurePINVerification? {
        _ = (PINFormat, APDU, PINByteOffset)
        return nil
    }

    public func withSession<T>(_ body: @escaping () throws -> T) throws -> T {
        _ = body
        throw tkMakeError(.communicationError, reason: "no smart-card session on Linux")
    }

    public func send(
        ins: UInt8,
        p1: UInt8,
        p2: UInt8,
        data: Data? = nil,
        le: Int? = nil,
        reply: @escaping (Data?, UInt16, (any Error)?) -> Void
    ) {
        _ = (ins, p1, p2, data, le)
        reply(nil, 0, tkMakeError(.communicationError, reason: "no smart-card reader on Linux"))
    }

    public func send(
        ins: UInt8,
        p1: UInt8,
        p2: UInt8,
        data: Data? = nil,
        le: Int? = nil
    ) throws -> (sw: UInt16, response: Data) {
        _ = (ins, p1, p2, data, le)
        throw tkMakeError(.communicationError, reason: "no smart-card reader on Linux")
    }
}

// MARK: - User interaction

public protocol TKSmartCardUserInteractionDelegate: AnyObject {
    func characterEntered(in interaction: TKSmartCardUserInteraction)
    func correctionKeyPressed(in interaction: TKSmartCardUserInteraction)
    func invalidCharacterEntered(in interaction: TKSmartCardUserInteraction)
    func newPINConfirmationRequested(in interaction: TKSmartCardUserInteraction)
    func newPINRequested(in interaction: TKSmartCardUserInteraction)
    func oldPINRequested(in interaction: TKSmartCardUserInteraction)
    func validationKeyPressed(in interaction: TKSmartCardUserInteraction)
}

public extension TKSmartCardUserInteractionDelegate {
    func characterEntered(in interaction: TKSmartCardUserInteraction) {}
    func correctionKeyPressed(in interaction: TKSmartCardUserInteraction) {}
    func invalidCharacterEntered(in interaction: TKSmartCardUserInteraction) {}
    func newPINConfirmationRequested(in interaction: TKSmartCardUserInteraction) {}
    func newPINRequested(in interaction: TKSmartCardUserInteraction) {}
    func oldPINRequested(in interaction: TKSmartCardUserInteraction) {}
    func validationKeyPressed(in interaction: TKSmartCardUserInteraction) {}
}

open class TKSmartCardUserInteraction: NSObject {
    public weak var delegate: (any TKSmartCardUserInteractionDelegate)?
    public var initialTimeout: TimeInterval = 0
    public var interactionTimeout: TimeInterval = 0
    private var running = false

    public func cancel() -> Bool {
        if running {
            running = false
            return true
        }
        return false
    }

    public func run(reply: @escaping (Bool, (any Error)?) -> Void) {
        running = false
        reply(false, tkMakeError(.notImplemented, reason: "PIN pad / user interaction requires reader hardware"))
    }
}

open class TKSmartCardUserInteractionForPINOperation: TKSmartCardUserInteraction {
    public var pinCompletion: TKSmartCardUserInteractionForPINOperation.Completion = []
    public var pinMessageIndices: [NSNumber]?
    public var locale: Locale! = Locale.current
    public var resultData: Data?
    public var resultSW: UInt16 = 0
}

open class TKSmartCardUserInteractionForSecurePINChange: TKSmartCardUserInteractionForPINOperation {
    public var pinConfirmation: TKSmartCardUserInteractionForSecurePINChange.Confirmation = []
}

open class TKSmartCardUserInteractionForSecurePINVerification: TKSmartCardUserInteractionForPINOperation {}
