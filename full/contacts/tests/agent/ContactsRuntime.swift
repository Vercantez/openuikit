import Contacts
import Foundation
@_spi(OpenUIKitHost) import Contacts
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

func expect(_ condition: Bool, _ message: String) {
    if !condition {
        fail(message)
    }
}

func fail(_ message: String) -> Never {
    fputs("CONTACTS_AGENT_RUNTIME_FAIL: \(message)\n", stderr)
    exit(1)
}

func wait(_ semaphore: DispatchSemaphore, _ message: String) {
    if semaphore.wait(timeout: .now() + 5) == .timedOut {
        fail(message)
    }
}

func keys(_ values: String...) -> [any CNKeyDescriptor] {
    values.map { $0 as NSString }
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

let storeRoot = FileManager.default.temporaryDirectory
    .appendingPathComponent("openuikit-contacts-\(ProcessInfo.processInfo.processIdentifier)", isDirectory: true)
try! FileManager.default.createDirectory(at: storeRoot, withIntermediateDirectories: true)
_ = storeRoot.path.withCString { path in
    "OPENUIKIT_CONTACTS_DIRECTORY".withCString { key in
        setenv(key, path, 1)
    }
}
CNContactStore._resetPortableStore()
expect(
    CNContactStore._portableStoreDirectory().path == storeRoot.path,
    "documented store directory override"
)

CNContactStore._setPortableAuthorizationDecision(.denied)
expect(CNContactStore.authorizationStatus(for: .contacts) == .notDetermined, "denied-hook starts notDetermined")
let deniedStore = CNContactStore()
let deniedSem = DispatchSemaphore(value: 0)
var deniedGranted = true
deniedStore.requestAccess(for: .contacts) { granted, error in
    deniedGranted = granted
    expect(error == nil, "denied requestAccess has no fabricated TCC error")
    deniedSem.signal()
}
wait(deniedSem, "denied requestAccess deadlock")
expect(!deniedGranted, "documented denied decision")
expect(CNContactStore.authorizationStatus(for: .contacts) == .denied, "status denied after hook")
do {
    _ = try deniedStore.unifiedContacts(
        matching: CNContact.predicateForContacts(matchingName: "Nobody"),
        keysToFetch: keys(CNContactGivenNameKey)
    )
    fail("denied fetch must stay fail-closed")
} catch let error as CNError {
    expect(error.code == .authorizationDenied, "denied fetch code")
} catch {
    fail("unexpected denied fetch \(error)")
}

CNContactStore._resetPortableStore()

let constants = CNAllPublicStringConstants()
expect(constants.count == 308, "expected 308 public string constants, got \(constants.count)")
expect(constants.allSatisfy { !$0.isEmpty }, "public string constants must be nonempty")
expect(CNContactGivenNameKey == "givenName", "given name key")
expect(CNLabelHome == "_$!<Home>!$_", "home label payload")
expect(CNLabelWork == "_$!<Work>!$_", "work label payload")
expect(CNLabelOther == "_$!<Other>!$_", "other label payload")
expect(CNLabelPhoneNumberiPhone == "iPhone", "iPhone label")
expect(CNLabelPhoneNumberMobile == "_$!<Mobile>!$_", "mobile label")
expect(CNErrorDomain == "CNErrorDomain", "error domain")
expect(CNLabelContactRelationFather == "_$!<Father>!$_", "father relation")
expect(CNLabelContactRelationMother == "_$!<Mother>!$_", "mother relation")
expect(CNLabelDateAnniversary == "_$!<Anniversary>!$_", "anniversary label")

expect(CNAuthorizationStatus.notDetermined.rawValue == 0, "auth notDetermined")
expect(CNAuthorizationStatus.restricted.rawValue == 1, "auth restricted")
expect(CNAuthorizationStatus.denied.rawValue == 2, "auth denied")
expect(CNAuthorizationStatus.authorized.rawValue == 3, "auth authorized")
expect(CNAuthorizationStatus.limited.rawValue == 4, "auth limited")
expect(CNAuthorizationStatus.limited != CNAuthorizationStatus.denied, "auth inequality")
expect(CNContactSortOrder.none.rawValue == 0, "sort none")
expect(CNContactSortOrder.userDefault.rawValue == 1, "sort userDefault")
expect(CNContactSortOrder.givenName.rawValue == 2, "sort given")
expect(CNContactSortOrder.familyName.rawValue == 3, "sort family")
expect(CNContactSortOrder.givenName != .familyName, "sort inequality")
expect(CNContactType.person.rawValue == 0, "person type")
expect(CNContactType.organization.rawValue == 1, "org type")
expect(CNContactType.person != .organization, "contact type inequality")
expect(CNEntityType.contacts.rawValue == 0, "entity")
expect(CNContainerType.unassigned.rawValue == 0, "unassigned")
expect(CNContainerType.local.rawValue == 1, "local container type")
expect(CNContainerType.exchange.rawValue == 2, "exchange")
expect(CNContainerType.cardDAV.rawValue == 3, "carddav")
expect(CNContainerType.local != .exchange, "container inequality")
expect(CNContactDisplayNameOrder.userDefault.rawValue == 0, "display userDefault")
expect(CNContactDisplayNameOrder.givenNameFirst.rawValue == 1, "display given first")
expect(CNContactDisplayNameOrder.familyNameFirst.rawValue == 2, "display order")
expect(CNContactDisplayNameOrder.givenNameFirst != .familyNameFirst, "display inequality")
expect(CNContactFormatterStyle.fullName.rawValue == 0, "full name style")
expect(CNContactFormatterStyle.phoneticFullName.rawValue == 1, "formatter style")
expect(CNContactFormatterStyle.fullName != .phoneticFullName, "formatter inequality")
expect(CNPostalAddressFormatterStyle.mailingAddress.rawValue == 0, "postal style")
expect(CNError.Code.authorizationDenied.rawValue == 100, "auth denied code")
expect(CNError.featureNotAvailable.rawValue == 104, "feature not available")
expect(CNError.recordDoesNotExist.rawValue == 200, "record does not exist")
expect(CNError.insertedRecordAlreadyExists.rawValue == 201, "already exists")
expect(CNError.predicateInvalid.rawValue == 400, "predicate invalid")
expect(CNError.Code(rawValue: 100) == .authorizationDenied, "error rawValue init")
expect(CNAuthorizationStatus(rawValue: 0) == .notDetermined, "auth rawValue init")
expect(CNContactSortOrder(rawValue: 3) == .familyName, "sort rawValue init")
expect(CNContactType(rawValue: 1) == .organization, "type rawValue init")
expect(CNEntityType(rawValue: 0) == .contacts, "entity rawValue init")
expect(CNContainerType(rawValue: 3) == .cardDAV, "container rawValue init")
expect(CNContactFormatterStyle(rawValue: 1) == .phoneticFullName, "formatter rawValue init")
expect(CNContactDisplayNameOrder(rawValue: 2) == .familyNameFirst, "display rawValue init")
expect(CNPostalAddressFormatterStyle(rawValue: 0) == .mailingAddress, "postal rawValue init")
var hasher = Hasher()
CNAuthorizationStatus.authorized.hash(into: &hasher)
CNContactSortOrder.givenName.hash(into: &hasher)
CNContactType.person.hash(into: &hasher)
CNContainerType.local.hash(into: &hasher)
CNEntityType.contacts.hash(into: &hasher)
CNContactDisplayNameOrder.givenNameFirst.hash(into: &hasher)
CNContactFormatterStyle.fullName.hash(into: &hasher)
CNPostalAddressFormatterStyle.mailingAddress.hash(into: &hasher)
CNError.Code.authorizationDenied.hash(into: &hasher)
_ = hasher.finalize()
_ = CNContactSortOrder.givenName.hashValue
_ = CNContactDisplayNameOrder.givenNameFirst.hashValue
_ = CNContactFormatterStyle.fullName.hashValue
_ = CNContactType.person.hashValue
_ = CNContainerType.local.hashValue
_ = CNEntityType.contacts.hashValue
_ = CNPostalAddressFormatterStyle.mailingAddress.hashValue
_ = CNError.Code.authorizationDenied.hashValue

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
        keysToFetch: keys(CNContactGivenNameKey)
    )
    fail("fetch must fail closed before requestAccess")
} catch let error as CNError {
    expect(error.code == .authorizationDenied, "fail closed authorization")
} catch {
    fail("unexpected error \(error)")
}

