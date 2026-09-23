// OpenUIKitObjCBridge — UICollectionView / UICollectionViewFlowLayout
// selectors for Objective-C callers (eidolon-flowlayout). Kept in its own
// file so it merges independently of UIKitObjCBridge.swift.
//
// The override points of UICollectionViewLayout / UICollectionViewFlowLayout
// / UICollectionViewLayoutAttributes are `@objc` in OpenUIKit itself (those
// classes are vtable-free, ObjCSubclassing.swift). What lives here is the
// rest: members whose Swift type has no Objective-C spelling
// (`sectionInset` is OpenUIKit's Swift UIEdgeInsets, `scrollDirection` a
// Swift enum), and UICollectionView's surface, whose data source and
// delegate are Swift protocols. An Objective-C object conforming to the
// UIKitObjCSupport.h protocols is wrapped in an adapter that conforms to the
// Swift ones and forwards each call the object implements (respondsToSelector,
// as UIKit asks); for a method it does not implement the adapter returns what
// OpenUIKit's protocol-extension default would. The `delegate` /
// `dataSource` getters return the original object, so an Objective-C layout
// that reads `self.collectionView.delegate` (ARCollectionViewMasonryLayout's
// `conformsToProtocol:` check) sees what it set.

#if canImport(ObjectiveC)
import CoreGraphics
import Foundation
import ObjectiveC
import OpenCoreGraphics
import OpenUIKit
import OpenUIKitObjCSupport

// MARK: - Message sends to an Objective-C protocol object

/// Calls `sel` on `target` through its IMP with the C signature `F`.
@inline(__always)
private func imp<F>(_ target: NSObject, _ sel: Selector, as: F.Type) -> F {
    unsafeBitCast(target.method(for: sel), to: F.self)
}

private typealias CountIMP = @convention(c) (NSObject, Selector, NSObject) -> Int
private typealias CountInSectionIMP = @convention(c) (NSObject, Selector, NSObject, Int) -> Int
private typealias ObjectAtPathIMP = @convention(c) (NSObject, Selector, NSObject, NSIndexPath) -> NSObject
private typealias SupplementaryIMP = @convention(c) (NSObject, Selector, NSObject, NSString, NSIndexPath) -> NSObject
private typealias BoolAtPathIMP = @convention(c) (NSObject, Selector, NSObject, NSIndexPath) -> Bool
private typealias VoidAtPathIMP = @convention(c) (NSObject, Selector, NSObject, NSIndexPath) -> Void
private typealias VoidCellAtPathIMP = @convention(c) (NSObject, Selector, NSObject, NSObject, NSIndexPath) -> Void
private typealias SizeAtPathIMP = @convention(c) (NSObject, Selector, NSObject, NSObject, NSIndexPath) -> CGSize
private typealias SizeInSectionIMP = @convention(c) (NSObject, Selector, NSObject, NSObject, Int) -> CGSize
private typealias InsetInSectionIMP = @convention(c) (NSObject, Selector, NSObject, NSObject, Int) -> UIEdgeInsetsObjC
private typealias FloatInSectionIMP = @convention(c) (NSObject, Selector, NSObject, NSObject, Int) -> CGFloat
private typealias ScrollIMP = @convention(c) (NSObject, Selector, NSObject) -> Void
private typealias ScrollBoolIMP = @convention(c) (NSObject, Selector, NSObject, Bool) -> Void

