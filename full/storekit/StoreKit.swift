import Foundation
#if canImport(AppKit)
@_exported import AppKit
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(OpenUIKit)
import OpenUIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

public struct StoreKitPortableError: Error, Equatable, Sendable,
    CustomStringConvertible
{
    public enum Code: Int, Sendable {
        case serviceUnavailable = 1
        case paymentsUnavailable = 2
        case productUnavailable = 3
    }

    public let code: Code
    public let description: String

    public init(_ code: Code) {
        self.code = code
        switch code {
        case .serviceUnavailable:
            description = "App Store service is unavailable on this host"
        case .paymentsUnavailable:
            description = "App Store payments are unavailable on this host"
        case .productUnavailable:
            description = "App Store product metadata is unavailable on this host"
        }
    }
}

/// Errors published by StoreKit 2.
///
/// Apple: https://developer.apple.com/documentation/storekit/storekiterror
/// `notAvailableInStorefront` — the function isn’t available on devices
/// configured for this storefront. Linux has no App Store; the local testing
/// store throws this when no `.storekit` configuration is loaded.
public enum StoreKitError: Error, Sendable, LocalizedError {
    case unknown
    case userCancelled
    case networkError(URLError)
    case systemError(any Error)
    case notAvailableInStorefront
    case notEntitled
    case unsupported

    public var errorDescription: String? { String(describing: self) }
    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
}

open class SKStoreReviewController: NSObject {
    public private(set) static var portableRequestCount = 0
    public static let portableError = StoreKitPortableError(.serviceUnavailable)

    public override init() { super.init() }

    public class func requestReview() {
        portableRequestCount += 1
    }

    public class func requestReview(in windowScene: UIWindowScene) {
        _ = windowScene
        portableRequestCount += 1
    }
}

public enum AppStore {
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

    public private(set) static var portableReviewRequestCount = 0

    public static var canMakePayments: Bool {
        LocalTestingStore.shared.canMakePayments
    }

    public static var deviceVerificationID: UUID? { nil }

    public static func requestReview(in scene: UIWindowScene) {
        portableReviewRequestCount += 1
        _ = scene
    }

    /// Apple: `AppStore.sync()` synchronizes transaction information with the
    /// App Store. https://developer.apple.com/documentation/storekit/appstore/sync()
    /// Without a loaded `.storekit` configuration this host has no storefront.
    public static func sync() async throws {
        try StoreKitTesting.sync()
    }

    public static func showManageSubscriptions(in scene: UIWindowScene) async throws {
        _ = scene
        try StoreKitTesting.showManageSubscriptions()
    }

    public static func showManageSubscriptions(
        in scene: UIWindowScene,
        subscriptionGroupID: String
    ) async throws {
        _ = scene
        _ = subscriptionGroupID
        try StoreKitTesting.showManageSubscriptions()
    }

    @MainActor
    public static func presentOfferCodeRedeemSheet(in scene: UIWindowScene) async throws {
        _ = scene
        throw StoreKitError.notAvailableInStorefront
    }

    @MainActor
    public static func presentMerchandising(
        _ kind: AppStoreMerchandisingKind,
        from controller: UIViewController
    ) async throws -> AppStoreMerchandisingKind.PresentationResult {
        _ = kind
        _ = controller
        throw StoreKitError.notAvailableInStorefront
    }
}

public struct SKError: Error, Hashable, @unchecked Sendable, CustomStringConvertible, LocalizedError {
    public enum Code: Int, Sendable, Hashable {
        case unknown = 0
        case clientInvalid = 1
        case paymentCancelled = 2
        case paymentInvalid = 3
        case paymentNotAllowed = 4
        case storeProductNotAvailable = 5
        case cloudServicePermissionDenied = 6
        case cloudServiceNetworkConnectionFailed = 7
        case cloudServiceRevoked = 8
        case privacyAcknowledgementRequired = 9
        case unauthorizedRequestData = 10
        case invalidOfferIdentifier = 11
        case invalidSignature = 12
        case missingOfferParams = 13
        case invalidOfferPrice = 14
        case overlayCancelled = 15
        case overlayInvalidConfiguration = 16
        case overlayTimeout = 17
        case ineligibleForOffer = 18
        case unsupportedPlatform = 19
        case overlayPresentedInBackgroundScene = 20
    }

