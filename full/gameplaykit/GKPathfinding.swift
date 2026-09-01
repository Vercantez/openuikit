import Foundation

open class GKGraphNode: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    private var connections: [GKGraphNode] = []

    public var connectedNodes: [GKGraphNode] { connections }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard GKLinuxArchive.hasMarker(coder) else { return nil }
        super.init()
    }

    open func encode(with coder: NSCoder) {
        GKLinuxArchive.encodeMarker(coder)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        GKGraphNode()
    }

    func gkRestoreConnections(_ nodes: [GKGraphNode]) {
        connections = nodes
    }

    open func addConnections(to nodes: [GKGraphNode], bidirectional: Bool) {
        for node in nodes where node !== self {
            if !connections.contains(where: { $0 === node }) {
                connections.append(node)
            }
            if bidirectional {
                node.addConnections(to: [self], bidirectional: false)
            }
        }
    }

    open func removeConnections(to nodes: [GKGraphNode], bidirectional: Bool) {
        connections.removeAll { candidate in
            nodes.contains(where: { $0 === candidate })
        }
        if bidirectional {
            for node in nodes {
                node.removeConnections(to: [self], bidirectional: false)
            }
        }
    }

    open func cost(to node: GKGraphNode) -> Float {
        if node === self { return 0 }
        if connections.contains(where: { $0 === node }) {
            return 1
        }
        return Float.greatestFiniteMagnitude
    }

    open func estimatedCost(to node: GKGraphNode) -> Float {
        0
    }

    open func findPath(to goalNode: GKGraphNode) -> [GKGraphNode] {
        gkAStar(from: self, to: goalNode)
    }

    open func findPath(from startNode: GKGraphNode) -> [GKGraphNode] {
        startNode.findPath(to: self)
    }
}

open class GKGraphNode2D: GKGraphNode {
    public var position: SIMD2<Float>

    public required init(point: SIMD2<Float>) {
        self.position = point
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard GKLinuxArchive.hasMarker(coder),
              coder.containsValue(forKey: GKLinuxArchive.xKey),
              coder.containsValue(forKey: GKLinuxArchive.yKey) else {
            return nil
        }
        position = SIMD2<Float>(
            coder.decodeFloat(forKey: GKLinuxArchive.xKey),
            coder.decodeFloat(forKey: GKLinuxArchive.yKey)
        )
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(position.x, forKey: GKLinuxArchive.xKey)
        coder.encode(position.y, forKey: GKLinuxArchive.yKey)
    }

    open class func node(withPoint point: SIMD2<Float>) -> Self {
        Self(point: point)
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        GKGraphNode2D(point: position)
    }

    open override func cost(to node: GKGraphNode) -> Float {
        if node === self { return 0 }
        guard connectedNodes.contains(where: { $0 === node }) else {
            return Float.greatestFiniteMagnitude
        }
        if let other = node as? GKGraphNode2D {
            return gkDistance(position, other.position)
        }
        return super.cost(to: node)
    }

    open override func estimatedCost(to node: GKGraphNode) -> Float {
        if let other = node as? GKGraphNode2D {
            return gkDistance(position, other.position)
        }
        return 0
    }
}

open class GKGraphNode3D: GKGraphNode {
    public var position: SIMD3<Float>

    public required init(point: SIMD3<Float>) {
        self.position = point
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard GKLinuxArchive.hasMarker(coder),
              coder.containsValue(forKey: GKLinuxArchive.xKey),
              coder.containsValue(forKey: GKLinuxArchive.yKey),
              coder.containsValue(forKey: GKLinuxArchive.zKey) else {
            return nil
        }
        position = SIMD3<Float>(
            coder.decodeFloat(forKey: GKLinuxArchive.xKey),
            coder.decodeFloat(forKey: GKLinuxArchive.yKey),
            coder.decodeFloat(forKey: GKLinuxArchive.zKey)
        )
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(position.x, forKey: GKLinuxArchive.xKey)
        coder.encode(position.y, forKey: GKLinuxArchive.yKey)
        coder.encode(position.z, forKey: GKLinuxArchive.zKey)
    }

    open class func node(withPoint point: SIMD3<Float>) -> Self {
        Self(point: point)
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        GKGraphNode3D(point: position)
    }

