// Real iOS 26.1 oracle for the WordPress-iOS §9.6 rows `UITextItem` and
// `UIPopoverPresentationControllerSourceItem`.
// Run scripts/wordpress_rows_probe_sim.sh <outdir> (PHASE=textitem|popover,
// KIND=iphone|ipad). The touch synthesizer is swipeprobe's.
import UIKit
import Darwin

var logLines: [String] = []
func probeLog(_ s: String) {
    logLines.append(s)
    print(s)
    fflush(stdout)
}

let rawMsgSend = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "objc_msgSend")!
typealias MsgSendPointBool = @convention(c) (AnyObject, Selector, CGPoint, Bool) -> Void
typealias MsgSendInt = @convention(c) (AnyObject, Selector, Int) -> Void
typealias MsgSendDouble = @convention(c) (AnyObject, Selector, Double) -> Void
typealias MsgSendBool = @convention(c) (AnyObject, Selector, Bool) -> Void
typealias MsgSendObjBool = @convention(c) (AnyObject, Selector, AnyObject?, Bool) -> Void
typealias MsgSendVoid = @convention(c) (AnyObject, Selector) -> Void
typealias MsgSendRetObj = @convention(c) (AnyObject, Selector) -> Unmanaged<AnyObject>?

func r(_ f: CGRect) -> [Any] {
    // CGRect.null (the default sourceRect) is infinite; JSON has no infinity.
    [Double(f.origin.x), Double(f.origin.y), Double(f.width), Double(f.height)].map { v -> Any in
        v.isFinite ? ((v * 1000).rounded() / 1000) as Any : "\(v)" as Any
    }
}
func rangeArr(_ n: NSRange) -> [Int] { [n.location, n.length] }

// MARK: - JSON transcript (rewritten after every case)

var transcript: [String: Any] = [:]
var caseOrder: [String] = []
func record(_ name: String, _ value: [String: Any]) {
    transcript[name] = value
    caseOrder.append(name)
    transcript["_order"] = caseOrder
    writeTranscript()
}
func writeTranscript() {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let phase = ProcessInfo.processInfo.environment["PROBE_PHASE"] ?? CommandLine.arguments.dropFirst().first ?? "textitem"
    let url = docs.appendingPathComponent("wordpressrows-\(phase).json")
    if let data = try? JSONSerialization.data(withJSONObject: transcript, options: [.prettyPrinted, .sortedKeys]) {
        try? data.write(to: url)
    }
}

// MARK: - Touch synthesizer (swipeprobe's, single touch)

