// UIView animation engine (M6). Owner: animation module.
//
// UIKit semantics reproduced here (validated against Tools/oracle2 goldens +
// direct CAAnimation parameter probes, see docs/QUARTZ_NOTES.md "Animation"):
//   - Inside a `UIView.animate` block, animatable property setters RECORD a
//     from->to animation on the view and update the model value immediately
//     (model = final value; the presentation interpolates).
//   - Presentation sampling is driven by `OpenUIKitRuntime.animationTime`
//     (a settable clock — the host seeks, nothing runs on wall time).
//     LayerBridge builds the QZLayer tree from presentation values at that
//     time; quartz's animation/timing engine evaluates the curves
//     (LayerBridge.swift, applyPresentation).
//   - Curves are Core Animation's standard cubic beziers:
//       linear (0,0,1,1), easeIn (0.42,0,1,1), easeOut (0,0,0.58,1),
//       easeInOut (0.42,0,0.58,1)
//     solved numerically for x(t) like CA does (quartz's solver — verified
//     against golden animation frames to < 0.1 pt).
//   - UIView springs are physical damped springs (CASpringAnimation with
//     mass 1) whose natural frequency is DURATION-FIT. Probing the real
//     CASpringAnimation UIKit emits (17 (ζ, D) combinations) shows UIKit
//     solves, for damping ratio ζ < 1 and initial velocity v = 0:
//         (β/ω_d)·e^(−β·D) = 0.001,  β = ζ·ω_n,  ω_d = ω_n·√(1−ζ²)
//     which closes to  ω_n = ln(1000·ζ/√(1−ζ²)) / (ζ·D).
//     This matches UIKit's generated stiffness/damping to 8+ significant
//     digits on every probe. ζ = 1 solves (1 + ω·D)·e^(−ω·D) = 0.001
//     (probe: ω·D = 9.23341, ours 9.2334134764). With velocity the probed
//     equation generalizes to |(β−v)/ω_d|·e^(−β·D) = 0.001; we take the
//     settled (largest) root — see KNOWN_GAPS for the large-velocity branch
//     UIKit's internal solver jumps to.
//   - Animation is complete at t ≥ delay + duration: the presentation shows
//     the MODEL value exactly (CA removes the animation on completion);
//     before `delay` the FROM value shows (UIKit fills backwards).
//   - Completion handlers fire when the animation ENDS on that clock, not
//     when the block returns (M8.1). They are queued at
//     `begin + delay + duration` and delivered by
//     `UIView._stepAnimationCompletions(to:)`, which UIWindow.tick calls —
//     the same host-clock pattern as scroll deceleration and navigation
//     transitions. A block that records no animation at all completes
//     immediately (as in UIKit, where no CAAnimation is created).
//
// This file has no Foundation dependency. Recording and value interpolation
// are pure Swift; exact timing sampling (including begin-from-current-state)
// calls LayerBridge's CQuartz-backed evaluator so recording and rendering use
// one curve/spring implementation.

// MARK: - Recorded animation

/// One recorded property animation (the unit UIView.animate produces per
/// changed property).
struct UIViewAnimation {
    enum Property {
        case position        // view.center            -> layer position
        case bounds          // view.bounds            -> layer bounds
        case alpha           // view.alpha             -> layer opacity
        case backgroundColor // view.backgroundColor   -> layer background
        case transform       // view.transform         -> layer affine transform
        case cornerRadius    // view.layer.cornerRadius
    }

    enum Value {
        case scalar(CGFloat)
        case point(CGPoint)
        case rect(CGRect)
        case color(UIColor?)
        case transform(CGAffineTransform)
    }

    enum Timing {
        /// Cubic bezier timing function (CA control points).
        case curve(c1x: CGFloat, c1y: CGFloat, c2x: CGFloat, c2y: CGFloat)
        /// UIView spring (damping ratio + normalized initial velocity).
        case spring(dampingRatio: CGFloat, initialVelocity: CGFloat)
    }

