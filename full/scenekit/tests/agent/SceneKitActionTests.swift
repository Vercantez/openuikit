import Foundation
import SceneKit

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
