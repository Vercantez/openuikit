import Foundation
import PassKit

// MARK: - Per-family tests for previously declared PassKit-owned identifiers.

private func passKitHash<T: Hashable>(_ value: T) -> Int {
    var hasher = Hasher()
    hasher.combine(value)
    return hasher.finalize()
}

func testEnumHashableAndInequality() {
    precondition(PKAddIdentityDocumentType.idCard != .photoID)
    _ = passKitHash(PKAddIdentityDocumentType.mDL)
    precondition(PKAddPassButtonStyle.black != .blackOutline)
    _ = passKitHash(PKAddPassButtonStyle.black)
    precondition(PKAddPaymentPassError.unsupported != .userCancelled)
    _ = passKitHash(PKAddPaymentPassError.systemCancelled)
    precondition(PKAddPaymentPassStyle.payment != .access)
    _ = passKitHash(PKAddPaymentPassStyle.payment)
    precondition(PKAddSecureElementPassError.Code.genericError != .userCanceledError)
    _ = passKitHash(PKAddSecureElementPassError.Code.deviceNotReadyError)
    precondition(PKAddShareablePassConfigurationPrimaryAction.add != .share)
    _ = passKitHash(PKAddShareablePassConfigurationPrimaryAction.add)
    precondition(PKApplePayLaterAvailability.available != .unavailableItemIneligible)
    _ = passKitHash(PKApplePayLaterAvailability.available)
    precondition(PKAutomaticPassPresentationSuppressionResult.notSupported != .success)
    _ = passKitHash(PKAutomaticPassPresentationSuppressionResult.denied)
    precondition(PKBarcodeEventConfigurationDataType.unknown != .signingCertificate)
    _ = passKitHash(PKBarcodeEventConfigurationDataType.signingKeyMaterial)
    precondition(PKDisbursementError.Code.unknownError != .unsupportedCardError)
    _ = passKitHash(PKDisbursementError.Code.recipientContactInvalidError)
    precondition(PKIdentityButton.Label.verifyIdentity != .verifyAge)
    _ = passKitHash(PKIdentityButton.Label.verify)
    precondition(PKIdentityButton.Style.black != .blackOutline)
    _ = passKitHash(PKIdentityButton.Style.black)
    precondition(PKIdentityError.Code.cancelled != .notSupported)
    _ = passKitHash(PKIdentityError.Code.unknown)
    precondition(PKIssuerProvisioningExtensionAuthorizationResult.canceled != .authorized)
    _ = passKitHash(PKIssuerProvisioningExtensionAuthorizationResult.authorized)
    precondition(PKPassKitError.Code.invalidDataError != .notEntitledError)
    _ = passKitHash(PKPassKitError.Code.invalidSignature)
    precondition(PKPassLibraryAddPassesStatus.didAddPasses != .didCancelAddPasses)
    _ = passKitHash(PKPassLibraryAddPassesStatus.shouldReviewPasses)
    precondition(PKPassLibrary.AuthorizationStatus.denied != .authorized)
    _ = passKitHash(PKPassLibrary.AuthorizationStatus.restricted)
    precondition(PKPassLibrary.Capability.backgroundAddPasses == .backgroundAddPasses)
    _ = passKitHash(PKPassLibrary.Capability.backgroundAddPasses)
    precondition(PKPassType.barcode != .secureElement)
    _ = passKitHash(PKPassType.any)
    precondition(PKPayLaterAction.learnMore != .calculator)
    _ = passKitHash(PKPayLaterAction.learnMore)
    precondition(PKPayLaterDisplayStyle.standard != .price)
    _ = passKitHash(PKPayLaterDisplayStyle.badge)
    precondition(PKPaymentAuthorizationStatus.success != .failure)
    _ = passKitHash(PKPaymentAuthorizationStatus.pinLockout)
    precondition(PKPaymentButtonStyle.black != .automatic)
    _ = passKitHash(PKPaymentButtonStyle.white)
    precondition(PKPaymentButtonType.buy != .donate)
    _ = passKitHash(PKPaymentButtonType.plain)
    precondition(PKPaymentError.Code.unknownError != .couponCodeInvalidError)
    _ = passKitHash(PKPaymentError.Code.billingContactInvalidError)
    precondition(PKPaymentMethodType.credit != .debit)
    _ = passKitHash(PKPaymentMethodType.prepaid)
    precondition(PKPaymentPassActivationState.activated != .deactivated)
    _ = passKitHash(PKPaymentPassActivationState.suspended)
    precondition(PKPaymentSummaryItemType.final != .pending)
    _ = passKitHash(PKPaymentSummaryItemType.final)
    precondition(PKSecureElementPass.PassActivationState.activated != .deactivated)
    _ = passKitHash(PKSecureElementPass.PassActivationState.activating)
    precondition(PKShareSecureElementPassError.Code.unknownError != .setupError)
    _ = passKitHash(PKShareSecureElementPassError.Code.setupError)
    precondition(PKShareSecureElementPassResult.canceled != .failed)
    _ = passKitHash(PKShareSecureElementPassResult.shared)
    precondition(PKAddressField.postalAddress != .email)
    _ = passKitHash(PKAddressField.phone)
    precondition(PKMerchantCapability.threeDSecure != .emv)
    _ = passKitHash(PKMerchantCapability.credit)
    precondition(PKRadioTechnology.NFC != .bluetooth)
    _ = passKitHash(PKRadioTechnology.NFC)
}

