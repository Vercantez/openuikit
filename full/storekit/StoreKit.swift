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
/// The portable store remains deliberately fail-closed when no App Store
/// service is connected, but applications must still be able to distinguish
/// user cancellation and transport/system failures using Apple's public error
/// surface.
public enum StoreKitError: Error, Sendable {
    case unknown
    case userCancelled
    case networkError(URLError)
    case systemError(any Error)
    case notAvailableInStorefront
    case notEntitled
    case unsupported
}

@MainActor
open class SKStoreReviewController: NSObject {
    public private(set) static var portableRequestCount = 0
    public static let portableError = StoreKitPortableError(.serviceUnavailable)

    public override init() { super.init() }

    public class func requestReview() {
        portableRequestCount += 1
    }

    @MainActor
    public class func requestReview(in windowScene: UIWindowScene) {
        _ = windowScene
        portableRequestCount += 1
    }
}

@MainActor
public enum AppStore {
    public private(set) static var portableReviewRequestCount = 0

    public static func requestReview(in scene: UIWindowScene) {
        portableReviewRequestCount += 1
    }

    public static func sync() async throws {
        throw StoreKitPortableError(.serviceUnavailable)
    }

    public static func showManageSubscriptions(in scene: UIWindowScene) async throws {
        throw StoreKitPortableError(.serviceUnavailable)
    }

    public static func showManageSubscriptions(
        in scene: UIWindowScene,
        subscriptionGroupID: String
    ) async throws {
        throw StoreKitPortableError(.serviceUnavailable)
    }
}

public struct SKError: Error, Hashable, @unchecked Sendable, CustomStringConvertible {
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

    public init(productIdentifiers: Set<String>) {
        self.productIdentifiers = productIdentifiers
        super.init()
    }

    public override func start() {
        super.start()
    }
}

public final class SKProduct {
    public let productIdentifier: String
    public let localizedTitle: String
    public let localizedDescription: String
    public let price: Decimal

    public init(
        productIdentifier: String,
        localizedTitle: String = "",
        localizedDescription: String = "",
        price: Decimal = 0
    ) {
        self.productIdentifier = productIdentifier
        self.localizedTitle = localizedTitle
        self.localizedDescription = localizedDescription
        self.price = price
    }
}

public enum SKPaymentTransactionState: Int, Sendable {
    case purchasing = 0
    case purchased = 1
    case failed = 2
    case restored = 3
    case deferred = 4
}

open class SKPayment {
    public let productIdentifier: String
    open var quantity: Int { 1 }

    public init(product: SKProduct) {
        productIdentifier = product.productIdentifier
    }
}

public final class SKMutablePayment: SKPayment {
    private var storedQuantity = 1
    public override var quantity: Int {
        get { storedQuantity }
        set { storedQuantity = max(1, newValue) }
    }
}

public final class SKPaymentTransaction {
    public let payment: SKPayment
    public let transactionState: SKPaymentTransactionState
    public let error: Error?
    public let transactionIdentifier: String?

    public init(
        payment: SKPayment,
        transactionState: SKPaymentTransactionState,
        error: Error?,
        transactionIdentifier: String? = nil
    ) {
        self.payment = payment
        self.transactionState = transactionState
        self.error = error
        self.transactionIdentifier = transactionIdentifier
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
}

public extension SKPaymentTransactionObserver {
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {}
    func paymentQueue(
        _ queue: SKPaymentQueue,
        restoreCompletedTransactionsFailedWithError error: Error
    ) {}
}

public final class SKPaymentQueue {
    private static let shared = SKPaymentQueue()
    private var observers: [SKPaymentTransactionObserver] = []

    private init() {}
    public static func `default`() -> SKPaymentQueue { shared }
    public static func canMakePayments() -> Bool { false }

    public func add(_ observer: SKPaymentTransactionObserver) {
        if !observers.contains(where: { $0 === observer }) {
            observers.append(observer)
        }
    }

    public func remove(_ observer: SKPaymentTransactionObserver) {
        observers.removeAll { $0 === observer }
    }

    public func add(_ payment: SKPayment) {
        let failure = SKPaymentTransaction(
            payment: payment,
            transactionState: .failed,
            error: StoreKitPortableError(.paymentsUnavailable)
        )
        for observer in observers {
            observer.paymentQueue(self, updatedTransactions: [failure])
        }
    }

    public func finishTransaction(_ transaction: SKPaymentTransaction) {}

