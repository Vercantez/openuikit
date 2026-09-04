// Modal's root screen: a stack of buttons that raise the presentations the
// script drives, plus a bar button the popover anchors to.
import UIKit

final class ModalRootViewController: UIViewController {

    private var moreItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Modals"
        view.backgroundColor = .systemBackground
        moreItem = UIBarButtonItem(primaryAction: UIAction(title: "More") { [weak self] _ in
            self?.presentPopover()
        })
        navigationItem.rightBarButtonItem = moreItem

        let titles = [
            ("Sheet Medium", { [weak self] in self?.presentMediumSheet() }),
            ("Sheet Large", { [weak self] in self?.presentLargeSheet() }),
            ("Alert", { [weak self] in self?.presentAlert() }),
            ("Action Sheet", { [weak self] in self?.presentActionSheet() }),
            ("Popover", { [weak self] in self?.presentPopover() }),
        ]
        var previous: UIView?
        for (title, handler) in titles {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .preferredFont(forTextStyle: .body)
            button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button)
            var constraints: [NSLayoutConstraint] = [
                button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                button.heightAnchor.constraint(equalToConstant: 44),
            ]
            if let previous {
                constraints.append(
                    button.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 12))
            } else {
                constraints.append(
                    button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                constant: 24))
            }
            NSLayoutConstraint.activate(constraints)
            previous = button
        }
    }

    // MARK: Scripted steps (ModalApp.perform)

    /// A pageSheet with medium + large detents and a grabber. UIKit selects
    /// the first detent (medium) unless `selectedDetentIdentifier` is set.
    func presentMediumSheet() {
        let sheet = ModalSheetViewController()
        sheet.heading = "Medium sheet"
        sheet.modalPresentationStyle = .pageSheet
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.prefersGrabberVisible = true
        }
        present(sheet, animated: true, completion: nil)
    }

    /// Same detents, but `selectedDetentIdentifier = .large`, presented
    /// animated — the large rest state, not a detent change on an already
    /// presented medium sheet.
    func presentLargeSheet() {
        let sheet = ModalSheetViewController()
        sheet.heading = "Large sheet"
        sheet.modalPresentationStyle = .pageSheet
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.prefersGrabberVisible = true
            presentation.selectedDetentIdentifier = .large
        }
        present(sheet, animated: true, completion: nil)
    }

    /// Title, message, three actions including a destructive one.
    func presentAlert() {
        let alert = UIAlertController(title: "Save changes?",
                                      message: "This cannot be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive))
        present(alert, animated: true, completion: nil)
    }

    /// Four actions plus cancel. The popover controller is never touched:
    /// on iPhone that flips an action sheet into a popover and drops cancel
    /// (docs/ORACLE_FLOW.md).
    func presentActionSheet() {
        let sheet = UIAlertController(title: nil, message: nil,
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Copy", style: .default))
        sheet.addAction(UIAlertAction(title: "Share", style: .default))
        sheet.addAction(UIAlertAction(title: "Favorite", style: .default))
        sheet.addAction(UIAlertAction(title: "Delete", style: .destructive))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true, completion: nil)
    }

    /// A 240 × 180 popover from the bar button. On the phone iOS adapts it
    /// to a sheet; the capture is whatever that adaptation draws.
    func presentPopover() {
        let content = ModalPopoverViewController()
        content.preferredContentSize = CGSize(width: 240, height: 180)
        content.modalPresentationStyle = .popover
        if let popover = content.popoverPresentationController {
            popover.barButtonItem = moreItem
        }
        present(content, animated: true, completion: nil)
    }

    func dismissPresented() {
        dismiss(animated: true, completion: nil)
    }
}

/// Plain Auto Layout content on a system background — the sheet CHROME
/// (detent height, card inset, corner radius, dim, grabber) is UIKit's.
///
/// `heading` is a stored property rather than a designated initializer:
/// real UIKit's designated initializer is `init(nibName:bundle:)` and
/// OpenUIKit's is `init()`, and one source file cannot spell both
/// (NavFlowDetailViewController).
final class ModalSheetViewController: UIViewController {
    var heading: String = "Sheet"
    private let headingLabel = UILabel()
    private let bodyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        headingLabel.text = heading
        headingLabel.font = .preferredFont(forTextStyle: .title2)
        headingLabel.textColor = .label
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headingLabel)

        bodyLabel.text = "Presented as a page sheet."
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            headingLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),
            headingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bodyLabel.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: 12),
            bodyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ])
    }
}

/// The popover's content. preferredContentSize is 240 × 180; on the phone
/// the presentation becomes a sheet and this view fills that sheet.
final class ModalPopoverViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = "Popover"
        label.font = .preferredFont(forTextStyle: .title2)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 28),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ])
    }
}
