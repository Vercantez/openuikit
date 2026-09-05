@_spi(OpenUIKitHost) import VisionKit
import Foundation

func testDataScannerAvailability() {
    precondition(DataScannerViewController.isSupported == false)
    precondition(DataScannerViewController.isAvailable == false)
    precondition(DataScannerViewController.supportedTextRecognitionLanguages.isEmpty)
}

func testDataScannerInitialization() {
    let types: Set<DataScannerViewController.RecognizedDataType> = [
        .text(),
        .text(languages: ["en"], textContentType: .emailAddress),
    ]
    let scanner = DataScannerViewController(recognizedDataTypes: types)
    precondition(scanner.qualityLevel == .balanced)
    precondition(scanner.recognizesMultipleItems == false)
    precondition(scanner.isHighFrameRateTrackingEnabled == true)
    precondition(scanner.isPinchToZoomEnabled == true)
    precondition(scanner.isGuidanceEnabled == true)
    precondition(scanner.isHighlightingEnabled == false)
    precondition(scanner.recognizedDataTypes == types)

    let custom = DataScannerViewController(
        recognizedDataTypes: [.text(textContentType: .URL)],
        qualityLevel: .accurate,
        recognizesMultipleItems: true,
        isHighFrameRateTrackingEnabled: false,
        isPinchToZoomEnabled: false,
        isGuidanceEnabled: false,
        isHighlightingEnabled: true
    )
    precondition(custom.qualityLevel == .accurate)
    precondition(custom.recognizesMultipleItems)
    precondition(!custom.isHighFrameRateTrackingEnabled)
    precondition(!custom.isPinchToZoomEnabled)
    precondition(!custom.isGuidanceEnabled)
    precondition(custom.isHighlightingEnabled)
    precondition(custom.recognizedDataTypes == [.text(textContentType: .URL)])
}

func testDataScannerZoomFactors() {
    let scanner = DataScannerViewController(recognizedDataTypes: [.text()])
    precondition(scanner.minZoomFactor == 1)
    precondition(scanner.maxZoomFactor == 1)
    precondition(scanner.zoomFactor == 1)
    scanner.zoomFactor = 8
    precondition(scanner.zoomFactor == 1)
    scanner.zoomFactor = 0.25
    precondition(scanner.zoomFactor == 1)
    scanner.zoomFactor = 1
    precondition(scanner.zoomFactor == 1)
}

func testDataScannerScanning() {
    let scanner = DataScannerViewController(recognizedDataTypes: [.text()])
    precondition(scanner.isScanning == false)
    do {
        try scanner.startScanning()
        fatalError("startScanning must throw on Linux")
    } catch let error as DataScannerViewController.ScanningUnavailable {
        precondition(error == .unsupported)
        precondition(error != .cameraRestricted)
    } catch {
        fatalError("startScanning must throw ScanningUnavailable")
    }
    precondition(scanner.isScanning == false)
    scanner.stopScanning()
    precondition(scanner.isScanning == false)
    _ = scanner.recognizedItems
}

func testDataScannerLifecycle() {
    let scanner = DataScannerViewController(recognizedDataTypes: [.text()])
    scanner.loadView()
    scanner.viewDidLoad()
    scanner.viewWillAppear(false)
    scanner.viewDidDisappear(true)
    scanner.removeFromParent()
    precondition(scanner.isScanning == false)
}

func testDataScannerRegionOfInterest() {
    let scanner = DataScannerViewController(recognizedDataTypes: [.text()])
    precondition(scanner.regionOfInterest == nil)
    let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
    scanner.regionOfInterest = rect
    precondition(scanner.regionOfInterest == rect)
    scanner.regionOfInterest = nil
    precondition(scanner.regionOfInterest == nil)
}

