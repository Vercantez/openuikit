import Foundation
import StoreKit

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testStoreKitNotificationNames() {
    expect(
        SKCloudServiceCapabilitiesDidChangeNotification.rawValue
            == "SKCloudServiceCapabilitiesDidChangeNotification",
        "capabilities"
    )
    expect(
        SKStorefrontCountryCodeDidChangeNotification.rawValue
            == "SKStorefrontCountryCodeDidChangeNotification",
        "country"
    )
    expect(
        SKStorefrontIdentifierDidChangeNotification.rawValue
            == "SKStorefrontIdentifierDidChangeNotification",
        "identifier"
    )
    expect(
        Notification.Name.SKCloudServiceCapabilitiesDidChange
            == SKCloudServiceCapabilitiesDidChangeNotification,
        "name alias"
    )
}

func testSKAdImpressionAdType() {
    let impression = SKAdImpression()
    expect(impression.adType == nil, "blank adType")
    impression.adType = "video"
    expect(impression.adType == "video", "set adType")
}

func testDateComponentsSubscriptionPeriod() {
    let monthly = DateComponents(subscriptionPeriod: .monthly)
    expect(monthly.month == 1, "month")
    let weekly = DateComponents(subscriptionPeriod: .weekly)
    expect(weekly.weekOfYear == 1, "week")
    let yearly = DateComponents(subscriptionPeriod: Product.SubscriptionPeriod(value: 2, unit: .year))
    expect(yearly.year == 2, "year")
    let daily = DateComponents(subscriptionPeriod: Product.SubscriptionPeriod(value: 3, unit: .day))
    expect(daily.day == 3, "day")
}

func testSKRawValueInits() {
    expect(SKDownloadState(rawValue: 4) == .failed, "download")
    expect(SKOverlay.Position(rawValue: 1) == .bottomRaised, "overlay")
    expect(SKCloudServiceCapability(rawValue: 1 << 0) == .musicCatalogPlayback, "capability")
    expect(SKCloudServiceAuthorizationStatus(rawValue: 3) == .authorized, "status")
}

func testSubscriptionStoreButtonLabelValues() {
    expect(SubscriptionStoreButtonLabel.automatic != .multiline, "auto vs multi")
    expect(SubscriptionStoreButtonLabel.multiline != .singleLine, "multi vs single")
    expect(SubscriptionStoreButtonLabel.action.multiline == .multiline, "instance multiline")
    expect(SubscriptionStoreButtonLabel.price.singleLine == .singleLine, "instance single")
    expect(SubscriptionStoreButtonLabel.displayName.action == .action, "instance action")
    _ = SubscriptionStoreButtonLabel.automatic.hashValue
}

func testSubscriptionStorePolicyKindValues() {
    expect(SubscriptionStorePolicyKind.privacyPolicy != .termsOfService, "kinds")
    expect(
        SubscriptionStorePolicyKind.privacyPolicy.hashValue
            != SubscriptionStorePolicyKind.termsOfService.hashValue
            || SubscriptionStorePolicyKind.privacyPolicy != .termsOfService,
        "hash or inequality"
    )
}

func testStoreButtonKindValues() {
    expect(StoreButtonKind.restore != .restorePurchases, "restore vs restorePurchases")
    expect(StoreButtonKind.signIn != .redeemCode, "signIn")
    expect(StoreButtonKind.policies != .cancellation, "policies")
}

func testSubscriptionOfferViewButtonKindValues() {
    expect(SubscriptionOfferViewButtonKind.redeemCode != .detailLink, "detailLink")
}

func testSubscriptionStoreControlBackgroundValues() {
    expect(
        SubscriptionStoreControlBackground.automatic
            != SubscriptionStoreControlBackground.gradientMaterial,
        "automatic vs material"
    )
    expect(
        SubscriptionStoreControlBackground.gradientMaterialOnScroll
            != SubscriptionStoreControlBackground.gradientMaterial,
        "onScroll vs material"
    )
}

func testControlPlacementKeyValues() {
    expect(
        SubscriptionStoreControlPlacementKey.scrollView
            != SubscriptionStoreControlPlacementKey.bottomBar,
        "scroll vs bar"
    )
    expect(
        SubscriptionStoreControlPlacementKey.buttonsInBottomBar.rawValue
            == "buttonsInBottomBar",
        "buttonsInBottomBar"
    )
    _ = SubscriptionStoreControlPlacementKey.scrollView.hashValue
}

private func readPlacementAutomatic<P: SubscriptionStoreControlPlacement>(_: P.Type) -> P {
    .automatic
}

