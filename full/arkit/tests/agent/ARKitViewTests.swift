import Foundation
import ARKit

func testSCNViewStandIn() {
    let session = ARSession()
    let view = ARSCNView()
    view.session = session
    view.automaticallyUpdatesLighting = false
    view.rendersCameraGrain = true
    view.rendersMotionBlur = true
    _ = view.scene
    _ = view.delegate
    arkitRequire(view.anchor(for: SCNNode()) == nil, "node map")
    arkitRequire(view.node(for: ARAnchor(transform: .identity)) == nil, "anchor map")
    _ = view.hitTest(.zero, types: .featurePoint)
    _ = view.raycastQuery(from: CGPoint(x: 0.5, y: 0.5), allowing: .estimatedPlane, alignment: .horizontal)
    _ = view.unprojectPoint(.zero, ontoPlane: .identity)
    arkitRequire(ARSCNFaceGeometry(device: ARKitHostMTLDevice()) == nil, "face geo")
    arkitRequire(ARSCNFaceGeometry(device: ARKitHostMTLDevice(), fillMesh: true) == nil, "fill mesh")
    ARSCNFaceGeometry().update(from: ARFaceGeometry())
    arkitRequire(ARSCNPlaneGeometry(device: ARKitHostMTLDevice()) == nil, "plane geo")
    ARSCNPlaneGeometry().update(from: ARPlaneGeometry())
}

func testSKViewStandIn() {
    let view = ARSKView()
    view.session = ARSession()
    arkitRequire(view.anchor(for: SKNode()) == nil, "sprite node")
    arkitRequire(view.node(for: ARAnchor(transform: .identity)) == nil, "sprite anchor")
    _ = view.hitTest(.zero, types: .existingPlane)
    _ = view.delegate
}

func testCoachingOverlayStandIn() {
    let session = ARSession()
    let coaching = ARCoachingOverlayView()
    coaching.goal = .horizontalPlane
    coaching.session = session
    coaching.activatesAutomatically = false
    coaching.setActive(true, animated: false)
    arkitRequire(!coaching.isActive, "stays inactive")
    arkitRequire(coaching.goal == .horizontalPlane, "goal stored")
    let scn = ARSCNView()
    coaching.sessionProvider = scn
    arkitRequire(coaching.sessionProvider?.session === scn.session || coaching.sessionProvider != nil, "provider")
    _ = coaching.delegate
}

func testViewDelegateDefaults() {
    let renderer = DummySceneRenderer()
    let node = SCNNode()
    let anchor = ARAnchor(transform: .identity)
    let scn = EmptySCNViewDelegate()
    scn.renderer(renderer, didAdd: node, for: anchor)
    scn.renderer(renderer, didRemove: node, for: anchor)
    scn.renderer(renderer, didUpdate: node, for: anchor)
    arkitRequire(scn.renderer(renderer, nodeFor: anchor) == nil, "nodeFor")
    scn.renderer(renderer, willUpdate: node, for: anchor)

    let sk = EmptySKViewDelegate()
    let view = ARSKView()
    let sprite = SKNode()
    sk.view(view, didAdd: sprite, for: anchor)
    sk.view(view, didRemove: sprite, for: anchor)
    sk.view(view, didUpdate: sprite, for: anchor)
    arkitRequire(sk.view(view, nodeFor: anchor) == nil, "sprite nodeFor")
    sk.view(view, willUpdate: sprite, for: anchor)

    let coaching = EmptyCoachingDelegate()
    let overlay = ARCoachingOverlayView()
    coaching.coachingOverlayViewWillActivate(overlay)
    coaching.coachingOverlayViewDidDeactivate(overlay)
    coaching.coachingOverlayViewDidRequestSessionReset(overlay)
}
