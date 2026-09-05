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
/// main thread — empty selection unless `_enqueueResults` ran first.
///
/// Apple: https://developer.apple.com/documentation/photosui/phpickerviewcontroller
public final class PHPickerViewController: UIViewController, @unchecked Sendable {
    public let configuration: PHPickerConfiguration
    public weak var delegate: (any PHPickerViewControllerDelegate)?

    private var queuedResults: [PHPickerResult]?
    private var appliedUpdate: PHPickerConfiguration.Update?

    public init(configuration: PHPickerConfiguration) {
        self.configuration = configuration
        super.init()
    }

    public func deselectAssets(withIdentifiers identifiers: [String]) {
        _ = identifiers
    }

    public func moveAsset(
        withIdentifier identifier: String,
        afterAssetWithIdentifier afterIdentifier: String?
    ) {
        _ = identifier
        _ = afterIdentifier
    }

    public func updatePicker(using configuration: PHPickerConfiguration.Update) {
        appliedUpdate = configuration
    }

    public func scrollToInitialPosition() {}

    public func zoomIn() {}

    public func zoomOut() {}

    /// Queue results for the next `_present()`. Replaces any previous queue.
    /// Not an Apple API; isolated-host / unit-test seam.
    @_spi(OpenUIKitHost)
    public func _enqueueResults(_ results: [PHPickerResult]) {
        queuedResults = results
    }

    @_spi(OpenUIKitHost)
    public var _appliedUpdate: PHPickerConfiguration.Update? { appliedUpdate }

    /// Simulate presentation. Linux shows no UI and returns immediately after
    /// delivering the delegate callback on the main thread.
    ///
    /// Default payload is `[]` (Apple's documented cancel / empty selection).
    /// If `_enqueueResults` ran, those results are delivered once and cleared.
    ///
    /// Delivery rule (Linux host, not measured on iOS): if already on the
    /// main thread, the delegate runs before `_present()` returns so a
    /// synchronous sealed-host test can observe it without pumping a run
    /// loop. Off the main thread, delivery uses `DispatchQueue.main.sync`.
    @_spi(OpenUIKitHost)
    public func _present() {
        let results = queuedResults ?? []
        queuedResults = nil
        deliverOnMain(results)
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
