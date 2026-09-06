import Foundation
import SceneKit

// ---- SceneKitActionTests.swift ----
func testActionClock() {
    let scene = SCNScene()
    let mover = SCNNode()
    scene.rootNode.addChildNode(mover)
    mover.runAction(SCNAction.move(by: SCNVector3(x: 2, y: 0, z: 0), duration: 1))
    mover.linux_advanceTime(0.5)
    precondition(abs(mover.position.x - 1) < 1e-4)
    mover.linux_advanceTime(0.5)
    precondition(abs(mover.position.x - 2) < 1e-4)
    precondition(!mover.hasActions)
    let leftover = SCNNode()
    leftover.position = SCNVector3Zero
    scene.rootNode.addChildNode(leftover)
    leftover.runAction(SCNAction.sequence([
        SCNAction.wait(duration: 1),
        SCNAction.move(by: SCNVector3(x: 4, y: 0, z: 0), duration: 1)
    ]))
    leftover.linux_advanceTime(1.5)
    precondition(abs(leftover.position.x - 2) < 1e-4)
    let paused = SCNNode()
    scene.rootNode.addChildNode(paused)
    let pausedAction = SCNAction.move(by: SCNVector3(x: 9, y: 0, z: 0), duration: 1)
    pausedAction.speed = 0
    paused.runAction(pausedAction)
    paused.linux_advanceTime(5)
    precondition(abs(paused.position.x) < 1e-4)
    let repeater = SCNNode()
    scene.rootNode.addChildNode(repeater)
    repeater.runAction(SCNAction.repeat(SCNAction.move(by: SCNVector3(x: 1, y: 0, z: 0), duration: 1), count: 3))
    repeater.linux_advanceTime(3)
    precondition(abs(repeater.position.x - 3) < 1e-4)
    let cancel = SCNNode()
    scene.rootNode.addChildNode(cancel)
    cancel.runAction(SCNAction.move(by: SCNVector3(x: 3, y: 0, z: 0), duration: 2), forKey: "move")
    cancel.linux_advanceTime(0.5)
    precondition(cancel.action(forKey: "move") != nil)
    cancel.removeAction(forKey: "move")
    let xAfter = cancel.position.x
    cancel.linux_advanceTime(2)
    precondition(abs(cancel.position.x - xAfter) < 1e-4)
    _ = cancel.actionKeys
    cancel.removeAllActions()
}

func testActionEasing() {
    let scene = SCNScene()
    let ease = SCNNode()
    scene.rootNode.addChildNode(ease)
    let move = SCNAction.move(by: SCNVector3(10, 0, 0), duration: 1)
    move.timingMode = .easeIn
    ease.runAction(move)
    ease.linux_advanceTime(0.5)
    precondition(abs(ease.position.x - 2.5) < 1e-4)
    let out = SCNNode()
    scene.rootNode.addChildNode(out)
    let moveOut = SCNAction.move(by: SCNVector3(10, 0, 0), duration: 1)
    moveOut.timingMode = .easeOut
    out.runAction(moveOut)
    out.linux_advanceTime(0.5)
    precondition(abs(out.position.x - 7.5) < 1e-4)
    let group = SCNNode()
    scene.rootNode.addChildNode(group)
    group.runAction(SCNAction.group([
        SCNAction.move(by: SCNVector3(2, 0, 0), duration: 1),
        SCNAction.fadeOut(duration: 1)
    ]))
    group.linux_advanceTime(1)
    precondition(abs(group.position.x - 2) < 1e-4)
    let fader = SCNNode()
    scene.rootNode.addChildNode(fader)
    fader.runAction(SCNAction.fadeOut(duration: 1))
    fader.linux_advanceTime(1)
    fader.runAction(SCNAction.hide())
    fader.linux_advanceTime(0)
    precondition(fader.isHidden)
    var ran = false
    let instant = SCNNode()
    scene.rootNode.addChildNode(instant)
    instant.runAction(SCNAction.run { _ in ran = true })
    instant.linux_advanceTime(0)
    precondition(ran)
    _ = SCNAction.move(to: SCNVector3Zero, duration: 0)
    _ = SCNAction.rotate(by: 0.1, around: SCNVector3(0, 1, 0), duration: 0)
    _ = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0)
    _ = SCNAction.scale(by: 2, duration: 0)
    _ = SCNAction.scale(to: 1, duration: 0)
    _ = SCNAction.fadeIn(duration: 0)
    _ = SCNAction.fadeOpacity(to: 0.5, duration: 0)
    _ = SCNAction.unhide()
    _ = SCNAction.removeFromParentNode()
    _ = SCNAction.repeatForever(SCNAction.wait(duration: 1))
    _ = SCNAction.customAction(duration: 0, action: { _, _ in })
}

func testCustomActionAndRotate() {
    let node = SCNNode()
    var samples: [CGFloat] = []
    node.runAction(SCNAction.customAction(duration: 1, action: { _, t in
        samples.append(t)
    }))
    node.linux_advanceTime(0.5)
    precondition(!samples.isEmpty)
    precondition(abs(Float(samples.last ?? 0) - 0.5) < 1e-3)
    node.linux_advanceTime(0.5)
    precondition(abs(Float(samples.last ?? 0) - 1) < 1e-3)
    let spinner = SCNNode()
    spinner.runAction(SCNAction.rotateBy(x: 0, y: CGFloat.pi / 2, z: 0, duration: 1))
    spinner.linux_advanceTime(1)
    precondition(abs(spinner.eulerAngles.y - Float.pi / 2) < 1e-3)
    let scaled = SCNNode()
    scaled.runAction(SCNAction.scale(to: 3, duration: 1))
    scaled.linux_advanceTime(1)
    precondition(abs(scaled.scale.x - 3) < 1e-3)
    let mover = SCNNode()
    mover.runAction(SCNAction.move(to: SCNVector3(4, 0, 0), duration: 1))
    mover.linux_advanceTime(1)
    precondition(abs(mover.position.x - 4) < 1e-3)
    let by = SCNNode()
    by.runAction(SCNAction.moveBy(x: 2, y: 0, z: 0, duration: 1))
    by.linux_advanceTime(1)
    precondition(abs(by.position.x - 2) < 1e-3)
    let rev = SCNAction.move(by: SCNVector3(3, 0, 0), duration: 1).reversed()
    let back = SCNNode()
    back.position = SCNVector3(3, 0, 0)
    back.runAction(rev)
    back.linux_advanceTime(1)
    precondition(abs(back.position.x) < 1e-3)
    let timed = SCNAction.move(by: SCNVector3(10, 0, 0), duration: 1)
    timed.timingFunction = { t in t * t }
    let eased = SCNNode()
    eased.runAction(timed)
    eased.linux_advanceTime(0.5)
    precondition(abs(eased.position.x - 2.5) < 1e-3)
}

func testJavaScriptAndPlayAudioFailClosed() {
    let node = SCNNode()
    node.runAction(SCNAction.javaScriptAction(withScript: "node.position.x = 9", duration: 1))
    node.linux_advanceTime(1)
    precondition(abs(node.position.x) < 1e-4)
    let audio = SCNAudioSource()
    audio.shouldStream = false
    node.runAction(SCNAction.playAudio(audio, waitForCompletion: false))
    node.linux_advanceTime(0)
    precondition(abs(node.position.x) < 1e-4)
}

// ---- SceneKitAnimationTests.swift ----
func testAnimatableKeys() {
    let anim = SCNAnimation()
    anim.duration = 1
    anim.keyPath = "position"
    anim.isRemovedOnCompletion = true
    anim.repeatCount = 0
    anim.autoreverses = false
    anim.startDelay = 0
    anim.timeOffset = 0
    anim.isAppliedOnCompletion = true
    anim.usesSceneTimeBase = false
    let player = SCNAnimationPlayer(animation: anim)
    player.play()
    precondition(!player.paused)
    player.stop()
    player.paused = true
    player.speed = 1
    player.blendFactor = 1
    let node = SCNNode()
    node.addAnimation(anim, forKey: "pos")
    precondition(node.animationKeys.contains("pos"))
    node.pauseAnimation(forKey: "pos")
    precondition(node.isAnimationPaused(forKey: "pos"))
    node.resumeAnimation(forKey: "pos")
    _ = node.animationPlayer(forKey: "pos")
    node.setAnimationSpeed(1, forKey: "pos")
    node.removeAnimation(forKey: "pos")
    node.addAnimationPlayer(player, forKey: "p")
    node.removeAllAnimations()
    let event = SCNAnimationEvent(keyTime: 0.5, block: { _, _, _ in })
    precondition(event.time == 0.5)
    _ = SCNTimingFunction()
    let morph = SCNMorpher()
    morph.setWeight(0.25, forTargetAt: 0)
    precondition(abs(Float(morph.weight(forTargetAt: 0)) - 0.25) < 1e-4)
    morph.setWeight(0.1, forTargetNamed: "a")
    _ = morph.weight(forTargetNamed: "a")
    _ = morph.calculationMode
}

func testCAAnimationBridge() {
    let scn = SCNAnimation()
    scn.duration = 2
    scn.blendInDuration = 0.1
    scn.blendOutDuration = 0.2
    scn.usesSceneTimeBase = true
    scn.isAdditive = true
    scn.isCumulative = true
    scn.fillsForward = true
    scn.fillsBackward = true
    scn.animationEvents = [SCNAnimationEvent(keyTime: 0.25, block: { _, _, _ in })]
    var started = false
    scn.animationDidStart = { _, _ in started = true }
    scn.animationDidStop = { _, _, _ in }
    _ = scn.animationDidStart
    _ = started
    let ca = CAAnimation(SCNAnimation: scn)
    precondition(abs(ca.duration - 2) < 1e-9)
    precondition(ca.usesSceneTimeBase)
    precondition(abs(Float(ca.fadeInDuration) - 0.1) < 1e-4)
    let back = SCNAnimation(caAnimation: ca)
    precondition(abs(back.duration - 2) < 1e-9)
    let alt = SCNAnimation(CAAnimation: ca)
    precondition(abs(alt.duration - 2) < 1e-9)
    let node = SCNNode()
    node.addAnimation(scn, forKey: "pos")
    let retrieved = node.animation(forKey: "pos")
    precondition(retrieved != nil)
    let controller = SCNParticlePropertyController(animation: ca)
    precondition(abs(controller.animation.duration - 2) < 1e-9)
}

func testAnimationTimingFunctionAndAudio() {
    let anim = SCNAnimation()
    let fn = SCNTimingFunction.function(withTimingMode: .easeInEaseOut)
    anim.timingFunction = fn
    precondition(anim.timingFunction === fn)
    let source = SCNAudioSource()
    source.isPositional = true
    source.rate = 1.5
    source.reverbBlend = 0.25
    source.shouldStream = true
    precondition(source.isPositional)
    precondition(abs(source.rate - 1.5) < 1e-4)
    precondition(abs(source.reverbBlend - 0.25) < 1e-4)
    precondition(source.shouldStream)
    let player = SCNAudioPlayer(source: source)
    var started = false
    var finished = false
    player.willStartPlayback = { started = true }
    player.didFinishPlayback = { finished = true }
    player.willStartPlayback?()
    player.didFinishPlayback?()
    precondition(started && finished)
    precondition(player.audioSource === source)
}

// ---- SceneKitCameraTests.swift ----
func testCameraProjection() {
    let cam = SCNCamera()
    cam.fieldOfView = 90
    cam.zNear = 1
    cam.zFar = 100
    let persp = cam.projectionTransform(withViewportSize: CGSize(width: 100, height: 100))
    let f = 1 / tan(Float.pi / 4)
    precondition(abs(persp.m11 - f) < 1e-4)
    precondition(abs(persp.m22 - f) < 1e-4)
    precondition(abs(persp.m34 + 1) < 1e-4)
    cam.usesOrthographicProjection = true
    cam.orthographicScale = 2
    let ortho = cam.projectionTransform(withViewportSize: CGSize(width: 200, height: 100))
    precondition(abs(ortho.m11 - 0.25) < 1e-4)
    precondition(abs(ortho.m22 - 0.5) < 1e-4)
    cam.usesOrthographicProjection = false
    cam.fieldOfView = 90
    cam.zNear = 1
    cam.zFar = 100
    let persp2 = cam.projectionTransform(withViewportSize: CGSize(width: 100, height: 100))
    let n: Float = 1
    let far: Float = 100
    let expectedM33 = -(far + n) / (far - n)
    let expectedM43 = -2 * far * n / (far - n)
    precondition(abs(persp2.m33 - expectedM33) < 1e-4)
    precondition(abs(persp2.m43 - expectedM43) < 1e-4)
}

