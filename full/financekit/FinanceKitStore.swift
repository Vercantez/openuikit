import Foundation

public final class FinanceStore: @unchecked Sendable {
    public static let shared = FinanceStore()

    private let lock = NSLock()
    private var enabledBackgroundTypes: Set<BackgroundDataType> = []
    private var backgroundFrequency: UpdateFrequency?

    private init() {}

    public enum DataType: Hashable, Sendable {
        case orders
        case financialData
    }

    public enum BackgroundDataType: Codable, Hashable, Sendable {
        case accounts
        case accountBalances
        case transactions
    }

    public enum UpdateFrequency: Codable, Hashable, Sendable {
        case hourly
        case daily
        case weekly
    }

    public enum ContainsOrderResult: Hashable, Sendable, CaseIterable {
        case exists
        case notFound
        case newerExists
        case olderExists
    }

    public enum SaveOrderResult: Hashable, Sendable, CaseIterable {
        case added
        case cancelled
        case newerExisting
    }

    public struct HistoryToken: Sendable, Codable {
        var payload: Data

        init(payload: Data) {
            self.payload = payload
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            payload = try container.decode(Data.self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(payload)
        }
    }

    public struct Changes<Model: Identifiable>: @unchecked Sendable {
        public let inserted: [Model]
        public let updated: [Model]
        public let deleted: [Model.ID]
        public let newToken: HistoryToken

        public init(
            inserted: [Model],
            updated: [Model],
            deleted: [Model.ID],
            newToken: HistoryToken
        ) {
            self.inserted = inserted
            self.updated = updated
            self.deleted = deleted
            self.newToken = newToken
        }
    }

    public struct History<Model: Identifiable>: AsyncSequence, @unchecked Sendable {
        public typealias Element = Changes<Model>
        public typealias AsyncIterator = Iterator

        let token: HistoryToken?
        let isMonitoring: Bool
        let restriction: FinanceError

        public func makeAsyncIterator() -> Iterator {
            Iterator(restriction: restriction)
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = Changes<Model>

            let restriction: FinanceError

            public func next() async throws -> Changes<Model>? {
                throw restriction
            }
        }
    }

    public static func isDataAvailable(_ type: DataType) -> Bool {
        _ = type
        return false
    }

    public func accounts(query: AccountQuery) async throws -> [Account] {
        _ = query
        throw FinanceError.dataRestricted(.financialData)
    }

    public func transactions(query: TransactionQuery) async throws -> [Transaction] {
        _ = query
        throw FinanceError.dataRestricted(.financialData)
    }

    public func accountBalances(query: AccountBalanceQuery) async throws -> [AccountBalance] {
        _ = query
        throw FinanceError.dataRestricted(.financialData)
    }

    public func accountHistory(
        since token: HistoryToken? = nil,
        isMonitoring: Bool = true
    ) -> History<Account> {
        History(
            token: token,
            isMonitoring: isMonitoring,
            restriction: .dataRestricted(.financialData)
        )
    }

    public func transactionHistory(
        forAccountID accountID: UUID,
        since token: HistoryToken? = nil,
        isMonitoring: Bool = true
    ) -> History<Transaction> {
        _ = accountID
        return History(
            token: token,
            isMonitoring: isMonitoring,
            restriction: .dataRestricted(.financialData)
        )
    }

    public func accountBalanceHistory(
        forAccountID accountID: UUID,
        since token: HistoryToken? = nil,
        isMonitoring: Bool = true
    ) -> History<AccountBalance> {
        _ = accountID
        return History(
            token: token,
            isMonitoring: isMonitoring,
            restriction: .dataRestricted(.financialData)
        )
    }

    public func authorizationStatus() async throws -> AuthorizationStatus {
        .denied
    }

    public func requestAuthorization() async throws -> AuthorizationStatus {
        .denied
    }

    public func containsOrder(
        matching fqoid: FullyQualifiedOrderIdentifier,
        updatedDate: Date? = nil
    ) async throws -> ContainsOrderResult {
        _ = (fqoid, updatedDate)
        throw FinanceError.dataRestricted(.orders)
    }

    public func saveOrder(signedArchive: Data) async throws -> SaveOrderResult {
        _ = signedArchive
        throw FinanceError.dataRestricted(.orders)
    }

    public func enableBackgroundDelivery(for types: [BackgroundDataType], frequency: UpdateFrequency) {
        lock.lock()
        enabledBackgroundTypes.formUnion(types)
        backgroundFrequency = frequency
        lock.unlock()
    }

    public func disableBackgroundDelivery(for types: [BackgroundDataType]) {
        lock.lock()
        enabledBackgroundTypes.subtract(types)
        lock.unlock()
    }

    public func disableAllBackgroundDelivery() {
        lock.lock()
        enabledBackgroundTypes.removeAll()
        backgroundFrequency = nil
        lock.unlock()
    }
}
