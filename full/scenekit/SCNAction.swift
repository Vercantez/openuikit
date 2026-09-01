import Foundation

enum _SCNActionKind {
    case wait
    case hide
    case unhide
    case remove
    case fadeTo(CGFloat)
    case fadeBy(CGFloat)
    case moveBy(SCNVector3)
    case moveTo(SCNVector3)
    case rotateBy(SCNVector3)
    case rotateTo(SCNVector3, Bool)
    case rotateByAxis(Float, SCNVector3)
    case rotateToAxisAngle(SCNVector4)
    case scaleBy(Float)
    case scaleTo(Float)
    case sequence([SCNAction])
    case group([SCNAction])
    case `repeat`(SCNAction, Int?)
    case run((SCNNode) -> Void)
    case custom((SCNNode, CGFloat) -> Void)
    case javascript
    case playAudio
}

public final class SCNAction: NSObject {
    public var duration: TimeInterval
    public var speed: CGFloat = 1
    public var timingMode = SCNActionTimingMode.linear
    public var timingFunction: SCNActionTimingFunction?
    var kind: _SCNActionKind

    init(duration: TimeInterval, kind: _SCNActionKind) {
        self.duration = duration
        self.kind = kind
        super.init()
    }

    public required init?(coder: NSCoder) { return nil }

    public func reversed() -> SCNAction {
        switch kind {
        case .moveBy(let delta):
            return SCNAction(duration: duration, kind: .moveBy(_scnScale(delta, -1)))
        case .rotateBy(let delta):
            return SCNAction(duration: duration, kind: .rotateBy(_scnScale(delta, -1)))
        case .scaleBy(let factor):
            return SCNAction(duration: duration, kind: .scaleBy(factor == 0 ? 0 : 1 / factor))
        case .fadeBy(let factor):
            return SCNAction(duration: duration, kind: .fadeBy(-factor))
        case .hide:
            return SCNAction.unhide()
        case .unhide:
            return SCNAction.hide()
        case .sequence(let actions):
            return SCNAction.sequence(actions.reversed().map { $0.reversed() })
        default:
            return SCNAction(duration: duration, kind: kind)
        }
    }

    public static func wait(duration sec: TimeInterval) -> SCNAction {
        SCNAction(duration: sec, kind: .wait)
    }

    public static func wait(duration sec: TimeInterval, withRange durationRange: TimeInterval) -> SCNAction {
        _ = durationRange
        return wait(duration: sec)
    }

    public static func hide() -> SCNAction {
        SCNAction(duration: 0, kind: .hide)
    }

    public static func unhide() -> SCNAction {
        SCNAction(duration: 0, kind: .unhide)
    }

    public static func removeFromParentNode() -> SCNAction {
        SCNAction(duration: 0, kind: .remove)
    }

    public static func fadeIn(duration sec: TimeInterval) -> SCNAction {
        SCNAction(duration: sec, kind: .fadeTo(1))
    }

    public static func fadeOut(duration sec: TimeInterval) -> SCNAction {
        SCNAction(duration: sec, kind: .fadeTo(0))
    }

    public static func fadeOpacity(to opacity: CGFloat, duration sec: TimeInterval) -> SCNAction {
        SCNAction(duration: sec, kind: .fadeTo(opacity))
    }

    public static func fadeOpacity(by factor: CGFloat, duration sec: TimeInterval) -> SCNAction {
        SCNAction(duration: sec, kind: .fadeBy(factor))
    }

    public static func move(by delta: SCNVector3, duration: TimeInterval) -> SCNAction {
        SCNAction(duration: duration, kind: .moveBy(delta))
    }

    public static func moveBy(x deltaX: CGFloat, y deltaY: CGFloat, z deltaZ: CGFloat, duration: TimeInterval) -> SCNAction {
        move(by: SCNVector3(deltaX, deltaY, deltaZ), duration: duration)
    }

    public static func move(to location: SCNVector3, duration: TimeInterval) -> SCNAction {
        SCNAction(duration: duration, kind: .moveTo(location))
    }

    public static func rotateBy(x xAngle: CGFloat, y yAngle: CGFloat, z zAngle: CGFloat, duration: TimeInterval) -> SCNAction {
        SCNAction(duration: duration, kind: .rotateBy(SCNVector3(xAngle, yAngle, zAngle)))
    }