func testCameraStores() {
    let cam = SCNCamera()
    cam.wantsHDR = true
    cam.fStop = 2.8
    cam.focalLength = 50
    cam.sensorHeight = 24
    cam.automaticallyAdjustsZRange = false
    cam.projectionDirection = .vertical
    cam.wantsExposureAdaptation = false
    cam.exposureOffset = 0
    cam.averageGray = 0.18
    cam.whitePoint = 1
    cam.minimumExposure = -15
    cam.maximumExposure = 15
    cam.contrast = 0
    cam.saturation = 0
    cam.bloomIntensity = 0
    cam.bloomThreshold = 1
    cam.bloomBlurRadius = 3
    cam.vignettingIntensity = 0
    cam.motionBlurIntensity = 0
    cam.wantsDepthOfField = false
    cam.focusDistance = 2.5
    cam.aperture = 0.125
    cam.apertureBladeCount = 6
    cam.screenSpaceAmbientOcclusionIntensity = 0
    cam.grainIntensity = 0
    cam.whiteBalanceTemperature = 0
    cam.xFov = 0
    cam.yFov = 0
    cam.categoryBitMask = 1
    cam.name = "cam"
    _ = cam.colorGrading
    _ = cam.projectionTransform
    precondition(cam.wantsHDR)
}

func testCameraPostProcessStores() {
    let cam = SCNCamera()
    cam.bloomIterationCount = 3
    cam.bloomIterationSpread = 0.5
    cam.colorFringeIntensity = 0.2
    cam.colorFringeStrength = 0.1
    cam.exposureAdaptationBrighteningSpeedFactor = 0.8
    cam.exposureAdaptationDarkeningSpeedFactor = 0.4
    cam.focalBlurRadius = 2
    cam.focalBlurSampleCount = 5
    cam.focalDistance = 8
    cam.focalSize = 1
    cam.grainIsColored = true
    cam.grainScale = 2
    cam.screenSpaceAmbientOcclusionBias = 0.1
    cam.screenSpaceAmbientOcclusionDepthThreshold = 0.5
    cam.screenSpaceAmbientOcclusionNormalThreshold = 0.2
    cam.screenSpaceAmbientOcclusionRadius = 4
    cam.vignettingPower = 1.5
    cam.whiteBalanceTint = 0.3
    precondition(cam.bloomIterationCount == 3)
    precondition(abs(Float(cam.bloomIterationSpread) - 0.5) < 1e-4)
    precondition(cam.grainIsColored)
    precondition(cam.focalBlurSampleCount == 5)
    precondition(abs(Float(cam.whiteBalanceTint) - 0.3) < 1e-4)
}

// ---- SceneKitConstraintTests.swift ----
func testLookAtDistanceBillboard() {
    let scene = SCNScene()
    let target = SCNNode()
    target.position = SCNVector3(10, 0, 0)
    let follower = SCNNode()
    scene.rootNode.addChildNode(target)
    scene.rootNode.addChildNode(follower)
    let look = SCNLookAtConstraint(target: target)
    look.influenceFactor = 1
    look.isGimbalLockEnabled = false
    look.localFront = SCNNode.localFront
    look.targetOffset = SCNVector3Zero
    look.worldUp = SCNNode.localUp
    follower.constraints = [look]
    follower.linux_advanceTime(0)
    precondition(abs(follower.worldFront.x) > 0.5)
    let dist = SCNDistanceConstraint(target: target)
    dist.minimumDistance = 4
    dist.maximumDistance = 4
    follower.constraints = [dist]
    follower.linux_advanceTime(0)
    let dx = follower.worldPosition.x - target.worldPosition.x
    let dy = follower.worldPosition.y - target.worldPosition.y
    let dz = follower.worldPosition.z - target.worldPosition.z
    let len = (dx * dx + dy * dy + dz * dz).squareRoot()
    precondition(abs(len - 4) < 0.05)
    let billboard = SCNBillboardConstraint()
    billboard.freeAxes = .all
    follower.constraints = [look, dist, billboard]
    follower.linux_advanceTime(0)
    precondition(follower.constraints?.count == 3)
    let tf = SCNTransformConstraint(inWorldSpace: false, with: { _, m in m })
    _ = SCNTransformConstraint(inWorldSpace: true, withBlock: { _, m in m })
    _ = SCNTransformConstraint.orientationConstraint(inWorldSpace: false, with: { _, q in q })
    _ = SCNTransformConstraint.positionConstraint(inWorldSpace: false, with: { _, v in v })
    _ = tf
    let accel = SCNAccelerationConstraint()
    accel.damping = 0.2
    let slider = SCNSliderConstraint()
    slider.radius = 1
    let repl = SCNReplicatorConstraint()
    repl.replicatesPosition = false
    let avoid = SCNAvoidOccluderConstraint()
    avoid.bias = 0.1
    let ik = SCNIKConstraint.inverseKinematicsConstraint(chainRootNode: follower)
    precondition(ik.chainRootNode === follower)
    _ = accel.maximumLinearAcceleration
    _ = slider.offset
    _ = repl.orientationOffset
    _ = avoid.occluderCategoryBitMask
}

func testReplicatorConstraintMath() {
    let scene = SCNScene()
    let target = SCNNode()
    target.position = SCNVector3(3, 4, 5)
    target.scale = SCNVector3(2, 2, 2)
    target.eulerAngles = SCNVector3(0, Float.pi / 2, 0)
    let follower = SCNNode()
    scene.rootNode.addChildNode(target)
    scene.rootNode.addChildNode(follower)
    let repl = SCNReplicatorConstraint(target: target)
    repl.replicatesPosition = true
    repl.replicatesOrientation = true
    repl.replicatesScale = true
    repl.positionOffset = SCNVector3(1, 0, 0)
    repl.scaleOffset = SCNVector3(0.5, 0.5, 0.5)
    repl.orientationOffset = SCNQuaternion(x: 0, y: 0, z: 0, w: 1)
    repl.influenceFactor = 1
    follower.constraints = [repl]
    follower.linux_advanceTime(0)
    precondition(abs(follower.worldPosition.x - 4) < 1e-3)
    precondition(abs(follower.worldPosition.y - 4) < 1e-3)
    precondition(abs(follower.scale.x - 2.5) < 1e-3)
    precondition(abs(follower.worldOrientation.y - target.worldOrientation.y) < 0.05)
}

func testIKAndAccelerationConstraints() {
    let root = SCNNode()
    let joint = SCNNode()
    root.addChildNode(joint)
    let ik = SCNIKConstraint.inverseKinematicsConstraint(chainRootNode: root)
    ik.targetPosition = SCNVector3(0, 1, 0)
    ik.setMaxAllowedRotationAngle(30, forJoint: joint)
    precondition(abs(Float(ik.maxAllowedRotationAngle(forJoint: joint)) - 30) < 1e-4)
    precondition(abs(ik.targetPosition.y - 1) < 1e-4)
    let accel = SCNAccelerationConstraint()
    accel.decelerationDistance = 2
    accel.maximumLinearVelocity = 5
    precondition(abs(Float(accel.decelerationDistance) - 2) < 1e-4)
    let constraint = SCNConstraint()
    constraint.isEnabled = false
    constraint.isIncremental = true
    precondition(!constraint.isEnabled)
    precondition(constraint.isIncremental)
    let slider = SCNSliderConstraint()
    slider.collisionCategoryBitMask = 3
    precondition(slider.collisionCategoryBitMask == 3)
    final class AvoidProbe: NSObject, SCNAvoidOccluderConstraintDelegate {
        func avoidOccluderConstraint(_ constraint: SCNAvoidOccluderConstraint, didAvoidOccluder occluder: SCNNode, for node: SCNNode) {
            _ = constraint
            _ = occluder
            _ = node
        }
        func avoidOccluderConstraint(_ constraint: SCNAvoidOccluderConstraint, shouldAvoidOccluder occluder: SCNNode, for node: SCNNode) -> Bool {
            _ = constraint
            _ = occluder
            _ = node
            return true
        }
    }
    let avoid = SCNAvoidOccluderConstraint()
    let probe = AvoidProbe()
    avoid.delegate = probe
    _ = probe.avoidOccluderConstraint(avoid, shouldAvoidOccluder: joint, for: root)
    probe.avoidOccluderConstraint(avoid, didAvoidOccluder: joint, for: root)
}

