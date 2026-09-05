import Foundation

@frozen
public enum VerificationResult<SignedType>: Sendable where SignedType: Sendable {
    public enum VerificationError: Error, Hashable, Sendable, LocalizedError {
        case invalidCertificateChain
        case invalidEncoding
        case invalidSignature
        case missingRequiredProperties
        case revokedCertificate
        case invalidDeviceVerification

        public var errorDescription: String? { String(describing: self) }
        public var failureReason: String? { errorDescription }
        public var recoverySuggestion: String? { nil }
        public var helpAnchor: String? { nil }
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

extension VerificationResult: Equatable where SignedType: Equatable {}
extension VerificationResult: Hashable where SignedType: Hashable {}
extension VerificationResult: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .verified:
            return "verified"
        case .unverified(_, let error):
            return "unverified(\(error))"
        }
    }
}

extension VerificationResult where SignedType == Transaction {
    public var jwsRepresentation: String { unsafePayloadValue.jwsRepresentation }
    public var headerData: Data { unsafePayloadValue.jwsHeaderData }
    public var payloadData: Data { unsafePayloadValue.jwsPayloadData }
    public var signatureData: Data { unsafePayloadValue.jwsSignatureData }
    public var signedData: Data { headerData + payloadData }
    public var signedDate: Date { unsafePayloadValue.signedDate }
    public var deviceVerification: Data { unsafePayloadValue.deviceVerification }
    public var deviceVerificationNonce: UUID { unsafePayloadValue.deviceVerificationNonce }
}

extension VerificationResult where SignedType == AppTransaction {
    public var jwsRepresentation: String { "" }
    public var headerData: Data { Data() }
    public var payloadData: Data { Data() }
    public var signatureData: Data { Data() }
    public var signedData: Data { Data() }
    public var signedDate: Date { unsafePayloadValue.signedDate }
    public var deviceVerification: Data { unsafePayloadValue.deviceVerification }
    public var deviceVerificationNonce: UUID { unsafePayloadValue.deviceVerificationNonce }
}

extension VerificationResult where SignedType == Product.SubscriptionInfo.RenewalInfo {
    public var jwsRepresentation: String { "" }
    public var headerData: Data { Data() }
    public var payloadData: Data { Data() }
    public var signatureData: Data { Data() }
    public var signedData: Data { Data() }
    public var signedDate: Date { unsafePayloadValue.signedDate }
    public var deviceVerification: Data { unsafePayloadValue.deviceVerification }
    public var deviceVerificationNonce: UUID { unsafePayloadValue.deviceVerificationNonce }
}

public struct Transaction: Identifiable, Hashable, Sendable, CustomDebugStringConvertible {
    public typealias ID = UInt64

    public struct Transactions: AsyncSequence, Sendable {
        public typealias Element = VerificationResult<Transaction>
        public enum Kind: Sendable {
            case snapshot([VerificationResult<Transaction>])
            case updates
        }

        let kind: Kind

        public init(snapshot: [VerificationResult<Transaction>]) {
            kind = .snapshot(snapshot)
        }

        public static var liveUpdates: Transactions {
            Transactions(kind: .updates)
        }

        private init(kind: Kind) { self.kind = kind }

        public struct AsyncIterator: AsyncIteratorProtocol {
            var snapshot: [VerificationResult<Transaction>]
            var index = 0
            var listenerID: UUID?
            var live = false

            public mutating func next() async -> Element? {
                if live {
                    guard let listenerID else { return nil }
                    return await LocalTestingStore.shared.nextUpdate(id: listenerID)
                }
                guard index < snapshot.count else { return nil }
                let value = snapshot[index]
                index += 1
                return value
            }
        }

        public func makeAsyncIterator() -> AsyncIterator {
            switch kind {
            case .snapshot(let values):
                return AsyncIterator(snapshot: values, live: false)
            case .updates:
                let identifier = LocalTestingStore.shared.registerUpdateListener()
                return AsyncIterator(snapshot: [], listenerID: identifier, live: true)
            }
        }
    }

