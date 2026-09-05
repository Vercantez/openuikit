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

final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

func resetIsolatedStore() {
    let storeRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent(
            "openuikit-contacts-\(ProcessInfo.processInfo.processIdentifier)-\(UUID().uuidString)",
            isDirectory: true
        )
    try! FileManager.default.createDirectory(at: storeRoot, withIntermediateDirectories: true)
    _ = storeRoot.path.withCString { path in
        "OPENUIKIT_CONTACTS_DIRECTORY".withCString { key in
            setenv(key, path, 1)
        }
    }
    CNContactStore._resetPortableStore()
}

func authorizeStore() -> CNContactStore {
    let store = CNContactStore()
    let grantedSem = DispatchSemaphore(value: 0)
    let granted = Box(false)
    let grantError = Box<Error?>(nil)
    store.requestAccess(for: .contacts) { ok, error in
        granted.value = ok
        grantError.value = error
        grantedSem.signal()
    }
    wait(grantedSem, "authorizeStore deadlock")
    expect(grantError.value == nil && granted.value, "authorizeStore requestAccess")
    return store
}

func makeAdaContact() -> CNMutableContact {
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
    return contact
}

final class RecordingVisitor: NSObject, CNChangeHistoryEventVisitor {
    var addContacts = 0
    var deleteContacts = 0
    var drops = 0
    var updateContacts = 0
    var addGroups = 0
    var deleteGroups = 0
    var updateGroups = 0
    var addMembers = 0
    var addSubgroups = 0
    var removeMembers = 0
    var removeSubgroups = 0

    func visit(_ event: CNChangeHistoryAddContactEvent) { addContacts += 1 }
    func visit(_ event: CNChangeHistoryDeleteContactEvent) { deleteContacts += 1 }
    func visit(_ event: CNChangeHistoryDropEverythingEvent) { drops += 1 }
    func visit(_ event: CNChangeHistoryUpdateContactEvent) { updateContacts += 1 }
    func visit(_ event: CNChangeHistoryAddGroupEvent) { addGroups += 1 }
    func visit(_ event: CNChangeHistoryDeleteGroupEvent) { deleteGroups += 1 }
    func visit(_ event: CNChangeHistoryUpdateGroupEvent) { updateGroups += 1 }
    func visitAddMember(_ event: CNChangeHistoryAddMemberToGroupEvent) { addMembers += 1 }
    func visitAddSubgroup(_ event: CNChangeHistoryAddSubgroupToGroupEvent) { addSubgroups += 1 }
    func visitRemoveMember(_ event: CNChangeHistoryRemoveMemberFromGroupEvent) { removeMembers += 1 }
    func visitRemoveSubgroup(_ event: CNChangeHistoryRemoveSubgroupFromGroupEvent) { removeSubgroups += 1 }
}


// --- ContactsCodingTests.swift ---
func testSecureCodingRoundTrip() {
    let contact = makeAdaContact()
    let group = CNMutableGroup()
    group.name = "Scientists"
    let postal = contact.postalAddresses[0].value
    let request = CNContactFetchRequest(keysToFetch: keys(CNContactGivenNameKey, CNContactFamilyNameKey))
    request.sortOrder = .familyName
    let historyRequest = CNChangeHistoryFetchRequest()
    historyRequest.includeGroupChanges = true
    let property = CNContactProperty(contact: contact, key: CNContactGivenNameKey, value: contact.givenName as NSString)

    let archivedContact = try! NSKeyedArchiver.archivedData(withRootObject: contact, requiringSecureCoding: true)
    let unarchivedContact = try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNContact.self, from: archivedContact)
    expect(unarchivedContact?.givenName == "Ada", "CNContact nscoding")
    expect(unarchivedContact?.birthday?.year == 1815, "CNContact birthday nscoding")

    let archivedPhone = try! NSKeyedArchiver.archivedData(
        withRootObject: CNPhoneNumber(stringValue: "555"),
        requiringSecureCoding: true
    )
    expect(
        try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNPhoneNumber.self, from: archivedPhone)?.stringValue == "555",
        "CNPhoneNumber nscoding"
    )

    let archivedGroup = try! NSKeyedArchiver.archivedData(withRootObject: group, requiringSecureCoding: true)
    expect(
        try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNGroup.self, from: archivedGroup)?.name == "Scientists",
        "CNGroup nscoding"
    )

    let archivedContainer = try! NSKeyedArchiver.archivedData(
        withRootObject: CNContainer(identifier: "c", name: "n", type: .local),
        requiringSecureCoding: true
    )
    expect(
        try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNContainer.self, from: archivedContainer)?.type == .local,
        "CNContainer nscoding"
    )

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
    expect(
        try! NSKeyedUnarchiver.unarchivedObject(ofClass: CNContactFetchRequest.self, from: fetchRequestArchive)?.sortOrder
            == .familyName,
        "CNContactFetchRequest nscoding"
    )

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
}