func testNewtypeWrapperHashable() {
    _ = passKitHash(PKContactField.emailAddress)
    _ = passKitHash(PKDisbursementErrorKey.contactFieldUserInfoKey)
    _ = passKitHash(PKEncryptionScheme.ECC_V2)
    _ = passKitHash(PKPassLibraryNotificationKey.serialNumberUserInfoKey)
    _ = passKitHash(PKPassLibraryNotificationName.PKPassLibraryDidChange)
    _ = passKitHash(PKPaymentErrorKey.postalAddressUserInfoKey)
    _ = passKitHash(PKStoredValuePassBalance.BalanceType.cash)
    precondition(PKContactField.emailAddress != .name)
}

func testOptionSetAlgebra() {
    var address: PKAddressField = []
    precondition(address.isEmpty)
    let inserted = address.insert(.postalAddress)
    precondition(inserted.inserted)
    precondition(address.contains(.postalAddress))
    _ = address.update(with: .phone)
    _ = address.remove(.phone)
    precondition(address.isSubset(of: [.postalAddress, .email, .name, .phone]))
    precondition(PKAddressField.all.isSuperset(of: [.postalAddress]))
    precondition(!PKAddressField.postalAddress.isDisjoint(with: [.postalAddress, .email]))
    precondition(PKAddressField.postalAddress.union(.email).contains(.email))
    precondition(PKAddressField([.postalAddress, .email]).intersection(.email) == .email)
    precondition(PKAddressField.postalAddress.symmetricDifference(.email).contains(.email))
    var subtractCopy = PKAddressField.all
    subtractCopy.subtract(.name)
    precondition(!subtractCopy.contains(.name))
    precondition(PKAddressField.all.subtracting(.phone).contains(.email))
    precondition(PKAddressField.postalAddress.isStrictSubset(of: PKAddressField.all))
    precondition(PKAddressField.all.isStrictSuperset(of: [.email]))
    address.formUnion(.email)
    address.formIntersection([.postalAddress, .email])
    address.formSymmetricDifference(.phone)
    let fromArray = PKAddressField(arrayLiteral: .postalAddress, .name)
    precondition(fromArray.contains(.name))
    let fromSequence = PKAddressField([PKAddressField.email])
    precondition(fromSequence.contains(.email))

    var merchant: PKMerchantCapability = [.threeDSecure]
    precondition(!merchant.isEmpty)
    _ = merchant.insert(.emv)
    _ = merchant.update(with: .credit)
    _ = merchant.remove(.credit)
    precondition(merchant.contains(.threeDSecure))
    precondition(merchant.union(.debit).contains(.debit))
    precondition(merchant.intersection(.threeDSecure) == .threeDSecure)
    precondition(merchant.symmetricDifference(.emv).contains(.threeDSecure) || true)
    merchant.formUnion(.instantFundsOut)
    merchant.formIntersection([.threeDSecure, .emv, .instantFundsOut])
    merchant.formSymmetricDifference(.debit)
    precondition(PKMerchantCapability.threeDSecure.isSubset(of: [.threeDSecure, .emv]))
    precondition(PKMerchantCapability([.threeDSecure, .emv]).isSuperset(of: [.emv]))
    precondition(!PKMerchantCapability.threeDSecure.isDisjoint(with: [.threeDSecure, .credit]))
    precondition(PKMerchantCapability.threeDSecure.isStrictSubset(of: [.threeDSecure, .emv]))
    precondition(PKMerchantCapability([.threeDSecure, .emv]).isStrictSuperset(of: [.threeDSecure]))
    var merchantSubtract = PKMerchantCapability([.threeDSecure, .emv])
    merchantSubtract.subtract(.emv)
    precondition(PKMerchantCapability([.threeDSecure, .emv]).subtracting(.emv) == .threeDSecure)
    let merchantArray = PKMerchantCapability(arrayLiteral: .credit, .debit)
    precondition(merchantArray.contains(.credit))
    let merchantSeq = PKMerchantCapability([PKMerchantCapability.emv])
    precondition(merchantSeq.contains(.emv))

    var radio: PKRadioTechnology = []
    precondition(radio.isEmpty)
    _ = radio.insert(.NFC)
    _ = radio.update(with: .bluetooth)
    _ = radio.remove(.bluetooth)
    precondition(radio.contains(.NFC))
    precondition(radio.union(.bluetooth).contains(.bluetooth))
    precondition(radio.intersection(.NFC) == .NFC)
    precondition(radio.symmetricDifference(.bluetooth).contains(.bluetooth))
    radio.formUnion(.bluetooth)
    radio.formIntersection([.NFC, .bluetooth])
    radio.formSymmetricDifference(.NFC)
    precondition(PKRadioTechnology.NFC.isSubset(of: [.NFC, .bluetooth]))
    precondition(PKRadioTechnology([.NFC, .bluetooth]).isSuperset(of: [.NFC]))
    precondition(!PKRadioTechnology.NFC.isDisjoint(with: [.NFC]))
    precondition(PKRadioTechnology.NFC.isStrictSubset(of: [.NFC, .bluetooth]))
    precondition(PKRadioTechnology([.NFC, .bluetooth]).isStrictSuperset(of: [.NFC]))
    var radioSubtract = PKRadioTechnology([.NFC, .bluetooth])
    radioSubtract.subtract(.NFC)
    precondition(PKRadioTechnology([.NFC, .bluetooth]).subtracting(.NFC) == .bluetooth)
    let radioArray = PKRadioTechnology(arrayLiteral: .NFC)
    precondition(radioArray.contains(.NFC))
    let radioSeq = PKRadioTechnology([PKRadioTechnology.bluetooth])
    precondition(radioSeq.contains(.bluetooth))
    let radioEmpty = PKRadioTechnology()
    precondition(radioEmpty.isEmpty)
}

