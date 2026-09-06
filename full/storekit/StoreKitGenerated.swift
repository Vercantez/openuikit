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

    public class func registerArcadeAppWithRandom(
        fromLib randomFromLib: Data,
        randomFromLibLength: UInt32,
        resultHandler: @escaping (Data?, UInt32, Data?, UInt32, (any Error)?) -> Void
    ) {
        _ = randomFromLib
        _ = randomFromLibLength
        resultHandler(nil, 0, nil, 0, StoreKitPortableError(.serviceUnavailable))
    }

    public class func arcadeSubscriptionStatus(
        withNonce nonce: UInt64,
        resultHandler: @escaping (Data?, UInt32, Data?, UInt32, (any Error)?) -> Void
    ) {
        _ = nonce
        resultHandler(nil, 0, nil, 0, StoreKitPortableError(.serviceUnavailable))
    }

    public class func repairArcadeApp() {}
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

    public func requestUserTokenNow(forDeveloperToken developerToken: String) throws -> String {
        _ = developerToken
        throw StoreKitPortableError(.serviceUnavailable)
    }

    public func requestUserToken(forDeveloperToken developerToken: String) async throws -> String {
        try requestUserTokenNow(forDeveloperToken: developerToken)
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
    public var downloadState: SKDownloadState { state }
    public var contentIdentifier: String { "" }
    public var contentURL: URL? { nil }
    public var contentVersion: String { "" }
    public var error: (any Error)? { StoreKitPortableError(.serviceUnavailable) }
    public var progress: Float { 0 }
    public var timeRemaining: TimeInterval { SKDownloadTimeRemainingUnknown }
    public var expectedContentLength: Int64 { 0 }
    public var contentLength: Int64 { expectedContentLength }
    public var transaction: SKPaymentTransaction? { nil }
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

    public override func start() {
        guard !isCancelled else { return }
        delegate?.request(self, didFailWithError: SKError(.unsupportedPlatform))
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
        public var campaignToken: String?
        public var providerToken: String?
        public var customProductPageIdentifier: String?
        public var latestReleaseID: String?
        public var userDismissible = true
        var additional: [String: Any] = [:]
        public init(appIdentifier: String, position: Position) {
            self.appIdentifier = appIdentifier
            self.position = position
            super.init()
        }
        public func additionalValue(forKey key: String) -> Any? { additional[key] }
        public func setAdditionalValue(_ value: Any?, forKey key: String) {
            additional[key] = value
        }
        public func setAdImpression(_ impression: SKAdImpression?) {
            additional["adImpression"] = impression
        }
    }
    open class AppClipConfiguration: Configuration {
        public var position: Position
        public var campaignToken: String?
        public var providerToken: String?
        public var customProductPageIdentifier: String?
        public var latestReleaseID: String?
        var additional: [String: Any] = [:]
        public init(position: Position) {
            self.position = position
            super.init()
        }
        public func additionalValue(forKey key: String) -> Any? { additional[key] }
        public func setAdditionalValue(_ value: Any?, forKey key: String) {
            additional[key] = value
        }
    }
    public enum Position: Int, Sendable {
        case bottom = 0
        case bottomRaised = 1
    }
    public final class TransitionContext: NSObject {
        public var startFrame: CGRect = .zero
        public var endFrame: CGRect = .zero
        public override init() { super.init() }
        public func addAnimationBlock(_ animation: @escaping () -> Void) { animation() }
        public func add(_ animation: @escaping () -> Void) { animation() }
    }
    public var configuration: Configuration
    public weak var delegate: SKOverlayDelegate?
    public private(set) var portablePresentCount = 0
    public init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
    }
    public func present(in scene: UIWindowScene) {
        _ = scene
        portablePresentCount += 1
    }
    public func dismiss(from scene: UIWindowScene) {
        _ = scene
        portablePresentCount += 1
    }
    /// Apple class method `dismissOverlayInScene:`. Linux records the call
    /// and does not present or dismiss UI.
    public class func dismiss(in scene: UIWindowScene) {
        _ = scene
    }
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
    public private(set) var portableLoadCount = 0
    public func loadProduct(
        withParameters parameters: [String: Any],
        completionBlock: ((Bool, (any Error)?) -> Void)? = nil
    ) {
        _ = parameters
        portableLoadCount += 1
        completionBlock?(false, StoreKitPortableError(.serviceUnavailable))
    }
    public func loadProduct(
        withParameters parameters: [String: Any],
        impression: SKAdImpression,
        completionBlock: ((Bool, (any Error)?) -> Void)? = nil
    ) {
        _ = impression
        loadProduct(withParameters: parameters, completionBlock: completionBlock)
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
    public let jsonRepresentation: Data
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
    let jwsHeaderData: Data
    let jwsPayloadData: Data
    let jwsSignatureData: Data
    let jwsRepresentation: String

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
        jsonRepresentation = Data()
        jwsHeaderData = Data()
        jwsPayloadData = Data()
        jwsSignatureData = Data()
        jwsRepresentation = ""
    }

    init(signed: StoreKitJWS, bundleID: String, environment: AppStore.Environment) {
        self.originalAppVersion = "1.0"
        self.appVersion = "1.0"
        self.signedDate = Date()
        self.environment = environment
        self.appVersionID = nil
        self.preorderDate = nil
        self.originalPlatform = .iOS
        self.deviceVerification = Data(repeating: 0, count: 16)
        self.originalPurchaseDate = Date(timeIntervalSince1970: 0)
        self.deviceVerificationNonce = UUID()
        self.appID = nil
        self.bundleID = bundleID
        self.jsonRepresentation = signed.payloadData
        self.jwsHeaderData = signed.headerData
        self.jwsPayloadData = signed.payloadData
        self.jwsSignatureData = signed.signatureData
        self.jwsRepresentation = signed.compactSerialization
    }

    public static func currentForTesting() throws -> VerificationResult<AppTransaction> {
        try LocalTestingStore.shared.appTransaction()
    }

    public static var shared: VerificationResult<AppTransaction> {
        get async throws {
            try currentForTesting()
        }
    }

    public static func refresh() async throws -> VerificationResult<AppTransaction> {
        try currentForTesting()
    }
}