// --- ContactsConstantsTests.swift ---
func testPublicStringConstants() {
    let pairs: [(String, String)] = [
        (CNContactBirthdayKey, "birthday"),
        (CNContactDatesKey, "dates"),
        (CNContactDepartmentNameKey, "departmentName"),
        (CNContactEmailAddressesKey, "emailAddresses"),
        (CNContactFamilyNameKey, "familyName"),
        (CNContactGivenNameKey, "givenName"),
        (CNContactIdentifierKey, "identifier"),
        (CNContactImageDataAvailableKey, "imageDataAvailable"),
        (CNContactImageDataKey, "imageData"),
        (CNContactInstantMessageAddressesKey, "instantMessageAddresses"),
        (CNContactJobTitleKey, "jobTitle"),
        (CNContactMiddleNameKey, "middleName"),
        (CNContactNamePrefixKey, "namePrefix"),
        (CNContactNameSuffixKey, "nameSuffix"),
        (CNContactNicknameKey, "nickname"),
        (CNContactNonGregorianBirthdayKey, "nonGregorianBirthday"),
        (CNContactNoteKey, "note"),
        (CNContactOrganizationNameKey, "organizationName"),
        (CNContactPhoneNumbersKey, "phoneNumbers"),
        (CNContactPhoneticFamilyNameKey, "phoneticFamilyName"),
        (CNContactPhoneticGivenNameKey, "phoneticGivenName"),
        (CNContactPhoneticMiddleNameKey, "phoneticMiddleName"),
        (CNContactPhoneticOrganizationNameKey, "phoneticOrganizationName"),
        (CNContactPostalAddressesKey, "postalAddresses"),
        (CNContactPreviousFamilyNameKey, "previousFamilyName"),
        (CNContactPropertyAttribute, "CNContactPropertyAttribute"),
        (CNContactPropertyNotFetchedExceptionName, "CNContactPropertyNotFetchedExceptionName"),
        (CNContactRelationsKey, "contactRelations"),
        (CNContactSocialProfilesKey, "socialProfiles"),
        (CNContactThumbnailImageDataKey, "thumbnailImageData"),
        (CNContactTypeKey, "contactType"),
        (CNContactUrlAddressesKey, "urlAddresses"),
        (CNContainerIdentifierKey, "identifier"),
        (CNContainerNameKey, "name"),
        (CNContainerTypeKey, "type"),
        (CNErrorDomain, "CNErrorDomain"),
        (CNErrorUserInfoAffectedRecordIdentifiersKey, "CNErrorUserInfoAffectedRecordIdentifiersKey"),
        (CNErrorUserInfoAffectedRecordsKey, "CNErrorUserInfoAffectedRecordsKey"),
        (CNErrorUserInfoKeyPathsKey, "CNErrorUserInfoKeyPathsKey"),
        (CNErrorUserInfoValidationErrorsKey, "CNErrorUserInfoValidationErrorsKey"),
        (CNGroupIdentifierKey, "identifier"),
        (CNGroupNameKey, "name"),
        (CNInstantMessageAddressServiceKey, "service"),
        (CNInstantMessageAddressUsernameKey, "username"),
        (CNInstantMessageServiceAIM, "AIM"),
        (CNInstantMessageServiceFacebook, "Facebook"),
        (CNInstantMessageServiceGaduGadu, "GaduGadu"),
        (CNInstantMessageServiceGoogleTalk, "GoogleTalk"),
        (CNInstantMessageServiceICQ, "ICQ"),
        (CNInstantMessageServiceJabber, "Jabber"),
        (CNInstantMessageServiceMSN, "MSN"),
        (CNInstantMessageServiceQQ, "QQ"),
        (CNInstantMessageServiceSkype, "Skype"),
        (CNInstantMessageServiceYahoo, "Yahoo"),
        (CNLabelContactRelationAssistant, "_$!<Assistant>!$_"),
        (CNLabelContactRelationAunt, "_$!<Aunt>!$_"),
        (CNLabelContactRelationAuntFathersBrothersWife, "_$!<AuntFathersBrothersWife>!$_"),
        (CNLabelContactRelationAuntFathersElderBrothersWife, "_$!<AuntFathersElderBrothersWife>!$_"),
        (CNLabelContactRelationAuntFathersElderSister, "_$!<AuntFathersElderSister>!$_"),
        (CNLabelContactRelationAuntFathersSister, "_$!<AuntFathersSister>!$_"),
        (CNLabelContactRelationAuntFathersYoungerBrothersWife, "_$!<AuntFathersYoungerBrothersWife>!$_"),
        (CNLabelContactRelationAuntFathersYoungerSister, "_$!<AuntFathersYoungerSister>!$_"),
        (CNLabelContactRelationAuntMothersBrothersWife, "_$!<AuntMothersBrothersWife>!$_"),
        (CNLabelContactRelationAuntMothersElderSister, "_$!<AuntMothersElderSister>!$_"),
        (CNLabelContactRelationAuntMothersSister, "_$!<AuntMothersSister>!$_"),
        (CNLabelContactRelationAuntMothersYoungerSister, "_$!<AuntMothersYoungerSister>!$_"),
        (CNLabelContactRelationAuntParentsElderSister, "_$!<AuntParentsElderSister>!$_"),
        (CNLabelContactRelationAuntParentsSister, "_$!<AuntParentsSister>!$_"),
        (CNLabelContactRelationAuntParentsYoungerSister, "_$!<AuntParentsYoungerSister>!$_"),
        (CNLabelContactRelationBoyfriend, "_$!<Boyfriend>!$_"),
        (CNLabelContactRelationBrother, "_$!<Brother>!$_"),
        (CNLabelContactRelationBrotherInLaw, "_$!<BrotherInLaw>!$_"),
        (CNLabelContactRelationBrotherInLawElderSistersHusband, "_$!<BrotherInLawElderSistersHusband>!$_"),
        (CNLabelContactRelationBrotherInLawHusbandsBrother, "_$!<BrotherInLawHusbandsBrother>!$_"),
        (CNLabelContactRelationBrotherInLawHusbandsSistersHusband, "_$!<BrotherInLawHusbandsSistersHusband>!$_"),
        (CNLabelContactRelationBrotherInLawSistersHusband, "_$!<BrotherInLawSistersHusband>!$_"),
        (CNLabelContactRelationBrotherInLawSpousesBrother, "_$!<BrotherInLawSpousesBrother>!$_"),
        (CNLabelContactRelationBrotherInLawWifesBrother, "_$!<BrotherInLawWifesBrother>!$_"),
        (CNLabelContactRelationBrotherInLawWifesSistersHusband, "_$!<BrotherInLawWifesSistersHusband>!$_"),
        (CNLabelContactRelationBrotherInLawYoungerSistersHusband, "_$!<BrotherInLawYoungerSistersHusband>!$_"),
        (CNLabelContactRelationChild, "_$!<Child>!$_"),
        (CNLabelContactRelationChildInLaw, "_$!<ChildInLaw>!$_"),
        (CNLabelContactRelationCoBrotherInLaw, "_$!<CoBrotherInLaw>!$_"),
        (CNLabelContactRelationCoFatherInLaw, "_$!<CoFatherInLaw>!$_"),
        (CNLabelContactRelationCoMotherInLaw, "_$!<CoMotherInLaw>!$_"),
        (CNLabelContactRelationCoParentInLaw, "_$!<CoParentInLaw>!$_"),
        (CNLabelContactRelationCoSiblingInLaw, "_$!<CoSiblingInLaw>!$_"),
        (CNLabelContactRelationCoSisterInLaw, "_$!<CoSisterInLaw>!$_"),
        (CNLabelContactRelationColleague, "_$!<Colleague>!$_"),
        (CNLabelContactRelationCousin, "_$!<Cousin>!$_"),
        (CNLabelContactRelationCousinFathersBrothersDaughter, "_$!<CousinFathersBrothersDaughter>!$_"),
        (CNLabelContactRelationCousinFathersBrothersSon, "_$!<CousinFathersBrothersSon>!$_"),
        (CNLabelContactRelationCousinFathersSistersDaughter, "_$!<CousinFathersSistersDaughter>!$_"),
        (CNLabelContactRelationCousinFathersSistersSon, "_$!<CousinFathersSistersSon>!$_"),
        (CNLabelContactRelationCousinGrandparentsSiblingsChild, "_$!<CousinGrandparentsSiblingsChild>!$_"),
        (CNLabelContactRelationCousinGrandparentsSiblingsDaughter, "_$!<CousinGrandparentsSiblingsDaughter>!$_"),
        (CNLabelContactRelationCousinGrandparentsSiblingsSon, "_$!<CousinGrandparentsSiblingsSon>!$_"),
        (CNLabelContactRelationCousinMothersBrothersDaughter, "_$!<CousinMothersBrothersDaughter>!$_"),
        (CNLabelContactRelationCousinMothersBrothersSon, "_$!<CousinMothersBrothersSon>!$_"),
        (CNLabelContactRelationCousinMothersSistersDaughter, "_$!<CousinMothersSistersDaughter>!$_"),
        (CNLabelContactRelationCousinMothersSistersSon, "_$!<CousinMothersSistersSon>!$_"),
        (CNLabelContactRelationCousinOrSiblingsChild, "_$!<CousinOrSiblingsChild>!$_"),
        (CNLabelContactRelationCousinParentsSiblingsChild, "_$!<CousinParentsSiblingsChild>!$_"),
        (CNLabelContactRelationCousinParentsSiblingsDaughter, "_$!<CousinParentsSiblingsDaughter>!$_"),
        (CNLabelContactRelationCousinParentsSiblingsSon, "_$!<CousinParentsSiblingsSon>!$_"),
        (CNLabelContactRelationDaughter, "_$!<Daughter>!$_"),
        (CNLabelContactRelationDaughterInLaw, "_$!<DaughterInLaw>!$_"),
        (CNLabelContactRelationDaughterInLawOrSisterInLaw, "_$!<DaughterInLawOrSisterInLaw>!$_"),
        (CNLabelContactRelationDaughterInLawOrStepdaughter, "_$!<DaughterInLawOrStepdaughter>!$_"),
        (CNLabelContactRelationElderBrother, "_$!<ElderBrother>!$_"),
        (CNLabelContactRelationElderBrotherInLaw, "_$!<ElderBrotherInLaw>!$_"),
        (CNLabelContactRelationElderCousin, "_$!<ElderCousin>!$_"),
        (CNLabelContactRelationElderCousinFathersBrothersDaughter, "_$!<ElderCousinFathersBrothersDaughter>!$_"),
        (CNLabelContactRelationElderCousinFathersBrothersSon, "_$!<ElderCousinFathersBrothersSon>!$_"),
        (CNLabelContactRelationElderCousinFathersSistersDaughter, "_$!<ElderCousinFathersSistersDaughter>!$_"),
        (CNLabelContactRelationElderCousinFathersSistersSon, "_$!<ElderCousinFathersSistersSon>!$_"),
        (CNLabelContactRelationElderCousinMothersBrothersDaughter, "_$!<ElderCousinMothersBrothersDaughter>!$_"),
        (CNLabelContactRelationElderCousinMothersBrothersSon, "_$!<ElderCousinMothersBrothersSon>!$_"),
        (CNLabelContactRelationElderCousinMothersSiblingsDaughterOrFathersSistersDaughter, "_$!<ElderCousinMothersSiblingsDaughterOrFathersSistersDaughter>!$_"),
        (CNLabelContactRelationElderCousinMothersSiblingsSonOrFathersSistersSon, "_$!<ElderCousinMothersSiblingsSonOrFathersSistersSon>!$_"),
        (CNLabelContactRelationElderCousinMothersSistersDaughter, "_$!<ElderCousinMothersSistersDaughter>!$_"),
        (CNLabelContactRelationElderCousinMothersSistersSon, "_$!<ElderCousinMothersSistersSon>!$_"),
        (CNLabelContactRelationElderCousinParentsSiblingsDaughter, "_$!<ElderCousinParentsSiblingsDaughter>!$_"),
        (CNLabelContactRelationElderCousinParentsSiblingsSon, "_$!<ElderCousinParentsSiblingsSon>!$_"),
        (CNLabelContactRelationElderSibling, "_$!<ElderSibling>!$_"),
        (CNLabelContactRelationElderSiblingInLaw, "_$!<ElderSiblingInLaw>!$_"),
        (CNLabelContactRelationElderSister, "_$!<ElderSister>!$_"),
        (CNLabelContactRelationElderSisterInLaw, "_$!<ElderSisterInLaw>!$_"),
        (CNLabelContactRelationEldestBrother, "_$!<EldestBrother>!$_"),
        (CNLabelContactRelationEldestSister, "_$!<EldestSister>!$_"),
        (CNLabelContactRelationFather, "_$!<Father>!$_"),
        (CNLabelContactRelationFatherInLaw, "_$!<FatherInLaw>!$_"),
        (CNLabelContactRelationFatherInLawHusbandsFather, "_$!<FatherInLawHusbandsFather>!$_"),
        (CNLabelContactRelationFatherInLawOrStepfather, "_$!<FatherInLawOrStepfather>!$_"),
        (CNLabelContactRelationFatherInLawWifesFather, "_$!<FatherInLawWifesFather>!$_"),
        (CNLabelContactRelationFemaleCousin, "_$!<FemaleCousin>!$_"),
        (CNLabelContactRelationFemaleFriend, "_$!<FemaleFriend>!$_"),
        (CNLabelContactRelationFemalePartner, "_$!<FemalePartner>!$_"),
        (CNLabelContactRelationFriend, "_$!<Friend>!$_"),
        (CNLabelContactRelationGirlfriend, "_$!<Girlfriend>!$_"),
        (CNLabelContactRelationGirlfriendOrBoyfriend, "_$!<GirlfriendOrBoyfriend>!$_"),
        (CNLabelContactRelationGrandaunt, "_$!<Grandaunt>!$_"),
        (CNLabelContactRelationGrandchild, "_$!<Grandchild>!$_"),
        (CNLabelContactRelationGrandchildOrSiblingsChild, "_$!<GrandchildOrSiblingsChild>!$_"),
        (CNLabelContactRelationGranddaughter, "_$!<Granddaughter>!$_"),
        (CNLabelContactRelationGranddaughterDaughtersDaughter, "_$!<GranddaughterDaughtersDaughter>!$_"),
        (CNLabelContactRelationGranddaughterOrNiece, "_$!<GranddaughterOrNiece>!$_"),
        (CNLabelContactRelationGranddaughterSonsDaughter, "_$!<GranddaughterSonsDaughter>!$_"),
        (CNLabelContactRelationGrandfather, "_$!<Grandfather>!$_"),
        (CNLabelContactRelationGrandfatherFathersFather, "_$!<GrandfatherFathersFather>!$_"),
        (CNLabelContactRelationGrandfatherMothersFather, "_$!<GrandfatherMothersFather>!$_"),
        (CNLabelContactRelationGrandmother, "_$!<Grandmother>!$_"),
        (CNLabelContactRelationGrandmotherFathersMother, "_$!<GrandmotherFathersMother>!$_"),
        (CNLabelContactRelationGrandmotherMothersMother, "_$!<GrandmotherMothersMother>!$_"),
        (CNLabelContactRelationGrandnephew, "_$!<Grandnephew>!$_"),
        (CNLabelContactRelationGrandnephewBrothersGrandson, "_$!<GrandnephewBrothersGrandson>!$_"),
        (CNLabelContactRelationGrandnephewSistersGrandson, "_$!<GrandnephewSistersGrandson>!$_"),
        (CNLabelContactRelationGrandniece, "_$!<Grandniece>!$_"),
        (CNLabelContactRelationGrandnieceBrothersGranddaughter, "_$!<GrandnieceBrothersGranddaughter>!$_"),
        (CNLabelContactRelationGrandnieceSistersGranddaughter, "_$!<GrandnieceSistersGranddaughter>!$_"),
        (CNLabelContactRelationGrandparent, "_$!<Grandparent>!$_"),
        (CNLabelContactRelationGrandson, "_$!<Grandson>!$_"),
        (CNLabelContactRelationGrandsonDaughtersSon, "_$!<GrandsonDaughtersSon>!$_"),
        (CNLabelContactRelationGrandsonOrNephew, "_$!<GrandsonOrNephew>!$_"),
        (CNLabelContactRelationGrandsonSonsSon, "_$!<GrandsonSonsSon>!$_"),
        (CNLabelContactRelationGranduncle, "_$!<Granduncle>!$_"),
        (CNLabelContactRelationGreatGrandchild, "_$!<GreatGrandchild>!$_"),
        (CNLabelContactRelationGreatGrandchildOrSiblingsGrandchild, "_$!<GreatGrandchildOrSiblingsGrandchild>!$_"),
        (CNLabelContactRelationGreatGranddaughter, "_$!<GreatGranddaughter>!$_"),
        (CNLabelContactRelationGreatGrandfather, "_$!<GreatGrandfather>!$_"),
        (CNLabelContactRelationGreatGrandmother, "_$!<GreatGrandmother>!$_"),
        (CNLabelContactRelationGreatGrandparent, "_$!<GreatGrandparent>!$_"),
        (CNLabelContactRelationGreatGrandson, "_$!<GreatGrandson>!$_"),
        (CNLabelContactRelationHusband, "_$!<Husband>!$_"),
        (CNLabelContactRelationMaleCousin, "_$!<MaleCousin>!$_"),
        (CNLabelContactRelationMaleFriend, "_$!<MaleFriend>!$_"),
        (CNLabelContactRelationMalePartner, "_$!<MalePartner>!$_"),
        (CNLabelContactRelationManager, "_$!<Manager>!$_"),
        (CNLabelContactRelationMother, "_$!<Mother>!$_"),
        (CNLabelContactRelationMotherInLaw, "_$!<MotherInLaw>!$_"),
        (CNLabelContactRelationMotherInLawHusbandsMother, "_$!<MotherInLawHusbandsMother>!$_"),
        (CNLabelContactRelationMotherInLawOrStepmother, "_$!<MotherInLawOrStepmother>!$_"),
        (CNLabelContactRelationMotherInLawWifesMother, "_$!<MotherInLawWifesMother>!$_"),
        (CNLabelContactRelationNephew, "_$!<Nephew>!$_"),
        (CNLabelContactRelationNephewBrothersSon, "_$!<NephewBrothersSon>!$_"),
        (CNLabelContactRelationNephewBrothersSonOrHusbandsSiblingsSon, "_$!<NephewBrothersSonOrHusbandsSiblingsSon>!$_"),
        (CNLabelContactRelationNephewOrCousin, "_$!<NephewOrCousin>!$_"),
        (CNLabelContactRelationNephewSistersSon, "_$!<NephewSistersSon>!$_"),
        (CNLabelContactRelationNephewSistersSonOrWifesSiblingsSon, "_$!<NephewSistersSonOrWifesSiblingsSon>!$_"),
        (CNLabelContactRelationNiece, "_$!<Niece>!$_"),
        (CNLabelContactRelationNieceBrothersDaughter, "_$!<NieceBrothersDaughter>!$_"),
        (CNLabelContactRelationNieceBrothersDaughterOrHusbandsSiblingsDaughter, "_$!<NieceBrothersDaughterOrHusbandsSiblingsDaughter>!$_"),
        (CNLabelContactRelationNieceOrCousin, "_$!<NieceOrCousin>!$_"),
        (CNLabelContactRelationNieceSistersDaughter, "_$!<NieceSistersDaughter>!$_"),
        (CNLabelContactRelationNieceSistersDaughterOrWifesSiblingsDaughter, "_$!<NieceSistersDaughterOrWifesSiblingsDaughter>!$_"),
        (CNLabelContactRelationParent, "_$!<Parent>!$_"),
        (CNLabelContactRelationParentInLaw, "_$!<ParentInLaw>!$_"),
        (CNLabelContactRelationParentsElderSibling, "_$!<ParentsElderSibling>!$_"),
        (CNLabelContactRelationParentsSibling, "_$!<ParentsSibling>!$_"),
        (CNLabelContactRelationParentsSiblingFathersElderSibling, "_$!<ParentsSiblingFathersElderSibling>!$_"),
        (CNLabelContactRelationParentsSiblingFathersSibling, "_$!<ParentsSiblingFathersSibling>!$_"),
        (CNLabelContactRelationParentsSiblingFathersYoungerSibling, "_$!<ParentsSiblingFathersYoungerSibling>!$_"),
        (CNLabelContactRelationParentsSiblingMothersElderSibling, "_$!<ParentsSiblingMothersElderSibling>!$_"),
        (CNLabelContactRelationParentsSiblingMothersSibling, "_$!<ParentsSiblingMothersSibling>!$_"),
        (CNLabelContactRelationParentsSiblingMothersYoungerSibling, "_$!<ParentsSiblingMothersYoungerSibling>!$_"),
        (CNLabelContactRelationParentsYoungerSibling, "_$!<ParentsYoungerSibling>!$_"),
        (CNLabelContactRelationPartner, "_$!<Partner>!$_"),
        (CNLabelContactRelationSibling, "_$!<Sibling>!$_"),
        (CNLabelContactRelationSiblingInLaw, "_$!<SiblingInLaw>!$_"),
        (CNLabelContactRelationSiblingsChild, "_$!<SiblingsChild>!$_"),
        (CNLabelContactRelationSister, "_$!<Sister>!$_"),
        (CNLabelContactRelationSisterInLaw, "_$!<SisterInLaw>!$_"),
        (CNLabelContactRelationSisterInLawBrothersWife, "_$!<SisterInLawBrothersWife>!$_"),
        (CNLabelContactRelationSisterInLawElderBrothersWife, "_$!<SisterInLawElderBrothersWife>!$_"),
        (CNLabelContactRelationSisterInLawHusbandsBrothersWife, "_$!<SisterInLawHusbandsBrothersWife>!$_"),
        (CNLabelContactRelationSisterInLawHusbandsSister, "_$!<SisterInLawHusbandsSister>!$_"),
        (CNLabelContactRelationSisterInLawSpousesSister, "_$!<SisterInLawSpousesSister>!$_"),
        (CNLabelContactRelationSisterInLawWifesBrothersWife, "_$!<SisterInLawWifesBrothersWife>!$_"),
        (CNLabelContactRelationSisterInLawWifesSister, "_$!<SisterInLawWifesSister>!$_"),
        (CNLabelContactRelationSisterInLawYoungerBrothersWife, "_$!<SisterInLawYoungerBrothersWife>!$_"),
        (CNLabelContactRelationSon, "_$!<Son>!$_"),
        (CNLabelContactRelationSonInLaw, "_$!<SonInLaw>!$_"),
        (CNLabelContactRelationSonInLawOrBrotherInLaw, "_$!<SonInLawOrBrotherInLaw>!$_"),
        (CNLabelContactRelationSonInLawOrStepson, "_$!<SonInLawOrStepson>!$_"),
        (CNLabelContactRelationSpouse, "_$!<Spouse>!$_"),
        (CNLabelContactRelationStepbrother, "_$!<Stepbrother>!$_"),
        (CNLabelContactRelationStepchild, "_$!<Stepchild>!$_"),
        (CNLabelContactRelationStepdaughter, "_$!<Stepdaughter>!$_"),
        (CNLabelContactRelationStepfather, "_$!<Stepfather>!$_"),
        (CNLabelContactRelationStepmother, "_$!<Stepmother>!$_"),
        (CNLabelContactRelationStepparent, "_$!<Stepparent>!$_"),
        (CNLabelContactRelationStepsister, "_$!<Stepsister>!$_"),
        (CNLabelContactRelationStepson, "_$!<Stepson>!$_"),
        (CNLabelContactRelationTeacher, "_$!<Teacher>!$_"),
        (CNLabelContactRelationUncle, "_$!<Uncle>!$_"),
        (CNLabelContactRelationUncleFathersBrother, "_$!<UncleFathersBrother>!$_"),
        (CNLabelContactRelationUncleFathersElderBrother, "_$!<UncleFathersElderBrother>!$_"),
        (CNLabelContactRelationUncleFathersElderSistersHusband, "_$!<UncleFathersElderSistersHusband>!$_"),
        (CNLabelContactRelationUncleFathersSistersHusband, "_$!<UncleFathersSistersHusband>!$_"),
        (CNLabelContactRelationUncleFathersYoungerBrother, "_$!<UncleFathersYoungerBrother>!$_"),
        (CNLabelContactRelationUncleFathersYoungerSistersHusband, "_$!<UncleFathersYoungerSistersHusband>!$_"),
        (CNLabelContactRelationUncleMothersBrother, "_$!<UncleMothersBrother>!$_"),
        (CNLabelContactRelationUncleMothersElderBrother, "_$!<UncleMothersElderBrother>!$_"),
        (CNLabelContactRelationUncleMothersSistersHusband, "_$!<UncleMothersSistersHusband>!$_"),
        (CNLabelContactRelationUncleMothersYoungerBrother, "_$!<UncleMothersYoungerBrother>!$_"),
        (CNLabelContactRelationUncleParentsBrother, "_$!<UncleParentsBrother>!$_"),
        (CNLabelContactRelationUncleParentsElderBrother, "_$!<UncleParentsElderBrother>!$_"),
        (CNLabelContactRelationUncleParentsYoungerBrother, "_$!<UncleParentsYoungerBrother>!$_"),
        (CNLabelContactRelationWife, "_$!<Wife>!$_"),
        (CNLabelContactRelationYoungerBrother, "_$!<YoungerBrother>!$_"),
        (CNLabelContactRelationYoungerBrotherInLaw, "_$!<YoungerBrotherInLaw>!$_"),
        (CNLabelContactRelationYoungerCousin, "_$!<YoungerCousin>!$_"),
        (CNLabelContactRelationYoungerCousinFathersBrothersDaughter, "_$!<YoungerCousinFathersBrothersDaughter>!$_"),
        (CNLabelContactRelationYoungerCousinFathersBrothersSon, "_$!<YoungerCousinFathersBrothersSon>!$_"),
        (CNLabelContactRelationYoungerCousinFathersSistersDaughter, "_$!<YoungerCousinFathersSistersDaughter>!$_"),
        (CNLabelContactRelationYoungerCousinFathersSistersSon, "_$!<YoungerCousinFathersSistersSon>!$_"),
        (CNLabelContactRelationYoungerCousinMothersBrothersDaughter, "_$!<YoungerCousinMothersBrothersDaughter>!$_"),
        (CNLabelContactRelationYoungerCousinMothersBrothersSon, "_$!<YoungerCousinMothersBrothersSon>!$_"),
        (CNLabelContactRelationYoungerCousinMothersSiblingsDaughterOrFathersSistersDaughter, "_$!<YoungerCousinMothersSiblingsDaughterOrFathersSistersDaughter>!$_"),
        (CNLabelContactRelationYoungerCousinMothersSiblingsSonOrFathersSistersSon, "_$!<YoungerCousinMothersSiblingsSonOrFathersSistersSon>!$_"),
        (CNLabelContactRelationYoungerCousinMothersSistersDaughter, "_$!<YoungerCousinMothersSistersDaughter>!$_"),
        (CNLabelContactRelationYoungerCousinMothersSistersSon, "_$!<YoungerCousinMothersSistersSon>!$_"),
        (CNLabelContactRelationYoungerCousinParentsSiblingsDaughter, "_$!<YoungerCousinParentsSiblingsDaughter>!$_"),
        (CNLabelContactRelationYoungerCousinParentsSiblingsSon, "_$!<YoungerCousinParentsSiblingsSon>!$_"),
        (CNLabelContactRelationYoungerSibling, "_$!<YoungerSibling>!$_"),
        (CNLabelContactRelationYoungerSiblingInLaw, "_$!<YoungerSiblingInLaw>!$_"),
        (CNLabelContactRelationYoungerSister, "_$!<YoungerSister>!$_"),
        (CNLabelContactRelationYoungerSisterInLaw, "_$!<YoungerSisterInLaw>!$_"),
        (CNLabelContactRelationYoungestBrother, "_$!<YoungestBrother>!$_"),
        (CNLabelContactRelationYoungestSister, "_$!<YoungestSister>!$_"),
        (CNLabelDateAnniversary, "_$!<Anniversary>!$_"),
        (CNLabelEmailiCloud, "iCloud"),
        (CNLabelHome, "_$!<Home>!$_"),
        (CNLabelOther, "_$!<Other>!$_"),
        (CNLabelPhoneNumberAppleWatch, "Apple Watch"),
        (CNLabelPhoneNumberHomeFax, "_$!<HomeFAX>!$_"),
        (CNLabelPhoneNumberMain, "_$!<Main>!$_"),
        (CNLabelPhoneNumberMobile, "_$!<Mobile>!$_"),
        (CNLabelPhoneNumberOtherFax, "_$!<OtherFAX>!$_"),
        (CNLabelPhoneNumberPager, "_$!<Pager>!$_"),
        (CNLabelPhoneNumberWorkFax, "_$!<WorkFAX>!$_"),
        (CNLabelPhoneNumberiPhone, "iPhone"),
        (CNLabelSchool, "_$!<School>!$_"),
        (CNLabelURLAddressHomePage, "_$!<HomePage>!$_"),
        (CNLabelWork, "_$!<Work>!$_"),
        (CNPostalAddressCityKey, "city"),
        (CNPostalAddressCountryKey, "country"),
        (CNPostalAddressISOCountryCodeKey, "ISOCountryCode"),
        (CNPostalAddressLocalizedPropertyNameAttribute, "CNPostalAddressLocalizedPropertyNameAttribute"),
        (CNPostalAddressPostalCodeKey, "postalCode"),
        (CNPostalAddressPropertyAttribute, "CNPostalAddressPropertyAttribute"),
        (CNPostalAddressStateKey, "state"),
        (CNPostalAddressStreetKey, "street"),
        (CNPostalAddressSubAdministrativeAreaKey, "subAdministrativeArea"),
        (CNPostalAddressSubLocalityKey, "subLocality"),
        (CNSocialProfileServiceFacebook, "Facebook"),
        (CNSocialProfileServiceFlickr, "Flickr"),
        (CNSocialProfileServiceGameCenter, "GameCenter"),
        (CNSocialProfileServiceKey, "service"),
        (CNSocialProfileServiceLinkedIn, "LinkedIn"),
        (CNSocialProfileServiceMySpace, "MySpace"),
        (CNSocialProfileServiceSinaWeibo, "SinaWeibo"),
        (CNSocialProfileServiceTencentWeibo, "TencentWeibo"),
        (CNSocialProfileServiceTwitter, "Twitter"),
        (CNSocialProfileServiceYelp, "Yelp"),
        (CNSocialProfileURLStringKey, "urlString"),
        (CNSocialProfileUserIdentifierKey, "userIdentifier"),
        (CNSocialProfileUsernameKey, "username"),
    ]
    expect(pairs.count == 308, "308 public string constants")
    for (value, expected) in pairs {
        expect(value == expected, "constant payload \(expected)")
    }
    let all = CNAllPublicStringConstants()
    expect(all.count == 308, "aggregator count \(all.count)")
    expect(Set(all) == Set(pairs.map(\.0)), "aggregator membership")
}

