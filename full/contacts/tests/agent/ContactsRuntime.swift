import Contacts
import Foundation
@_spi(OpenUIKitHost) import Contacts

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fail(message)
    }
}

func fail(_ message: String) -> Never {
    fputs("CONTACTS_AGENT_RUNTIME_FAIL: \(message)\n", stderr)
    exit(1)
}

final class RecordingVisitor: NSObject, CNChangeHistoryEventVisitor {
    var addContacts = 0
    var subgroups = 0

    func visit(_ event: CNChangeHistoryAddContactEvent) { addContacts += 1 }
    func visit(_ event: CNChangeHistoryDeleteContactEvent) {}
    func visit(_ event: CNChangeHistoryDropEverythingEvent) {}
    func visit(_ event: CNChangeHistoryUpdateContactEvent) {}
    func visitAddSubgroup(_ event: CNChangeHistoryAddSubgroupToGroupEvent) { subgroups += 1 }
}

CNContactStore._resetPortableStore()

let constants = CNAllPublicStringConstants()
expect(constants.count == 308, "expected 308 public string constants, got \(constants.count)")
expect(constants.allSatisfy { !$0.isEmpty }, "public string constants must be nonempty")
expect(CNContactGivenNameKey == "givenName", "given name key")
expect(CNLabelHome == "_$!<Home>!$_", "home label payload")
expect(CNLabelPhoneNumberiPhone == "iPhone", "iPhone label")
expect(CNErrorDomain == "CNErrorDomain", "error domain")
expect(CNLabelContactRelationFather == "_$!<Father>!$_", "father relation")

expect(CNAuthorizationStatus.notDetermined.rawValue == 0, "auth notDetermined")
expect(CNAuthorizationStatus.authorized.rawValue == 3, "auth authorized")
expect(CNAuthorizationStatus.limited != CNAuthorizationStatus.denied, "auth inequality")
expect(CNContactSortOrder.familyName.rawValue == 3, "sort family")
expect(CNContactType.organization.rawValue == 1, "org type")
expect(CNEntityType.contacts.rawValue == 0, "entity")
expect(CNContainerType.cardDAV.rawValue == 3, "carddav")
expect(CNContactDisplayNameOrder.familyNameFirst.rawValue == 2, "display order")
expect(CNContactFormatterStyle.phoneticFullName.rawValue == 1, "formatter style")
expect(CNPostalAddressFormatterStyle.mailingAddress.rawValue == 0, "postal style")
expect(CNError.Code.authorizationDenied.rawValue == 100, "auth denied code")
expect(CNError.featureNotAvailable.rawValue == 104, "feature not available")
expect(CNError.vCardMalformed.rawValue == 800, "vcard malformed")
var hasher = Hasher()
CNAuthorizationStatus.authorized.hash(into: &hasher)
_ = hasher.finalize()
_ = CNContactSortOrder.givenName.hashValue

let denied = CNError(
    .authorizationDenied,
    userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: ["abc"]]
)
expect(CNError.errorDomain == CNErrorDomain, "custom nserror domain")
expect(denied.errorCode == 100, "custom nserror code")
expect(denied.affectedRecordIdentifiers == ["abc"], "affected ids")
expect(CNError.Code.authorizationDenied ~= denied, "error code pattern")

expect(
    CNContactStore.authorizationStatus(for: .contacts) == .notDetermined,
    "start notDetermined"
)

let store = CNContactStore()
do {
    _ = try store.unifiedContacts(
        matching: CNContact.predicateForContacts(matchingName: "Ada"),
        keysToFetch: [CNContactGivenNameKey]
    )
    fail("fetch must fail closed before requestAccess")
} catch let error as CNError {
    expect(error.code == .authorizationDenied, "fail closed authorization")
} catch {
    fail("unexpected error \(error)")
}

var granted = false
var grantError: Error?
store.requestAccess(for: .contacts) { ok, error in
    granted = ok
    grantError = error
}
expect(grantError == nil, "requestAccess error")
expect(granted, "in-memory requestAccess")
expect(
    CNContactStore.authorizationStatus(for: .contacts) == .authorized,
    "authorized after request"
)

