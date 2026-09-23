// How OpenUIKit itself calls UIKit's delegate / data-source protocols.
//
// On the Apple toolchain (OPENUIKIT_OBJC_SUBCLASSING) the protocols are UIKit's
// `@objc` protocols with `optional` requirements, so every call is
// `delegate.method?(…)`: an unimplemented optional method is not called, and
// the caller uses UIKit's behaviour for "absent" (the value in the `??`
// below). On Linux ELF and the Foundation-hidden guest the protocols are Swift
// protocols whose default implementations return that same value. Both builds
// call through these helpers, so each call site is written once and the two
// builds agree wherever a delegate does not implement a method.
//
// The "absent" values are the ones OpenUIKit's default implementations have
// always returned; Tests/ObjCProtocolTests checks the ones UIKit's behaviour
// depends on against the iOS 26.1 simulator (Tools/oracle2/objcprotocolprobe).

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
#elseif canImport(Foundation)
import Foundation
#endif
#if OPENUIKIT_OBJC_SUBCLASSING
import struct Foundation.Data
#endif

#if OPENUIKIT_OBJC_SUBCLASSING

extension UIScrollViewDelegate {
    func _didScroll(_ s: UIScrollView) { scrollViewDidScroll?(s) }
    func _didZoom(_ s: UIScrollView) { scrollViewDidZoom?(s) }
    func _willBeginDragging(_ s: UIScrollView) { scrollViewWillBeginDragging?(s) }
    func _willEndDragging(_ s: UIScrollView, velocity: CGPoint, targetContentOffset target: UnsafeMutablePointer<CGPoint>) {
        scrollViewWillEndDragging?(s, withVelocity: velocity, targetContentOffset: target)
    }
    func _didEndDragging(_ s: UIScrollView, willDecelerate: Bool) {
        scrollViewDidEndDragging?(s, willDecelerate: willDecelerate)
    }
    func _willBeginDecelerating(_ s: UIScrollView) { scrollViewWillBeginDecelerating?(s) }
    func _didEndDecelerating(_ s: UIScrollView) { scrollViewDidEndDecelerating?(s) }
    func _didEndScrollingAnimation(_ s: UIScrollView) { scrollViewDidEndScrollingAnimation?(s) }
    func _viewForZooming(_ s: UIScrollView) -> UIView? { viewForZooming?(in: s) ?? nil }
    func _willBeginZooming(_ s: UIScrollView, with view: UIView?) { scrollViewWillBeginZooming?(s, with: view) }
    func _didEndZooming(_ s: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollViewDidEndZooming?(s, with: view, atScale: scale)
    }
    func _didChangeAdjustedContentInset(_ s: UIScrollView) { scrollViewDidChangeAdjustedContentInset?(s) }
}

extension UITableViewDataSource {
    func _numberOfSections(_ t: UITableView) -> Int { numberOfSections?(in: t) ?? 1 }
    func _titleForHeader(_ t: UITableView, _ s: Int) -> String? { tableView?(t, titleForHeaderInSection: s) ?? nil }
    func _titleForFooter(_ t: UITableView, _ s: Int) -> String? { tableView?(t, titleForFooterInSection: s) ?? nil }
    func _canEdit(_ t: UITableView, _ p: IndexPath) -> Bool { tableView?(t, canEditRowAt: p) ?? true }
    func _canMove(_ t: UITableView, _ p: IndexPath) -> Bool { tableView?(t, canMoveRowAt: p) ?? false }
    func _commit(_ t: UITableView, _ style: UITableViewCell.EditingStyle, _ p: IndexPath) {
        tableView?(t, commit: style, forRowAt: p)
    }
    func _moveRow(_ t: UITableView, _ from: IndexPath, _ to: IndexPath) { tableView?(t, moveRowAt: from, to: to) }
}

