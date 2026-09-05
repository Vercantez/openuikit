import Foundation
import CoreNFC

func testNFCNDEFTextPayload() {
    let locale = Locale(identifier: "en-US")
    guard let text = NFCNDEFPayload.wellKnownTypeTextPayload(string: "hello", locale: locale) else {
        preconditionFailure("text payload factory")
    }
    precondition(text.typeNameFormat == .nfcWellKnown)
    precondition(text.type == Data([0x54]))
    precondition(text.identifier.isEmpty)
    let decoded = text.wellKnownTypeTextPayload()
    precondition(decoded.0 == "hello")
    precondition(decoded.1?.identifier.hasPrefix("en") == true || decoded.1?.language.languageCode?.identifier == "en")

    guard let typo = NFCNDEFPayload.wellKnowTypeTextPayload(string: "hello", locale: locale) else {
        preconditionFailure("historical text factory")
    }
    precondition(typo.payload == text.payload)
    precondition(text.wellKnownTypeURIPayload() == nil)
}

func testNFCNDEFURIPayload() {
    guard let uri = NFCNDEFPayload.wellKnownTypeURIPayload(string: "https://example.com/nfc") else {
        preconditionFailure("uri string factory")
    }
    precondition(uri.typeNameFormat == .nfcWellKnown)
    precondition(uri.type == Data([0x55]))
    precondition(uri.wellKnownTypeURIPayload()?.absoluteString == "https://example.com/nfc")

    guard let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(
        url: URL(string: "https://www.example.com/")!
    ) else {
        preconditionFailure("uri url factory")
    }
    precondition(urlPayload.payload.first == 2)
    precondition(urlPayload.wellKnownTypeURIPayload()?.absoluteString == "https://www.example.com/")
    precondition(NFCNDEFPayload.wellKnownTypeURIPayload(string: "") == nil)
    let empty = NFCNDEFPayload(format: .empty, type: Data(), identifier: Data(), payload: Data())
    precondition(empty.wellKnownTypeURIPayload() == nil)
    precondition(empty.wellKnownTypeTextPayload().0 == nil)
}

func testNFCNDEFPayloadProperties() {
    let identifier = Data([0x01, 0x02])
    let payload = NFCNDEFPayload(
        format: .media,
        type: Data("text/plain".utf8),
        identifier: identifier,
        payload: Data("body".utf8)
    )
    precondition(payload.typeNameFormat == .media)
    precondition(payload.type == Data("text/plain".utf8))
    precondition(payload.identifier == identifier)
    precondition(payload.payload == Data("body".utf8))
    precondition(payload.chunkSize == 0)

    let chunked = NFCNDEFPayload(
        format: .nfcExternal,
        type: Data([0x61]),
        identifier: Data(),
        payload: Data([0xFF]),
        chunkSize: 16
    )
    precondition(chunked.chunkSize == 16)
    precondition(chunked.typeNameFormat == .nfcExternal)
}

func testNFCNDEFMessageEncodeDecode() {
    let locale = Locale(identifier: "en")
    guard let text = NFCNDEFPayload.wellKnownTypeTextPayload(string: "hello", locale: locale) else {
        preconditionFailure("text")
    }
    guard let uri = NFCNDEFPayload.wellKnownTypeURIPayload(string: "https://example.com/nfc") else {
        preconditionFailure("uri")
    }
    let empty = NFCNDEFPayload(format: .empty, type: Data(), identifier: Data(), payload: Data())
    let message = NFCNDEFMessage(records: [text, uri, empty])
    precondition(message.records.count == 3)
    precondition(message.length > 0)
    let labeled = NFCNDEFMessage(NDEFRecords: [text])
    precondition(labeled.records.count == 1)

    let encoded = message.encodedData()
    guard let parsed = NFCNDEFMessage(data: encoded) else {
        preconditionFailure("message parse")
    }
    precondition(parsed.records.count == 3)
    precondition(parsed.records[0].wellKnownTypeTextPayload().0 == "hello")
    precondition(parsed.length == encoded.count)
    precondition(NFCNDEFMessage(data: Data()) == nil)
    let emptyMessage = NFCNDEFMessage(records: [])
    precondition(emptyMessage.length == 0)
}

func testNFCNDEFPayloadSecureCoding() {
    let payload = NFCNDEFPayload(
        format: .absoluteURI,
        type: Data([0x55]),
        identifier: Data([0x09]),
        payload: Data("urn:nfc:ok".utf8),
        chunkSize: 4
    )
    precondition(NFCNDEFPayload.supportsSecureCoding)
    let data = try! NSKeyedArchiver.archivedData(withRootObject: payload, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: NFCNDEFPayload.self, from: data)
    precondition(decoded?.typeNameFormat == .absoluteURI)
    precondition(decoded?.identifier == Data([0x09]))
    precondition(decoded?.chunkSize == 4)

    let message = NFCNDEFMessage(records: [payload])
    precondition(NFCNDEFMessage.supportsSecureCoding)
    let messageData = try! NSKeyedArchiver.archivedData(withRootObject: message, requiringSecureCoding: true)
    let decodedMessage = try! NSKeyedUnarchiver.unarchivedObject(ofClass: NFCNDEFMessage.self, from: messageData)
    precondition(decodedMessage?.records.count == 1)
    precondition(decodedMessage?.records[0].typeNameFormat == .absoluteURI)
}
