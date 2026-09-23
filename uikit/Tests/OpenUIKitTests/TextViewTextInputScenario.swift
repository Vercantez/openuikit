// UITextView's UITextInput document/selection model — ONE scenario, two
// runtimes:
//
//   * Apple: Tools/oracle2/textviewinputprobe/run.sh compiles this file with
//     `-D OUK_ORACLE` into an iOS 26.1 simulator app, runs it on a throwaway
//     iPhone 16 and commits transcript-ios26.1.txt.
//   * OpenUIKit: TextViewTextInputTests runs the same function and compares
//     its lines with that transcript.
//
// Every line is plain data (offsets, NSRanges, escaped UTF-16, delegate and
// notification events in call order). Events that arrive only after the run
// loop turns are logged separately as "late:" so ordering is not guessed.
#if OUK_ORACLE
import UIKit
#else
import Foundation
@testable import OpenUIKit
#endif

@MainActor
final class OUKTextViewInputRecorder: NSObject, UITextViewDelegate {
    var events: [String] = []
    weak var textView: UITextView?

    private func sel(_ tv: UITextView) -> String { OUKTextViewInputScenario.nsRange(tv.selectedRange) }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool { events.append("shouldBegin"); return true }
    func textViewDidBeginEditing(_ textView: UITextView) { events.append("didBegin sel=\(sel(textView))") }
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool { events.append("shouldEnd"); return true }
    func textViewDidEndEditing(_ textView: UITextView) { events.append("didEnd") }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        events.append("shouldChange \(OUKTextViewInputScenario.nsRange(range)) \(OUKTextViewInputScenario.esc(text))")
        return true
    }
    func textViewDidChange(_ textView: UITextView) {
        events.append("didChange text=\(OUKTextViewInputScenario.esc(textView.text ?? "")) sel=\(sel(textView))")
    }
    func textViewDidChangeSelection(_ textView: UITextView) { events.append("didChangeSelection sel=\(sel(textView))") }

}

@MainActor
enum OUKTextViewInputScenario {
    static func nsRange(_ r: NSRange) -> String { "{\(r.location),\(r.length)}" }

    /// ASCII verbatim; everything else as \u{XXXX} per UTF-16 unit, so lone
    /// surrogates survive printing.
    static func esc(_ s: String) -> String {
        var out = "\""
        for u in s.utf16 {
            if u >= 0x20 && u < 0x7F && u != 0x5C && u != 0x22 {
                out.unicodeScalars.append(Unicode.Scalar(UInt8(u)))
            } else {
                out += "\\u{" + String(u, radix: 16, uppercase: true) + "}"
            }
        }
        return out + "\""
    }

    static func num(_ v: CGFloat) -> String {
        let d = Double(v)
        if d == d.rounded() { return String(Int(d)) }
        return String((d * 100).rounded() / 100)
    }

    static func rect(_ r: CGRect) -> String {
        "(\(num(r.origin.x)),\(num(r.origin.y)),\(num(r.size.width)),\(num(r.size.height)))"
    }

    static func off(_ tv: UITextView, _ p: UITextPosition?) -> String {
        guard let p else { return "nil" }
        return String(tv.offset(from: tv.beginningOfDocument, to: p))
    }

    static func range(_ tv: UITextView, _ r: UITextRange?) -> String {
        guard let r else { return "nil" }
        return "[\(off(tv, r.start)),\(off(tv, r.end))\(r.isEmpty ? " empty" : "")]"
    }

    static func pos(_ tv: UITextView, _ o: Int) -> UITextPosition {
        tv.position(from: tv.beginningOfDocument, offset: o)!
    }

    static func tr(_ tv: UITextView, _ a: Int, _ b: Int) -> UITextRange {
        tv.textRange(from: pos(tv, a), to: pos(tv, b))!
    }

    static func state(_ tv: UITextView) -> String {
        "text=\(esc(tv.text ?? "")) sel=\(nsRange(tv.selectedRange)) selTR=\(range(tv, tv.selectedTextRange)) marked=\(range(tv, tv.markedTextRange)) fr=\(tv.isFirstResponder ? 1 : 0)"
    }

