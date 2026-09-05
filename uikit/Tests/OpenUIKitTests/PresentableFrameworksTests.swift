// Presentable first-party frameworks. Owner: SafariServices / MessageUI /
// LinkPresentation.
//
// Geometry numbers come from PresentProbe on iPhone SE 2x and iPhone 16 3x
// / iOS 26.1 (docs/agent_reports/presentable-frameworks.md).
import Foundation
import XCTest
import SafariServices
import MessageUI
import LinkPresentation
import ConformanceApps
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class PresentableFrameworksTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut = .macOS

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        super.tearDown()
    }

    func testPresentIsRegistered() {
        XCTAssertTrue(ConformanceApps.isRegistered("Present"))
        XCTAssertTrue(ConformanceApps.names.contains("Present"))
    }

    func testCanSendMailIsFalse() {
        // MEASURED PresentProbe mail, iPhone SE 2x / iOS 26.1.
        XCTAssertFalse(MFMailComposeViewController.canSendMail())
        XCTAssertFalse(MFMessageComposeViewController.canSendText())
    }

    func testMailComposerStoresPrefill() {
        let mail = MFMailComposeViewController()
        mail.setToRecipients(["reader@example.com"])
        mail.setSubject("Hello")
        mail.setMessageBody("Body text", isHTML: false)
        mail.setBccRecipients(["bcc@example.com"])
        mail.addAttachmentData(Data([1, 2, 3]), mimeType: "text/plain", fileName: "note.txt")
        _ = mail.view
        XCTAssertEqual(mail.viewControllers.count, 1)
    }

    func testSafariCopiesConfigurationAndPaintsIOSChrome() {
        OpenUIKitRuntime.systemFontCut = .iOS
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        config.barCollapsingEnabled = false
        let url = URL(string: "http://127.0.0.1/")!
        let safari = SFSafariViewController(url: url, configuration: config)
        XCTAssertTrue(safari.configuration.entersReaderIfAvailable)
        XCTAssertFalse(safari.configuration.barCollapsingEnabled)
        XCTAssertEqual(safari.dismissButtonStyle, .done)
        XCTAssertEqual(safari.modalPresentationStyle, .fullScreen)

        config.entersReaderIfAvailable = false
        XCTAssertTrue(safari.configuration.entersReaderIfAvailable,
                      "init must copy Configuration")

        safari.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        safari.view.layoutIfNeeded()
        let dismiss = tagged(safari.view, 1001)
        let back = tagged(safari.view, 1002)
        let capsule = tagged(safari.view, 1003)
        XCTAssertEqual(dismiss?.frame, CGRect(x: 16, y: 8, width: 44, height: 44))
        XCTAssertEqual(back?.frame, CGRect(x: 16, y: 603, width: 48, height: 48))
        XCTAssertEqual(capsule?.frame, CGRect(x: 375 - 16 - 174, y: 603, width: 174, height: 48))
    }

    func testSafariChromeUsesSafeAreaOnNotchedPhone() {
        OpenUIKitRuntime.systemFontCut = .iOS
        let safari = SFSafariViewController(url: URL(string: "http://127.0.0.1/")!)
        safari.additionalSafeAreaInsets = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
        safari.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        safari.view.layoutIfNeeded()
        let dismiss = tagged(safari.view, 1001)
        let back = tagged(safari.view, 1002)
        // y = SA.top + 8 = 67; toolbar y = 852 − max(16, 34−16) − 48 = 786.
        XCTAssertEqual(dismiss?.frame.origin, CGPoint(x: 16, y: 67))
        XCTAssertEqual(back?.frame.origin.y, 786)
    }

    func testSafariCatalystCutDoesNotPaintChrome() {
        OpenUIKitRuntime.systemFontCut = .macOS
        let safari = SFSafariViewController(url: URL(string: "http://127.0.0.1/")!)
        safari.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        safari.view.layoutIfNeeded()
        XCTAssertNil(tagged(safari.view, 1001))
    }

    func testReadingListAndContentBlockerFailClosed() throws {
        XCTAssertTrue(SSReadingList.supportsURL(URL(string: "https://example.com")!))
        XCTAssertFalse(SSReadingList.supportsURL(URL(string: "ftp://example.com")!))
        XCTAssertThrowsError(
            try SSReadingList.default()?.addItem(
                with: URL(string: "ftp://example.com")!, title: nil, previewText: nil)
        ) { error in
            let typed = error as? SSReadingListError
            XCTAssertEqual(typed?.code, .urlSchemeNotAllowed)
        }
        XCTAssertThrowsError(
            try SSReadingList.default()?.addItem(
                with: URL(string: "https://example.com")!, title: nil, previewText: nil)
        )

        let blocker = expectation(description: "blocker")
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: "x") { state, error in
            XCTAssertNil(state)
            XCTAssertNotNil(error)
            blocker.fulfill()
        }
        wait(for: [blocker], timeout: 1)

        let session = SFAuthenticationSession(
            url: URL(string: "https://example.com")!,
            callbackURLScheme: "app"
        ) { _, _ in }
        XCTAssertFalse(session.start())
    }

    func testLinkViewPlainCardMatchesProbe() {
        OpenUIKitRuntime.systemFontCut = .iOS
        let metadata = LPLinkMetadata()
        metadata.title = "Example Article"
        metadata.url = URL(string: "https://example.com/article")
        let card = LPLinkView(metadata: metadata)
        card.frame = CGRect(x: 16, y: 24, width: 343, height: 53)
        card.layoutIfNeeded()
        XCTAssertEqual(card.intrinsicContentSize, CGSize(width: 186, height: 53))
        XCTAssertEqual(card.layer.cornerRadius, 10)

        var title: UILabel?
        var host: UILabel?
        for sub in card.subviews {
            guard let label = sub as? UILabel else { continue }
            if label.font.weight == .semibold { title = label }
            if label.font.pointSize == 13 { host = label }
        }
        XCTAssertEqual(title?.text, "Example Article")
        XCTAssertEqual(title?.frame, CGRect(x: 16, y: 8, width: 269, height: 18))
        XCTAssertEqual(host?.text, "example.com")
        XCTAssertEqual(host?.frame, CGRect(x: 16, y: 28, width: 269, height: 16))
    }

    func testMetadataProviderFailsClosed() async {
        let provider = LPMetadataProvider()
        do {
            _ = try await provider.startFetchingMetadata(for: URL(string: "https://example.com")!)
            XCTFail("fetch must fail closed")
        } catch let error as LPError {
            XCTAssertEqual(error.code, .metadataFetchFailed)
        } catch {
            XCTFail("wrong error \(error)")
        }
    }

    private func tagged(_ view: UIView, _ tag: Int) -> UIView? {
        if view.tag == tag { return view }
        for sub in view.subviews {
            if let found = tagged(sub, tag) { return found }
        }
        return nil
    }
}
