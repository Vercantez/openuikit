import Foundation

// StoreKit-owned SwiftUI overlay types. Isolated host compilation uses the
// module-local View lookalike. These views never present App Store UI.

public struct ProductView<Icon: View, PlaceholderIcon: View>: View {
    public var body: some View { EmptyView() }
    public init() {}
    public init(id productID: Product.ID, prefersPromotionalIcon: Bool = false) {
        _ = productID
        _ = prefersPromotionalIcon
    }
    public init(_ product: Product, prefersPromotionalIcon: Bool = false) {
        _ = product
        _ = prefersPromotionalIcon
    }
    public init(
        id productID: Product.ID,
        prefersPromotionalIcon: Bool = false,
        @ViewBuilder icon: () -> Icon
    ) {
        _ = productID
        _ = prefersPromotionalIcon
        _ = icon
    }
    public init(
        _ product: Product,
        prefersPromotionalIcon: Bool = false,
        @ViewBuilder icon: () -> Icon
    ) {
        _ = product
        _ = prefersPromotionalIcon
        _ = icon
    }
    public init(
        id productID: Product.ID,
        prefersPromotionalIcon: Bool = false,
        @ViewBuilder icon: @escaping (ProductIconPhase) -> Icon,
        @ViewBuilder placeholderIcon: () -> PlaceholderIcon
    ) {
        _ = productID
        _ = prefersPromotionalIcon
        _ = icon
        _ = placeholderIcon
    }
}

public struct StoreView<Icon: View, PlaceholderIcon: View>: View {
    public var body: some View { EmptyView() }
    public init() {}
}

public struct SubscriptionStoreView<Content: View>: View {
    public var body: some View { EmptyView() }
    public init() {}
    public init(productIDs: some Collection<String>, @ViewBuilder content: () -> Content) {
        _ = productIDs
        _ = content
    }
}

public struct SubscriptionStoreButton: View {
    public var body: some View { EmptyView() }
    public init() {}
}

public struct SubscriptionStorePicker<PickerContent: View, ConfirmationContent: View>: View {
    public var body: some View { EmptyView() }
    public init() {}
}

public struct SubscriptionStorePickerOption<Label: View>: View {
    public var body: some View { EmptyView() }
    public init() {}
}

public struct SubscriptionStoreContentView<Content: StoreContent>: View {
    public var body: some View { EmptyView() }
    public init() {}
}

public struct SubscriptionOfferView<Icon: View, PlaceholderIcon: View>: View {
    public var body: some View { EmptyView() }
    public init() {}
}

public struct AutomaticSubscriptionStoreMarketingContent: View {
    public var body: some View { EmptyView() }
    public init() {}
}

public struct AutomaticSubscriptionStorePickerOptionLabel: View {
    public var body: some View { EmptyView() }
    public init() {}
}

public struct AutomaticProductPlaceholderIcon: View {
    public var body: some View { EmptyView() }
    public init() {}
}

public struct AutomaticSubscriptionOptionGroupLabel: View {
    public var body: some View { EmptyView() }
    public init() {}
}

public enum ProductIconPhase {
    case loading
    case success(Image)
    case failure(any Error)
    case unavailable
}

public protocol StoreContent {
    associatedtype Body: StoreContent
    var body: Body { get }
}

public protocol ProductViewStyle {
    associatedtype Body: View
    typealias Configuration = ProductViewStyleConfiguration
    func makeBody(configuration: Self.Configuration) -> Self.Body
}

public protocol SubscriptionOfferViewStyle {
    associatedtype Body: View
    typealias Configuration = SubscriptionOfferViewStyleConfiguration
    func makeBody(configuration: Self.Configuration) -> Self.Body
}

public protocol SubscriptionStoreControlStyle {
    associatedtype Body: View
    associatedtype Placement: SubscriptionStoreControlPlacement = AutomaticSubscriptionStoreControlPlacement
    typealias Configuration = SubscriptionStoreControlStyleConfiguration
    func makeBody(configuration: Self.Configuration) -> Self.Body
}

public protocol SubscriptionStoreControlPlacement: RawRepresentable where RawValue == SubscriptionStoreControlPlacementKey {
    static var automatic: Self { get }
}

public protocol SubscriptionOptionGroupStyle {}