// --- ContactsContactTests.swift ---
func testContactPropertiesAndKeys() {
    let contact = makeAdaContact()
    expect(contact.identifier.count == 36, "uuid identifier")
    expect(contact.contactType == .person, "contactType")
    expect(contact.namePrefix == "Ms", "namePrefix")
    expect(contact.givenName == "Ada", "givenName")
    expect(contact.middleName == "Byron", "middleName")
    expect(contact.familyName == "Lovelace", "familyName")
    expect(contact.previousFamilyName == "Byron", "previousFamilyName")
    expect(contact.nameSuffix == "Countess", "nameSuffix")
    expect(contact.nickname == "Ada", "nickname")
    expect(contact.organizationName == "Analytical Engine", "organizationName")
    expect(contact.departmentName == "Mathematics", "departmentName")
    expect(contact.jobTitle == "Mathematician", "jobTitle")
    expect(contact.phoneticGivenName == "Ay-duh", "phoneticGivenName")
    expect(contact.phoneticMiddleName == "By-ron", "phoneticMiddleName")
    expect(contact.phoneticFamilyName == "Love-lace", "phoneticFamilyName")
    expect(contact.phoneticOrganizationName == "Engine", "phoneticOrganizationName")
    expect(contact.birthday?.year == 1815, "birthday")
    expect(contact.nonGregorianBirthday == nil, "nonGregorianBirthday")
    expect(contact.note == "First programmer", "note")
    expect(contact.imageData == Data([0x00, 0x01, 0x02]), "imageData")
    expect(contact.imageDataAvailable, "imageDataAvailable")
    expect(contact.thumbnailImageData == contact.imageData, "thumbnailImageData")
    expect(contact.phoneNumbers.count == 1, "phoneNumbers")
    expect(contact.emailAddresses.count == 1, "emailAddresses")
    expect(contact.postalAddresses.count == 1, "postalAddresses")
    expect(contact.dates.count == 1, "dates")
    expect(contact.urlAddresses.count == 1, "urlAddresses")
    expect(contact.contactRelations.count == 1, "contactRelations")
    expect(contact.socialProfiles.count == 1, "socialProfiles")
    expect(contact.instantMessageAddresses.count == 1, "instantMessageAddresses")
    expect(contact.isKeyAvailable(CNContactGivenNameKey), "isKeyAvailable")
    expect(
        contact.areKeysAvailable([CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]),
        "areKeysAvailable"
    )
    expect(!contact.isUnifiedWithContact(withIdentifier: "missing"), "isUnifiedWithContact")
    expect(CNContact.localizedString(forKey: CNContactGivenNameKey) == "Given Name", "localizedString")
    let copied = contact.copy() as! CNContact
    expect(copied.givenName == "Ada", "NSCopying")
}