var requestAccessReturned = false
var granted = false
var grantError: Error?
let grantedSem = DispatchSemaphore(value: 0)
store.requestAccess(for: .contacts) { ok, error in
    expect(requestAccessReturned, "requestAccess callback is not reentrant on the calling stack")
    granted = ok
    grantError = error
    _ = try? store.containers(matching: nil)
    var nestedReturned = false
    let nestedSem = DispatchSemaphore(value: 0)
    store.requestAccess(for: .contacts) { nestedGranted, nestedError in
        expect(nestedReturned, "nested requestAccess callback is not reentrant")
        expect(nestedGranted && nestedError == nil, "nested requestAccess")
        nestedSem.signal()
    }
    nestedReturned = true
    wait(nestedSem, "nested requestAccess deadlock")
    grantedSem.signal()
}
requestAccessReturned = true
wait(grantedSem, "requestAccess callback deadlock")
expect(grantError == nil, "requestAccess error")
expect(granted, "in-memory requestAccess")
expect(
    CNContactStore.authorizationStatus(for: .contacts) == .authorized,
    "authorized after request"
)

let asyncGrantedSem = DispatchSemaphore(value: 0)
var asyncGranted = false
Task {
    do {
        asyncGranted = try await store.requestAccess(for: .contacts)
    } catch {
        fail("async requestAccess \(error)")
    }
    asyncGrantedSem.signal()
}
wait(asyncGrantedSem, "async requestAccess deadlock")
expect(asyncGranted, "async requestAccess grants the in-memory sandbox")

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
let givenDescriptor: any CNKeyDescriptor = CNContactGivenNameKey as NSString
let boxedDescriptor: Any = givenDescriptor
expect(boxedDescriptor is NSString, "String keys are NSString descriptors")
expect(boxedDescriptor is NSCopying, "descriptor NSCopying")
expect(boxedDescriptor is NSSecureCoding, "descriptor NSSecureCoding")
expect(boxedDescriptor is NSObjectProtocol, "descriptor NSObjectProtocol")
_ = (givenDescriptor as NSCopying).copy(with: nil)

