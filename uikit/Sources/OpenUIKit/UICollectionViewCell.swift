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
@preconcurrency @MainActor
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
@preconcurrency @MainActor
open class UICollectionReusableView: UIView, ReusableView {
    /// Stamped by the collection view when the view is created for an
    /// identifier (UIKit sets it the same way — it is read-only to apps).
    public internal(set) var reuseIdentifier: String?

    /// Supplementary views remember their kind so the collection view can
    /// return them to the right pool (headers and footers may share an
    /// identifier).
    var elementKind: String?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
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

    /// Self-sizing hook. UICollectionViewListCell returns a height fitted
    /// to its content configuration; the base class keeps the layout's size.
    open func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        layoutAttributes
    }
}

// MARK: - UICollectionViewCell

extension UICollectionViewCell {
    /// The Auto Layout height of the content view at `width`, or nil when
    /// nothing constrains it vertically (then the layout's estimate stands).
    func _fittedContentHeight(forWidth width: CGFloat) -> CGFloat? {
        guard width > 0 else { return nil }
        contentView.frame = CGRect(x: 0, y: 0, width: width, height: contentView.frame.height)
        let fitting = contentView.systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
        return fitting.height > 0 ? fitting.height : nil
    }
}

@preconcurrency @MainActor
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
        didSet {
            if isSelected != oldValue {
                updateSelectionOverlay()
                setNeedsUpdateConfiguration()
            }
        }
    }
    open var isHighlighted = false {
        didSet {
            if isHighlighted != oldValue {
                updateSelectionOverlay()
                setNeedsUpdateConfiguration()
            }
        }
    }

    // MARK: Configurations (iOS 14)
    //
    // UIKit declares these on UICollectionViewCell, not only on the list cell
    // (NetNewsWire's MainFeedCollectionViewCell / MainTimelineCell /
    // TimelineCustomizerCell subclass UICollectionViewCell and override
    // updateConfiguration(using:)). MEASURED Tools/oracle2/cellconfigprobe
    // (iPhone 16 / iOS 26.1):
    //   * a plain cell has no background or content configuration (nil), and
    //     both `automaticallyUpdates…` flags are true;
    //   * updateConfiguration(using:) runs once when the displayed cell is
    //     laid out (after cellForItemAt, in a window), still with a nil
    //     background configuration;
    //   * setNeedsUpdateConfiguration() and a state change (isSelected) do not
    //     call it synchronously; the next layout pass calls it once, with the
    //     new state (coalesced).
    // UICollectionViewListCell overrides the members with its list defaults.

    /// Pending configuration pass (consumed in layoutSubviews).
    final var _needsConfigurationUpdate = true
    private var _plainContentConfiguration: (any UIContentConfiguration)?
    private var _plainInstalledContentView: (UIView & UIContentView)?
    private var _plainBackgroundConfiguration: UIBackgroundConfiguration?
    private var _plainBackgroundHost: _UIBackgroundConfigurationView?

    public var automaticallyUpdatesContentConfiguration = true
    public var automaticallyUpdatesBackgroundConfiguration = true
    public var configurationUpdateHandler: ((UICollectionViewCell, UICellConfigurationState) -> Void)?

    open var contentConfiguration: (any UIContentConfiguration)? {
        get { _plainContentConfiguration }
        set {
            _plainContentConfiguration = newValue
            _installPlainContent()
            setNeedsLayout()
        }
    }

    open var backgroundConfiguration: UIBackgroundConfiguration? {
        get { _plainBackgroundConfiguration }
        set {
            _plainBackgroundConfiguration = newValue
            _applyPlainBackground()
        }
    }

    open var configurationState: UICellConfigurationState {
        var state = UICellConfigurationState(traitCollection: traitCollection)
        state.isSelected = isSelected
        state.isHighlighted = isHighlighted
        return state
    }

    open func setNeedsUpdateConfiguration() {
        _needsConfigurationUpdate = true
        setNeedsLayout()
    }

    open func updateConfiguration(using state: UICellConfigurationState) {
        if automaticallyUpdatesContentConfiguration, let current = _plainContentConfiguration {
            _plainContentConfiguration = current.updated(for: state)
            _installPlainContent()
        }
        if automaticallyUpdatesBackgroundConfiguration, let current = _plainBackgroundConfiguration {
            _plainBackgroundConfiguration = current.updated(for: state)
            _applyPlainBackground()
        }
        configurationUpdateHandler?(self, state)
    }

    /// Runs the pending configuration pass (MEASURED: once per layout).
    final func _updateConfigurationIfNeeded() {
        guard _needsConfigurationUpdate else { return }
        _needsConfigurationUpdate = false
        updateConfiguration(using: configurationState)
    }

    private func _installPlainContent() {
        _plainInstalledContentView?.removeFromSuperview()
        _plainInstalledContentView = nil
        guard let configuration = _plainContentConfiguration else { return }
        let view = configuration.makeContentView()
        view.configuration = configuration
        contentView.addSubview(view)
        _plainInstalledContentView = view
    }

    private func _applyPlainBackground() {
        guard let configuration = _plainBackgroundConfiguration else {
            _plainBackgroundHost?.removeFromSuperview()
            _plainBackgroundHost = nil
            return
        }
        let host = _plainBackgroundHost ?? {
            let v = _UIBackgroundConfigurationView()
            insertSubview(v, at: 0)
            return v
        }()
        _plainBackgroundHost = host
        host.configuration = configuration
        // Applying a configuration resets the host's own corner radius; a
        // configuration update can run outside layoutSubviews (at install).
        _applyListSectionCorners()
        setNeedsLayout()
    }

    /// The collection view currently displaying this cell (set while bound).
    weak var collectionView: UICollectionView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureContentView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureContentView()
    }

    private func configureContentView() {
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
        _updateConfigurationIfNeeded()
        super.layoutSubviews()
        backgroundView?.frame = bounds
        selectedBackgroundView?.frame = bounds
        contentView.frame = bounds
        _plainBackgroundHost?.frame = bounds
        _plainInstalledContentView?.frame = contentView.bounds
        _applyListSectionCorners()
    }

    /// A plain cell in an insetGrouped list section is part of the section's
    /// rounded card. MEASURED Tools/oracle2/listheaderprobe
    /// (transcript-ios26.1.txt, plain UICollectionViewCell rows, with and
    /// without a cell `backgroundColor` as NetNewsWire's FeedCell nib sets):
    /// UIKit rounds the CELL, not its background view: the first row gets
    /// `cornerConfiguration` top-left/top-right `.fixed(26)` (layer
    /// maskedCorners 3), the last row bottom-left/bottom-right (12), middle
    /// rows `.unspecified` (maskedCorners 0); every row clips to bounds; `layer.cornerRadius`
    /// stays 0 and the background view keeps square corners.
    private func _applyListSectionCorners() {
        guard !(self is UICollectionViewListCell) else { return }
        guard let cv = collectionView,
              let list = (cv.collectionViewLayout as? UICollectionViewCompositionalLayout)?
                ._storedListConfiguration,
              list.appearance == .insetGrouped,
              let path = cv.indexPath(for: self) else {
            if _appliedListSectionCorners {
                _appliedListSectionCorners = false
                cornerConfiguration = .unspecified
                layer.maskedCorners = ._allKnown
            }
            return
        }
        let first = path.item == 0
        let last = path.item == cv.numberOfItems(inSection: path.section) - 1
        let r = UICornerRadius.fixed(Double(UICollectionViewListCell.insetGroupedCornerRadius))
        let wanted = UICornerConfiguration.corners(topLeftRadius: first ? r : nil,
                                                  topRightRadius: first ? r : nil,
                                                  bottomLeftRadius: last ? r : nil,
                                                  bottomRightRadius: last ? r : nil)
        var mask: CACornerMask = []
        if first { mask.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if last { mask.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
        _appliedListSectionCorners = true
        clipsToBounds = true
        // cornerConfiguration alone leaves maskedCorners at all four
        // (UICornerConfiguration.swift); the list sets them as well.
        if layer.maskedCorners != mask { layer.maskedCorners = mask }
        if cornerConfiguration != wanted { cornerConfiguration = wanted }
    }
    private var _appliedListSectionCorners = false

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

// Swift only permits a dynamic metatype call through a required initializer,
// unlike Objective-C's selector dispatch. These open SPI sibling classes turn
// that source-language restriction into the initializer-vtable lookup UIKit's
// registration path needs: UICollectionView casts only the one-word class
// metatype, then invokes the required override below. The override occupies
// UICollectionReusableView.init(frame:)'s vtable slot, so the allocator keeps
// the original registered metatype and dispatches to its most-derived ordinary
// frame override. UICollectionViewCell's override therefore still configures
// contentView exactly once when the registered class is a cell.
//
// These classes must remain open. That prevents whole-module optimization from
// devirtualizing the constructor call which deliberately carries another
// class's metatype. It is SPI so application subclasses inherit no
// OpenUIKit-only required initializer.
@_spi(OpenUIKitInternals)
@preconcurrency @MainActor
open class _UICollectionReusableViewDynamicConstructor: UICollectionReusableView {
    public required override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

@_spi(OpenUIKitInternals)
@preconcurrency @MainActor
open class _UICollectionViewCellDynamicConstructor: UICollectionViewCell {
    public required override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