func testControlPlacementStatics() {
    expect(
        readPlacementAutomatic(AutomaticSubscriptionStoreControlPlacement.self).rawValue.rawValue
            == "automatic",
        "protocol automatic"
    )
    expect(
        AutomaticSubscriptionStoreControlPlacement.automatic.rawValue.rawValue == "automatic",
        "auto placement"
    )
    expect(
        AutomaticSubscriptionStoreControlPlacement.scrollView.rawValue == .scrollView,
        "auto scroll"
    )
    expect(
        AutomaticSubscriptionStoreControlPlacement.bottomBar.rawValue == .bottomBar,
        "auto bar"
    )
    expect(
        AutomaticSubscriptionStoreControlPlacement.buttonsInBottomBar.rawValue
            == .buttonsInBottomBar,
        "auto buttons bar"
    )
    expect(
        PickerSubscriptionStoreControlStyle.Placement.scrollView.rawValue == .scrollView,
        "picker scroll"
    )
    expect(
        PickerSubscriptionStoreControlStyle.Placement.buttonsInBottomBar.rawValue
            == .buttonsInBottomBar,
        "picker buttons bar"
    )
    expect(
        ButtonsSubscriptionStoreControlStyle.Placement.scrollView.rawValue == .scrollView,
        "buttons scroll"
    )
    expect(
        ButtonsSubscriptionStoreControlStyle.Placement.bottomBar.rawValue == .bottomBar,
        "buttons bar"
    )
    expect(
        PagedPickerSubscriptionStoreControlStyle.Placement.scrollView.rawValue == .scrollView,
        "paged scroll"
    )
    expect(
        PagedPickerSubscriptionStoreControlStyle.Placement.bottomBar.rawValue == .bottomBar,
        "paged bar"
    )
    expect(
        PagedPickerSubscriptionStoreControlStyle.Placement.buttonsInBottomBar.rawValue
            == .buttonsInBottomBar,
        "paged buttons bar"
    )
    expect(
        CompactPickerSubscriptionStoreControlStyle.Placement.scrollView.rawValue == .scrollView,
        "compact scroll"
    )
    expect(
        CompactPickerSubscriptionStoreControlStyle.Placement.bottomBar.rawValue == .bottomBar,
        "compact bar"
    )
    expect(
        CompactPickerSubscriptionStoreControlStyle.Placement.buttonsInBottomBar.rawValue
            == .buttonsInBottomBar,
        "compact buttons bar"
    )
}

func testSubscriptionControlStyleStatics() {
    let picker: PickerSubscriptionStoreControlStyle = .picker
    let buttons: ButtonsSubscriptionStoreControlStyle = .buttons
    let compact: CompactPickerSubscriptionStoreControlStyle = .compactPicker
    let paged: PagedPickerSubscriptionStoreControlStyle = .pagedPicker
    let prominent: ProminentPickerSubscriptionStoreControlStyle = .prominentPicker
    let pagedProminent: PagedProminentPickerSubscriptionStoreControlStyle = .pagedProminentPicker
    _ = picker
    _ = buttons
    _ = compact
    _ = paged
    _ = prominent
    _ = pagedProminent
}

func testProductAndOfferViewStyleStatics() {
    let compactProduct: CompactProductViewStyle = .compact
    let compactOffer: CompactSubscriptionOfferViewStyle = .compact
    let tabs: TabsSubscriptionOptionGroupStyle = .tabs
    let links: LinksSubscriptionOptionGroupStyle = .links
    _ = compactProduct
    _ = compactOffer
    _ = tabs
    _ = links
}

func testSubscribeButtonTypealiases() {
    let protocolButton: SubscriptionStoreControlStyle.SubscribeButton = SubscriptionStoreButton()
    _ = protocolButton.body
    _ = AutomaticSubscriptionStoreControlStyle.SubscribeButton()
    _ = PickerSubscriptionStoreControlStyle.SubscribeButton()
    _ = ButtonsSubscriptionStoreControlStyle.SubscribeButton()
    _ = CompactPickerSubscriptionStoreControlStyle.SubscribeButton()
    _ = PagedPickerSubscriptionStoreControlStyle.SubscribeButton()
    _ = ProminentPickerSubscriptionStoreControlStyle.SubscribeButton()
    _ = PagedProminentPickerSubscriptionStoreControlStyle.SubscribeButton()
}

