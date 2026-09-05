import Dispatch
import Foundation
import AuthenticationServices

private func field(_ value: String, type: ASImportableEditableField.FieldType = .string) -> ASImportableEditableField {
    ASImportableEditableField(id: Data(value.utf8), fieldType: type, value: value, label: value)
}

func testImportableEditableFieldAllTypes() {
    let types: [ASImportableEditableField.FieldType] = [
        .wifiNetworkSecurityType, .countryCode, .concealedString, .subdivisionCode,
        .date, .email, .number, .string, .boolean, .yearMonth
    ]
    for type in types {
        let value = ASImportableEditableField(id: nil, fieldType: type, value: "v")
        precondition(value.fieldType == type)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ASImportableEditableField.FieldType.string.rawValue == "string")
}

func testImportableCredentialAllCasesRoundTrip() {
    let linked = ASImportableLinkedItem(item: Data("item".utf8), account: Data("acc".utf8))
    precondition(linked.item == Data("item".utf8))
    let fingerprint = ASImportableCredentialScope.AndroidAppCertificationFingerprint(
        fingerprint: Data("fp".utf8),
        hashAlgorithm: "sha256"
    )
    let android = ASImportableCredentialScope.AndroidAppID(
        bundleID: "app.example",
        certificate: fingerprint,
        name: "Example"
    )
    let scope = ASImportableCredentialScope(
        urls: [URL(string: "https://example.invalid")!],
        androidApps: [android]
    )
    precondition(scope.androidApps.first?.bundleID == "app.example")

    let credentials: [ASImportableCredential] = [
        .basicAuthentication(.init(userName: field("user"), password: field("pw", type: .concealedString))),
        .creditCard(.init(
            number: field("4111"), fullName: field("Lane"), cardType: field("visa"),
            verificationNumber: field("123"), pin: field("0000"), expiryDate: field("12/30", type: .yearMonth),
            validFrom: field("01/20", type: .yearMonth)
        )),
        .personName(.init(
            title: field("Mx"), given: field("Lane"), givenInformal: field("L"),
            given2: nil, surnamePrefix: nil, surname: field("Example"),
            surname2: nil, credentials: nil, generation: field("Jr")
        )),
        .customFields(.init(id: Data("cf".utf8), label: "custom", fields: [field("x")])),
        .itemReference(.init(reference: linked)),
        .driversLicense(.init(
            fullName: field("Lane"), birthDate: field("1", type: .date), issueDate: field("2", type: .date),
            expiryDate: field("3", type: .date), issuingAuthority: field("DMV"), territory: field("CA", type: .subdivisionCode),
            country: field("US", type: .countryCode), licenseNumber: field("L1"), licenseClass: field("C")
        )),
        .identityDocument(.init(
            issuingCountry: field("US", type: .countryCode), documentNumber: field("D"),
            identificationNumber: field("I"), nationality: field("US"), fullName: field("Lane"),
            birthDate: field("1", type: .date), birthPlace: field("Town"), sex: field("X"),
            issueDate: field("2", type: .date), expiryDate: field("3", type: .date),
            issuingAuthority: field("Gov")
        )),
        .generatedPassword(.init(password: "pwgen")),
        .note(.init(content: field("hello"))),
        .totp(.init(
            secret: Data("secret".utf8), period: 30, digits: 6, userName: "lane",
            algorithm: .sha1, issuer: "Example"
        )),
        .totp(.init(
            secret: Data("secret".utf8), period: 30, digits: 8, userName: nil,
            algorithm: .sha256, issuer: nil
        )),
        .wifi(.init(
            ssid: field("net"), networkSecurityType: field("wpa", type: .wifiNetworkSecurityType),
            passphrase: field("pw", type: .concealedString), hidden: field("false", type: .boolean)
        )),
        .apiKey(.init(
            key: field("k"), userName: field("u"), keyType: field("bearer"),
            url: field("https://example.invalid"), validFrom: field("1", type: .date),
            expiryDate: field("2", type: .date)
        )),
        .sshKey(.init(
            keyType: "ed25519", privateKey: Data("pk".utf8), keyComment: "lane",
            creationDate: field("1", type: .date), expiryDate: field("2", type: .date),
            keyGenerationSource: field("host")
        )),
        .address(.init(
            streetAddress: field("1 Main"), postalCode: field("00000"), city: field("Town"),
            territory: field("CA"), country: field("US"), telephone: field("555")
        )),
        .passkey(.init(
            credentialID: Data("id".utf8), relyingPartyIdentifier: "example.invalid",
            userName: "lane", userDisplayName: "Lane", userHandle: Data("h".utf8), key: Data("k".utf8)
        )),
        .passport(.init(
            issuingCountry: field("US"), passportType: field("P"), passportNumber: field("P1"),
            nationalIdentificationNumber: field("N"), nationality: field("US"), fullName: field("Lane"),
            birthDate: field("1"), birthPlace: field("Town"), sex: field("X"),
            issueDate: field("2"), expiryDate: field("3"), issuingAuthority: field("Gov")
        )),
    ]
    precondition(ASImportableCredential.TOTP.Algorithm.sha1.rawValue == "sha1")
    precondition(ASImportableCredential.TOTP.Algorithm.sha512.rawValue == "sha512")

    let datedItem = ASImportableItem(
        id: Data("dated".utf8),
        created: Date(timeIntervalSince1970: 1),
        lastModified: Date(timeIntervalSince1970: 2),
        title: "dated",
        subtitle: "sub",
        favorite: true,
        scope: scope,
        credentials: credentials,
        tags: ["a"]
    )
    precondition(datedItem.favorite)
    let collection = ASImportableCollection(
        id: Data("col".utf8),
        created: Date(timeIntervalSince1970: 3),
        lastModified: Date(timeIntervalSince1970: 4),
        title: "col",
        subtitle: "sub",
        items: [linked],
        subcollections: []
    )
    precondition(collection.title == "col")
    let account = ASImportableAccount(
        id: Data("acct".utf8),
        userName: "lane",
        email: "lane@example.invalid",
        fullName: "Lane Example",
        collections: [collection],
        items: [datedItem]
    )
    let exported = ASExportedCredentialData(
        accounts: [account],
        formatVersion: .v1,
        exporterRelyingPartyIdentifier: "example.invalid",
        exporterDisplayName: "lane",
        timestamp: Date(timeIntervalSince1970: 5)
    )
    let encoded = try! JSONEncoder().encode(exported)
    let decoded = try! JSONDecoder().decode(ASExportedCredentialData.self, from: encoded)
    precondition(decoded == exported)
    precondition(decoded.accounts.first?.items.first?.credentials.count == credentials.count)

    let options = ASCredentialExportManager.ExportOptions(formatVersion: .v1)
    let optionsData = try! JSONEncoder().encode(options)
    let decodedOptions = try! JSONDecoder().decode(ASCredentialExportManager.ExportOptions.self, from: optionsData)
    precondition(decodedOptions == options)
    _ = options.hashValue
    _ = exported.hashValue
    _ = account.hashValue
    _ = collection.hashValue
    _ = datedItem.hashValue
    _ = scope.hashValue
    _ = linked.hashValue
    _ = fingerprint.hashValue
    _ = android.hashValue
}

