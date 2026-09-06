import Foundation
import PassKit

// MARK: - Stored ZIP (APPNOTE.TXT method 0) for PKPass.init(data:) fixtures

private func zipCRCTable() -> [UInt32] {
    var table = [UInt32](repeating: 0, count: 256)
    for i in 0..<256 {
        var crc = UInt32(i)
        for _ in 0..<8 {
            if crc & 1 == 1 {
                crc = 0xEDB8_8320 ^ (crc >> 1)
            } else {
                crc = crc >> 1
            }
        }
        table[i] = crc
    }
    return table
}

private let zipCRC32Table = zipCRCTable()

private func zipCRC32(_ data: Data) -> UInt32 {
    var crc: UInt32 = 0xFFFF_FFFF
    for byte in data {
        let index = Int((crc ^ UInt32(byte)) & 0xFF)
        crc = zipCRC32Table[index] ^ (crc >> 8)
    }
    return crc ^ 0xFFFF_FFFF
}

private func appendUInt16(_ data: inout Data, _ value: UInt16) {
    var le = value.littleEndian
    withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
}

private func appendUInt32(_ data: inout Data, _ value: UInt32) {
    var le = value.littleEndian
    withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
}

func passKitStoredZip(_ files: [String: Data]) -> Data {
    var locals = Data()
    var centrals = Data()
    let names = files.keys.sorted()
    for name in names {
        guard let payload = files[name] else { continue }
        let nameData = Data(name.utf8)
        let localOffset = UInt32(locals.count)
        let crc = zipCRC32(payload)
        let size = UInt32(payload.count)
        appendUInt32(&locals, 0x0403_4b50)
        appendUInt16(&locals, 20)
        appendUInt16(&locals, 0)
        appendUInt16(&locals, 0)
        appendUInt16(&locals, 0)
        appendUInt16(&locals, 0)
        appendUInt32(&locals, crc)
        appendUInt32(&locals, size)
        appendUInt32(&locals, size)
        appendUInt16(&locals, UInt16(nameData.count))
        appendUInt16(&locals, 0)
        locals.append(nameData)
        locals.append(payload)

        appendUInt32(&centrals, 0x0201_4b50)
        appendUInt16(&centrals, 20)
        appendUInt16(&centrals, 20)
        appendUInt16(&centrals, 0)
        appendUInt16(&centrals, 0)
        appendUInt16(&centrals, 0)
        appendUInt16(&centrals, 0)
        appendUInt32(&centrals, crc)
        appendUInt32(&centrals, size)
        appendUInt32(&centrals, size)
        appendUInt16(&centrals, UInt16(nameData.count))
        appendUInt16(&centrals, 0)
        appendUInt16(&centrals, 0)
        appendUInt16(&centrals, 0)
        appendUInt16(&centrals, 0)
        appendUInt32(&centrals, 0)
        appendUInt32(&centrals, localOffset)
        centrals.append(nameData)
    }
    let cdOffset = UInt32(locals.count)
    var out = locals
    out.append(centrals)
    appendUInt32(&out, 0x0605_4b50)
    appendUInt16(&out, 0)
    appendUInt16(&out, 0)
    appendUInt16(&out, UInt16(names.count))
    appendUInt16(&out, UInt16(names.count))
    appendUInt32(&out, UInt32(centrals.count))
    appendUInt32(&out, cdOffset)
    appendUInt16(&out, 0)
    return out
}

func passKitPassJSONObject(_ extra: [String: Any] = [:]) -> [String: Any] {
    var root: [String: Any] = [
        "formatVersion": 1,
        "passTypeIdentifier": "pass.openuikit.example",
        "serialNumber": "SN-1",
        "teamIdentifier": "TEAMID",
        "organizationName": "OpenUIKit",
        "description": "Event ticket",
        "logoText": "Logo",
        "authenticationToken": "tok-1",
        "webServiceURL": "https://example.com/passes",
        "relevantDate": "2026-09-05T12:00:00Z",
        "expirationDate": "2026-12-01T00:00:00Z",
        "voided": false,
        "barcode": [
            "format": "PKBarcodeFormatQR",
            "message": "HELLO",
            "messageEncoding": "iso-8859-1",
        ],
        "barcodes": [
            [
                "format": "PKBarcodeFormatQR",
                "message": "HELLO",
                "messageEncoding": "iso-8859-1",
            ]
        ],
        "locations": [
            ["latitude": 37.33, "longitude": -122.03, "relevantText": "Gate A"]
        ],
        "userInfo": ["k": "v"],
        "generic": [
            "primaryFields": [
                ["key": "balance", "label": "Balance", "value": "12.50"]
            ],
            "secondaryFields": [
                ["key": "sec", "label": "S", "value": "two"]
            ],
            "auxiliaryFields": [
                ["key": "aux", "label": "A", "value": "aux-v"]
            ],
            "backFields": [
                ["key": "terms", "label": "Terms", "value": "back"]
            ],
        ],
    ]
    for (key, value) in extra {
        root[key] = value
    }
    return root
}

