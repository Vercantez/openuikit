import Foundation
import FinanceKit

func testTransactionTypeRawValues() {
    let expected: [(TransactionType, Int16)] = [
        (.unknown, 0),
        (.adjustment, 1),
        (.atm, 2),
        (.billPayment, 3),
        (.check, 4),
        (.deposit, 5),
        (.directDeposit, 6),
        (.dividend, 7),
        (.fee, 8),
        (.interest, 9),
        (.pointOfSale, 10),
        (.transfer, 11),
        (.withdrawal, 12),
        (.standingOrder, 13),
        (.directDebit, 14),
        (.loan, 15),
        (.refund, 16),
    ]
    financeKitExpect(TransactionType.allCases.count == expected.count)
    financeKitExpect(TransactionType.AllCases.self == [TransactionType].self)
    for (value, raw) in expected {
        financeKitExpect(value.rawValue == raw)
        financeKitExpect(TransactionType(rawValue: raw) == value)
    }
    financeKitExpect(TransactionType(rawValue: 99) == nil)
    financeKitExpect(Set(TransactionType.allCases).count == expected.count)
}

func testTransactionStatusRawValues() {
    let expected: [(TransactionStatus, Int16)] = [
        (.authorized, 0),
        (.memo, 1),
        (.pending, 2),
        (.booked, 3),
        (.rejected, 4),
    ]
    financeKitExpect(TransactionStatus.allCases.count == expected.count)
    financeKitExpect(TransactionStatus.AllCases.self == [TransactionStatus].self)
    for (value, raw) in expected {
        financeKitExpect(value.rawValue == raw)
        financeKitExpect(TransactionStatus(rawValue: raw) == value)
    }
    financeKitExpect(TransactionStatus(rawValue: 8) == nil)
}

func testCreditDebitIndicatorRawValues() {
    financeKitExpect(CreditDebitIndicator.credit.rawValue == 0)
    financeKitExpect(CreditDebitIndicator.debit.rawValue == 1)
    financeKitExpect(CreditDebitIndicator(rawValue: 0) == .credit)
    financeKitExpect(CreditDebitIndicator(rawValue: 1) == .debit)
    financeKitExpect(CreditDebitIndicator(rawValue: 2) == nil)
    financeKitExpect(CreditDebitIndicator.allCases == [.credit, .debit])
    financeKitExpect(CreditDebitIndicator.AllCases.self == [CreditDebitIndicator].self)
}

func testMerchantCategoryCodeRawValue() {
    let grocery = MerchantCategoryCode(rawValue: 5411)
    financeKitExpect(grocery.rawValue == 5411)
    financeKitExpect(MerchantCategoryCode.RawValue.self == Int16.self)
}

func testSaveOrderResultAllCases() {
    financeKitExpect(
        FinanceStore.SaveOrderResult.allCases == [.added, .cancelled, .newerExisting]
    )
    financeKitExpect(FinanceStore.SaveOrderResult.AllCases.self == [FinanceStore.SaveOrderResult].self)
    financeKitSink(FinanceStore.SaveOrderResult.added)
    financeKitSink(FinanceStore.SaveOrderResult.cancelled)
    financeKitSink(FinanceStore.SaveOrderResult.newerExisting)
}

func testContainsOrderResultAllCases() {
    financeKitExpect(
        FinanceStore.ContainsOrderResult.allCases == [.exists, .notFound, .newerExists, .olderExists]
    )
    financeKitExpect(FinanceStore.ContainsOrderResult.AllCases.self == [FinanceStore.ContainsOrderResult].self)
    financeKitSink(FinanceStore.ContainsOrderResult.exists)
    financeKitSink(FinanceStore.ContainsOrderResult.notFound)
    financeKitSink(FinanceStore.ContainsOrderResult.newerExists)
    financeKitSink(FinanceStore.ContainsOrderResult.olderExists)
}

func testUpdateFrequencyCases() {
    financeKitSink(FinanceStore.UpdateFrequency.hourly)
    financeKitSink(FinanceStore.UpdateFrequency.daily)
    financeKitSink(FinanceStore.UpdateFrequency.weekly)
    financeKitExpect(FinanceStore.UpdateFrequency.hourly != FinanceStore.UpdateFrequency.daily)
}

func testBackgroundDataTypeCases() {
    financeKitSink(FinanceStore.BackgroundDataType.accounts)
    financeKitSink(FinanceStore.BackgroundDataType.accountBalances)
    financeKitSink(FinanceStore.BackgroundDataType.transactions)
    financeKitExpect(FinanceStore.BackgroundDataType.accounts != .transactions)
}

func testDataTypeCases() {
    financeKitSink(FinanceStore.DataType.orders)
    financeKitSink(FinanceStore.DataType.financialData)
    financeKitExpect(FinanceStore.DataType.orders != .financialData)
}

func testAuthorizationStatusCases() {
    financeKitSink(AuthorizationStatus.notDetermined)
    financeKitSink(AuthorizationStatus.denied)
    financeKitSink(AuthorizationStatus.authorized)
    financeKitExpect(AuthorizationStatus.denied != .authorized)
}
