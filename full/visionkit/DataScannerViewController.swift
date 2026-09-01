import Foundation

/// A delegate that observes data-scanner recognition events.
@MainActor
public protocol DataScannerViewControllerDelegate: AnyObject {
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable
    )
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didAdd addedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    )
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didTapOn item: RecognizedItem
    )
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didRemove removedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    )
    func dataScanner(
        _ dataScanner: DataScannerViewController,
        didUpdate updatedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    )
    func dataScannerDidZoom(_ dataScanner: DataScannerViewController)
}

extension DataScannerViewControllerDelegate {
    @MainActor
    public func dataScanner(
        _ dataScanner: DataScannerViewController,
        becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable
    ) {
        _ = dataScanner
        _ = error
    }

    @MainActor
    public func dataScanner(
        _ dataScanner: DataScannerViewController,
        didAdd addedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        _ = dataScanner
        _ = addedItems
        _ = allItems
    }

    @MainActor
    public func dataScanner(
        _ dataScanner: DataScannerViewController,
        didTapOn item: RecognizedItem
    ) {
        _ = dataScanner
        _ = item
    }

    @MainActor
    public func dataScanner(
        _ dataScanner: DataScannerViewController,
        didRemove removedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        _ = dataScanner
        _ = removedItems
        _ = allItems
    }

    @MainActor
    public func dataScanner(
        _ dataScanner: DataScannerViewController,
        didUpdate updatedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        _ = dataScanner
        _ = updatedItems
        _ = allItems
    }

    @MainActor
    public func dataScannerDidZoom(_ dataScanner: DataScannerViewController) {
        _ = dataScanner
    }
}

/// A view controller that scans the camera for text and barcodes.
///
/// Linux has no camera or A12-class scanner, so `isSupported` and
/// `isAvailable` are `false`. `startScanning()` throws `.unsupported` and
/// `capturePhoto()` throws `VisionKitAvailabilityError.cameraUnavailable`.
@MainActor
open class DataScannerViewController: UIViewController {
    public struct RecognizedDataType: Hashable, Sendable {
        fileprivate enum Kind: Hashable, Sendable {
            case text(languages: [String], textContentType: TextContentType?)
            case barcode(symbologies: [String])
        }

        fileprivate let kind: Kind

        public static func text(
            languages: [String] = [],
            textContentType: TextContentType? = nil
        ) -> RecognizedDataType {
            RecognizedDataType(
                kind: .text(languages: languages, textContentType: textContentType)
            )
        }

        public static func barcode(
            symbologies: [VNBarcodeSymbology] = []
        ) -> RecognizedDataType {
            RecognizedDataType(
                kind: .barcode(symbologies: symbologies.map(\.rawValue))
            )
        }
    }

    public enum QualityLevel: Hashable, Sendable {
        case fast
        case balanced
        case accurate
    }

    public enum TextContentType: Hashable, Sendable {
        case emailAddress
        case flightNumber
        case telephoneNumber
        case dateTimeDuration
        case fullStreetAddress
        case shipmentTrackingNumber
        case URL
        case currency
    }

    public enum ScanningUnavailable: Error, Hashable, Sendable {
        case unsupported
        case cameraRestricted
    }

    public final let recognizedDataTypes: Set<RecognizedDataType>
    public final let qualityLevel: QualityLevel
    public final let recognizesMultipleItems: Bool
    public final let isHighFrameRateTrackingEnabled: Bool
    public final let isPinchToZoomEnabled: Bool
    public final let isGuidanceEnabled: Bool
    public final let isHighlightingEnabled: Bool

    public weak var delegate: (any DataScannerViewControllerDelegate)?
    public private(set) var overlayContainerView = UIView()
    public private(set) var isScanning = false
    public var regionOfInterest: CGRect?

    public var minZoomFactor: Double { 1.0 }
    public var maxZoomFactor: Double { 1.0 }

    private var storedZoomFactor: Double = 1.0
    private let recognizedItemsStream: AsyncStream<[RecognizedItem]>

    public var zoomFactor: Double {
        get { storedZoomFactor }
        set {
            let clamped = min(max(newValue, minZoomFactor), maxZoomFactor)
            guard clamped != storedZoomFactor else { return }
            storedZoomFactor = clamped
            delegate?.dataScannerDidZoom(self)
        }
    }

    public var recognizedItems: AsyncStream<[RecognizedItem]> {
        recognizedItemsStream
    }

    /// Data scanning requires an A12 Bionic chip or later.
    open class var isSupported: Bool { false }

    /// No camera permission or camera device exists on this host.
    open class var isAvailable: Bool { false }

    /// No on-device recognition models are shipped with this Linux port.
    open class var supportedTextRecognitionLanguages: [String] { [] }

    public init(
        recognizedDataTypes: Set<RecognizedDataType>,
        qualityLevel: QualityLevel = .balanced,
        recognizesMultipleItems: Bool = false,
        isHighFrameRateTrackingEnabled: Bool = true,
        isPinchToZoomEnabled: Bool = true,
        isGuidanceEnabled: Bool = true,
        isHighlightingEnabled: Bool = false
    ) {
        self.recognizedDataTypes = recognizedDataTypes
        self.qualityLevel = qualityLevel
        self.recognizesMultipleItems = recognizesMultipleItems
        self.isHighFrameRateTrackingEnabled = isHighFrameRateTrackingEnabled
        self.isPinchToZoomEnabled = isPinchToZoomEnabled
        self.isGuidanceEnabled = isGuidanceEnabled
        self.isHighlightingEnabled = isHighlightingEnabled
        let (stream, continuation) = AsyncStream<[RecognizedItem]>.makeStream()
        continuation.finish()
        recognizedItemsStream = stream
        super.init()
    }

    open override func loadView() {
        super.loadView()
        view.addSubview(overlayContainerView)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        stopScanning()
        super.viewDidDisappear(animated)
    }

    open override func removeFromParent() {
        stopScanning()
        super.removeFromParent()
    }

    open func startScanning() throws {
        throw ScanningUnavailable.unsupported
    }

    open func stopScanning() {
        isScanning = false
    }

    open func capturePhoto() async throws -> UIImage {
        throw VisionKitAvailabilityError.cameraUnavailable
    }
}
