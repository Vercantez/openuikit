import Foundation

// Remaining StoreKit core types not defined in StoreKit.swift. Isolated host
// paths that would talk to App Store, Music, or overlay UI stay fail-closed.

public let SKANErrorDomain = "SKANErrorDomain"
public var SKDownloadTimeRemainingUnknown: TimeInterval { -1 }
public let SKReceiptPropertyIsExpired = "expired"
public let SKReceiptPropertyIsRevoked = "revoked"
public let SKReceiptPropertyIsVolumePurchase = "volume"
public let SKStoreProductParameterAdNetworkAttributionSignature = "SKStoreProductParameterAdNetworkAttributionSignature"
public let SKStoreProductParameterAdNetworkCampaignIdentifier = "SKStoreProductParameterAdNetworkCampaignIdentifier"
public let SKStoreProductParameterAdNetworkIdentifier = "SKStoreProductParameterAdNetworkIdentifier"
public let SKStoreProductParameterAdNetworkNonce = "SKStoreProductParameterAdNetworkNonce"
public let SKStoreProductParameterAdNetworkSourceAppStoreIdentifier = "SKStoreProductParameterAdNetworkSourceAppStoreIdentifier"
public let SKStoreProductParameterAdNetworkSourceIdentifier = "SKStoreProductParameterAdNetworkSourceIdentifier"
public let SKStoreProductParameterAdNetworkTimestamp = "SKStoreProductParameterAdNetworkTimestamp"
public let SKStoreProductParameterAdNetworkVersion = "SKStoreProductParameterAdNetworkVersion"
public let SKStoreProductParameterAdvertisingPartnerToken = "SKStoreProductParameterAdvertisingPartnerToken"
public let SKStoreProductParameterAffiliateToken = "SKStoreProductParameterAffiliateToken"
public let SKStoreProductParameterCampaignToken = "SKStoreProductParameterCampaignToken"
public let SKStoreProductParameterCustomProductPageIdentifier = "SKStoreProductParameterCustomProductPageIdentifier"
public let SKStoreProductParameterITunesItemIdentifier = "SKStoreProductParameterITunesItemIdentifier"
public let SKStoreProductParameterProductIdentifier = "SKStoreProductParameterProductIdentifier"
public let SKStoreProductParameterProviderToken = "SKStoreProductParameterProviderToken"

public func SKTerminateForInvalidReceipt() {}

public enum SKCloudServiceAuthorizationStatus: Int, Sendable {
    case notDetermined = 0
    case denied = 1
    case restricted = 2
    case authorized = 3
}

public struct SKCloudServiceCapability: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let musicCatalogPlayback = SKCloudServiceCapability(rawValue: 1 << 0)
    public static let musicCatalogSubscriptionEligible = SKCloudServiceCapability(rawValue: 1 << 1)
    public static let addToCloudMusicLibrary = SKCloudServiceCapability(rawValue: 1 << 2)
}

public enum SKDownloadState: Int, Sendable {
    case waiting = 0
    case active = 1
    case paused = 2
    case finished = 3
    case failed = 4
    case cancelled = 5
}

public enum SKProductStorePromotionVisibility: Int, Sendable {
    case `default` = 0
    case show = 1
    case hide = 2
}

public struct SKANError: Error, Hashable, Sendable {
    public enum Code: Int, Sendable, Hashable {
        case impressionMissingRequiredValue = 0
        case unsupported = 1
        case adNetworkIdMissing = 2
        case mismatchedSourceAppId = 3
        case impressionNotFound = 4
        case invalidCampaignId = 5
        case invalidConversionValue = 6
        case invalidSourceAppId = 7
        case invalidAdvertisedAppId = 8
        case invalidVersion = 9
        case unknown = 10
        case impressionTooShort = 11
    }

    public var code: Code
    public init(_ code: Code) { self.code = code }
}

public struct SKCloudServiceSetupAction: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let subscribe = SKCloudServiceSetupAction(rawValue: "subscribe")
}

public struct SKCloudServiceSetupMessageIdentifier: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let join = SKCloudServiceSetupMessageIdentifier(rawValue: "join")
    public static let connect = SKCloudServiceSetupMessageIdentifier(rawValue: "connect")
    public static let addMusic = SKCloudServiceSetupMessageIdentifier(rawValue: "addMusic")
    public static let playMusic = SKCloudServiceSetupMessageIdentifier(rawValue: "playMusic")
}

