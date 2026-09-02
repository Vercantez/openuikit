import Social
import UIKit

// Corpus usage from DuckDuckGo ShareExtension/ShareViewController.swift:
// SLComposeServiceViewController subclass whose configurationItems() -> [Any]!
// returns []. App-specific providers and URL opening are omitted.

class ShareViewController: SLComposeServiceViewController {
    override func configurationItems() -> [Any]! {
        []
    }

    override func didSelectPost() {
        _ = contentText
    }
}
