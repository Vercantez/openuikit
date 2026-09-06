// TextKit-1 attachments. Numbers MEASURED iPhone SE 2x / iOS 26.1
// (`/tmp/probe-uikit-textkit`, SIM_DEVICE=2x, 2026-09-06).
import Foundation
import XCTest
@testable import OpenUIKit

private typealias NSAttributedString = OpenUIKit.NSAttributedString
private typealias NSMutableAttributedString = OpenUIKit.NSMutableAttributedString
private typealias NSTextAttachment = OpenUIKit.NSTextAttachment
private typealias NSTextStorage = OpenUIKit.NSTextStorage
private typealias NSTextContainer = OpenUIKit.NSTextContainer
private typealias NSLayoutManager = OpenUIKit.NSLayoutManager
private typealias NSTextAttachmentViewProvider = OpenUIKit.NSTextAttachmentViewProvider

final class TextKitProbeProvider: OpenUIKit.NSTextAttachmentViewProvider {
    static var loads = 0
    override func loadView() {
        TextKitProbeProvider.loads += 1
        let v = UIView()
        v.backgroundColor = .systemBlue
        view = v
    }
}

#if !os(Linux)
@MainActor
#endif
final class TextKitTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    private var savedBounds: CGRect!
    private var savedScale: CGFloat!

    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
        savedCut = OpenUIKitRuntime.systemFontCut
        savedBounds = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 375, height: 667),
                                     scale: 2)
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        super.tearDown()
    }

    fileprivate func solid24() -> UIImage {
        TextTestSupport.solidImage(from: ["size": [24.0, 24.0], "colors": ["#FF0000"]])
    }

    fileprivate func attachmentString(bounds: CGRect? = nil) -> NSAttributedString {
        let att = NSTextAttachment()
        att.image = solid24()
        if let bounds { att.bounds = bounds }
        let font = UIFont.systemFont(ofSize: 17)
        let out = NSMutableAttributedString(string: "A", attributes: [.font: font])
        out.append(NSAttributedString(attachment: att))
        out.append(NSAttributedString(string: "B", attributes: [.font: font]))
        out.addAttribute(.font, value: font, range: NSRange(location: 1, length: 1))
        return out
    }

    func testAttachmentStringInsertsObjectReplacement() {
        let att = NSTextAttachment()
        att.image = solid24()
        let s = NSAttributedString(attachment: att)
        XCTAssertEqual(s.string, NSAttachmentCharacterString)
        XCTAssertEqual(s.length, 1)
        let stored = s.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment
        XCTAssertTrue(stored === att)
    }

    func testDefaultBoundsIsImageSizeOnBaseline() {
        // MEASURED attach_probe path 0 vs path 1: bounds == .zero and
        // explicit (0,0,24,24) both report attachmentBounds (0, 0, 24, 24).
        let att = NSTextAttachment()
        att.image = solid24()
        let b = att.attachmentBounds(for: nil,
                                     proposedLineFragment: CGRect(x: 0, y: 0, width: 0, height: 0),
                                     glyphPosition: CGPoint(x: 0, y: 0),
                                     characterIndex: 0)
        XCTAssertEqual(b.origin.x, 0, accuracy: 1e-9)
        XCTAssertEqual(b.origin.y, 0, accuracy: 1e-9)
        XCTAssertEqual(b.width, 24, accuracy: 1e-9)
        XCTAssertEqual(b.height, 24, accuracy: 1e-9)
        att.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
        let b2 = att.attachmentBounds(for: nil,
                                      proposedLineFragment: CGRect(x: 0, y: 0, width: 0, height: 0),
                                      glyphPosition: CGPoint(x: 0, y: 0),
                                      characterIndex: 0)
        XCTAssertEqual(b2, b)
    }

    func testLabelSizeThatFitsDefault24() {
        // MEASURED attach_probe path 0, 17 pt regular, 24×24: 46×28.5
        // (A≈11 + 24 + B≈11; height = max(16.187, 24) + 4.101 → 28.101,
        // 2x ceil 28.5).
        let label = UILabel()
        label.attributedText = attachmentString()
        let sz = label.sizeThatFits(CGSize(width: 400, height: 400))
        XCTAssertEqual(sz.width, 46, accuracy: 0.05)
        XCTAssertEqual(sz.height, 28.5, accuracy: 1e-9)
        // path 5 padding 4: size unchanged (padding is a drawing inset).
        let att = NSTextAttachment()
        att.image = solid24()
        att.lineLayoutPadding = 4
        let font = UIFont.systemFont(ofSize: 17)
        let s = NSMutableAttributedString(string: "A", attributes: [.font: font])
        s.append(NSAttributedString(attachment: att))
        s.append(NSAttributedString(string: "B", attributes: [.font: font]))
        s.addAttribute(.font, value: font, range: NSRange(location: 1, length: 1))
        label.attributedText = s
        let szPad = label.sizeThatFits(CGSize(width: 400, height: 400))
        XCTAssertEqual(szPad.width, 46, accuracy: 0.05)
        XCTAssertEqual(szPad.height, 28.5, accuracy: 1e-9)
    }

    func testLabelSizeThatFitsHangingOrigin() {
        // MEASURED attach_bounds_sweep origin.y = −24: height 40.5
        // (ascent 16.187, descent 24).
        let label = UILabel()
        label.attributedText = attachmentString(
            bounds: CGRect(x: 0, y: -24, width: 24, height: 24))
        let sz = label.sizeThatFits(CGSize(width: 400, height: 400))
        XCTAssertEqual(sz.height, 40.5, accuracy: 1e-9)
    }

    func testLayoutManagerUsedRectAndLocations() {
        // MEASURED attach_probe UITextView path 7: usedRect height 28.101,
        // first glyph (5, 24), attachment (16.023, 24).
        let storage = NSTextStorage(attributedString: attachmentString())
        let lm = NSLayoutManager()
        let tc = NSTextContainer(size: CGSize(width: 200, height: 200))
        tc.lineFragmentPadding = 5
        storage.addLayoutManager(lm)
        lm.addTextContainer(tc)
        let used = lm.usedRect(for: tc)
        XCTAssertEqual(used.height, 28.101, accuracy: 0.01)
        let first = lm.location(forGlyphAt: 0)
        XCTAssertEqual(first.x, 5, accuracy: 1e-6)
        XCTAssertEqual(first.y, 24, accuracy: 0.05)
        let attLoc = lm.location(forGlyphAt: 1)
        XCTAssertEqual(attLoc.x, 16.023, accuracy: 0.05)
        XCTAssertEqual(attLoc.y, 24, accuracy: 0.05)
    }

    func testTextStorageNotificationsAndDelegate() {
        let storage = NSTextStorage(string: "hi")
        var did = 0
        let token = OpenUIKit.NotificationCenter.default.addObserver(
            forName: NSTextStorage.didProcessEditingNotification,
            object: storage, queue: nil) { _ in did += 1 }
        storage.replaceCharacters(in: NSRange(location: 2, length: 0), with: "!")
        XCTAssertEqual(storage.string, "hi!")
        XCTAssertGreaterThanOrEqual(did, 1)
        OpenUIKit.NotificationCenter.default.removeObserver(token)
    }

    func testTextViewExposesLiveTextKitStack() {
        let tv = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 80))
        tv.font = .systemFont(ofSize: 17)
        tv.attributedText = attachmentString()
        tv.layoutIfNeeded()
        XCTAssertTrue(tv.textStorage === tv.layoutManager.textStorage)
        XCTAssertTrue(tv.layoutManager.textContainers.first === tv.textContainer)
        XCTAssertEqual(tv.textContainer.lineFragmentPadding, 5, accuracy: 1e-9)
        XCTAssertEqual(tv.textStorage.length, 3)
        let used = tv.layoutManager.usedRect(for: tv.textContainer)
        XCTAssertEqual(used.height, 28.101, accuracy: 0.05)
    }

    func testWrapHelloAttachmentFits200() {
        // MEASURED attach_probe path 6 sizeThatFits200 = 200×48.5.
        let att = NSTextAttachment()
        att.image = solid24()
        let font = UIFont.systemFont(ofSize: 17)
        let s = NSMutableAttributedString(string: "Hello ", attributes: [.font: font])
        s.append(NSAttributedString(attachment: att))
        s.append(NSAttributedString(string: " world that wraps over two lines here",
                                    attributes: [.font: font]))
        s.addAttribute(.font, value: font, range: NSRange(location: 0, length: s.length))
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = s
        let sz = label.sizeThatFits(CGSize(width: 200, height: 4000))
        XCTAssertEqual(sz.width, 200, accuracy: 0.5)
        XCTAssertEqual(sz.height, 48.5, accuracy: 0.5)
    }

    func testViewProviderRegistryAndHosting() {
        TextKitProbeProvider.loads = 0
        NSTextAttachment.registerViewProviderClass(TextKitProbeProvider.self, forFileType: "public.test-kit")
        let att = NSTextAttachment()
        att.fileType = "public.test-kit"
        att.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
        XCTAssertTrue(att.usesTextAttachmentView)
        let font = UIFont.systemFont(ofSize: 17)
        let s = NSMutableAttributedString(string: "A", attributes: [.font: font])
        s.append(NSAttributedString(attachment: att))
        let tv = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 80))
        tv.font = font
        tv.attributedText = s
        tv.layoutIfNeeded()
        XCTAssertGreaterThanOrEqual(TextKitProbeProvider.loads, 1)
        var hosted = 0
        for sub in tv.contentView.subviews {
            if sub.backgroundColor == UIColor.systemBlue { hosted += 1 }
        }
        XCTAssertEqual(hosted, 1)
    }
}
