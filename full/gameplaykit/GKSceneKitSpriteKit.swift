#if canImport(SpriteKit)
import SpriteKit
#endif
#if canImport(SceneKit)
import SceneKit
#endif
import Foundation

enum _GameplayKitOverlayAvailability {
    static var spriteKit: Bool {
        #if canImport(SpriteKit)
        true
        #else
        false
        #endif
    }

    static var sceneKit: Bool {
        #if canImport(SceneKit)
        true
        #else
        false
        #endif
    }
}

#if canImport(SpriteKit) || canImport(SceneKit)
private final class _GKWeakEntityBox {
    weak var value: GKEntity?
    init(_ value: GKEntity?) { self.value = value }
}

private var _gkNodeEntities: [ObjectIdentifier: _GKWeakEntityBox] = [:]
#endif

#if canImport(SpriteKit)
open class GKSKNodeComponent: GKComponent {
    public var node: SKNode

    public init(node: SKNode) {
        self.node = node
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.node = SKNode()
        super.init()
        return nil
    }
}

extension SKNode {
    public weak var entity: GKEntity? {
        get { _gkNodeEntities[ObjectIdentifier(self)]?.value }
        set { _gkNodeEntities[ObjectIdentifier(self)] = _GKWeakEntityBox(newValue) }
    }

    @MainActor
    open class func obstacles(fromNodeBounds nodes: [SKNode]) -> [GKPolygonObstacle] {
        nodes.map { node in
            let frame = node.frame
            return GKPolygonObstacle(points: [
                SIMD2<Float>(Float(frame.minX), Float(frame.minY)),
                SIMD2<Float>(Float(frame.maxX), Float(frame.minY)),
                SIMD2<Float>(Float(frame.maxX), Float(frame.maxY)),
                SIMD2<Float>(Float(frame.minX), Float(frame.maxY))
            ])
        }
    }

    @MainActor
    open class func obstacles(fromNodePhysicsBodies nodes: [SKNode]) -> [GKPolygonObstacle] {
        obstacles(fromNodeBounds: nodes)
    }

    @MainActor
    open class func obstacles(fromSpriteTextures sprites: [SKNode], accuracy: Float) -> [GKPolygonObstacle] {
        _ = accuracy
        return obstacles(fromNodeBounds: sprites)
    }
}
#endif

#if canImport(SceneKit)
open class GKSCNNodeComponent: GKComponent {
    public let node: SCNNode

    public init(node: SCNNode) {
        self.node = node
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.node = SCNNode()
        super.init()
        return nil
    }
}

extension SCNNode {
    public weak var entity: GKEntity? {
        get { _gkNodeEntities[ObjectIdentifier(self)]?.value }
        set { _gkNodeEntities[ObjectIdentifier(self)] = _GKWeakEntityBox(newValue) }
    }
}
#endif
