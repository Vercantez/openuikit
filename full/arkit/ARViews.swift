import Foundation

/// SceneKit/SpriteKit renderer stand-ins. Linux has no UIKit view hierarchy
/// or GPU scene graph; these types compile as `NSObject` and never produce
/// camera imagery.
open class ARSCNFaceGeometry: SCNGeometry {
    public override init() {
        super.init()
    }

    public convenience init?(device: any MTLDevice) {
        _ = device
        return nil
    }

    public convenience init?(device: any MTLDevice, fillMesh: Bool) {
        _ = (device, fillMesh)
        return nil
    }

    public func update(from faceGeometry: ARFaceGeometry) {
        _ = faceGeometry
    }
}

open class ARSCNPlaneGeometry: SCNGeometry {
    public convenience init?(device: any MTLDevice) {
        _ = device
        return nil
    }

    public func update(from planeGeometry: ARPlaneGeometry) {
        _ = planeGeometry
    }
}

public protocol ARSCNViewDelegate: ARSessionObserver, SCNSceneRendererDelegate {
    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    func renderer(_ renderer: any SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor)
    func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
    func renderer(_ renderer: any SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode?
    func renderer(_ renderer: any SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor)
}

public extension ARSCNViewDelegate {
    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        _ = (renderer, node, anchor)
    }

    func renderer(_ renderer: any SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        _ = (renderer, node, anchor)
    }

    func renderer(_ renderer: any SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        _ = (renderer, node, anchor)
    }

    func renderer(_ renderer: any SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        _ = (renderer, anchor)
        return nil
    }

    func renderer(_ renderer: any SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        _ = (renderer, node, anchor)
    }
}

open class ARSCNView: NSObject, ARSessionProviding {
    public var automaticallyUpdatesLighting: Bool = true
    public weak var delegate: (any ARSCNViewDelegate)?
    public var rendersCameraGrain: Bool = false
    public var rendersMotionBlur: Bool = false
    public var scene: SCNScene = SCNScene()
    public var session: ARSession = ARSession()

    public override init() {
        super.init()
    }

    public func anchor(for node: SCNNode) -> ARAnchor? {
        _ = node
        return nil
    }

    public func node(for anchor: ARAnchor) -> SCNNode? {
        _ = anchor
        return nil
    }

    public func hitTest(_ point: CGPoint, types: ARHitTestResult.ResultType) -> [ARHitTestResult] {
        session.currentFrame?.hitTest(point, types: types) ?? []
    }

    public func raycastQuery(
        from point: CGPoint,
        allowing target: ARRaycastQuery.Target,
        alignment: ARRaycastQuery.TargetAlignment
    ) -> ARRaycastQuery? {
        session.currentFrame?.raycastQuery(from: point, allowing: target, alignment: alignment)
    }

    public func unprojectPoint(_ point: CGPoint, ontoPlane planeTransform: simd_float4x4) -> simd_float3? {
        session.currentFrame?.camera.unprojectPoint(
            point,
            ontoPlane: planeTransform,
            orientation: .landscapeRight,
            viewportSize: session.currentFrame?.camera.imageResolution ?? .zero
        )
    }
}

public protocol ARSKViewDelegate: ARSessionObserver, SKViewDelegate {
    func view(_ view: ARSKView, didAdd node: SKNode, for anchor: ARAnchor)
    func view(_ view: ARSKView, didRemove node: SKNode, for anchor: ARAnchor)
    func view(_ view: ARSKView, didUpdate node: SKNode, for anchor: ARAnchor)
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode?
    func view(_ view: ARSKView, willUpdate node: SKNode, for anchor: ARAnchor)
}

public extension ARSKViewDelegate {
    func view(_ view: ARSKView, didAdd node: SKNode, for anchor: ARAnchor) {
        _ = (view, node, anchor)
    }

    func view(_ view: ARSKView, didRemove node: SKNode, for anchor: ARAnchor) {
        _ = (view, node, anchor)
    }

    func view(_ view: ARSKView, didUpdate node: SKNode, for anchor: ARAnchor) {
        _ = (view, node, anchor)
    }

    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        _ = (view, anchor)
        return nil
    }

    func view(_ view: ARSKView, willUpdate node: SKNode, for anchor: ARAnchor) {
        _ = (view, node, anchor)
    }
}

open class ARSKView: NSObject, ARSessionProviding {
    public weak var delegate: (any ARSKViewDelegate)?
    public var session: ARSession = ARSession()

    public override init() {
        super.init()
    }

    public func anchor(for node: SKNode) -> ARAnchor? {
        _ = node
        return nil
    }

    public func node(for anchor: ARAnchor) -> SKNode? {
        _ = anchor
        return nil
    }

    public func hitTest(_ point: CGPoint, types: ARHitTestResult.ResultType) -> [ARHitTestResult] {
        session.currentFrame?.hitTest(point, types: types) ?? []
    }
}