final class TouchSynth {
    let window: UIWindow
    var touch: NSObject
    init(window: UIWindow) {
        self.window = window
        let cls = NSClassFromString("UITouch") as! NSObject.Type
        touch = cls.init()
    }
    func touchesEvent() -> NSObject? {
        let app = UIApplication.shared
        let sel = NSSelectorFromString("_touchesEvent")
        guard app.responds(to: sel) else { return nil }
        let f = unsafeBitCast(rawMsgSend, to: MsgSendRetObj.self)
        return f(app, sel)?.takeUnretainedValue() as? NSObject
    }
    func phaseValue(_ p: UITouch.Phase) -> Int {
        switch p {
        case .began: return 0
        case .moved: return 1
        case .stationary: return 2
        case .ended: return 3
        case .cancelled: return 4
        default: return 0
        }
    }
    func send(_ phase: UITouch.Phase, at point: CGPoint, timestamp: Double, first: Bool) {
        let setInt = unsafeBitCast(rawMsgSend, to: MsgSendInt.self)
        let setDouble = unsafeBitCast(rawMsgSend, to: MsgSendDouble.self)
        let setObjBool = unsafeBitCast(rawMsgSend, to: MsgSendObjBool.self)
        let call = unsafeBitCast(rawMsgSend, to: MsgSendVoid.self)
        let setObj = unsafeBitCast(rawMsgSend, to: (@convention(c) (AnyObject, Selector, AnyObject?) -> Void).self)
        let setBool = unsafeBitCast(rawMsgSend, to: MsgSendBool.self)
        let setPointBool = unsafeBitCast(rawMsgSend, to: MsgSendPointBool.self)
        guard let ev = touchesEvent() else { return }
        call(ev, NSSelectorFromString("_clearTouches"))
        if ev.responds(to: NSSelectorFromString("_setTimestamp:")) {
            setDouble(ev, NSSelectorFromString("_setTimestamp:"), timestamp)
        }
        let t = touch
        if first {
            let cls = NSClassFromString("UITouch") as! NSObject.Type
            touch = cls.init()
            let t2 = touch
            setObj(t2, NSSelectorFromString("setWindow:"), window)
            let view = window.hitTest(point, with: nil) ?? window
            setObj(t2, NSSelectorFromString("setView:"), view)
            setInt(t2, NSSelectorFromString("setTapCount:"), 1)
            if t2.responds(to: NSSelectorFromString("_setIsFirstTouchForView:")) {
                setBool(t2, NSSelectorFromString("_setIsFirstTouchForView:"), true)
            }
            if t2.responds(to: NSSelectorFromString("_setSenderID:")) {
                let f = unsafeBitCast(rawMsgSend, to: (@convention(c) (AnyObject, Selector, UInt64) -> Void).self)
                f(t2, NSSelectorFromString("_setSenderID:"), 0x0ACE_FADE_0000_0002)
            }
            setPointBool(t2, NSSelectorFromString("_setLocationInWindow:resetPrevious:"), point, true)
            setInt(t2, NSSelectorFromString("setPhase:"), phaseValue(phase))
            setDouble(t2, NSSelectorFromString("setTimestamp:"), timestamp)
            setObjBool(ev, NSSelectorFromString("_addTouch:forDelayedDelivery:"), t2, false)
        } else {
            setPointBool(t, NSSelectorFromString("_setLocationInWindow:resetPrevious:"), point, false)
            setInt(t, NSSelectorFromString("setPhase:"), phaseValue(phase))
            setDouble(t, NSSelectorFromString("setTimestamp:"), timestamp)
            setObjBool(ev, NSSelectorFromString("_addTouch:forDelayedDelivery:"), t, false)
        }
        UIApplication.shared.sendEvent(ev as! UIEvent)
    }
}

// MARK: - UITextItem phase

var openedURLs: [String] = []

func describeItem(_ item: UITextItem) -> [String: Any] {
    var d: [String: Any] = ["range": rangeArr(item.range), "class": NSStringFromClass(type(of: item))]
    switch item.content {
    case .link(let u): d["content"] = "link"; d["link"] = u.absoluteString
    case .textAttachment(let a): d["content"] = "textAttachment"; d["attachmentClass"] = NSStringFromClass(type(of: a))
    case .tag(let s): d["content"] = "tag"; d["tag"] = s
    @unknown default: d["content"] = "unknown"
    }
    return d
}
func describeAction(_ a: UIAction) -> [String: Any] {
    ["title": a.title, "identifier": a.identifier.rawValue, "attributes": a.attributes.rawValue,
     "image": a.image == nil ? "nil" : "set", "subtitle": a.subtitle ?? "nil", "class": NSStringFromClass(type(of: a))]
}
func describeMenu(_ m: UIMenu) -> [String: Any] {
    func el(_ e: UIMenuElement) -> [String: Any] {
        if let a = e as? UIAction { return describeAction(a) }
        if let m = e as? UIMenu { return describeMenu(m) }
        return ["title": e.title, "class": NSStringFromClass(type(of: e))]
    }
    return ["title": m.title, "identifier": m.identifier.rawValue, "options": m.options.rawValue,
            "children": m.children.map(el), "class": NSStringFromClass(type(of: m))]
}

/// Delegate variants. `mode` picks which selectors respond.
final class TextDelegate: NSObject, UITextViewDelegate {
    enum Mode { case new, old, both, none }
    let mode: Mode
    var primaryReturn: String = "default"   // "default" | "nil" | "custom"
    var menuReturn: String = "default"      // "default" | "nil" | "customMenu"
    var events: [[String: Any]] = []
    init(mode: Mode) { self.mode = mode }

