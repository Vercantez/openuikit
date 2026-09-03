import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(OpenGLES)
import OpenGLES
#endif
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit) && canImport(OpenGLES) && canImport(CoreGraphics)
@MainActor
public protocol GLKViewDelegate: NSObjectProtocol {
    func glkView(_ view: GLKView, drawIn rect: CGRect)
}

@MainActor
public protocol GLKViewControllerDelegate: NSObjectProtocol {
    func glkViewControllerUpdate(_ controller: GLKViewController)
    func glkViewController(_ controller: GLKViewController, willPause pause: Bool)
}

@MainActor
open class GLKView: UIView {
    open var context: EAGLContext
    public weak var delegate: (any GLKViewDelegate)?
    open var drawableColorFormat: GLKViewDrawableColorFormat = .RGBA8888
    open var drawableDepthFormat: GLKViewDrawableDepthFormat = .formatNone
    open var drawableStencilFormat: GLKViewDrawableStencilFormat = .formatNone
    open var drawableMultisample: GLKViewDrawableMultisample = .multisampleNone
    open var drawableWidth: Int = 0
    open var drawableHeight: Int = 0
    open var enableSetNeedsDisplay: Bool = true

    public init(frame: CGRect, context: EAGLContext) {
        self.context = context
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    open func bindDrawable() {}

    open func deleteDrawable() {}

    open func display() {
        delegate?.glkView(self, drawIn: bounds)
    }

    /// Pixel readback is not implemented. This port does not fabricate a UIImage.
    open var snapshot: UIImage {
        fatalError("GLKView.snapshot is unavailable in this GLKit port; framebuffer readback is not implemented")
    }
}

@MainActor
open class GLKViewController: UIViewController {
    public weak var delegate: (any GLKViewControllerDelegate)?
    open var preferredFramesPerSecond: Int = 0
    open private(set) var framesPerSecond: Int = 0
    open private(set) var framesDisplayed: Int = 0
    open var isPaused: Bool = true
    open var pauseOnWillResignActive: Bool = true
    open var resumeOnDidBecomeActive: Bool = true
    open private(set) var timeSinceFirstResume: TimeInterval = 0
    open private(set) var timeSinceLastResume: TimeInterval = 0
    open private(set) var timeSinceLastUpdate: TimeInterval = 0
    open private(set) var timeSinceLastDraw: TimeInterval = 0

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
