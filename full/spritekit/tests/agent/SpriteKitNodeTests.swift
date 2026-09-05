import Foundation
import SpriteKit

func testNodeHierarchy() {
    let parent = SKNode()
    parent.name = "parent"
    let child = SKNode()
    child.name = "child"
    parent.addChild(child)
    precondition(child.parent === parent)
    precondition(parent.children.count == 1)
    precondition(parent.childNode(withName: "child") === child)
    parent.addChild(parent)
    precondition(parent.children.filter { $0 === parent }.isEmpty)
    let extra = SKNode()
    extra.name = "extra"
    parent.insertChild(extra, at: 0)
    precondition(parent.children.first === extra)
    extra.removeFromParent()
    precondition(extra.parent == nil)
    parent.removeChildren(in: [child])
    precondition(parent.children.isEmpty)
    parent.addChild(child)
    parent.removeAllChildren()
    precondition(parent.children.isEmpty)
}

func testNodeSearchAndConvert() {
    let root = SKNode()
    root.name = "root"
    let a = SKNode()
    a.name = "a"
    let b = SKNode()
    b.name = "b"
    root.addChild(a)
    a.addChild(b)
    a.position = CGPoint(x: 10, y: 0)
    b.position = CGPoint(x: 5, y: 0)
    precondition(root.childNode(withName: "//b") === b)
    precondition(root["//b"].count == 1)
    var seen = 0
    root.enumerateChildNodes(withName: "//a") { _, _ in seen += 1 }
    precondition(seen == 1)
    let world = b.convert(CGPoint.zero, to: nil)
    precondition(abs(world.x - 15) < 0.001)
    let local = root.convert(world, from: b)
    _ = local
    precondition(root.inParentHierarchy(b) == false)
    precondition(b.inParentHierarchy(root))
    let dest = SKNode()
    b.move(toParent: dest)
    precondition(b.parent === dest)
}

func testNodeFrameAndHitTest() {
    let node = SKSpriteNode(color: .red, size: CGSize(width: 20, height: 10))
    node.position = CGPoint(x: 0, y: 0)
    precondition(node.contains(CGPoint.zero))
    precondition(node.nodes(at: .zero).contains { $0 === node })
    _ = node.atPoint(.zero)
    _ = node.calculateAccumulatedFrame()
    let other = SKSpriteNode(color: .blue, size: CGSize(width: 20, height: 10))
    precondition(node.intersects(other))
    precondition(node.isEqual(to: node))
    precondition(!node.isEqual(to: other))
}

func testNodeUserState() {
    let node = SKNode()
    node.alpha = 0.5
    node.speed = 2
    node.isHidden = true
    node.isPaused = true
    node.isUserInteractionEnabled = true
    node.isFocused = true
    node.focusBehavior = .focusable
    node.zPosition = 4
    node.setScale(3)
    precondition(node.xScale == 3 && node.yScale == 3)
    node.userData = NSMutableDictionary(dictionary: ["k": "v"])
    let reach = SKReachConstraints(lowerAngleLimit: -1, upperAngleLimit: 1)
    node.reachConstraints = reach
    precondition(node.reachConstraints?.upperAngleLimit == 1)
    let attr = SKAttributeValue(float: 2)
    node.setValue(attr, forAttribute: "gain")
    precondition(node.value(forAttributeNamed: "gain")?.floatValue == 2)
    node.attributeValues["gain"] = SKAttributeValue(float: 3)
    precondition(node.attributeValues["gain"]?.floatValue == 3)
}

func testNodeCodingAndCopy() {
    let node = SKNode()
    node.name = "coded"
    node.position = CGPoint(x: 2, y: 3)
    let data = try! NSKeyedArchiver.archivedData(withRootObject: node, requiringSecureCoding: true)
    let decoded = try? NSKeyedUnarchiver.unarchivedObject(ofClass: SKNode.self, from: data)
    precondition(decoded?.name == "coded")
    let copy = node.copy() as! SKNode
    precondition(copy.name == "coded")
    precondition(SKNode(fileNamed: "missing") == nil)
}

func testNodeFileLoadFailsClosed() {
    do {
        _ = try SKNode(fileNamed: "scene.sks", securelyWithClasses: [])
        precondition(false, "named archive must fail closed")
    } catch {
        _ = error
    }
}