let contact = CNMutableContact()
contact.givenName = "Ada"
contact.familyName = "Lovelace"
contact.nickname = "Ada"
contact.organizationName = "Analytical Engine"
contact.jobTitle = "Mathematician"
contact.departmentName = "Mathematics"
contact.namePrefix = "Ms"
contact.nameSuffix = "Countess"
contact.middleName = "Byron"
contact.phoneticGivenName = "Ay-duh"
contact.phoneticFamilyName = "Love-lace"
contact.phoneticMiddleName = "By-ron"
contact.phoneticOrganizationName = "Engine"
contact.previousFamilyName = "Byron"
contact.note = "First programmer"
contact.contactType = .person
contact.birthday = DateComponents(calendar: Calendar(identifier: .gregorian), year: 1815, month: 12, day: 10)
contact.imageData = Data([0x00, 0x01, 0x02])
contact.phoneNumbers = [
    CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "+1-555-0100"))
]
contact.emailAddresses = [
    CNLabeledValue(label: CNLabelHome, value: "ada@example.com" as NSString)
]
contact.urlAddresses = [
    CNLabeledValue(label: CNLabelURLAddressHomePage, value: "https://example.com" as NSString)
]
let postal = CNMutablePostalAddress()
postal.street = "12 Great Street"
postal.city = "London"
postal.state = "England"
postal.postalCode = "SW1A"
postal.country = "United Kingdom"
postal.isoCountryCode = "GB"
postal.subLocality = "Westminster"
postal.subAdministrativeArea = "Greater London"
contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: postal)]
contact.contactRelations = [
    CNLabeledValue(
        label: CNLabelContactRelationFather,
        value: CNContactRelation(name: "Lord Byron")
    )
]
contact.socialProfiles = [
    CNLabeledValue(
        label: CNLabelWork,
        value: CNSocialProfile(
            urlString: "https://social.example/ada",
            username: "ada",
            userIdentifier: "ada-1",
            service: CNSocialProfileServiceTwitter
        )
    )
]
contact.instantMessageAddresses = [
    CNLabeledValue(
        label: CNLabelWork,
        value: CNInstantMessageAddress(username: "ada", service: CNInstantMessageServiceJabber)
    )
]
let anniversary = NSDateComponents()
anniversary.year = 1835
anniversary.month = 7
anniversary.day = 8
contact.dates = [CNLabeledValue(label: CNLabelDateAnniversary, value: anniversary)]

expect(contact.isKeyAvailable(CNContactGivenNameKey), "mutable keys available")
expect(contact.imageDataAvailable, "image available")
expect(contact.id.uuidString == contact.identifier, "identifiable id")
expect(contact.areKeysAvailable([CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]), "descriptor keys")

let formatted = CNContactFormatter.string(from: contact, style: .fullName)
expect(formatted == "Ada Lovelace", "full name \(String(describing: formatted))")
let phonetic = CNContactFormatter.string(from: contact, style: .phoneticFullName)
expect(phonetic == "Ay-duh Love-lace", "phonetic \(String(describing: phonetic))")
expect(CNContactFormatter.nameOrder(for: contact) == .givenNameFirst, "name order")
expect(CNContactFormatter.delimiter(for: contact) == " ", "delimiter")
expect(
    CNContactFormatter.attributedString(from: contact, style: .fullName)?.string == "Ada Lovelace",
    "attributed name"
)
let formatter = CNContactFormatter()
formatter.style = .fullName
expect(formatter.string(from: contact) == "Ada Lovelace", "instance formatter")
expect(formatter.attributedString(from: contact)?.string == "Ada Lovelace", "instance attributed")

let mailing = CNPostalAddressFormatter.string(from: postal, style: .mailingAddress)
expect(mailing.contains("12 Great Street"), "street in mailing")
expect(mailing.contains("London"), "city in mailing")
let postalFormatter = CNPostalAddressFormatter()
expect(postalFormatter.string(from: postal).contains("United Kingdom"), "instance postal")
expect(
    CNPostalAddressFormatter.attributedString(
        from: postal,
        style: .mailingAddress
    ).string.contains("SW1A"),
    "attributed postal"
)
expect(CNPostalAddress.localizedString(forKey: CNPostalAddressCityKey) == "City", "city title")
expect(CNLabeledValue<NSString>.localizedString(forLabel: CNLabelHome) == "Home", "label title")
expect(CNContact.localizedString(forKey: CNContactGivenNameKey) == "Given Name", "contact key title")
expect(CNInstantMessageAddress.localizedString(forService: CNInstantMessageServiceJabber) == "Jabber", "im service")
expect(CNSocialProfile.localizedString(forKey: CNSocialProfileUsernameKey) == "Username", "social key")

let labeled = CNLabeledValue(label: CNLabelWork, value: "work@example.com" as NSString)
let relabeled = labeled.settingLabel(CNLabelOther)
expect(relabeled.label == CNLabelOther, "relabel")
expect(relabeled.identifier == labeled.identifier, "stable labeled identifier")
expect((relabeled.settingValue("other@example.com" as NSString).value as String) == "other@example.com", "set value")

let emptyPhone = CNPhoneNumber.new()
expect(emptyPhone.stringValue == "", "empty phone")

let save = CNSaveRequest()
save.transactionAuthor = "ContactsRuntime"
save.shouldRefetchContacts = true
save.add(contact, toContainerWithIdentifier: nil)

let group = CNMutableGroup()
group.name = "Scientists"
save.add(group, toContainerWithIdentifier: nil)
try! store.execute(save)

