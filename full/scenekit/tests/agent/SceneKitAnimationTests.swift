import Foundation
import SceneKit

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
