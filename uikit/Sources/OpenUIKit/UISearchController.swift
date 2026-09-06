// UISearchController. Owner: viewcontroller module (conformance app Tabs).
//
// The public surface a UINavigationItem.searchController assignment needs:
// a search bar, an updater, `isActive`, and the two presentation flags
// UIKit apps set. Chrome (the bar's slot, cancel, hide-on-scroll) lives
// on UINavigationBar / UINavigationController; this type is the object
// those bars read. Numbers next to those rules are measured from Tabs
// captures on the iPhone SE 2x / iOS 26.1, not guessed here.
//
// APP LADDER §4 row 11: UISearchControllerDelegate will/did present/dismiss,
// searchResultsController, automaticallyShowsSearchResultsController,
// showsSearchResultsController, searchSuggestions, scopeBarActivation,
// and iOS 26 navigationItem.searchController placement. Delegate order is
// unit-tested; placement chrome is the already-measured Ledger/Tabs dock.

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
    func updateSearchResults(for searchController: UISearchController,
                             selecting searchSuggestion: UISearchSuggestion)
}

extension UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController,
                                     selecting searchSuggestion: UISearchSuggestion) {}
}

@preconcurrency @MainActor
public protocol UISearchControllerDelegate: AnyObject {
    func willPresentSearchController(_ searchController: UISearchController)
    func didPresentSearchController(_ searchController: UISearchController)
    func willDismissSearchController(_ searchController: UISearchController)
    func didDismissSearchController(_ searchController: UISearchController)
    func presentSearchController(_ searchController: UISearchController)
    func searchController(_ searchController: UISearchController,
                           willChangeTo newPlacement: UINavigationItem.SearchBarPlacement)
    func searchController(_ searchController: UISearchController,
                          didChangeFrom previousPlacement: UINavigationItem.SearchBarPlacement)
}

extension UISearchControllerDelegate {
    public func willPresentSearchController(_ searchController: UISearchController) {}
    public func didPresentSearchController(_ searchController: UISearchController) {}
    public func willDismissSearchController(_ searchController: UISearchController) {}
    public func didDismissSearchController(_ searchController: UISearchController) {}
    public func presentSearchController(_ searchController: UISearchController) {}
    public func searchController(_ searchController: UISearchController,
                                willChangeTo newPlacement: UINavigationItem.SearchBarPlacement) {}
    public func searchController(_ searchController: UISearchController,
                                 didChangeFrom previousPlacement: UINavigationItem.SearchBarPlacement) {}
}

