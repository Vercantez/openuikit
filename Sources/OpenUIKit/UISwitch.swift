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
public class UISwitch: UIView {
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

    public init() {
        super.init(frame: CGRect(origin: .zero, size: UISwitch.forcedSize))
    }

    public override init(frame: CGRect) {
        // UIKit ignores the size and keeps the origin.
        super.init(frame: CGRect(origin: frame.origin, size: UISwitch.forcedSize))
    }

    public func setOn(_ on: Bool, animated: Bool) {
        isOn = on
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

        // Track: full-bounds capsule.
        let trackColor: CGColor = isOn
            ? (onTintColor ?? tintColor).resolvedCGColor(with: traits)
            : UISwitch.offTrackColor.resolvedCGColor(with: traits)
        canvas.fill(Path.roundedRect(bounds, cornerRadius: bounds.height / 2),
                    color: trackColor)

        // Thumb: white capsule inset 2pt, on the on/off side.
        let t = UISwitch.thumbSize
        let x = isOn ? bounds.maxX - UISwitch.thumbInset - t.width : bounds.minX + UISwitch.thumbInset
        let thumbRect = CGRect(x: x, y: bounds.minY + UISwitch.thumbInset,
                               width: t.width, height: t.height)
        let thumbColor = (thumbTintColor ?? .white).resolvedCGColor(with: traits)
        canvas.fill(Path.roundedRect(thumbRect, cornerRadius: t.height / 2),
                    color: thumbColor)
    }
}
