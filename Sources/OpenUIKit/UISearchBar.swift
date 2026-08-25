// UISearchBar. Owner: controls module (app-compat cluster "controls2").
//
// MEASURED (Mac Catalyst iOS 26.1, offscreen oracle — view tree, layer tree
// and the rendered ink):
//
//   * `sizeThatFits(_:)` returns (width, 44) at EVERY height (probed at
//     36/44/50/56/60/80) and `intrinsicContentSize` is (noIntrinsicMetric,
//     44).
//   * The search text field is (8, (H - 44) / 2, W - 16, 36) — fitted over
//     six heights (H = 36 -> y = -4, 44 -> 0, 50 -> 3, 56 -> 6, 60 -> 8,
//     80 -> 18) and three widths (200/320/375 all give W - 16).
//   * The magnifier image view is (12, 7.5, 20.5, 20) INSIDE the field, its
//     image 20.5 x 18.5, tinted `label`. The rendered ink is a 2 pt stroked
//     ring of outer radius 6.5 centred at (8.5, 8.5) in the image view, plus
//     a 2 pt handle running at 45 degrees from the ring to (17.5, 17.5) —
//     read off the golden ink at 2x, where the ring spans exactly 13 x 13 pt
//     and every stroke is 4 device pixels wide.
//   * The placeholder label is at (39.5, 8, ..., 20.5) in the field —
//     7 pt after the magnifier — in **system MEDIUM 17**, not regular, and
//     its colour resolves to black at alpha 0.25 (light) / white at alpha
//     0.25 (dark). The field's own font is the same medium 17.
//   * The clear button (present only with text) is (269.5, 7.5, 20.5, 20.5)
//     in a 304 pt field, i.e. 14 pt in from the field's trailing edge.
//   * The editable text starts at x 39.5 in the field, same as the
//     placeholder.
//
// NOT MEASURABLE OFFSCREEN, and therefore NOT GOLDENED — this control has no
// fixture scene, deliberately:
//
//   * **The field's pill does not composite.** `searchTextField.backgroundColor`
//     is nil, its layer's `backgroundColor` is nil and `cornerRadius` is 0
//     with `cornerCurve = .continuous`; the visible rounded fill is a private
//     material that `layer.render(in:)` draws as NOTHING (the capture is
//     transparent everywhere except the magnifier and the placeholder ink).
//     Same limitation as the tab-bar platter, the sheet grabber and the dark
//     text-field border (docs/KNOWN_GAPS.md). `fieldFill` and
//     `fieldCornerRadius` below are therefore INFERRED, not measured:
//     `tertiarySystemFill` is iOS's documented search-field material and
//     10 pt reads as the iOS rounded rect. A pixel golden needs the WINDOWED
//     oracle (`Tools/oracle2`), which needs an active display session.
//   * **The cancel button never appears offscreen.** `showsCancelButton = true`
//     followed by a layout pass leaves the view tree unchanged — UIKit builds
//     the button lazily in a real window. Everything about it here (a 17 pt
//     regular "Cancel" in the tint colour, 8 pt from the trailing edge, the
//     field shrinking to make room) is UIKit's documented shape, NOT a
//     measurement.
//   * `searchBarStyle`, `barTintColor`, scope bars, bookmark/results buttons
//     and the search-results-controller integration are not implemented.
//     `.minimal` is honoured to the extent that it suppresses the pill.

public protocol UISearchBarDelegate: AnyObject {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
}

extension UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {}
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool { true }
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {}
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool { true }
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {}
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {}
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {}
}

public enum UISearchBarStyle: Int, Sendable {
    case `default` = 0
    case prominent = 1
    case minimal = 2
}

/// The search bar's text field. UIKit exposes the same class name and it is
/// an ordinary `UITextField` there too; the magnifier is drawn by this
/// subclass rather than by a separate image view, because OpenUIKit has no
/// SF Symbols to load one from (the geometry is the measured one).
public class UISearchTextField: UITextField {
    /// Measured icon frame inside the field.
    public static let iconFrame = CGRect(x: 12, y: 7.5, width: 20.5, height: 20)
    /// Measured ring: centre (8.5, 8.5) in the icon box, outer radius 6.5,
    /// 2 pt stroke; the handle ends at (17.5, 17.5).
    static let ringCenter = CGPoint(x: 8.5, y: 8.5)
    static let ringOuterRadius: CGFloat = 6.5
    static let strokeWidth: CGFloat = 2
    static let handleEnd = CGPoint(x: 17.5, y: 17.5)
    /// Measured: the placeholder and the text both start 39.5 pt in.
    public static let textLeftInset: CGFloat = 39.5
    /// Measured: 14 pt from the field's trailing edge to the clear button,
    /// which is itself 20.5 pt wide.
    public static let clearButtonInset: CGFloat = 14
    public static let clearButtonWidth: CGFloat = 20.5
    /// Inferred, NOT measured (file header).
    public static let fieldCornerRadius: CGFloat = 10

    /// Whether the private material pill is drawn. `false` reproduces what
    /// the offscreen oracle captures (nothing) and what `.minimal` looks
    /// like.
    var drawsFieldBackground = true
    weak var _searchBar: UISearchBar?