public struct SKCloudServiceSetupOptionsKey: Hashable, RawRepresentable, Sendable {
    public var rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let action = SKCloudServiceSetupOptionsKey(rawValue: "action")
    public static let iTunesItemIdentifier = SKCloudServiceSetupOptionsKey(rawValue: "iTunesItemIdentifier")
    public static let affiliateToken = SKCloudServiceSetupOptionsKey(rawValue: "affiliateToken")
    public static let campaignToken = SKCloudServiceSetupOptionsKey(rawValue: "campaignToken")
    public static let messageIdentifier = SKCloudServiceSetupOptionsKey(rawValue: "messageIdentifier")
}

open class SKArcadeService: NSObject {
    public override init() { super.init() }
    public class func registerArcadeApp(
        withRandomFromLib randomFromLib: Data,
        randomFromLibLength: UInt32,
        resultHandler: @escaping (Data?, UInt32, Data?, UInt32, (any Error)?) -> Void
    ) {
        resultHandler(nil, 0, nil, 0, StoreKitPortableError(.serviceUnavailable))
    }
}

open class SKCloudServiceController: NSObject {
    public override init() { super.init() }
    public class func authorizationStatus() -> SKCloudServiceAuthorizationStatus { .denied }
    public class func requestAuthorization(
        _ handler: @escaping (SKCloudServiceAuthorizationStatus) -> Void
    ) {
        handler(.denied)
    }
    public func requestCapabilities(
        completionHandler: @escaping (SKCloudServiceCapability, (any Error)?) -> Void
    ) {
        completionHandler([], StoreKitPortableError(.serviceUnavailable))
    }
    public func requestStorefrontCountryCode(
        completionHandler: @escaping (String?, (any Error)?) -> Void
    ) {
        completionHandler(nil, StoreKitPortableError(.serviceUnavailable))
    }
    public func requestStorefrontIdentifier(
        completionHandler: @escaping (String?, (any Error)?) -> Void
    ) {
        completionHandler(nil, StoreKitPortableError(.serviceUnavailable))
    }
    public func requestPersonalizationToken(
        forClientToken clientToken: String,
        withCompletionHandler completionHandler: @escaping (String?, (any Error)?) -> Void
    ) {
        _ = clientToken
        completionHandler(nil, StoreKitPortableError(.serviceUnavailable))
    }
}

open class SKCloudServiceSetupViewController: UIViewController {
    public weak var delegate: SKCloudServiceSetupViewControllerDelegate?
    public func load(
        options: [SKCloudServiceSetupOptionsKey: Any] = [:],
        completionHandler: ((Bool, (any Error)?) -> Void)? = nil
    ) {
        _ = options
        completionHandler?(false, StoreKitPortableError(.serviceUnavailable))
    }
}

public protocol SKCloudServiceSetupViewControllerDelegate: NSObjectProtocol {
    func cloudServiceSetupViewControllerDidDismiss(_ cloudServiceSetupViewController: SKCloudServiceSetupViewController)
}

public extension SKCloudServiceSetupViewControllerDelegate {
    func cloudServiceSetupViewControllerDidDismiss(_ cloudServiceSetupViewController: SKCloudServiceSetupViewController) {}
}

open class SKDownload: NSObject {
    public var state: SKDownloadState { .failed }
    public var contentIdentifier: String { "" }
    public var contentURL: URL? { nil }
    public var contentVersion: String { "" }
    public var error: (any Error)? { StoreKitPortableError(.serviceUnavailable) }
    public var progress: Float { 0 }
    public var timeRemaining: TimeInterval { SKDownloadTimeRemainingUnknown }
    public var expectedContentLength: Int64 { 0 }
    public override init() { super.init() }
}

open class SKPaymentDiscount: NSObject {
    public var identifier: String
    public var keyIdentifier: String
    public var nonce: UUID
    public var signature: String
    public var timestamp: NSNumber
    public init(
        identifier: String,
        keyIdentifier: String,
        nonce: UUID,
        signature: String,
        timestamp: NSNumber
    ) {
        self.identifier = identifier
        self.keyIdentifier = keyIdentifier
        self.nonce = nonce
        self.signature = signature
        self.timestamp = timestamp
    }
}