public struct PurchaseIntent: Hashable, Sendable, Identifiable {
    public typealias ID = Product.ID
    public struct PurchaseIntents: AsyncSequence {
        public typealias Element = PurchaseIntent
        public struct AsyncIterator: AsyncIteratorProtocol {
            var snapshot: [PurchaseIntent]
            var index = 0
            public mutating func next() async -> PurchaseIntent? {
                guard index < snapshot.count else { return nil }
                let value = snapshot[index]
                index += 1
                return value
            }
        }
        let snapshot: [PurchaseIntent]
        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(snapshot: snapshot)
        }
    }
    public var product: Product
    public var offer: Product.SubscriptionOffer?
    public var id: Product.ID { product.id }
    public static var intents: PurchaseIntents {
        PurchaseIntents(snapshot: LocalTestingStore.shared.pendingPurchaseIntents())
    }
    public init(product: Product, offer: Product.SubscriptionOffer? = nil) {
        self.product = product
        self.offer = offer
    }
}

public enum ExternalPurchase {
    public enum NoticeResult: Hashable, Sendable {
        case cancelled
        case continuedWithExternalPurchaseToken(token: String)
    }

    public static var isEligible: Bool { false }
    public static var canPresentNow: Bool { false }
    public static var canPresent: Bool {
        get async { canPresentNow }
    }

    public static func presentNoticeSheetNow() throws -> NoticeResult {
        throw StoreKitError.notAvailableInStorefront
    }

    public static func presentNoticeSheet() async throws -> NoticeResult {
        try presentNoticeSheetNow()
    }
}

public enum ExternalLinkAccount {
    public static var isEligible: Bool { false }
    public static var canOpenNow: Bool { false }
    public static var canOpen: Bool {
        get async { canOpenNow }
    }

    public static func openNow() throws {
        throw StoreKitError.notAvailableInStorefront
    }

    public static func open() async throws {
        try openNow()
    }
}

public enum ExternalPurchaseLink {
    public static var isEligible: Bool { false }
    public static var canOpenNow: Bool { false }
    public static var canOpen: Bool {
        get async { canOpenNow }
    }
    public static var eligibleURLs: [URL]? { nil }

    public static func openNow() throws {
        throw StoreKitError.notAvailableInStorefront
    }

    public static func open() async throws {
        try openNow()
    }

    public static func openNow(url: URL) throws {
        _ = url
        throw StoreKitError.notAvailableInStorefront
    }

    public static func open(url: URL) async throws {
        try openNow(url: url)
    }
}

public enum ExternalPurchaseCustomLink {
    public struct Token: Hashable, Sendable {
        public let value: String
        public init(value: String = "") { self.value = value }
    }

    public enum NoticeType: Int, Hashable, Sendable {
        case browser = 0
        case withinApp = 1
    }

    public enum NoticeResult: Hashable, Sendable {
        case cancelled
        case continued
    }

    public static var isEligibleNow: Bool { false }
    public static var isEligible: Bool {
        get async { isEligibleNow }
    }

    public static func tokenNow(for tokenType: String) throws -> Token? {
        _ = tokenType
        throw StoreKitError.notAvailableInStorefront
    }

    public static func token(for tokenType: String) async throws -> Token? {
        try tokenNow(for: tokenType)
    }

