@_spi(OpenUIKitHost) import VisionKit
import Foundation

private func assertAnalysisTypes() {
    var types: ImageAnalyzer.AnalysisTypes = []
    precondition(types.isEmpty)
    precondition(!types.contains(.text))
    types.insert(.text)
    precondition(types.contains(.text))
    precondition(!types.contains(.visualLookUp))
    precondition(ImageAnalyzer.AnalysisTypes.text != .visualLookUp)
    precondition(ImageAnalyzer.AnalysisTypes.text != .machineReadableCode)
    precondition(ImageAnalyzer.AnalysisTypes.visualLookUp != .machineReadableCode)
    let combined: ImageAnalyzer.AnalysisTypes = [.text, .visualLookUp]
    precondition(combined.contains(.text))
    precondition(combined.contains(.visualLookUp))
    precondition(!combined.contains(.machineReadableCode))
    precondition(combined.intersection(.text) == .text)
    precondition(combined.union(.machineReadableCode).contains(.machineReadableCode))
    precondition(combined.subtracting(.text).contains(.visualLookUp))
    precondition(!combined.subtracting(.text).contains(.text))
    precondition(combined.isSuperset(of: .text))
    precondition(!combined.isSubset(of: .text))
    precondition(!combined.isDisjoint(with: .text))
    precondition(ImageAnalyzer.AnalysisTypes().isDisjoint(with: .text))
    var mutable = combined
    mutable.formUnion(.machineReadableCode)
    mutable.formIntersection([.text, .machineReadableCode])
    precondition(mutable.contains(.text))
    precondition(!mutable.contains(.visualLookUp))
    _ = mutable.remove(.text)
    precondition(!mutable.contains(.text))
    _ = mutable.update(with: .visualLookUp)
    mutable.formSymmetricDifference(.visualLookUp)
    precondition(!mutable.contains(.visualLookUp))
    mutable.subtract(.machineReadableCode)
    let fromSequence = ImageAnalyzer.AnalysisTypes([.text, .text])
    precondition(fromSequence.contains(.text))
    precondition(.text != ImageAnalyzer.AnalysisTypes(rawValue: 0))
}

private func assertInteractionTypes() {
    var types: ImageAnalysisInteraction.InteractionTypes = []
    precondition(types.isEmpty)
    types = [.automatic, .textSelection]
    precondition(types.contains(.automatic))
    precondition(types.contains(.textSelection))
    precondition(!types.contains(.imageSubject))
    precondition(ImageAnalysisInteraction.InteractionTypes.automatic != .automaticTextOnly)
    precondition(ImageAnalysisInteraction.InteractionTypes.dataDetectors != .visualLookUp)
    precondition(ImageAnalysisInteraction.InteractionTypes.imageSubject != .textSelection)
    precondition(types.union(.dataDetectors).contains(.dataDetectors))
    precondition(types.intersection(.automatic) == .automatic)
    var copy = types
    copy.insert(.imageSubject)
    precondition(copy.contains(.imageSubject))
    _ = copy.remove(.automatic)
    precondition(!copy.contains(.automatic))
}

private func assertAnalyzerSurface() {
    precondition(ImageAnalyzer.isSupported == false)
    precondition(ImageAnalyzer.supportedTextRecognitionLanguages.isEmpty)
    let analyzer = ImageAnalyzer()
    _ = analyzer
    var configuration = ImageAnalyzer.Configuration(.text)
    precondition(configuration.analysisTypes.contains(.text))
    precondition(configuration.locales.isEmpty)
    configuration.locales = ["en-US"]
    precondition(configuration.locales == ["en-US"])
}

private func assertAnalysisFixture() {
    let analysis = ImageAnalysis.hostFixture(
        transcript: "HELLO",
        resultTypes: [.text]
    )
    precondition(analysis.transcript == "HELLO")
    precondition(analysis.hasResults(for: .text))
    precondition(!analysis.hasResults(for: .visualLookUp))
    precondition(analysis.hasResults(for: [.text, .machineReadableCode]))
}

@MainActor
private func assertDataScanner() {
    precondition(DataScannerViewController.isSupported == false)
    precondition(DataScannerViewController.isAvailable == false)
    precondition(DataScannerViewController.supportedTextRecognitionLanguages.isEmpty)

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
    precondition(scanner.isScanning == false)
    precondition(scanner.minZoomFactor == 1)
    precondition(scanner.maxZoomFactor == 1)
    scanner.zoomFactor = 8
    precondition(scanner.zoomFactor == 1)
    scanner.regionOfInterest = CGRect(x: 0, y: 0, width: 10, height: 10)
    precondition(scanner.regionOfInterest?.width == 10)

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
    scanner.loadView()
    scanner.viewDidLoad()
    scanner.viewWillAppear(false)
    scanner.viewDidDisappear(false)
    scanner.removeFromParent()
    _ = scanner.recognizedItems

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

    let quality: Set<DataScannerViewController.QualityLevel> = [.fast, .balanced, .accurate]
    precondition(quality.count == 3)
    let content: Set<DataScannerViewController.TextContentType> = [
        .dateTimeDuration, .URL, .fullStreetAddress, .emailAddress,
        .telephoneNumber, .shipmentTrackingNumber, .flightNumber, .currency,
    ]
    precondition(content.count == 8)
    let unavailable: Set<DataScannerViewController.ScanningUnavailable> = [
        .unsupported, .cameraRestricted,
    ]
    precondition(unavailable.count == 2)
    precondition(DataScannerViewController.RecognizedDataType.text() != .text(languages: ["fr"]))
}

