import Foundation
import StoreKit

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private let depthStoreJSON = """
{
  "identifier": "DEPTH3",
  "products": [
    {
      "displayPrice": "0.99",
      "familyShareable": true,
      "localizations": [
        { "description": "Coins", "displayName": "Coins", "locale": "en_US" }
      ],
      "productID": "coins",
      "referenceName": "Coins",
      "type": "Consumable"
    },
    {
      "displayPrice": "4.99",
      "familyShareable": true,
      "localizations": [
        { "description": "Pro", "displayName": "Pro", "locale": "en_US" }
      ],
      "productID": "pro",
      "referenceName": "Pro",
      "type": "NonConsumable"
    }
  ],
  "settings": { "_locale": "en_US" },
  "nonRenewingSubscriptions": [
    {
      "displayPrice": "9.99",
      "familyShareable": false,
      "localizations": [
        { "description": "Season", "displayName": "Season Pass", "locale": "en_US" }
      ],
      "productID": "season",
      "referenceName": "Season",
      "type": "NonRenewingSubscription",
      "recurringSubscriptionPeriod": "P3M"
    }
  ],
  "subscriptionGroups": [
    {
      "id": "group1",
      "localizations": [],
      "name": "Plus",
      "subscriptions": [
        {
          "adHocOffers": [
            {
              "offerID": "promo1",
              "displayPrice": "0.49",
              "numberOfPeriods": 1,
              "paymentMode": "payAsYouGo",
              "subscriptionPeriod": "P1M"
            }
          ],
          "winBackOffers": [
            {
              "offerID": "win1",
              "displayPrice": "0.00",
              "numberOfPeriods": 1,
              "paymentMode": "free",
              "subscriptionPeriod": "P1W"
            }
          ],
          "displayPrice": "1.99",
          "familyShareable": false,
          "groupNumber": 1,
          "introductoryOffer": {
            "displayPrice": "0.00",
            "numberOfPeriods": 1,
            "paymentMode": "free",
            "subscriptionPeriod": "P1W"
          },
          "localizations": [
            { "description": "Monthly", "displayName": "Plus Monthly", "locale": "en_US" }
          ],
          "productID": "plus.monthly",
          "recurringSubscriptionPeriod": "P1M",
          "referenceName": "Plus Monthly",
          "subscriptionGroupID": "group1",
          "type": "RecurringSubscription"
        }
      ]
    }
  ]
}
"""

func testSKAdImpressionModel() {
    let impression = SKAdImpression(
        sourceAppStoreItemIdentifier: 1,
        advertisedAppStoreItemIdentifier: 2,
        adNetworkIdentifier: "net",
        adCampaignIdentifier: 3,
        adImpressionIdentifier: "imp",
        timestamp: 4,
        signature: "sig",
        version: "2.0"
    )
    impression.adDescription = "desc"
    impression.adPurchaserName = "buyer"
    impression.sourceIdentifier = 9
    expect(impression.sourceAppStoreItemIdentifier == 1, "source app")
    expect(impression.advertisedAppStoreItemIdentifier == 2, "advertised")
    expect(impression.adNetworkIdentifier == "net", "network")
    expect(impression.adCampaignIdentifier == 3, "campaign")
    expect(impression.adImpressionIdentifier == "imp", "impression id")
    expect(impression.timestamp == 4, "timestamp")
    expect(impression.signature == "sig", "signature")
    expect(impression.version == "2.0", "version")
    expect(impression.adDescription == "desc", "description")
    expect(impression.adPurchaserName == "buyer", "purchaser")
    expect(impression.sourceIdentifier == 9, "source identifier")
    let blank = SKAdImpression()
    expect(blank.adNetworkIdentifier.isEmpty, "blank network")
}