    open override func cost(to node: GKGraphNode) -> Float {
        if node === self { return 0 }
        guard connectedNodes.contains(where: { $0 === node }) else {
            return Float.greatestFiniteMagnitude
        }
        if let other = node as? GKGraphNode3D {
            return gkDistance(position, other.position)
        }
        return super.cost(to: node)
    }

    open override func estimatedCost(to node: GKGraphNode) -> Float {
        if let other = node as? GKGraphNode3D {
            return gkDistance(position, other.position)
        }
        return 0
    }
}

open class GKGridGraphNode: GKGraphNode {
    public private(set) var gridPosition: SIMD2<Int32>

    public required init(gridPosition: SIMD2<Int32>) {
        self.gridPosition = gridPosition
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard GKLinuxArchive.hasMarker(coder),
              coder.containsValue(forKey: GKLinuxArchive.xKey),
              coder.containsValue(forKey: GKLinuxArchive.yKey) else {
            return nil
        }
        gridPosition = SIMD2<Int32>(
            Int32(truncatingIfNeeded: coder.decodeInt64(forKey: GKLinuxArchive.xKey)),
            Int32(truncatingIfNeeded: coder.decodeInt64(forKey: GKLinuxArchive.yKey))
        )
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Int64(gridPosition.x), forKey: GKLinuxArchive.xKey)
        coder.encode(Int64(gridPosition.y), forKey: GKLinuxArchive.yKey)
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        GKGridGraphNode(gridPosition: gridPosition)
    }

    open override func cost(to node: GKGraphNode) -> Float {
        if node === self { return 0 }
        guard connectedNodes.contains(where: { $0 === node }) else {
            return Float.greatestFiniteMagnitude
        }
        if let other = node as? GKGridGraphNode {
            let dx = abs(Int(gridPosition.x) - Int(other.gridPosition.x))
            let dy = abs(Int(gridPosition.y) - Int(other.gridPosition.y))
            if dx == 1 && dy == 1 {
                return 1.4142135
            }
            return Float(dx + dy)
        }
        return super.cost(to: node)
    }

    open override func estimatedCost(to node: GKGraphNode) -> Float {
        guard let other = node as? GKGridGraphNode else { return 0 }
        let dx = Float(abs(Int(gridPosition.x) - Int(other.gridPosition.x)))
        let dy = Float(abs(Int(gridPosition.y) - Int(other.gridPosition.y)))
        return (dx * dx + dy * dy).squareRoot()
    }
}

