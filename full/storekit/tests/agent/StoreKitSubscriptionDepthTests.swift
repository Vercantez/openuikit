import Foundation
import StoreKit

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testIntroOfferEligibleBeforePurchase() {
    StoreKitTesting.reset()
    expect(StoreKitTesting.isEligibleForIntroOffer(for: "group1") == false, "no store")
    try! StoreKitTesting.loadConfiguration(json: """
    {
      "identifier": "INTRO",
      "products": [],
      "settings": { "_locale": "en_US" },
      "nonRenewingSubscriptions": [],
      "subscriptionGroups": [{
        "id": "group1",
        "localizations": [],
        "name": "Plus",
        "subscriptions": [{
          "displayPrice": "1.99",
          "familyShareable": false,
          "groupNumber": 1,
          "introductoryOffer": {
            "displayPrice": "0.00",
            "numberOfPeriods": 1,
            "paymentMode": "free",
            "subscriptionPeriod": "P1W"
          },
          "localizations": [{ "description": "Monthly", "displayName": "Plus Monthly", "locale": "en_US" }],
          "productID": "plus.monthly",
          "recurringSubscriptionPeriod": "P1M",
          "referenceName": "Plus Monthly",
          "subscriptionGroupID": "group1",
          "type": "RecurringSubscription"
        }]
      }]
    }
    """)
    expect(StoreKitTesting.isEligibleForIntroOffer(for: "group1"), "eligible before purchase")
    let product = try! StoreKitTesting.products(for: ["plus.monthly"])[0]
    _ = try! StoreKitTesting.purchase(product)
    expect(StoreKitTesting.isEligibleForIntroOffer(for: "group1") == false, "consumed after subscribe")
}

func testRevocationRemovesEntitlement() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: """
    {
      "identifier": "REV",
      "products": [{
        "displayPrice": "4.99",
        "familyShareable": false,
        "localizations": [{ "description": "Pro", "displayName": "Pro", "locale": "en_US" }],
        "productID": "pro",
        "referenceName": "Pro",
        "type": "NonConsumable"
      }],
      "settings": { "_locale": "en_US" },
      "subscriptionGroups": [],
      "nonRenewingSubscriptions": []
    }
    """)
    let product = try! StoreKitTesting.products(for: ["pro"])[0]
    _ = try! StoreKitTesting.purchase(product)
    expect(StoreKitTesting.currentEntitlement(for: "pro") != nil, "entitled")
    StoreKitTesting.revoke(productID: "pro", reason: .developerIssue)
    expect(StoreKitTesting.currentEntitlement(for: "pro") == nil, "revoked not entitled")
    let latest = StoreKitTesting.latest(for: "pro")
    expect(latest?.unsafePayloadValue.revocationDate != nil, "revocation date")
    expect(latest?.unsafePayloadValue.revocationReason == .developerIssue, "reason")
}

func testExpirationRemovesSubscriptionEntitlement() {
    StoreKitTesting.reset()
    try! StoreKitTesting.loadConfiguration(json: """
    {
      "identifier": "EXP",
      "products": [],
      "settings": { "_locale": "en_US" },
      "nonRenewingSubscriptions": [],
      "subscriptionGroups": [{
        "id": "group1",
        "localizations": [],
        "name": "Plus",
        "subscriptions": [{
          "displayPrice": "1.99",
          "familyShareable": false,
          "groupNumber": 1,
          "localizations": [{ "description": "Monthly", "displayName": "Plus Monthly", "locale": "en_US" }],
          "productID": "plus.monthly",
          "recurringSubscriptionPeriod": "P1M",
          "referenceName": "Plus Monthly",
          "subscriptionGroupID": "group1",
          "type": "RecurringSubscription"
        }]
      }]
    }
    """)
    let product = try! StoreKitTesting.products(for: ["plus.monthly"])[0]
    _ = try! StoreKitTesting.purchase(product)
    expect(StoreKitTesting.currentEntitlement(for: "plus.monthly") != nil, "subscribed")
    StoreKitTesting.expire(productID: "plus.monthly")
    expect(StoreKitTesting.currentEntitlement(for: "plus.monthly") == nil, "expired")
    let statuses = try! StoreKitTesting.subscriptionStatus(for: "group1")
    expect(statuses.count == 1, "status remains")
    expect(statuses[0].state == .expired, "expired state")
    expect(
        statuses[0].renewalInfo.unsafePayloadValue.expirationReason == .autoRenewDisabled,
        "local expire maps to autoRenewDisabled until Apple's reason is observed"
    )
}

func testRenewalInfoExpirationReasons() {
    expect(Product.SubscriptionInfo.RenewalInfo.ExpirationReason.unknown.rawValue == 0, "unknown")
    expect(Product.SubscriptionInfo.RenewalInfo.ExpirationReason.autoRenewDisabled.rawValue == 1, "disabled")
    expect(Product.SubscriptionInfo.RenewalInfo.ExpirationReason.billingError.rawValue == 2, "billing")
    expect(Product.SubscriptionInfo.RenewalInfo.ExpirationReason.didNotConsentToPriceIncrease.rawValue == 3, "consent")
    expect(Product.SubscriptionInfo.RenewalInfo.ExpirationReason.productUnavailable.rawValue == 4, "unavailable")
}

func testTransactionReasonAndRevocationRawValues() {
    expect(Transaction.Reason.purchase.rawValue == "purchase", "purchase")
    expect(Transaction.Reason.renewal.rawValue == "renewal", "renewal")
    expect(Transaction.RevocationReason.other.rawValue == 0, "other")
    expect(Transaction.RevocationReason.developerIssue.rawValue == 1, "developer")
}
