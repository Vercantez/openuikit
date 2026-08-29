// Focus-driven Core Animation compatibility: keyed basic animations,
// transaction timing/completion, and presentation sampling for CALayer.
//
// The model tree is updated immediately. Animation records preserve the old
// presentation value and are sampled from OpenUIKitRuntime.animationTime by
// both renderers. Transactions and completions use that same host clock; no
// wall clock or hidden dispatch queue participates in deterministic renders.

public struct CAMediaTimingFillMode: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let removed = CAMediaTimingFillMode(rawValue: "removed")
    public static let forwards = CAMediaTimingFillMode(rawValue: "forwards")
    public static let backwards = CAMediaTimingFillMode(rawValue: "backwards")
    public static let both = CAMediaTimingFillMode(rawValue: "both")
}

open class CAAnimation {
    public var duration: Double = 0
    public var repeatCount: Float = 0
    public var fillMode: CAMediaTimingFillMode = .removed
    public var isRemovedOnCompletion: Bool = true

    public init() {}

    func _copyAnimation() -> CAAnimation {
        let result = CAAnimation()
        _copyCommon(to: result)
        return result
    }

    func _copyCommon(to result: CAAnimation) {
        result.duration = duration
        result.repeatCount = repeatCount
        result.fillMode = fillMode
        result.isRemovedOnCompletion = isRemovedOnCompletion
    }
}

open class CAPropertyAnimation: CAAnimation {
    public var keyPath: String?

    public init(keyPath path: String?) {
        keyPath = path
        super.init()
    }

    public override init() {
        keyPath = nil
        super.init()
    }

    override func _copyAnimation() -> CAAnimation {
        let result = CAPropertyAnimation(keyPath: keyPath)
        _copyCommon(to: result)
        return result
    }
}

open class CABasicAnimation: CAPropertyAnimation {
    public var fromValue: Any?
    public var toValue: Any?
    public var byValue: Any?

    public override init(keyPath path: String?) {
        super.init(keyPath: path)
    }

    public override init() {
        super.init()
    }

    override func _copyAnimation() -> CAAnimation {
        let result = CABasicAnimation(keyPath: keyPath)
        _copyCommon(to: result)
        result.fromValue = fromValue
        result.toValue = toValue
        result.byValue = byValue
        return result
    }
}

enum _CALayerAnimationValue {
    case scalar(CGFloat)
    case point(CGPoint)
    case rect(CGRect)
    case vector([CGFloat])

    static func decode(_ value: Any?) -> _CALayerAnimationValue? {
        switch value {
        case let value as CGPoint: return .point(value)
        case let value as CGRect: return .rect(value)
        case let value as CGFloat: return .scalar(value)
        case let value as Float: return .scalar(CGFloat(value))
        case let value as Int: return .scalar(CGFloat(value))
        case let value as [CGFloat]: return .vector(value)
        case let value as [Float]: return .vector(value.map(CGFloat.init))
        case let value as [Int]: return .vector(value.map(CGFloat.init))
        default: return nil
        }
    }

    func interpolated(to other: _CALayerAnimationValue,
                      fraction: CGFloat) -> _CALayerAnimationValue? {
        let u = Swift.min(Swift.max(fraction, 0), 1)
        func lerp(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * u }
        switch (self, other) {
        case let (.scalar(a), .scalar(b)):
            return .scalar(lerp(a, b))
        case let (.point(a), .point(b)):
            return .point(CGPoint(x: lerp(a.x, b.x), y: lerp(a.y, b.y)))
        case let (.rect(a), .rect(b)):
            return .rect(CGRect(x: lerp(a.origin.x, b.origin.x),
                                y: lerp(a.origin.y, b.origin.y),
                                width: lerp(a.size.width, b.size.width),
                                height: lerp(a.size.height, b.size.height)))
        case let (.vector(a), .vector(b)) where a.count == b.count:
            return .vector(zip(a, b).map(lerp))
        default:
            return nil
        }
    }
}

struct _CALayerAnimationRecord {
    let key: String?
    let animation: CAAnimation
    let keyPath: String
    let from: _CALayerAnimationValue
    let to: _CALayerAnimationValue
    let begin: Double