    override func responds(to aSelector: Selector!) -> Bool {
        let name = NSStringFromSelector(aSelector)
        let isNew = name.contains("primaryActionForTextItem") || name.contains("menuConfigurationForTextItem")
            || name.contains("textItemMenuWillDisplay") || name.contains("textItemMenuWillEnd")
        let isOld = name.contains("shouldInteractWithURL") || name.contains("shouldInteractWithTextAttachment")
        if isNew { return mode == .new || mode == .both }
        if isOld { return mode == .old || mode == .both }
        return super.responds(to: aSelector)
    }

    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        events.append(["call": "primaryActionFor", "item": describeItem(textItem), "defaultAction": describeAction(defaultAction)])
        switch primaryReturn {
        case "nil": return nil
        case "custom":
            return UIAction(title: "Custom") { [weak self] _ in self?.events.append(["call": "customActionFired"]) }
        default: return defaultAction
        }
    }
    func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
        events.append(["call": "menuConfigurationFor", "item": describeItem(textItem), "defaultMenu": describeMenu(defaultMenu)])
        switch menuReturn {
        case "nil": return nil
        case "customMenu":
            return UITextItem.MenuConfiguration(menu: UIMenu(title: "Mine", children: [UIAction(title: "One") { _ in }]))
        default: return UITextItem.MenuConfiguration(menu: defaultMenu)
        }
    }
    func textView(_ textView: UITextView, textItemMenuWillDisplayFor textItem: UITextItem, animator: any UIContextMenuInteractionAnimating) {
        events.append(["call": "textItemMenuWillDisplay", "item": describeItem(textItem)])
    }
    func textView(_ textView: UITextView, textItemMenuWillEndFor textItem: UITextItem, animator: any UIContextMenuInteractionAnimating) {
        events.append(["call": "textItemMenuWillEnd", "item": describeItem(textItem)])
    }
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        events.append(["call": "shouldInteractWithURL", "url": URL.absoluteString, "range": rangeArr(characterRange), "interaction": interaction.rawValue])
        return true
    }
    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        events.append(["call": "shouldInteractWithAttachment", "range": rangeArr(characterRange), "interaction": interaction.rawValue])
        return true
    }
}

final class TextItemPhase {
    let window: UIWindow
    let synth: TouchSynth
    var cases: [(String, () -> Void)] = []
    var textView: UITextView?
    var delegate: TextDelegate?
    let linkURL = URL(string: "wpprobe://open?item=link")!
    let httpsURL = URL(string: "https://example.com/apple")!
    // "Read Apple or #tag here X end": link "Apple" (5..10), tag "tagword", attachment U+FFFC.
    var linkRange = NSRange(), tagRange = NSRange(), attRange = NSRange(), httpsRange = NSRange()

    init(window: UIWindow) {
        self.window = window
        synth = TouchSynth(window: window)
    }

    func makeAttributed() -> NSAttributedString {
        let s = NSMutableAttributedString(string: "Read ", attributes: [.font: UIFont.systemFont(ofSize: 17)])
        linkRange = NSRange(location: s.length, length: 5)
        s.append(NSAttributedString(string: "Apple", attributes: [.font: UIFont.systemFont(ofSize: 17), .link: linkURL]))
        s.append(NSAttributedString(string: " or ", attributes: [.font: UIFont.systemFont(ofSize: 17)]))
        tagRange = NSRange(location: s.length, length: 7)
        s.append(NSAttributedString(string: "tagword", attributes: [.font: UIFont.systemFont(ofSize: 17), .textItemTag: "wp-tag"]))
        s.append(NSAttributedString(string: " here ", attributes: [.font: UIFont.systemFont(ofSize: 17)]))
        let att = NSTextAttachment()
        let img = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { ctx in
            UIColor.systemRed.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }
        att.image = img
        att.bounds = CGRect(x: 0, y: -4, width: 24, height: 24)
        attRange = NSRange(location: s.length, length: 1)
        s.append(NSAttributedString(attachment: att))
        s.append(NSAttributedString(string: " end ", attributes: [.font: UIFont.systemFont(ofSize: 17)]))
        httpsRange = NSRange(location: s.length, length: 3)
        s.append(NSAttributedString(string: "web", attributes: [.font: UIFont.systemFont(ofSize: 17), .link: httpsURL]))
        return s
    }

