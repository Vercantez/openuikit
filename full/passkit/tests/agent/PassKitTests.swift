import Foundation
import PassKit

func testPaymentNetworks() {
    precondition(PKPaymentNetwork.visa.rawValue == "Visa")
    precondition(PKPaymentNetwork.amex.rawValue == "AmEx")
    precondition(PKPaymentNetwork.masterCard.rawValue == "MasterCard")
    precondition(PKPaymentNetwork.discover.rawValue == "Discover")
    precondition(PKPaymentNetwork.JCB.rawValue == "JCB")
    precondition(PKPaymentNetwork.NAPAS.rawValue == "NAPAS")
    precondition(PKPaymentNetwork.bancontact.rawValue == "Bancontact")
    precondition(PKPaymentNetwork.bankAxept.rawValue == "BankAxept")
    precondition(PKPaymentNetwork.barcode.rawValue == "Barcode")
    precondition(PKPaymentNetwork.carteBancaire.rawValue == "CarteBancaire")
    precondition(PKPaymentNetwork.carteBancaires.rawValue == "CarteBancaires")
    precondition(PKPaymentNetwork.cartesBancaires.rawValue == "CartesBancaires")
    precondition(PKPaymentNetwork.dankort.rawValue == "Dankort")
    precondition(PKPaymentNetwork.eftpos.rawValue == "Eftpos")
    precondition(PKPaymentNetwork.electron.rawValue == "Electron")
    precondition(PKPaymentNetwork.girocard.rawValue == "Girocard")
    precondition(PKPaymentNetwork.himyan.rawValue == "Himyan")
    precondition(PKPaymentNetwork.idCredit.rawValue == "IDCredit")
    precondition(PKPaymentNetwork.interac.rawValue == "Interac")
    precondition(PKPaymentNetwork.jaywan.rawValue == "Jaywan")
    precondition(PKPaymentNetwork.meeza.rawValue == "Meeza")
    precondition(PKPaymentNetwork.mir.rawValue == "Mir")
    precondition(PKPaymentNetwork.myDebit.rawValue == "MyDebit")
    precondition(PKPaymentNetwork.nanaco.rawValue == "Nanaco")
    precondition(PKPaymentNetwork.pagoBancomat.rawValue == "PagoBancomat")
    precondition(PKPaymentNetwork.postFinance.rawValue == "PostFinance")
    precondition(PKPaymentNetwork.privateLabel.rawValue == "PrivateLabel")
    precondition(PKPaymentNetwork.quicPay.rawValue == "QuicPay")
    precondition(PKPaymentNetwork.tmoney.rawValue == "Tmoney")
    precondition(PKPaymentNetwork.vPay.rawValue == "VPay")
    precondition(PKPaymentNetwork.waon.rawValue == "Waon")
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
        preconditionFailure("non-ZIP bytes must not become a PKPass")
    } catch let error as PKPassKitError {
        precondition(error.code == .invalidDataError)
        precondition(error.errorCode == PKPassKitError.invalidDataError.rawValue)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testPassLibraryFailClosed() {
    let library = PKPassLibrary()
    precondition(library.passes().isEmpty)
    precondition(library.passes(of: .barcode).isEmpty)
    precondition(library.passes(withReaderIdentifier: "r").isEmpty)
    precondition(PKPassLibrary.isPassLibraryAvailable() == false)
    precondition(PKPassLibrary.isPaymentPassActivationAvailable() == false)
    precondition(PKPassLibrary.isSuppressingAutomaticPassPresentation() == false)
    precondition(library.isPaymentPassActivationAvailable() == false)
    precondition(library.isSecureElementPassActivationAvailable == false)
    precondition(library.remoteSecureElementPasses.isEmpty)
    precondition(library.remotePaymentPasses().isEmpty)
    precondition(library.containsPass(PKPass()) == false)
    precondition(library.pass(withPassTypeIdentifier: "pass.example", serialNumber: "1") == nil)
    precondition(library.canAddFelicaPass() == false)
    precondition(library.canAddPaymentPass(withPrimaryAccountIdentifier: "x") == false)
    precondition(library.canAddSecureElementPass(primaryAccountIdentifier: "x") == false)
    precondition(library.authorizationStatus(for: .backgroundAddPasses) == .denied)
    precondition(library.replacePass(with: PKPass()) == false)
    library.removePass(PKPass())
    library.openPaymentSetup()
    library.present(PKPaymentPass())
    library.present(PKSecureElementPass())
    PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: 0)
    var suppression = PKAutomaticPassPresentationSuppressionResult.success
    let token = PKPassLibrary.requestAutomaticPassPresentationSuppression { suppression = $0 }
    precondition(token == 0)
    precondition(suppression == .notSupported)
    var status = PKPassLibraryAddPassesStatus.didAddPasses
    library.addPasses([], withCompletionHandler: { status = $0 })
    precondition(status == .didCancelAddPasses)
    var activateOK = true
    var activateError: (any Error)?
    library.activate(PKPaymentPass(), withActivationCode: "0000") { ok, error in
        activateOK = ok
        activateError = error
    }
    precondition(activateOK == false)
    precondition((activateError as? PKPassKitError)?.code == .notEntitledError)
    var dataOK = true
    library.activate(PKPaymentPass(), withActivationData: Data()) { ok, error in
        dataOK = ok
        activateError = error
    }
    precondition(dataOK == false)
    precondition((activateError as? PKPassKitError)?.code == .notEntitledError)
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
    precondition(PKPassKitError.invalidDataError.rawValue == 1)
    precondition(PKPassKitError.unsupportedVersionError.rawValue == 2)
    precondition(PKPassKitError.invalidSignature.rawValue == 3)
    precondition(PKPassKitError.notEntitledError.rawValue == 4)
    precondition(PKPassKitError.Code(rawValue: 1) == .invalidDataError)
    precondition(PKPaymentError.couponCodeInvalidError.rawValue == 4)
    precondition(PKPaymentError.couponCodeExpiredError.rawValue == 5)
    precondition(PKIdentityError.cancelled.rawValue == 2)
    precondition(PKAddSecureElementPassError.genericError.rawValue == 0)
    let payment = PKPaymentError(.billingContactInvalidError)
    precondition(payment.code == .billingContactInvalidError)
    precondition(PKPaymentError.errorDomain == PKPaymentErrorDomain)
    precondition(PKPassKitErrorDomain == "PKPassKitErrorDomain")
    precondition(PKPassKitError.errorDomain == PKPassKitErrorDomain)
    precondition(PKIdentityErrorDomain == "PKIdentityErrorDomain")
    let kit = PKPassKitError(.notEntitledError)
    precondition(kit.errorCode == 4)
    precondition(kit.errorUserInfo.isEmpty)
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
        precondition(button.paymentButtonStyle == .black)
        precondition(button.isEnabled == false)
        button.cornerRadius = 8
        precondition(button.cornerRadius == 8)
        let art = PKPaymentButton(
            paymentButtonType: .plain,
            paymentButtonStyle: .white,
            disableCardArt: true
        )
        precondition(art.isEnabled == false)
        let typed = PKPaymentButton(type: .donate, style: .automatic, disableCardArt: true)
        precondition(typed.paymentButtonType == .donate)
        precondition(PKAddPassButtonStyle.black.rawValue == 0)
        precondition(PKAddPassButtonStyle(rawValue: 1) == .blackOutline)
        // Drawing (Apple Pay button artwork) is not modelled; UIKit note
        // in README. Construction and the disabled flag are the host evidence.
    }
}
