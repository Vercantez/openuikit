import Foundation

/// Local StoreKit Testing store for hosts with no App Store.
///
/// Parses the documented Xcode `.storekit` JSON configuration schema
/// (`identifier`, `products`, `subscriptionGroups`, `nonRenewingSubscriptions`,
/// `settings`) used by StoreKit Testing in Xcode. There is no App Store on
/// Linux: purchases run through this in-memory catalog.
///
/// Compact JWS is real (base64url header/payload/signature plus `x5c`).
/// Signature verification is fail-closed: results are
/// `VerificationResult.unverified(_, .invalidSignature)` unless `settings`
/// contains `_treatTransactionsAsVerified` = true. That flag is a portable
/// testing override, not Apple root validation.
public enum StoreKitTesting {
    public static func reset() {
        LocalTestingStore.shared.reset()
    }

    public static var isConfigurationLoaded: Bool {
        LocalTestingStore.shared.isLoaded
    }

    public static func loadConfiguration(json: String) throws {
        guard let data = json.data(using: .utf8) else {
            throw StoreKitError.systemError(
                NSError(domain: "StoreKitTesting", code: 1)
            )
        }
        try loadConfiguration(data: data)
    }

    public static func loadConfiguration(data: Data) throws {
        try LocalTestingStore.shared.load(data: data)
        SKPaymentQueue.default().notifyStorefrontDidChange()
    }

    public static func loadConfiguration(from url: URL) throws {
        let data = try Data(contentsOf: url)
        try loadConfiguration(data: data)
    }

    /// Synchronous catalog lookup. `Product.products(for:)` is the async
    /// wrapper around this host path; the catalog does not suspend.
    public static func products(for identifiers: [String]) throws -> [Product] {
        guard LocalTestingStore.shared.isLoaded else {
            throw StoreKitError.notAvailableInStorefront
        }
        return LocalTestingStore.shared.products(for: identifiers)
    }

    public static func purchase(
        _ product: Product,
        options: Set<Product.PurchaseOption> = []
    ) throws -> Product.PurchaseResult {
        var quantity = 1
        var token: UUID?
        var offer: Transaction.Offer?
        for option in options {
            if let value = option.quantityValue { quantity = value }
            if let value = option.appAccountTokenValue { token = value }
            if let identifier = option.promotionalOfferID {
                offer = Transaction.Offer(
                    id: identifier,
                    type: .promotional,
                    paymentMode: .payAsYouGo
                )
            }
            if let identifier = option.winBackOfferID {
                offer = Transaction.Offer(
                    id: identifier,
                    type: .winBack,
                    paymentMode: .freeTrial
                )
            }
        }
        let result = try LocalTestingStore.shared.purchase(
            product: product,
            quantity: quantity,
            appAccountToken: token,
            offer: offer
        )
        return .success(result)
    }

    public static func currentEntitlements() -> [VerificationResult<Transaction>] {
        LocalTestingStore.shared.snapshotEntitlements()
    }

    public static func allTransactions() -> [VerificationResult<Transaction>] {
        LocalTestingStore.shared.snapshotAll()
    }

    public static func unfinished() -> [VerificationResult<Transaction>] {
        LocalTestingStore.shared.snapshotUnfinished()
    }

    public static func latest(for productID: String) -> VerificationResult<Transaction>? {
        LocalTestingStore.shared.latest(for: productID)
    }

    public static func currentEntitlement(
        for productID: String
    ) -> VerificationResult<Transaction>? {
        LocalTestingStore.shared.currentEntitlement(for: productID)
    }

    public static func finish(_ transaction: Transaction) {
        LocalTestingStore.shared.finish(id: transaction.id)
    }

    public static func currentStorefront() -> Storefront? {
        LocalTestingStore.shared.currentStorefront
    }

    public static func sync() throws {
        guard LocalTestingStore.shared.isLoaded else {
            throw StoreKitError.notAvailableInStorefront
        }
    }

    public static func appTransaction() throws -> VerificationResult<AppTransaction> {
        try AppTransaction.currentForTesting()
    }

    public static func subscriptionStatus(
        for groupID: String
    ) throws -> [Product.SubscriptionInfo.Status] {
        try Product.SubscriptionInfo.statusNow(for: groupID)
    }

    public static func isEligibleForIntroOffer(for groupID: String) -> Bool {
        LocalTestingStore.shared.isEligibleForIntroOffer(groupID: groupID)
    }

