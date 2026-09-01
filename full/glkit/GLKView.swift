import Foundation

public protocol GLKViewDelegate: AnyObject {
    func glkView(_ view: GLKView, drawIn rect: CGRect)
}

public protocol GLKViewControllerDelegate: AnyObject {
    func glkViewControllerUpdate(_ controller: GLKViewController)
    func glkViewController(_ controller: GLKViewController, willPause pause: Bool)
}

extension GLKViewControllerDelegate {
    public func glkViewController(_ controller: GLKViewController, willPause pause: Bool) {
        _ = controller
        _ = pause
    }
}

@MainActor
open class GLKView: NSObject {
    open var context: EAGLContext
    public weak var delegate: (any GLKViewDelegate)?
    open var drawableColorFormat: GLKViewDrawableColorFormat = .RGBA8888
    open var drawableDepthFormat: GLKViewDrawableDepthFormat = .formatNone
    open var drawableStencilFormat: GLKViewDrawableStencilFormat = .formatNone
    open var drawableMultisample: GLKViewDrawableMultisample = .multisampleNone
    open var drawableWidth: Int = 0
    open var drawableHeight: Int = 0
    open var enableSetNeedsDisplay: Bool = true
    public let frame: CGRect

    public init(frame: CGRect, context: EAGLContext) {
        self.frame = frame
        self.context = context
        super.init()
    }

    /// No EAGL drawable exists on Linux; this is a documented no-op.
    open func bindDrawable() {}

    /// No EAGL drawable exists on Linux; this is a documented no-op.
    open func deleteDrawable() {}

    open func display() {
        delegate?.glkView(self, drawIn: frame)
    }

    /// Returns an empty image. Linux GLKit does not read back a GPU framebuffer.
    open var snapshot: UIImage { UIImage() }
}

@MainActor
open class GLKViewController: NSObject {
    public weak var delegate: (any GLKViewControllerDelegate)?
    open var preferredFramesPerSecond: Int = 30
    open private(set) var framesPerSecond: Int = 0
    open private(set) var framesDisplayed: Int = 0
    open var isPaused: Bool = true {
        didSet {
            if oldValue != isPaused {
                delegate?.glkViewController(self, willPause: isPaused)
            }
        }
    }
    open var pauseOnWillResignActive: Bool = true
    open var resumeOnDidBecomeActive: Bool = true
    open private(set) var timeSinceFirstResume: TimeInterval = 0
    open private(set) var timeSinceLastResume: TimeInterval = 0
    open private(set) var timeSinceLastUpdate: TimeInterval = 0
    open private(set) var timeSinceLastDraw: TimeInterval = 0

    public override init() {
        super.init()
    }
}
