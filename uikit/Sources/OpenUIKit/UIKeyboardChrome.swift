// iOS software-keyboard chrome. Owner: text-input / capture path.
//
// Real iOS puts the keyboard in a UITextEffectsWindow / UIRemoteKeyboardWindow
// above the app window. Confprobe's drawHierarchy of the app window is blank
// in that region (the keys live in a remote process); the port therefore
// draws a measured default alphabetic keyboard into its own window under the
// iOS cut and composites it above the app window at capture time.
//
// MEASURED /tmp/kb-se (kbprobe), iPhone SE 3rd gen 2x / iOS 26.1,
// field_white_light / field_black_light / field_red_light / field_gray_light
// / field_white_dark / field_black_dark / notes_white_light /
// search_white_light + field_anim_light. Status bar hidden, window 375×667.
//
//   keyboardWillShow frameEnd [0, 407, 375, 260]  (667 − 260 = 407)
//   duration 0.3833 s (= 23/60), curve 7 (maps to public easeInOut)
//   UITextEffectsWindow level 1, frame [0, 0, 375, 667]
//   UIKeyboardItemContainerView [0, 407, 375, 260]
//   _UIRemoteKeyboardPlaceholderView [4.5, 407, 366, 260]
//
// Panel (full-width, top corners only):
//   r = 26  (left edge at y=407 is 26 pt; y=418 left 5.0 vs r=26 → 4.76)
//   light mix  out = (1 − α)·B + α·T   α = 185/255
//     white → (226, 228, 232)  black → (156, 158, 161)
//     gray 128 → 192 (pred 191)  red residual reported, not fitted
//   dark mix   α = 212/255, α·T = 23
//     black → (23, 23, 23)  white → (66, 66, 67)
//
// Keys (panel-local y; window y = 407 + local):
//   QuickType 52 pt (empty: no suggestion ink; first letter row at y 459)
//   letter 30.5×42 r=7, h-gap 6, v-gap 12, left 8.5
//   row 1 y 459  QWERTYUIOP at xs 8.5/45/81.5/117.5/154/190.5/227/263.5/299.5/336
//   row 2 y 513  ASDFGHJKL  at xs 26.5 + 36.5·n
//   row 3 y 567  shift 41.5 @8.5, ZXCVBNM, delete 41.5 @325
//   row 4 y 621  123 39.5 / emoji 39.5 / mic 30.5 / space 139.5 / return 85
//   bottom pad 4  (621+42 = 663, 667−663 = 4)
//   letter caps 22 pt regular, ink (0,0,0) light / (255,255,255) dark,
//     Q ink bbox 12×17 centred in the 30.5×42 cap (label path)
//   "123" 16 pt regular, ink h 12.5
//   letter / special / space caps are the same fill: light (255,255,255),
//     dark (61,61,61)
//
//   iPhone 16 3x /tmp/kb-16 field_white_light: window 393×852, frameEnd
//     [0, 517, 393, 335] (335 = 260 + home-indicator band), same duration
//     0.3833 / curve 7 / windowLevel 1. Placeholder [4.667, 517, 384, 335].
//     Conformance apps run on the SE; this file draws the SE 260 pt layout.
//
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

@preconcurrency @MainActor
public enum _UIKeyboardChrome {
    /// SE default keyboard + QuickType. MEASURED Forms t1200 / kbprobe
    /// keyboardFrameEnd height, iPhone SE 2x / iOS 26.1.
    public static let overlap: CGFloat = 260
    /// Compact-height (SE landscapeLeft 667×375) alphabetic + QuickType.
    /// MEASURED Forms t1200.landscape golden (simctl shot rotated 90° CW),
    /// iPhone SE 2x / iOS 26.1: panel top y=169, 375−169=206; table
    /// `adjustedContentInset.bottom` **206**.
    public static let compactOverlap: CGFloat = 206
    /// Number pad has no QuickType. MEASURED kbstateprobe numberpad,
    /// iPhone SE 2x / iOS 26.1: frameEnd [0, 434, 375, 233].
    public static let numberPadOverlap: CGFloat = 233
    /// MEASURED keyboardWillShow duration 0.3833 s = 23/60.
    public static let presentDuration: Double = 23.0 / 60.0
    /// UITextEffectsWindow.windowLevel.rawValue.
    static let windowLevel = UIWindow.Level(1)

    /// Light panel: α = 185/255, T = (156, 158, 161)/185.
    /// MEASURED field_white_light / field_black_light interiors.
    static let lightMixAlpha: CGFloat = 185.0 / 255.0
    static let lightTint = (r: CGFloat(156) / 185, g: CGFloat(158) / 185,
                            b: CGFloat(161) / 185)
    /// Dark panel: α = 212/255, α·T = 23. MEASURED field_black_dark.
    static let darkMixAlpha: CGFloat = 212.0 / 255.0
    static let darkTint: CGFloat = 23.0 / 212.0

    static let panelRadius: CGFloat = 26
    static let quickTypeHeight: CGFloat = 52
    static let keyHeight: CGFloat = 42
    static let keyRadius: CGFloat = 7
    static let rowGap: CGFloat = 12
    static let letterFontSize: CGFloat = 22
    static let digitFontSize: CGFloat = 16

