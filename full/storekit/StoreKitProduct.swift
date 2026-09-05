import Foundation

public struct Product: Identifiable, Hashable, Sendable, CustomDebugStringConvertible {
    public typealias ID = String

    public struct ProductType: Hashable, Sendable, RawRepresentable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let consumable = ProductType(rawValue: "Consumable")
        public static let nonConsumable = ProductType(rawValue: "NonConsumable")
        public static let nonRenewable = ProductType(rawValue: "NonRenewable")
        public static let autoRenewable = ProductType(rawValue: "AutoRenewable")
        public var localizedDescription: String { rawValue }

        static func fromStoreKitFile(_ raw: String?) -> ProductType? {
            guard let raw else { return nil }
            if raw == "Consumable" { return .consumable }
            if raw == "NonConsumable" { return .nonConsumable }
            if raw == "NonRenewingSubscription" { return .nonRenewable }
            if raw == "RecurringSubscription" { return .autoRenewable }
            return ProductType(rawValue: raw)
        }
    }

    public struct SubscriptionPeriod: Hashable, Sendable, CustomDebugStringConvertible {
        public enum Unit: Int, Sendable, Hashable, Comparable, CustomDebugStringConvertible {
            case day, week, month, year
            public static func < (lhs: Unit, rhs: Unit) -> Bool { lhs.rawValue < rhs.rawValue }
            public var debugDescription: String {
                switch self {
                case .day: return "day"
                case .week: return "week"
                case .month: return "month"
                case .year: return "year"
                }
            }
            public var localizedDescription: String { debugDescription }
            public func formatted<S>(_ format: S) -> S.FormatOutput
            where S: Foundation.FormatStyle, S.FormatInput == Product.SubscriptionPeriod.Unit {
                format.format(self)
            }

            public struct FormatStyle: Hashable, Sendable, Foundation.FormatStyle {
                public typealias FormatInput = Product.SubscriptionPeriod.Unit
                public typealias FormatOutput = String
                public init() {}
                public init(from decoder: any Decoder) throws { self.init() }
                public func encode(to encoder: any Encoder) throws {}
                public func format(_ value: Product.SubscriptionPeriod.Unit) -> String {
                    value.debugDescription
                }
                public func locale(_ locale: Locale) -> Product.SubscriptionPeriod.Unit.FormatStyle {
                    _ = locale
                    return self
                }
            }
        }

        public let value: Int
        public let unit: Unit
        public init(value: Int, unit: Unit) {
            self.value = value
            self.unit = unit
        }
        public var debugDescription: String { "\(value) \(unit)" }
        public static var weekly: SubscriptionPeriod { SubscriptionPeriod(value: 1, unit: .week) }
        public static var monthly: SubscriptionPeriod { SubscriptionPeriod(value: 1, unit: .month) }
        public static var yearly: SubscriptionPeriod { SubscriptionPeriod(value: 1, unit: .year) }
        public static var everyTwoWeeks: SubscriptionPeriod { SubscriptionPeriod(value: 2, unit: .week) }
        public static var everyTwoMonths: SubscriptionPeriod { SubscriptionPeriod(value: 2, unit: .month) }
        public static var everyThreeDays: SubscriptionPeriod { SubscriptionPeriod(value: 3, unit: .day) }
        public static var everyThreeMonths: SubscriptionPeriod { SubscriptionPeriod(value: 3, unit: .month) }
        public static var everySixMonths: SubscriptionPeriod { SubscriptionPeriod(value: 6, unit: .month) }

        public func dateRange(referenceDate: Date = Date()) -> Range<Date> {
            let end = endDate(from: referenceDate)
            if end >= referenceDate {
                return referenceDate..<end
            }
            return end..<referenceDate
        }

        public func formatted<S>(
            _ format: S,
            referenceDate: Date = Date()
        ) -> S.FormatOutput where S: Foundation.FormatStyle, S.FormatInput == Range<Date> {
            format.format(dateRange(referenceDate: referenceDate))
        }

        public func formatted<S>(
            _ format: S,
            referenceDate: Date = Date()
        ) -> S.FormatOutput where S: Foundation.FormatStyle, S.FormatInput == Duration {
            _ = referenceDate
            return format.format(duration)
        }

        var duration: Duration {
            switch unit {
            case .day: return .seconds(Int64(value) * 86_400)
            case .week: return .seconds(Int64(value) * 604_800)
            case .month: return .seconds(Int64(value) * 2_592_000)
            case .year: return .seconds(Int64(value) * 31_536_000)
            }
        }

        func endDate(from start: Date) -> Date {
            var components = DateComponents()
            switch unit {
            case .day: components.day = value
            case .week: components.weekOfYear = value
            case .month: components.month = value
            case .year: components.year = value
            }
            return Calendar(identifier: .gregorian).date(byAdding: components, to: start) ?? start
        }

        init?(iso8601Duration raw: String) {
            guard raw.first == "P" else { return nil }
            var number = 0
            var seenDigit = false
            var unit: Unit?
            for character in raw.dropFirst() {
                if let digit = character.wholeNumberValue {
                    seenDigit = true
                    number = number * 10 + digit
                    continue
                }
                if character == "D" { unit = .day }
                else if character == "W" { unit = .week }
                else if character == "M" { unit = .month }
                else if character == "Y" { unit = .year }
                else { return nil }
            }
            guard seenDigit, let unit else { return nil }
            self.init(value: number, unit: unit)
        }
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

        public struct PaymentMode: Hashable, Sendable, RawRepresentable {
            public var rawValue: String
            public init(rawValue: String) { self.rawValue = rawValue }
            public static let freeTrial = PaymentMode(rawValue: "freeTrial")
            public static let payAsYouGo = PaymentMode(rawValue: "payAsYouGo")
            public static let payUpFront = PaymentMode(rawValue: "payUpFront")
            public var localizedDescription: String { rawValue }
        }

        public struct OfferType: Hashable, Sendable, RawRepresentable {
            public var rawValue: String
            public init(rawValue: String) { self.rawValue = rawValue }
            public static let introductory = OfferType(rawValue: "introductory")
            public static let promotional = OfferType(rawValue: "promotional")
            public static let winBack = OfferType(rawValue: "winBack")
            public var localizedDescription: String { rawValue }
        }

        public let id: String?
        public let type: OfferType
        public let price: Decimal
        public let displayPrice: String
        public let period: SubscriptionPeriod
        public let periodCount: Int
        public let paymentMode: PaymentMode

        public init(id: String?) {
            self.id = id
            self.type = .introductory
            self.price = 0
            self.displayPrice = "0"
            self.period = .monthly
            self.periodCount = 1
            self.paymentMode = .freeTrial
        }

        public init(
            id: String?,
            type: OfferType,
            price: Decimal,
            displayPrice: String,
            period: SubscriptionPeriod,
            periodCount: Int,
            paymentMode: PaymentMode
        ) {
            self.id = id
            self.type = type
            self.price = price
            self.displayPrice = displayPrice
            self.period = period
            self.periodCount = periodCount
            self.paymentMode = paymentMode
        }
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
            PurchaseOption(storage: .other("winBack:\(offer.id ?? "")"))
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
            _ offerID: String,
            compactJWS: String
        ) -> [PurchaseOption] {
            _ = compactJWS
            return [PurchaseOption(storage: .other("promo:\(offerID)"))]
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

        var quantityValue: Int? {
            if case .quantity(let value) = storage { return value }
            return nil
        }

        var appAccountTokenValue: UUID? {
            if case .appAccountToken(let value) = storage { return value }
            return nil
        }
    }

    public enum PurchaseResult: Sendable, Equatable, Hashable {
        case success(VerificationResult<Transaction>)
        case userCancelled
        case pending
    }

    public enum PurchaseError: Error, Hashable, LocalizedError {
        case invalidQuantity
        case productUnavailable
        case purchaseNotAllowed
        case ineligibleForOffer
        case invalidOfferIdentifier
        case invalidOfferPrice
        case missingOfferParameters
        case invalidOfferSignature

        public var errorDescription: String? { String(describing: self) }
        public var failureReason: String? { errorDescription }
        public var recoverySuggestion: String? { nil }
        public var helpAnchor: String? { nil }
    }

    public struct SubscriptionInfo: Hashable, Sendable {
        public struct RenewalState: Hashable, Sendable, RawRepresentable {
            public var rawValue: Int
            public init(rawValue: Int) { self.rawValue = rawValue }
            public static let subscribed = RenewalState(rawValue: 1)
            public static let expired = RenewalState(rawValue: 2)
            public static let inBillingRetryPeriod = RenewalState(rawValue: 3)
            public static let inGracePeriod = RenewalState(rawValue: 4)
            public static let revoked = RenewalState(rawValue: 5)
            public var localizedDescription: String {
                switch self {
                case .subscribed: return "subscribed"
                case .expired: return "expired"
                case .inBillingRetryPeriod: return "inBillingRetryPeriod"
                case .inGracePeriod: return "inGracePeriod"
                case .revoked: return "revoked"
                default: return "raw:\(rawValue)"
                }
            }
        }

        public struct RenewalInfo: Hashable, Sendable, CustomDebugStringConvertible {
            public struct ExpirationReason: Hashable, Sendable, RawRepresentable {
                public var rawValue: Int
                public init(rawValue: Int) { self.rawValue = rawValue }
                public static let unknown = ExpirationReason(rawValue: 0)
                public static let autoRenewDisabled = ExpirationReason(rawValue: 1)
                public static let billingError = ExpirationReason(rawValue: 2)
                public static let didNotConsentToPriceIncrease = ExpirationReason(rawValue: 3)
                public static let productUnavailable = ExpirationReason(rawValue: 4)
                public var localizedDescription: String { String(rawValue) }
            }

            @frozen
            public enum PriceIncreaseStatus: Hashable, Sendable {
                case noIncreasePending
                case pending
                case agreed
                public var localizedDescription: String { String(describing: self) }
            }

            public struct AdvancedCommerceInfo: Hashable, Sendable {
                public struct Item: Hashable, Sendable {
                    public typealias Details = Transaction.AdvancedCommerceInfo.Item.Details
                    public let details: Details
                    public init(details: Details) { self.details = details }
                }

                public let description: String
                public let displayName: String
                public let consistencyToken: String
                public let requestReferenceID: String
                public let items: [Item]
                public let period: SubscriptionPeriod
                public let taxCode: String
                public init(
                    description: String,
                    displayName: String,
                    consistencyToken: String,
                    requestReferenceID: String,
                    items: [Item],
                    period: SubscriptionPeriod,
                    taxCode: String
                ) {
                    self.description = description
                    self.displayName = displayName
                    self.consistencyToken = consistencyToken
                    self.requestReferenceID = requestReferenceID
                    self.items = items
                    self.period = period
                    self.taxCode = taxCode
                }
            }

            public let willAutoRenew: Bool
            public let currentProductID: String
            public let originalTransactionID: UInt64
            public let expirationReason: ExpirationReason?
            public let isInBillingRetry: Bool
            public let autoRenewPreference: String?
            public let priceIncreaseStatus: PriceIncreaseStatus
            public let renewalDate: Date?
            public let gracePeriodExpirationDate: Date?
            public let recentSubscriptionStartDate: Date
            public let signedDate: Date
            public let environment: AppStore.Environment
            public let renewalPrice: Decimal?
            public let currencyCode: String?
            public let appAccountToken: UUID?
            public let appTransactionID: String
            public let eligibleWinBackOfferIDs: [String]
            public let offer: Transaction.Offer?
            public let advancedCommerceInfo: AdvancedCommerceInfo?
            public let deviceVerification: Data
            public let deviceVerificationNonce: UUID
            public var jsonRepresentation: Data { Data() }
            public var environmentStringRepresentation: String { environment.rawValue }
            public var offerPeriodStringRepresentation: String? { nil }
            public var offerPaymentModeStringRepresentation: String? { nil }
            public var offerID: String? { offer?.id }
            public var offerType: Transaction.OfferType? { offer?.type }
            public var currency: Locale.Currency? {
                guard let currencyCode else { return nil }
                return Locale.Currency(currencyCode)
            }
            public var debugDescription: String {
                "RenewalInfo(\(currentProductID) autoRenew=\(willAutoRenew))"
            }

            public init(
                willAutoRenew: Bool,
                currentProductID: String,
                originalTransactionID: UInt64,
                signedDate: Date = Date(),
                environment: AppStore.Environment = .xcode,
                expirationReason: ExpirationReason? = nil,
                isInBillingRetry: Bool = false,
                autoRenewPreference: String? = nil,
                priceIncreaseStatus: PriceIncreaseStatus = .noIncreasePending,
                renewalDate: Date? = nil,
                gracePeriodExpirationDate: Date? = nil,
                recentSubscriptionStartDate: Date = Date(timeIntervalSince1970: 0),
                renewalPrice: Decimal? = nil,
                currencyCode: String? = nil,
                appAccountToken: UUID? = nil,
                appTransactionID: String = "0",
                eligibleWinBackOfferIDs: [String] = [],
                offer: Transaction.Offer? = nil,
                advancedCommerceInfo: AdvancedCommerceInfo? = nil,
                deviceVerification: Data = Data(),
                deviceVerificationNonce: UUID = UUID()
            ) {
                self.willAutoRenew = willAutoRenew
                self.currentProductID = currentProductID
                self.originalTransactionID = originalTransactionID
                self.expirationReason = expirationReason
                self.isInBillingRetry = isInBillingRetry
                self.autoRenewPreference = autoRenewPreference
                self.priceIncreaseStatus = priceIncreaseStatus
                self.renewalDate = renewalDate
                self.gracePeriodExpirationDate = gracePeriodExpirationDate
                self.recentSubscriptionStartDate = recentSubscriptionStartDate
                self.signedDate = signedDate
                self.environment = environment
                self.renewalPrice = renewalPrice
                self.currencyCode = currencyCode
                self.appAccountToken = appAccountToken
                self.appTransactionID = appTransactionID
                self.eligibleWinBackOfferIDs = eligibleWinBackOfferIDs
                self.offer = offer
                self.advancedCommerceInfo = advancedCommerceInfo
                self.deviceVerification = deviceVerification
                self.deviceVerificationNonce = deviceVerificationNonce
            }
        }

        public struct Status: Hashable, Sendable {
            public let state: RenewalState
            public let transaction: VerificationResult<Transaction>
            public let renewalInfo: VerificationResult<RenewalInfo>

            public init(
                state: RenewalState,
                transaction: VerificationResult<Transaction>,
                renewalInfo: VerificationResult<RenewalInfo>
            ) {
                self.state = state
                self.transaction = transaction
                self.renewalInfo = renewalInfo
            }

            public struct Statuses: AsyncSequence {
                public typealias Element = Product.SubscriptionInfo.Status
                public struct AsyncIterator: AsyncIteratorProtocol {
                    public mutating func next() async -> Element? { nil }
                }
                public func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
            }

            public static var updates: Statuses { Statuses() }
            public static var all: AsyncStream<(groupID: String, statuses: [Product.SubscriptionInfo.Status])> {
                AsyncStream { $0.finish() }
            }
        }

        public let subscriptionGroupID: String
        public let subscriptionPeriod: SubscriptionPeriod
        public let groupDisplayName: String
        public let groupLevel: Int
        public let introductoryOffer: SubscriptionOffer?
        public let promotionalOffers: [SubscriptionOffer]
        public let winBackOffers: [SubscriptionOffer]

        public init(subscriptionGroupID: String) {
            self.subscriptionGroupID = subscriptionGroupID
            self.subscriptionPeriod = .monthly
            self.groupDisplayName = ""
            self.groupLevel = 1
            self.introductoryOffer = nil
            self.promotionalOffers = []
            self.winBackOffers = []
        }

        public init(
            subscriptionGroupID: String,
            subscriptionPeriod: SubscriptionPeriod,
            groupDisplayName: String,
            groupLevel: Int,
            introductoryOffer: SubscriptionOffer?,
            promotionalOffers: [SubscriptionOffer],
            winBackOffers: [SubscriptionOffer]
        ) {
            self.subscriptionGroupID = subscriptionGroupID
            self.subscriptionPeriod = subscriptionPeriod
            self.groupDisplayName = groupDisplayName
            self.groupLevel = groupLevel
            self.introductoryOffer = introductoryOffer
            self.promotionalOffers = promotionalOffers
            self.winBackOffers = winBackOffers
        }

        public var isEligibleForIntroOffer: Bool {
            get async { Self.isEligibleForIntroOfferNow(for: subscriptionGroupID) }
        }

        public static func isEligibleForIntroOffer(for groupID: String) async -> Bool {
            isEligibleForIntroOfferNow(for: groupID)
        }

        static func isEligibleForIntroOfferNow(for groupID: String) -> Bool {
            LocalTestingStore.shared.isEligibleForIntroOffer(groupID: groupID)
        }

        public var status: [Status] {
            get async throws {
                try await Self.status(for: subscriptionGroupID)
            }
        }

        public static func status(for groupID: String) async throws -> [Status] {
            try statusNow(for: groupID)
        }

        static func statusNow(for groupID: String) throws -> [Status] {
            guard LocalTestingStore.shared.isLoaded else {
                throw StoreKitError.notAvailableInStorefront
            }
            let all = LocalTestingStore.shared.snapshotAll()
            var latest: [String: VerificationResult<Transaction>] = [:]
            for wrapped in all {
                let transaction = wrapped.unsafePayloadValue
                if transaction.subscriptionGroupID == groupID {
                    latest[transaction.productID] = wrapped
                }
            }
            var result: [Status] = []
            for wrapped in latest.values {
                let transaction = wrapped.unsafePayloadValue
                let state: RenewalState
                if transaction.revocationDate != nil {
                    state = .revoked
                } else if let expiration = transaction.expirationDate, expiration < Date() {
                    state = .expired
                } else {
                    state = .subscribed
                }
                let info = RenewalInfo(
                    willAutoRenew: state == .subscribed,
                    currentProductID: transaction.productID,
                    originalTransactionID: transaction.originalID,
                    signedDate: transaction.signedDate,
                    environment: transaction.environment,
                    expirationReason: state == .expired ? .autoRenewDisabled : nil,
                    renewalDate: transaction.expirationDate
                )
                let renewal: VerificationResult<RenewalInfo>
                switch wrapped {
                case .verified:
                    renewal = .verified(info)
                case .unverified(_, let error):
                    let mapped: VerificationResult<RenewalInfo>.VerificationError
                    switch error {
                    case .invalidCertificateChain: mapped = .invalidCertificateChain
                    case .invalidEncoding: mapped = .invalidEncoding
                    case .invalidSignature: mapped = .invalidSignature
                    case .missingRequiredProperties: mapped = .missingRequiredProperties
                    case .revokedCertificate: mapped = .revokedCertificate
                    case .invalidDeviceVerification: mapped = .invalidDeviceVerification
                    }
                    renewal = .unverified(info, mapped)
                }
                result.append(Status(state: state, transaction: wrapped, renewalInfo: renewal))
            }
            return result
        }

        public static func status(transactionID: UInt64) async throws -> SubscriptionStatus? {
            let all = try await status(for: "")
            _ = all
            for wrapped in LocalTestingStore.shared.snapshotAll() {
                if wrapped.unsafePayloadValue.id == transactionID {
                    let group = wrapped.unsafePayloadValue.subscriptionGroupID ?? ""
                    let statuses = try await status(for: group)
                    return statuses.first {
                        $0.transaction.unsafePayloadValue.id == transactionID
                    }
                }
            }
            return nil
        }
    }

    public struct SubscriptionRelationship: OptionSet, Hashable, Sendable {
        public var rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let current = SubscriptionRelationship(rawValue: 1)
        public static let upgrade = SubscriptionRelationship(rawValue: 2)
        public static let downgrade = SubscriptionRelationship(rawValue: 4)
        public static let crossgrade = SubscriptionRelationship(rawValue: 8)
        public static let all: SubscriptionRelationship = [.current, .upgrade, .downgrade, .crossgrade]
    }

    public struct PromotionInfo: Hashable, Sendable {
        public enum Visibility: Int, Sendable, Hashable {
            case appStoreConnectDefault = 0
            case hidden = 1
            case visible = 2
        }

        public let productID: Product.ID
        public var visibility: Visibility

        public init(productID: Product.ID, visibility: Visibility = .appStoreConnectDefault) {
            self.productID = productID
            self.visibility = visibility
        }

        public func update() async throws {
            guard LocalTestingStore.shared.isLoaded else {
                throw StoreKitError.notAvailableInStorefront
            }
        }

        public static var currentOrder: [Product.PromotionInfo] {
            get async throws {
                guard LocalTestingStore.shared.isLoaded else {
                    throw StoreKitError.notAvailableInStorefront
                }
                return []
            }
        }

        public static func updateProductVisibility(
            _ visibility: Visibility,
            for productID: Product.ID
        ) async throws {
            _ = visibility
            _ = productID
            guard LocalTestingStore.shared.isLoaded else {
                throw StoreKitError.notAvailableInStorefront
            }
        }

        public static func updateProductOrder(byID order: some Collection<String>) async throws {
            _ = Array(order)
            guard LocalTestingStore.shared.isLoaded else {
                throw StoreKitError.notAvailableInStorefront
            }
        }

        public static func updateAll(_ promotions: some Collection<Product.PromotionInfo>) async throws {
            _ = Array(promotions)
            guard LocalTestingStore.shared.isLoaded else {
                throw StoreKitError.notAvailableInStorefront
            }
        }
    }

    public enum TaskState {
        case loading
        case success(Product)
        case failure(any Error)
        case unavailable
        public var product: Product? {
            if case .success(let product) = self { return product }
            return nil
        }
    }

    public enum CollectionTaskState {
        case loading
        case success([Product], unavailable: [Product.ID])
        case failure(any Error)
        public var products: [Product]? {
            if case .success(let products, _) = self { return products }
            return nil
        }
    }

    public let id: String
    public let displayName: String
    public let description: String
    public let price: Decimal
    public let displayPrice: String
    public let subscription: SubscriptionInfo?
    public let isFamilyShareable: Bool
    public let type: ProductType
    public var jsonRepresentation: Data {
        let object: [String: Any] = [
            "id": id,
            "displayName": displayName,
            "description": description,
            "displayPrice": displayPrice,
            "type": type.rawValue,
        ]
        return (try? JSONSerialization.data(withJSONObject: object)) ?? Data()
    }
    public var debugDescription: String { "Product(\(id) \(displayPrice))" }
    public var priceFormatStyle: Decimal.FormatStyle.Currency {
        Decimal.FormatStyle.Currency(code: "USD")
    }
    public var subscriptionPeriodFormatStyle: Date.ComponentsFormatStyle {
        // Linux Foundation exposes Codable init only; `{}` decodes to the default style.
        let data = Data("{}".utf8)
        return try! JSONDecoder().decode(Date.ComponentsFormatStyle.self, from: data)
    }
    public var subscriptionPeriodUnitFormatStyle: Product.SubscriptionPeriod.Unit.FormatStyle {
        Product.SubscriptionPeriod.Unit.FormatStyle()
    }

    public var latestTransaction: VerificationResult<Transaction>? {
        get async { await Transaction.latest(for: id) }
    }

    public var currentEntitlement: VerificationResult<Transaction>? {
        get async { await Transaction.currentEntitlement(for: id) }
    }

    public var currentEntitlements: Transaction.Transactions {
        Transaction.currentEntitlements(for: id)
    }

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
        self.displayPrice = displayPrice ?? price.description
        self.subscription = subscription
        self.isFamilyShareable = isFamilyShareable
        self.type = type
    }

    public static func products<Identifiers>(
        for identifiers: Identifiers
    ) async throws -> [Product] where Identifiers: Collection, Identifiers.Element == String {
        try StoreKitTesting.products(for: Array(identifiers))
    }

    public func purchase(
        options: Set<PurchaseOption> = []
    ) async throws -> PurchaseResult {
        try StoreKitTesting.purchase(self, options: options)
    }

    public func purchase(
        confirmIn viewController: UIViewController,
        options: Set<PurchaseOption> = []
    ) async throws -> PurchaseResult {
        _ = viewController
        return try StoreKitTesting.purchase(self, options: options)
    }

    public func purchase(
        confirmIn scene: some UIScene,
        options: Set<PurchaseOption> = []
    ) async throws -> PurchaseResult {
        _ = scene
        return try StoreKitTesting.purchase(self, options: options)
    }

    #if canImport(AppKit)
    @available(macOS 15.2, *)
    public func purchase(
        confirmIn window: NSWindow,
        options: Set<PurchaseOption> = []
    ) async throws -> PurchaseResult {
        _ = window
        return try StoreKitTesting.purchase(self, options: options)
    }
    #endif
}

public typealias SubscriptionInfo = Product.SubscriptionInfo
public typealias SubscriptionPeriod = Product.SubscriptionPeriod
public typealias SubscriptionStatus = Product.SubscriptionInfo.Status
public typealias SubscriptionRenewalInfo = Product.SubscriptionInfo.RenewalInfo
public typealias SubscriptionRenewalState = Product.SubscriptionInfo.RenewalState
