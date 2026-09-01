#if canImport(simd)
import simd
#endif
import Foundation

public protocol GKAgentDelegate: NSObjectProtocol {
    func agentDidUpdate(_ agent: GKAgent)
    func agentWillUpdate(_ agent: GKAgent)
}

public extension GKAgentDelegate {
    func agentDidUpdate(_ agent: GKAgent) {}
    func agentWillUpdate(_ agent: GKAgent) {}
}

enum GKGoalKind {
    case seek(GKAgent)
    case flee(GKAgent)
    case avoidAgents([GKAgent], TimeInterval)
    case avoidObstacles([GKObstacle], TimeInterval)
    case separate([GKAgent], Float, Float)
    case align([GKAgent], Float, Float)
    case cohere([GKAgent], Float, Float)
    case reachSpeed(Float)
    case wander(Float)
    case intercept(GKAgent, TimeInterval)
    case follow(GKPath, TimeInterval, Bool)
    case stayOn(GKPath, TimeInterval)
}

open class GKGoal: NSObject, NSCopying {
    let kind: GKGoalKind

    init(kind: GKGoalKind) {
        self.kind = kind
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        GKGoal(kind: kind)
    }

    public convenience init(toSeekAgent agent: GKAgent) {
        self.init(kind: .seek(agent))
    }

    public convenience init(toFleeAgent agent: GKAgent) {
        self.init(kind: .flee(agent))
    }

    public convenience init(toAvoid agents: [GKAgent], maxPredictionTime: TimeInterval) {
        self.init(kind: .avoidAgents(agents, maxPredictionTime))
    }

    public convenience init(toAvoidAgents agents: [GKAgent], maxPredictionTime: TimeInterval) {
        self.init(toAvoid: agents, maxPredictionTime: maxPredictionTime)
    }

    public convenience init(toAvoid obstacles: [GKObstacle], maxPredictionTime: TimeInterval) {
        self.init(kind: .avoidObstacles(obstacles, maxPredictionTime))
    }

    public convenience init(toAvoidObstacles obstacles: [GKObstacle], maxPredictionTime: TimeInterval) {
        self.init(toAvoid: obstacles, maxPredictionTime: maxPredictionTime)
    }

    public convenience init(toSeparateFrom agents: [GKAgent], maxDistance: Float, maxAngle: Float) {
        self.init(kind: .separate(agents, maxDistance, maxAngle))
    }

    public convenience init(toSeparateFromAgents agents: [GKAgent], maxDistance: Float, maxAngle: Float) {
        self.init(toSeparateFrom: agents, maxDistance: maxDistance, maxAngle: maxAngle)
    }

    public convenience init(toAlignWith agents: [GKAgent], maxDistance: Float, maxAngle: Float) {
        self.init(kind: .align(agents, maxDistance, maxAngle))
    }

    public convenience init(toAlignWithAgents agents: [GKAgent], maxDistance: Float, maxAngle: Float) {
        self.init(toAlignWith: agents, maxDistance: maxDistance, maxAngle: maxAngle)
    }

    public convenience init(toCohereWith agents: [GKAgent], maxDistance: Float, maxAngle: Float) {
        self.init(kind: .cohere(agents, maxDistance, maxAngle))
    }

    public convenience init(toCohereWithAgents agents: [GKAgent], maxDistance: Float, maxAngle: Float) {
        self.init(toCohereWith: agents, maxDistance: maxDistance, maxAngle: maxAngle)
    }

    public convenience init(toReachTargetSpeed targetSpeed: Float) {
        self.init(kind: .reachSpeed(targetSpeed))
    }

    public convenience init(toWander speed: Float) {
        self.init(kind: .wander(speed))
    }

    public convenience init(toInterceptAgent target: GKAgent, maxPredictionTime: TimeInterval) {
        self.init(kind: .intercept(target, maxPredictionTime))
    }

    public convenience init(toFollow path: GKPath, maxPredictionTime: TimeInterval, forward: Bool) {
        self.init(kind: .follow(path, maxPredictionTime, forward))
    }

