import Foundation

#if canImport(Metal)
import Metal
#endif
#if canImport(MetalKit)
import MetalKit
#endif

private func defaultLabel() -> TCControlLabel { .buttonA }

public final class TCButtonDescriptor: NSObject {
    public var label: TCControlLabel
    public var contents: TCControlContents?
    public var anchor: TCControlLayoutAnchor
    public var anchorCoordinateSystem: TCControlLayoutAnchorCoordinateSystem
    public var offset: CGPoint
    public var zIndex: Int
    public var size: CGSize
    public var colliderShape: TCColliderShape
    public var highlightDuration: TimeInterval

    public override init() {
        label = defaultLabel()
        contents = nil
        anchor = .center
        anchorCoordinateSystem = .relative
        offset = .zero
        zIndex = 0
        size = .zero
        colliderShape = .circle
        highlightDuration = 0
        super.init()
    }
}

public final class TCSwitchDescriptor: NSObject {
    public var label: TCControlLabel
    public var contents: TCControlContents?
    public var switchedOnContents: TCControlContents?
    public var anchor: TCControlLayoutAnchor
    public var anchorCoordinateSystem: TCControlLayoutAnchorCoordinateSystem
    public var offset: CGPoint
    public var zIndex: Int
    public var size: CGSize
    public var colliderShape: TCColliderShape
    public var highlightDuration: TimeInterval

    public override init() {
        label = defaultLabel()
        contents = nil
        switchedOnContents = nil
        anchor = .center
        anchorCoordinateSystem = .relative
        offset = .zero
        zIndex = 0
        size = .zero
        colliderShape = .circle
        highlightDuration = 0
        super.init()
    }
}

public final class TCThumbstickDescriptor: NSObject {
    public var label: TCControlLabel
    public var backgroundContents: TCControlContents?
    public var stickContents: TCControlContents?
    public var hidesWhenNotPressed: Bool
    public var stickSize: CGSize
    public var size: CGSize
    public var anchor: TCControlLayoutAnchor
    public var anchorCoordinateSystem: TCControlLayoutAnchorCoordinateSystem
    public var offset: CGPoint
    public var zIndex: Int
    public var colliderShape: TCColliderShape
    public var highlightDuration: TimeInterval

    public override init() {
        label = TCControlLabel.leftThumbstick
        backgroundContents = nil
        stickContents = nil
        hidesWhenNotPressed = false
        stickSize = .zero
        size = .zero
        anchor = .bottomLeft
        anchorCoordinateSystem = .relative
        offset = .zero
        zIndex = 0
        colliderShape = .circle
        highlightDuration = 0
        super.init()
    }
}

public final class TCDirectionPadDescriptor: NSObject {
    public var compositeLabel: TCControlLabel?
    public var upLabel: TCControlLabel?
    public var downLabel: TCControlLabel?
    public var leftLabel: TCControlLabel?
    public var rightLabel: TCControlLabel?
    public var upContents: TCControlContents?
    public var downContents: TCControlContents?
    public var leftContents: TCControlContents?
    public var rightContents: TCControlContents?
    public var anchor: TCControlLayoutAnchor
    public var anchorCoordinateSystem: TCControlLayoutAnchorCoordinateSystem
    public var offset: CGPoint
    public var zIndex: Int
    public var size: CGSize
    public var colliderShape: TCColliderShape
    public var highlightDuration: TimeInterval
    public var isRadial: Bool
    public var isDigital: Bool
    public var inputIsMutuallyExclusive: Bool

    public override init() {
        compositeLabel = TCControlLabel.directionPad
        upLabel = nil
        downLabel = nil
        leftLabel = nil
        rightLabel = nil
        upContents = nil
        downContents = nil
        leftContents = nil
        rightContents = nil
        anchor = .bottomLeft
        anchorCoordinateSystem = .relative
        offset = .zero
        zIndex = 0
        size = .zero
        colliderShape = .rect
        highlightDuration = 0
        isRadial = false
        isDigital = true
        inputIsMutuallyExclusive = true
        super.init()
    }
}

public final class TCThrottleDescriptor: NSObject {
    public var label: TCControlLabel
    public var backgroundContents: TCControlContents?
    public var indicatorContents: TCControlContents?
    public var size: CGSize
    public var indicatorSize: CGSize
    public var throttleSize: CGSize
    public var orientation: TCThrottle.Orientation
    public var snapsToBaseValue: Bool
    public var baseValue: CGFloat
    public var anchor: TCControlLayoutAnchor
    public var anchorCoordinateSystem: TCControlLayoutAnchorCoordinateSystem
    public var offset: CGPoint
    public var zIndex: Int
    public var colliderShape: TCColliderShape
    public var highlightDuration: TimeInterval

    public override init() {
        label = defaultLabel()
        backgroundContents = nil
        indicatorContents = nil
        size = .zero
        indicatorSize = .zero
        throttleSize = .zero
        orientation = .vertical
        snapsToBaseValue = true
        baseValue = 0
        anchor = .centerLeft
        anchorCoordinateSystem = .relative
        offset = .zero
        zIndex = 0
        colliderShape = .rect
        highlightDuration = 0
        super.init()
    }
}

public final class TCTouchpadDescriptor: NSObject {
    public var label: TCControlLabel
    public var contents: TCControlContents?
    public var anchor: TCControlLayoutAnchor
    public var anchorCoordinateSystem: TCControlLayoutAnchorCoordinateSystem
    public var offset: CGPoint
    public var zIndex: Int
    public var size: CGSize
    public var colliderShape: TCColliderShape
    public var highlightDuration: TimeInterval
    public var reportsRelativeValues: Bool

    public override init() {
        label = defaultLabel()
        contents = nil
        anchor = .center
        anchorCoordinateSystem = .relative
        offset = .zero
        zIndex = 0
        size = .zero
        colliderShape = .rect
        highlightDuration = 0
        reportsRelativeValues = false
        super.init()
    }
}

public final class TCTouchControllerDescriptor: NSObject {
    public var size: CGSize
    public var drawableSize: CGSize
    public var sampleCount: Int

    public override init() {
        size = .zero
        drawableSize = .zero
        sampleCount = 1
        super.init()
    }

#if canImport(Metal)
    public var device: any MTLDevice
    public var colorPixelFormat: MTLPixelFormat
    public var depthAttachmentPixelFormat: MTLPixelFormat
    public var stencilAttachmentPixelFormat: MTLPixelFormat
#endif

#if canImport(MetalKit)
    public convenience init(mtkView: MTKView) {
        self.init(MTKView: mtkView)
    }

    public convenience init(MTKView mtkView: MTKView) {
        self.init()
        size = mtkView.drawableSize
        drawableSize = mtkView.drawableSize
        _ = mtkView
    }
#endif
}