@MainActor
private func assertDelegates() {
    final class ScannerSink: DataScannerViewControllerDelegate {}
    final class InteractionSink: ImageAnalysisInteractionDelegate {}
    final class CameraSink: NSObject, VNDocumentCameraViewControllerDelegate {}

    let scanner = DataScannerViewController(recognizedDataTypes: [.text()])
    let scannerSink = ScannerSink()
    scanner.delegate = scannerSink
    scannerSink.dataScanner(scanner, becameUnavailableWithError: .unsupported)
    scannerSink.dataScanner(scanner, didAdd: [], allItems: [])
    scannerSink.dataScanner(scanner, didRemove: [], allItems: [])
    scannerSink.dataScanner(scanner, didUpdate: [], allItems: [])
    scannerSink.dataScannerDidZoom(scanner)

    let interaction = ImageAnalysisInteraction()
    let interactionSink = InteractionSink()
    let viaDelegate = ImageAnalysisInteraction(interactionSink)
    viaDelegate.delegate = interactionSink
    precondition(viaDelegate.preferredInteractionTypes.isEmpty)
    precondition(viaDelegate.activeInteractionTypes.isEmpty)
    precondition(viaDelegate.contentsRect == .zero)
    viaDelegate.setContentsRectNeedsUpdate()
    precondition(viaDelegate.contentsRect == .zero)
    viaDelegate.analysis = ImageAnalysis.hostFixture(transcript: "abc", resultTypes: [.text])
    viaDelegate.preferredInteractionTypes = [.textSelection]
    precondition(viaDelegate.activeInteractionTypes.contains(.textSelection))
    precondition(viaDelegate.text == "abc")
    precondition(viaDelegate.selectedText.isEmpty)
    precondition(viaDelegate.selectedAttributedText.characters.isEmpty)
    precondition(!viaDelegate.hasActiveTextSelection)
    viaDelegate.selectedRanges = []
    viaDelegate.resetTextSelection()
    precondition(!viaDelegate.hasActiveTextSelection)
    viaDelegate.selectableItemsHighlighted = true
    precondition(viaDelegate.selectableItemsHighlighted)
    viaDelegate.setSupplementaryInterfaceHidden(false, animated: true)
    precondition(viaDelegate.isSupplementaryInterfaceHidden == false)
    viaDelegate.allowLongPressForDataDetectorsInTextMode = true
    precondition(viaDelegate.allowLongPressForDataDetectorsInTextMode)
    precondition(!viaDelegate.liveTextButtonVisible)
    let origin = CGPoint.zero
    precondition(!viaDelegate.hasText(at: origin))
    precondition(!viaDelegate.analysisHasText(at: origin))
    precondition(!viaDelegate.hasDataDetector(at: origin))
    precondition(!viaDelegate.hasInteractiveItem(at: origin))
    precondition(!viaDelegate.hasSupplementaryInterface(at: origin))
    viaDelegate.highlightedSubjects = []
    precondition(interactionSink.interaction(viaDelegate, shouldBeginAt: origin, for: .automatic) == false)
    interactionSink.interaction(viaDelegate, highlightSelectedItemsDidChange: true)
    interactionSink.interaction(viaDelegate, liveTextButtonDidChangeToVisible: true)
    interactionSink.textSelectionDidChange(viaDelegate)
    _ = interactionSink.contentsRect(for: viaDelegate)
    _ = interaction

    let camera = VNDocumentCameraViewController()
    precondition(VNDocumentCameraViewController.isSupported == false)
    let cameraSink = CameraSink()
    camera.delegate = cameraSink
    let scan = VNDocumentCameraScan.hostFixture(title: "Scan", pageCount: 2)
    precondition(scan.title == "Scan")
    precondition(scan.pageCount == 2)
    cameraSink.documentCameraViewControllerDidCancel(camera)
    cameraSink.documentCameraViewController(camera, didFinishWith: scan)
    cameraSink.documentCameraViewController(
        camera,
        didFailWithError: DataScannerViewController.ScanningUnavailable.unsupported
    )
}

@MainActor
private func assertRecognizedItemsAndSubjects() async {
    let bounds = RecognizedItem.Bounds(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    precondition(bounds.topLeft.y == 1)
    let text = RecognizedItem.Text.hostFixture(transcript: "code", bounds: bounds)
    precondition(text.transcript == "code")
    precondition(text.bounds.bottomRight.x == 1)
    let item = RecognizedItem.text(text)
    precondition(item.id == text.id)
    precondition(item.bounds.topLeft.x == 0)
    let barcode = RecognizedItem.Barcode.hostFixture(
        payloadStringValue: "payload",
        bounds: bounds
    )
    precondition(barcode.payloadStringValue == "payload")
    let barcodeItem = RecognizedItem.barcode(barcode)
    precondition(barcodeItem.id == barcode.id)

    let interaction = ImageAnalysisInteraction()
    let none = await interaction.subject(at: .zero)
    precondition(none == nil)
    let subjects = await interaction.subjects
    precondition(subjects.isEmpty)
    let fixture = ImageAnalysisInteraction.Subject.hostFixture(
        bounds: CGRect(x: 1, y: 2, width: 3, height: 4)
    )
    precondition(fixture.bounds.width == 3)
    let other = ImageAnalysisInteraction.Subject.hostFixture(
        bounds: CGRect(x: 0, y: 0, width: 1, height: 1)
    )
    precondition(fixture != other)
    precondition(ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable
        == .imageUnavailable)
    _ = ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable.hashValue
}

func runVisionKitHostTests() async {
    assertAnalysisTypes()
    assertInteractionTypes()
    assertAnalyzerSurface()
    assertAnalysisFixture()
    await MainActor.run {
        assertDataScanner()
        assertDelegates()
    }
    await assertRecognizedItemsAndSubjects()
    print("VISIONKIT_AGENT_RUNTIME_OK")
}

await runVisionKitHostTests()