open class GKGraph: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    private var nodeStorage: [GKGraphNode] = []

    public var nodes: [GKGraphNode]? { nodeStorage.isEmpty ? nil : nodeStorage }

    public init(_ nodes: [GKGraphNode]) {
        self.nodeStorage = nodes
        super.init()
    }

    public convenience init(nodes: [GKGraphNode]) {
        self.init(nodes)
    }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard GKLinuxArchive.hasMarker(coder) else { return nil }
        super.init()
        let decoded = GKLinuxArchive.decodeObjectArray(
            coder,
            key: GKLinuxArchive.nodesKey,
            classes: [GKGraphNode.self, GKGraphNode2D.self, GKGraphNode3D.self, GKGridGraphNode.self]
        ) as [GKGraphNode]?
        guard let decoded else { return nil }
        nodeStorage = decoded
        let edges = coder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: GKLinuxArchive.edgesKey) as? [NSNumber]
        guard let edges else { return nil }
        guard edges.count % 2 == 0 else { return nil }
        var index = 0
        while index < edges.count {
            let from = edges[index].intValue
            let to = edges[index + 1].intValue
            index += 2
            guard nodeStorage.indices.contains(from), nodeStorage.indices.contains(to) else { return nil }
            nodeStorage[from].addConnections(to: [nodeStorage[to]], bidirectional: false)
        }
    }

    open func encode(with coder: NSCoder) {
        GKLinuxArchive.encodeMarker(coder)
        coder.encode(nodeStorage as NSArray, forKey: GKLinuxArchive.nodesKey)
        var identity = [ObjectIdentifier: Int]()
        for (offset, node) in nodeStorage.enumerated() {
            identity[ObjectIdentifier(node)] = offset
        }
        var edges: [NSNumber] = []
        for (offset, node) in nodeStorage.enumerated() {
            for connected in node.connectedNodes {
                if let target = identity[ObjectIdentifier(connected)] {
                    edges.append(NSNumber(value: offset))
                    edges.append(NSNumber(value: target))
                }
            }
        }
        coder.encode(edges as NSArray, forKey: GKLinuxArchive.edgesKey)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let clones = nodeStorage.map { node -> GKGraphNode in
            (node.copy() as? GKGraphNode) ?? GKGraphNode()
        }
        var map: [ObjectIdentifier: GKGraphNode] = [:]
        for (original, clone) in zip(nodeStorage, clones) {
            map[ObjectIdentifier(original)] = clone
        }
        for original in nodeStorage {
            guard let clone = map[ObjectIdentifier(original)] else { continue }
            let restored = original.connectedNodes.compactMap { map[ObjectIdentifier($0)] }
            clone.gkRestoreConnections(restored)
        }
        return GKGraph(clones)
    }

    open func add(_ nodes: [GKGraphNode]) {
        for node in nodes where !nodeStorage.contains(where: { $0 === node }) {
            nodeStorage.append(node)
        }
    }

    open func remove(_ nodes: [GKGraphNode]) {
        nodeStorage.removeAll { candidate in
            nodes.contains(where: { $0 === candidate })
        }
        for remaining in nodeStorage {
            remaining.removeConnections(to: nodes, bidirectional: false)
        }
    }

    open func connectToLowestCostNode(node: GKGraphNode, bidirectional: Bool) {
        guard !nodeStorage.isEmpty else {
            add([node])
            return
        }
        var best: GKGraphNode?
        var bestCost = Float.greatestFiniteMagnitude
        for existing in nodeStorage where existing !== node {
            let cost = node.estimatedCost(to: existing)
            if cost < bestCost {
                bestCost = cost
                best = existing
            }
        }
        add([node])
        if let best {
            node.addConnections(to: [best], bidirectional: bidirectional)
        }
    }

    open func findPath(from startNode: GKGraphNode, to endNode: GKGraphNode) -> [GKGraphNode] {
        startNode.findPath(to: endNode)
    }
}

open class GKGridGraph<NodeType: GKGridGraphNode>: GKGraph {
    public let gridOrigin: SIMD2<Int32>
    public let gridWidth: Int
    public let gridHeight: Int
    public let diagonalsAllowed: Bool
    private var grid: [SIMD2<Int32>: NodeType] = [:]
    private let nodeType: NodeType.Type

    public init(
        fromGridStartingAt position: SIMD2<Int32>,
        width: Int32,
        height: Int32,
        diagonalsAllowed: Bool
    ) {
        self.gridOrigin = position
        self.gridWidth = Int(width)
        self.gridHeight = Int(height)
        self.diagonalsAllowed = diagonalsAllowed
        self.nodeType = NodeType.self
        super.init([])
        buildGrid()
    }

    public init(
        fromGridStartingAt position: SIMD2<Int32>,
        width: Int32,
        height: Int32,
        diagonalsAllowed: Bool,
        nodeClass: AnyClass
    ) {
        self.gridOrigin = position
        self.gridWidth = Int(width)
        self.gridHeight = Int(height)
        self.diagonalsAllowed = diagonalsAllowed
        self.nodeType = (nodeClass as? NodeType.Type) ?? NodeType.self
        super.init([])
        buildGrid()
    }

    public convenience init(nodes: [GKGraphNode]) {
        self.init(fromGridStartingAt: SIMD2<Int32>(0, 0), width: 0, height: 0, diagonalsAllowed: false)
        add(nodes)
    }

    public required init?(coder: NSCoder) {
        self.gridOrigin = SIMD2<Int32>(0, 0)
        self.gridWidth = 0
        self.gridHeight = 0
        self.diagonalsAllowed = false
        self.nodeType = NodeType.self
        super.init()
        return nil
    }

    private func buildGrid() {
        var created: [NodeType] = []
        if gridWidth <= 0 || gridHeight <= 0 { return }
        for y in 0..<gridHeight {
            for x in 0..<gridWidth {
                let pos = SIMD2<Int32>(gridOrigin.x + Int32(x), gridOrigin.y + Int32(y))
                let node = nodeType.init(gridPosition: pos)
                grid[pos] = node
                created.append(node)
            }
        }
        add(created)
        for node in created {
            connectToAdjacentNodes(node: node)
        }
    }

