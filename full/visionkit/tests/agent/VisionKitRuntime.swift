@_spi(OpenUIKitHost) import VisionKit
import Foundation

@MainActor
private final class InteractionProbe: ImageAnalysisInteractionDelegate {}

@MainActor
private final class ScannerProbe: DataScannerViewControllerDelegate {}

private final class DocumentProbe: NSObject, VNDocumentCameraViewControllerDelegate {}

private func exerciseOptionSet<T: OptionSet>(
    _ first: T,
    _ second: T
) where T.Element == T, T.ArrayLiteralElement == T {
    var value = first
    precondition(first.contains(first))
    precondition(!first.isDisjoint(with: first))
    precondition(first.isSuperset(of: first))
    precondition(first.isSubset(of: first))
    precondition(!first.isStrictSubset(of: first))
    precondition(!first.isStrictSuperset(of: first))
    precondition(!first.isEmpty)
    precondition(T().isEmpty)
    precondition(first != second)
    _ = first.union(second)
    _ = first.intersection(second)
    _ = first.symmetricDifference(second)
    _ = first.subtracting(second)
    _ = T([first, second])
    let literal: T = [first, second]
    _ = literal
    value.formUnion(second)
    value.formIntersection(first)
    value.formSymmetricDifference(second)
    value.subtract(first)
    _ = value.insert(first)
    _ = value.remove(first)
    _ = value.update(with: second)
}

