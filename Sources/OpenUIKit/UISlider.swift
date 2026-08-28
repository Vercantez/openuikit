// UISlider. Owner: controls module (app-compat cluster).
//
// Measured against real UIKit (Mac Catalyst iOS 26.1). The track and the
// minimum-track fill render offscreen (v1 oracle); the thumb is an
// iOS 26 `_UILiquidLensView` that only the render server draws, so the
// fixture (`fixtures/scenes/control_slider.json`) is a `"window": true`
// scene captured by Tools/oracle2 — the same rule UISwitch follows.
//
// Geometry (oracle layout dumps + pixel probes, slider 280 x 40, value .35):
//   - intrinsicContentSize = (noIntrinsicMetric, 34).
//   - Track: full width, 6 pt tall, vertically centred ((40-6)/2 = 17),
//     capsule (radius 3).
//   - Thumb: 37 x 24 capsule, vertically centred ((40-24)/2 = 8), and
//     thumbX = fraction * (width - 37)  (dumped 85 for .35 of 280).
//   - Minimum-track fill runs from the left edge to the THUMB CENTRE
//     (dumped fill width 103.55 = 85.05 + 18.5) and is drawn under the
//     thumb.
//   - Colors: minimum track = tintColor (systemBlue, measured (0,136,255));
//     maximum track = neutral gray (229,229,229) light / (68,68,68) dark;
//     thumb = white with a soft shadow (fitted below).
//
// The thumb shadow: the golden's darkness profile around the white capsule
// peaks at ~17/255 just under the bottom edge, ~13/255 above the top edge,
// and fades out over ~5 pt — i.e. a CA-style shadow of black at ~0.11
// opacity, blur radius 3 pt, offset (0, 1). Those three numbers are fitted
// to that measured profile, nothing else.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

