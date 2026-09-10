// WordPress-iOS §9.6 blocking rows: `UITextItem` and
// `UIPopoverPresentationControllerSourceItem`. Every number is a row of
// Tools/oracle2/wordpressrowsprobe's transcripts (iPhone 16 / iPad A16,
// iOS 26.1) — see docs/agent_reports/wordpress-textitem-popover.md.
import XCTest
@testable import OpenUIKit

private typealias NSAttributedString = OpenUIKit.NSAttributedString
private typealias NSMutableAttributedString = OpenUIKit.NSMutableAttributedString
private typealias NSTextAttachment = OpenUIKit.NSTextAttachment

// MARK: - Delegates shaped like the corpus

/// WordPress's shape: only the iOS 17 methods.
#if !os(Linux)
@MainActor
#endif
private final class NewOnlyDelegate: UITextViewDelegate {
    var events: [String] = []
    var items: [UITextItem] = []
    var defaultActions: [UIAction] = []
    var defaultMenus: [UIMenu] = []
    var primaryReturn: String = "default"   // default | nil | custom
    var menuReturn: String = "default"      // default | nil
    var customFired = 0
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem,
                  defaultAction: UIAction) -> UIAction? {
        events.append("primaryActionFor")
        items.append(textItem)
        defaultActions.append(defaultAction)
        switch primaryReturn {
        case "nil": return nil
        case "custom": return UIAction(title: "Custom") { [weak self] _ in self?.customFired += 1 }
        default: return defaultAction
        }
    }
    func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem,
                  defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
        events.append("menuConfigurationFor")
        items.append(textItem)
        defaultMenus.append(defaultMenu)
        return menuReturn == "nil" ? nil : UITextItem.MenuConfiguration(menu: defaultMenu)
    }
    func textView(_ textView: UITextView, textItemMenuWillDisplayFor textItem: UITextItem,
                  animator: UIContextMenuInteractionAnimating) {
        events.append("textItemMenuWillDisplay")
    }
    func textView(_ textView: UITextView, textItemMenuWillEndFor textItem: UITextItem,
                  animator: UIContextMenuInteractionAnimating) {
        events.append("textItemMenuWillEnd")
    }
}

/// The iOS 15/16 shape (firefox's fallback): only the iOS 10 gates.
#if !os(Linux)
@MainActor
#endif
private final class OldOnlyDelegate: UITextViewDelegate {
    var events: [String] = []
    var ranges: [NSRange] = []
    var interactions: [UITextItemInteraction] = []
    var answer = true
    func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                  in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        events.append("shouldInteractWithURL \(URL.absoluteString)")
        ranges.append(characterRange)
        interactions.append(interaction)
        return answer
    }
    func textView(_ textView: UITextView, shouldInteractWith attachment: NSTextAttachment,
                  in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        events.append("shouldInteractWithAttachment")
        ranges.append(characterRange)
        return answer
    }
}

/// Both generations (firefox's WebCompatLearnMoreFooterView).
#if !os(Linux)
@MainActor
#endif
private final class BothDelegate: UITextViewDelegate {
    var events: [String] = []
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem,
                  defaultAction: UIAction) -> UIAction? {
        events.append("primaryActionFor")
        return defaultAction
    }
    func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                  in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        events.append("shouldInteractWithURL")
        return true
    }
}

#if !os(Linux)
@MainActor
#endif
private final class ConformingOnlyTextDelegate: UITextViewDelegate {}

// MARK: - UITextItem