public struct SubscriptionStoreControlPlacementKey: Hashable, Sendable, RawRepresentable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static var scrollView: SubscriptionStoreControlPlacementKey {
        SubscriptionStoreControlPlacementKey(rawValue: "scrollView")
    }
    public static var bottomBar: SubscriptionStoreControlPlacementKey {
        SubscriptionStoreControlPlacementKey(rawValue: "bottomBar")
    }
    public static var buttonsInBottomBar: SubscriptionStoreControlPlacementKey {
        SubscriptionStoreControlPlacementKey(rawValue: "buttonsInBottomBar")
    }
}

public struct AutomaticSubscriptionStoreControlPlacement: SubscriptionStoreControlPlacement {
    public var rawValue: SubscriptionStoreControlPlacementKey
    public static var automatic: AutomaticSubscriptionStoreControlPlacement {
        AutomaticSubscriptionStoreControlPlacement(rawValue: SubscriptionStoreControlPlacementKey(rawValue: "automatic"))
    }
    public static var scrollView: AutomaticSubscriptionStoreControlPlacement {
        AutomaticSubscriptionStoreControlPlacement(rawValue: .scrollView)
    }
    public static var bottomBar: AutomaticSubscriptionStoreControlPlacement {
        AutomaticSubscriptionStoreControlPlacement(rawValue: .bottomBar)
    }
    public static var buttonsInBottomBar: AutomaticSubscriptionStoreControlPlacement {
        AutomaticSubscriptionStoreControlPlacement(rawValue: .buttonsInBottomBar)
    }
    public init() { self.rawValue = SubscriptionStoreControlPlacementKey(rawValue: "automatic") }
    public init(rawValue: SubscriptionStoreControlPlacementKey) { self.rawValue = rawValue }
}

public struct SubscriptionStorePolicyKind: Hashable, Sendable {
    public static let privacyPolicy = SubscriptionStorePolicyKind(id: "privacyPolicy")
    public static let termsOfService = SubscriptionStorePolicyKind(id: "termsOfService")
    private var id: String
    private init(id: String) { self.id = id }
}

public struct SubscriptionStoreButtonLabel: Hashable, Sendable {
    public static let automatic = SubscriptionStoreButtonLabel(id: "automatic")
    public static let action = SubscriptionStoreButtonLabel(id: "action")
    public static let price = SubscriptionStoreButtonLabel(id: "price")
    public static let displayName = SubscriptionStoreButtonLabel(id: "displayName")
    public static let singleLine = SubscriptionStoreButtonLabel(id: "singleLine")
    public static let multiline = SubscriptionStoreButtonLabel(id: "multiline")
    public var action: SubscriptionStoreButtonLabel { .action }
    public var price: SubscriptionStoreButtonLabel { .price }
    public var displayName: SubscriptionStoreButtonLabel { .displayName }
    public var singleLine: SubscriptionStoreButtonLabel { .singleLine }
    public var multiline: SubscriptionStoreButtonLabel { .multiline }
    private var id: String
    private init(id: String) { self.id = id }
}

public struct StoreButtonKind: Hashable, Sendable {
    public static let restore = StoreButtonKind(id: "restore")
    public static let restorePurchases = StoreButtonKind(id: "restorePurchases")
    public static let redeemCode = StoreButtonKind(id: "redeemCode")
    public static let policies = StoreButtonKind(id: "policies")
    public static let cancellation = StoreButtonKind(id: "cancellation")
    public static let signIn = StoreButtonKind(id: "signIn")
    private var id: String
    private init(id: String) { self.id = id }
}

public struct SubscriptionOfferViewButtonKind: Hashable, Sendable {
    public static let redeemCode = SubscriptionOfferViewButtonKind(id: "redeemCode")
    public static let detailLink = SubscriptionOfferViewButtonKind(id: "detailLink")
    private var id: String
    private init(id: String) { self.id = id }
}

public struct SubscriptionStoreControlBackground: Hashable, Sendable {
    private var id: String
    public init() { self.id = "automatic" }
    private init(id: String) { self.id = id }
    public static var automatic: SubscriptionStoreControlBackground {
        SubscriptionStoreControlBackground(id: "automatic")
    }
    public static var gradientMaterial: SubscriptionStoreControlBackground {
        SubscriptionStoreControlBackground(id: "gradientMaterial")
    }
    public static var gradientMaterialOnScroll: SubscriptionStoreControlBackground {
        SubscriptionStoreControlBackground(id: "gradientMaterialOnScroll")
    }
}