open class SKProductDiscount: NSObject {
    public enum PaymentMode: UInt, Sendable {
        case payAsYouGo = 0
        case payUpFront = 1
        case freeTrial = 2
    }
    public enum `Type`: UInt, Sendable {
        case introductory = 0
        case subscription = 1
    }
    public var price: Decimal { 0 }
    public var priceLocale: Locale { Locale(identifier: "en_US_POSIX") }
    public var identifier: String? { nil }
    public var subscriptionPeriod: SKProductSubscriptionPeriod { SKProductSubscriptionPeriod() }
    public var numberOfPeriods: Int { 0 }
    public var paymentMode: PaymentMode { .payAsYouGo }
    public var type: `Type` { .introductory }
    public override init() { super.init() }
}

open class SKProductSubscriptionPeriod: NSObject {
    public var numberOfUnits: Int { 0 }
    public var unit: SKProduct.PeriodUnit { .day }
    public override init() { super.init() }
}

extension SKProduct {
    public enum PeriodUnit: UInt, Sendable {
        case day = 0
        case week = 1
        case month = 2
        case year = 3
    }
    public var subscriptionPeriod: SKProductSubscriptionPeriod? { nil }
    public var introductoryPrice: SKProductDiscount? { nil }
    public var subscriptionGroupIdentifier: String? { nil }
    public var discounts: [SKProductDiscount] { [] }
    public var isDownloadable: Bool { false }
    public var downloadContentLengths: [NSNumber] { [] }
    public var downloadContentVersion: String { "" }
    public var isFamilyShareable: Bool { false }
    public var priceLocale: Locale { Locale(identifier: "en_US_POSIX") }
}

open class SKProductStorePromotionController: NSObject {
    public class func `default`() -> SKProductStorePromotionController { SKProductStorePromotionController() }
    public override init() { super.init() }
    public func fetchStorePromotionVisibility(
        for product: SKProduct,
        completionHandler: ((SKProductStorePromotionVisibility, (any Error)?) -> Void)? = nil
    ) {
        _ = product
        completionHandler?(.default, StoreKitPortableError(.serviceUnavailable))
    }
    public func update(
        storePromotionVisibility visibility: SKProductStorePromotionVisibility,
        for product: SKProduct,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = visibility
        _ = product
        completionHandler?(StoreKitPortableError(.serviceUnavailable))
    }
}

open class SKReceiptRefreshRequest: SKRequest {
    public var receiptProperties: [String: Any]?
    public init(receiptProperties: [String: Any]?) {
        self.receiptProperties = receiptProperties
        super.init()
    }
}

open class SKStorefront: NSObject {
    public var countryCode: String { "" }
    public var identifier: String { "" }
    public override init() { super.init() }
}

open class SKOverlay: NSObject {
    open class Configuration: NSObject {
        public override init() { super.init() }
    }
    open class AppConfiguration: Configuration {
        public var appIdentifier: String
        public var position: Position
        public init(appIdentifier: String, position: Position) {
            self.appIdentifier = appIdentifier
            self.position = position
            super.init()
        }
    }
    open class AppClipConfiguration: Configuration {
        public var position: Position
        public init(position: Position) {
            self.position = position
            super.init()
        }
    }
    public enum Position: Int, Sendable {
        case bottom = 0
        case bottomRaised = 1
    }
    public final class TransitionContext: NSObject {
        public override init() { super.init() }
        public func add(_ animation: @escaping () -> Void) { animation() }
    }
    public var configuration: Configuration
    public weak var delegate: SKOverlayDelegate?
    public init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
    }
    @MainActor
    public func present(in scene: UIWindowScene) { _ = scene }
    @MainActor
    public func dismiss(from scene: UIWindowScene) { _ = scene }
}

public protocol SKOverlayDelegate: NSObjectProtocol {
    func storeOverlayDidFinishDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext)
    func storeOverlayDidFailToLoad(_ overlay: SKOverlay, error: any Error)
    func storeOverlayWillStartPresentation(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext)
    func storeOverlayWillStartDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext)
}

