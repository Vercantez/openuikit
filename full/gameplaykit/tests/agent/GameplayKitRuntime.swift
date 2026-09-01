import Foundation
import GameplayKit

enum GameplayKitRuntimeFailure: Error {
    case message(String)
}

func expect(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw GameplayKitRuntimeFailure.message(message)
    }
}

final class LoadState: GKState {
    var entered = false
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == ReadyState.self
    }
    override func didEnter(from previousState: GKState?) {
        entered = true
    }
}

final class ReadyState: GKState {
    var enteredFromLoad = false
    override func didEnter(from previousState: GKState?) {
        enteredFromLoad = previousState is LoadState
    }
}

final class HealthComponent: GKComponent {
    var value: Int = 0
    var added = 0
    var removed = 0

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

final class BounceState: GKState {
    var enterCount = 0
    override func didEnter(from previousState: GKState?) {
        enterCount += 1
        if enterCount == 1 {
            _ = stateMachine?.enter(LandState.self)
        }
    }
}

final class LandState: GKState {
    var enterCount = 0
    override func didEnter(from previousState: GKState?) {
        enterCount += 1
    }
}

final class ProbePlayer: NSObject, GKGameModelPlayer {
    let playerId: Int
    init(id: Int) { self.playerId = id }
}

final class ProbeUpdate: NSObject, GKGameModelUpdate {
    var value: Int = 0
    let delta: Int
    init(delta: Int) { self.delta = delta }
}

final class ProbeModel: NSObject, GKGameModel {
    var players: [any GKGameModelPlayer]?
    var activePlayer: (any GKGameModelPlayer)?
    var scoreValue: Int

    init(score: Int, player: ProbePlayer) {
        self.scoreValue = score
        self.players = [player]
        self.activePlayer = player
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = ProbeModel(score: scoreValue, player: players?.first as! ProbePlayer)
        return copy
    }

    func setGameModel(_ gameModel: any GKGameModel) {
        if let other = gameModel as? ProbeModel {
            scoreValue = other.scoreValue
        }
    }

    func gameModelUpdates(for player: any GKGameModelPlayer) -> [any GKGameModelUpdate]? {
        [ProbeUpdate(delta: 4), ProbeUpdate(delta: -1)]
    }

    func apply(_ gameModelUpdate: any GKGameModelUpdate) {
        if let update = gameModelUpdate as? ProbeUpdate {
            scoreValue += update.delta
        }
    }