func testMutableContactSetters() {
    let contact = CNMutableContact()
    contact.contactType = .organization
    contact.namePrefix = "Dr"
    contact.givenName = "Grace"
    contact.middleName = "Brewster"
    contact.familyName = "Hopper"
    contact.previousFamilyName = "Murray"
    contact.nameSuffix = "USN"
    contact.nickname = "Amazing Grace"
    contact.organizationName = "Navy"
    contact.departmentName = "COBOL"
    contact.jobTitle = "Rear Admiral"
    contact.phoneticGivenName = "Grace"
    contact.phoneticMiddleName = "Brewster"
    contact.phoneticFamilyName = "Hopper"
    contact.phoneticOrganizationName = "Navy"
    contact.birthday = DateComponents(calendar: Calendar(identifier: .gregorian), year: 1906, month: 12, day: 9)
    contact.nonGregorianBirthday = DateComponents(year: 1906, month: 12, day: 9)
    contact.note = "compiler"
    contact.imageData = Data([0x0A])
    contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "1"))]
    contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: "grace@example.com" as NSString)]
    contact.postalAddresses = [CNLabeledValue(label: CNLabelWork, value: CNMutablePostalAddress())]
    let anniversary = NSDateComponents()
    anniversary.year = 1952
    contact.dates = [CNLabeledValue(label: CNLabelDateAnniversary, value: anniversary)]
    contact.urlAddresses = [CNLabeledValue(label: CNLabelURLAddressHomePage, value: "https://example.com" as NSString)]
    contact.contactRelations = [CNLabeledValue(label: CNLabelContactRelationColleague, value: CNContactRelation(name: "Team"))]
    contact.socialProfiles = [
        CNLabeledValue(
            label: CNLabelWork,
            value: CNSocialProfile(urlString: "u", username: "g", userIdentifier: "1", service: CNSocialProfileServiceTwitter)
        )
    ]
    contact.instantMessageAddresses = [
        CNLabeledValue(label: CNLabelWork, value: CNInstantMessageAddress(username: "g", service: CNInstantMessageServiceAIM))
    ]
    expect(contact.contactType == .organization, "mutable contactType")
    expect(contact.givenName == "Grace", "mutable givenName")
    expect(contact.familyName == "Hopper", "mutable familyName")
    expect(contact.nonGregorianBirthday?.year == 1906, "mutable nonGregorianBirthday")
    expect(contact.phoneNumbers[0].label == CNLabelPhoneNumberMain, "mutable phoneNumbers")
    expect(contact.emailAddresses[0].value as String == "grace@example.com", "mutable emailAddresses")
    expect(contact.urlAddresses[0].value as String == "https://example.com", "mutable urlAddresses")
    expect(contact.dates[0].label == CNLabelDateAnniversary, "mutable dates")
    expect(contact.instantMessageAddresses[0].value.service == CNInstantMessageServiceAIM, "mutable IM")
    let snapshot = contact.copy() as! CNContact
    let mutated = snapshot.mutableCopy() as! CNMutableContact
    mutated.givenName = "Other"
    expect(snapshot.givenName == "Grace", "mutableCopy independence")
}

