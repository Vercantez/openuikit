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

func testSceneSourceMetadata() {
    let tmp = URL(fileURLWithPath: "/tmp/scenekit-linux-meta-\(ProcessInfo.processInfo.processIdentifier).scn")
    try? Data([0x00]).write(to: tmp)
    let src = SCNSceneSource(url: tmp, options: nil)
    precondition(src != nil)
    _ = src?.property(forKey: SCNSceneSourceAssetAuthorKey)
    _ = src?.property(forKey: SCNSceneSourceAssetCreatedDateKey)
    precondition((try? src?.scene(options: nil)) == nil)
    precondition(src?.identifiersOfEntries(withClass: SCNNode.self).isEmpty == true)
    precondition(src?.entryWithIdentifier("x", withClass: SCNNode.self) == nil)
    precondition(src?.entries(passingTest: { _, _, _ in true }).isEmpty == true)
    let empty = SCNSceneSource(data: Data(), options: [.checkConsistency: true])
    var sawError = false
    _ = empty?.scene(options: nil, statusHandler: { _, status, _, _ in
        if status == .error { sawError = true }
    })
    precondition(sawError)
    try? FileManager.default.removeItem(at: tmp)
}