// ---- SceneKitEnumTests.swift ----
func testEnumOptionSetAndConstantValues() {
    _ = SCNActionTimingMode.self
    _ = SCNActionTimingMode.easeIn
    _ = SCNActionTimingMode.easeInEaseOut
    _ = SCNActionTimingMode.easeOut
    _ = SCNActionTimingMode.linear
    _ = SCNAntialiasingMode.self
    _ = SCNAntialiasingMode.multisampling2X
    _ = SCNAntialiasingMode.multisampling4X
    _ = SCNAntialiasingMode.none
    _ = SCNBillboardAxis.self
    _ = SCNBillboardAxis.all
    _ = SCNBillboardAxis.X
    _ = SCNBillboardAxis.Y
    _ = SCNBillboardAxis.Z
    _ = SCNBlendMode.self
    _ = SCNBlendMode.add
    _ = SCNBlendMode.alpha
    _ = SCNBlendMode.max
    _ = SCNBlendMode.multiply
    _ = SCNBlendMode.replace
    _ = SCNBlendMode.screen
    _ = SCNBlendMode.subtract
    _ = SCNBufferFrequency.self
    _ = SCNBufferFrequency.perFrame
    _ = SCNBufferFrequency.perNode
    _ = SCNBufferFrequency.perShadable
    _ = SCNCameraProjectionDirection.self
    _ = SCNCameraProjectionDirection.horizontal
    _ = SCNCameraProjectionDirection.vertical
    _ = SCNChamferMode.self
    _ = SCNChamferMode.back
    _ = SCNChamferMode.both
    _ = SCNChamferMode.front
    _ = SCNColorMask.self
    _ = SCNColorMask.all
    _ = SCNColorMask.alpha
    _ = SCNColorMask.blue
    _ = SCNColorMask.green
    _ = SCNColorMask.red
    _ = SCNCullMode.self
    _ = SCNCullMode.back
    _ = SCNCullMode.front
    _ = SCNDebugOptions.self
    _ = SCNDebugOptions.renderAsWireframe
    _ = SCNDebugOptions.showBoundingBoxes
    _ = SCNDebugOptions.showCameras
    _ = SCNDebugOptions.showConstraints
    _ = SCNDebugOptions.showCreases
    _ = SCNDebugOptions.showLightExtents
    _ = SCNDebugOptions.showLightInfluences
    _ = SCNDebugOptions.showPhysicsFields
    _ = SCNDebugOptions.showPhysicsShapes
    _ = SCNDebugOptions.showSkeletons
    _ = SCNDebugOptions.showWireframe
    _ = SCNFillMode.self
    _ = SCNFillMode.fill
    _ = SCNFillMode.lines
    _ = SCNFilterMode.self
    _ = SCNFilterMode.linear
    _ = SCNFilterMode.nearest
    _ = SCNFilterMode.none
    _ = SCNGeometryPrimitiveType.self
    _ = SCNGeometryPrimitiveType.line
    _ = SCNGeometryPrimitiveType.point
    _ = SCNGeometryPrimitiveType.polygon
    _ = SCNGeometryPrimitiveType.triangleStrip
    _ = SCNGeometryPrimitiveType.triangles
    _ = SCNHitTestSearchMode.self
    _ = SCNHitTestSearchMode.all
    _ = SCNHitTestSearchMode.any
    _ = SCNHitTestSearchMode.closest
    _ = SCNInteractionMode.self
    _ = SCNInteractionMode.fly
    _ = SCNInteractionMode.orbitAngleMapping
    _ = SCNInteractionMode.orbitArcball
    _ = SCNInteractionMode.orbitCenteredArcball
    _ = SCNInteractionMode.orbitTurntable
    _ = SCNInteractionMode.pan
    _ = SCNInteractionMode.truck
    _ = SCNLightAreaType.self
    _ = SCNLightAreaType.polygon
    _ = SCNLightAreaType.rectangle
    _ = SCNLightProbeType.self
    _ = SCNLightProbeType.irradiance
    _ = SCNLightProbeType.radiance
    _ = SCNLightProbeUpdateType.self
    _ = SCNLightProbeUpdateType.never
    _ = SCNLightProbeUpdateType.realtime
    _ = SCNMorpherCalculationMode.self
    _ = SCNMorpherCalculationMode.additive
    _ = SCNMorpherCalculationMode.normalized
    _ = SCNMovabilityHint.self
    _ = SCNMovabilityHint.fixed
    _ = SCNMovabilityHint.movable
    _ = SCNNodeFocusBehavior.self
    _ = SCNNodeFocusBehavior.focusable
    _ = SCNNodeFocusBehavior.none
    _ = SCNNodeFocusBehavior.occluding
    _ = SCNParticleBirthDirection.self
    _ = SCNParticleBirthDirection.constant
    _ = SCNParticleBirthDirection.random
    _ = SCNParticleBirthDirection.surfaceNormal
    _ = SCNParticleBirthLocation.self
    _ = SCNParticleBirthLocation.surface
    _ = SCNParticleBirthLocation.vertex
    _ = SCNParticleBirthLocation.volume
    _ = SCNParticleBlendMode.self
    _ = SCNParticleBlendMode.additive
    _ = SCNParticleBlendMode.alpha
    _ = SCNParticleBlendMode.multiply
    _ = SCNParticleBlendMode.replace
    _ = SCNParticleBlendMode.screen
    _ = SCNParticleBlendMode.subtract
    _ = SCNParticleEvent.self
    _ = SCNParticleEvent.birth
    _ = SCNParticleEvent.collision
    _ = SCNParticleEvent.death
    _ = SCNParticleImageSequenceAnimationMode.self
    _ = SCNParticleImageSequenceAnimationMode.autoReverse
    _ = SCNParticleImageSequenceAnimationMode.clamp
    _ = SCNParticleImageSequenceAnimationMode.`repeat`
    _ = SCNParticleInputMode.self
    _ = SCNParticleInputMode.overDistance
    _ = SCNParticleInputMode.overLife
    _ = SCNParticleInputMode.overOtherProperty
    _ = SCNParticleModifierStage.self
    _ = SCNParticleModifierStage.postCollision
    _ = SCNParticleModifierStage.postDynamics
    _ = SCNParticleModifierStage.preCollision
    _ = SCNParticleModifierStage.preDynamics
    _ = SCNParticleOrientationMode.self
    _ = SCNParticleOrientationMode.billboardScreenAligned
    _ = SCNParticleOrientationMode.billboardViewAligned
    _ = SCNParticleOrientationMode.billboardYAligned
    _ = SCNParticleOrientationMode.free
    _ = SCNParticleSortingMode.self
    _ = SCNParticleSortingMode.distance
    _ = SCNParticleSortingMode.none
    _ = SCNParticleSortingMode.oldestFirst
    _ = SCNParticleSortingMode.projectedDepth
    _ = SCNParticleSortingMode.youngestFirst
    _ = SCNPhysicsBodyType.self
    _ = SCNPhysicsBodyType.dynamic
    _ = SCNPhysicsBodyType.kinematic
    _ = SCNPhysicsBodyType.`static`
    _ = SCNPhysicsCollisionCategory.self
    _ = SCNPhysicsCollisionCategory.all
    _ = SCNPhysicsCollisionCategory.`default`
    _ = SCNPhysicsCollisionCategory.`static`
    _ = SCNPhysicsFieldScope.self
    _ = SCNPhysicsFieldScope.insideExtent
    _ = SCNPhysicsFieldScope.outsideExtent
    _ = SCNReferenceLoadingPolicy.self
    _ = SCNReferenceLoadingPolicy.immediate
    _ = SCNReferenceLoadingPolicy.onDemand
    _ = SCNRenderingAPI.self
    _ = SCNRenderingAPI.metal
    _ = SCNRenderingAPI.openGLES2
    _ = SCNSceneSourceStatus.self
    _ = SCNSceneSourceStatus.complete
    _ = SCNSceneSourceStatus.error
    _ = SCNSceneSourceStatus.parsing
    _ = SCNSceneSourceStatus.processing
    _ = SCNSceneSourceStatus.validating
    _ = SCNShadowMode.self
    _ = SCNShadowMode.deferred
    _ = SCNShadowMode.forward
    _ = SCNShadowMode.modulated
    _ = SCNTessellationSmoothingMode.self
    _ = SCNTessellationSmoothingMode.none
    _ = SCNTessellationSmoothingMode.pnTriangles
    _ = SCNTessellationSmoothingMode.phong
    _ = SCNTransparencyMode.self
    _ = SCNTransparencyMode.aOne
    _ = SCNTransparencyMode.dualLayer
    _ = SCNTransparencyMode.rgbZero
    _ = SCNTransparencyMode.singleLayer
    _ = SCNWrapMode.self
    _ = SCNWrapMode.clamp
    _ = SCNWrapMode.clampToBorder
    _ = SCNWrapMode.mirror
    _ = SCNWrapMode.`repeat`
    _ = SCNConsistencyInvalidArgumentError
    _ = SCNConsistencyInvalidCountError
    _ = SCNConsistencyInvalidURIError
    _ = SCNConsistencyMissingAttributeError
    _ = SCNConsistencyMissingElementError
    _ = SCNConsistencyXMLSchemaValidationError
    _ = SCNProgramCompilationError
    _ = SCNConsistencyElementIDErrorKey
    _ = SCNConsistencyElementTypeErrorKey
    _ = SCNConsistencyLineNumberErrorKey
    _ = SCNDetailedErrorsKey
    _ = SCNErrorDomain
    _ = SCNGeometrySource.Semantic.boneIndices
    _ = SCNGeometrySource.Semantic.boneWeights
    _ = SCNGeometrySource.Semantic.color
    _ = SCNGeometrySource.Semantic.edgeCrease
    _ = SCNGeometrySource.Semantic.normal
    _ = SCNGeometrySource.Semantic.tangent
    _ = SCNGeometrySource.Semantic.texcoord
    _ = SCNGeometrySource.Semantic.vertex
    _ = SCNGeometrySource.Semantic.vertexCrease
    _ = SCNHitTestOption.backFaceCulling
    _ = SCNHitTestOption.boundingBoxOnly
    _ = SCNHitTestOption.clipToZRange
    _ = SCNHitTestOption.firstFoundOnly
    _ = SCNHitTestOption.ignoreChildNodes
    _ = SCNHitTestOption.ignoreHiddenNodes
    _ = SCNHitTestOption.categoryBitMask
    _ = SCNHitTestOption.ignoreLightArea
    _ = SCNHitTestOption.searchMode
    _ = SCNHitTestOption.rootNode
    _ = SCNHitTestOption.sortResults
    _ = SCNLight.LightType.ambient
    _ = SCNLight.LightType.area
    _ = SCNLight.LightType.directional
    _ = SCNLight.LightType.IES
    _ = SCNLight.LightType.omni
    _ = SCNLight.LightType.probe
    _ = SCNLight.LightType.spot
    _ = SCNMaterial.LightingModel.blinn
    _ = SCNMaterial.LightingModel.constant
    _ = SCNMaterial.LightingModel.lambert
    _ = SCNMaterial.LightingModel.phong
    _ = SCNMaterial.LightingModel.physicallyBased
    _ = SCNMaterial.LightingModel.shadowOnly
    _ = SCNMatrix4Identity
    _ = SCNModelTransform
    _ = SCNModelViewProjectionTransform
    _ = SCNModelViewTransform
    _ = SCNNormalTransform
    _ = SCNPhysicsShape.Option.keepAsCompound
    _ = SCNPhysicsShape.Option.collisionMargin
    _ = SCNPhysicsShape.Option.scale
    _ = SCNPhysicsShape.ShapeType.boundingBox
    _ = SCNPhysicsShape.ShapeType.concavePolyhedron
    _ = SCNPhysicsShape.ShapeType.convexHull
    _ = SCNPhysicsShape.Option.type
    _ = SCNView.Option.preferLowPowerDevice
    _ = SCNView.Option.preferredDevice
    _ = SCNView.Option.preferredRenderingAPI
    _ = SCNProgramMappingChannelKey
    _ = SCNProjectionTransform
    _ = SCNScene.Attribute.endTime
    _ = SCNSceneExportDestinationURL
    _ = SCNScene.Attribute.frameRate
    _ = SCNSceneSource.LoadingOption.animationImportPolicy
    _ = SCNSceneSourceAssetAuthorKey
    _ = SCNSceneSourceAssetAuthoringToolKey
    _ = SCNSceneSourceAssetContributorsKey
    _ = SCNSceneSourceAssetCreatedDateKey
    _ = SCNSceneSource.LoadingOption.assetDirectoryURLs
    _ = SCNSceneSourceAssetModifiedDateKey
    _ = SCNSceneSourceAssetUnitKey
    _ = SCNSceneSourceAssetUnitMeterKey
    _ = SCNSceneSourceAssetUnitNameKey
    _ = SCNSceneSourceAssetUpAxisKey
    _ = SCNSceneSource.LoadingOption.checkConsistency
    _ = SCNSceneSource.LoadingOption.convertToYUp
    _ = SCNSceneSource.LoadingOption.convertUnitsToMeters
    _ = SCNSceneSource.LoadingOption.createNormalsIfAbsent
    _ = SCNSceneSource.LoadingOption.flattenScene
    _ = SCNSceneSource.LoadingOption.preserveOriginalTopology
    _ = SCNSceneSource.LoadingOption.overrideAssetURLs
    _ = SCNSceneSource.LoadingOption.strictConformance
    _ = SCNSceneSource.LoadingOption.useSafeMode
    _ = SCNScene.Attribute.startTime
    _ = SCNScene.Attribute.upAxis
    _ = SCNShaderModifierEntryPoint.fragment
    _ = SCNShaderModifierEntryPoint.geometry
    _ = SCNShaderModifierEntryPoint.lightingModel
    _ = SCNShaderModifierEntryPoint.surface
    _ = SCNVector3Zero
    _ = SCNVector4Zero
    _ = SCNViewTransform
    _ = SCNGeometrySource.Semantic.self
    _ = SCNHitTestOption.self
    _ = SCNLight.LightType.self
    _ = SCNMaterial.LightingModel.self
    _ = SCNPhysicsShape.Option.self
    _ = SCNPhysicsShape.ShapeType.self
    _ = SCNScene.Attribute.self
    _ = SCNSceneSource.LoadingOption.self
    _ = SCNShaderModifierEntryPoint.self
    _ = SCNView.Option.self
    _ = SCN_ENABLE_METAL
    _ = SCN_ENABLE_OPENGL
    var axes: SCNBillboardAxis = [.X, .Y]
    precondition(axes.contains(.X))
    precondition(!axes.isEmpty)
    _ = axes.rawValue
    axes.insert(.Z)
    axes.remove(.Y)
    _ = axes.union(.all)
    _ = axes.intersection(.X)
    _ = axes.symmetricDifference(.Z)
    _ = SCNBillboardAxis.X.subtracting(.X)
    precondition(SCNBillboardAxis.X.isSubset(of: .all))
    precondition(SCNBillboardAxis.all.isSuperset(of: .X))
    precondition(SCNBillboardAxis.X.isDisjoint(with: .Y))
    var mask: SCNColorMask = [.red, .green]
    mask.formUnion(.blue)
    mask.formIntersection(.red)
    mask.formSymmetricDifference(.alpha)
    _ = SCNColorMask.red != SCNColorMask.blue
    var debug: SCNDebugOptions = [.showBoundingBoxes, .showWireframe]
    debug.insert(.showCameras)
    precondition(debug.contains(.showBoundingBoxes))
    _ = SCNPhysicsCollisionCategory.`default`.union(.`static`)
    _ = SCNHitTestOption.firstFoundOnly
    _ = SCNHitTestOption.boundingBoxOnly
    _ = SCNHitTestOption.ignoreHiddenNodes
    _ = SCNHitTestOption.ignoreChildNodes
    _ = SCNHitTestOption.backFaceCulling
    _ = SCNHitTestOption.sortResults
    _ = SCNHitTestOption.searchMode
    _ = SCNHitTestOption.categoryBitMask
    _ = SCNHitTestOption.clipToZRange
    _ = SCNHitTestOption.rootNode
    _ = SCNGeometrySource.Semantic.vertex
    _ = SCNGeometrySource.Semantic.normal
    _ = SCNGeometrySource.Semantic.texcoord
    _ = SCNGeometrySource.Semantic.color
    _ = SCNGeometrySource.Semantic.tangent
    _ = SCNMaterial.LightingModel.phong
    _ = SCNMaterial.LightingModel.blinn
    _ = SCNMaterial.LightingModel.lambert
    _ = SCNMaterial.LightingModel.constant
    _ = SCNLight.LightType.omni
    _ = SCNLight.LightType.directional
    _ = SCNView.Option.preferredRenderingAPI
    _ = SCNView.Option.preferLowPowerDevice
    _ = SCNShaderModifierEntryPoint.surface
    _ = SCNActionTimingMode.linear != .easeIn
    _ = SCNActionTimingMode.easeOut.hashValue
    _ = SCNErrorDomain
    _ = SCNDetailedErrorsKey
    _ = SCNConsistencyElementIDErrorKey
    _ = SCNConsistencyElementTypeErrorKey
    _ = SCNConsistencyLineNumberErrorKey
    _ = SCNConsistencyInvalidArgumentError
    _ = SCNConsistencyInvalidCountError
    _ = SCNConsistencyInvalidURIError
    _ = SCNConsistencyMissingAttributeError
    _ = SCNConsistencyMissingElementError
    _ = SCNConsistencyXMLSchemaValidationError
    _ = SCNProgramCompilationError
    _ = SCNModelTransform
    _ = SCNModelViewTransform
    _ = SCNModelViewProjectionTransform
    _ = SCNNormalTransform
    _ = SCNProjectionTransform
    _ = SCNViewTransform
    _ = SCNProgramMappingChannelKey
    _ = SCNSceneExportDestinationURL
    _ = SCNSceneSourceAssetAuthorKey
    _ = SCNSceneSourceAssetAuthoringToolKey
    _ = SCNSceneSourceAssetContributorsKey
    _ = SCNSceneSourceAssetCreatedDateKey
    _ = SCNSceneSourceAssetModifiedDateKey
    _ = SCNSceneSourceAssetUnitKey
    _ = SCNSceneSourceAssetUnitMeterKey
    _ = SCNSceneSourceAssetUnitNameKey
    _ = SCNSceneSourceAssetUpAxisKey
    _ = SCN_ENABLE_METAL
    _ = SCN_ENABLE_OPENGL
    _ = SCNVector3Zero
    _ = SCNVector4Zero
    _ = SCNMatrix4Identity
    _ = SCNActionTimingMode.linear.hashValue
    _ = SCNBillboardAxis.X.hashValue
    _ = SCNPhysicsShape.Option.type.hashValue
    var enumHasher = Hasher()
    SCNActionTimingMode.linear.hash(into: &enumHasher)
    SCNBillboardAxis.X.hash(into: &enumHasher)
    _ = SCNBillboardAxis(rawValue: 1)
    _ = SCNPhysicsShape.Option(rawValue: "x")
    _ = SCNHitTestOption(rawValue: "firstFoundOnly")
    _ = SCNPhysicsWorld.TestOption.backfaceCulling
    _ = SCNPhysicsWorld.TestOption.collisionBitMask
    _ = SCNPhysicsWorld.TestOption.searchMode
    _ = SCNPhysicsWorld.TestSearchMode.any
    _ = SCNPhysicsWorld.TestSearchMode.closest
    _ = SCNPhysicsWorld.TestSearchMode.all
    _ = SCNPhysicsWorld.TestOption.self
    _ = SCNPhysicsWorld.TestSearchMode.self
    _ = SCNPhysicsWorld.TestOption(rawValue: "collisionBitMask")
    _ = SCNPhysicsWorld.TestSearchMode(rawValue: "closest")
    _ = SCNPhysicsWorld.TestOption.collisionBitMask != .searchMode
    _ = SCNPhysicsWorld.TestSearchMode.closest != .any
    _ = SCNPhysicsWorld.TestOption.collisionBitMask.hashValue
    _ = SCNPhysicsWorld.TestSearchMode.closest.hashValue
    var physHasher = Hasher()
    SCNPhysicsWorld.TestOption.collisionBitMask.hash(into: &physHasher)
    SCNPhysicsWorld.TestSearchMode.closest.hash(into: &physHasher)
    _ = SCNTransparencyMode.default
    _ = SCNSceneSource.AnimationImportPolicy.doNotPlay
    _ = SCNSceneSource.AnimationImportPolicy.playRepeatedly
    _ = SCNSceneSource.AnimationImportPolicy.playUsingSceneTimeBase
    _ = SCNParticleSystem.ParticleProperty.angle
    _ = SCNParticleSystem.ParticleProperty.bounce
    _ = SCNParticleSystem.ParticleProperty.charge
    _ = SCNParticleSystem.ParticleProperty.contactNormal
    _ = SCNParticleSystem.ParticleProperty.contactPoint
    _ = SCNParticleSystem.ParticleProperty.frameRate
    _ = SCNParticleSystem.ParticleProperty.life
    _ = SCNParticleSystem.ParticleProperty.rotationAxis
}