    public convenience init(toFollowPath path: GKPath, maxPredictionTime: TimeInterval, forward: Bool) {
        self.init(toFollow: path, maxPredictionTime: maxPredictionTime, forward: forward)
    }

    public convenience init(toStayOn path: GKPath, maxPredictionTime: TimeInterval) {
        self.init(kind: .stayOn(path, maxPredictionTime))
    }

    public convenience init(toStayOnPath path: GKPath, maxPredictionTime: TimeInterval) {
        self.init(toStayOn: path, maxPredictionTime: maxPredictionTime)
    }
}

open class GKBehavior: NSObject, NSCopying {
    private var ordered: [GKGoal] = []
    private var weights: [ObjectIdentifier: Float] = [:]

    public var goalCount: Int { ordered.count }

    public override init() {
        super.init()
    }

    public convenience init(goal: GKGoal, weight: Float) {
        self.init()
        setWeight(weight, for: goal)
    }

    public convenience init(goals: [GKGoal]) {
        self.init()
        for goal in goals {
            setWeight(1, for: goal)
        }
    }

    public convenience init(goals: [GKGoal], andWeights weights: [NSNumber]) {
        self.init()
        for (index, goal) in goals.enumerated() {
            let weight = index < weights.count ? weights[index].floatValue : 1
            setWeight(weight, for: goal)
        }
    }

    public convenience init(weightedGoals: [GKGoal: NSNumber]) {
        self.init()
        for (goal, weight) in weightedGoals {
            setWeight(weight.floatValue, for: goal)
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = GKBehavior()
        copy.ordered = ordered
        copy.weights = weights
        return copy
    }

    open func setWeight(_ weight: Float, for goal: GKGoal) {
        let id = ObjectIdentifier(goal)
        if weights[id] == nil {
            ordered.append(goal)
        }
        weights[id] = weight
    }

    open func weight(for goal: GKGoal) -> Float {
        weights[ObjectIdentifier(goal)] ?? 0
    }

    open func remove(_ goal: GKGoal) {
        let id = ObjectIdentifier(goal)
        weights.removeValue(forKey: id)
        ordered.removeAll { $0 === goal }
    }

    open func removeAllGoals() {
        ordered.removeAll()
        weights.removeAll()
    }

    open subscript(idx: Int) -> GKGoal {
        ordered[idx]
    }

    open subscript(goal: GKGoal) -> NSNumber! {
        get { NSNumber(value: weight(for: goal)) }
        set {
            if let value = newValue {
                setWeight(value.floatValue, for: goal)
            } else {
                remove(goal)
            }
        }
    }

    func weightedGoals() -> [(GKGoal, Float)] {
        ordered.map { ($0, weights[ObjectIdentifier($0)] ?? 0) }
    }
}

open class GKCompositeBehavior: GKBehavior {
    private var behaviors: [GKBehavior] = []
    private var behaviorWeights: [ObjectIdentifier: Float] = [:]

    public var behaviorCount: Int { behaviors.count }

    public convenience init(behaviors: [GKBehavior]) {
        self.init()
        for behavior in behaviors {
            setWeight(1, for: behavior)
        }
    }

    public convenience init(behaviors: [GKBehavior], andWeights weights: [NSNumber]) {
        self.init()
        for (index, behavior) in behaviors.enumerated() {
            let weight = index < weights.count ? weights[index].floatValue : 1
            setWeight(weight, for: behavior)
        }
    }

    open func setWeight(_ weight: Float, for behavior: GKBehavior) {
        let id = ObjectIdentifier(behavior)
        if behaviorWeights[id] == nil {
            behaviors.append(behavior)
        }
        behaviorWeights[id] = weight
    }

    open func weight(for behavior: GKBehavior) -> Float {
        behaviorWeights[ObjectIdentifier(behavior)] ?? 0
    }

    open func remove(_ behavior: GKBehavior) {
        behaviorWeights.removeValue(forKey: ObjectIdentifier(behavior))
        behaviors.removeAll { $0 === behavior }
    }

