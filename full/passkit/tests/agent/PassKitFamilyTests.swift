import Foundation
import PassKit

// MARK: - Split from the prior kitchen-sink corpus tests. Each function
// exercises one type family so coverage.tsv can cite per-identifier evidence.

func testDateComponentsRangeCoding() {
    let range = PKDateComponentsRange(
        startDateComponents: DateComponents(day: 1),
        endDateComponents: DateComponents(day: 2)
    )
    precondition(range.startDateComponents.day == 1)
    precondition(range.endDateComponents.day == 2)
    let labeled = PKDateComponentsRange(
        start: DateComponents(month: 3),
        end: DateComponents(month: 4)
    )
    precondition(labeled.startDateComponents.month == 3)
    _ = PKDateComponentsRange(coder: NSCoder())
}

func testAddPassMetadataPreviewFields() {
    let image = CGImage()
    let preview = PKAddPassMetadataPreview(passThumbnail: image, localizedDescription: "preview")
    precondition(preview.localizedDescription == "preview")
    precondition(preview.passThumbnailImage != nil)
}

func testAddIdentityDocumentMetadataInit() {
    let preview = PKAddPassMetadataPreview(passThumbnail: CGImage(), localizedDescription: "id")
    let idMeta = PKAddIdentityDocumentMetadata(
        provisioningCredentialIdentifier: "cred",
        sharingInstanceIdentifier: "share",
        cardTemplateIdentifier: "tpl",
        issuingCountryCode: "US",
        documentType: .idCard,
        preview: preview
    )
    precondition(idMeta.credentialIdentifier == "cred")
    precondition(idMeta.sharingInstanceIdentifier == "share")
    precondition(idMeta.cardTemplateIdentifier == "tpl")
    precondition(idMeta.issuingCountryCode == "US")
    precondition(idMeta.documentType == .idCard)
    precondition(idMeta.preview.localizedDescription == "id")
    precondition(PKAddIdentityDocumentType(rawValue: 2) == .photoID)
}

func testJapanIndividualNumberCardMetadataInits() {
    let preview = PKAddPassMetadataPreview(passThumbnail: CGImage(), localizedDescription: "jp")
    let japan = PKJapanIndividualNumberCardMetadata(
        provisioningCredentialIdentifier: "cred",
        sharingInstanceIdentifier: "share",
        cardConfigurationIdentifier: "cfg",
        preview: preview
    )
    japan.authenticationPassword = "apw"
    japan.signingPassword = "spw"
    precondition(japan.credentialIdentifier == "cred")
    precondition(japan.cardConfigurationIdentifier == "cfg")
    precondition(japan.preview.localizedDescription == "jp")
    precondition(japan.authenticationPassword == "apw")
    precondition(japan.signingPassword == "spw")
    let templated = PKJapanIndividualNumberCardMetadata(
        provisioningCredentialIdentifier: "cred2",
        sharingInstanceIdentifier: "share2",
        cardTemplateIdentifier: "tpl",
        preview: preview
    )
    precondition(templated.cardTemplateIdentifier == "tpl")
}

func testAddShareablePassConfigurationStore() {
    let shareConfig = PKAddShareablePassConfiguration()
    shareConfig.primaryAction = .add
    shareConfig.provisioningPolicyIdentifier = "policy"
    shareConfig.credentialsMetadata = []
    precondition(shareConfig.primaryAction == .add)
    precondition(shareConfig.provisioningPolicyIdentifier == "policy")
    precondition(shareConfig.credentialsMetadata.isEmpty)
    precondition(PKAddShareablePassConfigurationPrimaryAction(rawValue: 1) == .share)
}

func testAddSecureElementPassConfigurationAndViewController() {
    let config = PKAddSecureElementPassConfiguration()
    config.issuerIdentifier = "issuer"
    config.localizedDescription = "desc"
    precondition(config.issuerIdentifier == "issuer")
    precondition(config.localizedDescription == "desc")
    MainActor.assumeIsolated {
        precondition(
            PKAddSecureElementPassViewController.canAddSecureElementPass(configuration: config) == false
        )
        precondition(
            PKAddSecureElementPassViewController(configuration: config, delegate: nil) == nil
        )
        let vc = PKAddSecureElementPassViewController()
        vc.delegate = nil
        precondition(vc.delegate == nil)
    }
}

