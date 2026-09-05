import Foundation
#if canImport(Dispatch)
import Dispatch
#endif

public struct PHPickerResult: Hashable, @unchecked Sendable {
    public let itemProvider: NSItemProvider
    public var assetIdentifier: String? { storedIdentifier }

    private let storedIdentifier: String?

    @_spi(OpenUIKitHost)
    public init(itemProvider: NSItemProvider, assetIdentifier: String?) {
        self.itemProvider = itemProvider
        self.storedIdentifier = assetIdentifier
    }

    /// Host seam: a result whose item provider already has a registered
    /// representation. Type identifiers are the portable UTType strings
    /// (`public.jpeg`, `public.image`, `public.movie`) used by the isolated
    /// UniformTypeIdentifiers lookalike and the port's UniformTypeIdentifiers.
    ///
    /// Apple: https://developer.apple.com/documentation/photosui/phpickerresult-swift.struct
    @_spi(OpenUIKitHost)
    public static func _hostResult(
        assetIdentifier: String?,
        typeIdentifier: String,
        payload: Data
    ) -> PHPickerResult {
        let provider = NSItemProvider()
        provider.registerDataRepresentation(
            forTypeIdentifier: typeIdentifier,
            visibility: .all
        ) { completion in
            completion(payload, nil)
            return nil
        }
        return PHPickerResult(itemProvider: provider, assetIdentifier: assetIdentifier)
    }

    public static func == (lhs: PHPickerResult, rhs: PHPickerResult) -> Bool {
        lhs.storedIdentifier == rhs.storedIdentifier
            && lhs.itemProvider === rhs.itemProvider
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(storedIdentifier)
        hasher.combine(ObjectIdentifier(itemProvider))
    }
}

public protocol PHPickerViewControllerDelegate: AnyObject {
    /// Apple documents this as the finish/cancel callback; cancel delivers
    /// an empty array. The protocol is `@MainActor` on iOS 26.1
    /// (symbol graph `s:8PhotosUI30PHPickerViewControllerDelegateP`).
    /// https://developer.apple.com/documentation/photosui/phpickerviewcontrollerdelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult])
}

/// Linux has no Photos picker chrome. `_present()` is the documented host
/// seam: it returns after delivering `picker(_:didFinishPicking:)` on the
/// main thread — empty selection unless `_enqueueResults` ran first or a
/// host library has a current selection.
///
/// Apple: https://developer.apple.com/documentation/photosui/phpickerviewcontroller
public final class PHPickerViewController: UIViewController, @unchecked Sendable {
    public let configuration: PHPickerConfiguration
    public weak var delegate: (any PHPickerViewControllerDelegate)?

    private var queuedResults: [PHPickerResult]?
    private var appliedUpdate: PHPickerConfiguration.Update?
    private var hostLibrary: [PHPickerHostAsset] = []
    private var selectedIdentifiers: [String]
    private var liveSelectionLimit: Int
    private var liveEdgesWithoutContentMargins: NSDirectionalRectEdge
    private var didScrollToInitialPosition = false
    private var zoomSteps = 0

    public init(configuration: PHPickerConfiguration) {
        self.configuration = configuration
        selectedIdentifiers = configuration.preselectedAssetIdentifiers
        liveSelectionLimit = configuration.selectionLimit
        liveEdgesWithoutContentMargins = configuration.edgesWithoutContentMargins
        super.init()
    }

    public func deselectAssets(withIdentifiers identifiers: [String]) {
        let removing = Set(identifiers)
        selectedIdentifiers.removeAll { removing.contains($0) }
    }

    public func moveAsset(
        withIdentifier identifier: String,
        afterAssetWithIdentifier afterIdentifier: String?
    ) {
        guard let from = selectedIdentifiers.firstIndex(of: identifier) else {
            return
        }
        selectedIdentifiers.remove(at: from)
        if let afterIdentifier, let after = selectedIdentifiers.firstIndex(of: afterIdentifier) {
            selectedIdentifiers.insert(identifier, at: after + 1)
        } else {
            selectedIdentifiers.insert(identifier, at: 0)
        }
    }

    public func updatePicker(using configuration: PHPickerConfiguration.Update) {
        appliedUpdate = configuration
        if let selectionLimit = configuration.selectionLimit {
            liveSelectionLimit = selectionLimit
            capSelection()
        }
        if let edges = configuration.edgesWithoutContentMargins {
            liveEdgesWithoutContentMargins = edges
        }
    }

    public func scrollToInitialPosition() {
        didScrollToInitialPosition = true
    }

    public func zoomIn() {
        zoomSteps += 1
    }

    public func zoomOut() {
        zoomSteps -= 1
    }

    /// Queue results for the next `_present()`. Replaces any previous queue
    /// and takes precedence over the host library. Not an Apple API.
    @_spi(OpenUIKitHost)
    public func _enqueueResults(_ results: [PHPickerResult]) {
        queuedResults = results
    }

