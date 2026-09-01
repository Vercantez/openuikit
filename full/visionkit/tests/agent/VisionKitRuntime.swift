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
    _ = T(rawValue: first.rawValue)
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
    precondition(ImageAnalyzer.AnalysisTypes.visualLookUp.rawValue != 0)

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
    let hostView = UIView()
    interaction.willMove(to: hostView)
    interaction.didMove(to: hostView)
    precondition(interaction.view === hostView)
    interaction.preferredInteractionTypes = [.automatic, .textSelection]
    interaction.analysis = hosted
    _ = interaction.activeInteractionTypes
    interaction.setContentsRectNeedsUpdate()
    precondition(interaction.contentsRect.width == 1)
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
    interaction.supplementaryInterfaceFont = UIFont()
    interaction.supplementaryInterfaceContentInsets = .zero
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
    precondition(
        interactionDelegate.contentsRect(for: interaction)
            == CGRect(x: 0, y: 0, width: 1, height: 1)
    )
    precondition(interactionDelegate.contentView(for: interaction) === hostView)
    precondition(interactionDelegate.presentingViewController(for: interaction) == nil)
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
    let barcodeType = DataScannerViewController.RecognizedDataType.barcode(
        symbologies: [VNBarcodeSymbology(rawValue: "QR")]
    )
    precondition(textType != barcodeType)
    _ = textType.hashValue
    _ = barcodeType.hashValue

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
        recognizedDataTypes: [textType, barcodeType],
        qualityLevel: .accurate,
        recognizesMultipleItems: true,
        isHighFrameRateTrackingEnabled: false,
        isPinchToZoomEnabled: false,
        isGuidanceEnabled: false,
        isHighlightingEnabled: true
    )
    scanner.delegate = scannerDelegate
    scanner.loadView()
    scanner.viewDidLoad()
    scanner.viewWillAppear(false)
    _ = scanner.overlayContainerView
    precondition(scanner.recognizedDataTypes.count == 2)
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
    } catch let error as DataScannerViewController.ScanningUnavailable {
        precondition(error == .unsupported)
    } catch {
        preconditionFailure("unexpected startScanning error: \(error)")
    }
    scanner.stopScanning()
    scanner.viewDidDisappear(false)
    scanner.removeFromParent()
    scannerDelegate.dataScannerDidZoom(scanner)
    scannerDelegate.dataScanner(scanner, becameUnavailableWithError: .unsupported)

    let bounds = RecognizedItem.Bounds(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomLeft: .zero,
        bottomRight: CGPoint(x: 1, y: 0)
    )
    let textItem = RecognizedItem.Text(bounds: bounds, transcript: "OCR")
    let barcodeItem = RecognizedItem.Barcode(
        observation: VNBarcodeObservation(payloadStringValue: "payload")
    )
    let recognizedText = RecognizedItem.text(textItem)
    let recognizedBarcode = RecognizedItem.barcode(barcodeItem)
    precondition(recognizedText.id == textItem.id)
    precondition(recognizedBarcode.bounds.topLeft == .zero)
    precondition(textItem.transcript == "OCR")
    precondition(barcodeItem.payloadStringValue == "payload")
    _ = textItem.observation
    _ = barcodeItem.observation
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
    let scan = VNDocumentCameraScan(title: "fixture", pageImages: [UIImage()])
    precondition(scan.pageCount == 1)
    precondition(scan.title == "fixture")
    _ = scan.imageOfPage(at: 0)
    documentDelegate.documentCameraViewController(documentCamera, didFinishWith: scan)
    documentDelegate.documentCameraViewController(
        documentCamera,
        didFailWithError: VisionKitAvailabilityError.documentCameraUnsupported
    )
    documentDelegate.documentCameraViewControllerDidCancel(documentCamera)
}

private func asyncSurface() async {
    let analyzer = ImageAnalyzer()
    let configuration = ImageAnalyzer.Configuration([.text, .machineReadableCode])
    await expectAnalysisFailure {
        try await analyzer.analyze(UIImage(), configuration: configuration)
    }
    await expectAnalysisFailure {
        try await analyzer.analyze(
            UIImage(),
            orientation: .up,
            configuration: configuration
        )
    }
    await expectAnalysisFailure {
        try await analyzer.analyze(
            imageAt: URL(fileURLWithPath: "/tmp/missing.png"),
            orientation: .up,
            configuration: configuration
        )
    }
    await expectAnalysisFailure {
        try await analyzer.analyze(
            CGImage(),
            orientation: .up,
            configuration: configuration
        )
    }
    await expectAnalysisFailure {
        try await analyzer.analyze(
            CVPixelBuffer(),
            orientation: .up,
            configuration: configuration
        )
    }
    await expectAnalysisFailure {
        try await analyzer.analyze(
            CIImage(),
            orientation: .up,
            configuration: configuration
        )
    }

    let interaction = await MainActor.run { ImageAnalysisInteraction() }
    let lifted = await interaction.subject(at: .zero)
    precondition(lifted == nil)
    let subjects = await interaction.subjects
    precondition(subjects.isEmpty)
    do {
        _ = try await interaction.image(for: [])
        preconditionFailure("subject image must fail closed")
    } catch ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable {
    } catch {
        preconditionFailure("unexpected image(for:) error: \(error)")
    }

    let subject = await MainActor.run {
        ImageAnalysisInteraction.Subject(bounds: .zero)
    }
    do {
        _ = try await subject.image
        preconditionFailure("Subject.image must fail closed")
    } catch ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable {
    } catch {
        preconditionFailure("unexpected Subject.image error: \(error)")
    }

    let scanner = await MainActor.run {
        DataScannerViewController(recognizedDataTypes: [])
    }
    do {
        _ = try await scanner.capturePhoto()
        preconditionFailure("capturePhoto must fail closed")
    } catch VisionKitAvailabilityError.cameraUnavailable {
    } catch {
        preconditionFailure("unexpected capturePhoto error: \(error)")
    }
    for await items in await scanner.recognizedItems {
        precondition(items.isEmpty)
    }
}

private func expectAnalysisFailure(
    _ body: () async throws -> ImageAnalysis
) async {
    do {
        _ = try await body()
        preconditionFailure("ImageAnalyzer.analyze must fail closed")
    } catch VisionKitAvailabilityError.imageAnalysisUnsupported {
    } catch {
        preconditionFailure("unexpected analyze error: \(error)")
    }
}

await MainActor.run {
    syncSurface()
}
await asyncSurface()
print("VISIONKIT_AGENT_RUNTIME_OK")
