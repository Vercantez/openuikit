import Foundation
import UIKit
import CoreGraphics
import ImageIO
import CoreImage
import CoreVideo
import Vision
@_spi(OpenUIKitHost) import VisionKit

#if canImport(Glibc)
import Glibc
#endif

// Integrated dependency-identity client for a future clean EC2 guest run.
// Isolated `tests/acceptance/test_host.sh` does not compile this file.
//
// EC2 (no local Docker):
// 1. Build real guest Foundation, UIKit, CoreGraphics, ImageIO, CoreImage,
//    CoreVideo, and Vision modules and dylibs.
// 2. Build VisionKit with those -I/-L paths into libVisionKit.dylib.
// 3. Link this client against libVisionKit.dylib and the dependency dylibs.
// 4. Run with LD_LIBRARY_PATH so libVisionKit.dylib is loaded.
// 5. Confirm the marker below and that libVisionKit.dylib is in the process
//    image list.

private func requireLoadedVisionKit() {
#if os(Linux) && canImport(Glibc)
    let handle = dlopen("libVisionKit.dylib", Int32(RTLD_NOW) | Int32(RTLD_NOLOAD))
    precondition(handle != nil, "libVisionKit.dylib must already be loaded")
#endif
}

@MainActor
private func passUIKitRoutes() async throws {
    let image = UIImage()
    let analyzer = ImageAnalyzer()
    let configuration = ImageAnalyzer.Configuration([.text, .machineReadableCode])
    do {
        _ = try await analyzer.analyze(image, configuration: configuration)
        preconditionFailure("analyze(UIImage) must fail closed")
    } catch VisionKitHostError.imageAnalysisUnsupported {
    }
    do {
        _ = try await analyzer.analyze(
            image,
            orientation: .up,
            configuration: configuration
        )
        preconditionFailure("analyze(UIImage, orientation:) must fail closed")
    } catch VisionKitHostError.imageAnalysisUnsupported {
    }

    let view = UIView()
    let interaction = ImageAnalysisInteraction()
    interaction.willMove(to: view)
    interaction.didMove(to: view)
    precondition(interaction.view === view)
    interaction.supplementaryInterfaceFont = UIFont.systemFont(ofSize: 12)
    interaction.supplementaryInterfaceContentInsets = .zero
    _ = interaction.supplementaryInterfaceFont
    _ = interaction.supplementaryInterfaceContentInsets
    do {
        _ = try await interaction.image(for: [])
        preconditionFailure("image(for:) must fail closed")
    } catch ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable {
    }
    let subject = ImageAnalysisInteraction.Subject(bounds: .zero)
    do {
        _ = try await subject.image
        preconditionFailure("Subject.image must fail closed")
    } catch ImageAnalysisInteraction.SubjectUnavailable.imageUnavailable {
    }

    let scanner = DataScannerViewController(recognizedDataTypes: [])
    scanner.loadView()
    scanner.viewDidLoad()
    scanner.viewWillAppear(false)
    _ = scanner.overlayContainerView
    do {
        _ = try await scanner.capturePhoto()
        preconditionFailure("capturePhoto must fail closed")
    } catch VisionKitHostError.cameraUnavailable {
    }
    scanner.viewDidDisappear(false)
    scanner.removeFromParent()

    let scan = VNDocumentCameraScan(title: "identity", pageImages: [image])
    precondition(scan.pageCount == 1)
    _ = scan.imageOfPage(at: 0)
}

private func passImageIOAndGraphicsRoutes() async throws {
    let analyzer = ImageAnalyzer()
    let configuration = ImageAnalyzer.Configuration(.text)
    let orientation = CGImagePropertyOrientation.up
    do {
        _ = try await analyzer.analyze(
            imageAt: URL(fileURLWithPath: "/tmp/visionkit-missing.png"),
            orientation: orientation,
            configuration: configuration
        )
        preconditionFailure("analyze(imageAt:) must fail closed")
    } catch VisionKitHostError.imageAnalysisUnsupported {
    }

    let cgImage = CGImage(width: 1, height: 1)
    do {
        _ = try await analyzer.analyze(
            cgImage,
            orientation: orientation,
            configuration: configuration
        )
        preconditionFailure("analyze(CGImage) must fail closed")
    } catch VisionKitHostError.imageAnalysisUnsupported {
    }
}

private func passCoreImageRoute() async throws {
    let analyzer = ImageAnalyzer()
    let configuration = ImageAnalyzer.Configuration(.text)
    guard let ciImage = CIFilter.linearGradient().outputImage else {
        preconditionFailure("CIImage identity must be constructible")
    }
    do {
        _ = try await analyzer.analyze(
            ciImage,
            orientation: .up,
            configuration: configuration
        )
        preconditionFailure("analyze(CIImage) must fail closed")
    } catch VisionKitHostError.imageAnalysisUnsupported {
    }
}

private func passCoreVideoRoute() async throws {
    let analyzer = ImageAnalyzer()
    let configuration = ImageAnalyzer.Configuration(.text)
    let pixelBuffer = CVPixelBuffer()
    do {
        _ = try await analyzer.analyze(
            pixelBuffer,
            orientation: .up,
            configuration: configuration
        )
        preconditionFailure("analyze(CVPixelBuffer) must fail closed")
    } catch VisionKitHostError.imageAnalysisUnsupported {
    }
}

private func passVisionRoutes() {
    let symbology = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyQR")
    let barcodeType = DataScannerViewController.RecognizedDataType.barcode(
        symbologies: [symbology]
    )
    _ = barcodeType
    let textObservation = VNRecognizedTextObservation()
    let barcodeObservation = VNBarcodeObservation()
    let text = RecognizedItem.Text(
        transcript: "identity",
        observation: textObservation
    )
    let barcode = RecognizedItem.Barcode(observation: barcodeObservation)
    _ = text.observation
    _ = barcode.observation
    _ = RecognizedItem.text(text)
    _ = RecognizedItem.barcode(barcode)
}

requireLoadedVisionKit()
try await passUIKitRoutes()
try await passImageIOAndGraphicsRoutes()
try await passCoreImageRoute()
try await passCoreVideoRoute()
passVisionRoutes()
print("VISIONKIT_DEPENDENCY_IDENTITY_OK")
