import Foundation
import GameplayKit

// --- GameplayKitAgentTests.swift ---

private final class RecordingDelegate: NSObject, GKAgentDelegate {
    var will = 0
    var did = 0
    func agentWillUpdate(_ agent: GKAgent) {
        will += 1
        _ = agent
    }
    func agentDidUpdate(_ agent: GKAgent) {
        did += 1
    }
}

func testAgentSeekAndProperties() {
    let seeker = GKAgent2D()
    seeker.maxSpeed = 10
    seeker.maxAcceleration = 20
    seeker.mass = 1
    seeker.radius = 0.4
    precondition(seeker.radius == 0.4)
    let target = GKAgent2D()
    target.position = SIMD2<Float>(5, 0)
    let delegate = RecordingDelegate()
    seeker.delegate = delegate
    seeker.behavior = GKBehavior(goal: GKGoal(toSeekAgent: target), weight: 1)
    let before = seeker.position.x
    seeker.update(deltaTime: 0.5)
    precondition(seeker.position.x > before)
    precondition(delegate.will == 1 && delegate.did == 1)
    _ = seeker.velocity
    _ = seeker.rotation
    _ = seeker.speed

    let agent3 = GKAgent3D()
    agent3.rightHanded = false
    precondition(agent3.rightHanded == false)
    agent3.position = SIMD3<Float>(0, 0, 0)
    let target3 = GKAgent3D()
    target3.position = SIMD3<Float>(4, 0, 0)
    agent3.maxSpeed = 8
    agent3.maxAcceleration = 12
    agent3.behavior = GKBehavior(goal: GKGoal(toSeekAgent: target3), weight: 1)
    let beforeZ = agent3.position.x
    agent3.update(deltaTime: 0.5)
    precondition(agent3.position.x >= beforeZ)
    _ = agent3.velocity
}

func testBehaviorWeightsAndComposite() {
    let goal = GKGoal(toWander: 3)
    let behavior = GKBehavior(goal: goal, weight: 2)
    precondition(behavior.goalCount == 1)
    precondition(behavior.weight(for: goal) == 2)
    precondition(behavior[0] === goal)
    precondition(behavior[goal].floatValue == 2)
    behavior.setWeight(4, for: goal)
    precondition(behavior.weight(for: goal) == 4)
    let second = GKGoal(toReachTargetSpeed: 5)
    let many = GKBehavior(goals: [goal, second])
    precondition(many.goalCount == 2)
    let weighted = GKBehavior(goals: [goal], andWeights: [NSNumber(value: 1.5)])
    precondition(weighted.weight(for: goal) == 1.5)
    let map = GKBehavior(weightedGoals: [goal: NSNumber(value: 0.5)])
    precondition(map.weight(for: goal) == 0.5)
    behavior.remove(goal)
    precondition(behavior.goalCount == 0)
    many.removeAllGoals()
    precondition(many.goalCount == 0)

    let child = GKBehavior(goal: GKGoal(toWander: 1), weight: 1)
    let composite = GKCompositeBehavior(behaviors: [child])
    precondition(composite.behaviorCount == 1)
    let firstBehavior: GKBehavior = composite[0]
    precondition(firstBehavior === child)
    precondition(composite[child].floatValue == 1)
    composite.setWeight(3, for: child)
    precondition(composite.weight(for: child) == 3)
    let weightedComposite = GKCompositeBehavior(
        behaviors: [child],
        andWeights: [NSNumber(value: 2)]
    )
    precondition(weightedComposite.behaviorCount == 1)
    composite.remove(child)
    precondition(composite.behaviorCount == 0)
    weightedComposite.removeAllBehaviors()
    precondition(weightedComposite.behaviorCount == 0)
}

func testGoalsPathAndObstacles() {
    let agent = GKAgent2D()
    let other = GKAgent2D()
    other.position = SIMD2<Float>(2, 0)
    _ = GKGoal(toSeekAgent: targetAgent())
    _ = GKGoal(toFleeAgent: other)
    _ = GKGoal(toAvoid: [other], maxPredictionTime: 1)
    _ = GKGoal(toAvoidAgents: [other], maxPredictionTime: 1)
    let circle = GKCircleObstacle(radius: 1)
    circle.position = SIMD2<Float>(1, 1)
    precondition(circle.radius == 1)
    _ = GKGoal(toAvoid: [circle], maxPredictionTime: 1)
    _ = GKGoal(toAvoidObstacles: [circle], maxPredictionTime: 1)
    _ = GKGoal(toSeparateFrom: [other], maxDistance: 4, maxAngle: 1)
    _ = GKGoal(toSeparateFromAgents: [other], maxDistance: 4, maxAngle: 1)
    _ = GKGoal(toAlignWith: [other], maxDistance: 4, maxAngle: 1)
    _ = GKGoal(toAlignWithAgents: [other], maxDistance: 4, maxAngle: 1)
    _ = GKGoal(toCohereWith: [other], maxDistance: 4, maxAngle: 1)
    _ = GKGoal(toCohereWithAgents: [other], maxDistance: 4, maxAngle: 1)
    _ = GKGoal(toReachTargetSpeed: 2)
    _ = GKGoal(toWander: 3)
    _ = GKGoal(toInterceptAgent: other, maxPredictionTime: 1)
    let path2 = GKPath(points: [SIMD2<Float>(0, 0), SIMD2<Float>(1, 0)], radius: 0.4, cyclical: false)
    precondition(path2.numPoints == 2)
    precondition(path2.radius == 0.4)
    precondition(path2.isCyclical == false)
    precondition(path2.float2(at: 1).x == 1)
    precondition(path2.point(at: 0) == SIMD2<Float>(0, 0))
    _ = GKGoal(toFollow: path2, maxPredictionTime: 1, forward: true)
    _ = GKGoal(toFollowPath: path2, maxPredictionTime: 1, forward: false)
    _ = GKGoal(toStayOn: path2, maxPredictionTime: 1)
    _ = GKGoal(toStayOnPath: path2, maxPredictionTime: 1)
    let path3 = GKPath(points: [SIMD3<Float>(0, 0, 0), SIMD3<Float>(0, 1, 0)], radius: 0.2, cyclical: true)
    precondition(path3.float3(at: 1).y == 1)
    precondition(path3.isCyclical)
    let a = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let b = GKGraphNode2D(point: SIMD2<Float>(1, 0))
    let fromGraph = GKPath(graphNodes: [a, b], radius: 0.3)
    precondition(fromGraph.numPoints == 2)
    let sphere = GKSphereObstacle(radius: 2)
    sphere.position = SIMD3<Float>(0, 1, 0)
    precondition(sphere.radius == 2)
    _ = agent
}

private func targetAgent() -> GKAgent2D {
    let agent = GKAgent2D()
    agent.position = SIMD2<Float>(3, 0)
    return agent
}
// --- GameplayKitCodingTests.swift ---

