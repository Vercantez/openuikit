import Foundation
import StoreKit

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private func exerciseStoreContentModifiers<Content: StoreContent>(_ content: Content) {
    _ = content.subscriptionStoreButtonLabel(.automatic)
    _ = content.subscriptionStoreControlStyle(
        AutomaticSubscriptionStoreControlStyle(),
        placement: .automatic
    )
    _ = content.subscriptionStoreOptionGroupStyle(AutomaticSubscriptionOptionGroupStyle())
    _ = content.subscriptionStoreControlBackground(SubscriptionStoreControlBackground())
    _ = content.subscriptionStoreControlBackground(Color.clear)
    _ = content.subscriptionStorePickerItemBackground(Color.clear, in: Rectangle())
    _ = content.subscriptionStorePickerItemBackground(Color.clear)
    _ = content.storeButton(.visible, for: .restore, .redeemCode)
    _ = content.productDescription(.hidden)
}

func testStoreContentProtocolModifiers() {
    exerciseStoreContentModifiers(EmptyStoreContent())
}

func testTupleStoreContentModifiers() {
    exerciseStoreContentModifiers(TupleStoreContent<EmptyStoreContent>())
}

func testSubscriptionOptionGroupStoreContentModifiers() {
    exerciseStoreContentModifiers(
        SubscriptionOptionGroup<EmptyView, EmptyView, EmptyView>()
    )
}

func testSubscriptionOptionSectionStoreContentModifiers() {
    exerciseStoreContentModifiers(
        SubscriptionOptionSection<EmptyView, EmptyView, EmptyView>()
    )
}

func testSubscriptionOptionGroupSetStoreContentModifiers() {
    exerciseStoreContentModifiers(
        SubscriptionOptionGroupSet<String, EmptyView, EmptyView>()
    )
}

func testSubscriptionPeriodGroupSetStoreContentModifiers() {
    exerciseStoreContentModifiers(
        SubscriptionPeriodGroupSet<EmptyView, EmptyView>()
    )
}

func testProductViewStyleStatics() {
    let automatic: AutomaticProductViewStyle = .automatic
    let large: LargeProductViewStyle = .large
    let regular: RegularProductViewStyle = .regular
    _ = automatic
    _ = large
    _ = regular
    expect(true, "ProductViewStyle.automatic/large/regular are model-level")
}

func testSubscriptionOverlayStyleStatics() {
    let control: AutomaticSubscriptionStoreControlStyle = .automatic
    let offer: AutomaticSubscriptionOfferViewStyle = .automatic
    let group: AutomaticSubscriptionOptionGroupStyle = .automatic
    _ = control
    _ = offer
    _ = group
    expect(true, "subscription overlay .automatic styles construct")
}

func testEnvironmentStoreKitActions() {
    let values = EnvironmentValues()
    _ = values.displayStoreKitMessage
    _ = values.requestReview
    _ = values.purchase
}

func testContainerBackgroundPlacementStoreKit() {
    expect(
        ContainerBackgroundPlacement.subscriptionStore
            != ContainerBackgroundPlacement.subscriptionStoreHeader,
        "subscriptionStore vs header"
    )
    expect(
        ContainerBackgroundPlacement.subscriptionStoreFullHeight
            != ContainerBackgroundPlacement.subscriptionStore,
        "fullHeight vs store"
    )
    expect(
        ContainerBackgroundPlacement.subscriptionStoreHeader
            != ContainerBackgroundPlacement.subscriptionStoreFullHeight,
        "header vs fullHeight"
    )
}