func testSubscriptionPickerTypealiases() {
    let protocolPicker: SubscriptionStoreControlStyle.SubscriptionPicker =
        SubscriptionStorePicker<EmptyView, EmptyView>()
    _ = protocolPicker.body
    let automatic: AutomaticSubscriptionStoreControlStyle.SubscriptionPicker =
        SubscriptionStorePicker<EmptyView, EmptyView>()
    let picker: PickerSubscriptionStoreControlStyle.SubscriptionPicker =
        SubscriptionStorePicker<EmptyView, EmptyView>()
    let buttons: ButtonsSubscriptionStoreControlStyle.SubscriptionPicker =
        SubscriptionStorePicker<EmptyView, EmptyView>()
    let compact: CompactPickerSubscriptionStoreControlStyle.SubscriptionPicker =
        SubscriptionStorePicker<EmptyView, EmptyView>()
    let paged: PagedPickerSubscriptionStoreControlStyle.SubscriptionPicker =
        SubscriptionStorePicker<EmptyView, EmptyView>()
    let prominent: ProminentPickerSubscriptionStoreControlStyle.SubscriptionPicker =
        SubscriptionStorePicker<EmptyView, EmptyView>()
    let pagedProminent: PagedProminentPickerSubscriptionStoreControlStyle.SubscriptionPicker =
        SubscriptionStorePicker<EmptyView, EmptyView>()
    _ = automatic.body
    _ = picker.body
    _ = buttons.body
    _ = compact.body
    _ = paged.body
    _ = prominent.body
    _ = pagedProminent.body
}

func testSubscriptionPickerOptionTypealiases() {
    let protocolOption: SubscriptionStoreControlStyle.SubscriptionPickerOption =
        SubscriptionStorePickerOption<EmptyView>()
    _ = protocolOption.body
    let automatic: AutomaticSubscriptionStoreControlStyle.SubscriptionPickerOption =
        SubscriptionStorePickerOption<EmptyView>()
    let picker: PickerSubscriptionStoreControlStyle.SubscriptionPickerOption =
        SubscriptionStorePickerOption<EmptyView>()
    let buttons: ButtonsSubscriptionStoreControlStyle.SubscriptionPickerOption =
        SubscriptionStorePickerOption<EmptyView>()
    let compact: CompactPickerSubscriptionStoreControlStyle.SubscriptionPickerOption =
        SubscriptionStorePickerOption<EmptyView>()
    let paged: PagedPickerSubscriptionStoreControlStyle.SubscriptionPickerOption =
        SubscriptionStorePickerOption<EmptyView>()
    let prominent: ProminentPickerSubscriptionStoreControlStyle.SubscriptionPickerOption =
        SubscriptionStorePickerOption<EmptyView>()
    let pagedProminent: PagedProminentPickerSubscriptionStoreControlStyle.SubscriptionPickerOption =
        SubscriptionStorePickerOption<EmptyView>()
    _ = automatic.body
    _ = picker.body
    _ = buttons.body
    _ = compact.body
    _ = paged.body
    _ = prominent.body
    _ = pagedProminent.body
}

func testStoreContentBuilderConditionals() {
    let present = StoreContentBuilder.buildIf(EmptyStoreContent())
    if case .some = present {
        expect(true, "buildIf present")
    } else {
        expect(false, "buildIf present")
    }
    let absent = StoreContentBuilder.buildIf(Optional<EmptyStoreContent>.none)
    if case .none = absent {
        expect(true, "buildIf absent")
    } else {
        expect(false, "buildIf absent")
    }
    _ = StoreContentBuilder.buildLimitedAvailability(EmptyStoreContent())
}

private func depthPass6SubscriptionProduct() -> Product {
    Product(
        id: "plus.monthly",
        displayName: "Plus",
        description: "Subscription",
        subscription: Product.SubscriptionInfo(subscriptionGroupID: "plus")
    )
}

func testControlStyleConfigurationOptionMembers() {
    let product = depthPass6SubscriptionProduct()
    let option = SubscriptionStoreControlStyleConfiguration.Option(subscription: product)
    let other = SubscriptionStoreControlStyleConfiguration.Option(
        subscription: Product(id: "other")
    )
    let optionID: SubscriptionStoreControlStyleConfiguration.Option.ID = option.id
    expect(optionID == "plus.monthly", "option id")
    expect(option.subscription.id == "plus.monthly", "subscription")
    expect(option.activeOffer == nil, "no offer")
    _ = option.icon
    option.subscribe()
    expect(option.displayName == "Plus", "product keypath")
    let groupID: String? = option[dynamicMember: \Product.SubscriptionInfo.subscriptionGroupID]
    expect(groupID == "plus", "info keypath")
    let intro: Product.SubscriptionOffer? =
        option[dynamicMember: \Product.SubscriptionInfo.introductoryOffer]
    expect(intro == nil, "optional info keypath")
    expect(option == option, "option equal")
    expect(option != other, "option unequal")
    _ = option.hashValue
}