func passKitJSONData(_ object: [String: Any]) -> Data {
    do {
        return try JSONSerialization.data(withJSONObject: object)
    } catch {
        preconditionFailure("fixture JSON must serialize: \(error)")
    }
}

func waitFor(_ work: @escaping (@escaping () -> Void) -> Void) {
    let lock = NSCondition()
    var done = false
    work {
        lock.lock()
        done = true
        lock.broadcast()
        lock.unlock()
    }
    lock.lock()
    let deadline = Date().addingTimeInterval(5)
    while !done {
        if !lock.wait(until: deadline) {
            lock.unlock()
            preconditionFailure("async PassKit call timed out")
        }
    }
    lock.unlock()
}

// MARK: - PKPass archive

func testPassJSONArchive() {
    let json = passKitJSONData(passKitPassJSONObject())
    let zip = passKitStoredZip(["pass.json": json, "icon.png": Data([0x89, 0x50])])
    let pass: PKPass
    do {
        pass = try PKPass(data: zip)
    } catch {
        preconditionFailure("stored ZIP fixture must parse: \(error)")
    }
    precondition(pass.serialNumber == "SN-1")
    precondition(pass.passTypeIdentifier == "pass.openuikit.example")
    precondition(pass.organizationName == "OpenUIKit")
    precondition(pass.localizedDescription == "Event ticket")
    precondition(pass.localizedName == "Logo")
    precondition(pass.authenticationToken == "tok-1")
    precondition(pass.webServiceURL?.absoluteString == "https://example.com/passes")
    precondition(pass.passURL == nil)
    precondition(pass.isRemotePass == false)
    precondition(pass.deviceName.isEmpty)
    precondition(pass.passType == .barcode)
    precondition(pass.paymentPass == nil)
    precondition(pass.secureElementPass == nil)
    precondition(pass.relevantDate != nil)
    precondition(pass.relevantDates.count == 1)
    precondition(pass.relevantDates[0].date != nil)
    let userInfo = pass.userInfo
    precondition((userInfo?["k"] as? String) == "v")
    precondition((pass.localizedValue(forFieldKey: "balance") as? String) == "12.50")
    precondition((pass.localizedValue(forFieldKey: "sec") as? String) == "two")
    precondition((pass.localizedValue(forFieldKey: "aux") as? String) == "aux-v")
    precondition((pass.localizedValue(forFieldKey: "terms") as? String) == "back")
    precondition((pass.localizedValue(forFieldKey: "barcode") as? String) == "HELLO")
    precondition((pass.localizedValue(forFieldKey: "barcodes") as? String) == "HELLO")
    precondition((pass.localizedValue(forFieldKey: "locationRelevantText") as? String) == "Gate A")
    if let flag = pass.localizedValue(forFieldKey: "voided") as? Bool {
        precondition(flag == false)
    } else if let number = pass.localizedValue(forFieldKey: "voided") as? NSNumber {
        precondition(number.boolValue == false)
    } else {
        preconditionFailure("voided must round-trip")
    }
    precondition(pass.localizedValue(forFieldKey: "missing") == nil)
    _ = pass.icon
}

func testPassJSONArchiveRejects() {
    func expectCode(_ data: Data, _ code: PKPassKitError.Code) {
        do {
            _ = try PKPass(data: data)
            preconditionFailure("expected PKPassKitError.\(code)")
        } catch let error as PKPassKitError {
            precondition(error.code == code)
        } catch {
            preconditionFailure("unexpected error \(error)")
        }
    }
    expectCode(Data(), .invalidDataError)
    expectCode(Data("not-a-pass".utf8), .invalidDataError)
    expectCode(passKitStoredZip(["manifest.json": Data("{}".utf8)]), .invalidDataError)

    var missingSerial = passKitPassJSONObject()
    missingSerial["serialNumber"] = ""
    expectCode(passKitStoredZip(["pass.json": passKitJSONData(missingSerial)]), .invalidDataError)

    var version = passKitPassJSONObject()
    version["formatVersion"] = 99
    expectCode(passKitStoredZip(["pass.json": passKitJSONData(version)]), .unsupportedVersionError)

    var boarding = passKitPassJSONObject()
    boarding["generic"] = nil
    boarding["boardingPass"] = [
        "transitType": "PKTransitTypeAir",
        "primaryFields": [
            ["key": "origin", "label": "From", "value": "SFO"]
        ],
    ]
    do {
        let pass = try PKPass(data: passKitStoredZip(["pass.json": passKitJSONData(boarding)]))
        precondition((pass.localizedValue(forFieldKey: "origin") as? String) == "SFO")
        precondition((pass.localizedValue(forFieldKey: "transitType") as? String) == "PKTransitTypeAir")
    } catch {
        preconditionFailure("boardingPass fixture must parse: \(error)")
    }
}

