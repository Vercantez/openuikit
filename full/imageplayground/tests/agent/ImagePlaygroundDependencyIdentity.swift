@_spi(OpenUIKitHost) import ImagePlayground
import CoreGraphics
import Foundation
import ImageIO
import PencilKit
import SwiftUI
import UIKit

/// Future clean-EC2 dependency-identity probe.
///
/// The isolated host gate does not compile or run this file. A later run must
/// build guest Foundation, CoreGraphics, ImageIO, PencilKit, SwiftUI, and
/// UIKit first, compile ImagePlayground against their `-I`/`-L` paths, then
/// link this client and execute it with `LD_LIBRARY_PATH` covering
/// `libImagePlayground.dylib`.

@MainActor
private final class IdentityDelegate: NSObject, ImagePlaygroundViewController.Delegate {
    var createdURL: URL?
    var cancelled = false

    func imagePlaygroundViewController(
        _ imagePlaygroundViewController: ImagePlaygroundViewController,
        didCreateImageAt imageURL: URL
    ) {
        _ = imagePlaygroundViewController
        createdURL = imageURL
    }

    func imagePlaygroundViewControllerDidCancel(
        _ imagePlaygroundViewController: ImagePlaygroundViewController
    ) {
        cancelled = true
    }
}

private struct IdentityProbeView: View {
    @State private var presented = false

    var body: some View {
        EmptyView()
            .imagePlaygroundSheet(
                isPresented: $presented,
                concept: "probe",
                sourceImage: nil,
                onCompletion: { _ in },
                onCancellation: nil
            )
            .imagePlaygroundSheet(
                isPresented: $presented,
                concept: "probe",
                sourceImageURL: URL(fileURLWithPath: "/tmp/imageplayground-identity.png"),
                onCompletion: { _ in },
                onCancellation: nil
            )
            .imagePlaygroundSheet(
                isPresented: $presented,
                concepts: [.text("probe")],
                sourceImage: nil,
                onCompletion: { _ in },
                onCancellation: nil
            )
            .imagePlaygroundSheet(
                isPresented: $presented,
                concepts: [.text("probe")],
                sourceImageURL: URL(fileURLWithPath: "/tmp/imageplayground-identity.png"),
                onCompletion: { _ in },
                onCancellation: nil
            )
            .imagePlaygroundGenerationStyle(.illustration, in: ImagePlaygroundStyle.all)
            .imagePlaygroundPersonalizationPolicy(.automatic)
    }
}

private func require(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError(message)
    }
}

@MainActor
private func exerciseViewControllerIdentity() {
    require(!ImagePlaygroundViewController.isAvailable, "isAvailable remains fail-closed")

    let controller = ImagePlaygroundViewController()
    let asViewController: UIViewController = controller
    require(controller === asViewController, "ImagePlaygroundViewController is a UIViewController")

    let uiImage = UIImage()
    controller.sourceImage = uiImage
    require(controller.sourceImage != nil, "sourceImage accepts UIImage")

    controller.preferredContentSize = CGSize(width: 320, height: 480)
    require(controller.preferredContentSize.width == 320, "preferredContentSize override")
    controller.isModalInPresentation = true
    require(controller.isModalInPresentation, "isModalInPresentation override")
    _ = controller.modalPresentationStyle
    _ = controller.supportedInterfaceOrientations

    controller.viewDidLoad()
    controller.viewDidDisappear(false)

    let delegate = IdentityDelegate()
    controller.delegate = delegate
    let created = URL(fileURLWithPath: "/tmp/imageplayground-identity-created.png")
    controller._dispatchDelegateDidCreateImageAtForHostTests(created)
    require(delegate.createdURL == created, "required delegate dispatch")
    controller._dispatchDelegateDidCancelForHostTests()
    require(delegate.cancelled, "optional cancel dispatch")

    let existential: any ImagePlaygroundViewController.Delegate = delegate
    let second = URL(fileURLWithPath: "/tmp/imageplayground-identity-existential.png")
    existential.imagePlaygroundViewController(controller, didCreateImageAt: second)
    require(delegate.createdURL == second, "existential required-method dispatch")
    existential.imagePlaygroundViewControllerDidCancel(controller)
}

@MainActor
private func exerciseConceptAndCreatedImageIdentity() {
    let cgImage = CGImage(width: 4, height: 4)
    let fromCGImage = ImagePlaygroundConcept.image(cgImage)
    _ = fromCGImage

    let drawing = PKDrawing()
    _ = ImagePlaygroundConcept.drawing(drawing)

    let created = ImageCreator.CreatedImage(_hostCGImage: cgImage)
    require(created.cgImage === cgImage, "CreatedImage.cgImage is the CoreGraphics identity")
    _ = created.cgImage.width
}

@MainActor
private func exerciseSwiftUIIdentity() {
    _ = IdentityProbeView()
    var values = EnvironmentValues()
    require(!values.supportsImagePlayground, "supportsImagePlayground is fail-closed")
    _ = values.imagePlaygroundPersonalizationPolicy
    _ = values.imagePlaygroundAllowedGenerationStyles
    _ = values.imagePlaygroundSelectedGenerationStyle
}

private func exerciseImageIOURLConcept() throws {
    let cgImage = CGImage(width: 2, height: 2)
    let pngBytes = cgImage.pngData()
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("imageplayground-identity.png")
    try Data(pngBytes).write(to: url)
    _ = ImagePlaygroundConcept.image(url)
    _ = CGImageSourceCreateWithData(Data(pngBytes) as CFData, nil)
}

private func exerciseFailClosedCreator() async {
    do {
        _ = try await ImageCreator()
        fatalError("ImageCreator() must throw when generation is unavailable")
    } catch is ImageCreator.Error {
        return
    } catch {
        fatalError("expected ImageCreator.Error, got \(error)")
    }
}

await MainActor.run {
    exerciseViewControllerIdentity()
    exerciseConceptAndCreatedImageIdentity()
    exerciseSwiftUIIdentity()
}
do {
    try exerciseImageIOURLConcept()
} catch {
    fatalError("ImageIO URL probe failed: \(error)")
}
await exerciseFailClosedCreator()
print("IMAGEPLAYGROUND_DEPENDENCY_IDENTITY_OK")