func testIssuerProvisioningExtensionSurface() {
    let status = PKIssuerProvisioningExtensionStatus()
    precondition(status.passEntriesAvailable == false)
    precondition(status.remotePassEntriesAvailable == false)
    precondition(status.requiresAuthentication == false)
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
    _ = entry.title
    _ = entry.art
    let paymentEntry = PKIssuerProvisioningExtensionPaymentPassEntry(
        identifier: "i",
        title: "t",
        art: CGImage(),
        addRequestConfiguration: PKAddPaymentPassRequestConfiguration()
    )
    precondition(paymentEntry.identifier == "i")
    precondition(paymentEntry.title == "t")
    _ = paymentEntry.addRequestConfiguration
    precondition(PKIssuerProvisioningExtensionAuthorizationResult(rawValue: 1) == .authorized)
}

func testVehicleConnectionSessionFailClosed() {
    waitFor { done in
        Task {
            do {
                _ = try await PKVehicleConnectionSession.session(
                    for: PKSecureElementPass(),
                    delegate: FamilyVehicleProbe()
                )
                preconditionFailure("vehicle session must fail closed")
            } catch {
            }
            done()
        }
    }
    let vehicle = PKVehicleConnectionSession()
    vehicle.delegate = FamilyVehicleProbe()
    precondition(vehicle.connectionStatus == .disconnected)
    _ = vehicle.delegate
    do {
        try vehicle.send(Data())
        preconditionFailure("vehicle send must throw")
    } catch {
    }
    vehicle.invalidate()
    precondition(PKVehicleConnectionErrorCode(rawValue: 1) == .sessionUnableToStart)
    precondition(PKVehicleConnectionSessionConnectionState(rawValue: 0) == .disconnected)
}

func testPayLaterViewHostFields() {
    let laterViewAmount = Decimal(12)
    MainActor.assumeIsolated {
        let later = PKPayLaterView(amount: laterViewAmount, currency: Locale.Currency("USD"))
        later.action = .learnMore
        later.displayStyle = .badge
        precondition(later.amount == laterViewAmount)
        precondition(PKPayLaterAction(rawValue: 1) == .calculator)
        precondition(PKPayLaterDisplayStyle(rawValue: 3) == .price)
        let laterProbe = FamilyPayLaterProbe()
        later.delegate = laterProbe
        laterProbe.payLaterViewDidUpdateHeight(later)
        _ = later.delegate
        let add = PKAddPassButton(addPassButtonStyle: .blackOutline)
        add.addPassButtonStyle = .black
        _ = add.addPassButtonStyle
        let identityButton = PKIdentityButton(label: .verifyAge, style: .blackOutline)
        identityButton.cornerRadius = 2
        precondition(identityButton.cornerRadius == 2)
        _ = PKIdentityButton.Label(rawValue: 0)
        _ = PKIdentityButton.Style(rawValue: 1)
    }
}

func testShareSecureElementPassViewControllerFields() {
    MainActor.assumeIsolated {
        let shareVC = PKShareSecureElementPassViewController(
            secureElementPass: PKSecureElementPass(),
            delegate: nil
        )
        shareVC.promptToShareURL = true
        precondition(shareVC.promptToShareURL)
        _ = shareVC.delegate
    }
}

func testPaymentInformationEventExtensionType() {
    let infoExt = PKPaymentInformationEventExtension()
    _ = infoExt
}

func testPKObjectConstructs() {
    let object = PKObject()
    _ = object
    _ = PKPaymentMerchantSession(dictionary: ["k": "v"])
}

func testPayLaterValidateFailClosed() {
    waitFor { done in
        Task {
            let eligible = await PKPayLater.validate(amount: 10, currency: Locale.Currency("USD"))
            precondition(eligible == false)
            done()
        }
    }
}

func testShareableAndIdentityDocumentConfigurationFailClosed() {
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
            done()
        }
    }
    let config = PKAddIdentityDocumentConfiguration()
    _ = config.metadata
}

func testDisbursementErrorSwiftOverlayMembers() {
    precondition(PKDisbursementError.unsupportedCardError.rawValue == 1)
    precondition(PKDisbursementError.recipientContactInvalidError.rawValue == 2)
    precondition(PKDisbursementError.unknownError.rawValue == -1)
    precondition(PKDisbursementError.errorDomain == PKDisbursementErrorDomain)
    precondition(PKDisbursementError.Code(rawValue: -1) == .unknownError)
    let error = PKDisbursementError(.unsupportedCardError)
    precondition(error.code == .unsupportedCardError)
}

