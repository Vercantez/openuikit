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
    convenience init(value: Int) {
        self.init()
        self.value = value
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
    try expect(GK_VERSION == 26_01_00, "version")
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
    try expect(lcg2.nextInt() == lcgA, "lcg determinism")
    let mt = GKMersenneTwisterRandomSource(seed: 99)
    try expect(mt.nextInt(upperBound: 10) >= 0, "mt bounded")
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

    let a = GKGraphNode2D(point: vector_float2(0, 0))
    let b = GKGraphNode2D(point: vector_float2(1, 0))
    let c = GKGraphNode2D(point: vector_float2(1, 1))
    a.addConnections(to: [b], bidirectional: true)
    b.addConnections(to: [c], bidirectional: true)
    let path = a.findPath(to: c)
    try expect(path.count == 3, "astar length")
    let graph = GKGraph(nodes: [a, b, c])
    try expect(graph.findPath(from: a, to: c).count == 3, "graph path")

    let grid = GKGridGraph<GKGridGraphNode>(
        fromGridStartingAt: vector_int2(0, 0),
        width: 4,
        height: 4,
        diagonalsAllowed: false
    )
    let start = grid.node(atGridPosition: vector_int2(0, 0))
    let end = grid.node(atGridPosition: vector_int2(3, 0))
    try expect(start != nil && end != nil, "grid nodes")
    let gridPath = grid.findPath(from: start!, to: end!)
    try expect(gridPath.count == 4, "grid path length")

    let wall = GKPolygonObstacle(points: [
        SIMD2<Float>(2, 2), SIMD2<Float>(3, 2), SIMD2<Float>(3, 3), SIMD2<Float>(2, 3)
    ])
    try expect(wall.vertexCount == 4, "polygon verts")
    let obstacles = GKObstacleGraph<GKGraphNode2D>(obstacles: [wall], bufferRadius: 0.1)
    try expect(obstacles.obstacles.count == 1, "obstacle graph")
    let extra = GKGraphNode2D(point: vector_float2(0, 0))
    obstacles.connectUsingObstacles(node: extra)

    let mesh = GKMeshGraph<GKGraphNode2D>(
        bufferRadius: 0.1,
        minCoordinate: vector_float2(0, 0),
        maxCoordinate: vector_float2(4, 4)
    )
    mesh.triangulationMode = [.vertices, .centers]
    mesh.addObstacles([wall])
    mesh.triangulate()
    try expect(mesh.triangleCount > 0, "mesh triangles")

    let perlin = GKPerlinNoiseSource(frequency: 1, octaveCount: 3, persistence: 0.5, lacunarity: 2, seed: 7)
    let noise = GKNoise(perlin)
    let n1 = noise.value(atPosition: vector_float2(0.2, 0.3))
    let n2 = GKNoise(GKPerlinNoiseSource(frequency: 1, octaveCount: 3, persistence: 0.5, lacunarity: 2, seed: 7))
        .value(atPosition: vector_float2(0.2, 0.3))
    try expect(n1 == n2, "perlin determinism")
    let map = GKNoiseMap(
        noise,
        size: vector_double2(1, 1),
        origin: vector_double2(0, 0),
        sampleCount: vector_int2(8, 8),
        seamless: false
    )
    try expect(map.sampleCount.x == 8, "noise map size")
    _ = map.value(at: vector_int2(0, 0))
    _ = map.interpolatedValue(at: vector_float2(1.5, 1.5))
    _ = GKNoise(GKCheckerboardNoiseSource.checkerboardNoise(withSquareSize: 1))
        .value(atPosition: vector_float2(0.2, 0.2))

    let seeker = GKAgent2D()
    seeker.maxSpeed = 10
    seeker.maxAcceleration = 20
    seeker.mass = 1
    let target = GKAgent2D()
    target.position = vector_float2(5, 0)
    seeker.behavior = GKBehavior(goal: GKGoal(toSeekAgent: target), weight: 1)
    let before = seeker.position.x
    seeker.update(deltaTime: 0.5)
    try expect(seeker.position.x > before, "agent seeks")

    let box = GKBox(boxMin: vector_float3(-1, -1, -1), boxMax: vector_float3(1, 1, 1))
    let tree = GKOctree<NSString>(boundingBox: box, minimumCellSize: 0.5)
    _ = tree.add("token" as NSString, at: vector_float3(0, 0, 0))
    try expect(tree.elements(at: vector_float3(0, 0, 0)).count == 1, "octree query")

    let quad = GKQuad(quadMin: vector_float2(-2, -2), quadMax: vector_float2(2, 2))
    let qtree = GKQuadtree<NSString>(boundingQuad: quad, minimumCellSize: 0.5)
    _ = qtree.add("q" as NSString, in: GKQuad(quadMin: vector_float2(0, 0), quadMax: vector_float2(0.5, 0.5)))
    try expect(qtree.elements(at: vector_float2(0.1, 0.1)).count == 1, "quadtree query")

    let rtree = GKRTree<NSString>(maxNumberOfChildren: 4)
    rtree.addElement(
        "r" as NSString,
        boundingRectMin: vector_float2(0, 0),
        boundingRectMax: vector_float2(1, 1),
        splitStrategy: .halve
    )
    try expect(rtree.elements(inBoundingRectMin: vector_float2(-1, -1), rectMax: vector_float2(2, 2)).count == 1, "rtree")

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

do {
    try runGameplayKitRuntime()
    print("GAMEPLAYKIT_AGENT_RUNTIME_OK")
} catch {
    print("GAMEPLAYKIT_AGENT_RUNTIME_FAILED: \(error)")
    exit(1)
}
