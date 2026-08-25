// UISwitch. Owner: controls module.
//
// Metrics and colors are measured from golden/switch_onoff.{png,layout.json}
// (Mac Catalyst iOS 26.1, rendered by Tools/oracle2 in a real UIWindow):
//
//   - UIKit FORCES the switch frame to 63x28 regardless of the frame that is
//     set (origin preserved). intrinsicContentSize is 61x28 (yes, 2pt
//     narrower than the forced frame — that is what the oracle dumps).
//   - Track: a circular capsule filling the whole 63x28 bounds
//     (radius = height/2 = 14). Corner profile matches the plain kappa
//     rounded rect within ~0.3px at scale 2.
//   - On fill: onTintColor, default = tintColor (systemBlue; golden's default
//     track is exactly systemBlue light (0,136,255), NOT systemGreen on this
//     runtime).
//   - Off fill (light): black at alpha 66/255 (~0.259). The golden background
//     is transparent there and the un-composited track pixels are exactly
//     (0, 0, 0, 66). Dark mode uses white at alpha 63/255 (see offTrackColor).
//   - Thumb: white circular capsule, 37x24, inset 2pt from the track edge
//     (off: x=2, on: x=63-2-37=24; y=2). Golden thumb outline matches a
//     circular corner radius of 12 (height/2) within ~0.1px; no visible
//     shadow survives in the golden capture.
public class UISwitch: UIControl {
    /// Frame size real UIKit forces on every UISwitch (Catalyst iOS 26.1).
    static let forcedSize = CGSize(width: 63, height: 28)
    static let intrinsicSize = CGSize(width: 61, height: 28)
    static let thumbSize = CGSize(width: 37, height: 24)
    static let thumbInset: CGFloat = 2
    /// Off-state track fill. Dynamic: measured by probing the real-window
    /// oracle (Tools/oracle2) with an off switch over pure black and pure
    /// white backgrounds and solving the composite per channel:
    ///   light: over black -> (0,0,0), over white -> 189/255  => black @ 66/255
    ///   dark:  over black -> 63/255,  over white -> 255/255  => white @ 63/255
    static let offTrackColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 63.0 / 255.0)
            : UIColor(white: 0, alpha: 66.0 / 255.0)
    })

    public var isOn: Bool = false
    public var onTintColor: UIColor?
    public var thumbTintColor: UIColor?

    // MARK: - Toggle animation model (fitted against golden/switch_toggle_anim)
    //
    // Real (iOS 26 Catalyst) UISwitch.setOn(_:animated: true) is a hybrid:
    //   * The blue "well" slides in/out under a CASpringAnimation probed
    //     directly from the oracle: critically damped, DURATION-FIT with
    //     UIKit's ωD = 9.2334 settling equation (same model as our
    //     UIView spring engine): off→on ωn = 9.2400 / D = 0.99947,
    //     on→off ωn = 15.7080 / D = 0.58792. The local blue coverage
    //     measured in the golden frames is linear in the spring progress
    //     with a per-side offset (blue arrives at the LEFT end first when
    //     turning on, and leaves the RIGHT end first when turning off);
    //     coverage is flat within each side of the thumb.
    //   * The THUMB is display-link driven (_UILiquidLensView — no
    //     CAAnimation); its travel is captured on the wall clock and
    //     fitted exactly (≤ 0.001 residual at every golden capture time)
    //     by the cubic bezier (0.160, 0.004)-(0.406, 1.192) over 0.336 s,
    //     identical in both directions.
    struct ToggleAnimation {
        let fromOn: Bool
        let start: Double     // OpenUIKitRuntime.animationTime at setOn
    }
    var toggleAnim: ToggleAnimation?

    static let onTrackSpringOmega = 9.2400      // sqrt(85.3772...)
    static let onTrackDuration = 0.99947
    static let offTrackSpringOmega = 15.7080    // sqrt(246.7401...)
    static let offTrackDuration = 0.58792
    static let thumbDuration = 0.336
    // Golden-fitted local-coverage maps (see file header note above).
    static let onCoverageLeft: (CGFloat) -> CGFloat = { p in 1.048 * p + 0.057 }
    static let onCoverageRight: (CGFloat) -> CGFloat = { p in 1.041 * p - 0.042 }
    static let offRemovedLeft: (CGFloat) -> CGFloat = { p in 0.974 * p + 0.032 }
    static let offRemovedRight: (CGFloat) -> CGFloat = { p in 0.969 * p + 0.137 }

    public init() {
        super.init(frame: CGRect(origin: .zero, size: UISwitch.forcedSize))
    }

    public override init(frame: CGRect) {
        // UIKit ignores the size and keeps the origin.
        super.init(frame: CGRect(origin: frame.origin, size: UISwitch.forcedSize))
    }

    public func setOn(_ on: Bool, animated: Bool) {
        if animated, on != isOn {
            toggleAnim = ToggleAnimation(fromOn: isOn,
                                         start: OpenUIKitRuntime.animationTime)
            // Host redraw hint: the slowest component (off->on track spring)
            // settles within ~1.0s of the toggle.
            OpenUIKitRuntime.noteAnimationWork(
                until: OpenUIKitRuntime.animationTime + UISwitch.onTrackDuration + 0.05)
        } else if !animated {
            toggleAnim = nil
        }
        isOn = on
    }

    // MARK: - Toggle-animation math (pure Swift, no Foundation)

    /// 1 − (1 + ωt)·e^(−ωt): critically damped spring step response.
    func _criticalSpringProgress(omega: Double, t: Double) -> Double {
        guard t > 0 else { return 0 }
        let x = omega * t
        return 1 - (1 + x) * _expNeg(x)
    }

    /// e^(−x) for x ≥ 0 (range-reduced Taylor; ~1e-12 for the ranges used).
    func _expNeg(_ x: Double) -> Double {
        guard x > 0 else { return 1 }
        // e^-x = (e^-x/2^k)^(2^k) with x/2^k <= 0.5
        var k = 0
        var y = x
        while y > 0.5 { y /= 2; k += 1 }
        var term = 1.0
        var sum = 1.0
        for i in 1...16 {
            term *= -y / Double(i)
            sum += term
        }
        for _ in 0..<k { sum *= sum }
        return sum
    }

    /// Thumb travel curve: cubic bezier (0.160, 0.004)-(0.406, 1.192) in
    /// normalized time u = t / thumbDuration (fitted exactly to the golden
    /// wall-clock captures; identical both directions).
    func _thumbCurve(_ u: Double) -> Double {
        if u <= 0 { return 0 }
        if u >= 1 { return 1 }
        let c1x = 0.160, c1y = 0.004, c2x = 0.406, c2y = 1.192
        // Solve x(s) = u by bisection (x is monotone for 0<=c1x,c2x<=1).
        var lo = 0.0, hi = 1.0
        for _ in 0..<48 {
            let s = (lo + hi) / 2
            let om = 1 - s
            let xv = 3 * om * om * s * c1x + 3 * om * s * s * c2x + s * s * s
            if xv < u { lo = s } else { hi = s }
        }
        let s = (lo + hi) / 2
        let om = 1 - s
        return 3 * om * om * s * c1y + 3 * om * s * s * c2y + s * s * s
    }

    // MARK: - Control behavior (tap toggles)

    /// UIKit: releasing inside the switch toggles it (with the thumb-slide
    /// animation) and fires .valueChanged. Releasing outside cancels.
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        guard isTouchInside else { return }
        setOn(!isOn, animated: true)
        sendActions(for: .valueChanged, with: event)
    }

    public override var intrinsicContentSize: CGSize { UISwitch.intrinsicSize }

    public override func sizeThatFits(_ size: CGSize) -> CGSize { UISwitch.forcedSize }

    public override func layoutSubviews() {
        // UIView.frame is not overridable here, so the forced size is
        // re-asserted in layout (openrender always lays out before it dumps
        // or renders). Origin (for identity transforms: frame.origin) stays.
        super.layoutSubviews()
        if bounds.size != UISwitch.forcedSize {
            if transform.isIdentity {
                frame = CGRect(origin: frame.origin, size: UISwitch.forcedSize)
            } else {
                bounds.size = UISwitch.forcedSize
            }
        }
    }

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let traits = traitCollection
        let thumbSize = UISwitch.thumbSize
        let thumbColor = (thumbTintColor ?? .white).resolvedCGColor(with: traits)
        let trackPath = Path.roundedRect(bounds, cornerRadius: bounds.height / 2)
        let offX = bounds.minX + UISwitch.thumbInset
        let onX = bounds.maxX - UISwitch.thumbInset - thumbSize.width

        // Mid-flight toggle animation?
        if let anim = toggleAnim {
            let turningOn = !anim.fromOn
            let elapsed = OpenUIKitRuntime.animationTime - anim.start
            let trackDur = turningOn ? UISwitch.onTrackDuration
                                     : UISwitch.offTrackDuration
            if elapsed >= 0, elapsed < trackDur {
                let onColor = (onTintColor ?? tintColor).resolvedCGColor(with: traits)
                let offColor = UISwitch.offTrackColor.resolvedCGColor(with: traits)
                // Track: off capsule + on-color plateaus (left/right of the
                // thumb) at the golden-fitted coverages.
                let omega = turningOn ? UISwitch.onTrackSpringOmega
                                      : UISwitch.offTrackSpringOmega
                let p = CGFloat(_criticalSpringProgress(omega: omega, t: elapsed))
                let clamp: (CGFloat) -> CGFloat = { Swift.min(1, Swift.max(0, $0)) }
                let covL = turningOn ? clamp(UISwitch.onCoverageLeft(p))
                                     : clamp(1 - UISwitch.offRemovedLeft(p))
                let covR = turningOn ? clamp(UISwitch.onCoverageRight(p))
                                     : clamp(1 - UISwitch.offRemovedRight(p))
                // Thumb travel (0 = off side, 1 = on side).
                let f = clamp(CGFloat(_thumbCurve(elapsed / UISwitch.thumbDuration)))
                let pos = turningOn ? f : 1 - f
                let thumbX = offX + (onX - offX) * pos
                let thumbMid = thumbX + thumbSize.width / 2

                canvas.fill(trackPath, color: offColor)
                canvas.save()
                canvas.clip(to: trackPath)
                if covL > 0 {
                    canvas.fill(rect: CGRect(x: bounds.minX, y: bounds.minY,
                                             width: thumbMid - bounds.minX,
                                             height: bounds.height),
                                color: onColor.withAlpha(onColor.alpha * covL))
                }
                if covR > 0 {
                    canvas.fill(rect: CGRect(x: thumbMid, y: bounds.minY,
                                             width: bounds.maxX - thumbMid,
                                             height: bounds.height),
                                color: onColor.withAlpha(onColor.alpha * covR))
                }
                canvas.restore()

                let thumbRect = CGRect(x: thumbX,
                                       y: bounds.minY + UISwitch.thumbInset,
                                       width: thumbSize.width,
                                       height: thumbSize.height)
                canvas.fill(Path.roundedRect(thumbRect,
                                             cornerRadius: thumbSize.height / 2),
                            color: thumbColor)
                return
            }
        }

        // Static state (or settled animation): the original exact drawing.
        let trackColor: CGColor = isOn
            ? (onTintColor ?? tintColor).resolvedCGColor(with: traits)
            : UISwitch.offTrackColor.resolvedCGColor(with: traits)
        canvas.fill(trackPath, color: trackColor)

        let x = isOn ? onX : offX
        let thumbRect = CGRect(x: x, y: bounds.minY + UISwitch.thumbInset,
                               width: thumbSize.width, height: thumbSize.height)
        canvas.fill(Path.roundedRect(thumbRect, cornerRadius: thumbSize.height / 2),
                    color: thumbColor)
    }
}