#if !os(Linux)
@MainActor
#endif
final class TextItemTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    private var savedBounds: CGRect!
    private var savedScale: CGFloat!
    private var savedHandler: ((String) -> Bool)?
    private var opened: [String] = []

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        savedBounds = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        savedHandler = UIApplication.urlOpenHandler
        OpenUIKitRuntime.systemFontCut = .iOS
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852), scale: 3)
        opened = []
        UIApplication.urlOpenHandler = { [weak self] s in self?.opened.append(s); return true }
    }

    override func tearDown() {
        _UIMenuPresentation.active?.dismiss()
        UIApplication.urlOpenHandler = savedHandler
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        super.tearDown()
    }

    // The probe's string: "Read Apple or tagword here \u{FFFC} end web".
    // MEASURED ranges: link [5, 5], tag [14, 7], attachment [27, 1].
    let linkURL = URL(string: "wpprobe://open?item=link")!
    // MEASURED tap points (window coordinates, from the oracle's glyph rects
    // `linkRectWin [68.015, 208, 44.061, 24.101]` etc.).
    let linkPoint = CGPoint(x: 90.045, y: 220.05)
    let tagPoint = CGPoint(x: 167.649, y: 220.05)
    let attachmentPoint = CGPoint(x: 253.493, y: 220.05)
    let plainPoint = CGPoint(x: 44.54, y: 220.05)

    private func attributed() -> NSAttributedString {
        let f = UIFont.systemFont(ofSize: 17)
        let s = NSMutableAttributedString(string: "Read ", attributes: [.font: f])
        s.append(NSAttributedString(string: "Apple", attributes: [.font: f, .link: linkURL]))
        s.append(NSAttributedString(string: " or ", attributes: [.font: f]))
        s.append(NSAttributedString(string: "tagword", attributes: [.font: f, .textItemTag: "wp-tag"]))
        s.append(NSAttributedString(string: " here ", attributes: [.font: f]))
        let att = NSTextAttachment()
        att.image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { _ in
            UIColor.systemRed.setFill()
        }
        att.bounds = CGRect(x: 0, y: -4, width: 24, height: 24)
        s.append(NSAttributedString(attachment: att))
        s.append(NSAttributedString(string: " end ", attributes: [.font: f]))
        s.append(NSAttributedString(string: "web", attributes: [.font: f, .link: URL(string: "https://example.com/apple")!]))
        return s
    }

    private func makeTextView(editable: Bool = false, selectable: Bool = true) -> (UIWindow, UITextView) {
        let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let root = UIViewController()
        root.view.backgroundColor = .white
        w.rootViewController = root
        w.makeKeyAndVisible()
        let tv = UITextView(frame: CGRect(x: 20, y: 200, width: 353, height: 120))
        tv.attributedText = attributed()
        tv.isEditable = editable
        tv.isSelectable = selectable
        root.view.addSubview(tv)
        w.layoutIfNeeded()
        return (w, tv)
    }

    private func tap(_ w: UIWindow, at p: CGPoint) {
        w.sendTouch(.began, at: p, timestamp: 0, touchID: 0)
        w.sendTouch(.ended, at: p, timestamp: 0.06, touchID: 0)
    }

    private func press(_ w: UIWindow, at p: CGPoint) {
        w.sendTouch(.began, at: p, timestamp: 0, touchID: 0)
        w.sendTouch(.ended, at: p, timestamp: 0.9, touchID: 0)
    }

    func testTagKeyAndConfigurationShapes() {
        XCTAssertEqual(NSAttributedString.Key.textItemTag.rawValue, "UITextItemTagAttribute")
        let menu = UIMenu(title: "M")
        XCTAssertTrue(UITextItem.MenuConfiguration(menu: menu).menu === menu)
        XCTAssertTrue(UITextItem.MenuConfiguration(preview: nil, menu: menu).preview == nil)
        XCTAssertTrue(UITextItem.MenuConfiguration(menu: menu).preview === UITextItem.MenuPreview.default)
        let (_, tv) = makeTextView()
        // MEASURED default linkTextAttributes: systemBlue only.
        XCTAssertEqual(tv.linkTextAttributes.count, 1)
        XCTAssertEqual(tv.linkTextAttributes[.foregroundColor] as? UIColor, UIColor.systemBlue)
        XCTAssertTrue(tv.isSelectable)
    }

    func testHitTestFindsTheThreeItemsWithMeasuredRanges() {
        let (w, tv) = makeTextView()
        func item(_ p: CGPoint) -> UITextItem? { tv.textItem(at: tv.convert(p, from: w)) }
        guard case .link(let u)? = item(linkPoint)?.content else { return XCTFail("link") }
        XCTAssertEqual(u, linkURL)
        XCTAssertEqual(item(linkPoint)?.range, NSRange(location: 5, length: 5))
        guard case .tag(let t)? = item(tagPoint)?.content else { return XCTFail("tag") }
        XCTAssertEqual(t, "wp-tag")
        XCTAssertEqual(item(tagPoint)?.range, NSRange(location: 14, length: 7))
        guard case .textAttachment? = item(attachmentPoint)?.content else { return XCTFail("attachment") }
        XCTAssertEqual(item(attachmentPoint)?.range, NSRange(location: 27, length: 1))
        XCTAssertNil(item(plainPoint))
    }

    /// MEASURED `tap.link.new.default`: one `primaryActionFor`, the default
    /// action (title "", identifier `UITextInteractableItemDefaultAction`)
    /// returned → the URL opens, nothing else asked.
    func testTapLinkPerformsReturnedDefaultAction() {
        let (w, tv) = makeTextView()
        let d = NewOnlyDelegate()
        tv.delegate = d
        tap(w, at: linkPoint)
        XCTAssertEqual(d.events, ["primaryActionFor"])
        XCTAssertEqual(d.items.first?.range, NSRange(location: 5, length: 5))
        XCTAssertEqual(d.defaultActions.first?.title, "")
        XCTAssertEqual(d.defaultActions.first?.identifier.rawValue, "UITextInteractableItemDefaultAction")
        XCTAssertEqual(d.defaultActions.first?.attributes, [])
        XCTAssertNil(d.defaultActions.first?.image)
        XCTAssertEqual(opened, [linkURL.absoluteString])
        XCTAssertNil(_UIMenuPresentation.active)
    }

    /// MEASURED `tap.link.new.nil`: nil → nothing opens; the menu question
    /// follows with the URL-titled default menu and the platter shows.
    func testTapLinkNilFallsThroughToTheMenu() {
        let (w, tv) = makeTextView()
        let d = NewOnlyDelegate()
        d.primaryReturn = "nil"
        tv.delegate = d
        tap(w, at: linkPoint)
        XCTAssertEqual(d.events, ["primaryActionFor", "menuConfigurationFor", "textItemMenuWillDisplay"])
        XCTAssertEqual(opened, [])
        let menu = d.defaultMenus.first
        XCTAssertEqual(menu?.title, linkURL.absoluteString)
        XCTAssertEqual(menu?.identifier.rawValue, "UITextItemDefaultMenuIdentifier")
        XCTAssertEqual(menu?.children.map(\.title), ["Open", "Copy", "Share…"])
        XCTAssertTrue(menu?.children.allSatisfy { $0 is UIAction } ?? false)
        XCTAssertNotNil(_UIMenuPresentation.active)
        _UIMenuPresentation.active?.dismiss()
        XCTAssertEqual(d.events.last, "textItemMenuWillEnd")
    }

    /// MEASURED `tap.link.new.custom`: the custom action runs; no open, no menu.
    func testTapLinkCustomActionRunsInstead() {
        let (w, tv) = makeTextView()
        let d = NewOnlyDelegate()
        d.primaryReturn = "custom"
        tv.delegate = d
        tap(w, at: linkPoint)
        XCTAssertEqual(d.events, ["primaryActionFor"])
        XCTAssertEqual(d.customFired, 1)
        XCTAssertEqual(opened, [])
        XCTAssertNil(_UIMenuPresentation.active)
    }

    /// MEASURED `tap.link.old`: only the iOS 10 gate implemented → it is
    /// asked with the run range and `.invokeDefaultAction`; true opens.
    func testTapLinkOldOnlyDelegateIsAsked() {
        let (w, tv) = makeTextView()
        let d = OldOnlyDelegate()
        tv.delegate = d
        tap(w, at: linkPoint)
        XCTAssertEqual(d.events, ["shouldInteractWithURL \(linkURL.absoluteString)"])
        XCTAssertEqual(d.ranges, [NSRange(location: 5, length: 5)])
        XCTAssertEqual(d.interactions, [.invokeDefaultAction])
        XCTAssertEqual(opened, [linkURL.absoluteString])

        opened = []
        d.answer = false
        d.events = []
        tap(w, at: linkPoint)
        XCTAssertEqual(d.events.count, 1)
        XCTAssertEqual(opened, [])
    }

    /// MEASURED `tap.link.both`: only `primaryActionFor`; `tap.link.noDelegate`
    /// and `tap.link.noneImplemented`: the URL opens.
    func testTapLinkBothNoneAndNoDelegate() {
        let (w, tv) = makeTextView()
        let both = BothDelegate()
        tv.delegate = both
        tap(w, at: linkPoint)
        XCTAssertEqual(both.events, ["primaryActionFor"])
        XCTAssertEqual(opened, [linkURL.absoluteString])

        opened = []
        tv.delegate = nil
        tap(w, at: linkPoint)
        XCTAssertEqual(opened, [linkURL.absoluteString])

        opened = []
        let none = ConformingOnlyTextDelegate()
        tv.delegate = none
        tap(w, at: linkPoint)
        XCTAssertEqual(opened, [linkURL.absoluteString])
    }

    /// MEASURED `tap.link.new.notSelectable`: nothing; `tap.link.new.editable`:
    /// opens and the text view does not become first responder.
    func testSelectableGateAndEditableTextView() {
        let (w, tv) = makeTextView(selectable: false)
        let d = NewOnlyDelegate()
        tv.delegate = d
        tap(w, at: linkPoint)
        XCTAssertEqual(d.events, [])
        XCTAssertEqual(opened, [])

        let (w2, tv2) = makeTextView(editable: true)
        let d2 = NewOnlyDelegate()
        tv2.delegate = d2
        tap(w2, at: linkPoint)
        XCTAssertEqual(d2.events, ["primaryActionFor"])
        XCTAssertEqual(opened, [linkURL.absoluteString])
        XCTAssertFalse(tv2.isFirstResponder)
        XCTAssertFalse(tv2.isEditing)
    }

    /// MEASURED `tap.tag.new`: `.tag("wp-tag")` [14, 7]; the default action
    /// asks for the menu, whose default is EMPTY, so nothing shows.
    func testTapTagAsksPrimaryThenEmptyMenu() {
        let (w, tv) = makeTextView()
        let d = NewOnlyDelegate()
        tv.delegate = d
        tap(w, at: tagPoint)
        XCTAssertEqual(d.events, ["primaryActionFor", "menuConfigurationFor"])
        guard case .tag(let t)? = d.items.first?.content else { return XCTFail("tag item") }
        XCTAssertEqual(t, "wp-tag")
        XCTAssertEqual(d.items.first?.range, NSRange(location: 14, length: 7))
        XCTAssertEqual(d.defaultMenus.first?.title, "")
        XCTAssertEqual(d.defaultMenus.first?.children.count, 0)
        XCTAssertNil(_UIMenuPresentation.active)
        XCTAssertEqual(opened, [])
    }

    /// MEASURED `tap.attachment.both`: `.textAttachment` [27, 1], no menu,
    /// nothing opens; `press.attachment.new`: default menu "Copy Image" /
    /// "Save to Camera Roll" under the default identifier.
    func testAttachmentTapAndPress() {
        let (w, tv) = makeTextView()
        let d = NewOnlyDelegate()
        tv.delegate = d
        tap(w, at: attachmentPoint)
        XCTAssertEqual(d.events, ["primaryActionFor"])
        guard case .textAttachment? = d.items.first?.content else { return XCTFail("attachment item") }
        XCTAssertEqual(d.items.first?.range, NSRange(location: 27, length: 1))
        XCTAssertNil(_UIMenuPresentation.active)

        d.events = []
        press(w, at: attachmentPoint)
        XCTAssertEqual(d.events, ["primaryActionFor", "menuConfigurationFor", "textItemMenuWillDisplay"])
        XCTAssertEqual(d.defaultMenus.first?.title, "")
        XCTAssertEqual(d.defaultMenus.first?.identifier.rawValue, "UITextItemDefaultMenuIdentifier")
        XCTAssertEqual(d.defaultMenus.first?.children.map(\.title), ["Copy Image", "Save to Camera Roll"])
        XCTAssertNotNil(_UIMenuPresentation.active)
    }

    /// MEASURED `press.link.new.default` / `press.link.new.nilMenu`: a long
    /// press asks `primaryActionFor` (not performed) then the menu; nil
    /// config shows nothing.
    func testLongPressLinkAsksMenuAfterPrimary() {
        let (w, tv) = makeTextView()
        let d = NewOnlyDelegate()
        tv.delegate = d
        press(w, at: linkPoint)
        XCTAssertEqual(d.events, ["primaryActionFor", "menuConfigurationFor", "textItemMenuWillDisplay"])
        XCTAssertEqual(opened, [], "the primary action is asked but not performed")
        XCTAssertEqual(d.defaultMenus.first?.children.map(\.title), ["Open", "Copy", "Share…"])
        XCTAssertNotNil(_UIMenuPresentation.active)
        _UIMenuPresentation.active?.dismiss()

        d.events = []
        d.menuReturn = "nil"
        press(w, at: linkPoint)
        XCTAssertEqual(d.events, ["primaryActionFor", "menuConfigurationFor"])
        XCTAssertNil(_UIMenuPresentation.active)
        XCTAssertEqual(opened, [])
    }

    /// WordPress's ExpandableCell shape end to end: a link tap routes to the
    /// cell's callback, and a link long press shows no menu (nil config).
    func testWordPressExpandableCellShape() {
        let (w, tv) = makeTextView()
        let d = NewOnlyDelegate()
        d.primaryReturn = "custom"
        d.menuReturn = "nil"
        tv.delegate = d
        tap(w, at: linkPoint)
        XCTAssertEqual(d.customFired, 1)
        XCTAssertEqual(opened, [])
        press(w, at: linkPoint)
        XCTAssertNil(_UIMenuPresentation.active)
    }
}