    public static func showManageSubscriptions() throws {
        throw StoreKitError.notAvailableInStorefront
    }

    public static func beginRefundRequest(
        transactionID: UInt64
    ) throws -> Transaction.RefundRequestStatus {
        _ = transactionID
        throw StoreKitError.notAvailableInStorefront
    }

    public static func revoke(
        productID: String,
        reason: Transaction.RevocationReason
    ) {
        LocalTestingStore.shared.revoke(productID: productID, reason: reason)
        SKPaymentQueue.default().notifyRevokedEntitlements(
            productIdentifiers: [productID]
        )
    }

    public static func expire(productID: String) {
        LocalTestingStore.shared.expire(productID: productID)
    }

    public static func parseJWS(_ compact: String) throws -> StoreKitJWS {
        try StoreKitJWSCodec.parse(compact)
    }

    public static func signatureCheck(
        _ compact: String
    ) -> VerificationResult<Transaction>.VerificationError {
        StoreKitJWSCodec.signatureCheck(compact)
    }

    public static func takePendingUpdates() -> [VerificationResult<Transaction>] {
        LocalTestingStore.shared.takePendingUpdates()
    }

    public static func enqueuePurchaseIntent(
        productID: String,
        offer: Product.SubscriptionOffer? = nil
    ) throws {
        try LocalTestingStore.shared.enqueuePurchaseIntent(productID: productID, offer: offer)
    }

    public static func takePendingIntents() -> [PurchaseIntent] {
        LocalTestingStore.shared.takePendingIntents()
    }

    public static func enqueueMessage(reason: Message.Reason) {
        LocalTestingStore.shared.enqueueMessage(Message(reason: reason))
    }

    public static func takePendingMessages() -> [Message] {
        LocalTestingStore.shared.takePendingMessages()
    }

    public static func promotionOrder() throws -> [Product.PromotionInfo] {
        guard LocalTestingStore.shared.isLoaded else {
            throw StoreKitError.notAvailableInStorefront
        }
        return LocalTestingStore.shared.promotionInfos()
    }

    public static func updateProductVisibility(
        _ visibility: Product.PromotionInfo.Visibility,
        for productID: String
    ) throws {
        guard LocalTestingStore.shared.isLoaded else {
            throw StoreKitError.notAvailableInStorefront
        }
        LocalTestingStore.shared.setPromotionVisibility(visibility, for: productID)
    }

    public static func updateProductOrder(byID order: [String]) throws {
        guard LocalTestingStore.shared.isLoaded else {
            throw StoreKitError.notAvailableInStorefront
        }
        LocalTestingStore.shared.setPromotionOrder(order)
    }

    public static func presentOfferCodeRedeemSheet() throws {
        throw StoreKitError.notAvailableInStorefront
    }

    public static func subscriptionStatuses() -> [Product.SubscriptionInfo.Status] {
        LocalTestingStore.shared.allSubscriptionStatuses()
    }

    public static func storefrontUpdates() -> [Storefront] {
        if let current = LocalTestingStore.shared.currentStorefront {
            return [current]
        }
        return []
    }
}

struct CatalogProduct: Sendable {
    var id: String
    var displayName: String
    var description: String
    var price: Decimal
    var displayPrice: String
    var type: Product.ProductType
    var familyShareable: Bool
    var subscriptionGroupID: String?
    var groupLevel: Int
    var groupDisplayName: String
    var period: Product.SubscriptionPeriod?
    var introductory: Product.SubscriptionOffer?
    var promotionalOffers: [Product.SubscriptionOffer]
    var winBackOffers: [Product.SubscriptionOffer]
}

struct StoredTransaction: Sendable {
    var transaction: Transaction
    var finished: Bool
}

final class UpdateListenerBox: @unchecked Sendable {
    var continuation: CheckedContinuation<VerificationResult<Transaction>?, Never>?
}

final class LocalTestingStore: @unchecked Sendable {
    static let shared = LocalTestingStore()

