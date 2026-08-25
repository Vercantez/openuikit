// Tasks demo app — row components. Owner: demo app (M7.5 second app).
//
// The pieces the Tasks list is built from:
//
//   - CheckboxView: a 24pt ring in the task's priority color plus a fill
//     disc that carries a white vector checkmark (Canvas paths — the
//     portable stack has no SF Symbols). Checking springs the fill's SCALE
//     from ~0 to 1 with damping 0.6; unchecking eases it back out.
//     Scale is animated with `transform` rather than the fill's bounds on
//     purpose: drawContent is rasterized at the view's MODEL bounds and the
//     result is composited through the layer's presentation transform, so a
//     transform animation scales the drawn checkmark for free, while a
//     bounds animation would not re-draw it.
//   - TaskRow: checkbox + title + priority dot + chevron, with the standard
//     table-row highlight flash (systemGray4 on touch-down, 0.3s fade back)
//     from docs/APP_FEEL.md. Touches that land on the checkbox never reach
//     the row, so the row's own tap (push detail) and the checkbox's tap
//     (complete/reopen) do not fight.
//   - TaskSectionCard: an inset-grouped card that CLIPS, so an inserted row
//     can slide in from behind its top edge, plus an empty-state label.
//   - PillButton: the floating "+ New Task" capsule.

import OpenUIKit

// MARK: - Checkbox

/// The white checkmark disc. Its own view so the fill can be scaled with a
/// spring while the ring behind it stays put.
final class CheckmarkFillView: UIView {
    static let size: CGFloat = 24

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        // Checkmark in a 24x24 design space, scaled to bounds.
        let s = min(bounds.width, bounds.height) / CheckmarkFillView.size
        guard s > 0 else { return }
        canvas.save()
        defer { canvas.restore() }
        canvas.translate(x: bounds.minX, y: bounds.minY)
        canvas.concatenate(CGAffineTransform(scaleX: s, y: s))
        var p = Path()
        p.move(to: CGPoint(x: 6.4, y: 12.4))
        p.addLine(to: CGPoint(x: 10.1, y: 16.1))
        p.addLine(to: CGPoint(x: 17.6, y: 8.3))
        canvas.stroke(p, color: CGColor(red: 1, green: 1, blue: 1, alpha: 1),
                      lineWidth: 2.4)
    }
}

/// The tappable checkbox. The view is a generous 40x52 hit area; the 24pt
/// ring is drawn centered in it.
public final class CheckboxView: UIControl {
    static let hitSize = CGSize(width: 40, height: TaskRow.height)
    static let ringDiameter: CGFloat = 24
    static let ringLineWidth: CGFloat = 2

    /// Spring used for the fill pop (docs/APP_FEEL.md: every state change
    /// animates; damping 0.6 gives the small overshoot iOS uses).
    static let fillSpringDuration: Double = 0.45
    static let fillSpringDamping: CGFloat = 0.6
    static let fillCollapseDuration: Double = 0.22

    let fill = CheckmarkFillView()

    public private(set) var isChecked: Bool
    public var priority: TaskPriority {
        didSet {
            guard priority != oldValue else { return }
            setNeedsDisplay()               // ring color
            fill.backgroundColor = priority.color
        }
    }

    public init(priority: TaskPriority, isChecked: Bool) {
        self.priority = priority
        self.isChecked = isChecked
        super.init(frame: CGRect(origin: .zero, size: CheckboxView.hitSize))
        isOpaque = false
        backgroundColor = .clear

        fill.bounds.size = CGSize(width: CheckmarkFillView.size,
                                  height: CheckmarkFillView.size)
        fill.backgroundColor = priority.color
        fill.layer.cornerRadius = CheckmarkFillView.size / 2
        fill.isUserInteractionEnabled = false
        fill.isOpaque = false
        addSubview(fill)
        applyCheckedState(animated: false)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        fill.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    public func setChecked(_ checked: Bool, animated: Bool) {
        guard checked != isChecked else { return }
        isChecked = checked
        applyCheckedState(animated: animated)
    }

    private static let collapsed = CGAffineTransform(scaleX: 0.01, y: 0.01)

    private func applyCheckedState(animated: Bool) {
        guard animated else {
            fill.removeAllAnimations()
            fill.transform = isChecked ? .identity : CheckboxView.collapsed
            fill.alpha = isChecked ? 1 : 0
            return
        }
        if isChecked {
            // Start from nothing, then spring the scale up past 1 and back.
            fill.removeAllAnimations()
            fill.transform = CheckboxView.collapsed
            fill.alpha = 1
            UIView.animate(withDuration: CheckboxView.fillSpringDuration,
                           delay: 0,
                           usingSpringWithDamping: CheckboxView.fillSpringDamping,
                           initialSpringVelocity: 0.4, animations: {
                self.fill.transform = .identity
            })
        } else {
            UIView.animate(withDuration: CheckboxView.fillCollapseDuration,
                           delay: 0, options: .curveEaseIn, animations: {
                self.fill.transform = CheckboxView.collapsed
                self.fill.alpha = 0
            })
        }
    }

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let r = (CheckboxView.ringDiameter - CheckboxView.ringLineWidth) / 2
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        let ring = Path.roundedRect(CGRect(x: c.x - r, y: c.y - r,
                                           width: 2 * r, height: 2 * r),
                                    cornerRadius: r)
        canvas.stroke(ring, color: priority.color.resolvedCGColor(with: traitCollection),
                      lineWidth: CheckboxView.ringLineWidth)
    }
}