public struct IdentifiedStoreContent<IdentifiedView: View> {
    public init() {}
}

@resultBuilder
public struct StoreContentBuilder {
    public static func buildBlock() -> EmptyStoreContent { EmptyStoreContent() }
    public static func buildBlock<Content: StoreContent>(_ content: Content) -> Content { content }
    public static func buildIf<Content: StoreContent>(_ section: Content?) -> Content? { section }
    public static func buildLimitedAvailability(_ content: any StoreContent) -> some StoreContent {
        _ = content
        return EmptyStoreContent()
    }
}

public struct EmptyStoreContent: StoreContent {
    public var body: EmptyStoreContent { self }
    public init() {}
}

public struct TupleStoreContent<each Content>: StoreContent {
    public var body: EmptyStoreContent { EmptyStoreContent() }
    public init() {}
}

public struct SubscriptionStoreControlStyleConfiguration {
    public struct Icon: View {
        public var body: some View { EmptyView() }
        public init() {}
    }

    @dynamicMemberLookup
    public struct Option: Hashable {
        public typealias ID = Product.ID
        public var subscription: Product
        public var activeOffer: Product.SubscriptionOffer? { nil }
        public var icon: Icon? { nil }
        public var id: Product.ID { subscription.id }
        public func subscribe() {}
        public init(subscription: Product = Product(id: "")) {
            self.subscription = subscription
        }
        public static func == (lhs: Option, rhs: Option) -> Bool {
            lhs.subscription == rhs.subscription
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(subscription)
        }
        public subscript<T>(dynamicMember keyPath: KeyPath<Product, T>) -> T {
            subscription[keyPath: keyPath]
        }
        public subscript<T>(dynamicMember keyPath: KeyPath<Product.SubscriptionInfo, T>) -> T? {
            subscription.subscription?[keyPath: keyPath]
        }
        public subscript<T>(dynamicMember keyPath: KeyPath<Product.SubscriptionInfo, T?>) -> T? {
            subscription.subscription?[keyPath: keyPath]
        }
    }

    @dynamicMemberLookup
    public struct PickerOption: Hashable {
        public typealias ID = Product.ID
        public var isSelected: Bool
        public var subscription: Product
        public var activeOffer: Product.SubscriptionOffer? { nil }
        public var icon: Icon? { nil }
        public var id: Product.ID { subscription.id }
        public init(subscription: Product = Product(id: ""), isSelected: Bool = false) {
            self.subscription = subscription
            self.isSelected = isSelected
        }
        public static func == (lhs: PickerOption, rhs: PickerOption) -> Bool {
            lhs.subscription == rhs.subscription && lhs.isSelected == rhs.isSelected
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(subscription)
            hasher.combine(isSelected)
        }
        public subscript<T>(dynamicMember keyPath: KeyPath<Product, T>) -> T {
            subscription[keyPath: keyPath]
        }
        public subscript<T>(dynamicMember keyPath: KeyPath<Product.SubscriptionInfo, T>) -> T? {
            subscription.subscription?[keyPath: keyPath]
        }
        public subscript<T>(dynamicMember keyPath: KeyPath<Product.SubscriptionInfo, T?>) -> T? {
            subscription.subscription?[keyPath: keyPath]
        }
    }

    public struct Section {
        public struct ID: Hashable, Sendable {
            public init() {}
        }
        public struct Header: View {
            public var body: some View { EmptyView() }
            public init() {}
        }
        public struct Footer: View {
            public var body: some View { EmptyView() }
            public init() {}
        }
        public var id: ID
        public var header: Header?
        public var footer: Footer?
        public var options: [Option]
        public init(
            id: ID = ID(),
            header: Header? = nil,
            footer: Footer? = nil,
            options: [Option] = []
        ) {
            self.id = id
            self.header = header
            self.footer = footer
            self.options = options
        }
    }

    public var options: [Option]
    public var sections: [Section]
    public var groupDisplayName: String
    public var autoRenewPreference: Product?
    public var descriptionVisibility: Visibility
    public var allOptions: [Product] { options.map(\.subscription) }
    public init(
        options: [Option] = [],
        sections: [Section] = [],
        groupDisplayName: String = "",
        autoRenewPreference: Product? = nil,
        descriptionVisibility: Visibility = .automatic
    ) {
        self.options = options
        self.sections = sections
        self.groupDisplayName = groupDisplayName
        self.autoRenewPreference = autoRenewPreference
        self.descriptionVisibility = descriptionVisibility
    }
}

