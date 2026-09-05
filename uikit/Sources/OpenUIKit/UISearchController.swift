// UISearchController. Owner: viewcontroller module (conformance app Tabs).
//
// The public surface a UINavigationItem.searchController assignment needs:
// a search bar, an updater, `isActive`, and the two presentation flags
// UIKit apps set. Chrome (the bar's slot, cancel, hide-on-scroll) lives
// on UINavigationBar / UINavigationController; this type is the object
// those bars read. Numbers next to those rules are measured from Tabs
// captures on the iPhone SE 2x / iOS 26.1, not guessed here.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

/// UIKit's updater. The search controller calls this when the query or
/// the active state changes.
@preconcurrency @MainActor
public protocol UISearchResultsUpdating: AnyObject {
    func updateSearchResults(for searchController: UISearchController)
}

@preconcurrency @MainActor
open class UISearchController: UIViewController, UISearchBarDelegate {
    public let searchBar: UISearchBar
    public weak var searchResultsUpdater: UISearchResultsUpdating?
    public private(set) var searchResultsController: UIViewController?

    /// Dims the presenting view while active. Stored; the Tabs app sets
    /// it false so the table stays the results view.
    public var obscuresBackgroundDuringPresentation: Bool = true
    /// Stored for source compatibility; OpenUIKit does not hide the
    /// navigation bar itself while active (the bar hosts the search field).
    public var hidesNavigationBarDuringPresentation: Bool = true
    public var automaticallyShowsCancelButton: Bool = true

    /// The navigation item currently displaying this controller, if any.
    weak var _item: UINavigationItem?

    /// MEASURED `/tmp/tabs-search-slot-probe` + Tabs t6000, iPhone SE 2x /
    /// iOS 26.1, hide-on-scroll default: after the first active→inactive
    /// the search occupies a 60 pt stacked slot under the 54 pt bar
    /// (nav `[0, 10, 375, 114]`, table adj.top **124**). Initial rest
    /// (never activated) keeps the slot at 0 (Tabs t200).
    var _slotRevealed = false

    public var isActive: Bool = false {
        didSet {
            guard isActive != oldValue else { return }
            applyActiveState()
        }
    }

    public init(searchResultsController: UIViewController?) {
        self.searchResultsController = searchResultsController
        self.searchBar = UISearchBar()
        super.init()
        searchBar.delegate = self
    }

    func applyActiveState() {
        if automaticallyShowsCancelButton {
            searchBar.setShowsCancelButton(isActive, animated: false)
        }
        if isActive {
            _ = searchBar.becomeFirstResponder()
        } else {
            _slotRevealed = true
            _ = searchBar.resignFirstResponder()
        }
        searchResultsUpdater?.updateSearchResults(for: self)
        _item?._bar?._searchPresentationChanged()
    }

    // MARK: UISearchBarDelegate

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if !isActive { isActive = true }
    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchResultsUpdater?.updateSearchResults(for: self)
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isActive = false
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchResultsUpdater?.updateSearchResults(for: self)
    }
}
