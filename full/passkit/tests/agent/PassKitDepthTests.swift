import Foundation
import PassKit

// MARK: - SHA-1 (RFC 3174) for manifest.json fixtures

private enum PassKitFixtureSHA1 {
    static func hexDigest(_ data: Data) -> String {
        digest(data).map { String(format: "%02x", $0) }.joined()
    }

    static func digest(_ data: Data) -> [UInt8] {
        var h0: UInt32 = 0x6745_2301
        var h1: UInt32 = 0xEFCD_AB89
        var h2: UInt32 = 0x98BA_DCFE
        var h3: UInt32 = 0x1032_5476
        var h4: UInt32 = 0xC3D2_E1F0
        var message = [UInt8](data)
        let bitCount = UInt64(message.count) * 8
        message.append(0x80)
        while (message.count % 64) != 56 {
            message.append(0)
        }
        for i in (0..<8).reversed() {
            message.append(UInt8((bitCount >> (UInt64(i) * 8)) & 0xFF))
        }
        var chunkStart = 0
        while chunkStart < message.count {
            var w = [UInt32](repeating: 0, count: 80)
            for i in 0..<16 {
                let o = chunkStart + i * 4
                w[i] = (UInt32(message[o]) << 24)
                    | (UInt32(message[o + 1]) << 16)
                    | (UInt32(message[o + 2]) << 8)
                    | UInt32(message[o + 3])
            }
            for i in 16..<80 {
                let mixed = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16]
                w[i] = (mixed << 1) | (mixed >> 31)
            }
            var a = h0
            var b = h1
            var c = h2
            var d = h3
            var e = h4
            for i in 0..<80 {
                let f: UInt32
                let k: UInt32
                switch i {
                case 0..<20:
                    f = (b & c) | ((~b) & d)
                    k = 0x5A82_7999
                case 20..<40:
                    f = b ^ c ^ d
                    k = 0x6ED9_EBA1
                case 40..<60:
                    f = (b & c) | (b & d) | (c & d)
                    k = 0x8F1B_BCDC
                default:
                    f = b ^ c ^ d
                    k = 0xCA62_C1D6
                }
                let temp = (((a << 5) | (a >> 27)) &+ f &+ e &+ k &+ w[i])
                e = d
                d = c
                c = (b << 30) | (b >> 2)
                b = a
                a = temp
            }
            h0 = h0 &+ a
            h1 = h1 &+ b
            h2 = h2 &+ c
            h3 = h3 &+ d
            h4 = h4 &+ e
            chunkStart += 64
        }
        func bytes(_ value: UInt32) -> [UInt8] {
            [
                UInt8((value >> 24) & 0xFF),
                UInt8((value >> 16) & 0xFF),
                UInt8((value >> 8) & 0xFF),
                UInt8(value & 0xFF),
            ]
        }
        return bytes(h0) + bytes(h1) + bytes(h2) + bytes(h3) + bytes(h4)
    }
}

private func signedPkpassFiles(includeSignature: Bool, corruptManifest: Bool = false) -> [String: Data] {
    let json = passKitJSONData(passKitPassJSONObject())
    let icon = Data([0x89, 0x50, 0x4E, 0x47])
    var manifest: [String: String] = [
        "pass.json": PassKitFixtureSHA1.hexDigest(json),
        "icon.png": PassKitFixtureSHA1.hexDigest(icon),
    ]
    if corruptManifest {
        manifest["pass.json"] = String(repeating: "0", count: 40)
    }
    let manifestData = passKitJSONData(manifest)
    var files: [String: Data] = [
        "pass.json": json,
        "icon.png": icon,
        "manifest.json": manifestData,
    ]
    if includeSignature {
        // Minimal BER SEQUENCE so the payload is recognizably PKCS#7-shaped.
        files["signature"] = Data([0x30, 0x03, 0x02, 0x01, 0x00])
    }
    return files
}

func testPassManifestSHA1AcceptsMatchingHashes() {
    let abc = PassKitFixtureSHA1.hexDigest(Data("abc".utf8))
    precondition(abc == "a9993e364706816aba3e25717850c26c9cd0d89d")
    let zip = passKitStoredZip(signedPkpassFiles(includeSignature: false))
    let pass: PKPass
    do {
        pass = try PKPass(data: zip)
    } catch {
        preconditionFailure("matching SHA-1 manifest must parse: \(error)")
    }
    precondition(pass.passTypeIdentifier == "pass.openuikit.example")
    precondition(pass.serialNumber == "SN-1")
    precondition(pass.organizationName == "OpenUIKit")
    precondition(pass.localizedName == "Logo")
    precondition(pass.authenticationToken == "tok-1")
    precondition(pass.webServiceURL?.absoluteString == "https://example.com/passes")
    precondition(pass.relevantDate != nil)
    precondition(pass.passURL == nil)
}

