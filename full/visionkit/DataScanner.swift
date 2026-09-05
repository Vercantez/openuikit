import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(Vision)
import Vision
#endif

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
    public func dataScanner(
        _ dataScanner: DataScannerViewController,
        becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable
    ) {
        _ = dataScanner
        _ = error
    }

    public func dataScanner(
        _ dataScanner: DataScannerViewController,
        didAdd addedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        _ = dataScanner
        _ = addedItems
        _ = allItems
    }

    public func dataScanner(
        _ dataScanner: DataScannerViewController,
        didTapOn item: RecognizedItem
    ) {
        _ = dataScanner
        _ = item
    }

    public func dataScanner(
        _ dataScanner: DataScannerViewController,
        didRemove removedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        _ = dataScanner
        _ = removedItems
        _ = allItems
    }

    public func dataScanner(
        _ dataScanner: DataScannerViewController,
        didUpdate updatedItems: [RecognizedItem],
        allItems: [RecognizedItem]
    ) {
        _ = dataScanner
        _ = updatedItems
        _ = allItems
    }

    public func dataScannerDidZoom(_ dataScanner: DataScannerViewController) {
        _ = dataScanner
    }
}

/// Camera data scanner. Linux has no A12 Neural Engine camera pipeline, so
/// `isSupported` and `isAvailable` are false and `startScanning` throws
/// `.unsupported`. No recognized items are ever produced.
///
/// Apple annotates this type `@MainActor`. The isolated Linux host has no
/// UIKit run loop, so the Linux type is usable from synchronous tests.
public class DataScannerViewController: NSObject {
    public struct RecognizedDataType: Hashable, Sendable {
        private enum Kind: Hashable, Sendable {
            case text(languages: [String], textContentType: TextContentType?)
            case barcode(symbologyNames: [String])
        }

        private let kind: Kind

        private init(kind: Kind) {
            self.kind = kind
        }

        public static func text(
            languages: [String] = [],
            textContentType: TextContentType? = nil
        ) -> RecognizedDataType {
            RecognizedDataType(
                kind: .text(languages: languages, textContentType: textContentType)
            )
        }

#if canImport(Vision)
        public static func barcode(
            symbologies: [VNBarcodeSymbology] = []
        ) -> RecognizedDataType {
            RecognizedDataType(
                kind: .barcode(symbologyNames: symbologies.map(\.rawValue))
            )
        }
#endif
    }

    public enum QualityLevel: Hashable, Sendable {
        case fast
        case balanced
        case accurate
    }

    public enum TextContentType: Hashable, Sendable {
        case dateTimeDuration
        case URL
        case fullStreetAddress
        case emailAddress
        case telephoneNumber
        case shipmentTrackingNumber
        case flightNumber
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

    public private(set) var isScanning = false

    /// Linux has no optical zoom hardware. The stored range is `[1, 1]`;
    /// Darwin min/max are unobserved.
    public var minZoomFactor: Double { 1 }

    public var maxZoomFactor: Double { 1 }

    public var zoomFactor: Double {
        get { storedZoomFactor }
        set {
            let clamped = min(max(newValue, minZoomFactor), maxZoomFactor)
            let changed = clamped != storedZoomFactor
            storedZoomFactor = clamped
            if changed, isScanning {
                delegate?.dataScannerDidZoom(self)
            }
        }
    }

    public var regionOfInterest: CGRect?

#if canImport(UIKit)
    public var overlayContainerView: UIView {
        if let storedOverlayContainerView {
            return storedOverlayContainerView
        }
        let view = UIView()
        storedOverlayContainerView = view
        return view
    }

    private var storedOverlayContainerView: UIView?
#endif

    private var storedZoomFactor: Double = 1
    private var recognizedItemsStream: AsyncStream<[RecognizedItem]>?
    private var recognizedItemsContinuation: AsyncStream<[RecognizedItem]>.Continuation?

    public class var isSupported: Bool { false }

    public class var isAvailable: Bool { false }

    public class var supportedTextRecognitionLanguages: [String] { [] }

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
        super.init()
    }

    public var recognizedItems: AsyncStream<[RecognizedItem]> {
        if let recognizedItemsStream {
            return recognizedItemsStream
        }
        let stream = AsyncStream<[RecognizedItem]> { continuation in
            self.recognizedItemsContinuation = continuation
        }
        recognizedItemsStream = stream
        return stream
    }

    public func startScanning() throws {
        // Both `isSupported` and `isAvailable` are false on Linux. Darwin's
        // throw-versus-delegate precedence when both are false is unobserved;
        // Linux throws `.unsupported` and does not invoke the delegate.
        isScanning = false
        throw ScanningUnavailable.unsupported
    }

    public func stopScanning() {
        isScanning = false
        recognizedItemsContinuation?.finish()
        recognizedItemsContinuation = nil
    }

#if canImport(UIKit)
    public func capturePhoto() async throws -> UIImage {
        throw ScanningUnavailable.unsupported
    }
#endif

    public func loadView() {}

    public func viewDidLoad() {}

    public func viewWillAppear(_ animated: Bool) {
        _ = animated
    }

    public func viewDidDisappear(_ animated: Bool) {
        _ = animated
        stopScanning()
    }

    public func removeFromParent() {
        stopScanning()
    }

}