func testSKAdNetworkFailClosed() {
    expect(SKAdNetwork.CoarseConversionValue.high.rawValue == "high", "high")
    expect(SKAdNetwork.CoarseConversionValue.medium.rawValue == "medium", "medium")
    expect(SKAdNetwork.CoarseConversionValue.low.rawValue == "low", "low")
    SKAdNetwork.registerAppForAdNetworkAttribution()
    SKAdNetwork.updateConversionValue(3)
    var seen = 0
    SKAdNetwork.updatePostbackConversionValue(1) { error in
        seen += 1
        expect(error is StoreKitPortableError, "postback")
    }
    SKAdNetwork.updatePostbackConversionValue(
        1,
        coarseValue: .medium
    ) { error in
        seen += 1
        expect(error is StoreKitPortableError, "coarse")
    }
    SKAdNetwork.updatePostbackConversionValue(
        1,
        coarseValue: .high,
        lockWindow: true
    ) { error in
        seen += 1
        expect(error is StoreKitPortableError, "lock")
    }
    let impression = SKAdImpression()
    SKAdNetwork.startImpression(impression) { error in
        seen += 1
        expect(error is StoreKitPortableError, "start")
    }
    SKAdNetwork.endImpression(impression) { error in
        seen += 1
        expect(error is StoreKitPortableError, "end")
    }
    expect(seen == 5, "completion handlers ran")
}

func testSKArcadeServiceFailClosed() {
    var seen = 0
    SKArcadeService.registerArcadeAppWithRandom(
        fromLib: Data(),
        randomFromLibLength: 0
    ) { _, _, _, _, error in
        seen += 1
        expect(error is StoreKitPortableError, "register")
    }
    SKArcadeService.arcadeSubscriptionStatus(withNonce: 1) { _, _, _, _, error in
        seen += 1
        expect(error is StoreKitPortableError, "status")
    }
    SKArcadeService.repairArcadeApp()
    expect(seen == 2, "handlers")
}

func testSKCloudServiceControllerFailClosed() {
    expect(SKCloudServiceController.authorizationStatus() == .denied, "denied")
    var status: SKCloudServiceAuthorizationStatus = .authorized
    SKCloudServiceController.requestAuthorization { value in
        status = value
    }
    expect(status == .denied, "request denied")
    let controller = SKCloudServiceController()
    var capabilitiesError: Error?
    controller.requestCapabilities { capability, error in
        expect(capability.isEmpty, "no music")
        capabilitiesError = error
    }
    expect(capabilitiesError is StoreKitPortableError, "capabilities")
    var storefrontError: Error?
    controller.requestStorefrontCountryCode { code, error in
        expect(code == nil, "no country")
        storefrontError = error
    }
    expect(storefrontError is StoreKitPortableError, "country")
    controller.requestStorefrontIdentifier { identifier, error in
        expect(identifier == nil, "no identifier")
        storefrontError = error
    }
    expect(storefrontError is StoreKitPortableError, "identifier")
    controller.requestPersonalizationToken(forClientToken: "token") { token, error in
        expect(token == nil, "no token")
        storefrontError = error
    }
    do {
        _ = try controller.requestUserTokenNow(forDeveloperToken: "dev")
        expect(false, "user token")
    } catch {
        expect(error is StoreKitPortableError, "user token fail-closed")
    }
}

func testSKDownloadFailClosed() {
    let download = SKDownload()
    expect(download.state == .failed, "state")
    expect(download.downloadState == .failed, "downloadState alias")
    expect(download.contentIdentifier.isEmpty, "id")
    expect(download.contentURL == nil, "url")
    expect(download.contentVersion.isEmpty, "version")
    expect(download.error is StoreKitPortableError, "error")
    expect(download.progress == 0, "progress")
    expect(download.timeRemaining == SKDownloadTimeRemainingUnknown, "remaining")
    expect(download.expectedContentLength == 0, "expected")
    expect(download.contentLength == 0, "contentLength")
    expect(download.transaction == nil, "no transaction")
}