final class ArchiveHealthComponent: GKComponent {
    override class var supportsSecureCoding: Bool { true }
    var value: Int = 0

    convenience init(value: Int) {
        self.init()
        self.value = value
    }

    override init() {
        super.init()
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        ArchiveHealthComponent(value: value)
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Int64(value), forKey: "health.value")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        value = Int(coder.decodeInt64(forKey: "health.value"))
    }
}

func testLinuxArchiveRoundTrip() {
    do {
        let entity = GKEntity()
        entity.addComponent(ArchiveHealthComponent(value: 13))
        let entityData = try NSKeyedArchiver.archivedData(withRootObject: entity, requiringSecureCoding: true)
        let entityDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKEntity.self, from: entityData)
        precondition(entityDecoded?.component(ofType: ArchiveHealthComponent.self)?.value == 13)
        precondition(entityDecoded?.component(ofType: ArchiveHealthComponent.self)?.entity === entityDecoded)

        let a = GKGraphNode2D(point: SIMD2<Float>(0, 0))
        let b = GKGraphNode2D(point: SIMD2<Float>(2, 0))
        a.addConnections(to: [b], bidirectional: true)
        let graph = GKGraph(nodes: [a, b])
        let graphData = try NSKeyedArchiver.archivedData(withRootObject: graph, requiringSecureCoding: true)
        let graphDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKGraph.self, from: graphData)
        precondition(graphDecoded?.nodes?.count == 2)
        let decodedA = graphDecoded?.nodes?.first as? GKGraphNode2D
        let decodedB = graphDecoded?.nodes?.dropFirst().first as? GKGraphNode2D
        precondition(decodedA?.position == SIMD2<Float>(0, 0))
        precondition(decodedB?.position == SIMD2<Float>(2, 0))
        precondition(decodedA?.connectedNodes.count == 1)
        precondition(decodedA?.connectedNodes.first === decodedB)

        let wall = GKPolygonObstacle(points: [
            SIMD2<Float>(0, 0), SIMD2<Float>(1, 0), SIMD2<Float>(0, 1)
        ])
        let wallData = try NSKeyedArchiver.archivedData(withRootObject: wall, requiringSecureCoding: true)
        let wallDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKPolygonObstacle.self, from: wallData)
        precondition(wallDecoded?.vertexCount == 3)
        precondition(wallDecoded?.vertex(at: 1) == SIMD2<Float>(1, 0))

        let scene = GKScene()
        scene.addEntity(entity)
        scene.addGraph(graph, name: "main")
        let sceneData = try NSKeyedArchiver.archivedData(withRootObject: scene, requiringSecureCoding: true)
        let sceneDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKScene.self, from: sceneData)
        precondition(sceneDecoded?.entities.count == 1)
        precondition(sceneDecoded?.graphs["main"]?.nodes?.count == 2)

        let tree = GKDecisionTree(attribute: "color" as NSString)
        _ = tree.rootNode?.createBranch(value: 1, attribute: "go" as NSString)
        let treeData = try NSKeyedArchiver.archivedData(withRootObject: tree, requiringSecureCoding: true)
        let treeDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKDecisionTree.self, from: treeData)
        let action = treeDecoded?.findAction(forAnswers: ["color" as NSString: 1 as NSNumber]) as? NSString
        precondition(action == "go")

        let source = GKARC4RandomSource(seed: Data([1, 2, 3, 4, 5, 6, 7, 8]))
        _ = source.nextInt()
        let sourceData = try NSKeyedArchiver.archivedData(withRootObject: source, requiringSecureCoding: true)
        let sourceDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKARC4RandomSource.self, from: sourceData)
        precondition(sourceDecoded?.nextInt() == source.nextInt())
        let sourceCoder = try NSKeyedUnarchiver(forReadingFrom: sourceData)
        sourceCoder.requiresSecureCoding = true
        _ = GKRandomSource(coder: sourceCoder)
    } catch {
        preconditionFailure("linux archive round-trip failed: \(error)")
    }
}

func testMalformedArchiveRejected() {
    let garbage = Data([0xFF, 0x00, 0x01, 0x02, 0x03])
    do {
        let coder = try NSKeyedUnarchiver(forReadingFrom: garbage)
        coder.requiresSecureCoding = true
        precondition(GKEntity(coder: coder) == nil)
        precondition(GKComponent(coder: coder) == nil)
        precondition(GKScene(coder: coder) == nil)
        precondition(GKGraph(coder: coder) == nil)
        precondition(GKGraphNode(coder: coder) == nil)
        precondition(GKPolygonObstacle(coder: coder) == nil)
        precondition(GKDecisionTree(coder: coder) == nil)
    } catch {
        // Unarchiver may throw on garbage; that is still fail-closed.
    }

    do {
        let unrelated = try NSKeyedArchiver.archivedData(
            withRootObject: "nope" as NSString,
            requiringSecureCoding: true
        )
        let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKEntity.self, from: unrelated)
        precondition(decoded == nil)
    } catch {
        // Unrelated root rejected.
    }
}
// --- GameplayKitDecisionTests.swift ---

func testDecisionTreeFindActionAndBranches() {
    let decision = GKDecisionTree(attribute: "color" as NSString)
    precondition(decision.rootNode != nil)
    let go = decision.rootNode?.createBranch(value: 1, attribute: "go" as NSString)
    _ = decision.rootNode?.createBranch(weight: 2, attribute: "wait" as NSString)
    _ = decision.rootNode?.createBranch(predicate: NSPredicate(value: false), attribute: "skip" as NSString)
    _ = go
    let action = decision.findAction(forAnswers: ["color" as NSString: 1 as NSNumber]) as? NSString
    precondition(action == "go")
    _ = decision.randomSource
    decision.randomSource = GKARC4RandomSource(seed: Data([1]))

    let examples: [[any NSObjectProtocol]] = [["red" as NSString], ["blue" as NSString]]
    let tree = GKDecisionTree(
        examples: examples,
        actions: ["left" as NSString, "right" as NSString],
        attributes: ["color" as NSString]
    )
    _ = tree.findAction(forAnswers: [:])
}

func testDecisionTreeFailClosedImportExport() {
    let url = URL(fileURLWithPath: "/tmp/openuikit-missing.gktree")
    let imported = GKDecisionTree(url: url, error: nil)
    _ = imported.rootNode
    let alt = GKDecisionTree(URL: url, error: nil)
    _ = alt.rootNode
    let tree = GKDecisionTree(attribute: "root" as NSString)
    precondition(tree.export(to: url, error: nil) == false)
}
// --- GameplayKitEntityTests.swift ---

private final class HealthComponent: GKComponent {
    override class var supportsSecureCoding: Bool { true }
    var value: Int = 0
    var added = 0
    var removed = 0
    var updates = 0

    convenience init(value: Int) {
        self.init()
        self.value = value
    }

    override init() {
        super.init()
    }

    override func didAddToEntity() {
        added += 1
    }

