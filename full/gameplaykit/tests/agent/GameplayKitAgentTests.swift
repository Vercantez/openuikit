import Foundation
import GameplayKit

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
