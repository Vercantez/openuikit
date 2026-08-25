// UISearchBar + UISearchBarDelegate. Owner: text-input module (M13
// "delegate protocols" cluster).
//
// HONEST SCOPE, READ THIS FIRST. `UISearchBarDelegate` cannot be declared
// without a `UISearchBar` to name in its signatures, and the census wants the
// delegate (3 uses) more than the bar (9). So this file gives the bar the
// smallest shape that carries real behaviour — a text field plus UIKit's
// delegate callbacks — and NOTHING of the iOS search-bar CHROME:
//
//   - no magnifier glyph, no clear button, no bookmark/results buttons
//   - no Cancel button (`showsCancelButton` is stored and ignored)
//   - no scope bar, no barTintColor / searchBarStyle rendering
//   - the field is a plain `.roundedRect` UITextField spanning the bar
//
// The iOS search field's own metrics have NOT been probed, so nothing here
// is oracle-validated and there is deliberately no fixture: a search bar
// rendered by OpenUIKit will not match real UIKit pixel for pixel. This is
// recorded in docs/KNOWN_GAPS.md. What DOES hold is the delegate contract —
// an app's search logic (text-change filtering, search-button handling,
// begin/end editing) runs correctly.

/// UIKit's protocol, member for member. Everything is defaulted, so a
/// conformance implements only what it uses.
public protocol UISearchBarDelegate: AnyObject {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange,
                   replacementText text: String) -> Bool
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar)
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar)
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int)
}

public extension UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool { true }
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {}
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool { true }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {}
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {}
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange,
                   replacementText text: String) -> Bool { true }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {}
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {}
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {}
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {}
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {}
}

open class UISearchBar: UIView {

    /// The field the bar is built from. Public because everything the bar
    /// itself does not implement (fonts, colours, the caret) is really a
    /// UITextField feature, and an app may need to reach it.
    public let searchTextField = UITextField()

    public weak var delegate: UISearchBarDelegate?

    public var text: String? {
        get { searchTextField.text }
        set { searchTextField.text = newValue }
    }

    public var placeholder: String? {
        get { searchTextField.placeholder }
        set { searchTextField.placeholder = newValue }
    }

    /// Stored for source compatibility; no cancel button is drawn.
    public var showsCancelButton = false
    /// Stored for source compatibility; no scope bar is drawn.
    public var scopeButtonTitles: [String]?
    public var selectedScopeIndex: Int = 0 {
        didSet {
            guard selectedScopeIndex != oldValue else { return }
            delegate?.searchBar(self, selectedScopeButtonIndexDidChange: selectedScopeIndex)
        }
    }

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        searchTextField.borderStyle = .roundedRect
        searchTextField.delegate = bridge
        bridge.owner = self
        // textDidChange follows the field's .editingChanged event, not the
        // selection callback — a caret move is not a text change.
        searchTextField.addTarget(for: .editingChanged) { [weak self] _, _ in
            guard let self else { return }
            self.delegate?.searchBar(self, textDidChange: self.text ?? "")
        }
        addSubview(searchTextField)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        searchTextField.frame = bounds
    }

    @discardableResult
    open override func becomeFirstResponder() -> Bool {
        searchTextField.becomeFirstResponder()
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        searchTextField.resignFirstResponder()
    }

    open override var canBecomeFirstResponder: Bool { false }

    /// The bar's own "the user tapped Cancel" entry point. There is no
    /// cancel BUTTON to tap here (see the file header), so an app or a test
    /// drives it directly; the callback is UIKit's.
    public func _cancel() {
        text = ""
        delegate?.searchBar(self, textDidChange: "")
        delegate?.searchBarCancelButtonClicked(self)
        resignFirstResponder()
    }

    /// Translates UITextField's delegate into UISearchBar's. Kept as a
    /// separate object so a search bar's own `delegate` cannot be confused
    /// with the field's.
    final class Bridge: UITextFieldDelegate {
        weak var owner: UISearchBar?

        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            guard let o = owner else { return true }
            return o.delegate?.searchBarShouldBeginEditing(o) ?? true
        }
        func textFieldDidBeginEditing(_ textField: UITextField) {
            guard let o = owner else { return }
            o.delegate?.searchBarTextDidBeginEditing(o)
        }
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            guard let o = owner else { return true }
            return o.delegate?.searchBarShouldEndEditing(o) ?? true
        }
        func textFieldDidEndEditing(_ textField: UITextField) {
            guard let o = owner else { return }
            o.delegate?.searchBarTextDidEndEditing(o)
        }
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            guard let o = owner else { return true }
            return o.delegate?.searchBar(o, shouldChangeTextIn: range,
                                         replacementText: string) ?? true
        }
        /// The keyboard's return key IS the search button.
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            guard let o = owner else { return true }
            o.delegate?.searchBarSearchButtonClicked(o)
            return true
        }
    }
    let bridge = Bridge()
}