    open func node(atGridPosition position: SIMD2<Int32>) -> NodeType? {
        grid[position]
    }

    open func connectToAdjacentNodes(node: GKGridGraphNode) {
        let x = Int(node.gridPosition.x)
        let y = Int(node.gridPosition.y)
        var neighbors: [GKGraphNode] = []
        let cardinal = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        let diagonal = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        let offsets = diagonalsAllowed ? cardinal + diagonal : cardinal
        for (dx, dy) in offsets {
            let pos = SIMD2<Int32>(Int32(x + dx), Int32(y + dy))
            if let other = grid[pos] {
                neighbors.append(other)
            }
        }
        node.addConnections(to: neighbors, bidirectional: true)
        if grid[node.gridPosition] == nil, let typed = node as? NodeType {
            grid[node.gridPosition] = typed
            add([typed])
        }
    }

    open func classForGenericArgument(at index: Int) -> AnyClass {
        NodeType.self
    }
}

open class GKObstacleGraph<NodeType: GKGraphNode2D>: GKGraph {
    public let bufferRadius: Float
    private var obstacleStorage: [GKPolygonObstacle] = []
    private var locked: Set<LockedPair> = []
    private let nodeType: NodeType.Type

    private struct LockedPair: Hashable {
        let a: ObjectIdentifier
        let b: ObjectIdentifier
        init(_ x: GKGraphNode, _ y: GKGraphNode) {
            let ix = ObjectIdentifier(x)
            let iy = ObjectIdentifier(y)
            if ix.hashValue <= iy.hashValue {
                a = ix
                b = iy
            } else {
                a = iy
                b = ix
            }
        }
    }

    public var obstacles: [GKPolygonObstacle] { obstacleStorage }

    public init(obstacles: [GKPolygonObstacle], bufferRadius: Float) {
        self.bufferRadius = bufferRadius
        self.nodeType = NodeType.self
        super.init([])
        addObstacles(obstacles)
    }

    public init(obstacles: [GKPolygonObstacle], bufferRadius: Float, nodeClass: AnyClass) {
        self.bufferRadius = bufferRadius
        self.nodeType = (nodeClass as? NodeType.Type) ?? NodeType.self
        super.init([])
        addObstacles(obstacles)
    }

    public convenience init(nodes: [GKGraphNode]) {
        self.init(obstacles: [], bufferRadius: 0)
        add(nodes)
    }

    public required init?(coder: NSCoder) {
        self.bufferRadius = 0
        self.nodeType = NodeType.self
        super.init()
        return nil
    }

    open func addObstacles(_ obstacles: [GKPolygonObstacle]) {
        obstacleStorage.append(contentsOf: obstacles)
        rebuildVisibility()
    }

    open func removeObstacles(_ obstacles: [GKPolygonObstacle]) {
        obstacleStorage.removeAll { candidate in
            obstacles.contains(where: { $0 === candidate })
        }
        rebuildVisibility()
    }

    open func removeAllObstacles() {
        obstacleStorage.removeAll()
        rebuildVisibility()
    }

    open func nodes(for obstacle: GKPolygonObstacle) -> [NodeType] {
        let verts = obstacle.allVertices()
        return (nodes ?? []).compactMap { node in
            guard let typed = node as? NodeType else { return nil }
            return verts.contains(where: { gkDistance($0, typed.position) < bufferRadius * 2 + 1e-3 }) ? typed : nil
        }
    }

    open func connectUsingObstacles(node: NodeType) {
        connectUsingObstacles(node: node, ignoring: [])
    }

    open func connectUsingObstacles(node: NodeType, ignoring obstaclesToIgnore: [GKPolygonObstacle]) {
        add([node])
        let ignored = Set(obstaclesToIgnore.map { ObjectIdentifier($0) })
        for existing in nodes ?? [] {
            guard let other = existing as? NodeType, other !== node else { continue }
            if lineOfSight(node.position, other.position, ignoring: ignored) {
                node.addConnections(to: [other], bidirectional: true)
            }
        }
    }

    open func connectUsingObstacles(node: NodeType, ignoringBufferRadiusOf obstaclesBufferRadiusToIgnore: [GKPolygonObstacle]) {
        connectUsingObstacles(node: node, ignoring: obstaclesBufferRadiusToIgnore)
    }

