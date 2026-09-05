import Foundation
@_spi(OpenUIKitHost) import Contacts

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