let formatted = CNContactFormatter.string(from: contact, style: .fullName)
expect(formatted == "Ms Ada Byron Lovelace Countess", "full name \(String(describing: formatted))")
let phonetic = CNContactFormatter.string(from: contact, style: .phoneticFullName)
expect(phonetic == "Ay-duh By-ron Love-lace", "phonetic \(String(describing: phonetic))")
expect(CNContactFormatter.nameOrder(for: contact) == .givenNameFirst, "name order")
expect(CNContactFormatter.delimiter(for: contact) == " ", "delimiter")
expect(
    CNContactFormatter.attributedString(from: contact, style: .fullName)?.string == "Ms Ada Byron Lovelace Countess",
    "attributed name"
)
let formatter = CNContactFormatter()
formatter.style = .fullName
expect(formatter.string(from: contact) == "Ms Ada Byron Lovelace Countess", "instance formatter")
expect(formatter.attributedString(from: contact)?.string == "Ms Ada Byron Lovelace Countess", "instance attributed")

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
expect(CNSocialProfile.localizedString(forService: CNSocialProfileServiceTwitter) == "Twitter", "social service")

let labeled = CNLabeledValue(label: CNLabelWork, value: "work@example.com" as NSString)
let relabeled = labeled.settingLabel(CNLabelOther)
expect(relabeled.label == CNLabelOther, "relabel")
expect(relabeled.identifier == labeled.identifier, "stable labeled identifier")
expect((relabeled.settingValue("other@example.com" as NSString).value as String) == "other@example.com", "set value")