func testContactIdentifiersAndAccountCreationCredential() {
    let email = ASEmailIdentifier(value: "lane@example.invalid")
    let phone = ASPhoneNumberIdentifier(value: "+1555")
    precondition(email.value.hasPrefix("lane"))
    precondition(phone.value.hasPrefix("+"))
    let contactEmail = ASContactIdentifier.email(email)
    let contactPhone = ASContactIdentifier.phoneNumber(phone)
    if case .email(let value) = contactEmail {
        precondition(value.value == email.value)
    } else {
        preconditionFailure("expected email identifier")
    }
    if case .phoneNumber(let value) = contactPhone {
        precondition(value.value == phone.value)
    } else {
        preconditionFailure("expected phone identifier")
    }
    _ = ASContactIdentifierRequest.email
    _ = ASContactIdentifierRequest.phoneNumber
    let created = ASAuthorizationAccountCreationPlatformPublicKeyCredential()
    created.contactIdentifier = contactEmail
    created.name = PersonNameComponents()
    created.credentialRegistration = ASAuthorizationPlatformPublicKeyCredentialRegistration()
    precondition(created.credentialRegistration.attachment == .platform)
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    created.encode(with: archiver)
    precondition(ASAuthorizationAccountCreationPlatformPublicKeyCredential(coder: archiver) == nil)
    _ = created.copy()
    precondition(ASAuthorizationAccountCreationPlatformPublicKeyCredential.supportsSecureCoding)
}