    public static var errorDomain: String { SKErrorDomain }
    public static var unknown: Code { .unknown }
    public static var clientInvalid: Code { .clientInvalid }
    public static var paymentCancelled: Code { .paymentCancelled }
    public static var paymentInvalid: Code { .paymentInvalid }
    public static var paymentNotAllowed: Code { .paymentNotAllowed }
    public static var storeProductNotAvailable: Code { .storeProductNotAvailable }
    public static var cloudServicePermissionDenied: Code { .cloudServicePermissionDenied }
    public static var cloudServiceNetworkConnectionFailed: Code { .cloudServiceNetworkConnectionFailed }
    public static var cloudServiceRevoked: Code { .cloudServiceRevoked }
    public static var privacyAcknowledgementRequired: Code { .privacyAcknowledgementRequired }
    public static var unauthorizedRequestData: Code { .unauthorizedRequestData }
    public static var invalidOfferIdentifier: Code { .invalidOfferIdentifier }
    public static var invalidSignature: Code { .invalidSignature }
    public static var missingOfferParams: Code { .missingOfferParams }
    public static var invalidOfferPrice: Code { .invalidOfferPrice }
    public static var overlayCancelled: Code { .overlayCancelled }
    public static var overlayInvalidConfiguration: Code { .overlayInvalidConfiguration }
    public static var overlayTimeout: Code { .overlayTimeout }
    public static var ineligibleForOffer: Code { .ineligibleForOffer }
    public static var unsupportedPlatform: Code { .unsupportedPlatform }
    public static var overlayPresentedInBackgroundScene: Code { .overlayPresentedInBackgroundScene }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var description: String { "StoreKit error \(code.rawValue)" }
    public var errorDescription: String? { description }

    public static func == (lhs: SKError, rhs: SKError) -> Bool {
        lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

public let SKErrorDomain = "SKErrorDomain"

open class SKRequest {
    public weak var delegate: SKRequestDelegate?
    public private(set) var isCancelled = false

    public init() {}

    open func start() {
        guard !isCancelled else { return }
        delegate?.request(
            self,
            didFailWithError: StoreKitPortableError(.serviceUnavailable)
        )
    }

    open func cancel() { isCancelled = true }
}

public protocol SKRequestDelegate: NSObjectProtocol {
    func requestDidFinish(_ request: SKRequest)
    func request(_ request: SKRequest, didFailWithError error: Error)
}

public extension SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {}
    func request(_ request: SKRequest, didFailWithError error: Error) {}
}

public final class SKProductsResponse {
    public let products: [SKProduct]
    public let invalidProductIdentifiers: [String]

    public init(products: [SKProduct], invalidProductIdentifiers: [String]) {
        self.products = products
        self.invalidProductIdentifiers = invalidProductIdentifiers
    }
}

public protocol SKProductsRequestDelegate: SKRequestDelegate {
    func productsRequest(
        _ request: SKProductsRequest,
        didReceive response: SKProductsResponse
    )
}

public final class SKProductsRequest: SKRequest {
    public let productIdentifiers: Set<String>
    public weak var productsDelegate: SKProductsRequestDelegate?

    public override var delegate: SKRequestDelegate? {
        get { productsDelegate }
        set { productsDelegate = newValue as? SKProductsRequestDelegate }
    }

    public init(productIdentifiers: Set<String>) {
        self.productIdentifiers = productIdentifiers
        super.init()
    }

    public override func start() {
        guard !isCancelled else { return }
        guard LocalTestingStore.shared.isLoaded else {
            let error = SKError(.paymentNotAllowed)
            productsDelegate?.request(self, didFailWithError: error)
            return
        }
        let split = LocalTestingStore.shared.skProducts(for: productIdentifiers)
        let response = SKProductsResponse(
            products: split.valid,
            invalidProductIdentifiers: split.invalid
        )
        productsDelegate?.productsRequest(self, didReceive: response)
        productsDelegate?.requestDidFinish(self)
    }
}

public final class SKProduct {
    public enum PeriodUnit: UInt, Sendable {
        case day = 0
        case week = 1
        case month = 2
        case year = 3

