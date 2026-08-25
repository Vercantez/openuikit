// UIProgressView. Owner: controls module.
//
// Behavior verified against the Mac Catalyst oracle (iOS 26.1 UIKit) and
// golden/progress_views.{png,layout.json}:
//
// - The default-style bar is ALWAYS 4pt tall: intrinsicContentSize is
//   (noIntrinsicMetric, 4) and layout forces the bounds height to 4 even
//   when the frame was set taller (oracle probe: frame height 10 -> dumped
//   frame height 4, origin preserved).
// - Track and fill are pills: rounded rects with corner radius = height/2
//   (2pt). Measured from golden/progress_views.png — both ends of the
//   track AND of the fill are fully rounded.
// - Default progressTintColor is nil -> tintColor (systemBlue).
//   Default trackTintColor is nil -> systemFill (measured (120,120,128,51)
//   in the golden = systemFill light rgba(0.47,0.47,0.5,0.2)).
// - Fill width in points = round-half-up-to-integer of progress * width,
//   with a MINIMUM of 8pt (= pill diameter). Oracle probes:
//   0.333*280 = 93.24 -> 93; 0.5*281 = 140.5 -> 141; 0.01*280 = 2.8 -> 8.
//   At progress == 0 the fill layer keeps its 8pt minimum frame but is NOT
//   drawn (golden shows track only).
// - The fill draws ON TOP of the track (real UIKit stacks two image views).
//   Both are drawn directly in drawContent here; the private subview tree
//   (UIProgressViewModernVisualElement + image views) is excluded from
//   layout comparison, so no internal subviews are needed.

@MainActor
open class UIProgressView: UIView {
    /// Default-style track height in points (iOS 26 modern visual element).
    static let barHeight: CGFloat = 4
    /// Minimum fill length: the pill's diameter.
    static let minFillWidth: CGFloat = 8

    public var progress: Float = 0 {
        didSet { progress = min(max(progress, 0), 1) }
    }
    public var progressTintColor: UIColor?
    public var trackTintColor: UIColor?

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIProgressView.barHeight)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: UIProgressView.barHeight)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // Real UIKit forces the default-style bar to its 4pt height no
        // matter what frame height was assigned (frame origin preserved).
        if bounds.height != UIProgressView.barHeight {
            var f = frame
            f.size.height = UIProgressView.barHeight
            frame = f
        }
    }

    /// Fill length in points for the current progress and bounds width.
    /// Round half-up to whole points; minimum 8pt (pill diameter).
    var fillWidth: CGFloat {
        let exact = CGFloat(progress) * bounds.width
        return max(UIProgressView.minFillWidth,
                   exact.rounded(.toNearestOrAwayFromZero))
    }

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let traits = traitCollection
        let radius = bounds.height / 2

        let track = (trackTintColor ?? .systemFill).resolvedCGColor(with: traits)
        if track.alpha > 0 {
            canvas.fill(.roundedRect(bounds, cornerRadius: radius), color: track)
        }

        guard progress > 0 else { return }  // fill not drawn at 0
        let fill = (progressTintColor ?? tintColor).resolvedCGColor(with: traits)
        guard fill.alpha > 0 else { return }
        let fillRect = CGRect(x: bounds.minX, y: bounds.minY,
                              width: min(fillWidth, bounds.width), height: bounds.height)
        canvas.fill(.roundedRect(fillRect, cornerRadius: radius), color: fill)
    }
}
