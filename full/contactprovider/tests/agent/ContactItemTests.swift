import Foundation
import ContactProvider

func testContactItemType() {
    let contact = CNMutableContact()
    contact.givenName = "Ada"
    let item = ContactItem.contact(contact, ContactItem.Identifier("ada"))
    switch item {
    case .contact(let stored, let identifier):
        precondition(stored.givenName == "Ada")
        precondition(identifier.value == "ada")
    }
}

func testContactItemContactCase() {
    let contact = CNMutableContact()
    contact.familyName = "Lovelace"
    let identifier = ContactItem.Identifier("lovelace")
    let item = ContactItem.contact(contact, identifier)
    if case .contact(let stored, let storedID) = item {
        precondition(stored.familyName == "Lovelace")
        precondition(storedID == identifier)
    } else {
        preconditionFailure("expected contact case")
    }
}

func testContactItemEquality() {
    let first = CNMutableContact()
    first.identifier = "same"
    let second = CNMutableContact()
    second.identifier = "same"
    let id = ContactItem.Identifier("person")
    let left = ContactItem.contact(first, id)
    let right = ContactItem.contact(second, id)
    precondition(left == right)

    let other = CNMutableContact()
    other.identifier = "other"
    precondition(ContactItem.contact(other, id) != left)
    precondition(ContactItem.contact(first, ContactItem.Identifier("else")) != left)
}

func testContactItemInequality() {
    let contact = CNMutableContact()
    let left = ContactItem.contact(contact, ContactItem.Identifier("a"))
    let right = ContactItem.contact(contact, ContactItem.Identifier("b"))
    precondition(left != right)
    precondition(!(left != left))
}

func testContactItemHash() {
    let contact = CNMutableContact()
    contact.identifier = "hash-me"
    let item = ContactItem.contact(contact, ContactItem.Identifier("id"))
    var hasher = Hasher()
    item.hash(into: &hasher)
    _ = hasher.finalize()
}

func testContactItemHashValue() {
    let contact = CNMutableContact()
    contact.identifier = "stable"
    let item = ContactItem.contact(contact, ContactItem.Identifier("stable"))
    let twin = ContactItem.contact(contact, ContactItem.Identifier("stable"))
    precondition(item.hashValue == twin.hashValue)
}

func testIdentifierType() {
    let identifier = ContactItem.Identifier("type")
    precondition(type(of: identifier) == ContactItem.Identifier.self)
}

func testIdentifierInit() {
    let identifier = ContactItem.Identifier("created")
    precondition(identifier.value == "created")
}

func testIdentifierValue() {
    let identifier = ContactItem.Identifier("value-check")
    precondition(identifier.value == "value-check")
    precondition(ContactItem.Identifier("").value.isEmpty)
}

func testIdentifierRootContainer() {
    precondition(ContactItem.Identifier.rootContainer.value == "rootContainer")
    precondition(ContactItem.Identifier.rootContainer == ContactItem.Identifier("rootContainer"))
    precondition(ContactItem.Identifier.rootContainer != ContactItem.Identifier("other"))
}

func testIdentifierEquality() {
    precondition(ContactItem.Identifier("a") == ContactItem.Identifier("a"))
    precondition(ContactItem.Identifier("a") != ContactItem.Identifier("b"))
}

func testIdentifierInequality() {
    precondition(ContactItem.Identifier("x") != ContactItem.Identifier("y"))
    precondition(!(ContactItem.Identifier.rootContainer != ContactItem.Identifier("rootContainer")))
}

func testIdentifierHash() {
    var hasher = Hasher()
    ContactItem.Identifier("hash").hash(into: &hasher)
    _ = hasher.finalize()
}

func testIdentifierHashValue() {
    let identifier = ContactItem.Identifier("same")
    precondition(identifier.hashValue == ContactItem.Identifier("same").hashValue)
    var set = Set<ContactItem.Identifier>()
    set.insert(.rootContainer)
    set.insert(ContactItem.Identifier("rootContainer"))
    precondition(set.count == 1)
}
