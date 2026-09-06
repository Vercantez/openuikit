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

func testSceneNamedFailClosedAndFog() {
    precondition(SCNScene(named: "missing.scn") == nil)
    precondition(SCNScene(named: "missing.scn", inDirectory: "Scenes", options: nil) == nil)
    do {
        _ = try SCNScene(url: URL(fileURLWithPath: "/tmp/missing-scenekit.scn"), options: nil)
        precondition(false, "URL load must fail-close")
    } catch {
        _ = error
    }
    let scene = SCNScene()
    scene.fogColor = SCNVector4(0.2, 0.2, 0.3, 1)
    scene.screenSpaceReflectionMaximumDistance = 40
    scene.screenSpaceReflectionSampleCount = 8
    scene.screenSpaceReflectionStride = 2
    precondition(scene.screenSpaceReflectionSampleCount == 8)
    let policy = SCNSceneSource.AnimationImportPolicy.doNotPlay
    precondition(policy != .playRepeatedly)
    _ = SCNSceneSource.AnimationImportPolicy.playUsingSceneTimeBase
    _ = SCNSceneSource.AnimationImportPolicy.self
    _ = SCNSceneSource.AnimationImportPolicy.playRepeatedly.hashValue
    var hasher = Hasher()
    SCNSceneSource.AnimationImportPolicy.doNotPlay.hash(into: &hasher)
    let _: SCNSceneExportProgressHandler = { _, _, _ in }
    let _: SCNSceneSourceStatusHandler = { _, _, _, _ in }
    let src = SCNSceneSource(data: Data(), options: nil)
    precondition((try? src?.scene(options: [.flattenScene: true])) == nil)
}
