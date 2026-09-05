@_spi(OpenUIKitHost) import VisionKit
import Foundation

/// v1 sealed gate compiles this file only. Test bodies are kept in lockstep
/// with `tests/agent/*Tests.swift`; the gate invokes them here, then prints
/// the runtime marker. Tests are synchronous and never hop to MainActor.

// From AnalysisTypesTests.swift
/// Table-driven Linux-local bits for `ImageAnalyzer.AnalysisTypes`.
/// Darwin numeric ABI is unobserved (see oracle-questions.tsv).
func testAnalysisTypesBits() {
    typealias Types = ImageAnalyzer.AnalysisTypes
    let catalog: [(Types, UInt)] = [
        (.text, 1 << 0),
        (.visualLookUp, 1 << 1),
        (.machineReadableCode, 1 << 2),
    ]
    for (flag, bit) in catalog {
        precondition(flag.rawValue == bit)
        precondition(Types(rawValue: bit) == flag)
        precondition(Types(rawValue: bit).contains(flag))
    }
    precondition(Types.text != .visualLookUp)
    precondition(Types.text != .machineReadableCode)
    precondition(Types.visualLookUp != .machineReadableCode)
    precondition(Types.Element.self == Types.self)
    precondition(Types.ArrayLiteralElement.self == Types.self)
    precondition(Types.RawValue.self == UInt.self)
    let passthrough = Types(rawValue: 0b101)
    precondition(passthrough.rawValue == 0b101)
    precondition(passthrough.contains(.text))
    precondition(!passthrough.contains(.visualLookUp))
    precondition(passthrough.contains(.machineReadableCode))
}

func testAnalysisTypesAlgebra() {
    typealias Types = ImageAnalyzer.AnalysisTypes
    var empty = Types()
    precondition(empty.isEmpty)
    precondition(!empty.contains(.text))
    empty.insert(.text)
    precondition(empty.contains(.text))
    precondition(!empty.contains(.visualLookUp))

    let combined: Types = [.text, .visualLookUp]
    precondition(combined.contains(.text))
    precondition(combined.contains(.visualLookUp))
    precondition(!combined.contains(.machineReadableCode))
    precondition(combined != .text)
    precondition(combined.intersection(.text) == .text)
    precondition(combined.union(.machineReadableCode).contains(.machineReadableCode))
    precondition(combined.subtracting(.text).contains(.visualLookUp))
    precondition(!combined.subtracting(.text).contains(.text))
    precondition(combined.isSuperset(of: .text))
    precondition(!combined.isSubset(of: .text))
    precondition(combined.isStrictSuperset(of: .text))
    precondition(Types.text.isStrictSubset(of: combined))
    precondition(!combined.isDisjoint(with: .text))
    precondition(Types().isDisjoint(with: .text))

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
    precondition(mutable.isEmpty)

    let fromSequence = Types([.text, .text])
    precondition(fromSequence.contains(.text))
    precondition(.text != Types(rawValue: 0))
    let symmetric = Types.text.symmetricDifference(.visualLookUp)
    precondition(symmetric.contains(.text))
    precondition(symmetric.contains(.visualLookUp))
}
// From DataScannerTests.swift
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
// From DocumentCameraTests.swift
func testDocumentCameraScan() {
    let scan = VNDocumentCameraScan.hostFixture(title: "Scan", pageCount: 2)
    precondition(scan.title == "Scan")
    precondition(scan.pageCount == 2)
    let empty = VNDocumentCameraScan.hostFixture(title: "", pageCount: 0)
    precondition(empty.title.isEmpty)
    precondition(empty.pageCount == 0)
}

func testDocumentCameraViewController() {
    precondition(VNDocumentCameraViewController.isSupported == false)
    let camera = VNDocumentCameraViewController()
    precondition(camera.delegate == nil)
    final class CameraSink: NSObject, VNDocumentCameraViewControllerDelegate {}
    let sink = CameraSink()
    camera.delegate = sink
    precondition(camera.delegate === sink)
    camera.delegate = nil
    precondition(camera.delegate == nil)
}