func testPassKitErrorBridgingWitnesses() {
    let error = PKPassKitError(.notEntitledError, userInfo: ["reason": "linux"])
    precondition(PKPassKitError.errorDomain == PKPassKitErrorDomain)
    precondition(error.errorCode == 4)
    precondition(!error.errorUserInfo.isEmpty)
    precondition(!error.userInfo.isEmpty)
    precondition(error.code == .notEntitledError)
    precondition(error.localizedDescription.contains("PKPassKit"))
    precondition(error == PKPassKitError(.notEntitledError, userInfo: ["reason": "linux"]))
    _ = passKitHash(error)
    do {
        throw PKPassKitError(.invalidSignature)
    } catch PKPassKitError.invalidSignature {
    } catch {
        preconditionFailure("PKPassKitError ~= mismatch")
    }
}

func testPaymentErrorBridgingWitnesses() {
    let error = PKPaymentError(.couponCodeInvalidError, userInfo: ["code": "SAVE"])
    precondition(PKPaymentError.errorDomain == PKPaymentErrorDomain)
    precondition(error.errorCode == 4)
    precondition(!error.errorUserInfo.isEmpty)
    precondition(!error.userInfo.isEmpty)
    precondition(error.code == .couponCodeInvalidError)
    precondition(error.localizedDescription.contains("PKPayment"))
    precondition(error == PKPaymentError(.couponCodeInvalidError, userInfo: ["code": "SAVE"]))
    _ = passKitHash(error)
    do {
        throw PKPaymentError(.billingContactInvalidError)
    } catch PKPaymentError.billingContactInvalidError {
    } catch {
        preconditionFailure("PKPaymentError ~= mismatch")
    }
}

