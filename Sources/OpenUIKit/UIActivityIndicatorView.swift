// UIActivityIndicatorView. Owner: controls module (app-compat cluster).
//
// Every number below is measured from real UIKit (Mac Catalyst iOS 26.1)
// via the offscreen oracle — the spinner is one of the few iOS 26 controls
// that DOES render through `layer.render(in:)`, so `fixtures/scenes/
// control_activity.json` is a normal v1 golden.
//
// Geometry (probe: indicators at several frame sizes, both styles):
//   - 8 capsule blades on a circle, 45 degrees apart, long axis radial.
//   - medium: intrinsic 20x20, blade 6.5 x 2.5 (cap radius 1.25), blade
//     centre 6.75 pt from the graphic centre => ink spans radius 3.5 .. 10.
//     (Length/thickness are least-squares fits of an analytic capsule
//     coverage field to the golden's pixels, not bbox reads: the bbox
//     includes the anti-aliased rows.)
//   - large:  intrinsic 37x37, blade 12 x 5 (cap radius 2.5), blade centre
//     11.5 pt from the centre => ink spans radius 5.5 .. 17.5. The large
//     graphic is 35 pt wide inside its 37 pt box: its centre sits at
//     origin + 17.5, NOT at the box centre.
//   - The graphic box is placed at floor((bounds.size - intrinsic) / 2)
//     (a 60x60 indicator dumps its image view at 11, not 11.5).
//
// Blade opacity ladder (probed with a pure-red indicator over white, which
// isolates alpha exactly): 217, 180, 143, 106, 69, 69, 69, 69 (/255),
// starting at the LEFT (9 o'clock) blade and getting lighter counter-
// clockwise. The four trailing blades share the 69/255 floor.
//
// Default color: a neutral dynamic gray — white 128/255 light, 140/255 dark
// (solved from the light/dark goldens with the ladder above; both fit every
// blade to within 1 count).
//
// NOT oracle-validated: the rotation TIMING. Core Animation discards the
// spin animation offscreen and the windowed oracle can only sample it on
// the wall clock, so the goldens pin the REST pose (step 0). The animation
// implemented here is UIKit's classic discrete one — the ladder advances
// one blade (45 degrees, clockwise) every 1/8 s, i.e. one revolution per
// second. See docs/KNOWN_GAPS.md.

public enum UIActivityIndicatorViewStyle: Sendable {
    case medium, large
}

@preconcurrency @MainActor
open class UIActivityIndicatorView: UIView {
    public typealias Style = UIActivityIndicatorViewStyle

    struct Metrics {
        let size: CGFloat          // intrinsic square side
        let outer: CGFloat         // graphic radius (centre offset inside the box)
        let ring: CGFloat          // blade centre distance from the graphic centre
        let bladeLength: CGFloat
        let bladeThickness: CGFloat
    }
    static let mediumMetrics = Metrics(size: 20, outer: 10, ring: 6.75,
                                       bladeLength: 6.5, bladeThickness: 2.5)
    static let largeMetrics = Metrics(size: 37, outer: 17.5, ring: 11.5,
                                      bladeLength: 12, bladeThickness: 5)

    /// Per-blade alpha, blade 0 = the darkest (left / 9 o'clock) one.
    static let bladeAlphas: [CGFloat] = [217, 180, 143, 106, 69, 69, 69, 69]
        .map { $0 / 255 }
    static let bladeCount = 8
    /// Seconds per 45-degree step (see the header note: not oracle-timed).
    static let stepDuration: Double = 1.0 / 8.0

    /// The measured default color (neutral dynamic gray).
    public static let defaultColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 140.0 / 255.0, alpha: 1)
            : UIColor(white: 128.0 / 255.0, alpha: 1)
    })

    public let style: Style
    public var color: UIColor = UIActivityIndicatorView.defaultColor {
        didSet { setNeedsDisplay() }
    }
    public var hidesWhenStopped: Bool = true {
        didSet { setNeedsDisplay() }
    }
    public private(set) var isAnimating: Bool = false

    /// `OpenUIKitRuntime.animationTime` when the spin started.
    var animationStart: Double = 0

    public init(style: Style = .medium) {
        self.style = style
        super.init(frame: CGRect(origin: .zero,
                                 size: UIActivityIndicatorView.metrics(style).sizeValue))
        isUserInteractionEnabled = false
    }

    public override init(frame: CGRect) {
        self.style = .medium
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    static func metrics(_ style: Style) -> Metrics {
        style == .large ? largeMetrics : mediumMetrics
    }
    var metrics: Metrics { UIActivityIndicatorView.metrics(style) }

    public func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        animationStart = OpenUIKitRuntime.animationTime
        setNeedsDisplay()
    }

    public func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        setNeedsDisplay()
    }

    public override var intrinsicContentSize: CGSize { metrics.sizeValue }
    public override func sizeThatFits(_ size: CGSize) -> CGSize { metrics.sizeValue }

    /// Which 45-degree step the ladder has advanced to. Also extends the
    /// host's redraw deadline: a spinner is never "settled", so a host that
    /// skips static frames must be told there is still work.
    var currentStep: Int {
        guard isAnimating else { return 0 }
        let now = OpenUIKitRuntime.animationTime
        OpenUIKitRuntime.noteAnimationWork(until: now + UIActivityIndicatorView.stepDuration)
        let elapsed = now - animationStart
        guard elapsed > 0 else { return 0 }
        let steps = (elapsed / UIActivityIndicatorView.stepDuration).rounded(.down)
        return Int(steps.truncatingRemainder(dividingBy: Double(UIActivityIndicatorView.bladeCount)))
    }

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard isAnimating || !hidesWhenStopped else { return }
        guard bounds.width > 0, bounds.height > 0 else { return }
        let m = metrics
        let base = color.resolvedCGColor(with: traitCollection)
        guard base.alpha > 0 else { return }

        let ox = ((bounds.width - m.size) / 2).rounded(.down)
        let oy = ((bounds.height - m.size) / 2).rounded(.down)
        let cx = bounds.minX + ox + m.outer
        let cy = bounds.minY + oy + m.outer
        let step = CGFloat(currentStep)

        let local = CGRect(x: -m.bladeLength / 2, y: -m.bladeThickness / 2,
                           width: m.bladeLength, height: m.bladeThickness)
        let capsule = Path.roundedRect(local, cornerRadius: m.bladeThickness / 2)

        for k in 0..<UIActivityIndicatorView.bladeCount {
            let alpha = UIActivityIndicatorView.bladeAlphas[k]
            // Screen angle (y down): blade 0 at pi (left), the ladder runs
            // counter-clockwise; `step` rotates the whole graphic clockwise.
            let phi = .pi - CGFloat(k) * .pi / 4 + step * .pi / 4
            let px = cx + m.ring * _bpCos(phi)
            let py = cy + m.ring * _bpSin(phi)
            let t = CGAffineTransform(rotationAngle: phi)
                .concatenating(CGAffineTransform(translationX: px, y: py))
            canvas.fill(capsule.applying(t), color: base.withAlpha(alpha))
        }
    }
}

extension UIActivityIndicatorView.Metrics {
    var sizeValue: CGSize { CGSize(width: size, height: size) }
}