    let property: Property
    var from: Value
    var to: Value
    /// `OpenUIKitRuntime.animationTime` when the animation was recorded
    /// (CA: the commit time). 0 for scene-driven animations (openrender
    /// commits at clock 0); a live host advancing the clock gets runtime
    /// `UIView.animate` calls (control interactions) starting NOW, not at
    /// the host's t = 0. (var with default so the memberwise init keeps
    /// accepting begin-less calls — scene/test animations commit at 0.)
    var begin: Double = 0
    let delay: Double
    let duration: Double
    let timing: Timing
    /// Animation-block transaction that owns this property animation. Zero
    /// denotes a manually constructed/test animation with no completion.
    var transactionID: Int = 0
}

// MARK: - Animation block context

/// Set while a `UIView.animate` animations block runs; property setters
/// consult it to record animations.
enum UIViewAnimationContext {
    struct Params {
        var duration: Double
        var delay: Double
        var timing: UIViewAnimation.Timing
        var beginsFromCurrentState: Bool = false
        var transactionID: Int = 0
    }
    static var current: Params?
    /// Animations recorded by the innermost running block (used to decide
    /// whether its completion has anything to wait for).
    static var recordedInBlock = 0
    static var nextTransactionID = 1
    /// Old completion entries displaced while the current animations closure
    /// runs. They are delivered only after the animation context is restored,
    /// so reentrant completion work cannot inherit the replacement transaction.
    static var interruptedEntries: [UIViewAnimationCompletionQueue.Entry] = []
}

// MARK: - Deferred completion handlers

/// Queue of `UIView.animate` completion handlers waiting for the host clock
/// to reach their animation's end time.
///
/// The portable core has no run loop, so — exactly like scroll deceleration
/// (`UIScrollView._stepScrollAnimations`) and navigation transitions
/// (`UINavigationController._stepTransitions`) — the host drives delivery:
/// `UIWindow.tick(timestamp:)` calls `UIView._stepAnimationCompletions(to:)`,
/// which fires every handler whose end time has passed. A host that advances
/// `OpenUIKitRuntime.animationTime` without ticking never delivers them.
enum UIViewAnimationCompletionQueue {
    struct Entry {
        let end: Double
        let seq: Int
        let transactionID: Int
        let body: (Bool) -> Void
    }

    static var entries: [Entry] = []
    private static var nextSeq = 0

    /// Queue `body` for delivery once the clock reaches `end`.
    static func schedule(end: Double, transactionID: Int,
                         _ body: @escaping (Bool) -> Void) {
        entries.append(Entry(end: end, seq: nextSeq,
                             transactionID: transactionID, body: body))
        nextSeq &+= 1
    }

    /// An in-flight property animation was replaced. UIKit completes the
    /// displaced animation block with `finished == false`; this matters for
    /// patterns such as animateHidden, whose old completion must not apply a
    /// stale hidden state after a reversal.
    static func takeInterrupted(transactionID: Int) -> [Entry] {
        guard transactionID != 0 else { return [] }
        var interrupted: [Entry] = []
        entries.removeAll { entry in
            if entry.transactionID == transactionID {
                interrupted.append(entry)
                return true
            }
            return false
        }
        interrupted.sort { $0.seq < $1.seq }
        return interrupted
    }

    /// Deliver every handler due at or before `time`, oldest end first
    /// (ties broken by scheduling order).
    ///
    /// Handlers due in this step are taken as one batch BEFORE any of them
    /// run: a completion that starts a new animation enqueues a completion
    /// for a later step, never for this one. That mirrors a run loop turn and
    /// makes an unbounded completion→animation→completion chain impossible.
    static func step(to time: Double) {
        guard !entries.isEmpty else { return }
        var due: [Entry] = []
        var remaining: [Entry] = []
        for e in entries {
            if e.end <= time { due.append(e) } else { remaining.append(e) }
        }
        guard !due.isEmpty else { return }
        entries = remaining
        due.sort { ($0.end, $0.seq) < ($1.end, $1.seq) }
        for e in due { e.body(true) }
    }
}

// MARK: - UIView.animate API

extension UIView {
    /// Raw values are Darwin's `UIViewAnimationCurve`. The type is still
    /// used by transition-coordinator contexts even though modern animation
    /// calls express the same curves through `AnimationOptions`.
    public enum AnimationCurve: Int, Sendable {
        case easeInOut = 0
        case easeIn = 1
        case easeOut = 2
        case linear = 3
    }