    /// Measured text box: 39.5 pt in from the left, and 14 + 20.5 pt in from
    /// the right once a clear button is present.
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        let right = (text ?? "").isEmpty ? 0
            : UISearchTextField.clearButtonInset + UISearchTextField.clearButtonWidth
        return CGRect(x: bounds.minX + UISearchTextField.textLeftInset, y: bounds.minY,
                      width: max(0, bounds.width - UISearchTextField.textLeftInset - right),
                      height: bounds.height)
    }

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        if drawsFieldBackground {
            let fill = UIColor.tertiarySystemFill.resolvedCGColor(with: traitCollection)
            canvas.fill(Path.roundedRect(bounds,
                                         cornerRadius: UISearchTextField.fieldCornerRadius),
                        color: fill)
        }
        drawMagnifier(in: canvas, bounds: bounds)
        super.drawContent(in: canvas, bounds: bounds)
    }

    private func drawMagnifier(in canvas: Canvas, bounds: CGRect) {
        let box = UISearchTextField.iconFrame.offsetBy(dx: bounds.minX, dy: bounds.minY)
        let c = CGPoint(x: box.minX + UISearchTextField.ringCenter.x,
                        y: box.minY + UISearchTextField.ringCenter.y)
        let color = (_tintColor ?? UIColor.label).resolvedCGColor(with: traitCollection)
        let w = UISearchTextField.strokeWidth
        let mid = UISearchTextField.ringOuterRadius - w / 2
        // A square with cornerRadius == half its side IS a circle in Path.
        let ring = Path.roundedRect(CGRect(x: c.x - mid, y: c.y - mid,
                                           width: mid * 2, height: mid * 2),
                                    cornerRadius: mid)
        canvas.stroke(ring, color: color, lineWidth: w)
        let end = CGPoint(x: box.minX + UISearchTextField.handleEnd.x,
                          y: box.minY + UISearchTextField.handleEnd.y)
        let k = mid / (2 as CGFloat).squareRoot()
        var handle = Path()
        handle.move(to: CGPoint(x: c.x + k, y: c.y + k))
        handle.addLine(to: end)
        canvas.stroke(handle, color: color, lineWidth: w)
    }
}

open class UISearchBar: UIView {
    /// Measured: 44 pt tall whatever the frame says.
    public static let standardHeight: CGFloat = 44
    /// Measured: the field is inset 8 pt on each side and 36 pt tall.
    public static let fieldSideInset: CGFloat = 8
    public static let fieldHeight: CGFloat = 36
    /// NOT measured (file header): the cancel button's metrics.
    public static let cancelButtonFontSize: CGFloat = 17
    public static let cancelButtonGap: CGFloat = 8

    public weak var delegate: UISearchBarDelegate?

    public let searchTextField = UISearchTextField()
    private var cancelButton: UIButton?

    public var text: String? {
        get { searchTextField.text }
        set {
            searchTextField.text = newValue ?? ""
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    public var placeholder: String? {
        get { searchTextField.placeholder }
        set { searchTextField.placeholder = newValue; setNeedsDisplay() }
    }

    public var searchBarStyle: UISearchBarStyle = .default {
        didSet {
            searchTextField.drawsFieldBackground = searchBarStyle != .minimal
            searchTextField.setNeedsDisplay()
        }
    }

    public var showsCancelButton: Bool = false {
        didSet { if showsCancelButton != oldValue { setNeedsLayout() } }
    }

    public func setShowsCancelButton(_ shows: Bool, animated: Bool) {
        showsCancelButton = shows
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        // Measured: the field's font is system MEDIUM 17, not regular.
        searchTextField.font = .systemFont(ofSize: 17, weight: .medium)
        // Measured: black / white at alpha 0.25, not `placeholderText`.
        searchTextField.placeholderLabel.textColor = UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.25) : UIColor(white: 0, alpha: 0.25)
        })
        searchTextField._searchBar = self
        addSubview(searchTextField)
    }

    open override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UISearchBar.standardHeight)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: UISearchBar.standardHeight)
    }

    /// Measured: (8, (H - 44) / 2, W - 16, 36), shrunk by the cancel button
    /// when one is shown (that part is NOT measured -- file header).
    open override func layoutSubviews() {
        super.layoutSubviews()
        let y = (bounds.height - UISearchBar.standardHeight) / 2
        var right = bounds.width - UISearchBar.fieldSideInset
        if showsCancelButton {
            let b = cancelButton ?? makeCancelButton()
            b.isHidden = false
            let w = b.sizeThatFits(bounds.size).width
            b.frame = CGRect(x: bounds.width - UISearchBar.fieldSideInset - w,
                             y: y, width: w, height: UISearchBar.standardHeight)
            right -= w + UISearchBar.cancelButtonGap
        } else {
            cancelButton?.isHidden = true
        }
        searchTextField.frame = CGRect(x: UISearchBar.fieldSideInset, y: y,
                                       width: max(0, right - UISearchBar.fieldSideInset),
                                       height: UISearchBar.fieldHeight)
    }

    private func makeCancelButton() -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle("Cancel", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: UISearchBar.cancelButtonFontSize)
        b.addTarget(for: .touchUpInside) { [weak self] _, _ in
            guard let self else { return }
            self.delegate?.searchBarCancelButtonClicked(self)
        }
        addSubview(b)
        cancelButton = b
        return b
    }

    // MARK: Delegate plumbing

    /// Called by the field when its text changes (the field routes editing
    /// through the M8 text-input path; the search bar only forwards).
    func _textDidChange() {
        delegate?.searchBar(self, textDidChange: searchTextField.text ?? "")
        setNeedsLayout()
    }

    func _shouldBeginEditing() -> Bool { delegate?.searchBarShouldBeginEditing(self) ?? true }
    func _didBeginEditing() { delegate?.searchBarTextDidBeginEditing(self) }
    func _shouldEndEditing() -> Bool { delegate?.searchBarShouldEndEditing(self) ?? true }
    func _didEndEditing() { delegate?.searchBarTextDidEndEditing(self) }
    func _searchButtonClicked() { delegate?.searchBarSearchButtonClicked(self) }
}