    public func restoreCompletedTransactions() {
        let error = StoreKitPortableError(.paymentsUnavailable)
        for observer in observers {
            observer.paymentQueue(
                self,
                restoreCompletedTransactionsFailedWithError: error
            )
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

@frozen
public enum VerificationResult<SignedType> {
    public enum VerificationError: Error, Hashable, Sendable {
        case invalidCertificateChain
        case invalidEncoding
        case invalidSignature
        case missingRequiredProperties
        case revokedCertificate
    }

    case verified(SignedType)
    case unverified(SignedType, VerificationError)

    public var unsafePayloadValue: SignedType {
        switch self {
        case .verified(let value), .unverified(let value, _):
            return value
        }
    }

    public var payloadValue: SignedType {
        get throws {
            switch self {
            case .verified(let value):
                return value
            case .unverified(_, let error):
                throw error
            }
        }
    }
}

public struct Product: Identifiable, Hashable, Sendable {
    public struct SubscriptionPeriod: Hashable, Sendable, CustomDebugStringConvertible {
        public enum Unit: Int, Sendable, Hashable, Comparable, CustomDebugStringConvertible {
            case day, week, month, year
            public static func < (lhs: Unit, rhs: Unit) -> Bool { lhs.rawValue < rhs.rawValue }
            public var debugDescription: String { String(describing: self) }
            public var localizedDescription: String { debugDescription }
        }

        public let value: Int
        public let unit: Unit
        public init(value: Int, unit: Unit) { self.value = value; self.unit = unit }
        public var debugDescription: String { "\(value) \(unit)" }
        public static var weekly: SubscriptionPeriod { SubscriptionPeriod(value: 1, unit: .week) }
        public static var monthly: SubscriptionPeriod { SubscriptionPeriod(value: 1, unit: .month) }
        public static var yearly: SubscriptionPeriod { SubscriptionPeriod(value: 1, unit: .year) }
        public static var everyTwoWeeks: SubscriptionPeriod { SubscriptionPeriod(value: 2, unit: .week) }
        public static var everyTwoMonths: SubscriptionPeriod { SubscriptionPeriod(value: 2, unit: .month) }
        public static var everyThreeDays: SubscriptionPeriod { SubscriptionPeriod(value: 3, unit: .day) }
        public static var everyThreeMonths: SubscriptionPeriod { SubscriptionPeriod(value: 3, unit: .month) }
        public static var everySixMonths: SubscriptionPeriod { SubscriptionPeriod(value: 6, unit: .month) }
    }

    public struct SubscriptionOffer: Hashable, Sendable, Identifiable {
        public struct Signature: Hashable, Sendable {
            public var keyID: String
            public var nonce: UUID
            public var timestamp: Int
            public var signature: Data
            public init(keyID: String, nonce: UUID, timestamp: Int, signature: Data) {
                self.keyID = keyID
                self.nonce = nonce
                self.timestamp = timestamp
                self.signature = signature
            }
        }

        public let id: String
        public init(id: String) { self.id = id }
    }

    public struct PurchaseOption: Hashable, Sendable, CustomDebugStringConvertible {
        private enum Storage: Hashable, Sendable {
            case quantity(Int)
            case appAccountToken(UUID)
            case other(String)
        }

        private var storage: Storage
        public var debugDescription: String { String(describing: storage) }

        public static func quantity(_ quantity: Int) -> PurchaseOption {
            PurchaseOption(storage: .quantity(quantity))
        }

        public static func appAccountToken(_ token: UUID) -> PurchaseOption {
            PurchaseOption(storage: .appAccountToken(token))
        }

        public static func simulatesAskToBuyInSandbox(_ simulateAskToBuy: Bool) -> PurchaseOption {
            PurchaseOption(storage: .other("simulatesAskToBuyInSandbox:\(simulateAskToBuy)"))
        }

        public static func winBackOffer(_ offer: Product.SubscriptionOffer) -> PurchaseOption {
            PurchaseOption(storage: .other("winBack:\(offer.id)"))
        }

        public static func promotionalOffer(
            offerID: String,
            keyID: String,
            nonce: UUID,
            signature: Data,
            timestamp: Int
        ) -> PurchaseOption {
            _ = keyID
            _ = nonce
            _ = signature
            _ = timestamp
            return PurchaseOption(storage: .other("promo:\(offerID)"))
        }

        public static func promotionalOffer(
            offerID: String,
            signature: Product.SubscriptionOffer.Signature
        ) -> PurchaseOption {
            _ = signature
            return PurchaseOption(storage: .other("promo:\(offerID)"))
        }

        public static func promotionalOffer(
            _ offer: Product.SubscriptionOffer,
            compactJWS: String
        ) -> PurchaseOption {
            _ = compactJWS
            return PurchaseOption(storage: .other("promo:\(offer.id)"))
        }

        public static func onStorefrontChange(
            shouldContinuePurchase: @escaping (Storefront) -> Bool
        ) -> PurchaseOption {
            _ = shouldContinuePurchase
            return PurchaseOption(storage: .other("onStorefrontChange"))
        }

        public static func introductoryOfferEligibility(compactJWS: String) -> PurchaseOption {
            PurchaseOption(storage: .other("intro:\(compactJWS)"))
        }

        public static func custom(key: String, value: Data) -> PurchaseOption {
            PurchaseOption(storage: .other("custom:\(key):data"))
        }

        public static func custom(key: String, value: String) -> PurchaseOption {
            PurchaseOption(storage: .other("custom:\(key):\(value)"))
        }

        public static func custom(key: String, value: Bool) -> PurchaseOption {
            PurchaseOption(storage: .other("custom:\(key):\(value)"))
        }

        public static func custom(key: String, value: Double) -> PurchaseOption {
            PurchaseOption(storage: .other("custom:\(key):\(value)"))
        }
    }

    public enum PurchaseResult {
        case success(VerificationResult<Transaction>)
        case userCancelled
        case pending
    }

    public struct SubscriptionInfo: Hashable, Sendable {
        public let subscriptionGroupID: String
        public init(subscriptionGroupID: String) {
            self.subscriptionGroupID = subscriptionGroupID
        }
    }

    public typealias ID = String
    public struct ProductType: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let consumable = ProductType(rawValue: "Consumable")
        public static let nonConsumable = ProductType(rawValue: "NonConsumable")
        public static let nonRenewable = ProductType(rawValue: "NonRenewable")
        public static let autoRenewable = ProductType(rawValue: "AutoRenewable")
    }

    public let id: String
    public let displayName: String
    public let description: String
    public let price: Decimal
    public let displayPrice: String
    public let subscription: SubscriptionInfo?
    public let isFamilyShareable: Bool
    public let type: ProductType
    public var jsonRepresentation: Data { Data() }

    public init(
        id: String,
        displayName: String = "",
        description: String = "",
        price: Decimal = 0,
        displayPrice: String? = nil,
        subscription: SubscriptionInfo? = nil,
        isFamilyShareable: Bool = false,
        type: ProductType = .consumable
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.price = price
        // Real StoreKit products carry a storefront-localized string. The
        // portable initializer accepts that authoritative value; a manually
        // constructed test product falls back to the locale-independent
        // Decimal spelling rather than inventing a currency.
        self.displayPrice = displayPrice ?? price.description
        self.subscription = subscription
        self.isFamilyShareable = isFamilyShareable
        self.type = type
    }

    public static func products<Identifiers>(
        for identifiers: Identifiers
    ) async throws -> [Product] where Identifiers: Collection, Identifiers.Element == String {
        _ = identifiers
        throw StoreKitPortableError(.productUnavailable)
    }

    public func purchase(
        options: Set<PurchaseOption> = []
    ) async throws -> PurchaseResult {
        throw StoreKitPortableError(.paymentsUnavailable)
    }

    #if canImport(AppKit)
    @available(macOS 15.2, *)
    public func purchase(
        confirmIn window: NSWindow,
        options: Set<PurchaseOption> = []
    ) async throws -> PurchaseResult {
        _ = window
        _ = options
        throw StoreKitPortableError(.paymentsUnavailable)
    }
    #endif
}

public struct Transaction: Identifiable, Hashable, Sendable {
    public let id: UInt64
    public let productID: String
    public let purchaseDate: Date
    public let expirationDate: Date?
    public let revocationDate: Date?

    public init(
        id: UInt64,
        productID: String,
        purchaseDate: Date,
        expirationDate: Date? = nil,
        revocationDate: Date? = nil
    ) {
        self.id = id
        self.productID = productID
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
    }

    public static func latest(
        for productID: String
    ) async -> VerificationResult<Transaction>? { nil }

    public static func currentEntitlement(
        for productID: String
    ) async -> VerificationResult<Transaction>? { nil }

    public static var updates: AsyncStream<VerificationResult<Transaction>> {
        AsyncStream { $0.finish() }
    }

    public static var currentEntitlements: AsyncStream<VerificationResult<Transaction>> {
        AsyncStream { $0.finish() }
    }

    public func finish() async {}
}

public struct Storefront: Hashable, Sendable, Identifiable {
    public typealias ID = String
    public let id: String
    public let countryCode: String
    public init(id: String, countryCode: String) {
        self.id = id
        self.countryCode = countryCode
    }
    public static var current: Storefront? { get async { nil } }
}
