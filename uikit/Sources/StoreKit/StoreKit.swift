// Fail-closed StoreKit for Linux / OpenUIKit apps.
//
// Types exist so the 14 ladder-corpus apps that `import StoreKit` compile.
// There is no App Store on this host: Product.products(for:) returns [],
// Transaction.updates is an empty stream, AppStore.sync() throws,
// SKPaymentQueue.canMakePayments() is false. Every stub is listed in
// docs/agent_reports/silent-frameworks.md.
//
// Call shapes grepped from scratch/ladder-corpus 2026-09-05
// (Hackers SupportPurchaseRepository, pocket-casts IAPHelper,
// Signal BackupSubscriptionManager, Telegram InAppPurchaseManager,
// simplenote StoreManager, nextcloud NCStoreReview).

import Foundation
import OpenUIKit

public enum StoreKitError: Error, Sendable {
    case unknown
    case userCancelled
    case networkError(URLError)
    case systemError(any Error)
    case notAvailableInStorefront
    case notEntitled
    case unsupported
}

public let SKErrorDomain = "SKErrorDomain"

public struct SKError: Error, Hashable {
    public enum Code: Int, Sendable {
        case unknown = 0
        case clientInvalid = 1
        case paymentCancelled = 2
        case paymentInvalid = 3
        case paymentNotAllowed = 4
        case storeProductNotAvailable = 5
    }

    public let code: Code
    public init(_ code: Code) { self.code = code }
}

open class SKStoreReviewController: NSObject {
    public override init() { super.init() }

    public class func requestReview() {}

    public class func requestReview(in windowScene: UIWindowScene) {
        _ = windowScene
    }
}

public enum AppStore {
    public static var canMakePayments: Bool { false }

    public static func requestReview(in scene: UIWindowScene) {
        _ = scene
    }

    public static func sync() async throws {
        throw StoreKitError.unknown
    }
}

open class SKRequest {
    public weak var delegate: SKRequestDelegate?
    public init() {}
    open func start() {}
    open func cancel() {}
}

public protocol SKRequestDelegate: AnyObject {
    func requestDidFinish(_ request: SKRequest)
    func request(_ request: SKRequest, didFailWithError error: Error)
}

public extension SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {}
    func request(_ request: SKRequest, didFailWithError error: Error) {}
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

public final class SKProductsResponse {
    public let products: [SKProduct]
    public let invalidProductIdentifiers: [String]
    public init(products: [SKProduct], invalidProductIdentifiers: [String]) {
        self.products = products
        self.invalidProductIdentifiers = invalidProductIdentifiers
    }
}

public protocol SKProductsRequestDelegate: SKRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse)
}

public final class SKProductsRequest: SKRequest {
    public let productIdentifiers: Set<String>
    public init(productIdentifiers: Set<String>) {
        self.productIdentifiers = productIdentifiers
        super.init()
    }

    public override func start() {
        let response = SKProductsResponse(
            products: [],
            invalidProductIdentifiers: Array(productIdentifiers)
        )
        (delegate as? SKProductsRequestDelegate)?.productsRequest(self, didReceive: response)
        delegate?.requestDidFinish(self)
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

    public init(productIdentifier: String) {
        self.productIdentifier = productIdentifier
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
    public static let `default` = SKPaymentQueue()
    private var observers: [ObjectIdentifier: SKPaymentTransactionObserver] = [:]

    public static func canMakePayments() -> Bool { false }

    public func add(_ observer: SKPaymentTransactionObserver) {
        observers[ObjectIdentifier(observer)] = observer
    }

    public func remove(_ observer: SKPaymentTransactionObserver) {
        observers.removeValue(forKey: ObjectIdentifier(observer))
    }

    public func add(_ payment: SKPayment) {
        let failure = SKPaymentTransaction(
            payment: payment,
            transactionState: .failed,
            error: SKError(.paymentNotAllowed)
        )
        for observer in observers.values {
            observer.paymentQueue(self, updatedTransactions: [failure])
        }
    }

    public func finishTransaction(_ transaction: SKPaymentTransaction) {
        _ = transaction
    }

    public func restoreCompletedTransactions() {
        let error = SKError(.unknown)
        for observer in observers.values {
            observer.paymentQueue(self, restoreCompletedTransactionsFailedWithError: error)
        }
    }
}

@frozen
public enum VerificationResult<SignedType> {
    case verified(SignedType)
    case unverified(SignedType, Error)

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
    public typealias ID = String
    public let id: String
    public let displayName: String
    public let description: String
    public let price: Decimal
    public let displayPrice: String

    public init(
        id: String,
        displayName: String = "",
        description: String = "",
        price: Decimal = 0,
        displayPrice: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.price = price
        self.displayPrice = displayPrice ?? price.description
    }

    public static func == (lhs: Product, rhs: Product) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

    public static func products<Identifiers>(
        for identifiers: Identifiers
    ) async throws -> [Product] where Identifiers: Collection, Identifiers.Element == String {
        _ = identifiers
        return []
    }

    public enum PurchaseResult: Sendable {
        case success(VerificationResult<Transaction>)
        case userCancelled
        case pending
    }

    public struct PurchaseOption: Hashable, Sendable {}

    public func purchase() async throws -> PurchaseResult {
        throw StoreKitError.unknown
    }

    public func purchase(options: Set<PurchaseOption>) async throws -> PurchaseResult {
        _ = options
        throw StoreKitError.unknown
    }

    public struct SubscriptionPeriod: Hashable, Sendable {
        public enum Unit: Hashable, Sendable {
            case day, week, month, year
        }
        public var value: Int
        public var unit: Unit
        public init(value: Int, unit: Unit) {
            self.value = value
            self.unit = unit
        }
    }
}

public struct Transaction: Identifiable, Hashable, Sendable {
    public let id: UInt64
    public let productID: String
    public let purchaseDate: Date

    public init(id: UInt64, productID: String, purchaseDate: Date) {
        self.id = id
        self.productID = productID
        self.purchaseDate = purchaseDate
    }

    public static func latest(for productID: String) async -> VerificationResult<Transaction>? {
        _ = productID
        return nil
    }

    public static func currentEntitlement(
        for productID: String
    ) async -> VerificationResult<Transaction>? {
        _ = productID
        return nil
    }

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
