import Foundation
import ProximityReader

func testMobileDocumentReaderTokenAndSupport() {
    precondition(MobileDocumentReader.isSupported == false)
    let reader = MobileDocumentReader()
    _ = reader
    let token = MobileDocumentReader.Token("doc-token")
    precondition(token.tokenString == "doc-token")
    precondition(token == MobileDocumentReader.Token("doc-token"))
    precondition(token != MobileDocumentReader.Token("other"))
    _ = token.hashValue
    var hasher = Hasher()
    token.hash(into: &hasher)
    let configuration = MobileDocumentReader.Configuration(readerInstanceIdentifier: "reader-1")
    precondition(configuration.readerInstanceIdentifier == "reader-1")
    precondition(configuration == MobileDocumentReader.Configuration(readerInstanceIdentifier: "reader-1"))
    _ = configuration.hashValue
    configuration.hash(into: &hasher)
}


func testMobileDocumentReaderErrorCases() {
    let cases: [MobileDocumentReaderError] = [
        .notAllowed, .systemBusy, .invalidToken, .notSupported, .invalidRequest,
        .sessionExpired, .invalidResponse, .networkUnavailable, .serviceUnavailable,
        .unknown, .cancelled,
    ]
    precondition(cases.count == 11)
    precondition(MobileDocumentReaderError.notSupported == .notSupported)
    precondition(MobileDocumentReaderError.cancelled != .unknown)
}


func testMobileDocumentReaderErrorLocalized() {
    let error = MobileDocumentReaderError.notSupported
    precondition(error.errorDescription?.contains("notSupported") == true)
    precondition(error.failureReason == nil)
    precondition(error.recoverySuggestion == nil)
    precondition(error.helpAnchor == nil)
    precondition(error.localizedDescription.contains("notSupported"))
    _ = error.hashValue
    var hasher = Hasher()
    error.hash(into: &hasher)
}


func testPhotoIDDataRequestElements() {
    let names: [MobilePhotoIDDataRequest.Element] = [
        .familyName, .dateOfBirth, .documentNumber, .issuingAuthority,
        .documentIssueDate, .documentExpirationDate, .age, .sex, .address,
        .portrait, .givenName,
    ]
    precondition(names.count == 11)
    precondition(MobilePhotoIDDataRequest.Element.familyName != .givenName)
    let age = MobilePhotoIDDataRequest.Element.ageAtLeast(21)
    precondition(age != .age)
    precondition(MobilePhotoIDDataRequest.Element.ageAtLeast(21) == MobilePhotoIDDataRequest.Element.ageAtLeast(21))
    precondition(MobilePhotoIDDataRequest.Element.ageAtLeast(18) != age)
    _ = age.hashValue
    var hasher = Hasher()
    age.hash(into: &hasher)
}


func testPhotoIDDataRequestFactories() {
    let request = MobilePhotoIDDataRequest(
        retainedElements: [.givenName],
        nonRetainedElements: [.portrait]
    )
    precondition(request.retainedElements == [.givenName])
    precondition(request.nonRetainedElements == [.portrait])
    let factory = MobilePhotoIDDataRequest.photoIDData(
        retaining: [.familyName],
        notRetaining: [.age]
    )
    precondition(factory.retainedElements == [.familyName])
    let viaProtocol: MobilePhotoIDDataRequest = .photoIDData(
        retaining: [.documentNumber],
        notRetaining: []
    )
    precondition(viaProtocol.retainedElements == [.documentNumber])
    precondition(request != factory)
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
}


