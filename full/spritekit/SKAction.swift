import Foundation
#if canImport(Dispatch)
import Dispatch
#endif

enum _SKActionKind {
    case wait
    case moveBy(CGVector)
    case moveTo(CGPoint, axisX: Bool, axisY: Bool)
    case fadeBy(CGFloat)
    case fadeTo(CGFloat)
    case scaleBy(x: CGFloat, y: CGFloat)
    case scaleTo(x: CGFloat?, y: CGFloat?)
    case rotateBy(CGFloat)
    case rotateTo(CGFloat, shortest: Bool)
    case resizeBy(w: CGFloat, h: CGFloat)
    case resizeTo(w: CGFloat?, h: CGFloat?)
    case hide(Bool)
    case removeFromParent
    case speedBy(CGFloat)
    case speedTo(CGFloat)
    case sequence([SKAction])
    case group([SKAction])
    case `repeat`(SKAction, count: Int)
    case repeatForever(SKAction)
    case custom((SKNode, CGFloat) -> Void)
    case run(() -> Void)
    case runAction(SKAction, child: String)
    case setTexture(SKTexture?, resize: Bool, normal: Bool)
    case animate([SKTexture], timePerFrame: TimeInterval, resize: Bool, restore: Bool)
    case playSound
    case playPause(Int)
    case physicsImpulse(force: CGVector?, angular: CGFloat?, torque: CGFloat?)
    case changeFloat(key: String, to: Float?, by: Float?)
    case colorize(SKColor?, blend: CGFloat?)
    case follow
    case reach
    case warp
    case perform
}

final class _SKActionRuntime {
    let action: SKAction
    let key: String?
    var elapsed: TimeInterval = 0
    var cancelled = false
    var finished = false
    var startPoint: CGPoint?
    var startAlpha: CGFloat?
    var startXScale: CGFloat?
    var startYScale: CGFloat?
    var startRotation: CGFloat?
    var startSpeed: CGFloat?
    var startWidth: CGFloat?
    var startHeight: CGFloat?
    var sequenceIndex = 0
    var sequenceRuntime: _SKActionRuntime?
    var groupRuntimes: [_SKActionRuntime] = []
    var repeatRuntime: _SKActionRuntime?
    var repeatRemaining = 0
    var animationIndex = 0
    var animationElapsed: TimeInterval = 0
    var restoredTexture: SKTexture?

    init(action: SKAction, key: String?) {
        self.action = action
        self.key = key
    }

    func step(on node: SKNode, dt: TimeInterval) {
        guard !cancelled, !finished else { return }
        switch action.kind {
        case .sequence(let actions):
            stepSequence(actions, on: node, dt: dt)
        case .group(let actions):
            stepGroup(actions, on: node, dt: dt)
        case .repeat(let inner, let count):
            stepRepeat(inner, remaining: count, forever: false, on: node, dt: dt)
        case .repeatForever(let inner):
            stepRepeat(inner, remaining: 0, forever: true, on: node, dt: dt)
        case .runAction(let inner, let childName):
            if let child = node.childNode(withName: childName) {
                if sequenceRuntime == nil {
                    sequenceRuntime = _SKActionRuntime(action: inner, key: nil)
                }
                sequenceRuntime?.step(on: child, dt: dt)
                if sequenceRuntime?.finished == true { finished = true }
            } else {
                finished = true
            }
        default:
            stepSimple(on: node, dt: dt)
        }
    }

    private func duration() -> TimeInterval {
        let speed = max(0.0001, TimeInterval(action.speed))
        return max(0, action.duration) / speed
    }

    private func progress() -> CGFloat {
        let d = duration()
        if d <= 0 { return 1 }
        var t = CGFloat(elapsed / d)
        t = sk_clamp(t, 0, 1)
        t = sk_timing(action.timingMode, t)
        t = CGFloat(action.timingFunction(Float(t)))
        return t
    }

