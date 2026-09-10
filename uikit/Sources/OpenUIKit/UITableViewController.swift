// UITableViewController. Owner: tableview module (M10).
//
// UIKit's convenience controller: its view IS a UITableView, and the
// controller is the table's data source and delegate. Every protocol
// requirement is declared as an overridable method on the class (not left
// to the protocol-extension defaults) so subclass overrides are reached
// through the protocol witnesses — the classic Swift protocol-extension
// dispatch pitfall.

@preconcurrency @MainActor
open class UITableViewController: UIViewController, UITableViewDataSource,
                                  UITableViewDelegate {
    let style: UITableView.Style

    /// The controller's table (same object as `view`).
    public var tableView: UITableView! {
        view as? UITableView
    }

    public init(style: UITableView.Style = .plain) {
        self.style = style
        super.init()
    }

    /// MEASURED `table.coder` (viewcontrollercoderprobe): an empty archive
    /// yields a plain-style, unloaded controller; the coder is not read.
    public required init?(coder: NSCoder) {
        style = .plain
        super.init(coder: coder)
    }

    open override func loadView() {
        let tv = UITableView(frame: CGRect(x: 0, y: 0, width: 390, height: 844),
                             style: style)
        tv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tv.dataSource = self
        tv.delegate = self
        view = tv
    }

    // MARK: UITableViewDataSource (override in subclasses)

    open func numberOfSections(in tableView: UITableView) -> Int { 1 }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

    open func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("UITableViewController subclasses must override tableView(_:cellForRowAt:)")
    }

    open func tableView(_ tableView: UITableView,
                        titleForHeaderInSection section: Int) -> String? { nil }

    open func tableView(_ tableView: UITableView,
                        titleForFooterInSection section: Int) -> String? { nil }

    open func tableView(_ tableView: UITableView,
                        canEditRowAt indexPath: IndexPath) -> Bool { true }

    open func tableView(_ tableView: UITableView,
                        editingStyleForRowAt indexPath: IndexPath)
        -> UITableViewCell.EditingStyle { .delete }

    open func tableView(_ tableView: UITableView,
                        commit editingStyle: UITableViewCell.EditingStyle,
                        forRowAt indexPath: IndexPath) {}

    open func tableView(_ tableView: UITableView,
                        canMoveRowAt indexPath: IndexPath) -> Bool { false }

    open func tableView(_ tableView: UITableView,
                        moveRowAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {}

    // MARK: UITableViewDelegate (override in subclasses)

    open func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    open func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    open func tableView(_ tableView: UITableView,
                        heightForFooterInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                        forRowAt indexPath: IndexPath) {}

    open func tableView(_ tableView: UITableView,
                        viewForHeaderInSection section: Int) -> UIView? { nil }

    open func tableView(_ tableView: UITableView,
                        viewForFooterInSection section: Int) -> UIView? { nil }

    open func tableView(_ tableView: UITableView,
                        didHighlightRowAt indexPath: IndexPath) {}

    open func tableView(_ tableView: UITableView,
                        didUnhighlightRowAt indexPath: IndexPath) {}

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {}

    // MARK: UIScrollViewDelegate (override in subclasses)

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {}
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {}
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {}
    open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
}