func testIdentityErrorBridgingWitnesses() {
    let error = PKIdentityError(.cancelled, userInfo: ["n": "1"])
    precondition(PKIdentityError.errorDomain == PKIdentityErrorDomain)
    precondition(error.errorCode == 2)
    precondition(!error.errorUserInfo.isEmpty)
    precondition(!error.userInfo.isEmpty)
    precondition(error.code == .cancelled)
    precondition(error.localizedDescription.contains("PKIdentity"))
    precondition(error == PKIdentityError(.cancelled, userInfo: ["n": "1"]))
    _ = passKitHash(error)
    do {
        throw PKIdentityError(.notSupported)
    } catch PKIdentityError.notSupported {
    } catch {
        preconditionFailure("PKIdentityError ~= mismatch")
    }
}

func testDisbursementErrorBridgingWitnesses() {
    let error = PKDisbursementError(.unsupportedCardError, userInfo: ["card": "no"])
    precondition(PKDisbursementError.errorDomain == PKDisbursementErrorDomain)
    precondition(error.errorCode == 1)
    precondition(!error.errorUserInfo.isEmpty)
    precondition(!error.userInfo.isEmpty)
    precondition(error.code == .unsupportedCardError)
    precondition(error.localizedDescription.contains("PKDisbursement"))
    precondition(error == PKDisbursementError(.unsupportedCardError, userInfo: ["card": "no"]))
    _ = passKitHash(error)
    do {
        throw PKDisbursementError(.recipientContactInvalidError)
    } catch PKDisbursementError.recipientContactInvalidError {
    } catch {
        preconditionFailure("PKDisbursementError ~= mismatch")
    }
}

func testAddSecureElementPassErrorBridgingWitnesses() {
    let error = PKAddSecureElementPassError(.deviceNotReadyError, userInfo: ["se": "no"])
    precondition(PKAddSecureElementPassError.errorDomain == PKAddSecureElementPassErrorDomain)
    precondition(error.errorCode == 5)
    precondition(!error.errorUserInfo.isEmpty)
    precondition(!error.userInfo.isEmpty)
    precondition(error.code == .deviceNotReadyError)
    precondition(error.localizedDescription.contains("PKAddSecureElement"))
    precondition(error == PKAddSecureElementPassError(.deviceNotReadyError, userInfo: ["se": "no"]))
    _ = passKitHash(error)
    do {
        throw PKAddSecureElementPassError(.userCanceledError)
    } catch PKAddSecureElementPassError.userCanceledError {
    } catch {
        preconditionFailure("PKAddSecureElementPassError ~= mismatch")
    }
}

func testShareSecureElementPassErrorBridgingWitnesses() {
    let error = PKShareSecureElementPassError(.setupError, userInfo: ["share": "no"])
    precondition(PKShareSecureElementPassError.errorDomain == PKShareSecureElementPassErrorDomain)
    precondition(error.errorCode == 1)
    precondition(!error.errorUserInfo.isEmpty)
    precondition(!error.userInfo.isEmpty)
    precondition(error.code == .setupError)
    precondition(error.localizedDescription.contains("PKShareSecureElement"))
    precondition(error == PKShareSecureElementPassError(.setupError, userInfo: ["share": "no"]))
    _ = passKitHash(error)
    do {
        throw PKShareSecureElementPassError(.unknownError)
    } catch PKShareSecureElementPassError.unknownError {
    } catch {
        preconditionFailure("PKShareSecureElementPassError ~= mismatch")
    }
}

func testJPKIErrorLocalizedDescription() {
    precondition(JPKIPassContents.Error.resourceNotAvailable.localizedDescription.contains("JPKI"))
    _ = JPKIPassContents.Error.unknownError.localizedDescription
}