func testDocumentCameraDelegate() {
    final class CameraSink: NSObject, VNDocumentCameraViewControllerDelegate {}
    let camera = VNDocumentCameraViewController()
    let sink = CameraSink()
    let scan = VNDocumentCameraScan.hostFixture(title: "Scan", pageCount: 1)
    sink.documentCameraViewControllerDidCancel(camera)
    sink.documentCameraViewController(camera, didFinishWith: scan)
    sink.documentCameraViewController(
        camera,
        didFailWithError: DataScannerViewController.ScanningUnavailable.unsupported
    )
}
// From ImageAnalysisInteractionTests.swift
func testInteractionInitialization() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction.delegate == nil)
    precondition(interaction.analysis == nil)
    final class Sink: ImageAnalysisInteractionDelegate {}
    let sink = Sink()
    let viaDelegate = ImageAnalysisInteraction(sink)
    precondition(viaDelegate.delegate === sink)
}

func testInteractionContentsRect() {
    final class RectSink: ImageAnalysisInteractionDelegate {
        var rect = CGRect(x: 1, y: 2, width: 3, height: 4)
        func contentsRect(for interaction: ImageAnalysisInteraction) -> CGRect {
            _ = interaction
            return rect
        }
    }
    let empty = ImageAnalysisInteraction()
    precondition(empty.contentsRect == .zero)
    empty.setContentsRectNeedsUpdate()
    precondition(empty.contentsRect == .zero)

    let sink = RectSink()
    let interaction = ImageAnalysisInteraction(sink)
    interaction.setContentsRectNeedsUpdate()
    precondition(interaction.contentsRect == sink.rect)
    sink.rect = CGRect(x: 9, y: 9, width: 1, height: 1)
    precondition(interaction.contentsRect.origin.x == 1)
    interaction.setContentsRectNeedsUpdate()
    precondition(interaction.contentsRect == sink.rect)
}

func testInteractionTextSurface() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction.text.isEmpty)
    precondition(interaction.selectedText.isEmpty)
    precondition(interaction.selectedAttributedText.characters.isEmpty)
    precondition(!interaction.hasActiveTextSelection)
    interaction.analysis = ImageAnalysis.hostFixture(transcript: "abc", resultTypes: [.text])
    precondition(interaction.text == "abc")
    let range = interaction.text.startIndex..<interaction.text.endIndex
    interaction.selectedRanges = [range]
    precondition(interaction.hasActiveTextSelection)
    interaction.resetTextSelection()
    precondition(!interaction.hasActiveTextSelection)
    precondition(interaction.selectedRanges.isEmpty)
}

func testInteractionHitTests() {
    let interaction = ImageAnalysisInteraction()
    interaction.analysis = ImageAnalysis.hostFixture(transcript: "abc", resultTypes: [.text])
    let origin = CGPoint.zero
    precondition(!interaction.hasText(at: origin))
    precondition(!interaction.analysisHasText(at: origin))
    precondition(!interaction.hasDataDetector(at: origin))
    precondition(!interaction.hasInteractiveItem(at: origin))
    precondition(!interaction.hasSupplementaryInterface(at: origin))
    let away = CGPoint(x: 50, y: 50)
    precondition(!interaction.hasText(at: away))
}

func testInteractionSupplementaryInterface() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction.isSupplementaryInterfaceHidden)
    precondition(!interaction.liveTextButtonVisible)
    precondition(!interaction.allowLongPressForDataDetectorsInTextMode)
    precondition(!interaction.selectableItemsHighlighted)
    interaction.setSupplementaryInterfaceHidden(false, animated: true)
    precondition(interaction.isSupplementaryInterfaceHidden == false)
    interaction.setSupplementaryInterfaceHidden(true, animated: false)
    precondition(interaction.isSupplementaryInterfaceHidden)
    interaction.allowLongPressForDataDetectorsInTextMode = true
    precondition(interaction.allowLongPressForDataDetectorsInTextMode)
    interaction.selectableItemsHighlighted = true
    precondition(interaction.selectableItemsHighlighted)
}