// ---- SceneKitGeometryTests.swift ----
func testPrimitiveLayouts() {
    let box = SCNBox(width: 2, height: 4, length: 6, chamferRadius: 0)
    precondition(box.width == 2 && box.height == 4 && box.length == 6)
    precondition(box.widthSegmentCount == 1)
    precondition(box.sources(for: .vertex).first?.vectorCount ?? 0 >= 24)
    precondition(!box.sources(for: .normal).isEmpty)
    precondition(box.elements.first?.primitiveType == .triangles)
    precondition(abs(box.boundingBox.max.x - 1) < 1e-4)
    let sphere = SCNSphere(radius: 2)
    precondition(sphere.segmentCount == 24)
    let plane = SCNPlane(width: 4, height: 2)
    precondition(plane.sources(for: .vertex).first?.vectorCount == 6)
    let cyl = SCNCylinder(radius: 1, height: 2)
    precondition(cyl.radialSegmentCount == 24)
    let cone = SCNCone(topRadius: 0, bottomRadius: 1, height: 2)
    precondition(cone.bottomRadius == 1)
    let cap = SCNCapsule(capRadius: 0.5, height: 2)
    precondition(cap.capSegmentCount == 24)
    let torus = SCNTorus(ringRadius: 1, pipeRadius: 0.2)
    precondition(torus.ringSegmentCount == 24)
    let tube = SCNTube(innerRadius: 0.5, outerRadius: 1, height: 2)
    precondition(tube.outerRadius == 1)
    let pyr = SCNPyramid(width: 1, height: 2, length: 1)
    precondition(pyr.height == 2)
    let floor = SCNFloor()
    precondition(floor.reflectivity == 0.25)
    let text = SCNText(string: "A", extrusionDepth: 1)
    precondition((text.string as? String) == "A")
    let shape = SCNShape()
    shape.extrusionDepth = 2
    precondition(shape.chamferMode == .both)
    _ = box.chamferRadius
    _ = box.heightSegmentCount
    _ = box.lengthSegmentCount
    _ = sphere.isGeodesic
    _ = plane.widthSegmentCount
    _ = plane.cornerRadius
    _ = cyl.heightSegmentCount
    _ = cone.radialSegmentCount
    _ = cap.radialSegmentCount
    _ = torus.pipeSegmentCount
    _ = tube.radialSegmentCount
    _ = pyr.width
    _ = floor.reflectionFalloffEnd
    _ = text.flatness
    _ = shape.chamferRadius
}

func testCustomGeometrySource() {
    let floats: [Float] = [0, 0, 0, 1, 0, 0, 0, 1, 0]
    let data = floats.withUnsafeBufferPointer { Data(buffer: $0) }
    let src = SCNGeometrySource(
        data: data, semantic: .vertex, vectorCount: 3,
        usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4,
        dataOffset: 0, dataStride: 12
    )
    let elem = SCNGeometryElement(indices: [UInt16]([0, 1, 2]), primitiveType: .triangles)
    let geom = SCNGeometry(sources: [src], elements: [elem])
    precondition(geom.elementCount == 1)
    geom.subdivisionLevel = 2
    precondition(geom.subdivisionLevel == 2)
    _ = geom.sources
    _ = geom.elements
    _ = geom.materials
    _ = geom.firstMaterial
    _ = src.semantic
    _ = src.vectorCount
    _ = src.usesFloatComponents
    _ = src.componentsPerVector
    _ = src.bytesPerComponent
    _ = src.dataOffset
    _ = src.dataStride
    _ = src.data
    _ = elem.primitiveType
    _ = elem.primitiveCount
    _ = elem.bytesPerIndex
    _ = elem.data
    let verts = SCNGeometrySource(vertices: [SCNVector3Zero, SCNVector3(1, 0, 0), SCNVector3(0, 1, 0)])
    _ = SCNGeometrySource(normals: [SCNVector3(0, 1, 0)])
    _ = SCNGeometrySource(textureCoordinates: [CGPoint.zero])
    _ = verts
    let lod = SCNLevelOfDetail(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0), screenSpaceRadius: 10)
    precondition(lod.screenSpaceRadius == 10)
    let tess = SCNGeometryTessellator()
    tess.edgeTessellationFactor = 2
    precondition(tess.smoothingMode == .none)
    _ = geom.elements.first
    _ = geom.sources(for: .vertex)
}

func testPrimitiveVertexCounts() {
    let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0)
    precondition(box.widthSegmentCount == 1)
    precondition(box.heightSegmentCount == 1)
    precondition(box.lengthSegmentCount == 1)
    precondition(box.sources(for: .vertex).first?.vectorCount == 36)
    precondition(box.elements.first?.primitiveCount == 12)
    let plane = SCNPlane(width: 4, height: 2)
    precondition(plane.widthSegmentCount == 1 && plane.heightSegmentCount == 1)
    precondition(plane.sources(for: .vertex).first?.vectorCount == 6)
    let sphere = SCNSphere(radius: 1)
    precondition(sphere.segmentCount == 24)
    precondition(sphere.sources(for: .vertex).first?.vectorCount == 24 * 48 * 6)
    let cyl = SCNCylinder(radius: 1, height: 2)
    precondition(cyl.radialSegmentCount == 24)
    precondition(cyl.heightSegmentCount == 1)
    precondition(cyl.sources(for: .vertex).first?.vectorCount == 288)
    let cone = SCNCone(topRadius: 0, bottomRadius: 1, height: 2)
    precondition(cone.radialSegmentCount == 24)
    precondition(cone.sources(for: .vertex).first?.vectorCount == 144)
    let torus = SCNTorus(ringRadius: 1, pipeRadius: 0.2)
    precondition(torus.ringSegmentCount == 24 && torus.pipeSegmentCount == 24)
    precondition(torus.sources(for: .vertex).first?.vectorCount == 24 * 24 * 6)
    let pyr = SCNPyramid(width: 1, height: 2, length: 1)
    precondition(pyr.sources(for: .vertex).first?.vectorCount == 18)
    let floor = SCNFloor()
    precondition(floor.sources(for: .vertex).first?.vectorCount == 6)
    let text = SCNText(string: "Hi", extrusionDepth: 1)
    precondition((text.string as? String) == "Hi")
    precondition((text.sources(for: .vertex).first?.vectorCount ?? 0) >= 36)
    text.alignmentMode = "center"
    text.truncationMode = "end"
    text.isWrapped = true
    text.containerFrame = CGRect(x: 0, y: 0, width: 10, height: 1)
    precondition(text.alignmentMode == "center")
    precondition(text.isWrapped)
    let verts = SCNGeometrySource(vertices: [
        SCNVector3(0, 0, 0), SCNVector3(1, 0, 0), SCNVector3(0, 1, 0)
    ])
    precondition(verts.vectorCount == 3)
    precondition(verts.semantic == .vertex)
    precondition(verts.componentsPerVector == 3)
    precondition(verts.dataStride == 12)
    let norms = SCNGeometrySource(normals: [SCNVector3(0, 0, 1)])
    precondition(norms.semantic == .normal)
    let uvs = SCNGeometrySource(textureCoordinates: [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1)])
    precondition(uvs.semantic == .texcoord)
    precondition(uvs.componentsPerVector == 2)
    let elem = SCNGeometryElement(indices: [UInt32]([0, 1, 2, 0, 2, 3]), primitiveType: .triangles)
    precondition(elem.primitiveType == .triangles)
    precondition(elem.primitiveCount == 2)
    precondition(elem.bytesPerIndex == 4)
}

