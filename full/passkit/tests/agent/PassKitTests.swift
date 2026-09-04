import Foundation
import PassKit

func testPaymentNetworks() {
    precondition(PKPaymentNetwork.visa.rawValue == "Visa")
    precondition(PKPaymentNetwork.amex.rawValue == "AmEx")
    precondition(PKPaymentNetwork.masterCard.rawValue == "MasterCard")
    precondition(PKPaymentNetwork.discover.rawValue == "Discover")
    precondition(PKPaymentNetwork.JCB.rawValue == "JCB")
    precondition(PKPaymentNetwork.chinaUnionPay.rawValue == "ChinaUnionPay")
    precondition(PKPaymentNetwork.maestro.rawValue == "Maestro")
    precondition(PKPaymentNetwork.mada.rawValue == "Mada")
    precondition(PKPaymentNetwork.suica.rawValue == "Suica")
    precondition(PKPaymentNetwork.bancomat != .visa)
    precondition(PKPaymentNetwork(rawValue: "Visa") == .visa)
    precondition(PKPaymentNetwork("Elo").rawValue == "Elo")
    var hasher = Hasher()
    PKPaymentNetwork.visa.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMerchantCapability() {
    let caps: PKMerchantCapability = [.threeDSecure, .credit]
    precondition(caps.contains(.threeDSecure))
    precondition(caps.contains(.credit))
    precondition(!caps.contains(.emv))
    precondition(PKMerchantCapability.capability3DS == .threeDSecure)
    precondition(PKMerchantCapability.capabilityEMV == .emv)
    precondition(PKMerchantCapability.capabilityDebit == .debit)
    precondition(PKMerchantCapability.capabilityCredit == .credit)
    precondition(PKMerchantCapability.instantFundsOut.rawValue == 1 << 7)
    precondition(caps.union(.debit).contains(.debit))
    precondition(!caps.intersection(.emv).contains(.emv))
    precondition(!caps.isEmpty)
    precondition(PKMerchantCapability().isEmpty)
}

func testAddressAndContactFields() {
    precondition(PKAddressField.all.contains(.postalAddress))
    precondition(PKAddressField.all.contains(.name))
    precondition(PKContactField.emailAddress.rawValue == "emailAddress")
    precondition(PKContactField.phoneticName.rawValue == "phoneticName")
    let contact = PKContact()
    contact.emailAddress = "a@example.com"
    contact.phoneNumber = CNPhoneNumber(stringValue: "+1")
    precondition(contact.emailAddress == "a@example.com")
    precondition(contact.phoneNumber?.stringValue == "+1")
}

func testPaymentButtonEnums() {
    precondition(PKPaymentButtonType.plain.rawValue == 0)
    precondition(PKPaymentButtonType.buy.rawValue == 1)
    precondition(PKPaymentButtonType.`continue`.rawValue == 16)
    precondition(PKPaymentButtonStyle.automatic.rawValue == 3)
    precondition(PKAddPassButtonStyle.black.rawValue == 0)
    precondition(PKAddPassButtonStyle.blackOutline.rawValue == 1)
}

func testAuthorizationStatusAndSummaryItems() {
    precondition(PKPaymentAuthorizationStatus.success.rawValue == 0)
    precondition(PKPaymentAuthorizationStatus.failure.rawValue == 1)
    precondition(PKPaymentSummaryItemType.final.rawValue == 0)
    let item = PKPaymentSummaryItem(label: "Total", amount: Decimal(10), type: .final)
    precondition(item.label == "Total")
    precondition(item.type == .final)
    let recurring = PKRecurringPaymentSummaryItem(label: "Sub", amount: Decimal(5))
    recurring.intervalCount = 2
    precondition(recurring.intervalCount == 2)
}

func testPassInitFailClosed() {
    do {
        _ = try PKPass(data: Data("not-a-pass".utf8))
        preconditionFailure("unsigned bytes must not become a PKPass")
    } catch let error as PassKitPortableError {
        precondition(error.code == .passValidationUnavailable)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testPassLibraryFailClosed() {
    let library = PKPassLibrary()
    precondition(library.passes().isEmpty)
    precondition(PKPassLibrary.isPassLibraryAvailable() == false)
    precondition(library.containsPass(PKPass()) == false)
    precondition(library.canAddFelicaPass() == false)
    precondition(library.authorizationStatus(for: .backgroundAddPasses) == .denied)
    var added = true
    library.addPasses([], withCompletionHandler: { added = $0 })
    precondition(added == false)
}

func testApplePayUnavailable() {
    precondition(PKPaymentAuthorizationViewController.canMakePayments() == false)
    precondition(
        PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa]) == false
    )
    precondition(PKPaymentAuthorizationController.canMakePayments() == false)
    MainActor.assumeIsolated {
        precondition(PKAddPassesViewController.canAddPasses() == false)
    }
    let request = PKPaymentRequest()
    request.merchantIdentifier = "merchant.example"
    request.countryCode = "US"
    request.currencyCode = "USD"
    request.supportedNetworks = [.visa, .masterCard]
    request.merchantCapabilities = [.threeDSecure]
    precondition(PKPaymentRequest.availableNetworks().isEmpty)
    MainActor.assumeIsolated {
        precondition(PKPaymentAuthorizationViewController(paymentRequest: request) == nil)
    }
    var presented = true
    PKPaymentAuthorizationController(paymentRequest: request).present { presented = $0 }
    precondition(presented == false)
}

func testPaymentErrors() {
    precondition(PKPassKitError.unknownError.rawValue == -1)
    precondition(PKPaymentError.couponCodeInvalidError.rawValue == 4)
    precondition(PKIdentityError.cancelled.rawValue == 2)
    precondition(PKAddSecureElementPassError.genericError.rawValue == 0)
    let payment = PKPaymentError(.billingContactInvalidError)
    precondition(payment.code == .billingContactInvalidError)
    precondition(PKPaymentError.errorDomain == PKPaymentErrorDomain)
    precondition(PKPassKitErrorDomain == "PKPassKitErrorDomain")
    precondition(PKIdentityErrorDomain == "PKIdentityErrorDomain")
}

func testEncryptionAndRadio() {
    precondition(PKEncryptionScheme.ECC_V2.rawValue == "ECC_V2")
    precondition(PKRadioTechnology.NFC.contains(.NFC))
    precondition(PKPassType.barcode.rawValue == 0)
    precondition(PKShippingType.shipping.rawValue == 0)
    precondition(PKPayLaterDisplayStyle.standard.rawValue == 0)
}

func testOverlayLabels() {
    precondition(PayWithApplePayButtonLabel.buy != .donate)
    precondition(PayWithApplePayButtonStyle.automatic != .black)
    precondition(AddPassToWalletButtonStyle.black != .blackOutline)
    precondition(VerifyIdentityWithWalletButtonLabel.verifyAge != .verify)
    let filter = AddPassToWalletButtonFilter.paymentNetwork(.visa)
    _ = filter
    let button = PayWithApplePayButton<EmptyView>(action: {})
    _ = button.body
    let later = PayLaterView(amount: 12.5)
    _ = later.body
}

func testIdentityElements() {
    precondition(PKIdentityElement.givenName !== PKIdentityElement.familyName)
    precondition(PKIdentityIntentToStore.willNotStore !== PKIdentityIntentToStore.mayStore)
    let request = PKIdentityRequest()
    request.merchantIdentifier = "merchant.example"
    precondition(request.merchantIdentifier == "merchant.example")
}

func testPassKitButtonDisabled() {
    MainActor.assumeIsolated {
        let button = PKPaymentButton(
            paymentButtonType: .buy,
            paymentButtonStyle: .black
        )
        precondition(button.paymentButtonType == .buy)
        precondition(button.isEnabled == false)
        precondition(PKAddPassButtonStyle.black.rawValue == 0)
    }
}