public struct ProductViewStyleConfiguration {
    public struct Icon: View {
        public var body: some View { EmptyView() }
        public init() {}
    }
    public var icon: Icon
    public var product: Product?
    public var state: Product.TaskState
    public var descriptionVisibility: Visibility
    public var hasCurrentEntitlement: Bool
    public func purchase() {}
    public init(
        icon: Icon = Icon(),
        product: Product? = nil,
        state: Product.TaskState = .loading,
        descriptionVisibility: Visibility = .automatic,
        hasCurrentEntitlement: Bool = false
    ) {
        self.icon = icon
        self.product = product
        self.state = state
        self.descriptionVisibility = descriptionVisibility
        self.hasCurrentEntitlement = hasCurrentEntitlement
    }
}

public struct SubscriptionOfferViewStyleConfiguration {
    public struct Icon: View { public var body: some View { EmptyView() } }
}

public struct LargeProductViewStyle: ProductViewStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct CompactProductViewStyle: ProductViewStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct RegularProductViewStyle: ProductViewStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct AutomaticProductViewStyle: ProductViewStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}

public struct CompactSubscriptionOfferViewStyle: SubscriptionOfferViewStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct AutomaticSubscriptionOfferViewStyle: SubscriptionOfferViewStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}

public struct PickerSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public struct Placement: SubscriptionStoreControlPlacement {
        public var rawValue: SubscriptionStoreControlPlacementKey
        public static var automatic: Placement { Placement(rawValue: SubscriptionStoreControlPlacementKey(rawValue: "picker")) }
        public static var scrollView: Placement { Placement(rawValue: .scrollView) }
        public static var buttonsInBottomBar: Placement { Placement(rawValue: .buttonsInBottomBar) }
        public init() { self.rawValue = SubscriptionStoreControlPlacementKey(rawValue: "picker") }
        public init(rawValue: SubscriptionStoreControlPlacementKey) { self.rawValue = rawValue }
    }
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct ButtonsSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public struct Placement: SubscriptionStoreControlPlacement {
        public var rawValue: SubscriptionStoreControlPlacementKey
        public static var automatic: Placement { Placement(rawValue: SubscriptionStoreControlPlacementKey(rawValue: "buttons")) }
        public static var scrollView: Placement { Placement(rawValue: .scrollView) }
        public static var bottomBar: Placement { Placement(rawValue: .bottomBar) }
        public init() { self.rawValue = SubscriptionStoreControlPlacementKey(rawValue: "buttons") }
        public init(rawValue: SubscriptionStoreControlPlacementKey) { self.rawValue = rawValue }
    }
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct AutomaticSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public struct Placement: SubscriptionStoreControlPlacement {
        public var rawValue: SubscriptionStoreControlPlacementKey
        public static var automatic: Placement { Placement(rawValue: SubscriptionStoreControlPlacementKey(rawValue: "automatic")) }
        public init() { self.rawValue = SubscriptionStoreControlPlacementKey(rawValue: "automatic") }
        public init(rawValue: SubscriptionStoreControlPlacementKey) { self.rawValue = rawValue }
    }
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct PagedPickerSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public struct Placement: SubscriptionStoreControlPlacement {
        public var rawValue: SubscriptionStoreControlPlacementKey
        public static var automatic: Placement { Placement(rawValue: SubscriptionStoreControlPlacementKey(rawValue: "paged")) }
        public static var scrollView: Placement { Placement(rawValue: .scrollView) }
        public static var buttonsInBottomBar: Placement { Placement(rawValue: .buttonsInBottomBar) }
        public static var bottomBar: Placement { Placement(rawValue: .bottomBar) }
        public init() { self.rawValue = SubscriptionStoreControlPlacementKey(rawValue: "paged") }
        public init(rawValue: SubscriptionStoreControlPlacementKey) { self.rawValue = rawValue }
    }
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct CompactPickerSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public struct Placement: SubscriptionStoreControlPlacement {
        public var rawValue: SubscriptionStoreControlPlacementKey
        public static var automatic: Placement { Placement(rawValue: SubscriptionStoreControlPlacementKey(rawValue: "compact")) }
        public static var scrollView: Placement { Placement(rawValue: .scrollView) }
        public static var buttonsInBottomBar: Placement { Placement(rawValue: .buttonsInBottomBar) }
        public static var bottomBar: Placement { Placement(rawValue: .bottomBar) }
        public init() { self.rawValue = SubscriptionStoreControlPlacementKey(rawValue: "compact") }
        public init(rawValue: SubscriptionStoreControlPlacementKey) { self.rawValue = rawValue }
    }
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct ProminentPickerSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct PagedProminentPickerSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}