    func install(mode: TextDelegate.Mode?, editable: Bool = false, selectable: Bool = true) -> (UITextView, TextDelegate?) {
        textView?.removeFromSuperview()
        let tv = UITextView(frame: CGRect(x: 20, y: 200, width: 353, height: 120))
        tv.attributedText = makeAttributed()
        tv.isEditable = editable
        tv.isSelectable = selectable
        tv.backgroundColor = .white
        window.rootViewController!.view.addSubview(tv)
        var d: TextDelegate?
        if let mode { d = TextDelegate(mode: mode); tv.delegate = d }
        textView = tv
        delegate = d
        tv.layoutIfNeeded()
        return (tv, d)
    }

    func rect(of range: NSRange, in tv: UITextView) -> CGRect {
        let g = tv.layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var r = tv.layoutManager.boundingRect(forGlyphRange: g, in: tv.textContainer)
        r.origin.x += tv.textContainerInset.left
        r.origin.y += tv.textContainerInset.top
        return tv.convert(r, to: window)
    }

    func tap(_ p: CGPoint, then: @escaping () -> Void) {
        let t0 = ProcessInfo.processInfo.systemUptime
        synth.send(.began, at: p, timestamp: t0, first: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            self.synth.send(.ended, at: p, timestamp: t0 + 0.06, first: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: then)
        }
    }
    func longPress(_ p: CGPoint, hold: Double = 0.9, then: @escaping () -> Void) {
        let t0 = ProcessInfo.processInfo.systemUptime
        synth.send(.began, at: p, timestamp: t0, first: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            self.synth.send(.ended, at: p, timestamp: t0 + hold, first: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: then)
        }
    }

    func windowTree() -> [String] {
        var out: [String] = []
        func walk(_ v: UIView, _ depth: Int) {
            if depth > 3 { return }
            out.append("\(String(repeating: " ", count: depth))\(NSStringFromClass(type(of: v))) \(r(v.frame))")
            for s in v.subviews { walk(s, depth + 1) }
        }
        for w in UIApplication.shared.windows { walk(w, 0) }
        return out
    }

