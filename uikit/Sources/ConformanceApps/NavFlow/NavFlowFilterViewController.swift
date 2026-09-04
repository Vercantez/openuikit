// NavFlow's modal sheet: the pageSheet the "Filter" bar button raises.
//
// Plain Auto Layout content on a system background — the sheet CHROME (the
// card inset, its corner radius, the dimmed base) is UIKit's, which is
// exactly what the capture is measuring.
import UIKit

final class NavFlowFilterViewController: UIViewController {

    private let headingLabel = UILabel()
    private let rows = ["Unplayed", "Downloaded", "Starred"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        headingLabel.text = "Filter"
        headingLabel.font = .preferredFont(forTextStyle: .title2)
        headingLabel.textColor = .label
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headingLabel)

        var constraints: [NSLayoutConstraint] = [
            headingLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            headingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ]
        var previous: UIView = headingLabel
        for title in rows {
            let label = UILabel()
            label.text = title
            label.font = .preferredFont(forTextStyle: .body)
            label.textColor = .label
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            let hairline = UIView()
            hairline.backgroundColor = .separator
            hairline.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hairline)
            constraints += [
                label.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 20),
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                hairline.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
                hairline.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                hairline.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                hairline.heightAnchor.constraint(equalToConstant: 0.5),
            ]
            previous = hairline
        }
        NSLayoutConstraint.activate(constraints)
    }
}