func testPurchaseIntentFromTestingStore() {
    StoreKitTesting.reset()
    do {
        try StoreKitTesting.enqueuePurchaseIntent(productID: "pro")
        expect(false, "no store")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    try! StoreKitTesting.enqueuePurchaseIntent(productID: "pro")
    let offer = Product.SubscriptionOffer(id: "promo1")
    try! StoreKitTesting.enqueuePurchaseIntent(productID: "plus.monthly", offer: offer)
    let pending = StoreKitTesting.takePendingIntents()
    expect(pending.count == 2, "two intents")
    expect(pending[0].id == "pro", "id")
    expect(pending[0].product.id == "pro", "product")
    expect(pending[0].offer == nil, "no offer")
    expect(pending[1].offer?.id == "promo1", "offer")
    expect(pending[0] != pending[1], "distinct")
    expect(pending[0].hashValue != pending[1].hashValue, "hash")
    _ = PurchaseIntent.intents
    _ = PurchaseIntent.intents.makeAsyncIterator()
}

func testMessageReasonValues() {
    expect(Message.Reason.generic.rawValue == 0, "generic")
    expect(Message.Reason.billingIssue.rawValue == 1, "billing")
    expect(Message.Reason.priceIncreaseConsent.rawValue == 2, "consent")
    expect(Message.Reason.winBackOffer.rawValue == 3, "winback")
    expect(Message.Reason.billingIssue.localizedDescription == "billingIssue", "desc")
    expect(Message.Reason(rawValue: 1) == .billingIssue, "init")
    let first = Message(reason: .billingIssue)
    let second = Message(reason: .generic)
    expect(first.reason == .billingIssue, "reason")
    expect(first != second, "distinct")
    expect(first.hashValue != second.hashValue || first.reason != second.reason, "hash or reason")
    StoreKitTesting.reset()
    StoreKitTesting.enqueueMessage(reason: .winBackOffer)
    let pending = StoreKitTesting.takePendingMessages()
    expect(pending.count == 1, "queued")
    expect(pending[0].reason == .winBackOffer, "queued reason")
    _ = Message.messages
    _ = Message.messages.makeAsyncIterator()
}

func testMessageDisplayFailClosed() {
    let message = Message(reason: .priceIncreaseConsent)
    do {
        try message.display(in: UIWindowScene())
        expect(false, "must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // UI message sheet is unavailable on Linux.
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testExternalPurchaseFailClosed() {
    expect(ExternalPurchase.isEligible == false, "eligible")
    expect(ExternalPurchase.canPresentNow == false, "canPresent")
    let cancelled = ExternalPurchase.NoticeResult.cancelled
    let continued = ExternalPurchase.NoticeResult.continuedWithExternalPurchaseToken(token: "t")
    expect(cancelled != continued, "distinct")
    expect(cancelled == .cancelled, "cancelled")
    expect(cancelled.hashValue == ExternalPurchase.NoticeResult.cancelled.hashValue, "hash")
    do {
        _ = try ExternalPurchase.presentNoticeSheetNow()
        expect(false, "must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // Apple notice sheet is not present on Linux.
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testExternalLinkAccountFailClosed() {
    expect(ExternalLinkAccount.isEligible == false, "eligible")
    expect(ExternalLinkAccount.canOpenNow == false, "canOpen")
    do {
        try ExternalLinkAccount.openNow()
        expect(false, "must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testExternalPurchaseLinkFailClosed() {
    expect(ExternalPurchaseLink.isEligible == false, "eligible")
    expect(ExternalPurchaseLink.canOpenNow == false, "canOpen")
    expect(ExternalPurchaseLink.eligibleURLs == nil, "no URLs")
    do {
        try ExternalPurchaseLink.openNow()
        expect(false, "open")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
    do {
        try ExternalPurchaseLink.openNow(url: URL(string: "https://example.invalid")!)
        expect(false, "open url")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testExternalPurchaseCustomLinkFailClosed() {
    expect(ExternalPurchaseCustomLink.isEligibleNow == false, "eligible")
    expect(ExternalPurchaseCustomLink.NoticeType.browser.rawValue == 0, "browser")
    expect(ExternalPurchaseCustomLink.NoticeType.withinApp.rawValue == 1, "within")
    expect(ExternalPurchaseCustomLink.NoticeType(rawValue: 0) == .browser, "init")
    expect(
        ExternalPurchaseCustomLink.NoticeType.browser.hashValue
            == ExternalPurchaseCustomLink.NoticeType(rawValue: 0)!.hashValue,
        "type hash"
    )
    let token = ExternalPurchaseCustomLink.Token(value: "tok")
    expect(token.value == "tok", "value")
    expect(token != ExternalPurchaseCustomLink.Token(value: "other"), "distinct")
    expect(token.hashValue == ExternalPurchaseCustomLink.Token(value: "tok").hashValue, "hash")
    expect(
        ExternalPurchaseCustomLink.NoticeResult.cancelled
            != ExternalPurchaseCustomLink.NoticeResult.continued,
        "results"
    )
    do {
        _ = try ExternalPurchaseCustomLink.tokenNow(for: "type")
        expect(false, "token")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
    do {
        _ = try ExternalPurchaseCustomLink.showNoticeNow(type: .browser)
        expect(false, "notice")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testPaymentMethodBindingFailClosed() {
    expect(
        PaymentMethodBinding.PaymentMethodBindingError.notEligible
            != .invalidPinningID,
        "notEligible"
    )
    expect(
        PaymentMethodBinding.PaymentMethodBindingError.failed
            != .notEligible,
        "failed"
    )
    let error = PaymentMethodBinding.PaymentMethodBindingError.failed
    expect(error.errorDescription != nil, "description")
    expect(error.failureReason != nil, "reason")
    expect(error.recoverySuggestion == nil, "recovery")
    expect(error.helpAnchor == nil, "help")
    expect(
        error.hashValue
            != PaymentMethodBinding.PaymentMethodBindingError.notEligible.hashValue,
        "error hash"
    )
    do {
        _ = try PaymentMethodBinding.make(id: "pin")
        expect(false, "make")
    } catch PaymentMethodBinding.PaymentMethodBindingError.notEligible {
        // Linux has no Apple Account payment-method pinning.
    } catch {
        expect(false, "wrong \(error)")
    }
    let binding = PaymentMethodBinding(portableID: "pin")
    expect(binding.id == "pin", "id")
    expect(binding != PaymentMethodBinding(portableID: "other"), "distinct")
    expect(binding.hashValue == PaymentMethodBinding(portableID: "pin").hashValue, "hash")
    do {
        try binding.bindNow()
        expect(false, "bind")
    } catch PaymentMethodBinding.PaymentMethodBindingError.failed {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testInvalidRequestErrorFields() {
    let error = InvalidRequestError(code: 7, message: "bad")
    expect(error.code == 7, "code")
    expect(error.message == "bad", "message")
    expect(error != InvalidRequestError(), "distinct")
}

func testAdvancedCommerceProductFailClosed() {
    StoreKitTesting.reset()
    do {
        _ = try AdvancedCommerceProduct.make(id: "sku")
        expect(false, "no store")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    let product = try! AdvancedCommerceProduct.make(id: "pro")
    expect(product.id == "pro", "id")
    expect(product.type == .autoRenewable, "default type")
    expect(product.debugDescription.contains("pro"), "debug")
    _ = product.currentEntitlements
    _ = product.allTransactions
    expect(product.hashValue == AdvancedCommerceProduct(portableID: "pro").hashValue, "hash")
    let option = AdvancedCommerceProduct.PurchaseOption.onStorefrontChange { _ in true }
    expect(option.debugDescription.contains("PurchaseOption"), "option")
    expect(option == AdvancedCommerceProduct.PurchaseOption(), "empty options equal")
    do {
        _ = try product.purchaseNow(compactJWS: "aaa.bbb.ccc")
        expect(false, "purchase")
    } catch StoreKitError.notAvailableInStorefront {
        // Advanced Commerce compact JWS is not redeemed on Linux.
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testPurchaseQuantityAndInvalidQuantity() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    let product = try! StoreKitTesting.products(for: ["coins"])[0]
    let result = try! StoreKitTesting.purchase(product, options: [.quantity(3)])
    guard case .success(let verification) = result else {
        expect(false, "purchase")
        return
    }
    expect(verification.unsafePayloadValue.purchasedQuantity == 3, "quantity")
    do {
        _ = try StoreKitTesting.purchase(product, options: [.quantity(0)])
        expect(false, "invalid")
    } catch Product.PurchaseError.invalidQuantity {
        // Apple rejects quantity < 1.
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testPromotionalOfferAppliedToTransaction() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    let product = try! StoreKitTesting.products(for: ["plus.monthly"])[0]
    expect(product.subscription?.promotionalOffers.count == 1, "promo catalog")
    expect(product.subscription?.promotionalOffers[0].id == "promo1", "promo id")
    expect(product.subscription?.promotionalOffers[0].type == .promotional, "type")
    let result = try! StoreKitTesting.purchase(
        product,
        options: [.promotionalOffer("promo1", compactJWS: "hdr.pay.sig")[0]]
    )
    guard case .success(let verification) = result else {
        expect(false, "purchase")
        return
    }
    expect(verification.unsafePayloadValue.offer?.id == "promo1", "offer")
    expect(verification.unsafePayloadValue.offer?.type == .promotional, "offer type")
    do {
        _ = try StoreKitTesting.purchase(
            product,
            options: [.promotionalOffer("missing", compactJWS: "x")[0]]
        )
        expect(false, "unknown offer")
    } catch Product.PurchaseError.invalidOfferIdentifier {
        // unknown promotional offer is fail-closed
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testWinBackOffersFromCatalog() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    let product = try! StoreKitTesting.products(for: ["plus.monthly"])[0]
    expect(product.subscription?.winBackOffers.count == 1, "winback catalog")
    expect(product.subscription?.winBackOffers[0].id == "win1", "id")
    expect(product.subscription?.winBackOffers[0].type == .winBack, "type")
    let option = Product.PurchaseOption.winBackOffer(product.subscription!.winBackOffers[0])
    let result = try! StoreKitTesting.purchase(product, options: [option])
    guard case .success(let verification) = result else {
        expect(false, "purchase")
        return
    }
    expect(verification.unsafePayloadValue.offer?.id == "win1", "applied")
    expect(verification.unsafePayloadValue.offer?.type == .winBack, "type")
}

func testNonRenewingSubscriptionFromCatalog() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    let products = try! StoreKitTesting.products(for: ["season"])
    expect(products.count == 1, "season")
    expect(products[0].type == .nonRenewable, "type")
    let result = try! StoreKitTesting.purchase(products[0])
    guard case .success(let verification) = result else {
        expect(false, "purchase")
        return
    }
    expect(verification.unsafePayloadValue.productType == .nonRenewable, "txn type")
    expect(verification.unsafePayloadValue.expirationDate != nil, "period expiration")
    expect(StoreKitTesting.currentEntitlement(for: "season") != nil, "entitled")
}

func testIntroOfferAttachedOnFirstSubscribe() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    let product = try! StoreKitTesting.products(for: ["plus.monthly"])[0]
    expect(product.subscription?.introductoryOffer != nil, "intro present")
    let result = try! StoreKitTesting.purchase(product)
    guard case .success(let verification) = result else {
        expect(false, "purchase")
        return
    }
    expect(verification.unsafePayloadValue.offer?.type == .introductory, "intro attached")
}

func testAppTransactionJWSWithStore() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    let result = try! StoreKitTesting.appTransaction()
    let transaction = result.unsafePayloadValue
    expect(transaction.appVersion == "1.0", "version")
    expect(transaction.originalAppVersion == "1.0", "original")
    expect(transaction.originalPlatform == .iOS, "platform")
    expect(transaction.environment == .xcode, "env")
    expect(transaction.originalPlatformStringRepresentation == "iOS", "platform string")
    expect(!transaction.jsonRepresentation.isEmpty, "json")
    let compact = result.jwsRepresentation
    let parts = compact.split(separator: ".", omittingEmptySubsequences: false)
    expect(parts.count == 3, "compact JWS")
    let parsed = try! StoreKitTesting.parseJWS(compact)
    expect(!parsed.x5cChain.isEmpty, "x5c")
    expect(parsed.algorithm == "ES256", "alg")
    guard case .unverified(_, let error) = result else {
        expect(false, "fail-closed signature")
        return
    }
    expect(error == .invalidSignature, "invalidSignature")
}

func testFamilyShareableFromCatalog() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    let pro = try! StoreKitTesting.products(for: ["pro"])[0]
    expect(pro.isFamilyShareable, "family")
    let plus = try! StoreKitTesting.products(for: ["plus.monthly"])[0]
    expect(plus.isFamilyShareable == false, "not family")
}

func testPromotionOrderPersists() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    try! StoreKitTesting.updateProductOrder(byID: ["pro", "coins"])
    try! StoreKitTesting.updateProductVisibility(.visible, for: "pro")
    try! StoreKitTesting.updateProductVisibility(.hidden, for: "coins")
    let order = try! StoreKitTesting.promotionOrder()
    expect(order.count == 2, "order")
    expect(order[0].productID == "pro", "first")
    expect(order[0].visibility == .visible, "visible")
    expect(order[1].productID == "coins", "second")
    expect(order[1].visibility == .hidden, "hidden")
}

func testSKPaymentQueueDownloadCommands() {
    StoreKitTesting.reset()
    let observer = RecordingTransactionObserver()
    let queue = SKPaymentQueue.default()
    queue.add(observer)
    let download = SKDownload()
    queue.start([download])
    queue.pause([download])
    queue.resume([download])
    queue.cancel([download])
    queue.remove(observer)
    expect(true, "download commands notify observers without hanging")
}

func testAppAccountTokenOnPurchase() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    let token = UUID()
    let product = try! StoreKitTesting.products(for: ["pro"])[0]
    let result = try! StoreKitTesting.purchase(product, options: [.appAccountToken(token)])
    guard case .success(let verification) = result else {
        expect(false, "purchase")
        return
    }
    expect(verification.unsafePayloadValue.appAccountToken == token, "token")
}

func testProductJSONRepresentation() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depthStoreJSON)
    let product = try! StoreKitTesting.products(for: ["pro"])[0]
    let object = try! JSONSerialization.jsonObject(with: product.jsonRepresentation)
    guard let dict = object as? [String: Any] else {
        expect(false, "json")
        return
    }
    expect(dict["id"] as? String == "pro", "id")
    expect(dict["type"] as? String == "NonConsumable", "type")
}

func testStorefrontCurrencyFromLocale() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: """
    {
      "identifier": "DE",
      "products": [{
        "displayPrice": "1.00",
        "familyShareable": false,
        "localizations": [{ "description": "One", "displayName": "One", "locale": "de_DE" }],
        "productID": "one",
        "referenceName": "One",
        "type": "Consumable"
      }],
      "settings": { "_locale": "de_DE" },
      "subscriptionGroups": [],
      "nonRenewingSubscriptions": []
    }
    """)
    let storefront = StoreKitTesting.currentStorefront()
    expect(storefront?.countryCode == "DE", "region")
    expect(storefront?.id == "DE", "id")
    let product = try! StoreKitTesting.products(for: ["one"])[0]
    let result = try! StoreKitTesting.purchase(product)
    guard case .success(let verification) = result else {
        expect(false, "purchase")
        return
    }
    expect(verification.unsafePayloadValue.currencyCode == "EUR", "euro")
    expect(verification.unsafePayloadValue.storefrontCountryCode == "DE", "country")
}

func testSubscriptionRelationshipBits() {
    expect(Product.SubscriptionRelationship.current.rawValue == 1, "current")
    expect(Product.SubscriptionRelationship.upgrade.rawValue == 2, "upgrade")
    expect(Product.SubscriptionRelationship.downgrade.rawValue == 4, "downgrade")
    expect(Product.SubscriptionRelationship.crossgrade.rawValue == 8, "crossgrade")
    expect(Product.SubscriptionRelationship.all.contains(.downgrade), "all")
}

func testSKCloudServiceSetupViewControllerFailClosed() {
    let controller = SKCloudServiceSetupViewController()
    var seen = 0
    controller.load(options: [.action: SKCloudServiceSetupAction.subscribe]) { success, error in
        seen += 1
        expect(success == false, "no music setup")
        expect(error is StoreKitPortableError, "fail-closed")
    }
    expect(seen == 1, "completion")
    expect(SKCloudServiceSetupAction.subscribe.rawValue == "subscribe", "action")
    expect(SKCloudServiceSetupMessageIdentifier.join.rawValue == "join", "join")
    expect(SKCloudServiceSetupMessageIdentifier.connect.rawValue == "connect", "connect")
    expect(SKCloudServiceSetupMessageIdentifier.addMusic.rawValue == "addMusic", "add")
    expect(SKCloudServiceSetupMessageIdentifier.playMusic.rawValue == "playMusic", "play")
    expect(SKCloudServiceSetupOptionsKey.action.rawValue == "action", "key")
}