let emptyPhone = CNPhoneNumber.new()
expect(emptyPhone.stringValue == "", "empty phone")
expect(!emptyPhone.initialCountryCode.isEmpty, "phone initialCountryCode")

var observerQueries = 0
let observer = NotificationCenter.default.addObserver(
    forName: .CNContactStoreDidChange,
    object: store,
    queue: nil
) { _ in
    let containers = try? store.containers(matching: nil)
    expect(containers?.count == 1, "observer reentered containers()")
    let custom = NSPredicate { object, _ in
        _ = store.defaultContainerIdentifier()
        return object is CNGroup
    }
    _ = try? store.groups(matching: custom)
    observerQueries += 1
}

let save = CNSaveRequest()
save.transactionAuthor = "ContactsRuntime"
save.shouldRefetchContacts = true
save.add(contact, toContainerWithIdentifier: nil)

let group = CNMutableGroup()
group.name = "Scientists"
save.add(group, toContainerWithIdentifier: nil)
try! store.execute(save)
expect(observerQueries >= 1, "did-change observer ran without deadlock")

let fetched = try! store.unifiedContacts(
    matching: CNContact.predicateForContacts(matchingName: "Ada"),
    keysToFetch: keys(
        CNContactGivenNameKey,
        CNContactFamilyNameKey,
        CNContactEmailAddressesKey,
        CNContactPhoneNumbersKey
    )
)
expect(fetched.count == 1, "fetched ada")
expect(fetched[0].givenName == "Ada", "fetched given")
expect(fetched[0].isKeyAvailable(CNContactEmailAddressesKey), "email key fetched")