    private static var attached: _UIKeyboardWindow?

    static var isIOS: Bool { OpenUIKitRuntime.systemFontCut == .iOS }

    /// Height of the keyboard currently shown, or the SE alphabetic 260.
    /// Phone number pad is 233 (kbstateprobe numberpad). Pad docked
    /// alphabetic is 337 (kbstateprobe iPad has_text). Compact-height
    /// alphabetic is 206 (Forms t1200.landscape).
    public static var currentOverlap: CGFloat {
        attached?.panel.state.overlap ?? overlap
    }

    /// Show or hide the keyboard window for `window`'s first responder.
    static func sync(from window: UIWindow) {
        guard isIOS else {
            attached?.isHidden = true
            return
        }
        let responder = window.firstResponder
        let wants = responder is UIKeyInput
        if wants {
            let kb = ensureWindow(matching: window)
            kb.overrideUserInterfaceStyle = window.overrideUserInterfaceStyle
            kb.frame = window.bounds
            let appearing = kb.isHidden
            kb.isHidden = false
            kb.layoutKeyboard(animated: appearing, responder: responder)
        } else if let kb = attached, !kb.isHidden {
            kb.dismissAnimated()
        }
    }

    /// Composite the keyboard window above `app` when it is showing.
    public static func renderCapture(appWindow: UIWindow, scale: CGFloat) -> Bitmap {
        let base = UIRenderer.render(appWindow, scale: scale)
        guard isIOS,
              let kb = attached,
              !kb.isHidden,
              appWindow.firstResponder is UIKeyInput else { return base }
        kb.layoutKeyboard(animated: false, responder: appWindow.firstResponder)
        kb.layoutIfNeeded()
        let overlay = UIRenderer.render(kb, scale: scale)
        composite(overlay, over: base)
        return base
    }

    private static func ensureWindow(matching app: UIWindow) -> _UIKeyboardWindow {
        if let kb = attached {
            kb.frame = app.bounds
            return kb
        }
        let kb = _UIKeyboardWindow(frame: app.bounds)
        kb.windowLevel = windowLevel
        kb.isHidden = true
        attached = kb
        return kb
    }

    /// True when some app window (not the keyboard window) has a UIKeyInput
    /// first responder. Used so a field-to-field resign does not hide us.
    static func appHasKeyInputFocus() -> Bool {
        for w in UIApplication.shared.windows {
            if w is _UIKeyboardWindow { continue }
            if w.firstResponder is UIKeyInput { return true }
        }
        return false
    }

    /// Straight-alpha source-over. Keyboard panel is T@α; keys are opaque.
    public static func composite(_ src: Bitmap, over dst: Bitmap) {
        let n = Swift.min(src.width * src.height, dst.width * dst.height)
        var i = 0
        while i < n {
            let o = i * 4
            let sa = Int(src.pixels[o + 3])
            if sa == 0 {
                i += 1
                continue
            }
            if sa == 255 {
                dst.pixels[o] = src.pixels[o]
                dst.pixels[o + 1] = src.pixels[o + 1]
                dst.pixels[o + 2] = src.pixels[o + 2]
                dst.pixels[o + 3] = 255
                i += 1
                continue
            }
            let da = Int(dst.pixels[o + 3])
            let inv = 255 - sa
            let outA = sa + (da * inv + 127) / 255
            if outA <= 0 {
                i += 1
                continue
            }
            var c = 0
            while c < 3 {
                let sc = Int(src.pixels[o + c])
                let dc = Int(dst.pixels[o + c])
                let num = sc * sa + dc * da * inv / 255
                dst.pixels[o + c] = UInt8((num + outA / 2) / outA)
                c += 1
            }
            dst.pixels[o + 3] = UInt8(outA)
            i += 1
        }
    }
}

@preconcurrency @MainActor
final class _UIKeyboardWindow: UIWindow {
    let panel = _UIKeyboardPanel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = nil
        isOpaque = false
        isUserInteractionEnabled = false
        addSubview(panel)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = nil
        isOpaque = false
        isUserInteractionEnabled = false
        addSubview(panel)
    }

    func layoutKeyboard(animated: Bool, responder: UIResponder? = nil) {
        let state = _UIKeyboardResolved.resolve(from: responder)
        let rest = restPanelFrame(overlap: state.overlap)
        panel.bounds = CGRect(origin: .zero, size: rest.size)
        panel.buildIfNeeded(width: rest.width, state: state)
        panel.removeAllAnimations()
        if animated, panel.frame.origin.y != rest.origin.y {
            if panel.frame == .zero || panel.frame.origin.y >= bounds.height - 1 {
                panel.frame = CGRect(x: 0, y: bounds.height,
                                      width: rest.width, height: rest.height)
            }
            UIView.animate(withDuration: _UIKeyboardChrome.presentDuration) {
                self.panel.frame = rest
            }
        } else {
            panel.frame = rest
        }
    }

    func dismissAnimated() {
        let rest = restPanelFrame
        panel.removeAllAnimations()
        UIView.animate(withDuration: _UIKeyboardChrome.presentDuration,
                       animations: {
            self.panel.frame = CGRect(x: 0, y: self.bounds.height,
                                      width: rest.width, height: rest.height)
        }, completion: { _ in
            if _UIKeyboardChrome.appHasKeyInputFocus() { return }
            self.isHidden = true
        })
    }

    var restPanelFrame: CGRect { restPanelFrame(overlap: panel.state.overlap) }

    func restPanelFrame(overlap: CGFloat) -> CGRect {
        CGRect(x: 0, y: bounds.height - overlap, width: bounds.width, height: overlap)
    }
}