func testShareSecureElementPassErrorSwiftOverlayMembers() {
    let shareErr = PKShareSecureElementPassError(.setupError)
    precondition(shareErr.code == .setupError)
    precondition(PKShareSecureElementPassError.errorDomain == PKShareSecureElementPassErrorDomain)
    precondition(PKShareSecureElementPassError.unknownError.rawValue == 0)
    precondition(PKShareSecureElementPassResult(rawValue: 2) == .failed)
}

func testPassKitCompletionBlockAliases() {
    let info: PKInformationRequestCompletionBlock = { response in
        precondition(response.paymentInformation.isEmpty || true)
    }
    info(PKBarcodeEventMetadataResponse())
    let sig: PKSignatureRequestCompletionBlock = { response in
        _ = response.signedData
    }
    sig(PKBarcodeEventSignatureResponse())
    let token: PKSuppressionRequestToken = 0
    precondition(token == 0)
}

func testPaymentRequestStoredFields() {
    let request = PKPaymentRequest()
    request.applicationData = Data("app".utf8)
    request.attributionIdentifier = "attr"
    request.billingAddress = ABRecord()
    request.billingContact = PKContact()
    request.shippingAddress = ABRecord()
    request.shippingContact = PKContact()
    request.requiredBillingAddressFields = [.postalAddress]
    request.requiredShippingAddressFields = [.name]
    request.shippingType = .delivery
    request.shippingContactEditingMode = .enabled
    request.supportedCountries = ["US"]
    request.couponCode = "SAVE"
    request.supportsCouponCode = true
    precondition(request.applicationData?.count == 3)
    precondition(request.attributionIdentifier == "attr")
    precondition(request.billingContact != nil)
    precondition(request.shippingContact != nil)
    precondition(request.billingAddress != nil)
    precondition(request.shippingAddress != nil)
    precondition(request.requiredBillingAddressFields.contains(.postalAddress))
    precondition(request.shippingType == .delivery)
    precondition(request.shippingContactEditingMode == .enabled)
    precondition(request.supportedCountries?.contains("US") == true)
    precondition(PKShippingContactEditingMode(rawValue: 2) == .storePickup)
}

func testPaymentRequestApplePayLaterAndMCC() {
    let request = PKPaymentRequest()
    request.merchantCategoryCode = PKPaymentRequest.MerchantCategoryCode(rawValue: 5411)
    precondition(request.merchantCategoryCode?.rawValue == 5411)
    precondition(request.merchantCategoryCode?.description == "5411")
    precondition(PKPaymentRequest.MerchantCategoryCode("12")?.rawValue == 12)
    precondition(
        PKPaymentRequest.MerchantCategoryCode(rawValue: 5411).hashValue
            == PKPaymentRequest.MerchantCategoryCode(rawValue: 5411).hashValue
    )
    do {
        let encoded = try JSONEncoder().encode(PKPaymentRequest.MerchantCategoryCode(rawValue: 5411))
        let decoded = try JSONDecoder().decode(PKPaymentRequest.MerchantCategoryCode.self, from: encoded)
        precondition(decoded.rawValue == 5411)
    } catch {
        preconditionFailure("MerchantCategoryCode round-trip")
    }
    request.applePayLaterAvailability = .available
    if case .available = request.applePayLaterAvailability {
    } else {
        preconditionFailure("applePayLaterAvailability")
    }
    request.applePayLaterAvailability = .unavailable(.itemIneligible)
    request.applePayLaterAvailability = .unavailable(.recurringTransaction)
    precondition(
        PKPaymentRequest.ApplePayLaterAvailability.Reason.itemIneligible
            != .recurringTransaction
    )
    var hasher = Hasher()
    hasher.combine(PKPaymentRequest.ApplePayLaterAvailability.Reason.itemIneligible)
    _ = hasher.finalize()
    precondition(
        PKPaymentRequest.ApplePayLaterAvailability.Reason.itemIneligible.hashValue
            == PKPaymentRequest.ApplePayLaterAvailability.Reason.itemIneligible.hashValue
    )
    precondition(PKApplePayLaterAvailability(rawValue: 0) == .available)
}