func testAddPaymentPassValueStores() {
    let config = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2)
    precondition(config != nil)
    config?.cardholderName = "Jane"
    config?.localizedDescription = "Card"
    config?.paymentNetwork = .visa
    config?.primaryAccountIdentifier = "pai"
    config?.primaryAccountSuffix = "1234"
    config?.productIdentifiers = ["p1"]
    config?.requiresFelicaSecureElement = false
    config?.style = .payment
    let labeled = PKLabeledValue(label: "PAN", value: "••••1234")
    config?.cardDetails = [labeled]
    precondition(config?.encryptionScheme == .ECC_V2)
    precondition(config?.cardholderName == "Jane")
    precondition(config?.cardDetails[0].label == "PAN")
    precondition(config?.cardDetails[0].value == "••••1234")
    precondition(PKEncryptionScheme.RSA_V2.rawValue == "RSA_V2")
    precondition(PKEncryptionScheme(rawValue: "ECC_V2") == .ECC_V2)

    let request = PKAddPaymentPassRequest()
    request.activationData = Data([1])
    request.encryptedPassData = Data([2])
    request.ephemeralPublicKey = Data([3])
    request.wrappedKey = Data([4])
    precondition(request.activationData?.count == 1)
    precondition(request.encryptedPassData?.count == 1)
    precondition(request.ephemeralPublicKey?.count == 1)
    precondition(request.wrappedKey?.count == 1)

    let car = PKAddCarKeyPassConfiguration()
    car.manufacturerIdentifier = "maker"
    car.password = "pw"
    car.provisioningTemplateIdentifier = "tpl"
    car.supportedRadioTechnologies = [.NFC]
    precondition(car.manufacturerIdentifier == "maker")
    precondition(car.supportedRadioTechnologies.contains(.NFC))

    MainActor.assumeIsolated {
        precondition(PKAddPaymentPassViewController.canAddPaymentPass() == false)
        let vc = PKAddPaymentPassViewController(requestConfiguration: config!, delegate: nil)
        precondition(vc == nil)
        precondition(PKAddSecureElementPassViewController.canAddSecureElementPass(configuration: car) == false)
        let se = PKAddSecureElementPassViewController(configuration: car, delegate: nil)
        precondition(se == nil)
    }
}

func testContactShippingPaymentMethod() {
    let contact = PKContact()
    contact.emailAddress = "a@example.com"
    contact.phoneNumber = CNPhoneNumber(stringValue: "+1")
    var name = PersonNameComponents()
    name.givenName = "Ada"
    contact.name = name
    let postal = CNPostalAddress()
    postal.city = "Cupertino"
    contact.postalAddress = postal
    contact.supplementarySubLocality = "sub"
    precondition(contact.emailAddress == "a@example.com")
    precondition(contact.phoneNumber?.stringValue == "+1")
    precondition(contact.name?.givenName == "Ada")
    precondition(contact.postalAddress?.city == "Cupertino")
    precondition(contact.supplementarySubLocality == "sub")
    precondition(PKContactField(rawValue: "name") == .name)
    precondition(PKContactField.phoneticName.rawValue == "phoneticName")

    let ship = PKShippingMethod(label: "Ground", amount: NSDecimalNumber(string: "4.00"))
    ship.identifier = "ground"
    ship.detail = "5 days"
    var start = DateComponents()
    start.day = 1
    var end = DateComponents()
    end.day = 3
    ship.dateComponentsRange = PKDateComponentsRange(start: start, end: end)
    precondition(ship.identifier == "ground")
    precondition(ship.detail == "5 days")
    precondition(ship.dateComponentsRange?.startDateComponents.day == 1)
    precondition(ship.amount.compare(NSDecimalNumber(string: "4.00")) == .orderedSame)
    precondition(PKShippingType(rawValue: 2) == .storePickup)

    let method = PKPaymentMethod()
    method.displayName = "Visa 1234"
    method.network = .visa
    method.type = .credit
    method.billingAddress = CNContact()
    precondition(method.displayName == "Visa 1234")
    precondition(method.network == .visa)
    precondition(method.type == .credit)
    precondition(PKPaymentMethodType(rawValue: 2) == .credit)
    _ = method.paymentPass
    _ = method.secureElementPass
}