func testContactPredicatesAndDescriptors() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)

    let byName = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(matchingName: "Ada"),
        keysToFetch: keys(CNContactGivenNameKey)
    )
    expect(byName.count == 1, "predicateForContacts matchingName")
    let byEmail = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(matchingEmailAddress: "ada@example.com"),
        keysToFetch: keys(CNContactIdentifierKey)
    )
    expect(byEmail.count == 1, "predicateForContacts matchingEmailAddress")
    let byPhone = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: "+1-555-0100")),
        keysToFetch: keys(CNContactIdentifierKey)
    )
    expect(byPhone.count == 1, "predicateForContacts matching phone")
    let byID = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(withIdentifiers: [contact.identifier]),
        keysToFetch: keys(CNContactIdentifierKey)
    )
    expect(byID.count == 1, "predicateForContacts withIdentifiers")
    let inContainer = try! store.unifiedContacts(
        matching: CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier()),
        keysToFetch: keys(CNContactIdentifierKey)
    )
    expect(inContainer.count == 1, "predicateForContactsInContainer")

    let comparator = CNContact.comparator(forNameSortOrder: .familyName)
    expect(comparator(contact, contact) == .orderedSame, "comparator")
    _ = CNContact.descriptorForAllComparatorKeys()
}

func testContactIdentifiable() {
    let contact = CNMutableContact()
    contact.givenName = "Id"
    expect(contact.id.uuidString == contact.identifier, "CNContact.ID is UUID")
    let typed: CNContact.ID = contact.id
    expect(typed == contact.id, "typealias CNContact.ID")
}

func testUnfetchedKeysAndThumbnail() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)
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
    expect(contact.thumbnailImageData == contact.imageData, "thumbnail equals imageData")
}

