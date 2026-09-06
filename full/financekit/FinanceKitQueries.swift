import Foundation

public struct AccountQuery: Sendable {
    public var sortDescriptors: [SortDescriptor<Account>]
    public var predicate: Predicate<Account>?
    public var limit: Int?
    public var offset: Int?

    public init(
        sortDescriptors: [SortDescriptor<Account>] = [],
        predicate: Predicate<Account>? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.sortDescriptors = sortDescriptors
        self.predicate = predicate
        self.limit = limit
        self.offset = offset
    }
}

public struct TransactionQuery: Sendable {
    public var sortDescriptors: [SortDescriptor<Transaction>]
    public var predicate: Predicate<Transaction>?
    public var limit: Int?
    public var offset: Int?

    public init(
        sortDescriptors: [SortDescriptor<Transaction>] = [],
        predicate: Predicate<Transaction>? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.sortDescriptors = sortDescriptors
        self.predicate = predicate
        self.limit = limit
        self.offset = offset
    }

    public static func predicate(forTransactionTypes transactionTypes: [TransactionType]) -> Predicate<Transaction> {
        #Predicate<Transaction> { transaction in
            transactionTypes.contains(transaction.transactionType)
        }
    }

    public static func predicate(forStatuses statuses: [TransactionStatus]) -> Predicate<Transaction> {
        #Predicate<Transaction> { transaction in
            statuses.contains(transaction.status)
        }
    }

    public static func predicate(
        forMerchantCategoryCodes merchantCategoryCodes: [MerchantCategoryCode]
    ) -> Predicate<Transaction> {
        #Predicate<Transaction> { transaction in
            transaction.merchantCategoryCode != nil
                && merchantCategoryCodes.contains(transaction.merchantCategoryCode!)
        }
    }
}

public struct AccountBalanceQuery: Sendable {
    public var sortDescriptors: [SortDescriptor<AccountBalance>]
    public var predicate: Predicate<AccountBalance>?
    public var limit: Int?
    public var offset: Int?

    public init(
        sortDescriptors: [SortDescriptor<AccountBalance>] = [],
        predicate: Predicate<AccountBalance>? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.sortDescriptors = sortDescriptors
        self.predicate = predicate
        self.limit = limit
        self.offset = offset
    }

    public static func predicate(bookedSince startDate: Date, until endDate: Date? = nil) -> Predicate<AccountBalance> {
        if let endDate {
            return #Predicate<AccountBalance> { balance in
                balance.booked != nil
                    && balance.booked!.asOfDate >= startDate
                    && balance.booked!.asOfDate <= endDate
            }
        }
        return #Predicate<AccountBalance> { balance in
            balance.booked != nil && balance.booked!.asOfDate >= startDate
        }
    }

    public static func predicate(availableSince startDate: Date, until endDate: Date? = nil) -> Predicate<AccountBalance> {
        if let endDate {
            return #Predicate<AccountBalance> { balance in
                balance.available != nil
                    && balance.available!.asOfDate >= startDate
                    && balance.available!.asOfDate <= endDate
            }
        }
        return #Predicate<AccountBalance> { balance in
            balance.available != nil && balance.available!.asOfDate >= startDate
        }
    }
}
