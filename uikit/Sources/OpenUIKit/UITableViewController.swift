// UITableViewController. Owner: tableview module (M10).
//
// UIKit's convenience controller: its view IS a UITableView, and the
// controller is the table's data source and delegate. Every protocol
// requirement is declared as an overridable method on the class (not left
// to the protocol-extension defaults) so subclass overrides are reached
// through the protocol witnesses — the classic Swift protocol-extension
// dispatch pitfall.

// Objective-C runtime name = UIKit's, and header macro SWIFT_CLASS_NAMED:
// Objective-C app classes may subclass it (vtable-free, see
// ObjCSubclassing.swift).
// `@objc` members (OPENUIKIT_OBJC_SUBCLASSING) need Foundation in scope; a
// scoped declaration import keeps its geometry out of this file (UIView.swift).
#if OPENUIKIT_OBJC_SUBCLASSING
import struct Foundation.Data
#endif

#if OPENUIKIT_OBJC_SUBCLASSING
@objc(UITableViewController)
#endif
@preconcurrency @MainActor
open class UITableViewController: UIViewController, UITableViewDataSource,
                                  UITableViewDelegate {
    final let style: UITableView.Style

    /// The controller's table (same object as `view`).
    public final var tableView: UITableView! {
        get { view as? UITableView }
        // iOS 26.1 (iososswallsprobe lens.tvc.*): assigning a table makes it
        // both `tableView` and `view`.
        set { view = newValue }
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    public dynamic init(style: UITableView.Style = .plain) {
        self.style = style
        super.init()
    }

    /// MEASURED `table.coder` (viewcontrollercoderprobe): an empty archive
    /// yields a plain-style, unloaded controller; the coder is not read.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    public required dynamic init?(coder: NSCoder) {
        style = .plain
        super.init(coder: coder)
    }

    open override func loadView() {
        // A storyboard table view controller's view is its view nib's table.
        if _loadStoryboardView() { return }
        let tv = UITableView(frame: CGRect(x: 0, y: 0, width: 390, height: 844),
                             style: style)
        tv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tv.dataSource = self
        tv.delegate = self
        view = tv
    }

    // MARK: UITableViewDataSource (override in subclasses)

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(numberOfSectionsInTableView:)
#endif
    open dynamic func numberOfSections(in tableView: UITableView) -> Int { 1 }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:cellForRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("UITableViewController subclasses must override tableView(_:cellForRowAt:)")
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        titleForHeaderInSection section: Int) -> String? { nil }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        titleForFooterInSection section: Int) -> String? { nil }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:canEditRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        canEditRowAt indexPath: IndexPath) -> Bool { true }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:editingStyleForRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        editingStyleForRowAt indexPath: IndexPath)
        -> UITableViewCell.EditingStyle { .delete }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:commitEditingStyle:forRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        commit editingStyle: UITableViewCell.EditingStyle,
                        forRowAt indexPath: IndexPath) {}

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:canMoveRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        canMoveRowAt indexPath: IndexPath) -> Bool { false }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:moveRowAtIndexPath:toIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        moveRowAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {}

    // MARK: UITableViewDelegate (override in subclasses)

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:heightForRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        heightForFooterInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:willDisplayCell:forRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                        forRowAt indexPath: IndexPath) {}

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        viewForHeaderInSection section: Int) -> UIView? { nil }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        viewForFooterInSection section: Int) -> UIView? { nil }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:didHighlightRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        didHighlightRowAt indexPath: IndexPath) {}

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:didUnhighlightRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                        didUnhighlightRowAt indexPath: IndexPath) {}

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:didSelectRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:didDeselectRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {}

    // NetNewsWire's settings / inspector / themes controllers override these.
    // Declared with UIKit's not-implemented answers; routing highlight,
    // context menus and indentation through them is OPEN in the port.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:shouldHighlightRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                                shouldHighlightRowAt indexPath: IndexPath) -> Bool { true }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:indentationLevelForRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                                indentationLevelForRowAt indexPath: IndexPath) -> Int { 0 }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:contextMenuConfigurationForRowAtIndexPath:point:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                                contextMenuConfigurationForRowAt indexPath: IndexPath,
                                point: CGPoint) -> UIContextMenuConfiguration? { nil }

    /// The swipe hooks the portable table view already asks its delegate for
    /// (UITableViewDelegate); declared here so a subclass can `override`.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:leadingSwipeActionsConfigurationForRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                                leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? { nil }
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(tableView:trailingSwipeActionsConfigurationForRowAtIndexPath:)
#endif
    open dynamic func tableView(_ tableView: UITableView,
                                trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? { nil }

    // MARK: UIScrollViewDelegate (override in subclasses)

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func scrollViewDidScroll(_ scrollView: UIScrollView) {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc
#endif
    open dynamic func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
}
