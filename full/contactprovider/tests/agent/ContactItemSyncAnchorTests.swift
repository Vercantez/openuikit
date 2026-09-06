import Foundation
import ContactProvider

func testSyncAnchorType() {
    let anchor = ContactItemSyncAnchor(generationMarker: Data([0x01]), offset: 1)
    precondition(type(of: anchor) == ContactItemSyncAnchor.self)
}

func testSyncAnchorInit() {
    let marker = Data([0x11, 0x22])
    let anchor = ContactItemSyncAnchor(generationMarker: marker, offset: 8)
    precondition(anchor.generationMarker == marker)
    precondition(anchor.offset == 8)
}

func testSyncAnchorGenerationMarker() {
    var anchor = ContactItemSyncAnchor(generationMarker: Data([0x30]), offset: 0)
    precondition(anchor.generationMarker == Data([0x30]))
    anchor.generationMarker = Data([0x31])
    precondition(anchor.generationMarker == Data([0x31]))
}

func testSyncAnchorOffset() {
    var anchor = ContactItemSyncAnchor(generationMarker: Data(), offset: 5)
    precondition(anchor.offset == 5)
    anchor.offset = 15
    precondition(anchor.offset == 15)
}

func testSyncAnchorEquality() {
    let marker = Data("sync".utf8)
    let left = ContactItemSyncAnchor(generationMarker: marker, offset: 1)
    let right = ContactItemSyncAnchor(generationMarker: marker, offset: 1)
    precondition(left == right)
    precondition(left != ContactItemSyncAnchor(generationMarker: marker, offset: 2))
}

func testSyncAnchorInequality() {
    let left = ContactItemSyncAnchor(generationMarker: Data([1]), offset: 0)
    let right = ContactItemSyncAnchor(generationMarker: Data([1]), offset: 1)
    precondition(left != right)
    precondition(!(left != left))
}

func testSyncAnchorCodable() {
    let original = ContactItemSyncAnchor(generationMarker: Data([0xBE, 0xEF]), offset: 99)
    let data = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(ContactItemSyncAnchor.self, from: data)
    precondition(decoded == original)
    precondition(decoded.offset == 99)
}