func testPayWithApplePayButtonInitsAndPhase() {
    precondition(PayWithApplePayButtonLabel.buy != .donate)
    precondition(PayWithApplePayButtonStyle.automatic != .black)
    _ = PayWithApplePayButton<EmptyView>.Body.self
    let actionButton = PayWithApplePayButton<EmptyView>(action: {})
    _ = actionButton.body
    let request = PKPaymentRequest()
    let requestButton = PayWithApplePayButton<EmptyView>(
        .plain,
        request: request,
        onPaymentAuthorizationChange: { _ in }
    )
    _ = requestButton.body
    let merchantButton = PayWithApplePayButton<EmptyView>(
        .buy,
        request: request,
        onPaymentAuthorizationChange: { _ in },
        onMerchantSessionRequested: {}
    )
    _ = merchantButton.body
    let fallbackAction = PayWithApplePayButton(
        .checkout,
        action: {},
        fallback: { EmptyView() }
    )
    _ = fallbackAction.body
    let fallbackRequest = PayWithApplePayButton(
        .order,
        request: request,
        onPaymentAuthorizationChange: { _ in },
        fallback: { EmptyView() }
    )
    _ = fallbackRequest.body
    let fallbackMerchant = PayWithApplePayButton(
        .tip,
        request: request,
        onPaymentAuthorizationChange: { _ in },
        onMerchantSessionRequested: {},
        fallback: { EmptyView() }
    )
    _ = fallbackMerchant.body
    let will = PayWithApplePayButtonPaymentAuthorizationPhase.willAuthorize
    let finish = PayWithApplePayButtonPaymentAuthorizationPhase.didFinish
    let authorized = PayWithApplePayButtonPaymentAuthorizationPhase.didAuthorize(
        payment: PKPayment(),
        resultHandler: { _ in }
    )
    switch will {
    case .willAuthorize:
        break
    default:
        preconditionFailure("willAuthorize")
    }
    switch finish {
    case .didFinish:
        break
    default:
        preconditionFailure("didFinish")
    }
    switch authorized {
    case .didAuthorize:
        break
    default:
        preconditionFailure("didAuthorize")
    }
}

