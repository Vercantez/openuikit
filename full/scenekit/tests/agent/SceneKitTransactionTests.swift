import Foundation
import SceneKit

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
