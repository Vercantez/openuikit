import Foundation
import CoreNFC

func testNFCISO7816APDURoundTrip() {
    let apdu = NFCISO7816APDU(
        instructionClass: 0x00,
        instructionCode: 0xA4,
        p1Parameter: 0x04,
        p2Parameter: 0x00,
        data: Data([0x01, 0x02]),
        expectedResponseLength: 256
    )
    let bytes = apdu.encodedBytes()
    guard let parsed = NFCISO7816APDU(data: bytes) else {
        preconditionFailure("APDU parse")
    }
    precondition(parsed.instructionClass == 0x00)
    precondition(parsed.instructionCode == 0xA4)
    precondition(parsed.p1Parameter == 0x04)
    precondition(parsed.p2Parameter == 0x00)
    precondition(parsed.data == Data([0x01, 0x02]))
    precondition(parsed.expectedResponseLength == 256)
    precondition(NFCISO7816APDU(data: Data([0x00])) == nil)
}

func testNFCISO7816APDUProperties() {
    let noData = NFCISO7816APDU(
        instructionClass: 0x80,
        instructionCode: 0xCA,
        p1Parameter: 0x9F,
        p2Parameter: 0x7F,
        data: Data(),
        expectedResponseLength: 16
    )
    precondition(noData.data == nil)
    precondition(noData.expectedResponseLength == 16)
    guard let headerOnly = NFCISO7816APDU(data: Data([0x00, 0xA4, 0x04, 0x00])) else {
        preconditionFailure("header-only APDU")
    }
    precondition(headerOnly.expectedResponseLength == -1)
    precondition(headerOnly.data == nil)
    guard let leOnly = NFCISO7816APDU(data: Data([0x00, 0xB0, 0x00, 0x00, 0x00])) else {
        preconditionFailure("Le-only APDU")
    }
    precondition(leOnly.expectedResponseLength == 256)
}

func testNFCISO7816ResponseAPDU() {
    let ok = NFCISO7816ResponseAPDU(statusWord1: 0x90, statusWord2: 0x00, payload: nil)
    precondition(ok.statusWord1 == 0x90)
    precondition(ok.statusWord2 == 0x00)
    precondition(ok.payload == nil)
    let withPayload = NFCISO7816ResponseAPDU(
        statusWord1: 0x61,
        statusWord2: 0x10,
        payload: Data([0xAA])
    )
    precondition(withPayload.payload == Data([0xAA]))
    precondition(ok != withPayload)
}
