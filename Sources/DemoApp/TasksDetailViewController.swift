// Tasks demo app — task detail screen. Owner: demo app (M7.5 second app).
//
// Pushed by tapping a row's body (the checkbox swallows its own taps). Shows
// the task's large title, a three-way priority picker, the notes paragraph,
// and a button that flips completion and pops.
//
// The picker's selection change animates: the two buttons involved crossfade
// their fill (clear <-> the priority color) and their two stacked title
// labels (tinted / white) crossfade with it. Fill and alpha are layer-driven
// properties, so a single UIView.animate block covers the whole switch —
// UILabel.textColor is drawn content and would have snapped.
//
// Edits are made on the shared TaskItem and reported to the root list
// through closures, so the list is already correct — and animating — while
// the pop transition is still running.

import OpenUIKit

// MARK: - Priority picker button

public final class PriorityOptionButton: UIControl {
    public static let height: CGFloat = 44
    static let selectionDuration: Double = 0.22

    public let priority: TaskPriority
    let tintTitle = UILabel()
    let whiteTitle = UILabel()

    public private(set) var isOn: Bool

    public init(priority: TaskPriority, isOn: Bool) {
        self.priority = priority
        self.isOn = isOn
        super.init(frame: CGRect(x: 0, y: 0, width: 110,
                                 height: PriorityOptionButton.height))
        isOpaque = false
        layer.cornerRadius = 10
        layer.borderWidth = 1.5

        for (label, color) in [(tintTitle, priority.color),
                               (whiteTitle, UIColor.white)] {
            label.text = priority.title
            label.font = .systemFont(ofSize: 16, weight: .semibold)
            label.textColor = color
            addSubview(label)
        }
        applySelection(animated: false)
    }

    public func setOn(_ on: Bool, animated: Bool) {
        guard on != isOn else { return }
        isOn = on
        applySelection(animated: animated)
    }

    private func applySelection(animated: Bool) {
        // Deselected is the priority color at alpha 0, not `.clear`: the
        // fill lerps componentwise, and lerping toward transparent BLACK
        // would drag the midpoint of the crossfade through mud.
        let empty = priority.color.withAlphaComponent(0)
        let apply = {
            self.backgroundColor = self.isOn ? self.priority.color : empty
            self.whiteTitle.alpha = self.isOn ? 1 : 0
            self.tintTitle.alpha = self.isOn ? 0 : 1
        }
        guard animated else { apply(); return }
        UIView.animate(withDuration: PriorityOptionButton.selectionDuration,
                       delay: 0, options: .curveEaseInOut, animations: apply)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // Resolve the outline against the live traits (dark mode gives the
        // system colors different components).
        layer.borderColor = priority.color.resolvedCGColor(with: traitCollection)
        for label in [tintTitle, whiteTitle] {
            let s = label.intrinsicContentSize
            label.frame = CGRect(x: (bounds.width - s.width) / 2,
                                 y: (bounds.height - s.height) / 2,
                                 width: s.width, height: s.height)
        }
    }
}

// MARK: - Screen

public final class TasksDetailViewController: UIViewController {
    static let margin: CGFloat = 16
    static let actionHeight: CGFloat = 50
    static let actionBottomGap: CGFloat = 24

    public let task: TaskItem

    /// The task's priority was changed here.
    public var onPriorityChanged: (() -> Void)?
    /// The completion button was tapped (the root owns the state flip and
    /// the animated section move).
    public var onCompletionToggled: (() -> Void)?

    let titleLabel = UILabel()
    let statusLabel = UILabel()
    let notesLabel = UILabel()
    var optionButtons: [PriorityOptionButton] = []

    public init(task: TaskItem) {
        self.task = task
        super.init()
        title = "Task"
    }

    public override func viewDidLoad() {
        view.backgroundColor = .systemGroupedBackground
        let m = TasksDetailViewController.margin
        let w = view.bounds.width - 2 * m
        var y: CGFloat = 20

        titleLabel.text = task.title
        titleLabel.font = .systemFont(ofSize: 28, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        let ts = titleLabel.sizeThatFits(CGSize(width: w, height: 200))
        titleLabel.frame = CGRect(x: m, y: y, width: w, height: ts.height)
        view.addSubview(titleLabel)
        y = titleLabel.frame.maxY + 8

        statusLabel.font = .systemFont(ofSize: 15)
        statusLabel.textColor = .secondaryLabel
        statusLabel.text = statusText()
        let ss = statusLabel.intrinsicContentSize
        statusLabel.frame = CGRect(x: m, y: y, width: w, height: ss.height)
        view.addSubview(statusLabel)
        y = statusLabel.frame.maxY + 30

        y = addHeader("PRIORITY", at: y, margin: m)

        let gap: CGFloat = 10
        let bw = (w - 2 * gap) / 3
        for (i, priority) in TaskPriority.allCases.enumerated() {
            let b = PriorityOptionButton(priority: priority,
                                         isOn: priority == task.priority)
            b.frame = CGRect(x: m + CGFloat(i) * (bw + gap), y: y,
                             width: bw, height: PriorityOptionButton.height)
            b.addTarget(for: .touchUpInside) { [weak self] control, _ in
                guard let b = control as? PriorityOptionButton else { return }
                self?.select(b.priority)
            }
            view.addSubview(b)
            optionButtons.append(b)
        }
        y += PriorityOptionButton.height + 30

        y = addHeader("NOTES", at: y, margin: m)

        notesLabel.text = task.notes
        notesLabel.font = .systemFont(ofSize: 15)
        notesLabel.textColor = .label
        notesLabel.numberOfLines = 0
        let ns = notesLabel.sizeThatFits(CGSize(width: w - 32, height: 400))
        let card = UIView(frame: CGRect(x: m, y: y, width: w,
                                        height: ns.height + 32))
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10
        view.addSubview(card)
        notesLabel.frame = CGRect(x: 16, y: 16, width: w - 32, height: ns.height)
        card.addSubview(notesLabel)

        let action = PillButton(title: actionTitle(),
                                color: task.isDone ? .systemGray : .systemGreen)
        action.frame = CGRect(
            x: m,
            y: view.bounds.height - TasksDetailViewController.actionBottomGap
                - TasksDetailViewController.actionHeight,
            width: w, height: TasksDetailViewController.actionHeight)
        action.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        action.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?.toggleCompletionAndPop()
        }
        view.addSubview(action)
    }

    func addHeader(_ text: String, at y: CGFloat, margin m: CGFloat) -> CGFloat {
        let header = makeSectionHeader(text)
        let hs = header.intrinsicContentSize
        header.frame = CGRect(x: m, y: y, width: hs.width, height: hs.height)
        view.addSubview(header)
        return header.frame.maxY + 8
    }

    func statusText() -> String {
        (task.isDone ? "Completed" : "Open")
            + "  \u{2022}  \(task.priority.longTitle) priority"
    }

    func actionTitle() -> String { task.isDone ? "Reopen" : "Mark Completed" }

    // MARK: Actions

    func select(_ priority: TaskPriority) {
        guard priority != task.priority else { return }
        task.priority = priority
        for b in optionButtons { b.setOn(b.priority == priority, animated: true) }
        statusLabel.text = statusText()
        statusLabel.setNeedsDisplay()
        onPriorityChanged?()
    }

    func toggleCompletionAndPop() {
        // The root flips `task.isDone` and starts the section move; the pop
        // then reveals a list that is already animating.
        onCompletionToggled?()
        navigationController?.popViewController(animated: true)
    }
}
