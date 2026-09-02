// Tasks demo app — cells + shared components. Owner: demo app.
//
// The Tasks list is a real UITableView (insetGrouped) since M10, so the
// pieces here are the ones the table cannot provide itself:
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
//   - TaskCell: a UITableViewCell dequeued from the table's reuse pool. Its
//     contentView carries the checkbox and the priority dot; the title is
//     the cell's own `textLabel` and the chevron is the cell's measured
//     `.disclosureIndicator` accessory. Row feel comes from the cell itself
//     (UITableViewCell's measured #DCDCDC selection flash + 0.3s fade),
//     which is the table's version of docs/APP_FEEL.md's row highlight.
//     Touches that land on the checkbox never reach the cell, so the row's
//     tap (push detail) and the checkbox's tap (complete/reopen) do not
//     fight.
//   - IconCell / PlaceholderCell: the Settings-style "Statistics" row and
//     the empty-section placeholder.
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

/// The tappable checkbox: a generous full-row-height hit area with the 24pt
/// ring drawn centered in it.
public final class CheckboxView: UIControl {
    static let hitWidth: CGFloat = 40
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
        super.init(frame: CGRect(x: 0, y: 0, width: CheckboxView.hitWidth,
                                 height: UITableViewCell.defaultRowHeight))
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

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

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

    /// Settle the fill into its resting state.
    ///
    /// The "off" rest state HIDES the fill rather than leaving it scaled to
    /// 1%: a non-translation transform anywhere in a subtree makes that
    /// whole subtree ineligible for the layer composite cache, so a shrunken
    /// fill would force its entire table cell to re-rasterize on every
    /// scrolled frame (measured: 27 → 8 ms per frame across a visible
    /// screenful of rows). Hidden subtrees are skipped outright.
    private func settle() {
        fill.removeAllAnimations()
        fill.transform = .identity
        fill.isHidden = !isChecked
        fill.alpha = isChecked ? 1 : 0
    }