        init(storeKitUnit: Product.SubscriptionPeriod.Unit) {
            switch storeKitUnit {
            case .day: self = .day
            case .week: self = .week
            case .month: self = .month
            case .year: self = .year
            }
        }
    }

    public let productIdentifier: String
    public let localizedTitle: String
    public let localizedDescription: String
    public let price: NSDecimalNumber
    public let priceLocale: Locale
    public let subscriptionPeriod: SKProductSubscriptionPeriod?
    public let introductoryPrice: SKProductDiscount?
    public let subscriptionGroupIdentifier: String?
    public let discounts: [SKProductDiscount]
    public let isDownloadable: Bool
    public let downloadContentLengths: [NSNumber]
    public let downloadContentVersion: String
    public let contentVersion: String
    public let isFamilyShareable: Bool

    public init(
        productIdentifier: String,
        localizedTitle: String = "",
        localizedDescription: String = "",
        price: NSDecimalNumber = NSDecimalNumber(value: 0),
        priceLocale: Locale = Locale(identifier: "en_US_POSIX"),
        subscriptionGroupIdentifier: String? = nil,
        subscriptionPeriod: SKProductSubscriptionPeriod? = nil,
        introductoryPrice: SKProductDiscount? = nil,
        discounts: [SKProductDiscount] = [],
        isDownloadable: Bool = false,
        downloadContentLengths: [NSNumber] = [],
        downloadContentVersion: String = "",
        isFamilyShareable: Bool = false
    ) {
        self.productIdentifier = productIdentifier
        self.localizedTitle = localizedTitle
        self.localizedDescription = localizedDescription
        self.price = price
        self.priceLocale = priceLocale
        self.subscriptionGroupIdentifier = subscriptionGroupIdentifier
        self.subscriptionPeriod = subscriptionPeriod
        self.introductoryPrice = introductoryPrice
        self.discounts = discounts
        self.isDownloadable = isDownloadable
        self.downloadContentLengths = downloadContentLengths
        self.downloadContentVersion = downloadContentVersion
        self.contentVersion = downloadContentVersion
        self.isFamilyShareable = isFamilyShareable
    }

    public convenience init(
        productIdentifier: String,
        localizedTitle: String = "",
        localizedDescription: String = "",
        price: Decimal
    ) {
        self.init(
            productIdentifier: productIdentifier,
            localizedTitle: localizedTitle,
            localizedDescription: localizedDescription,
            price: NSDecimalNumber(decimal: price)
        )
    }

    public var formattedPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)
    }
}

public enum SKPaymentTransactionState: Int, Sendable {
    case purchasing = 0
    case purchased = 1
    case failed = 2
    case restored = 3
    case deferred = 4
}

open class SKPayment: NSObject {
    var storedProductIdentifier: String
    var storedQuantity: Int
    var storedRequestData: Data?
    var storedApplicationUsername: String?
    var storedSimulatesAskToBuy: Bool
    var storedPaymentDiscount: SKPaymentDiscount?

    open var productIdentifier: String { storedProductIdentifier }
    open var quantity: Int { storedQuantity }
    open var requestData: Data? { storedRequestData }
    open var applicationUsername: String? { storedApplicationUsername }
    open var simulatesAskToBuyInSandbox: Bool { storedSimulatesAskToBuy }
    open var paymentDiscount: SKPaymentDiscount? { storedPaymentDiscount }

    public convenience init(product: SKProduct) {
        self.init(productIdentifier: product.productIdentifier)
    }

    public init(productIdentifier: String) {
        storedProductIdentifier = productIdentifier
        storedQuantity = 1
        storedSimulatesAskToBuy = false
        super.init()
    }
}