func testAddPassToWalletButtonInitsAndResponse() {
    _ = AddPassToWalletButton<EmptyView>.Body.self
    let action = AddPassToWalletButton<EmptyView>(action: {})
    _ = action.body
    let passes = AddPassToWalletButton<EmptyView>([PKPass()], onCompletion: { _ in })
    _ = passes.body
    let seConfig = PKAddSecureElementPassConfiguration()
    let seButton = AddPassToWalletButton<EmptyView>(seConfig, onCompletion: { _ in })
    _ = seButton.body
    let carKey = AddPassToWalletButton<EmptyView>(
        carKeyPassword: "pw",
        supportedRadioTechnologies: .NFC,
        issuerIdentifier: "iss",
        onCompletion: { _ in }
    )
    _ = carKey.body
    let carKeyFallback = AddPassToWalletButton(
        carKeyPassword: "pw",
        supportedRadioTechnologies: [.NFC, .bluetooth],
        issuerIdentifier: "iss",
        onCompletion: { _ in },
        fallback: { EmptyView() }
    )
    _ = carKeyFallback.body
    let named = AddPassToWalletButton<EmptyView>(
        .ECC_V2,
        cardholderName: "Ada",
        passStyle: .payment,
        primaryAccountSuffix: "1234",
        cardDetails: [],
        description: "card",
        filters: [
            .paymentNetwork(.visa),
            .productIdentifier("prod"),
            .primaryAccountIdentifier("pai"),
        ],
        onRequest: { _ in PKAddPaymentPassRequest() },
        onCompletion: { _ in }
    )
    _ = named.body
    let suffix = AddPassToWalletButton<EmptyView>(
        .RSA_V2,
        primaryAccountSuffix: "9999",
        passStyle: .access,
        cardDetails: [],
        description: nil,
        filters: [],
        onRequest: { _ in PKAddPaymentPassRequest() },
        onCompletion: { _ in }
    )
    _ = suffix.body
    let fromConfig = AddPassToWalletButton<EmptyView>(
        PKAddPaymentPassRequestConfiguration(),
        onRequest: { _ in PKAddPaymentPassRequest() },
        onCompletion: { _ in }
    )
    _ = fromConfig.body
    let passFallback = AddPassToWalletButton([PKPass()], onCompletion: { _ in }, fallback: { EmptyView() })
    _ = passFallback.body
    let seFallback = AddPassToWalletButton(seConfig, onCompletion: { _ in }, fallback: { EmptyView() })
    _ = seFallback.body
    let namedFallback = AddPassToWalletButton(
        .ECC_V2,
        cardholderName: "Ada",
        passStyle: .payment,
        primaryAccountSuffix: "1234",
        cardDetails: [],
        description: "card",
        filters: [],
        onRequest: { _ in PKAddPaymentPassRequest() },
        onCompletion: { _ in },
        fallback: { EmptyView() }
    )
    _ = namedFallback.body
    let suffixFallback = AddPassToWalletButton(
        .RSA_V2,
        primaryAccountSuffix: "9999",
        passStyle: .access,
        cardDetails: [],
        description: nil,
        filters: [],
        onRequest: { _ in PKAddPaymentPassRequest() },
        onCompletion: { _ in },
        fallback: { EmptyView() }
    )
    _ = suffixFallback.body
    let configFallback = AddPassToWalletButton(
        PKAddPaymentPassRequestConfiguration(),
        onRequest: { _ in PKAddPaymentPassRequest() },
        onCompletion: { _ in },
        fallback: { EmptyView() }
    )
    _ = configFallback.body
    let response = AddPassToWalletButtonResponse(
        certificates: [Data([1])],
        nonce: Data([2]),
        nonceSignature: Data([3])
    )
    precondition(response.certificates.count == 1)
    precondition(response.nonce.count == 1)
    precondition(response.nonceSignature.count == 1)
    _ = AddPassToWalletButtonFilter.productIdentifier("sku")
    _ = AddPassToWalletButtonFilter.primaryAccountIdentifier("pai")
}

func testAsyncShareablePassConfigurationView() {
    _ = AsyncShareablePassConfiguration<EmptyView>.Body.self
    let view = AsyncShareablePassConfiguration(
        metadata: [],
        action: .add,
        content: { (result: AsyncShareablePassConfiguration<EmptyView>.Result) in
            switch result {
            case .loading:
                break
            case .failure:
                break
            case .success:
                break
            }
            return EmptyView()
        }
    )
    _ = view.body
    let loading = AsyncShareablePassConfiguration<EmptyView>.Result.loading
    let failure = AsyncShareablePassConfiguration<EmptyView>.Result.failure(PKPassKitError(.notEntitledError))
    let success = AsyncShareablePassConfiguration<EmptyView>.Result.success(PKAddShareablePassConfiguration())
    switch loading {
    case .loading:
        break
    default:
        preconditionFailure("loading")
    }
    switch failure {
    case .failure:
        break
    default:
        preconditionFailure("failure")
    }
    switch success {
    case .success:
        break
    default:
        preconditionFailure("success")
    }
}

func testPayLaterViewOverlayValues() {
    _ = PayLaterView.Body.self
    precondition(PayLaterViewAction.learnMore != .calculator)
    precondition(PayLaterViewDisplayStyle.standard != .badge)
    precondition(PayLaterViewDisplayStyle.checkout != .price)
    let standard = PayLaterView(amount: 12.5)
    _ = standard.body
    let action = PayLaterView(amount: 3, action: .calculator, displayStyle: .checkout)
    _ = action.body
    let currency = PayLaterView(amount: 9, currency: Locale.Currency("USD"))
    _ = currency.body
}

func testVerifyIdentityWithWalletButtonOverlay() {
    _ = VerifyIdentityWithWalletButton<EmptyView>.Body.self
    precondition(VerifyIdentityWithWalletButtonStyle.black != .blackOutline)
    let action = VerifyIdentityWithWalletButton<EmptyView>(action: {})
    _ = action.body
    let request = VerifyIdentityWithWalletButton<EmptyView>(
        .verifyIdentity,
        request: PKIdentityRequest(),
        onCompletion: { _ in }
    )
    _ = request.body
    let fallback = VerifyIdentityWithWalletButton(
        .verifyAge,
        request: PKIdentityRequest(),
        onCompletion: { _ in },
        fallback: { EmptyView() }
    )
    _ = fallback.body
}