func testPassManifestSHA1RejectsMismatch() {
    let zip = passKitStoredZip(signedPkpassFiles(includeSignature: false, corruptManifest: true))
    do {
        _ = try PKPass(data: zip)
        preconditionFailure("mismatched SHA-1 must throw")
    } catch let error as PKPassKitError {
        precondition(error.code == .invalidDataError)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
}

func testPassPKCS7SignatureFailClosed() {
    let zip = passKitStoredZip(signedPkpassFiles(includeSignature: true))
    do {
        _ = try PKPass(data: zip)
        preconditionFailure("PKCS#7 signature must fail closed")
    } catch let error as PKPassKitError {
        precondition(error.code == .invalidSignature)
        precondition(error.errorCode == PKPassKitError.invalidSignature.rawValue)
    } catch {
        preconditionFailure("unexpected \(error)")
    }
}

func testPassLibraryHostStoreAddRemoveContains() {
    let library = PKPassLibrary()
    let zip = passKitStoredZip(["pass.json": passKitJSONData(passKitPassJSONObject())])
    let pass: PKPass
    do {
        pass = try PKPass(data: zip)
    } catch {
        preconditionFailure("fixture pass: \(error)")
    }
    library.removePass(pass)
    precondition(library.containsPass(pass) == false)
    var status = PKPassLibraryAddPassesStatus.didCancelAddPasses
    library.addPasses([pass], withCompletionHandler: { status = $0 })
    precondition(status == .didAddPasses)
    precondition(library.containsPass(pass))
    precondition(
        library.pass(
            withPassTypeIdentifier: pass.passTypeIdentifier,
            serialNumber: pass.serialNumber
        )?.serialNumber == pass.serialNumber
    )
    precondition(library.replacePass(with: pass))
    library.removePass(pass)
    precondition(library.containsPass(pass) == false)
    precondition(library.replacePass(with: pass) == false)
}

func testPassLibraryHostStorePassesOfType() {
    let library = PKPassLibrary()
    var extra = passKitPassJSONObject()
    extra["serialNumber"] = "SN-HOST-2"
    let zip = passKitStoredZip(["pass.json": passKitJSONData(extra)])
    let pass: PKPass
    do {
        pass = try PKPass(data: zip)
    } catch {
        preconditionFailure("fixture pass: \(error)")
    }
    library.removePass(pass)
    library.addPasses([pass], withCompletionHandler: { _ in })
    let barcode = library.passes(of: .barcode)
    precondition(barcode.contains { $0.serialNumber == "SN-HOST-2" })
    let any = library.passes(of: .any)
    precondition(any.contains { $0.serialNumber == "SN-HOST-2" })
    let secure = library.passes(of: .secureElement)
    precondition(!secure.contains { $0.serialNumber == "SN-HOST-2" })
    library.removePass(pass)
    precondition(library.passes(of: .barcode).allSatisfy { $0.serialNumber != "SN-HOST-2" })
}

private func validPaymentRequest() -> PKPaymentRequest {
    let request = PKPaymentRequest()
    request.merchantIdentifier = "merchant.example"
    request.countryCode = "US"
    request.currencyCode = "USD"
    request.supportedNetworks = [.visa]
    request.merchantCapabilities = [.threeDSecure]
    request.paymentSummaryItems = [
        PKPaymentSummaryItem(label: "Item", amount: NSDecimalNumber(string: "4.00")),
        PKPaymentSummaryItem(label: "OpenUIKit", amount: NSDecimalNumber(string: "4.00"), type: .final),
    ]
    return request
}

func testPaymentRequestValidationRequiredFields() {
    let empty = PKPaymentRequest()
    let issues = PassKitPaymentRequestValidation.issues(for: empty)
    precondition(issues.contains(.missingMerchantIdentifier))
    precondition(issues.contains(.missingSupportedNetworks))
    precondition(issues.contains(.missingMerchantCapabilities))
    precondition(issues.contains(.invalidCountryCode))
    precondition(issues.contains(.invalidCurrencyCode))
    precondition(issues.contains(.missingPaymentSummaryItems))
    precondition(PassKitPaymentRequestValidation.issues(for: validPaymentRequest()).isEmpty)
}

func testPaymentRequestValidationISOCodes() {
    let request = validPaymentRequest()
    request.countryCode = "USA"
    request.currencyCode = "US"
    let issues = PassKitPaymentRequestValidation.issues(for: request)
    precondition(issues.contains(.invalidCountryCode))
    precondition(issues.contains(.invalidCurrencyCode))
    request.countryCode = "gb"
    request.currencyCode = "gbp"
    precondition(!PassKitPaymentRequestValidation.issues(for: request).contains(.invalidCountryCode))
    precondition(!PassKitPaymentRequestValidation.issues(for: request).contains(.invalidCurrencyCode))
}

func testPaymentRequestValidationSummaryItems() {
    let request = validPaymentRequest()
    request.paymentSummaryItems = [
        PKPaymentSummaryItem(label: "", amount: NSDecimalNumber(string: "1")),
    ]
    precondition(
        PassKitPaymentRequestValidation.issues(for: request).contains(.emptyPaymentSummaryItemLabel)
    )
    request.paymentSummaryItems = [
        PKPaymentSummaryItem(label: "Pending total", amount: NSDecimalNumber(string: "3"), type: .pending),
    ]
    precondition(
        PassKitPaymentRequestValidation.issues(for: request).contains(.pendingTotalMustBeZero)
    )
    request.paymentSummaryItems = [
        PKPaymentSummaryItem(label: "Pending total", amount: NSDecimalNumber.zero, type: .pending),
    ]
    precondition(
        !PassKitPaymentRequestValidation.issues(for: request).contains(.pendingTotalMustBeZero)
    )
}

func testPaymentRequestValidationRecurringReloadDeferred() {
    let request = validPaymentRequest()
    let recurringItem = PKRecurringPaymentSummaryItem(label: "Sub", amount: Decimal(5))
    recurringItem.intervalUnit = .month
    recurringItem.intervalCount = 0
    request.recurringPaymentRequest = PKRecurringPaymentRequest(
        paymentDescription: "",
        regularBilling: recurringItem,
        managementURL: URL(fileURLWithPath: "/")
    )
    var issues = PassKitPaymentRequestValidation.issues(for: request)
    precondition(issues.contains(.recurringMissingPaymentDescription))
    precondition(issues.contains(.recurringMissingIntervalCount))
    precondition(issues.contains(.recurringMissingManagementURL))
    recurringItem.intervalCount = 1
    request.recurringPaymentRequest = PKRecurringPaymentRequest(
        paymentDescription: "Sub",
        regularBilling: recurringItem,
        managementURL: URL(string: "https://example.com/manage")!
    )
    precondition(!PassKitPaymentRequestValidation.issues(for: request).contains(.recurringMissingManagementURL))

    let reloadItem = PKAutomaticReloadPaymentSummaryItem(label: "Reload", amount: NSDecimalNumber(value: 5))
    reloadItem.thresholdAmount = NSDecimalNumber(string: "10")
    request.automaticReloadPaymentRequest = PKAutomaticReloadPaymentRequest(
        paymentDescription: "",
        automaticReloadBilling: reloadItem,
        managementURL: URL(fileURLWithPath: "/")
    )
    issues = PassKitPaymentRequestValidation.issues(for: request)
    precondition(issues.contains(.reloadMissingPaymentDescription))
    precondition(issues.contains(.reloadMissingManagementURL))
    request.automaticReloadPaymentRequest = PKAutomaticReloadPaymentRequest(
        paymentDescription: "Reload",
        automaticReloadBilling: reloadItem,
        managementURL: URL(string: "https://example.com/reload")!
    )
    precondition(request.automaticReloadPaymentRequest?.automaticReloadBilling.thresholdAmount.compare(NSDecimalNumber(string: "10")) == .orderedSame)

    let deferredItem = PKDeferredPaymentSummaryItem(label: "Later", amount: NSDecimalNumber(value: 9))
    request.deferredPaymentRequest = PKDeferredPaymentRequest(
        paymentDescription: "",
        deferredBilling: deferredItem,
        managementURL: URL(fileURLWithPath: "/")
    )
    issues = PassKitPaymentRequestValidation.issues(for: request)
    precondition(issues.contains(.deferredMissingPaymentDescription))
    precondition(issues.contains(.deferredMissingDate))
    precondition(issues.contains(.deferredMissingManagementURL))
    deferredItem.deferredDate = Date(timeIntervalSince1970: 1_800_000_000)
    request.deferredPaymentRequest = PKDeferredPaymentRequest(
        paymentDescription: "Defer",
        deferredBilling: deferredItem,
        managementURL: URL(string: "https://example.com/defer")!
    )
    precondition(PassKitPaymentRequestValidation.issues(for: request).isEmpty)
}

func testPaymentRequestValidationCouponAndShipping() {
    let request = validPaymentRequest()
    request.couponCode = "SAVE"
    request.supportsCouponCode = false
    precondition(
        PassKitPaymentRequestValidation.issues(for: request).contains(.couponCodeWithoutSupport)
    )
    request.supportsCouponCode = true
    precondition(
        !PassKitPaymentRequestValidation.issues(for: request).contains(.couponCodeWithoutSupport)
    )
    let couponErr = PKPaymentRequest.paymentCouponCodeInvalidError(localizedDescription: "bad")
    precondition((couponErr as? PKPaymentError)?.code == .couponCodeInvalidError)
    let expired = PKPaymentRequest.paymentCouponCodeExpiredError(localizedDescription: "old")
    precondition((expired as? PKPaymentError)?.code == .couponCodeExpiredError)

    let nameless = PKShippingMethod(label: "Ground", amount: NSDecimalNumber(string: "4.00"))
    nameless.identifier = nil
    request.shippingMethods = [nameless]
    precondition(
        PassKitPaymentRequestValidation.issues(for: request).contains(.shippingMethodMissingIdentifier)
    )
    nameless.identifier = "ground"
    nameless.detail = "5 days"
    request.shippingMethods = [nameless]
    request.requiredShippingContactFields = [.postalAddress, .name]
    request.requiredBillingContactFields = [.emailAddress]
    precondition(PassKitPaymentRequestValidation.issues(for: request).isEmpty)
    precondition(request.requiredShippingContactFields.contains(.name))
    precondition(request.shippingMethods?.first?.detail == "5 days")
}

private final class PaymentAuthFinishProbe: PKPaymentAuthorizationControllerDelegate {
    var finished = false
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        finished = true
        _ = controller
    }
}