    private func stepSimple(on node: SKNode, dt: TimeInterval) {
        if startPoint == nil { capture(node) }
        elapsed += dt
        let t = progress()
        apply(t, on: node)
        if elapsed >= duration() {
            apply(1, on: node)
            finished = true
        }
    }

    private func capture(_ node: SKNode) {
        startPoint = node.position
        startAlpha = node.alpha
        startXScale = node.xScale
        startYScale = node.yScale
        startRotation = node.zRotation
        startSpeed = node.speed
        if let sprite = node as? SKSpriteNode {
            startWidth = sprite.size.width
            startHeight = sprite.size.height
            restoredTexture = sprite.texture
        }
        switch action.kind {
        case .run(let block):
            block()
        case .hide(let hidden):
            node.isHidden = hidden
        case .removeFromParent:
            node.removeFromParent()
        case .playSound, .playPause, .follow, .reach, .warp, .perform:
            break
        case .setTexture(let texture, let resize, let normal):
            if let sprite = node as? SKSpriteNode {
                if normal {
                    sprite.normalTexture = texture
                } else {
                    sprite.texture = texture
                    if resize, let texture {
                        sprite.size = texture.size()
                    }
                }
            }
        case .custom(let block):
            block(node, 0)
        default:
            break
        }
    }

    private func apply(_ t: CGFloat, on node: SKNode) {
        switch action.kind {
        case .wait, .playSound, .playPause, .follow, .reach, .warp, .perform, .setTexture, .hide, .removeFromParent, .run:
            break
        case .moveBy(let delta):
            if let start = startPoint {
                node.position = CGPoint(x: start.x + delta.dx * t, y: start.y + delta.dy * t)
            }
        case .moveTo(let dest, let axisX, let axisY):
            if let start = startPoint {
                node.position = CGPoint(
                    x: axisX ? sk_lerp(start.x, dest.x, t) : start.x,
                    y: axisY ? sk_lerp(start.y, dest.y, t) : start.y
                )
            }
        case .fadeBy(let factor):
            if let start = startAlpha {
                node.alpha = sk_clamp(start + factor * t, 0, 1)
            }
        case .fadeTo(let alpha):
            if let start = startAlpha {
                node.alpha = sk_lerp(start, alpha, t)
            }
        case .scaleBy(let x, let y):
            if let sx = startXScale, let sy = startYScale {
                node.xScale = sx * sk_lerp(1, x, t)
                node.yScale = sy * sk_lerp(1, y, t)
            }
        case .scaleTo(let x, let y):
            if let sx = startXScale, let sy = startYScale {
                if let x { node.xScale = sk_lerp(sx, x, t) }
                if let y { node.yScale = sk_lerp(sy, y, t) }
            }
        case .rotateBy(let angle):
            if let start = startRotation {
                node.zRotation = start + angle * t
            }
        case .rotateTo(let angle, let shortest):
            if let start = startRotation {
                var target = angle
                if shortest {
                    var delta = target - start
                    while delta > .pi { delta -= 2 * .pi }
                    while delta < -.pi { delta += 2 * .pi }
                    target = start + delta
                }
                node.zRotation = sk_lerp(start, target, t)
            }
        case .resizeBy(let w, let h):
            if let sprite = node as? SKSpriteNode, let sw = startWidth, let sh = startHeight {
                sprite.size = CGSize(width: sw + w * t, height: sh + h * t)
            }
        case .resizeTo(let w, let h):
            if let sprite = node as? SKSpriteNode, let sw = startWidth, let sh = startHeight {
                sprite.size = CGSize(
                    width: w.map { sk_lerp(sw, $0, t) } ?? sw,
                    height: h.map { sk_lerp(sh, $0, t) } ?? sh
                )
            }
        case .speedBy(let delta):
            if let start = startSpeed {
                node.speed = start + delta * t
            }
        case .speedTo(let value):
            if let start = startSpeed {
                node.speed = sk_lerp(start, value, t)
            }
        case .custom(let block):
            block(node, t * CGFloat(action.duration))
        case .animate(let textures, let timePerFrame, let resize, _):
            if textures.isEmpty { return }
            let idx = min(textures.count - 1, Int((elapsed / max(timePerFrame, 0.0001)).rounded(.down)))
            if let sprite = node as? SKSpriteNode {
                sprite.texture = textures[idx]
                if resize { sprite.size = textures[idx].size() }
            }
        case .physicsImpulse(let force, let angular, let torque):
            if t >= 1, let body = node.physicsBody {
                if let force { body.applyForce(force) }
                if let angular { body.applyAngularImpulse(angular) }
                if let torque { body.applyTorque(torque) }
            }
        case .changeFloat(let key, let to, let by):
            if let body = node.physicsBody {
                if key == "mass" {
                    if let to { body.mass = sk_lerp(body.mass, CGFloat(to), t) }
                    if let by { body.mass += CGFloat(by) * (t == 1 ? 0 : 0) ; if t == 1 { body.mass += CGFloat(by) } }
                }
                if key == "charge" {
                    if let to { body.charge = CGFloat(to) }
                    if let by, t == 1 { body.charge += CGFloat(by) }
                }
            }
        case .colorize(let color, let blend):
            if let sprite = node as? SKSpriteNode {
                if let blend { sprite.colorBlendFactor = blend }
                if let color { sprite.color = color }
            }
        default:
            break
        }
    }

