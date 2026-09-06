import Foundation
import ContactProvider

func testPageType() {
    let page = ContactItemPage(generationMarker: Data([0x01]), offset: 1)
    precondition(type(of: page) == ContactItemPage.self)
}

func testPageInit() {
    let marker = Data([0xAA, 0xBB])
    let page = ContactItemPage(generationMarker: marker, offset: 12)
    precondition(page.generationMarker == marker)
    precondition(page.offset == 12)
}

func testPageGenerationMarker() {
    var page = ContactItemPage(generationMarker: Data([0x10]), offset: 0)
    precondition(page.generationMarker == Data([0x10]))
    page.generationMarker = Data([0x20, 0x21])
    precondition(page.generationMarker == Data([0x20, 0x21]))
}

func testPageOffset() {
    var page = ContactItemPage(generationMarker: Data(), offset: 4)
    precondition(page.offset == 4)
    page.offset = 9
    precondition(page.offset == 9)
}

func testPageInitialPage() {
    let page = ContactItemPage.initialPage
    precondition(page.generationMarker.isEmpty)
    precondition(page.offset == 0)
    precondition(page == ContactItemPage(generationMarker: Data(), offset: 0))
}

func testPageEquality() {
    let marker = Data("gen".utf8)
    let left = ContactItemPage(generationMarker: marker, offset: 2)
    let right = ContactItemPage(generationMarker: marker, offset: 2)
    precondition(left == right)
    precondition(left != ContactItemPage(generationMarker: marker, offset: 3))
    precondition(left != ContactItemPage(generationMarker: Data("other".utf8), offset: 2))
}

func testPageInequality() {
    let left = ContactItemPage(generationMarker: Data([1]), offset: 0)
    let right = ContactItemPage(generationMarker: Data([2]), offset: 0)
    precondition(left != right)
    precondition(!(ContactItemPage.initialPage != ContactItemPage.initialPage))
}

func testPageCodable() {
    let original = ContactItemPage(generationMarker: Data([0xDE, 0xAD]), offset: 42)
    let data = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(ContactItemPage.self, from: data)
    precondition(decoded == original)
    precondition(decoded.generationMarker == original.generationMarker)
    precondition(decoded.offset == 42)
}