    /// Animation options. Raw values mirror UIKit's UIViewAnimationOptions
    /// (curve occupies bits 16..19; 0 = easeInOut is the default).
    public struct AnimationOptions: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let curveEaseInOut = AnimationOptions(rawValue: 0 << 16)
        public static let curveEaseIn = AnimationOptions(rawValue: 1 << 16)
        public static let curveEaseOut = AnimationOptions(rawValue: 2 << 16)
        public static let curveLinear = AnimationOptions(rawValue: 3 << 16)

        /// Continue a replaced property animation from its sampled
        /// presentation value instead of jumping back to the old model.
        public static let beginFromCurrentState = AnimationOptions(rawValue: 1 << 2)

        /// UIKit's cross-dissolve transition selector. OpenUIKit preserves
        /// transition duration/completion and all property animations in the
        /// block; content snapshot blending is not yet represented by the
        /// portable renderer, so content-only changes switch at commit time.
        public static let transitionCrossDissolve = AnimationOptions(rawValue: 5 << 20)

        var timingCurve: UIViewAnimation.Timing {
            switch (rawValue >> 16) & 0xF {
            case 1: return .curve(c1x: 0.42, c1y: 0, c2x: 1, c2y: 1)      // easeIn
            case 2: return .curve(c1x: 0, c1y: 0, c2x: 0.58, c2y: 1)      // easeOut
            case 3: return .curve(c1x: 0, c1y: 0, c2x: 1, c2y: 1)         // linear
            default: return .curve(c1x: 0.42, c1y: 0, c2x: 0.58, c2y: 1)  // easeInOut
            }
        }
    }

    public static func animate(withDuration duration: Double,
                               delay: Double,
                               options: AnimationOptions = [],
                               animations: () -> Void,
                               completion: ((Bool) -> Void)? = nil) {
        runAnimationBlock(UIViewAnimationContext.Params(
            duration: duration, delay: delay, timing: options.timingCurve,
            beginsFromCurrentState: options.contains(.beginFromCurrentState)),
            animations: animations, completion: completion)
    }

    public static func animate(withDuration duration: Double,
                               animations: () -> Void,
                               completion: ((Bool) -> Void)? = nil) {
        animate(withDuration: duration, delay: 0, options: [],
                animations: animations, completion: completion)
    }

    public static func animate(withDuration duration: Double,
                               delay: Double,
                               usingSpringWithDamping dampingRatio: CGFloat,
                               initialSpringVelocity velocity: CGFloat,
                               options: AnimationOptions = [],
                               animations: () -> Void,
                               completion: ((Bool) -> Void)? = nil) {
        runAnimationBlock(UIViewAnimationContext.Params(
            duration: duration, delay: delay,
            timing: .spring(dampingRatio: dampingRatio, initialVelocity: velocity),
            beginsFromCurrentState: options.contains(.beginFromCurrentState)),
            animations: animations, completion: completion)
    }

    static func runAnimationBlock(_ params: UIViewAnimationContext.Params,
                                  animations: () -> Void,
                                  completion: ((Bool) -> Void)?,
                                  waitsForDurationWhenEmpty: Bool = false) {
        let savedParams = UIViewAnimationContext.current
        let savedCount = UIViewAnimationContext.recordedInBlock
        let savedInterrupted = UIViewAnimationContext.interruptedEntries
        var transaction = params
        if let enclosing = savedParams {
            // A nested block participates in the outer transaction, matching
            // UIKit's inherited animation context/completion ownership.
            transaction.transactionID = enclosing.transactionID
        } else {
            transaction.transactionID = UIViewAnimationContext.nextTransactionID
            UIViewAnimationContext.nextTransactionID &+= 1
        }
        UIViewAnimationContext.current = transaction
        UIViewAnimationContext.recordedInBlock = 0
        UIViewAnimationContext.interruptedEntries = []
        animations()
        let recorded = UIViewAnimationContext.recordedInBlock
        let interrupted = UIViewAnimationContext.interruptedEntries
        UIViewAnimationContext.current = savedParams
        // An outer block owns everything its nested blocks recorded, so its
        // own completion still has something to wait for.
        UIViewAnimationContext.recordedInBlock = savedCount &+ recorded
        UIViewAnimationContext.interruptedEntries = savedInterrupted

        // Deliver interruptions after this transaction's completion has been
        // scheduled and after its context has been removed. A reentrant old
        // completion that starts a third animation is therefore independent
        // and can correctly interrupt the just-created replacement.
        defer {
            if savedParams != nil {
                UIViewAnimationContext.interruptedEntries
                    .append(contentsOf: interrupted)
            } else {
                for entry in interrupted { entry.body(false) }
            }
        }

        guard let completion else { return }
        let end = OpenUIKitRuntime.animationTime + params.delay + params.duration
        if (recorded == 0 && !waitsForDurationWhenEmpty)
            || end <= OpenUIKitRuntime.animationTime {
            // Nothing to animate (UIKit creates no CAAnimation, so the
            // handler runs right away), or a zero-length animation that is
            // already over.
            completion(true)
            return
        }
        // Real UIKit delivers after `delay + duration` of wall time; we
        // deliver when the host clock passes that point (UIWindow.tick).
        OpenUIKitRuntime.noteAnimationWork(until: end)
        UIViewAnimationCompletionQueue.schedule(
            end: end, transactionID: transaction.transactionID, completion)
    }

    /// Deliver `UIView.animate` completion handlers whose animation has ended
    /// at or before `time` on the `OpenUIKitRuntime.animationTime` clock.
    ///
    /// `UIWindow.tick(timestamp:)` calls this; a host that steps the clock
    /// without ticking a window must call it itself or completions never run.
    public static func _stepAnimationCompletions(to time: Double) {
        UIViewAnimationCompletionQueue.step(to: time)
    }

    /// Host redraw hint: a completion handler is still queued, so more frames
    /// (and ticks) are needed — the handler may change the hierarchy.
    public static var _hasPendingAnimationCompletions: Bool {
        !UIViewAnimationCompletionQueue.entries.isEmpty
    }

    // MARK: Recording

    /// Record `property` going from `from` to `to` if an animation block is
    /// active. Called from property didSet observers. Model values are
    /// already updated by the time this runs (UIKit semantics).
    func recordAnimation(_ property: UIViewAnimation.Property,
                         from: UIViewAnimation.Value,
                         to: UIViewAnimation.Value) {
        guard let ctx = UIViewAnimationContext.current else { return }
        UIViewAnimationContext.recordedInBlock &+= 1
        let now = OpenUIKitRuntime.animationTime
        var actualFrom = from
        if let oldIndex = animations.firstIndex(where: { $0.property == property }) {
            let old = animations[oldIndex]
            let oldEnd = old.begin + old.delay + old.duration
            if now < oldEnd {
                UIViewAnimationContext.interruptedEntries.append(contentsOf:
                    UIViewAnimationCompletionQueue.takeInterrupted(
                        transactionID: old.transactionID))
                if ctx.beginsFromCurrentState {
                    actualFrom = presentationValue(of: old, at: now)
                }
            }
        }
        let anim = UIViewAnimation(property: property, from: actualFrom, to: to,
                                   begin: now, delay: ctx.delay,
                                   duration: ctx.duration, timing: ctx.timing,
                                   transactionID: ctx.transactionID)
        // Host redraw hint: frames keep changing until this animation ends.
        OpenUIKitRuntime.noteAnimationWork(until: anim.begin + anim.delay
                                                  + anim.duration)
        // Re-animating the same property replaces the previous animation
        // (CA: same key on the layer).
        if let i = animations.firstIndex(where: { $0.property == property }) {
            animations[i] = anim
        } else {
            animations.append(anim)
        }
    }

    /// Sample one old property's presentation value using the exact timing
    /// evaluator the renderer uses, then apply the same value interpolation.
    /// This is the core of `.beginFromCurrentState` no-jump reversal.
    func presentationValue(of animation: UIViewAnimation,
                           at time: Double) -> UIViewAnimation.Value {
        let u = LayerBridge.animationProgress(animation, at: time)
        func lerp(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * u }
        switch (animation.from, animation.to) {
        case (.scalar(let a), .scalar(let b)):
            return .scalar(lerp(a, b))
        case (.point(let a), .point(let b)):
            return .point(CGPoint(x: lerp(a.x, b.x), y: lerp(a.y, b.y)))
        case (.rect(let a), .rect(let b)):
            return .rect(CGRect(x: lerp(a.minX, b.minX),
                                y: lerp(a.minY, b.minY),
                                width: lerp(a.width, b.width),
                                height: lerp(a.height, b.height)))
        case (.transform(let a), .transform(let b)):
            return .transform(UIViewTransformInterpolation.interpolate(a, b, u))
        case (.color(let a), .color(let b)):
            if u <= 0 { return .color(a) }
            if u >= 1 { return .color(b) }
            let clear = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
            let lhs = a?.resolvedCGColor(with: traitCollection) ?? clear
            let rhs = b?.resolvedCGColor(with: traitCollection) ?? clear
            return .color(UIColor(red: lerp(lhs.red, rhs.red),
                                  green: lerp(lhs.green, rhs.green),
                                  blue: lerp(lhs.blue, rhs.blue),
                                  alpha: lerp(lhs.alpha, rhs.alpha)))
        default:
            return animation.from
        }
    }

    /// Drop all recorded animations (the presentation snaps to the model).
    public func removeAllAnimations() { animations.removeAll() }

    /// Drop only the animations that have already ENDED at `time`.
    ///
    /// CA removes an animation from the layer when it completes; the portable
    /// engine has no run loop to do that, so a finished animation keeps
    /// pinning the presentation to its recorded `to` value and would override
    /// any later model change (a container re-framing the view, say). Code
    /// that reassigns an animated property after its animation finished calls
    /// this from the completion handler.
    func _removeFinishedAnimations(at time: Double) {
        animations.removeAll { time >= $0.begin + $0.delay + $0.duration }
    }
}