func testInteractionAnalysisProperty() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction.analysis == nil)
    let analysis = ImageAnalysis.hostFixture(transcript: "code", resultTypes: [.machineReadableCode])
    interaction.analysis = analysis
    precondition(interaction.analysis === analysis)
    precondition(interaction.text == "code")
    interaction.analysis = nil
    precondition(interaction.analysis == nil)
    precondition(interaction.text.isEmpty)
}

func testInteractionSubjects() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction._hostSubject(at: .zero) == nil)
    precondition(interaction._hostSubjects().isEmpty)
    precondition(interaction.highlightedSubjects.isEmpty)
    let fixture = ImageAnalysisInteraction.Subject.hostFixture(
        bounds: CGRect(x: 1, y: 2, width: 3, height: 4)
    )
    precondition(fixture.bounds.width == 3)
    precondition(fixture.bounds.height == 4)
    let other = ImageAnalysisInteraction.Subject.hostFixture(
        bounds: CGRect(x: 0, y: 0, width: 1, height: 1)
    )
    precondition(fixture != other)
    precondition(fixture == fixture)
    precondition(fixture.hashValue == fixture.hashValue)
    var hasher = Hasher()
    fixture.hash(into: &hasher)
    other.hash(into: &hasher)
    _ = hasher.finalize()
    interaction.highlightedSubjects = [fixture]
    precondition(interaction.highlightedSubjects.count == 1)
    interaction.highlightedSubjects = []
    precondition(interaction.highlightedSubjects.isEmpty)
    let asyncPeek = interaction.subject(at:)
    _ = asyncPeek
}

func testSubjectUnavailable() {
    precondition(
        ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable
            == .imageUnavailable
    )
    _ = ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable.hashValue
    var hasher = Hasher()
    ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable.hash(into: &hasher)
    _ = hasher.finalize()
    let error: Error = ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable
    precondition(!error.localizedDescription.isEmpty)
    precondition(
        error.localizedDescription
            == ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable.localizedDescription
    )
}

func testInteractionDelegate() {
    final class InteractionSink: ImageAnalysisInteractionDelegate {}
    let sink = InteractionSink()
    let interaction = ImageAnalysisInteraction(sink)
    let origin = CGPoint.zero
    precondition(sink.interaction(interaction, shouldBeginAt: origin, for: .automatic) == false)
    sink.interaction(interaction, highlightSelectedItemsDidChange: true)
    sink.interaction(interaction, liveTextButtonDidChangeToVisible: true)
    sink.textSelectionDidChange(interaction)
    precondition(sink.contentsRect(for: interaction) == .zero)
}
// From ImageAnalyzerTests.swift
func testImageAnalyzerAvailability() {
    precondition(ImageAnalyzer.isSupported == false)
    precondition(ImageAnalyzer.supportedTextRecognitionLanguages.isEmpty)
    let analyzer = ImageAnalyzer()
    _ = analyzer
}

func testImageAnalyzerConfiguration() {
    var configuration = ImageAnalyzer.Configuration(.text)
    precondition(configuration.analysisTypes.contains(.text))
    precondition(!configuration.analysisTypes.contains(.visualLookUp))
    precondition(configuration.locales.isEmpty)
    configuration.locales = ["en-US"]
    precondition(configuration.locales == ["en-US"])
    let lookUp = ImageAnalyzer.Configuration([.visualLookUp, .machineReadableCode])
    precondition(lookUp.analysisTypes.contains(.visualLookUp))
    precondition(lookUp.analysisTypes.contains(.machineReadableCode))
}

