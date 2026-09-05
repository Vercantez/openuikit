import Foundation
import SceneKit

func testSceneGraphAndLoad() {
    let scene = SCNScene()
    _ = scene.rootNode
    _ = scene.background
    _ = scene.lightingEnvironment
    _ = scene.physicsWorld
    scene.isPaused = false
    scene.fogStartDistance = 0
    scene.fogEndDistance = 0
    scene.fogDensityExponent = 0
    scene.wantsScreenSpaceReflection = false
    scene.setAttribute("y", forKey: SCNScene.Attribute.upAxis.rawValue)
    _ = scene.attribute(forKey: SCNScene.Attribute.upAxis.rawValue)
    precondition(SCNScene(named: "missing") == nil)
    precondition(scene.write(to: URL(fileURLWithPath: "/tmp/scenekit-linux-export.scn"), options: nil, delegate: nil, progressHandler: nil) == false)
    let src = SCNSceneSource(data: Data(), options: nil)
    precondition((try? src?.scene(options: nil)) == nil)
    _ = src?.url
    _ = src?.data
    _ = SCNSceneSource.LoadingOption.flattenScene
    let ref = SCNReferenceNode(url: URL(fileURLWithPath: "/tmp/missing.scn"))
    ref?.load()
    precondition(ref?.isLoaded == false)
    ref?.unload()
    let audio = SCNAudioSource()
    audio.load()
    precondition(audio.volume == 1)
    precondition(SCNAudioSource(named: "missing.wav") != nil)
    let technique = SCNTechnique(dictionary: ["pass": "none"])
    precondition(technique != nil)
    let program = SCNProgram()
    program.vertexFunctionName = "v"
    precondition(program.isOpaque)
}
