import FinanceKit
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build FinanceKit with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that `import`s FinanceKit and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm Foundation Date / Decimal / UUID / Data values round-trip through
//    public FinanceKit APIs without framework-local stand-ins.

private func assertNotFinanceKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("FinanceKit."))
}

func financeKitDependencyIdentityMain() {
    let amount = Decimal(string: "19.99")!
    assertNotFinanceKitType(amount)
    precondition(type(of: amount) == Decimal.self)

    let date = Date(timeIntervalSince1970: 1_700_000_000)
    assertNotFinanceKitType(date)

    let identifier = UUID()
    assertNotFinanceKitType(identifier)

    let payload = Data("order-archive".utf8)
    assertNotFinanceKitType(payload)

    let currency = CurrencyAmount(amount: amount, currencyCode: "USD")
    precondition(currency.amount == amount)
    assertNotFinanceKitType(currency.amount)

    let balance = Balance(amount: currency, asOfDate: date, creditDebitIndicator: .credit)
    precondition(balance.asOfDate == date)

    let query = TransactionQuery(limit: 1)
    _ = query.limit

    _ = FinanceStore.isDataAvailable(.orders)
    _ = payload.count
}

financeKitDependencyIdentityMain()
