import Foundation

enum _SCNActionKind {
    case wait
    case moveBy(SCNVector3)
    case moveTo(SCNVector3)
    case scaleBy(Float)
    case scaleTo(Float)
    case fadeBy(Float)
    case fadeTo(Float)
    case hide(Bool)
    case removeFromParent
    case rotateBy(SCNVector3)
    case rotateTo(SCNVector3, shortest: Bool)
    case rotateAxis(Float, SCNVector3)
    case rotateToAxisAngle(SCNVector4)
    case sequence([SCNAction])
    case group([SCNAction])
    case `repeat`(SCNAction, count: Int)
    case repeatForever(SCNAction)
    case custom((SCNNode, CGFloat) -> Void)
    case run((SCNNode) -> Void)
    case playAudio
    case javaScript
}

final class _SCNActionRuntime {
    let action: SCNAction
    let key: String
    var elapsed: TimeInterval = 0
    var cancelled = false
    var finished = false
    var startPosition: SCNVector3?
    var startScale: SCNVector3?
    var startOpacity: CGFloat?
    var startRotation: SCNVector4?
    var sequenceIndex = 0
    var sequenceRuntimes: [_SCNActionRuntime] = []
    var groupRuntimes: [_SCNActionRuntime] = []
    var repeatRuntime: _SCNActionRuntime?
    var repeatRemaining: Int = 0
    var onFinish: (() -> Void)?

    init(action: SCNAction, key: String) {
        self.action = action
        self.key = key
    }
}

open class SCNAction: NSObject, NSCopying, NSSecureCoding {
    public var duration: TimeInterval
    public var speed: CGFloat
    public var timingMode: SCNActionTimingMode
    public var timingFunction: SCNActionTimingFunction?
    var kind: _SCNActionKind

    public override init() {
        duration = 0
        speed = 1
        timingMode = .linear
        kind = .wait
        super.init()
    }

    func _copyKind() -> _SCNActionKind { kind }

    public func reversed() -> SCNAction {
        let copy = SCNAction()
        copy.duration = duration
        copy.speed = speed
        copy.timingMode = timingMode
        copy.timingFunction = timingFunction
        switch kind {
        case .moveBy(let d):
            copy.kind = .moveBy(SCNVector3(x: -d.x, y: -d.y, z: -d.z))
        case .scaleBy(let s):
            copy.kind = .scaleBy(s == 0 ? 0 : 1 / s)
        case .fadeBy(let f):
            copy.kind = .fadeBy(-f)
        case .hide(let hidden):
            copy.kind = .hide(!hidden)
        case .sequence(let actions):
            copy.kind = .sequence(actions.reversed().map { $0.reversed() })
        case .group(let actions):
            copy.kind = .group(actions.map { $0.reversed() })
        case .rotateBy(let e):
            copy.kind = .rotateBy(SCNVector3(x: -e.x, y: -e.y, z: -e.z))
        default:
            copy.kind = kind
        }
        return copy
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SCNAction()
        copy.duration = duration
        copy.speed = speed
        copy.timingMode = timingMode
        copy.timingFunction = timingFunction
        copy.kind = kind
        return copy
    }

    public static var supportsSecureCoding: Bool { true }
    public required init?(coder: NSCoder) { return nil }
    public func encode(with coder: NSCoder) {}

