import Foundation
import TelephonyMessagingKit

func testRCSBusinessCardAndMedia() {
    let card = tmkCard()
    precondition(card.orientation == .vertical)
    precondition(card.imageAlignment == .left)
    precondition(card.content.title == "title")
    precondition(card.content.media?.displayHeight == .medium)
    tmkRoundTrip(card)
    tmkRoundTrip(card.content)
    tmkRoundTrip(tmkCardMedia())
    tmkRoundTrip(tmkCarousel())
}

func testRCSBusinessProfile() {
    let media = tmkBusinessMedia()
    tmkRoundTrip(media)
    let entry = RCSService.Business.MediaEntry(contentType: .logo, label: .icon, media: media)
    tmkRoundTrip(entry)
    let address = RCSService.Business.AddressEntry(label: "HQ", address: "1 Infinite Loop")
    tmkRoundTrip(address)
    let org = RCSService.Business.OrganizationName(displayName: "Acme", nameType: .officialName)
    tmkRoundTrip(org)
    let tel = RCSService.Business.TelephoneDetails(phoneNumber: "+15555550100", phoneNumberType: "work", label: "main")
    tmkRoundTrip(tel)
    let uriEntry = RCSService.Business.URIEntry(uri: tmkURL(), type: .sip, label: .serviceID)
    tmkRoundTrip(uriEntry)
    let comm = RCSService.Business.CommunicationAddress(uriEntries: [uriEntry], telephoneDetails: tel)
    tmkRoundTrip(comm)
    let verify = RCSService.Business.VerificationDetails(
        isVerified: true,
        verifiedBy: "carrier",
        expirationDate: Date(timeIntervalSince1970: 9)
    )
    tmkRoundTrip(verify)
    let menu = RCSService.Business.Menu(title: "root", contents: [.suggestion(tmkSuggestion())])
    tmkRoundTrip(menu)
    let business = RCSService.Business(
        websiteURL: tmkURL(),
        description: "biz",
        emailAddress: "biz@example.invalid",
        mediaEntries: [entry],
        providerName: "Acme",
        categoryNames: ["retail"],
        addressEntries: [address],
        persistentMenu: menu,
        organizationNames: [org],
        backgroundImageURL: tmkURL(),
        verificationDetails: verify,
        communicationAddress: comm,
        styleSheetTemplateURL: tmkURL(),
        termsAndConditionsURL: tmkURL(),
        version: "1"
    )
    precondition(business.themeColor == nil)
    precondition(business.providerName == "Acme")
    let encoded = try! JSONEncoder().encode(business)
    let decoded = try! JSONDecoder().decode(RCSService.Business.self, from: encoded)
    precondition(decoded.providerName == "Acme")
    precondition(decoded.version == "1")
}

func testRCSBusinessActions() {
    let open = RCSService.Business.OpenURLAction(url: tmkURL(), target: .inApp(detent: .large))
    tmkRoundTrip(open)
    let compose = RCSService.Business.ComposeTextAction(phoneNumber: "+1", text: "hi")
    tmkRoundTrip(compose)
    tmkRoundTrip(tmkShowLocation())
    let coords = RCSService.Business.ShowLocationAction(
        fallbackURL: nil,
        label: nil,
        method: .coordinates(CLLocationCoordinate2D(latitude: 0, longitude: 1))
    )
    tmkRoundTrip(coords)
    tmkRoundTrip(tmkSuggestedAction())
    tmkRoundTrip(RCSService.Business.SuggestedReply(displayText: "Thanks"))
    let calendar = RCSService.Business.CreateCalendarEventAction(
        description: "sync",
        fallbackURL: tmkURL(),
        title: "Planning",
        endTime: Date(timeIntervalSince1970: 20),
        startTime: Date(timeIntervalSince1970: 10)
    )
    precondition(calendar.title == "Planning")
    precondition(calendar.startTime.timeIntervalSince1970 == 10)
    precondition(calendar.endTime.timeIntervalSince1970 == 20)
    precondition(calendar.fallbackURL == tmkURL())
    tmkRoundTrip(calendar)
    let recording = RCSService.Business.ComposeRecordingAction(phoneNumber: "+15555550100", mediaType: .video)
    precondition(recording.mediaType == .video)
    tmkRoundTrip(recording)
}