    func score(for player: any GKGameModelPlayer) -> Int {
        scoreValue
    }
}

func runGameplayKitRuntime() throws {
    try expect(GKGameModelMaxScore == 1 << 24, "max score")
    try expect(GKGameModelMinScore == -(1 << 24), "min score")

    let load = LoadState()
    let ready = ReadyState()
    let machine = GKStateMachine(states: [load, ready])
    try expect(machine.enter(LoadState.self), "enter load")
    try expect(machine.currentState === load, "current load")
    try expect(load.entered, "load entered")
    try expect(machine.canEnterState(ReadyState.self), "can enter ready")
    try expect(machine.enter(ReadyState.self), "enter ready")
    try expect(ready.enteredFromLoad, "ready from load")
    try expect(machine.state(forClass: LoadState.self) === load, "state for class")

    let bounce = BounceState()
    let land = LandState()
    let reentrant = GKStateMachine(states: [bounce, land])
    try expect(reentrant.enter(BounceState.self), "reentrant enter")
    try expect(reentrant.currentState === land, "reentrant landed")
    try expect(bounce.enterCount == 1, "bounce entered once")
    try expect(land.enterCount == 1, "land entered from bounce")

    try testComponentOwnership()
    try testCodingFailClosed()
    try testCopyIndependence()
    try testRandomBounds()
    try testPathfindingEdges()

    let entity = GKEntity()
    let health = HealthComponent(value: 7)
    entity.addComponent(health)
    try expect(entity.component(ofType: HealthComponent.self)?.value == 7, "component lookup")
    let system = GKComponentSystem<HealthComponent>(componentClass: HealthComponent.self)
    system.addComponent(foundIn: entity)
    try expect(system.components.count == 1, "component system")
    entity.update(deltaTime: 0.016)

    let arc4 = GKARC4RandomSource(seed: Data([1, 2, 3, 4, 5, 6, 7, 8]))
    let first = arc4.nextInt()
    let copy = arc4.copy() as! GKARC4RandomSource
    let arc4b = GKARC4RandomSource(seed: Data([1, 2, 3, 4, 5, 6, 7, 8]))
    try expect(arc4b.nextInt() == first, "arc4 seed determinism")
    copy.dropValues(8)
    _ = copy.nextBool()
    let lcg = GKLinearCongruentialRandomSource(seed: 42)
    let lcgA = lcg.nextInt()
    let lcg2 = GKLinearCongruentialRandomSource(seed: 42)
    try expect(lcg2.nextInt() == lcgA, "lcg linux determinism")
    let mt = GKMersenneTwisterRandomSource(seed: 99)
    try expect(mt.nextInt(upperBound: 10) >= 0 && mt.nextInt(upperBound: 10) < 10, "mt bounded")
    let die = GKRandomDistribution.d6()
    let roll = die.nextInt()
    try expect(roll >= 1 && roll <= 6, "d6 range")
    let shuffled = GKShuffledDistribution(randomSource: GKARC4RandomSource(seed: Data([9])), lowestValue: 1, highestValue: 3)
    var seen = Set<Int>()
    for _ in 0..<3 { seen.insert(shuffled.nextInt()) }
    try expect(seen == Set([1, 2, 3]), "shuffled deck")
    let gaussian = GKGaussianDistribution(randomSource: GKLinearCongruentialRandomSource(seed: 3), mean: 10, deviation: 2)
    _ = gaussian.nextInt()
    let array: NSArray = ["a", "b", "c", "d"]
    try expect(array.shuffled(using: GKARC4RandomSource(seed: Data([2]))).count == 4, "nsarray shuffle")

    let a = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let b = GKGraphNode2D(point: SIMD2<Float>(1, 0))
    let c = GKGraphNode2D(point: SIMD2<Float>(1, 1))
    a.addConnections(to: [b], bidirectional: true)
    b.addConnections(to: [c], bidirectional: true)
    let path = a.findPath(to: c)
    try expect(path.count == 3, "astar length")
    let graph = GKGraph(nodes: [a, b, c])
    try expect(graph.findPath(from: a, to: c).count == 3, "graph path")

    let grid = GKGridGraph<GKGridGraphNode>(
        fromGridStartingAt: SIMD2<Int32>(0, 0),
        width: 4,
        height: 4,
        diagonalsAllowed: false
    )
    let start = grid.node(atGridPosition: SIMD2<Int32>(0, 0))
    let end = grid.node(atGridPosition: SIMD2<Int32>(3, 0))
    try expect(start != nil && end != nil, "grid nodes")
    let gridPath = grid.findPath(from: start!, to: end!)
    try expect(gridPath.count == 4, "grid path length")

    let wall = GKPolygonObstacle(points: [
        SIMD2<Float>(2, 2), SIMD2<Float>(3, 2), SIMD2<Float>(3, 3), SIMD2<Float>(2, 3)
    ])
    try expect(wall.vertexCount == 4, "polygon verts")
    let obstacles = GKObstacleGraph<GKGraphNode2D>(obstacles: [wall], bufferRadius: 0.1)
    try expect(obstacles.obstacles.count == 1, "obstacle graph")
    let extra = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    obstacles.connectUsingObstacles(node: extra)

    let mesh = GKMeshGraph<GKGraphNode2D>(
        bufferRadius: 0.1,
        minCoordinate: SIMD2<Float>(0, 0),
        maxCoordinate: SIMD2<Float>(4, 4)
    )
    mesh.triangulationMode = [.vertices, .centers]
    mesh.addObstacles([wall])
    mesh.triangulate()
    try expect(mesh.triangleCount > 0, "mesh triangles")

    let perlin = GKPerlinNoiseSource(frequency: 1, octaveCount: 3, persistence: 0.5, lacunarity: 2, seed: 7)
    let noise = GKNoise(perlin)
    let n1 = noise.value(atPosition: SIMD2<Float>(0.2, 0.3))
    let n2 = GKNoise(GKPerlinNoiseSource(frequency: 1, octaveCount: 3, persistence: 0.5, lacunarity: 2, seed: 7))
        .value(atPosition: SIMD2<Float>(0.2, 0.3))
    try expect(n1 == n2, "perlin determinism")
    let map = GKNoiseMap(
        noise,
        size: SIMD2<Double>(1, 1),
        origin: SIMD2<Double>(0, 0),
        sampleCount: SIMD2<Int32>(8, 8),
        seamless: false
    )
    try expect(map.sampleCount.x == 8, "noise map size")
    _ = map.value(at: SIMD2<Int32>(0, 0))
    _ = map.interpolatedValue(at: SIMD2<Float>(1.5, 1.5))
    _ = GKNoise(GKCheckerboardNoiseSource.checkerboardNoise(withSquareSize: 1))
        .value(atPosition: SIMD2<Float>(0.2, 0.2))

    let seeker = GKAgent2D()
    seeker.maxSpeed = 10
    seeker.maxAcceleration = 20
    seeker.mass = 1
    let target = GKAgent2D()
    target.position = SIMD2<Float>(5, 0)
    seeker.behavior = GKBehavior(goal: GKGoal(toSeekAgent: target), weight: 1)
    let before = seeker.position.x
    seeker.update(deltaTime: 0.5)
    try expect(seeker.position.x > before, "agent seeks")

    let box = GKBox(boxMin: SIMD3<Float>(-1, -1, -1), boxMax: SIMD3<Float>(1, 1, 1))
    let tree = GKOctree<NSString>(boundingBox: box, minimumCellSize: 0.5)
    _ = tree.add("token" as NSString, at: SIMD3<Float>(0, 0, 0))
    try expect(tree.elements(at: SIMD3<Float>(0, 0, 0)).count == 1, "octree query")

    let quad = GKQuad(quadMin: SIMD2<Float>(-2, -2), quadMax: SIMD2<Float>(2, 2))
    let qtree = GKQuadtree<NSString>(boundingQuad: quad, minimumCellSize: 0.5)
    _ = qtree.add("q" as NSString, in: GKQuad(quadMin: SIMD2<Float>(0, 0), quadMax: SIMD2<Float>(0.5, 0.5)))
    try expect(qtree.elements(at: SIMD2<Float>(0.1, 0.1)).count == 1, "quadtree query")

    let rtree = GKRTree<NSString>(maxNumberOfChildren: 4)
    rtree.addElement(
        "r" as NSString,
        boundingRectMin: SIMD2<Float>(0, 0),
        boundingRectMax: SIMD2<Float>(1, 1),
        splitStrategy: .halve
    )
    try expect(rtree.elements(inBoundingRectMin: SIMD2<Float>(-1, -1), rectMax: SIMD2<Float>(2, 2)).count == 1, "rtree")

    let player = ProbePlayer(id: 1)
    let model = ProbeModel(score: 0, player: player)
    let minmax = GKMinmaxStrategist()
    minmax.gameModel = model
    minmax.maxLookAheadDepth = 2
    minmax.randomSource = GKARC4RandomSource(seed: Data([4]))
    try expect(minmax.bestMove(for: player) != nil, "minmax move")

    let rules = GKRuleSystem()
    let fact = "ready" as NSString
    rules.add(GKRule(blockPredicate: { _ in true }, action: { system in
        system.assertFact(fact)
    }))
    rules.evaluate()
    try expect(rules.grade(forFact: fact) == 1, "rule assert")

    let decision = GKDecisionTree(attribute: "color" as NSString)
    _ = decision.rootNode?.createBranch(value: 1, attribute: "go" as NSString)
    _ = decision.findAction(forAnswers: ["color": 1 as NSNumber])

    let scene = GKScene()
    scene.addEntity(entity)
    try expect(scene.entities.count == 1, "scene entity")
    try expect(GKScene(fileNamed: "missing.gkscene") == nil, "scene archive fail-closed")

    let mode: GKMeshGraphTriangulationMode = [.vertices, .centers]
    try expect(mode.contains(.vertices), "option set")
    try expect(GKRTreeSplitStrategy(rawValue: 0) == .halve, "split strategy")
}

func testComponentOwnership() throws {
    let first = GKEntity()
    let second = GKEntity()
    let health = HealthComponent(value: 7)
    first.addComponent(health)
    try expect(health.entity === first, "attach first")
    try expect(first.component(ofType: HealthComponent.self) === health, "first owns")
    second.addComponent(health)
    try expect(health.entity === second, "transfer entity pointer")
    try expect(first.component(ofType: HealthComponent.self) == nil, "first detached")
    try expect(second.component(ofType: HealthComponent.self) === health, "second owns")
    try expect(health.removed == 1, "detached once")
    try expect(health.added == 2, "added to each entity")

    let replacement = HealthComponent(value: 9)
    second.addComponent(replacement)
    try expect(second.component(ofType: HealthComponent.self) === replacement, "replacement")
    try expect(health.entity == nil, "replaced component cleared")
    try expect(second.components.count == 1, "one component of class")

    second.removeComponent(ofType: HealthComponent.self)
    try expect(second.component(ofType: HealthComponent.self) == nil, "removed")
    try expect(replacement.entity == nil, "removed entity nil")

    var host: GKEntity? = GKEntity()
    let orphan = HealthComponent(value: 1)
    host!.addComponent(orphan)
    host = nil
    try expect(orphan.entity == nil, "deallocated entity")
}

func testCodingFailClosed() throws {
    let garbage = Data([0xFF, 0x00, 0x01, 0x02, 0x03])
    do {
        let coder = try NSKeyedUnarchiver(forReadingFrom: garbage)
        coder.requiresSecureCoding = true
        try expect(GKEntity(coder: coder) == nil, "entity coder nil")
        try expect(GKComponent(coder: coder) == nil, "component coder nil")
        try expect(GKScene(coder: coder) == nil, "scene coder nil")
        try expect(GKGraph(coder: coder) == nil, "graph coder nil")
        try expect(GKGraphNode(coder: coder) == nil, "graph node coder nil")
        try expect(GKPolygonObstacle(coder: coder) == nil, "polygon coder nil")
        try expect(GKDecisionTree(coder: coder) == nil, "decision tree coder nil")
    } catch {
        try expect(true, "malformed archive rejected")
    }

    let unrelated = try NSKeyedArchiver.archivedData(withRootObject: "nope" as NSString, requiringSecureCoding: true)
    do {
        let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKEntity.self, from: unrelated)
        try expect(decoded == nil, "unrelated root is not an entity")
    } catch {
        try expect(true, "unrelated root rejected")
    }