    /// Runs the scenario. `host` is a view inside a key window; `settle` turns
    /// the run loop so deferred side effects surface as "late:" lines.
    static func run(host: UIView, settle: () -> Void) -> [String] {
        var lines: [String] = []
        let rec = OUKTextViewInputRecorder()
        let tv = UITextView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        tv.font = UIFont.systemFont(ofSize: 17)
        rec.textView = tv
#if OUK_ORACLE
        let nc = NotificationCenter.default
#else
        // Linux corelibs Foundation also ships NotificationCenter.default
        // (TextKitTests.swift; MEASURED CHECK_ONLY Linux build: "ambiguous use
        // of 'default'").
        let nc = OpenUIKit.NotificationCenter.default
#endif
        // Block observers (synchronous, queue nil): selector observers need
        // Objective-C interop, which the Linux build does not have.
        var tokens: [Any] = []
        for (name, line) in [
            (UITextView.textDidChangeNotification, "note TextDidChange"),
            (UITextView.textDidBeginEditingNotification, "note TextDidBeginEditing"),
            (UITextView.textDidEndEditingNotification, "note TextDidEndEditing"),
        ] {
            tokens.append(nc.addObserver(forName: name, object: tv, queue: nil) { _ in
                MainActor.assumeIsolated { rec.events.append(line) }
            })
        }
        defer { for token in tokens { nc.removeObserver(token) } }

        func step(_ name: String, _ body: () -> String?) {
            rec.events = []
            let extra = body()
            let now = rec.events
            lines.append("\(name): \(extra.map { $0 + " | " } ?? "")\(state(tv))")
            for e in now { lines.append("  \(e)") }
            rec.events = []
            settle()
            for e in rec.events { lines.append("  late: \(e)") }
        }

        step("fresh") { "begin=\(off(tv, tv.beginningOfDocument)) end=\(off(tv, tv.endOfDocument)) hasText=\(tv.hasText ? 1 : 0)" }
        tv.delegate = rec
        host.addSubview(tv)
        step("text=Hello world (detached from responder)") { tv.text = "Hello world"; return "end=\(off(tv, tv.endOfDocument))" }
        step("selectedRange={2,3}") { tv.selectedRange = NSRange(location: 2, length: 3); return nil }
        step("text(in: selectedTextRange)") { tv.selectedTextRange.map { esc(tv.text(in: $0) ?? "nil") } ?? "no range" }
        step("selectedTextRange=[1,4]") { tv.selectedTextRange = tr(tv, 1, 4); return nil }
        step("selectedTextRange=nil") { tv.selectedTextRange = nil; return nil }
        step("replace [0,5) Howdy!") { tv.replace(tr(tv, 0, 5), withText: "Howdy!"); return nil }
        step("insertText X (not first responder)") { tv.insertText("X"); return nil }
        step("deleteBackward (not first responder)") { tv.deleteBackward(); return nil }

        step("becomeFirstResponder") { "returned=\(tv.becomeFirstResponder() ? 1 : 0)" }
        step("selectedRange={0,0}") { tv.selectedRange = NSRange(location: 0, length: 0); return nil }
        step("selectedRange={0,0} again") { tv.selectedRange = NSRange(location: 0, length: 0); return nil }
        step("insertText abc") { tv.insertText("abc"); return nil }
        step("deleteBackward") { tv.deleteBackward(); return nil }
        step("selectedRange={0,3}") { tv.selectedRange = NSRange(location: 0, length: 3); return nil }
        step("insertText Z over selection") { tv.insertText("Z"); return nil }
        step("selectedRange={1,2}") { tv.selectedRange = NSRange(location: 1, length: 2); return nil }
        step("deleteBackward over selection") { tv.deleteBackward(); return nil }
        step("replace [0,1) Q (first responder)") { tv.replace(tr(tv, 0, 1), withText: "Q"); return nil }
        // Plain letters: "--" would go through the keyboard's smart-dash
        // substitution on a first responder (MEASURED: it became U+2014 via
        // an extra shouldChange/didChange round).
        step("replace [2,2) empty-range insert") { tv.replace(tr(tv, 2, 2), withText: "mn"); return nil }
        step("replace [0,2) with empty") { tv.replace(tr(tv, 0, 2), withText: ""); return nil }
        step("selectedRange={0,0}, replace [3,4) after caret") {
            tv.selectedRange = NSRange(location: 0, length: 0); rec.events = []
            tv.replace(tr(tv, 3, 4), withText: "KL"); return nil
        }
        step("selectedRange={1,0}, replace [3,3) empty with empty") {
            tv.selectedRange = NSRange(location: 1, length: 0); rec.events = []
            tv.replace(tr(tv, 3, 3), withText: ""); return nil
        }
        step("insertText empty") { tv.insertText(""); return nil }
        step("unmarkText with no marked text") { tv.unmarkText(); return nil }

        step("selectedRange={2,0}") { tv.selectedRange = NSRange(location: 2, length: 0); return nil }
        step("setMarkedText ka sel{2,0}") { tv.setMarkedText("ka", selectedRange: NSRange(location: 2, length: 0)); return nil }
        step("text(in: markedTextRange)") { tv.markedTextRange.map { esc(tv.text(in: $0) ?? "nil") } ?? "no range" }
        step("setMarkedText \u{304B}\u{306A} sel{1,0}") { tv.setMarkedText("\u{304B}\u{306A}", selectedRange: NSRange(location: 1, length: 0)); return nil }
        step("setMarkedText abc sel{0,2}") { tv.setMarkedText("abc", selectedRange: NSRange(location: 0, length: 2)); return nil }
        step("unmarkText") { tv.unmarkText(); return nil }
        step("setMarkedText x sel{1,0}") { tv.setMarkedText("x", selectedRange: NSRange(location: 1, length: 0)); return nil }
        step("insertText y (replaces marked)") { tv.insertText("y"); return nil }
        step("setMarkedText mm sel{2,0}") { tv.setMarkedText("mm", selectedRange: NSRange(location: 2, length: 0)); return nil }
        step("setMarkedText nil") { tv.setMarkedText(nil, selectedRange: NSRange(location: 0, length: 0)); return nil }
        step("setMarkedText pq sel{2,0}") { tv.setMarkedText("pq", selectedRange: NSRange(location: 2, length: 0)); return nil }
        step("setMarkedText empty") { tv.setMarkedText("", selectedRange: NSRange(location: 0, length: 0)); return nil }
        step("setMarkedText rs sel{2,0}") { tv.setMarkedText("rs", selectedRange: NSRange(location: 2, length: 0)); return nil }
        step("selectedRange={0,0} while marked") { tv.selectedRange = NSRange(location: 0, length: 0); return nil }
        step("unmarkText (cleanup)") { tv.unmarkText(); return nil }

        step("text=a\u{1F600}b (programmatic, first responder)") { tv.text = "a\u{1F600}b"; return "end=\(off(tv, tv.endOfDocument))" }
        step("positions") {
            let b = tv.beginningOfDocument, e = tv.endOfDocument
            var parts: [String] = []
            for o in [-1, 0, 1, 2, 3, 4, 5] { parts.append("from0+\(o)=\(off(tv, tv.position(from: b, offset: o)))") }
            parts.append("fromEnd-1=\(off(tv, tv.position(from: e, offset: -1)))")
            parts.append("fromEnd+1=\(off(tv, tv.position(from: e, offset: 1)))")
            parts.append("offset(end,begin)=\(tv.offset(from: e, to: b))")
            return parts.joined(separator: " ")
        }
        step("ranges") {
            var parts: [String] = []
            let rev = tv.textRange(from: pos(tv, 3), to: pos(tv, 1))
            parts.append("textRange(3,1)=\(range(tv, rev))")
            if let rev { parts.append("text(in: 3..1)=\(esc(tv.text(in: rev) ?? "nil"))") }
            parts.append("text(0..2)=\(esc(tv.text(in: tr(tv, 0, 2)) ?? "nil"))")
            parts.append("text(2..4)=\(esc(tv.text(in: tr(tv, 2, 4)) ?? "nil"))")
            parts.append("text(1..3)=\(esc(tv.text(in: tr(tv, 1, 3)) ?? "nil"))")
            parts.append("text(0..0)=\(esc(tv.text(in: tr(tv, 0, 0)) ?? "nil"))")
            return parts.joined(separator: " ")
        }
        step("selectedRange={2,0} inside surrogate pair") { tv.selectedRange = NSRange(location: 2, length: 0); return nil }
        step("selectedTextRange=[2,2] inside surrogate pair") { tv.selectedTextRange = tr(tv, 2, 2); return nil }
        step("selectedRange={4,0}") { tv.selectedRange = NSRange(location: 4, length: 0); return nil }
        step("deleteBackward") { tv.deleteBackward(); return nil }
        step("deleteBackward over emoji") { tv.deleteBackward(); return nil }

        step("attributedText=Tail") { tv.attributedText = NSAttributedString(string: "Tail"); return nil }
        step("selectedRange={1,1}") { tv.selectedRange = NSRange(location: 1, length: 1); return nil }
        step("text=Tail (same text)") { tv.text = "Tail"; return nil }
        step("text=Longer text") { tv.selectedRange = NSRange(location: 1, length: 1); rec.events = []; tv.text = "Longer text"; return nil }
        step("text=ab (shorter)") { tv.text = "ab"; return nil }
        step("text=ab again (selection already at end)") { tv.text = "ab"; return nil }
        step("text=xy (same length, selection at end)") { tv.text = "xy"; return nil }

        step("resignFirstResponder") { "returned=\(tv.resignFirstResponder() ? 1 : 0)" }
        step("replace [0,1) after resign") { tv.replace(tr(tv, 0, 1), withText: "c"); return nil }

        // Geometry (text "Hello", 17 pt system font, 320 pt wide). The font
        // is re-set: the font-less attributedText above reset it.
        tv.font = UIFont.systemFont(ofSize: 17)
        tv.text = "Hello"
        tv.layoutIfNeeded()
        step("geometry") {
            var parts: [String] = []
            parts.append("caret0=\(rect(tv.caretRect(for: tv.beginningOfDocument)))")
            parts.append("caretEnd=\(rect(tv.caretRect(for: tv.endOfDocument)))")
            parts.append("first[0,0)=\(rect(tv.firstRect(for: tr(tv, 0, 0))))")
            parts.append("first[1,3)=\(rect(tv.firstRect(for: tr(tv, 1, 3))))")
            let rs = tv.selectionRects(for: tr(tv, 1, 3))
            parts.append("selRects[1,3)=\(rs.count)")
            return parts.joined(separator: " ")
        }
        step("geometry carets") {
            (0...5).map { "c\($0)=\(rect(tv.caretRect(for: pos(tv, $0))))" }.joined(separator: " ")
        }
        tv.text = "Hello\nWorld"
        tv.layoutIfNeeded()
        step("geometry two lines") {
            var parts: [String] = []
            for o in [5, 6, 11] { parts.append("c\(o)=\(rect(tv.caretRect(for: pos(tv, o))))") }
            parts.append("first[3,8)=\(rect(tv.firstRect(for: tr(tv, 3, 8))))")
            parts.append("first[6,8)=\(rect(tv.firstRect(for: tr(tv, 6, 8))))")
            parts.append("selRects[3,8)=\(tv.selectionRects(for: tr(tv, 3, 8)).count)")
            return parts.joined(separator: " ")
        }
        tv.font = UIFont.systemFont(ofSize: 12)
        tv.text = "Hi"
        tv.layoutIfNeeded()
        step("geometry 12pt") {
            "c0=\(rect(tv.caretRect(for: pos(tv, 0)))) c2=\(rect(tv.caretRect(for: pos(tv, 2)))) first[0,0)=\(rect(tv.firstRect(for: tr(tv, 0, 0))))"
        }
        tv.removeFromSuperview()
        return lines
    }
}