    open func removeAllBehaviors() {
        behaviors.removeAll()
        behaviorWeights.removeAll()
    }

    open subscript(idx: Int) -> GKBehavior {
        behaviors[idx]
    }

    open subscript(behavior: GKBehavior) -> NSNumber {
        get { NSNumber(value: weight(for: behavior)) }
        set { setWeight(newValue.floatValue, for: behavior) }
    }

    func weightedBehaviors() -> [(GKBehavior, Float)] {
        behaviors.map { ($0, behaviorWeights[ObjectIdentifier($0)] ?? 0) }
    }
}

open class GKObstacle: NSObject {}

open class GKCircleObstacle: GKObstacle {
    public var radius: Float
    public var position: SIMD2<Float>

    public init(radius: Float) {
        self.radius = radius
        self.position = SIMD2<Float>(0, 0)
        super.init()
    }
}

open class GKSphereObstacle: GKObstacle {
    public var radius: Float
    public var position: SIMD3<Float>

    public init(radius: Float) {
        self.radius = radius
        self.position = SIMD3<Float>(0, 0, 0)
        super.init()
    }
}

open class GKPolygonObstacle: GKObstacle, NSCopying {
    private var vertices: [SIMD2<Float>]

    public var vertexCount: Int { vertices.count }

    public init(points: [SIMD2<Float>]) {
        self.vertices = points
        super.init()
    }

    public required init?(coder: NSCoder) {
        vertices = []
        super.init()
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        GKPolygonObstacle(points: vertices)
    }

    open func vertex(at index: Int) -> SIMD2<Float> {
        vertices[index]
    }

    func allVertices() -> [SIMD2<Float>] { vertices }
}

open class GKPath: NSObject {
    private var points3D: [SIMD3<Float>]
    public var radius: Float
    public var isCyclical: Bool

    public var numPoints: Int { points3D.count }

    public init(graphNodes: [GKGraphNode], radius: Float) {
        self.radius = radius
        self.isCyclical = false
        self.points3D = graphNodes.map { node in
            if let n2 = node as? GKGraphNode2D {
                return SIMD3<Float>(n2.position.x, n2.position.y, 0)
            }
            if let n3 = node as? GKGraphNode3D {
                return n3.position
            }
            if let grid = node as? GKGridGraphNode {
                return SIMD3<Float>(Float(grid.gridPosition.x), Float(grid.gridPosition.y), 0)
            }
            return SIMD3<Float>(0, 0, 0)
        }
        super.init()
    }

    public convenience init(points: [SIMD2<Float>], radius: Float, cyclical: Bool) {
        let mapped = points.map { SIMD3<Float>($0.x, $0.y, 0) }
        self.init(points3D: mapped, radius: radius, cyclical: cyclical)
    }

    public convenience init(points: [SIMD3<Float>], radius: Float, cyclical: Bool) {
        self.init(points3D: points, radius: radius, cyclical: cyclical)
    }

    init(points3D: [SIMD3<Float>], radius: Float, cyclical: Bool) {
        self.points3D = points3D
        self.radius = radius
        self.isCyclical = cyclical
        super.init()
    }

    open func float2(at index: Int) -> SIMD2<Float> {
        let p = points3D[index]
        return SIMD2<Float>(p.x, p.y)
    }

    open func float3(at index: Int) -> SIMD3<Float> {
        points3D[index]
    }

    open func point(at index: Int) -> SIMD2<Float> {
        float2(at: index)
    }

    func closestPoint(to point: SIMD2<Float>) -> (SIMD2<Float>, Int) {
        guard !points3D.isEmpty else { return (point, 0) }
        var bestIndex = 0
        var best = float2(at: 0)
        var bestDist = gkDistance(point, best)
        for index in 1..<numPoints {
            let candidate = float2(at: index)
            let dist = gkDistance(point, candidate)
            if dist < bestDist {
                bestDist = dist
                best = candidate
                bestIndex = index
            }
        }
        return (best, bestIndex)
    }
}

open class GKAgent: GKComponent {
    public var behavior: GKBehavior?
    public weak var delegate: (any GKAgentDelegate)?
    public var mass: Float = 1
    public var radius: Float = 0.5
    public var speed: Float = 0
    public var maxAcceleration: Float = 100
    public var maxSpeed: Float = 100
    var wanderTheta: Float = 0