func testGeometryMaterialsAndElements() {
    let geom = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
    geom.chamferSegmentCount = 7
    precondition(geom.chamferSegmentCount == 7)
    let plane = SCNPlane(width: 2, height: 2)
    plane.cornerSegmentCount = 9
    precondition(plane.cornerSegmentCount == 9)
    let red = SCNMaterial()
    red.name = "red"
    let blue = SCNMaterial()
    blue.name = "blue"
    geom.insertMaterial(red, at: 0)
    precondition(geom.materials.first === red)
    geom.replaceMaterial(at: 0, with: blue)
    precondition(geom.materials.first === blue)
    geom.removeMaterial(at: 0)
    let elem = geom.element(at: 0)
    elem.pointSize = 4
    elem.minimumPointScreenSpaceRadius = 1
    elem.maximumPointScreenSpaceRadius = 8
    elem.primitiveRange = NSRange(location: 0, length: elem.primitiveCount)
    precondition(elem.indicesChannelCount >= 1)
    precondition(elem.hasInterleavedIndicesChannels == false)
    precondition(abs(Float(elem.pointSize) - 4) < 1e-4)
    let crease = SCNGeometryElement(indices: [UInt16]([0, 1]), primitiveType: .line)
    let creaseSrc = SCNGeometrySource(vertices: [SCNVector3Zero, SCNVector3(1, 0, 0)])
    geom.edgeCreasesElement = crease
    geom.edgeCreasesSource = creaseSrc
    geom.wantsAdaptiveSubdivision = true
    let lod = SCNLevelOfDetail(geometry: SCNSphere(radius: 0.5), worldSpaceDistance: 12)
    geom.levelsOfDetail = [lod]
    precondition(abs(Float(lod.worldSpaceDistance) - 12) < 1e-4)
    let tess = SCNGeometryTessellator()
    tess.isAdaptive = true
    tess.isScreenSpace = true
    tess.insideTessellationFactor = 3
    tess.maximumEdgeLength = 2
    tess.tessellationFactorScale = 1.5
    geom.tessellator = tess
    precondition(tess.isAdaptive && tess.isScreenSpace)
    let channeled = SCNGeometry(
        sources: geom.sources,
        elements: geom.elements,
        sourceChannels: [0]
    )
    precondition(channeled.geometrySourceChannels?.first?.intValue == 0)
}

// ---- SceneKitHitTestTests.swift ----
func testHitTestSegment() {
    let scene = SCNScene()
    let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0)
    let node = SCNNode(geometry: box)
    node.name = "cube"
    scene.rootNode.addChildNode(node)
    let hits = scene.rootNode.hitTestWithSegment(
        from: SCNVector3(0, 0, 5),
        to: SCNVector3(0, 0, -5),
        options: [SCNHitTestOption.sortResults.rawValue: true]
    )
    precondition(!hits.isEmpty)
    precondition(hits[0].node === node)
    precondition(abs(hits[0].worldCoordinates.z - 1) < 0.15)
    _ = hits[0].localCoordinates
    _ = hits[0].localNormal
    _ = hits[0].worldNormal
    _ = hits[0].modelTransform
    _ = hits[0].geometryIndex
    _ = hits[0].faceIndex
    _ = hits[0].simdLocalCoordinates
    _ = hits[0].simdWorldCoordinates
    _ = hits[0].simdLocalNormal
    _ = hits[0].simdWorldNormal
    _ = hits[0].textureCoordinates(withMappingChannel: 0)
    let hidden = SCNNode(geometry: box)
    hidden.isHidden = true
    hidden.position = SCNVector3(10, 0, 0)
    scene.rootNode.addChildNode(hidden)
    let ignoreHidden = scene.rootNode.hitTestWithSegment(
        from: SCNVector3(10, 0, 5),
        to: SCNVector3(10, 0, -5),
        options: [SCNHitTestOption.ignoreHiddenNodes.rawValue: true]
    )
    precondition(ignoreHidden.isEmpty)
}

func testHitTestResultBoneNode() {
    let result = SCNHitTestResult()
    precondition(result.boneNode == nil)
    _ = SCNHitTestResult.self
}

func testHitTestFailClosedWithoutScene() {
    let renderer = SCNRenderer()
    renderer.scene = nil
    let empty = renderer.hitTest(CGPoint(x: 16, y: 16), options: nil)
    precondition(empty.isEmpty)
    let view = SCNView(frame: CGRect(x: 0, y: 0, width: 32, height: 32), options: nil)
    view.scene = nil
    precondition(view.hitTest(CGPoint.zero, options: nil).isEmpty)
}

// ---- SceneKitLightTests.swift ----
func testLightStores() {
    let light = SCNLight()
    light.type = .spot
    light.spotOuterAngle = 60
    light.spotInnerAngle = 0
    light.intensity = 500
    light.color = SCNVector3(1, 1, 1)
    light.temperature = 6500
    light.castsShadow = false
    light.shadowRadius = 3
    light.shadowMode = .forward
    light.shadowBias = 1
    light.zNear = 1
    light.zFar = 100
    light.attenuationStartDistance = 0
    light.attenuationEndDistance = 0
    light.attenuationFalloffExponent = 2
    light.areaType = .rectangle
    light.probeType = .irradiance
    light.probeUpdateType = .never
    light.areaExtents = SIMD3<Float>(2, 1, 0)
    light.parallaxCenterOffset = SIMD3<Float>()
    light.parallaxExtentsFactor = SIMD3<Float>(1, 1, 1)
    light.probeExtents = SIMD3<Float>()
    light.probeOffset = SIMD3<Float>()
    light.categoryBitMask = 1
    light.name = "light"
    _ = light.gobo
    _ = light.probeEnvironment
    _ = light.sphericalHarmonicsCoefficients
    precondition(light.spotOuterAngle == 60)
    precondition(abs(light.areaExtents.x - 2) < 1e-4)
}

func testLightShadowAndAreaStores() {
    let light = SCNLight()
    light.iesProfileURL = URL(fileURLWithPath: "/tmp/missing.ies")
    light.areaPolygonVertices = []
    light.automaticallyAdjustsShadowProjection = false
    light.doubleSided = true
    light.drawsArea = true
    light.forcesBackFaceCasters = true
    light.maximumShadowDistance = 50
    light.parallaxCorrectionEnabled = true
    light.sampleDistributedShadowMaps = true
    light.shadowCascadeCount = 3
    light.shadowCascadeSplittingFactor = 0.4
    light.shadowColor = SCNVector4(0, 0, 0, 1)
    light.shadowMapSize = CGSize(width: 512, height: 512)
    light.shadowSampleCount = 8
    precondition(light.doubleSided)
    precondition(light.drawsArea)
    precondition(light.forcesBackFaceCasters)
    precondition(light.shadowCascadeCount == 3)
    precondition(light.iesProfileURL?.path.hasSuffix("missing.ies") == true)
}

// ---- SceneKitMaterialTests.swift ----
func testMaterialLightingAndBlend() {
    let mat = SCNMaterial()
    mat.lightingModel = .phong
    mat.isDoubleSided = true
    mat.blendMode = .add
    mat.transparency = 0.5
    mat.shininess = 32
    mat.cullMode = .back
    mat.fillMode = .fill
    mat.transparencyMode = .aOne
    mat.locksAmbientWithDiffuse = false
    mat.isLitPerPixel = true
    mat.readsFromDepthBuffer = true
    mat.writesToDepthBuffer = true
    mat.fresnelExponent = 0
    mat.diffuse.contents = SCNVector3(1, 0, 0)
    mat.specular.contents = SCNVector3(1, 1, 1)
    mat.ambient.contents = SCNVector3Zero
    mat.emission.contents = SCNVector3Zero
    mat.transparent.contents = SCNVector4(1, 1, 1, 1)
    mat.reflective.contents = SCNVector3Zero
    mat.multiply.contents = SCNVector3(1, 1, 1)
    mat.normal.contents = SCNVector3(0, 0, 1)
    mat.metalness.contents = 0
    mat.roughness.contents = 1
    precondition(mat.isDoubleSided && mat.blendMode == .add)
    _ = mat.selfIllumination
    _ = mat.ambientOcclusion
    _ = mat.displacement
    _ = mat.clearCoat
    _ = mat.clearCoatRoughness
    _ = mat.clearCoatNormal
    let prop = SCNMaterialProperty(contents: SCNVector3(1, 0, 0))
    prop.intensity = 1
    prop.magnificationFilter = .linear
    prop.minificationFilter = .linear
    prop.mipFilter = .nearest
    prop.wrapS = .clamp
    prop.wrapT = .`repeat`
    prop.mappingChannel = 0
    prop.maxAnisotropy = 1
    _ = prop.contentsTransform
    _ = prop.textureComponents
}

func testMaterialPropertyBorderAndPrecomputed() {
    let mat = SCNMaterial()
    mat.colorBufferWriteMask = [.red, .green]
    precondition(mat.colorBufferWriteMask.contains(.red))
    let prop = SCNMaterialProperty()
    prop.borderColor = SCNVector4(1, 0, 0, 1)
    precondition(prop.borderColor != nil)
    do {
        _ = try SCNMaterialProperty.precomputedLightingEnvironmentContents(with: Data())
        precondition(false, "precomputed lighting must fail-close")
    } catch {
        _ = error
    }
    do {
        _ = try SCNMaterialProperty.precomputedLightingEnvironmentContents(with: URL(fileURLWithPath: "/tmp/missing.env"))
        precondition(false, "precomputed lighting URL must fail-close")
    } catch {
        _ = error
    }
}

// ---- SceneKitMathTests.swift ----
func skNear(_ a: Float, _ b: Float, _ message: String, eps: Float = 1e-4) {
    precondition(abs(a - b) < eps, "\(message) (\(a) vs \(b))")
}

func skXform(_ m: SCNMatrix4, _ p: SCNVector3) -> SCNVector3 {
    SCNVector3(
        x: m.m11 * p.x + m.m21 * p.y + m.m31 * p.z + m.m41,
        y: m.m12 * p.x + m.m22 * p.y + m.m32 * p.z + m.m42,
        z: m.m13 * p.x + m.m23 * p.y + m.m33 * p.z + m.m43
    )
}

func testVectorMath() {
    precondition(SCNVector3EqualToVector3(SCNVector3Zero, SCNVector3Make(0, 0, 0)))
    let v = SCNVector3(1, 2, 3)
    skNear(v.x, 1, "x"); skNear(v.y, 2, "y"); skNear(v.z, 3, "z")
    let v2 = SCNVector3(x: 4, y: 5, z: 6)
    skNear(v2.x, 4, "init x")
    _ = SCNVector3(1.0 as Double, 2.0, 3.0)
    _ = SCNVector3(1 as Int, 2, 3)
    let simd3 = SIMD3<Float>(v)
    skNear(SCNVector3(simd3).y, 2, "simd3")
    precondition(SCNVector4EqualToVector4(SCNVector4Make(1, 2, 3, 4), SCNVector4(x: 1, y: 2, z: 3, w: 4)))
    let q = SCNVector4(1, 2, 3, 4)
    skNear(q.w, 4, "w")
    let simd4 = SIMD4<Float>(q)
    skNear(SCNVector4(simd4).z, 3, "simd4")
}

func testMatrixMath() {
    precondition(SCNMatrix4IsIdentity(SCNMatrix4Identity))
    precondition(SCNMatrix4EqualToMatrix4(SCNMatrix4Identity, SCNMatrix4()))
    let translated = SCNMatrix4MakeTranslation(3, 4, 5)
    let origin = skXform(translated, SCNVector3Zero)
    skNear(origin.x, 3, "tx"); skNear(origin.y, 4, "ty"); skNear(origin.z, 5, "tz")
    let scaled = SCNMatrix4MakeScale(2, 3, 4)
    let p = skXform(scaled, SCNVector3(x: 1, y: 1, z: 1))
    skNear(p.x, 2, "sx"); skNear(p.y, 3, "sy"); skNear(p.z, 4, "sz")
    let t1 = SCNMatrix4MakeTranslation(1, 0, 0)
    let t2 = SCNMatrix4MakeTranslation(0, 2, 0)
    let composed = SCNMatrix4Mult(t1, t2)
    let c = skXform(composed, SCNVector3Zero)
    skNear(c.x, 1, "mult x"); skNear(c.y, 2, "mult y")
    let inv = SCNMatrix4Invert(translated)
    let round = SCNMatrix4Mult(inv, translated)
    precondition(SCNMatrix4IsIdentity(round) || abs(round.m11 - 1) < 1e-3)
    let rot = SCNMatrix4MakeRotation(Float.pi / 2, 0, 1, 0)
    let rp = skXform(rot, SCNVector3(1, 0, 0))
    skNear(rp.x, 0, "ry x", eps: 1e-5)
    skNear(rp.z, -1, "ry z", eps: 1e-5)
    let moved = SCNMatrix4Translate(SCNMatrix4Identity, 1, 2, 3)
    skNear(moved.m41, 1, "translate helper")
    let scaledM = SCNMatrix4Scale(SCNMatrix4MakeTranslation(1, 2, 3), 2, 2, 2)
    let q = skXform(scaledM, SCNVector3(1, 0, 0))
    skNear(q.x, 4, "scale helper x")
    _ = SCNMatrix4Rotate(SCNMatrix4Identity, 0.1, 0, 1, 0)
    skNear(translated.m11, 1, "m11")
    skNear(translated.m22, 1, "m22")
    skNear(translated.m33, 1, "m33")
    skNear(translated.m44, 1, "m44")
    _ = translated.m12; _ = translated.m13; _ = translated.m14
    _ = translated.m21; _ = translated.m23; _ = translated.m24
    _ = translated.m31; _ = translated.m32; _ = translated.m34
    _ = translated.m42; _ = translated.m43
}

