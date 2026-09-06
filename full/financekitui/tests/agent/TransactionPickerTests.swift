import Foundation
@_spi(OpenUIKitHost) import FinanceKitUI

func testTransactionPickerStruct() {
    FinanceKitUIHostControl.reset()
    var selected: [Transaction] = []
    let picker = TransactionPicker(
        selection: Binding(get: { selected }, set: { selected = $0 }),
        label: { EmptyView() }
    )
    let asView: any View = picker
    _ = asView
    precondition(picker.hostSelectionCount == 0)
    precondition(FinanceKitUIHostControl.lastTransactionPickerSelectionCount() == 0)
}

func testTransactionPickerBodyTypealias() {
    precondition(TransactionPicker<EmptyView>.Body.self == EmptyView.self)
}

func testTransactionPickerBody() {
    var selected = [Transaction(id: UUID())]
    let picker = TransactionPicker(
        selection: Binding(get: { selected }, set: { selected = $0 }),
        label: { EmptyView() }
    )
    let body = picker.body
    precondition(type(of: body) == EmptyView.self)
    precondition(picker.hostSelectionCount == 1)
}

func testTransactionPickerInitSelectionLabel() {
    FinanceKitUIHostControl.reset()
    let first = Transaction(id: UUID())
    let second = Transaction(id: UUID())
    var selected = [first, second]
    let picker = TransactionPicker(
        selection: Binding(get: { selected }, set: { selected = $0 }),
        label: { EmptyView() }
    )
    precondition(picker.hostSelectionCount == 2)
    precondition(FinanceKitUIHostControl.lastTransactionPickerSelectionCount() == 2)
    selected = [first]
    precondition(picker.hostSelectionCount == 1)
}
