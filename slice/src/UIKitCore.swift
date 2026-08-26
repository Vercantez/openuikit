// OpenUIKit — portable UIKit reimplementation.
// VENDOR-EDIT (swift-macho-linux slice): trimmed from ~/uikit's UIKitCore.swift.
// Removed resource/font/image fields (resourceRoot, imageSearchPaths,
// imageScreenScale, fontPaths, systemFontCut, layerCaching) that pull the
// FontEngine / UIImage / ResourceIO stacks — the boxes_basic / corner_radius
// render slice draws only rects + corner radii and needs none of them.
// Kept: the runtime knobs RenderPass / UIView / UIViewAnimation reference.

public enum OpenUIKitRuntime {
    public static var renderBackend: RenderBackend {
        get { CanvasBackendSelection.current }
        set { CanvasBackendSelection.current = newValue }
    }
    // Slice default is the hand-written render pass (avoids LayerBridge, which
    // this slice does not vendor). Still uses the .quartz backend below.
    public static var compositor: RenderCompositor = .renderPass
    public static var animationTime: Double = 0
    public internal(set) static var animationWorkDeadline: Double = -.infinity
    static func noteAnimationWork(until t: Double) {
        if t > animationWorkDeadline { animationWorkDeadline = t }
    }
}

public enum RenderCompositor: Sendable {
    case renderPass
    case layers
}