// --- ContactsEnumTests.swift ---
func testEnumRawValues() {
    expect(CNAuthorizationStatus.notDetermined.rawValue == 0, "auth notDetermined")
    expect(CNAuthorizationStatus.restricted.rawValue == 1, "auth restricted")
    expect(CNAuthorizationStatus.denied.rawValue == 2, "auth denied")
    expect(CNAuthorizationStatus.authorized.rawValue == 3, "auth authorized")
    expect(CNAuthorizationStatus.limited.rawValue == 4, "auth limited")
    expect(CNAuthorizationStatus.limited != CNAuthorizationStatus.denied, "auth inequality")
    expect(CNAuthorizationStatus(rawValue: 0) == .notDetermined, "auth rawValue init")
    expect(CNAuthorizationStatus.authorized.hashValue == CNAuthorizationStatus(rawValue: 3)?.hashValue, "auth hashValue")
    var hasher = Hasher()
    CNAuthorizationStatus.authorized.hash(into: &hasher)

    expect(CNContactSortOrder.none.rawValue == 0, "sort none")
    expect(CNContactSortOrder.userDefault.rawValue == 1, "sort userDefault")
    expect(CNContactSortOrder.givenName.rawValue == 2, "sort given")
    expect(CNContactSortOrder.familyName.rawValue == 3, "sort family")
    expect(CNContactSortOrder.givenName != .familyName, "sort inequality")
    expect(CNContactSortOrder(rawValue: 3) == .familyName, "sort rawValue init")
    expect(CNContactSortOrder.givenName.hashValue == CNContactSortOrder(rawValue: 2)?.hashValue, "sort hashValue")
    CNContactSortOrder.givenName.hash(into: &hasher)

    expect(CNContactType.person.rawValue == 0, "person type")
    expect(CNContactType.organization.rawValue == 1, "org type")
    expect(CNContactType.person != .organization, "contact type inequality")
    expect(CNContactType(rawValue: 1) == .organization, "type rawValue init")
    expect(CNContactType.person.hashValue == CNContactType(rawValue: 0)?.hashValue, "type hashValue")
    CNContactType.person.hash(into: &hasher)

    expect(CNEntityType.contacts.rawValue == 0, "entity")
    expect(CNEntityType(rawValue: 0) == .contacts, "entity rawValue init")
    expect(CNEntityType.contacts.hashValue == CNEntityType(rawValue: 0)?.hashValue, "entity hashValue")
    expect(!(CNEntityType.contacts != .contacts), "entity inequality")
    expect(CNEntityType(rawValue: 99) == nil, "entity missing rawValue")
    CNEntityType.contacts.hash(into: &hasher)

    expect(CNContainerType.unassigned.rawValue == 0, "unassigned")
    expect(CNContainerType.local.rawValue == 1, "local container type")
    expect(CNContainerType.exchange.rawValue == 2, "exchange")
    expect(CNContainerType.cardDAV.rawValue == 3, "carddav")
    expect(CNContainerType.local != .exchange, "container inequality")
    expect(CNContainerType(rawValue: 3) == .cardDAV, "container rawValue init")
    expect(CNContainerType.local.hashValue == CNContainerType(rawValue: 1)?.hashValue, "container hashValue")
    CNContainerType.local.hash(into: &hasher)

    expect(CNContactDisplayNameOrder.userDefault.rawValue == 0, "display userDefault")
    expect(CNContactDisplayNameOrder.givenNameFirst.rawValue == 1, "display given first")
    expect(CNContactDisplayNameOrder.familyNameFirst.rawValue == 2, "display order")
    expect(CNContactDisplayNameOrder.givenNameFirst != .familyNameFirst, "display inequality")
    expect(CNContactDisplayNameOrder(rawValue: 2) == .familyNameFirst, "display rawValue init")
    expect(CNContactDisplayNameOrder.givenNameFirst.hashValue == CNContactDisplayNameOrder(rawValue: 1)?.hashValue, "display hashValue")
    CNContactDisplayNameOrder.givenNameFirst.hash(into: &hasher)

    expect(CNContactFormatterStyle.fullName.rawValue == 0, "full name style")
    expect(CNContactFormatterStyle.phoneticFullName.rawValue == 1, "formatter style")
    expect(CNContactFormatterStyle.fullName != .phoneticFullName, "formatter inequality")
    expect(CNContactFormatterStyle(rawValue: 1) == .phoneticFullName, "formatter rawValue init")
    expect(CNContactFormatterStyle.fullName.hashValue == CNContactFormatterStyle(rawValue: 0)?.hashValue, "formatter hashValue")
    CNContactFormatterStyle.fullName.hash(into: &hasher)

    expect(CNPostalAddressFormatterStyle.mailingAddress.rawValue == 0, "postal style")
    expect(CNPostalAddressFormatterStyle(rawValue: 0) == .mailingAddress, "postal rawValue init")
    expect(
        CNPostalAddressFormatterStyle.mailingAddress.hashValue
            == CNPostalAddressFormatterStyle(rawValue: 0)?.hashValue,
        "postal hashValue"
    )
    expect(!(CNPostalAddressFormatterStyle.mailingAddress != .mailingAddress), "postal inequality")
    expect(CNPostalAddressFormatterStyle(rawValue: 9) == nil, "postal missing rawValue")
    CNPostalAddressFormatterStyle.mailingAddress.hash(into: &hasher)

    expect(CNError.Code.communicationError.rawValue == 1, "communicationError")
    expect(CNError.Code.dataAccessError.rawValue == 2, "dataAccessError")
    expect(CNError.Code.authorizationDenied.rawValue == 100, "authorizationDenied")
    expect(CNError.Code.noAccessableWritableContainers.rawValue == 101, "noAccessableWritableContainers")
    expect(CNError.Code.unauthorizedKeys.rawValue == 102, "unauthorizedKeys")
    expect(CNError.Code.featureDisabledByUser.rawValue == 103, "featureDisabledByUser")
    expect(CNError.Code.featureNotAvailable.rawValue == 104, "featureNotAvailable")
    expect(CNError.Code.recordDoesNotExist.rawValue == 200, "recordDoesNotExist")
    expect(CNError.Code.insertedRecordAlreadyExists.rawValue == 201, "insertedRecordAlreadyExists")
    expect(CNError.Code.containmentCycle.rawValue == 202, "containmentCycle")
    expect(CNError.Code.containmentScope.rawValue == 203, "containmentScope")
    expect(CNError.Code.recordIdentifierInvalid.rawValue == 204, "recordIdentifierInvalid")
    expect(CNError.Code.recordNotWritable.rawValue == 205, "recordNotWritable")
    expect(CNError.Code.parentRecordDoesNotExist.rawValue == 206, "parentRecordDoesNotExist")
    expect(CNError.Code.parentContainerNotWritable.rawValue == 207, "parentContainerNotWritable")
    expect(CNError.Code.validationMultipleErrors.rawValue == 300, "validationMultipleErrors")
    expect(CNError.Code.validationTypeMismatch.rawValue == 301, "validationTypeMismatch")
    expect(CNError.Code.validationConfigurationError.rawValue == 302, "validationConfigurationError")
    expect(CNError.Code.predicateInvalid.rawValue == 400, "predicateInvalid")
    expect(CNError.Code.policyViolation.rawValue == 500, "policyViolation")
    expect(CNError.Code.clientIdentifierInvalid.rawValue == 600, "clientIdentifierInvalid")
    expect(CNError.Code.clientIdentifierDoesNotExist.rawValue == 601, "clientIdentifierDoesNotExist")
    expect(CNError.Code.clientIdentifierCollision.rawValue == 602, "clientIdentifierCollision")
    expect(CNError.Code.changeHistoryExpired.rawValue == 700, "changeHistoryExpired")
    expect(CNError.Code.changeHistoryInvalidAnchor.rawValue == 701, "changeHistoryInvalidAnchor")
    expect(CNError.Code.changeHistoryInvalidFetchRequest.rawValue == 702, "changeHistoryInvalidFetchRequest")
    expect(CNError.Code.vCardMalformed.rawValue == 800, "vCardMalformed")
    expect(CNError.Code.vCardSummarizationError.rawValue == 801, "vCardSummarizationError")
    expect(CNError.Code(rawValue: 100) == .authorizationDenied, "error rawValue init")
    expect(CNError.Code.authorizationDenied != .featureNotAvailable, "error code inequality")
    expect(CNError.Code.authorizationDenied.hashValue == CNError.Code(rawValue: 100)?.hashValue, "error hashValue")
    CNError.Code.authorizationDenied.hash(into: &hasher)
    _ = hasher.finalize()
}

// --- ContactsErrorTests.swift ---
func testErrorCodeAliases() {
    let aliases: [(CNError.Code, CNError.Code, Int)] = [
        (CNError.communicationError, .communicationError, 1),
        (CNError.dataAccessError, .dataAccessError, 2),
        (CNError.authorizationDenied, .authorizationDenied, 100),
        (CNError.noAccessableWritableContainers, .noAccessableWritableContainers, 101),
        (CNError.unauthorizedKeys, .unauthorizedKeys, 102),
        (CNError.featureDisabledByUser, .featureDisabledByUser, 103),
        (CNError.featureNotAvailable, .featureNotAvailable, 104),
        (CNError.recordDoesNotExist, .recordDoesNotExist, 200),
        (CNError.insertedRecordAlreadyExists, .insertedRecordAlreadyExists, 201),
        (CNError.containmentCycle, .containmentCycle, 202),
        (CNError.containmentScope, .containmentScope, 203),
        (CNError.recordIdentifierInvalid, .recordIdentifierInvalid, 204),
        (CNError.recordNotWritable, .recordNotWritable, 205),
        (CNError.parentRecordDoesNotExist, .parentRecordDoesNotExist, 206),
        (CNError.parentContainerNotWritable, .parentContainerNotWritable, 207),
        (CNError.validationMultipleErrors, .validationMultipleErrors, 300),
        (CNError.validationTypeMismatch, .validationTypeMismatch, 301),
        (CNError.validationConfigurationError, .validationConfigurationError, 302),
        (CNError.predicateInvalid, .predicateInvalid, 400),
        (CNError.policyViolation, .policyViolation, 500),
        (CNError.clientIdentifierInvalid, .clientIdentifierInvalid, 600),
        (CNError.clientIdentifierDoesNotExist, .clientIdentifierDoesNotExist, 601),
        (CNError.clientIdentifierCollision, .clientIdentifierCollision, 602),
        (CNError.changeHistoryExpired, .changeHistoryExpired, 700),
        (CNError.changeHistoryInvalidAnchor, .changeHistoryInvalidAnchor, 701),
        (CNError.changeHistoryInvalidFetchRequest, .changeHistoryInvalidFetchRequest, 702),
        (CNError.vCardMalformed, .vCardMalformed, 800),
        (CNError.vCardSummarizationError, .vCardSummarizationError, 801),
    ]
    expect(aliases.count == 28, "every CNError code alias")
    expect(Set(aliases.map(\.2)).count == aliases.count, "unique alias raw values")
    for (alias, code, raw) in aliases {
        expect(alias == code, "alias \(raw)")
        expect(alias.rawValue == raw, "alias raw \(raw)")
    }
    expect(CNError.vCardMalformed != CNError.vCardSummarizationError, "vcard error inequality")
    expect(CNError.changeHistoryExpired != CNError.changeHistoryInvalidAnchor, "history error inequality")
    expect(CNError.clientIdentifierInvalid != CNError.clientIdentifierCollision, "client id error inequality")
}

func testErrorUserInfoAndPatternMatching() {
    let denied = CNError(
        .authorizationDenied,
        userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: ["abc"]]
    )
    expect(CNError.errorDomain == CNErrorDomain, "custom nserror domain")
    expect(denied.errorCode == 100, "custom nserror code")
    expect(denied.code == .authorizationDenied, "bridged code")
    expect(denied.affectedRecordIdentifiers == ["abc"], "affected ids")
    expect(CNError.Code.authorizationDenied ~= denied, "error code pattern")
    expect(denied == CNError(.authorizationDenied, userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: ["abc"]]), "error equality")
    expect(denied != CNError(.dataAccessError), "error inequality")
    var hasher = Hasher()
    denied.hash(into: &hasher)
    expect(denied.hashValue == CNError(.authorizationDenied, userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: ["abc"]]).hashValue, "error hash")
    expect(denied.keyPaths == nil, "error keyPaths")
    expect(denied.affectedRecords == nil, "error affectedRecords")
    _ = denied.userInfo
    _ = denied.errorUserInfo
    _ = denied.localizedDescription

    let records = NSObject()
    let detailed = CNError(
        .validationMultipleErrors,
        userInfo: [
            CNErrorUserInfoKeyPathsKey: [CNContactBirthdayKey],
            CNErrorUserInfoAffectedRecordsKey: [records],
            CNErrorUserInfoValidationErrorsKey: ["month"],
        ]
    )
    expect(detailed.keyPaths == [CNContactBirthdayKey], "keyPaths userInfo")
    expect(detailed.affectedRecords?.count == 1, "affectedRecords userInfo")
}

