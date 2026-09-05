import Foundation
@_spi(OpenUIKitHost) import Contacts

func testVCardSerialization() {
    let contact = makeAdaContact()
    let vCard = try! CNContactVCardSerialization.data(with: [contact])
    let vCardText = String(data: vCard, encoding: .utf8) ?? ""
    expect(vCardText.contains("BEGIN:VCARD"), "vcard begin")
    expect(vCardText.contains("VERSION:3.0"), "vcard version")
    expect(vCardText.contains("TEL;TYPE=CELL:"), "vcard tel type")
    expect(vCardText.contains("EMAIL;TYPE=HOME:"), "vcard email type")
    expect(vCardText.contains("BDAY:1815-12-10"), "vcard bday")
    expect(vCardText.contains("PHOTO;ENCODING=b;TYPE="), "vcard photo")
    expect(vCardText.contains("NOTE:"), "vcard note")
    expect(vCardText.contains("URL:"), "vcard url")
    expect(vCardText.contains("ADR;TYPE=HOME:"), "vcard adr type")
    let decoded = try! CNContactVCardSerialization.contacts(with: vCard)
    expect(decoded.count == 1, "vcard count")
    expect(decoded[0].givenName == "Ada", "vcard given")
    expect(decoded[0].familyName == "Lovelace", "vcard family")
    expect(decoded[0].namePrefix == "Ms", "vcard prefix")
    expect(decoded[0].middleName == "Byron", "vcard middle")
    expect(decoded[0].nameSuffix == "Countess", "vcard suffix")
    expect(decoded[0].phoneNumbers.count == 1, "vcard phone")
    expect(decoded[0].phoneNumbers[0].label == CNLabelPhoneNumberMobile, "vcard phone label")
    expect(decoded[0].emailAddresses[0].value as String == "ada@example.com", "vcard email")
    expect(decoded[0].birthday?.year == 1815, "vcard birthday year")
    expect(decoded[0].imageData == Data([0x00, 0x01, 0x02]), "vcard photo round trip")
    expect(decoded[0].note == "First programmer", "vcard note round trip")
    _ = CNContactVCardSerialization.descriptorForRequiredKeys()
    do {
        _ = try CNContactVCardSerialization.contacts(with: Data("BEGIN:VCARD\nVERSION:3.0\nN:Foo\n".utf8))
        fail("unterminated vcard must throw")
    } catch let error as CNError {
        expect(error.code == .vCardMalformed, "malformed vcard")
    } catch {
        fail("expected vCardMalformed")
    }
}