    /// Install a portable Photos-lane catalog. Preselected identifiers that
    /// are absent from the catalog are dropped. Not an Apple API.
    @_spi(OpenUIKitHost)
    public func _installLibrary(_ assets: [PHPickerHostAsset]) {
        hostLibrary = assets
        let known = Set(assets.map(\.identifier))
        selectedIdentifiers.removeAll { !known.contains($0) }
        selectedIdentifiers.removeAll { identifier in
            guard let asset = hostLibrary.first(where: { $0.identifier == identifier }) else {
                return true
            }
            return !assetMatchesFilter(asset)
        }
        capSelection()
    }

    /// Append matching library identifiers to the current selection, honoring
    /// `selectionLimit` (`0` means unlimited) and skipping duplicates.
    /// Ordered / continuousAndOrdered keep insertion order. Not an Apple API.
    @_spi(OpenUIKitHost)
    public func _hostSelect(_ identifiers: [String]) {
        for identifier in identifiers {
            guard !selectedIdentifiers.contains(identifier) else { continue }
            guard let asset = hostLibrary.first(where: { $0.identifier == identifier }) else {
                continue
            }
            guard assetMatchesFilter(asset) else { continue }
            if liveSelectionLimit > 0, selectedIdentifiers.count >= liveSelectionLimit {
                continue
            }
            selectedIdentifiers.append(identifier)
        }
    }

    @_spi(OpenUIKitHost)
    public var _appliedUpdate: PHPickerConfiguration.Update? { appliedUpdate }

    @_spi(OpenUIKitHost)
    public var _selectedIdentifiers: [String] { selectedIdentifiers }

    @_spi(OpenUIKitHost)
    public var _effectiveSelectionLimit: Int { liveSelectionLimit }

    @_spi(OpenUIKitHost)
    public var _effectiveEdgesWithoutContentMargins: NSDirectionalRectEdge {
        liveEdgesWithoutContentMargins
    }

    @_spi(OpenUIKitHost)
    public var _didScrollToInitialPosition: Bool { didScrollToInitialPosition }

    @_spi(OpenUIKitHost)
    public var _zoomSteps: Int { zoomSteps }

    /// Simulate presentation. Linux shows no UI and returns immediately after
    /// delivering the delegate callback on the main thread.
    ///
    /// Default payload is `[]` (Apple's documented cancel / empty selection).
    /// If `_enqueueResults` ran, those results are delivered once and cleared.
    /// Otherwise the current host selection is delivered as `PHPickerResult`
    /// values whose item providers register the asset type identifiers.
    ///
    /// Delivery rule (Linux host, not measured on iOS): if already on the
    /// main thread, the delegate runs before `_present()` returns so a
    /// synchronous sealed-host test can observe it without pumping a run
    /// loop. Off the main thread, delivery uses `DispatchQueue.main.sync`.
    @_spi(OpenUIKitHost)
    public func _present() {
        let results: [PHPickerResult]
        if let queuedResults {
            results = queuedResults
            self.queuedResults = nil
        } else {
            results = selectedIdentifiers.compactMap { identifier in
                hostLibrary.first(where: { $0.identifier == identifier }).map { asset in
                    PHPickerResult._hostResult(
                        assetIdentifier: asset.identifier,
                        typeIdentifier: asset.typeIdentifier,
                        payload: asset.payload
                    )
                }
            }
        }
        deliverOnMain(results)
    }

    private func assetMatchesFilter(_ asset: PHPickerHostAsset) -> Bool {
        guard let filter = configuration.filter else { return true }
        return filter._matches(asset)
    }

    private func capSelection() {
        if liveSelectionLimit > 0, selectedIdentifiers.count > liveSelectionLimit {
            selectedIdentifiers = Array(selectedIdentifiers.prefix(liveSelectionLimit))
        }
    }

    private func deliverOnMain(_ results: [PHPickerResult]) {
        let invoke = { [weak self] in
            guard let self else { return }
            self.delegate?.picker(self, didFinishPicking: results)
        }
        if Thread.isMainThread {
            invoke()
        } else {
            DispatchQueue.main.sync(execute: invoke)
        }
    }
}

extension PHPhotoLibrary {
    /// Linux listed gap: no limited-library UI. The call is a no-op.
    /// Apple: https://developer.apple.com/documentation/photokit/phphotolibrary/presentlimitedlibrarypicker(from:)
    public func presentLimitedLibraryPicker(from controller: UIViewController) {
        _ = controller
    }

    public func presentLimitedLibraryPicker(from controller: UIViewController) async -> [String] {
        _ = controller
        return []
    }

    /// Linux listed gap: no limited-library UI. Completes immediately with
    /// an empty identifier list. Apple's queue and cancel payload are
    /// unobserved (see oracle-questions.tsv).
    public func presentLimitedLibraryPicker(
        from controller: UIViewController,
        completionHandler: @escaping ([String]) -> Void
    ) {
        _ = controller
        completionHandler([])
    }
}