func testPhotoIDResponseDocumentElements() {
    let authority = MobilePhotoIDDataRequest.Response.DocumentElements.IssuingAuthority(
        jurisdiction: "CA",
        isoCountryCode: "US",
        name: "DMV"
    )
    precondition(authority.jurisdiction == "CA")
    precondition(authority.isoCountryCode == "US")
    precondition(authority.name == "DMV")
    _ = authority.hashValue
    var hasher = Hasher()
    authority.hash(into: &hasher)

    let address = CNPostalAddress()
    address.city = "Cupertino"
    var components = PersonNameComponents()
    components.givenName = "Ada"
    let elements = MobilePhotoIDDataRequest.Response.DocumentElements(
        ageAtLeastElements: [21: true],
        dateOfBirth: DateComponents(year: 1990, month: 1, day: 2),
        portraitData: Data([0xFF]),
        documentNumber: "P1",
        nameComponents: components,
        issuingAuthority: authority,
        documentIssueDate: DateComponents(year: 2020),
        documentExpirationDate: DateComponents(year: 2030),
        age: 34,
        sex: .female,
        address: address
    )
    precondition(elements.ageAtLeastElements[21] == true)
    precondition(elements.documentNumber == "P1")
    precondition(elements.age == 34)
    precondition(elements.sex == .female)
    precondition(elements.address?.city == "Cupertino")
    precondition(elements.nameComponents?.givenName == "Ada")
    _ = elements.hashValue
    elements.hash(into: &hasher)
    let response = MobilePhotoIDDataRequest.Response(documentElements: elements)
    precondition(response.documentElements.documentNumber == "P1")
    _ = response.hashValue
    response.hash(into: &hasher)
}


func testPhotoIDSexEnum() {
    let sexes: [MobilePhotoIDDataRequest.Response.DocumentElements.Sex] = [
        .notApplicable, .male, .female, .unknown,
    ]
    precondition(sexes.count == 4)
    precondition(MobilePhotoIDDataRequest.Response.DocumentElements.Sex.male.localizedName == "Male")
    precondition(MobilePhotoIDDataRequest.Response.DocumentElements.Sex.female.localizedName == "Female")
    precondition(MobilePhotoIDDataRequest.Response.DocumentElements.Sex.notApplicable.localizedName == "Not Applicable")
    precondition(MobilePhotoIDDataRequest.Response.DocumentElements.Sex.unknown.localizedName == "Unknown")
    precondition(MobilePhotoIDDataRequest.Response.DocumentElements.Sex.male != .female)
    _ = MobilePhotoIDDataRequest.Response.DocumentElements.Sex.male.hashValue
    var hasher = Hasher()
    MobilePhotoIDDataRequest.Response.DocumentElements.Sex.unknown.hash(into: &hasher)
}


func testPhotoIDRawDataRequest() {
    let request = MobilePhotoIDRawDataRequest(
        retainedElements: [.givenName],
        nonRetainedElements: [.portrait]
    )
    precondition(request.retainedElements == [.givenName])
    let factory = MobilePhotoIDRawDataRequest.photoIDRawData(
        retaining: [.familyName],
        notRetaining: []
    )
    precondition(factory.retainedElements == [.familyName])
    let viaProtocol: MobilePhotoIDRawDataRequest = .photoIDRawData(
        retaining: [.age],
        notRetaining: []
    )
    precondition(viaProtocol.retainedElements == [.age])
    _ = MobilePhotoIDRawDataRequest.Element.ageAtLeast(65)
    let response = MobilePhotoIDRawDataRequest.Response(
        responseData: Data([0x01]),
        sessionTranscript: Data([0x02])
    )
    precondition(response.responseData == Data([0x01]))
    precondition(response.sessionTranscript == Data([0x02]))
    _ = request.hashValue
    _ = response.hashValue
}


func testDocumentDisplayRequest() {
    precondition(MobileDocumentDisplayRequest.Options.ValidationMode.check != .confirm)
    precondition(MobileDocumentDisplayRequest.Options.ValidationMode.checkMultiple != .check)
    let options = MobileDocumentDisplayRequest.Options(
        allowedDocumentTypes: [.driversLicense, .photoID],
        validationMode: .confirm
    )
    precondition(options.allowedDocumentTypes.contains(.driversLicense))
    precondition(options.validationMode == .confirm)
    let national = MobileDocumentDisplayRequest.Options.DocumentType.nationalIDCard(region: Locale.Region("DE"))
    precondition(national != .photoID)
    let request = MobileDocumentDisplayRequest(
        elements: [.givenName, .familyName, .age],
        options: options
    )
    precondition(request.elements.contains(.givenName))
    let factory = MobileDocumentDisplayRequest.displayDocument([.age], options: .init())
    precondition(factory.elements == [.age])
    let viaProtocol: MobileDocumentDisplayRequest = .displayDocument([.familyName], options: options)
    precondition(viaProtocol.elements == [.familyName])
    _ = MobileDocumentDisplayRequest.Element.ageAtLeast(18)
    let response = MobileDocumentDisplayRequest.Response(validationOutcome: .approved)
    precondition(response.validationOutcome == .approved)
    _ = request.hashValue
    _ = options.hashValue
    _ = national.hashValue
}


