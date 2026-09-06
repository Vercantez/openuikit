// System pickers / search-controller delegate. APP LADDER §4 rows 11–12.
import Foundation
import XCTest
@_spi(OpenUIKitHost) @testable import OpenUIKit
@_spi(OpenUIKitHost) import PhotosUI
import SafariServices

#if !os(Linux)
@MainActor
#endif
final class SystemPickerTests: XCTestCase {

    // MARK: UISearchController delegate

    func testSearchControllerDelegateOrderOnActivateAndCancel() {
        final class Probe: UISearchControllerDelegate, UISearchResultsUpdating {
            var log: [String] = []
            func willPresentSearchController(_ searchController: UISearchController) { log.append("willPresent") }
            func didPresentSearchController(_ searchController: UISearchController) { log.append("didPresent") }
            func willDismissSearchController(_ searchController: UISearchController) { log.append("willDismiss") }
            func didDismissSearchController(_ searchController: UISearchController) { log.append("didDismiss") }
            func updateSearchResults(for searchController: UISearchController) { log.append("update") }
        }
        let sc = UISearchController(searchResultsController: nil)
        let probe = Probe()
        sc.delegate = probe
        sc.searchResultsUpdater = probe
        sc.isActive = true
        XCTAssertEqual(probe.log, ["willPresent", "update", "didPresent"])
        probe.log.removeAll()
        sc.isActive = false
        XCTAssertEqual(probe.log, ["willDismiss", "update", "didDismiss"])
        XCTAssertFalse(sc.isActive)
        XCTAssertTrue(sc.automaticallyShowsSearchResultsController)
        XCTAssertEqual(sc.searchBarPlacement, .automatic)
        XCTAssertEqual(sc.scopeBarActivation, .automatic)
    }

    func testSearchSuggestionsSelectClearsListAndUpdates() {
        final class Probe: UISearchResultsUpdating {
            var selected: String?
            var updates = 0
            func updateSearchResults(for searchController: UISearchController) { updates += 1 }
            func updateSearchResults(for searchController: UISearchController,
                                      selecting searchSuggestion: UISearchSuggestion) {
                selected = searchSuggestion.localizedSuggestion
            }
        }
        let sc = UISearchController()
        let probe = Probe()
        sc.searchResultsUpdater = probe
        let item = UISearchSuggestionItem(string: "Coffee")
        sc.searchSuggestions = [item]
        XCTAssertEqual(sc.searchSuggestions?.count, 1)
        sc._selectSuggestion(item)
        XCTAssertEqual(probe.selected, "Coffee")
        XCTAssertNil(sc.searchSuggestions)
        XCTAssertEqual(sc.searchBar.text, "Coffee")
        XCTAssertGreaterThanOrEqual(probe.updates, 1)
    }

    func testPreferredSearchBarPlacementNotifiesDelegate() {
        final class Probe: UISearchControllerDelegate {
            var willTo: UINavigationItem.SearchBarPlacement?
            var didFrom: UINavigationItem.SearchBarPlacement?
            func searchController(_ searchController: UISearchController,
                                  willChangeTo newPlacement: UINavigationItem.SearchBarPlacement) {
                willTo = newPlacement
            }
            func searchController(_ searchController: UISearchController,
                                    didChangeFrom previousPlacement: UINavigationItem.SearchBarPlacement) {
                didFrom = previousPlacement
            }
        }
        let sc = UISearchController(searchResultsController: nil)
        let probe = Probe()
        sc.delegate = probe
        let item = UINavigationItem(title: "Library")
        item.searchController = sc
        XCTAssertEqual(item.preferredSearchBarPlacement, .automatic)
        XCTAssertEqual(item.searchBarPlacement, .automatic)
        item.preferredSearchBarPlacement = .stacked
        XCTAssertEqual(probe.willTo, .stacked)
        XCTAssertEqual(probe.didFrom, .automatic)
        XCTAssertEqual(sc.searchBarPlacement, .stacked)
        XCTAssertNotNil(item.searchBarPlacementBarButtonItem)
        XCTAssertTrue(item.searchBarPlacementAllowsToolbarIntegration)
    }