    try testLinuxArchiveRoundTrip()
}

func testLinuxArchiveRoundTrip() throws {
    let entity = GKEntity()
    entity.addComponent(HealthComponent(value: 13))
    let entityData = try NSKeyedArchiver.archivedData(withRootObject: entity, requiringSecureCoding: true)
    let entityDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKEntity.self, from: entityData)
    try expect(entityDecoded?.component(ofType: HealthComponent.self)?.value == 13, "entity archive value")
    try expect(entityDecoded?.component(ofType: HealthComponent.self)?.entity === entityDecoded, "decoded ownership")

    let a = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let b = GKGraphNode2D(point: SIMD2<Float>(2, 0))
    a.addConnections(to: [b], bidirectional: true)
    let graph = GKGraph(nodes: [a, b])
    let graphData = try NSKeyedArchiver.archivedData(withRootObject: graph, requiringSecureCoding: true)
    let graphDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKGraph.self, from: graphData)
    try expect(graphDecoded?.nodes?.count == 2, "graph node count")
    let decodedA = graphDecoded?.nodes?.first as? GKGraphNode2D
    let decodedB = graphDecoded?.nodes?.dropFirst().first as? GKGraphNode2D
    try expect(decodedA?.position == SIMD2<Float>(0, 0), "decoded A position")
    try expect(decodedB?.position == SIMD2<Float>(2, 0), "decoded B position")
    try expect(decodedA?.connectedNodes.count == 1, "decoded A edge")
    try expect(decodedA?.connectedNodes.first === decodedB, "decoded edge identity")

    let wall = GKPolygonObstacle(points: [
        SIMD2<Float>(0, 0), SIMD2<Float>(1, 0), SIMD2<Float>(0, 1)
    ])
    let wallData = try NSKeyedArchiver.archivedData(withRootObject: wall, requiringSecureCoding: true)
    let wallDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKPolygonObstacle.self, from: wallData)
    try expect(wallDecoded?.vertexCount == 3, "polygon archive count")
    try expect(wallDecoded?.vertex(at: 1) == SIMD2<Float>(1, 0), "polygon archive vertex")

    let scene = GKScene()
    scene.addEntity(entity)
    scene.addGraph(graph, name: "main")
    let sceneData = try NSKeyedArchiver.archivedData(withRootObject: scene, requiringSecureCoding: true)
    let sceneDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKScene.self, from: sceneData)
    try expect(sceneDecoded?.entities.count == 1, "scene entities")
    try expect(sceneDecoded?.graphs["main"]?.nodes?.count == 2, "scene graph")

    let tree = GKDecisionTree(attribute: "color" as NSString)
    _ = tree.rootNode?.createBranch(value: 1, attribute: "go" as NSString)
    let treeData = try NSKeyedArchiver.archivedData(withRootObject: tree, requiringSecureCoding: true)
    let treeDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKDecisionTree.self, from: treeData)
    let action = treeDecoded?.findAction(forAnswers: ["color" as NSString: 1 as NSNumber]) as? NSString
    try expect(action == "go", "decision tree archive")

    let source = GKARC4RandomSource(seed: Data([1, 2, 3, 4, 5, 6, 7, 8]))
    _ = source.nextInt()
    let sourceData = try NSKeyedArchiver.archivedData(withRootObject: source, requiringSecureCoding: true)
    let sourceDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: GKARC4RandomSource.self, from: sourceData)
    try expect(sourceDecoded?.nextInt() == source.nextInt(), "arc4 archive stream")
}