func testImageAnalysisResults() {
    let analysis = ImageAnalysis.hostFixture(
        transcript: "HELLO",
        resultTypes: [.text]
    )
    precondition(analysis.transcript == "HELLO")
    precondition(analysis.hasResults(for: .text))
    precondition(!analysis.hasResults(for: .visualLookUp))
    precondition(analysis.hasResults(for: [.text, .machineReadableCode]))
    precondition(!analysis.hasResults(for: [.visualLookUp, .machineReadableCode]))
    let empty = ImageAnalysis.hostFixture(transcript: "", resultTypes: [])
    precondition(empty.transcript.isEmpty)
    precondition(!empty.hasResults(for: .text))
}
// From InteractionTypesTests.swift
/// Table-driven Linux-local bits for `ImageAnalysisInteraction.InteractionTypes`.
/// Darwin numeric ABI is unobserved (see oracle-questions.tsv).
func testInteractionTypesBits() {
    typealias Types = ImageAnalysisInteraction.InteractionTypes
    let catalog: [(Types, UInt)] = [
        (.automatic, 1 << 0),
        (.automaticTextOnly, 1 << 1),
        (.textSelection, 1 << 2),
        (.dataDetectors, 1 << 3),
        (.visualLookUp, 1 << 4),
        (.imageSubject, 1 << 5),
    ]
    for (flag, bit) in catalog {
        precondition(flag.rawValue == bit)
        precondition(Types(rawValue: bit) == flag)
        precondition(Types(rawValue: bit).contains(flag))
    }
    precondition(Types.automatic != .automaticTextOnly)
    precondition(Types.dataDetectors != .visualLookUp)
    precondition(Types.imageSubject != .textSelection)
    precondition(Types.Element.self == Types.self)
    precondition(Types.ArrayLiteralElement.self == Types.self)
    precondition(Types.RawValue.self == UInt.self)
    let passthrough = Types(rawValue: (1 << 2) | (1 << 5))
    precondition(passthrough.contains(.textSelection))
    precondition(passthrough.contains(.imageSubject))
    precondition(!passthrough.contains(.automatic))
}

func testInteractionTypesAlgebra() {
    typealias Types = ImageAnalysisInteraction.InteractionTypes
    var types: Types = []
    precondition(types.isEmpty)
    types = [.automatic, .textSelection]
    precondition(types.contains(.automatic))
    precondition(types.contains(.textSelection))
    precondition(!types.contains(.imageSubject))
    precondition(types != .automatic)
    precondition(types.union(.dataDetectors).contains(.dataDetectors))
    precondition(types.intersection(.automatic) == .automatic)
    precondition(types.subtracting(.automatic).contains(.textSelection))
    precondition(types.isSuperset(of: .automatic))
    precondition(!types.isSubset(of: .automatic))
    precondition(types.isStrictSuperset(of: .automatic))
    precondition(Types.automatic.isStrictSubset(of: types))
    precondition(!types.isDisjoint(with: .automatic))
    precondition(Types().isDisjoint(with: .automatic))

    var copy = types
    copy.insert(.imageSubject)
    precondition(copy.contains(.imageSubject))
    _ = copy.remove(.automatic)
    precondition(!copy.contains(.automatic))
    _ = copy.update(with: .visualLookUp)
    copy.formUnion(.automaticTextOnly)
    copy.formIntersection([.textSelection, .imageSubject, .visualLookUp])
    copy.formSymmetricDifference(.visualLookUp)
    copy.subtract(.imageSubject)
    precondition(copy.contains(.textSelection))

    let fromSequence = Types([.dataDetectors, .dataDetectors])
    precondition(fromSequence.contains(.dataDetectors))
    let symmetric = Types.automatic.symmetricDifference(.textSelection)
    precondition(symmetric.contains(.automatic))
    precondition(symmetric.contains(.textSelection))
}