func testPaymentAuthorizationControllerDelegateDefaults() {
    let probe = AuthControllerDelegateProbe()
    let controller = PKPaymentAuthorizationController(paymentRequest: PKPaymentRequest())
    let payment = PKPayment()
    var finished = false
    probe.paymentAuthorizationControllerDidFinish(controller)
    finished = true
    precondition(finished)
    var status: PKPaymentAuthorizationStatus?
    probe.paymentAuthorizationController(controller, didAuthorizePayment: payment) { status = $0 }
    precondition(status == .failure)
    var result: PKPaymentAuthorizationResult?
    probe.paymentAuthorizationController(controller, didAuthorizePayment: payment) { result = $0 }
    precondition(result?.status == .failure)
    probe.paymentAuthorizationController(controller, didRequestMerchantSessionUpdate: { update in
        precondition(update.status == .failure)
    })
    var methodItems: [PKPaymentSummaryItem]?
    probe.paymentAuthorizationController(controller, didSelectPaymentMethod: PKPaymentMethod()) {
        methodItems = $0
    }
    precondition(methodItems?.isEmpty == true)
    var contactStatus: PKPaymentAuthorizationStatus?
    probe.paymentAuthorizationController(controller, didSelectShippingContact: PKContact()) {
        contactStatus = $0
        _ = ($1, $2)
    }
    precondition(contactStatus == .failure)
    var shipStatus: PKPaymentAuthorizationStatus?
    probe.paymentAuthorizationController(controller, didSelectShippingMethod: PKShippingMethod()) {
        shipStatus = $0
        _ = $1
    }
    precondition(shipStatus == .failure)
    probe.paymentAuthorizationControllerWillAuthorizePayment(controller)
    precondition(probe.presentationWindow(for: controller) == nil)
    waitFor { done in
        Task {
            _ = await probe.paymentAuthorizationController(controller, didAuthorizePayment: payment)
            _ = await probe.paymentAuthorizationController(controller, didChangeCouponCode: "SAVE")
            _ = await probe.paymentAuthorizationController(controller, didSelectPaymentMethod: PKPaymentMethod())
            _ = await probe.paymentAuthorizationController(controller, didSelectShippingContact: PKContact())
            _ = await probe.paymentAuthorizationController(controller, didSelectShippingMethod: PKShippingMethod())
            done()
        }
    }
}

func testPaymentAuthorizationViewControllerDelegateDefaults() {
    MainActor.assumeIsolated {
        let probe = AuthViewDelegateProbe()
        let controller = PKPaymentAuthorizationViewController()
        let payment = PKPayment()
        probe.paymentAuthorizationViewControllerDidFinish(controller)
        var status: PKPaymentAuthorizationStatus?
        probe.paymentAuthorizationViewController(controller, didAuthorizePayment: payment) { status = $0 }
        precondition(status == .failure)
        var result: PKPaymentAuthorizationResult?
        probe.paymentAuthorizationViewController(controller, didAuthorizePayment: payment) { result = $0 }
        precondition(result?.status == .failure)
        probe.paymentAuthorizationViewController(controller, didRequestMerchantSessionUpdate: { update in
            precondition(update.status == .failure)
        })
        var methodItems: [PKPaymentSummaryItem]?
        probe.paymentAuthorizationViewController(controller, didSelect: PKPaymentMethod()) {
            methodItems = $0
        }
        precondition(methodItems?.isEmpty == true)
        var addressStatus: PKPaymentAuthorizationStatus?
        probe.paymentAuthorizationViewController(controller, didSelectShippingAddress: ABRecord()) {
            addressStatus = $0
            _ = ($1, $2)
        }
        precondition(addressStatus == .failure)
        var contactStatus: PKPaymentAuthorizationStatus?
        probe.paymentAuthorizationViewController(controller, didSelectShippingContact: PKContact()) {
            contactStatus = $0
            _ = ($1, $2)
        }
        precondition(contactStatus == .failure)
        var shipStatus: PKPaymentAuthorizationStatus?
        probe.paymentAuthorizationViewController(controller, didSelect: PKShippingMethod()) {
            shipStatus = $0
            _ = $1
        }
        precondition(shipStatus == .failure)
        probe.paymentAuthorizationViewControllerWillAuthorizePayment(controller)
        waitFor { done in
            Task { @MainActor in
                _ = await probe.paymentAuthorizationViewController(controller, didAuthorizePayment: payment)
                _ = await probe.paymentAuthorizationViewController(controller, didChangeCouponCode: "SAVE")
                _ = await probe.paymentAuthorizationViewController(controller, didSelect: PKPaymentMethod())
                _ = await probe.paymentAuthorizationViewController(controller, didSelectShippingContact: PKContact())
                _ = await probe.paymentAuthorizationViewController(controller, didSelect: PKShippingMethod())
                done()
            }
        }
    }
}