public extension SKOverlayDelegate {
    func storeOverlayDidFinishDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {}
    func storeOverlayDidFailToLoad(_ overlay: SKOverlay, error: any Error) {}
    func storeOverlayWillStartPresentation(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {}
    func storeOverlayWillStartDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {}
}

open class SKStoreProductViewController: UIViewController {
    public weak var delegate: SKStoreProductViewControllerDelegate?
    public func loadProduct(
        withParameters parameters: [String: Any],
        completionBlock: ((Bool, (any Error)?) -> Void)? = nil
    ) {
        _ = parameters
        completionBlock?(false, StoreKitPortableError(.serviceUnavailable))
    }
}

public protocol SKStoreProductViewControllerDelegate: NSObjectProtocol {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController)
}

public extension SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {}
}

public protocol SKPaymentQueueDelegate: NSObjectProtocol {
    func paymentQueue(_ queue: SKPaymentQueue, shouldContinue transaction: SKPaymentTransaction, in newStorefront: SKStorefront) -> Bool
}

public extension SKPaymentQueueDelegate {
    func paymentQueue(_ queue: SKPaymentQueue, shouldContinue transaction: SKPaymentTransaction, in newStorefront: SKStorefront) -> Bool {
        false
    }
}

public protocol StoreDownloaderExtension {}

extension AppStore {
    public struct Environment: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let production = Environment(rawValue: "Production")
        public static let sandbox = Environment(rawValue: "Sandbox")
        public static let xcode = Environment(rawValue: "Xcode")
    }
    public struct Platform: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let iOS = Platform(rawValue: "iOS")
        public static let macOS = Platform(rawValue: "macOS")
        public static let tvOS = Platform(rawValue: "tvOS")
        public static let watchOS = Platform(rawValue: "watchOS")
        public static let visionOS = Platform(rawValue: "visionOS")
    }
    public static var canMakePayments: Bool { false }
    public static var deviceVerificationID: UUID? { nil }
    @MainActor
    public static func presentOfferCodeRedeemSheet(in scene: UIWindowScene) async throws {
        _ = scene
        throw StoreKitPortableError(.serviceUnavailable)
    }
}

public struct AppStoreMerchandisingKind: Hashable, Sendable {
    public struct PresentationResult: Hashable, Sendable {
        public init() {}
    }
    public init() {}
}

public struct AppTransaction: Hashable, Sendable {
    public var jsonRepresentation: Data { Data() }
    public init() {}
}

public struct PurchaseIntent: Hashable, Sendable {
    public struct PurchaseIntents {}
    public var product: Product { Product(id: "") }
    public static var intents: PurchaseIntents { PurchaseIntents() }
}

public enum ExternalPurchase {
    public static var isEligible: Bool { false }
}

public enum ExternalLinkAccount {
    public static var isEligible: Bool { false }
}

public enum ExternalPurchaseLink {
    public static var isEligible: Bool { false }
}

public enum ExternalPurchaseCustomLink {
    public struct Token: Hashable, Sendable { public init() {} }
    public struct NoticeType: Hashable, Sendable { public init() {} }
    public static var isEligible: Bool { false }
}

public struct InvalidRequestError: Error, Hashable, Sendable {
    public init() {}
}

public struct PaymentMethodBinding: Hashable, Sendable {
    public var id: String { "" }
}

public struct AdvancedCommerceProduct: Hashable, Sendable {
    public struct PurchaseOption: Hashable, Sendable {
        public init() {}
    }
    public var id: String { "" }
}

public struct Message: Hashable, Sendable {
    public struct Reason: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }
    public struct Messages {}
    public var reason: Reason { Reason(rawValue: "") }
}

public typealias SubscriptionInfo = Product.SubscriptionInfo
public typealias SubscriptionPeriod = Product.SubscriptionPeriod

extension Product {
    public struct SubscriptionRelationship: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }
    public struct PromotionInfo: Hashable, Sendable {
        public var productID: String { "" }
    }
    public enum TaskState {
        case loading
        case success(Product)
        case failure(any Error)
        case unavailable
    }
    public enum CollectionTaskState {
        case loading
        case success([Product])
        case failure(any Error)
    }
    public enum PurchaseError: Error {
        case invalidQuantity
        case productUnavailable
        case purchaseNotAllowed
        case ineligibleForOffer
        case invalidOfferIdentifier
        case invalidOfferPrice
        case missingOfferParameters
        case invalidOfferSignature
    }
}

