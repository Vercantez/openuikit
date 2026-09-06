import Foundation

public protocol SKSceneDelegate: NSObjectProtocol {
    func update(_ currentTime: TimeInterval, for scene: SKScene)
    func didEvaluateActions(for scene: SKScene)
    func didSimulatePhysics(for scene: SKScene)
    func didApplyConstraints(for scene: SKScene)
    func didFinishUpdate(for scene: SKScene)
}

public extension SKSceneDelegate {
    func update(_ currentTime: TimeInterval, for scene: SKScene) {}
    func didEvaluateActions(for scene: SKScene) {}
    func didSimulatePhysics(for scene: SKScene) {}
    func didApplyConstraints(for scene: SKScene) {}
    func didFinishUpdate(for scene: SKScene) {}
}

public protocol SKViewDelegate: NSObjectProtocol {
    func view(_ view: SKView, shouldRenderAtTime time: TimeInterval) -> Bool
}

public extension SKViewDelegate {
    func view(_ view: SKView, shouldRenderAtTime time: TimeInterval) -> Bool { true }
}

open class SKScene: SKNode {
    public var size: CGSize {
        didSet { if oldValue != size { didChangeSize(oldValue) } }
    }
    public var scaleMode: SKSceneScaleMode = .fill
    public var backgroundColor: SKColor = .black
    public var anchorPoint: CGPoint = .zero
    public weak var camera: SKCameraNode?
    public weak var listener: SKNode?
    public weak var delegate: (any SKSceneDelegate)?
    public internal(set) weak var view: SKView?
    public let physicsWorld = SKPhysicsWorld()
    var _lastUpdate: TimeInterval?

    public init(size: CGSize) {
        self.size = size
        super.init()
        physicsWorld._scene = self
        sceneDidLoad()
    }

    public required init?(coder: NSCoder) {
        size = CGSize(
            width: CGFloat(coder.decodeDouble(forKey: "w")),
            height: CGFloat(coder.decodeDouble(forKey: "h"))
        )
        super.init(coder: coder)
        physicsWorld._scene = self
    }

    public override init() {
        size = CGSize(width: 1024, height: 768)
        super.init()
        physicsWorld._scene = self
    }

    open func sceneDidLoad() {}
    open func didChangeSize(_ oldSize: CGSize) { _ = oldSize }
    open func didMove(to view: SKView) { self.view = view }
    open func willMove(from view: SKView) {
        if self.view === view { self.view = nil }
    }
    open func update(_ currentTime: TimeInterval) {
        delegate?.update(currentTime, for: self)
        let dt: TimeInterval
        if let last = _lastUpdate {
            dt = max(0, min(currentTime - last, 1.0 / 15.0))
        } else {
            dt = 1.0 / 60.0
        }
        _lastUpdate = currentTime
        _evaluateActions(dt: dt)
        didEvaluateActions()
        physicsWorld._step(dt: dt * TimeInterval(physicsWorld.speed))
        didSimulatePhysics()
        _applyConstraints()
        didApplyConstraints()
        didFinishUpdate()
    }

    open func didEvaluateActions() { delegate?.didEvaluateActions(for: self) }
    open func didSimulatePhysics() { delegate?.didSimulatePhysics(for: self) }
    open func didApplyConstraints() { delegate?.didApplyConstraints(for: self) }
    open func didFinishUpdate() { delegate?.didFinishUpdate(for: self) }

    open func convertPoint(fromView point: CGPoint) -> CGPoint {
        let viewSize = view?.bounds.size ?? size
        let mapping = SKViewport.mapping(sceneSize: size, viewSize: viewSize, mode: scaleMode)
        let sceneX = (point.x - mapping.offsetX) / mapping.scaleX
        let sceneYFromTop = (point.y - mapping.offsetY) / mapping.scaleY
        let origin = CGPoint(x: -size.width * anchorPoint.x, y: -size.height * anchorPoint.y)
        return CGPoint(x: origin.x + sceneX, y: origin.y + (size.height - sceneYFromTop))
    }