@MainActor
private func syncSurface() {
    exerciseOptionSet(ImageAnalyzer.AnalysisTypes.text, .machineReadableCode)
    exerciseOptionSet(
        ImageAnalysisInteraction.InteractionTypes.automatic,
        .textSelection
    )
    var types: ImageAnalyzer.AnalysisTypes = [.text, .visualLookUp]
    types.insert(.machineReadableCode)
    precondition(types.contains(.text))
    precondition(types.contains(.visualLookUp))
    precondition(types.contains(.machineReadableCode))
    precondition(!ImageAnalyzer.AnalysisTypes.text.contains(.visualLookUp))

    precondition(ImageAnalyzer.isSupported == false)
    precondition(ImageAnalyzer.supportedTextRecognitionLanguages.isEmpty)
    var configuration = ImageAnalyzer.Configuration(.text)
    configuration.locales = ["en-US"]
    precondition(configuration.analysisTypes.contains(.text))
    precondition(configuration.locales == ["en-US"])
    _ = ImageAnalyzer()

    let emptyAnalysis = ImageAnalysis()
    precondition(emptyAnalysis.transcript.isEmpty)
    precondition(!emptyAnalysis.hasResults(for: .text))
    let hosted = ImageAnalysis(transcript: "hello", resultTypes: .text)
    precondition(hosted.transcript == "hello")
    precondition(hosted.hasResults(for: .text))
    precondition(!hosted.hasResults(for: .visualLookUp))

    let interactionDelegate = InteractionProbe()
    let interaction = ImageAnalysisInteraction(interactionDelegate)
    interaction.preferredInteractionTypes = [.automatic, .textSelection]
    interaction.analysis = hosted
    _ = interaction.activeInteractionTypes
    interaction.setContentsRectNeedsUpdate()
    _ = interaction.contentsRect
    precondition(interaction.selectedText.isEmpty)
    precondition(interaction.selectedAttributedText.characters.isEmpty)
    precondition(interaction.text == "hello")
    precondition(interaction.liveTextButtonVisible == false)
    interaction.selectedRanges = []
    precondition(interaction.hasActiveTextSelection == false)
    interaction.resetTextSelection()
    interaction.selectableItemsHighlighted = true
    interaction.isSupplementaryInterfaceHidden = true
    interaction.setSupplementaryInterfaceHidden(false, animated: false)
    precondition(interaction.isSupplementaryInterfaceHidden == false)
    interaction.allowLongPressForDataDetectorsInTextMode = true
    interaction.highlightedSubjects = []
    precondition(interaction.analysisHasText(at: .zero) == false)
    precondition(interaction.hasDataDetector(at: .zero) == false)
    precondition(interaction.hasInteractiveItem(at: .zero) == false)
    precondition(interaction.hasSupplementaryInterface(at: .zero) == false)
    precondition(interaction.hasText(at: .zero) == false)
    precondition(
        interactionDelegate.interaction(
            interaction,
            shouldBeginAt: .zero,
            for: .automatic
        )
    )
    interactionDelegate.interaction(interaction, liveTextButtonDidChangeToVisible: false)
    interactionDelegate.interaction(interaction, highlightSelectedItemsDidChange: false)
    interactionDelegate.textSelectionDidChange(interaction)

    let unavailable = ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable
    precondition(unavailable == .imageUnavailable)
    precondition(!(unavailable != .imageUnavailable))
    _ = unavailable.hashValue
    _ = unavailable.localizedDescription
    let subject = ImageAnalysisInteraction.Subject(bounds: .zero)
    precondition(subject.bounds == .zero)
    precondition(subject == subject)
    _ = subject.hashValue

    let textType = DataScannerViewController.RecognizedDataType.text(
        languages: ["en-US"],
        textContentType: .emailAddress
    )
    _ = textType.hashValue

    let qualities: [DataScannerViewController.QualityLevel] = [
        .fast, .balanced, .accurate
    ]
    precondition(qualities[0] != qualities[1])
    _ = qualities[2].hashValue

    let contentTypes: [DataScannerViewController.TextContentType] = [
        .emailAddress,
        .flightNumber,
        .telephoneNumber,
        .dateTimeDuration,
        .fullStreetAddress,
        .shipmentTrackingNumber,
        .URL,
        .currency
    ]
    precondition(Set(contentTypes).count == 8)

    let scanErrors: [DataScannerViewController.ScanningUnavailable] = [
        .unsupported, .cameraRestricted
    ]
    precondition(scanErrors[0] != scanErrors[1])
    _ = scanErrors[0].localizedDescription
    _ = scanErrors[0].hashValue

    precondition(DataScannerViewController.isSupported == false)
    precondition(DataScannerViewController.isAvailable == false)
    precondition(DataScannerViewController.supportedTextRecognitionLanguages.isEmpty)

    let scannerDelegate = ScannerProbe()
    let scanner = DataScannerViewController(
        recognizedDataTypes: [textType],
        qualityLevel: .accurate,
        recognizesMultipleItems: true,
        isHighFrameRateTrackingEnabled: false,
        isPinchToZoomEnabled: false,
        isGuidanceEnabled: false,
        isHighlightingEnabled: true
    )
    scanner.delegate = scannerDelegate
    precondition(scanner.recognizedDataTypes.count == 1)
    precondition(scanner.qualityLevel == .accurate)
    precondition(scanner.recognizesMultipleItems)
    precondition(!scanner.isHighFrameRateTrackingEnabled)
    precondition(!scanner.isPinchToZoomEnabled)
    precondition(!scanner.isGuidanceEnabled)
    precondition(scanner.isHighlightingEnabled)
    precondition(!scanner.isScanning)
    scanner.regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    scanner.zoomFactor = 8
    precondition(scanner.zoomFactor == scanner.minZoomFactor)
    precondition(scanner.maxZoomFactor == scanner.minZoomFactor)
    do {
        try scanner.startScanning()
        preconditionFailure("startScanning must fail closed")
    } catch {
        precondition(!scanner.isScanning)
    }
    scanner.stopScanning()
    scannerDelegate.dataScannerDidZoom(scanner)
    scannerDelegate.dataScanner(scanner, becameUnavailableWithError: .unsupported)

    let bounds = RecognizedItem.Bounds(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomLeft: .zero,
        bottomRight: CGPoint(x: 1, y: 0)
    )
    let textItem = RecognizedItem.Text(bounds: bounds, transcript: "OCR")
    let barcodeItem = RecognizedItem.Barcode(payloadStringValue: "payload")
    let recognizedText = RecognizedItem.text(textItem)
    let recognizedBarcode = RecognizedItem.barcode(barcodeItem)
    precondition(recognizedText.id == textItem.id)
    precondition(recognizedBarcode.bounds.topLeft == .zero)
    precondition(textItem.transcript == "OCR")
    precondition(barcodeItem.payloadStringValue == "payload")
    scannerDelegate.dataScanner(scanner, didAdd: [recognizedText], allItems: [recognizedText])
    scannerDelegate.dataScanner(scanner, didUpdate: [recognizedText], allItems: [recognizedText])
    scannerDelegate.dataScanner(scanner, didRemove: [], allItems: [])
    scannerDelegate.dataScanner(scanner, didTapOn: recognizedBarcode)

    precondition(VNDocumentCameraViewController.isSupported == false)
    let documentDelegate = DocumentProbe()
    let documentCamera = VNDocumentCameraViewController()
    documentCamera.delegate = documentDelegate
    documentCamera.failClosed()
    documentCamera.cancel()
    let scan = VNDocumentCameraScan(title: "fixture", pageCount: 1)
    precondition(scan.pageCount == 1)
    precondition(scan.title == "fixture")
    documentDelegate.documentCameraViewController(documentCamera, didFinishWith: scan)
    documentDelegate.documentCameraViewController(
        documentCamera,
        didFailWithError: VisionKitHostError.documentCameraUnsupported
    )
    documentDelegate.documentCameraViewControllerDidCancel(documentCamera)
}

private func asyncSurface() async {
    let interaction = await MainActor.run { ImageAnalysisInteraction() }
    let lifted = await interaction.subject(at: .zero)
    precondition(lifted == nil)
    let subjects = await interaction.subjects
    precondition(subjects.isEmpty)

    let scanner = await MainActor.run {
        DataScannerViewController(recognizedDataTypes: [])
    }
    for await items in await scanner.recognizedItems {
        precondition(items.isEmpty)
    }
}

await MainActor.run {
    syncSurface()
}
await asyncSurface()
print("VISIONKIT_AGENT_RUNTIME_OK")