public final class SKMutablePayment: SKPayment {
    public override var productIdentifier: String {
        get { storedProductIdentifier }
        set { storedProductIdentifier = newValue }
    }
    public override var quantity: Int {
        get { storedQuantity }
        set { storedQuantity = max(1, newValue) }
    }
    public override var requestData: Data? {
        get { storedRequestData }
        set { storedRequestData = newValue }
    }
    public override var applicationUsername: String? {
        get { storedApplicationUsername }
        set { storedApplicationUsername = newValue }
    }
    public override var simulatesAskToBuyInSandbox: Bool {
        get { storedSimulatesAskToBuy }
        set { storedSimulatesAskToBuy = newValue }
    }
    public override var paymentDiscount: SKPaymentDiscount? {
        get { storedPaymentDiscount }
        set { storedPaymentDiscount = newValue }
    }
}

public final class SKPaymentTransaction {
    public let payment: SKPayment
    public let transactionState: SKPaymentTransactionState
    public let error: Error?
    public let transactionIdentifier: String?
    public let transactionDate: Date?
    public let original: SKPaymentTransaction?
    public let downloads: [SKDownload]

    public init(
        payment: SKPayment,
        transactionState: SKPaymentTransactionState,
        error: Error?,
        transactionIdentifier: String? = nil,
        transactionDate: Date? = nil,
        original: SKPaymentTransaction? = nil,
        downloads: [SKDownload] = []
    ) {
        self.payment = payment
        self.transactionState = transactionState
        self.error = error
        self.transactionIdentifier = transactionIdentifier
        self.transactionDate = transactionDate
        self.original = original
        self.downloads = downloads
    }
}

public protocol SKPaymentTransactionObserver: NSObjectProtocol {
    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    )
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue)
    func paymentQueue(
        _ queue: SKPaymentQueue,
        restoreCompletedTransactionsFailedWithError error: Error
    )
    func paymentQueue(
        _ queue: SKPaymentQueue,
        removedTransactions transactions: [SKPaymentTransaction]
    )
    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedDownloads downloads: [SKDownload]
    )
    func paymentQueue(
        _ queue: SKPaymentQueue,
        shouldAddStorePayment payment: SKPayment,
        for product: SKProduct
    ) -> Bool
    func paymentQueue(
        _ queue: SKPaymentQueue,
        didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]
    )
    func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue)
}

public extension SKPaymentTransactionObserver {
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {}
    func paymentQueue(
        _ queue: SKPaymentQueue,
        restoreCompletedTransactionsFailedWithError error: Error
    ) {}
    func paymentQueue(
        _ queue: SKPaymentQueue,
        removedTransactions transactions: [SKPaymentTransaction]
    ) {}
    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedDownloads downloads: [SKDownload]
    ) {}
    func paymentQueue(
        _ queue: SKPaymentQueue,
        shouldAddStorePayment payment: SKPayment,
        for product: SKProduct
    ) -> Bool {
        _ = queue
        _ = payment
        _ = product
        return false
    }
    func paymentQueue(
        _ queue: SKPaymentQueue,
        didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]
    ) {}
    func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue) {}
}

public final class SKPaymentQueue: NSObject {
    private static let shared = SKPaymentQueue()
    private var observers: [SKPaymentTransactionObserver] = []
    public weak var delegate: SKPaymentQueueDelegate?

    private override init() { super.init() }
    public static func `default`() -> SKPaymentQueue { shared }

    /// Apple: `canMakePayments` indicates whether the person can make purchases.
    /// https://developer.apple.com/documentation/storekit/skpaymentqueue/canmakepayments()
    /// `SKError.paymentNotAllowed` (raw 4) is used when they cannot.
    /// https://developer.apple.com/documentation/storekit/skerror/code
    public static func canMakePayments() -> Bool {
        LocalTestingStore.shared.canMakePayments
    }

    public var transactionObservers: [any SKPaymentTransactionObserver] { observers }
    public var transactions: [SKPaymentTransaction] {
        LocalTestingStore.shared.pendingSKTransactions
    }
    public var storefront: SKStorefront? {
        LocalTestingStore.shared.currentSKStorefront
    }

