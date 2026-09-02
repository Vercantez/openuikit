import Social
import UIKit

// Corpus usage from Home Assistant Sources/Extensions/Share/ShareViewController.swift:
// SLComposeServiceViewController subclass reading contentText, returning []
// from configurationItems(), and loadPreviewView() -> UIView!. App-specific
// PromiseKit/API posting is omitted.

@objc(HAShareViewController)
class ShareViewController: SLComposeServiceViewController {
    func enteredShareText() -> String {
        contentText ?? ""
    }

    override func loadPreviewView() -> UIView! {
        nil
    }

    override func didSelectPost() {
        _ = contentText
    }

    override func configurationItems() -> [Any]! {
        []
    }
}
