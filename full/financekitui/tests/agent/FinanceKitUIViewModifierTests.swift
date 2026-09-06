import Foundation
@_spi(OpenUIKitHost) import FinanceKitUI

func testViewTransactionPicker() {
    FinanceKitUIHostControl.reset()
    var presented = true
    var selection = [Transaction(id: UUID())]
    let view = EmptyView().transactionPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { selection }, set: { selection = $0 })
    )
    precondition(type(of: view) == EmptyView.self)
    precondition(FinanceKitUIHostControl.lastTransactionPickerPresented() == true)
    precondition(FinanceKitUIHostControl.lastTransactionPickerSelectionCount() == 1)
    precondition(presented == true)
}

func testTransactionPickerTransactionPickerModifier() {
    FinanceKitUIHostControl.reset()
    var selected: [Transaction] = []
    var presented = false
    let picker = TransactionPicker(
        selection: Binding(get: { selected }, set: { selected = $0 }),
        label: { EmptyView() }
    )
    let modified = picker.transactionPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { selected }, set: { selected = $0 })
    )
    precondition(type(of: modified) == TransactionPicker<EmptyView>.self)
    precondition(FinanceKitUIHostControl.lastTransactionPickerPresented() == false)
    precondition(FinanceKitUIHostControl.lastTransactionPickerSelectionCount() == 0)
}

func testAddOrderToWalletButtonTransactionPickerModifier() {
    FinanceKitUIHostControl.reset()
    var presented = true
    var selection = [Transaction(), Transaction()]
    let button = AddOrderToWalletButton(signedArchive: Data(), onCompletion: { _ in })
    let modified = button.transactionPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { selection }, set: { selection = $0 })
    )
    precondition(type(of: modified) == AddOrderToWalletButton.self)
    precondition(FinanceKitUIHostControl.lastTransactionPickerPresented() == true)
    precondition(FinanceKitUIHostControl.lastTransactionPickerSelectionCount() == 2)
}

func testViewAddOrderToWalletButtonStyle() {
    FinanceKitUIHostControl.reset()
    let styled = EmptyView().addOrderToWalletButtonStyle(.black)
    precondition(type(of: styled) == EmptyView.self)
    precondition(FinanceKitUIHostControl.lastWalletStyle() == .black)
}

func testTransactionPickerAddOrderToWalletButtonStyle() {
    FinanceKitUIHostControl.reset()
    var selected: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { selected }, set: { selected = $0 }),
        label: { EmptyView() }
    )
    let styled = picker.addOrderToWalletButtonStyle(.blackOutline)
    precondition(type(of: styled) == TransactionPicker<EmptyView>.self)
    precondition(FinanceKitUIHostControl.lastWalletStyle() == .blackOutline)
}

func testAddOrderToWalletButtonAddOrderToWalletButtonStyle() {
    FinanceKitUIHostControl.reset()
    let button = AddOrderToWalletButton(signedArchive: Data([0x02]), onCompletion: { _ in })
    let styled = button.addOrderToWalletButtonStyle(.black)
    precondition(type(of: styled) == AddOrderToWalletButton.self)
    precondition(FinanceKitUIHostControl.lastWalletStyle() == .black)
    precondition(FinanceKitUIHostControl.lastWalletArchive() == Data([0x02]))
}
