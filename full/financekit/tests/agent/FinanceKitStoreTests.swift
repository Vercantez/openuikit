import Foundation
import FinanceKit

func testFinanceStoreShared() {
    financeKitExpect(FinanceStore.shared === FinanceStore.shared)
}

func testIsDataAvailableFalse() {
    financeKitExpect(FinanceStore.isDataAvailable(.orders) == false)
    financeKitExpect(FinanceStore.isDataAvailable(.financialData) == false)
}

func testEnableBackgroundDeliveryNoOp() {
    FinanceStore.shared.enableBackgroundDelivery(
        for: [.accounts, .transactions],
        frequency: .hourly
    )
}

func testDisableBackgroundDeliveryNoOp() {
    FinanceStore.shared.disableBackgroundDelivery(for: [.accountBalances])
}

func testDisableAllBackgroundDeliveryNoOp() {
    FinanceStore.shared.disableAllBackgroundDelivery()
}

func testTransactionsMethodReference() {
    financeKitSink(FinanceStore.shared.transactions(query:))
    financeKitExpect(FinanceStore.isDataAvailable(.financialData) == false)
}

func testAccountsMethodReference() {
    financeKitSink(FinanceStore.shared.accounts(query:))
}

func testAccountBalancesMethodFailClosed() {
    financeKitSink(FinanceStore.shared.accountBalances(query:))
}

func testSaveOrderMethodFailClosed() {
    financeKitSink(FinanceStore.shared.saveOrder(signedArchive:))
    financeKitExpect(FinanceStore.isDataAvailable(.orders) == false)
}

func testContainsOrderMethodFailClosed() {
    financeKitSink(FinanceStore.shared.containsOrder(matching:updatedDate:))
}

func testAuthorizationStatusMethod() {
    financeKitSink(FinanceStore.shared.authorizationStatus)
}

func testRequestAuthorizationMethod() {
    financeKitSink(FinanceStore.shared.requestAuthorization)
}