func testPlatformAssertionAndRegistrationCredentials() {
    let assertion = ASAuthorizationPlatformPublicKeyCredentialAssertion()
    assertion.rawClientDataJSON = Data("j".utf8)
    assertion.credentialID = Data("id".utf8)
    assertion.rawAuthenticatorData = Data("a".utf8)
    assertion.signature = Data("s".utf8)
    assertion.userID = Data("u".utf8)
    assertion.attachment = .platform
    assertion.prf = ASAuthorizationPublicKeyCredentialPRFAssertionOutput()
    assertion.largeBlob = .read(data: nil)
    precondition(assertion.credentialID == Data("id".utf8))
    let registration = ASAuthorizationPlatformPublicKeyCredentialRegistration()
    registration.rawAttestationObject = Data("att".utf8)
    registration.attachment = .crossPlatform
    registration.prf = .supported
    registration.largeBlob = .unsupported
    precondition(registration.rawAttestationObject == Data("att".utf8))
    let skAssertion = ASAuthorizationSecurityKeyPublicKeyCredentialAssertion()
    skAssertion.appID = true
    skAssertion.userID = Data("u".utf8)
    skAssertion.signature = Data("s".utf8)
    skAssertion.rawAuthenticatorData = Data("a".utf8)
    let skRegistration = ASAuthorizationSecurityKeyPublicKeyCredentialRegistration()
    skRegistration.transports = [.usb]
    skRegistration.rawAttestationObject = Data("att".utf8)
    precondition(skRegistration.transports == [.usb])
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    assertion.encode(with: archiver)
    registration.encode(with: archiver)
    skAssertion.encode(with: archiver)
    skRegistration.encode(with: archiver)
    precondition(ASAuthorizationPlatformPublicKeyCredentialAssertion(coder: archiver) == nil)
    precondition(ASAuthorizationPlatformPublicKeyCredentialRegistration(coder: archiver) == nil)
    precondition(ASAuthorizationSecurityKeyPublicKeyCredentialAssertion(coder: archiver) == nil)
    precondition(ASAuthorizationSecurityKeyPublicKeyCredentialRegistration(coder: archiver) == nil)
    precondition(ASAuthorizationPlatformPublicKeyCredentialDescriptor(coder: archiver) == nil)
    precondition(ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor(coder: archiver) == nil)
    precondition(ASAuthorizationPublicKeyCredentialParameters(coder: archiver) == nil)
    _ = assertion.copy()
    _ = registration.copy()
    _ = skAssertion.copy()
    _ = skRegistration.copy()
    _ = ASAuthorizationResult.passkeyAssertion(assertion)
    _ = ASAuthorizationResult.passkeyRegistration(registration)
    _ = ASAuthorizationResult.securityKeyAssertion(skAssertion)
    _ = ASAuthorizationResult.securityKeyRegistration(skRegistration)
    _ = ASAuthorizationResult.appleID(ASAuthorizationAppleIDCredential())
    _ = ASAuthorizationResult.passkeyAccountCreation(ASAuthorizationAccountCreationPlatformPublicKeyCredential())
}

func testRequestOptionsRemainingMembers() {
    var options = ASAuthorizationController.RequestOptions()
    _ = ASAuthorizationController.RequestOptions(rawValue: 1)
    _ = ASAuthorizationController.RequestOptions(arrayLiteral: .preferImmediatelyAvailableCredentials)
    _ = ASAuthorizationController.RequestOptions([.preferImmediatelyAvailableCredentials])
    options.formUnion(.preferImmediatelyAvailableCredentials)
    options.formIntersection(.preferImmediatelyAvailableCredentials)
    options.formSymmetricDifference([])
    _ = options.intersection(.preferImmediatelyAvailableCredentials)
    _ = options.symmetricDifference([])
    _ = options.subtracting([])
    _ = options.isStrictSubset(of: [.preferImmediatelyAvailableCredentials])
    _ = options.isStrictSuperset(of: [])
    _ = options.update(with: .preferImmediatelyAvailableCredentials)
    _ = options.remove(.preferImmediatelyAvailableCredentials)
}

func testWebBrowserCredentialAndTransportAllSupported() {
    var credential = ASAuthorizationWebBrowserPlatformPublicKeyCredential(
        name: "lane",
        relyingParty: "example.invalid",
        credentialID: Data("id".utf8),
        userHandle: Data("h".utf8)
    )
    credential.providerName = "provider"
    credential.userName = "lane"
    credential.customTitle = "title"
    precondition(credential.customTitle == "title")
    let transports = ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.allSupported
    precondition(transports.count == 3)
    _ = ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport(rawValue: "usb")
    _ = ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport("nfc")
    let manager = ASAuthorizationWebBrowserPublicKeyCredentialManager()
    let requested = asAwait { () -> ASAuthorizationWebBrowserPublicKeyCredentialManager.AuthorizationState in
        await manager.requestAuthorization()
    }
    guard case .success(.denied) = requested else {
        preconditionFailure("expected denied requestAuthorization")
    }
}

func testOpenIDRequestStateAndNonce() {
    let request = ASAuthorizationAppleIDProvider().createRequest()
    request.state = "state"
    request.nonce = "nonce"
    precondition(request.state == "state")
    precondition(request.nonce == "nonce")
    precondition(request.requestedOperation == .operationImplicit)
    request.requestedScopes = nil
    precondition(request.requestedScopes == nil)
}