// MARK: - Spring duration fit (UIKit model)

enum UIViewSpring {
    /// Natural (undamped) angular frequency ω_n of the spring UIKit builds
    /// for `animate(withDuration:usingSpringWithDamping:...)`. mass = 1,
    /// stiffness = ω_n², damping coefficient = 2·ζ·ω_n. See file header for
    /// the probed settling equation this solves.
    static func naturalFrequency(dampingRatio: CGFloat, initialVelocity: CGFloat,
                                 duration: Double) -> Double {
        let D = Swift.max(1e-9, duration)
        let z = Double(Swift.min(Swift.max(dampingRatio, 1e-6), 1))
        let v = Double(initialVelocity)
        if z >= 1 {
            // Critical damping: (1 + (ω − v)·D)·e^(−ω·D) = 0.001.
            // Fixed point on x = ω·D: x = ln((1 + x − v·D)/0.001).
            var x = 9.2334134764515865 // v = 0 solution
            for _ in 0..<64 {
                let arg = Swift.max(1e-12, 1 + x - v * D)
                let next = _ln(arg / 0.001)
                if (next - x).magnitude < 1e-14 { x = next; break }
                x = next
            }
            return x / D
        }
        let r = (1 - z * z).squareRoot()
        if v == 0 {
            // Closed form of (β/ω_d)·e^(−β·D) = 0.001.
            return _ln(1000 * z / r) / (z * D)
        }
        // |(β − v)/ω_d|·e^(−β·D) = 0.001, settled (largest) root.
        // Fixed point: β = ln(|β − v|·z / (β·r·0.001)) / D.
        var beta = _ln(1000 * z / r) / D
        for _ in 0..<256 {
            let num = (beta - v).magnitude * z
            let den = beta * r * 0.001
            guard num > 0, den > 0 else { break }
            let next = _ln(num / den) / D
            guard next > 0 else { break }
            if (next - beta).magnitude < 1e-13 { beta = next; break }
            beta = next
        }
        return Swift.max(beta, 1e-6) / z
    }
}

