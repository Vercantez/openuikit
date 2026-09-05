import Foundation
import GameplayKit

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
