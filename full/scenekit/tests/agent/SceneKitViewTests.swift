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

func testCameraControllerOrbitAndDolly() {
    let scene = SCNScene()
    let cam = SCNNode()
    cam.camera = SCNCamera()
    cam.camera?.fieldOfView = 60
    cam.position = SCNVector3(0, 0, 10)
    scene.rootNode.addChildNode(cam)
    let box = SCNNode(geometry: SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0))
    scene.rootNode.addChildNode(box)
    let controller = SCNCameraController()
    controller.pointOfView = cam
    controller.target = SCNVector3Zero
    controller.worldUp = SCNNode.localUp
    controller.inertiaEnabled = true
    controller.inertiaFriction = 0.1
    controller.minimumVerticalAngle = -80
    controller.maximumVerticalAngle = 80
    controller.minimumHorizontalAngle = -3
    controller.maximumHorizontalAngle = 3
    precondition(controller.inertiaEnabled)
    precondition(abs(Float(controller.inertiaFriction) - 0.1) < 1e-4)
    controller.beginInteraction(CGPoint.zero, withViewport: CGSize(width: 64, height: 64))
    precondition(controller.isInertiaRunning)
    controller.stopInertia()
    precondition(!controller.isInertiaRunning)
    let before = cam.worldPosition.z
    controller.dollyToTarget(2)
    precondition(cam.worldPosition.z < before)
    controller.dolly(toTarget: -1)
    controller.dolly(by: 0.5, onScreenPoint: CGPoint(x: 32, y: 32), viewport: CGSize(width: 64, height: 64))
    controller.rollAroundTarget(0.1)
    controller.roll(by: 0.05, aroundScreenPoint: CGPoint.zero, viewport: CGSize(width: 64, height: 64))
    controller.clearRoll()
    controller.frameNodes([box])
    let dist = (
        cam.worldPosition.x * cam.worldPosition.x +
        cam.worldPosition.y * cam.worldPosition.y +
        cam.worldPosition.z * cam.worldPosition.z
    ).squareRoot()
    precondition(dist > 0.5)
    final class InertiaProbe: NSObject, SCNCameraControllerDelegate {
        var ended = false
        var started = false
        func cameraInertiaDidEnd(for cameraController: SCNCameraController) {
            ended = true
            _ = cameraController
        }
        func cameraInertiaWillStart(for cameraController: SCNCameraController) {
            started = true
            _ = cameraController
        }
    }
    let probe = InertiaProbe()
    controller.delegate = probe
    probe.cameraInertiaWillStart(for: controller)
    probe.cameraInertiaDidEnd(for: controller)
    precondition(probe.started && probe.ended)
}
