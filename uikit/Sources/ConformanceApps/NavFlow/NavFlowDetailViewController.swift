// NavFlow's pushed detail screen: an Auto Layout card of labels plus a
// UISwitch whose state lives in UserDefaults, like a settings detail pane.
//
// Everything is pinned to `view.safeAreaLayoutGuide`, which is what an app
// writes and which makes the screen a measurement of the safe area a
// navigation controller hands its child.
import UIKit

final class NavFlowDetailViewController: UIViewController {

    /// Set by the pushing controller. A stored property rather than a
    /// designated initializer: real UIKit's designated initializer is
    /// `init(nibName:bundle:)` and OpenUIKit's is `init()`, and one source
    /// file cannot spell both.
    var item: NavFlowItem?

    private let card = UIView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let switchLabel = UILabel()
    private let statusLabel = UILabel()
    private let notificationsSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = item?.title
        view.backgroundColor = .systemGroupedBackground

        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 10

        titleLabel.text = item?.title
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        bodyLabel.text = item?.body
        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0

        switchLabel.text = "Allow Notifications"
        switchLabel.font = .preferredFont(forTextStyle: .body)
        switchLabel.textColor = .label

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel

        notificationsSwitch.isOn = UserDefaults.standard.bool(forKey: NavFlowApp.notificationsKey)
        notificationsSwitch.addAction(UIAction { [weak self] _ in
            self?.notificationsDidChange()
        }, for: .valueChanged)

        for v in [card, titleLabel, bodyLabel, switchLabel, statusLabel, notificationsSwitch] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addSubview(card)
        for v in [titleLabel, bodyLabel, switchLabel, statusLabel, notificationsSwitch] {
            card.addSubview(v)
        }

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: guide.topAnchor, constant: 20),
            card.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            notificationsSwitch.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 20),
            notificationsSwitch.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            switchLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            switchLabel.centerYAnchor.constraint(equalTo: notificationsSwitch.centerYAnchor),

            statusLabel.topAnchor.constraint(equalTo: notificationsSwitch.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
        ])
        updateStatusLabel()
    }

    // MARK: Scripted step (NavFlowApp.perform)

    /// What flipping the switch does. `setOn(_:animated:)` does not send
    /// `.valueChanged` in UIKit, so the handler is called the way the control
    /// would call it.
    func toggleNotifications() {
        notificationsSwitch.setOn(!notificationsSwitch.isOn, animated: true)
        notificationsDidChange()
    }

    private func notificationsDidChange() {
        UserDefaults.standard.set(notificationsSwitch.isOn, forKey: NavFlowApp.notificationsKey)
        updateStatusLabel()
    }

    private func updateStatusLabel() {
        let on = UserDefaults.standard.bool(forKey: NavFlowApp.notificationsKey)
        statusLabel.text = on ? "Notifications are on." : "Notifications are off."
    }
}