// MARK: - Row

public final class TaskRow: UIControl {
    public static let height: CGFloat = 52
    static let checkboxLeading: CGFloat = 8
    static let titleLeading: CGFloat = 54
    static let trailingInset: CGFloat = 16
    static let dotSize: CGFloat = 8
    static let highlightFadeDuration: Double = 0.3
    /// Row alpha once completed (docs task spec).
    static let completedAlpha: CGFloat = 0.85

    public let task: TaskItem
    public let checkbox: CheckboxView
    public let titleLabel = UILabel()
    let dot = UIView()
    let chevron = UILabel()
    let separator = UIView()

    /// Checkbox tapped (complete / reopen).
    public var onToggle: ((TaskRow) -> Void)?
    /// Row body tapped (push the detail screen).
    public var onTap: ((TaskRow) -> Void)?

    public var showsSeparator: Bool {
        get { !separator.isHidden }
        set { separator.isHidden = !newValue }
    }

    public init(task: TaskItem) {
        self.task = task
        checkbox = CheckboxView(priority: task.priority, isChecked: task.isDone)
        super.init(frame: CGRect(x: 0, y: 0, width: 358, height: TaskRow.height))
        backgroundColor = .secondarySystemGroupedBackground

        checkbox.addTarget(for: .touchUpInside) { [weak self] _, _ in
            guard let self else { return }
            self.onToggle?(self)
        }
        addSubview(checkbox)

        titleLabel.text = task.title
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label
        addSubview(titleLabel)

        dot.backgroundColor = task.priority.color
        dot.layer.cornerRadius = TaskRow.dotSize / 2
        dot.isUserInteractionEnabled = false
        dot.bounds.size = CGSize(width: TaskRow.dotSize, height: TaskRow.dotSize)
        addSubview(dot)

        chevron.text = "\u{203A}" // ›
        chevron.font = .systemFont(ofSize: 17, weight: .semibold)
        chevron.textColor = .systemGray2
        addSubview(chevron)

        separator.backgroundColor = .separator
        separator.isUserInteractionEnabled = false
        addSubview(separator)

        addTarget(for: .touchUpInside) { [weak self] _, _ in
            guard let self else { return }
            self.onTap?(self)
        }

        applyCompletionStyle(animated: false)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height
        checkbox.frame = CGRect(x: TaskRow.checkboxLeading, y: 0,
                                width: CheckboxView.hitSize.width, height: h)
        let c = chevron.intrinsicContentSize
        chevron.frame = CGRect(x: bounds.width - TaskRow.trailingInset - c.width,
                               y: (h - c.height) / 2,
                               width: c.width, height: c.height)
        let dotX = chevron.frame.minX - 12 - TaskRow.dotSize
        dot.center = CGPoint(x: dotX + TaskRow.dotSize / 2, y: h / 2)
        let t = titleLabel.intrinsicContentSize
        let available = dotX - 12 - TaskRow.titleLeading
        titleLabel.frame = CGRect(x: TaskRow.titleLeading, y: (h - t.height) / 2,
                                  width: min(t.width, max(available, 0)),
                                  height: t.height)
        separator.frame = CGRect(x: TaskRow.titleLeading, y: h - 0.5,
                                 width: bounds.width - TaskRow.titleLeading,
                                 height: 0.5)
    }