    open func lockConnection(from startNode: NodeType, to endNode: NodeType) {
        locked.insert(LockedPair(startNode, endNode))
        startNode.addConnections(to: [endNode], bidirectional: true)
    }

    open func unlockConnection(from startNode: NodeType, to endNode: NodeType) {
        locked.remove(LockedPair(startNode, endNode))
    }

    open func isConnectionLocked(from startNode: NodeType, to endNode: NodeType) -> Bool {
        locked.contains(LockedPair(startNode, endNode))
    }

    open func classForGenericArgument(at index: Int) -> AnyClass {
        NodeType.self
    }

    private func rebuildVisibility() {
        let previous = (nodes ?? []).compactMap { $0 as? NodeType }
        if let all = nodes {
            remove(all)
        }
        var created: [NodeType] = []
        for obstacle in obstacleStorage {
            let verts = obstacle.allVertices()
            for vertex in verts {
                let node = nodeType.init(point: vertex)
                created.append(node)
            }
        }
        add(created)
        for i in 0..<created.count {
            for j in (i + 1)..<created.count {
                let a = created[i]
                let b = created[j]
                if locked.contains(LockedPair(a, b)) || lineOfSight(a.position, b.position, ignoring: []) {
                    a.addConnections(to: [b], bidirectional: true)
                }
            }
        }
        for leftover in previous {
            connectUsingObstacles(node: leftover)
        }
    }

    private func lineOfSight(_ a: SIMD2<Float>, _ b: SIMD2<Float>, ignoring: Set<ObjectIdentifier>) -> Bool {
        for obstacle in obstacleStorage {
            if ignoring.contains(ObjectIdentifier(obstacle)) { continue }
            let verts = obstacle.allVertices()
            guard verts.count >= 2 else { continue }
            for i in 0..<verts.count {
                let v1 = verts[i]
                let v2 = verts[(i + 1) % verts.count]
                if gkSegmentsIntersect(a, b, v1, v2) {
                    let sharesEndpoint =
                        gkDistance(a, v1) < 1e-4 || gkDistance(a, v2) < 1e-4
                        || gkDistance(b, v1) < 1e-4 || gkDistance(b, v2) < 1e-4
                    if !sharesEndpoint {
                        return false
                    }
                }
            }
        }
        return true
    }
}

open class GKMeshGraph<NodeType: GKGraphNode2D>: GKGraph {
    public let bufferRadius: Float
    public var triangulationMode: GKMeshGraphTriangulationMode = [.vertices]
    private var obstacleStorage: [GKPolygonObstacle] = []
    private var triangles: [GKTriangle] = []
    private let minCoordinate: SIMD2<Float>
    private let maxCoordinate: SIMD2<Float>
    private let nodeType: NodeType.Type

    public var obstacles: [GKPolygonObstacle] { obstacleStorage }
    public var triangleCount: Int { triangles.count }

    public init(bufferRadius: Float, minCoordinate min: SIMD2<Float>, maxCoordinate max: SIMD2<Float>) {
        self.bufferRadius = bufferRadius
        self.minCoordinate = min
        self.maxCoordinate = max
        self.nodeType = NodeType.self
        super.init([])
    }

    public init(
        bufferRadius: Float,
        minCoordinate min: SIMD2<Float>,
        maxCoordinate max: SIMD2<Float>,
        nodeClass: AnyClass
    ) {
        self.bufferRadius = bufferRadius
        self.minCoordinate = min
        self.maxCoordinate = max
        self.nodeType = (nodeClass as? NodeType.Type) ?? NodeType.self
        super.init([])
    }

    public convenience init(nodes: [GKGraphNode]) {
        self.init(bufferRadius: 0, minCoordinate: SIMD2<Float>(0, 0), maxCoordinate: SIMD2<Float>(1, 1))
        add(nodes)
    }

    public required init?(coder: NSCoder) {
        self.bufferRadius = 0
        self.minCoordinate = SIMD2<Float>(0, 0)
        self.maxCoordinate = SIMD2<Float>(1, 1)
        self.nodeType = NodeType.self
        super.init()
        return nil
    }

    open func addObstacles(_ obstacles: [GKPolygonObstacle]) {
        obstacleStorage.append(contentsOf: obstacles)
    }

    open func removeObstacles(_ obstacles: [GKPolygonObstacle]) {
        obstacleStorage.removeAll { candidate in
            obstacles.contains(where: { $0 === candidate })
        }
    }