    override func willRemoveFromEntity() {
        removed += 1
    }

    override func update(deltaTime seconds: TimeInterval) {
        updates += 1
        _ = seconds
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        HealthComponent(value: value)
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Int64(value), forKey: "health.value")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        value = Int(coder.decodeInt64(forKey: "health.value"))
    }
}

func testComponentOwnership() {
    let first = GKEntity()
    let second = GKEntity()
    let health = HealthComponent(value: 7)
    precondition(health.entity == nil)
    first.addComponent(health)
    precondition(health.entity === first)
    precondition(first.component(ofType: HealthComponent.self) === health)
    precondition(first.components.count == 1)
    second.addComponent(health)
    precondition(health.entity === second)
    precondition(first.component(ofType: HealthComponent.self) == nil)
    precondition(second.component(ofType: HealthComponent.self) === health)
    precondition(health.removed == 1)
    precondition(health.added == 2)

    let replacement = HealthComponent(value: 9)
    second.addComponent(replacement)
    precondition(second.component(ofType: HealthComponent.self) === replacement)
    precondition(health.entity == nil)
    precondition(second.components.count == 1)

    second.removeComponent(ofType: HealthComponent.self)
    precondition(second.component(ofType: HealthComponent.self) == nil)
    precondition(replacement.entity == nil)

    var host: GKEntity? = GKEntity()
    let orphan = HealthComponent(value: 1)
    host!.addComponent(orphan)
    host = nil
    precondition(orphan.entity == nil)
}

func testComponentSystemAndEntityUpdate() {
    let entity = GKEntity()
    let health = HealthComponent(value: 7)
    entity.addComponent(health)
    let system = GKComponentSystem<HealthComponent>(componentClass: HealthComponent.self)
    precondition(system.componentClass == HealthComponent.self)
    system.addComponent(foundIn: entity)
    precondition(system.components.count == 1)
    precondition(system[0] === health)
    precondition(system.classForGenericArgument(at: 0) == HealthComponent.self)
    entity.update(deltaTime: 0.016)
    precondition(health.updates == 1)
    system.update(deltaTime: 0.016)
    precondition(health.updates == 2)
    let extra = HealthComponent(value: 3)
    system.addComponent(extra)
    precondition(system.components.count == 2)
    system.removeComponent(extra)
    precondition(system.components.count == 1)
    system.removeComponent(foundIn: entity)
    precondition(system.components.isEmpty)
}
// --- GameplayKitEnumTests.swift ---

func testEnumAndOptionSetValues() {
    precondition(GKGameModelMaxScore == 1 << 24)
    precondition(GKGameModelMinScore == -(1 << 24))
    precondition(GKRTreeSplitStrategy.halve.rawValue == 0)
    precondition(GKRTreeSplitStrategy.linear.rawValue == 1)
    precondition(GKRTreeSplitStrategy.quadratic.rawValue == 2)
    precondition(GKRTreeSplitStrategy.reduceOverlap.rawValue == 3)
    precondition(GKRTreeSplitStrategy(rawValue: 0) == .halve)
    precondition(GKRTreeSplitStrategy(rawValue: 1) == .linear)
    precondition(GKRTreeSplitStrategy(rawValue: 2) == .quadratic)
    precondition(GKRTreeSplitStrategy(rawValue: 3) == .reduceOverlap)
    precondition(GKRTreeSplitStrategy(rawValue: 99) == nil)
    precondition(GKRTreeSplitStrategy.halve != .linear)
    var hasher = Hasher()
    GKRTreeSplitStrategy.halve.hash(into: &hasher)
    precondition(GKRTreeSplitStrategy.halve.hashValue == GKRTreeSplitStrategy.halve.hashValue)

    precondition(GKMeshGraphTriangulationMode.vertices.rawValue == 1)
    precondition(GKMeshGraphTriangulationMode.centers.rawValue == 2)
    precondition(GKMeshGraphTriangulationMode.edgeMidpoints.rawValue == 4)
    let empty = GKMeshGraphTriangulationMode()
    precondition(empty.isEmpty)
    precondition(GKMeshGraphTriangulationMode(rawValue: 0).isEmpty)
    var mode: GKMeshGraphTriangulationMode = [.vertices, .centers]
    precondition(mode.contains(.vertices))
    precondition(mode.contains(.centers))
    precondition(!mode.contains(.edgeMidpoints))
    let inserted = mode.insert(.edgeMidpoints)
    precondition(inserted.inserted)
    precondition(mode.contains(.edgeMidpoints))
    let removed = mode.remove(.centers)
    precondition(removed == .centers)
    _ = mode.update(with: .vertices)
    precondition(mode.union(.centers).contains(.centers))
    precondition(mode.intersection(.vertices).contains(.vertices))
    precondition(!mode.symmetricDifference(.vertices).contains(.vertices))
    mode.formUnion(.centers)
    mode.formIntersection([.vertices, .centers])
    mode.formSymmetricDifference(.edgeMidpoints)
    precondition(mode.isSubset(of: [.vertices, .centers, .edgeMidpoints]))
    let pair: GKMeshGraphTriangulationMode = [.vertices, .centers]
    precondition(pair.isSuperset(of: .vertices))
    precondition(!mode.isDisjoint(with: .vertices) || mode.contains(.edgeMidpoints))
    precondition(GKMeshGraphTriangulationMode.vertices.isStrictSubset(of: [.vertices, .centers]))
    precondition(pair.isStrictSuperset(of: .vertices))
    var subtractable: GKMeshGraphTriangulationMode = [.vertices, .centers]
    subtractable.subtract(.centers)
    precondition(subtractable == .vertices)
    precondition(GKMeshGraphTriangulationMode.vertices.subtracting(.vertices).isEmpty)
    let fromSequence = GKMeshGraphTriangulationMode([.vertices, .edgeMidpoints])
    precondition(fromSequence.contains(.vertices))
    let literal: GKMeshGraphTriangulationMode = [.centers]
    precondition(literal == .centers)
    precondition(mode != empty)
}

func testGeometryValueTypes() {
    let zeroBox = GKBox()
    precondition(zeroBox.boxMin == SIMD3<Float>(0, 0, 0))
    precondition(zeroBox.boxMax == SIMD3<Float>(0, 0, 0))
    let box = GKBox(boxMin: SIMD3<Float>(-1, -2, -3), boxMax: SIMD3<Float>(1, 2, 3))
    precondition(box.boxMin.x == -1)
    precondition(box.boxMax.z == 3)
    precondition(box != zeroBox)

    let zeroQuad = GKQuad()
    precondition(zeroQuad.quadMin == SIMD2<Float>(0, 0))
    precondition(zeroQuad.quadMax == SIMD2<Float>(0, 0))
    let quad = GKQuad(quadMin: SIMD2<Float>(-2, -3), quadMax: SIMD2<Float>(4, 5))
    precondition(quad.quadMin.y == -3)
    precondition(quad.quadMax.x == 4)

    let zeroTriangle = GKTriangle()
    precondition(zeroTriangle.points.0 == SIMD3<Float>(0, 0, 0))
    let triangle = GKTriangle(points: (
        SIMD3<Float>(1, 0, 0),
        SIMD3<Float>(0, 1, 0),
        SIMD3<Float>(0, 0, 1)
    ))
    precondition(triangle.points.1.y == 1)
    precondition(triangle == triangle)
}
// --- GameplayKitMeshTests.swift ---