func testDocumentDisplayValidationOutcome() {
    let outcomes: [MobileDocumentDisplayRequest.Response.ValidationOutcome] = [
        .approved, .rejected, .dismissed,
    ]
    precondition(outcomes.count == 3)
    precondition(MobileDocumentDisplayRequest.Response.ValidationOutcome.approved != .rejected)
    _ = MobileDocumentDisplayRequest.Response.ValidationOutcome.dismissed.hashValue
    var hasher = Hasher()
    MobileDocumentDisplayRequest.Response.ValidationOutcome.approved.hash(into: &hasher)
}


func testAnyOfDataRequest() {
    var anyOf = MobileDocumentAnyOfDataRequest()
    anyOf.addRequest(MobilePhotoIDDataRequest(retainedElements: [.givenName]))
    var other = MobileDocumentAnyOfDataRequest()
    precondition(anyOf != other)
    other.addRequest(MobilePhotoIDDataRequest(retainedElements: [.givenName]))
    precondition(anyOf == other)
    other.addRequest(MobileDriversLicenseDataRequest(retainedElements: [.familyName]))
    other.addRequest(MobileNationalIDCardDataRequest(region: Locale.Region("US")))
    _ = anyOf.hashValue
    let response = MobileDocumentAnyOfDataRequest.Response(
        documentResponse: MobilePhotoIDDataRequest.Response(
            documentElements: MobilePhotoIDDataRequest.Response.DocumentElements()
        )
    )
    _ = response.documentResponse
    _ = response.hashValue
}


func testDriversLicenseDataRequestElements() {
    let names: [MobileDriversLicenseDataRequest.Element] = [
        .familyName, .dateOfBirth, .veteranStatus, .documentNumber, .issuingAuthority,
        .organDonorStatus, .documentIssueDate, .drivingPrivileges, .documentExpirationDate,
        .documentDHSComplianceStatus, .age, .sex, .height, .weight, .address, .eyeColor,
        .portrait, .givenName, .hairColor,
    ]
    precondition(names.count == 19)
    precondition(MobileDriversLicenseDataRequest.Element.eyeColor != .hairColor)
    _ = MobileDriversLicenseDataRequest.Element.ageAtLeast(21)
    let request = MobileDriversLicenseDataRequest.driversLicenseData(
        retaining: [.givenName],
        notRetaining: [.portrait]
    )
    precondition(request.retainedElements == [.givenName])
    let viaProtocol: MobileDriversLicenseDataRequest = .driversLicenseData(
        retaining: [.familyName],
        notRetaining: []
    )
    precondition(viaProtocol.retainedElements == [.familyName])
    _ = request.hashValue
}


