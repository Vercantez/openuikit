import Foundation

public struct PHPickerCapabilities: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static var search: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 0) }
    public static var stagingArea: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 1) }
    public static var collectionNavigation: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 2) }
    public static var selectionActions: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 3) }
    public static var sensitivityAnalysisIntervention: PHPickerCapabilities {
        PHPickerCapabilities(rawValue: 1 << 4)
    }
}

public struct PHPickerResult: Hashable, @unchecked Sendable {
    public let itemProvider: NSItemProvider
    public var assetIdentifier: String? { storedIdentifier }

    private let storedIdentifier: String?

    @_spi(OpenUIKitHost)
    public init(itemProvider: NSItemProvider, assetIdentifier: String?) {
        self.itemProvider = itemProvider
        self.storedIdentifier = assetIdentifier
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

@MainActor
public protocol PHPickerViewControllerDelegate: AnyObject {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult])
}

@MainActor
public final class PHPickerViewController: NSObject {
    public let configuration: PHPickerConfiguration
    public weak var delegate: (any PHPickerViewControllerDelegate)?

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
        _ = configuration
    }

    public func scrollToInitialPosition() {}

    public func zoomIn() {}

    public func zoomOut() {}
}

extension PHPhotoLibrary {
    public func presentLimitedLibraryPicker(from controller: UIViewController) {
        _ = controller
    }

    public func presentLimitedLibraryPicker(from controller: UIViewController) async -> [String] {
        _ = controller
        return []
    }

    public func presentLimitedLibraryPicker(
        from controller: UIViewController,
        completionHandler: @escaping ([String]) -> Void
    ) {
        _ = controller
        completionHandler([])
    }
}
