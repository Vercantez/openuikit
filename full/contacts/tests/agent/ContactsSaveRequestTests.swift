import Foundation
@_spi(OpenUIKitHost) import Contacts

func testSaveRequestMutations() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let group = CNMutableGroup()
    group.name = "Scientists"
    let save = CNSaveRequest()
    save.transactionAuthor = "ContactsRuntime"
    save.shouldRefetchContacts = true
    expect(save.transactionAuthor == "ContactsRuntime", "transactionAuthor")
    expect(save.shouldRefetchContacts, "shouldRefetchContacts")
    save.add(contact, toContainerWithIdentifier: nil)
    save.add(group, toContainerWithIdentifier: nil)
    try! store.execute(save)

    let memberSave = CNSaveRequest()
    memberSave.addMember(contact, to: group)
    try! store.execute(memberSave)

    let renamed = group.mutableCopy() as! CNMutableGroup
    renamed.name = "Analysts"
    let updateGroup = CNSaveRequest()
    updateGroup.update(renamed)
    try! store.execute(updateGroup)
    let groups = try! store.groups(matching: CNGroup.predicateForGroups(withIdentifiers: [group.identifier]))
    expect(groups[0].name == "Analysts", "update group")

    let remove = CNSaveRequest()
    remove.removeMember(contact, from: group)
    remove.delete(renamed)
    let doomed = contact.mutableCopy() as! CNMutableContact
    remove.delete(doomed)
    try! store.execute(remove)
    let remaining = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(withIdentifiers: [contact.identifier]),
        keysToFetch: keys(CNContactIdentifierKey)
    )
    expect(remaining.isEmpty, "deleted contact")
    let leftoverGroups = try! store.groups(matching: CNGroup.predicateForGroups(withIdentifiers: [group.identifier]))
    expect(leftoverGroups.isEmpty, "deleted group")
}