    private func stepSequence(_ actions: [SKAction], on node: SKNode, dt: TimeInterval) {
        if actions.isEmpty { finished = true; return }
        if sequenceRuntime == nil {
            sequenceIndex = 0
            sequenceRuntime = _SKActionRuntime(action: actions[0], key: nil)
        }
        sequenceRuntime?.step(on: node, dt: dt)
        while sequenceRuntime?.finished == true {
            sequenceIndex += 1
            if sequenceIndex >= actions.count {
                finished = true
                return
            }
            sequenceRuntime = _SKActionRuntime(action: actions[sequenceIndex], key: nil)
            sequenceRuntime?.step(on: node, dt: 0)
        }
    }

    private func stepGroup(_ actions: [SKAction], on node: SKNode, dt: TimeInterval) {
        if groupRuntimes.isEmpty {
            groupRuntimes = actions.map { _SKActionRuntime(action: $0, key: nil) }
        }
        for runtime in groupRuntimes {
            runtime.step(on: node, dt: dt)
        }
        if groupRuntimes.allSatisfy({ $0.finished || $0.cancelled }) {
            finished = true
        }
    }

    private func stepRepeat(_ inner: SKAction, remaining: Int, forever: Bool, on node: SKNode, dt: TimeInterval) {
        if repeatRuntime == nil {
            repeatRemaining = remaining
            repeatRuntime = _SKActionRuntime(action: inner, key: nil)
        }
        repeatRuntime?.step(on: node, dt: dt)
        if repeatRuntime?.finished == true {
            if forever {
                repeatRuntime = _SKActionRuntime(action: inner, key: nil)
            } else {
                repeatRemaining -= 1
                if repeatRemaining <= 0 {
                    finished = true
                } else {
                    repeatRuntime = _SKActionRuntime(action: inner, key: nil)
                }
            }
        }
    }
}

open class SKAction: NSObject, NSCopying, NSSecureCoding {
    public var duration: TimeInterval = 0
    public var speed: CGFloat = 1
    public var timingMode: SKActionTimingMode = .linear
    public var timingFunction: SKActionTimingFunction = { $0 }
    var kind: _SKActionKind = .wait

    public override init() { super.init() }

    public convenience init?(named name: String) {
        _ = name
        return nil
    }

    public convenience init?(named name: String, duration: TimeInterval) {
        _ = duration
        self.init(named: name)
    }

    public convenience init?(named name: String, fromURL url: URL) {
        _ = url
        self.init(named: name)
    }