// MARK: - UIPopoverPresentationControllerSourceItem

#if !os(Linux)
@MainActor
#endif
final class PopoverSourceItemTests: XCTestCase {
    private var savedCut: FontEngine.SystemFontCut!
    private var savedBounds: CGRect!
    private var savedScale: CGFloat!
    private var savedIdiom: UIUserInterfaceIdiom!
    private var savedTraits: UITraitCollection!

    override func setUp() {
        super.setUp()
        savedCut = OpenUIKitRuntime.systemFontCut
        savedBounds = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        savedIdiom = UIDevice.current.userInterfaceIdiom
        savedTraits = UITraitCollection.current
        OpenUIKitRuntime.systemFontCut = .iOS
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        UIDevice.current.userInterfaceIdiom = savedIdiom
        UITraitCollection.current = savedTraits
        super.tearDown()
    }

    /// iPad (A16) 820×1180 @2x, safe area 32 / 25, as the oracle ran.
    private func pad() -> (UIWindow, UIViewController, UINavigationController) {
        UIDevice.current.userInterfaceIdiom = .pad
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 2, userInterfaceIdiom: .pad)
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 820, height: 1180), scale: 2)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        window._setSafeAreaInsets(UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0))
        let base = UIViewController()
        base.view.backgroundColor = .white
        let nav = UINavigationController(rootViewController: base)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        return (window, base, nav)
    }

    private func popoverVC(size: CGSize = CGSize(width: 240, height: 180)) -> (UIViewController, UIPopoverPresentationController) {
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        vc.preferredContentSize = size
        vc.modalPresentationStyle = .popover
        return (vc, vc.popoverPresentationController!)
    }

    func testProtocolShapeAndDefaults() {
        let (_, pop) = popoverVC()
        XCTAssertTrue(pop.sourceRect.isNull, "MEASURED default sourceRect is CGRect.null")
        XCTAssertEqual(pop.arrowDirection, .unknown)
        XCTAssertEqual(UIPopoverArrowDirection.unknown.rawValue, Int(bitPattern: UInt.max))
        XCTAssertEqual(UIPopoverArrowDirection.any.rawValue, 15)
        XCTAssertNil(pop.sourceItem)
        // The `weak var anchor: UIPopoverPresentationControllerSourceItem?`
        // WordPress's ReaderPostMenu holds compiles: the protocol is class-bound.
        weak var anchor: (any UIPopoverPresentationControllerSourceItem)?
        let v = UIView()
        anchor = v
        XCTAssertNotNil(anchor)
    }

    /// MEASURED `sourceItem.view` / `sourceView.view` / `barButtonItem.prop`
    /// / `sourceItem.barButton`: the two view stores are separate; the bar
    /// button stores mirror each other.
    func testSourceItemStoresMirrorLikeUIKit() {
        let (_, pop) = popoverVC()
        let v = UIView()
        let item = UIBarButtonItem(title: "More", style: .plain, target: nil, action: nil)
        pop.sourceItem = v
        XCTAssertTrue((pop.sourceItem as AnyObject?) === v)
        XCTAssertNil(pop.sourceView)
        XCTAssertNil(pop.barButtonItem)
        pop.sourceItem = item
        XCTAssertTrue(pop.barButtonItem === item)
        XCTAssertTrue((pop.sourceItem as AnyObject?) === item)
        pop.sourceItem = nil
        XCTAssertNil(pop.barButtonItem)
        pop.barButtonItem = item
        XCTAssertTrue((pop.sourceItem as AnyObject?) === item)
        pop.barButtonItem = nil
        XCTAssertNil(pop.sourceItem)
        pop.sourceView = v
        XCTAssertNil(pop.sourceItem)
        XCTAssertTrue(pop.sourceView === v)
    }

    /// MEASURED base rows: `frame(in:)` for a view in a window, a detached
    /// view, a layout guide, and a bar button in no bar.
    func testFrameInReferenceView() {
        let (window, base, _) = pad()
        let anchor = UIView(frame: CGRect(x: 100, y: 300, width: 60, height: 40))
        base.view.addSubview(anchor)
        window.layoutIfNeeded()
        XCTAssertEqual(anchor.frame(in: window), CGRect(x: 100, y: 300, width: 60, height: 40))
        XCTAssertEqual(anchor.frame(in: anchor), CGRect(x: 0, y: 0, width: 60, height: 40))
        XCTAssertEqual(UIView(frame: CGRect(x: 1, y: 2, width: 3, height: 4)).frame(in: window),
                       CGRect(x: 1, y: 2, width: 3, height: 4))
        let guide = UILayoutGuide()
        base.view.addLayoutGuide(guide)
        NSLayoutConstraint.activate([
            guide.leadingAnchor.constraint(equalTo: base.view.leadingAnchor, constant: 10),
            guide.topAnchor.constraint(equalTo: base.view.topAnchor, constant: 400),
            guide.widthAnchor.constraint(equalToConstant: 50),
            guide.heightAnchor.constraint(equalToConstant: 30),
        ])
        base.view.layoutIfNeeded()
        XCTAssertEqual(guide.frame(in: window), CGRect(x: 10, y: 400, width: 50, height: 30))
        let loose = UIBarButtonItem(title: "X", style: .plain, target: nil, action: nil)
        XCTAssertEqual(loose.frame(in: window), .zero, "MEASURED: zero, not nil")
    }

    /// MEASURED `sourceItem.view`: `[160, 230, 253, 180]`, arrow .left —
    /// x = view.maxX, width + 13, centred on the view's midY.
    func testViewSourceItemPlacesToTheRightWithLeftArrow() {
        let (window, base, _) = pad()
        let anchor = UIView(frame: CGRect(x: 100, y: 300, width: 60, height: 40))
        base.view.addSubview(anchor)
        window.layoutIfNeeded()
        let (vc, pop) = popoverVC()
        pop.sourceItem = anchor
        base.present(vc, animated: false)
        XCTAssertEqual(pop.adaptedStyle, .popover)
        XCTAssertEqual(vc.view.frame, CGRect(x: 160, y: 230, width: 253, height: 180))
        XCTAssertEqual(pop.arrowDirection, .left)
        XCTAssertNil(pop.sourceView)
        vc.dismiss(animated: false)

        // MEASURED `sourceView.view`: the old spelling lands the same frame.
        let (vc2, pop2) = popoverVC()
        pop2.sourceView = anchor
        base.present(vc2, animated: false)
        XCTAssertEqual(vc2.view.frame, CGRect(x: 160, y: 230, width: 253, height: 180))
        XCTAssertEqual(pop2.arrowDirection, .left)
        vc2.dismiss(animated: false)

        // MEASURED `sourceItem.lowView` (y 980): `[160, 910, 253, 180]`.
        let low = UIView(frame: CGRect(x: 100, y: 980, width: 60, height: 40))
        base.view.addSubview(low)
        let (vc3, pop3) = popoverVC()
        pop3.sourceItem = low
        base.present(vc3, animated: false)
        XCTAssertEqual(vc3.view.frame, CGRect(x: 160, y: 910, width: 253, height: 180))
        XCTAssertEqual(pop3.arrowDirection, .left)
    }

    /// MEASURED `sourceItem.view.rect` and `sourceView.view.rect`:
    /// sourceRect (0, 0, 10, 10) → `[110, 215, 253, 180]` for both spellings.
    func testSourceRectAppliesToSourceItemViews() {
        let (window, base, _) = pad()
        let anchor = UIView(frame: CGRect(x: 100, y: 300, width: 60, height: 40))
        base.view.addSubview(anchor)
        window.layoutIfNeeded()
        let (vc, pop) = popoverVC()
        pop.sourceItem = anchor
        pop.sourceRect = CGRect(x: 0, y: 0, width: 10, height: 10)
        base.present(vc, animated: false)
        XCTAssertEqual(vc.view.frame, CGRect(x: 110, y: 215, width: 253, height: 180))
        vc.dismiss(animated: false)
        let (vc2, pop2) = popoverVC()
        pop2.sourceView = anchor
        pop2.sourceRect = CGRect(x: 0, y: 0, width: 10, height: 10)
        base.present(vc2, animated: false)
        XCTAssertEqual(vc2.view.frame, CGRect(x: 110, y: 215, width: 253, height: 180))
    }

    /// MEASURED `sourceItem.view.arrowsDown`: `[19, 107, 240, 193]`, .down —
    /// height + 13, maxY = view.minY, x clamped to the 19 pt margin.
    func testPermittedDownClampsAndGrowsHeight() {
        let (window, base, _) = pad()
        let anchor = UIView(frame: CGRect(x: 100, y: 300, width: 60, height: 40))
        base.view.addSubview(anchor)
        window.layoutIfNeeded()
        let (vc, pop) = popoverVC()
        pop.sourceItem = anchor
        pop.permittedArrowDirections = .down
        base.present(vc, animated: false)
        XCTAssertEqual(vc.view.frame, CGRect(x: 19, y: 107, width: 240, height: 193))
        XCTAssertEqual(pop.arrowDirection, .down)
    }

    /// MEASURED `sourceItem.barButton` `[561, 62, 240, 180]` and
    /// `sourceItem.barButton.left` `[19, 62, 240, 180]`: no arrow (raw 0),
    /// y = SA.top + 30, centred on the item and clamped to the margin;
    /// `.arrowsDown` on a bar button changes nothing.
    func testBarButtonSourceItemHasNoArrowAndClamps() {
        let (window, base, nav) = pad()
        let right = UIBarButtonItem(title: "More", style: .plain, target: nil, action: nil)
        let left = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        base.navigationItem.rightBarButtonItem = right
        base.navigationItem.leftBarButtonItem = left
        base.title = "Probe"
        window.layoutIfNeeded()
        nav.navigationBar.layoutIfNeeded()
        let rf = try! XCTUnwrap(right.frame(in: window))
        XCTAssertGreaterThan(rf.width, 0, "the item is laid out in the bar")
        XCTAssertGreaterThan(rf.midX, 653.75, "centred on the item would overshoot → clamp")
        let lf = try! XCTUnwrap(left.frame(in: window))
        XCTAssertLessThan(lf.midX, 139, "centred on the item would undershoot → clamp")

        let (vc, pop) = popoverVC()
        pop.sourceItem = right
        pop.permittedArrowDirections = .down
        base.present(vc, animated: false)
        XCTAssertEqual(vc.view.frame, CGRect(x: 561, y: 62, width: 240, height: 180))
        XCTAssertEqual(pop.arrowDirection.rawValue, 0)
        XCTAssertTrue(pop.barButtonItem === right)
        vc.dismiss(animated: false)

        let (vc2, pop2) = popoverVC()
        pop2.sourceItem = left
        base.present(vc2, animated: false)
        XCTAssertEqual(vc2.view.frame, CGRect(x: 19, y: 62, width: 240, height: 180))
        XCTAssertEqual(pop2.arrowDirection.rawValue, 0)
    }

    /// MEASURED `sourceItem.tabItem`: arrow .down, height 193, width 240,
    /// maxY = the item's minY, centred on the item's midX.
    func testTabBarItemSourceItem() {
        let (window, base, _) = pad()
        let bar = UITabBar(frame: CGRect(x: 0, y: 1097, width: 820, height: 64))
        let one = UITabBarItem(title: "One", image: nil, tag: 1)
        let two = UITabBarItem(title: "Two", image: nil, tag: 2)
        bar.items = [one, two]
        base.view.addSubview(bar)
        window.layoutIfNeeded()
        bar.layoutIfNeeded()
        let itemFrame = try! XCTUnwrap(two.frame(in: window))
        XCTAssertGreaterThan(itemFrame.width, 0)
        let (vc, pop) = popoverVC()
        pop.sourceItem = two
        base.present(vc, animated: false)
        XCTAssertEqual(pop.arrowDirection, .down)
        XCTAssertEqual(vc.view.frame.size, CGSize(width: 240, height: 193))
        XCTAssertEqual(vc.view.frame.maxY, itemFrame.minY, accuracy: 1e-9)
        XCTAssertEqual(vc.view.frame.midX, itemFrame.midX, accuracy: 1e-9)
    }

    /// MEASURED iPhone 16 (`ios-26.1-iphone16-popover.json`): every source
    /// kind adapts to the full-height sheet, `arrowDirection` stays
    /// `.unknown`, and `adaptiveSheetPresentationController.detents =
    /// [.medium()]` (WordPress) yields the medium sheet, whose drop shadow
    /// view is `[8, 403.687, 377, 440.313]`.
    func testCompactWidthAdaptsAndMediumDetentFlows() {
        UIDevice.current.userInterfaceIdiom = .phone
        UITraitCollection.current = UITraitCollection(
            userInterfaceStyle: .light, displayScale: 3, userInterfaceIdiom: .phone)
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852), scale: 3)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window._setSafeAreaInsets(UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0))
        let base = UIViewController()
        window.rootViewController = base
        window.makeKeyAndVisible()
        let anchor = UIView(frame: CGRect(x: 100, y: 300, width: 60, height: 40))
        base.view.addSubview(anchor)

        let (vc, pop) = popoverVC()
        pop.sourceItem = anchor
        XCTAssertEqual(pop.adaptedStyle, .pageSheet)
        base.present(vc, animated: false)
        XCTAssertTrue(vc.presentationController is UISheetPresentationController)
        XCTAssertEqual(vc._presentationSheet?.frame, CGRect(x: 0, y: 59, width: 393, height: 793))
        XCTAssertEqual(pop.arrowDirection, .unknown)
        vc.dismiss(animated: false)

        let (vc2, pop2) = popoverVC()
        pop2.sourceItem = anchor
        pop2.adaptiveSheetPresentationController.detents = [.medium()]
        XCTAssertTrue(pop2.adaptiveSheetPresentationController === vc2._sheetController)
        base.present(vc2, animated: false)
        XCTAssertTrue(vc2.presentationController === vc2._sheetController)
        let mf = try! XCTUnwrap(vc2._presentationSheet?.frame)
        XCTAssertEqual(mf.height, 440.313, accuracy: 0.001)
        XCTAssertEqual(mf.minY, 403.687, accuracy: 0.001)
        XCTAssertEqual(mf.minX, 8, accuracy: 0.001)
        XCTAssertEqual(mf.width, 377, accuracy: 0.001)
    }
}