    private let lock = NSLock()
    private var loaded = false
    private var treatVerified = false
    private var locale = Locale(identifier: "en_US")
    private var storefrontID = "USA"
    private var countryCode = "USA"
    private var currencyCode = "USD"
    private var catalog: [String: CatalogProduct] = [:]
    private var transactions: [StoredTransaction] = []
    private var nextTransactionID: UInt64 = 1
    private var pendingUpdates: [VerificationResult<Transaction>] = []
    private var listeners: [UUID: UpdateListenerBox] = [:]
    private var skTransactions: [SKPaymentTransaction] = []
    private var introConsumedGroups: Set<String> = []
    private var purchaseIntents: [PurchaseIntent] = []
    private var messages: [Message] = []
    private var promotionOrderIDs: [String] = []
    private var promotionVisibility: [String: Product.PromotionInfo.Visibility] = [:]

    private init() {}

    var isLoaded: Bool {
        lock.lock()
        defer { lock.unlock() }
        return loaded
    }

    var canMakePayments: Bool {
        lock.lock()
        defer { lock.unlock() }
        return loaded
    }

    var treatsTransactionsAsVerified: Bool {
        lock.lock()
        defer { lock.unlock() }
        return treatVerified
    }

    var currentStorefront: Storefront? {
        lock.lock()
        defer { lock.unlock() }
        guard loaded else { return nil }
        return Storefront(id: storefrontID, countryCode: countryCode)
    }

    var currentSKStorefront: SKStorefront? {
        lock.lock()
        defer { lock.unlock() }
        guard loaded else { return nil }
        return SKStorefront(identifier: storefrontID, countryCode: countryCode)
    }

    var priceLocale: Locale {
        lock.lock()
        defer { lock.unlock() }
        return locale
    }

    var pendingSKTransactions: [SKPaymentTransaction] {
        lock.lock()
        defer { lock.unlock() }
        return skTransactions
    }

    func reset() {
        lock.lock()
        loaded = false
        treatVerified = false
        locale = Locale(identifier: "en_US")
        storefrontID = "USA"
        countryCode = "USA"
        currencyCode = "USD"
        catalog = [:]
        transactions = []
        nextTransactionID = 1
        pendingUpdates = []
        let waiting = listeners
        listeners = [:]
        skTransactions = []
        introConsumedGroups = []
        purchaseIntents = []
        messages = []
        promotionOrderIDs = []
        promotionVisibility = [:]
        lock.unlock()
        for box in waiting.values {
            box.continuation?.resume(returning: nil)
            box.continuation = nil
        }
    }

