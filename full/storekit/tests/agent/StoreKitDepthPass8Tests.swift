import Foundation
import StoreKit

private func expectDepth8(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testStoreKitCompatibilityTypealiases() {
    let period: SubscriptionPeriod = Product.SubscriptionPeriod(value: 1, unit: .month)
    let state: SubscriptionRenewalState = .subscribed
    let info: SubscriptionInfo = Product.SubscriptionInfo(subscriptionGroupID: "depth.aliases")
    let renewal: SubscriptionRenewalInfo = Product.SubscriptionInfo.RenewalInfo(
        willAutoRenew: true,
        currentProductID: "monthly",
        originalTransactionID: 8
    )
    let status: SubscriptionStatus = Product.SubscriptionInfo.Status(
        state: state,
        transaction: .unverified(Transaction(id: 8, productID: "monthly", purchaseDate: Date()), .invalidSignature),
        renewalInfo: .verified(renewal)
    )

    expectDepth8(period == .monthly, "period alias")
    expectDepth8(info.subscriptionGroupID == "depth.aliases", "info alias")
    expectDepth8(state == .subscribed, "state alias")
    expectDepth8(renewal.currentProductID == "monthly", "renewal alias")
    expectDepth8(status.state == .subscribed, "status alias")
}

func testStoreKitStructuralInequalityWitnesses() {
    expectDepth8(Transaction(id: 1, productID: "one", purchaseDate: Date()) != Transaction(id: 2, productID: "two", purchaseDate: Date()), "transaction")
    expectDepth8(
        Transaction.Offer(id: "one", type: .promotional)
            != Transaction.Offer(id: "two", type: .winBack),
        "transaction offer"
    )
    let firstInfo = Product.SubscriptionInfo(subscriptionGroupID: "one")
    let secondInfo = Product.SubscriptionInfo(subscriptionGroupID: "two")
    expectDepth8(firstInfo != secondInfo, "subscription info")

    let firstRenewal = Product.SubscriptionInfo.RenewalInfo(willAutoRenew: true, currentProductID: "one", originalTransactionID: 1)
    let secondRenewal = Product.SubscriptionInfo.RenewalInfo(willAutoRenew: false, currentProductID: "two", originalTransactionID: 2)
    expectDepth8(firstRenewal != secondRenewal, "renewal info")
    expectDepth8(
        Product.SubscriptionInfo.RenewalInfo.AdvancedCommerceInfo(
            description: "one", displayName: "One", consistencyToken: "1",
            requestReferenceID: "one", items: [], period: .monthly, taxCode: "A"
        ) != Product.SubscriptionInfo.RenewalInfo.AdvancedCommerceInfo(
            description: "two", displayName: "Two", consistencyToken: "2",
            requestReferenceID: "two", items: [], period: .yearly, taxCode: "B"
        ),
        "renewal advanced commerce"
    )
    expectDepth8(
        Product.SubscriptionInfo.RenewalInfo.AdvancedCommerceInfo.Item(
            details: Transaction.AdvancedCommerceInfo.Item.Details(sku: "one", description: "one", displayName: "One", price: 1)
        ) != Product.SubscriptionInfo.RenewalInfo.AdvancedCommerceInfo.Item(
            details: Transaction.AdvancedCommerceInfo.Item.Details(sku: "two", description: "two", displayName: "Two", price: 2)
        ),
        "renewal item"
    )
    expectDepth8(
        Product.SubscriptionInfo.Status(
            state: .subscribed,
            transaction: .verified(Transaction(id: 1, productID: "one", purchaseDate: Date())),
            renewalInfo: .verified(firstRenewal)
        ) != Product.SubscriptionInfo.Status(
            state: .expired,
            transaction: .verified(Transaction(id: 2, productID: "two", purchaseDate: Date())),
            renewalInfo: .verified(secondRenewal)
        ),
        "subscription status"
    )
}