func testPaymentAuthorizationControllerFailClosedDelegateDispatch() {
    let request = validPaymentRequest()
    let controller = PKPaymentAuthorizationController(paymentRequest: request)
    let probe = PaymentAuthFinishProbe()
    controller.delegate = probe
    var presented = true
    controller.present { presented = $0 }
    precondition(presented == false)
    precondition(probe.finished)
    precondition(controller.linuxHostValidationIssues.isEmpty)
    precondition(controller.paymentRequest === request)
    precondition(PKPaymentAuthorizationController.canMakePayments() == false)

    let invalid = PKPaymentAuthorizationController(paymentRequest: PKPaymentRequest())
    let invalidProbe = PaymentAuthFinishProbe()
    invalid.delegate = invalidProbe
    invalid.present { presented = $0 }
    precondition(presented == false)
    precondition(invalidProbe.finished)
    precondition(invalid.linuxHostValidationIssues.contains(.missingMerchantIdentifier))
}

func testPaymentAuthorizationViewControllerFailClosed() {
    let request = validPaymentRequest()
    MainActor.assumeIsolated {
        precondition(PKPaymentAuthorizationViewController.canMakePayments() == false)
        precondition(PKPaymentAuthorizationViewController(paymentRequest: request) == nil)
        let vc = PKPaymentAuthorizationViewController()
        precondition(vc.delegate == nil)
        _ = vc.paymentRequest
    }
}