    func load(data: Data) throws {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw StoreKitError.systemError(error)
        }
        guard let root = object as? [String: Any] else {
            throw StoreKitError.systemError(
                NSError(domain: "StoreKitTesting", code: 2)
            )
        }
        lock.lock()
        defer { lock.unlock() }
        catalog = [:]
        transactions = []
        nextTransactionID = 1
        pendingUpdates = []
        skTransactions = []
        introConsumedGroups = []
        purchaseIntents = []
        messages = []
        promotionOrderIDs = []
        promotionVisibility = [:]
        parseSettings(root["settings"] as? [String: Any])
        parseProducts(root["products"] as? [Any] ?? [])
        parseNonRenewing(root["nonRenewingSubscriptions"] as? [Any] ?? [])
        parseGroups(root["subscriptionGroups"] as? [Any] ?? [])
        loaded = true
    }

    func products(for identifiers: [String]) -> [Product] {
        lock.lock()
        defer { lock.unlock() }
        var result: [Product] = []
        for identifier in identifiers {
            if let catalogProduct = catalog[identifier] {
                result.append(makeProduct(catalogProduct))
            }
        }
        return result
    }

    func skProducts(for identifiers: Set<String>) -> (valid: [SKProduct], invalid: [String]) {
        lock.lock()
        defer { lock.unlock() }
        var valid: [SKProduct] = []
        var invalid: [String] = []
        for identifier in identifiers {
            if let catalogProduct = catalog[identifier] {
                valid.append(makeSKProduct(catalogProduct))
            } else {
                invalid.append(identifier)
            }
        }
        return (valid, invalid)
    }

    func catalogProduct(id: String) -> CatalogProduct? {
        lock.lock()
        defer { lock.unlock() }
        return catalog[id]
    }

    func purchase(
        product: Product,
        quantity: Int,
        appAccountToken: UUID?,
        offer: Transaction.Offer? = nil
    ) throws -> VerificationResult<Transaction> {
        lock.lock()
        guard loaded else {
            lock.unlock()
            throw StoreKitError.notAvailableInStorefront
        }
        guard let catalogProduct = catalog[product.id] else {
            lock.unlock()
            throw Product.PurchaseError.productUnavailable
        }
        if quantity < 1 {
            lock.unlock()
            throw Product.PurchaseError.invalidQuantity
        }
        var appliedOffer = offer
        if let identifier = offer?.id, offer?.type == .promotional {
            let known = catalogProduct.promotionalOffers.contains { $0.id == identifier }
            if !known {
                lock.unlock()
                throw Product.PurchaseError.invalidOfferIdentifier
            }
        }
        if let identifier = offer?.id, offer?.type == .winBack {
            let known = catalogProduct.winBackOffers.contains { $0.id == identifier }
            if !known {
                lock.unlock()
                throw Product.PurchaseError.invalidOfferIdentifier
            }
        }
        let now = Date()
        let identifier = nextTransactionID
        nextTransactionID += 1
        var expiration: Date?
        if catalogProduct.type == .autoRenewable, let period = catalogProduct.period {
            expiration = period.endDate(from: now)
        }
        if catalogProduct.type == .nonRenewable, let period = catalogProduct.period {
            expiration = period.endDate(from: now)
        }
        if catalogProduct.type == .autoRenewable, let group = catalogProduct.subscriptionGroupID {
            if appliedOffer == nil,
               !introConsumedGroups.contains(group),
               let introductory = catalogProduct.introductory
            {
                appliedOffer = Transaction.Offer(
                    id: introductory.id,
                    type: .introductory,
                    paymentMode: Transaction.Offer.PaymentMode(
                        rawValue: introductory.paymentMode.rawValue
                    ),
                    period: introductory.period
                )
            }
            introConsumedGroups.insert(group)
        }
        let storefront = Storefront(id: storefrontID, countryCode: countryCode)
        let bundleID = Bundle.main.bundleIdentifier ?? "localhost"
        let nonce = UUID()
        let jws = LocalTestingStore.makeJWS(
            productID: catalogProduct.id,
            transactionID: identifier,
            date: now,
            bundleID: bundleID,
            productType: catalogProduct.type,
            storefront: storefront,
            quantity: quantity,
            environment: "Xcode",
            expiration: expiration
        )
        let transaction = Transaction(
            id: identifier,
            productID: catalogProduct.id,
            purchaseDate: now,
            expirationDate: expiration,
            revocationDate: nil,
            originalID: identifier,
            originalPurchaseDate: now,
            webOrderLineItemID: nil,
            subscriptionGroupID: catalogProduct.subscriptionGroupID,
            productType: catalogProduct.type,
            appBundleID: bundleID,
            appAccountToken: appAccountToken,
            purchasedQuantity: quantity,
            storefront: storefront,
            reason: .purchase,
            ownershipType: .purchased,
            environment: .xcode,
            signedDate: now,
            deviceVerification: Data(repeating: 0, count: 16),
            deviceVerificationNonce: nonce,
            jsonRepresentation: jws.payloadData,
            jwsHeaderData: jws.headerData,
            jwsPayloadData: jws.payloadData,
            jwsSignatureData: jws.signatureData,
            jwsRepresentation: jws.compactSerialization,
            price: catalogProduct.price,
            currencyCode: currencyCode,
            offer: appliedOffer
        )
        transactions.append(StoredTransaction(transaction: transaction, finished: false))
        let result: VerificationResult<Transaction>
        if treatVerified {
            result = .verified(transaction)
        } else {
            // Apple: VerificationResult.unverified wraps values that failed
            // automatic verification. https://developer.apple.com/documentation/storekit/verificationresult
            let error = StoreKitJWSCodec.signatureCheck(transaction.jwsRepresentation)
            result = .unverified(transaction, error)
        }
        let waiters = Array(listeners.values)
        let parked = waiters.filter { $0.continuation != nil }
        lock.unlock()
        if parked.isEmpty {
            lock.lock()
            pendingUpdates.append(result)
            lock.unlock()
        } else {
            for box in parked {
                let continuation = box.continuation
                box.continuation = nil
                continuation?.resume(returning: result)
            }
        }
        return result
    }

    func finish(id: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        for index in transactions.indices {
            if transactions[index].transaction.id == id {
                transactions[index].finished = true
            }
        }
        skTransactions.removeAll { transaction in
            guard let identifier = transaction.transactionIdentifier else { return false }
            return UInt64(identifier) == id
        }
    }

    func latest(for productID: String) -> VerificationResult<Transaction>? {
        lock.lock()
        defer { lock.unlock() }
        let matches = transactions.filter { $0.transaction.productID == productID }
        guard let last = matches.last else { return nil }
        return wrap(last.transaction)
    }

    func currentEntitlement(for productID: String) -> VerificationResult<Transaction>? {
        lock.lock()
        defer { lock.unlock() }
        let matches = transactions.filter { stored in
            stored.transaction.productID == productID && entitles(stored)
        }
        guard let last = matches.last else { return nil }
        return wrap(last.transaction)
    }

    func snapshotAll(productID: String? = nil) -> [VerificationResult<Transaction>] {
        lock.lock()
        defer { lock.unlock() }
        return transactions.compactMap { stored in
            if let productID, stored.transaction.productID != productID {
                return nil
            }
            return wrap(stored.transaction)
        }
    }

    func snapshotEntitlements(productID: String? = nil) -> [VerificationResult<Transaction>] {
        lock.lock()
        defer { lock.unlock() }
        var latest: [String: StoredTransaction] = [:]
        for stored in transactions where entitles(stored) {
            if let productID, stored.transaction.productID != productID {
                continue
            }
            latest[stored.transaction.productID] = stored
        }
        return latest.values.map { wrap($0.transaction) }
    }

    func snapshotUnfinished() -> [VerificationResult<Transaction>] {
        lock.lock()
        defer { lock.unlock() }
        return transactions.compactMap { stored in
            stored.finished ? nil : wrap(stored.transaction)
        }
    }

    func registerUpdateListener() -> UUID {
        lock.lock()
        defer { lock.unlock() }
        let identifier = UUID()
        listeners[identifier] = UpdateListenerBox()
        return identifier
    }

    func nextUpdate(id: UUID) async -> VerificationResult<Transaction>? {
        await withCheckedContinuation { continuation in
            lock.lock()
            if !pendingUpdates.isEmpty {
                let value = pendingUpdates.removeFirst()
                lock.unlock()
                continuation.resume(returning: value)
                return
            }
            guard let box = listeners[id] else {
                lock.unlock()
                continuation.resume(returning: nil)
                return
            }
            box.continuation = continuation
            lock.unlock()
        }
    }

    func cancelUpdateListener(id: UUID) {
        lock.lock()
        let box = listeners.removeValue(forKey: id)
        lock.unlock()
        box?.continuation?.resume(returning: nil)
    }

    func recordSKTransaction(_ transaction: SKPaymentTransaction) {
        lock.lock()
        defer { lock.unlock() }
        skTransactions.append(transaction)
    }

    func removeSKTransaction(_ transaction: SKPaymentTransaction) {
        lock.lock()
        defer { lock.unlock() }
        skTransactions.removeAll { existing in
            existing === transaction
        }
    }

    func takePendingUpdates() -> [VerificationResult<Transaction>] {
        lock.lock()
        defer { lock.unlock() }
        let values = pendingUpdates
        pendingUpdates = []
        return values
    }

    func enqueuePurchaseIntent(productID: String, offer: Product.SubscriptionOffer?) throws {
        lock.lock()
        defer { lock.unlock() }
        guard loaded else {
            throw StoreKitError.notAvailableInStorefront
        }
        guard let catalogProduct = catalog[productID] else {
            throw Product.PurchaseError.productUnavailable
        }
        purchaseIntents.append(
            PurchaseIntent(product: makeProduct(catalogProduct), offer: offer)
        )
    }

    func pendingPurchaseIntents() -> [PurchaseIntent] {
        lock.lock()
        defer { lock.unlock() }
        return purchaseIntents
    }

    func takePendingIntents() -> [PurchaseIntent] {
        lock.lock()
        defer { lock.unlock() }
        let values = purchaseIntents
        purchaseIntents = []
        return values
    }

    func enqueueMessage(_ message: Message) {
        lock.lock()
        defer { lock.unlock() }
        messages.append(message)
    }

    func pendingMessages() -> [Message] {
        lock.lock()
        defer { lock.unlock() }
        return messages
    }

    func takePendingMessages() -> [Message] {
        lock.lock()
        defer { lock.unlock() }
        let values = messages
        messages = []
        return values
    }

    func appTransaction() throws -> VerificationResult<AppTransaction> {
        lock.lock()
        defer { lock.unlock() }
        guard loaded else {
            throw StoreKitError.notAvailableInStorefront
        }
        let bundleID = Bundle.main.bundleIdentifier ?? "localhost"
        let payload: [String: Any] = [
            "bundleId": bundleID,
            "applicationVersion": "1.0",
            "originalApplicationVersion": "1.0",
            "environment": "Xcode",
            "originalPlatform": "iOS",
            "receiptType": "Xcode",
        ]
        let signed = StoreKitJWSCodec.encode(payload: payload)
        let value = AppTransaction(signed: signed, bundleID: bundleID, environment: .xcode)
        if treatVerified {
            return .verified(value)
        }
        return .unverified(value, .invalidSignature)
    }

    func promotionInfos() -> [Product.PromotionInfo] {
        lock.lock()
        defer { lock.unlock() }
        let order = promotionOrderIDs
        return order.compactMap { identifier in
            guard catalog[identifier] != nil else { return nil }
            let visibility = promotionVisibility[identifier] ?? .appStoreConnectDefault
            return Product.PromotionInfo(productID: identifier, visibility: visibility)
        }
    }

    func setPromotionVisibility(
        _ visibility: Product.PromotionInfo.Visibility,
        for productID: String
    ) {
        lock.lock()
        defer { lock.unlock() }
        promotionVisibility[productID] = visibility
    }

    func setPromotionOrder(_ order: [String]) {
        lock.lock()
        defer { lock.unlock() }
        promotionOrderIDs = order
    }

    func isEligibleForIntroOffer(groupID: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard loaded else { return false }
        if introConsumedGroups.contains(groupID) {
            return false
        }
        for stored in transactions {
            if stored.transaction.subscriptionGroupID == groupID {
                return false
            }
        }
        return true
    }

    func revoke(productID: String, reason: Transaction.RevocationReason) {
        lock.lock()
        defer { lock.unlock() }
        for index in transactions.indices {
            if transactions[index].transaction.productID == productID {
                let current = transactions[index].transaction
                transactions[index].transaction = current.revoked(at: Date(), reason: reason)
            }
        }
    }

    func expire(productID: String) {
        lock.lock()
        defer { lock.unlock() }
        for index in transactions.indices {
            if transactions[index].transaction.productID == productID {
                let current = transactions[index].transaction
                transactions[index].transaction = current.expired(at: Date())
            }
        }
    }

    func restoredNonConsumables() -> [CatalogProduct] {
        lock.lock()
        defer { lock.unlock() }
        var seen: [String: CatalogProduct] = [:]
        for stored in transactions {
            let type = stored.transaction.productType
            if type == .nonConsumable || type == .autoRenewable || type == .nonRenewable {
                if let catalogProduct = catalog[stored.transaction.productID] {
                    seen[catalogProduct.id] = catalogProduct
                }
            }
        }
        return Array(seen.values)
    }

    func subscriptionGroupIDs() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(Set(catalog.values.compactMap(\.subscriptionGroupID))).sorted()
    }

    func allSubscriptionStatuses() -> [Product.SubscriptionInfo.Status] {
        var result: [Product.SubscriptionInfo.Status] = []
        for group in subscriptionGroupIDs() {
            if let statuses = try? Product.SubscriptionInfo.statusNow(for: group) {
                result.append(contentsOf: statuses)
            }
        }
        return result
    }

    private func entitles(_ stored: StoredTransaction) -> Bool {
        let type = stored.transaction.productType
        if stored.transaction.revocationDate != nil {
            return false
        }
        if type == .consumable {
            return false
        }
        if type == .autoRenewable {
            if let expiration = stored.transaction.expirationDate, expiration < Date() {
                return false
            }
        }
        return true
    }

    private func wrap(_ transaction: Transaction) -> VerificationResult<Transaction> {
        if treatVerified {
            return .verified(transaction)
        }
        let error = StoreKitJWSCodec.signatureCheck(transaction.jwsRepresentation)
        return .unverified(transaction, error)
    }

    private func makeProduct(_ catalogProduct: CatalogProduct) -> Product {
        var subscription: Product.SubscriptionInfo?
        if let group = catalogProduct.subscriptionGroupID, let period = catalogProduct.period {
            subscription = Product.SubscriptionInfo(
                subscriptionGroupID: group,
                subscriptionPeriod: period,
                groupDisplayName: catalogProduct.groupDisplayName,
                groupLevel: catalogProduct.groupLevel,
                introductoryOffer: catalogProduct.introductory,
                promotionalOffers: catalogProduct.promotionalOffers,
                winBackOffers: catalogProduct.winBackOffers
            )
        }
        return Product(
            id: catalogProduct.id,
            displayName: catalogProduct.displayName,
            description: catalogProduct.description,
            price: catalogProduct.price,
            displayPrice: catalogProduct.displayPrice,
            subscription: subscription,
            isFamilyShareable: catalogProduct.familyShareable,
            type: catalogProduct.type
        )
    }

    private func makeSKProduct(_ catalogProduct: CatalogProduct) -> SKProduct {
        var period: SKProductSubscriptionPeriod?
        if let value = catalogProduct.period {
            period = SKProductSubscriptionPeriod(
                numberOfUnits: value.value,
                unit: SKProduct.PeriodUnit(storeKitUnit: value.unit)
            )
        }
        return SKProduct(
            productIdentifier: catalogProduct.id,
            localizedTitle: catalogProduct.displayName,
            localizedDescription: catalogProduct.description,
            price: NSDecimalNumber(decimal: catalogProduct.price),
            priceLocale: locale,
            subscriptionGroupIdentifier: catalogProduct.subscriptionGroupID,
            subscriptionPeriod: period,
            isFamilyShareable: catalogProduct.familyShareable
        )
    }

    private func parseSettings(_ settings: [String: Any]?) {
        guard let settings else { return }
        if let localeID = settings["_locale"] as? String {
            locale = Locale(identifier: localeID)
        }
        if let region = locale.region?.identifier, !region.isEmpty {
            countryCode = region
            storefrontID = region
        }
        if let identifier = settings["_storefront"] as? String {
            storefrontID = identifier
            countryCode = identifier
        }
        if let currency = locale.currency?.identifier {
            currencyCode = currency
        }
        if let flag = settings["_treatTransactionsAsVerified"] as? Bool {
            treatVerified = flag
        }
        if let flag = settings["_treatTransactionsAsVerified"] as? NSNumber {
            treatVerified = flag.boolValue
        }
    }

    private func parseProducts(_ items: [Any]) {
        for item in items {
            guard let dict = item as? [String: Any] else { continue }
            ingest(dict, fallbackType: .consumable, groupID: nil, groupName: "", groupLevel: 0)
        }
    }

    private func parseNonRenewing(_ items: [Any]) {
        for item in items {
            guard let dict = item as? [String: Any] else { continue }
            ingest(dict, fallbackType: .nonRenewable, groupID: nil, groupName: "", groupLevel: 0)
        }
    }

    private func parseGroups(_ groups: [Any]) {
        for group in groups {
            guard let dict = group as? [String: Any] else { continue }
            let groupID = (dict["id"] as? String) ?? ""
            let groupName = (dict["name"] as? String) ?? groupID
            let subscriptions = dict["subscriptions"] as? [Any] ?? []
            for item in subscriptions {
                guard let product = item as? [String: Any] else { continue }
                let level = (product["groupNumber"] as? Int)
                    ?? (product["groupNumber"] as? NSNumber)?.intValue
                    ?? 1
                ingest(
                    product,
                    fallbackType: .autoRenewable,
                    groupID: groupID,
                    groupName: groupName,
                    groupLevel: level
                )
            }
        }
    }

    private func ingest(
        _ dict: [String: Any],
        fallbackType: Product.ProductType,
        groupID: String?,
        groupName: String,
        groupLevel: Int
    ) {
        guard let productID = dict["productID"] as? String else { return }
        let typeRaw = dict["type"] as? String
        let type = Product.ProductType.fromStoreKitFile(typeRaw) ?? fallbackType
        let localization = pickLocalization(dict["localizations"] as? [Any] ?? [])
        let priceString = (dict["displayPrice"] as? String) ?? "0"
        let price = Decimal(string: priceString) ?? 0
        let displayPrice = formatDisplayPrice(price)
        let family = (dict["familyShareable"] as? Bool) ?? false
        let periodRaw = dict["recurringSubscriptionPeriod"] as? String
        let period = periodRaw.flatMap(Product.SubscriptionPeriod.init(iso8601Duration:))
        let intro = parseIntro(dict["introductoryOffer"] as? [String: Any])
        let promotional = parseOffers(dict["adHocOffers"] as? [Any] ?? [], type: .promotional)
        let winBack = parseOffers(dict["winBackOffers"] as? [Any] ?? [], type: .winBack)
        let resolvedGroup = (dict["subscriptionGroupID"] as? String) ?? groupID
        catalog[productID] = CatalogProduct(
            id: productID,
            displayName: localization.name,
            description: localization.description,
            price: price,
            displayPrice: displayPrice,
            type: type,
            familyShareable: family,
            subscriptionGroupID: resolvedGroup,
            groupLevel: groupLevel,
            groupDisplayName: groupName,
            period: period,
            introductory: intro,
            promotionalOffers: promotional,
            winBackOffers: winBack
        )
    }

    private func pickLocalization(_ items: [Any]) -> (name: String, description: String) {
        let wanted = locale.identifier
        var fallback: (String, String)?
        for item in items {
            guard let dict = item as? [String: Any] else { continue }
            let name = (dict["displayName"] as? String) ?? ""
            let description = (dict["description"] as? String) ?? ""
            let itemLocale = (dict["locale"] as? String) ?? ""
            if fallback == nil {
                fallback = (name, description)
            }
            if itemLocale == wanted {
                return (name, description)
            }
        }
        return fallback ?? ("", "")
    }

    private func parseIntro(_ dict: [String: Any]?) -> Product.SubscriptionOffer? {
        guard let dict else { return nil }
        let offerID = dict["offerID"] as? String
        let priceString = (dict["displayPrice"] as? String) ?? "0"
        let price = Decimal(string: priceString) ?? 0
        let periodRaw = dict["subscriptionPeriod"] as? String
        let period = periodRaw.flatMap(Product.SubscriptionPeriod.init(iso8601Duration:))
            ?? .monthly
        let count = (dict["numberOfPeriods"] as? Int)
            ?? (dict["numberOfPeriods"] as? NSNumber)?.intValue
            ?? 1
        let modeRaw = (dict["paymentMode"] as? String) ?? ""
        let mode: Product.SubscriptionOffer.PaymentMode
        if modeRaw == "free" || modeRaw == "freeTrial" {
            mode = .freeTrial
        } else if modeRaw == "payAsYouGo" {
            mode = .payAsYouGo
        } else {
            mode = .payUpFront
        }
        return Product.SubscriptionOffer(
            id: offerID,
            type: .introductory,
            price: price,
            displayPrice: formatDisplayPrice(price),
            period: period,
            periodCount: count,
            paymentMode: mode
        )
    }

    private func parseOffers(
        _ items: [Any],
        type: Product.SubscriptionOffer.OfferType
    ) -> [Product.SubscriptionOffer] {
        var result: [Product.SubscriptionOffer] = []
        for item in items {
            guard let dict = item as? [String: Any] else { continue }
            guard let parsed = parseIntro(dict) else { continue }
            result.append(
                Product.SubscriptionOffer(
                    id: parsed.id,
                    type: type,
                    price: parsed.price,
                    displayPrice: parsed.displayPrice,
                    period: parsed.period,
                    periodCount: parsed.periodCount,
                    paymentMode: parsed.paymentMode
                )
            )
        }
        return result
    }

    private func formatDisplayPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        if let formatted = formatter.string(from: NSDecimalNumber(decimal: price)) {
            return formatted
        }
        return price.description
    }

    private static func makeJWS(
        productID: String,
        transactionID: UInt64,
        date: Date,
        bundleID: String,
        productType: Product.ProductType,
        storefront: Storefront,
        quantity: Int,
        environment: String,
        expiration: Date?
    ) -> StoreKitJWS {
        let millisecond = NSNumber(value: Int64(date.timeIntervalSince1970 * 1000))
        var payload: [String: Any] = [
            "transactionId": NSNumber(value: transactionID),
            "originalTransactionId": NSNumber(value: transactionID),
            "productId": productID,
            "bundleId": bundleID,
            "purchaseDate": millisecond,
            "originalPurchaseDate": millisecond,
            "signedDate": millisecond,
            "type": productType.rawValue,
            "quantity": NSNumber(value: quantity),
            "storefront": storefront.id,
            "storefrontId": storefront.id,
            "environment": environment,
            "inAppOwnershipType": "PURCHASED",
            "transactionReason": "PURCHASE",
        ]
        if let expiration {
            payload["expiresDate"] = NSNumber(value: Int64(expiration.timeIntervalSince1970 * 1000))
        }
        return StoreKitJWSCodec.encode(payload: payload)
    }
}