func testDataScannerQualityLevel() {
    let quality: Set<DataScannerViewController.QualityLevel> = [.fast, .balanced, .accurate]
    precondition(quality.count == 3)
    precondition(DataScannerViewController.QualityLevel.fast != .balanced)
    precondition(DataScannerViewController.QualityLevel.balanced != .accurate)
    precondition(DataScannerViewController.QualityLevel.fast != .accurate)
    precondition(DataScannerViewController.QualityLevel.fast.hashValue == DataScannerViewController.QualityLevel.fast.hashValue)
    var hasher = Hasher()
    DataScannerViewController.QualityLevel.accurate.hash(into: &hasher)
    _ = hasher.finalize()
}

func testDataScannerTextContentType() {
    let content: Set<DataScannerViewController.TextContentType> = [
        .dateTimeDuration, .URL, .fullStreetAddress, .emailAddress,
        .telephoneNumber, .shipmentTrackingNumber, .flightNumber, .currency,
    ]
    precondition(content.count == 8)
    precondition(DataScannerViewController.TextContentType.URL != .emailAddress)
    precondition(DataScannerViewController.TextContentType.currency != .flightNumber)
    precondition(
        DataScannerViewController.TextContentType.telephoneNumber.hashValue
            == DataScannerViewController.TextContentType.telephoneNumber.hashValue
    )
    var hasher = Hasher()
    DataScannerViewController.TextContentType.dateTimeDuration.hash(into: &hasher)
    _ = hasher.finalize()
}

func testDataScannerScanningUnavailable() {
    let unavailable: Set<DataScannerViewController.ScanningUnavailable> = [
        .unsupported, .cameraRestricted,
    ]
    precondition(unavailable.count == 2)
    precondition(DataScannerViewController.ScanningUnavailable.unsupported != .cameraRestricted)
    precondition(
        DataScannerViewController.ScanningUnavailable.unsupported.hashValue
            == DataScannerViewController.ScanningUnavailable.unsupported.hashValue
    )
    var hasher = Hasher()
    DataScannerViewController.ScanningUnavailable.cameraRestricted.hash(into: &hasher)
    _ = hasher.finalize()
    let error: Error = DataScannerViewController.ScanningUnavailable.unsupported
    precondition(!error.localizedDescription.isEmpty)
    precondition(
        error.localizedDescription
            == DataScannerViewController.ScanningUnavailable.unsupported.localizedDescription
    )
}

func testDataScannerRecognizedDataType() {
    let plain = DataScannerViewController.RecognizedDataType.text()
    let english = DataScannerViewController.RecognizedDataType.text(languages: ["en"])
    let email = DataScannerViewController.RecognizedDataType.text(
        languages: ["en"],
        textContentType: .emailAddress
    )
    precondition(plain != english)
    precondition(english != email)
    precondition(plain == .text())
    precondition(plain.hashValue == DataScannerViewController.RecognizedDataType.text().hashValue)
    var hasher = Hasher()
    email.hash(into: &hasher)
    _ = hasher.finalize()
    let set: Set<DataScannerViewController.RecognizedDataType> = [plain, english, email]
    precondition(set.count == 3)
}

func testDataScannerDelegate() {
    final class ScannerSink: DataScannerViewControllerDelegate {}
    let scanner = DataScannerViewController(recognizedDataTypes: [.text()])
    let sink = ScannerSink()
    scanner.delegate = sink
    precondition(scanner.delegate === sink)
    let bounds = RecognizedItem.Bounds(
        topLeft: .zero,
        topRight: .zero,
        bottomRight: .zero,
        bottomLeft: .zero
    )
    let item = RecognizedItem.text(RecognizedItem.Text.hostFixture(transcript: "x", bounds: bounds))
    sink.dataScanner(scanner, becameUnavailableWithError: .unsupported)
    sink.dataScanner(scanner, didAdd: [item], allItems: [item])
    sink.dataScanner(scanner, didRemove: [], allItems: [item])
    sink.dataScanner(scanner, didUpdate: [item], allItems: [item])
    sink.dataScanner(scanner, didTapOn: item)
    sink.dataScannerDidZoom(scanner)
    scanner.delegate = nil
    precondition(scanner.delegate == nil)
}
