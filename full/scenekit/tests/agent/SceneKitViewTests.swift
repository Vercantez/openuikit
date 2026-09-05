import Foundation
import SceneKit

func testSCNViewStores() {
    let view = SCNView(frame: CGRect(x: 0, y: 0, width: 64, height: 64), options: [
        SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal
    ])
    let scene = SCNScene()
    view.scene = scene
    view.allowsCameraControl = true
    let cam = SCNNode()
    cam.camera = SCNCamera()
    scene.rootNode.addChildNode(cam)
    view.pointOfView = cam
    precondition(view.allowsCameraControl)
    precondition(view.pointOfView === cam)
    precondition(view.scene === scene)
    view.play(nil)
    precondition(view.isPlaying)
    view.pause(nil)
    precondition(!view.isPlaying)
    view.stop(nil)
    let snap = view.linux_snapshot()
    precondition(snap.width == 64)
    _ = view.defaultCameraController
    _ = view.cameraControlConfiguration.allowsTranslation
    _ = view.antialiasingMode
    _ = view.preferredFramesPerSecond
    _ = view.rendersContinuously
    _ = view.projectPoint(SCNVector3Zero)
    _ = view.unprojectPoint(SCNVector3Zero)
    _ = view.hitTest(CGPoint.zero, options: nil)
    _ = SCNView.Option.preferLowPowerDevice.rawValue
    let cfg = view.cameraControlConfiguration
    _ = cfg.autoSwitchToFreeCamera
    _ = cfg.flyModeVelocity
    _ = cfg.panSensitivity
    _ = cfg.rotationSensitivity
    _ = cfg.truckSensitivity
    let controller = SCNCameraController()
    controller.interactionMode = .orbitArcball
    controller.automaticTarget = true
    controller.translateInCameraSpaceBy(x: 0, y: 0, z: 0)
    controller.rotateBy(x: 0, y: 0)
    controller.rollBy(0)
    controller.dollyBy(0)
    controller.beginInteraction(CGPoint.zero, withViewport: CGSize(width: 1, height: 1))
    controller.continueInteraction(CGPoint.zero, withViewport: CGSize(width: 1, height: 1), sensitivity: 1)
    controller.endInteraction(CGPoint.zero, withViewport: CGSize(width: 1, height: 1), velocity: CGPoint.zero)
    precondition(controller.automaticTarget)
}