func testMeshTriangulation() {
    let wall = GKPolygonObstacle(points: [
        SIMD2<Float>(2, 2), SIMD2<Float>(3, 2), SIMD2<Float>(3, 3), SIMD2<Float>(2, 3)
    ])
    precondition(wall.vertexCount == 4)
    precondition(wall.vertex(at: 0) == SIMD2<Float>(2, 2))
    let mesh = GKMeshGraph<GKGraphNode2D>(
        bufferRadius: 0.1,
        minCoordinate: SIMD2<Float>(0, 0),
        maxCoordinate: SIMD2<Float>(4, 4)
    )
    precondition(mesh.bufferRadius == 0.1)
    mesh.triangulationMode = [.vertices, .centers]
    precondition(mesh.triangulationMode.contains(.vertices))
    mesh.addObstacles([wall])
    precondition(mesh.obstacles.count == 1)
    mesh.triangulate()
    precondition(mesh.triangleCount > 0)
    let triangle = mesh.triangle(at: 0)
    _ = triangle.points.0
    let extra = GKGraphNode2D(point: SIMD2<Float>(0.2, 0.2))
    mesh.connectUsingObstacles(node: extra)
    mesh.removeObstacles([wall])
    _ = mesh.classForGenericArgument(at: 0)
    let withClass = GKMeshGraph<GKGraphNode2D>(
        bufferRadius: 0.2,
        minCoordinate: SIMD2<Float>(0, 0),
        maxCoordinate: SIMD2<Float>(2, 2),
        nodeClass: GKGraphNode2D.self
    )
    _ = GKMeshGraph<GKGraphNode2D>(nodes: [GKGraphNode2D(point: SIMD2<Float>(0, 0))])
    _ = withClass.bufferRadius
}

func testObstacleGraphConnectionsAndLocks() {
    let wall = GKPolygonObstacle(points: [
        SIMD2<Float>(2, 2), SIMD2<Float>(3, 2), SIMD2<Float>(3, 3), SIMD2<Float>(2, 3)
    ])
    let obstacles = GKObstacleGraph<GKGraphNode2D>(obstacles: [wall], bufferRadius: 0.1)
    precondition(obstacles.obstacles.count == 1)
    precondition(obstacles.bufferRadius == 0.1)
    let extra = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    obstacles.connectUsingObstacles(node: extra)
    let other = GKGraphNode2D(point: SIMD2<Float>(4, 0))
    obstacles.connectUsingObstacles(node: other, ignoring: [wall])
    let third = GKGraphNode2D(point: SIMD2<Float>(0, 4))
    obstacles.connectUsingObstacles(node: third, ignoringBufferRadiusOf: [wall])
    obstacles.lockConnection(from: extra, to: extra)
    precondition(obstacles.isConnectionLocked(from: extra, to: extra))
    obstacles.unlockConnection(from: extra, to: extra)
    _ = obstacles.nodes(for: wall)
    obstacles.addObstacles([])
    obstacles.removeObstacles([wall])
    obstacles.removeAllObstacles()
    precondition(obstacles.obstacles.isEmpty)
    _ = obstacles.classForGenericArgument(at: 0)
    let withClass = GKObstacleGraph<GKGraphNode2D>(
        obstacles: [],
        bufferRadius: 0.5,
        nodeClass: GKGraphNode2D.self
    )
    _ = GKObstacleGraph<GKGraphNode2D>(nodes: [GKGraphNode2D(point: SIMD2<Float>(1, 1))])
    _ = withClass.bufferRadius
}
// --- GameplayKitNoiseTests.swift ---

func testNoiseSourcesDeterminism() {
    let perlin = GKPerlinNoiseSource(frequency: 1, octaveCount: 3, persistence: 0.5, lacunarity: 2, seed: 7)
    precondition(perlin.frequency == 1)
    precondition(perlin.octaveCount == 3)
    precondition(perlin.persistence == 0.5)
    precondition(perlin.lacunarity == 2)
    precondition(perlin.seed == 7)
    let noise = GKNoise(perlin)
    let n1 = noise.value(atPosition: SIMD2<Float>(0.2, 0.3))
    let n2 = GKNoise(GKPerlinNoiseSource(frequency: 1, octaveCount: 3, persistence: 0.5, lacunarity: 2, seed: 7))
        .value(atPosition: SIMD2<Float>(0.2, 0.3))
    precondition(n1 == n2)
    _ = GKNoise(noiseSource: perlin)

    let billow = GKBillowNoiseSource(frequency: 1, octaveCount: 2, persistence: 0.4, lacunarity: 2, seed: 1)
    precondition(billow.persistence == 0.4)
    _ = GKNoise(billow).value(atPosition: SIMD2<Float>(0.1, 0.1))
    let ridged = GKRidgedNoiseSource(frequency: 1, octaveCount: 2, lacunarity: 2, seed: 2)
    _ = GKNoise(ridged).value(atPosition: SIMD2<Float>(0.2, 0.1))
    let constant = GKConstantNoiseSource.constantNoise(withValue: 0.25)
    precondition(constant.value == 0.25)
    let namedConstant = GKConstantNoiseSource(value: -0.5)
    precondition(namedConstant.value == -0.5)
    precondition(GKNoise(namedConstant).value(atPosition: SIMD2<Float>(0, 0)) == Float(-0.5))
    precondition(GKNoise(constant).value(atPosition: SIMD2<Float>(0, 0)) == Float(0.25))
    let cylinders = GKCylindersNoiseSource.cylindersNoise(withFrequency: 2)
    precondition(cylinders.frequency == 2)
    _ = GKCylindersNoiseSource(frequency: 1)
    let spheres = GKSpheresNoiseSource.spheresNoise(withFrequency: 1)
    precondition(spheres.frequency == 1)
    _ = GKSpheresNoiseSource(frequency: 2)
    let checker = GKCheckerboardNoiseSource.checkerboardNoise(withSquareSize: 1)
    precondition(checker.squareSize == 1)
    _ = GKCheckerboardNoiseSource(squareSize: 2)
    _ = GKNoise(GKCheckerboardNoiseSource.checkerboardNoise(withSquareSize: 1))
        .value(atPosition: SIMD2<Float>(0.2, 0.2))
    let voronoi = GKVoronoiNoiseSource.voronoiNoise(
        withFrequency: 1,
        displacement: 0.5,
        distanceEnabled: true,
        seed: 4
    )
    precondition(voronoi.frequency == 1)
    precondition(voronoi.displacement == 0.5)
    precondition(voronoi.isDistanceEnabled)
    precondition(voronoi.seed == 4)
    _ = GKVoronoiNoiseSource(frequency: 1, displacement: 1, distanceEnabled: false, seed: 0)
    _ = GKCoherentNoiseSource()
    _ = GKNoiseSource()
    _ = GKNoise()
}

