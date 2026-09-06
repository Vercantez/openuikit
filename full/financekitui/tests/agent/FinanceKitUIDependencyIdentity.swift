import FinanceKitUI
import Foundation
import FinanceKit
import UIKit
@_spi(OpenUIKitHost) import FinanceKitUI

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest FinanceKit/UIKit
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest FinanceKit, Foundation, UIKit (and their dylibs).
// 2. Build FinanceKitUI with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports FinanceKitUI and every dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `FINANCEKITUI_DEPENDENCY_IDENTITY_OK` and that
//    `libFinanceKitUI.dylib` was loaded.

private func assertNotFinanceKitUIType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("FinanceKitUI."))
}

func assertFoundationIdentity() {
    let archive = Data([0x4f, 0x4b])
    assertNotFinanceKitUIType(archive)
    var invoked = false
    let button = AddOrderToWalletButton(signedArchive: archive) { _ in
        invoked = true
    }
    precondition(button.hostArchive == archive)
    precondition(!invoked)
    _ = Foundation.UUID.self
    _ = Foundation.JSONEncoder.self
}

func assertUIKitIdentity() {
    let presenter = UIViewController()
    assertNotFinanceKitUIType(presenter)
    presenter.title = "financekitui-host"
    precondition(presenter.title == "financekitui-host")
}

func assertFinanceKitIdentity() {
    let transaction = Transaction(
        id: UUID(),
        accountID: UUID(),
        transactionAmount: CurrencyAmount(amount: 1, currencyCode: "USD"),
        creditDebitIndicator: .credit,
        transactionDescription: "probe",
        originalTransactionDescription: "probe",
        transactionType: .unknown,
        status: .booked,
        transactionDate: Date()
    )
    assertNotFinanceKitUIType(transaction)
    var selected = [transaction]
    let picker = TransactionPicker(
        selection: Binding(get: { selected }, set: { selected = $0 }),
        label: { EmptyView() }
    )
    precondition(picker.hostSelectionCount == 1)
    _ = FinanceStore.SaveOrderResult.added
    _ = FinanceStore.shared
}

func financeKitUIDependencyIdentityMain() {
    assertFoundationIdentity()
    assertUIKitIdentity()
    assertFinanceKitIdentity()
    print("FINANCEKITUI_DEPENDENCY_IDENTITY_OK")
}