let byEmail = try! store.unifiedContacts(
    matching: CNContact.predicateForContacts(matchingEmailAddress: "ada@example.com"),
    keysToFetch: keys(CNContactIdentifierKey)
)
expect(byEmail.count == 1, "email predicate")
let byPhone = try! store.unifiedContacts(
    matching: CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: "+1-555-0100")),
    keysToFetch: keys(CNContactIdentifierKey)
)
expect(byPhone.count == 1, "phone predicate")
let byID = try! store.unifiedContact(
    withIdentifier: contact.identifier,
    keysToFetch: keys(CNContactGivenNameKey)
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
    keysToFetch: keys(CNContactGivenNameKey)
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
let request = CNContactFetchRequest(keysToFetch: keys(CNContactGivenNameKey, CNContactFamilyNameKey))
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

let customPredicate = NSPredicate { object, _ in
    _ = try? store.containers(matching: nil)
    return (object as? CNContact)?.givenName == "Ada"
}
let customHits = try! store.unifiedContacts(
    matching: customPredicate,
    keysToFetch: keys(CNContactGivenNameKey)
)
expect(customHits.count == 1, "custom predicate reentered store without deadlock")

let rejectAll = NSPredicate { _, _ in false }
let rejected = try! store.unifiedContacts(
    matching: rejectAll,
    keysToFetch: keys(CNContactIdentifierKey)
)
expect(rejected.isEmpty, "untagged custom predicate is not misclassified")

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
    keysToFetch: keys(CNContactFamilyNameKey)
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

let attestedCodes: [CNError.Code] = [
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
    CNError.validationMultipleErrors,
    CNError.validationTypeMismatch,
    CNError.validationConfigurationError,
    CNError.predicateInvalid,
    CNError.policyViolation,
]
expect(Set(attestedCodes.map(\.rawValue)).count == attestedCodes.count, "unique attested error aliases")
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
    keysToFetch: keys(CNContactIdentifierKey)
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
historyRequest.additionalContactKeyDescriptors = keys(CNContactGivenNameKey)
historyRequest.excludedTransactionAuthors = ["ContactsRuntime"]
_ = CNFetchRequest()

let postalCopy = postal.copy() as! CNPostalAddress
expect(postalCopy.city == "London", "postal copy")
let postalMutable = postalCopy.mutableCopy() as! CNMutablePostalAddress
postalMutable.city = "Bath"
expect(postalCopy.city == "London", "postal copy independence")
expect(CNContactRelation(name: "X").name == "X", "relation name")
expect(!contact.isUnifiedWithContact(withIdentifier: "missing"), "not unified")

expect(contact.thumbnailImageData == contact.imageData, "thumbnail equals imageData")
let nicknameOnly = CNMutableContact()
nicknameOnly.nickname = "OnlyNick"
expect(CNContactFormatter.string(from: nicknameOnly, style: .fullName) == "OnlyNick", "nickname fallback")
let orgOnly = CNMutableContact()
orgOnly.contactType = .organization
orgOnly.organizationName = "Analytical Co"
expect(CNContactFormatter.string(from: orgOnly, style: .fullName) == "Analytical Co", "organization fallback")

let usAddress = CNMutablePostalAddress()
usAddress.street = "1 Market St"
usAddress.city = "San Francisco"
usAddress.state = "CA"
usAddress.postalCode = "94105"
usAddress.country = "United States"
usAddress.isoCountryCode = "US"
let usMailing = CNPostalAddressFormatter.string(from: usAddress, style: .mailingAddress)
expect(usMailing.contains("San Francisco, CA 94105"), "US city/state/ZIP layout \(usMailing)")

let partial = try! store.unifiedContact(
    withIdentifier: contact.identifier,
    keysToFetch: keys(CNContactGivenNameKey)
)
expect(partial.isKeyAvailable(CNContactGivenNameKey), "fetched given available")
expect(!partial.isKeyAvailable(CNContactEmailAddressesKey), "unfetched email")
do {
    try partial.requireKeyAvailable(CNContactEmailAddressesKey)
    fail("unfetched key must throw")
} catch let error as CNError {
    expect(error.code == .unauthorizedKeys, "unauthorizedKeys on unfetched access")
    expect(error.keyPaths == [CNContactEmailAddressesKey], "unauthorized key path")
} catch {
    fail("unexpected unfetched error \(error)")
}
do {
    try partial.requireKeysAvailable(keys(CNContactEmailAddressesKey, CNContactPhoneNumbersKey))
    fail("areKeysAvailable-style require must throw")
} catch let error as CNError {
    expect(error.code == .unauthorizedKeys, "unauthorizedKeys for missing descriptors")
} catch {
    fail("unexpected requireKeys \(error)")
}
_ = partial.emailAddresses
let unfetched = CNContact._consumeUnfetchedKeyError()
expect(unfetched?.code == .unauthorizedKeys, "getter records unauthorizedKeys")

CNContactStore._reloadPortableStoreFromDisk()
let reloaded = try! CNContactStore().unifiedContact(
    withIdentifier: contact.identifier,
    keysToFetch: keys(CNContactFamilyNameKey, CNContactGivenNameKey, CNContactImageDataKey, CNContactThumbnailImageDataKey)
)
expect(reloaded.familyName == "King", "directory store survived reload")
expect(reloaded.givenName == "Ada", "directory store given name")
expect(reloaded.thumbnailImageData == Data([0x00, 0x01, 0x02]), "persisted thumbnail")
expect(
    FileManager.default.fileExists(
        atPath: CNContactStore._portableStoreDirectory().appendingPathComponent("store.json").path
    ),
    "store.json exists"
)

let invalid = CNMutableContact()
invalid.givenName = "BadDate"
invalid.birthday = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2000, month: 99, day: 99)
let invalidSave = CNSaveRequest()
invalidSave.add(invalid, toContainerWithIdentifier: nil)
do {
    try store.execute(invalidSave)
    fail("invalid birthday must fail validation")
} catch let error as CNError {
    expect(error.code == .validationMultipleErrors, "validationMultipleErrors \(error.code)")
    expect(error.userInfo[CNErrorUserInfoValidationErrorsKey] != nil, "validation errors userInfo")
    expect(error.affectedRecordIdentifiers == [invalid.identifier], "validation affected ids")
    expect(error.keyPaths?.contains(CNContactBirthdayKey) == true, "validation keyPaths")
} catch {
    fail("unexpected validation error \(error)")
}

