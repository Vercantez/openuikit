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
    floor.reflectionCategoryBitMask = 2
    precondition(floor.reflectionCategoryBitMask == 2)
    _ = floor.reflectionFalloffStart
}

func testTechniqueProgramSkinnerAndCoding() {
    let technique = SCNTechnique(dictionary: ["pass": "none"])
    technique?["pass"] = "blit"
    technique?.setObject("x", forKeyedSubscript: "key" as NSString)
    precondition(technique?.dictionaryRepresentation["pass"] != nil)
    let program = SCNProgram()
    program.setSemantic(SCNModelViewTransform, forSymbol: "uMVP", options: nil)
    precondition(program.semantic(forSymbol: "uMVP") == SCNModelViewTransform)
    let weights = SCNGeometrySource(vertices: [SCNVector3Zero])
    let indices = SCNGeometrySource(vertices: [SCNVector3Zero])
    let skinner = SCNSkinner(
        baseGeometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0),
        bones: [SCNNode()],
        boneInverseBindTransforms: nil,
        boneWeights: weights,
        boneIndices: indices
    )
    skinner.baseGeometryBindTransform = SCNMatrix4MakeTranslation(1, 0, 0)
    precondition(skinner.boneWeights != nil)
    precondition(skinner.boneIndices != nil)
    final class StreamProbe: NSObject, SCNBufferStream {
        var wrote = 0
        func writeBytes(_ bytes: UnsafeRawPointer, count: Int) {
            wrote += count
            _ = bytes
        }
    }
    let stream = StreamProbe()
    var value: UInt8 = 7
    stream.writeBytes(&value, count: 1)
    precondition(stream.wrote == 1)
    if let data = try? NSKeyedArchiver.archivedData(withRootObject: "x", requiringSecureCoding: false),
       let coder = try? NSKeyedUnarchiver(forReadingFrom: data) {
        precondition(SCNParticleSystem(coder: coder) == nil)
        precondition(SCNPhysicsField(coder: coder) == nil)
        precondition(SCNPhysicsVehicleWheel(coder: coder) == nil)
        precondition(SCNConstraint(coder: coder) == nil)
        precondition(SCNTimingFunction(coder: coder) == nil)
        precondition(SCNMorpher(coder: coder) == nil)
        precondition(SCNAnimation(coder: coder) == nil)
        precondition(SCNAnimationPlayer(coder: coder) == nil)
        precondition(SCNAudioSource(coder: coder) == nil)
        precondition(SCNCamera(coder: coder) == nil)
        precondition(SCNGeometry(coder: coder) == nil)
        precondition(SCNGeometryElement(coder: coder) == nil)
        precondition(SCNGeometrySource(coder: coder) == nil)
        precondition(SCNGeometryTessellator(coder: coder) == nil)
        precondition(SCNLevelOfDetail(coder: coder) == nil)
        precondition(SCNLight(coder: coder) == nil)
        precondition(SCNMaterial(coder: coder) == nil)
        precondition(SCNMaterialProperty(coder: coder) == nil)
        precondition(SCNParticlePropertyController(coder: coder) == nil)
        precondition(SCNPhysicsBehavior(coder: coder) == nil)
        precondition(SCNPhysicsShape(coder: coder) == nil)
        precondition(SCNProgram(coder: coder) == nil)
        precondition(SCNScene(coder: coder) == nil)
        precondition(SCNSkinner(coder: coder) == nil)
        precondition(SCNTechnique(coder: coder) == nil)
    }
    let ref = SCNReferenceNode(url: URL(fileURLWithPath: "/tmp/missing.scn"))
    ref?.loadingPolicy = .onDemand
    ref?.load()
    precondition(ref?.isLoaded == false)
    _ = ref?.referenceURL
}