extension UITableViewDelegate {
    /// nil when the delegate does not implement the method. A delegate that
    /// implements it and answers `automaticDimension` self-sizes the row
    /// even when `rowHeight` is fixed (iOS 26.1, objcprotocolprobe
    /// "rowHeight 70, heightForRow 60/automatic/50": row 1 is 52).
    func _heightForRow(_ t: UITableView, _ p: IndexPath) -> CGFloat? {
        tableView?(t, heightForRowAt: p)
    }
    func _heightForHeader(_ t: UITableView, _ s: Int) -> CGFloat {
        tableView?(t, heightForHeaderInSection: s) ?? UITableView.automaticDimension
    }
    func _heightForFooter(_ t: UITableView, _ s: Int) -> CGFloat {
        tableView?(t, heightForFooterInSection: s) ?? UITableView.automaticDimension
    }
    func _willDisplay(_ t: UITableView, _ c: UITableViewCell, _ p: IndexPath) { tableView?(t, willDisplay: c, forRowAt: p) }
    func _viewForHeader(_ t: UITableView, _ s: Int) -> UIView? { tableView?(t, viewForHeaderInSection: s) ?? nil }
    func _viewForFooter(_ t: UITableView, _ s: Int) -> UIView? { tableView?(t, viewForFooterInSection: s) ?? nil }
    func _didHighlight(_ t: UITableView, _ p: IndexPath) { tableView?(t, didHighlightRowAt: p) }
    func _didUnhighlight(_ t: UITableView, _ p: IndexPath) { tableView?(t, didUnhighlightRowAt: p) }
    func _didSelect(_ t: UITableView, _ p: IndexPath) { tableView?(t, didSelectRowAt: p) }
    func _didDeselect(_ t: UITableView, _ p: IndexPath) { tableView?(t, didDeselectRowAt: p) }
    func _leadingSwipe(_ t: UITableView, _ p: IndexPath) -> UISwipeActionsConfiguration? {
        tableView?(t, leadingSwipeActionsConfigurationForRowAt: p) ?? nil
    }
    func _trailingSwipe(_ t: UITableView, _ p: IndexPath) -> UISwipeActionsConfiguration? {
        tableView?(t, trailingSwipeActionsConfigurationForRowAt: p) ?? nil
    }
}

extension UITableView {
    /// UITableView.h declares `tableView:editingStyleForRowAtIndexPath:` on
    /// the DELEGATE; absent, UIKit uses `.delete`.
    final func _editingStyle(_ p: IndexPath) -> UITableViewCell.EditingStyle {
        tableDelegate?.tableView?(self, editingStyleForRowAt: p) ?? .delete
    }
}

extension UICollectionViewDataSource {
    func _numberOfSections(_ c: UICollectionView) -> Int { numberOfSections?(in: c) ?? 1 }
    func _supplementary(_ c: UICollectionView, _ kind: String, _ p: IndexPath) -> UICollectionReusableView {
        collectionView?(c, viewForSupplementaryElementOfKind: kind, at: p) ?? UICollectionReusableView()
    }
}

extension UICollectionViewDelegate {
    func _shouldSelect(_ c: UICollectionView, _ p: IndexPath) -> Bool { collectionView?(c, shouldSelectItemAt: p) ?? true }
    func _didSelect(_ c: UICollectionView, _ p: IndexPath) { collectionView?(c, didSelectItemAt: p) }
    func _didDeselect(_ c: UICollectionView, _ p: IndexPath) { collectionView?(c, didDeselectItemAt: p) }
    func _willDisplay(_ c: UICollectionView, _ cell: UICollectionViewCell, _ p: IndexPath) {
        collectionView?(c, willDisplay: cell, forItemAt: p)
    }
    func _didEndDisplaying(_ c: UICollectionView, _ cell: UICollectionViewCell, _ p: IndexPath) {
        collectionView?(c, didEndDisplaying: cell, forItemAt: p)
    }
}

#else

extension UIScrollViewDelegate {
    func _didScroll(_ s: UIScrollView) { scrollViewDidScroll(s) }
    func _didZoom(_ s: UIScrollView) { scrollViewDidZoom(s) }
    func _willBeginDragging(_ s: UIScrollView) { scrollViewWillBeginDragging(s) }
    func _willEndDragging(_ s: UIScrollView, velocity: CGPoint, targetContentOffset target: UnsafeMutablePointer<CGPoint>) {
        scrollViewWillEndDragging(s, withVelocity: velocity, targetContentOffset: target)
    }
    func _didEndDragging(_ s: UIScrollView, willDecelerate: Bool) {
        scrollViewDidEndDragging(s, willDecelerate: willDecelerate)
    }
    func _willBeginDecelerating(_ s: UIScrollView) { scrollViewWillBeginDecelerating(s) }
    func _didEndDecelerating(_ s: UIScrollView) { scrollViewDidEndDecelerating(s) }
    func _didEndScrollingAnimation(_ s: UIScrollView) { scrollViewDidEndScrollingAnimation(s) }
    func _viewForZooming(_ s: UIScrollView) -> UIView? { viewForZooming(in: s) }
    func _willBeginZooming(_ s: UIScrollView, with view: UIView?) { scrollViewWillBeginZooming(s, with: view) }
    func _didEndZooming(_ s: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollViewDidEndZooming(s, with: view, atScale: scale)
    }
    func _didChangeAdjustedContentInset(_ s: UIScrollView) { scrollViewDidChangeAdjustedContentInset(s) }
}

