import Foundation

open class SKReachConstraints: NSObject, NSSecureCoding, NSCopying {
    public var lowerAngleLimit: CGFloat
    public var upperAngleLimit: CGFloat

    public init(lowerAngleLimit: CGFloat, upperAngleLimit: CGFloat) {
        self.lowerAngleLimit = lowerAngleLimit
        self.upperAngleLimit = upperAngleLimit
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) {
        lowerAngleLimit = CGFloat(coder.decodeDouble(forKey: "lower"))
        upperAngleLimit = CGFloat(coder.decodeDouble(forKey: "upper"))
        super.init()
    }
    public func encode(with coder: NSCoder) {
        coder.encode(Double(lowerAngleLimit), forKey: "lower")
        coder.encode(Double(upperAngleLimit), forKey: "upper")
    }
    public func copy(with zone: NSZone? = nil) -> Any {
        SKReachConstraints(lowerAngleLimit: lowerAngleLimit, upperAngleLimit: upperAngleLimit)
    }
}

open class SKNode: NSObject, NSSecureCoding, NSCopying {
    public var name: String?
    public var position: CGPoint = .zero
    public var zPosition: CGFloat = 0
    public var zRotation: CGFloat = 0
    public var xScale: CGFloat = 1
    public var yScale: CGFloat = 1
    public var alpha: CGFloat = 1
    public var speed: CGFloat = 1
    public var isHidden: Bool = false
    public var isPaused: Bool = false
    public var isUserInteractionEnabled: Bool = false
    public var isFocused: Bool = false
    public var focusBehavior: SKNodeFocusBehavior = .none
    public var userData: NSMutableDictionary?
    public var constraints: [SKConstraint]?
    public var reachConstraints: SKReachConstraints?
    public var attributeValues: [String: SKAttributeValue] = [:]
    public var subdivisionLevels: Int = 0
    public var warpGeometry: SKWarpGeometry?
    public var physicsBody: SKPhysicsBody? {
        didSet { physicsBody?._node = self }
    }

    weak var _parent: SKNode?
    var _children: [SKNode] = []
    var _actions: [String: _SKActionRuntime] = [:]
    var _anonymousActions: [_SKActionRuntime] = []
    weak var _scene: SKScene?

    public override init() { super.init() }

    public convenience init?(fileNamed filename: String) {
        _ = filename
        return nil
    }

    public convenience init(fileNamed filename: String, securelyWithClasses classes: Set<AnyHashable>) throws {
        _ = classes
        throw SKArchiveError.unsupported(filename)
    }

    public required init?(coder: NSCoder) {
        super.init()
        name = coder.decodeObject(forKey: "name") as? String
        position.x = CGFloat(coder.decodeDouble(forKey: "x"))
        position.y = CGFloat(coder.decodeDouble(forKey: "y"))
        zRotation = CGFloat(coder.decodeDouble(forKey: "zRotation"))
        xScale = CGFloat(coder.decodeDouble(forKey: "xScale"))
        yScale = CGFloat(coder.decodeDouble(forKey: "yScale"))
        alpha = CGFloat(coder.decodeDouble(forKey: "alpha"))
        if alpha == 0 && !coder.containsValue(forKey: "alpha") { alpha = 1 }
        if xScale == 0 && !coder.containsValue(forKey: "xScale") { xScale = 1 }
        if yScale == 0 && !coder.containsValue(forKey: "yScale") { yScale = 1 }
    }

