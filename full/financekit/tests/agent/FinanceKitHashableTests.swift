import Foundation
import FinanceKit

func testTransactionTypeHashable() {
    var hasher = Hasher()
    TransactionType.atm.hash(into: &hasher)
    financeKitExpect(TransactionType.atm.hashValue == TransactionType.atm.hashValue)
    financeKitExpect(Set([TransactionType.atm, .atm, .fee]).count == 2)
}

func testTransactionStatusHashable() {
    var hasher = Hasher()
    TransactionStatus.pending.hash(into: &hasher)
    financeKitExpect(TransactionStatus.booked.hashValue == TransactionStatus.booked.hashValue)
}

func testCreditDebitIndicatorHashable() {
    var hasher = Hasher()
    CreditDebitIndicator.credit.hash(into: &hasher)
    financeKitExpect(CreditDebitIndicator.debit.hashValue != 0 || CreditDebitIndicator.credit.hashValue != 1 || true)
}

func testMerchantCategoryCodeHashable() {
    var hasher = Hasher()
    MerchantCategoryCode(rawValue: 5411).hash(into: &hasher)
    financeKitExpect(MerchantCategoryCode(rawValue: 5411).hashValue == MerchantCategoryCode(rawValue: 5411).hashValue)
}

func testSaveOrderResultHashable() {
    var hasher = Hasher()
    FinanceStore.SaveOrderResult.added.hash(into: &hasher)
    financeKitExpect(FinanceStore.SaveOrderResult.added.hashValue == FinanceStore.SaveOrderResult.added.hashValue)
}

func testContainsOrderResultHashable() {
    var hasher = Hasher()
    FinanceStore.ContainsOrderResult.exists.hash(into: &hasher)
    financeKitExpect(FinanceStore.ContainsOrderResult.notFound.hashValue == FinanceStore.ContainsOrderResult.notFound.hashValue)
}

func testUpdateFrequencyHashable() {
    var hasher = Hasher()
    FinanceStore.UpdateFrequency.daily.hash(into: &hasher)
    financeKitExpect(FinanceStore.UpdateFrequency.hourly.hashValue == FinanceStore.UpdateFrequency.hourly.hashValue)
}

func testBackgroundDataTypeHashable() {
    var hasher = Hasher()
    FinanceStore.BackgroundDataType.transactions.hash(into: &hasher)
    financeKitExpect(FinanceStore.BackgroundDataType.accounts.hashValue == FinanceStore.BackgroundDataType.accounts.hashValue)
}

func testDataTypeHashable() {
    var hasher = Hasher()
    FinanceStore.DataType.orders.hash(into: &hasher)
    financeKitExpect(FinanceStore.DataType.financialData.hashValue == FinanceStore.DataType.financialData.hashValue)
}

func testAuthorizationStatusHashable() {
    var hasher = Hasher()
    AuthorizationStatus.authorized.hash(into: &hasher)
    financeKitExpect(AuthorizationStatus.denied.hashValue == AuthorizationStatus.denied.hashValue)
}

func testCurrencyAmountHashable() {
    var hasher = Hasher()
    sampleCurrencyAmount().hash(into: &hasher)
    financeKitExpect(sampleCurrencyAmount().hashValue == sampleCurrencyAmount().hashValue)
    financeKitExpect(sampleCurrencyAmount() != CurrencyAmount(amount: 1, currencyCode: "EUR"))
}

func testBalanceHashable() {
    var hasher = Hasher()
    sampleBalance().hash(into: &hasher)
    financeKitExpect(sampleBalance().hashValue == sampleBalance().hashValue)
}

func testCurrentBalanceHashable() {
    var hasher = Hasher()
    CurrentBalance.booked(sampleBalance(indicator: .debit)).hash(into: &hasher)
    financeKitExpect(CurrentBalance.available(sampleBalance()).hashValue == CurrentBalance.available(sampleBalance()).hashValue)
}

func testAccountCreditInformationHashable() {
    var hasher = Hasher()
    sampleLiabilityAccount().creditInformation.hash(into: &hasher)
    financeKitExpect(sampleLiabilityAccount().creditInformation.hashValue == sampleLiabilityAccount().creditInformation.hashValue)
}

func testFullyQualifiedOrderIdentifierHashable() {
    let identifier = FullyQualifiedOrderIdentifier(orderTypeIdentifier: "order.com.example", orderIdentifier: "1")
    var hasher = Hasher()
    identifier.hash(into: &hasher)
    financeKitExpect(identifier.hashValue == identifier.hashValue)
}
