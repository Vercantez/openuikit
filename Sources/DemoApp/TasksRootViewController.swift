// Tasks demo app — root list screen. Owner: demo app (M7.5 second app).
//
// "Tasks": a scrollable inset-grouped list with a TODAY section (open tasks),
// a COMPLETED section, and a MORE section holding the Statistics row, plus a
// floating "+ New Task" pill fixed over the scroll view.
//
// The interesting part is the section relayout. Every row/card/header frame
// is computed in one place (`relayout`) and assigned inside a single
// UIView.animate block, so completing a task animates as one coordinated
// move: the checkbox springs, the row travels from its Today slot to the top
// of Completed, and every row after it slides up to close the gap while both
// cards resize. Nothing jumps.
//
// Cards CLIP (that is what makes the rounded inset-grouped corners read, and
// it is what lets an inserted row slide in from behind the top edge), so a
// row crossing the gap between two cards would be clipped away mid-flight.
// It is therefore re-parented to the unclipped `contentView` for the
// duration of the move — keeping its absolute frame — and dropped back into
// the destination card by the animation's completion handler. That is the
// same trick UIKit uses when a table cell moves between sections: the cell
// floats above the section backgrounds while it travels.

import OpenUIKit

public final class TasksRootViewController: UIViewController {

    // MARK: Metrics

    static let margin: CGFloat = 16
    static let headerLeading: CGFloat = 16
    static let sectionGap: CGFloat = 24
    static let topInset: CGFloat = 12
    /// Room under the content for the floating pill.
    static let bottomInset: CGFloat = 104
    static let pillHeight: CGFloat = 50
    static let pillBottomGap: CGFloat = 24

    /// Section move: 0.35s, started after the checkbox spring has had a
    /// moment to read.
    public static let sectionMoveDuration: Double = 0.35
    static let sectionMoveDelay: Double = 0.18
    /// Insert: slide down + fade in, no delay (nothing precedes it).
    static let insertDuration: Double = 0.35

    // MARK: Views

    let scrollView = UIScrollView()
    let contentView = UIView()
    let todayHeader = makeSectionHeader("TODAY")
    let completedHeader = makeSectionHeader("COMPLETED")
    let moreHeader = makeSectionHeader("MORE")
    let todayCard = TaskSectionCard(emptyText: "Nothing left to do.")
    let completedCard = TaskSectionCard(emptyText: "Nothing finished yet.")
    var moreCard: GroupCard!
    var addButton: PillButton!

    // MARK: State

    var openRows: [TaskRow] = []
    var doneRows: [TaskRow] = []
    var nextPoolIndex = 0

    public override init() { super.init() }

    var cardWidth: CGFloat { view.bounds.width - 2 * TasksRootViewController.margin }

    // MARK: Load

    public override func viewDidLoad() {
        title = "Tasks"
        view.backgroundColor = .systemGroupedBackground

        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.alwaysBounceVertical = true
        scrollView.clipsToBounds = true
        view.addSubview(scrollView)

        contentView.backgroundColor = nil
        scrollView.addSubview(contentView)

        for header in [todayHeader, completedHeader, moreHeader] {
            contentView.addSubview(header)
        }
        contentView.addSubview(todayCard)
        contentView.addSubview(completedCard)

        let statsRow = SettingsRow(icon: .cellular, iconColor: .systemIndigo,
                                   title: "Statistics", accessory: .chevron)
        statsRow.onTap = { [weak self] _ in self?.pushStatistics() }
        moreCard = GroupCard(rows: [statsRow])
        contentView.addSubview(moreCard)

        let seed = TasksData.seed()
        for task in seed.open {
            let row = makeRow(task)
            todayCard.addSubview(row)
            openRows.append(row)
        }
        for task in seed.done {
            let row = makeRow(task)
            completedCard.addSubview(row)
            doneRows.append(row)
        }

        addButton = PillButton(title: "+  New Task", color: .systemBlue)
        addButton.frame = CGRect(
            x: TasksRootViewController.margin,
            y: view.bounds.height - TasksRootViewController.pillBottomGap
                - TasksRootViewController.pillHeight,
            width: cardWidth, height: TasksRootViewController.pillHeight)
        addButton.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        addButton.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?.addTask()
        }
        view.addSubview(addButton)