@preconcurrency @MainActor
open class UISlider: UIControl {
    static let trackHeight: CGFloat = 6
    static let thumbSize = CGSize(width: 37, height: 24)
    static let intrinsicHeight: CGFloat = 34
    /// Fitted from the golden's shadow profile (see header).
    static let thumbShadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.11)
    static let thumbShadowOffset = CGSize(width: 0, height: 1)
    static let thumbShadowBlur: CGFloat = 6   // Canvas blur = 2 x CA radius

    /// Default maximum-track color: a TRANSLUCENT neutral, not systemGray5.
    /// Measured (control_slider / control_dark goldens): light reads 229 over
    /// white and (45,178,80) over systemGreen (53,199,89) — i.e. exactly
    /// black at 26/255 (a translucent fill, verified on two backdrops);
    /// dark reads 26 over black — white at the same 26/255, the same
    /// light/dark symmetry UISwitch's off track has.
    public static let defaultMaximumTrackColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 26.0 / 255.0)
            : UIColor(white: 0, alpha: 26.0 / 255.0)
    })

    public var minimumValue: Float = 0 { didSet { clampValue() } }
    public var maximumValue: Float = 1 { didSet { clampValue() } }
    public var value: Float = 0 {
        didSet {
            clampValue()
            if value != oldValue { setNeedsDisplay() }
        }
    }
    /// UIKit: continuous sliders fire .valueChanged while dragging.
    public var isContinuous: Bool = true

    public var minimumTrackTintColor: UIColor? { didSet { setNeedsDisplay() } }
    public var maximumTrackTintColor: UIColor? { didSet { setNeedsDisplay() } }
    public var thumbTintColor: UIColor? { didSet { setNeedsDisplay() } }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    /// UIKit's plain slider starts at its legacy 100 x 34 control size.
    /// Keep this distinct from an explicit `init(frame: .zero)` request.
    public convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 100,
                                height: UISlider.intrinsicHeight))
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func setValue(_ v: Float, animated: Bool = false) {
        value = v
    }

    private func clampValue() {
        let lo = Swift.min(minimumValue, maximumValue)
        let hi = Swift.max(minimumValue, maximumValue)
        if value < lo { value = lo }
        if value > hi { value = hi }
    }

    /// 0...1 position of `value` in the min...max range.
    var fraction: CGFloat {
        let span = maximumValue - minimumValue
        guard span > 0 else { return 0 }
        return CGFloat((value - minimumValue) / span)
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UISlider.intrinsicHeight)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: UISlider.intrinsicHeight)
    }

    // MARK: Geometry

    /// Exact (unrounded) thumb origin x offset inside the bounds.
    var exactThumbOffsetX: CGFloat {
        fraction * Swift.max(0, bounds.width - UISlider.thumbSize.width)
    }

    /// Thumb rect in bounds coordinates for the current value. The thumb is
    /// a SUBVIEW in real UIKit, so its origin lands on UIKit's integer-point
    /// frame grid (oracle: 0.35 x 243 = 85.05 dumps as 85; 0.5 x 243 = 121.5
    /// dumps as 122 — nearest, ties away from zero). The minimum-track fill
    /// below uses the UNROUNDED centre (dumped fill width 103.55).
    public var thumbRect: CGRect {
        let s = UISlider.thumbSize
        return CGRect(x: bounds.minX + exactThumbOffsetX.rounded(.toNearestOrAwayFromZero),
                      y: bounds.minY
                         + ((bounds.height - s.height) / 2).rounded(.toNearestOrAwayFromZero),
                      width: s.width, height: s.height)
    }

    var trackRect: CGRect {
        CGRect(x: bounds.minX, y: bounds.minY + (bounds.height - UISlider.trackHeight) / 2,
               width: bounds.width, height: UISlider.trackHeight)
    }

    /// Value a touch at `x` (bounds coordinates) selects, given the grab
    /// offset inside the thumb.
    func value(forThumbOriginX x: CGFloat) -> Float {
        let travel = bounds.width - UISlider.thumbSize.width
        guard travel > 0 else { return minimumValue }
        let f = Swift.max(0, Swift.min(1, x / travel))
        return minimumValue + Float(f) * (maximumValue - minimumValue)
    }

    // MARK: Tracking
    //
    // A touch that lands on the thumb drags it from where it was grabbed;
    // a touch on the track jumps the thumb to it and then drags (UIKit's
    // own track-tap behavior varies by version and is not oracle-pinned —
    // documented in docs/KNOWN_GAPS.md).

    private var grabOffset: CGFloat = 0

    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let p = touch.location(in: self)
        let t = thumbRect
        if t.contains(p) {
            grabOffset = p.x - t.minX
        } else {
            grabOffset = UISlider.thumbSize.width / 2
            updateValue(toTouchX: p.x, event: event)
        }
        return super.beginTracking(touch, with: event)
    }

    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateValue(toTouchX: touch.location(in: self).x, event: event)
        return super.continueTracking(touch, with: event)
    }

    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let touch { updateValue(toTouchX: touch.location(in: self).x, event: event) }
        super.endTracking(touch, with: event)
        if !isContinuous { sendActions(for: .valueChanged, with: event) }
    }

    private func updateValue(toTouchX x: CGFloat, event: UIEvent?) {
        let newValue = value(forThumbOriginX: x - grabOffset)
        guard newValue != value else { return }
        value = newValue
        if isContinuous { sendActions(for: .valueChanged, with: event) }
    }

    // MARK: Drawing

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let traits = traitCollection
        let track = trackRect
        let radius = UISlider.trackHeight / 2

        let maxColor = (maximumTrackTintColor ?? UISlider.defaultMaximumTrackColor)
            .resolvedCGColor(with: traits)
        canvas.fill(Path.roundedRect(track, cornerRadius: radius), color: maxColor)

        let thumb = thumbRect
        let fillWidth = exactThumbOffsetX + UISlider.thumbSize.width / 2
        if fillWidth > 0 {
            let minColor = (minimumTrackTintColor ?? tintColor).resolvedCGColor(with: traits)
            let fill = CGRect(x: track.minX, y: track.minY,
                              width: Swift.min(fillWidth, track.width),
                              height: track.height)
            canvas.save()
            canvas.clip(to: track, cornerRadius: radius)
            canvas.fill(Path.roundedRect(fill, cornerRadius: radius), color: minColor)
            canvas.restore()
        }

        let thumbColor = (thumbTintColor ?? .white).resolvedCGColor(with: traits)
        canvas.save()
        canvas.setShadow(color: UISlider.thumbShadowColor,
                         offset: UISlider.thumbShadowOffset,
                         blur: UISlider.thumbShadowBlur)
        canvas.fill(Path.roundedRect(thumb, cornerRadius: thumb.height / 2),
                    color: thumbColor)
        canvas.restore()
    }
}