// MARK: - Affine transform interpolation (CA decomposition model)

enum UIViewTransformInterpolation {
    /// Decomposition M = Scale · Shear · Rotation (row-vector convention,
    /// matching CG). Mirrors CA's unmatrix-style component interpolation
    /// restricted to 2D: translation, scales, shear and rotation angle each
    /// lerp; rotation takes the shortest path (quaternion slerp equivalent
    /// for z-rotations). Validated against the anim_transform_rotate goldens
    /// (constant area, exact bbox at every capture time).
    struct Decomposed {
        var scaleX: CGFloat
        var scaleY: CGFloat
        var shear: CGFloat
        var rotation: CGFloat
        var tx: CGFloat
        var ty: CGFloat
    }

    static func decompose(_ m: CGAffineTransform) -> Decomposed? {
        let sx = (m.a * m.a + m.b * m.b).squareRoot()
        guard sx > 1e-12 else { return nil } // degenerate x basis
        let rot = _atan2(m.b, m.a)
        let cosR = m.a / sx, sinR = m.b / sx
        // Row 2 in the rotated frame: parallel component = shear·sy,
        // perpendicular component = sy (signed, handles flips).
        let par = m.c * cosR + m.d * sinR
        let perp = -m.c * sinR + m.d * cosR
        guard perp.magnitude > 1e-12 else { return nil } // degenerate y basis
        return Decomposed(scaleX: sx, scaleY: perp, shear: par / perp,
                          rotation: rot, tx: m.tx, ty: m.ty)
    }