    public func add(_ observer: SKPaymentTransactionObserver) {
        if !observers.contains(where: { $0 === observer }) {
            observers.append(observer)
        }
    }

    public func remove(_ observer: SKPaymentTransactionObserver) {
        observers.removeAll { $0 === observer }
    }

    public func add(_ payment: SKPayment) {
        guard LocalTestingStore.shared.isLoaded else {
            let failure = SKPaymentTransaction(
                payment: payment,
                transactionState: .failed,
                error: SKError(.paymentNotAllowed),
                transactionDate: Date()
            )
            notify([failure])
            return
        }
        let purchasing = SKPaymentTransaction(
            payment: payment,
            transactionState: .purchasing,
            error: nil,
            transactionDate: Date()
        )
        notify([purchasing])
        guard let catalog = LocalTestingStore.shared.catalogProduct(id: payment.productIdentifier) else {
            let failure = SKPaymentTransaction(
                payment: payment,
                transactionState: .failed,
                error: SKError(.storeProductNotAvailable),
                transactionDate: Date()
            )
            notify([failure])
            return
        }
        let product = Product(
            id: catalog.id,
            displayName: catalog.displayName,
            description: catalog.description,
            price: catalog.price,
            displayPrice: catalog.displayPrice,
            type: catalog.type
        )
        do {
            let result = try LocalTestingStore.shared.purchase(
                product: product,
                quantity: payment.quantity,
                appAccountToken: nil
            )
            let purchased = SKPaymentTransaction(
                payment: payment,
                transactionState: .purchased,
                error: nil,
                transactionIdentifier: String(result.unsafePayloadValue.id),
                transactionDate: result.unsafePayloadValue.purchaseDate
            )
            LocalTestingStore.shared.recordSKTransaction(purchased)
            notify([purchased])
        } catch {
            let failure = SKPaymentTransaction(
                payment: payment,
                transactionState: .failed,
                error: error,
                transactionDate: Date()
            )
            notify([failure])
        }
    }

    public func finishTransaction(_ transaction: SKPaymentTransaction) {
        if let identifier = transaction.transactionIdentifier, let value = UInt64(identifier) {
            LocalTestingStore.shared.finish(id: value)
        }
        LocalTestingStore.shared.removeSKTransaction(transaction)
        for observer in observers {
            observer.paymentQueue(self, removedTransactions: [transaction])
        }
    }

    public func restoreCompletedTransactions() {
        restoreCompletedTransactions(withApplicationUsername: nil)
    }

    public func restoreCompletedTransactions(withApplicationUsername username: String?) {
        _ = username
        guard LocalTestingStore.shared.isLoaded else {
            let error = SKError(.paymentNotAllowed)
            for observer in observers {
                observer.paymentQueue(self, restoreCompletedTransactionsFailedWithError: error)
            }
            return
        }
        var restored: [SKPaymentTransaction] = []
        for catalog in LocalTestingStore.shared.restoredNonConsumables() {
            let payment = SKPayment(productIdentifier: catalog.id)
            let original = SKPaymentTransaction(
                payment: payment,
                transactionState: .purchased,
                error: nil,
                transactionIdentifier: "orig-\(catalog.id)",
                transactionDate: Date()
            )
            let transaction = SKPaymentTransaction(
                payment: payment,
                transactionState: .restored,
                error: nil,
                transactionIdentifier: "rest-\(catalog.id)",
                transactionDate: Date(),
                original: original
            )
            restored.append(transaction)
            LocalTestingStore.shared.recordSKTransaction(transaction)
        }
        if !restored.isEmpty {
            notify(restored)
        }
        for observer in observers {
            observer.paymentQueueRestoreCompletedTransactionsFinished(self)
        }
    }

    public func start(_ downloads: [SKDownload]) {
        for observer in observers {
            observer.paymentQueue(self, updatedDownloads: downloads)
        }
    }

    public func cancel(_ downloads: [SKDownload]) {
        for observer in observers {
            observer.paymentQueue(self, updatedDownloads: downloads)
        }
    }