    func applySteering(_ steering: SIMD3<Float>, deltaTime: TimeInterval) -> SIMD3<Float> {
        var force = steering
        let forceLength = gkLength(force)
        if forceLength > maxAcceleration && forceLength > 0 {
            force = gkNormalize(force) * maxAcceleration
        }
        let safeMass = max(mass, 1e-4)
        return force / safeMass * Float(deltaTime)
    }
}

open class GKAgent2D: GKAgent {
    public var position: SIMD2<Float> = SIMD2<Float>(0, 0)
    public var rotation: Float = 0
    public private(set) var velocity: SIMD2<Float> = SIMD2<Float>(0, 0)

    open override func update(deltaTime seconds: TimeInterval) {
        guard seconds > 0 else { return }
        delegate?.agentWillUpdate(self)
        let steering = steeringForce(deltaTime: seconds)
        let deltaV = applySteering(SIMD3<Float>(steering.x, steering.y, 0), deltaTime: seconds)
        velocity += SIMD2<Float>(deltaV.x, deltaV.y)
        let speedLength = gkLength(velocity)
        if speedLength > maxSpeed {
            velocity = gkNormalize(velocity) * maxSpeed
        }
        speed = gkLength(velocity)
        position += velocity * Float(seconds)
        if speed > 1e-5 {
            rotation = atan2(velocity.y, velocity.x)
        }
        delegate?.agentDidUpdate(self)
    }

    private func steeringForce(deltaTime: TimeInterval) -> SIMD2<Float> {
        _ = deltaTime
        var total = SIMD2<Float>(0, 0)
        let behaviors: [(GKBehavior, Float)]
        if let composite = behavior as? GKCompositeBehavior {
            behaviors = composite.weightedBehaviors()
        } else if let behavior {
            behaviors = [(behavior, 1)]
        } else {
            behaviors = []
        }
        for (behavior, behaviorWeight) in behaviors {
            for (goal, weight) in behavior.weightedGoals() {
                total += goalForce(goal, deltaTime: deltaTime) * (weight * behaviorWeight)
            }
        }
        return total
    }

    private func seek(toward target: SIMD2<Float>) -> SIMD2<Float> {
        let desired = gkNormalize(target - position) * maxSpeed
        return desired - velocity
    }

