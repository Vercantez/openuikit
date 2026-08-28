// UIStepper. Owner: controls module (app-compat cluster "controls2").
//
// WHY THERE IS NO FIXTURE, AND WHERE THE NUMBERS COME FROM
//
// Real UIKit draws a stepper through a SwiftUI hosting view — the view tree
// is `UIStepper > UIStepperDesignLibraryVisualElement >
// UICoreHostingView<DesignLibraryStepper>` and nothing else — so an
// offscreen `layer.render(in:)` of one produces a COMPLETELY EMPTY image
// (measured this pass: 0 of 12032 non-transparent pixels at 2x). The control
// therefore renders only in the WINDOWED oracle (`Tools/oracle2`), which
// needs an active, unlocked display session and is unavailable in this
// environment (docs/KNOWN_GAPS.md records the same blocker from the previous
// controls cluster, which is exactly why UIStepper was deferred then).
//
// What IS available is the windowed probe the previous cluster took before
// it hit that wall, recorded in docs/KNOWN_GAPS.md, plus the properties this
// pass read straight off a live control:
//
//   MEASURED, this pass (property reads — no rendering needed):
//     * `intrinsicContentSize == (94, 32)`.
//     * Defaults: value 0, minimumValue 0, maximumValue 100, stepValue 1,
//       isContinuous true, autorepeat true, wraps false. (UIKit's
//       documented defaults, confirmed on a live control.)
//
//   MEASURED, previous cluster (windowed capture over white, iOS 26.1
//   Catalyst — docs/KNOWN_GAPS.md "Deferred, with the reason"):
//     * A 94 x 32 capsule background at about (243, 243, 243) over white,
//       i.e. a quaternarySystemFill-like material.
//     * The MINUS bar spans x 37…50 for a control at x = 20 — local x 17…30,
//       13 pt long — in near-black (37, 37, 37).
//     * A 1 pt divider at the centre, colour about 180.
//     * A matching 13 pt PLUS bar centred in the right half.
//
//   NOT MEASURED (the capture that would have shown them is the one that
//   could not be taken):
//     * The bars' THICKNESS. `barThickness` below is a placeholder.
//     * The capsule's corner radius — drawn as a true capsule (height / 2).
//     * The pressed/disabled appearance, and the divider's exact inset.
//
// Everything about the BEHAVIOUR is UIKit's documented model and is unit
// tested: stepping, clamping, `wraps`, `isContinuous`, and `.valueChanged`.
// `autorepeat` is accepted and IGNORED — repeating on a held touch needs a
// timer on the host clock, and no fixture or scripted capture exercises it.

@preconcurrency @MainActor
open class UIStepper: UIControl {
    /// Measured intrinsic size.
    public static let intrinsicSize = CGSize(width: 94, height: 32)
    /// Measured: the minus bar is 13 pt long, centred in the left half.
    static let barLength: CGFloat = 13
    /// NOT measured — placeholder (file header).
    static let barThickness: CGFloat = 1.5
    /// Measured: near-black (37, 37, 37) over white.
    static let glyphColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 232.0 / 255.0, alpha: 1)
            : UIColor(white: 37.0 / 255.0, alpha: 1)
    })
    /// Measured: the capsule reads (243, 243, 243) over white — the
    /// quaternarySystemFill family.
    static let backgroundFill = UIColor.quaternarySystemFill
    /// Measured: a 1 pt divider at the centre, colour about 180.
    static let dividerColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 90.0 / 255.0, alpha: 1)
            : UIColor(white: 180.0 / 255.0, alpha: 1)
    })
    static let dividerWidth: CGFloat = 1

    // MARK: UIKit's documented value model

    public var value: Double = 0 {
        didSet {
            let clamped = clamp(value)
            if clamped != value { value = clamped; return }
            if value != oldValue { setNeedsDisplay() }
        }
    }
    public var minimumValue: Double = 0 { didSet { value = clamp(value) } }
    public var maximumValue: Double = 100 { didSet { value = clamp(value) } }
    public var stepValue: Double = 1
    /// `.valueChanged` fires on every step while the touch is down (true) or
    /// only when it lifts (false). UIKit's default is true.
    public var isContinuous = true
    /// Accepted and IGNORED — see the file header.
    public var autorepeat = true
    /// Stepping past an end wraps to the other one instead of clamping.
    public var wraps = false

    public override init(frame: CGRect) {
        super.init(frame: frame.width == 0 && frame.height == 0
                   ? CGRect(origin: .zero, size: UIStepper.intrinsicSize)
                   : frame)
    }

    public convenience init() {
        self.init(frame: CGRect(origin: .zero, size: UIStepper.intrinsicSize))
    }

    open override var intrinsicContentSize: CGSize { UIStepper.intrinsicSize }
    open override func sizeThatFits(_ size: CGSize) -> CGSize { UIStepper.intrinsicSize }

    private func clamp(_ v: Double) -> Double {
        guard maximumValue > minimumValue else { return minimumValue }
        return min(max(v, minimumValue), maximumValue)
    }

    /// One step in either direction, honouring `wraps`. Returns whether the
    /// value actually moved.
    @discardableResult
    func step(_ direction: Double) -> Bool {
        let before = value
        var next = value + direction * stepValue
        if wraps {
            if next > maximumValue { next = minimumValue }
            else if next < minimumValue { next = maximumValue }
        }
        value = clamp(next)
        return value != before
    }

    // MARK: Touch handling — left half decrements, right half increments

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard isEnabled, let t = touches.first else { return }
        let p = t.location(in: self)
        let moved = step(p.x < bounds.midX ? -1 : 1)
        if moved, isContinuous { sendActions(for: .valueChanged) }
        _pendingChange = moved && !isContinuous
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if _pendingChange { sendActions(for: .valueChanged) }
        _pendingChange = false
    }

    private var _pendingChange = false

    // MARK: Drawing (see the file header for what is measured)

    open override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let traits = traitCollection
        canvas.fill(Path.roundedRect(bounds, cornerRadius: bounds.height / 2),
                    color: UIStepper.backgroundFill.resolvedCGColor(with: traits))
        let divider = CGRect(x: bounds.midX - UIStepper.dividerWidth / 2,
                             y: bounds.minY, width: UIStepper.dividerWidth,
                             height: bounds.height)
        canvas.fill(Path.rect(divider),
                    color: UIStepper.dividerColor.resolvedCGColor(with: traits))

        let glyph = UIStepper.glyphColor.resolvedCGColor(with: traits)
        let t = UIStepper.barThickness
        let l = UIStepper.barLength
        let leftCX = bounds.minX + bounds.width / 4
        let rightCX = bounds.maxX - bounds.width / 4
        let cy = bounds.midY
        canvas.fill(Path.rect(CGRect(x: leftCX - l / 2, y: cy - t / 2,
                                     width: l, height: t)), color: glyph)
        canvas.fill(Path.rect(CGRect(x: rightCX - l / 2, y: cy - t / 2,
                                     width: l, height: t)), color: glyph)
        canvas.fill(Path.rect(CGRect(x: rightCX - t / 2, y: cy - l / 2,
                                     width: t, height: l)), color: glyph)
    }
}
