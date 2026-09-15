import Foundation
import StoreKit

private func expectDepth10(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private struct Depth10Error: Error {}

private func depth10ControlConfiguration() -> SubscriptionStoreControlStyleConfiguration {
    SubscriptionStoreControlStyleConfiguration()
}

func testPickerControlStyleMembers() {
    let style = PickerSubscriptionStoreControlStyle()
    let automatic = PickerSubscriptionStoreControlStyle.Placement.automatic
    let `default` = PickerSubscriptionStoreControlStyle.Placement()
    expectDepth10(`default`.rawValue.rawValue == "picker", "picker default placement")
    let roundTrip = PickerSubscriptionStoreControlStyle.Placement(rawValue: automatic.rawValue)
    expectDepth10(roundTrip.rawValue == automatic.rawValue, "picker placement rawValue")
    expectDepth10(
        PickerSubscriptionStoreControlStyle.Placement.scrollView.rawValue
            == SubscriptionStoreControlPlacementKey.scrollView,
        "picker scrollView"
    )
    expectDepth10(
        PickerSubscriptionStoreControlStyle.Placement.buttonsInBottomBar.rawValue
            == SubscriptionStoreControlPlacementKey.buttonsInBottomBar,
        "picker buttonsInBottomBar"
    )
    let body: PickerSubscriptionStoreControlStyle.Body = style.makeBody(
        configuration: depth10ControlConfiguration()
    )
    _ = body
    _ = PickerSubscriptionStoreControlStyle.Placement.RawValue(rawValue: "picker")
}

func testButtonsControlStyleMembers() {
    let style = ButtonsSubscriptionStoreControlStyle()
    let automatic = ButtonsSubscriptionStoreControlStyle.Placement.automatic
    let `default` = ButtonsSubscriptionStoreControlStyle.Placement()
    expectDepth10(`default`.rawValue.rawValue == "buttons", "buttons default placement")
    let roundTrip = ButtonsSubscriptionStoreControlStyle.Placement(rawValue: automatic.rawValue)
    expectDepth10(roundTrip.rawValue == automatic.rawValue, "buttons placement rawValue")
    expectDepth10(
        ButtonsSubscriptionStoreControlStyle.Placement.scrollView.rawValue
            == SubscriptionStoreControlPlacementKey.scrollView,
        "buttons scrollView"
    )
    expectDepth10(
        ButtonsSubscriptionStoreControlStyle.Placement.bottomBar.rawValue
            == SubscriptionStoreControlPlacementKey.bottomBar,
        "buttons bottomBar"
    )
    let body: ButtonsSubscriptionStoreControlStyle.Body = style.makeBody(
        configuration: depth10ControlConfiguration()
    )
    _ = body
    _ = ButtonsSubscriptionStoreControlStyle.Placement.RawValue(rawValue: "buttons")
}

func testAutomaticControlStyleMembers() {
    let style = AutomaticSubscriptionStoreControlStyle()
    let automatic = AutomaticSubscriptionStoreControlStyle.Placement.automatic
    let `default` = AutomaticSubscriptionStoreControlStyle.Placement()
    expectDepth10(`default`.rawValue.rawValue == "automatic", "automatic default placement")
    let roundTrip = AutomaticSubscriptionStoreControlStyle.Placement(
        rawValue: automatic.rawValue
    )
    expectDepth10(roundTrip.rawValue == automatic.rawValue, "automatic placement rawValue")
    let body: AutomaticSubscriptionStoreControlStyle.Body = style.makeBody(
        configuration: depth10ControlConfiguration()
    )
    _ = body
    _ = AutomaticSubscriptionStoreControlStyle.Placement.RawValue(rawValue: "automatic")

    let placement = AutomaticSubscriptionStoreControlPlacement()
    expectDepth10(placement.rawValue.rawValue == "automatic", "control placement default")
    let placementRoundTrip = AutomaticSubscriptionStoreControlPlacement(
        rawValue: placement.rawValue
    )
    expectDepth10(
        placementRoundTrip.rawValue == SubscriptionStoreControlPlacementKey(rawValue: "automatic"),
        "control placement rawValue"
    )
    _ = AutomaticSubscriptionStoreControlPlacement.RawValue(rawValue: "automatic")
    let inferred: AutomaticSubscriptionStoreControlPlacement = .automatic
    expectDepth10(inferred.rawValue.rawValue == "automatic", "protocol automatic")
}

func testPagedPickerControlStyleMembers() {
    let style = PagedPickerSubscriptionStoreControlStyle()
    let automatic = PagedPickerSubscriptionStoreControlStyle.Placement.automatic
    let `default` = PagedPickerSubscriptionStoreControlStyle.Placement()
    expectDepth10(`default`.rawValue.rawValue == "paged", "paged default placement")
    let roundTrip = PagedPickerSubscriptionStoreControlStyle.Placement(
        rawValue: automatic.rawValue
    )
    expectDepth10(roundTrip.rawValue == automatic.rawValue, "paged placement rawValue")
    expectDepth10(
        PagedPickerSubscriptionStoreControlStyle.Placement.scrollView.rawValue
            == SubscriptionStoreControlPlacementKey.scrollView,
        "paged scrollView"
    )
    expectDepth10(
        PagedPickerSubscriptionStoreControlStyle.Placement.bottomBar.rawValue
            == SubscriptionStoreControlPlacementKey.bottomBar,
        "paged bottomBar"
    )
    expectDepth10(
        PagedPickerSubscriptionStoreControlStyle.Placement.buttonsInBottomBar.rawValue
            == SubscriptionStoreControlPlacementKey.buttonsInBottomBar,
        "paged buttonsInBottomBar"
    )
    let body: PagedPickerSubscriptionStoreControlStyle.Body = style.makeBody(
        configuration: depth10ControlConfiguration()
    )
    _ = body
    _ = PagedPickerSubscriptionStoreControlStyle.Placement.RawValue(rawValue: "paged")
}

func testCompactPickerControlStyleMembers() {
    let style = CompactPickerSubscriptionStoreControlStyle()
    let automatic = CompactPickerSubscriptionStoreControlStyle.Placement.automatic
    let `default` = CompactPickerSubscriptionStoreControlStyle.Placement()
    expectDepth10(`default`.rawValue.rawValue == "compact", "compact default placement")
    let roundTrip = CompactPickerSubscriptionStoreControlStyle.Placement(
        rawValue: automatic.rawValue
    )
    expectDepth10(roundTrip.rawValue == automatic.rawValue, "compact placement rawValue")
    expectDepth10(
        CompactPickerSubscriptionStoreControlStyle.Placement.scrollView.rawValue
            == SubscriptionStoreControlPlacementKey.scrollView,
        "compact scrollView"
    )
    expectDepth10(
        CompactPickerSubscriptionStoreControlStyle.Placement.bottomBar.rawValue
            == SubscriptionStoreControlPlacementKey.bottomBar,
        "compact bottomBar"
    )
    expectDepth10(
        CompactPickerSubscriptionStoreControlStyle.Placement.buttonsInBottomBar.rawValue
            == SubscriptionStoreControlPlacementKey.buttonsInBottomBar,
        "compact buttonsInBottomBar"
    )
    let body: CompactPickerSubscriptionStoreControlStyle.Body = style.makeBody(
        configuration: depth10ControlConfiguration()
    )
    _ = body
    _ = CompactPickerSubscriptionStoreControlStyle.Placement.RawValue(rawValue: "compact")
}

func testProminentPickerControlStyleMembers() {
    let prominent = ProminentPickerSubscriptionStoreControlStyle()
    let prominentBody: ProminentPickerSubscriptionStoreControlStyle.Body = prominent.makeBody(
        configuration: depth10ControlConfiguration()
    )
    _ = prominentBody
    _ = ProminentPickerSubscriptionStoreControlStyle.Placement.self
    let paged = PagedProminentPickerSubscriptionStoreControlStyle()
    let pagedBody: PagedProminentPickerSubscriptionStoreControlStyle.Body = paged.makeBody(
        configuration: depth10ControlConfiguration()
    )
    _ = pagedBody
    _ = PagedProminentPickerSubscriptionStoreControlStyle.Placement.self
}

func testControlStyleProtocolWitnesses() {
    let configuration = SubscriptionStoreControlStyleConfiguration()
    let style = PickerSubscriptionStoreControlStyle()
    let body: PickerSubscriptionStoreControlStyle.Body = style.makeBody(
        configuration: configuration
    )
    _ = body
    let placement: PickerSubscriptionStoreControlStyle.Placement = .automatic
    _ = placement
    let automaticStyle: AutomaticSubscriptionStoreControlStyle = .automatic
    _ = automaticStyle.makeBody(configuration: configuration)
    let pickerStyle: PickerSubscriptionStoreControlStyle = .picker
    _ = pickerStyle.makeBody(configuration: configuration)
    let buttonsStyle: ButtonsSubscriptionStoreControlStyle = .buttons
    _ = buttonsStyle.makeBody(configuration: configuration)
}

func testProductViewStyleBodies() {
    let configuration = ProductViewStyleConfiguration()
    let large = LargeProductViewStyle()
    let largeBody: LargeProductViewStyle.Body = large.makeBody(configuration: configuration)
    _ = largeBody
    let compact = CompactProductViewStyle()
    let compactBody: CompactProductViewStyle.Body = compact.makeBody(
        configuration: configuration
    )
    _ = compactBody
    let regular = RegularProductViewStyle()
    let regularBody: RegularProductViewStyle.Body = regular.makeBody(
        configuration: configuration
    )
    _ = regularBody
    let automatic = AutomaticProductViewStyle()
    let automaticBody: AutomaticProductViewStyle.Body = automatic.makeBody(
        configuration: configuration
    )
    _ = automaticBody
    let largeStatic: LargeProductViewStyle = .large
    let regularStatic: RegularProductViewStyle = .regular
    _ = largeStatic.makeBody(configuration: configuration)
    _ = regularStatic.makeBody(configuration: configuration)
}

func testSubscriptionOfferViewStyleBodies() {
    let configuration = SubscriptionOfferViewStyleConfiguration()
    let compact = CompactSubscriptionOfferViewStyle()
    let compactBody: CompactSubscriptionOfferViewStyle.Body = compact.makeBody(
        configuration: configuration
    )
    _ = compactBody
    let automatic = AutomaticSubscriptionOfferViewStyle()
    let automaticBody: AutomaticSubscriptionOfferViewStyle.Body = automatic.makeBody(
        configuration: configuration
    )
    _ = automaticBody
    let compactStatic: CompactSubscriptionOfferViewStyle = .compact
    let automaticStatic: AutomaticSubscriptionOfferViewStyle = .automatic
    _ = compactStatic.makeBody(configuration: configuration)
    _ = automaticStatic.makeBody(configuration: configuration)
}

func testProductIconPhaseCases() {
    let loading = ProductIconPhase.loading
    expectDepth10(loading.errors == nil, "loading has no error")
    let unavailable = ProductIconPhase.unavailable
    expectDepth10(unavailable.errors == nil, "unavailable has no error")
    let success = ProductIconPhase.success(Image())
    expectDepth10(success.errors == nil, "success has no error")
    if case .success = success {
        expectDepth10(true, "success case")
    } else {
        expectDepth10(false, "success case")
    }
    let failure = ProductIconPhase.failure(Depth10Error())
    expectDepth10(failure.errors is Depth10Error, "failure carries error")
    if case .failure = failure {
        expectDepth10(true, "failure case")
    } else {
        expectDepth10(false, "failure case")
    }
    if case .loading = loading {
        expectDepth10(true, "loading case")
    } else {
        expectDepth10(false, "loading case")
    }
}

func testEntitlementTaskStateCases() {
    let loading = EntitlementTaskState<Int>.loading
    expectDepth10(loading.value == nil, "loading has no value")
    let success = EntitlementTaskState<Int>.success(3)
    expectDepth10(success.value == 3, "success value")
    let failure = EntitlementTaskState<Int>.failure(Depth10Error())
    expectDepth10(failure.value == nil, "failure has no value")
    if case .success(let number) = success {
        expectDepth10(number == 3, "success payload")
    } else {
        expectDepth10(false, "success payload")
    }
    if case .failure = failure {
        expectDepth10(true, "failure case")
    } else {
        expectDepth10(false, "failure case")
    }
    if case .loading = loading {
        expectDepth10(true, "loading case")
    } else {
        expectDepth10(false, "loading case")
    }
}

func testStoreContentProtocolSurface() {
    let empty = EmptyStoreContent()
    let emptyBody: EmptyStoreContent = empty.body
    _ = emptyBody
    let tuple = TupleStoreContent<EmptyStoreContent>()
    let tupleBody: EmptyStoreContent = tuple.body
    _ = tupleBody
    _ = TupleStoreContent<EmptyStoreContent>.Body.self
    let identified = IdentifiedStoreContent<EmptyView>()
    _ = identified
    func acceptsStoreContent(_ content: some StoreContent) -> Bool { _ = content; return true }
    expectDepth10(acceptsStoreContent(empty), "StoreContent protocol")
    expectDepth10(acceptsStoreContent(tuple), "tuple StoreContent")
}

func testStoreContentBuilderSurface() {
    let single = StoreContentBuilder.buildBlock(EmptyStoreContent())
    _ = single
    let empty = StoreContentBuilder.buildBlock()
    _ = empty
    let first: EmptyStoreContent = StoreContentBuilder.buildEither(first: EmptyStoreContent())
    _ = first
    let second: EmptyStoreContent = StoreContentBuilder.buildEither(
        second: EmptyStoreContent()
    )
    _ = second
    let expressed = StoreContentBuilder.buildExpression(EmptyStoreContent())
    _ = expressed
    _ = StoreContentBuilder.self
}

func testSubscriptionStoreViewInits() {
    let plain = SubscriptionStoreView<EmptyView>()
    _ = plain.body
    let byIDs = SubscriptionStoreView<EmptyView>(productIDs: ["plus.monthly"]) {
        EmptyView()
    }
    _ = byIDs.body
    let byGroup = SubscriptionStoreView<EmptyView>(groupID: "plus") { EmptyView() }
    _ = byGroup.body
    let byProducts = SubscriptionStoreView<EmptyView>(
        subscriptions: [Product(id: "plus.monthly")]
    ) {
        EmptyView()
    }
    _ = byProducts.body
    _ = SubscriptionStoreView<EmptyView>.Body.self
}

func testStoreViewInits() {
    let plain = StoreView<EmptyView, EmptyView>()
    _ = plain.body
    let byIDs = StoreView<EmptyView, EmptyView>(ids: ["plus.monthly"])
    _ = byIDs.body
    let byProducts = StoreView<EmptyView, EmptyView>(products: [Product(id: "plus.monthly")])
    _ = byProducts.body
    let withIcon = StoreView<EmptyView, EmptyView>(ids: ["plus.monthly"]) { EmptyView() }
    _ = withIcon.body
    let withProductIcon = StoreView<EmptyView, EmptyView>(
        products: [Product(id: "plus.monthly")]
    ) {
        EmptyView()
    }
    _ = withProductIcon.body
    let phased = StoreView<EmptyView, EmptyView>(
        ids: ["plus.monthly"],
        icon: { _ in EmptyView() },
        placeholderIcon: { EmptyView() }
    )
    _ = phased.body
    let phasedProducts = StoreView<EmptyView, EmptyView>(
        products: [Product(id: "plus.monthly")],
        icon: { _ in EmptyView() },
        placeholderIcon: { EmptyView() }
    )
    _ = phasedProducts.body
    _ = StoreView<EmptyView, EmptyView>.Body.self
}

func testProductViewInits() {
    let plain = ProductView<EmptyView, EmptyView>()
    _ = plain.body
    let byID = ProductView<EmptyView, EmptyView>(id: "plus.monthly")
    _ = byID.body
    let byProduct = ProductView<EmptyView, EmptyView>(Product(id: "plus.monthly"))
    _ = byProduct.body
    let idIcon = ProductView<EmptyView, EmptyView>(id: "plus.monthly") { EmptyView() }
    _ = idIcon.body
    let productIcon = ProductView<EmptyView, EmptyView>(Product(id: "plus.monthly")) {
        EmptyView()
    }
    _ = productIcon.body
    let phased = ProductView<EmptyView, EmptyView>(
        id: "plus.monthly",
        icon: { _ in EmptyView() },
        placeholderIcon: { EmptyView() }
    )
    _ = phased.body
    _ = ProductView<EmptyView, EmptyView>.Body.self
}

func testSubscriptionOfferViewInits() {
    let plain = SubscriptionOfferView<EmptyView, EmptyView>()
    _ = plain.body
    let byProduct = SubscriptionOfferView<EmptyView, EmptyView>(Product(id: "plus.monthly"))
    _ = byProduct.body
    let byID = SubscriptionOfferView<EmptyView, EmptyView>(id: "plus.monthly")
    _ = byID.body
    let productIcon = SubscriptionOfferView<EmptyView, EmptyView>(
        Product(id: "plus.monthly")
    ) {
        EmptyView()
    }
    _ = productIcon.body
    let idIcon = SubscriptionOfferView<EmptyView, EmptyView>(id: "plus.monthly") {
        EmptyView()
    }
    _ = idIcon.body
    let phasedProduct = SubscriptionOfferView<EmptyView, EmptyView>(
        Product(id: "plus.monthly"),
        icon: { _ in EmptyView() },
        placeholderIcon: { EmptyView() }
    )
    _ = phasedProduct.body
    let phasedID = SubscriptionOfferView<EmptyView, EmptyView>(
        id: "plus.monthly",
        icon: { _ in EmptyView() },
        placeholderIcon: { EmptyView() }
    )
    _ = phasedID.body
    let byGroup = SubscriptionOfferView<EmptyView, EmptyView>(
        groupID: "plus",
        visibleRelationship: .current,
        useAppIcon: true
    )
    _ = byGroup.body
    _ = SubscriptionOfferView<EmptyView, EmptyView>.Body.self
}

func testSubscriptionPickerSurface() {
    let button = SubscriptionStoreButton()
    _ = button.body
    _ = SubscriptionStoreButton.Body.self
    let picker = SubscriptionStorePicker<EmptyView, EmptyView>()
    _ = picker.body
    _ = SubscriptionStorePicker<EmptyView, EmptyView>.Body.self
    let option = SubscriptionStorePickerOption<EmptyView>()
    _ = option.body
    _ = SubscriptionStorePickerOption<EmptyView>.Body.self
    let content = SubscriptionStoreContentView<EmptyStoreContent>()
    _ = content.body
    _ = SubscriptionStoreContentView<EmptyStoreContent>.Body.self
    let configured = SubscriptionStoreButton()
    _ = configured.body
}

func testAutomaticContentViews() {
    let marketing = AutomaticSubscriptionStoreMarketingContent()
    _ = marketing.body
    _ = AutomaticSubscriptionStoreMarketingContent.Body.self
    let label = AutomaticSubscriptionStorePickerOptionLabel()
    _ = label.body
    _ = AutomaticSubscriptionStorePickerOptionLabel.Body.self
    let placeholder = AutomaticProductPlaceholderIcon()
    _ = placeholder.body
    _ = AutomaticProductPlaceholderIcon.Body.self
    let groupLabel = AutomaticSubscriptionOptionGroupLabel()
    _ = groupLabel.body
    _ = AutomaticSubscriptionOptionGroupLabel.Body.self
}

func testOptionGroupStyleInits() {
    let tabs = TabsSubscriptionOptionGroupStyle()
    _ = tabs
    let links = LinksSubscriptionOptionGroupStyle()
    _ = links
    let automatic = AutomaticSubscriptionOptionGroupStyle()
    _ = automatic
    let output = SubscriptionOptionGroupStyleOutput()
    _ = output
    let tabsStatic: TabsSubscriptionOptionGroupStyle = .tabs
    let linksStatic: LinksSubscriptionOptionGroupStyle = .links
    let automaticStatic: AutomaticSubscriptionOptionGroupStyle = .automatic
    _ = tabsStatic
    _ = linksStatic
    _ = automaticStatic
    func acceptsOptionGroupStyle(_ style: some SubscriptionOptionGroupStyle) -> Bool {
        _ = style
        return true
    }
    expectDepth10(acceptsOptionGroupStyle(tabs), "option group style protocol")
}

func testStoreKitActionTypes() {
    let purchase = PurchaseAction()
    _ = purchase
    let review = RequestReviewAction()
    _ = review
    let message = DisplayMessageAction()
    _ = message
}

func testOfferViewStyleConfigurationSurface() {
    let configuration = SubscriptionOfferViewStyleConfiguration()
    let iconBody: SubscriptionOfferViewStyleConfiguration.Icon.Body = configuration.icon.body
    _ = iconBody
    _ = SubscriptionOfferViewStyleConfiguration.Icon.self
    _ = SubscriptionOfferViewStyleConfiguration.Icon.Body.self
    if case .loading = configuration.state {
        expectDepth10(true, "offer configuration default state")
    } else {
        expectDepth10(false, "offer configuration default state")
    }
    configuration.subscribe()
}

func testOptionGroupSurface() {
    let group = SubscriptionOptionGroup<EmptyView, EmptyView, EmptyView>()
    _ = group.body
    _ = SubscriptionOptionGroup<EmptyView, EmptyView, EmptyView>.Body.self
    let section = SubscriptionOptionSection<EmptyView, EmptyView, EmptyView>()
    _ = section.body
    _ = SubscriptionOptionSection<EmptyView, EmptyView, EmptyView>.Body.self
    let groupSet = SubscriptionOptionGroupSet<String, EmptyView, EmptyView>()
    _ = groupSet.body
    _ = SubscriptionOptionGroupSet<String, EmptyView, EmptyView>.Body.self
    let periodSet = SubscriptionPeriodGroupSet<EmptyView, EmptyView>()
    _ = periodSet.body
    _ = SubscriptionPeriodGroupSet<EmptyView, EmptyView>.Body.self
    func acceptsStoreContent(_ content: some StoreContent) -> Bool { _ = content; return true }
    expectDepth10(acceptsStoreContent(group), "option group StoreContent")
    expectDepth10(acceptsStoreContent(section), "option section StoreContent")
    expectDepth10(acceptsStoreContent(groupSet), "option group set StoreContent")
    expectDepth10(acceptsStoreContent(periodSet), "period group set StoreContent")
}

func testStoreContentInequalityWitnesses() {
    expectDepth10(
        SubscriptionStorePolicyKind.privacyPolicy != .termsOfService,
        "policy kind inequality"
    )
    expectDepth10(
        SubscriptionStoreButtonLabel.automatic != .action,
        "button label inequality"
    )
    expectDepth10(
        SubscriptionStoreControlPlacementKey.scrollView != .bottomBar,
        "placement key inequality"
    )
    let first = SubscriptionStoreControlStyleConfiguration.Option(
        subscription: Product(id: "a")
    )
    let second = SubscriptionStoreControlStyleConfiguration.Option(
        subscription: Product(id: "b")
    )
    expectDepth10(first != second, "configuration option inequality")
    let picked = SubscriptionStoreControlStyleConfiguration.PickerOption(
        subscription: Product(id: "a"),
        isSelected: true
    )
    let unpicked = SubscriptionStoreControlStyleConfiguration.PickerOption(
        subscription: Product(id: "a"),
        isSelected: false
    )
    expectDepth10(picked != unpicked, "picker option inequality")
    expectDepth10(
        SubscriptionStoreControlStyleConfiguration.Section.ID()
            == SubscriptionStoreControlStyleConfiguration.Section.ID(),
        "section id equality"
    )
}