func testDriversLicenseResponseEnums() {
    let sexes: [MobileDriversLicenseDataRequest.Response.DocumentElements.Sex] = [
        .notSpecified, .notApplicable, .male, .female, .unknown,
    ]
    precondition(sexes.count == 5)
    precondition(MobileDriversLicenseDataRequest.Response.DocumentElements.Sex.notSpecified.localizedName == "Not Specified")
    precondition(MobileDriversLicenseDataRequest.Response.DocumentElements.Sex.male != .female)
    _ = MobileDriversLicenseDataRequest.Response.DocumentElements.Sex.male.hashValue

    let eyes: [MobileDriversLicenseDataRequest.Response.DocumentElements.EyeColor] = [
        .dichromatic, .blue, .grey, .pink, .black, .brown, .green, .hazel, .maroon, .unknown,
    ]
    precondition(eyes.count == 10)
    precondition(MobileDriversLicenseDataRequest.Response.DocumentElements.EyeColor.blue != .brown)
    _ = MobileDriversLicenseDataRequest.Response.DocumentElements.EyeColor.green.hashValue

    let hair: [MobileDriversLicenseDataRequest.Response.DocumentElements.HairColor] = [
        .red, .bald, .grey, .black, .blond, .brown, .sandy, .white, .auburn, .unknown,
    ]
    precondition(hair.count == 10)
    precondition(MobileDriversLicenseDataRequest.Response.DocumentElements.HairColor.blond != .black)
    _ = MobileDriversLicenseDataRequest.Response.DocumentElements.HairColor.auburn.hashValue

    precondition(MobileDriversLicenseDataRequest.Response.DocumentElements.DHSComplianceStatus.compliant != .noncompliant)
    _ = MobileDriversLicenseDataRequest.Response.DocumentElements.DHSComplianceStatus.compliant.hashValue
    var hasher = Hasher()
    MobileDriversLicenseDataRequest.Response.DocumentElements.DHSComplianceStatus.noncompliant.hash(into: &hasher)
    MobileDriversLicenseDataRequest.Response.DocumentElements.EyeColor.unknown.hash(into: &hasher)
    MobileDriversLicenseDataRequest.Response.DocumentElements.HairColor.unknown.hash(into: &hasher)
    MobileDriversLicenseDataRequest.Response.DocumentElements.Sex.unknown.hash(into: &hasher)
}


func testDriversLicenseResponseFields() {
    let code = MobileDriversLicenseDataRequest.Response.DocumentElements.DrivingPrivilege.Code(
        code: "01",
        sign: "+",
        value: "auto"
    )
    precondition(code.code == "01")
    precondition(code.sign == "+")
    precondition(code.value == "auto")
    _ = code.hashValue
    var hasher = Hasher()
    code.hash(into: &hasher)

    let privilege = MobileDriversLicenseDataRequest.Response.DocumentElements.DrivingPrivilege(
        vehicleCategoryCode: "B",
        codes: [code],
        issueDate: DateComponents(year: 2015),
        expirationDate: DateComponents(year: 2028)
    )
    precondition(privilege.vehicleCategoryCode == "B")
    precondition(privilege.codes.count == 1)
    _ = privilege.hashValue
    privilege.hash(into: &hasher)

    let vehicleClass = MobileDriversLicenseDataRequest.Response.DocumentElements.AAMVADrivingPrivilege.VehicleClass(
        code: "C",
        description: "Commercial",
        issueDate: DateComponents(year: 2016),
        expirationDate: DateComponents(year: 2027)
    )
    precondition(vehicleClass.code == "C")
    precondition(vehicleClass.description == "Commercial")
    _ = vehicleClass.hashValue
    vehicleClass.hash(into: &hasher)

    let endorsement = MobileDriversLicenseDataRequest.Response.DocumentElements.AAMVADrivingPrivilege.VehicleEndorsement(
        code: "H",
        description: "Hazmat"
    )
    precondition(endorsement.code == "H")
    _ = endorsement.hashValue
    endorsement.hash(into: &hasher)

    let restriction = MobileDriversLicenseDataRequest.Response.DocumentElements.AAMVADrivingPrivilege.VehicleRestriction(
        code: "B",
        description: "Corrective lenses"
    )
    precondition(restriction.description.contains("Corrective"))
    _ = restriction.hashValue
    restriction.hash(into: &hasher)

    let aamva = MobileDriversLicenseDataRequest.Response.DocumentElements.AAMVADrivingPrivilege(
        vehicleClass: vehicleClass,
        vehicleEndorsements: [endorsement],
        vehicleRestrictions: [restriction]
    )
    precondition(aamva.vehicleEndorsements.count == 1)
    _ = aamva.hashValue
    aamva.hash(into: &hasher)

    let authority = MobileDriversLicenseDataRequest.Response.DocumentElements.IssuingAuthority(
        jurisdiction: "CA",
        isoCountryCode: "US",
        name: "DMV"
    )
    precondition(authority.name == "DMV")
    _ = authority.hashValue
    authority.hash(into: &hasher)

    let elements = MobileDriversLicenseDataRequest.Response.DocumentElements(
        isOrganDonor: true,
        documentNumber: "D1",
        issuingAuthority: authority,
        drivingPrivileges: [privilege],
        aamvaDrivingPrivileges: [aamva],
        documentDHSComplianceStatus: .compliant,
        height: Measurement(value: 180, unit: UnitLength.centimeters),
        weight: Measurement(value: 70, unit: UnitMass.kilograms),
        eyeColor: .hazel,
        hairColor: .brown,
        isVeteran: false
    )
    precondition(elements.isOrganDonor == true)
    precondition(elements.isVeteran == false)
    precondition(elements.height?.value == 180)
    precondition(elements.weight?.value == 70)
    _ = elements.hashValue
    elements.hash(into: &hasher)
    let response = MobileDriversLicenseDataRequest.Response(documentElements: elements)
    precondition(response.documentElements.documentNumber == "D1")
    _ = response.hashValue
    response.hash(into: &hasher)
}


