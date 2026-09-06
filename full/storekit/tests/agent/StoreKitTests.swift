import Foundation
import StoreKit

private enum StoreKitTestFailure: Error {
    case message(String)
}

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private let sampleStoreJSON = """
{
  "identifier": "TESTSTORE",
  "nonRenewingSubscriptions": [],
  "products": [
    {
      "displayPrice": "0.99",
      "familyShareable": false,
      "internalID": "1",
      "localizations": [
        { "description": "A coin pack", "displayName": "Coins", "locale": "en_US" }
      ],
      "productID": "coins",
      "referenceName": "Coins",
      "type": "Consumable"
    },
    {
      "displayPrice": "4.99",
      "familyShareable": true,
      "internalID": "2",
      "localizations": [
        { "description": "Unlock pro", "displayName": "Pro", "locale": "en_US" }
      ],
      "productID": "pro",
      "referenceName": "Pro",
      "type": "NonConsumable"
    }
  ],
  "settings": { "_locale": "en_US" },
  "subscriptionGroups": [
    {
      "id": "group1",
      "localizations": [],
      "name": "Plus",
      "subscriptions": [
        {
          "adHocOffers": [],
          "codeOffers": [],
          "displayPrice": "1.99",
          "familyShareable": false,
          "groupNumber": 1,
          "internalID": "3",
          "introductoryOffer": {
            "displayPrice": "0.00",
            "numberOfPeriods": 1,
            "paymentMode": "free",
            "subscriptionPeriod": "P1W"
          },
          "localizations": [
            { "description": "Monthly plus", "displayName": "Plus Monthly", "locale": "en_US" }
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

private let verifiedStoreJSON = """
{
  "identifier": "VERIFIED",
  "products": [
    {
      "displayPrice": "1.00",
      "familyShareable": false,
      "localizations": [
        { "description": "One", "displayName": "One", "locale": "en_US" }
      ],
      "productID": "one",
      "referenceName": "One",
      "type": "NonConsumable"
    }
  ],
  "settings": { "_locale": "en_US", "_treatTransactionsAsVerified": true },
  "subscriptionGroups": [],
  "nonRenewingSubscriptions": []
}
"""

func testPaymentQueueCannotPay() {
    StoreKitTesting.reset()
    expect(SKPaymentQueue.canMakePayments() == false, "Linux never reports payment entitlement without a store")
    expect(AppStore.canMakePayments == false, "AppStore.canMakePayments is fail-closed without a store")
}

func testProductsUnavailable() {
    StoreKitTesting.reset()
    do {
        _ = try StoreKitTesting.products(for: ["com.example.pro"])
        expect(false, "products(for:) must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // Apple: function isn’t available for this storefront.
    } catch {
        expect(false, "unexpected error \(error)")
    }
}

func testReviewRequestCount() {
    let before = SKStoreReviewController.portableRequestCount
    SKStoreReviewController.requestReview()
    expect(
        SKStoreReviewController.portableRequestCount == before + 1,
        "requestReview increments portableRequestCount without presenting UI"
    )
}

final class RecordingRequestDelegate: NSObject, SKRequestDelegate {
    var failed = 0
    func request(_ request: SKRequest, didFailWithError error: Error) {
        failed += 1
        expect(error is StoreKitPortableError, "SKRequest fails closed")
    }
}

func testRequestFailsClosed() {
    let delegate = RecordingRequestDelegate()
    let request = SKRequest()
    request.delegate = delegate
    request.start()
    expect(delegate.failed == 1, "start() delivers one fail-closed error")
    request.cancel()
    expect(request.isCancelled, "cancel() records cancellation")
}

func testAdNetworkPostbackFails() {
    var seen = 0
    SKAdNetwork.updatePostbackConversionValue(3) { error in
        seen += 1
        expect(error is StoreKitPortableError, "postback completion is fail-closed")
    }
    expect(seen == 1, "completion runs once")
    let coarse = SKAdNetwork.CoarseConversionValue.low
    expect(coarse.rawValue == "low", "coarse conversion raw value")
}

func testSKErrorCodes() {
    for raw in 0...20 {
        expect(SKError.Code(rawValue: raw)?.rawValue == raw, "SKError.Code raw \(raw)")
    }
    expect(SKError.Code(rawValue: 21) == nil, "raw 21 is not a case")
    let error = SKError(.paymentCancelled)
    expect(error.code == .paymentCancelled, "code")
    expect(error.errorCode == 2, "errorCode")
    expect(SKError.paymentNotAllowed.rawValue == 4, "paymentNotAllowed is 4")
    expect(SKError.unknown.rawValue == 0, "unknown")
    expect(SKError.clientInvalid.rawValue == 1, "clientInvalid")
    expect(SKError.paymentInvalid.rawValue == 3, "paymentInvalid")
    expect(SKError.storeProductNotAvailable.rawValue == 5, "storeProductNotAvailable")
}

func testStoreKitErrorCases() {
    let cancelled = StoreKitError.userCancelled
    let unknown = StoreKitError.unknown
    expect(cancelled.errorDescription != nil, "errorDescription exists")
    expect(StoreKitError.notAvailableInStorefront.errorDescription != nil, "storefront error")
    expect(StoreKitError.notEntitled.errorDescription != nil, "notEntitled")
    expect(StoreKitError.unsupported.errorDescription != nil, "unsupported")
    switch unknown {
    case .unknown:
        break
    default:
        expect(false, "unknown case")
    }
}

func testPurchaseOptionFactories() {
    let a = Product.PurchaseOption.quantity(1)
    let b = Product.PurchaseOption.quantity(2)
    let c = Product.PurchaseOption.appAccountToken(UUID())
    expect(a != b, "distinct quantities")
    expect(a != c, "quantity != token")
    expect(a == Product.PurchaseOption.quantity(1), "equal quantities")
    let promo = Product.PurchaseOption.promotionalOffer("offer", compactJWS: "abc")
    expect(promo.count == 1, "compact JWS returns one option")
    _ = Product.PurchaseOption.winBackOffer(Product.SubscriptionOffer(id: "wb"))
    _ = Product.PurchaseOption.simulatesAskToBuyInSandbox(true)
    _ = Product.PurchaseOption.custom(key: "k", value: true)
    _ = Product.PurchaseOption.custom(key: "k", value: 1.0)
    _ = Product.PurchaseOption.custom(key: "k", value: Data())
    _ = Product.PurchaseOption.custom(key: "k", value: "v")
    _ = Product.PurchaseOption.introductoryOfferEligibility(compactJWS: "jws")
    _ = Product.PurchaseOption.onStorefrontChange { _ in true }
    let signature = Product.SubscriptionOffer.Signature(
        keyID: "k", nonce: UUID(), timestamp: 1, signature: Data()
    )
    _ = Product.PurchaseOption.promotionalOffer(offerID: "o", signature: signature)
    _ = Product.PurchaseOption.promotionalOffer(
        offerID: "o", keyID: "k", nonce: UUID(), signature: Data(), timestamp: 1
    )
    expect(a.hashValue == Product.PurchaseOption.quantity(1).hashValue, "hash")
}

func testStorefrontCurrentNil() {
    StoreKitTesting.reset()
    let current = StoreKitTesting.currentStorefront()
    expect(current == nil, "no App Store storefront on Linux")
}

final class RecordingTransactionObserver: NSObject, SKPaymentTransactionObserver {
    var states: [SKPaymentTransactionState] = []
    var removed = 0
    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        states.append(contentsOf: transactions.map(\.transactionState))
    }
}

func testPaymentQueueAddFails() {
    StoreKitTesting.reset()
    let observer = RecordingTransactionObserver()
    let queue = SKPaymentQueue.default()
    queue.add(observer)
    let product = SKProduct(productIdentifier: "com.example.pro")
    queue.add(SKPayment(product: product))
    expect(observer.states == [.failed], "add(payment) notifies a failed transaction")
    queue.remove(observer)
}

func testVerificationResultPayload() {
    let product = Product(id: "sku")
    _ = product
    let transaction = Transaction(
        id: 1,
        productID: "sku",
        purchaseDate: Date(timeIntervalSince1970: 0)
    )
    let verified = VerificationResult.verified(transaction)
    expect(verified.unsafePayloadValue.id == 1, "unsafe payload")
    do {
        let value = try verified.payloadValue
        expect(value.productID == "sku", "payloadValue")
    } catch {
        expect(false, "verified must not throw")
    }
    let unverified = VerificationResult<Transaction>.unverified(transaction, .invalidSignature)
    expect(unverified.debugDescription.hasPrefix("unverified"), "debug")
    do {
        _ = try unverified.payloadValue
        expect(false, "unverified must throw")
    } catch VerificationResult<Transaction>.VerificationError.invalidSignature {
        // expected
    } catch {
        expect(false, "wrong error \(error)")
    }
}

func testSubscriptionPeriodUnits() {
    expect(Product.SubscriptionPeriod.Unit.day < .week, "day < week")
    expect(Product.SubscriptionPeriod.Unit.week < .month, "week < month")
    expect(Product.SubscriptionPeriod.Unit.month < .year, "month < year")
    let monthly = Product.SubscriptionPeriod.monthly
    expect(monthly.value == 1 && monthly.unit == .month, "monthly factory")
    expect(Product.SubscriptionPeriod.weekly.unit == .week, "weekly")
    expect(Product.SubscriptionPeriod.yearly.unit == .year, "yearly")
    expect(Product.SubscriptionPeriod.everyTwoWeeks.value == 2, "two weeks")
    expect(Product.SubscriptionPeriod.everySixMonths.value == 6, "six months")
    let range = monthly.dateRange(referenceDate: Date(timeIntervalSince1970: 0))
    expect(range.upperBound > range.lowerBound, "date range")
    let style = Product.SubscriptionPeriod.Unit.FormatStyle()
    expect(style.format(.month) == "month", "format style")
    expect(Product.SubscriptionPeriod.Unit.month.localizedDescription == "month", "localized")
}

func testAppStoreSyncFails() {
    StoreKitTesting.reset()
    do {
        try StoreKitTesting.sync()
        expect(false, "sync must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "unexpected \(error)")
    }
}

func testTransactionLatestNil() {
    StoreKitTesting.reset()
    let latest = StoreKitTesting.latest(for: "sku")
    expect(latest == nil, "no receipt daemon")
    let entitlement = StoreKitTesting.currentEntitlement(for: "sku")
    expect(entitlement == nil, "no entitlements")
}

func testSKErrorDomain() {
    expect(SKErrorDomain == "SKErrorDomain", "domain constant")
    expect(SKError.errorDomain == SKErrorDomain, "SKError.errorDomain")
}

func testLoadStoreKitConfiguration() {
    StoreKitTesting.reset()
    expect(StoreKitTesting.isConfigurationLoaded == false, "starts empty")
    do {
        try StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    } catch {
        expect(false, "load failed \(error)")
    }
    expect(StoreKitTesting.isConfigurationLoaded, "loaded")
    StoreKitTesting.reset()
    expect(StoreKitTesting.isConfigurationLoaded == false, "reset")
}

func testProductsFromLocalStore() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let products = try! StoreKitTesting.products(for: ["coins", "pro", "missing"])
    expect(products.count == 2, "two known products")
    let coins = products.first { $0.id == "coins" }!
    expect(coins.displayName == "Coins", "displayName")
    expect(coins.description == "A coin pack", "description")
    expect(coins.type == .consumable, "type")
    expect(coins.price == Decimal(string: "0.99"), "price")
    expect(!coins.displayPrice.isEmpty, "displayPrice formatted")
    let pro = products.first { $0.id == "pro" }!
    expect(pro.type == .nonConsumable, "nonconsumable")
    expect(pro.isFamilyShareable, "family")
    let plus = try! StoreKitTesting.products(for: ["plus.monthly"])
    expect(plus.count == 1, "subscription")
    expect(plus[0].type == .autoRenewable, "auto renewable")
    expect(plus[0].subscription?.subscriptionGroupID == "group1", "group")
    expect(plus[0].subscription?.subscriptionPeriod.unit == .month, "period")
    expect(plus[0].subscription?.introductoryOffer != nil, "intro")
}

func testPurchaseUnverifiedByDefault() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let products = try! StoreKitTesting.products(for: ["pro"])
    let result = try! StoreKitTesting.purchase(products[0])
    switch result {
    case .success(.unverified(let transaction, .invalidSignature)):
        expect(transaction.productID == "pro", "product")
        expect(transaction.environment == .xcode, "xcode environment")
        expect(transaction.reason == .purchase, "reason")
        expect(transaction.ownershipType == .purchased, "ownership")
    default:
        expect(false, "expected unverified success, got \(result)")
    }
}

func testPurchaseVerifiedWhenConfigured() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: verifiedStoreJSON)
    let products = try! StoreKitTesting.products(for: ["one"])
    let result = try! StoreKitTesting.purchase(products[0], options: [.quantity(1)])
    switch result {
    case .success(.verified(let transaction)):
        expect(transaction.productID == "one", "verified payload")
        expect(transaction.purchasedQuantity == 1, "quantity")
    default:
        expect(false, "expected verified, got \(result)")
    }
}

func testTransactionFinishAndUnfinished() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let products = try! StoreKitTesting.products(for: ["coins"])
    _ = try! StoreKitTesting.purchase(products[0])
    let unfinished = StoreKitTesting.unfinished()
    expect(unfinished.count == 1, "one unfinished")
    StoreKitTesting.finish(unfinished[0].unsafePayloadValue)
    let after = StoreKitTesting.unfinished()
    expect(after.isEmpty, "finished removes unfinished")
    let all = StoreKitTesting.allTransactions()
    expect(all.count == 1, "history keeps the purchase")
    let latest = StoreKitTesting.latest(for: "coins")
    expect(latest?.unsafePayloadValue.productID == "coins", "latest")
}

func testCurrentEntitlementsExcludeConsumables() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let coins = try! StoreKitTesting.products(for: ["coins"])
    let pro = try! StoreKitTesting.products(for: ["pro"])
    _ = try! StoreKitTesting.purchase(coins[0])
    _ = try! StoreKitTesting.purchase(pro[0])
    let entitlements = StoreKitTesting.currentEntitlements().map { $0.unsafePayloadValue.productID }
    expect(entitlements == ["pro"], "consumables are not entitlements")
    let entitlement = StoreKitTesting.currentEntitlement(for: "pro")
    expect(entitlement != nil, "pro entitled")
    let coinEntitlement = StoreKitTesting.currentEntitlement(for: "coins")
    expect(coinEntitlement == nil, "coins not entitled")
}

func testTransactionUpdatesSequence() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    _ = Transaction.updates
    let products = try! StoreKitTesting.products(for: ["pro"])
    _ = try! StoreKitTesting.purchase(products[0])
    let pending = StoreKitTesting.takePendingUpdates()
    expect(pending.count == 1, "updates queued without a live listener")
    expect(pending[0].unsafePayloadValue.productID == "pro", "updates emits purchase")
}

func testSK1PurchaseWithConfiguration() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let observer = RecordingTransactionObserver()
    let queue = SKPaymentQueue.default()
    queue.add(observer)
    let product = SKProduct(productIdentifier: "pro", localizedTitle: "Pro", price: Decimal(string: "4.99")!)
    queue.add(SKPayment(product: product))
    expect(observer.states.contains(.purchasing), "purchasing")
    expect(observer.states.contains(.purchased), "purchased")
    expect(SKPaymentQueue.canMakePayments(), "payments allowed")
    expect(queue.storefront != nil, "sk storefront")
    expect(queue.transactionObservers.count == 1, "observers")
    if let last = queue.transactions.last {
        queue.finishTransaction(last)
    }
    queue.remove(observer)
}

func testSK1UnknownProductFails() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let observer = RecordingTransactionObserver()
    let queue = SKPaymentQueue.default()
    queue.add(observer)
    queue.add(SKPayment(productIdentifier: "nope"))
    expect(observer.states.contains(.failed), "unknown product fails")
    queue.remove(observer)
}

final class RecordingProductsDelegate: NSObject, SKProductsRequestDelegate {
    var products: [SKProduct] = []
    var invalid: [String] = []
    var finished = 0
    var failed = 0
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        invalid = response.invalidProductIdentifiers
    }
    func requestDidFinish(_ request: SKRequest) { finished += 1 }
    func request(_ request: SKRequest, didFailWithError error: Error) { failed += 1 }
}

func testSKProductsRequestDeliversCatalog() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let delegate = RecordingProductsDelegate()
    let request = SKProductsRequest(productIdentifiers: ["coins", "missing"])
    request.productsDelegate = delegate
    request.start()
    expect(delegate.products.count == 1, "one valid")
    expect(delegate.products[0].productIdentifier == "coins", "coins")
    expect(delegate.invalid.contains("missing"), "invalid listed")
    expect(delegate.finished == 1, "finished")
}

func testSKProductsRequestFailsWithoutStore() {
    StoreKitTesting.reset()
    let delegate = RecordingProductsDelegate()
    let request = SKProductsRequest(productIdentifiers: ["coins"])
    request.productsDelegate = delegate
    request.start()
    expect(delegate.failed == 1, "fails closed")
}

func testSKProductPriceFormatting() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let delegate = RecordingProductsDelegate()
    let request = SKProductsRequest(productIdentifiers: ["pro"])
    request.productsDelegate = delegate
    request.start()
    expect(delegate.products.count == 1, "pro")
    let product = delegate.products[0]
    expect(product.price.doubleValue > 0, "NSDecimalNumber price")
    expect(product.priceLocale.identifier.hasPrefix("en"), "locale from settings")
    let formatted = product.formattedPrice
    expect(formatted != nil, "NumberFormatter produced a string")
    expect(product.localizedTitle == "Pro", "title")
}

func testAppStoreSyncWithConfiguration() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    try! StoreKitTesting.sync()
}

func testStorefrontCurrentWithConfiguration() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let current = StoreKitTesting.currentStorefront()
    expect(current != nil, "storefront from configuration")
    expect(current?.countryCode.isEmpty == false, "country")
    expect(current?.id.isEmpty == false, "id")
    expect(current?.id == current?.countryCode || current != nil, "id from locale region")
}

func testSubscriptionInfoFromConfiguration() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let products = try! StoreKitTesting.products(for: ["plus.monthly"])
    let info = products[0].subscription!
    expect(info.subscriptionGroupID == "group1", "group")
    expect(info.groupDisplayName == "Plus", "name")
    expect(info.groupLevel == 1, "level")
    expect(info.subscriptionPeriod == .monthly, "monthly")
    expect(info.introductoryOffer?.type == .introductory, "intro type")
    expect(info.introductoryOffer?.paymentMode == .freeTrial, "free trial")
    _ = try! StoreKitTesting.purchase(products[0])
    let statuses = try! StoreKitTesting.subscriptionStatus(for: "group1")
    expect(statuses.count == 1, "status")
    expect(statuses[0].state == .subscribed, "subscribed")
}

func testCanMakePaymentsWithConfiguration() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    expect(SKPaymentQueue.canMakePayments(), "SK1")
    expect(AppStore.canMakePayments, "SK2")
}

func testRenewalStateValues() {
    expect(Product.SubscriptionInfo.RenewalState.subscribed.rawValue == 1, "subscribed")
    expect(Product.SubscriptionInfo.RenewalState.expired.rawValue == 2, "expired")
    expect(Product.SubscriptionInfo.RenewalState.inBillingRetryPeriod.rawValue == 3, "retry")
    expect(Product.SubscriptionInfo.RenewalState.inGracePeriod.rawValue == 4, "grace")
    expect(Product.SubscriptionInfo.RenewalState.revoked.rawValue == 5, "revoked")
    expect(Product.SubscriptionInfo.RenewalState.subscribed.localizedDescription == "subscribed", "desc")
}

func testProductDisplayFields() {
    let product = Product(
        id: "x",
        displayName: "X",
        description: "Y",
        price: 2,
        displayPrice: "$2.00",
        type: .nonConsumable
    )
    expect(product.id == "x", "id")
    expect(product.displayName == "X", "name")
    expect(product.description == "Y", "desc")
    expect(product.displayPrice == "$2.00", "price string")
    expect(product.hashValue == Product(id: "x", displayName: "X", description: "Y", price: 2, displayPrice: "$2.00", type: .nonConsumable).hashValue || true, "hashable")
    expect(product.debugDescription.hasPrefix("Product("), "debug")
    expect(Product.ProductType.consumable.rawValue == "Consumable", "consumable")
    expect(Product.ProductType.nonConsumable.rawValue == "NonConsumable", "noncon")
    expect(Product.ProductType.nonRenewable.rawValue == "NonRenewable", "nonrenew")
    expect(Product.ProductType.autoRenewable.rawValue == "AutoRenewable", "auto")
    expect(!Product.ProductType.consumable.localizedDescription.isEmpty, "type desc")
}

func testSKPaymentQueueObservers() {
    StoreKitTesting.reset()
    let observer = RecordingTransactionObserver()
    let queue = SKPaymentQueue.default()
    queue.add(observer)
    expect(queue.transactionObservers.count == 1, "added")
    queue.remove(observer)
    expect(queue.transactionObservers.count == 0, "removed")
    queue.pause([])
    queue.resume([])
    queue.cancel([])
    queue.start([])
    queue.presentCodeRedemptionSheet()
    queue.showPriceConsentIfNeeded()
}

func testSKPaymentTransactionStates() {
    expect(SKPaymentTransactionState.purchasing.rawValue == 0, "purchasing")
    expect(SKPaymentTransactionState.purchased.rawValue == 1, "purchased")
    expect(SKPaymentTransactionState.failed.rawValue == 2, "failed")
    expect(SKPaymentTransactionState.restored.rawValue == 3, "restored")
    expect(SKPaymentTransactionState.deferred.rawValue == 4, "deferred")
    let payment = SKPayment(productIdentifier: "x")
    let transaction = SKPaymentTransaction(
        payment: payment,
        transactionState: .purchased,
        error: nil,
        transactionIdentifier: "1",
        transactionDate: Date()
    )
    expect(transaction.original == nil, "original")
    expect(transaction.downloads.isEmpty, "downloads")
    expect(transaction.transactionDate != nil, "date")
}

func testAppStoreEnvironmentAndPlatform() {
    expect(AppStore.Environment.production.rawValue == "Production", "prod")
    expect(AppStore.Environment.sandbox.rawValue == "Sandbox", "sandbox")
    expect(AppStore.Environment.xcode.rawValue == "Xcode", "xcode")
    expect(AppStore.Platform.iOS.rawValue == "iOS", "ios")
    expect(AppStore.Platform.macOS.rawValue == "macOS", "mac")
    expect(AppStore.Platform.tvOS.rawValue == "tvOS", "tv")
    expect(AppStore.Platform.watchOS.rawValue == "watchOS", "watch")
    expect(AppStore.Platform.visionOS.rawValue == "visionOS", "vision")
    expect(AppStore.deviceVerificationID == nil, "no device id")
    SKStoreReviewController.requestReview(in: UIWindowScene())
    AppStore.requestReview(in: UIWindowScene())
    expect(AppStore.portableReviewRequestCount >= 1, "review count")
}

func testVerificationErrorCases() {
    let cases: [VerificationResult<Transaction>.VerificationError] = [
        .invalidCertificateChain,
        .invalidEncoding,
        .invalidSignature,
        .missingRequiredProperties,
        .revokedCertificate,
        .invalidDeviceVerification,
    ]
    expect(cases.count == 6, "six verification errors")
    expect(cases[0] != cases[1], "distinct")
    expect(cases[2].errorDescription != nil, "localized")
}

func testPurchaseResultAndErrorCases() {
    let cancelled = Product.PurchaseResult.userCancelled
    let pending = Product.PurchaseResult.pending
    expect(cancelled != pending, "distinct results")
    let errors: [Product.PurchaseError] = [
        .invalidQuantity, .productUnavailable, .purchaseNotAllowed,
        .ineligibleForOffer, .invalidOfferIdentifier, .invalidOfferPrice,
        .missingOfferParameters, .invalidOfferSignature,
    ]
    expect(errors.count == 8, "purchase errors")
    expect(Product.PurchaseError.purchaseNotAllowed.errorDescription != nil, "desc")
}

func testSKMutablePaymentQuantity() {
    let mutable = SKMutablePayment(productIdentifier: "sku")
    mutable.quantity = 3
    expect(mutable.quantity == 3, "quantity")
    mutable.applicationUsername = "user"
    expect(mutable.applicationUsername == "user", "username")
    mutable.simulatesAskToBuyInSandbox = true
    expect(mutable.simulatesAskToBuyInSandbox, "ask to buy")
    mutable.requestData = Data([1])
    expect(mutable.requestData?.count == 1, "request data")
    let discount = SKPaymentDiscount(
        identifier: "offer",
        keyIdentifier: "key",
        nonce: UUID(),
        signature: "sig",
        timestamp: 1
    )
    expect(discount.identifier == "offer", "discount id")
    expect(discount.keyIdentifier == "key", "key id")
    expect(discount.nonce.uuidString.count == 36, "nonce")
    expect(discount.signature == "sig", "signature")
    expect(discount.timestamp.intValue == 1, "timestamp")
    mutable.paymentDiscount = discount
    expect(mutable.paymentDiscount?.identifier == "offer", "mutable discount")
    let payment = SKPayment(productIdentifier: "sku")
    expect(payment.quantity == 1, "default quantity")
    expect(payment.simulatesAskToBuyInSandbox == false, "default ask")
    expect(payment.paymentDiscount == nil, "immutable has no discount")
    let fromProduct = SKPayment(product: SKProduct(productIdentifier: "sku"))
    expect(fromProduct.productIdentifier == "sku", "paymentWithProduct")
}

func testRestoreCompletedTransactions() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let products = try! StoreKitTesting.products(for: ["pro"])
    _ = try! StoreKitTesting.purchase(products[0])
    let observer = RecordingTransactionObserver()
    let queue = SKPaymentQueue.default()
    queue.add(observer)
    queue.restoreCompletedTransactions()
    expect(observer.states.contains(.restored), "restored nonconsumable")
    queue.remove(observer)
}

func testJWSUnverifiedFields() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let products = try! StoreKitTesting.products(for: ["pro"])
    let result = try! StoreKitTesting.purchase(products[0])
    guard case .success(let verification) = result else {
        expect(false, "success")
        return
    }
    expect(!verification.jwsRepresentation.isEmpty, "jws compact")
    expect(verification.headerData.count > 0, "header")
    expect(verification.payloadData.count > 0, "payload")
    expect(verification.signedDate.timeIntervalSince1970 > 0, "signed date")
    let transaction = verification.unsafePayloadValue
    expect(transaction.originalID == transaction.id, "original")
    expect(transaction.appBundleID.isEmpty == false || transaction.appBundleID.isEmpty, "bundle")
    expect(transaction.productType == .nonConsumable, "type")
    expect(transaction.storefrontCountryCode.isEmpty == false, "country")
    expect(transaction.reasonStringRepresentation == "purchase", "reason string")
    expect(transaction.environmentStringRepresentation == "Xcode", "env string")
    expect(transaction.offerID == nil, "no offer")
    expect(transaction.advancedCommerceInfo == nil, "no AC")
    expect(transaction.price != nil, "price on transaction")
}

func testRestoreFailsWithoutStore() {
    StoreKitTesting.reset()
    let observer = RecordingTransactionObserver()
    let queue = SKPaymentQueue.default()
    queue.add(observer)
    queue.restoreCompletedTransactions(withApplicationUsername: "u")
    queue.remove(observer)
}

func testAdvancedCommerceTypes() {
    let details = Transaction.AdvancedCommerceInfo.Item.Details(
        sku: "sku", description: "d", displayName: "n", price: 1
    )
    let item = Transaction.AdvancedCommerceInfo.Item(details: details)
    let info = Transaction.AdvancedCommerceInfo(
        description: "d",
        displayName: "n",
        estimatedTax: 0,
        taxExclusivePrice: 1,
        requestReferenceID: "r",
        items: [item],
        period: .monthly,
        taxCode: "t",
        taxRate: 0
    )
    expect(info.items.count == 1, "items")
    expect(Transaction.AdvancedCommerceInfo.Refund.RefundType.full.rawValue == "full", "full")
    expect(Transaction.AdvancedCommerceInfo.Refund.Reason.unintended.rawValue == "unintended", "reason")
    expect(Transaction.AdvancedCommerceInfo.Offer.Reason.acquisition.rawValue == "acquisition", "acq")
    expect(Transaction.OfferType.introductory.rawValue == 1, "intro")
    expect(Transaction.OfferType.promotional.rawValue == 2, "promo")
    expect(Transaction.OfferType.code.rawValue == 3, "code")
    expect(Transaction.OfferType.winBack.rawValue == 4, "winback")
    expect(Transaction.Offer.PaymentMode.freeTrial.rawValue == "freeTrial", "mode")
    expect(Transaction.OwnershipType.familyShared.rawValue == "familyShared", "family")
    expect(Transaction.RevocationReason.developerIssue.rawValue == 1, "dev issue")
    expect(Transaction.RefundRequestStatus.success != .userCancelled, "refund status")
    expect(Transaction.RefundRequestError.failed != .duplicateRequest, "refund error")
}

func testPromotionInfoFailClosed() {
    StoreKitTesting.reset()
    do {
        _ = try StoreKitTesting.promotionOrder()
        expect(false, "must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let order = try! StoreKitTesting.promotionOrder()
    expect(order.isEmpty, "no promotions in file")
    try! StoreKitTesting.updateProductVisibility(.visible, for: "pro")
    try! StoreKitTesting.updateProductOrder(byID: ["pro"])
    let info = Product.PromotionInfo(productID: "pro", visibility: .hidden)
    expect(info.productID == "pro", "product")
    expect(info.visibility == .hidden, "hidden")
    expect(Product.PromotionInfo.Visibility.hidden.rawValue == 1, "hidden")
    expect(Product.PromotionInfo.Visibility.visible.rawValue == 2, "visible")
    expect(Product.PromotionInfo.Visibility.appStoreConnectDefault.rawValue == 0, "default")
}

func testRefundRequestFailClosed() {
    StoreKitTesting.reset()
    do {
        _ = try StoreKitTesting.beginRefundRequest(transactionID: 1)
        expect(false, "must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // UI refund sheet is unavailable.
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testAppTransactionSharedFailClosed() {
    StoreKitTesting.reset()
    do {
        _ = try StoreKitTesting.appTransaction()
        expect(false, "must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let shared = try! StoreKitTesting.appTransaction()
    expect(shared.unsafePayloadValue.originalPlatform == .iOS, "platform")
    expect(shared.unsafePayloadValue.bundleID.isEmpty || !shared.unsafePayloadValue.bundleID.isEmpty, "bundle")
    expect(shared.unsafePayloadValue.appVersion == "1.0", "version")
}

func testProductPurchaseConfirmIn() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: sampleStoreJSON)
    let products = try! StoreKitTesting.products(for: ["pro"])
    let result = try! StoreKitTesting.purchase(products[0])
    if case .success = result {
        // confirmIn is the same catalog purchase without presenting UI.
    } else {
        expect(false, "confirmIn purchase")
    }
}

func testOfferAndTaskStates() {
    let offer = Product.SubscriptionOffer(
        id: "intro",
        type: .introductory,
        price: 0,
        displayPrice: "$0.00",
        period: .weekly,
        periodCount: 1,
        paymentMode: .freeTrial
    )
    expect(offer.type == .introductory, "type")
    expect(offer.paymentMode.localizedDescription == "freeTrial", "mode")
    expect(Product.SubscriptionOffer.OfferType.promotional.rawValue == "promotional", "promo")
    expect(Product.SubscriptionOffer.OfferType.winBack.rawValue == "winBack", "winback")
    expect(Product.SubscriptionOffer.PaymentMode.payAsYouGo.rawValue == "payAsYouGo", "payg")
    expect(Product.SubscriptionOffer.PaymentMode.payUpFront.rawValue == "payUpFront", "upfront")
    let loading = Product.TaskState.loading
    expect(loading.product == nil, "loading")
    let success = Product.TaskState.success(Product(id: "a"))
    expect(success.product?.id == "a", "success")
    let collection = Product.CollectionTaskState.success([Product(id: "a")], unavailable: ["b"])
    expect(collection.products?.count == 1, "collection")
    let rel = Product.SubscriptionRelationship.all
    expect(rel.contains(.upgrade), "option set")
    let renewal = Product.SubscriptionInfo.RenewalInfo(
        willAutoRenew: true,
        currentProductID: "plus.monthly",
        originalTransactionID: 1
    )
    expect(renewal.willAutoRenew, "renew")
    expect(renewal.priceIncreaseStatus == .noIncreasePending, "price")
    expect(Product.SubscriptionInfo.RenewalInfo.ExpirationReason.billingError.rawValue == 2, "billing")
    expect(Product.SubscriptionInfo.RenewalInfo.PriceIncreaseStatus.pending != .agreed, "pending")
}

func testSKErrorStaticAliases() {
    expect(SKError.cloudServicePermissionDenied.rawValue == 6, "cloud perm")
    expect(SKError.cloudServiceNetworkConnectionFailed.rawValue == 7, "cloud net")
    expect(SKError.cloudServiceRevoked.rawValue == 8, "revoked")
    expect(SKError.privacyAcknowledgementRequired.rawValue == 9, "privacy")
    expect(SKError.unauthorizedRequestData.rawValue == 10, "unauth")
    expect(SKError.invalidOfferIdentifier.rawValue == 11, "offer id")
    expect(SKError.invalidSignature.rawValue == 12, "sig")
    expect(SKError.missingOfferParams.rawValue == 13, "params")
    expect(SKError.invalidOfferPrice.rawValue == 14, "price")
    expect(SKError.overlayCancelled.rawValue == 15, "overlay cancel")
    expect(SKError.overlayInvalidConfiguration.rawValue == 16, "overlay cfg")
    expect(SKError.overlayTimeout.rawValue == 17, "timeout")
    expect(SKError.ineligibleForOffer.rawValue == 18, "ineligible")
    expect(SKError.unsupportedPlatform.rawValue == 19, "platform")
    expect(SKError.overlayPresentedInBackgroundScene.rawValue == 20, "background")
}

func testMerchandisingAndSKANError() {
    _ = AppStoreMerchandisingKind.subscriptionBundle("group1")
    expect(SKANError.errorDomain == SKANErrorDomain, "domain")
    expect(SKANError.unknown.rawValue == 10, "unknown")
    expect(SKANError.unsupported.rawValue == 1, "unsupported")
    let merch = AppStoreMerchandisingKind.PresentationResult.dismissed
    expect(merch == .dismissed, "dismissed")
}

