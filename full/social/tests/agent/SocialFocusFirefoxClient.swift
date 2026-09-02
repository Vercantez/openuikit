import Social
import UIKit

// Corpus usage from focus-ios/OpenInFocus/ActionViewController.swift and
// firefox-ios's copy of that file: SLComposeServiceViewController subclass
// with configurationItems() -> [Any]!. App-specific URL opening is omitted.

final class ActionViewController: SLComposeServiceViewController {
    override func isContentValid() -> Bool { true }

    override func didSelectPost() {
        _ = contentText
    }

    override func configurationItems() -> [Any]! {
        []
    }
}