func testDriversLicenseRawDataRequest() {
    let request = MobileDriversLicenseRawDataRequest.driversLicenseRawData(
        retaining: [.givenName, .hairColor],
        notRetaining: [.portrait]
    )
    precondition(request.retainedElements.contains(.hairColor))
    let viaProtocol: MobileDriversLicenseRawDataRequest = .driversLicenseRawData(
        retaining: [.eyeColor],
        notRetaining: []
    )
    precondition(viaProtocol.retainedElements == [.eyeColor])
    _ = MobileDriversLicenseRawDataRequest.Element.ageAtLeast(16)
    let response = MobileDriversLicenseRawDataRequest.Response(
        responseData: Data([0x11]),
        sessionTranscript: Data([0x22])
    )
    precondition(response.responseData.count == 1)
    _ = request.hashValue
    _ = response.hashValue
}


func testDriversLicenseDisplayRequest() {
    let options = MobileDriversLicenseDisplayRequest.Options(validationMode: .checkMultiple)
    precondition(options.validationMode == .checkMultiple)
    precondition(MobileDriversLicenseDisplayRequest.Options.ValidationMode.check != .confirm)
    let request = MobileDriversLicenseDisplayRequest.displayDriversLicense(
        [.givenName, .familyName, .age],
        options: options
    )
    precondition(request.elements.contains(.age))
    let viaProtocol: MobileDriversLicenseDisplayRequest = .displayDriversLicense([.familyName])
    precondition(viaProtocol.elements == [.familyName])
    _ = MobileDriversLicenseDisplayRequest.Element.ageAtLeast(21)
    let response = MobileDriversLicenseDisplayRequest.Response(validationOutcome: .rejected)
    precondition(response.validationOutcome == .rejected)
    let outcomes: [MobileDriversLicenseDisplayRequest.Response.ValidationOutcome] = [
        .approved, .rejected, .dismissed,
    ]
    precondition(outcomes.contains(.dismissed))
    _ = request.hashValue
    _ = options.hashValue
    _ = response.hashValue
    var hasher = Hasher()
    MobileDriversLicenseDisplayRequest.Options.ValidationMode.confirm.hash(into: &hasher)
    MobileDriversLicenseDisplayRequest.Response.ValidationOutcome.approved.hash(into: &hasher)
}


func testNationalIDDataRequest() {
    let region = Locale.Region("DE")
    precondition(MobileNationalIDCardDataRequest.isSupportedRegion(region) == false)
    precondition(MobileNationalIDCardDataRequest.isSupportedRegion(Locale.Region("US")) == false)
    let request = MobileNationalIDCardDataRequest.nationalIDCardData(
        region: region,
        retaining: [.givenName, .familyName, .documentNumber, .dateOfBirth, .age, .sex, .portrait]
    )
    precondition(request.region == region)
    precondition(request.retainedElements.contains(.documentNumber))
    let viaProtocol: MobileNationalIDCardDataRequest = .nationalIDCardData(
        region: region,
        retaining: [.givenName]
    )
    precondition(viaProtocol.retainedElements == [.givenName])
    _ = MobileNationalIDCardDataRequest.Element.ageAtLeast(18)
    _ = request.hashValue
}


