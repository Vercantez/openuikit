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

func testPaymentRequestModel() {
    let item = PKPaymentSummaryItem(
        label: "Item",
        amount: NSDecimalNumber(string: "10.00"),
        type: .final
    )
    let tax = PKPaymentSummaryItem(label: "Tax", amount: NSDecimalNumber(string: "2.50"))
    precondition(item.label == "Item")
    precondition(item.type == .final)
    precondition(tax.type == .final)
    let total = item.amount.adding(tax.amount)
    precondition(total.compare(NSDecimalNumber(string: "12.50")) == .orderedSame)
    let pending = PKPaymentSummaryItem(
        label: "Pending",
        amount: NSDecimalNumber.zero,
        type: .pending
    )
    precondition(pending.type == .pending)
    precondition(PKPaymentSummaryItemType(rawValue: 1) == .pending)

    let request = PKPaymentRequest()
    request.merchantIdentifier = "merchant.example"
    request.countryCode = "US"
    request.currencyCode = "USD"
    request.supportedNetworks = [.visa, .masterCard, .amex]
    request.merchantCapabilities = [.threeDSecure, .credit]
    request.paymentSummaryItems = [item, tax]
    request.requiredBillingContactFields = [.postalAddress, .name]
    request.requiredShippingContactFields = [.phoneNumber, .emailAddress]
    request.requiredBillingAddressFields = [.postalAddress]
    request.requiredShippingAddressFields = [.name]
    request.applicationData = Data("app".utf8)
    request.attributionIdentifier = "attr"
    request.couponCode = "SAVE"
    request.supportsCouponCode = true
    request.shippingType = .delivery
    request.shippingContactEditingMode = .enabled
    request.supportedCountries = ["US"]
    request.merchantCategoryCode = PKPaymentRequest.MerchantCategoryCode(rawValue: 5411)
    request.applePayLaterAvailability = .available
    precondition(request.merchantIdentifier == "merchant.example")
    precondition(request.countryCode == "US")
    precondition(request.currencyCode == "USD")
    precondition(request.supportedNetworks.count == 3)
    precondition(request.paymentSummaryItems.count == 2)
    precondition(request.supportsCouponCode)
    precondition(request.shippingType == .delivery)
    precondition(request.merchantCategoryCode?.rawValue == 5411)
    precondition(request.merchantCategoryCode?.description == "5411")
    if case .available = request.applePayLaterAvailability {
    } else {
        preconditionFailure("applePayLaterAvailability")
    }
    request.applePayLaterAvailability = .unavailable(.itemIneligible)
    request.applePayLaterAvailability = .unavailable(.recurringTransaction)
    precondition(PKPaymentRequest.MerchantCategoryCode("12")?.rawValue == 12)
    precondition(PKPaymentRequest.availableNetworks().isEmpty)

    let billing = PKPaymentRequest.paymentBillingAddressInvalidError(
        withKey: "postalCode",
        localizedDescription: "bad zip"
    )
    precondition((billing as? PKPaymentError)?.code == .billingContactInvalidError)
    let contactErr = PKPaymentRequest.paymentContactInvalidError(
        withContactField: .emailAddress,
        localizedDescription: nil
    )
    precondition((contactErr as? PKPaymentError)?.code == .shippingContactInvalidError)
    let ship = PKPaymentRequest.paymentShippingAddressInvalidError(
        withKey: "street",
        localizedDescription: nil
    )
    precondition((ship as? PKPaymentError)?.code == .shippingContactInvalidError)
    let unserviceable = PKPaymentRequest.paymentShippingAddressUnserviceableError(
        withLocalizedDescription: "no"
    )
    precondition((unserviceable as? PKPaymentError)?.code == .shippingAddressUnserviceableError)
    let coupon = PKPaymentRequest.paymentCouponCodeInvalidError(localizedDescription: "bad")
    precondition((coupon as? PKPaymentError)?.code == .couponCodeInvalidError)
    let expired = PKPaymentRequest.paymentCouponCodeExpiredError(localizedDescription: "old")
    precondition((expired as? PKPaymentError)?.code == .couponCodeExpiredError)

    let reloadItem = PKAutomaticReloadPaymentSummaryItem(label: "Reload", amount: NSDecimalNumber(value: 5))
    reloadItem.thresholdAmount = NSDecimalNumber(string: "10")
    precondition(reloadItem.thresholdAmount.compare(NSDecimalNumber(string: "10")) == .orderedSame)
    let reload = PKAutomaticReloadPaymentRequest(
        paymentDescription: "Reload",
        automaticReloadBilling: reloadItem,
        managementURL: URL(string: "https://example.com/manage")!
    )
    reload.billingAgreement = "agree"
    reload.tokenNotificationURL = URL(string: "https://example.com/token")
    request.automaticReloadPaymentRequest = reload
    precondition(request.automaticReloadPaymentRequest?.paymentDescription == "Reload")
    precondition(request.automaticReloadPaymentRequest?.managementURL.absoluteString == "https://example.com/manage")

    let deferredItem = PKDeferredPaymentSummaryItem(label: "Later", amount: NSDecimalNumber(value: 9))
    deferredItem.deferredDate = Date.distantFuture
    let deferred = PKDeferredPaymentRequest(
        paymentDescription: "Defer",
        deferredBilling: deferredItem,
        managementURL: URL(string: "https://example.com/d")!
    )
    request.deferredPaymentRequest = deferred
    precondition(request.deferredPaymentRequest?.paymentDescription == "Defer")

    let recurringItem = PKRecurringPaymentSummaryItem(label: "Sub", amount: Decimal(5))
    recurringItem.intervalUnit = .month
    recurringItem.intervalCount = 1
    let recurring = PKRecurringPaymentRequest(
        paymentDescription: "Sub",
        regularBilling: recurringItem,
        managementURL: URL(string: "https://example.com/r")!
    )
    request.recurringPaymentRequest = recurring
    precondition(request.recurringPaymentRequest?.regularBilling.label == "Sub")

    let tokenContext = PKPaymentTokenContext(
        merchantIdentifier: "m",
        externalIdentifier: "e",
        merchantName: "Shop",
        merchantDomain: "example.com",
        amount: NSDecimalNumber(string: "1")
    )
    request.multiTokenContexts = [tokenContext]
    precondition(request.multiTokenContexts[0].merchantName == "Shop")
    precondition(request.multiTokenContexts[0].merchantDomain == "example.com")

    let update = PKPaymentRequestUpdate(paymentSummaryItems: [item])
    precondition(update.paymentSummaryItems.count == 1)
    update.status = .success
    let couponUpdate = PKPaymentRequestCouponCodeUpdate(
        errors: nil,
        paymentSummaryItems: [item],
        shippingMethods: []
    )
    precondition(couponUpdate.paymentSummaryItems.count == 1)
    let methodUpdate = PKPaymentRequestPaymentMethodUpdate(errors: nil, paymentSummaryItems: [item])
    precondition(methodUpdate.paymentSummaryItems.count == 1)
    let contactUpdate = PKPaymentRequestShippingContactUpdate(
        errors: nil,
        paymentSummaryItems: [item],
        shippingMethods: []
    )
    precondition(contactUpdate.shippingMethods.isEmpty)
    let shipUpdate = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: [item])
    precondition(shipUpdate.paymentSummaryItems.count == 1)
    let session = PKPaymentMerchantSession(dictionary: ["k": "v"])
    let sessionUpdate = PKPaymentRequestMerchantSessionUpdate(status: .failure, merchantSession: session)
    precondition(sessionUpdate.status == .failure)
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