@preconcurrency @MainActor
final class _UIKeyboardPanel: UIView {
    private var builtWidth: CGFloat = -1
    private var builtSignature: Int = -1
    var state = _UIKeyboardResolved()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = _UIKeyboardChrome.panelRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        clipsToBounds = true
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.cornerRadius = _UIKeyboardChrome.panelRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        clipsToBounds = true
        isOpaque = false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyFill(traitCollection)
    }

    func applyFill(_ t: UITraitCollection) {
        if t.userInterfaceStyle == .dark {
            backgroundColor = UIColor(white: _UIKeyboardChrome.darkTint,
                                       alpha: _UIKeyboardChrome.darkMixAlpha)
        } else {
            backgroundColor = UIColor(red: _UIKeyboardChrome.lightTint.r,
                                      green: _UIKeyboardChrome.lightTint.g,
                                      blue: _UIKeyboardChrome.lightTint.b,
                                      alpha: _UIKeyboardChrome.lightMixAlpha)
        }
        let cap = keyCapColor(t)
        let ink = keyInkColor(t)
        for sub in subviews {
            if let key = sub as? _UIKeyboardKey {
                key.backgroundColor = capColor(for: key, traits: t, defaultCap: cap)
                key.label?.textColor = inkColor(for: key, traits: t, defaultInk: ink)
                key.setNeedsDisplay()
            } else if sub.tag == 2601 {
                if t.userInterfaceStyle == .dark {
                    // MEASURED Forms t1200.dark divider mid (54, 54, 58)
                    // over panel ~27; Notes t1200.dark (50, 50, 52) over 23.
                    // 0.12 white over 28 → 55, over 23 → 51.
                    sub.backgroundColor = UIColor(white: 1, alpha: 0.12)
                } else {
                    sub.backgroundColor = UIColor(red: 208.0 / 255.0,
                                                  green: 210.0 / 255.0,
                                                  blue: 214.0 / 255.0,
                                                  alpha: 1)
                }
            }
        }
    }

    func capColor(for key: _UIKeyboardKey, traits t: UITraitCollection,
                    defaultCap: UIColor) -> UIColor {
        switch key.kind {
        case .search, .go, .done:
            if key.kind == .search, !state.searchReturnEnabled {
                // MEASURED kbstateprobe search_empty, SE 2x: empty search
                // return interior (190, 192, 195).
                if t.userInterfaceStyle == .dark {
                    return UIColor(white: 61.0 / 255.0, alpha: 1)
                }
                return UIColor(red: 190.0 / 255.0, green: 192.0 / 255.0,
                               blue: 195.0 / 255.0, alpha: 1)
            }
            return .systemBlue
        default:
            return defaultCap
        }
    }

    func inkColor(for key: _UIKeyboardKey, traits t: UITraitCollection,
                    defaultInk: UIColor) -> UIColor {
        switch key.kind {
        case .search, .go, .done:
            if key.kind == .search, !state.searchReturnEnabled {
                return defaultInk
            }
            return UIColor(white: 1, alpha: 1)
        default:
            return defaultInk
        }
    }

    func keyCapColor(_ t: UITraitCollection) -> UIColor {
        // MEASURED letter-cap interiors: light 255, dark 61.
        if t.userInterfaceStyle == .dark {
            return UIColor(white: 61.0 / 255.0, alpha: 1)
        }
        return UIColor(white: 1, alpha: 1)
    }

    func keyInkColor(_ t: UITraitCollection) -> UIColor {
        t.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 1)
            : UIColor(white: 0, alpha: 1)
    }

    func buildIfNeeded(width: CGFloat, state: _UIKeyboardResolved) {
        if abs(builtWidth - width) < 0.25, builtSignature == state.signature,
           !subviews.isEmpty {
            self.state = state
            applyFill(traitCollection)
            applyLetterCase(state.shifted)
            return
        }
        for s in subviews { s.removeFromSuperview() }
        builtWidth = width
        builtSignature = state.signature
        self.state = state
        if state.layout == .numberPad {
            buildNumberPad(width: width)
        } else if state.isPad {
            buildPadAlphabetic(width: width, shifted: state.shifted,
                                returnStyle: state.returnStyle)
        } else if state.isCompactHeight {
            buildPhoneLandscapeAlphabetic(width: width, shifted: state.shifted,
                                           returnStyle: state.returnStyle)
        } else {
            buildPhoneAlphabetic(width: width, shifted: state.shifted,
                                  returnStyle: state.returnStyle)
        }
        applyFill(traitCollection)
    }

    /// ASCII A–Z fold. Avoid String.uppercased (guest StringProcessing).
    static func folded(_ s: String, up: Bool) -> String {
        var out = ""
        for ch in s {
            if let v = ch.asciiValue {
                if up, v >= 97, v <= 122,
                   let u = UnicodeScalar(UInt32(v) - 32) {
                    out.append(Character(u))
                    continue
                }
                if !up, v >= 65, v <= 90,
                   let u = UnicodeScalar(UInt32(v) + 32) {
                    out.append(Character(u))
                    continue
                }
            }
            out.append(ch)
        }
        return out
    }

    func applyLetterCase(_ shifted: Bool) {
        for sub in subviews {
            guard let key = sub as? _UIKeyboardKey, key.kind == .letter,
                  let t = key.label?.text, t.count == 1 else { continue }
            key.label?.text = _UIKeyboardPanel.folded(t, up: shifted)
        }
    }

    func buildPhoneAlphabetic(width: CGFloat, shifted: Bool,
                               returnStyle: _UIKeyboardResolved.ReturnStyle) {
        let sx = width / 375
        let y0 = _UIKeyboardChrome.quickTypeHeight
        let kh = _UIKeyboardChrome.keyHeight
        let gap = _UIKeyboardChrome.rowGap
        let letters: [[String]] = [
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
            ["Z", "X", "C", "V", "B", "N", "M"],
        ]
        // MEASURED field_white_light row 1 xs / widths at y=468.
        let row1X: [CGFloat] = [8.5, 45, 81.5, 117.5, 154, 190.5, 227, 263.5, 299.5, 336]
        let row1W: [CGFloat] = [30.5, 30.5, 30, 30.5, 30.5, 30.5, 30.5, 30, 30.5, 30.5]
        let row2X: [CGFloat] = [26.5, 63, 99.5, 136, 172.5, 208.5, 245, 281.5, 318]
        let row2W: [CGFloat] = [30.5, 30.5, 30.5, 30.5, 30, 30.5, 30.5, 30.5, 30.5]
        let row3LetterX: [CGFloat] = [63, 99.5, 136, 172.5, 208.5, 245, 281.5]
        let row3LetterW: [CGFloat] = [30.5, 30.5, 30.5, 30, 30.5, 30.5, 30.5]

        func letterText(_ s: String) -> String {
            _UIKeyboardPanel.folded(s, up: shifted)
        }
        func addLetter(text: String, x: CGFloat, y: CGFloat, w: CGFloat) {
            let key = _UIKeyboardKey(kind: .letter)
            key.frame = CGRect(x: x * sx, y: y, width: w * sx, height: kh)
            key.installLabel(letterText(text), size: _UIKeyboardChrome.letterFontSize)
            addSubview(key)
        }
        var i = 0
        while i < letters[0].count {
            addLetter(text: letters[0][i], x: row1X[i], y: y0, w: row1W[i])
            i += 1
        }
        i = 0
        while i < letters[1].count {
            addLetter(text: letters[1][i], x: row2X[i], y: y0 + kh + gap, w: row2W[i])
            i += 1
        }
        let y3 = y0 + 2 * (kh + gap)
        addGlyph(shifted ? .shiftOn : .shiftOff, x: 8.5 * sx, y: y3, w: 41.5 * sx, h: kh)
        i = 0
        while i < letters[2].count {
            addLetter(text: letters[2][i], x: row3LetterX[i], y: y3, w: row3LetterW[i])
            i += 1
        }
        addGlyph(.delete, x: 325 * sx, y: y3, w: 41.5 * sx, h: kh)

        let y4 = y0 + 3 * (kh + gap)
        addDigitKey(x: 8.5 * sx, y: y4, w: 39.5 * sx, h: kh)
        addGlyph(.emoji, x: 54 * sx, y: y4, w: 39.5 * sx, h: kh)
        addGlyph(.mic, x: 99.5 * sx, y: y4, w: 30.5 * sx, h: kh)
        let space = _UIKeyboardKey(kind: .space)
        space.frame = CGRect(x: 136 * sx, y: y4, width: 139.5 * sx, height: kh)
        addSubview(space)
        addReturn(style: returnStyle, x: 281.5 * sx, y: y4, w: 85 * sx, h: kh)
        // MEASURED Forms t1200 / Notes t1200 golden, iPhone SE 2x: empty
        // QuickType has two 1 pt (2 device-px) dividers at x=125.5 / 247.5,
        // y 420–443.5 (panel-local 13–36.5). Light RGB (208, 210, 214) vs
        // panel 226; dark mid (54, 54, 58) over panel ~27.
        addQuickTypeDivider(x: 125.5 * sx)
        addQuickTypeDivider(x: 247.5 * sx)
    }

    /// Compact-height alphabetic (SE landscapeLeft 667×375).
    /// MEASURED Forms t1200.landscape golden after 90° CW, iPhone SE 2x /
    /// iOS 26.1: panel [0, 169, 667, 206]; letter 47×32; v-gap 8; left
    /// 72; row y 219 / 259 / 299 / 339; QT 50 (row1−panelTop); dividers
    /// x 221.5 / 443.5, y 14–36 panel-local (window 183–205).
    func buildPhoneLandscapeAlphabetic(width: CGFloat, shifted: Bool,
                                       returnStyle: _UIKeyboardResolved.ReturnStyle) {
        let sx = width / 667
        let kh: CGFloat = 32
        let y0: CGFloat = 50
        let gap: CGFloat = 8
        let letters: [[String]] = [
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
            ["Z", "X", "C", "V", "B", "N", "M"],
        ]
        let row1X: [CGFloat] = [72, 125, 178, 230.5, 283.5, 336.5, 389.5, 442.5, 495, 548]
        let row1W: [CGFloat] = [47, 47, 46.5, 47, 47, 47, 47, 46.5, 47, 47]
        let row2X: [CGFloat] = [98.5, 151.5, 204.5, 257, 310, 363, 416, 469, 521.5]
        let row2W: [CGFloat] = [47, 47, 46.5, 47, 47, 47, 47, 46.5, 47]
        let row3LetterX: [CGFloat] = [151.5, 204.5, 257, 310, 363, 416, 469]
        let row3LetterW: [CGFloat] = [47, 46.5, 47, 47, 47, 47, 46.5]

        func letterText(_ s: String) -> String {
            _UIKeyboardPanel.folded(s, up: shifted)
        }
        func addLetter(text: String, x: CGFloat, y: CGFloat, w: CGFloat) {
            let key = _UIKeyboardKey(kind: .letter)
            key.frame = CGRect(x: x * sx, y: y, width: w * sx, height: kh)
            key.installLabel(letterText(text), size: _UIKeyboardChrome.letterFontSize)
            addSubview(key)
        }
        var i = 0
        while i < letters[0].count {
            addLetter(text: letters[0][i], x: row1X[i], y: y0, w: row1W[i])
            i += 1
        }
        i = 0
        while i < letters[1].count {
            addLetter(text: letters[1][i], x: row2X[i], y: y0 + kh + gap, w: row2W[i])
            i += 1
        }
        let y3 = y0 + 2 * (kh + gap)
        addGlyph(shifted ? .shiftOn : .shiftOff, x: 72 * sx, y: y3, w: 63 * sx, h: kh)
        i = 0
        while i < letters[2].count {
            addLetter(text: letters[2][i], x: row3LetterX[i], y: y3, w: row3LetterW[i])
            i += 1
        }
        addGlyph(.delete, x: 532 * sx, y: y3, w: 63 * sx, h: kh)

        let y4 = y0 + 3 * (kh + gap)
        addDigitKey(x: 72 * sx, y: y4, w: 47 * sx, h: kh)
        addGlyph(.emoji, x: 125 * sx, y: y4, w: 47 * sx, h: kh)
        addGlyph(.mic, x: 178 * sx, y: y4, w: 36 * sx, h: kh)
        let space = _UIKeyboardKey(kind: .space)
        space.frame = CGRect(x: 220 * sx, y: y4, width: 269 * sx, height: kh)
        addSubview(space)
        addReturn(style: returnStyle, x: 495 * sx, y: y4, w: 100 * sx, h: kh)
        addQuickTypeDivider(x: 221.5 * sx, y: 14, h: 22)
        addQuickTypeDivider(x: 443.5 * sx, y: 14, h: 22)
    }

    /// MEASURED kbstateprobe numberpad, iPhone SE 2x / iOS 26.1:
    /// frameEnd [0, 434, 375, 233], no QuickType. Keys 113.5×47, xs
    /// 7.5 / 129 / 250, row y 24 / 78 / 132 / 186 (panel-local), pitch 54.
    func buildNumberPad(width: CGFloat) {
        let sx = width / 375
        let kh: CGFloat = 47
        let xs: [CGFloat] = [7.5, 129, 250]
        let w: CGFloat = 113.5
        let digits = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]
        var row = 0
        while row < 3 {
            var col = 0
            while col < 3 {
                let y: CGFloat = 24 + CGFloat(row) * 54
                addLetterKey(kind: .digit, text: digits[row][col],
                             size: 25, x: xs[col] * sx, y: y, w: w * sx, h: kh)
                col += 1
            }
            row += 1
        }
        addLetterKey(kind: .digit, text: "0", size: 25,
                      x: xs[1] * sx, y: 24 + 3 * 54, w: w * sx, h: kh)
        addGlyph(.delete, x: xs[2] * sx, y: 24 + 3 * 54, w: w * sx, h: kh)
    }

    /// MEASURED kbstateprobe iPad has_text / textview_empty, iPad (A16)
    /// 820×1180 @2x / iOS 26.1: docked panel height 337, shortcut bar 64,
    /// letter keys 51×52 pitch 65, row y 64/128/192/256.
    func buildPadAlphabetic(width: CGFloat, shifted: Bool,
                            returnStyle: _UIKeyboardResolved.ReturnStyle) {
        let sx = width / 820
        let kh: CGFloat = 52
        func letterText(_ s: String) -> String {
            _UIKeyboardPanel.folded(s, up: shifted)
        }
        func addL(_ t: String, x: CGFloat, y: CGFloat, w: CGFloat) {
            addLetterKey(kind: .letter, text: letterText(t),
                         size: _UIKeyboardChrome.letterFontSize,
                         x: x * sx, y: y, w: w * sx, h: kh)
        }
        addGlyph(.tab, x: 11 * sx, y: 64, w: 67 * sx, h: kh)
        let row1 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
        var i = 0
        while i < row1.count {
            addL(row1[i], x: 92 + 65 * CGFloat(i), y: 64, w: 51)
            i += 1
        }
        addGlyph(.delete, x: 742 * sx, y: 64, w: 67 * sx, h: kh)

        let row2 = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
        i = 0
        while i < row2.count {
            addL(row2[i], x: 111.5 + 65 * CGFloat(i), y: 128, w: 51)
            i += 1
        }
        addReturn(style: returnStyle, x: 696.5 * sx, y: 128, w: 112.5 * sx, h: kh)

        addGlyph(shifted ? .shiftOn : .shiftOff,
                 x: 9 * sx, y: 192, w: 120 * sx, h: kh)
        let row3 = ["Z", "X", "C", "V", "B", "N", "M", ",", "."]
        i = 0
        while i < row3.count {
            addL(row3[i], x: 139 + 65 * CGFloat(i), y: 192, w: 55)
            i += 1
        }
        addGlyph(shifted ? .shiftOn : .shiftOff,
                 x: 723.5 * sx, y: 192, w: 87.5 * sx, h: kh)

        addGlyph(.emoji, x: 9 * sx, y: 256, w: 59 * sx, h: kh)
        addLetterKey(kind: .digit, text: ".?123", size: 16,
                      x: 78 * sx, y: 256, w: 58.5 * sx, h: kh)
        addGlyph(.mic, x: 146.5 * sx, y: 256, w: 59 * sx, h: kh)
        let space = _UIKeyboardKey(kind: .space)
        space.frame = CGRect(x: 215.5 * sx, y: 256, width: 400 * sx, height: kh)
        addSubview(space)
        addLetterKey(kind: .digit, text: ".?123", size: 16,
                      x: 625.5 * sx, y: 256, w: 87.5 * sx, h: kh)
        addGlyph(.dismiss, x: 723 * sx, y: 256, w: 88 * sx, h: kh)
        // Pad shortcut bar: three 1 pt suggestion dividers at the
        // QuickType slots. MEASURED has_text: two verticals in the
        // centre third of the 64 pt bar (phone empty-bar geometry scaled
        // across 820: 125.5/375·820 ≈ 274.5, 247.5/375·820 ≈ 541).
        addQuickTypeDivider(x: 274.5 * sx, y: 20, h: 28)
        addQuickTypeDivider(x: 541 * sx, y: 20, h: 28)
    }

    func addLetterKey(kind: _UIKeyboardKey.Kind, text: String, size: CGFloat,
                       x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        let key = _UIKeyboardKey(kind: kind)
        key.frame = CGRect(x: x, y: y, width: w, height: h)
        key.installLabel(text, size: size)
        addSubview(key)
    }

    func addReturn(style: _UIKeyboardResolved.ReturnStyle,
                   x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        let kind: _UIKeyboardKey.Kind
        switch style {
        case .arrow: kind = .return
        case .search: kind = .search
        case .go: kind = .go
        case .done: kind = .done
        }
        addGlyph(kind, x: x, y: y, w: w, h: h)
    }

    func addQuickTypeDivider(x: CGFloat, y: CGFloat = 13, h: CGFloat = 23.5) {
        let v = UIView(frame: CGRect(x: x, y: y, width: 1, height: h))
        v.isUserInteractionEnabled = false
        v.tag = 2601
        addSubview(v)
    }

    func addDigitKey(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        let key = _UIKeyboardKey(kind: .digit)
        key.frame = CGRect(x: x, y: y, width: w, height: h)
        key.installLabel("123", size: _UIKeyboardChrome.digitFontSize)
        addSubview(key)
    }

    func addGlyph(_ kind: _UIKeyboardKey.Kind, x: CGFloat, y: CGFloat,
                  w: CGFloat, h: CGFloat) {
        let key = _UIKeyboardKey(kind: kind)
        key.frame = CGRect(x: x, y: y, width: w, height: h)
        addSubview(key)
    }
}