    public convenience init?(named name: String, fromURL url: URL, duration: TimeInterval) {
        _ = duration
        self.init(named: name, fromURL: url)
    }

    public required init?(coder: NSCoder) {
        duration = coder.decodeDouble(forKey: "duration")
        speed = CGFloat(coder.decodeDouble(forKey: "speed"))
        if speed == 0 { speed = 1 }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(duration, forKey: "duration")
        coder.encode(Double(speed), forKey: "speed")
    }

    public static var supportsSecureCoding: Bool { true }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = SKAction()
        copy.duration = duration
        copy.speed = speed
        copy.timingMode = timingMode
        copy.timingFunction = timingFunction
        copy.kind = kind
        return copy
    }

    public func reversed() -> SKAction {
        let copy = copy(with: nil) as! SKAction
        switch kind {
        case .moveBy(let d):
            copy.kind = .moveBy(CGVector(dx: -d.dx, dy: -d.dy))
        case .fadeBy(let f):
            copy.kind = .fadeBy(-f)
        case .scaleBy(let x, let y):
            copy.kind = .scaleBy(x: x == 0 ? 0 : 1 / x, y: y == 0 ? 0 : 1 / y)
        case .rotateBy(let a):
            copy.kind = .rotateBy(-a)
        case .hide(let hidden):
            copy.kind = .hide(!hidden)
        case .sequence(let actions):
            copy.kind = .sequence(actions.reversed().map { $0.reversed() })
        case .group(let actions):
            copy.kind = .group(actions.map { $0.reversed() })
        case .resizeBy(let w, let h):
            copy.kind = .resizeBy(w: -w, h: -h)
        default:
            break
        }
        return copy
    }

    private static func make(_ kind: _SKActionKind, duration: TimeInterval) -> SKAction {
        let action = SKAction()
        action.kind = kind
        action.duration = max(0, duration)
        return action
    }

    public class func wait(forDuration duration: TimeInterval) -> SKAction {
        make(.wait, duration: duration)
    }

    public class func wait(forDuration duration: TimeInterval, withRange durationRange: TimeInterval) -> SKAction {
        _ = durationRange
        return wait(forDuration: duration)
    }

    public class func move(by delta: CGVector, duration: TimeInterval) -> SKAction {
        make(.moveBy(delta), duration: duration)
    }

    public class func moveBy(x deltaX: CGFloat, y deltaY: CGFloat, duration: TimeInterval) -> SKAction {
        move(by: CGVector(dx: deltaX, dy: deltaY), duration: duration)
    }

    public class func move(to location: CGPoint, duration: TimeInterval) -> SKAction {
        make(.moveTo(location, axisX: true, axisY: true), duration: duration)
    }

    public class func moveTo(x: CGFloat, duration: TimeInterval) -> SKAction {
        make(.moveTo(CGPoint(x: x, y: 0), axisX: true, axisY: false), duration: duration)
    }

    public class func moveTo(y: CGFloat, duration: TimeInterval) -> SKAction {
        make(.moveTo(CGPoint(x: 0, y: y), axisX: false, axisY: true), duration: duration)
    }

    public class func fadeAlpha(by factor: CGFloat, duration: TimeInterval) -> SKAction {
        make(.fadeBy(factor), duration: duration)
    }

    public class func fadeAlpha(to alpha: CGFloat, duration: TimeInterval) -> SKAction {
        make(.fadeTo(alpha), duration: duration)
    }

    public class func fadeIn(withDuration duration: TimeInterval) -> SKAction {
        fadeAlpha(to: 1, duration: duration)
    }

    public class func fadeOut(withDuration duration: TimeInterval) -> SKAction {
        fadeAlpha(to: 0, duration: duration)
    }

    public class func scale(by scale: CGFloat, duration: TimeInterval) -> SKAction {
        make(.scaleBy(x: scale, y: scale), duration: duration)
    }

    public class func scale(to scale: CGFloat, duration: TimeInterval) -> SKAction {
        make(.scaleTo(x: scale, y: scale), duration: duration)
    }

    public class func scale(to size: CGSize, duration: TimeInterval) -> SKAction {
        make(.resizeTo(w: size.width, h: size.height), duration: duration)
    }

    public class func scaleX(by xScale: CGFloat, y yScale: CGFloat, duration: TimeInterval) -> SKAction {
        make(.scaleBy(x: xScale, y: yScale), duration: duration)
    }

    public class func scaleX(to scale: CGFloat, duration: TimeInterval) -> SKAction {
        make(.scaleTo(x: scale, y: nil), duration: duration)
    }

    public class func scaleX(to xScale: CGFloat, y yScale: CGFloat, duration: TimeInterval) -> SKAction {
        make(.scaleTo(x: xScale, y: yScale), duration: duration)
    }

    public class func scaleY(to scale: CGFloat, duration: TimeInterval) -> SKAction {
        make(.scaleTo(x: nil, y: scale), duration: duration)
    }

    public class func rotate(byAngle radians: CGFloat, duration: TimeInterval) -> SKAction {
        make(.rotateBy(radians), duration: duration)
    }

    public class func rotate(toAngle radians: CGFloat, duration: TimeInterval) -> SKAction {
        make(.rotateTo(radians, shortest: false), duration: duration)
    }

    public class func rotate(toAngle radians: CGFloat, duration: TimeInterval, shortestUnitArc: Bool) -> SKAction {
        make(.rotateTo(radians, shortest: shortestUnitArc), duration: duration)
    }

    public class func resize(byWidth width: CGFloat, height: CGFloat, duration: TimeInterval) -> SKAction {
        make(.resizeBy(w: width, h: height), duration: duration)
    }

    public class func resize(toHeight height: CGFloat, duration: TimeInterval) -> SKAction {
        make(.resizeTo(w: nil, h: height), duration: duration)
    }

    public class func resize(toWidth width: CGFloat, duration: TimeInterval) -> SKAction {
        make(.resizeTo(w: width, h: nil), duration: duration)
    }

    public class func resize(toWidth width: CGFloat, height: CGFloat, duration: TimeInterval) -> SKAction {
        make(.resizeTo(w: width, h: height), duration: duration)
    }

    public class func hide() -> SKAction { make(.hide(true), duration: 0) }
    public class func unhide() -> SKAction { make(.hide(false), duration: 0) }
    public class func removeFromParent() -> SKAction { make(.removeFromParent, duration: 0) }

    public class func sequence(_ actions: [SKAction]) -> SKAction {
        let action = make(.sequence(actions), duration: actions.reduce(0) { $0 + $1.duration })
        return action
    }

    public class func group(_ actions: [SKAction]) -> SKAction {
        make(.group(actions), duration: actions.map(\.duration).max() ?? 0)
    }

    public class func `repeat`(_ action: SKAction, count: UInt) -> SKAction {
        make(.repeat(action, count: Int(count)), duration: action.duration * TimeInterval(count))
    }

    public class func repeatForever(_ action: SKAction) -> SKAction {
        make(.repeatForever(action), duration: .infinity)
    }

    public class func run(_ block: @escaping () -> Void) -> SKAction {
        make(.run(block), duration: 0)
    }

    public class func run(_ block: @escaping () -> Void, queue: DispatchQueue) -> SKAction {
        make(.run({ queue.sync(execute: block) }), duration: 0)
    }

    public class func run(_ action: SKAction, onChildWithName name: String) -> SKAction {
        make(.runAction(action, child: name), duration: action.duration)
    }

    public class func customAction(
        withDuration duration: TimeInterval,
        actionBlock block: @escaping (SKNode, CGFloat) -> Void
    ) -> SKAction {
        make(.custom(block), duration: duration)
    }

    public class func speed(by speed: CGFloat, duration: TimeInterval) -> SKAction {
        make(.speedBy(speed), duration: duration)
    }

    public class func speed(to speed: CGFloat, duration: TimeInterval) -> SKAction {
        make(.speedTo(speed), duration: duration)
    }

    public class func setTexture(_ texture: SKTexture) -> SKAction {
        make(.setTexture(texture, resize: false, normal: false), duration: 0)
    }

    public class func setTexture(_ texture: SKTexture, resize: Bool) -> SKAction {
        make(.setTexture(texture, resize: resize, normal: false), duration: 0)
    }

    public class func setNormalTexture(_ texture: SKTexture) -> SKAction {
        make(.setTexture(texture, resize: false, normal: true), duration: 0)
    }

    public class func setNormalTexture(_ texture: SKTexture, resize: Bool) -> SKAction {
        make(.setTexture(texture, resize: resize, normal: true), duration: 0)
    }

    public class func animate(with textures: [SKTexture], timePerFrame sec: TimeInterval) -> SKAction {
        animate(with: textures, timePerFrame: sec, resize: false, restore: false)
    }

    public class func animate(
        with textures: [SKTexture],
        timePerFrame sec: TimeInterval,
        resize: Bool,
        restore: Bool
    ) -> SKAction {
        make(.animate(textures, timePerFrame: sec, resize: resize, restore: restore),
             duration: sec * TimeInterval(textures.count))
    }

    public class func animate(withNormalTextures textures: [SKTexture], timePerFrame sec: TimeInterval) -> SKAction {
        animate(with: textures, timePerFrame: sec)
    }

    public class func animate(
        withNormalTextures textures: [SKTexture],
        timePerFrame sec: TimeInterval,
        resize: Bool,
        restore: Bool
    ) -> SKAction {
        animate(with: textures, timePerFrame: sec, resize: resize, restore: restore)
    }

    public class func playSoundFileNamed(_ soundFile: String, waitForCompletion wait: Bool) -> SKAction {
        _ = soundFile
        return make(.playSound, duration: wait ? 0.01 : 0)
    }

    public class func play() -> SKAction { make(.playPause(1), duration: 0) }
    public class func pause() -> SKAction { make(.playPause(0), duration: 0) }
    public class func stop() -> SKAction { make(.playPause(-1), duration: 0) }

    public class func applyForce(_ force: CGVector, duration: TimeInterval) -> SKAction {
        make(.physicsImpulse(force: force, angular: nil, torque: nil), duration: duration)
    }

    public class func applyForce(_ force: CGVector, at point: CGPoint, duration: TimeInterval) -> SKAction {
        _ = point
        return applyForce(force, duration: duration)
    }

    public class func applyImpulse(_ impulse: CGVector, duration: TimeInterval) -> SKAction {
        applyForce(impulse, duration: duration)
    }

    public class func applyImpulse(_ impulse: CGVector, at point: CGPoint, duration: TimeInterval) -> SKAction {
        applyForce(impulse, at: point, duration: duration)
    }

    public class func applyTorque(_ torque: CGFloat, duration: TimeInterval) -> SKAction {
        make(.physicsImpulse(force: nil, angular: nil, torque: torque), duration: duration)
    }

    public class func applyAngularImpulse(_ impulse: CGFloat, duration: TimeInterval) -> SKAction {
        make(.physicsImpulse(force: nil, angular: impulse, torque: nil), duration: duration)
    }

    public class func changeMass(to v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "mass", to: v, by: nil), duration: duration)
    }

    public class func changeMass(by v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "mass", to: nil, by: v), duration: duration)
    }

    public class func changeCharge(to v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "charge", to: v, by: nil), duration: duration)
    }

    public class func changeCharge(by v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "charge", to: nil, by: v), duration: duration)
    }

    public class func changeVolume(to v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "volume", to: v, by: nil), duration: duration)
    }

    public class func changeVolume(by v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "volume", to: nil, by: v), duration: duration)
    }

    public class func changePlaybackRate(to v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "rate", to: v, by: nil), duration: duration)
    }

    public class func changePlaybackRate(by v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "rate", to: nil, by: v), duration: duration)
    }

    public class func changeObstruction(to v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "obstruction", to: v, by: nil), duration: duration)
    }

    public class func changeObstruction(by v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "obstruction", to: nil, by: v), duration: duration)
    }

    public class func changeOcclusion(to v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "occlusion", to: v, by: nil), duration: duration)
    }

    public class func changeOcclusion(by v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "occlusion", to: nil, by: v), duration: duration)
    }

    public class func changeReverb(to v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "reverb", to: v, by: nil), duration: duration)
    }

    public class func changeReverb(by v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "reverb", to: nil, by: v), duration: duration)
    }

    public class func stereoPan(to v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "pan", to: v, by: nil), duration: duration)
    }

    public class func stereoPan(by v: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "pan", to: nil, by: v), duration: duration)
    }

    public class func falloff(to falloff: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "falloff", to: falloff, by: nil), duration: duration)
    }

    public class func falloff(by falloff: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "falloff", to: nil, by: falloff), duration: duration)
    }

    public class func strength(to strength: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "strength", to: strength, by: nil), duration: duration)
    }

    public class func strength(by strength: Float, duration: TimeInterval) -> SKAction {
        make(.changeFloat(key: "strength", to: nil, by: strength), duration: duration)
    }

    public class func colorize(withColorBlendFactor colorBlendFactor: CGFloat, duration sec: TimeInterval) -> SKAction {
        make(.colorize(nil, blend: colorBlendFactor), duration: sec)
    }

    public class func colorize(with color: SKColor, colorBlendFactor: CGFloat, duration: TimeInterval) -> SKAction {
        make(.colorize(color, blend: colorBlendFactor), duration: duration)
    }

    public class func follow(_ path: CGPath, duration: TimeInterval) -> SKAction {
        _ = path
        return make(.follow, duration: duration)
    }

    public class func follow(_ path: CGPath, speed: CGFloat) -> SKAction {
        _ = speed
        return follow(path, duration: 0)
    }

    public class func follow(_ path: CGPath, asOffset offset: Bool, orientToPath orient: Bool, duration: TimeInterval) -> SKAction {
        _ = offset
        _ = orient
        return follow(path, duration: duration)
    }

    public class func follow(_ path: CGPath, asOffset offset: Bool, orientToPath orient: Bool, speed: CGFloat) -> SKAction {
        _ = offset
        _ = orient
        return follow(path, speed: speed)
    }

    public class func reach(to position: CGPoint, rootNode root: SKNode, duration: TimeInterval) -> SKAction {
        _ = position
        _ = root
        return make(.reach, duration: duration)
    }

    public class func reach(to position: CGPoint, rootNode root: SKNode, velocity: CGFloat) -> SKAction {
        _ = velocity
        return reach(to: position, rootNode: root, duration: 0)
    }

    public class func reach(to node: SKNode, rootNode root: SKNode, duration sec: TimeInterval) -> SKAction {
        reach(to: node.position, rootNode: root, duration: sec)
    }

    public class func reach(to node: SKNode, rootNode root: SKNode, velocity: CGFloat) -> SKAction {
        reach(to: node.position, rootNode: root, velocity: velocity)
    }

    public class func animate(withWarps warps: [SKWarpGeometry], times: [NSNumber]) -> SKAction? {
        _ = warps
        _ = times
        return make(.warp, duration: 0)
    }

    public class func animate(withWarps warps: [SKWarpGeometry], times: [NSNumber], restore: Bool) -> SKAction? {
        _ = restore
        return animate(withWarps: warps, times: times)
    }

    public class func warp(to warp: SKWarpGeometry, duration: TimeInterval) -> SKAction? {
        _ = warp
        return make(.warp, duration: duration)
    }
}