/// `UICollectionViewDataSource` (Swift) over an Objective-C
/// `id<UICollectionViewDataSource>`.
@MainActor
final class _OUKObjCCollectionViewDataSource: NSObject, OpenUIKit.UICollectionViewDataSource {
    weak var target: NSObject?
    init(_ target: NSObject) { self.target = target }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sel = NSSelectorFromString("numberOfSectionsInCollectionView:")
        guard let t = target, t.responds(to: sel) else { return 1 }
        return imp(t, sel, as: CountIMP.self)(t, sel, collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sel = NSSelectorFromString("collectionView:numberOfItemsInSection:")
        guard let t = target, t.responds(to: sel) else { return 0 }
        return imp(t, sel, as: CountInSectionIMP.self)(t, sel, collectionView, section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sel = NSSelectorFromString("collectionView:cellForItemAtIndexPath:")
        guard let t = target, t.responds(to: sel),
              let cell = imp(t, sel, as: ObjectAtPathIMP.self)(t, sel, collectionView, indexPath as NSIndexPath)
                as? UICollectionViewCell else {
            fatalError("-collectionView:cellForItemAtIndexPath: must return a UICollectionViewCell")
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let sel = NSSelectorFromString("collectionView:viewForSupplementaryElementOfKind:atIndexPath:")
        guard let t = target, t.responds(to: sel) else { return UICollectionReusableView() }
        let view = imp(t, sel, as: SupplementaryIMP.self)(t, sel, collectionView, kind as NSString,
                                                          indexPath as NSIndexPath)
        return view as? UICollectionReusableView ?? UICollectionReusableView()
    }
}

/// `UICollectionViewDelegateFlowLayout` (Swift) over an Objective-C
/// `id<UICollectionViewDelegate[FlowLayout]>`.
@MainActor
final class _OUKObjCCollectionViewDelegate: NSObject, OpenUIKit.UICollectionViewDelegateFlowLayout {
    weak var target: NSObject?
    init(_ target: NSObject) { self.target = target }

    private func responder(_ name: String) -> (NSObject, Selector)? {
        let sel = NSSelectorFromString(name)
        guard let t = target, t.responds(to: sel) else { return nil }
        return (t, sel)
    }

    // UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let (t, s) = responder("scrollViewDidScroll:") else { return }
        imp(t, s, as: ScrollIMP.self)(t, s, scrollView)
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let (t, s) = responder("scrollViewWillBeginDragging:") else { return }
        imp(t, s, as: ScrollIMP.self)(t, s, scrollView)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        guard let (t, s) = responder("scrollViewDidEndDragging:willDecelerate:") else { return }
        imp(t, s, as: ScrollBoolIMP.self)(t, s, scrollView, willDecelerate)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let (t, s) = responder("scrollViewDidEndDecelerating:") else { return }
        imp(t, s, as: ScrollIMP.self)(t, s, scrollView)
    }

    // UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let (t, s) = responder("collectionView:shouldSelectItemAtIndexPath:") else { return true }
        return imp(t, s, as: BoolAtPathIMP.self)(t, s, collectionView, indexPath as NSIndexPath)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let (t, s) = responder("collectionView:didSelectItemAtIndexPath:") else { return }
        imp(t, s, as: VoidAtPathIMP.self)(t, s, collectionView, indexPath as NSIndexPath)
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let (t, s) = responder("collectionView:didDeselectItemAtIndexPath:") else { return }
        imp(t, s, as: VoidAtPathIMP.self)(t, s, collectionView, indexPath as NSIndexPath)
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard let (t, s) = responder("collectionView:willDisplayCell:forItemAtIndexPath:") else { return }
        imp(t, s, as: VoidCellAtPathIMP.self)(t, s, collectionView, cell, indexPath as NSIndexPath)
    }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard let (t, s) = responder("collectionView:didEndDisplayingCell:forItemAtIndexPath:") else { return }
        imp(t, s, as: VoidCellAtPathIMP.self)(t, s, collectionView, cell, indexPath as NSIndexPath)
    }

    // UICollectionViewDelegateFlowLayout: absent → the flow layout's own
    // property, which is what UIKit falls back to.
    private func flow(_ l: UICollectionViewLayout) -> UICollectionViewFlowLayout? { l as? UICollectionViewFlowLayout }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let (t, s) = responder("collectionView:layout:sizeForItemAtIndexPath:") else {
            return flow(collectionViewLayout)?.itemSize ?? .zero
        }
        return imp(t, s, as: SizeAtPathIMP.self)(t, s, collectionView, collectionViewLayout, indexPath as NSIndexPath)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> OpenUIKit.UIEdgeInsets {
        guard let (t, s) = responder("collectionView:layout:insetForSectionAtIndex:") else {
            return flow(collectionViewLayout)?.sectionInset ?? .zero
        }
        let i = imp(t, s, as: InsetInSectionIMP.self)(t, s, collectionView, collectionViewLayout, section)
        return OpenUIKit.UIEdgeInsets(top: i.top, left: i.left, bottom: i.bottom, right: i.right)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let (t, s) = responder("collectionView:layout:minimumLineSpacingForSectionAtIndex:") else {
            return flow(collectionViewLayout)?.minimumLineSpacing ?? 0
        }
        return imp(t, s, as: FloatInSectionIMP.self)(t, s, collectionView, collectionViewLayout, section)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let (t, s) = responder("collectionView:layout:minimumInteritemSpacingForSectionAtIndex:") else {
            return flow(collectionViewLayout)?.minimumInteritemSpacing ?? 0
        }
        return imp(t, s, as: FloatInSectionIMP.self)(t, s, collectionView, collectionViewLayout, section)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let (t, s) = responder("collectionView:layout:referenceSizeForHeaderInSection:") else {
            return flow(collectionViewLayout)?.headerReferenceSize ?? .zero
        }
        return imp(t, s, as: SizeInSectionIMP.self)(t, s, collectionView, collectionViewLayout, section)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let (t, s) = responder("collectionView:layout:referenceSizeForFooterInSection:") else {
            return flow(collectionViewLayout)?.footerReferenceSize ?? .zero
        }
        return imp(t, s, as: SizeInSectionIMP.self)(t, s, collectionView, collectionViewLayout, section)
    }
}

nonisolated(unsafe) private var dataSourceAdapterKey: UInt8 = 0
nonisolated(unsafe) private var delegateAdapterKey: UInt8 = 0

// MARK: - UICollectionView