    func run(_ done: @escaping () -> Void) {
        let (tv0, _) = install(mode: nil)
        let base: [String: Any] = [
            "linkRange": rangeArr(linkRange), "tagRange": rangeArr(tagRange), "attRange": rangeArr(attRange), "httpsRange": rangeArr(httpsRange),
            "linkRectWin": r(rect(of: linkRange, in: tv0)), "tagRectWin": r(rect(of: tagRange, in: tv0)), "attRectWin": r(rect(of: attRange, in: tv0)),
            "linkTextAttributesDefault": tv0.linkTextAttributes.map { "\($0.key.rawValue)=\($0.value)" }.sorted(),
            "textItemTagKey": NSAttributedString.Key.textItemTag.rawValue,
            "gestureRecognizers": (tv0.gestureRecognizers ?? []).map { NSStringFromClass(type(of: $0)) },
            "interactions": tv0.interactions.map { NSStringFromClass(type(of: $0)) },
            "attributedReadback": (tv0.attributedText.attribute(.textItemTag, at: tagRange.location, effectiveRange: nil) as? String) ?? "nil",
        ]
        record("base", base)

        func caseTap(_ name: String, mode: TextDelegate.Mode?, primary: String = "default", menu: String = "default",
                     editable: Bool = false, selectable: Bool = true, range: NSRange? = nil, press: Bool = false,
                     extra: ((UITextView) -> [String: Any])? = nil) {
            cases.append((name, {
                let (tv, d) = self.install(mode: mode, editable: editable, selectable: selectable)
                d?.primaryReturn = primary
                d?.menuReturn = menu
                openedURLs = []
                let rg = range ?? self.linkRange
                let rr = self.rect(of: rg, in: tv)
                let p = CGPoint(x: rr.midX, y: rr.midY)
                let finish = {
                    var out: [String: Any] = [
                        "mode": mode.map { "\($0)" } ?? "noDelegate", "primaryReturn": primary, "menuReturn": menu,
                        "editable": editable, "selectable": selectable, "point": [p.x, p.y],
                        "events": d?.events ?? [], "openedURLs": openedURLs,
                        "selectedRange": rangeArr(tv.selectedRange), "isFirstResponder": tv.isFirstResponder,
                        "windowTree": self.windowTree(),
                    ]
                    if let extra { out.merge(extra(tv)) { a, _ in a } }
                    record(name, out)
                    // Put away any menu/first responder before the next case.
                    tv.resignFirstResponder()
                    self.window.rootViewController?.dismiss(animated: false)
                    self.next()
                }
                if press { self.longPress(p, then: finish) } else { self.tap(p, then: finish) }
            }))
        }
        caseTap("tap.link.new.default", mode: .new)
        caseTap("tap.link.new.nil", mode: .new, primary: "nil")
        caseTap("tap.link.new.custom", mode: .new, primary: "custom")
        caseTap("tap.link.old", mode: .old)
        caseTap("tap.link.both", mode: .both)
        caseTap("tap.link.noDelegate", mode: nil)
        caseTap("tap.link.noneImplemented", mode: TextDelegate.Mode.none)
        cases.append(("tap.tag.new", { self.tapRange(name: "tap.tag.new", mode: .new, which: "tag") }))
        cases.append(("tap.tag.both", { self.tapRange(name: "tap.tag.both", mode: .both, which: "tag") }))
        cases.append(("tap.attachment.new", { self.tapRange(name: "tap.attachment.new", mode: .new, which: "att") }))
        cases.append(("tap.attachment.both", { self.tapRange(name: "tap.attachment.both", mode: .both, which: "att") }))
        cases.append(("tap.plain.new", { self.tapRange(name: "tap.plain.new", mode: .new, which: "plain") }))
        caseTap("tap.link.new.notSelectable", mode: .new, selectable: false)
        caseTap("tap.link.new.editable", mode: .new, editable: true)
        caseTap("press.link.new.default", mode: .new, press: true)
        caseTap("press.link.new.nilMenu", mode: .new, menu: "nil", press: true)
        caseTap("press.link.both", mode: .both, press: true)
        cases.append(("press.tag.new", { self.tapRange(name: "press.tag.new", mode: .new, which: "tag", press: true) }))
        cases.append(("press.attachment.new", { self.tapRange(name: "press.attachment.new", mode: .new, which: "att", press: true) }))
        onDone = done
        next()
    }

    var onDone: (() -> Void)?
    func tapRange(name: String, mode: TextDelegate.Mode, which: String, press: Bool = false) {
        let (tv, d) = install(mode: mode)
        openedURLs = []
        let rg: NSRange
        switch which {
        case "tag": rg = tagRange
        case "att": rg = attRange
        default: rg = NSRange(location: 1, length: 2)
        }
        let rr = rect(of: rg, in: tv)
        let p = CGPoint(x: rr.midX, y: rr.midY)
        let finish = {
            record(name, [
                "mode": "\(mode)", "which": which, "point": [p.x, p.y], "events": d?.events ?? [], "openedURLs": openedURLs,
                "selectedRange": rangeArr(tv.selectedRange), "isFirstResponder": tv.isFirstResponder, "windowTree": self.windowTree(),
            ])
            tv.resignFirstResponder()
            self.window.rootViewController?.dismiss(animated: false)
            self.next()
        }
        if press { longPress(p, then: finish) } else { tap(p, then: finish) }
    }