    private func goalForce(_ goal: GKGoal, deltaTime: TimeInterval) -> SIMD2<Float> {
        _ = deltaTime
        switch goal.kind {
        case .seek(let agent):
            return seek(toward: agentPosition2(agent))
        case .flee(let agent):
            return -seek(toward: agentPosition2(agent))
        case .reachSpeed(let targetSpeed):
            let current = gkLength(velocity)
            let desiredSpeed = gkClamp(targetSpeed, 0, maxSpeed)
            if current < 1e-5 {
                let heading = SIMD2<Float>(cos(rotation), sin(rotation))
                return heading * desiredSpeed
            }
            return gkNormalize(velocity) * (desiredSpeed - current)
        case .wander(let wanderSpeed):
            wanderTheta += (GKRandomSource.sharedRandom().nextUniform() - 0.5) * 0.8
            let heading = SIMD2<Float>(cos(rotation + wanderTheta), sin(rotation + wanderTheta))
            return heading * wanderSpeed - velocity
        case .intercept(let agent, let prediction):
            let targetPos = agentPosition2(agent)
            let targetVel = agentVelocity2(agent)
            let predict = min(Float(prediction), gkDistance(position, targetPos) / max(maxSpeed, 1e-3))
            return seek(toward: targetPos + targetVel * predict)
        case .avoidAgents(let agents, let prediction):
            var force = SIMD2<Float>(0, 0)
            for other in agents where other !== self {
                let relative = agentPosition2(other) + agentVelocity2(other) * Float(prediction) - position
                let distance = gkLength(relative)
                let combined = radius + other.radius
                if distance < combined * 4 && distance > 1e-5 {
                    force -= gkNormalize(relative) * (combined / distance)
                }
            }
            return force * maxSpeed
        case .avoidObstacles(let obstacles, _):
            var force = SIMD2<Float>(0, 0)
            for obstacle in obstacles {
                if let circle = obstacle as? GKCircleObstacle {
                    let offset = position - circle.position
                    let distance = gkLength(offset)
                    let combined = radius + circle.radius
                    if distance < combined * 2 && distance > 1e-5 {
                        force += gkNormalize(offset) * (combined / distance)
                    }
                } else if let polygon = obstacle as? GKPolygonObstacle {
                    let verts = polygon.allVertices()
                    if gkPointInPolygon(position, verts) {
                        force += SIMD2<Float>(cos(rotation + Float.pi), sin(rotation + Float.pi)) * maxSpeed
                    }
                }
            }
            return force * maxSpeed
        case .separate(let agents, let maxDistance, _):
            var force = SIMD2<Float>(0, 0)
            var count: Float = 0
            for other in agents where other !== self {
                let offset = position - agentPosition2(other)
                let distance = gkLength(offset)
                if distance < maxDistance && distance > 1e-5 {
                    force += gkNormalize(offset) / distance
                    count += 1
                }
            }
            if count > 0 { force /= count }
            return force * maxSpeed
        case .align(let agents, let maxDistance, _):
            var heading = SIMD2<Float>(0, 0)
            var count: Float = 0
            for other in agents where other !== self {
                if gkDistance(position, agentPosition2(other)) <= maxDistance {
                    heading += agentVelocity2(other)
                    count += 1
                }
            }
            if count == 0 { return SIMD2<Float>(0, 0) }
            heading /= count
            return heading - velocity
        case .cohere(let agents, let maxDistance, _):
            var center = SIMD2<Float>(0, 0)
            var count: Float = 0
            for other in agents where other !== self {
                let otherPos = agentPosition2(other)
                if gkDistance(position, otherPos) <= maxDistance {
                    center += otherPos
                    count += 1
                }
            }
            if count == 0 { return SIMD2<Float>(0, 0) }
            return seek(toward: center / count)
        case .follow(let path, _, let forward):
            guard path.numPoints > 0 else { return SIMD2<Float>(0, 0) }
            let (_, index) = path.closestPoint(to: position)
            let nextIndex: Int
            if forward {
                nextIndex = min(index + 1, path.numPoints - 1)
            } else {
                nextIndex = max(index - 1, 0)
            }
            return seek(toward: path.float2(at: nextIndex))
        case .stayOn(let path, _):
            let (closest, _) = path.closestPoint(to: position)
            if gkDistance(position, closest) > path.radius {
                return seek(toward: closest)
            }
            return SIMD2<Float>(0, 0)
        }
    }

    private func agentPosition2(_ agent: GKAgent) -> SIMD2<Float> {
        if let agent2 = agent as? GKAgent2D {
            return agent2.position
        }
        if let agent3 = agent as? GKAgent3D {
            return SIMD2<Float>(agent3.position.x, agent3.position.y)
        }
        return SIMD2<Float>(0, 0)
    }

    private func agentVelocity2(_ agent: GKAgent) -> SIMD2<Float> {
        if let agent2 = agent as? GKAgent2D {
            return agent2.velocity
        }
        if let agent3 = agent as? GKAgent3D {
            return SIMD2<Float>(agent3.velocity.x, agent3.velocity.y)
        }
        return SIMD2<Float>(0, 0)
    }
}

open class GKAgent3D: GKAgent {
    public var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    public var rightHanded: Bool = true
    public private(set) var velocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var forwardAxis: SIMD3<Float> = SIMD3<Float>(0, 0, 1)
    #if canImport(simd)
    public var rotation = matrix_float3x3(
        SIMD3<Float>(1, 0, 0),
        SIMD3<Float>(0, 1, 0),
        SIMD3<Float>(0, 0, 1)
    )
    #endif

