#if canImport(CoreGraphics) && canImport(UIKit) && canImport(SwiftUI) && canImport(PencilKit) && canImport(ImageIO)
import CoreGraphics
import Foundation
import ImageIO
import PencilKit
import SwiftUI
import UIKit
import ImagePlayground

/// Future clean EC2 probe. Not compiled by the isolated host gate.
/// Requires guest CoreGraphics, ImageIO, PencilKit, SwiftUI, and UIKit dylibs.
@MainActor
enum ImagePlaygroundDependencyIdentity {
    static func run() async {
        let controller = ImagePlaygroundViewController()
        let asViewController: UIViewController = controller
        _ = asViewController

        precondition(ImagePlaygroundViewController.isAvailable == false)

        final class ProbeDelegate: NSObject, ImagePlaygroundViewController.Delegate {
            func imagePlaygroundViewController(
                _ imagePlaygroundViewController: ImagePlaygroundViewController,
                didCreateImageAt imageURL: URL
            ) {}
        }
        let delegate: any ImagePlaygroundViewController.Delegate = ProbeDelegate()
        controller.delegate = delegate
        let existential: any ImagePlaygroundViewController.Delegate = delegate
        _ = existential

        controller.concepts = [ImagePlaygroundConcept.text("identity")]
        controller.personalizationPolicy = .disabled
        controller.allowedGenerationStyles = ImagePlaygroundStyle.all
        controller.selectedGenerationStyle = .sketch
        controller.preferredContentSize = CGSize(width: 320, height: 480)

        do {
            _ = try await ImageCreator()
            fatalError("ImageCreator.init must stay fail-closed")
        } catch ImageCreator.Error.unavailable {
        } catch {
            fatalError("unexpected ImageCreator error \(error)")
        }

        print("IMAGEPLAYGROUND_DEPENDENCY_IDENTITY_OK")
    }
}
#endif