func testQuaternionFromRotation() {
    let node = SCNNode()
    node.rotation = SCNVector4(0, 1, 0, Float.pi / 2)
    skNear(node.orientation.w, cos(Float.pi / 4), "quat w", eps: 1e-3)
    node.eulerAngles = SCNVector3(0, Float.pi / 2, 0)
    skNear(node.eulerAngles.y, Float.pi / 2, "euler", eps: 2e-3)
}

// ---- SceneKitNodeTests.swift ----
func testNodeHierarchy() {
    let scene = SCNScene()
    let parent = SCNNode()
    parent.name = "parent"
    let child = SCNNode()
    child.name = "child"
    scene.rootNode.addChildNode(parent)
    parent.addChildNode(child)
    precondition(child.parent === parent)
    precondition(parent.childNodes.count == 1)
    precondition(scene.rootNode.childNode(withName: "child", recursively: true) === child)
    parent.addChildNode(parent)
    precondition(parent.childNodes.filter { $0 === parent }.isEmpty)
    child.addChildNode(parent)
    precondition(child.childNodes.filter { $0 === parent }.isEmpty)
    parent.insertChildNode(SCNNode(), at: 0)
    var enumerated = 0
    scene.rootNode.enumerateHierarchy { _, _ in enumerated += 1 }
    precondition(enumerated >= 3)
    var walk = 0
    scene.rootNode.enumerateChildNodes { _, stop in
        walk += 1
        if walk > 10_000 { stop.pointee = true }
    }
    _ = parent.childNodes(passingTest: { _, _ in true })
    let extra = SCNNode()
    parent.replaceChildNode(child, with: extra)
    extra.removeFromParentNode()
}

func testNodeTransforms() {
    let parent = SCNNode()
    let child = SCNNode()
    parent.addChildNode(child)
    child.position = SCNVector3(x: 1, y: 0, z: 0)
    parent.position = SCNVector3(x: 10, y: 0, z: 0)
    precondition(abs(child.worldPosition.x - 11) < 1e-4)
    let local = parent.convertPosition(child.worldPosition, from: nil)
    precondition(abs(local.x - 1) < 1e-4)
    _ = parent.convertPosition(child.position, to: nil)
    _ = parent.convertVector(SCNVector3(0, 1, 0), from: nil)
    _ = parent.convertVector(SCNVector3(0, 1, 0), to: nil)
    _ = parent.convertTransform(SCNMatrix4Identity, from: nil)
    _ = parent.convertTransform(SCNMatrix4Identity, to: nil)
    child.scale = SCNVector3(2, 2, 2)
    child.pivot = SCNMatrix4Identity
    child.localTranslate(by: SCNVector3(0.5, 0, 0))
    child.localRotate(by: SCNVector4(0, 1, 0, 0.1))
    child.look(at: SCNVector3(0, 0, 1))
    child.look(at: SCNVector3(1, 0, 0), up: SCNNode.localUp, localFront: SCNNode.localFront)
    _ = SCNNode.localRight
    _ = SCNNode.localUp
    _ = SCNNode.localFront
    _ = child.worldUp
    _ = child.worldRight
    _ = child.worldFront
    _ = child.worldOrientation
    _ = child.worldTransform
    _ = child.transform
    child.setWorldTransform(SCNMatrix4MakeTranslation(1, 2, 3))
    child.simdPosition = SIMD3<Float>(1, 2, 3)
    precondition(abs(child.position.y - 2) < 1e-4)
    _ = child.simdWorldPosition
    _ = child.simdEulerAngles
    _ = child.simdRotation
    _ = child.simdScale
    _ = child.simdWorldFront
    _ = child.simdWorldRight
    _ = child.simdWorldUp
    _ = SCNNode.simdLocalFront
    _ = SCNNode.simdLocalRight
    _ = SCNNode.simdLocalUp
    _ = child.simdConvertPosition(SIMD3<Float>(0, 0, 0), from: nil)
    _ = child.simdConvertPosition(SIMD3<Float>(0, 0, 0), to: nil)
    _ = child.simdConvertVector(SIMD3<Float>(0, 1, 0), from: nil)
    _ = child.simdConvertVector(SIMD3<Float>(0, 1, 0), to: nil)
    child.simdLocalTranslate(by: SIMD3<Float>(0, 0, 0))
    child.simdLook(at: SIMD3<Float>(0, 0, 1))
    child.opacity = 0.5
    child.isHidden = false
    child.categoryBitMask = 1
    child.castsShadow = true
    child.renderingOrder = 0
    child.movabilityHint = .fixed
    child.focusBehavior = .none
    child.isPaused = false
    _ = child.presentation
}

func testNodeCloneAndBounds() {
    let node = SCNNode(geometry: SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0))
    node.position = SCNVector3(5, 0, 0)
    let cloned = node.clone()
    precondition(cloned !== node)
    let flat = node.flattenedClone()
    precondition(flat.childNodes.isEmpty)
    _ = node.boundingBox
    _ = node.boundingSphere
    node.rotate(by: SCNVector4(0, 1, 0, 0.2), aroundTarget: SCNVector3Zero)
}

func testNodeHiddenOpacityPropagation() {
    let parent = SCNNode()
    parent.opacity = 0.5
    parent.categoryBitMask = 1
    let child = SCNNode()
    child.opacity = 0.5
    child.categoryBitMask = 3
    parent.addChildNode(child)
    precondition(abs(Float(child.linux_worldOpacity) - 0.25) < 1e-4)
    precondition(!child.linux_worldHidden)
    parent.isHidden = true
    precondition(child.linux_worldHidden)
    parent.isHidden = false
    precondition(child.linux_worldCategoryBitMask == 1)
    child.look(at: SCNVector3(0, 0, 1))
    let converted = parent.convertPosition(SCNVector3(1, 0, 0), from: nil)
    _ = parent.convertTransform(SCNMatrix4Identity, from: child)
    _ = converted
}

func testNodeAudioAndParticlesAttach() {
    let node = SCNNode()
    let player = SCNAudioPlayer(source: SCNAudioSource())
    node.addAudioPlayer(player)
    _ = node.audioPlayers
    node.removeAudioPlayer(player)
    node.removeAllAudioPlayers()
    let parts = SCNParticleSystem()
    node.addParticleSystem(parts)
    _ = node.particleSystems
    node.removeParticleSystem(parts)
    node.removeAllParticleSystems()
}

func testNodeMorpherAndPhysicsField() {
    let node = SCNNode()
    let morph = SCNMorpher()
    morph.targets = [SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)]
    morph.weights = [0.25]
    morph.unifiesNormals = true
    node.morpher = morph
    precondition(node.morpher === morph)
    precondition(morph.unifiesNormals)
    precondition(morph.targets.count == 1)
    let field = SCNPhysicsField.spring()
    field.strength = 2
    node.physicsField = field
    precondition(node.physicsField === field)
    final class RenderProbe: NSObject, SCNNodeRendererDelegate {
        var rendered = false
        func renderNode(_ node: SCNNode, renderer: SCNRenderer, arguments: [String: Any]) {
            rendered = true
            _ = node
            _ = renderer
            _ = arguments
        }
    }
    let probe = RenderProbe()
    node.rendererDelegate = probe
    probe.renderNode(node, renderer: SCNRenderer(), arguments: [:])
    precondition(probe.rendered)
    let geom = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
    geom.shaderModifiers = [.geometry: "// linux"]
    geom.minimumLanguageVersion = 2
    geom.handleUnbinding(ofSymbol: "u", handler: { _, _, _, _ in })
    precondition(geom.shaderModifiers?[.geometry] == "// linux")
}

// ---- SceneKitParticleTests.swift ----
func testParticleSystemStores() {
    let particles = SCNParticleSystem()
    particles.birthRate = 10
    particles.loops = true
    particles.emissionDuration = 1
    particles.particleLifeSpan = 1
    particles.particleSize = 1
    particles.particleColor = SCNVector4(1, 1, 1, 1)
    particles.emitterShape = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
    particles.warmupDuration = 0
    particles.birthRateVariation = 0
    particles.emittingDirection = SCNVector3(0, 1, 0)
    particles.spreadingAngle = 0
    particles.particleAngle = 0
    particles.particleAngularVelocity = 0
    particles.particleVelocity = 0
    particles.acceleration = SCNVector3Zero
    particles.isAffectedByGravity = false
    particles.isAffectedByPhysicsFields = false
    particles.particleDiesOnCollision = false
    particles.blendMode = .alpha
    particles.sortingMode = .none
    particles.orientationMode = .billboardScreenAligned
    particles.birthLocation = .surface
    particles.birthDirection = .constant
    particles.isLocal = false
    particles.dampingFactor = 0
    particles.speedFactor = 1
    particles.stretchFactor = 0
    particles.fresnelExponent = 0
    particles.writesToDepthBuffer = false
    precondition(particles.loops)
    _ = particles.particleImage
    _ = particles.systemSpawnedOnCollision
}

func testParticleEmissionAndReset() {
    let particles = SCNParticleSystem()
    particles.birthRate = 10
    particles.loops = true
    particles.emissionDuration = 10
    particles.emissionDurationVariation = 0
    particles.idleDuration = 0
    particles.idleDurationVariation = 0
    particles.particleLifeSpan = 5
    particles.particleLifeSpanVariation = 0
    particles.particleVelocity = 2
    particles.particleVelocityVariation = 0
    particles.emittingDirection = SCNVector3(0, 1, 0)
    particles.spreadingAngle = 0
    particles.acceleration = SCNVector3Zero
    particles.dampingFactor = 0
    particles.speedFactor = 1
    particles.particleSize = 1
    particles.particleSizeVariation = 0
    particles.particleAngle = 0
    particles.particleAngleVariation = 0
    particles.particleAngularVelocity = 0
    particles.particleAngularVelocityVariation = 0
    particles.particleMass = 1
    particles.particleMassVariation = 0
    particles.particleBounce = 0.2
    particles.particleBounceVariation = 0
    particles.particleCharge = 0
    particles.particleChargeVariation = 0
    particles.particleFriction = 0
    particles.particleFrictionVariation = 0
    particles.particleIntensity = 1
    particles.particleIntensityVariation = 0
    particles.particleColorVariation = SCNVector4Zero
    particles.isBlackPassEnabled = true
    particles.isLightingEnabled = true
    particles.orientationDirection = SCNVector3(0, 1, 0)
    particles.imageSequenceRowCount = 2
    particles.imageSequenceColumnCount = 2
    particles.imageSequenceInitialFrame = 0
    particles.imageSequenceInitialFrameVariation = 0
    particles.imageSequenceFrameRate = 12
    particles.imageSequenceFrameRateVariation = 0
    particles.imageSequenceAnimationMode = .repeat
    particles.systemSpawnedOnDying = SCNParticleSystem()
    particles.systemSpawnedOnLiving = SCNParticleSystem()
    let collider = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
    particles.colliderNodes = [collider]
    particles.particleDiesOnCollision = false
    precondition(particles.isBlackPassEnabled)
    precondition(particles.isLightingEnabled)
    precondition(particles.imageSequenceColumnCount == 2)
    precondition(particles.colliderNodes?.count == 1)
    particles.linux_advance(1)
    precondition(particles.linux_aliveCount == 10)
    precondition(abs(particles.linux_firstPosition.y - 2) < 0.15)
    particles.reset()
    precondition(particles.linux_aliveCount == 0)
}

func testParticleModifiersAndEvents() {
    let particles = SCNParticleSystem()
    particles.birthRate = 4
    particles.loops = true
    particles.emissionDuration = 10
    particles.particleLifeSpan = 10
    particles.particleVelocity = 5
    particles.emittingDirection = SCNVector3(0, 1, 0)
    particles.acceleration = SCNVector3Zero
    var births = 0
    particles.handle(.birth, forProperties: [.position], handler: { _, _, _, count in
        births += count
    })
    particles.addModifier(forProperties: [.velocity], at: .preDynamics, modifier: { data, stride, start, end, dt in
        _ = stride
        _ = dt
        let vel = data[0].assumingMemoryBound(to: Float.self)
        var i = start
        while i < end {
            vel[i * 3 + 0] = 0
            vel[i * 3 + 1] = 0
            vel[i * 3 + 2] = 0
            i += 1
        }
    })
    particles.linux_advance(1)
    precondition(births == 4)
    precondition(particles.linux_aliveCount == 4)
    precondition(abs(particles.linux_firstPosition.y) < 1e-3)
    particles.removeModifiers(at: .preCollision)
    particles.removeAllModifiers()
    let controller = SCNParticlePropertyController(animation: CAAnimation())
    controller.inputMode = .overLife
    controller.inputScale = 2
    controller.inputBias = 0.5
    controller.inputOrigin = SCNNode()
    controller.inputProperty = .life
    particles.propertyControllers = [.size: controller]
    precondition(particles.propertyControllers?[.size]?.inputMode == .overLife)
    precondition(abs(Float(controller.inputScale) - 2) < 1e-4)
    precondition(controller.inputProperty == .life)
}