func testNoiseOperationsAndMaps() {
    let source = GKConstantNoiseSource(value: 0.4)
    let noise = GKNoise(source)
    let other = GKNoise(GKConstantNoiseSource(value: 0.2))
    noise.add(other)
    noise.multiply(other)
    noise.minimum(other)
    noise.maximum(other)
    noise.invert()
    noise.applyAbsoluteValue()
    noise.clamp(lowerBound: -0.5, upperBound: 0.5)
    noise.raiseToPower(2)
    noise.raiseToPower(other)
    noise.move(by: SIMD3<Double>(0.1, 0, 0))
    noise.scale(by: SIMD3<Double>(1, 1, 1))
    noise.rotate(by: SIMD3<Double>(0, 0, 0))
    noise.applyTurbulence(frequency: 1, power: 0.2, roughness: 1, seed: 3)
    noise.displaceWithNoises(x: other, y: other, z: other)
    noise.remapValues(toCurveWithControlPoints: [
        NSNumber(value: -1): NSNumber(value: 0),
        NSNumber(value: 1): NSNumber(value: 1)
    ])
    noise.remapValues(toTerracesWithPeaks: [NSNumber(value: -0.5), NSNumber(value: 0.5)], terracesInverted: false)
    _ = noise.value(atPosition: SIMD2<Float>(0.1, 0.2))

    let select = GKNoise(componentNoises: [GKNoise(source), other], selectionNoise: other)
    _ = select.value(atPosition: SIMD2<Float>(0, 0))
    let blended = GKNoise(
        componentNoises: [GKNoise(source), other],
        selectionNoise: other,
        componentBoundaries: [NSNumber(value: 0)],
        boundaryBlendDistances: [NSNumber(value: 0.1)]
    )
    _ = blended.value(atPosition: SIMD2<Float>(0, 0))

    let map = GKNoiseMap(
        noise,
        size: SIMD2<Double>(1, 1),
        origin: SIMD2<Double>(0, 0),
        sampleCount: SIMD2<Int32>(8, 8),
        seamless: false
    )
    precondition(map.sampleCount.x == 8)
    precondition(map.size.x == 1)
    precondition(map.origin.x == 0)
    precondition(map.isSeamless == false)
    _ = map.value(at: SIMD2<Int32>(0, 0))
    map.setValue(0.5, at: SIMD2<Int32>(0, 0))
    precondition(map.value(at: SIMD2<Int32>(0, 0)) == 0.5)
    _ = map.interpolatedValue(at: SIMD2<Float>(1.5, 1.5))
    _ = GKNoiseMap()
    _ = GKNoiseMap(noise)
    _ = GKNoiseMap(noise: noise)
    let named = GKNoiseMap(
        noise: noise,
        size: SIMD2<Double>(1, 1),
        origin: SIMD2<Double>(0, 0),
        sampleCount: SIMD2<Int32>(4, 8),
        seamless: true
    )
    precondition(named.isSeamless)
    _ = named.sampleCount.y
}
// --- GameplayKitPathfindingTests.swift ---

func testGraphAStarAndEdges() {
    let a = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let b = GKGraphNode2D(point: SIMD2<Float>(1, 0))
    let c = GKGraphNode2D(point: SIMD2<Float>(1, 1))
    a.addConnections(to: [b], bidirectional: true)
    b.addConnections(to: [c], bidirectional: true)
    precondition(a.connectedNodes.count == 1)
    let path = a.findPath(to: c)
    precondition(path.count == 3)
    precondition(c.findPath(from: a).count == 3)
    let graph = GKGraph(nodes: [a, b, c])
    precondition(graph.nodes?.count == 3)
    precondition(graph.findPath(from: a, to: c).count == 3)
    let extra = GKGraphNode2D.node(withPoint: SIMD2<Float>(2, 0))
    graph.add([extra])
    graph.connectToLowestCostNode(node: extra, bidirectional: true)
    precondition(!extra.connectedNodes.isEmpty)
    graph.remove([extra])

    let start = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    precondition(start.findPath(to: start).isEmpty)
    let cycleA = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let cycleB = GKGraphNode2D(point: SIMD2<Float>(1, 0))
    let cycleC = GKGraphNode2D(point: SIMD2<Float>(1, 1))
    cycleA.addConnections(to: [cycleB], bidirectional: true)
    cycleB.addConnections(to: [cycleC], bidirectional: true)
    cycleC.addConnections(to: [cycleA], bidirectional: true)
    let cyclic = cycleA.findPath(to: cycleC)
    precondition(cyclic.first === cycleA && cyclic.last === cycleC)
    precondition(cyclic.count >= 2)
    let disconnected = GKGraphNode2D(point: SIMD2<Float>(50, 50))
    precondition(a.findPath(to: disconnected).isEmpty)
    cycleA.removeConnections(to: [cycleB], bidirectional: true)
    precondition(cycleA.cost(to: cycleA) == 0)
    _ = cycleA.estimatedCost(to: cycleC)
    let viaInit = GKGraph([a, b])
    precondition(viaInit.nodes?.count == 2)
}

func testGridGraphLookupAndPath() {
    let grid = GKGridGraph<GKGridGraphNode>(
        fromGridStartingAt: SIMD2<Int32>(0, 0),
        width: 4,
        height: 4,
        diagonalsAllowed: false
    )
    precondition(grid.gridWidth == 4)
    precondition(grid.gridHeight == 4)
    precondition(grid.gridOrigin == SIMD2<Int32>(0, 0))
    precondition(grid.diagonalsAllowed == false)
    let start = grid.node(atGridPosition: SIMD2<Int32>(0, 0))
    let end = grid.node(atGridPosition: SIMD2<Int32>(3, 0))
    precondition(start != nil && end != nil)
    let gridPath = grid.findPath(from: start!, to: end!)
    precondition(gridPath.count == 4)
    let standalone = GKGridGraphNode(gridPosition: SIMD2<Int32>(1, 1))
    precondition(standalone.gridPosition.x == 1)
    grid.connectToAdjacentNodes(node: standalone)
    _ = grid.classForGenericArgument(at: 0)
    let withClass = GKGridGraph<GKGridGraphNode>(
        fromGridStartingAt: SIMD2<Int32>(0, 0),
        width: 2,
        height: 2,
        diagonalsAllowed: true,
        nodeClass: GKGridGraphNode.self
    )
    precondition(withClass.diagonalsAllowed)
    let fromNodes = GKGridGraph<GKGridGraphNode>(nodes: [standalone])
    precondition(fromNodes.nodes?.count == 1)
}