func testPaymentErrorHelpersContactAndAddress() {
    let billing = PKPaymentRequest.paymentBillingAddressInvalidError(
        withKey: CNPostalAddressPostalCodeKeyIfPresent(),
        localizedDescription: "bad zip"
    )
    precondition((billing as? PKPaymentError)?.code == .billingContactInvalidError)
    let contactErr = PKPaymentRequest.paymentContactInvalidError(
        withContactField: .emailAddress,
        localizedDescription: "bad email"
    )
    precondition((contactErr as? PKPaymentError)?.code == .shippingContactInvalidError)
    precondition(PKPaymentError.errorDomain == PKPaymentErrorDomain)
    let ship = PKPaymentRequest.paymentShippingAddressInvalidError(
        withKey: "street",
        localizedDescription: nil
    )
    precondition((ship as? PKPaymentError)?.code == .shippingContactInvalidError)
    let unserviceable = PKPaymentRequest.paymentShippingAddressUnserviceableError(
        withLocalizedDescription: "no"
    )
    precondition((unserviceable as? PKPaymentError)?.code == .shippingAddressUnserviceableError)
    let payment = PKPaymentError(.billingContactInvalidError)
    precondition(payment.code == .billingContactInvalidError)
    precondition(PKPaymentError.Code(rawValue: 1) == .shippingContactInvalidError)
}

private func CNPostalAddressPostalCodeKeyIfPresent() -> String {
    "postalCode"
}

func testPaymentButtonTypeAndStyleRawValues() {
    let types: [(PKPaymentButtonType, Int)] = [
        (.plain, 0), (.buy, 1), (.setUp, 2), (.inStore, 3), (.donate, 4),
        (.checkout, 5), (.book, 6), (.subscribe, 7), (.reload, 8),
        (.addMoney, 9), (.topUp, 10), (.order, 11), (.rent, 12),
        (.support, 13), (.contribute, 14), (.tip, 15), (.continue, 16),
    ]
    for (value, raw) in types {
        precondition(value.rawValue == raw)
        precondition(PKPaymentButtonType(rawValue: raw) == value)
    }
    precondition(PKPaymentButtonStyle.white.rawValue == 0)
    precondition(PKPaymentButtonStyle.whiteOutline.rawValue == 1)
    precondition(PKPaymentButtonStyle.black.rawValue == 2)
    precondition(PKPaymentButtonStyle.automatic.rawValue == 3)
}