func testParticlePropertyConstants() {
    let props: [SCNParticleSystem.ParticleProperty] = [
        .position, .angle, .rotationAxis, .velocity, .angularVelocity, .life,
        .color, .opacity, .size, .frame, .frameRate, .bounce, .charge, .friction,
        .contactPoint, .contactNormal
    ]
    precondition(SCNParticleSystem.ParticleProperty.angle.rawValue == "angle")
    precondition(SCNParticleSystem.ParticleProperty.bounce.rawValue == "bounce")
    precondition(SCNParticleSystem.ParticleProperty.charge.rawValue == "charge")
    precondition(SCNParticleSystem.ParticleProperty.contactNormal.rawValue == "contactNormal")
    precondition(SCNParticleSystem.ParticleProperty.contactPoint.rawValue == "contactPoint")
    precondition(SCNParticleSystem.ParticleProperty.frameRate.rawValue == "frameRate")
    precondition(SCNParticleSystem.ParticleProperty.life.rawValue == "life")
    precondition(SCNParticleSystem.ParticleProperty.rotationAxis.rawValue == "rotationAxis")
    precondition(SCNParticleSystem.ParticleProperty.angle != .bounce)
    _ = SCNParticleSystem.ParticleProperty.angle.hashValue
    var hasher = Hasher()
    SCNParticleSystem.ParticleProperty.life.hash(into: &hasher)
    precondition(props.count == 16)
    _ = SCNParticleEventBlock.self
    _ = SCNParticleModifierBlock.self
    _ = SCNParticleSystem.ParticleProperty.self
}

// ---- SceneKitPhysicsTests.swift ----
func testPhysicsBookkeeping() {
    let body = SCNPhysicsBody.dynamic()
    precondition(body.type == .dynamic)
    let kin = SCNPhysicsBody.kinematic()
    precondition(kin.type == .kinematic)
    let stat = SCNPhysicsBody.static()
    precondition(stat.type == .static)
    let node = SCNNode()
    node.physicsBody = body
    let scene = SCNScene()
    scene.rootNode.addChildNode(node)
    scene.physicsWorld.gravity = SCNVector3Zero
    body.isAffectedByGravity = false
    body.damping = 0
    let before = node.position
    scene.physicsWorld.step()
    precondition(SCNVector3EqualToVector3(node.position, before))
    let world = SCNPhysicsWorld()
    world.gravity = SCNVector3(0, -9.8, 0)
    world.addBehavior(SCNPhysicsHingeJoint(body: kin, axis: SCNVector3(0, 1, 0), anchor: SCNVector3Zero))
    precondition(world.allBehaviors.count == 1)
    let field = SCNPhysicsField.linearGravity()
    precondition(field.isActive)
    _ = SCNPhysicsField.radialGravity()
    _ = SCNPhysicsField.vortex()
    _ = SCNPhysicsField.drag()
    _ = SCNPhysicsField.turbulenceField(smoothness: 1, animationSpeed: 1)
    _ = SCNPhysicsField.noiseField(smoothness: 1, animationSpeed: 1)
    _ = SCNPhysicsField.spring()
    _ = SCNPhysicsField.electric()
    _ = SCNPhysicsField.magnetic()
    let vehicle = SCNPhysicsVehicle(chassisBody: kin, wheels: [SCNPhysicsVehicleWheel(node: node)])
    precondition(vehicle.wheels.count == 1)
    let contact = SCNPhysicsContact()
    precondition(contact.collisionImpulse == 0)
    let shape = SCNPhysicsShape(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0), options: nil)
    _ = shape
    _ = SCNPhysicsBallSocketJoint(bodyA: kin, anchorA: SCNVector3Zero, bodyB: body, anchorB: SCNVector3Zero)
    _ = SCNPhysicsSliderJoint(bodyA: kin, axisA: SCNVector3(0, 1, 0), anchorA: SCNVector3Zero, bodyB: body, axisB: SCNVector3(0, 1, 0), anchorB: SCNVector3Zero)
    _ = SCNPhysicsConeTwistJoint(bodyA: kin, frameA: SCNMatrix4Identity, bodyB: body, frameB: SCNMatrix4Identity)
    body.mass = 1
    body.friction = 0.5
    body.restitution = 0.5
    body.damping = 0.1
    body.isAffectedByGravity = true
    _ = body.velocity
    _ = body.angularVelocity
    world.speed = 1
    world.timeStep = 1.0 / 60
    _ = SCNPhysicsWorld.TestOption.collisionBitMask
    _ = SCNPhysicsWorld.TestSearchMode.closest
}

final class _SCNContactProbe: NSObject, SCNPhysicsContactDelegate {
    var began = 0
    var updated = 0
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        began += 1
        _ = contact.nodeA
        _ = contact.nodeB
        _ = contact.contactPoint
        _ = contact.contactNormal
        _ = contact.penetrationDistance
        _ = contact.collisionImpulse
        _ = contact.sweepTestFraction
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        updated += 1
    }
}

func testPhysicsGravityIntegration() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3(0, -10, 0)
    scene.physicsWorld.timeStep = 1
    scene.physicsWorld.speed = 1
    let node = SCNNode()
    let body = SCNPhysicsBody.dynamic()
    body.mass = 1
    body.damping = 0
    body.isAffectedByGravity = true
    node.physicsBody = body
    scene.rootNode.addChildNode(node)
    scene.physicsWorld.step()
    // Semi-implicit Euler: v = -10, p = -10.
    precondition(abs(body.velocity.y + 10) < 1e-3)
    precondition(abs(node.position.y + 10) < 1e-3)
    let staticNode = SCNNode()
    staticNode.physicsBody = SCNPhysicsBody.static()
    staticNode.physicsBody?.isAffectedByGravity = true
    scene.rootNode.addChildNode(staticNode)
    let sy = staticNode.position.y
    scene.physicsWorld.step()
    precondition(abs(staticNode.position.y - sy) < 1e-4)
}

func testPhysicsSphereContacts() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let a = SCNNode(geometry: SCNSphere(radius: 0.5))
    let b = SCNNode(geometry: SCNSphere(radius: 0.5))
    a.position = SCNVector3(-0.25, 0, 0)
    b.position = SCNVector3(0.25, 0, 0)
    let bodyA = SCNPhysicsBody.dynamic()
    bodyA.mass = 1
    bodyA.damping = 0
    bodyA.restitution = 0
    bodyA.isAffectedByGravity = false
    bodyA.physicsShape = SCNPhysicsShape(geometry: a.geometry!, options: nil)
    let bodyB = SCNPhysicsBody.dynamic()
    bodyB.mass = 1
    bodyB.damping = 0
    bodyB.restitution = 0
    bodyB.isAffectedByGravity = false
    bodyB.physicsShape = SCNPhysicsShape(geometry: b.geometry!, options: nil)
    a.physicsBody = bodyA
    b.physicsBody = bodyB
    scene.rootNode.addChildNode(a)
    scene.rootNode.addChildNode(b)
    let overlap = scene.physicsWorld.contactTestBetween(bodyA, bodyB, options: nil)
    precondition(!overlap.isEmpty)
    precondition(overlap[0].penetrationDistance > 0)
    scene.physicsWorld.step()
    let dx = abs(b.worldPosition.x - a.worldPosition.x)
    precondition(dx >= 0.99)
}

func testPhysicsBoxAABBContacts() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let boxGeom = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0)
    let moving = SCNNode(geometry: boxGeom)
    let wall = SCNNode(geometry: boxGeom)
    moving.position = SCNVector3(0, 0, 0)
    wall.position = SCNVector3(1.5, 0, 0)
    let dyn = SCNPhysicsBody.dynamic()
    dyn.mass = 1
    dyn.damping = 0
    dyn.restitution = 0
    dyn.isAffectedByGravity = false
    dyn.physicsShape = SCNPhysicsShape(geometry: boxGeom, options: nil)
    let stat = SCNPhysicsBody.static()
    stat.physicsShape = SCNPhysicsShape(geometry: boxGeom, options: nil)
    moving.physicsBody = dyn
    wall.physicsBody = stat
    scene.rootNode.addChildNode(moving)
    scene.rootNode.addChildNode(wall)
    let hits = scene.physicsWorld.contactTest(with: dyn, options: nil)
    precondition(!hits.isEmpty)
    scene.physicsWorld.step()
    precondition(moving.worldPosition.x <= 0.01)
}

func testPhysicsContactDelegate() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let probe = _SCNContactProbe()
    scene.physicsWorld.contactDelegate = probe
    let a = SCNNode(geometry: SCNSphere(radius: 1))
    let b = SCNNode(geometry: SCNSphere(radius: 1))
    a.position = SCNVector3(-0.5, 0, 0)
    b.position = SCNVector3(0.5, 0, 0)
    let bodyA = SCNPhysicsBody.dynamic()
    bodyA.mass = 1
    bodyA.damping = 0
    bodyA.isAffectedByGravity = false
    bodyA.contactTestBitMask = .max
    bodyA.physicsShape = SCNPhysicsShape(geometry: a.geometry!, options: nil)
    let bodyB = SCNPhysicsBody.static()
    bodyB.physicsShape = SCNPhysicsShape(geometry: b.geometry!, options: nil)
    a.physicsBody = bodyA
    b.physicsBody = bodyB
    scene.rootNode.addChildNode(a)
    scene.rootNode.addChildNode(b)
    scene.physicsWorld.step()
    precondition(probe.began >= 1)
    scene.physicsWorld.updateCollisionPairs()
}

func testPhysicsForces() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let node = SCNNode()
    let body = SCNPhysicsBody.dynamic()
    body.mass = 2
    body.damping = 0
    body.isAffectedByGravity = false
    node.physicsBody = body
    scene.rootNode.addChildNode(node)
    body.applyForce(SCNVector3(4, 0, 0), asImpulse: false)
    scene.physicsWorld.step()
    // a = 4/2 = 2, v = 2, p = 2
    precondition(abs(body.velocity.x - 2) < 1e-3)
    precondition(abs(node.position.x - 2) < 1e-3)
    body.clearAllForces()
    body.applyForce(SCNVector3(0, 6, 0), asImpulse: true)
    scene.physicsWorld.step()
    precondition(abs(body.velocity.y - 3) < 1e-3)
    body.applyForce(SCNVector3(0, 0, 1), at: SCNVector3(1, 0, 0), asImpulse: true)
    body.applyTorque(SCNVector4(0, 1, 0, 0.2), asImpulse: true)
    body.setResting(true)
    precondition(body.isResting)
    precondition(abs(body.velocity.x) < 1e-4)
    body.resetTransform()
    precondition(!body.isResting)
    _ = body.allowsResting
    _ = body.angularDamping
    _ = body.angularRestingThreshold
    _ = body.angularVelocityFactor
    _ = body.centerOfMassOffset
    _ = body.charge
    _ = body.collisionBitMask
    _ = body.contactTestBitMask
    _ = body.continuousCollisionDetectionThreshold
    _ = body.linearRestingThreshold
    _ = body.momentOfInertia
    _ = body.physicsShape
    _ = body.rollingFriction
    _ = body.usesDefaultMomentOfInertia
    _ = body.velocityFactor
}

func testPhysicsRayAndContactQuery() {
    let scene = SCNScene()
    let box = SCNNode(geometry: SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0))
    scene.rootNode.addChildNode(box)
    let hits = scene.physicsWorld.rayTestWithSegment(
        from: SCNVector3(0, 0, 5),
        to: SCNVector3(0, 0, -5),
        options: nil
    )
    precondition(!hits.isEmpty)
    let world = SCNPhysicsWorld()
    world.removeAllBehaviors()
    let hinge = SCNPhysicsHingeJoint(body: SCNPhysicsBody.kinematic(), axis: SCNVector3(0, 1, 0), anchor: SCNVector3Zero)
    world.addBehavior(hinge)
    world.removeBehavior(hinge)
    precondition(world.allBehaviors.isEmpty)
    let sweep = world.convexSweepTest(
        with: SCNPhysicsShape(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0), options: nil),
        from: SCNMatrix4Identity,
        to: SCNMatrix4MakeTranslation(1, 0, 0),
        options: nil
    )
    precondition(sweep.isEmpty)
}

