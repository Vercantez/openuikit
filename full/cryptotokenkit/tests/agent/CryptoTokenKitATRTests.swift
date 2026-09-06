import Foundation
import CryptoTokenKit

private func tkMust(_ condition: Bool, _ message: String) {
    if !condition {
        preconditionFailure(message)
    }
}

func testTKSmartCardATRDirectConvention() {
    // TS=3B, T0=90 (TA1+TD1, K=0), TA1=11, TD1=00 (T=0)
    let bytes = Data([0x3B, 0x90, 0x11, 0x00])
    guard let atr = TKSmartCardATR(bytes: bytes) else {
        preconditionFailure("ATR parse")
    }
    tkMust(atr.bytes == bytes, "bytes")
    tkMust(atr.historicalBytes.isEmpty, "no historical")
    tkMust(atr.protocols.map(\.uint8Value) == [0], "T=0")
    guard let group = atr.interfaceGroup(at: 1) else {
        preconditionFailure("group 1")
    }
    tkMust(group.ta?.uint8Value == 0x11, "TA1")
    tkMust(group.tb == nil, "TB1")
    tkMust(group.tc == nil, "TC1")
    tkMust(group.protocol?.uint8Value == 0, "TD1 T=0")
    tkMust(atr.interfaceGroup(at: 0) == nil, "index 0")
    tkMust(atr.interfaceGroup(for: .t0) != nil, "for t0")
}

func testTKSmartCardATRHistoricalBytes() {
    // TS=3B, T0=02 (K=2 historical, no interface bytes)
    let bytes = Data([0x3B, 0x02, 0x51, 0x01])
    guard let atr = TKSmartCardATR(bytes: bytes) else {
        preconditionFailure("ATR parse")
    }
    tkMust(atr.historicalBytes == Data([0x51, 0x01]), "historical")
    tkMust(atr.protocols.map(\.uint8Value) == [0], "implied T=0")
    tkMust(atr.historicalRecords?.count == 1, "compact historical")
    tkMust(atr.historicalRecords?[0].tag == 0x05, "compact tag")
    tkMust(atr.historicalRecords?[0].value == Data([0x01]), "compact value")
}

func testTKSmartCardATRSource() {
    let payload: [Int32] = [0x3B, 0x90, 0x11, 0x00]
    var index = 0
    guard let atr = TKSmartCardATR(source: {
        if index >= payload.count {
            return -1
        }
        let value = payload[index]
        index += 1
        return value
    }) else {
        preconditionFailure("source ATR")
    }
    tkMust(atr.bytes == Data([0x3B, 0x90, 0x11, 0x00]), "bytes")
}

func testTKSmartCardATRRejectsInvalid() {
    tkMust(TKSmartCardATR(bytes: Data([0x00, 0x00])) == nil, "bad TS")
    tkMust(TKSmartCardATR(bytes: Data([0x3B])) == nil, "truncated")
    tkMust(TKSmartCardATR(bytes: Data([0x3F, 0x90])) == nil, "missing TA1/TD1")
}

func testTKSmartCardATRT1Protocol() {
    // TS=3B T0=80 (TD1 only) TD1=01 (T=1, no further)
    let bytes = Data([0x3B, 0x80, 0x01, 0x7C])
    guard let atr = TKSmartCardATR(bytes: bytes) else {
        preconditionFailure("T=1 ATR")
    }
    tkMust(atr.protocols.map(\.uint8Value) == [1], "T=1")
    tkMust(atr.interfaceGroup(for: .t1)?.protocol?.uint8Value == 1, "group for t1")
}