let foreign = CNMutableContact()
foreign.givenName = "CardDAV"
let foreignSave = CNSaveRequest()
foreignSave.add(foreign, toContainerWithIdentifier: "icloud-not-attached")
do {
    try store.execute(foreignSave)
    fail("non-local container must fail closed")
} catch let error as CNError {
    expect(error.code == .parentContainerNotWritable, "parentContainerNotWritable")
} catch {
    fail("unexpected container error \(error)")
}

do {
    _ = try store.unifiedContact(withIdentifier: "no-such-record", keysToFetch: keys(CNContactIdentifierKey))
    fail("missing unifiedContact must throw")
} catch let error as CNError {
    expect(error.code == .recordDoesNotExist, "recordDoesNotExist")
    expect(error.affectedRecordIdentifiers == ["no-such-record"], "missing id userInfo")
} catch {
    fail("unexpected missing contact \(error)")
}

let archivedContact = try! NSKeyedArchiver.archivedData(withRootObject: contact, requiringSecureCoding: true)
let unarchivedContact = try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNContact.self, from: archivedContact)
expect(unarchivedContact?.givenName == "Ada", "CNContact nscoding")
expect(unarchivedContact?.birthday?.year == 1815, "CNContact birthday nscoding")

let archivedGroup = try! NSKeyedArchiver.archivedData(withRootObject: group, requiringSecureCoding: true)
let unarchivedGroup = try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNGroup.self, from: archivedGroup)
expect(unarchivedGroup?.name == "Scientists", "CNGroup nscoding")

let archivedContainer = try! NSKeyedArchiver.archivedData(
    withRootObject: CNContainer(identifier: "c", name: "n", type: .local),
    requiringSecureCoding: true
)
let unarchivedContainer = try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNContainer.self, from: archivedContainer)
expect(unarchivedContainer?.type == .local, "CNContainer nscoding")

let archivedRelation = try! NSKeyedArchiver.archivedData(
    withRootObject: CNContactRelation(name: "Ada"),
    requiringSecureCoding: true
)
expect(
    try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNContactRelation.self, from: archivedRelation)?.name == "Ada",
    "CNContactRelation nscoding"
)

let archivedIM = try! NSKeyedArchiver.archivedData(
    withRootObject: CNInstantMessageAddress(username: "ada", service: CNInstantMessageServiceJabber),
    requiringSecureCoding: true
)
expect(
    try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNInstantMessageAddress.self, from: archivedIM)?.username == "ada",
    "CNInstantMessageAddress nscoding"
)

let archivedSocial = try! NSKeyedArchiver.archivedData(
    withRootObject: CNSocialProfile(urlString: "u", username: "n", userIdentifier: "i", service: "s"),
    requiringSecureCoding: true
)
expect(
    try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNSocialProfile.self, from: archivedSocial)?.username == "n",
    "CNSocialProfile nscoding"
)

let archivedPostal = try! NSKeyedArchiver.archivedData(withRootObject: postal, requiringSecureCoding: true)
expect(
    try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNPostalAddress.self, from: archivedPostal)?.city == "London",
    "CNPostalAddress nscoding"
)

let fetchRequestArchive = try! NSKeyedArchiver.archivedData(withRootObject: request, requiringSecureCoding: true)
let unarchivedFetch = try! NSKeyedUnarchiver.unarchivedObject(
    ofClass: CNContactFetchRequest.self,
    from: fetchRequestArchive
)
expect(unarchivedFetch?.sortOrder == .familyName, "CNContactFetchRequest nscoding")

let historyArchive = try! NSKeyedArchiver.archivedData(
    withRootObject: CNChangeHistoryDropEverythingEvent(),
    requiringSecureCoding: true
)
expect(
    try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNChangeHistoryDropEverythingEvent.self, from: historyArchive) != nil,
    "CNChangeHistoryEvent nscoding"
)

let historyRequestArchive = try! NSKeyedArchiver.archivedData(withRootObject: historyRequest, requiringSecureCoding: true)
expect(
    try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: CNChangeHistoryFetchRequest.self,
        from: historyRequestArchive
    )?.includeGroupChanges == true,
    "CNChangeHistoryFetchRequest nscoding"
)