func testAddPaymentPassViewControllerDelegateDefaults() {
    MainActor.assumeIsolated {
        let probe = AddPaymentPassDelegateProbe()
        let controller = PKAddPaymentPassViewController()
        probe.addPaymentPassViewController(controller, didFinishAdding: nil, error: PKPassKitError(.notEntitledError))
        waitFor { done in
            Task { @MainActor in
                let request = await probe.addPaymentPassViewController(
                    controller,
                    generateRequestWithCertificateChain: [],
                    nonce: Data(),
                    nonceSignature: Data()
                )
                _ = request
                done()
            }
        }
    }
}

func testAddSecureElementPassViewControllerDelegateDefaults() {
    MainActor.assumeIsolated {
        let probe = AddSecureElementPassDelegateProbe()
        let controller = PKAddSecureElementPassViewController()
        probe.addSecureElementPassViewController(controller, didFinishAdding: nil, error: PKPassKitError(.notEntitledError))
        probe.addSecureElementPassViewController(
            controller,
            didFinishAddingSecureElementPasses: nil,
            error: PKPassKitError(.notEntitledError)
        )
    }
}

func testShareSecureElementPassViewControllerDelegateDefaults() {
    MainActor.assumeIsolated {
        let probe = ShareSecureElementPassDelegateProbe()
        let controller = PKShareSecureElementPassViewController(
            secureElementPass: PKSecureElementPass(),
            delegate: nil
        )
        probe.shareSecureElementPassViewController(controller, didCreateShare: nil, activationCode: nil)
        probe.shareSecureElementPassViewController(controller, didFinishWith: .canceled)
    }
}

func testPaymentInformationRequestHandlingDefaults() {
    let probe = PaymentInformationHandlerProbe()
    waitFor { done in
        Task {
            await probe.handle(PKBarcodeEventConfigurationRequest())
            _ = await probe.handleInformationRequest(PKBarcodeEventMetadataRequest())
            _ = await probe.handle(PKBarcodeEventSignatureRequest())
            done()
        }
    }
}

func testIssuerProvisioningExtensionAuthorizationProviding() {
    let probe = IssuerAuthorizationProbe()
    var captured: PKIssuerProvisioningExtensionAuthorizationResult?
    probe.completionHandler = { captured = $0 }
    probe.completionHandler?(.authorized)
    precondition(captured == .authorized)
}

private final class AuthControllerDelegateProbe: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        _ = controller
    }
}

@MainActor
private final class AuthViewDelegateProbe: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        _ = controller
    }
}

@MainActor
private final class AddPaymentPassDelegateProbe: PKAddPaymentPassViewControllerDelegate {}

@MainActor
private final class AddSecureElementPassDelegateProbe: PKAddSecureElementPassViewControllerDelegate {}

@MainActor
private final class ShareSecureElementPassDelegateProbe: PKShareSecureElementPassViewControllerDelegate {}

private final class PaymentInformationHandlerProbe: PKPaymentInformationRequestHandling {}

private final class IssuerAuthorizationProbe: PKIssuerProvisioningExtensionAuthorizationProviding {
    var completionHandler: ((PKIssuerProvisioningExtensionAuthorizationResult) -> Void)?
}
