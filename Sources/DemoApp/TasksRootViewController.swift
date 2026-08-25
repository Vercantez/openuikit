// Tasks demo app — root list screen. Owner: demo app.
//
// "Tasks": an inset-grouped UITableView with a TODAY section (open tasks), a
// COMPLETED section and a MORE section holding the Statistics row, plus a
// floating "+ New Task" pill fixed over the table.
//
// M10 rewrote this screen from hand-placed rows inside a UIScrollView onto a
// real UITableView: three sections driven by UITableViewDataSource, cells
// dequeued from the table's reuse pool (only the visible rows exist), the
// measured inset-grouped chrome (26 pt cards, header typography, separator
// insets and the #DCDCDC selection flash) instead of hand-drawn cards.
//
// The feel it had to keep is the section relayout. Completing a task must
// read as ONE coordinated move: the checkbox springs, the row travels from
// its Today slot to the top of Completed, every row after it slides up to
// close the gap and both cards resize — nothing jumps, and the checkbox
// spring that started on touch-up keeps running while its row is in flight.
// `UITableView.performUpdates(withDuration:identity:updates:)` does exactly
// that: rows are matched across the update by identity (here the TaskItem
// itself), so the moving row keeps its cell — animations and all — while the
// table re-tiles around it. A plain `reloadData` would recycle that cell and
// kill the spring mid-pop.

import OpenUIKit

