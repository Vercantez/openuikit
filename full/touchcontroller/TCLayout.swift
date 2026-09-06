import Foundation

/// Layout box of a control on the parent canvas.
public protocol TCControlLayout: NSObjectProtocol {
    var anchor: TCControlLayoutAnchor { get set }
    var anchorCoordinateSystem: TCControlLayoutAnchorCoordinateSystem { get set }
    var offset: CGPoint { get set }
    var position: CGPoint { get }
    var size: CGSize { get set }
    var zIndex: Int { get set }
}

/// Interactive on-screen control.
///
/// `highlightDuration` is optional in the ObjC protocol. Every Linux
/// control stores it as a required property; Apple's optional-witness
/// timing is an oracle question.
public protocol TCControl: TCControlLayout {
    var label: TCControlLabel { get }
    var colliderShape: TCColliderShape { get }
    var isPressed: Bool { get }
    var isEnabled: Bool { get set }
    var highlightDuration: TimeInterval { get set }
    func handleTouchBegan(at point: CGPoint)
    func handleTouchMoved(at point: CGPoint)
    func handleTouchEnded(at point: CGPoint)
}

enum TCLayoutMath {
    static func anchorPoint(size: CGSize, anchor: TCControlLayoutAnchor) -> CGPoint {
        let width = max(size.width, 0)
        let height = max(size.height, 0)
        switch anchor {
        case .topLeft:
            return CGPoint(x: 0, y: 0)
        case .topCenter:
            return CGPoint(x: width / 2, y: 0)
        case .topRight:
            return CGPoint(x: width, y: 0)
        case .centerLeft:
            return CGPoint(x: 0, y: height / 2)
        case .center:
            return CGPoint(x: width / 2, y: height / 2)
        case .centerRight:
            return CGPoint(x: width, y: height / 2)
        case .bottomLeft:
            return CGPoint(x: 0, y: height)
        case .bottomCenter:
            return CGPoint(x: width / 2, y: height)
        case .bottomRight:
            return CGPoint(x: width, y: height)
        }
    }

    static func resolvedOrigin(
        parent: CGSize,
        size: CGSize,
        anchor: TCControlLayoutAnchor,
        coordinateSystem: TCControlLayoutAnchorCoordinateSystem,
        offset: CGPoint
    ) -> CGPoint {
        let parentAnchor = anchorPoint(size: parent, anchor: anchor)
        let applied: CGPoint
        switch coordinateSystem {
        case .absolute:
            applied = offset
        case .relative:
            applied = CGPoint(
                x: offset.x * parent.width,
                y: offset.y * parent.height
            )
        }
        let controlAnchor = anchorPoint(size: size, anchor: anchor)
        return CGPoint(
            x: parentAnchor.x + applied.x - controlAnchor.x,
            y: parentAnchor.y + applied.y - controlAnchor.y
        )
    }

    static func contains(
        point: CGPoint,
        origin: CGPoint,
        size: CGSize,
        shape: TCColliderShape
    ) -> Bool {
        let width = max(size.width, 0)
        let height = max(size.height, 0)
        if width == 0 || height == 0 {
            return false
        }
        let rect = CGRect(origin: origin, size: CGSize(width: width, height: height))
        switch shape {
        case .rect:
            return rect.contains(point)
        case .leftSide:
            return CGRect(
                x: rect.minX,
                y: rect.minY,
                width: width / 2,
                height: height
            ).contains(point)
        case .rightSide:
            return CGRect(
                x: rect.minX + width / 2,
                y: rect.minY,
                width: width / 2,
                height: height
            ).contains(point)
        case .circle:
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(width, height) / 2
            let dx = point.x - center.x
            let dy = point.y - center.y
            return (dx * dx + dy * dy) <= (radius * radius)
        }
    }
}

/// Shared layout, press, and enablement state for concrete controls.
public class TCControlBase: NSObject, TCControl {
    public var label: TCControlLabel
    public private(set) var colliderShape: TCColliderShape
    public var isEnabled: Bool = true
    public private(set) var isPressed: Bool = false
    public var highlightDuration: TimeInterval = 0
    public var anchor: TCControlLayoutAnchor
    public var anchorCoordinateSystem: TCControlLayoutAnchorCoordinateSystem
    public var offset: CGPoint
    public var size: CGSize
    public var zIndex: Int
    weak var canvas: TCTouchController?

    public var position: CGPoint {
        let parent = canvas?.size ?? .zero
        return TCLayoutMath.resolvedOrigin(
            parent: parent,
            size: size,
            anchor: anchor,
            coordinateSystem: anchorCoordinateSystem,
            offset: offset
        )
    }

    init(
        label: TCControlLabel,
        colliderShape: TCColliderShape,
        anchor: TCControlLayoutAnchor,
        anchorCoordinateSystem: TCControlLayoutAnchorCoordinateSystem,
        offset: CGPoint,
        size: CGSize,
        zIndex: Int,
        highlightDuration: TimeInterval
    ) {
        self.label = label
        self.colliderShape = colliderShape
        self.anchor = anchor
        self.anchorCoordinateSystem = anchorCoordinateSystem
        self.offset = offset
        self.size = size
        self.zIndex = zIndex
        self.highlightDuration = highlightDuration
        super.init()
    }

    func contains(_ point: CGPoint) -> Bool {
        TCLayoutMath.contains(
            point: point,
            origin: position,
            size: size,
            shape: colliderShape
        )
    }

    public func handleTouchBegan(at point: CGPoint) {
        guard isEnabled else { return }
        isPressed = contains(point)
        if isPressed {
            applyBegan(at: point)
        }
    }

    public func handleTouchMoved(at point: CGPoint) {
        guard isEnabled, isPressed else { return }
        applyMoved(at: point)
    }

    public func handleTouchEnded(at point: CGPoint) {
        guard isEnabled, isPressed else { return }
        applyEnded(at: point)
        isPressed = false
    }

    func applyBegan(at point: CGPoint) {
        _ = point
    }

    func applyMoved(at point: CGPoint) {
        _ = point
    }

    func applyEnded(at point: CGPoint) {
        _ = point
    }
}