    var end: Double {
        guard animation.repeatCount.isFinite else { return .infinity }
        let plays = animation.repeatCount > 0
            ? Double(animation.repeatCount) : 1
        return begin + Swift.max(0, animation.duration) * plays
    }

    /// nil means the model value should be used for this record at `time`.
    func value(at time: Double) -> _CALayerAnimationValue? {
        let duration = Swift.max(0, animation.duration)
        if time < begin {
            return animation.fillMode == .backwards || animation.fillMode == .both
                ? from : nil
        }
        if duration == 0 { return _terminalValue() }

        let elapsed = time - begin
        let repeats = animation.repeatCount
        if repeats.isInfinite {
            let fraction = CGFloat(elapsed.truncatingRemainder(dividingBy: duration) / duration)
            return from.interpolated(to: to, fraction: fraction)
        }

        let plays = repeats > 0 ? Double(repeats) : 1
        if elapsed >= duration * plays { return _terminalValue() }
        let fraction = CGFloat(elapsed.truncatingRemainder(dividingBy: duration) / duration)
        return from.interpolated(to: to, fraction: fraction)
    }

    private func _terminalValue() -> _CALayerAnimationValue? {
        guard !animation.isRemovedOnCompletion,
              animation.fillMode == .forwards || animation.fillMode == .both
        else { return nil }
        return to
    }
}

struct _CALayerPresentationState {
    var bounds: CGRect
    var position: CGPoint
    var opacity: Float
    var cornerRadius: CGFloat
    var locations: [CGFloat]?
}

@preconcurrency @MainActor
public enum CATransaction {
    struct Frame {
        var animationDuration: Double = 0.25
        var disableActions = false
        var completion: (() -> Void)?
        var latestAnimationEnd: Double?
    }

    struct Completion {
        let end: Double
        let sequence: Int
        let body: () -> Void
    }

    private static var frames: [Frame] = []
    private static var completions: [Completion] = []
    private static var nextSequence = 0

    public static func begin() { frames.append(Frame()) }

    public static func commit() {
        guard let frame = frames.popLast() else { return }
        if let completion = frame.completion {
            let end = frame.latestAnimationEnd ?? OpenUIKitRuntime.animationTime
            completions.append(Completion(end: end, sequence: nextSequence,
                                          body: completion))
            nextSequence &+= 1
        }
        if !frames.isEmpty, let end = frame.latestAnimationEnd {
            let index = frames.index(before: frames.endIndex)
            frames[index].latestAnimationEnd = Swift.max(
                frames[index].latestAnimationEnd ?? -.infinity, end)
        }
    }

    public static func setAnimationDuration(_ duration: Double) {
        guard !frames.isEmpty else { return }
        frames[frames.index(before: frames.endIndex)].animationDuration = Swift.max(0, duration)
    }

    public static func animationDuration() -> Double {
        frames.last?.animationDuration ?? 0.25
    }

    public static func setDisableActions(_ flag: Bool) {
        guard !frames.isEmpty else { return }
        frames[frames.index(before: frames.endIndex)].disableActions = flag
    }

    public static func disableActions() -> Bool { frames.last?.disableActions ?? false }

    public static func setCompletionBlock(_ block: (() -> Void)?) {
        guard !frames.isEmpty else { return }
        frames[frames.index(before: frames.endIndex)].completion = block
    }

    public static func completionBlock() -> (() -> Void)? { frames.last?.completion }

    static var _implicitAnimationDuration: Double? {
        guard let frame = frames.last, !frame.disableActions else { return nil }
        return frame.animationDuration
    }

    static func _noteAnimation(duration: Double) {
        guard !frames.isEmpty, duration.isFinite else {
            if !duration.isFinite { OpenUIKitRuntime.noteAnimationWork(until: .infinity) }
            return
        }
        let end = OpenUIKitRuntime.animationTime + Swift.max(0, duration)
        let index = frames.index(before: frames.endIndex)
        frames[index].latestAnimationEnd = Swift.max(
            frames[index].latestAnimationEnd ?? -.infinity, end)
        OpenUIKitRuntime.noteAnimationWork(until: end)
    }

    public static func flush() {
        _stepCompletions(to: OpenUIKitRuntime.animationTime)
    }

