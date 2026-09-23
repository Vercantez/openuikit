// List separators for PLAIN UICollectionViewCells. Owner: collection module.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGRect
#elseif canImport(Foundation)
import Foundation
#endif

extension UICollectionView {
    /// Separators an insetGrouped list draws between PLAIN
    /// `UICollectionViewCell`s. MEASURED Tools/oracle2/listseparatorprobe
    /// (iPhone 16 / iOS 26.1, transcript-ios26.1.txt):
    ///
    ///   * each separator is a `_UICollectionViewListSeparatorView`, a direct
    ///     subview of the collection view above the cells, 1 pt tall, filled
    ///     with `separatorColor` (0.235, 0.235, 0.263, alpha 0.12);
    ///   * untouched (`itemSeparatorHandler` nil): a bottom separator on every
    ///     row but the section's last, at the cell's maxY - 1, inset 16 from
    ///     both cell edges ([32, 84.33, 329, 1] under [16, 35, 361, 50.33]);
    ///   * NetNewsWire's handler (bottom hidden, top visible from row 1, top
    ///     leading 48, trailing 0): at the cell's minY, [64, y, 313, 1].
    ///
    /// The handler receives the section's configuration; insets it returns
    /// unchanged stay the automatic 16 / 16. Other list appearances were not
    /// measured and draw none here (UICollectionViewListCell keeps its own).
    func _layoutPlainListSeparators(_ attributes: [UICollectionViewLayoutAttributes]) {
        var lines: [(CGRect, UIColor)] = []
        if let layout = collectionViewLayout as? UICollectionViewCompositionalLayout,
           let list = layout._storedListConfiguration, list.appearance == .insetGrouped {
            let automaticInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            let base = UIListSeparatorConfiguration()
            let rtl = effectiveUserInterfaceLayoutDirection == .rightToLeft
            for a in attributes where a.representedElementCategory == .cell {
                guard let cell = visibleViews[a.elementKey] as? UICollectionViewCell,
                      !(cell is UICollectionViewListCell) else { continue }
                let path = a.indexPath
                let isLast = path.item == numberOfItems(inSection: path.section) - 1
                let c = list.itemSeparatorHandler?(path, base) ?? base
                let f = cell.frame
                func line(y: CGFloat, _ given: NSDirectionalEdgeInsets,
                          _ passed: NSDirectionalEdgeInsets) -> CGRect {
                    let i = given == passed ? automaticInsets : given
                    let left = rtl ? i.trailing : i.leading
                    let right = rtl ? i.leading : i.trailing
                    return CGRect(x: f.minX + left, y: y, width: f.width - left - right, height: 1)
                }
                if c.topSeparatorVisibility == .visible {
                    lines.append((line(y: f.minY, c.topSeparatorInsets, base.topSeparatorInsets), c.color))
                }
                if c.bottomSeparatorVisibility == .visible
                    || (c.bottomSeparatorVisibility == .automatic && !isLast) {
                    lines.append((line(y: f.maxY - 1, c.bottomSeparatorInsets, base.bottomSeparatorInsets), c.color))
                }
            }
        }
        while _plainListSeparators.count > lines.count {
            _plainListSeparators.removeLast().removeFromSuperview()
        }
        while _plainListSeparators.count < lines.count {
            let s = _UICollectionViewListSeparatorView(frame: .zero)
            addSubview(s)
            _plainListSeparators.append(s)
        }
        for (s, (frame, color)) in zip(_plainListSeparators, lines) {
            if s.frame != frame { s.frame = frame }
            if s.backgroundColor != color { s.backgroundColor = color }
            bringSubviewToFront(s)
        }
    }
}
