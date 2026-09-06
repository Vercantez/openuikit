import Foundation

public final class TCButton: TCControlBase {
    public var contents: TCControlContents?

    init(descriptor: TCButtonDescriptor, canvas: TCTouchController) {
        contents = descriptor.contents
        super.init(
            label: descriptor.label,
            colliderShape: descriptor.colliderShape,
            anchor: descriptor.anchor,
            anchorCoordinateSystem: descriptor.anchorCoordinateSystem,
            offset: descriptor.offset,
            size: descriptor.size,
            zIndex: descriptor.zIndex,
            highlightDuration: descriptor.highlightDuration
        )
        self.canvas = canvas
    }
}

public final class TCSwitch: TCControlBase {
    public var contents: TCControlContents?
    public var switchedOnContents: TCControlContents?
    public private(set) var isSwitchedOn: Bool = false

    init(descriptor: TCSwitchDescriptor, canvas: TCTouchController) {
        contents = descriptor.contents
        switchedOnContents = descriptor.switchedOnContents
        super.init(
            label: descriptor.label,
            colliderShape: descriptor.colliderShape,
            anchor: descriptor.anchor,
            anchorCoordinateSystem: descriptor.anchorCoordinateSystem,
            offset: descriptor.offset,
            size: descriptor.size,
            zIndex: descriptor.zIndex,
            highlightDuration: descriptor.highlightDuration
        )
        self.canvas = canvas
    }

    override func applyEnded(at point: CGPoint) {
        if contains(point) {
            isSwitchedOn.toggle()
        }
    }
}

public final class TCThumbstick: TCControlBase {
    public var backgroundContents: TCControlContents?
    public var stickContents: TCControlContents?
    public var hidesWhenNotPressed: Bool
    public var stickSize: CGSize

    init(descriptor: TCThumbstickDescriptor, canvas: TCTouchController) {
        backgroundContents = descriptor.backgroundContents
        stickContents = descriptor.stickContents
        hidesWhenNotPressed = descriptor.hidesWhenNotPressed
        stickSize = descriptor.stickSize
        super.init(
            label: descriptor.label,
            colliderShape: descriptor.colliderShape,
            anchor: descriptor.anchor,
            anchorCoordinateSystem: descriptor.anchorCoordinateSystem,
            offset: descriptor.offset,
            size: descriptor.size,
            zIndex: descriptor.zIndex,
            highlightDuration: descriptor.highlightDuration
        )
        self.canvas = canvas
    }
}

public final class TCDirectionPad: TCControlBase {
    public var compositeLabel: TCControlLabel?
    public var upLabel: TCControlLabel?
    public var downLabel: TCControlLabel?
    public var leftLabel: TCControlLabel?
    public var rightLabel: TCControlLabel?
    public var upContents: TCControlContents?
    public var downContents: TCControlContents?
    public var leftContents: TCControlContents?
    public var rightContents: TCControlContents?
    public var isRadial: Bool
    public var isDigital: Bool
    public var inputIsMutuallyExclusive: Bool

    init(descriptor: TCDirectionPadDescriptor, canvas: TCTouchController) {
        compositeLabel = descriptor.compositeLabel
        upLabel = descriptor.upLabel
        downLabel = descriptor.downLabel
        leftLabel = descriptor.leftLabel
        rightLabel = descriptor.rightLabel
        upContents = descriptor.upContents
        downContents = descriptor.downContents
        leftContents = descriptor.leftContents
        rightContents = descriptor.rightContents
        isRadial = descriptor.isRadial
        isDigital = descriptor.isDigital
        inputIsMutuallyExclusive = descriptor.inputIsMutuallyExclusive
        let label = descriptor.compositeLabel ?? TCControlLabel.directionPad
        super.init(
            label: label,
            colliderShape: descriptor.colliderShape,
            anchor: descriptor.anchor,
            anchorCoordinateSystem: descriptor.anchorCoordinateSystem,
            offset: descriptor.offset,
            size: descriptor.size,
            zIndex: descriptor.zIndex,
            highlightDuration: descriptor.highlightDuration
        )
        self.canvas = canvas
    }
}

public final class TCThrottle: TCControlBase {
    public enum Orientation: Int, Sendable, Hashable {
        case vertical = 0
        case horizontal = 1
    }

    public var backgroundContents: TCControlContents?
    public var indicatorContents: TCControlContents?
    public var orientation: Orientation
    public var snapsToBaseValue: Bool
    public var indicatorSize: CGSize
    public var throttleSize: CGSize
    private var storedBaseValue: CGFloat = 0

    public var baseValue: CGFloat {
        get { storedBaseValue }
        set { storedBaseValue = Self.clampUnit(newValue) }
    }

    init(descriptor: TCThrottleDescriptor, canvas: TCTouchController) {
        backgroundContents = descriptor.backgroundContents
        indicatorContents = descriptor.indicatorContents
        orientation = descriptor.orientation
        snapsToBaseValue = descriptor.snapsToBaseValue
        indicatorSize = descriptor.indicatorSize
        throttleSize = descriptor.throttleSize
        storedBaseValue = Self.clampUnit(descriptor.baseValue)
        super.init(
            label: descriptor.label,
            colliderShape: descriptor.colliderShape,
            anchor: descriptor.anchor,
            anchorCoordinateSystem: descriptor.anchorCoordinateSystem,
            offset: descriptor.offset,
            size: descriptor.size,
            zIndex: descriptor.zIndex,
            highlightDuration: descriptor.highlightDuration
        )
        self.canvas = canvas
    }

    static func clampUnit(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }

    override func applyEnded(at point: CGPoint) {
        _ = point
        if snapsToBaseValue {
            baseValue = Self.clampUnit(baseValue)
        }
    }
}

public final class TCTouchpad: TCControlBase {
    public var contents: TCControlContents?
    public var reportsRelativeValues: Bool

    init(descriptor: TCTouchpadDescriptor, canvas: TCTouchController) {
        contents = descriptor.contents
        reportsRelativeValues = descriptor.reportsRelativeValues
        super.init(
            label: descriptor.label,
            colliderShape: descriptor.colliderShape,
            anchor: descriptor.anchor,
            anchorCoordinateSystem: descriptor.anchorCoordinateSystem,
            offset: descriptor.offset,
            size: descriptor.size,
            zIndex: descriptor.zIndex,
            highlightDuration: descriptor.highlightDuration
        )
        self.canvas = canvas
    }
}
