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
    case size(CGSize)
    case rect(CGRect)
    case vector([CGFloat])

    static func decode(_ value: Any?) -> _CALayerAnimationValue? {
        switch value {
        case let value as CGPoint: return .point(value)
        case let value as CGSize: return .size(value)
        case let value as CGRect: return .rect(value)
        case let value as Double: return .scalar(CGFloat(value))
        case let value as CGFloat: return .scalar(value)
        case let value as Float: return .scalar(CGFloat(value))
        case let value as Int: return .scalar(CGFloat(value))
        // An uncontextualized Swift array literal stored in `Any` is
        // `[Double]`, including Focus's exact GradientProgressBar endpoints.
        // Foundation.CGFloat can be a distinct bridged value type (notably in
        // corelibs Foundation), so a `[CGFloat]` cast does not accept those
        // bytes on every supported host.
        case let value as [Double]: return .vector(value.map { CGFloat($0) })
        case let value as [CGFloat]: return .vector(value)
        case let value as [Float]: return .vector(value.map { CGFloat($0) })
        case let value as [Int]: return .vector(value.map { CGFloat($0) })
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
        case let (.size(a), .size(b)):
            return .size(CGSize(width: lerp(a.width, b.width),
                                height: lerp(a.height, b.height)))
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
    let workID: Int

    var end: Double {
        begin + Self._totalDuration(of: animation)
    }

    static func _totalDuration(of animation: CAAnimation) -> Double {
        guard animation.repeatCount.isFinite else { return .infinity }
        let plays = animation.repeatCount > 0
            ? Double(animation.repeatCount) : 1
        return Swift.max(0, animation.duration) * plays
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
        let repeats = animation.repeatCount
        guard repeats > 0, repeats.isFinite else { return to }
        let remainder = Double(repeats).truncatingRemainder(dividingBy: 1)
        guard remainder > 0 else { return to }
        return from.interpolated(to: to, fraction: CGFloat(remainder))
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
        // A nested frame can observe an inherited completion without owning
        // another scheduled invocation of it.
        var completionIsLocal = false
        var animationWorkIDs: [Int] = []
    }

    struct Completion {
        let fallbackEnd: Double
        let animationWorkIDs: [Int]
        let sequence: Int
        let body: () -> Void
    }

    private static var frames: [Frame] = []
    private static var completions: [Completion] = []
    private static var nextSequence = 0
    private static var nextWorkID = 0
    private struct WorkState {
        var deadline: Double
        var animationIsLive: Bool
        var completionReferences: Int
    }
    private static var workStates: [Int: WorkState] = [:]

    public static func begin() {
        // Core Animation nests transactions by inheriting the enclosing
        // transaction's current values. The child's later mutations remain
        // local and are discarded when it commits.
        let parent = frames.last
        frames.append(Frame(
            animationDuration: parent?.animationDuration ?? 0.25,
            disableActions: parent?.disableActions ?? false,
            completion: parent?.completion))
    }

    public static func commit() {
        guard let frame = frames.popLast() else { return }
        if frame.completionIsLocal, let completion = frame.completion {
            let ids = frame.animationWorkIDs
            for id in ids where workStates[id] != nil {
                workStates[id]!.completionReferences += 1
            }
            completions.append(Completion(
                fallbackEnd: OpenUIKitRuntime.animationTime,
                animationWorkIDs: ids,
                sequence: nextSequence,
                body: completion))
            nextSequence &+= 1
        }
        if !frames.isEmpty {
            let index = frames.index(before: frames.endIndex)
            for id in frame.animationWorkIDs
                where !frames[index].animationWorkIDs.contains(id) {
                frames[index].animationWorkIDs.append(id)
            }
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
        let index = frames.index(before: frames.endIndex)
        frames[index].completion = block
        frames[index].completionIsLocal = true
    }

    public static func completionBlock() -> (() -> Void)? { frames.last?.completion }

    static var _implicitAnimationDuration: Double? {
        guard let frame = frames.last, !frame.disableActions else { return nil }
        return frame.animationDuration
    }

    static func _noteAnimation(duration: Double) -> Int {
        let id = nextWorkID
        nextWorkID &+= 1
        let end = duration.isFinite
            ? OpenUIKitRuntime.animationTime + Swift.max(0, duration)
            : .infinity
        workStates[id] = WorkState(
            deadline: end, animationIsLive: true, completionReferences: 0)
        if !frames.isEmpty {
            let index = frames.index(before: frames.endIndex)
            if !frames[index].animationWorkIDs.contains(id) {
                frames[index].animationWorkIDs.append(id)
            }
        }
        _refreshWorkDeadline()
        return id
    }

    static func _removeAnimation(workID: Int) {
        guard var state = workStates[workID] else { return }
        state.deadline = OpenUIKitRuntime.animationTime
        state.animationIsLive = false
        if state.completionReferences == 0 {
            workStates.removeValue(forKey: workID)
        } else {
            workStates[workID] = state
        }
        _refreshWorkDeadline()
    }

    static func _finishAnimation(workID: Int) {
        guard var state = workStates[workID] else { return }
        state.animationIsLive = false
        if state.completionReferences == 0 {
            workStates.removeValue(forKey: workID)
        } else {
            workStates[workID] = state
        }
        _refreshWorkDeadline()
    }

    public static func flush() {
        _stepCompletions(to: OpenUIKitRuntime.animationTime)
    }

    static func _stepCompletions(to time: Double) {
        // Retire finite work even when its layer is not sampled. This bounds
        // the registry for add/remove churn and lets the host stop redrawing
        // when a non-removed forwards-fill record reaches its endpoint.
        let finishedIDs = workStates.compactMap { id, state in
            state.animationIsLive && state.deadline <= time ? id : nil
        }
        for id in finishedIDs {
            _finishAnimation(workID: id)
        }

        var due: [(end: Double, completion: Completion)] = []
        completions.removeAll { entry in
            let end = _completionEnd(entry)
            if end <= time {
                due.append((end, entry))
                return true
            }
            return false
        }
        due.sort {
            ($0.end, $0.completion.sequence) <
                ($1.end, $1.completion.sequence)
        }
        for entry in due {
            for id in entry.completion.animationWorkIDs {
                guard var state = workStates[id] else { continue }
                state.completionReferences -= 1
                if state.completionReferences == 0 && !state.animationIsLive {
                    workStates.removeValue(forKey: id)
                } else {
                    workStates[id] = state
                }
            }
            entry.completion.body()
        }
        _refreshWorkDeadline()
    }

    private static func _completionEnd(_ entry: Completion) -> Double {
        entry.animationWorkIDs.reduce(entry.fallbackEnd) { result, id in
            Swift.max(result, workStates[id]?.deadline ?? entry.fallbackEnd)
        }
    }

    private static func _refreshWorkDeadline() {
        let deadline = workStates.values.reduce(-Double.infinity) {
            result, state in
            state.animationIsLive ? Swift.max(result, state.deadline) : result
        }
        OpenUIKitRuntime._setCoreAnimationWorkDeadline(deadline)
    }

    static var _workRegistryCountForTesting: Int { workStates.count }

    static func _resetForTesting() {
        frames.removeAll()
        completions.removeAll()
        nextSequence = 0
        nextWorkID = 0
        workStates.removeAll()
        _refreshWorkDeadline()
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
            let replaced = _explicitAnimations.filter { $0.key == key }
            _explicitAnimations.removeAll { $0.key == key }
            for record in replaced {
                CATransaction._removeAnimation(workID: record.workID)
            }
        }
        let duration = _CALayerAnimationRecord._totalDuration(of: copy)
        let workID = CATransaction._noteAnimation(duration: duration)
        let record = _CALayerAnimationRecord(
            key: key, animation: copy, keyPath: keyPath,
            from: endpoints.0, to: endpoints.1,
            begin: OpenUIKitRuntime.animationTime, workID: workID)
        _explicitAnimations.append(record)
    }

    public func animation(forKey key: String) -> CAAnimation? {
        _purgeFinishedAnimations(at: OpenUIKitRuntime.animationTime)
        return _explicitAnimations.last { $0.key == key }?.animation._copyAnimation()
    }

    public func removeAnimation(forKey key: String) {
        let removed = _explicitAnimations.filter { $0.key == key }
        _explicitAnimations.removeAll { $0.key == key }
        for record in removed { CATransaction._removeAnimation(workID: record.workID) }
    }

    public func removeAllAnimations() {
        let removed = _explicitAnimations
        _explicitAnimations.removeAll()
        for record in removed { CATransaction._removeAnimation(workID: record.workID) }
    }

    func _recordImplicitAnimation<T>(keyPath: String, from: T, to: T) {
        guard let duration = CATransaction._implicitAnimationDuration,
              duration > 0
        else { return }
        _purgeFinishedAnimations(at: OpenUIKitRuntime.animationTime)
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = duration
        // A replacement begins at the live presentation value. A first
        // mutation still uses the pre-mutation model value supplied by the
        // property's setter (important for frame, whose storage is updated
        // before this hook runs).
        animation.fromValue = _explicitAnimations.contains { $0.keyPath == keyPath }
            ? nil : from
        animation.toValue = to
        add(animation, forKey: keyPath)
    }

    func _presentationState(at time: Double) -> _CALayerPresentationState {
        _purgeFinishedAnimations(at: time)
        var result = _CALayerPresentationState(
            bounds: bounds, position: position, opacity: opacity,
            cornerRadius: cornerRadius,
            locations: (self as? CAGradientLayer)?.locations)
        _applyExplicitPresentation(to: &result, at: time)
        return result
    }

    /// Apply explicit records over a caller-supplied base state. Backing
    /// layers use this to compose CABasicAnimation over UIView.animate's
    /// already-presented geometry instead of falling back to model values.
    func _applyExplicitPresentation(
        to result: inout _CALayerPresentationState, at time: Double
    ) {
        _purgeFinishedAnimations(at: time)
        for record in _explicitAnimations {
            guard let value = record.value(at: time) else { continue }
            switch (record.keyPath, value) {
            case ("bounds", .rect(let value)): result.bounds = value
            case ("bounds.size", .size(let value)): result.bounds.size = value
            case ("position", .point(let value)): result.position = value
            case ("opacity", .scalar(let value)): result.opacity = Float(value)
            case ("cornerRadius", .scalar(let value)): result.cornerRadius = value
            case ("locations", .vector(let value)): result.locations = value
            default: break
            }
        }
    }

    func _resolvedEndpoints(for animation: CABasicAnimation,
                            keyPath: String)
        -> (_CALayerAnimationValue, _CALayerAnimationValue)? {
        let model: _CALayerAnimationValue?
        switch keyPath {
        case "bounds": model = .rect(bounds)
        case "bounds.size": model = .size(bounds.size)
        case "position": model = .point(position)
        case "opacity": model = .scalar(CGFloat(opacity))
        case "cornerRadius": model = .scalar(cornerRadius)
        case "locations": model = (self as? CAGradientLayer)?.locations.map {
            .vector($0)
        }
        default: model = nil
        }
        guard _isSupportedKeyPath(keyPath) else { return nil }
        let suppliedFrom = animation.fromValue.flatMap(_CALayerAnimationValue.decode)
        let suppliedTo = animation.toValue.flatMap(_CALayerAnimationValue.decode)
        // A fully supplied vector animation is valid even when the model
        // gradient has nil locations. Only an omitted endpoint needs model
        // or live-presentation fallback.
        let presentation = _presentationAnimationValue(
            for: keyPath, at: OpenUIKitRuntime.animationTime) ?? model
        let from = animation.fromValue == nil ? presentation : suppliedFrom
        let to = animation.toValue == nil ? model : suppliedTo
        guard let from, let to,
              _value(from, hasShapeFor: keyPath),
              _value(to, hasShapeFor: keyPath),
              _endpointPairIsCompatible(from, to: to)
        else { return nil }
        return (from, to)
    }

    func _presentationAnimationValue(
        for keyPath: String, at time: Double
    ) -> _CALayerAnimationValue? {
        _purgeFinishedAnimations(at: time)
        for record in _explicitAnimations.reversed()
            where record.keyPath == keyPath {
            if let value = record.value(at: time) { return value }
        }
        return nil
    }

    private func _isSupportedKeyPath(_ keyPath: String) -> Bool {
        ["bounds", "bounds.size", "position", "opacity", "cornerRadius",
         "locations"].contains(keyPath)
    }

    private func _value(_ value: _CALayerAnimationValue,
                        hasShapeFor keyPath: String) -> Bool {
        switch (keyPath, value) {
        case ("bounds", .rect), ("bounds.size", .size),
             ("position", .point), ("opacity", .scalar),
             ("cornerRadius", .scalar), ("locations", .vector):
            return true
        default:
            return false
        }
    }

    private func _endpointPairIsCompatible(
        _ from: _CALayerAnimationValue, to: _CALayerAnimationValue
    ) -> Bool {
        guard case let (.vector(a), .vector(b)) = (from, to) else {
            return true
        }
        // Validate interpolation arity, not gradient color arity. Focus's
        // unchanged progress bar deliberately installs seven locations on a
        // three-color layer; Core Animation accepts and retains that value.
        return a.count == b.count
    }

    private func _purgeFinishedAnimations(at time: Double) {
        for record in _explicitAnimations where time >= record.end {
            CATransaction._finishAnimation(workID: record.workID)
        }
        _explicitAnimations.removeAll { record in
            time >= record.end && record.animation.isRemovedOnCompletion
        }
    }
}
