// PhotosUI — PHPickerViewController bridged to the photosui-lane model.
// Linux / the port has no Photos picker chrome. Presentation is
// fail-closed: Cancel and `_present()` deliver `[]` unless the host
// enqueued results first (`_enqueueResults`).
import Foundation
import UIKit

public struct PHPickerMode: Equatable, Hashable, Sendable {
    private let rawValue: UInt8
    private init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let `default` = PHPickerMode(rawValue: 0)
    public static var compact: PHPickerMode { PHPickerMode(rawValue: 1) }
}

public enum PHPickerConfigurationAssetRepresentationMode: Int, Hashable, Sendable {
    case automatic = 0
    case current = 1
    case compatible = 2
}

public enum PHPickerConfigurationSelection: Int, Hashable, Sendable {
    case `default` = 0
    case ordered = 1
    case continuous = 2
    case continuousAndOrdered = 3
}

public struct PHPickerCapabilities: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static var search: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 0) }
    public static var stagingArea: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 1) }
    public static var collectionNavigation: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 2) }
    public static var selectionActions: PHPickerCapabilities { PHPickerCapabilities(rawValue: 1 << 3) }
    public static var sensitivityAnalysisIntervention: PHPickerCapabilities {
        PHPickerCapabilities(rawValue: 1 << 4)
    }
}

public enum PHAssetPlaybackStyle: Int, Hashable, Sendable {
    case unsupported = 0
    case image = 1
    case imageAnimated = 2
    case livePhoto = 3
    case video = 4
    case videoLooping = 5
}

#if canImport(Photos)
import Photos
#else
public final class PHPhotoLibrary: NSObject {
    public static let shared = PHPhotoLibrary()
    private override init() { super.init() }
}
#endif

#if os(Linux)
/// corelibs Foundation has no NSItemProvider. Darwin uses Foundation's type
/// so a PhotosUI result is the same object an app's model layer holds.
public final class NSItemProvider: NSObject {
    public override init() { super.init() }
}
#endif

public struct PHPickerFilter: Equatable, Hashable, Sendable {
    private indirect enum Storage: Equatable, Hashable, Sendable {
        case images, videos, livePhotos, depthEffectPhotos, screenshots
        case slomoVideos, spatialMedia, cinematicVideos, timelapseVideos
        case screenRecordings, bursts, panoramas
        case playbackStyle(PHAssetPlaybackStyle)
        case any([Storage])
        case all([Storage])
        case not(Storage)
    }
    private let storage: Storage
    private init(_ storage: Storage) { self.storage = storage }

    public static let images = PHPickerFilter(.images)
    public static let videos = PHPickerFilter(.videos)
    public static let livePhotos = PHPickerFilter(.livePhotos)
    public static let depthEffectPhotos = PHPickerFilter(.depthEffectPhotos)
    public static let screenshots = PHPickerFilter(.screenshots)
    public static let slomoVideos = PHPickerFilter(.slomoVideos)
    public static let spatialMedia = PHPickerFilter(.spatialMedia)
    public static let cinematicVideos = PHPickerFilter(.cinematicVideos)
    public static let timelapseVideos = PHPickerFilter(.timelapseVideos)
    public static let screenRecordings = PHPickerFilter(.screenRecordings)
    public static let bursts = PHPickerFilter(.bursts)
    public static let panoramas = PHPickerFilter(.panoramas)

    public static func playbackStyle(_ playbackStyle: PHAssetPlaybackStyle) -> PHPickerFilter {
        PHPickerFilter(.playbackStyle(playbackStyle))
    }
    public static func any(of subfilters: [PHPickerFilter]) -> PHPickerFilter {
        PHPickerFilter(.any(subfilters.map(\.storage)))
    }
    public static func all(of subfilters: [PHPickerFilter]) -> PHPickerFilter {
        PHPickerFilter(.all(subfilters.map(\.storage)))
    }
    public static func not(_ filter: PHPickerFilter) -> PHPickerFilter {
        PHPickerFilter(.not(filter.storage))
    }
}

public struct PHPickerConfiguration: Equatable, Hashable {
    public typealias AssetRepresentationMode = PHPickerConfigurationAssetRepresentationMode
    public typealias Selection = PHPickerConfigurationSelection

    public struct Update: Equatable, Hashable {
        public var selectionLimit: Int?
        public var edgesWithoutContentMargins: NSDirectionalRectEdge?
        public init() {}
    }

    public var preferredAssetRepresentationMode: AssetRepresentationMode = .automatic
    public var selection: Selection = .default
    public var selectionLimit: Int = 1
    public var filter: PHPickerFilter?
    public var preselectedAssetIdentifiers: [String] = []
    public var mode: PHPickerMode = .default
    public var edgesWithoutContentMargins: NSDirectionalRectEdge = []
    public var disabledCapabilities: PHPickerCapabilities = []

    public init() {}
    public init(photoLibrary: PHPhotoLibrary) {
        _ = photoLibrary
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

    @_spi(OpenUIKitHost)
    public static func _hostResult(
        assetIdentifier: String?,
        typeIdentifier: String,
        payload: Data
    ) -> PHPickerResult {
        _ = typeIdentifier
        _ = payload
        return PHPickerResult(itemProvider: NSItemProvider(), assetIdentifier: assetIdentifier)
    }

    public static func == (lhs: PHPickerResult, rhs: PHPickerResult) -> Bool {
        lhs.storedIdentifier == rhs.storedIdentifier && lhs.itemProvider === rhs.itemProvider
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(storedIdentifier)
        hasher.combine(ObjectIdentifier(itemProvider))
    }
}

@preconcurrency @MainActor
public protocol PHPickerViewControllerDelegate: AnyObject {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult])
}

public final class PHPickerViewController: UIViewController {
    public let configuration: PHPickerConfiguration
    public weak var delegate: (any PHPickerViewControllerDelegate)?
    private var queuedResults: [PHPickerResult]?
    private var didFinish = false

    public init(configuration: PHPickerConfiguration) {
        self.configuration = configuration
        super.init()
        modalPresentationStyle = .pageSheet
    }

    public func updatePicker(using configuration: PHPickerConfiguration.Update) {
        _ = configuration
    }

    public func deselectAssets(withIdentifiers identifiers: [String]) { _ = identifiers }
    public func moveAsset(withIdentifier identifier: String,
                           afterAssetWithIdentifier afterIdentifier: String?) {
        _ = identifier
        _ = afterIdentifier
    }
    public func scrollToInitialPosition() {}
    public func zoomIn() {}
    public func zoomOut() {}

    public override func loadView() {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        v.backgroundColor = .systemGroupedBackground
        let label = UILabel()
        label.text = "Photo picker is unavailable."
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.frame = CGRect(x: 24, y: 400, width: 345, height: 48)
        v.addSubview(label)
        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.frame = CGRect(x: 24, y: 460, width: 345, height: 44)
        cancel.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?._finish([])
        }
        v.addSubview(cancel)
        view = v
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !didFinish { _finish([]) }
    }

    @_spi(OpenUIKitHost)
    public func _enqueueResults(_ results: [PHPickerResult]) {
        queuedResults = results
    }

    @_spi(OpenUIKitHost)
    public func _present() {
        let results = queuedResults ?? []
        queuedResults = nil
        _finish(results)
    }

    private func _finish(_ results: [PHPickerResult]) {
        guard !didFinish else { return }
        didFinish = true
        delegate?.picker(self, didFinishPicking: results)
        if presentingViewController != nil { dismiss(animated: true) }
    }
}