    public static func showNoticeNow(type: NoticeType) throws -> NoticeResult {
        _ = type
        throw StoreKitError.notAvailableInStorefront
    }

    public static func showNotice(type: NoticeType) async throws -> NoticeResult {
        try showNoticeNow(type: type)
    }
}

public struct InvalidRequestError: Error, Hashable, Sendable {
    public var code: Int64
    public var message: String
    public init(code: Int64 = 0, message: String = "") {
        self.code = code
        self.message = message
    }
}

public struct PaymentMethodBinding: Hashable, Sendable, Identifiable {
    public typealias ID = String
    public enum PaymentMethodBindingError: Error, Hashable, Sendable, LocalizedError {
        case notEligible
        case invalidPinningID
        case failed
        public var errorDescription: String? { String(describing: self) }
        public var failureReason: String? { errorDescription }
        public var recoverySuggestion: String? { nil }
        public var helpAnchor: String? { nil }
    }

    public let id: String

    public init(portableID: String) {
        self.id = portableID
    }

    public static func make(id: String) throws -> PaymentMethodBinding {
        _ = id
        throw PaymentMethodBindingError.notEligible
    }

    public init(id: String) async throws {
        self = try Self.make(id: id)
    }

    public func bindNow() throws {
        throw PaymentMethodBindingError.failed
    }

    public func bind() async throws {
        try bindNow()
    }
}

public struct AdvancedCommerceProduct: Hashable, Sendable, Identifiable, CustomDebugStringConvertible {
    public typealias ID = String
    public typealias ProductType = Product.ProductType
    public typealias PurchaseResult = Product.PurchaseResult

    public struct PurchaseOption: Hashable, Sendable, CustomDebugStringConvertible {
        public var debugDescription: String { "AdvancedCommerceProduct.PurchaseOption" }
        public init() {}
        public static func onStorefrontChange(
            shouldContinuePurchase: @escaping (Storefront) -> Bool
        ) -> PurchaseOption {
            _ = shouldContinuePurchase
            return PurchaseOption()
        }
    }

    public let id: ID
    public let type: ProductType
    public var debugDescription: String { "AdvancedCommerceProduct(\(id))" }
    public var currentEntitlements: Transaction.Transactions {
        Transaction.currentEntitlements
    }
    public var allTransactions: Transaction.Transactions { Transaction.all }
    public var latestTransaction: VerificationResult<Transaction>? {
        get async { await Transaction.latest(for: id) }
    }

    public init(portableID: String, type: ProductType = .autoRenewable) {
        self.id = portableID
        self.type = type
    }

    public static func make(id: ID) throws -> AdvancedCommerceProduct {
        guard LocalTestingStore.shared.isLoaded else {
            throw StoreKitError.notAvailableInStorefront
        }
        return AdvancedCommerceProduct(portableID: id)
    }

    public init(id: ID) async throws {
        self = try Self.make(id: id)
    }

    public func purchaseNow(
        compactJWS: String,
        options: Set<PurchaseOption> = []
    ) throws -> PurchaseResult {
        _ = compactJWS
        _ = options
        throw StoreKitError.notAvailableInStorefront
    }

    public func purchase(
        compactJWS: String,
        confirmIn viewController: UIViewController,
        options: Set<PurchaseOption> = []
    ) async throws -> PurchaseResult {
        _ = viewController
        return try purchaseNow(compactJWS: compactJWS, options: options)
    }
}

public struct Message: Hashable, Sendable {
    public struct Reason: Hashable, Sendable, RawRepresentable {
        public typealias RawValue = Int
        public var rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let generic = Reason(rawValue: 0)
        public static let billingIssue = Reason(rawValue: 1)
        public static let priceIncreaseConsent = Reason(rawValue: 2)
        public static let winBackOffer = Reason(rawValue: 3)
        public var localizedDescription: String {
            switch self {
            case .billingIssue: return "billingIssue"
            case .priceIncreaseConsent: return "priceIncreaseConsent"
            case .winBackOffer: return "winBackOffer"
            default: return "generic"
            }
        }
    }

    public struct Messages: AsyncSequence {
        public typealias Element = Message
        public struct AsyncIterator: AsyncIteratorProtocol {
            var snapshot: [Message]
            var index = 0
            public mutating func next() async -> Message? {
                guard index < snapshot.count else { return nil }
                let value = snapshot[index]
                index += 1
                return value
            }
        }
        let snapshot: [Message]
        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator(snapshot: snapshot)
        }
    }

    public let reason: Reason
    public static var messages: Messages {
        Messages(snapshot: LocalTestingStore.shared.pendingMessages())
    }

    public init(reason: Reason) {
        self.reason = reason
    }

    public func display(in scene: UIWindowScene) throws {
        _ = scene
        throw StoreKitError.notAvailableInStorefront
    }
}

