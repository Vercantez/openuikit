import UIKit
import SafariServices
import MessageUI
import LinkPresentation

final class PresentRootViewController: UIViewController {

    private let mailLabel = UILabel()
    private let linkView: LPLinkView = {
        let metadata = LPLinkMetadata()
        metadata.title = "Example Article"
        metadata.url = URL(string: "https://example.com/article")
        metadata.originalURL = URL(string: "https://example.com/article")
        return LPLinkView(metadata: metadata)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Present"
        view.backgroundColor = .systemBackground

        mailLabel.font = .preferredFont(forTextStyle: .body)
        mailLabel.textColor = .label
        mailLabel.numberOfLines = 1
        // MEASURED PresentProbe mail, iPhone SE 2x / iOS 26.1: false.
        let canMail = MFMailComposeViewController.canSendMail()
        mailLabel.text = canMail ? "canSendMail=true" : "canSendMail=false"
        view.addSubview(mailLabel)

        view.addSubview(linkView)

        let safariButton = UIButton(type: .system)
        safariButton.setTitle("Open Safari", for: .normal)
        safariButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        safariButton.addAction(UIAction { [weak self] _ in
            self?.presentSafari()
        }, for: .touchUpInside)
        safariButton.translatesAutoresizingMaskIntoConstraints = false
        mailLabel.translatesAutoresizingMaskIntoConstraints = false
        linkView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(safariButton)

        NSLayoutConstraint.activate([
            linkView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            linkView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            linkView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            linkView.heightAnchor.constraint(equalToConstant: 53),

            mailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mailLabel.topAnchor.constraint(equalTo: linkView.bottomAnchor, constant: 16),

            safariButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            safariButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            safariButton.topAnchor.constraint(equalTo: mailLabel.bottomAnchor, constant: 16),
            safariButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    func presentSafari() {
        // MEASURED PresentProbe safari: data:/file: throw NSInvalidArgumentException.
        // http://127.0.0.1/ is a local URL; chrome paints when the page fails.
        let url = URL(string: "http://127.0.0.1/")!
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true, completion: nil)
    }

    func dismissPresented() {
        dismiss(animated: true, completion: nil)
    }
}
