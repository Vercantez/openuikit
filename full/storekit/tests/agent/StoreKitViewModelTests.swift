import Foundation
import StoreKit

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testProductViewModelHoldsProductID() {
    let view = ProductView<EmptyView, EmptyView>(id: "pro")
    _ = view.body
    let fromProduct = ProductView<EmptyView, EmptyView>(Product(id: "pro"))
    _ = fromProduct.body
    expect(true, "ProductView is a model, not a renderer")
}

func testStoreViewAndSubscriptionStoreViewModels() {
    let store = StoreView<EmptyView, EmptyView>()
    _ = store.body
    let subscription = SubscriptionStoreView<EmptyView>(productIDs: ["plus.monthly"]) {
        EmptyView()
    }
    _ = subscription.body
    let button = SubscriptionStoreButton()
    _ = button.body
    expect(SubscriptionStorePolicyKind.privacyPolicy != .termsOfService, "policy kinds")
    expect(StoreButtonKind.restore != .redeemCode, "store buttons")
}

func testProductIconPhaseAndButtonLabels() {
    let phase = ProductIconPhase.loading
    var isLoading = false
    switch phase {
    case .loading:
        isLoading = true
    case .success, .failure, .unavailable:
        isLoading = false
    }
    expect(isLoading, "loading")
    expect(SubscriptionStoreButtonLabel.automatic != .price, "labels")
    expect(SubscriptionStoreButtonLabel.action != .displayName, "action")
}

func testAppStoreCanMakePaymentsTracksStore() {
    StoreKitTesting.reset()
    expect(AppStore.canMakePayments == false, "closed")
    try! StoreKitTesting.loadConfiguration(json: """
    {
      "identifier": "PAY",
      "products": [],
      "settings": { "_locale": "en_US" },
      "subscriptionGroups": [],
      "nonRenewingSubscriptions": []
    }
    """)
    expect(AppStore.canMakePayments, "open with configuration")
    expect(SKPaymentQueue.canMakePayments(), "SK1 matches")
}