    open func convertPoint(toView point: CGPoint) -> CGPoint {
        let viewSize = view?.bounds.size ?? size
        let mapping = SKViewport.mapping(sceneSize: size, viewSize: viewSize, mode: scaleMode)
        let origin = CGPoint(x: -size.width * anchorPoint.x, y: -size.height * anchorPoint.y)
        let sceneX = point.x - origin.x
        let sceneYFromBottom = point.y - origin.y
        return CGPoint(
            x: sceneX * mapping.scaleX + mapping.offsetX,
            y: (size.height - sceneYFromBottom) * mapping.scaleY + mapping.offsetY
        )
    }

    public override var frame: CGRect {
        CGRect(origin: .zero, size: size)
    }
}

open class SKView: NSObject {
    public weak var delegate: (any SKViewDelegate)?
    public private(set) var scene: SKScene?
    public var isPaused: Bool = false
    public var isAsynchronous: Bool = true
    public var ignoresSiblingOrder: Bool = false
    public var shouldCullNonVisibleNodes: Bool = true
    public var allowsTransparency: Bool = false
    public var disableDepthStencilBuffer: Bool = false
    public var showsFPS: Bool = false
    public var showsNodeCount: Bool = false
    public var showsDrawCount: Bool = false
    public var showsQuadCount: Bool = false
    public var showsPhysics: Bool = false
    public var showsFields: Bool = false
    public var preferredFramesPerSecond: Int = 60
    public var preferredFrameRate: Float = 60
    public var frameInterval: Int = 1
    /// Linux host viewport. Apple `SKView` inherits `UIView.bounds`.
    public var bounds: CGRect = CGRect(x: 0, y: 0, width: 320, height: 480)

    public override init() { super.init() }

    public func presentScene(_ scene: SKScene?) {
        if let current = self.scene {
            current.willMove(from: self)
            current.view = nil
        }
        self.scene = scene
        scene?.view = self
        if let scene, scene.scaleMode == .resizeFill, scene.size != bounds.size {
            scene.size = bounds.size
        }
        scene?.didMove(to: self)
    }

    public func presentScene(_ scene: SKScene, transition: SKTransition) {
        _ = transition
        presentScene(scene)
    }

    public func convert(_ point: CGPoint, from scene: SKScene) -> CGPoint {
        scene.convertPoint(toView: point)
    }

    public func convert(_ point: CGPoint, to scene: SKScene) -> CGPoint {
        scene.convertPoint(fromView: point)
    }

    public func texture(from node: SKNode) -> SKTexture? {
        texture(from: node, crop: node.calculateAccumulatedFrame())
    }

    public func texture(from node: SKNode, crop: CGRect) -> SKTexture? {
        SKSoftwareRaster.capture(node: node, crop: crop)
    }
}

/// CPU scene driver. Metal `init(device:)` / encode paths stay unavailable.
open class SKRenderer: NSObject {
    public var scene: SKScene?
    public var ignoresSiblingOrder: Bool = false
    public var shouldCullNonVisibleNodes: Bool = true
    public var showsDrawCount: Bool = false
    public var showsFields: Bool = false
    public var showsNodeCount: Bool = false
    public var showsPhysics: Bool = false
    public var showsQuadCount: Bool = false

    public override init() { super.init() }

    public func update(atTime currentTime: TimeInterval) {
        scene?.update(currentTime)
    }
}

enum SKSoftwareRaster {
    static func capture(node: SKNode, crop: CGRect) -> SKTexture? {
        let width = max(1, Int(crop.width.rounded(.down)))
        let height = max(1, Int(crop.height.rounded(.down)))
        guard crop.width > 0, crop.height > 0 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let space = node.parent ?? node
        func fill(_ rect: CGRect, color: SKColor) {
            let (red, green, blue, alpha) = sk_colorBytes(color)
            if alpha == 0 { return }
            let x0 = max(0, Int((rect.minX - crop.minX).rounded(.down)))
            let y0 = max(0, Int((rect.minY - crop.minY).rounded(.down)))
            let x1 = min(width, Int((rect.maxX - crop.minX).rounded(.up)))
            let y1 = min(height, Int((rect.maxY - crop.minY).rounded(.up)))
            if x0 >= x1 || y0 >= y1 { return }
            for y in y0..<y1 {
                for x in x0..<x1 {
                    let index = ((height - 1 - y) * width + x) * 4
                    pixels[index] = red
                    pixels[index + 1] = green
                    pixels[index + 2] = blue
                    pixels[index + 3] = alpha
                }
            }
        }
        func walk(_ current: SKNode) {
            if current.isHidden { return }
            let corners = sk_rectCorners(current.frame)
            let converted = corners.map { corner -> CGPoint in
                guard let parent = current.parent else { return corner }
                let world = parent._localToWorld(corner)
                return space._worldToLocal(world)
            }
            let xs = converted.map(\.x)
            let ys = converted.map(\.y)
            if let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() {
                let box = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                if let sprite = current as? SKSpriteNode {
                    fill(box, color: sprite.color)
                } else if let shape = current as? SKShapeNode {
                    fill(box, color: shape.fillColor)
                }
            }
            let children = ignoresSiblingOrder(current)
            for child in children {
                walk(child)
            }
        }
        walk(node)
        return SKTexture(data: Data(pixels), size: CGSize(width: CGFloat(width), height: CGFloat(height)))
    }