func testControlStyleConfigurationPickerOptionMembers() {
    let product = depthPass6SubscriptionProduct()
    let picker = SubscriptionStoreControlStyleConfiguration.PickerOption(
        subscription: product,
        isSelected: true
    )
    let unselected = SubscriptionStoreControlStyleConfiguration.PickerOption(
        subscription: product,
        isSelected: false
    )
    let pickerID: SubscriptionStoreControlStyleConfiguration.PickerOption.ID = picker.id
    expect(picker.isSelected, "selected")
    expect(pickerID == product.id, "picker id")
    expect(picker.subscription.id == "plus.monthly", "picker subscription")
    expect(picker.activeOffer == nil, "picker offer")
    _ = picker.icon
    expect(picker.displayName == "Plus", "picker product keypath")
    let groupID: String? = picker[dynamicMember: \Product.SubscriptionInfo.subscriptionGroupID]
    expect(groupID == "plus", "picker info keypath")
    let intro: Product.SubscriptionOffer? =
        picker[dynamicMember: \Product.SubscriptionInfo.introductoryOffer]
    expect(intro == nil, "picker optional info keypath")
    expect(picker == picker, "picker equal")
    expect(picker != unselected, "picker unequal")
    _ = picker.hashValue
}

func testControlStyleConfigurationSectionMembers() {
    let option = SubscriptionStoreControlStyleConfiguration.Option(
        subscription: depthPass6SubscriptionProduct()
    )
    let header = SubscriptionStoreControlStyleConfiguration.Section.Header()
    let footer = SubscriptionStoreControlStyleConfiguration.Section.Footer()
    let headerBody: SubscriptionStoreControlStyleConfiguration.Section.Header.Body = header.body
    let footerBody: SubscriptionStoreControlStyleConfiguration.Section.Footer.Body = footer.body
    _ = headerBody
    _ = footerBody
    let section = SubscriptionStoreControlStyleConfiguration.Section(
        header: header,
        footer: footer,
        options: [option]
    )
    expect(section.options.count == 1, "section options")
    expect(section.header != nil, "header")
    expect(section.footer != nil, "footer")
    expect(
        section.id == SubscriptionStoreControlStyleConfiguration.Section.ID(),
        "section id equal"
    )
    _ = section.id.hashValue
}

func testControlStyleConfigurationValues() {
    let product = depthPass6SubscriptionProduct()
    let option = SubscriptionStoreControlStyleConfiguration.Option(subscription: product)
    let section = SubscriptionStoreControlStyleConfiguration.Section(options: [option])
    let configuration = SubscriptionStoreControlStyleConfiguration(
        options: [option],
        sections: [section],
        groupDisplayName: "Plus",
        autoRenewPreference: product,
        descriptionVisibility: .visible
    )
    expect(configuration.allOptions.map(\.id) == ["plus.monthly"], "allOptions")
    expect(configuration.groupDisplayName == "Plus", "group name")
    expect(configuration.autoRenewPreference?.id == "plus.monthly", "preference")
    expect(configuration.descriptionVisibility == .visible, "visibility")
    expect(configuration.sections.count == 1, "sections")
    expect(configuration.options.count == 1, "options")
}

func testControlStyleConfigurationIcon() {
    let icon = SubscriptionStoreControlStyleConfiguration.Icon()
    let body: SubscriptionStoreControlStyleConfiguration.Icon.Body = icon.body
    _ = body
}

func testProductViewStyleConfigurationModel() {
    let product = Product(id: "pro")
    let configuration = ProductViewStyleConfiguration(
        product: product,
        state: .success(product),
        descriptionVisibility: .hidden,
        hasCurrentEntitlement: true
    )
    expect(configuration.product?.id == "pro", "product")
    expect(configuration.hasCurrentEntitlement, "entitlement")
    expect(configuration.descriptionVisibility == .hidden, "visibility")
    if case .success(let value) = configuration.state {
        expect(value.id == "pro", "state")
    } else {
        expect(false, "state")
    }
    let iconBody: ProductViewStyleConfiguration.Icon.Body = configuration.icon.body
    _ = iconBody
    configuration.purchase()
}

func testEntitlementTaskStateTransaction() {
    let loading: EntitlementTaskState<VerificationResult<Transaction>?> = .loading
    expect(loading.transaction == nil, "loading")
    let verified = VerificationResult<Transaction>.verified(
        Transaction(id: 7, productID: "pro", purchaseDate: Date(timeIntervalSince1970: 0))
    )
    let success: EntitlementTaskState<VerificationResult<Transaction>?> = .success(verified)
    expect(success.transaction?.unsafePayloadValue.id == 7, "success")
}
