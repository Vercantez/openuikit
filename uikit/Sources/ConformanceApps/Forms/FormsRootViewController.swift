// Forms' root screen: a grouped UITableViewController whose rows are real
// controls, pinned with Auto Layout to each cell's layoutMarginsGuide.
import UIKit

final class FormsRootViewController: UITableViewController {

    private enum Row: Int, CaseIterable {
        case name, notes, enabled, level, size, date, count
        static func at(_ indexPath: IndexPath) -> Row {
            Row(rawValue: indexPath.row) ?? .name
        }
    }

    let nameField = UITextField()
    let notesView = UITextView()
    let enabledSwitch = UISwitch()
    let levelSlider = UISlider()
    let sizeControl = UISegmentedControl(items: ["Small", "Medium", "Large"])
    let datePicker = UIDatePicker()
    let countStepper = UIStepper()

    private let enabledLabel = UILabel()
    private let levelLabel = UILabel()
    private let dateLabel = UILabel()
    private let countLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Form"
        configureControls()
        // OpenUIKit's navigation bar has no automatic content-scroll-view
        // detection (UIViewController.setContentScrollView is explicit-only);
        // real UIKit accepts the same call and already tracks this table.
        setContentScrollView(tableView)
    }

    private func configureControls() {
        nameField.placeholder = "Your name"
        nameField.font = .preferredFont(forTextStyle: .body)
        nameField.borderStyle = .none
        nameField.autocorrectionType = .no

        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.backgroundColor = .clear
        notesView.text = "Notes about this account."
        notesView.isScrollEnabled = false

        enabledLabel.text = "Enabled"
        enabledLabel.font = .preferredFont(forTextStyle: .body)
        enabledLabel.textColor = .label

        levelLabel.text = "Level"
        levelLabel.font = .preferredFont(forTextStyle: .body)
        levelLabel.textColor = .label
        levelSlider.value = 0.3

        sizeControl.selectedSegmentIndex = 0

        dateLabel.text = "Date"
        dateLabel.font = .preferredFont(forTextStyle: .body)
        dateLabel.textColor = .label
        // Pin calendar identity so the compact capsule shows the same
        // components on both sides of the comparison (OpenUIKit's default
        // date is the host clock; iOS's is wall-clock now).
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        datePicker.calendar = calendar
        datePicker.locale = Locale(identifier: "en_US_POSIX")
        datePicker.timeZone = TimeZone(secondsFromGMT: 0)
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.date = calendar.date(from: DateComponents(
            calendar: calendar, timeZone: calendar.timeZone,
            year: 2026, month: 9, day: 4))!

        countLabel.text = "Count"
        countLabel.font = .preferredFont(forTextStyle: .body)
        countLabel.textColor = .label
        countStepper.value = 3
        countStepper.minimumValue = 0
        countStepper.maximumValue = 10
    }

    // MARK: Data source

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        "Account"
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = Row.at(indexPath)
        let id = "Forms.\(row.rawValue)"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .default, reuseIdentifier: id)
        cell.selectionStyle = .none
        cell.textLabel?.text = nil
        install(row, in: cell)
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        Row.at(indexPath) == .notes ? 100 : 44
    }

    // MARK: Cell Auto Layout (layoutMarginsGuide)

    private func install(_ row: Row, in cell: UITableViewCell) {
        switch row {
        case .name:
            pinFullWidth(nameField, in: cell)
        case .notes:
            pinFullWidth(notesView, in: cell, fillVertically: true)
        case .enabled:
            pinTrailingControl(enabledSwitch, label: enabledLabel, in: cell)
        case .level:
            pinLabeledSlider(in: cell)
        case .size:
            pinFullWidth(sizeControl, in: cell, height: 33)
        case .date:
            pinTrailingControl(datePicker, label: dateLabel, in: cell,
                               controlWidth: 128, controlHeight: 34)
        case .count:
            pinTrailingControl(countStepper, label: countLabel, in: cell)
        }
    }

    /// Leading and trailing against the content view's layout margins guide;
    /// vertically centred unless the row is the notes field.
    private func pinFullWidth(_ view: UIView, in cell: UITableViewCell,
                              fillVertically: Bool = false,
                              height: CGFloat? = nil) {
        guard view.superview !== cell.contentView else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(view)
        let guide = cell.contentView.layoutMarginsGuide
        var constraints: [NSLayoutConstraint] = [
            view.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
        ]
        if fillVertically {
            constraints += [
                view.topAnchor.constraint(equalTo: guide.topAnchor),
                view.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            ]
        } else {
            constraints.append(
                view.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor))
            if let height {
                constraints.append(view.heightAnchor.constraint(equalToConstant: height))
            }
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func pinTrailingControl(_ control: UIView, label: UILabel,
                                    in cell: UITableViewCell,
                                    controlWidth: CGFloat? = nil,
                                    controlHeight: CGFloat? = nil) {
        guard label.superview !== cell.contentView else { return }
        label.translatesAutoresizingMaskIntoConstraints = false
        control.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(label)
        cell.contentView.addSubview(control)
        let guide = cell.contentView.layoutMarginsGuide
        var constraints: [NSLayoutConstraint] = [
            label.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            control.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            control.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor,
                                            constant: -8),
        ]
        if let controlWidth {
            constraints.append(control.widthAnchor.constraint(equalToConstant: controlWidth))
        }
        if let controlHeight {
            constraints.append(control.heightAnchor.constraint(equalToConstant: controlHeight))
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func pinLabeledSlider(in cell: UITableViewCell) {
        guard levelLabel.superview !== cell.contentView else { return }
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        levelSlider.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(levelLabel)
        cell.contentView.addSubview(levelSlider)
        let guide = cell.contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            levelLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            levelLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            levelSlider.leadingAnchor.constraint(equalTo: levelLabel.trailingAnchor,
                                                 constant: 12),
            levelSlider.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            levelSlider.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
        ])
        levelLabel.setContentHuggingPriority(.required, for: .horizontal)
        levelLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: Scripted steps (FormsApp.perform)

    func focusName() {
        _ = nameField.becomeFirstResponder()
    }

    func typeName() {
        nameField.text = "Alex Rivera"
    }

    func toggleEnabled() {
        enabledSwitch.setOn(!enabledSwitch.isOn, animated: true)
    }

    func slide(to value: Float) {
        levelSlider.setValue(value, animated: true)
    }

    func selectSegment(_ index: Int) {
        sizeControl.selectedSegmentIndex = index
    }

    func blur() {
        _ = nameField.resignFirstResponder()
        _ = view.endEditing(true)
    }
}