// --- ContactsFormatterTests.swift ---
func testContactFormatter() {
    let contact = makeAdaContact()
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
    expect(formatter.style == .fullName, "formatter style property")
    expect(formatter.string(from: contact) == "Ms Ada Byron Lovelace Countess", "instance formatter")
    expect(formatter.attributedString(from: contact)?.string == "Ms Ada Byron Lovelace Countess", "instance attributed")
    _ = CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
    _ = CNContactFormatter.descriptorForRequiredKeysForDelimiter
    _ = CNContactFormatter.descriptorForRequiredKeysForNameOrder

    let nicknameOnly = CNMutableContact()
    nicknameOnly.nickname = "OnlyNick"
    expect(CNContactFormatter.string(from: nicknameOnly, style: .fullName) == "OnlyNick", "nickname fallback")
    let orgOnly = CNMutableContact()
    orgOnly.contactType = .organization
    orgOnly.organizationName = "Analytical Co"
    expect(CNContactFormatter.string(from: orgOnly, style: .fullName) == "Analytical Co", "organization fallback")
}

func testPostalAddressFormatter() {
    let postal = CNMutablePostalAddress()
    postal.street = "12 Great Street"
    postal.city = "London"
    postal.state = "England"
    postal.postalCode = "SW1A"
    postal.country = "United Kingdom"
    postal.isoCountryCode = "GB"
    postal.subLocality = "Westminster"
    postal.subAdministrativeArea = "Greater London"
    let mailing = CNPostalAddressFormatter.string(from: postal, style: .mailingAddress)
    expect(mailing.contains("12 Great Street"), "street in mailing")
    expect(mailing.contains("London"), "city in mailing")
    let postalFormatter = CNPostalAddressFormatter()
    expect(postalFormatter.style == .mailingAddress, "default postal style")
    postalFormatter.style = .mailingAddress
    expect(postalFormatter.string(from: postal).contains("United Kingdom"), "instance postal")
    expect(
        CNPostalAddressFormatter.attributedString(
            from: postal,
            style: .mailingAddress
        ).string.contains("SW1A"),
        "attributed postal"
    )
    expect(
        postalFormatter.attributedString(from: postal).string.contains("London"),
        "instance attributed postal"
    )
    expect(CNPostalAddress.localizedString(forKey: CNPostalAddressCityKey) == "City", "city title")

    let usAddress = CNMutablePostalAddress()
    usAddress.street = "1 Market St"
    usAddress.city = "San Francisco"
    usAddress.state = "CA"
    usAddress.postalCode = "94105"
    usAddress.country = "United States"
    usAddress.isoCountryCode = "US"
    let usMailing = CNPostalAddressFormatter.string(from: usAddress, style: .mailingAddress)
    expect(usMailing.contains("San Francisco, CA 94105"), "US city/state/ZIP layout \(usMailing)")
}

// --- ContactsHistoryTests.swift ---
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

// --- ContactsSaveRequestTests.swift ---
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

// --- ContactsStoreTests.swift ---
func testContactStoreAuthorization() {
    resetIsolatedStore()
    expect(CNContactStore._portableStoreDirectory().path.contains("openuikit-contacts-"), "directory override")
    CNContactStore._setPortableAuthorizationDecision(.denied)
    expect(CNContactStore.authorizationStatus(for: .contacts) == .notDetermined, "denied-hook starts notDetermined")
    let deniedStore = CNContactStore()
    let deniedSem = DispatchSemaphore(value: 0)
    let deniedGranted = Box(true)
    deniedStore.requestAccess(for: .contacts) { granted, error in
        deniedGranted.value = granted
        expect(error == nil, "denied requestAccess has no fabricated TCC error")
        deniedSem.signal()
    }
    wait(deniedSem, "denied requestAccess deadlock")
    expect(!deniedGranted.value, "documented denied decision")
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

    resetIsolatedStore()
    expect(CNContactStore.authorizationStatus(for: .contacts) == .notDetermined, "start notDetermined")
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

    let requestAccessReturned = Box(false)
    let granted = Box(false)
    let grantError = Box<Error?>(nil)
    let grantedSem = DispatchSemaphore(value: 0)
    store.requestAccess(for: .contacts) { ok, error in
        expect(requestAccessReturned.value, "requestAccess callback is not reentrant on the calling stack")
        granted.value = ok
        grantError.value = error
        grantedSem.signal()
    }
    requestAccessReturned.value = true
    wait(grantedSem, "requestAccess callback deadlock")
    expect(grantError.value == nil, "requestAccess error")
    expect(granted.value, "in-memory requestAccess")
    expect(CNContactStore.authorizationStatus(for: .contacts) == .authorized, "authorized after request")
}

func testContactStoreSaveAndFetch() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)
    let fetched = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(matchingName: "Ada"),
        keysToFetch: keys(CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey)
    )
    expect(fetched.count == 1, "fetched ada")
    expect(fetched[0].givenName == "Ada", "fetched given")
    let byID = try! store.unifiedContact(
        withIdentifier: contact.identifier,
        keysToFetch: keys(CNContactGivenNameKey)
    )
    expect(byID.givenName == "Ada", "unified by id")
    expect(byID.id == contact.id, "uuid identity")

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

    do {
        _ = try store.unifiedContact(withIdentifier: "no-such-record", keysToFetch: keys(CNContactIdentifierKey))
        fail("missing unifiedContact must throw")
    } catch let error as CNError {
        expect(error.code == .recordDoesNotExist, "recordDoesNotExist")
        expect(error.affectedRecordIdentifiers == ["no-such-record"], "missing id userInfo")
    } catch {
        fail("unexpected missing contact \(error)")
    }
}

func testContactStoreEnumerate() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)

    var enumerated = 0
    let request = CNContactFetchRequest(keysToFetch: keys(CNContactGivenNameKey, CNContactFamilyNameKey))
    request.sortOrder = .familyName
    request.unifyResults = true
    request.predicate = CNContact.predicateForContacts(matchingName: "Ada")
    try! store.enumerateContacts(with: request) { item, stop in
        enumerated += 1
        if item.familyName == "Lovelace" {
            stop.pointee = ObjCBool(true)
        }
    }
    expect(enumerated == 1, "enumerated")

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
}

func testContactStoreGroupsAndContainers() {
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

    let groups = try! store.groups(matching: CNGroup.predicateForGroups(withIdentifiers: [group.identifier]))
    expect(groups.count == 1 && groups[0].name == "Scientists", "group fetch")
    expect(groups[0].identifier == group.identifier, "group identifier")
    let inGroup = try! store.unifiedContacts(
        matching: CNContact.predicateForContactsInGroup(withIdentifier: group.identifier),
        keysToFetch: keys(CNContactGivenNameKey)
    )
    expect(inGroup.count == 1, "contacts in group")
    _ = try! store.groups(matching: CNGroup.predicateForGroupsInContainer(withIdentifier: store.defaultContainerIdentifier()))

    let containers = try! store.containers(matching: nil)
    expect(containers.count == 1 && containers[0].type == .local, "local container")
    expect(containers[0].name.count >= 0, "container name")
    expect(store.defaultContainerIdentifier() == containers[0].identifier, "default container")
    let ofContact = try! store.containers(
        matching: CNContainer.predicateForContainerOfContact(withIdentifier: contact.identifier)
    )
    expect(ofContact.count == 1, "container of contact")
    _ = try! store.containers(matching: CNContainer.predicateForContainers(withIdentifiers: [store.defaultContainerIdentifier()]))
    _ = try! store.containers(matching: CNContainer.predicateForContainerOfGroup(withIdentifier: group.identifier))
}

func testContactStoreNotifications() {
    resetIsolatedStore()
    let store = authorizeStore()
    expect(NSNotification.Name.CNContactStoreDidChange.rawValue == "CNContactStoreDidChangeNotification", "note name")
    let observerQueries = Box(0)
    let observer = NotificationCenter.default.addObserver(
        forName: .CNContactStoreDidChange,
        object: store,
        queue: nil
    ) { _ in
        let containers = try? store.containers(matching: nil)
        expect(containers?.count == 1, "observer reentered containers()")
        observerQueries.value += 1
    }
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)
    expect(observerQueries.value >= 1, "did-change observer ran without deadlock")
    NotificationCenter.default.removeObserver(observer)
}

func testContactStoreValidationAndRollback() {
    resetIsolatedStore()
    let store = authorizeStore()

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
}

func testContactStoreDirectoryPersistence() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)
    CNContactStore._reloadPortableStoreFromDisk()
    let reloaded = try! CNContactStore().unifiedContact(
        withIdentifier: contact.identifier,
        keysToFetch: keys(CNContactFamilyNameKey, CNContactGivenNameKey, CNContactImageDataKey, CNContactThumbnailImageDataKey)
    )
    expect(reloaded.familyName == "Lovelace", "directory store survived reload")
    expect(reloaded.givenName == "Ada", "directory store given name")
    expect(reloaded.thumbnailImageData == Data([0x00, 0x01, 0x02]), "persisted thumbnail")
    expect(
        FileManager.default.fileExists(
            atPath: CNContactStore._portableStoreDirectory().appendingPathComponent("store.json").path
        ),
        "store.json exists"
    )
}