    func next() {
        guard !cases.isEmpty else { onDone?(); return }
        let c = cases.removeFirst()
        probeLog("case \(c.0)")
        // Dismiss any context menu left over from a long press by tapping empty space.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { c.1() }
    }
}

// MARK: - Popover phase

final class PopoverPhase {
    let window: UIWindow
    let nav: UINavigationController
    let root = UIViewController()
    let anchorView = UIView(frame: CGRect(x: 100, y: 300, width: 60, height: 40))
    let lowView = UIView(frame: CGRect(x: 100, y: 0, width: 60, height: 40))
    let tabBar = UITabBar()
    let rightItem = UIBarButtonItem(title: "More", style: .plain, target: nil, action: nil)
    let leftItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
    let tabItem1 = UITabBarItem(title: "One", image: nil, tag: 1)
    let tabItem2 = UITabBarItem(title: "Two", image: nil, tag: 2)
    var cases: [(String, () -> Void)] = []
    var onDone: (() -> Void)?

    init(window: UIWindow) {
        self.window = window
        nav = UINavigationController(rootViewController: root)
        window.rootViewController = nav
        root.view.backgroundColor = .white
        root.navigationItem.rightBarButtonItem = rightItem
        root.navigationItem.leftBarButtonItem = leftItem
        root.title = "Probe"
        anchorView.backgroundColor = .systemBlue
        root.view.addSubview(anchorView)
        lowView.backgroundColor = .systemGreen
        root.view.addSubview(lowView)
        tabBar.items = [tabItem1, tabItem2]
        root.view.addSubview(tabBar)
        window.makeKeyAndVisible()
        root.view.layoutIfNeeded()
        let b = root.view.bounds
        lowView.frame.origin.y = b.height - 200
        tabBar.frame = CGRect(x: 0, y: b.height - 83, width: b.width, height: 83)
        root.view.layoutIfNeeded()
    }

    func ancestors(_ v: UIView) -> [[String: Any]] {
        var out: [[String: Any]] = []
        var cur: UIView? = v
        while let c = cur {
            out.append(["class": NSStringFromClass(type(of: c)), "frame": r(c.frame),
                        "subviews": c.subviews.map { "\(NSStringFromClass(type(of: $0))) \(r($0.frame))" }])
            cur = c.superview
        }
        return out
    }