func testGraphNode3DAndCopyIndependence() {
    let node = GKGraphNode3D(point: SIMD3<Float>(1, 2, 3))
    precondition(node.position.z == 3)
    let factory = GKGraphNode3D.node(withPoint: SIMD3<Float>(4, 5, 6))
    precondition(factory.position.y == 5)
    let copy = node.copy() as! GKGraphNode3D
    copy.position = SIMD3<Float>(9, 9, 9)
    precondition(node.position == SIMD3<Float>(1, 2, 3))

    let a = GKGraphNode2D(point: SIMD2<Float>(3, 4))
    let nodeCopy = a.copy() as! GKGraphNode2D
    nodeCopy.position = SIMD2<Float>(9, 9)
    precondition(a.position == SIMD2<Float>(3, 4))
    let peer = GKGraphNode2D(point: SIMD2<Float>(1, 0))
    a.addConnections(to: [peer], bidirectional: true)
    let graph = GKGraph(nodes: [a, peer])
    let graphCopy = graph.copy() as! GKGraph
    let copyA = graphCopy.nodes?.first as? GKGraphNode2D
    copyA?.position = SIMD2<Float>(9, 9)
    precondition(a.position == SIMD2<Float>(3, 4))
    precondition(copyA?.connectedNodes.count == 1)
    precondition(copyA?.connectedNodes.first !== peer)
}
// --- GameplayKitRandomTests.swift ---

func testARC4SeedDeterminismAndCopy() {
    let seed = Data([1, 2, 3, 4, 5, 6, 7, 8])
    let arc4 = GKARC4RandomSource(seed: seed)
    precondition(arc4.seed == seed)
    let first = arc4.nextInt()
    let replay = GKARC4RandomSource(seed: seed)
    precondition(replay.nextInt() == first)
    let copy = arc4.copy() as! GKARC4RandomSource
    copy.dropValues(8)
    _ = copy.nextBool()
    let unadvanced = arc4.copy() as! GKARC4RandomSource
    precondition(arc4.nextInt() == unadvanced.nextInt())
    copy.dropValues(16)
    let fromCopy = copy.nextInt()
    let fromFresh = GKARC4RandomSource(seed: seed).nextInt()
    precondition(fromCopy != fromFresh)
    precondition(copy.seed == seed)
    let dropped = GKARC4RandomSource(seed: seed)
    dropped.dropValues(0)
    _ = GKARC4RandomSource()
    for _ in 0..<32 {
        let bound = arc4.nextInt(upperBound: 7)
        precondition(bound >= 0 && bound < 7)
    }
    precondition(arc4.nextInt(upperBound: 0) == 0)
    precondition(arc4.nextInt(upperBound: 1) == 0)
    let uniform = GKARC4RandomSource(seed: seed).nextUniform()
    precondition(uniform >= 0 && uniform < 1)
}

func testLCGAndMersenneDeterminism() {
    let lcg = GKLinearCongruentialRandomSource(seed: 42)
    let lcgA = lcg.nextInt()
    let lcg2 = GKLinearCongruentialRandomSource(seed: 42)
    precondition(lcg2.nextInt() == lcgA)
    precondition(GKLinearCongruentialRandomSource(seed: 42).seed == 42)
    _ = GKLinearCongruentialRandomSource()

    let mt = GKMersenneTwisterRandomSource(seed: 99)
    precondition(mt.seed == 99)
    let bounded = mt.nextInt(upperBound: 10)
    precondition(bounded >= 0 && bounded < 10)
    let replay = GKMersenneTwisterRandomSource(seed: 99)
    precondition(replay.nextInt() == GKMersenneTwisterRandomSource(seed: 99).nextInt())
    _ = GKMersenneTwisterRandomSource()
}

func testDistributionsAndShuffle() {
    let die = GKRandomDistribution.d6()
    let roll = die.nextInt()
    precondition(roll >= 1 && roll <= 6)
    let d20 = GKRandomDistribution.d20()
    for _ in 0..<16 {
        let value = d20.nextInt()
        precondition(value >= 1 && value <= 20)
    }
    let custom = GKRandomDistribution(lowestValue: 2, highestValue: 5)
    precondition(custom.lowestValue == 2)
    precondition(custom.highestValue == 5)
    precondition(custom.numberOfPossibleOutcomes == 4)
    let sides = GKRandomDistribution(forDieWithSideCount: 8)
    precondition(sides.lowestValue == 1 && sides.highestValue == 8)
    let sourced = GKRandomDistribution(
        randomSource: GKARC4RandomSource(seed: Data([9])),
        lowestValue: 1,
        highestValue: 4
    )
    _ = sourced.nextBool()
    let uniform = sourced.nextUniform()
    precondition(uniform >= 0 && uniform <= 1)
    _ = sourced.nextInt(upperBound: 3)

    let shuffled = GKShuffledDistribution(
        randomSource: GKARC4RandomSource(seed: Data([9])),
        lowestValue: 1,
        highestValue: 3
    )
    var seen = Set<Int>()
    for _ in 0..<3 { seen.insert(shuffled.nextInt()) }
    precondition(seen == Set([1, 2, 3]))

    let gaussianRange = GKGaussianDistribution(
        randomSource: GKLinearCongruentialRandomSource(seed: 3),
        lowestValue: 1,
        highestValue: 10
    )
    precondition(gaussianRange.mean == 5.5)
    let sample = gaussianRange.nextInt()
    precondition(sample >= 1 && sample <= 10)
    let gaussian = GKGaussianDistribution(
        randomSource: GKLinearCongruentialRandomSource(seed: 3),
        mean: 10,
        deviation: 2
    )
    precondition(gaussian.mean == 10)
    precondition(gaussian.deviation == 2)
    _ = gaussian.nextInt()

    let corpusObjects: [Any] = ["alpha", "beta", "gamma"]
    let shuffledObjects = GKMersenneTwisterRandomSource(seed: 99)
        .arrayByShufflingObjects(in: corpusObjects)
    let typed = shuffledObjects as? [String]
    precondition(typed?.count == 3)
    precondition(Set(typed ?? []) == Set(["alpha", "beta", "gamma"]))
    let array: NSArray = ["a", "b", "c", "d"]
    precondition(array.shuffled(using: GKARC4RandomSource(seed: Data([2]))).count == 4)
    precondition(array.shuffled().count == 4)
    _ = GKRandomSource.sharedRandom().nextInt(upperBound: 4)
    _ = GKRandomSource()
}

func testRandomProtocolNextValues() {
    let source: any GKRandom = GKARC4RandomSource(seed: Data([4, 5, 6, 7]))
    _ = source.nextInt()
    let bound = source.nextInt(upperBound: 5)
    precondition(bound >= 0 && bound < 5)
    let uniform = source.nextUniform()
    precondition(uniform >= 0 && uniform < 1)
    _ = source.nextBool()
}
// --- GameplayKitRulesTests.swift ---