@preconcurrency @MainActor
open class UISearchController: UIViewController, UISearchBarDelegate,
                               UIViewControllerTransitioningDelegate,
                               UIViewControllerAnimatedTransitioning {
    public enum ScopeBarActivation: Int, Sendable {
        case automatic = 0
        case manual = 1
        case onTextEntry = 2
        case onSearchActivation = 3
    }

    public let searchBar: UISearchBar
    public weak var searchResultsUpdater: UISearchResultsUpdating?
    public weak var delegate: UISearchControllerDelegate?
    public private(set) var searchResultsController: UIViewController?

    /// Dims the presenting view while active. Stored; the Tabs app sets
    /// it false so the table stays the results view.
    public var obscuresBackgroundDuringPresentation: Bool = true
    /// iOS 8–12 spelling. Same storage as `obscuresBackgroundDuringPresentation`.
    public var dimsBackgroundDuringPresentation: Bool {
        get { obscuresBackgroundDuringPresentation }
        set { obscuresBackgroundDuringPresentation = newValue }
    }
    /// Stored for source compatibility. iOS 26 honours this for the
    /// bottom-docked phone search (Ledger t3000 collapses the bar to
    /// height 0). Tab-hosted search keeps the bar (it hosts the field).
    public var hidesNavigationBarDuringPresentation: Bool = true
    public var automaticallyShowsCancelButton: Bool = true

    /// When true (default), results-controller visibility follows the query.
    /// Setting `showsSearchResultsController` directly flips this to false.
    public var automaticallyShowsSearchResultsController: Bool = true
    public var showsSearchResultsController: Bool = false {
        didSet {
            if !showsSearchResultsControllerAppliesAutomatically {
                automaticallyShowsSearchResultsController = false
            }
            applyResultsControllerVisibility()
        }
    }
    private var showsSearchResultsControllerAppliesAutomatically = false

    public var automaticallyShowsScopeBar: Bool = true {
        didSet {
            if automaticallyShowsScopeBar {
                scopeBarActivation = .automatic
            } else {
                scopeBarActivation = .manual
            }
        }
    }
    public var scopeBarActivation: ScopeBarActivation = .automatic {
        didSet { applyScopeBarVisibility() }
    }

    public var searchSuggestions: [UISearchSuggestion]? {
        didSet { /* menu chrome unmeasured; storage is the API */ }
    }
    public var ignoresSearchSuggestionsForSearchBarPlacementStacked: Bool = false

    /// The navigation item currently displaying this controller, if any.
    weak var _item: UINavigationItem?

    public var searchBarPlacement: UINavigationItem.SearchBarPlacement {
        _item?.searchBarPlacement ?? .automatic
    }

    public var isActive: Bool = false {
        didSet {
            guard isActive != oldValue else { return }
            applyActiveState()
        }
    }

    public convenience override init() {
        self.init(searchResultsController: nil)
    }

    public init(searchResultsController: UIViewController?) {
        self.searchResultsController = searchResultsController
        self.searchBar = UISearchBar()
        super.init()
        searchBar.delegate = self
        searchBar._owningSearchController = self
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.searchResultsController = nil
        self.searchBar = UISearchBar()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        searchBar.delegate = self
        searchBar._owningSearchController = self
    }

    func applyActiveState() {
        if isActive {
            delegate?.willPresentSearchController(self)
            delegate?.presentSearchController(self)
        } else {
            delegate?.willDismissSearchController(self)
        }
        if automaticallyShowsCancelButton {
            searchBar.setShowsCancelButton(isActive, animated: false)
        }
        // MEASURED merge-keyboard Notes t4000: isActive alone does not
        // raise the remote keyboard (golden still shows the tab bar).
        // Tabs focusSearch calls searchBar.becomeFirstResponder
        // explicitly. Do not become first responder from isActive.
        if isActive {
            // MEASURED Notes t6000 / Tabs t6000, iPhone SE 2x / iOS 26.1:
            // after cancel inside a tab-bar nav the inactive slot stays
            // visible (bar 114 = 54+60, inset 124) until scroll hides it.
            // First rest (t200) keeps height 0 — only a prior isActive
            // reveals the slot. Ledger (no tab bar) restores 54.
            _item?._bar?.searchSlotRevealed = true
        } else {
            _ = searchBar.resignFirstResponder()
            searchSuggestions = nil
        }
        applyAutomaticResultsVisibility()
        applyScopeBarVisibility()
        searchResultsUpdater?.updateSearchResults(for: self)
        _item?._bar?._searchPresentationChanged()
        if isActive {
            delegate?.didPresentSearchController(self)
        } else {
            delegate?.didDismissSearchController(self)
        }
    }

    func applyAutomaticResultsVisibility() {
        guard automaticallyShowsSearchResultsController else { return }
        let text = searchBar.text ?? ""
        let shouldShow = isActive && !text.isEmpty && searchResultsController != nil
        showsSearchResultsControllerAppliesAutomatically = true
        showsSearchResultsController = shouldShow
        showsSearchResultsControllerAppliesAutomatically = false
        automaticallyShowsSearchResultsController = true
    }

    func applyResultsControllerVisibility() {
        guard let results = searchResultsController else { return }
        if showsSearchResultsController {
            if results.parent !== self {
                addChild(results)
                loadViewIfNeeded()
                results.view.frame = view.bounds
                results.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view.addSubview(results.view)
                results.didMove(toParent: self)
            }
        } else if results.parent === self {
            results.willMove(toParent: nil)
            results.view.removeFromSuperview()
            results.removeFromParent()
        }
    }

    func applyScopeBarVisibility() {
        let titles = searchBar.scopeButtonTitles ?? []
        let enoughTitles = titles.count >= 2
        switch scopeBarActivation {
        case .automatic:
            searchBar._setShowsScopeBarFromController(isActive && enoughTitles)
        case .manual:
            break
        case .onTextEntry:
            let text = searchBar.text ?? ""
            searchBar._setShowsScopeBarFromController(isActive && enoughTitles && !text.isEmpty)
        case .onSearchActivation:
            searchBar._setShowsScopeBarFromController(isActive && enoughTitles)
        }
    }

    func _placementWillChange(to newPlacement: UINavigationItem.SearchBarPlacement) {
        delegate?.searchController(self, willChangeTo: newPlacement)
    }

    func _placementDidChange(from previous: UINavigationItem.SearchBarPlacement) {
        delegate?.searchController(self, didChangeFrom: previous)
    }

    /// Host / test seam: select a suggestion the way the iOS menu does.
    /// Clears `searchSuggestions` (SDK: interaction selects a suggestion
    /// and then nils the list).
    @_spi(OpenUIKitHost)
    public func _selectSuggestion(_ suggestion: UISearchSuggestion) {
        if let text = suggestion.localizedSuggestion {
            searchBar.text = text
        }
        searchSuggestions = nil
        searchResultsUpdater?.updateSearchResults(for: self, selecting: suggestion)
        searchResultsUpdater?.updateSearchResults(for: self)
        applyAutomaticResultsVisibility()
        applyScopeBarVisibility()
    }

    // MARK: UISearchBarDelegate

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if !isActive { isActive = true }
    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchSuggestions = nil
        applyAutomaticResultsVisibility()
        applyScopeBarVisibility()
        searchResultsUpdater?.updateSearchResults(for: self)
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isActive = false
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchResultsUpdater?.updateSearchResults(for: self)
    }

    public func searchBar(_ searchBar: UISearchBar,
                           selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchSuggestions = nil
        searchResultsUpdater?.updateSearchResults(for: self)
    }

    // MARK: UIViewControllerAnimatedTransitioning

    public func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval { 0 }

    public func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        transitionContext.completeTransition(true)
    }
}