    func testScopeBarActivationManualWhenShowsScopeBarSet() {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchBar.scopeButtonTitles = ["All", "Unread"]
        XCTAssertFalse(sc.searchBar.showsScopeBar)
        sc.isActive = true
        XCTAssertTrue(sc.searchBar.showsScopeBar)
        sc.searchBar.showsScopeBar = false
        XCTAssertEqual(sc.scopeBarActivation, .manual)
        sc.searchBar.selectedScopeButtonIndex = 1
        XCTAssertEqual(sc.searchBar.selectedScopeIndex, 1)
    }

    func testAutomaticallyShowsSearchResultsControllerFollowsQuery() {
        let results = UIViewController()
        let sc = UISearchController(searchResultsController: results)
        sc.isActive = true
        XCTAssertFalse(sc.showsSearchResultsController)
        sc.searchBar.text = "Row"
        sc.searchBar(sc.searchBar, textDidChange: "Row")
        XCTAssertTrue(sc.showsSearchResultsController)
        XCTAssertTrue(results.parent === sc)
        sc.searchBar.text = ""
        sc.searchBar(sc.searchBar, textDidChange: "")
        XCTAssertFalse(sc.showsSearchResultsController)
    }

    // MARK: Document picker

    func testDocumentPickerOpeningStoresTypesAndCancels() {
        final class Probe: UIDocumentPickerDelegate {
            var cancelled = 0
            var picked: [URL] = []
            func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { cancelled += 1 }
            func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                picked = urls
            }
        }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .pdf], asCopy: true)
        XCTAssertEqual(picker.allowedContentTypes.map(\.identifier), ["public.image", "com.adobe.pdf"])
        XCTAssertTrue(picker.asCopy)
        XCTAssertFalse(picker.allowsMultipleSelection)
        XCTAssertFalse(picker.shouldShowFileExtensions)
        let probe = Probe()
        picker.delegate = probe
        picker._hostCancel()
        XCTAssertEqual(probe.cancelled, 1)
        picker._hostCancel()
        XCTAssertEqual(probe.cancelled, 1, "one completion per presentation")

        let exporter = UIDocumentPickerViewController(forExporting: [URL(fileURLWithPath: "/tmp/a.txt")])
        XCTAssertEqual(exporter.exportedURLs.count, 1)
        let probe2 = Probe()
        exporter.delegate = probe2
        exporter._hostPick(urls: [URL(fileURLWithPath: "/tmp/a.txt")])
        XCTAssertEqual(probe2.picked.count, 1)
        XCTAssertEqual(probe2.cancelled, 0)
    }

    // MARK: Image picker

    func testImagePickerFailClosedAvailabilityAndCancel() {
        XCTAssertFalse(UIImagePickerController.isSourceTypeAvailable(.camera))
        XCTAssertFalse(UIImagePickerController.isSourceTypeAvailable(.photoLibrary))
        XCTAssertNil(UIImagePickerController.availableMediaTypes(for: .photoLibrary))
        XCTAssertFalse(UIImagePickerController.isCameraDeviceAvailable(.rear))
        XCTAssertFalse(UIImagePickerController.isFlashAvailable(for: .rear))
        XCTAssertNil(UIImagePickerController.availableCaptureModes(for: .front))

        final class Probe: UIImagePickerControllerDelegate {
            var cancelled = 0
            var info: [UIImagePickerController.InfoKey: Any]?
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { cancelled += 1 }
            func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
                self.info = info
            }
        }
        let picker = UIImagePickerController()
        let probe = Probe()
        picker.delegate = probe
        XCTAssertEqual(picker.sourceType, .photoLibrary)
        XCTAssertEqual(picker.mediaTypes, ["public.image"])
        XCTAssertFalse(picker.allowsEditing)
        picker._hostCancel()
        XCTAssertEqual(probe.cancelled, 1)

        let picker2 = UIImagePickerController()
        let probe2 = Probe()
        picker2.delegate = probe2
        picker2._hostPick(info: [.originalImage: UIColor.white])
        XCTAssertEqual(probe2.cancelled, 0)
        XCTAssertNotNil(probe2.info?[.originalImage])
        XCTAssertFalse(picker2.startVideoCapture())
    }

    // MARK: Color picker

    func testColorPickerSelectedColorAndDelegate() {
        final class Probe: UIColorPickerViewControllerDelegate {
            var colors: [UIColor] = []
            var continuous: [Bool] = []
            var finished = 0
            func colorPickerViewController(_ viewController: UIColorPickerViewController,
                                           didSelect color: UIColor,
                                           continuously: Bool) {
                colors.append(color)
                continuous.append(continuously)
            }
            func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
                finished += 1
            }
        }
        let picker = UIColorPickerViewController()
        XCTAssertEqual(picker.selectedColor, .white)
        XCTAssertTrue(picker.supportsAlpha)
        picker.selectedColor = UIColor(hue: 0.5, saturation: 1, brightness: 1, alpha: 1)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        XCTAssertTrue(picker.selectedColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a))
        XCTAssertEqual(h, 0.5, accuracy: 0.01)
        XCTAssertEqual(s, 1, accuracy: 0.01)
        XCTAssertEqual(b, 1, accuracy: 0.01)

        let probe = Probe()
        picker.delegate = probe
        picker.loadViewIfNeeded()
        XCTAssertNotNil(picker.view)
        picker._hostFinish()
        XCTAssertEqual(probe.finished, 1)
    }

    // MARK: Font picker

    func testFontPickerCancelAndHostPick() {
        final class Probe: UIFontPickerViewControllerDelegate {
            var cancelled = 0
            var picked = 0
            func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) { cancelled += 1 }
            func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) { picked += 1 }
        }
        let config = UIFontPickerViewController.Configuration()
        config.includeFaces = true
        let picker = UIFontPickerViewController(configuration: config)
        XCTAssertTrue(picker.configuration.includeFaces)
        config.includeFaces = false
        XCTAssertTrue(picker.configuration.includeFaces, "init copies configuration")
        let probe = Probe()
        picker.delegate = probe
        picker._hostCancel()
        XCTAssertEqual(probe.cancelled, 1)

        let picker2 = UIFontPickerViewController()
        let probe2 = Probe()
        picker2.delegate = probe2
        picker2._hostPick(descriptor: UIFontDescriptor(pointSize: 17, weight: .bold, design: .default))
        XCTAssertEqual(probe2.picked, 1)
        XCTAssertEqual(picker2.selectedFontDescriptor?.weight, .bold)
    }

    // MARK: Print

    func testPrintControllersFailClosed() {
        XCTAssertFalse(UIPrintInteractionController.isPrintingAvailable)
        XCTAssertTrue(UIPrintInteractionController.printableUTIs.isEmpty)
        XCTAssertFalse(UIPrintInteractionController.canPrint(URL(fileURLWithPath: "/tmp/a.pdf")))
        XCTAssertFalse(UIPrintInteractionController.canPrint(Data()))
        var completed: Bool?
        let ok = UIPrintInteractionController.shared.present(animated: false) { _, done, _ in
            completed = done
        }
        XCTAssertFalse(ok)
        XCTAssertEqual(completed, false)

        var picked = true
        let printerPicker = UIPrinterPickerController(initiallySelectedPrinter: nil)
        let shown = printerPicker.present(animated: false) { _, userDidSelect, _ in
            picked = userDidSelect
        }
        XCTAssertFalse(shown)
        XCTAssertFalse(picked)
        let printer = UIPrinter(url: URL(string: "ipp://example.test/printer")!)
        var contacted = true
        printer.contactPrinter { contacted = $0 }
        XCTAssertFalse(contacted)
    }

    // MARK: Document browser

    func testDocumentBrowserHostPickAndUnavailableReveal() {
        final class Probe: UIDocumentBrowserViewControllerDelegate {
            var urls: [URL] = []
            func documentBrowser(_ controller: UIDocumentBrowserViewController,
                                  didPickDocumentsAt documentURLs: [URL]) {
                urls = documentURLs
            }
        }
        let browser = UIDocumentBrowserViewController(forOpening: [.pdf, .text])
        XCTAssertTrue(browser.allowsDocumentCreation)
        XCTAssertFalse(browser.allowsPickingMultipleItems)
        let probe = Probe()
        browser.delegate = probe
        let file = URL(fileURLWithPath: "/tmp/note.pdf")
        browser._hostPick(urls: [file])
        XCTAssertEqual(probe.urls, [file])

        var revealError: Error?
        browser.revealDocument(at: file, importIfNeeded: false) { _, error in
            revealError = error
        }
        XCTAssertNotNil(revealError)
        let transition = browser.transitionController(forDocumentAt: file)
        XCTAssertEqual(transition.transitionDuration(using: nil), 0)
    }

    // MARK: SafariServices delegate extras

    func testSafariDelegateOptionalMethodsHaveDefaults() {
        final class Probe: NSObject, SFSafariViewControllerDelegate {
            var finished = 0
            func safariViewControllerDidFinish(_ controller: SFSafariViewController) { finished += 1 }
        }
        // The class is @MainActor only off Linux (project rule for XCTest there);
        // the picker init and delegate defaults are main-actor isolated, so the
        // Linux test bundle needs the explicit hop.
        MainActor.assumeIsolated {
            let url = URL(string: "http://127.0.0.1/")!
            let safari = SFSafariViewController(url: url)
            let probe = Probe()
            safari.delegate = probe
            let items = probe.safariViewController(safari, activityItemsFor: url, title: nil)
            XCTAssertTrue(items.isEmpty)
            XCTAssertTrue(probe.safariViewController(safari, excludedActivityTypesFor: url, title: nil).isEmpty)
        }
        probe.safariViewController(safari, initialLoadDidRedirectTo: url)
        probe.safariViewControllerWillOpenInBrowser(safari)
        probe.safariViewControllerDidFinish(safari)
        XCTAssertEqual(probe.finished, 1)
    }

    // MARK: Activity

    func testActivityViewControllerStillCompletes() {
        let vc = UIActivityViewController(activityItems: ["x"], applicationActivities: nil)
        XCTAssertTrue(vc.availableActivities.isEmpty)
        XCTAssertEqual(UIActivity.ActivityType.addToHomeScreen.rawValue,
                       "com.apple.UIKit.activity.AddToHomeScreen")
    }

    // MARK: PhotosUI

    func testPHPickerFailClosedEmptyAndHostEnqueue() {
        final class Probe: PHPickerViewControllerDelegate {
            var results: [PHPickerResult]?
            func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                self.results = results
            }
        }
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0
        let picker = PHPickerViewController(configuration: config)
        let probe = Probe()
        picker.delegate = probe
        picker._present()
        XCTAssertEqual(probe.results?.count, 0)

        let picker2 = PHPickerViewController(configuration: PHPickerConfiguration())
        let probe2 = Probe()
        picker2.delegate = probe2
        let queued = PHPickerResult._hostResult(
            assetIdentifier: "asset-1", typeIdentifier: "public.jpeg", payload: Data([1, 2, 3]))
        picker2._enqueueResults([queued])
        picker2._present()
        XCTAssertEqual(probe2.results?.count, 1)
        XCTAssertEqual(probe2.results?.first?.assetIdentifier, "asset-1")
        XCTAssertEqual(PHPickerFilter.any(of: [.images, .videos]),
                       PHPickerFilter.any(of: [.images, .videos]))
    }
}