func testAddPaymentPassRequestConfigurationFields() {
    let config = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2)
    precondition(config != nil)
    config?.cardholderName = "Jane"
    config?.localizedDescription = "Card"
    config?.paymentNetwork = .visa
    config?.primaryAccountIdentifier = "pai"
    config?.primaryAccountSuffix = "1234"
    config?.productIdentifiers = ["p1"]
    config?.style = .payment
    let labeled = PKLabeledValue(label: "PAN", value: "••••1234")
    config?.cardDetails = [labeled]
    precondition(config?.encryptionScheme == .ECC_V2)
    precondition(config?.cardholderName == "Jane")
    precondition(config?.cardDetails[0].label == "PAN")
    MainActor.assumeIsolated {
        precondition(PKAddPaymentPassViewController.canAddPaymentPass() == false)
        precondition(PKAddPaymentPassViewController(requestConfiguration: config!, delegate: nil) == nil)
        precondition(PKAddPassesViewController.canAddPasses() == false)
        precondition(PKAddPassesViewController(pass: PKPass()) == nil)
    }
}

func testPaymentTokenMethodContactFields() {
    let token = PKPaymentToken(paymentData: Data([9]), transactionIdentifier: "txn")
    token.paymentInstrumentName = "Visa"
    token.paymentNetwork = PKPaymentNetwork.visa.rawValue
    token.paymentMethod.displayName = "Visa 1234"
    token.paymentMethod.network = .visa
    token.paymentMethod.type = .credit
    precondition(token.transactionIdentifier == "txn")
    precondition(token.paymentData.count == 1)
    precondition(token.paymentMethod.type == .credit)
    let payment = PKPayment(token: token)
    let contact = PKContact()
    contact.emailAddress = "a@example.com"
    payment.billingContact = contact
    payment.shippingContact = contact
    precondition(payment.token.transactionIdentifier == "txn")
    precondition(payment.billingContact?.emailAddress == "a@example.com")
    precondition(contact.emailAddress == "a@example.com")
}

func testSecureElementAndIdentityFailClosed() {
    let se = PKSecureElementPass()
    precondition(se.passActivationState == .deactivated)
    precondition(se.primaryAccountIdentifier.isEmpty)
    precondition(se.deviceAccountIdentifier.isEmpty)
    let identity = PKIdentityRequest()
    identity.merchantIdentifier = "merchant.example"
    identity.nonce = Data()
    precondition(identity.merchantIdentifier == "merchant.example")
    let controller = PKIdentityAuthorizationController()
    controller.cancelRequest()
    precondition(PKIdentityElement.givenName !== PKIdentityElement.familyName)
    precondition(PKIdentityIntentToStore.willNotStore !== PKIdentityIntentToStore.mayStore)
    precondition(PKIdentityError.notSupported.rawValue == 1)
    precondition(PKIdentityError.cancelled.rawValue == 2)
}

func testPaymentNetworksTableDriven() {
    let rows: [(PKPaymentNetwork, String)] = [
        (.amex, "AmEx"), (.visa, "Visa"), (.masterCard, "MasterCard"),
        (.discover, "Discover"), (.JCB, "JCB"), (.NAPAS, "NAPAS"),
        (.bancontact, "Bancontact"), (.bankAxept, "BankAxept"),
        (.barcode, "Barcode"), (.carteBancaire, "CarteBancaire"),
        (.carteBancaires, "CarteBancaires"), (.cartesBancaires, "CartesBancaires"),
        (.dankort, "Dankort"), (.eftpos, "Eftpos"), (.electron, "Electron"),
        (.girocard, "Girocard"), (.himyan, "Himyan"), (.idCredit, "IDCredit"),
        (.interac, "Interac"), (.jaywan, "Jaywan"), (.meeza, "Meeza"),
        (.mir, "Mir"), (.myDebit, "MyDebit"), (.nanaco, "Nanaco"),
        (.pagoBancomat, "PagoBancomat"), (.postFinance, "PostFinance"),
        (.privateLabel, "PrivateLabel"), (.quicPay, "QuicPay"),
        (.tmoney, "Tmoney"), (.vPay, "VPay"), (.waon, "Waon"),
        (.chinaUnionPay, "ChinaUnionPay"), (.maestro, "Maestro"),
        (.mada, "Mada"), (.suica, "Suica"), (.bancomat, "Bancomat"),
        (.elo, "Elo"),
    ]
    for (network, raw) in rows {
        precondition(network.rawValue == raw)
        precondition(PKPaymentNetwork(rawValue: raw) == network)
    }
}