func testCorpusValueStores() {
    let range = PKDateComponentsRange(
        startDateComponents: DateComponents(day: 1),
        endDateComponents: DateComponents(day: 2)
    )
    precondition(range.endDateComponents.day == 2)
    _ = PKDateComponentsRange(coder: NSCoder())

    let preview = PKAddPassMetadataPreview(passThumbnail: CGImage(), localizedDescription: "p")
    _ = preview.passThumbnailImage
    _ = preview.localizedDescription

    let idMeta = PKAddIdentityDocumentMetadata(
        provisioningCredentialIdentifier: "c",
        sharingInstanceIdentifier: "s",
        cardTemplateIdentifier: "t",
        issuingCountryCode: "US",
        documentType: .idCard,
        preview: preview
    )
    _ = idMeta.preview
    precondition(PKAddIdentityDocumentType(rawValue: 2) == .photoID)

    let japan = PKJapanIndividualNumberCardMetadata(
        provisioningCredentialIdentifier: "c",
        sharingInstanceIdentifier: "s",
        cardConfigurationIdentifier: "cfg",
        preview: preview
    )
    _ = japan.preview
    _ = PKJapanIndividualNumberCardMetadata(
        provisioningCredentialIdentifier: "c",
        sharingInstanceIdentifier: "s",
        cardTemplateIdentifier: "t",
        preview: preview
    )

    let sharePreview = PKShareablePassMetadata.Preview(
        passThumbnail: CGImage(),
        localizedDescription: "share"
    )
    precondition(sharePreview.localizedDescription == "share")
    let meta = PKShareablePassMetadata(
        provisioningCredentialIdentifier: "c",
        sharingInstanceIdentifier: "s",
        cardTemplateIdentifier: "t",
        preview: sharePreview
    )
    _ = meta.preview
    _ = PKShareablePassMetadata(
        provisioningCredentialIdentifier: "c",
        cardConfigurationIdentifier: "cfg",
        sharingInstanceIdentifier: "s",
        passThumbnailImage: CGImage(),
        ownerDisplayName: "n",
        localizedDescription: "d"
    )
    _ = PKShareablePassMetadata(
        provisioningCredentialIdentifier: "c",
        sharingInstanceIdentifier: "s",
        cardConfigurationIdentifier: "cfg",
        preview: sharePreview
    )
    _ = PKShareablePassMetadata(
        provisioningCredentialIdentifier: "c",
        sharingInstanceIdentifier: "s",
        passThumbnailImage: CGImage(),
        ownerDisplayName: "n",
        localizedDescription: "d",
        accountHash: "h",
        templateIdentifier: "t",
        relyingPartyIdentifier: "r",
        requiresUnifiedAccessCapableDevice: false
    )

    let shareConfig = PKAddShareablePassConfiguration()
    precondition(shareConfig.primaryAction == .add)
    precondition(PKAddShareablePassConfigurationPrimaryAction(rawValue: 1) == .share)

    let barcodeCfg = PKBarcodeEventConfigurationRequest()
    _ = barcodeCfg.configurationData
    _ = barcodeCfg.configurationDataType
    _ = barcodeCfg.deviceAccountIdentifier
    let barcodeMeta = PKBarcodeEventMetadataRequest()
    _ = barcodeMeta.deviceAccountIdentifier
    _ = barcodeMeta.lastUsedBarcodeIdentifier
    let barcodeResp = PKBarcodeEventMetadataResponse(paymentInformation: Data([1]))
    precondition(barcodeResp.paymentInformation.count == 1)
    let sigReq = PKBarcodeEventSignatureRequest()
    _ = sigReq.barcodeIdentifier
    _ = sigReq.merchantName
    _ = sigReq.transactionIdentifier
    let sigResp = PKBarcodeEventSignatureResponse(signedData: Data([2]))
    precondition(sigResp.signedData.count == 1)
    precondition(PKBarcodeEventConfigurationDataType(rawValue: 0) == .unknown)

    let identity = PKIdentityRequest()
    identity.merchantIdentifier = "m"
    identity.nonce = Data()
    precondition(identity.merchantIdentifier == "m")
    _ = PKIdentityElement.givenName
    _ = PKIdentityElement.familyName
    _ = PKIdentityElement.age(atLeast: 21)
    _ = PKIdentityIntentToStore.willNotStore
    _ = PKIdentityIntentToStore.mayStore
    _ = PKIdentityIntentToStore.mayStore(days: 7)
    let anyDesc = PKIdentityAnyOfDescriptor(descriptors: [])
    precondition(anyDesc.descriptors.isEmpty)
    _ = PKIdentityDriversLicenseDescriptor()
    let national = PKIdentityNationalIDCardDescriptor()
    national.region = Locale.Region("US")
    _ = national.region
    _ = PKIdentityPhotoIDDescriptor()
    let idController = PKIdentityAuthorizationController()
    waitFor { done in
        Task {
            let allowed = await idController.canRequestDocument(anyDesc)
            precondition(allowed == false)
            done()
        }
    }
    idController.cancelRequest()
    waitFor { done in
        Task {
            do {
                _ = try await idController.requestDocument(identity)
                preconditionFailure("identity request must fail closed")
            } catch {
            }
            done()
        }
    }

    let status = PKIssuerProvisioningExtensionStatus()
    precondition(status.passEntriesAvailable == false)
    let handler = PKIssuerProvisioningExtensionHandler()
    handler.passEntries { entries in precondition(entries.isEmpty) }
    handler.remotePassEntries { entries in precondition(entries.isEmpty) }
    handler.status { value in precondition(value.requiresAuthentication == false) }
    waitFor { done in
        Task {
            let generated = await handler.generateAddPaymentPassRequestForPassEntryWithIdentifier(
                "id",
                configuration: PKAddPaymentPassRequestConfiguration(),
                certificateChain: [],
                nonce: Data(),
                nonceSignature: Data()
            )
            precondition(generated == nil)
            done()
        }
    }
    let entry = PKIssuerProvisioningExtensionPassEntry()
    _ = entry.identifier
    _ = PKIssuerProvisioningExtensionPaymentPassEntry(
        identifier: "i",
        title: "t",
        art: CGImage(),
        addRequestConfiguration: PKAddPaymentPassRequestConfiguration()
    )
    precondition(PKIssuerProvisioningExtensionAuthorizationResult(rawValue: 1) == .authorized)

    let disbursement = PKDisbursementRequest(
        merchantIdentifier: "m",
        currency: Locale.Currency("USD"),
        region: Locale.Region("US"),
        supportedNetworks: [.visa],
        merchantCapabilities: [.threeDSecure],
        summaryItems: []
    )
    precondition(disbursement.merchantIdentifier == "m")
    precondition(disbursement.supportedNetworks == [.visa])
    _ = PKDisbursementRequest.disbursementCardUnsupportedError()
    _ = PKDisbursementRequest.disbursementContactInvalidError(
        withContactField: .name,
        localizedDescription: nil
    )
    _ = PKDisbursementSummaryItem()
    precondition(PKDisbursementError.unsupportedCardError.rawValue == 1)
    precondition(PKDisbursementError.recipientContactInvalidError.rawValue == 2)
    precondition(PKDisbursementError.errorDomain == PKDisbursementErrorDomain)
    precondition(PKDisbursementError.Code(rawValue: -1) == .unknownError)
    precondition(PKDisbursementErrorKey.contactFieldUserInfoKey.rawValue.hasPrefix("PKDisbursement"))

    let laterViewAmount = Decimal(12)
    MainActor.assumeIsolated {
        let later = PKPayLaterView(amount: laterViewAmount, currency: Locale.Currency("USD"))
        later.action = .learnMore
        later.displayStyle = .badge
        precondition(later.amount == laterViewAmount)
        precondition(PKPayLaterAction(rawValue: 1) == .calculator)
        precondition(PKPayLaterDisplayStyle(rawValue: 3) == .price)
        let laterProbe = PayLaterProbe()
        later.delegate = laterProbe
        _ = later.delegate
        _ = laterProbe
        let add = PKAddPassButton(addPassButtonStyle: .blackOutline)
        add.addPassButtonStyle = .black
        _ = add.addPassButtonStyle
        let identityButton = PKIdentityButton(label: .verifyAge, style: .blackOutline)
        identityButton.cornerRadius = 2
        precondition(identityButton.cornerRadius == 2)
        _ = PKIdentityButton.Label(rawValue: 0)
        _ = PKIdentityButton.Style(rawValue: 1)
        let shareVC = PKShareSecureElementPassViewController(
            secureElementPass: PKSecureElementPass(),
            delegate: nil
        )
        shareVC.promptToShareURL = true
        _ = shareVC.promptToShareURL
    }

    waitFor { done in
        Task {
            let eligible = await PKPayLater.validate(amount: 10, currency: Locale.Currency("USD"))
            precondition(eligible == false)
            done()
        }
    }

    waitFor { done in
        Task {
            do {
                _ = try await PKAddShareablePassConfiguration.forPassMetadata(
                    [],
                    action: .add
                )
                preconditionFailure("shareable config must fail closed")
            } catch {
            }
            do {
                _ = try await PKAddShareablePassConfiguration.forPassMetaData(
                    [],
                    provisioningPolicyIdentifier: "p",
                    action: .add
                )
                preconditionFailure("shareable config must fail closed")
            } catch {
            }
            do {
                _ = try await PKAddIdentityDocumentConfiguration.forMetadata(PKIdentityDocumentMetadata())
                preconditionFailure("identity document config must fail closed")
            } catch {
            }
            do {
                _ = try await PKVehicleConnectionSession.session(
                    for: PKSecureElementPass(),
                    delegate: VehicleProbe()
                )
                preconditionFailure("vehicle session must fail closed")
            } catch {
            }
            done()
        }
    }

    let vehicle = PKVehicleConnectionSession()
    precondition(vehicle.connectionStatus == .disconnected)
    do {
        try vehicle.send(Data())
        preconditionFailure("vehicle send must throw")
    } catch {
    }
    vehicle.invalidate()
    precondition(PKVehicleConnectionErrorCode(rawValue: 1) == .sessionUnableToStart)
    precondition(PKVehicleConnectionSessionConnectionState(rawValue: 0) == .disconnected)

    let infoExt = PKPaymentInformationEventExtension()
    _ = infoExt
    let shareErr = PKShareSecureElementPassError(.setupError)
    precondition(shareErr.code == .setupError)
    precondition(PKShareSecureElementPassError.errorDomain == PKShareSecureElementPassErrorDomain)
    precondition(PKShareSecureElementPassResult(rawValue: 2) == .failed)
    precondition(PKPassLibraryAddPassesStatus(rawValue: 2) == .didCancelAddPasses)
    precondition(PKPassLibrary.AuthorizationStatus(rawValue: 0) == .denied)
    precondition(PKPassLibrary.Capability(rawValue: 0) == .backgroundAddPasses)
    precondition(PKPassType(rawValue: 0) == .barcode)
    precondition(PKAddressField(rawValue: 1).contains(.postalAddress))
    precondition(PKRadioTechnology(rawValue: 1).contains(.NFC))
    precondition(PKPaymentErrorKey(rawValue: "x").rawValue == "x")
    precondition(PKPassLibraryNotificationKey.serialNumberUserInfoKey.rawValue.hasPrefix("PKPassLibrary"))
    let note = PKPassLibraryNotificationName("custom")
    precondition(note.rawValue == "custom")
    _ = PKPassLibraryNotificationName.PKPassLibraryDidChange
    _ = PKAddPaymentPassError(rawValue: 0)
    precondition(PKAddPaymentPassStyle(rawValue: 1) == .access)
    precondition(PKApplePayLaterAvailability(rawValue: 0) == .available)
    precondition(PKAutomaticPassPresentationSuppressionResult(rawValue: 0) == .notSupported)
    precondition(PKPaymentButtonType(rawValue: 1) == .buy)
    precondition(PKPaymentButtonStyle(rawValue: 3) == .automatic)
    precondition(PKAddPassButtonStyle(rawValue: 0) == .black)
    precondition(PKMerchantCapability(rawValue: 1).contains(.threeDSecure))
    precondition(PKInstantFundsOutFeeSummaryItem().type == .final)

    waitFor { done in
        let library = PKPassLibrary()
        Task {
            let addStatus = await library.addPasses([])
            precondition(addStatus == .didCancelAddPasses)
            let auth = await library.requestAuthorization(for: .backgroundAddPasses)
            precondition(auth == .denied)
            do {
                _ = try await library.activate(PKSecureElementPass(), activationData: Data())
                preconditionFailure("activate must throw")
            } catch let error as PKPassKitError {
                precondition(error.code == .notEntitledError)
            } catch {
                preconditionFailure("unexpected \(error)")
            }
            do {
                _ = try await library.encryptedServiceProviderData(for: PKSecureElementPass())
                preconditionFailure("encrypted SPD must throw")
            } catch let error as PKPassKitError {
                precondition(error.code == .notEntitledError)
            } catch {
                preconditionFailure("unexpected \(error)")
            }
            do {
                _ = try await library.serviceProviderData(for: PKSecureElementPass())
                preconditionFailure("SPD must throw")
            } catch let error as PKPassKitError {
                precondition(error.code == .notEntitledError)
            } catch {
                preconditionFailure("unexpected \(error)")
            }
            do {
                _ = try await library.sign(Data(), using: PKSecureElementPass())
                preconditionFailure("sign must throw")
            } catch let error as PKPassKitError {
                precondition(error.code == .notEntitledError)
            } catch {
                preconditionFailure("unexpected \(error)")
            }
            done()
        }
    }
}

private final class PayLaterProbe: PKPayLaterViewDelegate {
    func payLaterViewDidUpdateHeight(_ view: PKPayLaterView) {
        _ = view
    }
}

private final class VehicleProbe: PKVehicleConnectionDelegate {
    func sessionDidChange(_ newState: PKVehicleConnectionSessionConnectionState) {
        _ = newState
    }
    func sessionDidReceive(_ data: Data) {
        _ = data
    }
}