func testPreferredAndActiveInteractionTypes() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction.preferredInteractionTypes.isEmpty)
    precondition(interaction.activeInteractionTypes.isEmpty)

    interaction.preferredInteractionTypes = [.textSelection]
    precondition(interaction.preferredInteractionTypes.contains(.textSelection))
    precondition(interaction.activeInteractionTypes.isEmpty)

    interaction.analysis = ImageAnalysis.hostFixture(transcript: "abc", resultTypes: [.text])
    precondition(interaction.activeInteractionTypes.contains(.textSelection))
    precondition(!interaction.activeInteractionTypes.contains(.automatic))

    interaction.preferredInteractionTypes = []
    precondition(interaction.activeInteractionTypes.isEmpty)
}
// From RecognizedItemTests.swift
func testRecognizedItemBounds() {
    let bounds = RecognizedItem.Bounds(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    precondition(bounds.topLeft.y == 1)
    precondition(bounds.topRight.x == 1)
    precondition(bounds.bottomRight.y == 0)
    precondition(bounds.bottomLeft.x == 0)
}

func testRecognizedItemText() {
    let bounds = RecognizedItem.Bounds(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    let id = UUID()
    let text = RecognizedItem.Text.hostFixture(transcript: "code", bounds: bounds, id: id)
    precondition(text.transcript == "code")
    precondition(text.id == id)
    precondition(text.bounds.bottomRight.x == 1)
    precondition(RecognizedItem.Text.ID.self == UUID.self)
    let item = RecognizedItem.text(text)
    precondition(item.id == text.id)
    precondition(item.bounds.topLeft.x == 0)
}

func testRecognizedItemBarcode() {
    let bounds = RecognizedItem.Bounds(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    let id = UUID()
    let barcode = RecognizedItem.Barcode.hostFixture(
        payloadStringValue: "payload",
        bounds: bounds,
        id: id
    )
    precondition(barcode.payloadStringValue == "payload")
    precondition(barcode.id == id)
    precondition(RecognizedItem.Barcode.ID.self == UUID.self)
    let item = RecognizedItem.barcode(barcode)
    precondition(item.id == barcode.id)
    precondition(item.bounds.topRight.y == 1)
    let empty = RecognizedItem.Barcode.hostFixture(payloadStringValue: nil, bounds: bounds)
    precondition(empty.payloadStringValue == nil)
}

func testRecognizedItemIdentity() {
    let bounds = RecognizedItem.Bounds(
        topLeft: .zero,
        topRight: .zero,
        bottomRight: .zero,
        bottomLeft: .zero
    )
    let text = RecognizedItem.Text.hostFixture(transcript: "a", bounds: bounds)
    let barcode = RecognizedItem.Barcode.hostFixture(payloadStringValue: "b", bounds: bounds)
    let textItem = RecognizedItem.text(text)
    let barcodeItem = RecognizedItem.barcode(barcode)
    precondition(textItem.id == text.id)
    precondition(barcodeItem.id == barcode.id)
    precondition(RecognizedItem.ID.self == UUID.self)
    precondition(textItem.bounds.topLeft == .zero)
    precondition(barcodeItem.bounds.bottomRight == .zero)
}

testAnalysisTypesBits()
testAnalysisTypesAlgebra()
testDataScannerAvailability()
testDataScannerInitialization()
testDataScannerZoomFactors()
testDataScannerScanning()
testDataScannerLifecycle()
testDataScannerRegionOfInterest()
testDataScannerQualityLevel()
testDataScannerTextContentType()
testDataScannerScanningUnavailable()
testDataScannerRecognizedDataType()
testDataScannerDelegate()
testDocumentCameraScan()
testDocumentCameraViewController()
testDocumentCameraDelegate()
testInteractionInitialization()
testInteractionContentsRect()
testInteractionTextSurface()
testInteractionHitTests()
testInteractionSupplementaryInterface()
testInteractionAnalysisProperty()
testInteractionSubjects()
testSubjectUnavailable()
testInteractionDelegate()
testImageAnalyzerAvailability()
testImageAnalyzerConfiguration()
testImageAnalysisResults()
testInteractionTypesBits()
testInteractionTypesAlgebra()
testPreferredAndActiveInteractionTypes()
testRecognizedItemBounds()
testRecognizedItemText()
testRecognizedItemBarcode()
testRecognizedItemIdentity()
print("VISIONKIT_AGENT_RUNTIME_OK")