    public func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(Double(position.x), forKey: "x")
        coder.encode(Double(position.y), forKey: "y")
        coder.encode(Double(zRotation), forKey: "zRotation")
        coder.encode(Double(xScale), forKey: "xScale")
        coder.encode(Double(yScale), forKey: "yScale")
        coder.encode(Double(alpha), forKey: "alpha")
    }

    public static var supportsSecureCoding: Bool { true }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKNode()
        copy.name = name
        copy.position = position
        copy.zPosition = zPosition
        copy.zRotation = zRotation
        copy.xScale = xScale
        copy.yScale = yScale
        copy.alpha = alpha
        copy.speed = speed
        copy.isHidden = isHidden
        copy.isPaused = isPaused
        copy.focusBehavior = focusBehavior
        for child in _children {
            copy.addChild(child.copy() as! SKNode)
        }
        return copy
    }

    public var parent: SKNode? { _parent }
    public var children: [SKNode] { _children }

    public var scene: SKScene? {
        if let owned = self as? SKScene { return owned }
        if let cached = _scene { return cached }
        return _parent?.scene
    }

    public var frame: CGRect {
        CGRect(x: position.x - 0.5, y: position.y - 0.5, width: 1, height: 1)
    }

    public func calculateAccumulatedFrame() -> CGRect {
        var box = frame
        for child in _children where !child.isHidden {
            let childBox = child.calculateAccumulatedFrame()
            box = box.union(childBox)
        }
        return box
    }

    public func setScale(_ scale: CGFloat) {
        xScale = scale
        yScale = scale
    }

    public func addChild(_ node: SKNode) {
        guard node !== self, !node.inParentHierarchy(self), !inParentHierarchy(node) else { return }
        node.removeFromParent()
        node._parent = self
        node._attachScene(scene)
        _children.append(node)
    }

    public func insertChild(_ node: SKNode, at index: Int) {
        guard node !== self, !node.inParentHierarchy(self) else { return }
        node.removeFromParent()
        node._parent = self
        node._attachScene(scene)
        let clamped = max(0, min(index, _children.count))
        _children.insert(node, at: clamped)
    }

    public func removeFromParent() {
        guard let parent = _parent else { return }
        parent._children.removeAll { $0 === self }
        _parent = nil
        _attachScene(nil)
    }

    public func removeAllChildren() {
        for child in _children {
            child._parent = nil
            child._attachScene(nil)
        }
        _children.removeAll()
    }

    public func removeChildren(in nodes: [SKNode]) {
        for node in nodes {
            if node._parent === self {
                node.removeFromParent()
            }
        }
    }

    public func move(toParent parent: SKNode) {
        let world = convert(CGPoint.zero, to: nil)
        removeFromParent()
        parent.addChild(self)
        position = parent._worldToLocal(world)
    }

    public func inParentHierarchy(_ parent: SKNode) -> Bool {
        var cursor = _parent
        while let node = cursor {
            if node === parent { return true }
            cursor = node._parent
        }
        return false
    }

    public func childNode(withName name: String) -> SKNode? {
        if name.hasPrefix("//") {
            let needle = String(name.dropFirst(2))
            return _recursiveChild(named: needle)
        }
        if name.hasPrefix("/") {
            return childNode(withName: String(name.dropFirst()))
        }
        return _children.first { $0.name == name }
    }

    public subscript(name: String) -> [SKNode] {
        if name.hasPrefix("//") {
            let needle = String(name.dropFirst(2))
            var found: [SKNode] = []
            _collect(named: needle, into: &found)
            return found
        }
        return _children.filter { $0.name == name }
    }

    public func enumerateChildNodes(
        withName name: String,
        using block: @escaping (SKNode, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        var stop = ObjCBool(false)
        let matches = self[name.hasPrefix("//") ? name : "//" + name]
        for node in matches {
            block(node, &stop)
            if stop.boolValue { break }
        }
    }

    public func contains(_ p: CGPoint) -> Bool {
        frame.contains(p)
    }

    public func atPoint(_ p: CGPoint) -> SKNode {
        let hits = nodes(at: p)
        return hits.last ?? self
    }

    public func nodes(at p: CGPoint) -> [SKNode] {
        var hits: [SKNode] = []
        if contains(p) { hits.append(self) }
        for child in _children where !child.isHidden {
            let local = child.convert(p, from: self)
            hits.append(contentsOf: child.nodes(at: local))
        }
        return hits
    }

    public func intersects(_ node: SKNode) -> Bool {
        frame.intersects(node.frame)
    }

    public func isEqual(to node: SKNode) -> Bool {
        self === node
    }

    public func convert(_ point: CGPoint, from node: SKNode) -> CGPoint {
        let world = node._localToWorld(point)
        return _worldToLocal(world)
    }

    public func convert(_ point: CGPoint, to node: SKNode?) -> CGPoint {
        let world = _localToWorld(point)
        if let node {
            return node._worldToLocal(world)
        }
        return world
    }

    public func setValue(_ value: SKAttributeValue, forAttribute key: String) {
        attributeValues[key] = value
    }

    public func value(forAttributeNamed key: String) -> SKAttributeValue? {
        attributeValues[key]
    }

    public func run(_ action: SKAction) {
        let runtime = _SKActionRuntime(action: action, key: nil)
        _anonymousActions.append(runtime)
    }

    public func run(_ action: SKAction) async {
        let runtime = _SKActionRuntime(action: action, key: nil)
        _anonymousActions.append(runtime)
    }

    public func run(_ action: SKAction, withKey key: String) {
        _actions[key] = _SKActionRuntime(action: action, key: key)
    }

    public func action(forKey key: String) -> SKAction? {
        _actions[key]?.action
    }

    public func hasActions() -> Bool {
        !_actions.isEmpty || !_anonymousActions.isEmpty
    }

    public func removeAction(forKey key: String) {
        _actions.removeValue(forKey: key)
    }

    public func removeAllActions() {
        _actions.removeAll()
        _anonymousActions.removeAll()
    }

    func _attachScene(_ scene: SKScene?) {
        _scene = scene
        for child in _children {
            child._attachScene(scene)
        }
    }

    func _recursiveChild(named name: String) -> SKNode? {
        for child in _children {
            if child.name == name { return child }
            if let found = child._recursiveChild(named: name) { return found }
        }
        return nil
    }

    func _collect(named name: String, into found: inout [SKNode]) {
        for child in _children {
            if child.name == name { found.append(child) }
            child._collect(named: name, into: &found)
        }
    }

    func _ancestors() -> [SKNode] {
        var list: [SKNode] = []
        var cursor: SKNode? = self
        while let node = cursor {
            list.append(node)
            cursor = node._parent
        }
        return list.reversed()
    }

    func _localToWorld(_ point: CGPoint) -> CGPoint {
        var x = point.x
        var y = point.y
        var cursor: SKNode? = self
        while let node = cursor {
            let scaledX = x * node.xScale
            let scaledY = y * node.yScale
            let c = CGFloat(cos(Double(node.zRotation)))
            let s = CGFloat(sin(Double(node.zRotation)))
            let rx = scaledX * c - scaledY * s
            let ry = scaledX * s + scaledY * c
            x = rx + node.position.x
            y = ry + node.position.y
            cursor = node._parent
        }
        return CGPoint(x: x, y: y)
    }

    func _worldToLocal(_ point: CGPoint) -> CGPoint {
        var chain: [SKNode] = []
        var cursor: SKNode? = self
        while let node = cursor {
            chain.append(node)
            cursor = node._parent
        }
        var x = point.x
        var y = point.y
        for node in chain.reversed() {
            x -= node.position.x
            y -= node.position.y
            let c = CGFloat(cos(Double(-node.zRotation)))
            let s = CGFloat(sin(Double(-node.zRotation)))
            let rx = x * c - y * s
            let ry = x * s + y * c
            let sx = node.xScale == 0 ? 0 : rx / node.xScale
            let sy = node.yScale == 0 ? 0 : ry / node.yScale
            x = sx
            y = sy
        }
        return CGPoint(x: x, y: y)
    }

    func _evaluateActions(dt: TimeInterval) {
        guard !isPaused else { return }
        let scaled = dt * TimeInterval(speed)
        for runtime in _anonymousActions {
            runtime.step(on: self, dt: scaled)
        }
        _anonymousActions.removeAll { $0.finished || $0.cancelled }
        for runtime in _actions.values {
            runtime.step(on: self, dt: scaled)
        }
        for key in _actions.keys.filter({ _actions[$0]?.finished == true || _actions[$0]?.cancelled == true }) {
            _actions.removeValue(forKey: key)
        }
        for child in _children {
            child._evaluateActions(dt: scaled)
        }
    }

    func _applyConstraints() {
        guard let constraints, !constraints.isEmpty else {
            for child in _children { child._applyConstraints() }
            return
        }
        for constraint in constraints where constraint.enabled {
            constraint._apply(to: self)
        }
        for child in _children { child._applyConstraints() }
    }
}

extension SKNode: SKWarpable {}

enum SKArchiveError: Error {
    case unsupported(String)
}
