@_spi(OpenUIKitHost) import CoreBluetooth
import CoreFoundation
import Foundation

func testCBUUIDStringAndData() {
    let short = CBUUID(string: "180A")
    precondition(short.uuidString == "180A")
    precondition(short.data == Data([0x18, 0x0A]))
    precondition(CBUUID(data: short.data).uuidString == "180A")
    precondition(CBUUID(data: Data([0x0A, 0x18])).uuidString == "0A18")
    precondition(CBUUID(data: Data([0x0A, 0x18])) != short)

    let expanded = CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB")
    precondition(expanded.uuidString == "180A")
    precondition(expanded.data == Data([0x18, 0x0A]))
    precondition(short == expanded)

    let thirtyTwo = CBUUID(string: "0000180A")
    precondition(thirtyTwo.uuidString == "180A")
    let wide32 = CBUUID(string: "12345678")
    precondition(wide32.data == Data([0x12, 0x34, 0x56, 0x78]))
    precondition(wide32.uuidString == "12345678")
    precondition(CBUUID(data: wide32.data).uuidString == "12345678")

    let full = CBUUID(string: "ABCDEF01-2345-6789-ABCD-EF0123456789")
    precondition(full.data.count == 16)
    precondition(full.uuidString == "ABCDEF01-2345-6789-ABCD-EF0123456789")
    precondition(CBUUID(data: full.data).uuidString == full.uuidString)
    precondition(CBUUID(string: "ABCDEF0123456789ABCDEF0123456789").uuidString == full.uuidString)
    precondition(CBUUID(string: "180a").uuidString == "180A")
    precondition(CBUUID._hostData(fromString: "180A") == Data([0x18, 0x0A]))
    precondition(CBUUID._hostData(fromString: "ZZZZ") == nil)
    precondition(CBUUID._hostData(fromBytes: Data([0x18, 0x0A])) == Data([0x18, 0x0A]))
}

func testCBUUIDNSUUIDAndCFUUID() {
    let short = CBUUID(string: "180A")
    let nsuuid = UUID(uuidString: "0000180A-0000-1000-8000-00805F9B34FB")!
    precondition(CBUUID(nsuuid: nsuuid) == short)
    precondition(CBUUID(NSUUID: nsuuid) == short)

    let cf = CFUUIDCreateFromUUIDBytes(
        nil,
        CFUUIDBytes(
            byte0: 0x00, byte1: 0x00, byte2: 0x18, byte3: 0x0A,
            byte4: 0x00, byte5: 0x00, byte6: 0x10, byte7: 0x00,
            byte8: 0x80, byte9: 0x00, byte10: 0x00, byte11: 0x80,
            byte12: 0x5F, byte13: 0x9B, byte14: 0x34, byte15: 0xFB
        )
    )!
    precondition(CBUUID(cfuuid: cf) == short)
    precondition(CBUUID(CFUUID: cf) == short)
}