func testPassKitErrorCodeTable() {
    precondition(PKPassKitError.unknownError.rawValue == -1)
    precondition(PKPassKitError.invalidDataError.rawValue == 1)
    precondition(PKPassKitError.unsupportedVersionError.rawValue == 2)
    precondition(PKPassKitError.invalidSignature.rawValue == 3)
    precondition(PKPassKitError.notEntitledError.rawValue == 4)
    precondition(PKPassKitErrorDomain == "PKPassKitErrorDomain")
    precondition(PKPaymentErrorDomain == "PKPaymentErrorDomain")
    precondition(PKIdentityErrorDomain == "PKIdentityErrorDomain")
    precondition(PKAddSecureElementPassErrorDomain == "PKAddSecureElementPassErrorDomain")
    precondition(PKDisbursementErrorDomain == "PKDisbursementErrorDomain")
    precondition(PKShareSecureElementPassErrorDomain == "PKShareSecureElementPassErrorDomain")
    precondition(PKPaymentError.couponCodeInvalidError.rawValue == 4)
    precondition(PKPaymentError.couponCodeExpiredError.rawValue == 5)
    precondition(PKAddSecureElementPassError.genericError.rawValue == 0)
    precondition(PKDisbursementError.unsupportedCardError.rawValue == 1)
    precondition(PKShareSecureElementPassError.setupError.rawValue == 1)
}

func testMerchantCapabilityAndAddressOptionSets() {
    precondition(PKMerchantCapability.threeDSecure.rawValue == 1 << 0)
    precondition(PKMerchantCapability.emv.rawValue == 1 << 1)
    precondition(PKMerchantCapability.credit.rawValue == 1 << 2)
    precondition(PKMerchantCapability.debit.rawValue == 1 << 3)
    precondition(PKMerchantCapability.instantFundsOut.rawValue == 1 << 7)
    precondition(PKMerchantCapability.capability3DS == .threeDSecure)
    let caps: PKMerchantCapability = [.threeDSecure, .credit]
    precondition(caps.contains(.threeDSecure))
    precondition(!caps.contains(.emv))
    precondition(PKAddressField.postalAddress.rawValue == 1 << 0)
    precondition(PKAddressField.phone.rawValue == 1 << 1)
    precondition(PKAddressField.email.rawValue == 1 << 2)
    precondition(PKAddressField.name.rawValue == 1 << 3)
    precondition(PKAddressField.all.contains(.postalAddress))
    precondition(PKRadioTechnology.NFC.rawValue == 1 << 0)
    precondition(PKRadioTechnology.bluetooth.rawValue == 1 << 1)
    precondition(PKContactField.emailAddress.rawValue == "emailAddress")
    precondition(PKContactField.phoneticName.rawValue == "phoneticName")
    precondition(PKEncryptionScheme.ECC_V2.rawValue == "ECC_V2")
    precondition(PKEncryptionScheme.RSA_V2.rawValue == "RSA_V2")
}

func testCorpusRemainingEnumRawValues() {
    precondition(PKAddIdentityDocumentType.idCard.rawValue == 0)
    precondition(PKAddIdentityDocumentType.mDL.rawValue == 1)
    precondition(PKAddIdentityDocumentType.photoID.rawValue == 2)
    precondition(PKAddIdentityDocumentType(rawValue: 2) == .photoID)
    precondition(PKBarcodeEventConfigurationDataType.unknown.rawValue == 0)
    precondition(PKBarcodeEventConfigurationDataType.signingKeyMaterial.rawValue == 1)
    precondition(PKBarcodeEventConfigurationDataType.signingCertificate.rawValue == 2)
    precondition(PKShareSecureElementPassResult.canceled.rawValue == 0)
    precondition(PKShareSecureElementPassResult.shared.rawValue == 1)
    precondition(PKShareSecureElementPassResult.failed.rawValue == 2)
    precondition(PKVehicleConnectionErrorCode.unknown.rawValue == 0)
    precondition(PKVehicleConnectionErrorCode.sessionUnableToStart.rawValue == 1)
    precondition(PKVehicleConnectionErrorCode.sessionNotActive.rawValue == 2)
    precondition(PKVehicleConnectionSessionConnectionState.disconnected.rawValue == 0)
    precondition(PKVehicleConnectionSessionConnectionState.connected.rawValue == 1)
    precondition(PKVehicleConnectionSessionConnectionState.connecting.rawValue == 2)
    precondition(PKVehicleConnectionSessionConnectionState.failedToConnect.rawValue == 3)
    precondition(PKAddPaymentPassError.unsupported.rawValue == 0)
    precondition(PKAddPaymentPassError.userCancelled.rawValue == 1)
    precondition(PKAddPaymentPassError.systemCancelled.rawValue == 2)
    precondition(PKAddShareablePassConfigurationPrimaryAction.add.rawValue == 0)
    precondition(PKAddShareablePassConfigurationPrimaryAction.share.rawValue == 1)
    precondition(PKIssuerProvisioningExtensionAuthorizationResult.canceled.rawValue == 0)
    precondition(PKIssuerProvisioningExtensionAuthorizationResult.authorized.rawValue == 1)
    precondition(PKPayLaterAction.learnMore.rawValue == 0)
    precondition(PKPayLaterAction.calculator.rawValue == 1)
    precondition(PKApplePayLaterAvailability(rawValue: 0) == .available)
    precondition(PKPassType(rawValue: 0) == .barcode)
    precondition(PKIdentityError.Code(rawValue: 2) == .cancelled)
    precondition(PKPaymentError.Code(rawValue: 4) == .couponCodeInvalidError)
    precondition(PKRadioTechnology(rawValue: 1).contains(.NFC))
    precondition(PKPayLaterDisplayStyle(rawValue: 0) == .standard)
    precondition(PKAddSecureElementPassError.Code(rawValue: 0) == .genericError)
    precondition(PKAutomaticPassPresentationSuppressionResult(rawValue: 0) == .notSupported)
}