func testSecureElementPassFailClosed() {
    let se = PKSecureElementPass()
    precondition(se.deviceAccountIdentifier.isEmpty)
    precondition(se.deviceAccountNumberSuffix.isEmpty)
    precondition(se.devicePassIdentifier == nil)
    precondition(se.pairedTerminalIdentifier == nil)
    precondition(se.passActivationState == .deactivated)
    precondition(se.primaryAccountIdentifier.isEmpty)
    precondition(se.primaryAccountNumberSuffix.isEmpty)
    precondition(PKSecureElementPass.PassActivationState(rawValue: 0) == .activated)
    precondition(se.secureElementPass === se)
    precondition(se.paymentPass == nil)

    let payment = PKPaymentPass()
    precondition(payment.activationState == .deactivated)
    precondition(PKPaymentPassActivationState(rawValue: 3) == .suspended)
    precondition(payment.paymentPass === payment)
    precondition(payment.secureElementPass === payment)

    let props = PKStoredValuePassProperties(for: PKPass())
    precondition(props.isBlocked == false)
    precondition(props.balances.isEmpty)
    _ = PKStoredValuePassProperties(forPass: PKPass())
    let transit = PKTransitPassProperties()
    _ = transit.isBlacklisted
    let suica = PKSuicaPassProperties(for: PKPass())
    precondition(suica.isBalanceAllowedForCommute == false)
    precondition(suica.isGreenCarTicketUsed == false)
    precondition(suica.isInShinkansenStation == false)
    precondition(suica.isLowBalanceGateNotificationEnabled == false)

    let balance = PKStoredValuePassBalance()
    balance.amount = 3
    balance.balanceType = .loyaltyPoints
    balance.currencyCode = "USD"
    precondition(balance.amount == 3)
    precondition(PKStoredValuePassBalance.BalanceType(rawValue: "cash") == .cash)
}

func testAddPassesViewControllerFailClosed() {
    MainActor.assumeIsolated {
        precondition(PKAddPassesViewController.canAddPasses() == false)
        let empty = PKPass()
        precondition(PKAddPassesViewController(pass: empty) == nil)
        precondition(PKAddPassesViewController(passes: [empty]) == nil)
        do {
            _ = try PKAddPassesViewController(issuerData: Data(), signature: Data())
            preconditionFailure("issuer provisioning must throw")
        } catch let error as PKPassKitError {
            precondition(error.code == .notEntitledError)
        } catch {
            preconditionFailure("unexpected error \(error)")
        }
        let shell = PKAddPassesViewController()
        let probe = AddPassesFinishProbe()
        shell.delegate = probe
        precondition(shell.delegate === probe)
        probe.addPassesViewControllerDidFinish(shell)
        precondition(probe.finished)
        // Seed has no UIKit: there is no presentation path that would call
        // the delegate. Listed in oracle-questions.tsv / README.
    }
}

@MainActor
private final class AddPassesFinishProbe: PKAddPassesViewControllerDelegate {
    var finished = false
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        finished = true
        _ = controller
    }
}

