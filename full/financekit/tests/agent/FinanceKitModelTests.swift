import Foundation
import FinanceKit

func testCurrencyAmountProperties() {
    let amount = sampleCurrencyAmount()
    financeKitExpect(amount.amount == Decimal(string: "12.50")!)
    financeKitExpect(amount.currencyCode == "USD")
}

func testBalanceProperties() {
    let balance = sampleBalance(indicator: .debit)
    financeKitExpect(balance.amount.currencyCode == "USD")
    financeKitExpect(balance.creditDebitIndicator == .debit)
    financeKitExpect(balance.asOfDate.timeIntervalSince1970 == 1_700_000_000)
}

func testCurrentBalanceCases() {
    let available = sampleBalance(indicator: .credit)
    let booked = sampleBalance(indicator: .debit)
    financeKitSink(CurrentBalance.available(available))
    financeKitSink(CurrentBalance.booked(booked))
    let both = CurrentBalance.availableAndBooked(available: available, booked: booked)
    if case .availableAndBooked(let a, let b) = both {
        financeKitExpect(a.creditDebitIndicator == .credit)
        financeKitExpect(b.creditDebitIndicator == .debit)
    } else {
        financeKitExpect(false, "availableAndBooked mismatch")
    }
}

func testAccountBalanceDerivedFields() {
    let available = sampleBalance(indicator: .credit)
    let booked = sampleBalance(indicator: .debit)
    let id = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
    let accountID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    let both = AccountBalance(
        id: id,
        accountID: accountID,
        currentBalance: .availableAndBooked(available: available, booked: booked)
    )
    financeKitExpect(both.id == id)
    financeKitExpect(both.accountID == accountID)
    financeKitExpect(both.available?.creditDebitIndicator == .credit)
    financeKitExpect(both.booked?.creditDebitIndicator == .debit)
    financeKitExpect(both.currencyCode == "USD")
    financeKitExpect(AccountBalance.ID.self == UUID.self)

    let availableOnly = AccountBalance(id: id, accountID: accountID, currentBalance: .available(available))
    financeKitExpect(availableOnly.available != nil)
    financeKitExpect(availableOnly.booked == nil)

    let bookedOnly = AccountBalance(id: id, accountID: accountID, currentBalance: .booked(booked))
    financeKitExpect(bookedOnly.available == nil)
    financeKitExpect(bookedOnly.booked != nil)
}

func testAssetAccountProperties() {
    let account = sampleAssetAccount()
    financeKitExpect(account.displayName == "Checking")
    financeKitExpect(account.accountDescription == "Primary")
    financeKitExpect(account.institutionName == "Example Bank")
    financeKitExpect(account.currencyCode == "USD")
    financeKitExpect(account.openingDate != nil)
    financeKitExpect(AssetAccount.ID.self == UUID.self)
}

func testLiabilityAccountProperties() {
    let account = sampleLiabilityAccount()
    financeKitExpect(account.displayName == "Card")
    financeKitExpect(account.creditInformation.creditLimit?.amount == Decimal(5000))
    financeKitExpect(account.openingDate == nil)
    financeKitExpect(LiabilityAccount.ID.self == UUID.self)
}

func testAccountComputedProperties() {
    let asset = Account.asset(sampleAssetAccount())
    let liability = Account.liability(sampleLiabilityAccount())
    financeKitExpect(asset.assetAccount?.displayName == "Checking")
    financeKitExpect(asset.liabilityAccount == nil)
    financeKitExpect(liability.liabilityAccount?.displayName == "Card")
    financeKitExpect(liability.assetAccount == nil)
    financeKitExpect(asset.displayName == "Checking")
    financeKitExpect(liability.institutionName == "Example Bank")
    financeKitExpect(asset.currencyCode == "USD")
    financeKitExpect(asset.accountDescription == "Primary")
    financeKitExpect(liability.openingDate == nil)
    financeKitExpect(Account.ID.self == UUID.self)
    financeKitExpect(asset.id != liability.id)
}

func testTransactionProperties() {
    let tx = sampleTransaction()
    financeKitExpect(tx.transactionDescription == "Coffee")
    financeKitExpect(tx.originalTransactionDescription == "COFFEE SHOP")
    financeKitExpect(tx.merchantName == "Cafe")
    financeKitExpect(tx.merchantCategoryCode?.rawValue == 5812)
    financeKitExpect(tx.transactionType == .pointOfSale)
    financeKitExpect(tx.status == .booked)
    financeKitExpect(tx.creditDebitIndicator == .debit)
    financeKitExpect(tx.foreignCurrencyAmount?.currencyCode == "EUR")
    financeKitExpect(tx.foreignCurrencyExchangeRate == Decimal(string: "1.08"))
    financeKitExpect(tx.postedDate != nil)
    financeKitExpect(Transaction.ID.self == UUID.self)
}

func testAccountCreditInformationProperties() {
    let info = sampleLiabilityAccount().creditInformation
    financeKitExpect(info.creditLimit?.currencyCode == "USD")
    financeKitExpect(info.nextPaymentDueDate != nil)
    financeKitExpect(info.minimumNextPaymentAmount?.amount == Decimal(25))
    financeKitExpect(info.overduePaymentAmount == nil)
}

func testMerchantCategoryCodeDescription() {
    let code = MerchantCategoryCode(rawValue: 5411)
    financeKitExpect(code.description == "5411")
}

func testMerchantCategoryCodeLosslessString() {
    financeKitExpect(MerchantCategoryCode("5812")?.rawValue == 5812)
    financeKitExpect(MerchantCategoryCode("not-a-code") == nil)
    financeKitExpect(MerchantCategoryCode("") == nil)
}

func testAccountEquality() {
    financeKitExpect(Account.asset(sampleAssetAccount()) == Account.asset(sampleAssetAccount()))
    financeKitExpect(Account.asset(sampleAssetAccount()) != Account.liability(sampleLiabilityAccount()))
}

func testTransactionEquality() {
    financeKitExpect(sampleTransaction() == sampleTransaction())
}

func testAccountBalanceEquality() {
    let id = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
    let accountID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    let lhs = AccountBalance(id: id, accountID: accountID, currentBalance: .available(sampleBalance()))
    let rhs = AccountBalance(id: id, accountID: accountID, currentBalance: .available(sampleBalance()))
    financeKitExpect(lhs == rhs)
}

func testAssetAccountEquality() {
    financeKitExpect(sampleAssetAccount() == sampleAssetAccount())
}

func testLiabilityAccountEquality() {
    financeKitExpect(sampleLiabilityAccount() == sampleLiabilityAccount())
}
