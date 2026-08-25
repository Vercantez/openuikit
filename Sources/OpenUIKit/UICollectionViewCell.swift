// UICollectionReusableView + UICollectionViewCell. Owner: collection module
// (M13).
//
// Unlike UITableViewCell there is NO measured chrome here: a real
// UICollectionViewCell draws nothing of its own. It is a transparent
// container with a `contentView` the app fills, an optional `backgroundView`
// behind it and an optional `selectedBackgroundView` that appears while the
// cell is selected or highlighted (both nil by default — a stock collection
// view shows no selection feedback at all, which is UIKit's behaviour and
// the reason apps set `selectedBackgroundView` themselves).
//
// Layering matches UIKit: backgroundView, then selectedBackgroundView, then
// contentView, then any subviews the app added to the cell itself.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif


/// The content container. Plain-view touches that land on it (or on
/// non-interactive subviews) are forwarded to the cell so selection works
/// while real controls inside keep their own touches — the same forwarding
/// UITableViewCellContentView does.


final class UICollectionViewCellContentView: UIView {
    var cell: UICollectionViewCell? { superview as? UICollectionViewCell }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        cell?.touchesBegan(touches, with: event)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        cell?.touchesMoved(touches, with: event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        cell?.touchesEnded(touches, with: event)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cell?.touchesCancelled(touches, with: event)
    }
}

// MARK: - UICollectionReusableView

/// Base class for everything a collection view recycles: cells and
/// supplementary (header/footer) views.
open class UICollectionReusableView: UIView, ReusableView {
    /// Stamped by the collection view when the view is created for an
    /// identifier (UIKit sets it the same way — it is read-only to apps).
    public internal(set) var reuseIdentifier: String?

    /// Supplementary views remember their kind so the collection view can
    /// return them to the right pool (headers and footers may share an
    /// identifier).
    var elementKind: String?

    public required override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    /// Reset before the view is handed back out. Override to clear content;
    /// always call super.
    open func prepareForReuse() {}

    /// Adopt a layout object's attributes. The collection view calls this
    /// after setting the frame, so overrides see the final geometry.
    open func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        alpha = layoutAttributes.alpha
        isHidden = layoutAttributes.isHidden
    }
}

// MARK: - UICollectionViewCell

open class UICollectionViewCell: UICollectionReusableView {
    public let contentView: UIView = UICollectionViewCellContentView()

    /// Drawn behind the content view. nil by default (UIKit).
    public var backgroundView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let v = backgroundView {
                v.isUserInteractionEnabled = false
                insertSubview(v, at: 0)
                setNeedsLayout()
            }
        }
    }

    /// Drawn above `backgroundView` while selected/highlighted. nil by
    /// default, which is why a stock collection view shows no selection.
    public var selectedBackgroundView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let v = selectedBackgroundView {
                v.isUserInteractionEnabled = false
                v.isHidden = !(isSelected || isHighlighted)
                insertSubview(v, at: backgroundView == nil ? 0 : 1)
                setNeedsLayout()
            }
        }
    }

    open var isSelected = false {
        didSet { if isSelected != oldValue { updateSelectionOverlay() } }
    }
    open var isHighlighted = false {
        didSet { if isHighlighted != oldValue { updateSelectionOverlay() } }
    }

    /// The collection view currently displaying this cell (set while bound).
    weak var collectionView: UICollectionView?

    public required init(frame: CGRect = .zero) {
        super.init(frame: frame)
        contentView.frame = bounds
        addSubview(contentView)
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        isSelected = false
        isHighlighted = false
    }

    private func updateSelectionOverlay() {
        selectedBackgroundView?.isHidden = !(isSelected || isHighlighted)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView?.frame = bounds
        selectedBackgroundView?.frame = bounds
        contentView.frame = bounds
    }

    // MARK: Touch handling (tap -> highlight -> select)

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard collectionView?.allowsSelection != false else { return }
        isHighlighted = true
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isHighlighted else { return }
        isHighlighted = false
        collectionView?.commitItemTap(on: self)
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = false
    }
}
