import Foundation
import FinanceKit

func testAccountQueryInit() {
    let empty = AccountQuery()
    financeKitExpect(empty.sortDescriptors.isEmpty)
    financeKitExpect(empty.predicate == nil)
    financeKitExpect(empty.limit == nil)
    financeKitExpect(empty.offset == nil)
    let sorted = AccountQuery(
        sortDescriptors: [SortDescriptor(\Account.displayName)],
        limit: 10,
        offset: 2
    )
    financeKitExpect(sorted.limit == 10)
    financeKitExpect(sorted.offset == 2)
    financeKitExpect(sorted.sortDescriptors.count == 1)
}

func testTransactionQueryInit() {
    let query = TransactionQuery(
        sortDescriptors: [SortDescriptor(\Transaction.transactionDate, order: .reverse)],
        predicate: TransactionQuery.predicate(forStatuses: [.booked]),
        limit: 5,
        offset: 1
    )
    financeKitExpect(query.limit == 5)
    financeKitExpect(query.offset == 1)
    financeKitExpect(query.predicate != nil)
}

func testAccountBalanceQueryInit() {
    let query = AccountBalanceQuery(limit: 3)
    financeKitExpect(query.limit == 3)
    financeKitExpect(query.offset == nil)
    financeKitExpect(query.sortDescriptors.isEmpty)
}

func testTransactionQueryPredicateForStatuses() {
    let predicate = TransactionQuery.predicate(forStatuses: [.booked, .pending])
    financeKitSink(predicate)
}

func testTransactionQueryPredicateForTypes() {
    let predicate = TransactionQuery.predicate(forTransactionTypes: [.atm, .pointOfSale])
    financeKitSink(predicate)
}

func testTransactionQueryPredicateForMCC() {
    let predicate = TransactionQuery.predicate(
        forMerchantCategoryCodes: [MerchantCategoryCode(rawValue: 5411)]
    )
    financeKitSink(predicate)
}

func testAccountBalanceQueryPredicateBooked() {
    let start = Date(timeIntervalSince1970: 1_600_000_000)
    let predicate = AccountBalanceQuery.predicate(bookedSince: start, until: Date())
    financeKitSink(predicate)
    let openEnded = AccountBalanceQuery.predicate(bookedSince: start)
    financeKitSink(openEnded)
}

func testAccountBalanceQueryPredicateAvailable() {
    let start = Date(timeIntervalSince1970: 1_600_000_000)
    let predicate = AccountBalanceQuery.predicate(availableSince: start, until: nil)
    financeKitSink(predicate)
}
