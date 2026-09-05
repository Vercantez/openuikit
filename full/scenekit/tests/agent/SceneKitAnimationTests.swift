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
