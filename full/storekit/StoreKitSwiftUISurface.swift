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

public protocol SubscriptionStoreControlPlacement: RawRepresentable where RawValue == SubscriptionStoreControlPlacementKey {}

public protocol SubscriptionOptionGroupStyle {}

public struct SubscriptionStoreControlPlacementKey: Hashable, Sendable, RawRepresentable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

public struct AutomaticSubscriptionStoreControlPlacement: SubscriptionStoreControlPlacement {
    public var rawValue: SubscriptionStoreControlPlacementKey { SubscriptionStoreControlPlacementKey(rawValue: "automatic") }
    public init() {}
    public init?(rawValue: SubscriptionStoreControlPlacementKey) { _ = rawValue }
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
    public var action: SubscriptionStoreButtonLabel { .action }
    public var price: SubscriptionStoreButtonLabel { .price }
    public var displayName: SubscriptionStoreButtonLabel { .displayName }
    public var singleLine: SubscriptionStoreButtonLabel { .singleLine }
    private var id: String
    private init(id: String) { self.id = id }
}

public struct StoreButtonKind: Hashable, Sendable {
    public static let restore = StoreButtonKind(id: "restore")
    public static let redeemCode = StoreButtonKind(id: "redeemCode")
    public static let policies = StoreButtonKind(id: "policies")
    public static let cancellation = StoreButtonKind(id: "cancellation")
    private var id: String
    private init(id: String) { self.id = id }
}

public struct SubscriptionOfferViewButtonKind: Hashable, Sendable {
    public static let redeemCode = SubscriptionOfferViewButtonKind(id: "redeemCode")
    private var id: String
    private init(id: String) { self.id = id }
}

public struct SubscriptionStoreControlBackground: Hashable, Sendable {
    public init() {}
}

public struct IdentifiedStoreContent<IdentifiedView: View> {
    public init() {}
}

@resultBuilder
public struct StoreContentBuilder {
    public static func buildBlock() -> EmptyStoreContent { EmptyStoreContent() }
    public static func buildBlock<Content: StoreContent>(_ content: Content) -> Content { content }
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
    public struct Icon: View { public var body: some View { EmptyView() } }
    @dynamicMemberLookup
    public struct Option {
        public subscript<T>(dynamicMember keyPath: KeyPath<Product, T>) -> T {
            Product(id: "")[keyPath: keyPath]
        }
        public subscript<T>(dynamicMember keyPath: KeyPath<Product.SubscriptionInfo, T>) -> T? { nil }
        public subscript<T>(dynamicMember keyPath: KeyPath<Product.SubscriptionInfo, T?>) -> T? { nil }
    }
    @dynamicMemberLookup
    public struct PickerOption {
        public subscript<T>(dynamicMember keyPath: KeyPath<Product, T>) -> T {
            Product(id: "")[keyPath: keyPath]
        }
        public subscript<T>(dynamicMember keyPath: KeyPath<Product.SubscriptionInfo, T>) -> T? { nil }
        public subscript<T>(dynamicMember keyPath: KeyPath<Product.SubscriptionInfo, T?>) -> T? { nil }
    }
    public struct Section {
        public struct ID: Hashable, Sendable { public init() {} }
        public struct Header: View { public var body: some View { EmptyView() } }
        public struct Footer: View { public var body: some View { EmptyView() } }
    }
}

public struct ProductViewStyleConfiguration {
    public struct Icon: View { public var body: some View { EmptyView() } }
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
        public var rawValue: SubscriptionStoreControlPlacementKey { SubscriptionStoreControlPlacementKey(rawValue: "picker") }
        public init() {}
        public init?(rawValue: SubscriptionStoreControlPlacementKey) { _ = rawValue }
    }
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct ButtonsSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public struct Placement: SubscriptionStoreControlPlacement {
        public var rawValue: SubscriptionStoreControlPlacementKey { SubscriptionStoreControlPlacementKey(rawValue: "buttons") }
        public init() {}
        public init?(rawValue: SubscriptionStoreControlPlacementKey) { _ = rawValue }
    }
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct AutomaticSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public struct Placement: SubscriptionStoreControlPlacement {
        public var rawValue: SubscriptionStoreControlPlacementKey { SubscriptionStoreControlPlacementKey(rawValue: "automatic") }
        public init() {}
        public init?(rawValue: SubscriptionStoreControlPlacementKey) { _ = rawValue }
    }
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct PagedPickerSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public struct Placement: SubscriptionStoreControlPlacement {
        public var rawValue: SubscriptionStoreControlPlacementKey { SubscriptionStoreControlPlacementKey(rawValue: "paged") }
        public init() {}
        public init?(rawValue: SubscriptionStoreControlPlacementKey) { _ = rawValue }
    }
    public init() {}
    public func makeBody(configuration: Configuration) -> EmptyView { EmptyView() }
}
public struct CompactPickerSubscriptionStoreControlStyle: SubscriptionStoreControlStyle {
    public struct Placement: SubscriptionStoreControlPlacement {
        public var rawValue: SubscriptionStoreControlPlacementKey { SubscriptionStoreControlPlacementKey(rawValue: "compact") }
        public init() {}
        public init?(rawValue: SubscriptionStoreControlPlacementKey) { _ = rawValue }
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

public struct SubscriptionOptionGroup<Content: View, Label: View, MarketingContent: View> {
    public init() {}
}
public struct SubscriptionOptionSection<Header: View, Content: View, Footer: View> {
    public init() {}
}
public struct SubscriptionOptionGroupSet<GroupID: Hashable, Label: View, MarketingContent: View> {
    public init() {}
}
public struct SubscriptionPeriodGroupSet<Label: View, MarketingContent: View> {
    public init() {}
}
