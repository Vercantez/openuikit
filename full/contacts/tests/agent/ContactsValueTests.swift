import Foundation
@_spi(OpenUIKitHost) import Contacts

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