private final class ProbePlayer: NSObject, GKGameModelPlayer {
    let playerId: Int
    init(id: Int) { self.playerId = id }
}

private final class ProbeUpdate: NSObject, GKGameModelUpdate {
    var value: Int = 0
    let delta: Int
    init(delta: Int) { self.delta = delta }
}

private final class ProbeModel: NSObject, GKGameModel {
    var players: [any GKGameModelPlayer]?
    var activePlayer: (any GKGameModelPlayer)?
    var scoreValue: Int

    init(score: Int, player: ProbePlayer) {
        self.scoreValue = score
        self.players = [player]
        self.activePlayer = player
    }

    func copy(with zone: NSZone? = nil) -> Any {
        ProbeModel(score: scoreValue, player: players?.first as! ProbePlayer)
    }

    func setGameModel(_ gameModel: any GKGameModel) {
        if let other = gameModel as? ProbeModel {
            scoreValue = other.scoreValue
        }
    }

    func gameModelUpdates(for player: any GKGameModelPlayer) -> [any GKGameModelUpdate]? {
        _ = player
        return [ProbeUpdate(delta: 4), ProbeUpdate(delta: -1)]
    }

    func apply(_ gameModelUpdate: any GKGameModelUpdate) {
        if let update = gameModelUpdate as? ProbeUpdate {
            scoreValue += update.delta
        }
    }

    func score(for player: any GKGameModelPlayer) -> Int {
        _ = player
        return scoreValue
    }

    func isWin(for player: any GKGameModelPlayer) -> Bool {
        _ = player
        return scoreValue >= 10
    }

    func isLoss(for player: any GKGameModelPlayer) -> Bool {
        _ = player
        return scoreValue < -10
    }

    func unapplyGameModelUpdate(_ gameModelUpdate: any GKGameModelUpdate) {
        if let update = gameModelUpdate as? ProbeUpdate {
            scoreValue -= update.delta
        }
    }
}

func testRuleSystemFactsAndAgenda() {
    let rules = GKRuleSystem()
    let fact = "ready" as NSString
    let other = "done" as NSString
    let rule = GKRule(blockPredicate: { _ in true }, action: { system in
        system.assertFact(fact)
    })
    rule.salience = 10
    precondition(rule.salience == 10)
    rules.add(rule)
    let extra = GKRule(blockPredicate: { _ in false }, action: { _ in })
    rules.add([extra])
    precondition(rules.rules.count == 2)
    rules.evaluate()
    precondition(rules.grade(forFact: fact) == 1)
    precondition(rules.facts.count == 1)
    precondition(rules.executed.count == 1)
    precondition(rules.agenda.count == 2)
    rules.assertFact(other, grade: 0.4)
    precondition(rules.grade(forFact: other) == 0.4)
    rules.retractFact(other, grade: 0.2)
    precondition(rules.grade(forFact: other) > 0)
    rules.retractFact(other)
    precondition(rules.maximumGrade(forFacts: [fact, other]) == 1)
    precondition(rules.minimumGrade(forFacts: [fact]) == 1)
    _ = rules.state
    rules.reset()
    precondition(rules.grade(forFact: fact) == 0)
    rules.removeAllRules()
    precondition(rules.rules.isEmpty)
}

func testNSPredicateRuleAndPredicateFactories() {
    let always = NSPredicate(value: true)
    let never = NSPredicate(value: false)
    let system = GKRuleSystem()
    let fact = "ok" as NSString
    let asserting = GKRule(predicate: always, assertingFact: fact, grade: 1)
    precondition(asserting.evaluatePredicate(in: system))
    asserting.performAction(in: system)
    precondition(system.grade(forFact: fact) == 1)
    let retracting = GKRule(predicate: always, retractingFact: fact, grade: 1)
    retracting.performAction(in: system)
    let predicateRule = GKNSPredicateRule(predicate: always)
    precondition(predicateRule.predicate == always)
    precondition(predicateRule.evaluatePredicate(in: system))
    let blocked = GKNSPredicateRule(predicate: never)
    precondition(!blocked.evaluatePredicate(in: system))
}

func testMinmaxAndMonteCarloStrategists() {
    let player = ProbePlayer(id: 1)
    let model = ProbeModel(score: 0, player: player)
    let minmax = GKMinmaxStrategist()
    minmax.gameModel = model
    minmax.maxLookAheadDepth = 2
    minmax.randomSource = GKARC4RandomSource(seed: Data([4]))
    precondition(minmax.maxLookAheadDepth == 2)
    let best = minmax.bestMove(for: player)
    precondition(best != nil)
    let random = minmax.randomMove(for: player, fromNumberOfBestMoves: 2)
    precondition(random != nil)
    let active = minmax.bestMoveForActivePlayer()
    precondition(active != nil)
    _ = model.score(for: player)
    _ = model.isWin(for: player)
    _ = model.isLoss(for: player)
    if let first = model.gameModelUpdates(for: player)?.first {
        model.apply(first)
        model.unapplyGameModelUpdate(first)
    }

    let monte = GKMonteCarloStrategist()
    monte.gameModel = model
    monte.budget = 8
    monte.explorationParameter = 2
    monte.randomSource = GKARC4RandomSource(seed: Data([5]))
    precondition(monte.budget == 8)
    precondition(monte.explorationParameter == 2)
    precondition(monte.bestMoveForActivePlayer() != nil)
    _ = player.playerId
    _ = (best as? ProbeUpdate)?.value
}
// --- GameplayKitSceneTests.swift ---

private final class DummyRoot: NSObject, GKSceneRootNodeType {}

func testSceneBookkeeping() {
    let scene = GKScene()
    let entity = GKEntity()
    scene.addEntity(entity)
    precondition(scene.entities.count == 1)
    let a = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let graph = GKGraph(nodes: [a])
    scene.addGraph(graph, name: "main")
    precondition(scene.graphs["main"] === graph)
    scene.removeGraph("main")
    precondition(scene.graphs["main"] == nil)
    scene.removeEntity(entity)
    precondition(scene.entities.isEmpty)
    let root = DummyRoot()
    scene.rootNode = root
    precondition(scene.rootNode === root)
    let copy = scene.copy() as! GKScene
    _ = copy.entities
}

func testSceneFileNamedFailClosed() {
    precondition(GKScene(fileNamed: "missing.gkscene") == nil)
    precondition(GKScene(fileNamed: "missing.gkscene", rootNode: DummyRoot()) == nil)
}
// --- GameplayKitSpatialTests.swift ---