    public class func wait(duration sec: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, sec)
        action.kind = .wait
        return action
    }

    public class func wait(duration sec: TimeInterval, withRange durationRange: TimeInterval) -> SCNAction {
        wait(duration: sec)
    }

    public class func move(by delta: SCNVector3, duration: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, duration)
        action.kind = .moveBy(delta)
        return action
    }

    public class func moveBy(x deltaX: CGFloat, y deltaY: CGFloat, z deltaZ: CGFloat, duration: TimeInterval) -> SCNAction {
        move(by: SCNVector3(deltaX, deltaY, deltaZ), duration: duration)
    }

    public class func move(to location: SCNVector3, duration: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, duration)
        action.kind = .moveTo(location)
        return action
    }

    public class func scale(by scale: CGFloat, duration sec: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, sec)
        action.kind = .scaleBy(Float(scale))
        return action
    }

    public class func scale(to scale: CGFloat, duration sec: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, sec)
        action.kind = .scaleTo(Float(scale))
        return action
    }

    public class func fadeIn(duration sec: TimeInterval) -> SCNAction {
        fadeOpacity(to: 1, duration: sec)
    }

    public class func fadeOut(duration sec: TimeInterval) -> SCNAction {
        fadeOpacity(to: 0, duration: sec)
    }

    public class func fadeOpacity(by factor: CGFloat, duration sec: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, sec)
        action.kind = .fadeBy(Float(factor))
        return action
    }

    public class func fadeOpacity(to opacity: CGFloat, duration sec: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, sec)
        action.kind = .fadeTo(Float(opacity))
        return action
    }

    public class func hide() -> SCNAction {
        let action = SCNAction()
        action.duration = 0
        action.kind = .hide(true)
        return action
    }

    public class func unhide() -> SCNAction {
        let action = SCNAction()
        action.duration = 0
        action.kind = .hide(false)
        return action
    }

    public class func removeFromParentNode() -> SCNAction {
        let action = SCNAction()
        action.duration = 0
        action.kind = .removeFromParent
        return action
    }

    public class func sequence(_ actions: [SCNAction]) -> SCNAction {
        let action = SCNAction()
        action.kind = .sequence(actions)
        action.duration = actions.reduce(0) { $0 + $1.duration }
        return action
    }

    public class func group(_ actions: [SCNAction]) -> SCNAction {
        let action = SCNAction()
        action.kind = .group(actions)
        action.duration = actions.map(\.duration).max() ?? 0
        return action
    }

    public class func `repeat`(_ action: SCNAction, count: Int) -> SCNAction {
        let wrapped = SCNAction()
        wrapped.kind = .repeat(action, count: max(0, count))
        wrapped.duration = action.duration * TimeInterval(max(0, count))
        return wrapped
    }

    public class func repeatForever(_ action: SCNAction) -> SCNAction {
        let wrapped = SCNAction()
        wrapped.kind = .repeatForever(action)
        wrapped.duration = .infinity
        return wrapped
    }

    public class func customAction(duration seconds: TimeInterval, action block: @escaping (SCNNode, CGFloat) -> Void) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, seconds)
        action.kind = .custom(block)
        return action
    }

    public class func run(_ block: @escaping (SCNNode) -> Void) -> SCNAction {
        let action = SCNAction()
        action.duration = 0
        action.kind = .run(block)
        return action
    }

    public class func rotate(by angle: CGFloat, around axis: SCNVector3, duration: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, duration)
        action.kind = .rotateAxis(Float(angle), axis)
        return action
    }

    public class func rotateBy(x xAngle: CGFloat, y yAngle: CGFloat, z zAngle: CGFloat, duration: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, duration)
        action.kind = .rotateBy(SCNVector3(xAngle, yAngle, zAngle))
        return action
    }

    public class func rotateTo(x xAngle: CGFloat, y yAngle: CGFloat, z zAngle: CGFloat, duration: TimeInterval) -> SCNAction {
        rotateTo(x: xAngle, y: yAngle, z: zAngle, duration: duration, usesShortestUnitArc: false)
    }

    public class func rotateTo(
        x xAngle: CGFloat,
        y yAngle: CGFloat,
        z zAngle: CGFloat,
        duration: TimeInterval,
        usesShortestUnitArc shortestUnitArc: Bool
    ) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, duration)
        action.kind = .rotateTo(SCNVector3(xAngle, yAngle, zAngle), shortest: shortestUnitArc)
        return action
    }

    public class func rotate(toAxisAngle axisAngle: SCNVector4, duration: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, duration)
        action.kind = .rotateToAxisAngle(axisAngle)
        return action
    }

    public class func playAudio(_ source: SCNAudioSource, waitForCompletion wait: Bool) -> SCNAction {
        let action = SCNAction()
        action.duration = wait ? max(0, TimeInterval(source.durationHint)) : 0
        action.kind = .playAudio
        return action
    }

    public class func javaScriptAction(withScript script: String, duration seconds: TimeInterval) -> SCNAction {
        let action = SCNAction()
        action.duration = max(0, seconds)
        action.kind = .javaScript
        return action
    }
}