func testShareablePassMetadataFields() {
    let preview = PKShareablePassMetadata.Preview(passThumbnail: CGImage(), localizedDescription: "share")
    preview.ownerDisplayName = "Ada"
    preview.provisioningTemplateIdentifier = "tpl"
    precondition(preview.localizedDescription == "share")
    precondition(preview.ownerDisplayName == "Ada")
    _ = preview.passThumbnail
    let meta = PKShareablePassMetadata(
        provisioningCredentialIdentifier: "c",
        sharingInstanceIdentifier: "s",
        cardTemplateIdentifier: "t",
        preview: preview
    )
    meta.accountHash = "h"
    meta.cardConfigurationIdentifier = "cfg"
    meta.cardTemplateIdentifier = "t"
    meta.credentialIdentifier = "c"
    meta.localizedDescription = "d"
    meta.ownerDisplayName = "n"
    meta.relyingPartyIdentifier = "r"
    meta.requiresUnifiedAccessCapableDevice = false
    meta.serverEnvironmentIdentifier = "env"
    meta.sharingInstanceIdentifier = "s"
    meta.templateIdentifier = "tpl"
    precondition(meta.preview.localizedDescription == "share")
    precondition(meta.credentialIdentifier == "c")
    precondition(meta.accountHash == "h")
    _ = meta.passThumbnailImage
    _ = PKShareablePassMetadata(
        provisioningCredentialIdentifier: "c",
        cardConfigurationIdentifier: "cfg",
        sharingInstanceIdentifier: "s",
        passThumbnailImage: CGImage(),
        ownerDisplayName: "n",
        localizedDescription: "d"
    )
}

func testDisbursementRequestFields() {
    let disbursement = PKDisbursementRequest(
        merchantIdentifier: "m",
        currency: Locale.Currency("USD"),
        region: Locale.Region("US"),
        supportedNetworks: [.visa],
        merchantCapabilities: [.threeDSecure],
        summaryItems: []
    )
    disbursement.applicationData = Data([1])
    disbursement.recipientContact = PKContact()
    disbursement.requiredRecipientContactFields = [.name]
    precondition(disbursement.merchantIdentifier == "m")
    precondition(disbursement.supportedNetworks == [.visa])
    precondition(disbursement.merchantCapabilities.contains(.threeDSecure))
    precondition(disbursement.summaryItems.isEmpty)
    precondition(disbursement.currency == Locale.Currency("USD"))
    precondition(disbursement.region == Locale.Region("US"))
    _ = PKDisbursementRequest.disbursementCardUnsupportedError()
    _ = PKDisbursementRequest.disbursementContactInvalidError(
        withContactField: .name,
        localizedDescription: nil
    )
    _ = PKDisbursementSummaryItem()
    precondition(PKDisbursementErrorKey.contactFieldUserInfoKey.rawValue.hasPrefix("PKDisbursement"))
}

func testBarcodeEventModelFields() {
    let sigReq = PKBarcodeEventSignatureRequest()
    sigReq.amount = 1
    sigReq.barcodeIdentifier = "b"
    sigReq.currencyCode = "USD"
    sigReq.deviceAccountIdentifier = "d"
    sigReq.merchantName = "Shop"
    sigReq.partialSignature = Data([1])
    sigReq.rawMerchantName = "shop"
    sigReq.transactionDate = Date.distantPast
    sigReq.transactionIdentifier = "txn"
    sigReq.transactionStatus = "ok"
    precondition(sigReq.barcodeIdentifier == "b")
    precondition(sigReq.merchantName == "Shop")
    precondition(sigReq.transactionIdentifier == "txn")
    let cfg = PKBarcodeEventConfigurationRequest()
    cfg.configurationData = Data([1])
    cfg.configurationDataType = .unknown
    cfg.deviceAccountIdentifier = "d"
    precondition(cfg.deviceAccountIdentifier == "d")
    let meta = PKBarcodeEventMetadataRequest()
    meta.deviceAccountIdentifier = "d"
    meta.lastUsedBarcodeIdentifier = "last"
    precondition(meta.lastUsedBarcodeIdentifier == "last")
    let metaResp = PKBarcodeEventMetadataResponse(paymentInformation: Data([1]))
    precondition(metaResp.paymentInformation.count == 1)
    let sigResp = PKBarcodeEventSignatureResponse(signedData: Data([2]))
    precondition(sigResp.signedData.count == 1)
}