    /// Reflect `task.priority` (edited on the detail screen) in the ring and
    /// the trailing dot. The dot's backgroundColor is layer-driven, so a
    /// caller can wrap this in UIView.animate and get a color crossfade.
    public func applyPriority() {
        checkbox.priority = task.priority
        dot.backgroundColor = task.priority.color
    }

    /// Everything in front of the row's background. Completion dims these
    /// rather than the row itself: the row travels between sections OVER the
    /// other rows, and a translucent row would let them show through.
    var foreground: [UIView] { [checkbox, titleLabel, dot, chevron] }

    /// Reflect `task.isDone`: the title drops to secondaryLabel and the row
    /// content dims to 0.85. Alpha is layer-driven (animatable); the title
    /// color is drawn content, so it snaps — which reads fine underneath the
    /// 0.35s section move that always accompanies it.
    public func applyCompletionStyle(animated: Bool) {
        titleLabel.textColor = task.isDone ? .secondaryLabel : .label
        titleLabel.setNeedsDisplay()
        let target: CGFloat = task.isDone ? TaskRow.completedAlpha : 1
        let apply = { for v in self.foreground { v.alpha = target } }
        guard animated else { apply(); return }
        UIView.animate(withDuration: TasksRootViewController.sectionMoveDuration,
                       delay: 0, options: .curveEaseInOut, animations: apply)
    }

    // MARK: Highlight flash (APP_FEEL row feel)

    public override func stateDidChange() {
        super.stateDidChange()
        if isHighlighted {
            removeAllAnimations()
            backgroundColor = .systemGray4
        } else {
            UIView.animate(withDuration: TaskRow.highlightFadeDuration,
                           delay: 0, options: .curveLinear, animations: {
                self.backgroundColor = .secondarySystemGroupedBackground
            })
        }
    }
}

// MARK: - Section card

/// An inset-grouped card that clips its rows (so an inserted row can slide
/// in from behind the top edge) and shows a placeholder when it is empty.
public final class TaskSectionCard: UIView {
    public static let emptyHeight: CGFloat = 52
    let emptyLabel = UILabel()

    public init(emptyText: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: 358,
                                 height: TaskSectionCard.emptyHeight))
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 10
        clipsToBounds = true

        emptyLabel.text = emptyText
        emptyLabel.font = .systemFont(ofSize: 15)
        emptyLabel.textColor = .tertiaryLabel
        addSubview(emptyLabel)
    }

    public var isEmptyStateVisible: Bool {
        get { !emptyLabel.isHidden }
        set { emptyLabel.isHidden = !newValue }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let s = emptyLabel.intrinsicContentSize
        emptyLabel.frame = CGRect(x: TaskRow.titleLeading,
                                  y: (TaskSectionCard.emptyHeight - s.height) / 2,
                                  width: s.width, height: s.height)
    }
}

// MARK: - Floating pill button

/// The "+ New Task" capsule: tint background, white title, soft shadow, and
/// a press that dips the scale and darkens the fill. A filled iOS button
/// dims its FILL, not its title, so the title color is pinned for the
/// highlighted state; and the dim darkens the color rather than lowering the
/// view's alpha, which would make the list scroll visibly through the pill.
public final class PillButton: UIButton {
    static let pressDuration: Double = 0.12
    static let pressScale: CGFloat = 0.96
    static let pressShade: CGFloat = 0.82

    let fillColor: UIColor
    let pressedColor: UIColor

    public init(title: String, color: UIColor) {
        fillColor = color
        pressedColor = UIColor(dynamicProvider: { traits in
            let c = color.resolvedCGColor(with: traits)
            let k = PillButton.pressShade
            return UIColor(red: c.red * k, green: c.green * k,
                           blue: c.blue * k, alpha: c.alpha)
        })
        super.init(type: .custom)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        setTitleColor(.white, for: .highlighted)
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        backgroundColor = color
        layer.shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 3)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    public override func stateDidChange() {
        super.stateDidChange()
        let pressed = isHighlighted
        UIView.animate(withDuration: PillButton.pressDuration, delay: 0,
                       options: .curveEaseOut, animations: {
            self.transform = pressed
                ? CGAffineTransform(scaleX: PillButton.pressScale,
                                    y: PillButton.pressScale)
                : .identity
            self.backgroundColor = pressed ? self.pressedColor : self.fillColor
        })
    }
}