    private static func ignoresSiblingOrder(_ node: SKNode) -> [SKNode] {
        node.children.sorted { $0.zPosition < $1.zPosition }
    }
}

open class SKTransition: NSObject {
    public var pausesIncomingScene: Bool = true
    public var pausesOutgoingScene: Bool = true
    var duration: TimeInterval = 0
    var direction: SKTransitionDirection = .up
    var kind: String = "fade"

    public class func fade(withDuration sec: TimeInterval) -> SKTransition {
        let t = SKTransition(); t.duration = sec; t.kind = "fade"; return t
    }
    public class func fade(with color: SKColor, duration sec: TimeInterval) -> SKTransition {
        _ = color
        return fade(withDuration: sec)
    }
    public class func crossFade(withDuration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "crossFade"; return t
    }
    public class func doorway(withDuration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "doorway"; return t
    }
    public class func doorsOpenHorizontal(withDuration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "doorsOpenH"; return t
    }
    public class func doorsOpenVertical(withDuration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "doorsOpenV"; return t
    }
    public class func doorsCloseHorizontal(withDuration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "doorsCloseH"; return t
    }
    public class func doorsCloseVertical(withDuration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "doorsCloseV"; return t
    }
    public class func flipHorizontal(withDuration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "flipH"; return t
    }
    public class func flipVertical(withDuration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "flipV"; return t
    }
    public class func moveIn(with direction: SKTransitionDirection, duration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "moveIn"; t.direction = direction; return t
    }
    public class func push(with direction: SKTransitionDirection, duration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "push"; t.direction = direction; return t
    }
    public class func reveal(with direction: SKTransitionDirection, duration sec: TimeInterval) -> SKTransition {
        let t = fade(withDuration: sec); t.kind = "reveal"; t.direction = direction; return t
    }
}

open class SKCameraNode: SKNode {
    public func contains(_ node: SKNode) -> Bool {
        containedNodeSet().contains(node)
    }

    public func containedNodeSet() -> Set<SKNode> {
        guard let scene else { return [] }
        let halfWidth = scene.size.width / (2 * max(abs(xScale), 0.0001))
        let halfHeight = scene.size.height / (2 * max(abs(yScale), 0.0001))
        let worldCamera = parent.map { $0._localToWorld(position) } ?? position
        let visible = CGRect(
            x: worldCamera.x - halfWidth,
            y: worldCamera.y - halfHeight,
            width: halfWidth * 2,
            height: halfHeight * 2
        )
        var set: Set<SKNode> = []
        func worldFrame(_ node: SKNode) -> CGRect {
            let world = sk_rectCorners(node.frame).map { corner -> CGPoint in
                if let parent = node.parent { return parent._localToWorld(corner) }
                return corner
            }
            let xs = world.map(\.x)
            let ys = world.map(\.y)
            return CGRect(
                x: xs.min() ?? 0,
                y: ys.min() ?? 0,
                width: (xs.max() ?? 0) - (xs.min() ?? 0),
                height: (ys.max() ?? 0) - (ys.min() ?? 0)
            )
        }
        func walk(_ node: SKNode) {
            if node !== scene, node.isHidden { return }
            if visible.intersects(worldFrame(node)) {
                set.insert(node)
            }
            for child in node.children { walk(child) }
        }
        walk(scene)
        return set
    }
}