public final class TasksRootViewController: UIViewController,
                                            UITableViewDataSource,
                                            UITableViewDelegate,
                                            BottomInsetAdjustable {

    // MARK: Metrics

    static let margin: CGFloat = 16
    /// Room under the content for the floating pill.
    static let bottomInset: CGFloat = 96
    static let pillHeight: CGFloat = 50
    static let pillBottomGap: CGFloat = 24

    /// Section move: 0.35s, started after the checkbox spring has had a
    /// moment to read.
    public static let sectionMoveDuration: Double = 0.35
    static let sectionMoveDelay: Double = 0.18
    /// Insert: the new row fades in while the rest slides down.
    static let insertDuration: Double = 0.35

    enum Section: Int, CaseIterable {
        case today = 0, completed, more
    }

    // MARK: Views

    public let tableView = UITableView(style: .insetGrouped)
    var addButton: PillButton!

    // MARK: State

    var openTasks: [TaskItem] = []
    var doneTasks: [TaskItem] = []
    var nextPoolIndex = 0

    /// Extra bottom inset for chrome the controller does not own (the
    /// showcase app's floating tab bar). Set before the view loads.
    public var extraBottomInset: CGFloat = 0

    public override init() { super.init() }

    // MARK: Load

    public override func viewDidLoad() {
        title = "Tasks"
        view.backgroundColor = .systemGroupedBackground

        let seed = TasksData.seed()
        openTasks = seed.open
        doneTasks = seed.done

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Device metrics: a real UIWindow measures a 16 pt side inset (the
        // 8 pt default is the offscreen-Catalyst oracle reading).
        tableView.insetGroupedSideInset = TasksRootViewController.margin
        tableView.contentInset.bottom = TasksRootViewController.bottomInset
            + extraBottomInset
        tableView.register(TaskCell.self,
                           forCellReuseIdentifier: TaskCell.identifier)
        tableView.register(IconCell.self,
                           forCellReuseIdentifier: IconCell.identifier)
        tableView.register(PlaceholderCell.self,
                           forCellReuseIdentifier: PlaceholderCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        addButton = PillButton(title: "+  New Task", color: .systemBlue)
        addButton.frame = CGRect(
            x: TasksRootViewController.margin,
            y: view.bounds.height - extraBottomInset
                - TasksRootViewController.pillBottomGap
                - TasksRootViewController.pillHeight,
            width: view.bounds.width - 2 * TasksRootViewController.margin,
            height: TasksRootViewController.pillHeight)
        addButton.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        addButton.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?.addTask()
        }
        view.addSubview(addButton)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // UIKit convention: a row stays selected while its detail is pushed
        // and fades back as the list reappears.
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }

    // MARK: Model access

    func tasks(in section: Section) -> [TaskItem] {
        switch section {
        case .today: return openTasks
        case .completed: return doneTasks
        case .more: return []
        }
    }

    /// Stable per-row identity used to match rows across an animated update.
    /// TaskItem is a reference type shared with the detail screen, so the
    /// object itself is the identity; the two synthetic rows get names.
    func identity(_ path: IndexPath) -> AnyHashable {
        guard let section = Section(rawValue: path.section) else { return "?" }
        switch section {
        case .more:
            return "stats"
        case .today, .completed:
            let list = tasks(in: section)
            guard path.row < list.count else {
                return "empty.\(path.section)"
            }
            return ObjectIdentifier(list[path.row])
        }
    }

    // MARK: UITableViewDataSource

    public func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    public func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .more: return 1
        // An empty section keeps one placeholder row so its card (and the
        // "nothing here" message) stays on screen.
        case .today: return max(openTasks.count, 1)
        case .completed: return max(doneTasks.count, 1)
        }
    }

    public func tableView(_ tableView: UITableView,
                          titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .today: return "Today"
        case .completed: return "Completed"
        case .more: return "More"
        }
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        if section == .more {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: IconCell.identifier, for: indexPath) as! IconCell
            cell.configure(icon: .cellular, color: .systemIndigo,
                           title: "Statistics")
            return cell
        }
        let list = tasks(in: section)
        guard indexPath.row < list.count else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: PlaceholderCell.identifier,
                for: indexPath) as! PlaceholderCell
            cell.textLabel.text = section == .today ? "Nothing left to do."
                                                    : "Nothing finished yet."
            return cell
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: TaskCell.identifier, for: indexPath) as! TaskCell
        cell.configure(list[indexPath.row])
        cell.onToggle = { [weak self] c in self?.toggleCompletion(of: c) }
        return cell
    }

    // MARK: UITableViewDelegate

    public func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        if section == .more {
            pushStatistics()
            return
        }
        let list = tasks(in: section)
        guard indexPath.row < list.count else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        pushDetail(for: list[indexPath.row])
    }

    // MARK: Completing / reopening

    /// Flip a task's completion: spring the checkbox, restyle the row, and
    /// move it between the two sections with everything else animating out
    /// of its way.
    public func toggleCompletion(of cell: TaskCell) {
        guard let task = cell.task else { return }
        let nowDone = !task.isDone
        task.isDone = nowDone
        cell.checkbox.setChecked(nowDone, animated: true)
        cell.applyCompletionStyle(animated: true)

        tableView.performUpdates(
            withDuration: TasksRootViewController.sectionMoveDuration,
            delay: TasksRootViewController.sectionMoveDelay,
            identity: { [weak self] in self?.identity($0) ?? AnyHashable("?") },
            updates: {
                if nowDone {
                    openTasks.removeAll { $0 === task }
                    doneTasks.insert(task, at: 0)
                } else {
                    doneTasks.removeAll { $0 === task }
                    openTasks.insert(task, at: 0)
                }
            })
    }

    // MARK: Inserting

    /// "+ New Task": take the next canned task, drop it in at the top of
    /// TODAY fading in while everything below it slides down in the same
    /// beat.
    public func addTask() {
        let task = TasksData.newTask(at: nextPoolIndex)
        nextPoolIndex += 1
        tableView.performUpdates(
            withDuration: TasksRootViewController.insertDuration,
            identity: { [weak self] in self?.identity($0) ?? AnyHashable("?") },
            updates: { openTasks.insert(task, at: 0) })
    }

    // MARK: Navigation

    func pushDetail(for task: TaskItem) {
        let detail = TasksDetailViewController(task: task)
        detail.extraBottomInset = extraBottomInset
        detail.onPriorityChanged = { [weak self] in
            guard let self, let cell = self.cell(for: task) else { return }
            UIView.animate(withDuration: 0.25, delay: 0,
                           options: .curveEaseInOut, animations: {
                cell.applyPriority()
            })
        }
        detail.onCompletionToggled = { [weak self] in
            guard let self, let cell = self.cell(for: task) else { return }
            self.toggleCompletion(of: cell)
        }
        navigationController?.pushViewController(detail, animated: true)
    }

    /// The visible cell currently displaying `task`, if any.
    func cell(for task: TaskItem) -> TaskCell? {
        tableView.visibleCells.compactMap { $0 as? TaskCell }
            .first { $0.task === task }
    }

    func pushStatistics() {
        navigationController?.pushViewController(
            TasksStatsViewController(tasks: openTasks + doneTasks),
            animated: true)
    }
}