    open override func update(deltaTime seconds: TimeInterval) {
        guard seconds > 0 else { return }
        delegate?.agentWillUpdate(self)
        var steering = SIMD3<Float>(0, 0, 0)
        if let behavior {
            for (goal, weight) in behavior.weightedGoals() {
                steering += goalForce(goal) * weight
            }
        }
        let deltaV = applySteering(steering, deltaTime: seconds)
        velocity += deltaV
        let speedLength = gkLength(velocity)
        if speedLength > maxSpeed {
            velocity = gkNormalize(velocity) * maxSpeed
        }
        speed = gkLength(velocity)
        position += velocity * Float(seconds)
        if speed > 1e-5 {
            let forward = gkNormalize(velocity)
            forwardAxis = forward
            #if canImport(simd)
            let up = SIMD3<Float>(0, 1, 0)
            var right = SIMD3<Float>(
                up.y * forward.z - up.z * forward.y,
                up.z * forward.x - up.x * forward.z,
                up.x * forward.y - up.y * forward.x
            )
            if gkLength(right) < 1e-5 {
                right = SIMD3<Float>(1, 0, 0)
            } else {
                right = gkNormalize(right)
            }
            if !rightHanded {
                right = -right
            }
            let trueUp = SIMD3<Float>(
                forward.y * right.z - forward.z * right.y,
                forward.z * right.x - forward.x * right.z,
                forward.x * right.y - forward.y * right.x
            )
            rotation = matrix_float3x3(right, trueUp, forward)
            #endif
        }
        delegate?.agentDidUpdate(self)
    }

    private func goalForce(_ goal: GKGoal) -> SIMD3<Float> {
        switch goal.kind {
        case .seek(let agent):
            return seek(toward: agentPosition3(agent))
        case .flee(let agent):
            return -seek(toward: agentPosition3(agent))
        case .reachSpeed(let targetSpeed):
            let current = gkLength(velocity)
            if current < 1e-5 {
                return forwardAxis * targetSpeed
            }
            return gkNormalize(velocity) * (targetSpeed - current)
        case .wander(let wanderSpeed):
            wanderTheta += (GKRandomSource.sharedRandom().nextUniform() - 0.5) * 0.8
            let yaw = wanderTheta
            let dir = SIMD3<Float>(cos(yaw), 0, sin(yaw))
            return dir * wanderSpeed - velocity
        case .intercept(let agent, let prediction):
            let targetPos = agentPosition3(agent)
            let targetVel = agentVelocity3(agent)
            let predict = min(Float(prediction), gkDistance(position, targetPos) / max(maxSpeed, 1e-3))
            return seek(toward: targetPos + targetVel * predict)
        default:
            return SIMD3<Float>(0, 0, 0)
        }
    }

    private func seek(toward target: SIMD3<Float>) -> SIMD3<Float> {
        gkNormalize(target - position) * maxSpeed - velocity
    }

    private func agentPosition3(_ agent: GKAgent) -> SIMD3<Float> {
        if let agent3 = agent as? GKAgent3D {
            return agent3.position
        }
        if let agent2 = agent as? GKAgent2D {
            return SIMD3<Float>(agent2.position.x, agent2.position.y, 0)
        }
        return SIMD3<Float>(0, 0, 0)
    }

    private func agentVelocity3(_ agent: GKAgent) -> SIMD3<Float> {
        if let agent3 = agent as? GKAgent3D {
            return agent3.velocity
        }
        if let agent2 = agent as? GKAgent2D {
            return SIMD3<Float>(agent2.velocity.x, agent2.velocity.y, 0)
        }
        return SIMD3<Float>(0, 0, 0)
    }
}