    public static func rotate(by angle: CGFloat, around axis: SCNVector3, duration: TimeInterval) -> SCNAction {
        SCNAction(duration: duration, kind: .rotateByAxis(Float(angle), axis))
    }

    public static func rotateTo(x xAngle: CGFloat, y yAngle: CGFloat, z zAngle: CGFloat, duration: TimeInterval) -> SCNAction {
        rotateTo(x: xAngle, y: yAngle, z: zAngle, duration: duration, usesShortestUnitArc: false)
    }

    public static func rotateTo(
        x xAngle: CGFloat,
        y yAngle: CGFloat,
        z zAngle: CGFloat,
        duration: TimeInterval,
        usesShortestUnitArc shortestUnitArc: Bool
    ) -> SCNAction {
        SCNAction(duration: duration, kind: .rotateTo(SCNVector3(xAngle, yAngle, zAngle), shortestUnitArc))
    }

    public static func rotate(toAxisAngle axisAngle: SCNVector4, duration: TimeInterval) -> SCNAction {
        SCNAction(duration: duration, kind: .rotateToAxisAngle(axisAngle))
    }

    public static func scale(by scale: CGFloat, duration sec: TimeInterval) -> SCNAction {
        SCNAction(duration: sec, kind: .scaleBy(Float(scale)))
    }

    public static func scale(to scale: CGFloat, duration sec: TimeInterval) -> SCNAction {
        SCNAction(duration: sec, kind: .scaleTo(Float(scale)))
    }

    public static func sequence(_ actions: [SCNAction]) -> SCNAction {
        let duration = actions.reduce(0) { $0 + $1.duration }
        return SCNAction(duration: duration, kind: .sequence(actions))
    }

    public static func group(_ actions: [SCNAction]) -> SCNAction {
        let duration = actions.map(\.duration).max() ?? 0
        return SCNAction(duration: duration, kind: .group(actions))
    }

    public static func `repeat`(_ action: SCNAction, count: Int) -> SCNAction {
        SCNAction(duration: action.duration * TimeInterval(max(0, count)), kind: .repeat(action, count))
    }

    public static func repeatForever(_ action: SCNAction) -> SCNAction {
        SCNAction(duration: .infinity, kind: .repeat(action, nil))
    }

    public static func run(_ block: @escaping (SCNNode) -> Void) -> SCNAction {
        SCNAction(duration: 0, kind: .run(block))
    }

    public static func run(_ block: @escaping (SCNNode) -> Void, queue: dispatch_queue_t) -> SCNAction {
        SCNAction(duration: 0, kind: .run { node in
            queue.async { block(node) }
        })
    }

    public static func customAction(duration seconds: TimeInterval, action block: @escaping (SCNNode, CGFloat) -> Void) -> SCNAction {
        SCNAction(duration: seconds, kind: .custom(block))
    }

    public static func javaScriptAction(withScript script: String, duration seconds: TimeInterval) -> SCNAction {
        _ = script
        return SCNAction(duration: seconds, kind: .javascript)
    }

    public static func playAudio(_ source: SCNAudioSource, waitForCompletion wait: Bool) -> SCNAction {
        _ = source
        return SCNAction(duration: wait ? 0 : 0, kind: .playAudio)
    }
}

final class _SCNActionState {
    let action: SCNAction
    var elapsed: TimeInterval = 0
    var started = false
    var startPosition = SCNVector3Zero
    var startEuler = SCNVector3Zero
    var startScale = SCNVector3(1, 1, 1)
    var startOpacity: CGFloat = 1
    var childStates: [_SCNActionState] = []
    var sequenceIndex = 0
    var repeatRemaining: Int?
    var continuation: CheckedContinuation<Void, Error>?
    var didResume = false

    init(action: SCNAction) {
        self.action = action
        switch action.kind {
        case .sequence(let actions):
            childStates = actions.map { _SCNActionState(action: $0) }
        case .group(let actions):
            childStates = actions.map { _SCNActionState(action: $0) }
        case .repeat(let inner, let count):
            childStates = [_SCNActionState(action: inner)]
            repeatRemaining = count
        default:
            break
        }
    }

    func resumeSuccess() {
        guard !didResume else { return }
        didResume = true
        continuation?.resume(returning: ())
        continuation = nil
    }

    func resumeCancel() {
        guard !didResume else { return }
        didResume = true
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
}
