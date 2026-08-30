import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(OpenUIKit)
import OpenUIKit
#else
#error("StoreKit requires UIKit or OpenUIKit")
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

@MainActor
public enum SKStoreReviewController {
    public private(set) static var portableRequestCount = 0
    public static let portableError = StoreKitPortableError(.serviceUnavailable)

    public static func requestReview() {
        portableRequestCount += 1
    }

    public static func requestReview(in windowScene: UIWindowScene) {
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

public struct SKError: Error, Equatable, Sendable, CustomStringConvertible {
    public enum Code: Int, Sendable {
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

    public let code: Code
    public let userInfo: [String: String]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo.mapValues { String(describing: $0) }
    }

    public var description: String { "StoreKit error \(code.rawValue)" }
}

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

public protocol SKRequestDelegate: AnyObject {
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

public protocol SKPaymentTransactionObserver: AnyObject {
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

public enum SKAdNetwork {
    public enum CoarseConversionValue: String, Sendable {
        case low, medium, high
    }

    public static func registerAppForAdNetworkAttribution() {}

    public static func updatePostbackConversionValue(
        _ conversionValue: Int,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        completionHandler?(StoreKitPortableError(.serviceUnavailable))
    }

    public static func updatePostbackConversionValue(
        _ fineValue: Int,
        coarseValue: CoarseConversionValue,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        completionHandler?(StoreKitPortableError(.serviceUnavailable))
    }
}

public enum VerificationResult<SignedType> {
    case verified(SignedType)
    case unverified(SignedType, Error)
}

public struct Product: Identifiable, Sendable {
    public struct SubscriptionPeriod: Hashable, Sendable {
        public enum Unit: Int, Sendable { case day, week, month, year }
        public let value: Int
        public let unit: Unit
        public init(value: Int, unit: Unit) { self.value = value; self.unit = unit }
    }

    public enum PurchaseOption: Hashable, Sendable {
        case quantity(Int)
        case appAccountToken(UUID)
    }

    public enum PurchaseResult {
        case success(VerificationResult<Transaction>)
        case userCancelled
        case pending
    }

    public struct SubscriptionInfo: Sendable {
        public let subscriptionGroupID: String
        public init(subscriptionGroupID: String) {
            self.subscriptionGroupID = subscriptionGroupID
        }
    }

    public let id: String
    public let displayName: String
    public let description: String
    public let price: Decimal
    public let subscription: SubscriptionInfo?

    public init(
        id: String,
        displayName: String = "",
        description: String = "",
        price: Decimal = 0,
        subscription: SubscriptionInfo? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.price = price
        self.subscription = subscription
    }

    public static func products(for identifiers: [String]) async throws -> [Product] {
        throw StoreKitPortableError(.productUnavailable)
    }

    public func purchase(
        options: Set<PurchaseOption> = []
    ) async throws -> PurchaseResult {
        throw StoreKitPortableError(.paymentsUnavailable)
    }
}

public struct Transaction: Identifiable, Sendable {
    public let id: UInt64
    public let productID: String
    public let purchaseDate: Date

    public init(id: UInt64, productID: String, purchaseDate: Date) {
        self.id = id
        self.productID = productID
        self.purchaseDate = purchaseDate
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

public struct Storefront: Sendable {
    public let id: String
    public let countryCode: String
    public init(id: String, countryCode: String) {
        self.id = id
        self.countryCode = countryCode
    }
    public static var current: Storefront? { get async { nil } }
}
