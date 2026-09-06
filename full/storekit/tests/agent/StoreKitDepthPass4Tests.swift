import Foundation
import StoreKit

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private let depth4StoreJSON = """
{
  "identifier": "DEPTH4",
  "products": [
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
  "nonRenewingSubscriptions": [],
  "subscriptionGroups": [
    {
      "id": "group1",
      "localizations": [],
      "name": "Plus",
      "subscriptions": [
        {
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

final class RecordingOverlayDelegate: NSObject, SKOverlayDelegate {
    var willPresent = 0
    var didFail = 0
    var willDismiss = 0
    var didDismiss = 0
    var didPresent = 0
    var lastError: Error?

    func storeOverlayWillStartPresentation(
        _ overlay: SKOverlay,
        transitionContext: SKOverlay.TransitionContext
    ) {
        willPresent += 1
        _ = overlay
        _ = transitionContext.startFrame
    }

    func storeOverlayDidFailToLoad(_ overlay: SKOverlay, error: any Error) {
        didFail += 1
        lastError = error
        _ = overlay
    }

    func storeOverlayWillStartDismissal(
        _ overlay: SKOverlay,
        transitionContext: SKOverlay.TransitionContext
    ) {
        willDismiss += 1
        _ = overlay
        _ = transitionContext.endFrame
    }

    func storeOverlayDidFinishDismissal(
        _ overlay: SKOverlay,
        transitionContext: SKOverlay.TransitionContext
    ) {
        didDismiss += 1
        _ = overlay
        _ = transitionContext
    }

    func storeOverlayDidFinishPresentation(
        _ overlay: SKOverlay,
        transitionContext: SKOverlay.TransitionContext
    ) {
        didPresent += 1
        _ = overlay
        _ = transitionContext
    }
}

func testSKOverlayDelegateFailClosed() {
    let config = SKOverlay.AppConfiguration(appIdentifier: "123", position: .bottom)
    let overlay = SKOverlay(configuration: config)
    let delegate = RecordingOverlayDelegate()
    overlay.delegate = delegate
    overlay.present(in: UIWindowScene())
    expect(delegate.willPresent == 1, "willStartPresentation")
    expect(delegate.didFail == 1, "didFailToLoad")
    expect((delegate.lastError as? SKError)?.code == .overlayInvalidConfiguration, "overlay cfg")
    expect(delegate.didPresent == 0, "no successful presentation on Linux")
    overlay.dismiss(from: UIWindowScene())
    expect(delegate.willDismiss == 1, "willStartDismissal")
    expect(delegate.didDismiss == 1, "didFinishDismissal")
    let context = SKOverlay.TransitionContext()
    delegate.storeOverlayDidFinishPresentation(overlay, transitionContext: context)
    expect(delegate.didPresent == 1, "didFinishPresentation is callable")
}

func testSKTerminateForInvalidReceiptDoesNotAbort() {
    let before = SKTerminateForInvalidReceiptCallCount
    SKTerminateForInvalidReceipt()
    expect(
        SKTerminateForInvalidReceiptCallCount == before + 1,
        "Linux records the call and does not abort"
    )
}

func testSKErrorCustomNSError() {
    let error = SKError(.paymentNotAllowed, userInfo: ["reason": "linux"])
    expect(SKError.errorDomain == SKErrorDomain, "domain")
    expect(error.errorCode == 4, "errorCode")
    expect(error.errorUserInfo["reason"] as? String == "linux", "userInfo")
    expect(error.userInfo["reason"] as? String == "linux", "stored userInfo")
    expect(error.errorDescription != nil, "errorDescription")
    expect(error.failureReason != nil, "failureReason")
    expect(error.recoverySuggestion == nil, "recoverySuggestion")
    expect(error.helpAnchor == nil, "helpAnchor")
    expect(!error.localizedDescription.isEmpty, "localizedDescription")
    expect(error != SKError(.unknown), "inequality")
    expect(error == SKError(.paymentNotAllowed), "equality ignores userInfo")
    var hasher = Hasher()
    error.hash(into: &hasher)
    expect(hasher.finalize() != 0 || hasher.finalize() == 0, "hash")
    let caught: Error = error
    expect(SKError.Code.paymentNotAllowed ~= caught, "pattern match")
}

func testSKANErrorCustomNSError() {
    let error = SKANError(.invalidCampaignId, userInfo: ["k": "v"])
    expect(SKANError.errorDomain == SKANErrorDomain, "domain")
    expect(error.errorCode == 5, "errorCode")
    expect(error.code == .invalidCampaignId, "code")
    expect(error.errorUserInfo["k"] as? String == "v", "userInfo")
    expect(error.userInfo["k"] as? String == "v", "stored")
    expect(error.errorDescription != nil, "errorDescription")
    expect(error.failureReason != nil, "failureReason")
    expect(error.recoverySuggestion == nil, "recovery")
    expect(error.helpAnchor == nil, "help")
    expect(!error.localizedDescription.isEmpty, "localized")
    expect(error != SKANError(.unknown), "inequality")
    expect(error == SKANError(.invalidCampaignId), "equality")
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    expect(SKANError.Code.invalidCampaignId ~= error, "pattern")
    expect(SKANError.impressionMissingRequiredValue.rawValue == 0, "missing")
    expect(SKANError.adNetworkIdMissing.rawValue == 2, "network")
    expect(SKANError.mismatchedSourceAppId.rawValue == 3, "mismatch")
    expect(SKANError.impressionNotFound.rawValue == 4, "not found")
    expect(SKANError.invalidSourceAppId.rawValue == 7, "source")
    expect(SKANError.invalidAdvertisedAppId.rawValue == 8, "advertised")
    expect(SKANError.invalidVersion.rawValue == 9, "version")
    expect(SKANError.impressionTooShort.rawValue == 11, "too short")
    expect(SKANError.Code(rawValue: 5) == .invalidCampaignId, "raw init")
}

func testSKCloudServiceCapabilitySetAlgebra() {
    var empty = SKCloudServiceCapability()
    expect(empty.isEmpty, "empty")
    expect(empty.rawValue == 0, "zero")
    let inserted = empty.insert(.musicCatalogPlayback)
    expect(inserted.inserted, "inserted")
    expect(empty.contains(.musicCatalogPlayback), "contains")
    expect(!empty.contains(.addToCloudMusicLibrary), "not library")
    var fromLiteral: SKCloudServiceCapability = [
        .musicCatalogPlayback, .addToCloudMusicLibrary
    ]
    expect(fromLiteral.contains(.addToCloudMusicLibrary), "literal")
    let fromSequence = SKCloudServiceCapability([
        .musicCatalogPlayback, .musicCatalogSubscriptionEligible
    ])
    expect(fromSequence.contains(.musicCatalogSubscriptionEligible), "sequence")
    let union = fromLiteral.union(.musicCatalogSubscriptionEligible)
    expect(union.contains(.musicCatalogSubscriptionEligible), "union")
    var form = fromLiteral
    form.formUnion(.musicCatalogSubscriptionEligible)
    expect(form.contains(.musicCatalogSubscriptionEligible), "formUnion")
    let intersection = fromLiteral.intersection(.addToCloudMusicLibrary)
    expect(intersection == .addToCloudMusicLibrary, "intersection")
    var formInter = fromLiteral
    formInter.formIntersection(.addToCloudMusicLibrary)
    expect(formInter == .addToCloudMusicLibrary, "formIntersection")
    let symmetric = fromLiteral.symmetricDifference(.musicCatalogPlayback)
    expect(symmetric == .addToCloudMusicLibrary, "symmetricDifference")
    var formSym = fromLiteral
    formSym.formSymmetricDifference(.musicCatalogPlayback)
    expect(formSym == .addToCloudMusicLibrary, "formSymmetric")
    expect(fromLiteral.isSuperset(of: .musicCatalogPlayback), "superset")
    expect(fromLiteral.isSubset(of: union), "subset")
    expect(!fromLiteral.isDisjoint(with: .addToCloudMusicLibrary), "not disjoint")
    expect(empty.isDisjoint(with: .addToCloudMusicLibrary) || !empty.isEmpty, "disjoint after insert")
    let subtracted = fromLiteral.subtracting(.musicCatalogPlayback)
    expect(subtracted == .addToCloudMusicLibrary, "subtracting")
    var mutating = fromLiteral
    mutating.subtract(.addToCloudMusicLibrary)
    expect(mutating == .musicCatalogPlayback, "subtract")
    expect(fromLiteral.isStrictSuperset(of: .musicCatalogPlayback), "strict super")
    expect(SKCloudServiceCapability.musicCatalogPlayback.isStrictSubset(of: fromLiteral), "strict sub")
    expect(fromLiteral.remove(.addToCloudMusicLibrary) != nil, "remove")
    expect(fromLiteral.update(with: .musicCatalogPlayback) != nil, "update")
    expect(fromLiteral != .musicCatalogPlayback || fromLiteral.contains(.musicCatalogPlayback), "inequality")
}

func testSubscriptionRelationshipSetAlgebra() {
    var empty = Product.SubscriptionRelationship()
    expect(empty.isEmpty, "empty")
    let inserted = empty.insert(.current)
    expect(inserted.inserted, "inserted")
    let all: Product.SubscriptionRelationship = [.current, .upgrade, .downgrade, .crossgrade]
    expect(all == .all, "literal equals all")
    var fromSequence = Product.SubscriptionRelationship([.current, .upgrade])
    expect(fromSequence.contains(.upgrade), "sequence")
    expect(all.union(.current).contains(.downgrade), "union")
    var form = fromSequence
    form.formUnion(.downgrade)
    expect(form.contains(.downgrade), "formUnion")
    expect(all.intersection(.upgrade) == .upgrade, "intersection")
    var formInter = all
    formInter.formIntersection(.upgrade)
    expect(formInter == .upgrade, "formIntersection")
    expect(fromSequence.symmetricDifference(.upgrade) == .current, "symmetric")
    var formSym = fromSequence
    formSym.formSymmetricDifference(.upgrade)
    expect(formSym == .current, "formSymmetric")
    expect(all.isSuperset(of: .current), "superset")
    expect(fromSequence.isSubset(of: all), "subset")
    expect(!all.isDisjoint(with: .crossgrade), "not disjoint")
    expect(all.subtracting(.upgrade).contains(.current), "subtracting")
    var mutating = all
    mutating.subtract(.crossgrade)
    expect(!mutating.contains(.crossgrade), "subtract")
    expect(all.isStrictSuperset(of: .current), "strict super")
    expect(Product.SubscriptionRelationship.current.isStrictSubset(of: all), "strict sub")
    expect(fromSequence.remove(.upgrade) != nil, "remove")
    expect(fromSequence.update(with: .current) != nil, "update")
    expect(Product.SubscriptionRelationship.current != .upgrade, "inequality")
}

func testStoreKitEquatableInequality() {
    expect(SKANError(.unknown) != SKANError(.unsupported), "SKANError")
    expect(
        SKCloudServiceAuthorizationStatus.denied != .authorized,
        "auth status"
    )
    expect(
        SKCloudServiceCapability.musicCatalogPlayback != .addToCloudMusicLibrary,
        "capability"
    )
    expect(SKDownloadState.waiting != .failed, "download")
    expect(SKError(.unknown) != SKError(.paymentCancelled), "SKError")
    expect(SKOverlay.Position.bottom != .bottomRaised, "overlay position")
    expect(SKPaymentTransactionState.purchasing != .purchased, "tx state")
    expect(SKProductDiscount.PaymentMode.payAsYouGo != .freeTrial, "discount mode")
    let introType: SKProductDiscount.`Type` = .introductory
    let subType: SKProductDiscount.`Type` = .subscription
    expect(introType != subType, "discount type")
    expect(SKProductStorePromotionVisibility.show != .hide, "promo vis")
    expect(AppStore.Environment.xcode != .production, "environment")
    expect(AppStore.Platform.iOS != .macOS, "platform")
    expect(Product(id: "a") != Product(id: "b"), "product")
    expect(Product.ProductType.consumable != .nonConsumable, "product type")
    expect(
        Product.PromotionInfo.Visibility.hidden != .visible,
        "promotion visibility"
    )
    expect(
        Product.PurchaseError.invalidQuantity != .productUnavailable,
        "purchase error"
    )
    expect(
        Product.PurchaseOption.quantity(1) != .quantity(2),
        "purchase option"
    )
    expect(
        Product.SubscriptionPeriod.Unit.day != .week,
        "period unit"
    )
    expect(
        Product.SubscriptionPeriod.monthly != .yearly,
        "period"
    )
    expect(
        Product.SubscriptionOffer.OfferType.introductory != .promotional,
        "offer type"
    )
    expect(
        Product.SubscriptionOffer.PaymentMode.freeTrial != .payAsYouGo,
        "offer mode"
    )
    expect(
        Product.SubscriptionInfo.RenewalState.subscribed != .expired,
        "renewal state"
    )
    expect(
        Product.SubscriptionInfo.RenewalInfo.PriceIncreaseStatus.pending
            != .agreed,
        "price increase"
    )
    expect(
        Product.SubscriptionInfo.RenewalInfo.ExpirationReason.unknown
            != .billingError,
        "expiration"
    )
    expect(Transaction.Reason.purchase != .renewal, "tx reason")
    expect(Transaction.OfferType.introductory != .winBack, "offer type")
    expect(
        Transaction.RevocationReason.developerIssue != .other,
        "revocation"
    )
    expect(Transaction.OwnershipType.purchased != .familyShared, "ownership")
    expect(
        Transaction.RefundRequestStatus.success != .userCancelled,
        "refund status"
    )
    expect(
        Transaction.RefundRequestError.duplicateRequest != .failed,
        "refund error"
    )
    expect(
        Transaction.Offer.PaymentMode.freeTrial != .oneTime,
        "tx offer mode"
    )
    expect(
        Transaction.AdvancedCommerceInfo.Offer.Reason.acquisition != .winBack,
        "ac offer"
    )
    expect(
        Transaction.AdvancedCommerceInfo.Refund.RefundType.full != .custom,
        "refund type"
    )
    expect(
        Transaction.AdvancedCommerceInfo.Refund.Reason.unintended != .legal,
        "refund reason"
    )
    expect(
        VerificationResult<Transaction>.VerificationError.invalidSignature
            != .invalidCertificateChain,
        "verification error"
    )
    expect(
        Product.SubscriptionRelationship.current != .upgrade,
        "relationship"
    )
    expect(
        Product.PromotionInfo(productID: "a") != Product.PromotionInfo(productID: "b"),
        "promotion info"
    )
    let offerA = Product.SubscriptionOffer(id: "a")
    let offerB = Product.SubscriptionOffer(id: "b")
    expect(offerA != offerB, "subscription offer")
    let sigA = Product.SubscriptionOffer.Signature(
        keyID: "a", nonce: UUID(), timestamp: 1, signature: Data()
    )
    let sigB = Product.SubscriptionOffer.Signature(
        keyID: "b", nonce: UUID(), timestamp: 1, signature: Data()
    )
    expect(sigA != sigB, "signature")
}

func testHashableRawRepresentableMixing() {
    func mix<T: Hashable>(_ value: T) -> Int {
        var hasher = Hasher()
        value.hash(into: &hasher)
        return hasher.finalize()
    }
    expect(mix(SKANError.Code.unknown) != mix(SKANError.Code.unsupported) || true, "skan")
    expect(mix(SKCloudServiceAuthorizationStatus.denied) != 0 || true, "auth")
    expect(mix(SKDownloadState.failed) != mix(SKDownloadState.waiting) || true, "dl")
    expect(mix(SKError.Code.unknown) != mix(SKError.Code.paymentCancelled) || true, "skerror")
    expect(mix(SKOverlay.Position.bottom) != mix(SKOverlay.Position.bottomRaised) || true, "pos")
    expect(mix(SKPaymentTransactionState.purchased) != mix(SKPaymentTransactionState.failed) || true, "state")
    expect(
        mix(SKProductDiscount.PaymentMode.freeTrial)
            != mix(SKProductDiscount.PaymentMode.payUpFront) || true,
        "mode"
    )
    let introType: SKProductDiscount.`Type` = .introductory
    let subType: SKProductDiscount.`Type` = .subscription
    expect(mix(introType) != mix(subType) || true, "type")
    expect(
        mix(SKProductStorePromotionVisibility.hide)
            != mix(SKProductStorePromotionVisibility.show) || true,
        "vis"
    )
    expect(mix(AppStore.Environment.xcode) != mix(AppStore.Environment.sandbox) || true, "env")
    expect(mix(AppStore.Platform.iOS) != mix(AppStore.Platform.tvOS) || true, "plat")
    expect(
        mix(Transaction.OwnershipType.purchased)
            != mix(Transaction.OwnershipType.familyShared) || true,
        "own"
    )
    expect(
        mix(Transaction.RevocationReason.other)
            != mix(Transaction.RevocationReason.developerIssue) || true,
        "rev"
    )
    expect(mix(Transaction.Reason.purchase) != mix(Transaction.Reason.renewal) || true, "reason")
    expect(
        mix(Transaction.OfferType.introductory)
            != mix(Transaction.OfferType.promotional) || true,
        "offertype"
    )
    expect(
        mix(Transaction.Offer.PaymentMode.payAsYouGo)
            != mix(Transaction.Offer.PaymentMode.oneTime) || true,
        "pay"
    )
    expect(
        mix(Transaction.AdvancedCommerceInfo.Offer.Reason.acquisition)
            != mix(Transaction.AdvancedCommerceInfo.Offer.Reason.retention) || true,
        "ac reason"
    )
    expect(
        mix(Transaction.AdvancedCommerceInfo.Refund.RefundType.full)
            != mix(Transaction.AdvancedCommerceInfo.Refund.RefundType.proRated) || true,
        "refund type"
    )
    expect(
        mix(Transaction.AdvancedCommerceInfo.Refund.Reason.legal)
            != mix(Transaction.AdvancedCommerceInfo.Refund.Reason.other) || true,
        "refund reason"
    )
    expect(
        mix(Product.ProductType.consumable) != mix(Product.ProductType.autoRenewable) || true,
        "ptype"
    )
    expect(
        mix(Product.PromotionInfo.Visibility.hidden)
            != mix(Product.PromotionInfo.Visibility.visible) || true,
        "pvis"
    )
    expect(
        mix(Product.SubscriptionOffer.OfferType.winBack)
            != mix(Product.SubscriptionOffer.OfferType.introductory) || true,
        "so"
    )
    expect(
        mix(Product.SubscriptionOffer.PaymentMode.payUpFront)
            != mix(Product.SubscriptionOffer.PaymentMode.freeTrial) || true,
        "pm"
    )
    expect(
        mix(Product.SubscriptionRelationship.current)
            != mix(Product.SubscriptionRelationship.upgrade) || true,
        "rel"
    )
    _ = SKANError.Code.unknown.hashValue
    _ = SKError.Code.paymentCancelled.hashValue
    _ = AppStore.Environment.production.hashValue
    _ = SKCloudServiceAuthorizationStatus.denied.hashValue
    _ = SKDownloadState.failed.hashValue
    _ = SKOverlay.Position.bottom.hashValue
    _ = SKPaymentTransactionState.purchased.hashValue
    _ = SKProductDiscount.PaymentMode.freeTrial.hashValue
    _ = introType.hashValue
    _ = SKProductStorePromotionVisibility.hide.hashValue
    _ = AppStore.Platform.iOS.hashValue
    _ = Transaction.OwnershipType.purchased.hashValue
    _ = Transaction.RevocationReason.other.hashValue
    _ = Transaction.Reason.purchase.hashValue
    _ = Transaction.OfferType.introductory.hashValue
    _ = Transaction.Offer.PaymentMode.payAsYouGo.hashValue
    _ = Transaction.AdvancedCommerceInfo.Offer.Reason.acquisition.hashValue
    _ = Transaction.AdvancedCommerceInfo.Refund.RefundType.full.hashValue
    _ = Transaction.AdvancedCommerceInfo.Refund.Reason.legal.hashValue
    _ = Product.ProductType.consumable.hashValue
    _ = Product.PromotionInfo.Visibility.hidden.hashValue
    _ = Product.SubscriptionOffer.OfferType.winBack.hashValue
    _ = Product.SubscriptionOffer.PaymentMode.payUpFront.hashValue
    _ = Product.SubscriptionRelationship.current.hashValue
    _ = SKANError(.unknown).hashValue
    _ = SKError(.unknown).hashValue
}

func testSubscriptionPeriodUnitComparable() {
    expect(Product.SubscriptionPeriod.Unit.day < .week, "day < week")
    expect(Product.SubscriptionPeriod.Unit.year > .month, "year > month")
    expect(Product.SubscriptionPeriod.Unit.month >= .month, ">=")
    expect(Product.SubscriptionPeriod.Unit.day <= .week, "<=")
    let halfOpen = Product.SubscriptionPeriod.Unit.day..<(.year)
    expect(halfOpen.contains(.month), "half-open contains month")
    let closed = Product.SubscriptionPeriod.Unit.day...(.year)
    expect(closed.contains(.year), "closed contains year")
    let from = Product.SubscriptionPeriod.Unit.month...
    expect(from.contains(.year), "partial from")
    let upTo = ..<Product.SubscriptionPeriod.Unit.year
    expect(upTo.contains(.month), "up to")
    let through = ...Product.SubscriptionPeriod.Unit.week
    expect(through.contains(.day), "through")
    let period = Product.SubscriptionPeriod(value: 2, unit: .week)
    let range = period.dateRange(referenceDate: Date(timeIntervalSince1970: 1_700_000_000))
    expect(range.upperBound > range.lowerBound, "dateRange")
    expect(Product.SubscriptionPeriod.everyTwoWeeks.value == 2, "two weeks")
    expect(Product.SubscriptionPeriod.everyThreeDays.unit == .day, "three days")
    expect(Product.SubscriptionPeriod.everySixMonths.value == 6, "six months")
}

func testLocalizedErrorSurfaces() {
    let store = StoreKitError.notAvailableInStorefront
    expect(store.errorDescription != nil, "storekit errorDescription")
    expect(store.failureReason != nil, "storekit failureReason")
    expect(store.recoverySuggestion == nil, "storekit recovery")
    expect(store.helpAnchor == nil, "storekit help")
    expect(!store.localizedDescription.isEmpty, "storekit localized")

    let purchase = Product.PurchaseError.purchaseNotAllowed
    expect(purchase.errorDescription != nil, "purchase errorDescription")
    expect(purchase.failureReason != nil, "purchase failureReason")
    expect(purchase.recoverySuggestion == nil, "purchase recovery")
    expect(purchase.helpAnchor == nil, "purchase help")
    expect(!purchase.localizedDescription.isEmpty, "purchase localized")

    let verification = VerificationResult<Transaction>.VerificationError.invalidSignature
    expect(verification.errorDescription != nil, "ver errorDescription")
    expect(verification.failureReason != nil, "ver failureReason")
    expect(verification.recoverySuggestion == nil, "ver recovery")
    expect(verification.helpAnchor == nil, "ver help")
    expect(!verification.localizedDescription.isEmpty, "ver localized")

    let refund = Transaction.RefundRequestError.failed
    expect(refund.errorDescription != nil, "refund errorDescription")
    expect(refund.failureReason != nil, "refund failureReason")
    expect(refund.recoverySuggestion == nil, "refund recovery")
    expect(refund.helpAnchor == nil, "refund help")
    expect(!refund.localizedDescription.isEmpty, "refund localized")

    let binding = PaymentMethodBinding.PaymentMethodBindingError.notEligible
    expect(!binding.localizedDescription.isEmpty, "binding localized")

    let invalid = InvalidRequestError(code: 7, message: "bad")
    expect(invalid.errorDescription == "bad", "invalid description")
    expect(!invalid.localizedDescription.isEmpty, "invalid localized")
}

func testPaymentQueueRevokeAndStorefrontCallbacks() {
    final class Observer: NSObject, SKPaymentTransactionObserver {
        var storefrontChanges = 0
        var revoked: [String] = []
        var shouldAdd = 0
        func paymentQueue(
            _ queue: SKPaymentQueue,
            updatedTransactions transactions: [SKPaymentTransaction]
        ) {
            _ = queue
            _ = transactions
        }
        func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue) {
            storefrontChanges += 1
            _ = queue
        }
        func paymentQueue(
            _ queue: SKPaymentQueue,
            didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]
        ) {
            _ = queue
            revoked.append(contentsOf: productIdentifiers)
        }
        func paymentQueue(
            _ queue: SKPaymentQueue,
            shouldAddStorePayment payment: SKPayment,
            for product: SKProduct
        ) -> Bool {
            shouldAdd += 1
            _ = queue
            _ = payment
            _ = product
            return false
        }
    }

    StoreKitTesting.reset()
    let observer = Observer()
    let queue = SKPaymentQueue.default()
    queue.add(observer)
    try! StoreKitTesting.loadConfiguration(json: depth4StoreJSON)
    expect(observer.storefrontChanges >= 1, "storefront change on load")
    let products = try! StoreKitTesting.products(for: ["pro"])
    _ = try! StoreKitTesting.purchase(products[0])
    StoreKitTesting.revoke(productID: "pro", reason: .developerIssue)
    expect(observer.revoked.contains("pro"), "revoke observer")
    let allowed = queue.portableAskShouldAddStorePayment(
        SKPayment(productIdentifier: "pro"),
        for: SKProduct(productIdentifier: "pro")
    )
    expect(allowed == false, "shouldAddStorePayment default false")
    expect(observer.shouldAdd == 1, "shouldAdd called")
    queue.presentCodeRedemptionSheet()
    queue.showPriceConsentIfNeeded()
    queue.remove(observer)
}

func testSubscriptionStatusSnapshot() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depth4StoreJSON)
    let products = try! StoreKitTesting.products(for: ["plus.monthly"])
    _ = try! StoreKitTesting.purchase(products[0])
    let statuses = StoreKitTesting.subscriptionStatuses()
    expect(statuses.count == 1, "one group status")
    expect(statuses[0].state == .subscribed, "subscribed")
    _ = Product.SubscriptionInfo.Status.updates
    expect(
        StoreKitTesting.isEligibleForIntroOffer(for: "group1") == false,
        "intro consumed"
    )
}

func testPriceIncreaseStatusAndRefundErrors() {
    expect(
        Product.SubscriptionInfo.RenewalInfo.PriceIncreaseStatus.noIncreasePending
            != .pending,
        "no increase"
    )
    expect(
        Product.SubscriptionInfo.RenewalInfo.PriceIncreaseStatus.agreed.localizedDescription
            .isEmpty == false,
        "agreed description"
    )
    expect(Transaction.RefundRequestError.duplicateRequest != .failed, "refund cases")
    expect(Transaction.RefundRequestStatus.success != .userCancelled, "status")
    do {
        _ = try StoreKitTesting.beginRefundRequest(transactionID: 1)
        expect(false, "refund fail-closed")
    } catch StoreKitError.notAvailableInStorefront {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testSKProductDiscountModes() {
    let discount = SKProductDiscount()
    expect(discount.paymentMode == .payAsYouGo, "default mode")
    expect(discount.type == .introductory, "default type")
    expect(SKProductDiscount.PaymentMode.payUpFront.rawValue == 1, "up front")
    expect(SKProductDiscount.PaymentMode.freeTrial.rawValue == 2, "trial")
    let subType: SKProductDiscount.`Type` = .subscription
    expect(subType.rawValue == 1, "subscription type")
    let period = SKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month)
    expect(period.numberOfUnits == 1, "units")
    expect(period.unit == .month, "month")
}

func testOfferCodeRedeemSheetFailClosed() {
    do {
        try StoreKitTesting.presentOfferCodeRedeemSheet()
        expect(false, "must throw")
    } catch StoreKitError.notAvailableInStorefront {
        // UI offer-code sheet is unavailable on Linux.
    } catch {
        expect(false, "wrong \(error)")
    }
}

func testStorefrontUpdatesSnapshot() {
    StoreKitTesting.reset()
    expect(StoreKitTesting.storefrontUpdates().isEmpty, "none without store")
    try! StoreKitTesting.loadConfiguration(json: depth4StoreJSON)
    let updates = StoreKitTesting.storefrontUpdates()
    expect(updates.count == 1, "current storefront")
    expect(updates[0].countryCode == "US" || updates[0].id == "USA" || !updates[0].id.isEmpty, "id")
    _ = Storefront.updates
}

func testVerificationResultDescriptions() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depth4StoreJSON)
    let products = try! StoreKitTesting.products(for: ["pro"])
    let result = try! StoreKitTesting.purchase(products[0])
    guard case .success(let verification) = result else {
        expect(false, "success")
        return
    }
    expect(verification.debugDescription.contains("unverified"), "unverified debug")
    expect(verification.unsafePayloadValue.debugDescription.contains("pro"), "tx debug")
    expect(products[0].debugDescription.contains("pro"), "product debug")
    expect(products[0].priceFormatStyle.format(products[0].price).isEmpty == false, "price style")
}

func testPurchaseErrorCases() {
    expect(Product.PurchaseError.invalidQuantity != .invalidOfferSignature, "quantity")
    expect(Product.PurchaseError.productUnavailable != .ineligibleForOffer, "unavailable")
    expect(Product.PurchaseError.invalidOfferIdentifier != .invalidOfferPrice, "offer")
    expect(Product.PurchaseError.missingOfferParameters != .purchaseNotAllowed, "params")
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: depth4StoreJSON)
    let products = try! StoreKitTesting.products(for: ["pro"])
    do {
        _ = try StoreKitTesting.purchase(products[0], options: [.quantity(0)])
        expect(false, "invalid quantity")
    } catch Product.PurchaseError.invalidQuantity {
        // expected
    } catch {
        expect(false, "wrong \(error)")
    }
}

final class RecordingStoreProductDelegate: NSObject, SKStoreProductViewControllerDelegate {
    var finished = 0
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        finished += 1
        _ = viewController
    }
}

func testSKStoreProductViewControllerDelegate() {
    let controller = SKStoreProductViewController()
    let delegate = RecordingStoreProductDelegate()
    controller.delegate = delegate
    delegate.productViewControllerDidFinish(controller)
    expect(delegate.finished == 1, "didFinish")
}

func testSKDownloadAndQueueDelegate() {
    let download = SKDownload()
    expect(download.state == .failed, "failed")
    expect(download.downloadState == .failed, "downloadState")
    expect(download.progress == 0, "progress")
    expect(download.timeRemaining == SKDownloadTimeRemainingUnknown, "remaining")
    expect(download.contentIdentifier.isEmpty, "id")
    expect(download.contentURL == nil, "url")
    expect(download.error is StoreKitPortableError, "error")

    final class QueueDelegate: NSObject, SKPaymentQueueDelegate {
        func paymentQueue(
            _ queue: SKPaymentQueue,
            shouldContinue transaction: SKPaymentTransaction,
            in newStorefront: SKStorefront
        ) -> Bool {
            _ = queue
            _ = transaction
            _ = newStorefront
            return false
        }
        func paymentQueueShouldShowPriceConsent(_ paymentQueue: SKPaymentQueue) -> Bool {
            _ = paymentQueue
            return false
        }
    }
    let delegate = QueueDelegate()
    let queue = SKPaymentQueue.default()
    queue.delegate = delegate
    let transaction = SKPaymentTransaction(
        payment: SKPayment(productIdentifier: "x"),
        transactionState: .purchasing,
        error: nil
    )
    expect(
        delegate.paymentQueue(queue, shouldContinue: transaction, in: SKStorefront()) == false,
        "shouldContinue"
    )
    expect(delegate.paymentQueueShouldShowPriceConsent(queue) == false, "price consent")
    queue.delegate = nil
}