    public func pause(_ downloads: [SKDownload]) {
        for observer in observers {
            observer.paymentQueue(self, updatedDownloads: downloads)
        }
    }

    public func resume(_ downloads: [SKDownload]) {
        for observer in observers {
            observer.paymentQueue(self, updatedDownloads: downloads)
        }
    }

    public func presentCodeRedemptionSheet() {}
    public func showPriceConsentIfNeeded() {}

    private func notify(_ transactions: [SKPaymentTransaction]) {
        for observer in observers {
            observer.paymentQueue(self, updatedTransactions: transactions)
        }
    }
}

open class SKAdNetwork: NSObject {
    public struct CoarseConversionValue: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let low = CoarseConversionValue(rawValue: "low")
        public static let medium = CoarseConversionValue(rawValue: "medium")
        public static let high = CoarseConversionValue(rawValue: "high")
    }

    public override init() { super.init() }

    public class func registerAppForAdNetworkAttribution() {}

    public class func updateConversionValue(_ conversionValue: Int) {
        _ = conversionValue
    }

    public class func updatePostbackConversionValue(
        _ conversionValue: Int,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        completionHandler?(StoreKitPortableError(.serviceUnavailable))
    }

    public class func updatePostbackConversionValue(
        _ fineValue: Int,
        coarseValue: CoarseConversionValue,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        _ = fineValue
        _ = coarseValue
        completionHandler?(StoreKitPortableError(.serviceUnavailable))
    }

    public class func updatePostbackConversionValue(_ conversionValue: Int) async throws {
        _ = conversionValue
        throw StoreKitPortableError(.serviceUnavailable)
    }

    public class func updatePostbackConversionValue(
        _ fineValue: Int,
        coarseValue: CoarseConversionValue
    ) async throws {
        _ = fineValue
        _ = coarseValue
        throw StoreKitPortableError(.serviceUnavailable)
    }

    public class func updatePostbackConversionValue(
        _ fineValue: Int,
        coarseValue: CoarseConversionValue,
        lockWindow: Bool
    ) async throws {
        _ = fineValue
        _ = coarseValue
        _ = lockWindow
        throw StoreKitPortableError(.serviceUnavailable)
    }

    public class func startImpression(_ impression: SKAdImpression) async throws {
        _ = impression
        throw StoreKitPortableError(.serviceUnavailable)
    }

    public class func endImpression(_ impression: SKAdImpression) async throws {
        _ = impression
        throw StoreKitPortableError(.serviceUnavailable)
    }
}

open class SKAdImpression: NSObject {
    public var sourceAppStoreItemIdentifier: NSNumber
    public var advertisedAppStoreItemIdentifier: NSNumber
    public var adNetworkIdentifier: String
    public var adCampaignIdentifier: NSNumber
    public var adImpressionIdentifier: String
    public var adDescription: String?
    public var adPurchaserName: String?
    public var timestamp: NSNumber
    public var signature: String
    public var version: String
    public var sourceIdentifier: NSNumber?

    public override init() {
        sourceAppStoreItemIdentifier = 0
        advertisedAppStoreItemIdentifier = 0
        adNetworkIdentifier = ""
        adCampaignIdentifier = 0
        adImpressionIdentifier = ""
        timestamp = 0
        signature = ""
        version = ""
        super.init()
    }

    public init(
        sourceAppStoreItemIdentifier: NSNumber,
        advertisedAppStoreItemIdentifier: NSNumber,
        adNetworkIdentifier: String,
        adCampaignIdentifier: NSNumber,
        adImpressionIdentifier: String,
        timestamp: NSNumber,
        signature: String,
        version: String
    ) {
        self.sourceAppStoreItemIdentifier = sourceAppStoreItemIdentifier
        self.advertisedAppStoreItemIdentifier = advertisedAppStoreItemIdentifier
        self.adNetworkIdentifier = adNetworkIdentifier
        self.adCampaignIdentifier = adCampaignIdentifier
        self.adImpressionIdentifier = adImpressionIdentifier
        self.timestamp = timestamp
        self.signature = signature
        self.version = version
    }
}
