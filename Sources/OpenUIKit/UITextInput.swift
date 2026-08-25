// Text-input plumbing. Owner: text-input module (M8).
//
// The portable core has no system keyboard: the HOST turns its native key
// events (SDL_TEXTINPUT / SDL_KEYDOWN, a test harness, ...) into calls on
// UIWindow:
//
//   window.sendText("héllo", timestamp: t)     // committed characters
//   window.sendKey(.backspace, timestamp: t)   // editing keys
//
// Both route to the window's current first responder (UIResponder.become/
// resignFirstResponder; UIWindow.firstResponder). Text editors implement
// UIKeyInput (UIKit's protocol shape) plus the internal UITextInputTraits
// key handling below.
//
// Caret blink: UIKit's caret shows solid for a beat after focus/typing and
// then blinks on a 0.5 s half-period. The blink phase derives from the host
// clock (UIWindow.tick / the timestamps passed to sendText/sendKey) — never
// from a wall clock — so scripted captures are deterministic.

/// UIKit's UIKeyInput: minimal text entry.
@MainActor
public protocol UIKeyInput: AnyObject {
    var hasText: Bool { get }
    func insertText(_ text: String)
    func deleteBackward()
}

/// Editing keys the host can send (beyond committed text).
public enum UIKeyEventKey: String, Sendable {
    case backspace
    case left
    case right
    case up
    case down
    case `return`
}

/// Internal: views that take editing-key input (caret movement, return).
@MainActor
protocol UITextKeyHandling: AnyObject {
    func handleKey(_ key: UIKeyEventKey)
}

extension UIWindow {
    /// Feed committed text from the host's input stream to the first
    /// responder. `timestamp` (host clock) resets the caret-blink phase so
    /// the caret is solid while typing.
    public func sendText(_ text: String, timestamp: TimeInterval = 0) {
        guard !text.isEmpty, let fr = firstResponder as? UIKeyInput else { return }
        UITextInputState.noteActivity(at: timestamp)
        fr.insertText(text)
    }

    /// Feed one editing key (backspace / arrows / return) to the first
    /// responder.
    public func sendKey(_ key: UIKeyEventKey, timestamp: TimeInterval = 0) {
        guard let fr = firstResponder else { return }
        UITextInputState.noteActivity(at: timestamp)
        if let handler = fr as? UITextKeyHandling {
            handler.handleKey(key)
        } else if let input = fr as? UIKeyInput, key == .backspace {
            input.deleteBackward()
        }
    }
}

/// Shared caret-blink state for the (single) focused text editor.
/// UIWindow.tick calls `_stepCaretBlink` every frame; the active editor
/// registers itself on focus and gets `caretBlinkChanged` callbacks when
/// the on/off phase flips, so it can update its caret view (a plain
/// property change — the next render picks it up).
@MainActor
public enum UITextInputState {
    /// Blink half-period (seconds) and the solid hold after focus/typing.
    public static var blinkHalfPeriod: TimeInterval = 0.5
    public static var solidHold: TimeInterval = 0.6

    static weak var activeEditor: (AnyObject & UITextCaretHosting)?
    static var phaseOrigin: TimeInterval = 0
    static var lastVisible = true

    /// True while an editor is focused — the host's "keep rendering"
    /// redraw hint (openhost polls it like _hasActiveScrollAnimations).
    public static var _hasActiveCaret: Bool { activeEditor != nil }

    static func focus(_ editor: AnyObject & UITextCaretHosting, at t: TimeInterval) {
        activeEditor = editor
        phaseOrigin = t
        lastVisible = true
    }

    static func unfocus(_ editor: AnyObject) {
        if activeEditor === editor { activeEditor = nil }
    }

    /// Typing/caret movement makes the caret solid again.
    static func noteActivity(at t: TimeInterval) {
        phaseOrigin = t
        if !lastVisible {
            lastVisible = true
            activeEditor?.caretBlinkChanged(visible: true)
        }
    }

    static func caretVisible(at t: TimeInterval) -> Bool {
        let dt = t - phaseOrigin
        if dt < solidHold { return true }
        let halves = ((dt - solidHold) / blinkHalfPeriod).rounded(.down)
        return halves.truncatingRemainder(dividingBy: 2) == 1
    }

    /// Advance the blink clock (called from UIWindow.tick).
    public static func _stepCaretBlink(to t: TimeInterval) {
        guard let editor = activeEditor else { return }
        let visible = caretVisible(at: t)
        if visible != lastVisible {
            lastVisible = visible
            editor.caretBlinkChanged(visible: visible)
        }
    }
}

/// Internal: an editor that hosts a blinking caret view.
@MainActor
protocol UITextCaretHosting {
    func caretBlinkChanged(visible: Bool)
}

// MARK: - Caret positioning math (unit-tested)

/// Pure caret math shared by UITextField and UITextView: glyph-boundary
/// hit testing and prefix widths from the FontEngine advance/kerning
/// tables (the same measurement the renderer uses).
@MainActor
public enum UITextCaretMath {
    /// Width of the first `count` unicode scalars of `text`.
    public static func prefixWidth(_ text: String, count: Int, font: UIFont) -> CGFloat {
        var total: CGFloat = 0
        var prev: Unicode.Scalar? = nil
        var i = 0
        for ch in text.unicodeScalars {
            if i == count { break }
            if let p = prev { total += FontEngine.kerning(p, ch, font: font) }
            total += FontEngine.advance(of: ch, font: font)
            prev = ch
            i += 1
        }
        return total
    }

    /// Nearest glyph boundary (0...scalarCount) to `x`, where x is in
    /// text space (pen 0 at the first glyph). UIKit picks the boundary
    /// whose position is closest to the tap.
    public static func caretIndex(for x: CGFloat, text: String, font: UIFont) -> Int {
        if x <= 0 { return 0 }
        var total: CGFloat = 0
        var prev: Unicode.Scalar? = nil
        var i = 0
        for ch in text.unicodeScalars {
            if let p = prev { total += FontEngine.kerning(p, ch, font: font) }
            let adv = FontEngine.advance(of: ch, font: font)
            // Boundary i sits at `total`; boundary i+1 at `total + adv`.
            if x < total + adv {
                return (x - total) <= (total + adv - x) ? i : i + 1
            }
            total += adv
            prev = ch
            i += 1
        }
        return i
    }

    /// String.Index for a unicode-scalar offset.
    public static func index(_ text: String, atScalarOffset n: Int) -> String.Index {
        var i = text.unicodeScalars.startIndex
        var k = 0
        while k < n, i < text.unicodeScalars.endIndex {
            i = text.unicodeScalars.index(after: i)
            k += 1
        }
        return i
    }

    public static func scalarCount(_ text: String) -> Int {
        text.unicodeScalars.count
    }
}