public struct TabsSubscriptionOptionGroupStyle: SubscriptionOptionGroupStyle { public init() {} }
public struct LinksSubscriptionOptionGroupStyle: SubscriptionOptionGroupStyle { public init() {} }
public struct AutomaticSubscriptionOptionGroupStyle: SubscriptionOptionGroupStyle { public init() {} }
public struct SubscriptionOptionGroupStyleOutput { public init() {} }

public struct PurchaseAction { public init() {} }
public struct RequestReviewAction { public init() {} }
public struct DisplayMessageAction { public init() {} }

public enum EntitlementTaskState<Value> {
    case loading
    case success(Value)
    case failure(any Error)
}

public struct SubscriptionOptionGroup<Content: View, Label: View, MarketingContent: View>: StoreContent {
    public var body: EmptyStoreContent { EmptyStoreContent() }
    public init() {}
}
public struct SubscriptionOptionSection<Header: View, Content: View, Footer: View>: StoreContent {
    public var body: EmptyStoreContent { EmptyStoreContent() }
    public init() {}
}
public struct SubscriptionOptionGroupSet<GroupID: Hashable, Label: View, MarketingContent: View>: StoreContent {
    public var body: EmptyStoreContent { EmptyStoreContent() }
    public init() {}
}
public struct SubscriptionPeriodGroupSet<Label: View, MarketingContent: View>: StoreContent {
    public var body: EmptyStoreContent { EmptyStoreContent() }
    public init() {}
}

extension StoreContent {
    nonisolated public func subscriptionStoreButtonLabel(
        _ label: SubscriptionStoreButtonLabel
    ) -> some StoreContent {
        _ = label
        return self
    }

    nonisolated public func subscriptionStoreControlStyle<S>(
        _ style: S,
        placement: S.Placement
    ) -> some StoreContent where S: SubscriptionStoreControlStyle {
        _ = style
        _ = placement
        return self
    }

    public func subscriptionStoreOptionGroupStyle(
        _ style: some SubscriptionOptionGroupStyle
    ) -> some StoreContent {
        _ = style
        return self
    }

    nonisolated public func subscriptionStoreControlBackground(
        _ backgroundStyle: SubscriptionStoreControlBackground
    ) -> some StoreContent {
        _ = backgroundStyle
        return self
    }

    nonisolated public func subscriptionStoreControlBackground(
        _ backgroundStyle: some ShapeStyle
    ) -> some StoreContent {
        _ = backgroundStyle
        return self
    }

    nonisolated public func subscriptionStorePickerItemBackground(
        _ backgroundStyle: some ShapeStyle,
        in shape: some Shape
    ) -> some StoreContent {
        _ = backgroundStyle
        _ = shape
        return self
    }

    nonisolated public func subscriptionStorePickerItemBackground(
        _ backgroundStyle: some ShapeStyle
    ) -> some StoreContent {
        _ = backgroundStyle
        return self
    }

    nonisolated public func storeButton(
        _ visibility: Visibility,
        for buttonKinds: StoreButtonKind...
    ) -> some StoreContent {
        _ = visibility
        _ = buttonKinds
        return self
    }

    nonisolated public func productDescription(_ visibility: Visibility) -> some StoreContent {
        _ = visibility
        return self
    }
}

extension SubscriptionStoreControlStyle where Self == AutomaticSubscriptionStoreControlStyle {
    public static var automatic: AutomaticSubscriptionStoreControlStyle {
        AutomaticSubscriptionStoreControlStyle()
    }
}

extension SubscriptionStoreControlStyle where Self == PickerSubscriptionStoreControlStyle {
    public static var picker: PickerSubscriptionStoreControlStyle { PickerSubscriptionStoreControlStyle() }
}

extension SubscriptionStoreControlStyle where Self == ButtonsSubscriptionStoreControlStyle {
    public static var buttons: ButtonsSubscriptionStoreControlStyle { ButtonsSubscriptionStoreControlStyle() }
}

