import Foundation

/// A picker that selects a collection of `FinanceKit.Transaction` values.
///
/// Darwin presents a system transaction sheet. Linux stores the selection
/// binding and label and never presents UI.
public struct TransactionPicker<Label: View>: View {
    public typealias Body = EmptyView

    let selection: Binding<[Transaction]>
    let label: Label

    /// Creates a transaction picker.
    ///
    /// Linux copies the current selection snapshot for host tests and does
    /// not present a sheet when the binding changes.
    public init(
        selection: Binding<[Transaction]>,
        @ViewBuilder label: () -> Label
    ) {
        self.selection = selection
        self.label = label()
        FinanceKitUIHostState.shared.recordPicker(
            isPresented: false,
            selectionCount: selection.wrappedValue.count
        )
    }

    /// Linux returns an empty view. The stored `label` is not rendered.
    public var body: EmptyView {
        EmptyView()
    }

    @_spi(OpenUIKitHost)
    public var hostSelectionCount: Int {
        selection.wrappedValue.count
    }

    @_spi(OpenUIKitHost)
    public var hostLabel: Label {
        label
    }
}

extension View {
    /// Presents a picker that selects a collection of transactions.
    ///
    /// Darwin shows the picker when `isPresented` is true. Linux records
    /// the presentation flag and selection count and returns `self`
    /// without presenting.
    public func transactionPicker(
        isPresented: Binding<Bool>,
        selection: Binding<[Transaction]>
    ) -> Self {
        FinanceKitUIHostState.shared.recordPicker(
            isPresented: isPresented.wrappedValue,
            selectionCount: selection.wrappedValue.count
        )
        return self
    }
}
