import Foundation
import FinanceKit

func testAccountHistoryConstruction() {
    let history = FinanceStore.shared.accountHistory()
    financeKitSink(history)
    let withToken = FinanceStore.shared.accountHistory(since: nil, isMonitoring: false)
    financeKitSink(withToken)
}

func testTransactionHistoryConstruction() {
    let history = FinanceStore.shared.transactionHistory(
        forAccountID: UUID(),
        since: nil,
        isMonitoring: false
    )
    financeKitSink(history)
}

func testAccountBalanceHistoryConstruction() {
    let history = FinanceStore.shared.accountBalanceHistory(forAccountID: UUID())
    financeKitSink(history)
}

func testHistoryMakeAsyncIterator() {
    let iterator = FinanceStore.shared.accountHistory().makeAsyncIterator()
    financeKitSink(iterator)
}

func testHistoryElementTypealias() {
    financeKitExpect(FinanceStore.History<Account>.Element.self == FinanceStore.Changes<Account>.self)
}

func testHistoryAsyncIteratorTypealias() {
    financeKitExpect(
        FinanceStore.History<Account>.AsyncIterator.self == FinanceStore.History<Account>.Iterator.self
    )
}

func testHistoryIteratorElement() {
    financeKitExpect(
        FinanceStore.History<Transaction>.Iterator.Element.self == FinanceStore.Changes<Transaction>.self
    )
}

func testHistoryIteratorNextReference() {
    let iterator = FinanceStore.shared.accountHistory().makeAsyncIterator()
    financeKitSink(iterator.next)
}

func testHistoryMap() {
    let mapped = FinanceStore.shared.accountHistory().map { $0.inserted.count }
    financeKitSink(mapped)
}

func testHistoryThrowingMap() {
    let mapped = FinanceStore.shared.accountHistory().map { (changes) async throws in
        changes.updated.count
    }
    financeKitSink(mapped)
}

func testHistoryCompactMap() {
    let mapped = FinanceStore.shared.transactionHistory(forAccountID: UUID()).compactMap {
        $0.inserted.first
    }
    financeKitSink(mapped)
}

func testHistoryThrowingCompactMap() {
    let mapped = FinanceStore.shared.accountBalanceHistory(forAccountID: UUID()).compactMap {
        (changes) async throws in changes.inserted.first
    }
    financeKitSink(mapped)
}

func testHistoryFilter() {
    let filtered = FinanceStore.shared.accountHistory().filter { !$0.deleted.isEmpty }
    financeKitSink(filtered)
}

func testHistoryDropWhile() {
    let dropped = FinanceStore.shared.accountHistory().drop(while: { $0.inserted.isEmpty })
    financeKitSink(dropped)
}

func testHistoryDropFirst() {
    let dropped = FinanceStore.shared.accountHistory().dropFirst(2)
    financeKitSink(dropped)
}

func testHistoryPrefix() {
    let prefixed = FinanceStore.shared.accountHistory().prefix(1)
    financeKitSink(prefixed)
}

func testHistoryPrefixWhile() {
    financeKitSink(FinanceStore.shared.accountHistory().prefix(while:))
}

func testHistoryFlatMapNeverFailure() {
    let flattened = FinanceStore.shared.accountHistory().flatMap { _ -> AsyncStream<Int> in
        AsyncStream { continuation in
            continuation.finish()
        }
    }
    financeKitSink(flattened)
}

func testHistoryFlatMapSameFailure() {
    let flattened = FinanceStore.shared.accountHistory().flatMap { _ -> AsyncThrowingStream<Int, Error> in
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
    financeKitSink(flattened)
}

func testHistoryFlatMapThrowing() {
    let flattened = FinanceStore.shared.accountHistory().flatMap { _ -> AsyncThrowingStream<Int, Error> in
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: FinanceError.unknown)
        }
    }
    financeKitSink(flattened)
}

func testHistoryFlatMapNeverNever() {
    // History.next() throws, so the Failure == Never overlay is not callable.
    // The identifier remains declared; this test keeps the History AsyncSequence
    // surface loadable.
    financeKitSink(FinanceStore.shared.accountHistory())
}

func testChangesProperties() {
    let tokenData = try! JSONEncoder().encode(Data([0x01]))
    let token = try! JSONDecoder().decode(FinanceStore.HistoryToken.self, from: tokenData)
    let changes = FinanceStore.Changes<Account>(
        inserted: [Account.asset(sampleAssetAccount())],
        updated: [],
        deleted: [],
        newToken: token
    )
    financeKitExpect(changes.inserted.count == 1)
    financeKitExpect(changes.updated.isEmpty)
    financeKitExpect(changes.deleted.isEmpty)
    financeKitSink(changes.newToken)
}

func testHistoryIteratorNextIsolation() {
    let call = { (iterator: inout FinanceStore.History<Account>.Iterator) async throws in
        _ = try await iterator.next(isolation: nil)
    }
    financeKitSink(call)
}

func testHistoryAllSatisfy() {
    financeKitSink(FinanceStore.shared.accountHistory().allSatisfy)
}

func testHistoryFirstWhere() {
    financeKitSink(FinanceStore.shared.accountHistory().first(where:))
}

func testHistoryContainsWhere() {
    financeKitSink(FinanceStore.shared.accountHistory().contains(where:))
}

func testHistoryMax() {
    let history = FinanceStore.shared.accountHistory()
    let call = {
        try await history.max(by: { _, _ in true })
    }
    financeKitSink(call)
}

func testHistoryMin() {
    let history = FinanceStore.shared.accountHistory()
    let call = {
        try await history.min(by: { _, _ in false })
    }
    financeKitSink(call)
}

func testHistoryReduce() {
    let history = FinanceStore.shared.accountHistory()
    let fn: (Int, (Int, FinanceStore.Changes<Account>) async throws -> Int) async throws -> Int =
        history.reduce
    financeKitSink(fn)
}

func testHistoryReduceInto() {
    let history = FinanceStore.shared.accountHistory()
    let fn: (Int, (inout Int, FinanceStore.Changes<Account>) async throws -> Void) async throws -> Int =
        history.reduce(into:_:)
    financeKitSink(fn)
}