func testNationalIDSexEnum() {
    let sexes: [MobileNationalIDCardDataRequest.Response.DocumentElements.Sex] = [
        .notApplicable, .male, .female, .unknown,
    ]
    precondition(sexes.count == 4)
    precondition(MobileNationalIDCardDataRequest.Response.DocumentElements.Sex.female.localizedName == "Female")
    precondition(MobileNationalIDCardDataRequest.Response.DocumentElements.Sex.male != .unknown)
    _ = MobileNationalIDCardDataRequest.Response.DocumentElements.Sex.male.hashValue
    var hasher = Hasher()
    MobileNationalIDCardDataRequest.Response.DocumentElements.Sex.unknown.hash(into: &hasher)
    let elements = MobileNationalIDCardDataRequest.Response.DocumentElements(
        ageAtLeastElements: [18: true],
        portraitData: Data(),
        dateOfBirth: DateComponents(year: 1980),
        documentNumber: "N1",
        nameComponents: PersonNameComponents(),
        age: 40,
        sex: .male
    )
    precondition(elements.documentNumber == "N1")
    _ = elements.hashValue
    elements.hash(into: &hasher)
    let response = MobileNationalIDCardDataRequest.Response(
        documentElements: elements,
        region: Locale.Region("FR")
    )
    precondition(response.region.identifier == "FR")
    _ = response.hashValue
    response.hash(into: &hasher)
}


func testNationalIDRawAndDisplay() {
    let region = Locale.Region("IT")
    precondition(MobileNationalIDCardDisplayRequest.isSupportedRegion(region) == false)
    precondition(MobileNationalIDCardRawDataRequest.isSupportedRegion(region) == false)
    let display = MobileNationalIDCardDisplayRequest.nationalIDCard(
        region: region,
        [.givenName, .familyName, .age],
        options: .init(validationMode: .confirm)
    )
    precondition(display.region == region)
    precondition(display.options.validationMode == .confirm)
    let viaDisplay: MobileNationalIDCardDisplayRequest = .nationalIDCard(region: region, [.age])
    precondition(viaDisplay.elements == [.age])
    _ = MobileNationalIDCardDisplayRequest.Element.ageAtLeast(16)
    let displayResponse = MobileNationalIDCardDisplayRequest.Response(validationOutcome: .dismissed)
    precondition(displayResponse.validationOutcome == .dismissed)
    let outcomes: [MobileNationalIDCardDisplayRequest.Response.ValidationOutcome] = [
        .approved, .rejected, .dismissed,
    ]
    precondition(outcomes.count == 3)

    let raw = MobileNationalIDCardRawDataRequest.nationalIDCardRawData(
        region: region,
        retaining: [.givenName, .address]
    )
    precondition(raw.retainedElements.contains(.address))
    let viaRaw: MobileNationalIDCardRawDataRequest = .nationalIDCardRawData(
        region: region,
        retaining: [.sex]
    )
    precondition(viaRaw.retainedElements == [.sex])
    _ = MobileNationalIDCardRawDataRequest.Element.ageAtLeast(21)
    let rawResponse = MobileNationalIDCardRawDataRequest.Response(
        responseData: Data([0x33]),
        sessionTranscript: Data([0x44])
    )
    precondition(rawResponse.sessionTranscript.count == 1)
    _ = display.hashValue
    _ = raw.hashValue
    _ = displayResponse.hashValue
    _ = rawResponse.hashValue
    var hasher = Hasher()
    MobileNationalIDCardDisplayRequest.Options.ValidationMode.check.hash(into: &hasher)
    MobileNationalIDCardDisplayRequest.Response.ValidationOutcome.rejected.hash(into: &hasher)
}


func testAnyOfRawDataRequest() {
    var anyOf = MobileDocumentAnyOfRawDataRequest()
    anyOf.addRequest(MobilePhotoIDRawDataRequest(retainedElements: [.givenName]))
    anyOf.addRequest(MobileDriversLicenseRawDataRequest())
    _ = anyOf.hashValue
    let response = MobileDocumentAnyOfRawDataRequest.Response(
        responseData: Data([0x01, 0x02]),
        sessionTranscript: Data([0x03])
    )
    precondition(response.responseData.count == 2)
    _ = response.hashValue
    precondition(anyOf != MobileDocumentAnyOfRawDataRequest())
}
