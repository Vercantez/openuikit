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
        // MEASURED merge-keyboard Notes t4000: isActive alone does not
        // raise the remote keyboard (golden still shows the tab bar).
        // Tabs focusSearch calls searchBar.becomeFirstResponder
        // explicitly. Do not become first responder from isActive.
        if !isActive {
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