let propertyArchive = try! NSKeyedArchiver.archivedData(withRootObject: property, requiringSecureCoding: true)
expect(
    try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNContactProperty.self, from: propertyArchive)?.key
        == CNContactGivenNameKey,
    "CNContactProperty nscoding"
)

do {
    try CNContactPickerViewController().presentPicker()
    fail("picker must fail closed")
} catch let error as CNError {
    expect(error.code == .featureNotAvailable, "picker requires UIKit/ContactsUI")
} catch {
    fail("unexpected picker error \(error)")
}

expect(CNError.vCardMalformed != CNError.vCardSummarizationError, "vcard error inequality")
expect(CNError.changeHistoryExpired != CNError.changeHistoryInvalidAnchor, "history error inequality")
expect(CNError.clientIdentifierInvalid != CNError.clientIdentifierCollision, "client id error inequality")
expect(CNError.parentContainerNotWritable.rawValue == 207, "parentContainerNotWritable alias")
_ = CNError.changeHistoryInvalidFetchRequest
_ = CNError.clientIdentifierDoesNotExist

let mutableEnumerate = CNContactFetchRequest(keysToFetch: keys(CNContactGivenNameKey, CNContactFamilyNameKey))
mutableEnumerate.mutableObjects = true
mutableEnumerate.unifyResults = false
mutableEnumerate.sortOrder = .givenName
var mutableCount = 0
try! store.enumerateContacts(with: mutableEnumerate) { item, _ in
    expect(item is CNMutableContact, "mutableObjects honored")
    mutableCount += 1
}
expect(mutableCount >= 1, "mutable enumerate")

let rolledInsert = CNMutableContact()
rolledInsert.givenName = "RollbackA"
let duplicateInsert = CNSaveRequest()
duplicateInsert.add(rolledInsert, toContainerWithIdentifier: nil)
duplicateInsert.add(rolledInsert, toContainerWithIdentifier: nil)
do {
    try store.execute(duplicateInsert)
    fail("duplicate insert must fail the whole transaction")
} catch let error as CNError {
    expect(error.code == .insertedRecordAlreadyExists, "duplicate insert code")
} catch {
    fail("unexpected rollback error \(error)")
}
let rolledHits = try! store.unifiedContacts(
    matching: CNContact.predicateForContacts(matchingName: "RollbackA"),
    keysToFetch: keys(CNContactGivenNameKey)
)
expect(rolledHits.isEmpty, "valid insert rolled back after later duplicate")

let keep = CNMutableContact()
keep.givenName = "KeepMe"
let ghost = CNMutableContact()
ghost.givenName = "Ghost"
let updateMissing = CNSaveRequest()
updateMissing.add(keep, toContainerWithIdentifier: nil)
updateMissing.update(ghost)
do {
    try store.execute(updateMissing)
    fail("update of missing contact must fail the whole transaction")
} catch let error as CNError {
    expect(error.code == .recordDoesNotExist, "missing update code")
} catch {
    fail("unexpected missing-update error \(error)")
}
let keepHits = try! store.unifiedContacts(
    matching: CNContact.predicateForContacts(matchingName: "KeepMe"),
    keysToFetch: keys(CNContactGivenNameKey)
)
expect(keepHits.isEmpty, "valid insert rolled back after later invalid update")

let remove = CNSaveRequest()
remove.removeMember(contact, from: group)
remove.delete(group)
let doomed = updated.mutableCopy() as! CNMutableContact
remove.delete(doomed)
try! store.execute(remove)
let remaining = try! store.unifiedContacts(
    matching: CNContact.predicateForContacts(withIdentifiers: [contact.identifier]),
    keysToFetch: keys(CNContactIdentifierKey)
)
expect(remaining.isEmpty, "deleted contact")

expect(NSNotification.Name.CNContactStoreDidChange.rawValue == "CNContactStoreDidChangeNotification", "note name")
NotificationCenter.default.removeObserver(observer)

print("CONTACTS_AGENT_RUNTIME_OK")