    static func compose(_ d: Decomposed) -> CGAffineTransform {
        let r = CGAffineTransform(rotationAngle: d.rotation)
        let cosR = r.a, sinR = r.b
        return CGAffineTransform(
            a: d.scaleX * cosR,
            b: d.scaleX * sinR,
            c: d.shear * d.scaleY * cosR - d.scaleY * sinR,
            d: d.shear * d.scaleY * sinR + d.scaleY * cosR,
            tx: d.tx, ty: d.ty)
    }

    static func interpolate(_ m0: CGAffineTransform, _ m1: CGAffineTransform,
                            _ u: CGFloat) -> CGAffineTransform {
        if u <= 0 { return m0 }
        if u >= 1 { return m1 }
        guard let d0 = decompose(m0), let d1 = decompose(m1) else {
            // Degenerate matrix: componentwise lerp (CA also degrades here).
            return CGAffineTransform(a: m0.a + (m1.a - m0.a) * u,
                                     b: m0.b + (m1.b - m0.b) * u,
                                     c: m0.c + (m1.c - m0.c) * u,
                                     d: m0.d + (m1.d - m0.d) * u,
                                     tx: m0.tx + (m1.tx - m0.tx) * u,
                                     ty: m0.ty + (m1.ty - m0.ty) * u)
        }
        var dr = d1.rotation - d0.rotation
        while dr > .pi { dr -= 2 * .pi }
        while dr < -.pi { dr += 2 * .pi }
        return compose(Decomposed(
            scaleX: d0.scaleX + (d1.scaleX - d0.scaleX) * u,
            scaleY: d0.scaleY + (d1.scaleY - d0.scaleY) * u,
            shear: d0.shear + (d1.shear - d0.shear) * u,
            rotation: d0.rotation + dr * u,
            tx: d0.tx + (d1.tx - d0.tx) * u,
            ty: d0.ty + (d1.ty - d0.ty) * u))
    }
}

// MARK: - Transcendental helpers (no Foundation)

/// Natural log; range-reduced via the binary exponent, then the atanh
/// series ln(s) = 2·(t + t³/3 + t⁵/5 + …), t = (s−1)/(s+1). |t| ≤ 0.2 after
/// reduction, so the series reaches double precision in ≤ 9 terms.
func _ln(_ x: Double) -> Double {
    precondition(x > 0, "_ln domain")
    let ln2 = 0.6931471805599453094
    var e = Double(x.exponent)
    var s = x.significand            // s ∈ [1, 2)
    if s > 1.5 { s /= 2; e += 1 }    // s ∈ [0.75, 1.5]
    let t = (s - 1) / (s + 1)
    let t2 = t * t
    var term = t
    var sum = t
    for k in 1...9 {
        term *= t2
        sum += term / Double(2 * k + 1)
    }
    return e * ln2 + 2 * sum
}

/// atan via repeated half-angle reduction + Taylor series (~1e-15).
func _atan(_ x: CGFloat) -> CGFloat {
    var v = x
    var mult: CGFloat = 1
    for _ in 0..<4 {
        v = v / (1 + (1 + v * v).squareRoot())
        mult *= 2
    }
    let v2 = v * v
    var term = v
    var sum = v
    for k in 1...7 {
        term *= -v2
        sum += term / CGFloat(2 * k + 1)
    }
    return mult * sum
}

func _atan2(_ y: CGFloat, _ x: CGFloat) -> CGFloat {
    if x > 0 { return _atan(y / x) }
    if x < 0 { return y >= 0 ? _atan(y / x) + .pi : _atan(y / x) - .pi }
    if y > 0 { return .pi / 2 }
    if y < 0 { return -.pi / 2 }
    return 0
}
