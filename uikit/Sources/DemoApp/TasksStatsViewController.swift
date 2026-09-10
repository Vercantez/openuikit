// Tasks demo app — statistics screen. Owner: demo app (M7.5 second app).
//
// One bar per priority showing the completed fraction, plus counts. The bars
// grow from zero on viewDidAppear (i.e. once the push transition has landed)
// with a 0.15s stagger between them.
//
// Bar construction: the TRACK is a real UIProgressView left at progress 0,
// which is exactly its empty pill. The FILL is a plain view with a
// background color and a 2pt corner radius whose frame width animates.
// UIProgressView draws its own fill in drawContent, and drawContent is
// rasterized against a view's MODEL bounds before the layer's presentation
// values are applied — so animating a progress view's bounds would slide a
// full-width fill around instead of growing it. A background-color layer, by
// contrast, is painted from the presentation bounds every frame, which is
// what makes the growth read correctly at 60fps.

import OpenUIKit

public final class TasksStatsViewController: UIViewController {
    static let margin: CGFloat = 16
    static let blockHeight: CGFloat = 62
    static let barHeight: CGFloat = 4
    static let barInset: CGFloat = 16

    /// Bar growth and the stagger between bars.
    static let growDuration: Double = 0.6
    static let growStagger: Double = 0.15

    struct Bar {
        let fill: UIView
        let target: CGRect
        let start: CGRect
    }

    let tasks: [TaskItem]
    var bars: [Bar] = []
    var didAnimateBars = false

    public init(tasks: [TaskItem]) {
        self.tasks = tasks
        super.init()
        title = "Statistics"
    }
    public required init?(coder: NSCoder) { fatalError() }

    func counts(for priority: TaskPriority) -> (done: Int, total: Int) {
        var done = 0, total = 0
        for t in tasks where t.priority == priority {
            total += 1
            if t.isDone { done += 1 }
        }
        return (done, total)
    }

    public override func viewDidLoad() {
        view.backgroundColor = .systemGroupedBackground
        let m = TasksStatsViewController.margin
        let w = view.bounds.width - 2 * m
        var y: CGFloat = 20

        // Summary.
        let doneCount = tasks.filter { $0.isDone }.count
        let summary = UILabel()
        summary.text = "\(doneCount) of \(tasks.count) complete"
        summary.font = .systemFont(ofSize: 28, weight: .semibold)
        summary.textColor = .label
        let sSize = summary.intrinsicContentSize
        summary.frame = CGRect(x: m, y: y, width: w, height: sSize.height)
        view.addSubview(summary)
        y = summary.frame.maxY + 6

        let sub = UILabel()
        sub.text = tasks.count == doneCount
            ? "Everything is finished."
            : "\(tasks.count - doneCount) still open across three priorities."
        sub.font = .systemFont(ofSize: 15)
        sub.textColor = .secondaryLabel
        sub.frame = CGRect(x: m, y: y, width: w,
                           height: sub.intrinsicContentSize.height)
        view.addSubview(sub)
        y = sub.frame.maxY + 28

        let header = makeSectionHeader("BY PRIORITY")
        let hs = header.intrinsicContentSize
        header.frame = CGRect(x: m, y: y, width: hs.width, height: hs.height)
        view.addSubview(header)
        y = header.frame.maxY + 8

        // One card holding the three priority blocks.
        let card = UIView(frame: CGRect(
            x: m, y: y, width: w,
            height: CGFloat(TaskPriority.allCases.count)
                * TasksStatsViewController.blockHeight + 8))
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10
        view.addSubview(card)

        let inset = TasksStatsViewController.barInset
        let barWidth = w - 2 * inset
        for (i, priority) in TaskPriority.allCases.enumerated() {
            let blockY = 4 + CGFloat(i) * TasksStatsViewController.blockHeight
            let (done, total) = counts(for: priority)

            let name = UILabel()
            name.text = priority.longTitle
            name.font = .systemFont(ofSize: 17)
            name.textColor = .label
            let nameSize = name.intrinsicContentSize
            name.frame = CGRect(x: inset, y: blockY + 12,
                                width: nameSize.width, height: nameSize.height)
            card.addSubview(name)

            let count = UILabel()
            count.text = "\(done) / \(total)"
            count.font = .systemFont(ofSize: 15)
            count.textColor = .secondaryLabel
            let cSize = count.intrinsicContentSize
            count.frame = CGRect(x: w - inset - cSize.width, y: blockY + 14,
                                 width: cSize.width, height: cSize.height)
            card.addSubview(count)

            let barY = blockY + 42
            let track = UIProgressView(frame: CGRect(
                x: inset, y: barY, width: barWidth,
                height: TasksStatsViewController.barHeight))
            track.progress = 0
            card.addSubview(track)

            let fraction = total == 0 ? 0 : CGFloat(done) / CGFloat(total)
            let fill = UIView()
            fill.backgroundColor = priority.color
            fill.layer.cornerRadius = TasksStatsViewController.barHeight / 2
            fill.isUserInteractionEnabled = false
            let start = CGRect(x: inset, y: barY, width: 0,
                               height: TasksStatsViewController.barHeight)
            fill.frame = start
            card.addSubview(fill)
            bars.append(Bar(fill: fill,
                            target: CGRect(x: inset, y: barY,
                                           width: barWidth * fraction,
                                           height: TasksStatsViewController.barHeight),
                            start: start))
        }

        let note = makeFootnote(
            "Bars show the share of each priority that is already completed. "
            + "They fill in on appearance, one after another.")
        let noteSize = note.sizeThatFits(CGSize(width: w - 32, height: 200))
        note.frame = CGRect(x: m + 16, y: card.frame.maxY + 8,
                            width: w - 32, height: noteSize.height)
        view.addSubview(note)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didAnimateBars else { return }
        didAnimateBars = true
        for (i, bar) in bars.enumerated() {
            bar.fill.frame = bar.start
            UIView.animate(withDuration: TasksStatsViewController.growDuration,
                           delay: Double(i) * TasksStatsViewController.growStagger,
                           options: .curveEaseOut, animations: {
                bar.fill.frame = bar.target
            })
        }
    }
}