func _scnSampleTiming(mode: SCNActionTimingMode, function: SCNActionTimingFunction?, t: Float) -> Float {
    let clamped = max(0, min(1, t))
    if let function {
        return function(clamped)
    }
    switch mode {
    case .linear:
        return clamped
    case .easeIn:
        return clamped * clamped
    case .easeOut:
        let u = 1 - clamped
        return 1 - u * u
    case .easeInEaseOut:
        return clamped * clamped * (3 - 2 * clamped)
    }
}

func _scnAdvanceAction(runtime: _SCNActionRuntime, node: SCNNode, dt: TimeInterval) -> TimeInterval {
    if runtime.cancelled || runtime.finished {
        return dt
    }
    let speed = TimeInterval(runtime.action.speed)
    if speed == 0 {
        return 0
    }
    var remaining = dt * speed
    switch runtime.action.kind {
    case .sequence(let children):
        if runtime.sequenceRuntimes.isEmpty {
            runtime.sequenceRuntimes = children.map { _SCNActionRuntime(action: $0, key: runtime.key) }
        }
        while runtime.sequenceIndex < runtime.sequenceRuntimes.count && remaining > 0 {
            let child = runtime.sequenceRuntimes[runtime.sequenceIndex]
            remaining = _scnAdvanceAction(runtime: child, node: node, dt: remaining)
            if child.finished || child.cancelled {
                runtime.sequenceIndex += 1
            } else {
                break
            }
        }
        if runtime.sequenceIndex >= runtime.sequenceRuntimes.count {
            runtime.finished = true
        }
        return remaining
    case .group(let children):
        if runtime.groupRuntimes.isEmpty {
            runtime.groupRuntimes = children.map { _SCNActionRuntime(action: $0, key: runtime.key) }
        }
        var leftover = remaining
        var allDone = true
        for child in runtime.groupRuntimes {
            let left = _scnAdvanceAction(runtime: child, node: node, dt: remaining)
            leftover = min(leftover, left)
            if !child.finished && !child.cancelled {
                allDone = false
            }
        }
        if allDone {
            runtime.finished = true
            return leftover
        }
        return 0
    case .repeat(let child, let count):
        if runtime.repeatRuntime == nil {
            runtime.repeatRemaining = count
            runtime.repeatRuntime = _SCNActionRuntime(action: child, key: runtime.key)
        }
        if count == 0 {
            runtime.finished = true
            return remaining
        }
        while runtime.repeatRemaining > 0 && remaining > 0 {
            guard let inner = runtime.repeatRuntime else { break }
            remaining = _scnAdvanceAction(runtime: inner, node: node, dt: remaining)
            if inner.finished {
                runtime.repeatRemaining -= 1
                if runtime.repeatRemaining > 0 {
                    runtime.repeatRuntime = _SCNActionRuntime(action: child, key: runtime.key)
                }
            } else {
                break
            }
        }
        if runtime.repeatRemaining <= 0 {
            runtime.finished = true
        }
        return remaining
    case .repeatForever(let child):
        if runtime.repeatRuntime == nil {
            runtime.repeatRuntime = _SCNActionRuntime(action: child, key: runtime.key)
        }
        while remaining > 0 {
            guard let inner = runtime.repeatRuntime else { break }
            remaining = _scnAdvanceAction(runtime: inner, node: node, dt: remaining)
            if inner.finished {
                runtime.repeatRuntime = _SCNActionRuntime(action: child, key: runtime.key)
            } else {
                break
            }
        }
        return 0
    default:
        break
    }

    let duration = max(runtime.action.duration, 0)
    if duration == 0 {
        _scnApplyAction(runtime: runtime, node: node, t: 1)
        runtime.finished = true
        return remaining
    }
    let before = runtime.elapsed
    runtime.elapsed += remaining
    var leftover: TimeInterval = 0
    var t: Float
    if runtime.elapsed >= duration {
        leftover = runtime.elapsed - duration
        runtime.elapsed = duration
        t = 1
        runtime.finished = true
    } else {
        t = Float(runtime.elapsed / duration)
        leftover = 0
    }
    _ = before
    let sampled = _scnSampleTiming(mode: runtime.action.timingMode, function: runtime.action.timingFunction, t: t)
    _scnApplyAction(runtime: runtime, node: node, t: sampled)
    return leftover
}

