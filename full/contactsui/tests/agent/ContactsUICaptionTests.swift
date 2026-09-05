@_spi(OpenUIKitHost) import ContactsUI
import Foundation

/// Table-driven Caption enum: cases, raw values, failable init, Hashable.
@MainActor
func testCaptionCases() {
    let table: [(ContactAccessButton.Caption, String)] = [
        (.defaultText, "defaultText"),
        (.email, "email"),
        (.phone, "phone"),
    ]
    precondition(Set(table.map(\.0)).count == 3)
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(ContactAccessButton.Caption(rawValue: raw) == value)
    }
    precondition(ContactAccessButton.Caption(rawValue: "not-a-caption") == nil)
    precondition(ContactAccessButton.Caption.email != .phone)
    precondition(ContactAccessButton.Caption.defaultText != .email)
    var hasher = Hasher()
    ContactAccessButton.Caption.phone.hash(into: &hasher)
    _ = hasher.finalize()
    _ = ContactAccessButton.Caption.email.hashValue
    typealias Raw = ContactAccessButton.Caption.RawValue
    precondition((table[0].1 as Raw) == "defaultText")
}