func testIdentityButtonAndDocumentDescriptor() {
    MainActor.assumeIsolated {
        let identityButton = PKIdentityButton(label: .verifyAge, style: .blackOutline)
        identityButton.cornerRadius = 2
        precondition(identityButton.cornerRadius == 2)
        _ = PKIdentityButton.Label(rawValue: 0)
        _ = PKIdentityButton.Style(rawValue: 1)
        _ = PKIdentityButton.Label.verifyIdentity
        _ = PKIdentityButton.Label.verify
        _ = PKIdentityButton.Label.verifyAge
        _ = PKIdentityButton.Label.`continue`
        _ = PKIdentityButton.Style.black
        _ = PKIdentityButton.Style.blackOutline
        let later = PKPayLaterView(amount: 12, currency: Locale.Currency("USD"))
        later.action = .learnMore
        later.displayStyle = .badge
        precondition(later.amount == 12)
        _ = later.delegate
        _ = later.currency
    }
    let anyDesc = PKIdentityAnyOfDescriptor(descriptors: [])
    precondition(anyDesc.descriptors.isEmpty)
    precondition(anyDesc.elements.isEmpty)
    anyDesc.addElements([PKIdentityElement.givenName], intentToStore: .willNotStore)
    _ = anyDesc.intentToStore(element: .givenName)
    _ = PKIdentityDriversLicenseDescriptor()
    _ = PKIdentityPhotoIDDescriptor()
    let national = PKIdentityNationalIDCardDescriptor()
    national.region = Locale.Region("US")
    _ = national.region
    let doc = PKIdentityDocument()
    precondition(doc.encryptedData.isEmpty)
    let idMeta = PKIdentityDocumentMetadata()
    idMeta.cardConfigurationIdentifier = "c"
    idMeta.cardTemplateIdentifier = "t"
    idMeta.credentialIdentifier = "cred"
    idMeta.documentType = .idCard
    idMeta.issuingCountryCode = "US"
    idMeta.serverEnvironmentIdentifier = "s"
    idMeta.sharingInstanceIdentifier = "share"
    precondition(idMeta.issuingCountryCode == "US")
}

func testPassLibraryNotificationConstantValues() {
    precondition(PKPassLibraryNotificationKey.serialNumberUserInfoKey.rawValue.hasPrefix("PKPassLibrary"))
    precondition(PKPassLibraryNotificationKey.addedPassesUserInfoKey.rawValue.hasPrefix("PKPassLibrary"))
    precondition(PKPassLibraryNotificationKey.passTypeIdentifierUserInfoKey.rawValue.hasPrefix("PKPassLibrary"))
    precondition(PKPassLibraryNotificationKey.recoveredPassesUserInfoKey.rawValue.hasPrefix("PKPassLibrary"))
    precondition(PKPassLibraryNotificationKey.removedPassInfosUserInfoKey.rawValue.hasPrefix("PKPassLibrary"))
    precondition(PKPassLibraryNotificationKey.replacementPassesUserInfoKey.rawValue.hasPrefix("PKPassLibrary"))
    let note = PKPassLibraryNotificationName("custom")
    precondition(note.rawValue == "custom")
    _ = PKPassLibraryNotificationName.PKPassLibraryDidChange
    _ = PKPassLibraryNotificationName.PKPassLibraryRemotePaymentPassesDidChange
    precondition(PKPassLibraryAddPassesStatus.didAddPasses.rawValue == 0)
    precondition(PKPassLibraryAddPassesStatus.shouldReviewPasses.rawValue == 1)
    precondition(PKPassLibraryAddPassesStatus.didCancelAddPasses.rawValue == 2)
    precondition(PKPassLibrary.AuthorizationStatus.denied.rawValue == 0)
    precondition(PKPassLibrary.Capability.backgroundAddPasses.rawValue == 0)
    precondition(PKAutomaticPassPresentationSuppressionResult.notSupported.rawValue == 0)
    precondition(PKPassType.barcode.rawValue == 0)
    precondition(PKPassType.secureElement.rawValue == 1)
}