func _scnApplyAction(runtime: _SCNActionRuntime, node: SCNNode, t: Float) {
    switch runtime.action.kind {
    case .wait, .javaScript, .playAudio:
        return
    case .moveBy(let delta):
        if runtime.startPosition == nil { runtime.startPosition = node.position }
        if let start = runtime.startPosition {
            node.position = _scnAdd(start, _scnScale(delta, t))
        }
    case .moveTo(let dest):
        if runtime.startPosition == nil { runtime.startPosition = node.position }
        if let start = runtime.startPosition {
            node.position = _scnLerp(start, dest, t)
        }
    case .scaleBy(let factor):
        if runtime.startScale == nil { runtime.startScale = node.scale }
        if let start = runtime.startScale {
            let s = 1 + (factor - 1) * t
            node.scale = SCNVector3(x: start.x * s, y: start.y * s, z: start.z * s)
        }
    case .scaleTo(let value):
        if runtime.startScale == nil { runtime.startScale = node.scale }
        if let start = runtime.startScale {
            node.scale = _scnLerp(start, SCNVector3(x: value, y: value, z: value), t)
        }
    case .fadeBy(let factor):
        if runtime.startOpacity == nil { runtime.startOpacity = node.opacity }
        if let start = runtime.startOpacity {
            node.opacity = max(0, min(1, start + CGFloat(factor) * CGFloat(t)))
        }
    case .fadeTo(let value):
        if runtime.startOpacity == nil { runtime.startOpacity = node.opacity }
        if let start = runtime.startOpacity {
            node.opacity = start + (CGFloat(value) - start) * CGFloat(t)
        }
    case .hide(let hidden):
        if t >= 1 { node.isHidden = hidden }
    case .removeFromParent:
        if t >= 1 { node.removeFromParentNode() }
    case .rotateBy(let euler):
        if runtime.startRotation == nil { runtime.startRotation = node.rotation }
        if let start = runtime.startRotation {
            node.rotation = SCNVector4(x: start.x, y: start.y, z: start.z, w: start.w + euler.z * t)
        }
    case .rotateTo(let euler, _):
        node.eulerAngles = _scnLerp(node.eulerAngles, euler, t)
    case .rotateAxis(let angle, let axis):
        if runtime.startRotation == nil { runtime.startRotation = node.rotation }
        node.rotation = SCNVector4(x: axis.x, y: axis.y, z: axis.z, w: angle * t)
    case .rotateToAxisAngle(let axisAngle):
        if runtime.startRotation == nil { runtime.startRotation = node.rotation }
        if let start = runtime.startRotation {
            node.rotation = SCNVector4(
                x: start.x + (axisAngle.x - start.x) * t,
                y: start.y + (axisAngle.y - start.y) * t,
                z: start.z + (axisAngle.z - start.z) * t,
                w: start.w + (axisAngle.w - start.w) * t
            )
        }
    case .custom(let block):
        block(node, CGFloat(t))
    case .run(let block):
        if t >= 1 { block(node) }
    default:
        break
    }
}

open class SCNTransaction: NSObject {
    private struct Frame {
        var disableActions = false
        var animationDuration: TimeInterval = 0
        var completionBlock: (() -> Void)?
        var values: [String: Any] = [:]
    }

    private static var stack: [Frame] = [Frame()]
    private static var lockCount = 0

    private static var current: Frame {
        get { stack[stack.count - 1] }
        set { stack[stack.count - 1] = newValue }
    }

    public class func begin() {
        stack.append(current)
    }

    public class func commit() {
        let finished = stack.removeLast()
        if stack.isEmpty {
            stack = [Frame()]
        }
        finished.completionBlock?()
    }

    public class func flush() {}

    public class func lock() { lockCount += 1 }
    public class func unlock() { lockCount = max(0, lockCount - 1) }

    public class var disableActions: Bool {
        get { current.disableActions }
        set { current.disableActions = newValue }
    }

    public class var animationDuration: TimeInterval {
        get { current.animationDuration }
        set { current.animationDuration = newValue }
    }

    public class var completionBlock: (() -> Void)? {
        get { current.completionBlock }
        set { current.completionBlock = newValue }
    }

    public class func setValue(_ value: Any?, forKey key: String) {
        current.values[key] = value
    }

    public class func value(forKey key: String) -> Any? {
        current.values[key]
    }
}
