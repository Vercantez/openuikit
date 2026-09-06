import TouchController
import Foundation
import UIKit

/// Future clean-EC2 identity probe. Not compiled by the isolated host gate.
///
/// Isolated hosts pass Foundation `CGPoint` / `CGSize` / `TimeInterval`
/// values through public TouchController APIs. Same-named substitutes for
/// `UIImage`, `MTLDevice`, `MTKView`, and `GCController` are forbidden.
/// The only UIKit-typed Apple initializer is
/// `TCControlImage.init(uiImage:size:device:)`, which also requires Metal
/// and is unavailable on this host.

enum _TCDependencyIdentity {
    static func prove() {
        let descriptor = TCTouchControllerDescriptor()
        let size = CGSize(width: 320, height: 180)
        descriptor.size = size
        descriptor.drawableSize = size
        precondition(descriptor.size.width == size.width)
        precondition(descriptor.size.height == size.height)
        let controller = TCTouchController(descriptor: descriptor)
        let point = CGPoint(x: 12, y: 18)
        _ = controller.handleTouchBegan(at: point, index: 0)
        _ = controller.handleTouchEnded(at: point, index: 0)
        let duration: TimeInterval = 0.2
        let button = TCButtonDescriptor()
        button.highlightDuration = duration
        precondition(button.highlightDuration == duration)
        _ = UIImage.self
    }
}

_TCDependencyIdentity.prove()
print("TOUCHCONTROLLER_DEPENDENCY_IDENTITY_OK")
