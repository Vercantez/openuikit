import Foundation
import StoreKit

private func expectDepth11(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private struct Depth11Error: Error {}

func testRequestReviewActionCallAsFunction() {
    let before = RequestReviewAction.portableRequestCount
    RequestReviewAction()()
    expectDepth11(RequestReviewAction.portableRequestCount == before + 1, "request review records portable call")
}

func testDisplayMessageActionFailsClosed() {
    let action = DisplayMessageAction()
    var threwNotAvailable = false
    do {
        try action(Message(reason: .generic))
    } catch StoreKitError.notAvailableInStorefront {
        threwNotAvailable = true
    } catch {
        threwNotAvailable = false
    }
    expectDepth11(threwNotAvailable, "display message fails closed without UI")
}

func testEntitlementTaskStateSyncMap() {
    let loading = EntitlementTaskState<Int>.loading
    let mappedLoading: EntitlementTaskState<String> = loading.map { "\($0)" }
    if case .loading = mappedLoading {
        expectDepth11(true, "map preserves loading")
    } else {
        expectDepth11(false, "map preserves loading")
    }
    let success = EntitlementTaskState<Int>.success(21)
    let mappedSuccess: EntitlementTaskState<Int> = success.map { $0 * 2 }
    expectDepth11(mappedSuccess.value == 42, "map transforms success value")
    let failure: EntitlementTaskState<Int> = .failure(Depth11Error())
    let mappedFailure: EntitlementTaskState<Int> = failure.map { $0 * 2 }
    expectDepth11(mappedFailure.value == nil, "map preserves failure")
    if case .failure = mappedFailure {
        expectDepth11(true, "map failure case")
    } else {
        expectDepth11(false, "map failure case")
    }
}

func testEntitlementTaskStateSyncFlatMap() {
    let loading = EntitlementTaskState<Int>.loading
    let flatLoading: EntitlementTaskState<Int> = loading.flatMap { .success($0) }
    if case .loading = flatLoading {
        expectDepth11(true, "flatMap preserves loading")
    } else {
        expectDepth11(false, "flatMap preserves loading")
    }
    let success = EntitlementTaskState<Int>.success(7)
    let flatSuccess: EntitlementTaskState<String> = success.flatMap { .success("n\($0)") }
    expectDepth11(flatSuccess.value == "n7", "flatMap transforms success value")
    let flatToFailure: EntitlementTaskState<String> = success.flatMap { _ in .failure(Depth11Error()) }
    expectDepth11(flatToFailure.value == nil, "flatMap can produce failure")
    let failure: EntitlementTaskState<Int> = .failure(Depth11Error())
    let flatFailure: EntitlementTaskState<Int> = failure.flatMap { .success($0) }
    expectDepth11(flatFailure.value == nil, "flatMap preserves failure")
}

func testOfferConfigurationSubscriptionModels() {
    var configuration = SubscriptionOfferViewStyleConfiguration()
    expectDepth11(configuration.activeOffer == nil, "default active offer is nil")
    expectDepth11(configuration.visibleSubscription == nil, "default visible subscription is nil")
    expectDepth11(configuration.subscriptions == nil, "default subscriptions is nil")
    expectDepth11(configuration.subscriptionStatus.isEmpty, "default subscription status is empty")
    expectDepth11(configuration.subscriptionGroupDisplayName.isEmpty, "default group name is empty")
    let offer = Product.SubscriptionOffer(id: "intro")
    configuration.activeOffer = offer
    expectDepth11(configuration.activeOffer == offer, "active offer round trip")
    configuration.visibleSubscription = nil
    expectDepth11(configuration.visibleSubscription == nil, "visible subscription round trip")
    configuration.subscriptions = []
    expectDepth11(configuration.subscriptions?.isEmpty == true, "subscriptions round trip")
    configuration.subscriptionStatus = []
    expectDepth11(configuration.subscriptionStatus.isEmpty, "subscription status round trip")
    configuration.subscriptionGroupDisplayName = "Premium"
    expectDepth11(configuration.subscriptionGroupDisplayName == "Premium", "group display name round trip")
    let before = SubscriptionOfferViewStyleConfiguration.portableDisplayDetailsCount
    configuration.displayDetails()
    expectDepth11(
        SubscriptionOfferViewStyleConfiguration.portableDisplayDetailsCount == before + 1,
        "displayDetails records portable call"
    )
}

func testProductIconPhasePromotionalIcon() {
    let loading = ProductIconPhase.loading
    expectDepth11(loading.promotionalIcon == nil, "promotional icon is nil without asset")
    let unavailable = ProductIconPhase.unavailable
    expectDepth11(unavailable.promotionalIcon == nil, "unavailable promotional icon is nil")
}