        relayout(animated: false)
    }

    func makeRow(_ task: TaskItem) -> TaskRow {
        let row = TaskRow(task: task)
        row.onToggle = { [weak self] r in self?.toggleCompletion(of: r) }
        row.onTap = { [weak self] r in self?.pushDetail(for: r) }
        return row
    }

    // MARK: Layout

    /// Assign every header / card / row frame. When `animated`, the frame
    /// assignments run inside one UIView.animate block so the whole section
    /// shift is a single coordinated move; `floating` names a row that is
    /// currently parented to `contentView` and therefore wants its slot in
    /// contentView coordinates instead of card-local ones.
    func relayout(animated: Bool, delay: Double = 0,
                  floating: TaskRow? = nil,
                  completion: (() -> Void)? = nil) {
        let m = TasksRootViewController.margin
        let w = cardWidth
        var y = TasksRootViewController.topInset

        func headerFrame(_ label: UILabel) -> CGRect {
            let s = label.intrinsicContentSize
            let f = CGRect(x: m + TasksRootViewController.headerLeading, y: y,
                           width: s.width, height: s.height)
            y = f.maxY + 6
            return f
        }

        let todayHeaderFrame = headerFrame(todayHeader)
        let todayCardFrame = CGRect(x: m, y: y, width: w,
                                    height: cardHeight(openRows.count))
        y = todayCardFrame.maxY + TasksRootViewController.sectionGap

        let completedHeaderFrame = headerFrame(completedHeader)
        let completedCardFrame = CGRect(x: m, y: y, width: w,
                                        height: cardHeight(doneRows.count))
        y = completedCardFrame.maxY + TasksRootViewController.sectionGap

        let moreHeaderFrame = headerFrame(moreHeader)
        let moreCardFrame = CGRect(x: m, y: y, width: w,
                                   height: moreCard.bounds.height)
        y = moreCardFrame.maxY

        // Instant work: nothing here is a visual move, and doing it inside
        // the animation block would record pointless animations.
        let contentHeight = y + TasksRootViewController.bottomInset
        contentView.frame = CGRect(x: 0, y: 0, width: view.bounds.width,
                                   height: contentHeight)
        scrollView.contentSize = CGSize(width: view.bounds.width,
                                        height: contentHeight)
        todayCard.isEmptyStateVisible = openRows.isEmpty
        completedCard.isEmptyStateVisible = doneRows.isEmpty
        for (i, row) in openRows.enumerated() {
            row.showsSeparator = i < openRows.count - 1
        }
        for (i, row) in doneRows.enumerated() {
            row.showsSeparator = i < doneRows.count - 1
        }

        let place = {
            self.todayHeader.frame = todayHeaderFrame
            self.todayCard.frame = todayCardFrame
            self.completedHeader.frame = completedHeaderFrame
            self.completedCard.frame = completedCardFrame
            self.moreHeader.frame = moreHeaderFrame
            self.moreCard.frame = moreCardFrame
            self.placeRows(self.openRows, in: todayCardFrame, floating: floating)
            self.placeRows(self.doneRows, in: completedCardFrame, floating: floating)
        }

        guard animated else {
            place()
            completion?()
            return
        }
        UIView.animate(withDuration: TasksRootViewController.sectionMoveDuration,
                       delay: delay, options: .curveEaseInOut,
                       animations: place,
                       completion: { _ in completion?() })
    }

    func cardHeight(_ count: Int) -> CGFloat {
        count == 0 ? TaskSectionCard.emptyHeight
                   : CGFloat(count) * TaskRow.height
    }

    /// Slot every row of a section. A floating row is parented to
    /// `contentView`, so its slot is offset by the card's own origin.
    func placeRows(_ rows: [TaskRow], in cardFrame: CGRect, floating: TaskRow?) {
        for (i, row) in rows.enumerated() {
            let local = CGRect(x: 0, y: CGFloat(i) * TaskRow.height,
                               width: cardFrame.width, height: TaskRow.height)
            row.frame = row === floating
                ? local.offsetBy(dx: cardFrame.minX, dy: cardFrame.minY)
                : local
        }
    }

    // MARK: Completing / reopening

    /// Flip a task's completion: spring the checkbox, restyle the row, and
    /// move it between the two sections with everything else animating out
    /// of its way.
    public func toggleCompletion(of row: TaskRow) {
        let nowDone = !row.task.isDone
        row.task.isDone = nowDone
        row.checkbox.setChecked(nowDone, animated: true)
        row.applyCompletionStyle(animated: true)

        if nowDone {
            openRows.removeAll { $0 === row }
            doneRows.insert(row, at: 0)
        } else {
            doneRows.removeAll { $0 === row }
            openRows.insert(row, at: 0)
        }

        floatRow(row)
        relayout(animated: true,
                 delay: TasksRootViewController.sectionMoveDelay,
                 floating: row) { [weak self] in
            self?.land(row)
        }
    }

    /// Re-parent `row` to the unclipped contentView, preserving its position
    /// on screen, so it is visible while it crosses between cards.
    func floatRow(_ row: TaskRow) {
        guard let parent = row.superview, parent !== contentView else { return }
        let origin = parent.convert(row.frame.origin, to: contentView)
        row.removeFromSuperview()
        contentView.addSubview(row)
        row.frame = CGRect(origin: origin, size: row.bounds.size)
    }

    /// Put a finished floating row back into its section card.
    ///
    /// The finished move animation must go first. Its recorded from/to
    /// positions are in contentView coordinates, and a completed animation
    /// still overrides the model at composite time — so re-parenting without
    /// dropping it would place the row at contentView coordinates inside the
    /// card, i.e. far below the card's bounds, where the card's clipping
    /// swallows it. (CA removes a finished animation from the layer at the
    /// same point; nothing here does that for us.)
    func land(_ row: TaskRow) {
        guard row.superview === contentView else { return }
        row.removeAllAnimations()
        let card: UIView = doneRows.contains(where: { $0 === row })
            ? completedCard : todayCard
        let origin = contentView.convert(row.frame.origin, to: card)
        row.removeFromSuperview()
        card.addSubview(row)
        row.frame = CGRect(origin: origin, size: row.bounds.size)
        relayout(animated: false)   // snap to the exact slot
    }

    // MARK: Inserting

    /// "+ New Task": take the next canned task, drop it in at the top of
    /// TODAY sliding down from behind the card's top edge while it fades in,
    /// and push everything below it down in the same beat.
    public func addTask() {
        let task = TasksData.newTask(at: nextPoolIndex)
        nextPoolIndex += 1
        let row = makeRow(task)
        todayCard.addSubview(row)
        openRows.insert(row, at: 0)

        // Start one row-height above its slot, transparent. The card clips,
        // so it emerges from under the top edge.
        row.frame = CGRect(x: 0, y: -TaskRow.height,
                           width: cardWidth, height: TaskRow.height)
        row.alpha = 0
        relayout(animated: true)
        UIView.animate(withDuration: TasksRootViewController.insertDuration,
                       delay: 0, options: .curveEaseOut, animations: {
            row.alpha = 1
        })
    }

    // MARK: Navigation

    func pushDetail(for row: TaskRow) {
        let detail = TasksDetailViewController(task: row.task)
        detail.onPriorityChanged = { [weak row] in
            guard let row else { return }
            UIView.animate(withDuration: 0.25, delay: 0,
                           options: .curveEaseInOut, animations: {
                row.applyPriority()
            })
        }
        detail.onCompletionToggled = { [weak self, weak row] in
            guard let self, let row else { return }
            self.toggleCompletion(of: row)
        }
        navigationController?.pushViewController(detail, animated: true)
    }

    func pushStatistics() {
        let all = openRows.map { $0.task } + doneRows.map { $0.task }
        navigationController?.pushViewController(
            TasksStatsViewController(tasks: all), animated: true)
    }
}
