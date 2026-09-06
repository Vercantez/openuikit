import Foundation
import FinanceKit

func financeKitExpect(_ condition: Bool, _ message: String = "precondition failed") {
    precondition(condition, message)
}

func financeKitSink<T>(_ value: T) {
    _ = value
}

func financeKitRoundTrip<T: Codable & Equatable>(_ value: T) -> T {
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        preconditionFailure("codable round-trip failed: \(error)")
    }
}

func sampleCurrencyAmount() -> CurrencyAmount {
    CurrencyAmount(amount: Decimal(string: "12.50")!, currencyCode: "USD")
}

func sampleBalance(indicator: CreditDebitIndicator = .credit) -> Balance {
    Balance(
        amount: sampleCurrencyAmount(),
        asOfDate: Date(timeIntervalSince1970: 1_700_000_000),
        creditDebitIndicator: indicator
    )
}

func sampleAssetAccount() -> AssetAccount {
    AssetAccount(
        id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        displayName: "Checking",
        accountDescription: "Primary",
        institutionName: "Example Bank",
        currencyCode: "USD",
        openingDate: Date(timeIntervalSince1970: 1_600_000_000)
    )
}

func sampleLiabilityAccount() -> LiabilityAccount {
    LiabilityAccount(
        id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        displayName: "Card",
        accountDescription: nil,
        institutionName: "Example Bank",
        currencyCode: "USD",
        creditInformation: AccountCreditInformation(
            creditLimit: CurrencyAmount(amount: Decimal(5000), currencyCode: "USD"),
            nextPaymentDueDate: Date(timeIntervalSince1970: 1_710_000_000),
            minimumNextPaymentAmount: CurrencyAmount(amount: Decimal(25), currencyCode: "USD"),
            overduePaymentAmount: nil
        ),
        openingDate: nil
    )
}

func sampleTransaction() -> Transaction {
    Transaction(
        id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
        accountID: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        transactionAmount: sampleCurrencyAmount(),
        foreignCurrencyAmount: CurrencyAmount(amount: Decimal(10), currencyCode: "EUR"),
        foreignCurrencyExchangeRate: Decimal(string: "1.08"),
        creditDebitIndicator: .debit,
        transactionDescription: "Coffee",
        originalTransactionDescription: "COFFEE SHOP",
        merchantCategoryCode: MerchantCategoryCode(rawValue: 5812),
        merchantName: "Cafe",
        transactionType: .pointOfSale,
        status: .booked,
        transactionDate: Date(timeIntervalSince1970: 1_700_000_100),
        postedDate: Date(timeIntervalSince1970: 1_700_086_400)
    )
}