@preconcurrency @MainActor
final class _UIKeyboardKey: UIView {
    enum Kind {
        case letter, digit, space, shiftOn, shiftOff, delete, emoji, mic
        case `return`, search, go, done, tab, dismiss
    }
    let kind: Kind
    var label: UILabel?

    /// LayerBridge content-image cache. MEASURED kinds are distinct glyphs.
    var kindFingerprint: Int {
        switch kind {
        case .letter: return 0
        case .digit: return 1
        case .space: return 2
        case .shiftOn: return 3
        case .shiftOff: return 13
        case .delete: return 4
        case .emoji: return 5
        case .mic: return 6
        case .return: return 7
        case .search: return 8
        case .go: return 9
        case .done: return 10
        case .tab: return 11
        case .dismiss: return 12
        }
    }

    init(kind: Kind) {
        self.kind = kind
        super.init(frame: .zero)
        layer.cornerRadius = _UIKeyboardChrome.keyRadius
        clipsToBounds = true
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        kind = .letter
        super.init(coder: coder)
    }

    func installLabel(_ text: String, size: CGFloat) {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: size, weight: .regular)
        l.textAlignment = .center
        l.frame = labelFrame
        l.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(l)
        label = l
    }

    /// MEASURED Forms t1200 Q: golden ink COM y is 1.15 pt above UILabel
    /// centre (40.6 vs 42.9 px at 2x). Offset the label up 1 pt.
    var labelFrame: CGRect { bounds.offsetBy(dx: 0, dy: -1) }

    override func layoutSubviews() {
        super.layoutSubviews()
        label?.frame = labelFrame
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        let ink = (label?.textColor ?? .black).resolvedCGColor(with: traitCollection)
        let w: CGFloat = 1.7
        switch kind {
        case .letter, .digit, .space:
            return
        case .shiftOn:
            // Filled up-arrow. MEASURED kbstateprobe empty_sentences /
            // Forms t1200, iPhone SE 2x: shift-on ink ~11 % of 41.5×42.
            fillShift(canvas, bounds: bounds, color: ink)
        case .shiftOff:
            // Outline up-arrow. MEASURED kbstateprobe has_text: shift-off
            // ink 0.045 of the cap vs filled 0.108.
            strokeShift(canvas, bounds: bounds, color: ink, lineWidth: w)
        case .delete:
            // Outline chevron + X. MEASURED Forms t1200 delete crop is
            // stroke, not fill (golden dark 7.5 % vs a filled body 21 %).
            let r = bounds.insetBy(dx: bounds.width * 0.22, dy: bounds.height * 0.30)
            var p = Path()
            p.move(to: CGPoint(x: r.minX + r.width * 0.28, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX - 1, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY + 1))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - 1))
            p.addLine(to: CGPoint(x: r.maxX - 1, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.28, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.midY))
            p.close()
            canvas.stroke(p, color: ink, lineWidth: w)
            let xc = r.minX + r.width * 0.62
            let yc = r.midY
            let s: CGFloat = 4
            var x1 = Path()
            x1.move(to: CGPoint(x: xc - s, y: yc - s))
            x1.addLine(to: CGPoint(x: xc + s, y: yc + s))
            canvas.stroke(x1, color: ink, lineWidth: w)
            var x2 = Path()
            x2.move(to: CGPoint(x: xc + s, y: yc - s))
            x2.addLine(to: CGPoint(x: xc - s, y: yc + s))
            canvas.stroke(x2, color: ink, lineWidth: w)
        case .emoji:
            // Outline face. MEASURED Forms t1200 emoji crop: ring + two
            // dots + open grin, not a filled disc (blob [65, 632, 18.5, 17.5]).
            let c = CGPoint(x: bounds.midX, y: bounds.midY)
            canvas.stroke(Path.roundedRect(CGRect(x: c.x - 9, y: c.y - 9,
                                                   width: 18, height: 18),
                                          cornerRadius: 9), color: ink, lineWidth: w)
            canvas.fill(Path.roundedRect(CGRect(x: c.x - 4.2, y: c.y - 3.2,
                                                 width: 2.6, height: 2.6),
                                          cornerRadius: 1.3), color: ink)
            canvas.fill(Path.roundedRect(CGRect(x: c.x + 1.6, y: c.y - 3.2,
                                                 width: 2.6, height: 2.6),
                                          cornerRadius: 1.3), color: ink)
            var grin = Path()
            grin.move(to: CGPoint(x: c.x - 5, y: c.y + 2.5))
            grin.addQuad(to: CGPoint(x: c.x + 5, y: c.y + 2.5),
                         control: CGPoint(x: c.x, y: c.y + 7.5))
            canvas.stroke(grin, color: ink, lineWidth: w)
        case .mic:
            let c = CGPoint(x: bounds.midX, y: bounds.midY)
            canvas.stroke(Path.roundedRect(CGRect(x: c.x - 3, y: c.y - 8,
                                                 width: 6, height: 10),
                                          cornerRadius: 3), color: ink, lineWidth: w)
            var cradle = Path()
            cradle.move(to: CGPoint(x: c.x - 5.5, y: c.y - 1))
            cradle.addQuad(to: CGPoint(x: c.x + 5.5, y: c.y - 1),
                            control: CGPoint(x: c.x, y: c.y + 6.5))
            canvas.stroke(cradle, color: ink, lineWidth: w)
            canvas.fill(Path.rect(CGRect(x: c.x - 0.85, y: c.y + 4, width: 1.7, height: 4)),
                        color: ink)
            canvas.fill(Path.rect(CGRect(x: c.x - 4, y: c.y + 7.5, width: 8, height: 1.7)),
                        color: ink)
        case .return:
            let c = CGPoint(x: bounds.midX, y: bounds.midY)
            var p = Path()
            p.move(to: CGPoint(x: c.x + 8, y: c.y - 7))
            p.addLine(to: CGPoint(x: c.x + 8, y: c.y + 2))
            p.addLine(to: CGPoint(x: c.x - 6, y: c.y + 2))
            canvas.stroke(p, color: ink, lineWidth: w)
            var head = Path()
            head.move(to: CGPoint(x: c.x - 2, y: c.y - 3))
            head.addLine(to: CGPoint(x: c.x - 8, y: c.y + 2))
            head.addLine(to: CGPoint(x: c.x - 2, y: c.y + 7))
            canvas.stroke(head, color: ink, lineWidth: w)
        case .search:
            // Magnifying glass. MEASURED kbstateprobe search_text, SE 2x:
            // blue return [281.5, 621, 85, 42] with a white glass.
            let c = CGPoint(x: bounds.midX - 1, y: bounds.midY - 1)
            canvas.stroke(Path.roundedRect(CGRect(x: c.x - 7, y: c.y - 7,
                                                   width: 12, height: 12),
                                          cornerRadius: 6), color: ink, lineWidth: w)
            var handle = Path()
            handle.move(to: CGPoint(x: c.x + 3.5, y: c.y + 3.5))
            handle.addLine(to: CGPoint(x: c.x + 9, y: c.y + 9))
            canvas.stroke(handle, color: ink, lineWidth: w)
        case .go:
            // Right-pointing arrow. MEASURED kbstateprobe return_go.
            let c = CGPoint(x: bounds.midX, y: bounds.midY)
            var p = Path()
            p.move(to: CGPoint(x: c.x - 8, y: c.y))
            p.addLine(to: CGPoint(x: c.x + 6, y: c.y))
            canvas.stroke(p, color: ink, lineWidth: w)
            var head = Path()
            head.move(to: CGPoint(x: c.x + 1, y: c.y - 6))
            head.addLine(to: CGPoint(x: c.x + 8, y: c.y))
            head.addLine(to: CGPoint(x: c.x + 1, y: c.y + 6))
            canvas.stroke(head, color: ink, lineWidth: w)
        case .done:
            // Checkmark. MEASURED kbstateprobe return_done.
            let c = CGPoint(x: bounds.midX, y: bounds.midY)
            var p = Path()
            p.move(to: CGPoint(x: c.x - 8, y: c.y + 1))
            p.addLine(to: CGPoint(x: c.x - 2, y: c.y + 8))
            p.addLine(to: CGPoint(x: c.x + 9, y: c.y - 7))
            canvas.stroke(p, color: ink, lineWidth: w)
        case .tab:
            let c = CGPoint(x: bounds.midX, y: bounds.midY)
            var p = Path()
            p.move(to: CGPoint(x: c.x - 8, y: c.y))
            p.addLine(to: CGPoint(x: c.x + 5, y: c.y))
            canvas.stroke(p, color: ink, lineWidth: w)
            var head = Path()
            head.move(to: CGPoint(x: c.x, y: c.y - 5))
            head.addLine(to: CGPoint(x: c.x + 6, y: c.y))
            head.addLine(to: CGPoint(x: c.x, y: c.y + 5))
            canvas.stroke(head, color: ink, lineWidth: w)
            canvas.stroke(Path.rect(CGRect(x: c.x + 7, y: c.y - 7, width: 1.7, height: 14)),
                          color: ink, lineWidth: w)
        case .dismiss:
            let c = CGPoint(x: bounds.midX, y: bounds.midY - 1)
            canvas.stroke(Path.roundedRect(CGRect(x: c.x - 10, y: c.y - 7,
                                                   width: 20, height: 12),
                                          cornerRadius: 2), color: ink, lineWidth: w)
            var chev = Path()
            chev.move(to: CGPoint(x: c.x - 5, y: c.y + 8))
            chev.addLine(to: CGPoint(x: c.x, y: c.y + 12))
            chev.addLine(to: CGPoint(x: c.x + 5, y: c.y + 8))
            canvas.stroke(chev, color: ink, lineWidth: w)
        }
    }

    func shiftPath(bounds: CGRect) -> Path {
        var p = Path()
        let cx = bounds.midX, cy = bounds.midY
        p.move(to: CGPoint(x: cx, y: cy - 9))
        p.addLine(to: CGPoint(x: cx + 8, y: cy + 1))
        p.addLine(to: CGPoint(x: cx + 3.5, y: cy + 1))
        p.addLine(to: CGPoint(x: cx + 3.5, y: cy + 9))
        p.addLine(to: CGPoint(x: cx - 3.5, y: cy + 9))
        p.addLine(to: CGPoint(x: cx - 3.5, y: cy + 1))
        p.addLine(to: CGPoint(x: cx - 8, y: cy + 1))
        p.close()
        return p
    }

    func fillShift(_ canvas: Canvas, bounds: CGRect, color: CGColor) {
        canvas.fill(shiftPath(bounds: bounds), color: color)
    }

    func strokeShift(_ canvas: Canvas, bounds: CGRect, color: CGColor,
                      lineWidth: CGFloat) {
        canvas.stroke(shiftPath(bounds: bounds), color: color, lineWidth: lineWidth)
    }
}