let fetched = try! store.unifiedContacts(
    matching: CNContact.predicateForContacts(matchingName: "Ada"),
    keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey]
)
expect(fetched.count == 1, "fetched ada")
expect(fetched[0].givenName == "Ada", "fetched given")
expect(fetched[0].isKeyAvailable(CNContactEmailAddressesKey), "email key fetched")

let byEmail = try! store.unifiedContacts(
    matching: CNContact.predicateForContacts(matchingEmailAddress: "ada@example.com"),
    keysToFetch: [CNContactIdentifierKey]
)
expect(byEmail.count == 1, "email predicate")
let byPhone = try! store.unifiedContacts(
    matching: CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: "+1-555-0100")),
    keysToFetch: [CNContactIdentifierKey]
)
expect(byPhone.count == 1, "phone predicate")
let byID = try! store.unifiedContact(
    withIdentifier: contact.identifier,
    keysToFetch: [CNContactGivenNameKey]
)
expect(byID.givenName == "Ada", "unified by id")
expect(byID.id == contact.id, "uuid identity")

let memberSave = CNSaveRequest()
memberSave.addMember(contact, to: group)
try! store.execute(memberSave)
let groups = try! store.groups(matching: CNGroup.predicateForGroups(withIdentifiers: [group.identifier]))
expect(groups.count == 1 && groups[0].name == "Scientists", "group fetch")
let inGroup = try! store.unifiedContacts(
    matching: CNContact.predicateForContactsInGroup(withIdentifier: group.identifier),
    keysToFetch: [CNContactGivenNameKey]
)
expect(inGroup.count == 1, "contacts in group")
let containers = try! store.containers(matching: nil)
expect(containers.count == 1 && containers[0].type == .local, "local container")
expect(store.defaultContainerIdentifier() == containers[0].identifier, "default container")
let ofContact = try! store.containers(
    matching: CNContainer.predicateForContainerOfContact(withIdentifier: contact.identifier)
)
expect(ofContact.count == 1, "container of contact")

var enumerated = 0
let request = CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey])
request.sortOrder = .familyName
request.unifyResults = true
try! store.enumerateContacts(with: request) { item, stop in
    enumerated += 1
    if item.familyName == "Lovelace" {
        stop.pointee = ObjCBool(true)
    }
}
expect(enumerated == 1, "enumerated")

let comparator = CNContact.comparator(forNameSortOrder: .familyName)
expect(comparator(fetched[0], fetched[0]) == .orderedSame, "comparator same")
_ = CNContact.descriptorForAllComparatorKeys()
_ = CNContactFormatter.descriptorForRequiredKeysForDelimiter
_ = CNContactFormatter.descriptorForRequiredKeysForNameOrder

let vCard = try! CNContactVCardSerialization.data(with: [contact])
let decoded = try! CNContactVCardSerialization.contacts(with: vCard)
expect(decoded.count == 1, "vcard count")
expect(decoded[0].givenName == "Ada", "vcard given")
expect(decoded[0].familyName == "Lovelace", "vcard family")
expect(decoded[0].phoneNumbers.count == 1, "vcard phone")
_ = CNContactVCardSerialization.descriptorForRequiredKeys()

let defaults = CNContactsUserDefaults.shared()
expect(!defaults.countryCode.isEmpty, "country code")
expect(defaults.sortOrder == .givenName, "portable sort default")

let history = store._portableChangeHistory()
expect(history.contains { $0 is CNChangeHistoryAddContactEvent }, "add contact history")
expect(history.contains { $0 is CNChangeHistoryAddGroupEvent }, "add group history")
expect(history.contains { $0 is CNChangeHistoryAddMemberToGroupEvent }, "add member history")
let visitor = RecordingVisitor()
for event in history {
    event.accept(visitor)
}
expect(visitor.addContacts >= 1, "visitor add")
expect(store.currentHistoryToken != nil, "history token")

let copied = contact.copy() as! CNContact
expect(copied.givenName == "Ada", "copy")
let mutableCopy = copied.mutableCopy() as! CNMutableContact
mutableCopy.givenName = "Augusta"
expect(copied.givenName == "Ada", "copy independence")

let update = byID.mutableCopy() as! CNMutableContact
update.familyName = "King"
let updateRequest = CNSaveRequest()
updateRequest.update(update)
try! store.execute(updateRequest)
let updated = try! store.unifiedContact(
    withIdentifier: contact.identifier,
    keysToFetch: [CNContactFamilyNameKey]
)
expect(updated.familyName == "King", "updated family")

let archived = try! NSKeyedArchiver.archivedData(withRootObject: CNPhoneNumber(stringValue: "555"), requiringSecureCoding: true)
let unarchived = try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNPhoneNumber.self, from: archived)
expect(unarchived?.stringValue == "555", "phone nscoding")