func testCopyIndependence() throws {
    let seed = Data([1, 2, 3, 4, 5, 6, 7, 8])
    let source = GKARC4RandomSource(seed: seed)
    let copied = source.copy() as! GKARC4RandomSource
    copied.dropValues(16)
    let fromCopy = copied.nextInt()
    let fromFresh = GKARC4RandomSource(seed: seed).nextInt()
    try expect(fromCopy != fromFresh, "advanced copy diverges")
    let sibling = source.copy() as! GKARC4RandomSource
    try expect(source.nextInt() == sibling.nextInt(), "unadvanced copy matches")
    try expect(copied.seed == seed, "seed preserved on copy")

    let node = GKGraphNode2D(point: SIMD2<Float>(3, 4))
    let nodeCopy = node.copy() as! GKGraphNode2D
    nodeCopy.position = SIMD2<Float>(9, 9)
    try expect(node.position == SIMD2<Float>(3, 4), "node copy independent")

    let entity = GKEntity()
    entity.addComponent(HealthComponent(value: 11))
    let entityCopy = entity.copy() as! GKEntity
    try expect(entityCopy.component(ofType: HealthComponent.self)?.value == 11, "entity copy value")
    entityCopy.component(ofType: HealthComponent.self)?.value = 0
    try expect(entity.component(ofType: HealthComponent.self)?.value == 11, "entity copy independent")

    let a = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let b = GKGraphNode2D(point: SIMD2<Float>(1, 0))
    a.addConnections(to: [b], bidirectional: true)
    let graph = GKGraph(nodes: [a, b])
    let graphCopy = graph.copy() as! GKGraph
    let copyA = graphCopy.nodes?.first as? GKGraphNode2D
    copyA?.position = SIMD2<Float>(9, 9)
    try expect(a.position == SIMD2<Float>(0, 0), "graph copy node independent")
    try expect(copyA?.connectedNodes.count == 1, "graph copy keeps edges")
    try expect(copyA?.connectedNodes.first !== b, "graph copy does not share nodes")

    let scene = GKScene()
    scene.addGraph(graph, name: "g")
    let sceneCopy = scene.copy() as! GKScene
    try expect(sceneCopy.graphs["g"] !== graph, "scene copy graph independent")
}

