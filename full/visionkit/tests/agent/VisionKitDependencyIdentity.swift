@_spi(OpenUIKitHost) import VisionKit
import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Vision)
import Vision
#endif

#if false
import UIKit
import Vision
#endif

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-UIKit/Vision success.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation, UIKit, and Vision modules and dylibs.
// 2. Build VisionKit with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports VisionKit and the dependencies.
// 4. Run with `LD_LIBRARY_PATH` covering every dylib.
// 5. Confirm `VISIONKIT_DEPENDENCY_IDENTITY_OK` and that `libVisionKit.dylib`
//    was loaded.
//
// Isolated hosts pass Foundation `CGPoint` / `CGRect` / `URL` / `UUID` /
// `AttributedString` values through VisionKit. Same-named substitutes for
// UIImage, UIView, CGImage, CIImage, CVPixelBuffer, and Vision observations
// are forbidden.

func visionKitDependencyIdentityProbe() {
    let bounds = RecognizedItem.Bounds(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    precondition(type(of: bounds.topLeft) == CGPoint.self)
    precondition(!String(reflecting: type(of: bounds.topLeft)).hasPrefix("VisionKit."))

    let rect = CGRect(x: 2, y: 3, width: 4, height: 5)
    precondition(type(of: rect) == CGRect.self)

    let interaction = ImageAnalysisInteraction()
    interaction.setContentsRectNeedsUpdate()
    _ = interaction.contentsRect
    let scanner = DataScannerViewController(recognizedDataTypes: [.text()])
    scanner.regionOfInterest = rect
    let stored: CGRect? = scanner.regionOfInterest
    precondition(stored == rect)
    precondition(!String(reflecting: type(of: stored)).hasPrefix("VisionKit."))
    let text = interaction.text
    _ = text
    let attributed: AttributedString = interaction.selectedAttributedText
    precondition(type(of: attributed) == AttributedString.self)
    let id: UUID = RecognizedItem.Text.hostFixture(
        transcript: "id",
        bounds: bounds
    ).id
    precondition(type(of: id) == UUID.self)

#if canImport(UIKit)
    let image = UIImage()
    _ = image
    precondition(!String(reflecting: type(of: image)).hasPrefix("VisionKit."))
#endif

    print("VISIONKIT_DEPENDENCY_IDENTITY_OK")
}

visionKitDependencyIdentityProbe()
