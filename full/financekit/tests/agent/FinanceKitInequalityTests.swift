import Foundation
import FinanceKit

func testSynthesizedInequalityOperators() {
    financeKitExpect(FinanceError.unknown != FinanceError.historyTokenInvalid)
    financeKitExpect(FinanceStore.SaveOrderResult.added != .cancelled)
    financeKitExpect(FinanceStore.UpdateFrequency.hourly != .weekly)
    financeKitExpect(FinanceStore.BackgroundDataType.accounts != .transactions)
    financeKitExpect(FinanceStore.ContainsOrderResult.exists != .notFound)
    financeKitExpect(FinanceStore.DataType.orders != .financialData)
    financeKitExpect(sampleTransaction() != Transaction(
        id: UUID(),
        accountID: sampleTransaction().accountID,
        transactionAmount: sampleCurrencyAmount(),
        creditDebitIndicator: .credit,
        transactionDescription: "Other",
        originalTransactionDescription: "OTHER",
        transactionType: .unknown,
        status: .pending,
        transactionDate: Date(timeIntervalSince1970: 0)
    ))
    financeKitExpect(sampleAssetAccount() != AssetAccount(
        id: UUID(),
        displayName: "Other",
        institutionName: "X",
        currencyCode: "EUR"
    ))
    let id = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
    let accountID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    financeKitExpect(
        AccountBalance(id: id, accountID: accountID, currentBalance: .available(sampleBalance()))
            != AccountBalance(id: UUID(), accountID: accountID, currentBalance: .available(sampleBalance()))
    )
    financeKitExpect(sampleCurrencyAmount() != CurrencyAmount(amount: 0, currencyCode: "USD"))
    financeKitExpect(CurrentBalance.available(sampleBalance()) != .booked(sampleBalance()))
    financeKitExpect(TransactionType.atm != .fee)
    financeKitExpect(sampleLiabilityAccount() != LiabilityAccount(
        id: UUID(),
        displayName: "Other",
        institutionName: "X",
        currencyCode: "USD",
        creditInformation: AccountCreditInformation()
    ))
    financeKitExpect(TransactionStatus.pending != .booked)
    financeKitExpect(AuthorizationStatus.denied != .authorized)
    financeKitExpect(CreditDebitIndicator.credit != .debit)
    financeKitExpect(MerchantCategoryCode(rawValue: 1) != MerchantCategoryCode(rawValue: 2))
    financeKitExpect(
        sampleLiabilityAccount().creditInformation
            != AccountCreditInformation(creditLimit: sampleCurrencyAmount())
    )
    financeKitExpect(
        FullyQualifiedOrderIdentifier(orderTypeIdentifier: "a", orderIdentifier: "1")
            != FullyQualifiedOrderIdentifier(orderTypeIdentifier: "a", orderIdentifier: "2")
    )
    financeKitExpect(Account.asset(sampleAssetAccount()) != Account.liability(sampleLiabilityAccount()))
    financeKitExpect(sampleBalance() != sampleBalance(indicator: .debit))
}