    func present(_ name: String, size: CGSize = CGSize(width: 240, height: 180),
                 configure: @escaping (UIPopoverPresentationController) -> [String: Any]) {
        cases.append((name, {
            let vc = UIViewController()
            vc.view.backgroundColor = .white
            vc.preferredContentSize = size
            vc.modalPresentationStyle = .popover
            guard let pop = vc.popoverPresentationController else { record(name, ["error": "no popoverPresentationController"]); self.next(); return }
            var before = configure(pop)
            before["sourceItem.pre"] = pop.sourceItem.map { NSStringFromClass(type(of: $0 as AnyObject)) } ?? "nil"
            before["sourceView.pre"] = pop.sourceView.map { NSStringFromClass(type(of: $0)) } ?? "nil"
            before["barButtonItem.pre"] = pop.barButtonItem == nil ? "nil" : "set"
            before["sourceRect.pre"] = r(pop.sourceRect)
            before["sourceRect.pre.isNull"] = pop.sourceRect.isNull
            before["permittedArrowDirections.pre"] = pop.permittedArrowDirections.rawValue
            before["arrowDirection.pre"] = pop.arrowDirection.rawValue
            self.root.present(vc, animated: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                var out = before
                out["presentationControllerClass"] = vc.presentationController.map { NSStringFromClass(type(of: $0)) } ?? "nil"
                out["adaptivePresentationStyle"] = vc.presentationController?.adaptivePresentationStyle.rawValue ?? -99
                out["presentedView.frameInWindow"] = r(vc.view.convert(vc.view.bounds, to: nil))
                out["presentedView.frame"] = r(vc.view.frame)
                out["ancestors"] = self.ancestors(vc.view)
                out["arrowDirection.post"] = pop.arrowDirection.rawValue
                out["sourceRect.post"] = r(pop.sourceRect)
                out["sourceView.post"] = pop.sourceView.map { NSStringFromClass(type(of: $0)) } ?? "nil"
                out["sourceView.post.isAnchor"] = pop.sourceView === self.anchorView
                out["barButtonItem.post"] = pop.barButtonItem === self.rightItem ? "rightItem" : (pop.barButtonItem == nil ? "nil" : "other")
                out["sourceItem.post"] = pop.sourceItem.map { NSStringFromClass(type(of: $0 as AnyObject)) } ?? "nil"
                out["sourceItem.post.isRightItem"] = (pop.sourceItem as AnyObject?) === self.rightItem
                out["sourceItem.post.isAnchor"] = (pop.sourceItem as AnyObject?) === self.anchorView
                out["containerView.frame"] = pop.containerView.map { r($0.frame) } ?? []
                out["presentedView.class"] = pop.presentedView.map { NSStringFromClass(type(of: $0)) } ?? "nil"
                out["presentedView.frameProp"] = pop.presentedView.map { r($0.frame) } ?? []
                out["adaptiveSheet.detents"] = pop.adaptiveSheetPresentationController.detents.map { "\($0)" }
                out["adaptiveSheet.class"] = NSStringFromClass(type(of: pop.adaptiveSheetPresentationController))
                out["adaptiveSheet.selected"] = pop.adaptiveSheetPresentationController.selectedDetentIdentifier?.rawValue ?? "nil"
                out["windows"] = UIApplication.shared.windows.map { "\(NSStringFromClass(type(of: $0))) \(r($0.frame))" }
                out["horizontalSizeClass"] = self.root.traitCollection.horizontalSizeClass.rawValue
                vc.dismiss(animated: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    record(name, out)
                    self.next()
                }
            }
        }))
    }

    func run(_ done: @escaping () -> Void) {
        onDone = done
        let navBar = nav.navigationBar
        var base: [String: Any] = [
            "window": r(window.frame), "safeArea": [window.safeAreaInsets.top, window.safeAreaInsets.left, window.safeAreaInsets.bottom, window.safeAreaInsets.right],
            "navBar.frameInWindow": r(navBar.convert(navBar.bounds, to: nil)),
            "anchorView.frameInWindow": r(anchorView.convert(anchorView.bounds, to: nil)),
            "lowView.frameInWindow": r(lowView.convert(lowView.bounds, to: nil)),
            "tabBar.frameInWindow": r(tabBar.convert(tabBar.bounds, to: nil)),
            "idiom": UIDevice.current.userInterfaceIdiom.rawValue,
            "horizontalSizeClass": root.traitCollection.horizontalSizeClass.rawValue,
            "scale": UIScreen.main.scale,
        ]
        if #available(iOS 17.0, *) {
            base["anchorView.frameIn.window"] = anchorView.frame(in: window).map(r) ?? []
            base["anchorView.frameIn.root"] = anchorView.frame(in: root.view).map(r) ?? []
            base["anchorView.frameIn.self"] = anchorView.frame(in: anchorView).map(r) ?? []
            base["rightItem.frameIn.window"] = rightItem.frame(in: window).map(r) ?? []
            base["rightItem.frameIn.navBar"] = rightItem.frame(in: navBar).map(r) ?? []
            base["leftItem.frameIn.window"] = leftItem.frame(in: window).map(r) ?? []
            base["tabItem1.frameIn.window"] = tabItem1.frame(in: window).map(r) ?? []
            base["tabItem2.frameIn.window"] = tabItem2.frame(in: window).map(r) ?? []
            base["detachedItem.frameIn.window"] = UIBarButtonItem(title: "X", style: .plain, target: nil, action: nil).frame(in: window).map(r) ?? []
            base["detachedView.frameIn.window"] = UIView(frame: CGRect(x: 1, y: 2, width: 3, height: 4)).frame(in: window).map(r) ?? []
            let guide = UILayoutGuide()
            root.view.addLayoutGuide(guide)
            NSLayoutConstraint.activate([guide.leadingAnchor.constraint(equalTo: root.view.leadingAnchor, constant: 10),
                                         guide.topAnchor.constraint(equalTo: root.view.topAnchor, constant: 400),
                                         guide.widthAnchor.constraint(equalToConstant: 50), guide.heightAnchor.constraint(equalToConstant: 30)])
            root.view.layoutIfNeeded()
            base["layoutGuide.frameIn.window"] = guide.frame(in: window).map(r) ?? []
        }
        base["navBar.tree"] = navBar.subviews.map { "\(NSStringFromClass(type(of: $0))) \(r($0.frame))" }
        record("base", base)