extension Product.SubscriptionInfo {
    public struct Status: Hashable, Sendable {
        public var state: RenewalState { RenewalState(rawValue: 0) }
    }
    public struct RenewalInfo: Hashable, Sendable {
        public var willAutoRenew: Bool { false }
    }
    public struct RenewalState: Hashable, Sendable, RawRepresentable {
        public var rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let subscribed = RenewalState(rawValue: 1)
        public static let expired = RenewalState(rawValue: 2)
        public static let inBillingRetryPeriod = RenewalState(rawValue: 3)
        public static let inGracePeriod = RenewalState(rawValue: 4)
        public static let revoked = RenewalState(rawValue: 5)
    }
}

public typealias SubscriptionStatus = Product.SubscriptionInfo.Status
public typealias SubscriptionRenewalInfo = Product.SubscriptionInfo.RenewalInfo
public typealias SubscriptionRenewalState = Product.SubscriptionInfo.RenewalState

extension Product.SubscriptionOffer {
    public struct PaymentMode: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let freeTrial = PaymentMode(rawValue: "freeTrial")
        public static let payAsYouGo = PaymentMode(rawValue: "payAsYouGo")
        public static let payUpFront = PaymentMode(rawValue: "payUpFront")
    }
    public struct OfferType: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let introductory = OfferType(rawValue: "introductory")
        public static let promotional = OfferType(rawValue: "promotional")
        public static let winBack = OfferType(rawValue: "winBack")
    }
}

extension Product.SubscriptionPeriod.Unit {
    public struct FormatStyle: Hashable, Sendable, Foundation.FormatStyle {
        public typealias FormatInput = Product.SubscriptionPeriod.Unit
        public typealias FormatOutput = String
        public init() {}
        public init(from decoder: any Decoder) throws { self.init() }
        public func encode(to encoder: any Encoder) throws {}
        public func format(_ value: Product.SubscriptionPeriod.Unit) -> String { String(describing: value) }
        public func locale(_ locale: Locale) -> Product.SubscriptionPeriod.Unit.FormatStyle { self }
    }
}

extension Transaction {
    public struct Transactions: AsyncSequence {
        public typealias Element = VerificationResult<Transaction>
        public struct AsyncIterator: AsyncIteratorProtocol {
            public mutating func next() async -> Element? { nil }
        }
        public func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
    }
    public struct AdvancedCommerceInfo: Hashable, Sendable {
        public init() {}
    }
    public struct Offer: Hashable, Sendable {
        public var id: String? { nil }
    }
    public struct Reason: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let purchase = Reason(rawValue: "purchase")
        public static let renewal = Reason(rawValue: "renewal")
    }
    public struct OfferType: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }
    public struct OwnershipType: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let purchased = OwnershipType(rawValue: "purchased")
        public static let familyShared = OwnershipType(rawValue: "familyShared")
    }
    public struct RevocationReason: Hashable, Sendable, RawRepresentable {
        public var rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
    }
    public enum RefundRequestStatus: Hashable, Sendable {
        case success
        case userCancelled
    }
    public enum RefundRequestError: Error {
        case duplicateRequest
        case failed
    }
    public var jsonRepresentation: Data { Data() }
    public var reason: Reason { .purchase }
    public var offer: Offer? { nil }
}

extension Storefront {
    public struct Storefronts: AsyncSequence {
        public typealias Element = Storefront
        public struct AsyncIterator: AsyncIteratorProtocol {
            public mutating func next() async -> Element? { nil }
        }
        public func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
    }
    public static var updates: Storefronts { Storefronts() }
}

extension StoreKitError: LocalizedError {
    public var errorDescription: String? { String(describing: self) }
    public var failureReason: String? { nil }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
}

extension SKPaymentQueue {
    public var transactions: [SKPaymentTransaction] { [] }
    public var storefront: SKStorefront? { nil }
    public weak var delegate: SKPaymentQueueDelegate? {
        get { nil }
        set { _ = newValue }
    }
}

extension SKPayment {
    public var requestData: Data? { nil }
    public var applicationUsername: String? { nil }
    public var simulatesAskToBuyInSandbox: Bool { false }
    public var paymentDiscount: SKPaymentDiscount? { nil }
}
