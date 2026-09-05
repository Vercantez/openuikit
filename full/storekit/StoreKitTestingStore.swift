import Foundation

/// Local StoreKit Testing store for hosts with no App Store.
///
/// Parses the documented Xcode `.storekit` JSON configuration schema
/// (`identifier`, `products`, `subscriptionGroups`, `nonRenewingSubscriptions`,
/// `settings`) used by StoreKit Testing in Xcode. There is no App Store on
/// Linux: purchases run through this in-memory catalog.
///
/// Signed results are modelled as `VerificationResult.unverified` unless the
/// configuration's `settings` dictionary contains the portable testing key
/// `_treatTransactionsAsVerified` = true. Apple's public `.storekit` schema
/// does not record JWS certificates, so Linux cannot honestly emit `.verified`
/// without that explicit test mark.
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
    }

    public static func loadConfiguration(from url: URL) throws {
        let data = try Data(contentsOf: url)
        try loadConfiguration(data: data)
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
        appAccountToken: UUID?
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
        let now = Date()
        let identifier = nextTransactionID
        nextTransactionID += 1
        var expiration: Date?
        if catalogProduct.type == .autoRenewable, let period = catalogProduct.period {
            expiration = period.endDate(from: now)
        }
        let storefront = Storefront(id: storefrontID, countryCode: countryCode)
        let jws = LocalTestingStore.makeJWS(
            productID: catalogProduct.id,
            transactionID: identifier,
            date: now
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
            appBundleID: Bundle.main.bundleIdentifier ?? "localhost",
            appAccountToken: appAccountToken,
            purchasedQuantity: quantity,
            storefront: storefront,
            reason: .purchase,
            ownershipType: .purchased,
            environment: .xcode,
            signedDate: now,
            deviceVerification: jws.deviceVerification,
            deviceVerificationNonce: jws.deviceVerificationNonce,
            jsonRepresentation: jws.payloadData,
            jwsHeaderData: jws.headerData,
            jwsPayloadData: jws.payloadData,
            jwsSignatureData: jws.signatureData,
            jwsRepresentation: jws.representation,
            price: catalogProduct.price,
            currencyCode: currencyCode,
            offer: nil
        )
        transactions.append(StoredTransaction(transaction: transaction, finished: false))
        let result: VerificationResult<Transaction>
        if treatVerified {
            result = .verified(transaction)
        } else {
            // Linux has no Apple root to validate JWS compact serialization.
            // Apple: VerificationResult.unverified wraps values that failed
            // automatic verification. https://developer.apple.com/documentation/storekit/verificationresult
            result = .unverified(transaction, .invalidSignature)
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
        return .unverified(transaction, .invalidSignature)
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
                promotionalOffers: [],
                winBackOffers: []
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
            introductory: intro
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

    private func formatDisplayPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        if let formatted = formatter.string(from: NSDecimalNumber(decimal: price)) {
            return formatted
        }
        return price.description
    }

    private struct JWSPieces {
        var headerData: Data
        var payloadData: Data
        var signatureData: Data
        var representation: String
        var deviceVerification: Data
        var deviceVerificationNonce: UUID
    }

    private static func makeJWS(productID: String, transactionID: UInt64, date: Date) -> JWSPieces {
        let headerObject: [String: String] = ["alg": "none", "typ": "JWS"]
        let payloadObject: [String: Any] = [
            "transactionId": NSNumber(value: transactionID),
            "productId": productID,
            "purchaseDate": NSNumber(value: date.timeIntervalSince1970),
        ]
        let headerData = (try? JSONSerialization.data(withJSONObject: headerObject)) ?? Data()
        let payloadData = (try? JSONSerialization.data(withJSONObject: payloadObject)) ?? Data()
        let signatureData = Data()
        let representation =
            base64url(headerData) + "." + base64url(payloadData) + "."
        return JWSPieces(
            headerData: headerData,
            payloadData: payloadData,
            signatureData: signatureData,
            representation: representation,
            deviceVerification: Data(repeating: 0, count: 16),
            deviceVerificationNonce: UUID()
        )
    }

    private static func base64url(_ data: Data) -> String {
        var output = ""
        for character in data.base64EncodedString() {
            if character == "+" {
                output.append("-")
            } else if character == "/" {
                output.append("_")
            } else if character == "=" {
                continue
            } else {
                output.append(character)
            }
        }
        return output
    }
}