    open func triangle(at index: Int) -> GKTriangle {
        triangles[index]
    }

    open func triangulate() {
        var points: [SIMD2<Float>] = [
            minCoordinate,
            SIMD2<Float>(maxCoordinate.x, minCoordinate.y),
            maxCoordinate,
            SIMD2<Float>(minCoordinate.x, maxCoordinate.y)
        ]
        for obstacle in obstacleStorage {
            points.append(contentsOf: obstacle.allVertices())
        }
        triangles = gkBowyerWatson(points)
        if let existing = nodes {
            remove(existing)
        }
        var created: [NodeType] = []
        for triangle in triangles {
            if triangulationMode.contains(.vertices) {
                let p0 = SIMD2<Float>(triangle.points.0.x, triangle.points.0.y)
                let p1 = SIMD2<Float>(triangle.points.1.x, triangle.points.1.y)
                let p2 = SIMD2<Float>(triangle.points.2.x, triangle.points.2.y)
                created.append(nodeType.init(point: p0))
                created.append(nodeType.init(point: p1))
                created.append(nodeType.init(point: p2))
            }
            if triangulationMode.contains(.centers) {
                let c = (triangle.points.0 + triangle.points.1 + triangle.points.2) / 3
                created.append(nodeType.init(point: SIMD2<Float>(c.x, c.y)))
            }
            if triangulationMode.contains(.edgeMidpoints) {
                let m01 = (triangle.points.0 + triangle.points.1) / 2
                let m12 = (triangle.points.1 + triangle.points.2) / 2
                let m20 = (triangle.points.2 + triangle.points.0) / 2
                created.append(nodeType.init(point: SIMD2<Float>(m01.x, m01.y)))
                created.append(nodeType.init(point: SIMD2<Float>(m12.x, m12.y)))
                created.append(nodeType.init(point: SIMD2<Float>(m20.x, m20.y)))
            }
        }
        var unique: [NodeType] = []
        for node in created {
            if !unique.contains(where: { gkDistance($0.position, node.position) < 1e-4 }) {
                unique.append(node)
            }
        }
        add(unique)
        for i in 0..<unique.count {
            var near: [GKGraphNode] = []
            for j in 0..<unique.count where i != j {
                if gkDistance(unique[i].position, unique[j].position) <= (maxCoordinate.x - minCoordinate.x) * 0.35 + bufferRadius {
                    near.append(unique[j])
                }
            }
            unique[i].addConnections(to: near, bidirectional: true)
        }
    }

    open func connectUsingObstacles(node: NodeType) {
        add([node])
        for existing in nodes ?? [] {
            guard let other = existing as? NodeType, other !== node else { continue }
            var blocked = false
            for obstacle in obstacleStorage {
                let verts = obstacle.allVertices()
                for i in 0..<verts.count {
                    if gkSegmentsIntersect(node.position, other.position, verts[i], verts[(i + 1) % verts.count]) {
                        blocked = true
                    }
                }
            }
            if !blocked {
                node.addConnections(to: [other], bidirectional: true)
            }
        }
    }

    open func classForGenericArgument(at index: Int) -> AnyClass {
        NodeType.self
    }
}

private struct GKCircumcircle {
    let center: SIMD2<Float>
    let radius: Float
}

private func gkCircumcircle(_ a: SIMD2<Float>, _ b: SIMD2<Float>, _ c: SIMD2<Float>) -> GKCircumcircle? {
    let d = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
    if abs(d) < 1e-8 { return nil }
    let a2 = a.x * a.x + a.y * a.y
    let b2 = b.x * b.x + b.y * b.y
    let c2 = c.x * c.x + c.y * c.y
    let ux = (a2 * (b.y - c.y) + b2 * (c.y - a.y) + c2 * (a.y - b.y)) / d
    let uy = (a2 * (c.x - b.x) + b2 * (a.x - c.x) + c2 * (b.x - a.x)) / d
    let center = SIMD2<Float>(ux, uy)
    return GKCircumcircle(center: center, radius: gkDistance(center, a))
}

