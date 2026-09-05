import Foundation
import SceneKit

func testProtocolAndTypealiasSurface() {
    _ = SCNActionable.self
    _ = SCNAnimatable.self
    _ = SCNAnimationProtocol.self
    _ = SCNBoundingVolume.self
    _ = SCNBufferStream.self
    _ = SCNShadable.self
    _ = SCNTechniqueSupport.self
    _ = SCNSceneRenderer.self
    _ = SCNSceneRendererDelegate.self
    _ = SCNCameraControlConfiguration.self
    _ = SCNCameraControllerDelegate.self
    _ = SCNNodeRendererDelegate.self
    _ = SCNAvoidOccluderConstraintDelegate.self
    _ = SCNPhysicsContactDelegate.self
    _ = SCNSceneExportDelegate.self
    _ = SCNProgramDelegate.self
    let _: SCNActionTimingFunction = { $0 }
    let _: SCNAnimationDidStartBlock = { _, _ in }
    let _: SCNAnimationDidStopBlock = { _, _, _ in }
    let _: SCNAnimationEventBlock = { _, _, _ in }
    let _: SCNBindingBlock = { _, _, _, _ in }
    let _: SCNBufferBindingBlock = { _, _, _, _ in }
    let _: SCNFieldForceEvaluator = { _, _, _, _, _ in SCNVector3Zero }
    _ = SCNQuaternion.self
    _ = SCNFloat.self
}

func testSkinnerAndProgramAndFloorExtras() {
    let skinner = SCNSkinner()
    _ = skinner.skeleton
    _ = skinner.baseGeometry
    _ = skinner.bones
    let program = SCNProgram()
    program.fragmentFunctionName = "f"
    program.vertexShader = nil
    program.fragmentShader = nil
    program.isOpaque = true
    program.handleBinding(ofBufferNamed: "b", frequency: .perFrame, handler: { _, _, _, _ in })
    let floor = SCNFloor()
    floor.length = 10
    floor.width = 10
    floor.reflectionResolutionScaleFactor = 1
    _ = floor.reflectionFalloffStart
}
