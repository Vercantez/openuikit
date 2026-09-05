// Notes' root screen: a UITextView filling the view below the nav bar.
import UIKit

final class NotesRootViewController: UIViewController {

    let body = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes"
        view.backgroundColor = .systemBackground
        body.font = .preferredFont(forTextStyle: .body)
        body.backgroundColor = .systemBackground
        body.text = ""
        body.autocorrectionType = .no
        body.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(body)
        NSLayoutConstraint.activate([
            body.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            body.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            body.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        setContentScrollView(body)
    }

    func focusBody() {
        _ = body.becomeFirstResponder()
    }

    func blur() {
        _ = body.resignFirstResponder()
        _ = view.endEditing(true)
    }
}
