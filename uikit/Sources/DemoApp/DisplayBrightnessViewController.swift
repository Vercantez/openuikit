// Display & Brightness screen. Owner: demo app (M7.5).
//
// APP_FEEL detail screen #2: a toggle group (UISwitch rows) and a draggable
// brightness slider driven by a UIPanGestureRecognizer (the "slider-ish
// progress-style drag" the spec asks for). The footer label live-updates
// with the dragged percentage so scripted captures can verify the drag.

import OpenUIKit

// MARK: - Slider

/// UISlider-style control: 4pt track, tint fill, 28pt white thumb with a
/// soft shadow. Value is dragged with a pan (1:1 in track units from the
/// value at pan start); sends .valueChanged continuously.
public final class BrightnessSlider: UIControl {
    public static let height: CGFloat = 34
    static let trackHeight: CGFloat = 4
    static let thumbSize: CGFloat = 28

    public var value: CGFloat = 0.5 {
        didSet {
            let clamped = min(max(value, 0), 1)
            if value != clamped { value = clamped }
            if value != oldValue {
                setNeedsLayout()
                layoutIfNeeded()
            }
        }
    }

    let track = UIView()
    let fill = UIView()
    let thumb = UIView()
    let pan = UIPanGestureRecognizer()
    var panStartValue: CGFloat = 0

    public init(value: CGFloat) {
        super.init(frame: CGRect(x: 0, y: 0, width: 200,
                                 height: BrightnessSlider.height))
        self.value = min(max(value, 0), 1)
        isOpaque = false

        track.backgroundColor = .systemFill
        track.layer.cornerRadius = BrightnessSlider.trackHeight / 2
        track.isUserInteractionEnabled = false
        addSubview(track)

        fill.backgroundColor = tintColor
        fill.layer.cornerRadius = BrightnessSlider.trackHeight / 2
        fill.isUserInteractionEnabled = false
        addSubview(fill)

        thumb.backgroundColor = .white
        thumb.layer.cornerRadius = BrightnessSlider.thumbSize / 2
        thumb.layer.shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        thumb.layer.shadowOpacity = 0.22
        thumb.layer.shadowRadius = 4
        thumb.layer.shadowOffset = CGSize(width: 0, height: 2)
        thumb.isUserInteractionEnabled = false
        addSubview(thumb)

        pan.addTarget { [weak self] r in
            guard let self, let pan = r as? UIPanGestureRecognizer else { return }
            self.handlePan(pan)
        }
        addGestureRecognizer(pan)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    var trackWidth: CGFloat {
        bounds.width - BrightnessSlider.thumbSize
    }

    func handlePan(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            panStartValue = value
        case .changed:
            guard trackWidth > 0 else { return }
            let dx = pan.translation(in: self).x
            let newValue = min(max(panStartValue + dx / trackWidth, 0), 1)
            if newValue != value {
                value = newValue
                sendActions(for: .valueChanged)
            }
        default:
            break
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let midY = bounds.height / 2
        let inset = BrightnessSlider.thumbSize / 2
        track.frame = CGRect(x: 0, y: midY - BrightnessSlider.trackHeight / 2,
                             width: bounds.width,
                             height: BrightnessSlider.trackHeight)
        let thumbX = inset + trackWidth * value
        fill.frame = CGRect(x: 0, y: track.frame.minY,
                            width: thumbX,
                            height: BrightnessSlider.trackHeight)
        thumb.frame = CGRect(x: thumbX - inset, y: midY - inset,
                             width: BrightnessSlider.thumbSize,
                             height: BrightnessSlider.thumbSize)
    }
}

/// Bare gray sun glyph (the min/max icons flanking the brightness slider).
final class SunIconView: UIView {
    init(size: CGFloat) {
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        isOpaque = false
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let gray = UIColor.systemGray2.resolvedCGColor(with: traitCollection)
        drawIconGlyph(.sun, in: canvas, bounds: bounds, color: gray)
    }
}

// MARK: - Screen

public final class DisplayBrightnessViewController: UIViewController {
    let slider = BrightnessSlider(value: 0.72)
    let footer = makeFootnote("Brightness: 72%")

    public init() { super.init() }
    public required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        if title == nil { title = "Display & Brightness" }
        view.backgroundColor = .systemGroupedBackground

        let margin: CGFloat = 16
        let width = view.bounds.width - 2 * margin
        var y: CGFloat = 18

        // Toggle group.
        let trueTone = SettingsRow(title: "True Tone", accessory: .toggle(true))
        let nightShift = SettingsRow(title: "Night Shift", accessory: .toggle(false))
        let raiseToWake = SettingsRow(title: "Raise to Wake", accessory: .toggle(true))
        let card = GroupCard(rows: [trueTone, nightShift, raiseToWake])
        card.frame = CGRect(x: margin, y: y, width: width,
                            height: card.bounds.height)
        card.autoresizingMask = [.flexibleWidth]
        view.addSubview(card)
        y = card.frame.maxY + 30

        // BRIGHTNESS card with the pan-driven slider.
        let header = makeSectionHeader("BRIGHTNESS")
        let hs = header.intrinsicContentSize
        header.frame = CGRect(x: margin + 16, y: y, width: hs.width,
                              height: hs.height)
        view.addSubview(header)
        y = header.frame.maxY + 7

        let sliderCard = UIView(frame: CGRect(x: margin, y: y, width: width,
                                              height: 64))
        sliderCard.backgroundColor = .secondarySystemGroupedBackground
        sliderCard.layer.cornerRadius = 10
        sliderCard.autoresizingMask = [.flexibleWidth]
        view.addSubview(sliderCard)

        let smallSun = SunIconView(size: 16)
        smallSun.frame = CGRect(x: 16, y: (64 - 16) / 2, width: 16, height: 16)
        sliderCard.addSubview(smallSun)
        let bigSun = SunIconView(size: 24)
        bigSun.frame = CGRect(x: width - 16 - 24, y: (64 - 24) / 2,
                              width: 24, height: 24)
        bigSun.autoresizingMask = [.flexibleLeftMargin]
        sliderCard.addSubview(bigSun)

        let sliderX = smallSun.frame.maxX + 10
        slider.frame = CGRect(x: sliderX,
                              y: (64 - BrightnessSlider.height) / 2,
                              width: bigSun.frame.minX - 10 - sliderX,
                              height: BrightnessSlider.height)
        slider.autoresizingMask = [.flexibleWidth]
        slider.addTarget(for: .valueChanged) { [weak self] control, _ in
            guard let self, let s = control as? BrightnessSlider else { return }
            let pct = Int((s.value * 100).rounded())
            self.footer.text = "Brightness: \(pct)%"
            self.footer.setNeedsLayout()
        }
        sliderCard.addSubview(slider)
        y = sliderCard.frame.maxY + 8

        let fs = footer.sizeThatFits(CGSize(width: width - 32, height: 100))
        footer.frame = CGRect(x: margin + 16, y: y, width: width - 32,
                              height: fs.height)
        view.addSubview(footer)
    }
}