    public struct OwnershipType: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let purchased = OwnershipType(rawValue: "purchased")
        public static let familyShared = OwnershipType(rawValue: "familyShared")
        public var localizedDescription: String { rawValue }
    }

    public struct RevocationReason: Hashable, Sendable, RawRepresentable {
        public var rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let developerIssue = RevocationReason(rawValue: 1)
        public static let other = RevocationReason(rawValue: 0)
        public var localizedDescription: String { String(rawValue) }
    }

    public struct Reason: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let purchase = Reason(rawValue: "purchase")
        public static let renewal = Reason(rawValue: "renewal")
    }

    public struct OfferType: Hashable, Sendable, RawRepresentable {
        public var rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let introductory = OfferType(rawValue: 1)
        public static let promotional = OfferType(rawValue: 2)
        public static let code = OfferType(rawValue: 3)
        public static let winBack = OfferType(rawValue: 4)
        public var localizedDescription: String { String(rawValue) }
    }

    public struct Offer: Hashable, Sendable {
        public struct PaymentMode: Hashable, Sendable, RawRepresentable {
            public var rawValue: String
            public init(rawValue: String) { self.rawValue = rawValue }
            public static let payAsYouGo = PaymentMode(rawValue: "payAsYouGo")
            public static let payUpFront = PaymentMode(rawValue: "payUpFront")
            public static let freeTrial = PaymentMode(rawValue: "freeTrial")
            public static let oneTime = PaymentMode(rawValue: "oneTime")
        }

        public let id: String?
        public let type: OfferType
        public let paymentMode: PaymentMode?
        public let period: Product.SubscriptionPeriod?

        public init(
            id: String?,
            type: OfferType,
            paymentMode: PaymentMode? = nil,
            period: Product.SubscriptionPeriod? = nil
        ) {
            self.id = id
            self.type = type
            self.paymentMode = paymentMode
            self.period = period
        }
    }

    public enum RefundRequestStatus: Hashable, Sendable {
        case success
        case userCancelled
    }

    public enum RefundRequestError: Error, Hashable, LocalizedError {
        case duplicateRequest
        case failed
        public var errorDescription: String? { String(describing: self) }
        public var failureReason: String? { errorDescription }
        public var recoverySuggestion: String? { nil }
        public var helpAnchor: String? { nil }
    }

    public struct AdvancedCommerceInfo: Hashable, Sendable {
        public struct Offer: Hashable, Sendable {
            public struct Reason: Hashable, Sendable, RawRepresentable {
                public var rawValue: String
                public init(rawValue: String) { self.rawValue = rawValue }
                public static let acquisition = Reason(rawValue: "acquisition")
                public static let winBack = Reason(rawValue: "winBack")
                public static let retention = Reason(rawValue: "retention")
            }

            public let periodCount: Int
            public let price: Decimal
            public let period: SubscriptionPeriod
            public let reason: Reason
            public init(
                periodCount: Int,
                price: Decimal,
                period: SubscriptionPeriod,
                reason: Reason
            ) {
                self.periodCount = periodCount
                self.price = price
                self.period = period
                self.reason = reason
            }
        }

        public struct Refund: Hashable, Sendable {
            public struct RefundType: Hashable, Sendable, RawRepresentable {
                public var rawValue: String
                public init(rawValue: String) { self.rawValue = rawValue }
                public static let full = RefundType(rawValue: "full")
                public static let custom = RefundType(rawValue: "custom")
                public static let proRated = RefundType(rawValue: "proRated")
            }

            public struct Reason: Hashable, Sendable, RawRepresentable {
                public var rawValue: String
                public init(rawValue: String) { self.rawValue = rawValue }
                public static let unintended = Reason(rawValue: "unintended")
                public static let modifyItems = Reason(rawValue: "modifyItems")
                public static let unfulfilled = Reason(rawValue: "unfulfilled")
                public static let unsatisfied = Reason(rawValue: "unsatisfied")
                public static let legal = Reason(rawValue: "legal")
                public static let other = Reason(rawValue: "other")
            }

            public let date: Date
            public let type: RefundType
            public let amount: Decimal
            public let reason: Reason
            public init(date: Date, type: RefundType, amount: Decimal, reason: Reason) {
                self.date = date
                self.type = type
                self.amount = amount
                self.reason = reason
            }
        }

        public struct Item: Hashable, Sendable {
            public struct Details: Hashable, Sendable {
                public let sku: String
                public let description: String
                public let displayName: String
                public let price: Decimal
                public let offer: AdvancedCommerceInfo.Offer?
                public init(
                    sku: String,
                    description: String,
                    displayName: String,
                    price: Decimal,
                    offer: AdvancedCommerceInfo.Offer? = nil
                ) {
                    self.sku = sku
                    self.description = description
                    self.displayName = displayName
                    self.price = price
                    self.offer = offer
                }
            }

            public let details: Details
            public let revocationDate: Date?
            public let refunds: [Refund]?
            public init(details: Details, revocationDate: Date? = nil, refunds: [Refund]? = nil) {
                self.details = details
                self.revocationDate = revocationDate
                self.refunds = refunds
            }
        }

        public let description: String?
        public let displayName: String?
        public let estimatedTax: Decimal
        public let taxExclusivePrice: Decimal
        public let requestReferenceID: String
        public let items: [Item]
        public let period: SubscriptionPeriod?
        public let taxCode: String
        public let taxRate: Decimal
        public init(
            description: String?,
            displayName: String?,
            estimatedTax: Decimal,
            taxExclusivePrice: Decimal,
            requestReferenceID: String,
            items: [Item],
            period: SubscriptionPeriod?,
            taxCode: String,
            taxRate: Decimal
        ) {
            self.description = description
            self.displayName = displayName
            self.estimatedTax = estimatedTax
            self.taxExclusivePrice = taxExclusivePrice
            self.requestReferenceID = requestReferenceID
            self.items = items
            self.period = period
            self.taxCode = taxCode
            self.taxRate = taxRate
        }
    }

    public let id: UInt64
    public let productID: String
    public let purchaseDate: Date
    public let expirationDate: Date?
    public let revocationDate: Date?
    public let originalID: UInt64
    public let originalPurchaseDate: Date
    public let webOrderLineItemID: String?
    public let subscriptionGroupID: String?
    public let productType: Product.ProductType
    public let appBundleID: String
    public let appAccountToken: UUID?
    public let purchasedQuantity: Int
    public let storefront: Storefront
    public let reason: Reason
    public let ownershipType: OwnershipType
    public let environment: AppStore.Environment
    public let signedDate: Date
    public let deviceVerification: Data
    public let deviceVerificationNonce: UUID
    public let jsonRepresentation: Data
    let jwsHeaderData: Data
    let jwsPayloadData: Data
    let jwsSignatureData: Data
    let jwsRepresentation: String
    public let price: Decimal?
    public let currencyCode: String?
    public let offer: Offer?
    public let revocationReason: RevocationReason?
    public let isUpgraded: Bool
    public let advancedCommerceInfo: AdvancedCommerceInfo?
    public var appTransactionID: String { String(originalID) }
    public var storefrontCountryCode: String { storefront.countryCode }
    public var reasonStringRepresentation: String { reason.rawValue }
    public var environmentStringRepresentation: String { environment.rawValue }
    public var offerPeriodStringRepresentation: String? {
        guard let period = offer?.period else { return nil }
        return period.debugDescription
    }
    public var offerPaymentModeStringRepresentation: String? { offer?.paymentMode?.rawValue }
    public var offerID: String? { offer?.id }
    public var offerType: OfferType? { offer?.type }
    public var currency: Locale.Currency? {
        guard let currencyCode else { return nil }
        return Locale.Currency(currencyCode)
    }
    public var debugDescription: String { "Transaction(\(id) \(productID))" }
    public var jws: StoreKitJWS? {
        try? StoreKitJWSCodec.parse(jwsRepresentation)
    }
    public var subscriptionStatus: Product.SubscriptionInfo.Status? {
        get async {
            guard let group = subscriptionGroupID else { return nil }
            return try? await Product.SubscriptionInfo.status(for: group).first
        }
    }

    func revoked(at date: Date, reason: RevocationReason) -> Transaction {
        Transaction(
            id: id,
            productID: productID,
            purchaseDate: purchaseDate,
            expirationDate: expirationDate,
            revocationDate: date,
            originalID: originalID,
            originalPurchaseDate: originalPurchaseDate,
            webOrderLineItemID: webOrderLineItemID,
            subscriptionGroupID: subscriptionGroupID,
            productType: productType,
            appBundleID: appBundleID,
            appAccountToken: appAccountToken,
            purchasedQuantity: purchasedQuantity,
            storefront: storefront,
            reason: reason == .developerIssue ? .purchase : self.reason,
            ownershipType: ownershipType,
            environment: environment,
            signedDate: signedDate,
            deviceVerification: deviceVerification,
            deviceVerificationNonce: deviceVerificationNonce,
            jsonRepresentation: jsonRepresentation,
            jwsHeaderData: jwsHeaderData,
            jwsPayloadData: jwsPayloadData,
            jwsSignatureData: jwsSignatureData,
            jwsRepresentation: jwsRepresentation,
            price: price,
            currencyCode: currencyCode,
            offer: offer,
            revocationReason: reason,
            isUpgraded: isUpgraded,
            advancedCommerceInfo: advancedCommerceInfo
        )
    }

    func expired(at date: Date) -> Transaction {
        Transaction(
            id: id,
            productID: productID,
            purchaseDate: purchaseDate,
            expirationDate: date,
            revocationDate: revocationDate,
            originalID: originalID,
            originalPurchaseDate: originalPurchaseDate,
            webOrderLineItemID: webOrderLineItemID,
            subscriptionGroupID: subscriptionGroupID,
            productType: productType,
            appBundleID: appBundleID,
            appAccountToken: appAccountToken,
            purchasedQuantity: purchasedQuantity,
            storefront: storefront,
            reason: reason,
            ownershipType: ownershipType,
            environment: environment,
            signedDate: signedDate,
            deviceVerification: deviceVerification,
            deviceVerificationNonce: deviceVerificationNonce,
            jsonRepresentation: jsonRepresentation,
            jwsHeaderData: jwsHeaderData,
            jwsPayloadData: jwsPayloadData,
            jwsSignatureData: jwsSignatureData,
            jwsRepresentation: jwsRepresentation,
            price: price,
            currencyCode: currencyCode,
            offer: offer,
            revocationReason: revocationReason,
            isUpgraded: isUpgraded,
            advancedCommerceInfo: advancedCommerceInfo
        )
    }

    public init(
        id: UInt64,
        productID: String,
        purchaseDate: Date,
        expirationDate: Date? = nil,
        revocationDate: Date? = nil
    ) {
        self.init(
            id: id,
            productID: productID,
            purchaseDate: purchaseDate,
            expirationDate: expirationDate,
            revocationDate: revocationDate,
            originalID: id,
            originalPurchaseDate: purchaseDate,
            webOrderLineItemID: nil,
            subscriptionGroupID: nil,
            productType: .consumable,
            appBundleID: "",
            appAccountToken: nil,
            purchasedQuantity: 1,
            storefront: Storefront(id: "USA", countryCode: "USA"),
            reason: .purchase,
            ownershipType: .purchased,
            environment: .xcode,
            signedDate: purchaseDate,
            deviceVerification: Data(),
            deviceVerificationNonce: UUID(),
            jsonRepresentation: Data(),
            jwsHeaderData: Data(),
            jwsPayloadData: Data(),
            jwsSignatureData: Data(),
            jwsRepresentation: "",
            price: nil,
            currencyCode: nil,
            offer: nil
        )
    }

    init(
        id: UInt64,
        productID: String,
        purchaseDate: Date,
        expirationDate: Date?,
        revocationDate: Date?,
        originalID: UInt64,
        originalPurchaseDate: Date,
        webOrderLineItemID: String?,
        subscriptionGroupID: String?,
        productType: Product.ProductType,
        appBundleID: String,
        appAccountToken: UUID?,
        purchasedQuantity: Int,
        storefront: Storefront,
        reason: Reason,
        ownershipType: OwnershipType,
        environment: AppStore.Environment,
        signedDate: Date,
        deviceVerification: Data,
        deviceVerificationNonce: UUID,
        jsonRepresentation: Data,
        jwsHeaderData: Data,
        jwsPayloadData: Data,
        jwsSignatureData: Data,
        jwsRepresentation: String,
        price: Decimal?,
        currencyCode: String?,
        offer: Offer?,
        revocationReason: RevocationReason? = nil,
        isUpgraded: Bool = false,
        advancedCommerceInfo: AdvancedCommerceInfo? = nil
    ) {
        self.id = id
        self.productID = productID
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
        self.originalID = originalID
        self.originalPurchaseDate = originalPurchaseDate
        self.webOrderLineItemID = webOrderLineItemID
        self.subscriptionGroupID = subscriptionGroupID
        self.productType = productType
        self.appBundleID = appBundleID
        self.appAccountToken = appAccountToken
        self.purchasedQuantity = purchasedQuantity
        self.storefront = storefront
        self.reason = reason
        self.ownershipType = ownershipType
        self.environment = environment
        self.signedDate = signedDate
        self.deviceVerification = deviceVerification
        self.deviceVerificationNonce = deviceVerificationNonce
        self.jsonRepresentation = jsonRepresentation
        self.jwsHeaderData = jwsHeaderData
        self.jwsPayloadData = jwsPayloadData
        self.jwsSignatureData = jwsSignatureData
        self.jwsRepresentation = jwsRepresentation
        self.price = price
        self.currencyCode = currencyCode
        self.offer = offer
        self.revocationReason = revocationReason
        self.isUpgraded = isUpgraded
        self.advancedCommerceInfo = advancedCommerceInfo
    }

    public static func latest(
        for productID: String
    ) async -> VerificationResult<Transaction>? {
        LocalTestingStore.shared.latest(for: productID)
    }

    public static func currentEntitlement(
        for productID: String
    ) async -> VerificationResult<Transaction>? {
        LocalTestingStore.shared.currentEntitlement(for: productID)
    }

    public static var updates: Transactions { .liveUpdates }
    public static var all: Transactions {
        Transactions(snapshot: LocalTestingStore.shared.snapshotAll())
    }
    public static func all(for productID: String) -> Transactions {
        Transactions(snapshot: LocalTestingStore.shared.snapshotAll(productID: productID))
    }
    public static var currentEntitlements: Transactions {
        Transactions(snapshot: LocalTestingStore.shared.snapshotEntitlements())
    }
    public static func currentEntitlements(for productID: String) -> Transactions {
        Transactions(snapshot: LocalTestingStore.shared.snapshotEntitlements(productID: productID))
    }
    public static var unfinished: Transactions {
        Transactions(snapshot: LocalTestingStore.shared.snapshotUnfinished())
    }

    public func finish() async {
        LocalTestingStore.shared.finish(id: id)
    }

    public func beginRefundRequest(in scene: UIWindowScene) async throws -> RefundRequestStatus {
        _ = scene
        throw StoreKitError.notAvailableInStorefront
    }

    public static func beginRefundRequest(
        for transactionID: UInt64,
        in scene: UIWindowScene
    ) async throws -> RefundRequestStatus {
        _ = transactionID
        _ = scene
        throw StoreKitError.notAvailableInStorefront
    }
}

public struct Storefront: Hashable, Sendable, Identifiable {
    public typealias ID = String
    public let id: String
    public let countryCode: String
    public init(id: String, countryCode: String) {
        self.id = id
        self.countryCode = countryCode
    }
    public var currency: Locale.Currency? {
        Locale.Currency(countryCode)
    }

    public struct Storefronts: AsyncSequence {
        public typealias Element = Storefront
        public struct AsyncIterator: AsyncIteratorProtocol {
            var emitted = false
            public mutating func next() async -> Storefront? {
                if emitted { return nil }
                emitted = true
                return await Storefront.current
            }
        }
        public func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
    }

    public static var current: Storefront? {
        get async { LocalTestingStore.shared.currentStorefront }
    }
    public static var updates: Storefronts { Storefronts() }
}