extension UICollectionView {
    /// `id<UICollectionViewDataSource>`: a Swift conformer is used as is, an
    /// Objective-C one through `_OUKObjCCollectionViewDataSource` (retained
    /// by the collection view; the object itself stays weak, as in UIKit).
    @objc(dataSource) public var __objc_dataSource: AnyObject? {
        get {
            if let adapter = dataSource as? _OUKObjCCollectionViewDataSource { return adapter.target }
            return dataSource
        }
        set {
            if let swift = newValue as? OpenUIKit.UICollectionViewDataSource {
                objc_setAssociatedObject(self, &dataSourceAdapterKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                dataSource = swift
            } else if let object = newValue as? NSObject {
                let adapter = _OUKObjCCollectionViewDataSource(object)
                objc_setAssociatedObject(self, &dataSourceAdapterKey, adapter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                dataSource = adapter
            } else {
                objc_setAssociatedObject(self, &dataSourceAdapterKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                dataSource = nil
            }
        }
    }

    // `-delegate` / `-setDelegate:` are UIScrollView's (UIKitObjCBridge.swift),
    // typed by the @objc UIScrollViewDelegate that UICollectionViewDelegate
    // refines (objc-protocols.md).

    @objc(collectionViewLayout) public var __objc_collectionViewLayout: UICollectionViewLayout {
        get { collectionViewLayout } set { collectionViewLayout = newValue }
    }
    @objc(reloadData) public func __objc_reloadData() { reloadData() }
    @objc(numberOfSections) public var __objc_numberOfSections: Int { numberOfSections }
    @objc(numberOfItemsInSection:) public func __objc_numberOfItems(inSection section: Int) -> Int {
        numberOfItems(inSection: section)
    }
    @objc(registerClass:forCellWithReuseIdentifier:)
    public func __objc_register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        guard let cellClass = cellClass as? UICollectionViewCell.Type else { return }
        register(cellClass, forCellWithReuseIdentifier: identifier)
    }
    @objc(registerClass:forSupplementaryViewOfKind:withReuseIdentifier:)
    public func __objc_register(_ viewClass: AnyClass?, forSupplementaryViewOfKind kind: String,
                                withReuseIdentifier identifier: String) {
        guard let viewClass = viewClass as? UICollectionReusableView.Type else { return }
        register(viewClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }
    @objc(dequeueReusableCellWithReuseIdentifier:forIndexPath:)
    public func __objc_dequeueReusableCell(withReuseIdentifier identifier: String,
                                           for indexPath: IndexPath) -> UICollectionViewCell {
        dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }
    @objc(dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:)
    public func __objc_dequeueReusableSupplementaryView(ofKind kind: String, withReuseIdentifier identifier: String,
                                                        for indexPath: IndexPath) -> UICollectionReusableView {
        dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath)
    }
    @objc(visibleCells) public var __objc_visibleCells: [UICollectionViewCell] { visibleCells }
    @objc(indexPathsForVisibleItems) public var __objc_indexPathsForVisibleItems: [IndexPath] {
        indexPathsForVisibleItems
    }
    @objc(cellForItemAtIndexPath:) public func __objc_cellForItem(at indexPath: IndexPath) -> UICollectionViewCell? {
        cellForItem(at: indexPath)
    }
    @objc(indexPathForCell:) public func __objc_indexPath(for cell: UICollectionViewCell) -> IndexPath? {
        indexPath(for: cell)
    }
    @objc(indexPathForItemAtPoint:) public func __objc_indexPathForItem(at point: CGPoint) -> IndexPath? {
        indexPathForItem(at: point)
    }
    @objc(supplementaryViewForElementKind:atIndexPath:)
    public func __objc_supplementaryView(forElementKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView? {
        supplementaryView(forElementKind: kind, at: indexPath)
    }
    @objc(layoutAttributesForItemAtIndexPath:)
    public func __objc_layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        layoutAttributesForItem(at: indexPath)
    }
    @objc(layoutAttributesForSupplementaryElementOfKind:atIndexPath:)
    public func __objc_layoutAttributesForSupplementaryElement(ofKind kind: String,
                                                               at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        layoutAttributesForSupplementaryElement(ofKind: kind, at: indexPath)
    }
}

// MARK: - UICollectionViewFlowLayout

extension UICollectionViewFlowLayout {
    @objc(sectionInset) public var __objc_sectionInset: UIEdgeInsetsObjC {
        get { UIEdgeInsetsObjC(top: sectionInset.top, left: sectionInset.left,
                               bottom: sectionInset.bottom, right: sectionInset.right) }
        set { sectionInset = OpenUIKit.UIEdgeInsets(top: newValue.top, left: newValue.left,
                                                    bottom: newValue.bottom, right: newValue.right) }
    }
    /// UICollectionViewScrollDirection: Vertical 0, Horizontal 1
    /// (UICollectionViewLayout.h).
    @objc(scrollDirection) public var __objc_scrollDirection: Int {
        get { scrollDirection == .horizontal ? 1 : 0 }
        set { scrollDirection = newValue == 1 ? .horizontal : .vertical }
    }
}
#endif
