import Foundation

public struct CurrencyAmount: Hashable, Sendable {
    public let amount: Decimal
    public let currencyCode: String

    public init(amount: Decimal, currencyCode: String) {
        self.amount = amount
        self.currencyCode = currencyCode
    }
}

extension CurrencyAmount: Codable {
    enum CodingKeys: String, CodingKey {
        case amount
        case currencyCode
    }
}

public struct Balance: Hashable, Sendable, Codable {
    public let amount: CurrencyAmount
    public let asOfDate: Date
    public let creditDebitIndicator: CreditDebitIndicator

    public init(amount: CurrencyAmount, asOfDate: Date, creditDebitIndicator: CreditDebitIndicator) {
        self.amount = amount
        self.asOfDate = asOfDate
        self.creditDebitIndicator = creditDebitIndicator
    }
}

public enum CurrentBalance: Hashable, Sendable, Codable {
    case available(Balance)
    case booked(Balance)
    case availableAndBooked(available: Balance, booked: Balance)
}

public struct AccountBalance: Equatable, Identifiable, Sendable, Codable {
    public typealias ID = UUID

    public let id: UUID
    public let accountID: UUID
    public let currentBalance: CurrentBalance

    public init(id: UUID, accountID: UUID, currentBalance: CurrentBalance) {
        self.id = id
        self.accountID = accountID
        self.currentBalance = currentBalance
    }

    public var available: Balance? {
        switch currentBalance {
        case .available(let balance):
            return balance
        case .booked:
            return nil
        case .availableAndBooked(let available, _):
            return available
        }
    }

    public var booked: Balance? {
        switch currentBalance {
        case .available:
            return nil
        case .booked(let balance):
            return balance
        case .availableAndBooked(_, let booked):
            return booked
        }
    }

    public var currencyCode: String {
        if let available {
            return available.amount.currencyCode
        }
        if let booked {
            return booked.amount.currencyCode
        }
        return ""
    }
}

public struct AccountCreditInformation: Hashable, Sendable, Codable {
    public let creditLimit: CurrencyAmount?
    public let nextPaymentDueDate: Date?
    public let minimumNextPaymentAmount: CurrencyAmount?
    public let overduePaymentAmount: CurrencyAmount?

    public init(
        creditLimit: CurrencyAmount? = nil,
        nextPaymentDueDate: Date? = nil,
        minimumNextPaymentAmount: CurrencyAmount? = nil,
        overduePaymentAmount: CurrencyAmount? = nil
    ) {
        self.creditLimit = creditLimit
        self.nextPaymentDueDate = nextPaymentDueDate
        self.minimumNextPaymentAmount = minimumNextPaymentAmount
        self.overduePaymentAmount = overduePaymentAmount
    }
}

public struct AssetAccount: Equatable, Identifiable, Sendable, Codable {
    public typealias ID = UUID

    public let id: UUID
    public let displayName: String
    public let accountDescription: String?
    public let institutionName: String
    public let currencyCode: String
    public let openingDate: Date?

    public init(
        id: UUID,
        displayName: String,
        accountDescription: String? = nil,
        institutionName: String,
        currencyCode: String,
        openingDate: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.accountDescription = accountDescription
        self.institutionName = institutionName
        self.currencyCode = currencyCode
        self.openingDate = openingDate
    }
}

public struct LiabilityAccount: Equatable, Identifiable, Sendable, Codable {
    public typealias ID = UUID

    public let id: UUID
    public let displayName: String
    public let accountDescription: String?
    public let institutionName: String
    public let currencyCode: String
    public let creditInformation: AccountCreditInformation
    public let openingDate: Date?

    public init(
        id: UUID,
        displayName: String,
        accountDescription: String? = nil,
        institutionName: String,
        currencyCode: String,
        creditInformation: AccountCreditInformation,
        openingDate: Date? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.accountDescription = accountDescription
        self.institutionName = institutionName
        self.currencyCode = currencyCode
        self.creditInformation = creditInformation
        self.openingDate = openingDate
    }
}

public enum Account: Equatable, Identifiable, Sendable, Codable {
    public typealias ID = UUID

    case asset(AssetAccount)
    case liability(LiabilityAccount)

    public var id: UUID {
        switch self {
        case .asset(let account): return account.id
        case .liability(let account): return account.id
        }
    }

    public var displayName: String {
        switch self {
        case .asset(let account): return account.displayName
        case .liability(let account): return account.displayName
        }
    }

    public var accountDescription: String? {
        switch self {
        case .asset(let account): return account.accountDescription
        case .liability(let account): return account.accountDescription
        }
    }

    public var institutionName: String {
        switch self {
        case .asset(let account): return account.institutionName
        case .liability(let account): return account.institutionName
        }
    }

    public var currencyCode: String {
        switch self {
        case .asset(let account): return account.currencyCode
        case .liability(let account): return account.currencyCode
        }
    }

    public var openingDate: Date? {
        switch self {
        case .asset(let account): return account.openingDate
        case .liability(let account): return account.openingDate
        }
    }

    public var assetAccount: AssetAccount? {
        if case .asset(let account) = self { return account }
        return nil
    }

    public var liabilityAccount: LiabilityAccount? {
        if case .liability(let account) = self { return account }
        return nil
    }
}

public struct Transaction: Equatable, Identifiable, Sendable, Codable {
    public typealias ID = UUID

    public let id: UUID
    public let accountID: UUID
    public let transactionAmount: CurrencyAmount
    public let foreignCurrencyAmount: CurrencyAmount?
    public let foreignCurrencyExchangeRate: Decimal?
    public let creditDebitIndicator: CreditDebitIndicator
    public let transactionDescription: String
    public let originalTransactionDescription: String
    public let merchantCategoryCode: MerchantCategoryCode?
    public let merchantName: String?
    public let transactionType: TransactionType
    public let status: TransactionStatus
    public let transactionDate: Date
    public let postedDate: Date?

    public init(
        id: UUID,
        accountID: UUID,
        transactionAmount: CurrencyAmount,
        foreignCurrencyAmount: CurrencyAmount? = nil,
        foreignCurrencyExchangeRate: Decimal? = nil,
        creditDebitIndicator: CreditDebitIndicator,
        transactionDescription: String,
        originalTransactionDescription: String,
        merchantCategoryCode: MerchantCategoryCode? = nil,
        merchantName: String? = nil,
        transactionType: TransactionType,
        status: TransactionStatus,
        transactionDate: Date,
        postedDate: Date? = nil
    ) {
        self.id = id
        self.accountID = accountID
        self.transactionAmount = transactionAmount
        self.foreignCurrencyAmount = foreignCurrencyAmount
        self.foreignCurrencyExchangeRate = foreignCurrencyExchangeRate
        self.creditDebitIndicator = creditDebitIndicator
        self.transactionDescription = transactionDescription
        self.originalTransactionDescription = originalTransactionDescription
        self.merchantCategoryCode = merchantCategoryCode
        self.merchantName = merchantName
        self.transactionType = transactionType
        self.status = status
        self.transactionDate = transactionDate
        self.postedDate = postedDate
    }
}