// --- ContactsVCardTests.swift ---
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

// --- ContactsValueTests.swift ---
func testLabeledValueAPI() {
    let labeled = CNLabeledValue(label: CNLabelWork, value: "work@example.com" as NSString)
    expect(labeled.label == CNLabelWork, "label")
    expect((labeled.value as String) == "work@example.com", "value")
    expect(!labeled.identifier.isEmpty, "identifier")
    let relabeled = labeled.settingLabel(CNLabelOther)
    expect(relabeled.label == CNLabelOther, "settingLabel")
    expect(relabeled.identifier == labeled.identifier, "stable labeled identifier")
    expect((relabeled.settingValue("other@example.com" as NSString).value as String) == "other@example.com", "settingValue")
    _ = labeled.settingLabel(CNLabelHome, value: "home@example.com" as NSString)
    expect(CNLabeledValue<NSString>.localizedString(forLabel: CNLabelHome) == "Home", "localizedString forLabel")
}

func testPhoneNumberAPI() {
    let emptyPhone = CNPhoneNumber.new()
    expect(emptyPhone.stringValue == "", "empty phone new()")
    let inited = CNPhoneNumber()
    expect(inited.stringValue == "", "empty phone init()")
    let numbered = CNPhoneNumber(stringValue: "+1-555-0100")
    expect(numbered.stringValue == "+1-555-0100", "stringValue")
    expect(!numbered.initialCountryCode.isEmpty, "phone initialCountryCode")
}

func testPostalAddressAPI() {
    let postal = CNMutablePostalAddress()
    postal.street = "12 Great Street"
    postal.subLocality = "Westminster"
    postal.city = "London"
    postal.subAdministrativeArea = "Greater London"
    postal.state = "England"
    postal.postalCode = "SW1A"
    postal.country = "United Kingdom"
    postal.isoCountryCode = "GB"
    expect(postal.street == "12 Great Street", "mutable street")
    expect(postal.subLocality == "Westminster", "mutable subLocality")
    expect(postal.city == "London", "mutable city")
    expect(postal.subAdministrativeArea == "Greater London", "mutable subAdministrativeArea")
    expect(postal.state == "England", "mutable state")
    expect(postal.postalCode == "SW1A", "mutable postalCode")
    expect(postal.country == "United Kingdom", "mutable country")
    expect(postal.isoCountryCode == "GB", "mutable isoCountryCode")
    let copied = postal.copy() as! CNPostalAddress
    expect(copied.city == "London", "postal copy")
    expect(copied.street == "12 Great Street", "immutable street")
    expect(copied.subLocality == "Westminster", "immutable subLocality")
    expect(copied.subAdministrativeArea == "Greater London", "immutable subAdministrativeArea")
    expect(copied.state == "England", "immutable state")
    expect(copied.postalCode == "SW1A", "immutable postalCode")
    expect(copied.country == "United Kingdom", "immutable country")
    expect(copied.isoCountryCode == "GB", "immutable isoCountryCode")
    let postalMutable = copied.mutableCopy() as! CNMutablePostalAddress
    postalMutable.city = "Bath"
    expect(copied.city == "London", "postal copy independence")
    expect(CNPostalAddress.localizedString(forKey: CNPostalAddressStreetKey) == "Street", "street title")
}

func testSocialProfileAPI() {
    let profile = CNSocialProfile(
        urlString: "https://social.example/ada",
        username: "ada",
        userIdentifier: "ada-1",
        service: CNSocialProfileServiceTwitter
    )
    expect(profile.urlString == "https://social.example/ada", "urlString")
    expect(profile.username == "ada", "username")
    expect(profile.userIdentifier == "ada-1", "userIdentifier")
    expect(profile.service == CNSocialProfileServiceTwitter, "service")
    expect(CNSocialProfile.localizedString(forKey: CNSocialProfileUsernameKey) == "Username", "social key")
    expect(CNSocialProfile.localizedString(forService: CNSocialProfileServiceTwitter) == "Twitter", "social service")
}

func testInstantMessageAddressAPI() {
    let im = CNInstantMessageAddress(username: "ada", service: CNInstantMessageServiceJabber)
    expect(im.username == "ada", "username")
    expect(im.service == CNInstantMessageServiceJabber, "service")
    expect(CNInstantMessageAddress.localizedString(forService: CNInstantMessageServiceJabber) == "Jabber", "im service")
    expect(CNInstantMessageAddress.localizedString(forKey: CNInstantMessageAddressUsernameKey) == "Username", "im key")
}

func testContactRelationAPI() {
    let relation = CNContactRelation(name: "Lord Byron")
    expect(relation.name == "Lord Byron", "relation name")
}

func testGroupAPI() {
    let group = CNMutableGroup()
    group.name = "Scientists"
    expect(group.name == "Scientists", "mutable group name")
    expect(!group.identifier.isEmpty, "group identifier")
    let copied = group.copy() as! CNGroup
    expect(copied.name == "Scientists", "group copy name")
    expect(copied.identifier == group.identifier, "group copy identifier")
    _ = CNGroup.predicateForGroups(withIdentifiers: [group.identifier])
    _ = CNGroup.predicateForGroupsInContainer(withIdentifier: "local")
}

func testContainerAPI() {
    let container = CNContainer(identifier: "c", name: "Local", type: .local)
    expect(container.identifier == "c", "container identifier")
    expect(container.name == "Local", "container name")
    expect(container.type == .local, "container type")
    _ = CNContainer.predicateForContainers(withIdentifiers: ["c"])
    _ = CNContainer.predicateForContainerOfContact(withIdentifier: "id")
    _ = CNContainer.predicateForContainerOfGroup(withIdentifier: "g")
}

func testContactPropertyAPI() {
    let contact = makeAdaContact()
    let property = CNContactProperty(
        contact: contact,
        key: CNContactGivenNameKey,
        value: contact.givenName as NSString,
        identifier: contact.identifier,
        label: CNLabelHome
    )
    expect(property.contact.givenName == "Ada", "property contact")
    expect(property.key == CNContactGivenNameKey, "property key")
    expect((property.value as? NSString) as String? == "Ada", "property value")
    expect(property.identifier == contact.identifier, "property identifier")
    expect(property.label == CNLabelHome, "property label")
}

func testContactFetchRequestAPI() {
    _ = CNFetchRequest()
    let request = CNContactFetchRequest(keysToFetch: keys(CNContactGivenNameKey, CNContactFamilyNameKey))
    request.sortOrder = .familyName
    request.unifyResults = true
    request.mutableObjects = false
    request.predicate = CNContact.predicateForContacts(matchingName: "Ada")
    expect(request.keysToFetch.count == 2, "keysToFetch")
    expect(request.sortOrder == .familyName, "sortOrder")
    expect(request.unifyResults, "unifyResults")
    expect(!request.mutableObjects, "mutableObjects")
    expect(request.predicate != nil, "predicate")
}

func testFetchResultAPI() {
    let contact = makeAdaContact()
    let fetchResult = CNFetchResult(value: contact, currentHistoryToken: Data([1]))
    expect(fetchResult.value.givenName == "Ada", "fetch result value")
    expect(fetchResult.currentHistoryToken == Data([1]), "fetch result token")
}

func testUserDefaultsAPI() {
    let defaults = CNContactsUserDefaults.shared()
    expect(!defaults.countryCode.isEmpty, "country code")
    expect(defaults.sortOrder == .givenName, "portable sort default")
}

func testKeyDescriptorProtocol() {
    let givenDescriptor: any CNKeyDescriptor = CNContactGivenNameKey as NSString
    let boxedDescriptor: Any = givenDescriptor
    expect(boxedDescriptor is NSString, "String keys are NSString descriptors")
    expect(boxedDescriptor is NSCopying, "descriptor NSCopying")
    expect(boxedDescriptor is NSSecureCoding, "descriptor NSSecureCoding")
    expect(boxedDescriptor is NSObjectProtocol, "descriptor NSObjectProtocol")
    _ = (givenDescriptor as NSCopying).copy(with: nil)
}

func runContactsAgentTests() {
    testPublicStringConstants()
    testEnumRawValues()
    testErrorCodeAliases()
    testErrorUserInfoAndPatternMatching()
    testLabeledValueAPI()
    testPhoneNumberAPI()
    testPostalAddressAPI()
    testSocialProfileAPI()
    testInstantMessageAddressAPI()
    testContactRelationAPI()
    testGroupAPI()
    testContainerAPI()
    testContactPropertyAPI()
    testContactFetchRequestAPI()
    testFetchResultAPI()
    testUserDefaultsAPI()
    testKeyDescriptorProtocol()
    testContactPropertiesAndKeys()
    testMutableContactSetters()
    testContactIdentifiable()
    testContactFormatter()
    testPostalAddressFormatter()
    testVCardSerialization()
    testSecureCodingRoundTrip()
    testChangeHistoryFetchRequest()
    testContactStoreAuthorization()
    testContactStoreSaveAndFetch()
    testContactPredicatesAndDescriptors()
    testUnfetchedKeysAndThumbnail()
    testContactStoreEnumerate()
    testContactStoreGroupsAndContainers()
    testContactStoreNotifications()
    testContactStoreValidationAndRollback()
    testContactStoreDirectoryPersistence()
    testSaveRequestMutations()
    testChangeHistoryEventsAndVisitor()
    print("CONTACTS_AGENT_RUNTIME_OK")
}
runContactsAgentTests()