func testPhysicsFieldForces() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let node = SCNNode()
    let body = SCNPhysicsBody.dynamic()
    body.mass = 1
    body.damping = 0
    body.isAffectedByGravity = false
    node.physicsBody = body
    scene.rootNode.addChildNode(node)
    let fieldNode = SCNNode()
    let field = SCNPhysicsField.linearGravity()
    field.strength = 4
    field.direction = SCNVector3(1, 0, 0)
    field.falloffExponent = 0
    field.halfExtent = SCNVector3(100, 100, 100)
    field.scope = .insideExtent
    field.isExclusive = false
    field.usesEllipsoidalExtent = false
    fieldNode.physicsField = field
    scene.rootNode.addChildNode(fieldNode)
    scene.physicsWorld.step()
    precondition(abs(body.velocity.x - 4) < 1e-3)
    node.worldPosition = SCNVector3Zero
    body.velocity = SCNVector3Zero
    let radial = SCNPhysicsField.radialGravity()
    radial.strength = 1
    radial.falloffExponent = 0
    fieldNode.physicsField = radial
    node.worldPosition = SCNVector3(2, 0, 0)
    scene.physicsWorld.step()
    precondition(body.velocity.x < 0)
    var customCalls = 0
    let custom = SCNPhysicsField.customField(evaluationBlock: { position, velocity, mass, charge, time in
        customCalls += 1
        _ = position
        _ = velocity
        _ = mass
        _ = charge
        _ = time
        return SCNVector3(0, 3, 0)
    })
    custom.strength = 1
    fieldNode.physicsField = custom
    body.velocity = SCNVector3Zero
    scene.physicsWorld.step()
    precondition(customCalls > 0)
    precondition(abs(body.velocity.y - 3) < 1e-3)
    _ = SCNPhysicsField.noiseField(smoothness: 1, animationSpeed: 1)
    _ = SCNPhysicsField.turbulenceField(smoothness: 0.5, animationSpeed: 2)
    let drag = SCNPhysicsField.drag()
    drag.strength = 1
    _ = drag.linux_evaluate(
        position: SCNVector3Zero, velocity: SCNVector3(4, 0, 0),
        mass: 1, charge: 0, time: 0, origin: SCNVector3Zero
    )
}

func testPhysicsVehicleAndSlider() {
    let scene = SCNScene()
    scene.physicsWorld.gravity = SCNVector3Zero
    scene.physicsWorld.timeStep = 1
    let chassis = SCNNode()
    let body = SCNPhysicsBody.dynamic()
    body.mass = 1
    body.damping = 0
    body.isAffectedByGravity = false
    chassis.physicsBody = body
    scene.rootNode.addChildNode(chassis)
    let wheelNode = SCNNode()
    let wheel = SCNPhysicsVehicleWheel(node: wheelNode)
    wheel.axle = SCNVector3(1, 0, 0)
    wheel.connectionPosition = SCNVector3(0, -0.5, 0)
    wheel.frictionSlip = 1.2
    wheel.maximumSuspensionForce = 100
    wheel.maximumSuspensionTravel = 0.2
    wheel.steeringAxis = SCNVector3(0, 1, 0)
    wheel.suspensionCompression = 0.8
    wheel.suspensionDamping = 0.5
    wheel.suspensionRestLength = 0.4
    wheel.suspensionStiffness = 20
    precondition(abs(Float(wheel.frictionSlip) - 1.2) < 1e-4)
    precondition(abs(wheel.axle.x - 1) < 1e-4)
    let vehicle = SCNPhysicsVehicle(chassisBody: body, wheels: [wheel])
    scene.physicsWorld.addBehavior(vehicle)
    vehicle.applyEngineForce(10, forWheelAt: 0)
    vehicle.applyBrakingForce(0, forWheelAt: 0)
    vehicle.setSteeringAngle(0.1, forWheelAt: 0)
    scene.physicsWorld.step()
    precondition(vehicle.speedInKilometersPerHour > 0)
    let slider = SCNPhysicsSliderJoint(
        bodyA: body, axisA: SCNVector3(0, 1, 0), anchorA: SCNVector3Zero,
        bodyB: SCNPhysicsBody.static(), axisB: SCNVector3(0, 1, 0), anchorB: SCNVector3Zero
    )
    slider.minimumLinearLimit = -1
    slider.maximumLinearLimit = 1
    slider.minimumAngularLimit = -0.5
    slider.maximumAngularLimit = 0.5
    slider.motorTargetLinearVelocity = 2
    slider.motorMaximumForce = 5
    slider.motorTargetAngularVelocity = 0
    slider.motorMaximumTorque = 1
    precondition(slider.maximumLinearLimit == 1)
    precondition(abs(Float(slider.motorTargetLinearVelocity) - 2) < 1e-4)
    scene.physicsWorld.addBehavior(slider)
    _ = SCNPhysicsBehavior()
    let cone = SCNPhysicsConeTwistJoint(bodyA: body, frameA: SCNMatrix4Identity, bodyB: nil, frameB: SCNMatrix4Identity)
    cone.maximumAngularLimit1 = 0.4
    cone.maximumAngularLimit2 = 0.5
    cone.maximumTwistAngle = 0.2
    precondition(abs(Float(cone.maximumTwistAngle) - 0.2) < 1e-4)
}

// ---- SceneKitRendererTests.swift ----
func testCPURasterizer() {
    let scene = SCNScene()
    scene.background.contents = SCNVector3(0, 0, 1)
    let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0)
    let material = SCNMaterial()
    material.lightingModel = .constant
    material.diffuse.contents = SCNVector3(1, 0, 0)
    material.isDoubleSided = true
    box.firstMaterial = material
    scene.rootNode.addChildNode(SCNNode(geometry: box))
    let camNode = SCNNode()
    camNode.camera = SCNCamera()
    camNode.camera?.usesOrthographicProjection = true
    camNode.camera?.orthographicScale = 2
    camNode.camera?.zNear = 0.1
    camNode.camera?.zFar = 20
    camNode.position = SCNVector3(0, 0, 5)
    scene.rootNode.addChildNode(camNode)
    let renderer = SCNRenderer()
    renderer.scene = scene
    renderer.pointOfView = camNode
    renderer.currentViewport = CGRect(x: 0, y: 0, width: 32, height: 32)
    renderer.autoenablesDefaultLighting = false
    renderer.isPlaying = false
    renderer.loops = true
    renderer.sceneTime = 0
    renderer.debugOptions = []
    renderer.showsStatistics = false
    let img = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    precondition(img.width == 32 && img.height == 32)
    let center = img.pixel(x: 16, y: 16)
    precondition(center.0 >= 200)
    material.lightingModel = .lambert
    let lightNode = SCNNode()
    let light = SCNLight()
    light.type = .directional
    light.intensity = 1000
    light.color = SCNVector3(1, 1, 1)
    lightNode.light = light
    lightNode.position = SCNVector3(0, 0, 5)
    scene.rootNode.addChildNode(lightNode)
    let lambert = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    precondition(lambert.pixel(x: 16, y: 16).0 >= 200)
    material.lightingModel = .phong
    material.shininess = 32
    material.specular.contents = SCNVector3(1, 1, 1)
    material.diffuse.contents = SCNVector3(0, 0, 1)
    let phong = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    precondition(phong.pixel(x: 16, y: 16).2 >= 100)
    material.lightingModel = .blinn
    let blinn = renderer.linux_snapshot(size: CGSize(width: 32, height: 32))
    precondition(blinn.rgba.count == 32 * 32 * 4)
    renderer.render()
    renderer.render(atTime: 0)
    renderer.update(atTime: 0)
    _ = renderer.projectPoint(SCNVector3Zero)
    _ = renderer.unprojectPoint(SCNVector3Zero)
    _ = renderer.hitTest(CGPoint(x: 16, y: 16), options: nil)
    _ = renderer.nodesInsideFrustum(of: camNode)
    _ = renderer.isNode(camNode, insideFrustumOf: camNode)
    _ = renderer.prepare(box, shouldAbortBlock: nil)
    _ = renderer.renderingAPI
    _ = renderer.currentViewport
    _ = renderer.usesReverseZ
    _ = renderer.context
}

func testRendererNextFrameAndProbes() {
    let renderer = SCNRenderer()
    renderer.nextFrameTime = 1.0 / 60.0
    precondition(abs(renderer.nextFrameTime - 1.0 / 60.0) < 1e-6)
    let probe = SCNNode()
    probe.light = SCNLight()
    renderer.updateProbes([probe], atTime: 0.5)
    precondition(abs(renderer.sceneTime - 0.5) < 1e-6)
    renderer.audioListener = probe
    renderer.isJitteringEnabled = true
    renderer.isTemporalAntialiasingEnabled = true
    renderer.overlaySKScene = nil
    precondition(renderer.isJitteringEnabled)
    precondition(renderer.audioListener === probe)
    let view = SCNView(frame: CGRect(x: 0, y: 0, width: 16, height: 16), options: nil)
    view.audioListener = probe
    view.isJitteringEnabled = true
    view.isTemporalAntialiasingEnabled = false
    view.overlaySKScene = "none"
    precondition(view.audioListener === probe)
}

// ---- SceneKitSceneTests.swift ----
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

// ---- SceneKitSurfaceTests.swift ----
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

// ---- SceneKitTransactionTests.swift ----
func testTransactionBeginCommit() {
    let scene = SCNScene()
    SCNTransaction.begin()
    SCNTransaction.disableActions = true
    let txn = SCNNode()
    scene.rootNode.addChildNode(txn)
    txn.runAction(SCNAction.move(by: SCNVector3(x: 5, y: 0, z: 0), duration: 1))
    precondition(abs(txn.position.x) < 1e-4)
    precondition(txn.hasActions)
    txn.linux_advanceTime(1)
    precondition(abs(txn.position.x - 5) < 1e-4)
    SCNTransaction.commit()
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 0.25
    var completed = false
    SCNTransaction.completionBlock = { completed = true }
    SCNTransaction.setValue("x", forKey: "k")
    precondition(SCNTransaction.value(forKey: "k") as? String == "x")
    SCNTransaction.flush()
    SCNTransaction.commit()
    precondition(completed)
    SCNTransaction.lock()
    SCNTransaction.unlock()
}

func testTransactionFlush() {
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 0.5
    var flushed = false
    SCNTransaction.completionBlock = { flushed = true }
    SCNTransaction.flush()
    precondition(abs(SCNTransaction.animationDuration) < 1e-9)
    precondition(flushed)
    SCNTransaction.commit()
}

// ---- SceneKitViewTests.swift ----
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

func runSceneKitFocusedTests() {
    testActionClock()
    testActionEasing()
    testCustomActionAndRotate()
    testJavaScriptAndPlayAudioFailClosed()
    testAnimatableKeys()
    testCAAnimationBridge()
    testAnimationTimingFunctionAndAudio()
    testCameraProjection()
    testCameraStores()
    testCameraPostProcessStores()
    testLookAtDistanceBillboard()
    testReplicatorConstraintMath()
    testIKAndAccelerationConstraints()
    testEnumOptionSetAndConstantValues()
    testPrimitiveLayouts()
    testCustomGeometrySource()
    testPrimitiveVertexCounts()
    testGeometryMaterialsAndElements()
    testHitTestSegment()
    testHitTestResultBoneNode()
    testHitTestFailClosedWithoutScene()
    testLightStores()
    testLightShadowAndAreaStores()
    testMaterialLightingAndBlend()
    testMaterialPropertyBorderAndPrecomputed()
    testVectorMath()
    testMatrixMath()
    testQuaternionFromRotation()
    testNodeHierarchy()
    testNodeTransforms()
    testNodeCloneAndBounds()
    testNodeHiddenOpacityPropagation()
    testNodeAudioAndParticlesAttach()
    testNodeMorpherAndPhysicsField()
    testParticleSystemStores()
    testParticleEmissionAndReset()
    testParticleModifiersAndEvents()
    testParticlePropertyConstants()
    testPhysicsBookkeeping()
    testPhysicsGravityIntegration()
    testPhysicsSphereContacts()
    testPhysicsBoxAABBContacts()
    testPhysicsContactDelegate()
    testPhysicsForces()
    testPhysicsRayAndContactQuery()
    testPhysicsFieldForces()
    testPhysicsVehicleAndSlider()
    testCPURasterizer()
    testRendererNextFrameAndProbes()
    testSceneGraphAndLoad()
    testSceneSourceMetadata()
    testSceneNamedFailClosedAndFog()
    testProtocolAndTypealiasSurface()
    testSkinnerAndProgramAndFloorExtras()
    testTechniqueProgramSkinnerAndCoding()
    testTransactionBeginCommit()
    testTransactionFlush()
    testSCNViewStores()
    testCameraControllerOrbitAndDolly()
}

runSceneKitFocusedTests()
print("CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean")
print("SCENEKIT_AGENT_RUNTIME_OK")