private func gkBowyerWatson(_ input: [SIMD2<Float>]) -> [GKTriangle] {
    guard input.count >= 3 else { return [] }
    var minX = input[0].x
    var minY = input[0].y
    var maxX = input[0].x
    var maxY = input[0].y
    for p in input {
        minX = min(minX, p.x)
        minY = min(minY, p.y)
        maxX = max(maxX, p.x)
        maxY = max(maxY, p.y)
    }
    let dx = max(maxX - minX, 1)
    let dy = max(maxY - minY, 1)
    let superA = SIMD2<Float>(minX - dx, minY - dy)
    let superB = SIMD2<Float>(maxX + dx * 3, minY - dy)
    let superC = SIMD2<Float>(minX - dx, maxY + dy * 3)
    var tris: [(SIMD2<Float>, SIMD2<Float>, SIMD2<Float>)] = [(superA, superB, superC)]
    for point in input {
        var bad: [(SIMD2<Float>, SIMD2<Float>, SIMD2<Float>)] = []
        var good: [(SIMD2<Float>, SIMD2<Float>, SIMD2<Float>)] = []
        for tri in tris {
            if let circle = gkCircumcircle(tri.0, tri.1, tri.2), gkDistance(circle.center, point) <= circle.radius + 1e-5 {
                bad.append(tri)
            } else {
                good.append(tri)
            }
        }
        var edges: [(SIMD2<Float>, SIMD2<Float>)] = []
        func same(_ x: SIMD2<Float>, _ y: SIMD2<Float>) -> Bool {
            gkDistance(x, y) < 1e-5
        }
        func addEdge(_ e: (SIMD2<Float>, SIMD2<Float>)) {
            if let idx = edges.firstIndex(where: { (same($0.0, e.0) && same($0.1, e.1)) || (same($0.0, e.1) && same($0.1, e.0)) }) {
                edges.remove(at: idx)
            } else {
                edges.append(e)
            }
        }
        for tri in bad {
            addEdge((tri.0, tri.1))
            addEdge((tri.1, tri.2))
            addEdge((tri.2, tri.0))
        }
        var next = good
        for edge in edges {
            next.append((edge.0, edge.1, point))
        }
        tris = next
    }
    let superPoints = [superA, superB, superC]
    func isSuper(_ p: SIMD2<Float>) -> Bool {
        superPoints.contains(where: { gkDistance($0, p) < 1e-4 })
    }
    return tris.compactMap { tri in
        if isSuper(tri.0) || isSuper(tri.1) || isSuper(tri.2) { return nil }
        return GKTriangle(points: (
            SIMD3<Float>(tri.0.x, tri.0.y, 0),
            SIMD3<Float>(tri.1.x, tri.1.y, 0),
            SIMD3<Float>(tri.2.x, tri.2.y, 0)
        ))
    }
}

func gkAStar(from start: GKGraphNode, to goal: GKGraphNode) -> [GKGraphNode] {
    if start === goal { return [] }
    var open: [GKGraphNode] = [start]
    var cameFrom: [ObjectIdentifier: GKGraphNode] = [:]
    var gScore: [ObjectIdentifier: Float] = [ObjectIdentifier(start): 0]
    var fScore: [ObjectIdentifier: Float] = [ObjectIdentifier(start): start.estimatedCost(to: goal)]
    var closed = Set<ObjectIdentifier>()

    while !open.isEmpty {
        open.sort { a, b in
            (fScore[ObjectIdentifier(a)] ?? Float.greatestFiniteMagnitude)
                < (fScore[ObjectIdentifier(b)] ?? Float.greatestFiniteMagnitude)
        }
        let current = open.removeFirst()
        if current === goal {
            var path = [current]
            var cursor = current
            while let previous = cameFrom[ObjectIdentifier(cursor)] {
                path.insert(previous, at: 0)
                cursor = previous
            }
            return path
        }
        closed.insert(ObjectIdentifier(current))
        for neighbor in current.connectedNodes {
            let id = ObjectIdentifier(neighbor)
            if closed.contains(id) { continue }
            let tentative = (gScore[ObjectIdentifier(current)] ?? Float.greatestFiniteMagnitude) + current.cost(to: neighbor)
            if tentative >= (gScore[id] ?? Float.greatestFiniteMagnitude) { continue }
            cameFrom[id] = current
            gScore[id] = tentative
            fScore[id] = tentative + neighbor.estimatedCost(to: goal)
            if !open.contains(where: { $0 === neighbor }) {
                open.append(neighbor)
            }
        }
    }
    return []
}
