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

    public static var errorDomain: String { SKANErrorDomain }
    public static var impressionMissingRequiredValue: Code { .impressionMissingRequiredValue }
    public static var unsupported: Code { .unsupported }
    public static var adNetworkIdMissing: Code { .adNetworkIdMissing }
    public static var mismatchedSourceAppId: Code { .mismatchedSourceAppId }
    public static var impressionNotFound: Code { .impressionNotFound }
    public static var invalidCampaignId: Code { .invalidCampaignId }
    public static var invalidConversionValue: Code { .invalidConversionValue }
    public static var invalidSourceAppId: Code { .invalidSourceAppId }
    public static var invalidAdvertisedAppId: Code { .invalidAdvertisedAppId }
    public static var invalidVersion: Code { .invalidVersion }
    public static var unknown: Code { .unknown }
    public static var impressionTooShort: Code { .impressionTooShort }

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
    public var price: NSDecimalNumber
    public var priceLocale: Locale
    public var identifier: String?
    public var subscriptionPeriod: SKProductSubscriptionPeriod
    public var numberOfPeriods: Int
    public var paymentMode: PaymentMode
    public var type: `Type`
    public override init() {
        price = 0
        priceLocale = Locale(identifier: "en_US_POSIX")
        identifier = nil
        subscriptionPeriod = SKProductSubscriptionPeriod()
        numberOfPeriods = 0
        paymentMode = .payAsYouGo
        type = .introductory
        super.init()
    }
}

open class SKProductSubscriptionPeriod: NSObject {
    public var numberOfUnits: Int
    public var unit: SKProduct.PeriodUnit
    public override init() {
        numberOfUnits = 0
        unit = .day
        super.init()
    }
    public init(numberOfUnits: Int, unit: SKProduct.PeriodUnit) {
        self.numberOfUnits = numberOfUnits
        self.unit = unit
        super.init()
    }
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
    public func fetchStorePromotionOrder(
        completionHandler: (([SKProduct], (any Error)?) -> Void)? = nil
    ) {
        completionHandler?([], StoreKitPortableError(.serviceUnavailable))
    }
    public func update(promotionOrder: [SKProduct]) async throws {
        _ = promotionOrder
        throw StoreKitError.notAvailableInStorefront
    }
    public func update(
        promotionVisibility: SKProductStorePromotionVisibility,
        for product: SKProduct
    ) async throws {
        _ = promotionVisibility
        _ = product
        throw StoreKitError.notAvailableInStorefront
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
    public var countryCode: String
    public var identifier: String
    public override init() {
        countryCode = ""
        identifier = ""
        super.init()
    }
    public init(identifier: String, countryCode: String) {
        self.identifier = identifier
        self.countryCode = countryCode
        super.init()
    }
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
    func paymentQueueShouldShowPriceConsent(_ paymentQueue: SKPaymentQueue) -> Bool
}

public extension SKPaymentQueueDelegate {
    func paymentQueue(_ queue: SKPaymentQueue, shouldContinue transaction: SKPaymentTransaction, in newStorefront: SKStorefront) -> Bool {
        false
    }
    func paymentQueueShouldShowPriceConsent(_ paymentQueue: SKPaymentQueue) -> Bool {
        false
    }
}

public protocol StoreDownloaderExtension {}

public struct AppStoreMerchandisingKind: Hashable, Sendable {
    public enum PresentationResult: Hashable, Sendable {
        case dismissed
        case purchaseCompleted(Product.PurchaseResult)
    }
    public init() {}
    public static func subscriptionBundle(_ groupID: String) -> AppStoreMerchandisingKind {
        _ = groupID
        return AppStoreMerchandisingKind()
    }
}

public struct AppTransaction: Hashable, Sendable, CustomDebugStringConvertible {
    public var jsonRepresentation: Data { Data() }
    public let originalAppVersion: String
    public let appVersion: String
    public let signedDate: Date
    public let environment: AppStore.Environment
    public let appVersionID: UInt64?
    public let preorderDate: Date?
    public let originalPlatform: AppStore.Platform
    public let deviceVerification: Data
    public let originalPurchaseDate: Date
    public let deviceVerificationNonce: UUID
    public let appID: UInt64?
    public let bundleID: String
    public var appTransactionID: String { "0" }
    public var originalPlatformStringRepresentation: String { originalPlatform.rawValue }
    public var debugDescription: String { "AppTransaction(\(bundleID))" }

    public init() {
        originalAppVersion = "1.0"
        appVersion = "1.0"
        signedDate = Date(timeIntervalSince1970: 0)
        environment = .xcode
        appVersionID = nil
        preorderDate = nil
        originalPlatform = .iOS
        deviceVerification = Data()
        originalPurchaseDate = Date(timeIntervalSince1970: 0)
        deviceVerificationNonce = UUID()
        appID = nil
        bundleID = Bundle.main.bundleIdentifier ?? ""
    }

    public static var shared: VerificationResult<AppTransaction> {
        get async throws {
            guard LocalTestingStore.shared.isLoaded else {
                throw StoreKitError.notAvailableInStorefront
            }
            return .unverified(AppTransaction(), .invalidSignature)
        }
    }

    public static func refresh() async throws -> VerificationResult<AppTransaction> {
        try await shared
    }
}

public struct PurchaseIntent: Hashable, Sendable, Identifiable {
    public typealias ID = Product.ID
    public struct PurchaseIntents: AsyncSequence {
        public typealias Element = PurchaseIntent
        public struct AsyncIterator: AsyncIteratorProtocol {
            public mutating func next() async -> PurchaseIntent? { nil }
        }
        public func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
    }
    public var product: Product
    public var offer: Product.SubscriptionOffer?
    public var id: Product.ID { product.id }
    public static var intents: PurchaseIntents { PurchaseIntents() }
    public init(product: Product, offer: Product.SubscriptionOffer? = nil) {
        self.product = product
        self.offer = offer
    }
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