let property = CNContactProperty(contact: contact, key: CNContactGivenNameKey, value: contact.givenName as NSString)
expect(property.key == CNContactGivenNameKey, "property key")

let fetchResult = CNFetchResult(value: contact, currentHistoryToken: Data([1]))
expect(fetchResult.value.givenName == "Ada", "fetch result")

let drop = CNChangeHistoryDropEverythingEvent()
drop.accept(visitor)
let subgroup = CNChangeHistoryAddSubgroupToGroupEvent(subgroup: group, group: group)
subgroup.accept(visitor)
let removeSub = CNChangeHistoryRemoveSubgroupFromGroupEvent(subgroup: group, group: group)
removeSub.accept(visitor)
expect(visitor.subgroups >= 1, "subgroup visitor")

let remove = CNSaveRequest()
remove.removeMember(contact, from: group)
remove.delete(group)
let doomed = updated.mutableCopy() as! CNMutableContact
remove.delete(doomed)
try! store.execute(remove)
let remaining = try! store.unifiedContacts(
    matching: CNContact.predicateForContacts(withIdentifiers: [contact.identifier]),
    keysToFetch: [CNContactIdentifierKey]
)
expect(remaining.isEmpty, "deleted contact")

expect(NSNotification.Name.CNContactStoreDidChange.rawValue == "CNContactStoreDidChangeNotification", "note name")

let errorAliases: [CNError.Code] = [
    CNError.communicationError,
    CNError.dataAccessError,
    CNError.authorizationDenied,
    CNError.noAccessableWritableContainers,
    CNError.unauthorizedKeys,
    CNError.featureDisabledByUser,
    CNError.featureNotAvailable,
    CNError.recordDoesNotExist,
    CNError.insertedRecordAlreadyExists,
    CNError.containmentCycle,
    CNError.containmentScope,
    CNError.recordIdentifierInvalid,
    CNError.recordNotWritable,
    CNError.parentRecordDoesNotExist,
    CNError.parentContainerNotWritable,
    CNError.validationMultipleErrors,
    CNError.validationTypeMismatch,
    CNError.validationConfigurationError,
    CNError.predicateInvalid,
    CNError.policyViolation,
    CNError.clientIdentifierInvalid,
    CNError.clientIdentifierDoesNotExist,
    CNError.clientIdentifierCollision,
    CNError.changeHistoryExpired,
    CNError.changeHistoryInvalidAnchor,
    CNError.changeHistoryInvalidFetchRequest,
    CNError.vCardMalformed,
    CNError.vCardSummarizationError,
]
expect(Set(errorAliases.map(\.rawValue)).count == errorAliases.count, "unique error aliases")
let hashedError = CNError(.communicationError)
expect(hashedError == CNError(.communicationError), "error equality")
expect(hashedError != CNError(.dataAccessError), "error inequality")
hashedError.hash(into: &hasher)
expect(hashedError.hashValue == CNError(.communicationError).hashValue, "error hash")
expect(hashedError.keyPaths == nil, "error keyPaths")
expect(hashedError.affectedRecords == nil, "error affectedRecords")
_ = hashedError.userInfo
_ = hashedError.errorUserInfo
_ = hashedError.localizedDescription

_ = try! store.unifiedContacts(
    matching: CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier()),
    keysToFetch: [CNContactIdentifierKey]
)
_ = try! store.groups(matching: CNGroup.predicateForGroupsInContainer(withIdentifier: store.defaultContainerIdentifier()))
_ = try! store.containers(matching: CNContainer.predicateForContainers(withIdentifiers: [store.defaultContainerIdentifier()]))
_ = try! store.containers(matching: CNContainer.predicateForContainerOfGroup(withIdentifier: group.identifier))
_ = labeled.settingLabel(CNLabelHome, value: "home@example.com" as NSString)

let historyRequest = CNChangeHistoryFetchRequest()
historyRequest.startingToken = store.currentHistoryToken
historyRequest.includeGroupChanges = true
historyRequest.shouldUnifyResults = true
historyRequest.mutableObjects = false
historyRequest.additionalContactKeyDescriptors = [CNContactGivenNameKey]
historyRequest.excludedTransactionAuthors = ["ContactsRuntime"]
_ = CNFetchRequest()

let postalCopy = postal.copy() as! CNPostalAddress
expect(postalCopy.city == "London", "postal copy")
let postalMutable = postalCopy.mutableCopy() as! CNMutablePostalAddress
postalMutable.city = "Bath"
expect(postalCopy.city == "London", "postal copy independence")
expect(CNContactRelation(name: "X").name == "X", "relation name")
expect(!contact.isUnifiedWithContact(withIdentifier: "missing"), "not unified")

print("CONTACTS_AGENT_RUNTIME_OK")