    static func _stepCompletions(to time: Double) {
        guard !completions.isEmpty else { return }
        var due: [Completion] = []
        completions.removeAll { entry in
            if entry.end <= time {
                due.append(entry)
                return true
            }
            return false
        }
        due.sort { ($0.end, $0.sequence) < ($1.end, $1.sequence) }
        for entry in due { entry.body() }
    }

    static func _resetForTesting() {
        frames.removeAll()
        completions.removeAll()
        nextSequence = 0
    }
}

extension CALayer {
    public func add(_ animation: CAAnimation, forKey key: String?) {
        guard let property = animation as? CAPropertyAnimation,
              let keyPath = property.keyPath,
              let basic = animation as? CABasicAnimation else {
            preconditionFailure("OpenUIKit CALayer.add currently supports CABasicAnimation with a keyPath")
        }
        precondition(basic.byValue == nil,
                     "OpenUIKit CABasicAnimation.byValue is not implemented")
        guard let endpoints = _resolvedEndpoints(for: basic, keyPath: keyPath) else {
            preconditionFailure("OpenUIKit does not support CABasicAnimation keyPath/value shape: \(keyPath)")
        }

        let copy = animation._copyAnimation()
        if let key {
            _explicitAnimations.removeAll { $0.key == key }
        }
        let record = _CALayerAnimationRecord(
            key: key, animation: copy, keyPath: keyPath,
            from: endpoints.0, to: endpoints.1,
            begin: OpenUIKitRuntime.animationTime)
        _explicitAnimations.append(record)
        CATransaction._noteAnimation(duration: record.end - record.begin)
    }

    public func animation(forKey key: String) -> CAAnimation? {
        _purgeFinishedAnimations(at: OpenUIKitRuntime.animationTime)
        return _explicitAnimations.last { $0.key == key }?.animation._copyAnimation()
    }

    public func removeAnimation(forKey key: String) {
        _explicitAnimations.removeAll { $0.key == key }
    }

    public func removeAllAnimations() { _explicitAnimations.removeAll() }

    func _recordImplicitAnimation<T>(keyPath: String, from: T, to: T) {
        guard let duration = CATransaction._implicitAnimationDuration,
              duration > 0
        else { return }
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = duration
        animation.fromValue = from
        animation.toValue = to
        add(animation, forKey: keyPath)
    }

    func _presentationState(at time: Double) -> _CALayerPresentationState {
        _purgeFinishedAnimations(at: time)
        var result = _CALayerPresentationState(
            bounds: bounds, position: position, opacity: opacity,
            cornerRadius: cornerRadius,
            locations: (self as? CAGradientLayer)?.locations)
        for record in _explicitAnimations {
            guard let value = record.value(at: time) else { continue }
            switch (record.keyPath, value) {
            case ("bounds", .rect(let value)): result.bounds = value
            case ("bounds.size", .point(let value)):
                result.bounds.size = CGSize(width: value.x, height: value.y)
            case ("position", .point(let value)): result.position = value
            case ("opacity", .scalar(let value)): result.opacity = Float(value)
            case ("cornerRadius", .scalar(let value)): result.cornerRadius = value
            case ("locations", .vector(let value)): result.locations = value
            default: break
            }
        }
        return result
    }

    private func _resolvedEndpoints(for animation: CABasicAnimation,
                                    keyPath: String)
        -> (_CALayerAnimationValue, _CALayerAnimationValue)? {
        let model: _CALayerAnimationValue?
        switch keyPath {
        case "bounds": model = .rect(bounds)
        case "bounds.size": model = .point(CGPoint(x: bounds.width, y: bounds.height))
        case "position": model = .point(position)
        case "opacity": model = .scalar(CGFloat(opacity))
        case "cornerRadius": model = .scalar(cornerRadius)
        case "locations": model = (self as? CAGradientLayer)?.locations.map {
            .vector($0)
        }
        default: model = nil
        }
        guard let fallback = model,
              let from = _CALayerAnimationValue.decode(animation.fromValue) ?? Optional(fallback),
              let to = _CALayerAnimationValue.decode(animation.toValue) ?? Optional(fallback)
        else { return nil }
        return (from, to)
    }

    private func _purgeFinishedAnimations(at time: Double) {
        _explicitAnimations.removeAll { record in
            time >= record.end && record.animation.isRemovedOnCompletion
        }
    }
}