    private func applyCheckedState(animated: Bool) {
        guard animated else {
            settle()
            return
        }
        if isChecked {
            // Start from nothing, then spring the scale up past 1 and back.
            fill.removeAllAnimations()
            fill.isHidden = false
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
            }, completion: { [weak self] _ in
                guard let self, !self.isChecked else { return }
                self.settle()
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

// MARK: - Task cell

public final class TaskCell: UITableViewCell {
    public static let identifier = "TaskCell"

    static let checkboxLeading: CGFloat = 8
    static let titleLeading: CGFloat = 54
    static let dotSize: CGFloat = 8
    /// Gap between the priority dot and the accessory's content edge.
    static let dotAccessoryGap: CGFloat = 10
    /// Row content alpha once completed (docs task spec).
    static let completedAlpha: CGFloat = 0.85

    public let checkbox = CheckboxView(priority: .low, isChecked: false)
    let dot = UIView()

    public private(set) var task: TaskItem?

    /// Checkbox tapped (complete / reopen). The data source re-installs this
    /// on every configure, because cells outlive the row they display.
    public var onToggle: ((TaskCell) -> Void)?

    public override init(style: CellStyle = .default,
                         reuseIdentifier: String? = nil) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        checkbox.addTarget(for: .touchUpInside) { [weak self] _, _ in
            guard let self else { return }
            self.onToggle?(self)
        }
        contentView.addSubview(checkbox)

        dot.layer.cornerRadius = TaskCell.dotSize / 2
        dot.isUserInteractionEnabled = false
        dot.bounds.size = CGSize(width: TaskCell.dotSize, height: TaskCell.dotSize)
        contentView.addSubview(dot)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    /// Bind `task`. Called from `cellForRowAt` on both fresh and recycled
    /// cells, so every piece of visible state is assigned unconditionally.
    public func configure(_ task: TaskItem) {
        self.task = task
        textLabel.text = task.title
        checkbox.priority = task.priority
        checkbox.setChecked(task.isDone, animated: false)
        dot.backgroundColor = task.priority.color
        applyCompletionStyle(animated: false)
        setNeedsLayout()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
        task = nil
        removeAllAnimations()
        backgroundColor = nil
        for v in foreground {
            v.removeAllAnimations()
            v.alpha = 1
        }
    }

    /// Reflect `task.priority` (edited on the detail screen) in the ring and
    /// the trailing dot. The dot's backgroundColor is layer-driven, so a
    /// caller can wrap this in UIView.animate and get a color crossfade.
    public func applyPriority() {
        guard let task else { return }
        checkbox.priority = task.priority
        dot.backgroundColor = task.priority.color
    }

    /// Everything in front of the cell's background. Completion dims these
    /// rather than the cell itself: the cell travels between sections OVER
    /// the other rows, and a translucent cell would let them show through.
    var foreground: [UIView] { [checkbox, textLabel, dot] }

    /// Reflect `task.isDone`: the title drops to secondaryLabel and the row
    /// content dims. Alpha is layer-driven (animatable); the title color is
    /// drawn content, so it snaps — which reads fine underneath the section
    /// move that always accompanies it.
    public func applyCompletionStyle(animated: Bool) {
        let done = task?.isDone ?? false
        textLabel.textColor = done ? .secondaryLabel : .label
        textLabel.setNeedsDisplay()
        let target: CGFloat = done ? TaskCell.completedAlpha : 1
        let apply = { for v in self.foreground { v.alpha = target } }
        guard animated else { apply(); return }
        UIView.animate(withDuration: TasksRootViewController.sectionMoveDuration,
                       delay: 0, options: .curveEaseInOut, animations: apply)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height
        checkbox.frame = CGRect(x: TaskCell.checkboxLeading, y: 0,
                                width: CheckboxView.hitWidth, height: h)
        // super sized contentView to the width left by the accessory.
        let dotX = contentView.bounds.width - TaskCell.dotAccessoryGap
            - TaskCell.dotSize
        dot.center = CGPoint(x: dotX + TaskCell.dotSize / 2, y: h / 2)
        // The measured cell layout puts textLabel at x = 16; the checkbox
        // occupies that column here, so the title starts after it.
        let t = textLabel.intrinsicContentSize
        let available = dotX - 12 - TaskCell.titleLeading
        textLabel.frame = CGRect(x: TaskCell.titleLeading,
                                 y: textLabel.frame.minY,
                                 width: min(t.width, max(available, 0)),
                                 height: t.height)
    }
}

// MARK: - Supporting cells

/// A Settings-style row: 29pt icon tile, title, disclosure chevron.
public final class IconCell: UITableViewCell {
    public static let identifier = "IconCell"
    static let iconLeading: CGFloat = 15
    static let titleLeading: CGFloat = 58

    var tile: IconTile?

    public override init(style: CellStyle = .default,
                         reuseIdentifier: String? = nil) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

    public func configure(icon: IconGlyph, color: UIColor, title: String) {
        tile?.removeFromSuperview()
        let t = IconTile(glyph: icon, color: color)
        contentView.addSubview(t)
        tile = t
        textLabel.text = title
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if let tile {
            let s = IconTile.tileSize
            tile.frame = CGRect(x: IconCell.iconLeading,
                                y: ((bounds.height - s.height) / 2).rounded(),
                                width: s.width, height: s.height)
        }
        let t = textLabel.intrinsicContentSize
        textLabel.frame = CGRect(x: IconCell.titleLeading,
                                 y: textLabel.frame.minY,
                                 width: min(t.width, bounds.width),
                                 height: t.height)
    }
}

/// The "nothing here yet" row a section shows instead of disappearing.
public final class PlaceholderCell: UITableViewCell {
    public static let identifier = "PlaceholderCell"

    public override init(style: CellStyle = .default,
                         reuseIdentifier: String? = nil) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        textLabel.font = .systemFont(ofSize: 15)
        textLabel.textColor = .tertiaryLabel
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }
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
        super.init(frame: .zero)
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

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError() }

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