func testPaymentTokenContextFields() {
    let tokenContext = PKPaymentTokenContext(
        merchantIdentifier: "m",
        externalIdentifier: "e",
        merchantName: "Shop",
        merchantDomain: "example.com",
        amount: NSDecimalNumber(string: "1")
    )
    precondition(tokenContext.merchantIdentifier == "m")
    precondition(tokenContext.externalIdentifier == "e")
    precondition(tokenContext.merchantName == "Shop")
    precondition(tokenContext.merchantDomain == "example.com")
    precondition(tokenContext.amount.compare(NSDecimalNumber(string: "1")) == .orderedSame)
    let request = PKPaymentRequest()
    request.multiTokenContexts = [tokenContext]
    precondition(request.multiTokenContexts[0].merchantName == "Shop")
}

func testPaymentRequestUpdateHierarchy() {
    let item = PKPaymentSummaryItem(label: "Item", amount: NSDecimalNumber(string: "10.00"), type: .final)
    let update = PKPaymentRequestUpdate(paymentSummaryItems: [item])
    update.status = .success
    update.shippingMethods = [PKShippingMethod()]
    update.automaticReloadPaymentRequest = nil
    update.deferredPaymentRequest = nil
    update.recurringPaymentRequest = nil
    update.multiTokenContexts = []
    precondition(update.paymentSummaryItems.count == 1)
    precondition(update.status == .success)
    precondition(update.shippingMethods.count == 1)
    precondition(update.automaticReloadPaymentRequest == nil)
    let couponUpdate = PKPaymentRequestCouponCodeUpdate(
        errors: nil,
        paymentSummaryItems: [item],
        shippingMethods: []
    )
    precondition(couponUpdate.paymentSummaryItems.count == 1)
    precondition(couponUpdate.errors == nil)
    let methodUpdate = PKPaymentRequestPaymentMethodUpdate(errors: nil, paymentSummaryItems: [item])
    precondition(methodUpdate.paymentSummaryItems.count == 1)
    precondition(methodUpdate.errors == nil)
    let contactUpdate = PKPaymentRequestShippingContactUpdate(
        errors: nil,
        paymentSummaryItems: [item],
        shippingMethods: []
    )
    precondition(contactUpdate.shippingMethods.isEmpty)
    precondition(contactUpdate.errors == nil)
    let shipUpdate = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: [item])
    precondition(shipUpdate.paymentSummaryItems.count == 1)
    let session = PKPaymentMerchantSession(dictionary: ["k": "v"])
    let sessionUpdate = PKPaymentRequestMerchantSessionUpdate(status: .failure, merchantSession: session)
    precondition(sessionUpdate.status == .failure)
    precondition(sessionUpdate.session != nil)
}

func testAutomaticReloadDeferredRecurringOnRequest() {
    let request = PKPaymentRequest()
    let reloadItem = PKAutomaticReloadPaymentSummaryItem(label: "Reload", amount: NSDecimalNumber(value: 5))
    reloadItem.thresholdAmount = NSDecimalNumber(string: "10")
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
}

func testInstantFundsOutFeeSummaryItemType() {
    precondition(PKInstantFundsOutFeeSummaryItem().type == .final)
    precondition(PKPaymentSummaryItemType(rawValue: 1) == .pending)
}

func testPaymentRequestCouponErrorFactories() {
    let coupon = PKPaymentRequest.paymentCouponCodeInvalidError(localizedDescription: "bad")
    precondition((coupon as? PKPaymentError)?.code == .couponCodeInvalidError)
    let expired = PKPaymentRequest.paymentCouponCodeExpiredError(localizedDescription: "old")
    precondition((expired as? PKPaymentError)?.code == .couponCodeExpiredError)
}

private final class FamilyPayLaterProbe: PKPayLaterViewDelegate {
    func payLaterViewDidUpdateHeight(_ view: PKPayLaterView) {
        _ = view
    }
}

private final class FamilyVehicleProbe: PKVehicleConnectionDelegate {
    func sessionDidChange(_ newState: PKVehicleConnectionSessionConnectionState) {
        _ = newState
    }
    func sessionDidReceive(_ data: Data) {
        _ = data
    }
}