func testPaymentAuthorizationFailClosed() {
    precondition(PKPaymentAuthorizationStatus.success.rawValue == 0)
    precondition(PKPaymentAuthorizationStatus.failure.rawValue == 1)
    precondition(PKPaymentAuthorizationStatus.pinLockout.rawValue == 7)
    precondition(PKPaymentAuthorizationStatus(rawValue: 4) == .invalidShippingContact)
    let result = PKPaymentAuthorizationResult(status: .failure, errors: [PKPassKitError(.notEntitledError)])
    precondition(result.status == .failure)
    precondition(result.errors?.count == 1)
    result.orderDetails = PKPaymentOrderDetails(
        orderTypeIdentifier: "order.com.example",
        orderIdentifier: "oid",
        webServiceURL: URL(string: "https://example.com/o")!,
        authenticationToken: "t"
    )
    precondition(result.orderDetails?.orderIdentifier == "oid")

    let request = PKPaymentRequest()
    request.merchantIdentifier = "merchant.example"
    request.countryCode = "US"
    request.currencyCode = "USD"
    request.supportedNetworks = [.visa]
    request.merchantCapabilities = [.threeDSecure]
    precondition(PKPaymentAuthorizationController.canMakePayments() == false)
    precondition(PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa]) == false)
    precondition(
        PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: [.visa],
            capabilities: [.threeDSecure]
        ) == false
    )
    precondition(PKPaymentAuthorizationController.supportsDisbursements() == false)
    precondition(PKPaymentAuthorizationController.supportsDisbursements(using: [.visa]) == false)
    precondition(
        PKPaymentAuthorizationController.supportsDisbursements(
            using: [.visa],
            capabilities: [.threeDSecure]
        ) == false
    )
    let controller = PKPaymentAuthorizationController(paymentRequest: request)
    precondition(controller.paymentRequest === request)
    var presented = true
    controller.present { presented = $0 }
    precondition(presented == false)
    var dismissed = false
    controller.dismiss { dismissed = true }
    precondition(dismissed)
    let disbursed = PKPaymentAuthorizationController(disbursementRequest: PKDisbursementRequest())
    _ = disbursed

    MainActor.assumeIsolated {
        precondition(PKPaymentAuthorizationViewController.canMakePayments() == false)
        precondition(
            PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa]) == false
        )
        precondition(
            PKPaymentAuthorizationViewController.canMakePayments(
                usingNetworks: [.visa],
                capabilities: [.credit]
            ) == false
        )
        precondition(PKPaymentAuthorizationViewController.supportsDisbursements() == false)
        precondition(PKPaymentAuthorizationViewController.supportsDisbursements(using: [.visa]) == false)
        precondition(
            PKPaymentAuthorizationViewController.supportsDisbursements(
                using: [.visa],
                capabilities: [.debit]
            ) == false
        )
        precondition(PKPaymentAuthorizationViewController(paymentRequest: request) == nil)
        let vc = PKPaymentAuthorizationViewController()
        let viewProbe = PaymentAuthViewProbe()
        vc.delegate = viewProbe
        _ = vc.delegate
        _ = viewProbe
        _ = PKPaymentAuthorizationViewController(disbursementRequest: PKDisbursementRequest())
    }

    let token = PKPaymentToken(paymentData: Data([9]), transactionIdentifier: "txn")
    precondition(token.transactionIdentifier == "txn")
    precondition(token.paymentData.count == 1)
    token.paymentInstrumentName = "Visa"
    token.paymentNetwork = PKPaymentNetwork.visa.rawValue
    token.paymentMethod.displayName = "Visa"
    let payment = PKPayment(token: token)
    payment.billingContact = PKContact()
    payment.shippingContact = PKContact()
    payment.billingAddress = ABRecord()
    payment.shippingAddress = ABRecord()
    payment.shippingMethod = PKShippingMethod()
    precondition(payment.token.transactionIdentifier == "txn")
}

@MainActor
private final class PaymentAuthViewProbe: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewControllerDidFinish(
        _ controller: PKPaymentAuthorizationViewController
    ) {
        _ = controller
    }
}

func testJPKIFailClosed() {
    precondition(JPKIPassContents.Error.unknownError.localizedDescription == "JPKIPassContents.Error")
    let pin = JPKIPassContents.UserIdentity.AuthenticationType.pin("0000")
    _ = JPKIPassContents.UserIdentity.AuthenticationType.systemBiometric
    let userRequest = JPKIPassContents.AuthenticationRequest<JPKIPassContents.UserIdentity>(type: pin)
    let user = JPKIPassContents.UserIdentity()
    waitFor { done in
        Task {
            do {
                _ = try await user.certificate(using: userRequest)
                preconditionFailure("JPKI certificate must fail closed")
            } catch JPKIPassContents.Error.resourceNotAvailable {
            } catch {
                preconditionFailure("unexpected JPKI error \(error)")
            }
            done()
        }
    }
    let signing = JPKIPassContents.SigningIdentity()
    let pw = JPKIPassContents.SigningIdentity.AuthenticationType.password("pw")
    let signingRequest = JPKIPassContents.AuthenticationRequest<JPKIPassContents.SigningIdentity>(type: pw)
    waitFor { done in
        Task {
            do {
                _ = try await signing.certificate(using: signingRequest)
                preconditionFailure("JPKI signing cert must fail closed")
            } catch JPKIPassContents.Error.resourceNotAvailable {
            } catch {
                preconditionFailure("unexpected JPKI error \(error)")
            }
            done()
        }
    }
    waitFor { done in
        Task {
            do {
                _ = try await JPKIPassContents(PKPass())
                preconditionFailure("JPKIPassContents init must fail closed")
            } catch JPKIPassContents.Error.resourceNotAvailable {
            } catch {
                preconditionFailure("unexpected JPKI error \(error)")
            }
            done()
        }
    }
}