        present("sourceItem.barButton") { pop in pop.sourceItem = self.rightItem; return [:] }
        present("sourceItem.barButton.left") { pop in pop.sourceItem = self.leftItem; return [:] }
        present("sourceItem.view") { pop in pop.sourceItem = self.anchorView; return [:] }
        present("sourceItem.lowView") { pop in pop.sourceItem = self.lowView; return [:] }
        present("sourceItem.tabItem") { pop in pop.sourceItem = self.tabItem2; return [:] }
        present("sourceView.view") { pop in pop.sourceView = self.anchorView; return [:] }
        present("sourceView.view.rect") { pop in pop.sourceView = self.anchorView; pop.sourceRect = CGRect(x: 0, y: 0, width: 10, height: 10); return [:] }
        present("sourceItem.view.rect") { pop in pop.sourceItem = self.anchorView; pop.sourceRect = CGRect(x: 0, y: 0, width: 10, height: 10); return [:] }
        present("barButtonItem.prop") { pop in pop.barButtonItem = self.rightItem; return [:] }
        present("sourceItem.barButton.arrowsDown") { pop in pop.sourceItem = self.rightItem; pop.permittedArrowDirections = .down; return [:] }
        present("sourceItem.view.arrowsLeft") { pop in pop.sourceItem = self.anchorView; pop.permittedArrowDirections = .left; return [:] }
        present("sourceItem.view.arrowsRight") { pop in pop.sourceItem = self.anchorView; pop.permittedArrowDirections = .right; return [:] }
        present("sourceItem.view.arrowsDown") { pop in pop.sourceItem = self.anchorView; pop.permittedArrowDirections = .down; return [:] }
        present("sourceItem.none") { _ in [:] }
        present("sourceItem.view.big", size: CGSize(width: 320, height: 600)) { pop in pop.sourceItem = self.anchorView; return [:] }
        present("sourceItem.view.mediumDetent") { pop in
            pop.sourceItem = self.anchorView
            pop.adaptiveSheetPresentationController.detents = [.medium()]
            return [:]
        }
        next()
    }

    func next() {
        guard !cases.isEmpty else { onDone?(); return }
        let c = cases.removeFirst()
        probeLog("case \(c.0)")
        c.1()
    }
}

// MARK: - App

final class ProbeDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var keep: AnyObject?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let phase = ProcessInfo.processInfo.environment["PROBE_PHASE"] ?? CommandLine.arguments.dropFirst().first ?? "textitem"
        let w = UIWindow(frame: UIScreen.main.bounds)
        window = w
        transcript["_device"] = ["bounds": r(UIScreen.main.bounds), "scale": UIScreen.main.scale,
                                 "system": UIDevice.current.systemVersion, "idiom": UIDevice.current.userInterfaceIdiom.rawValue,
                                 "phase": phase]
        if phase == "popover" {
            let p = PopoverPhase(window: w)
            keep = p
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                p.run { probeLog("done"); DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) } }
            }
        } else {
            let root = UIViewController()
            root.view.backgroundColor = .white
            w.rootViewController = root
            w.makeKeyAndVisible()
            let p = TextItemPhase(window: w)
            keep = p
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                p.run { probeLog("done"); DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) } }
            }
        }
        return true
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        openedURLs.append(url.absoluteString)
        probeLog("opened \(url)")
        return true
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(ProbeDelegate.self))