extension UITableViewDataSource {
    func _numberOfSections(_ t: UITableView) -> Int { numberOfSections(in: t) }
    func _titleForHeader(_ t: UITableView, _ s: Int) -> String? { tableView(t, titleForHeaderInSection: s) }
    func _titleForFooter(_ t: UITableView, _ s: Int) -> String? { tableView(t, titleForFooterInSection: s) }
    func _canEdit(_ t: UITableView, _ p: IndexPath) -> Bool { tableView(t, canEditRowAt: p) }
    func _canMove(_ t: UITableView, _ p: IndexPath) -> Bool { tableView(t, canMoveRowAt: p) }
    func _commit(_ t: UITableView, _ style: UITableViewCell.EditingStyle, _ p: IndexPath) {
        tableView(t, commit: style, forRowAt: p)
    }
    func _moveRow(_ t: UITableView, _ from: IndexPath, _ to: IndexPath) { tableView(t, moveRowAt: from, to: to) }
}

extension UITableViewDelegate {
    /// A Swift protocol cannot tell "not implemented" from the default
    /// `automaticDimension`, so both mean "absent" here (the portable
    /// builds' long-standing behaviour: `rowHeight` applies).
    func _heightForRow(_ t: UITableView, _ p: IndexPath) -> CGFloat? {
        let h = tableView(t, heightForRowAt: p)
        return h >= 0 ? h : nil
    }
    func _heightForHeader(_ t: UITableView, _ s: Int) -> CGFloat { tableView(t, heightForHeaderInSection: s) }
    func _heightForFooter(_ t: UITableView, _ s: Int) -> CGFloat { tableView(t, heightForFooterInSection: s) }
    func _willDisplay(_ t: UITableView, _ c: UITableViewCell, _ p: IndexPath) { tableView(t, willDisplay: c, forRowAt: p) }
    func _viewForHeader(_ t: UITableView, _ s: Int) -> UIView? { tableView(t, viewForHeaderInSection: s) }
    func _viewForFooter(_ t: UITableView, _ s: Int) -> UIView? { tableView(t, viewForFooterInSection: s) }
    func _didHighlight(_ t: UITableView, _ p: IndexPath) { tableView(t, didHighlightRowAt: p) }
    func _didUnhighlight(_ t: UITableView, _ p: IndexPath) { tableView(t, didUnhighlightRowAt: p) }
    func _didSelect(_ t: UITableView, _ p: IndexPath) { tableView(t, didSelectRowAt: p) }
    func _didDeselect(_ t: UITableView, _ p: IndexPath) { tableView(t, didDeselectRowAt: p) }
    func _leadingSwipe(_ t: UITableView, _ p: IndexPath) -> UISwipeActionsConfiguration? {
        tableView(t, leadingSwipeActionsConfigurationForRowAt: p)
    }
    func _trailingSwipe(_ t: UITableView, _ p: IndexPath) -> UISwipeActionsConfiguration? {
        tableView(t, trailingSwipeActionsConfigurationForRowAt: p)
    }
}

extension UITableView {
    /// The Swift protocol keeps this on the data source (its long-standing
    /// shape on the portable builds).
    final func _editingStyle(_ p: IndexPath) -> UITableViewCell.EditingStyle {
        dataSource?.tableView(self, editingStyleForRowAt: p) ?? .delete
    }
}

extension UICollectionViewDataSource {
    func _numberOfSections(_ c: UICollectionView) -> Int { numberOfSections(in: c) }
    func _supplementary(_ c: UICollectionView, _ kind: String, _ p: IndexPath) -> UICollectionReusableView {
        collectionView(c, viewForSupplementaryElementOfKind: kind, at: p)
    }
}

extension UICollectionViewDelegate {
    func _shouldSelect(_ c: UICollectionView, _ p: IndexPath) -> Bool { collectionView(c, shouldSelectItemAt: p) }
    func _didSelect(_ c: UICollectionView, _ p: IndexPath) { collectionView(c, didSelectItemAt: p) }
    func _didDeselect(_ c: UICollectionView, _ p: IndexPath) { collectionView(c, didDeselectItemAt: p) }
    func _willDisplay(_ c: UICollectionView, _ cell: UICollectionViewCell, _ p: IndexPath) {
        collectionView(c, willDisplay: cell, forItemAt: p)
    }
    func _didEndDisplaying(_ c: UICollectionView, _ cell: UICollectionViewCell, _ p: IndexPath) {
        collectionView(c, didEndDisplaying: cell, forItemAt: p)
    }
}

#endif
