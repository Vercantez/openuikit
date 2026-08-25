// UIToolbar. Owner: viewcontroller module (M13 "bars & appearance").
//
// MEASURED (real iOS 26.1, iPhone 16 — probe recipe in UIBarButtonItem.swift,
// golden/toolbar_basic): a toolbar is a row of glass capsule platters, laid
// out inside the bar's bounds with a 16 pt side margin and the shared 12 pt
// gap rule, with flexible spaces absorbing the slack. Two numbers differ
// from the navigation bar and were measured separately:
//
//   * the platters are **48 pt** tall (radius 24), not 44,
//   * and they are TOP-ALIGNED at the bar's own y = 0, not centred.
//
// The bar itself paints nothing unless its appearance was configured with a
// background (iOS 26 default = transparent, like every other bar).
//
// `isTranslucent` has no blur to be translucent WITH (docs/KNOWN_GAPS.md):
// it is stored, and a translucent bar simply keeps whatever flat background
// its appearance supplies — the measured flat equivalent.

public final class UIToolbar: UIView, _UIBarItemContainer {
    /// Measured intrinsic bar height (the platter plus its vertical margins).
    public static let defaultHeight: CGFloat = 54

    public var items: [UIBarButtonItem]? {
        didSet { rebuildItemViews() }
    }

    /// Bar-wide tint. Only a `.prominent` item's platter fill uses it —
    /// iOS 26 renders untinted bar buttons monochrome (measured; see
    /// UIBarButtonItem.swift).
    public var barTintColor: UIColor? {
        didSet { applyAppearance() }
    }
    public var isTranslucent: Bool = true

    public var standardAppearance = UIToolbarAppearance() {
        didSet { applyAppearance() }
    }
    public var scrollEdgeAppearance: UIToolbarAppearance? {
        didSet { applyAppearance() }
    }
    public var compactAppearance: UIToolbarAppearance?

    let background = UIView()
    let hairline = UIView()
    var itemViews: [_UIBarButtonItemView] = []

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isOpaque = false
        background.isUserInteractionEnabled = false
        hairline.isUserInteractionEnabled = false
        addSubview(background)
        addSubview(hairline)
        applyAppearance()
    }

    public func setItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        self.items = items
    }

    func _barItemsChanged() {
        for v in itemViews { v.applyColors() }
        setNeedsLayout()
    }

    func rebuildItemViews() {
        for v in itemViews { v.removeFromSuperview() }
        itemViews = (items ?? []).map { item in
            item._bar = self
            let v = _UIBarButtonItemView(item: item)
            v.platterHeight = _UIBarMetrics.toolbarPlatterHeight
            v.appliesRefraction = false     // measured: toolbars have no band
            v.barTintColor = barTintColor ?? tintColor ?? .systemBlue
            v.addTarget(for: .touchUpInside) { [weak item] control, event in
                guard let item, let action = item.action else { return }
                SelectorDispatch.send(action, to: item.target, sender: item,
                                      event: event)
                _ = control
            }
            addSubview(v)
            return v
        }
        applyAppearance()
        setNeedsLayout()
    }

    func applyAppearance() {
        let a = standardAppearance
        background.backgroundColor = a._resolvedBackgroundColor
        hairline.backgroundColor = a.shadowColor
        hairline.isHidden = a.shadowColor == nil || a._resolvedBackgroundColor == nil
        for v in itemViews { v.barTintColor = barTintColor ?? tintColor ?? .systemBlue }
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        background.frame = bounds
        hairline.frame = CGRect(x: 0, y: bounds.height - UIBarAppearance.shadowHeight,
                                width: bounds.width, height: UIBarAppearance.shadowHeight)
        // Measured: the toolbar's glass platters are TOP-aligned at the
        // bar's own y = 0 (not centred), 48 pt tall.
        let h = _UIBarMetrics.toolbarPlatterHeight
        _UIBarItemLayout.layout(itemViews, in: bounds.width, y: 0, height: h,
                                sideMargin: _UIBarMetrics.sideMargin)
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIToolbar.defaultHeight)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: UIToolbar.defaultHeight)
    }
}
