import Foundation
@_spi(OpenUIKitHost) import Contacts

func testChangeHistoryEventsAndVisitor() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let group = CNMutableGroup()
    group.name = "Scientists"
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    save.add(group, toContainerWithIdentifier: nil)
    try! store.execute(save)
    let memberSave = CNSaveRequest()
    memberSave.addMember(contact, to: group)
    try! store.execute(memberSave)
    let update = contact.mutableCopy() as! CNMutableContact
    update.note = "updated"
    let updateSave = CNSaveRequest()
    updateSave.update(update)
    try! store.execute(updateSave)

    let history = store._portableChangeHistory()
    expect(history.contains { $0 is CNChangeHistoryAddContactEvent }, "add contact history")
    expect(history.contains { $0 is CNChangeHistoryAddGroupEvent }, "add group history")
    expect(history.contains { $0 is CNChangeHistoryAddMemberToGroupEvent }, "add member history")
    expect(history.contains { $0 is CNChangeHistoryUpdateContactEvent }, "update contact history")
    expect(store.currentHistoryToken != nil, "history token")

    let visitor = RecordingVisitor()
    for event in history {
        event.accept(visitor)
    }
    expect(visitor.addContacts >= 1, "visitor add contact")
    expect(visitor.addGroups >= 1, "visitor add group")
    expect(visitor.addMembers >= 1, "visitor add member")
    expect(visitor.updateContacts >= 1, "visitor update contact")

    let addContact = history.compactMap { $0 as? CNChangeHistoryAddContactEvent }.first!
    expect(addContact.contact.givenName == "Ada", "add contact event contact")
    expect(addContact.containerIdentifier != nil, "add contact containerIdentifier")
    let addGroup = history.compactMap { $0 as? CNChangeHistoryAddGroupEvent }.first!
    expect(addGroup.group.name == "Scientists", "add group event group")
    expect(!addGroup.containerIdentifier.isEmpty, "add group containerIdentifier")
    let addMember = history.compactMap { $0 as? CNChangeHistoryAddMemberToGroupEvent }.first!
    expect(addMember.member.identifier == contact.identifier, "add member event member")
    expect(addMember.group.identifier == group.identifier, "add member event group")
    let updateContact = history.compactMap { $0 as? CNChangeHistoryUpdateContactEvent }.first!
    expect(updateContact.contact.identifier == contact.identifier, "update contact event")

    let drop = CNChangeHistoryDropEverythingEvent()
    drop.accept(visitor)
    expect(visitor.drops >= 1, "drop everything")
    let subgroup = CNChangeHistoryAddSubgroupToGroupEvent(subgroup: group, group: group)
    expect(subgroup.subgroup.identifier == group.identifier, "add subgroup.subgroup")
    expect(subgroup.group.identifier == group.identifier, "add subgroup.group")
    subgroup.accept(visitor)
    let removeSub = CNChangeHistoryRemoveSubgroupFromGroupEvent(subgroup: group, group: group)
    expect(removeSub.subgroup.identifier == group.identifier, "remove subgroup.subgroup")
    expect(removeSub.group.identifier == group.identifier, "remove subgroup.group")
    removeSub.accept(visitor)
    expect(visitor.addSubgroups >= 1 && visitor.removeSubgroups >= 1, "subgroup visitor")

    let deleteContact = CNChangeHistoryDeleteContactEvent(contactIdentifier: contact.identifier)
    expect(deleteContact.contactIdentifier == contact.identifier, "delete contactIdentifier")
    deleteContact.accept(visitor)
    let deleteGroup = CNChangeHistoryDeleteGroupEvent(groupIdentifier: group.identifier)
    expect(deleteGroup.groupIdentifier == group.identifier, "delete groupIdentifier")
    deleteGroup.accept(visitor)
    let updateGroup = CNChangeHistoryUpdateGroupEvent(group: group)
    expect(updateGroup.group.identifier == group.identifier, "update group event")
    updateGroup.accept(visitor)
    let removeMember = CNChangeHistoryRemoveMemberFromGroupEvent(member: contact, group: group)
    expect(removeMember.member.identifier == contact.identifier, "remove member")
    expect(removeMember.group.identifier == group.identifier, "remove member group")
    removeMember.accept(visitor)
    expect(visitor.deleteContacts >= 1, "visit delete contact")
    expect(visitor.deleteGroups >= 1, "visit delete group")
    expect(visitor.updateGroups >= 1, "visit update group")
    expect(visitor.removeMembers >= 1, "visit remove member")

    _ = CNChangeHistoryEvent()
    _ = CNChangeHistoryFetchRequest()
}

func testChangeHistoryFetchRequest() {
    let historyRequest = CNChangeHistoryFetchRequest()
    historyRequest.startingToken = Data([1, 2, 3])
    historyRequest.includeGroupChanges = true
    historyRequest.shouldUnifyResults = true
    historyRequest.mutableObjects = false
    historyRequest.additionalContactKeyDescriptors = keys(CNContactGivenNameKey)
    historyRequest.excludedTransactionAuthors = ["ContactsRuntime"]
    expect(historyRequest.startingToken == Data([1, 2, 3]), "startingToken")
    expect(historyRequest.includeGroupChanges, "includeGroupChanges")
    expect(historyRequest.shouldUnifyResults, "shouldUnifyResults")
    expect(!historyRequest.mutableObjects, "mutableObjects")
    expect(historyRequest.additionalContactKeyDescriptors?.count == 1, "additionalContactKeyDescriptors")
    expect(historyRequest.excludedTransactionAuthors == ["ContactsRuntime"], "excludedTransactionAuthors")
}