func testOctreeQueries() {
    let box = GKBox(boxMin: SIMD3<Float>(-1, -1, -1), boxMax: SIMD3<Float>(1, 1, 1))
    let tree = GKOctree<NSString>(boundingBox: box, minimumCellSize: 0.5)
    let token = "token" as NSString
    let node = tree.add(token, at: SIMD3<Float>(0, 0, 0))
    precondition(tree.elements(at: SIMD3<Float>(0, 0, 0)).count == 1)
    _ = node.box
    let boxed = tree.add("box" as NSString, in: box)
    _ = boxed
    precondition(tree.elements(in: box).count >= 1)
    precondition(tree.remove(token))
    let keep = "keep" as NSString
    let again = tree.add(keep, at: SIMD3<Float>(0.1, 0, 0))
    precondition(tree.remove(keep, using: again))
}

func testQuadtreeQueries() {
    let quad = GKQuad(quadMin: SIMD2<Float>(-2, -2), quadMax: SIMD2<Float>(2, 2))
    let tree = GKQuadtree<NSString>(boundingQuad: quad, minimumCellSize: 0.5)
    let q = "q" as NSString
    let node = tree.add(q, in: GKQuad(quadMin: SIMD2<Float>(0, 0), quadMax: SIMD2<Float>(0.5, 0.5)))
    precondition(tree.elements(at: SIMD2<Float>(0.1, 0.1)).count == 1)
    precondition(node.quad.quadMin.x == 0)
    let p = "p" as NSString
    _ = tree.add(p, at: SIMD2<Float>(0.2, 0.2))
    precondition(tree.elements(in: quad).count >= 1)
    precondition(tree.remove(p))
    let k = "k" as NSString
    let kept = tree.add(k, at: SIMD2<Float>(0, 0))
    precondition(tree.remove(k, using: kept))
}

func testRTreeQueries() {
    let tree = GKRTree<NSString>(maxNumberOfChildren: 4)
    tree.queryReserve = 8
    precondition(tree.queryReserve == 8)
    tree.addElement(
        "r" as NSString,
        boundingRectMin: SIMD2<Float>(0, 0),
        boundingRectMax: SIMD2<Float>(1, 1),
        splitStrategy: .halve
    )
    tree.addElement(
        "linear" as NSString,
        boundingRectMin: SIMD2<Float>(2, 2),
        boundingRectMax: SIMD2<Float>(3, 3),
        splitStrategy: .linear
    )
    tree.addElement(
        "quad" as NSString,
        boundingRectMin: SIMD2<Float>(4, 2),
        boundingRectMax: SIMD2<Float>(5, 3),
        splitStrategy: .quadratic
    )
    tree.addElement(
        "overlap" as NSString,
        boundingRectMin: SIMD2<Float>(0.2, 0.2),
        boundingRectMax: SIMD2<Float>(0.4, 0.4),
        splitStrategy: .reduceOverlap
    )
    precondition(tree.elements(inBoundingRectMin: SIMD2<Float>(-1, -1), rectMax: SIMD2<Float>(2, 2)).count >= 1)
    tree.removeElement(
        "r" as NSString,
        boundingRectMin: SIMD2<Float>(0, 0),
        boundingRectMax: SIMD2<Float>(1, 1)
    )
}
// --- GameplayKitStateMachineTests.swift ---

private final class LoadState: GKState {
    var entered = false
    var exited = false
    var updated = 0
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == ReadyState.self
    }
    override func didEnter(from previousState: GKState?) {
        entered = true
    }
    override func willExit(to nextState: GKState) {
        exited = true
    }
    override func update(deltaTime seconds: TimeInterval) {
        updated += 1
        _ = seconds
    }
}

private final class ReadyState: GKState {
    var enteredFromLoad = false
    override func didEnter(from previousState: GKState?) {
        enteredFromLoad = previousState is LoadState
    }
}

private final class BounceState: GKState {
    var enterCount = 0
    override func didEnter(from previousState: GKState?) {
        enterCount += 1
        if enterCount == 1 {
            _ = stateMachine?.enter(LandState.self)
        }
    }
}

private final class LandState: GKState {
    var enterCount = 0
    override func didEnter(from previousState: GKState?) {
        enterCount += 1
    }
}

func testStateMachineTransitions() {
    let load = LoadState()
    let ready = ReadyState()
    let machine = GKStateMachine(states: [load, ready])
    precondition(load.stateMachine === machine)
    precondition(machine.currentState == nil)
    precondition(machine.enter(LoadState.self))
    precondition(machine.currentState === load)
    precondition(load.entered)
    precondition(machine.canEnterState(ReadyState.self))
    precondition(!machine.canEnterState(LoadState.self) || load.isValidNextState(ReadyState.self))
    precondition(machine.enter(ReadyState.self))
    precondition(ready.enteredFromLoad)
    precondition(load.exited)
    precondition(machine.state(forClass: LoadState.self) === load)
    precondition(machine.state(forClass: ReadyState.self) === ready)
}

func testStateMachineReentrantEnterAndUpdate() {
    let bounce = BounceState()
    let land = LandState()
    let reentrant = GKStateMachine(states: [bounce, land])
    precondition(reentrant.enter(BounceState.self))
    precondition(reentrant.currentState === land)
    precondition(bounce.enterCount == 1)
    precondition(land.enterCount == 1)
    reentrant.update(deltaTime: 0.016)
    let load = LoadState()
    let ready = ReadyState()
    let timed = GKStateMachine(states: [load, ready])
    precondition(timed.enter(LoadState.self))
    timed.update(deltaTime: 1)
    precondition(load.updated == 1)
    precondition(!timed.enter(NSObject.self))
    precondition(timed.canEnterState(ReadyState.self))
    precondition(!timed.canEnterState(NSString.self))
}

do {
    testAgentSeekAndProperties()
    testBehaviorWeightsAndComposite()
    testGoalsPathAndObstacles()
    testLinuxArchiveRoundTrip()
    testMalformedArchiveRejected()
    testDecisionTreeFindActionAndBranches()
    testDecisionTreeFailClosedImportExport()
    testComponentOwnership()
    testComponentSystemAndEntityUpdate()
    testEnumAndOptionSetValues()
    testGeometryValueTypes()
    testMeshTriangulation()
    testObstacleGraphConnectionsAndLocks()
    testNoiseSourcesDeterminism()
    testNoiseOperationsAndMaps()
    testGraphAStarAndEdges()
    testGridGraphLookupAndPath()
    testGraphNode3DAndCopyIndependence()
    testARC4SeedDeterminismAndCopy()
    testLCGAndMersenneDeterminism()
    testDistributionsAndShuffle()
    testRandomProtocolNextValues()
    testRuleSystemFactsAndAgenda()
    testNSPredicateRuleAndPredicateFactories()
    testMinmaxAndMonteCarloStrategists()
    testSceneBookkeeping()
    testSceneFileNamedFailClosed()
    testOctreeQueries()
    testQuadtreeQueries()
    testRTreeQueries()
    testStateMachineTransitions()
    testStateMachineReentrantEnterAndUpdate()
    print("GAMEPLAYKIT_AGENT_RUNTIME_OK")
}
