import Foundation
import VideoSubscriberAccount

func testAccountApplicationProviderInit() {
    let provider = VSAccountApplicationProvider(
        localizedDisplayName: "Example TV",
        identifier: "com.example.tv"
    )
    precondition(provider.localizedDisplayName == "Example TV")
    precondition(provider.identifier == "com.example.tv")
}

func testAccountMetadataRequestDefaultsAndStorage() {
    let request = VSAccountMetadataRequest()
    precondition(request.channelIdentifier == nil)
    precondition(request.supportedAccountProviderIdentifiers.isEmpty)
    precondition(request.featuredAccountProviderIdentifiers.isEmpty)
    precondition(request.verificationToken == nil)
    precondition(request.includeAccountProviderIdentifier == false)
    precondition(request.includeAuthenticationExpirationDate == false)
    precondition(request.localizedVideoTitle == nil)
    precondition(request.isInterruptionAllowed == false)
    precondition(request.forceAuthentication == false)
    precondition(request.attributeNames.isEmpty)
    precondition(request.supportedAuthenticationSchemes.isEmpty)
    precondition(request.accountProviderAuthenticationToken == nil)
    precondition(request.applicationAccountProviders == nil)

    request.channelIdentifier = "channel"
    request.supportedAccountProviderIdentifiers = ["provider.a"]
    request.featuredAccountProviderIdentifiers = ["provider.b"]
    request.verificationToken = "token"
    request.includeAccountProviderIdentifier = true
    request.includeAuthenticationExpirationDate = true
    request.localizedVideoTitle = "Show"
    request.isInterruptionAllowed = true
    request.forceAuthentication = true
    request.attributeNames = ["attr"]
    request.supportedAuthenticationSchemes = [.saml, .api]
    request.accountProviderAuthenticationToken = "auth-token"
    let application = VSAccountApplicationProvider(
        localizedDisplayName: "App",
        identifier: "app.id"
    )
    request.applicationAccountProviders = [application]

    precondition(request.channelIdentifier == "channel")
    precondition(request.supportedAccountProviderIdentifiers == ["provider.a"])
    precondition(request.featuredAccountProviderIdentifiers == ["provider.b"])
    precondition(request.verificationToken == "token")
    precondition(request.includeAccountProviderIdentifier)
    precondition(request.includeAuthenticationExpirationDate)
    precondition(request.localizedVideoTitle == "Show")
    precondition(request.isInterruptionAllowed)
    precondition(request.forceAuthentication)
    precondition(request.attributeNames == ["attr"])
    precondition(request.supportedAuthenticationSchemes == [.saml, .api])
    precondition(request.accountProviderAuthenticationToken == "auth-token")
    precondition(request.applicationAccountProviders?.count == 1)
    precondition(request.applicationAccountProviders?.first?.identifier == "app.id")
}

func testAccountMetadataLinuxInit() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let data = Data([0x01, 0x02])
    let response = VSAccountProviderResponse(
        authenticationScheme: .api,
        body: "{}",
        status: "OK"
    )
    let metadata = VSAccountMetadata(
        accountProviderIdentifier: "provider.a",
        authenticationExpirationDate: date,
        verificationData: data,
        samlAttributeQueryResponse: "<saml/>",
        accountProviderResponse: response
    )
    precondition(metadata.accountProviderIdentifier == "provider.a")
    precondition(metadata.authenticationExpirationDate == date)
    precondition(metadata.verificationData == data)
    precondition(metadata.samlAttributeQueryResponse == "<saml/>")
    precondition(metadata.accountProviderResponse === response)
}

func testAccountProviderResponseFields() {
    let response = VSAccountProviderResponse(
        authenticationScheme: .saml,
        body: "<body/>",
        status: "Success"
    )
    precondition(response.authenticationScheme == .saml)
    precondition(response.body == "<body/>")
    precondition(response.status == "Success")
    let empty = VSAccountProviderResponse(authenticationScheme: .api)
    precondition(response.authenticationScheme != empty.authenticationScheme)
    precondition(empty.body == nil)
    precondition(empty.status == nil)
}