func testRandomBounds() throws {
    let source = GKARC4RandomSource(seed: Data([9, 8, 7, 6, 5, 4, 3, 2]))
    for _ in 0..<32 {
        let bound = source.nextInt(upperBound: 7)
        try expect(bound >= 0 && bound < 7, "arc4 upper bound")
    }
    try expect(source.nextInt(upperBound: 0) == 0, "zero bound")
    try expect(source.nextInt(upperBound: 1) == 0, "one bound")
    let die = GKRandomDistribution.d20()
    for _ in 0..<16 {
        let roll = die.nextInt()
        try expect(roll >= 1 && roll <= 20, "d20 range")
    }
}

func testPathfindingEdges() throws {
    let start = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    try expect(start.findPath(to: start).isEmpty, "start equals goal")

    let a = GKGraphNode2D(point: SIMD2<Float>(0, 0))
    let b = GKGraphNode2D(point: SIMD2<Float>(1, 0))
    let c = GKGraphNode2D(point: SIMD2<Float>(1, 1))
    a.addConnections(to: [b], bidirectional: true)
    b.addConnections(to: [c], bidirectional: true)
    c.addConnections(to: [a], bidirectional: true)
    let cyclic = a.findPath(to: c)
    try expect(cyclic.first === a && cyclic.last === c, "cycle path ends")
    try expect(cyclic.count >= 2, "cycle path finite")
    let disconnected = GKGraphNode2D(point: SIMD2<Float>(50, 50))
    try expect(a.findPath(to: disconnected).isEmpty, "no path")
}

do {
    try runGameplayKitRuntime()
    print("GAMEPLAYKIT_AGENT_RUNTIME_OK")
} catch {
    print("GAMEPLAYKIT_AGENT_RUNTIME_FAILED: \(error)")
    exit(1)
}
