// Keyboard state from the first responder. Owner: text-input / capture path.
//
// MEASURED kbstateprobe, iPhone SE 2x / iOS 26.1 (`/tmp/kbstate-se-light`)
// and iPad (A16) 820×1180 @2x (`/tmp/kbstate-ipad-light`):
//
//   empty UITextField autocap .sentences → uppercase, shift fill
//   "Alex Rivera" (cursor at end) → lowercase, shift outline
//   empty autocap .none → lowercase, shift outline
//   UITextView "…lunch." caret after '.' → lowercase (no space after
//     terminator, so not a new sentence)
//   UISearchBar.searchTextField returnKeyType .search (6),
//     autocorrectionType .no (1), autocap .sentences
//   empty search return key is gray; with text it is systemBlue +
//     magnifyingglass. UITextField returnKeyType .search is blue even
//     when empty.
//   numberPad phone: frameEnd height 233, no QuickType
//   iPad docked alphabetic: frameEnd [0, 843, 820, 337]
//
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGRect
#elseif canImport(Foundation)
import Foundation
#endif

@preconcurrency @MainActor
struct _UIKeyboardResolved {
    enum Layout { case alphabetic, numberPad }
    enum ReturnStyle { case arrow, search, go, done }

    var layout: Layout = .alphabetic
    var shifted: Bool = true
    var returnStyle: ReturnStyle = .arrow
    var searchReturnEnabled: Bool = true
    var overlap: CGFloat = 260
    var isPad: Bool = false
    var signature: Int = 0

    static func isPadIdiom() -> Bool {
        UITraitCollection.current.userInterfaceIdiom == .pad
            || UIDevice.current.userInterfaceIdiom == .pad
    }

    static func resolve(from responder: UIResponder?) -> _UIKeyboardResolved {
        var r = _UIKeyboardResolved()
        r.isPad = isPadIdiom()
        var autocap = UITextAutocapitalizationType.sentences
        var keyboard = UIKeyboardType.default
        var ret = UIReturnKeyType.default
        var text = ""
        var cursor = 0
        var isSearch = false

        if let f = responder as? UITextField {
            autocap = f.autocapitalizationType
            keyboard = f.keyboardType
            ret = f.returnKeyType
            text = f.text ?? ""
            if let sel = f.selectedTextRange {
                cursor = f.offset(from: f.beginningOfDocument, to: sel.start)
            } else {
                cursor = utf16Count(text)
            }
            if f is UISearchTextField { isSearch = true }
        } else if let v = responder as? UITextView {
            autocap = v.autocapitalizationType
            keyboard = v.keyboardType
            ret = v.returnKeyType
            text = v.text ?? ""
            cursor = v.caretOffset
        }

        r.shifted = shouldShift(text: text, cursor: cursor, autocap: autocap)
        if keyboard == .numberPad, !r.isPad {
            r.layout = .numberPad
            r.overlap = _UIKeyboardChrome.numberPadOverlap
        } else if r.isPad {
            r.layout = .alphabetic
            r.overlap = 337
        } else {
            r.layout = .alphabetic
            r.overlap = _UIKeyboardChrome.overlap
        }
        if isSearch { ret = .search }
        switch ret {
        case .search: r.returnStyle = .search
        case .go: r.returnStyle = .go
        case .done: r.returnStyle = .done
        default: r.returnStyle = .arrow
        }
        r.searchReturnEnabled = !(isSearch && text.isEmpty)
        var sig = r.layout == .numberPad ? 1 : 0
        sig = sig &* 31 &+ (r.shifted ? 1 : 0)
        sig = sig &* 31 &+ r.returnStyleHash
        sig = sig &* 31 &+ (r.searchReturnEnabled ? 1 : 0)
        sig = sig &* 31 &+ (r.isPad ? 1 : 0)
        r.signature = sig
        return r
    }

    var returnStyleHash: Int {
        switch returnStyle {
        case .arrow: return 0
        case .search: return 1
        case .go: return 2
        case .done: return 3
        }
    }

    /// MEASURED kbstateprobe empty_sentences / has_text / none / textview,
    /// iPhone SE 2x / iOS 26.1. .sentences capitalizes at the document
    /// start and after `.?!` followed by whitespace; a trailing `.` with
    /// no space (Notes body "lunch.") stays lowercase.
    static func shouldShift(text: String, cursor: Int,
                            autocap: UITextAutocapitalizationType) -> Bool {
        switch autocap {
        case .none: return false
        case .allCharacters: return true
        case .words, .sentences: break
        }
        let chars = Array(text)
        let i = Swift.min(Swift.max(0, cursor), chars.count)
        if i == 0 { return true }
        if autocap == .words {
            let p = chars[i - 1]
            return p == " " || p == "\n" || p == "\t"
        }
        var j = i - 1
        var sawSpace = false
        while j >= 0 {
            let p = chars[j]
            if p == " " || p == "\n" || p == "\t" {
                sawSpace = true
                j -= 1
                continue
            }
            if sawSpace {
                return p == "." || p == "!" || p == "?"
            }
            return false
        }
        return true
    }

    static func utf16Count(_ s: String) -> Int {
        var n = 0
        for _ in s.utf16 { n += 1 }
        return n
    }
}