extension SubscriptionStoreControlStyle where Self == CompactPickerSubscriptionStoreControlStyle {
    public static var compactPicker: CompactPickerSubscriptionStoreControlStyle {
        CompactPickerSubscriptionStoreControlStyle()
    }
}

extension SubscriptionStoreControlStyle where Self == PagedPickerSubscriptionStoreControlStyle {
    public static var pagedPicker: PagedPickerSubscriptionStoreControlStyle {
        PagedPickerSubscriptionStoreControlStyle()
    }
}

extension SubscriptionStoreControlStyle where Self == ProminentPickerSubscriptionStoreControlStyle {
    public static var prominentPicker: ProminentPickerSubscriptionStoreControlStyle {
        ProminentPickerSubscriptionStoreControlStyle()
    }
}

extension SubscriptionStoreControlStyle where Self == PagedProminentPickerSubscriptionStoreControlStyle {
    public static var pagedProminentPicker: PagedProminentPickerSubscriptionStoreControlStyle {
        PagedProminentPickerSubscriptionStoreControlStyle()
    }
}

extension SubscriptionStoreControlStyle {
    public typealias SubscriptionPickerOption = SubscriptionStorePickerOption
    public typealias SubscriptionPicker = SubscriptionStorePicker
    public typealias SubscribeButton = SubscriptionStoreButton
}

extension ProductViewStyle where Self == LargeProductViewStyle {
    public static var large: LargeProductViewStyle { LargeProductViewStyle() }
}

extension ProductViewStyle where Self == RegularProductViewStyle {
    public static var regular: RegularProductViewStyle { RegularProductViewStyle() }
}

extension ProductViewStyle where Self == AutomaticProductViewStyle {
    public static var automatic: AutomaticProductViewStyle { AutomaticProductViewStyle() }
}

extension ProductViewStyle where Self == CompactProductViewStyle {
    public static var compact: CompactProductViewStyle { CompactProductViewStyle() }
}

extension SubscriptionOfferViewStyle where Self == AutomaticSubscriptionOfferViewStyle {
    public static var automatic: AutomaticSubscriptionOfferViewStyle {
        AutomaticSubscriptionOfferViewStyle()
    }
}

extension SubscriptionOfferViewStyle where Self == CompactSubscriptionOfferViewStyle {
    public static var compact: CompactSubscriptionOfferViewStyle {
        CompactSubscriptionOfferViewStyle()
    }
}

extension SubscriptionOptionGroupStyle where Self == AutomaticSubscriptionOptionGroupStyle {
    public static var automatic: AutomaticSubscriptionOptionGroupStyle {
        AutomaticSubscriptionOptionGroupStyle()
    }
}

extension SubscriptionOptionGroupStyle where Self == TabsSubscriptionOptionGroupStyle {
    public static var tabs: TabsSubscriptionOptionGroupStyle { TabsSubscriptionOptionGroupStyle() }
}

extension SubscriptionOptionGroupStyle where Self == LinksSubscriptionOptionGroupStyle {
    public static var links: LinksSubscriptionOptionGroupStyle { LinksSubscriptionOptionGroupStyle() }
}

extension EntitlementTaskState where Value == VerificationResult<Transaction>? {
    public var transaction: VerificationResult<Transaction>? {
        switch self {
        case .success(let value):
            return value
        case .loading, .failure:
            return nil
        }
    }
}

extension EnvironmentValues {
    public var displayStoreKitMessage: DisplayMessageAction { DisplayMessageAction() }
    public var requestReview: RequestReviewAction { RequestReviewAction() }
    public var purchase: PurchaseAction { PurchaseAction() }
}

extension ContainerBackgroundPlacement {
    public static var subscriptionStore: ContainerBackgroundPlacement {
        var value = ContainerBackgroundPlacement()
        value.storeKitKind = "subscriptionStore"
        return value
    }

    public static var subscriptionStoreFullHeight: ContainerBackgroundPlacement {
        var value = ContainerBackgroundPlacement()
        value.storeKitKind = "subscriptionStoreFullHeight"
        return value
    }

    public static var subscriptionStoreHeader: ContainerBackgroundPlacement {
        var value = ContainerBackgroundPlacement()
        value.storeKitKind = "subscriptionStoreHeader"
        return value
    }
}
