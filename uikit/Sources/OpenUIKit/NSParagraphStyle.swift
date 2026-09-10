// NSParagraphStyle. Owner: text module (M12 — attributed text).
//
// Portable stand-in for Foundation's paragraph style (same shadowing caveat
// as NSAttributedString — see docs/KNOWN_GAPS.md). Only the properties the
// layout engine honors are declared; each one is oracle-measured, see
// AttributedTextLayout for the rules:
//   lineSpacing           extra points BETWEEN line boxes (n-1 gaps)
//   paragraphSpacing      extra points after a hard line break
//   paragraphSpacingBefore extra points before every paragraph but the first
//   lineHeightMultiple    scales the natural line height
//   minimum/maximumLineHeight  clamp, applied after the multiple
//   firstLineHeadIndent / headIndent   left inset of the first / later lines
//   tailIndent            negative = inset from the trailing edge
//   alignment, lineBreakMode  adopted by UILabel when set on the string
//
// The base class is nominally immutable (Foundation shape): its properties
// have internal setters and NSMutableParagraphStyle re-exposes them.

// NSObject provider, chosen exactly as UIResponder.swift chooses it — see
// that file's header for why this fails closed.
#if canImport(Foundation)
import protocol Foundation.NSCopying
import protocol Foundation.NSMutableCopying
import class Foundation.NSObject
import struct Foundation.NSZone
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("OpenUIKit requires Foundation.NSObject or ObjectiveC.NSObject")
#endif

/// SDK EVIDENCE (iOS 26.1,
/// .../iPhoneSimulator26.1.sdk/System/Library/Frameworks/UIKit.framework/
/// Headers/NSParagraphStyle.h):
///
///     :69   @interface NSParagraphStyle : NSObject <NSCopying, NSMutableCopying, NSSecureCoding>
///     :113  @interface NSMutableParagraphStyle : NSParagraphStyle
///
/// The NSObject base is adopted so Kickstarter-Prelude's
/// `NSMutableParagraphStyleProtocol: NSObjectProtocol` can be satisfied.
/// `NSSecureCoding` is not adopted: the port has no archiver for this type
/// and a stub would be unmeasured (docs/KNOWN_GAPS.md).
///
/// EQUALITY moves with the base class. `Hashable` is no longer restated —
/// it arrives from NSObject, whose witnesses are `isEqual(_:)` and `hash`.
/// A Swift `==` / `hash(into:)` pair declared here would be *ignored* by
/// `Set` and `Dictionary`, because the conformance is already satisfied by
/// the superclass; the value comparison is therefore spelled as overrides of
/// those two, the same shape as UIVisualEffect.swift:252. `==` is kept as an
/// overload so statically typed comparisons read the same as before.
open class NSParagraphStyle: NSObject, @unchecked Sendable {
    public internal(set) var alignment: NSTextAlignment = .natural
    public internal(set) var lineSpacing: CGFloat = 0
    public internal(set) var paragraphSpacing: CGFloat = 0
    public internal(set) var paragraphSpacingBefore: CGFloat = 0
    public internal(set) var lineHeightMultiple: CGFloat = 0
    public internal(set) var minimumLineHeight: CGFloat = 0
    public internal(set) var maximumLineHeight: CGFloat = 0
    public internal(set) var firstLineHeadIndent: CGFloat = 0
    public internal(set) var headIndent: CGFloat = 0
    public internal(set) var tailIndent: CGFloat = 0
    public internal(set) var lineBreakMode: NSLineBreakMode = .byWordWrapping
    public internal(set) var hyphenationFactor: Float = 0

    public override init() {}

    /// UIKit's shared default paragraph style.
    public static let `default` = NSParagraphStyle()

    /// Apple's is `NSMutableCopying`'s `mutableCopy()`, inherited from
    /// NSObject and typed `-> Any`; app source writes
    /// `style.mutableCopy() as! NSMutableParagraphStyle`. The port cannot
    /// keep its old `-> NSMutableParagraphStyle` signature now that NSObject
    /// supplies one, so the override matches Apple's and the typed helper
    /// keeps its own name for the port's internal callers.
    open func mutableParagraphStyleCopy() -> NSMutableParagraphStyle {
        let m = NSMutableParagraphStyle()
        m.setParagraphStyle(self)
        return m
    }

#if canImport(Foundation)
    /// NSCopying. A base paragraph style is immutable, so Apple's returns
    /// `self`; the port copies because its "immutability" is only an
    /// `internal(set)`, and the module can still mutate a shared instance.
    open func copy(with zone: NSZone? = nil) -> Any {
        let c = NSParagraphStyle()
        c._copyParagraphAttributes(from: self)
        return c
    }

    /// NSMutableCopying. NSObject's `mutableCopy()` routes here, which is
    /// what makes `style.mutableCopy() as! NSMutableParagraphStyle` — the
    /// spelling real app source uses — work.
    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        mutableParagraphStyleCopy()
    }
#endif

    /// Shared by `copy(with:)` and `NSMutableParagraphStyle.setParagraphStyle`.
    func _copyParagraphAttributes(from obj: NSParagraphStyle) {
        alignment = obj.alignment
        lineSpacing = obj.lineSpacing
        paragraphSpacing = obj.paragraphSpacing
        paragraphSpacingBefore = obj.paragraphSpacingBefore
        lineHeightMultiple = obj.lineHeightMultiple
        minimumLineHeight = obj.minimumLineHeight
        maximumLineHeight = obj.maximumLineHeight
        firstLineHeadIndent = obj.firstLineHeadIndent
        headIndent = obj.headIndent
        tailIndent = obj.tailIndent
        lineBreakMode = obj.lineBreakMode
        hyphenationFactor = obj.hyphenationFactor
    }

    /// True when nothing in this style changes layout (the fast path).
    var isDefaultLayout: Bool {
        lineSpacing == 0 && paragraphSpacing == 0 && paragraphSpacingBefore == 0
            && lineHeightMultiple == 0 && minimumLineHeight == 0 && maximumLineHeight == 0
            && firstLineHeadIndent == 0 && headIndent == 0 && tailIndent == 0
    }

    /// Value equality, kept as an overload so `a == b` on statically typed
    /// paragraph styles reads exactly as it did before the re-parent.
    public static func == (a: NSParagraphStyle, b: NSParagraphStyle) -> Bool {
        a._hasSameParagraphAttributes(as: b)
    }

    func _hasSameParagraphAttributes(as b: NSParagraphStyle) -> Bool {
        alignment == b.alignment && lineSpacing == b.lineSpacing
            && paragraphSpacing == b.paragraphSpacing
            && paragraphSpacingBefore == b.paragraphSpacingBefore
            && lineHeightMultiple == b.lineHeightMultiple
            && minimumLineHeight == b.minimumLineHeight
            && maximumLineHeight == b.maximumLineHeight
            && firstLineHeadIndent == b.firstLineHeadIndent
            && headIndent == b.headIndent && tailIndent == b.tailIndent
            && lineBreakMode == b.lineBreakMode
            && hyphenationFactor == b.hyphenationFactor
    }

    /// NSObject's Equatable/Hashable witnesses. These, not a Swift `==` /
    /// `hash(into:)` pair, are what `Set` and `Dictionary` consult now that
    /// the conformance comes from the superclass.
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSParagraphStyle else { return false }
        return _hasSameParagraphAttributes(as: other)
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(alignment)
        hasher.combine(lineSpacing)
        hasher.combine(paragraphSpacing)
        hasher.combine(paragraphSpacingBefore)
        hasher.combine(lineHeightMultiple)
        hasher.combine(minimumLineHeight)
        hasher.combine(maximumLineHeight)
        hasher.combine(firstLineHeadIndent)
        hasher.combine(headIndent)
        hasher.combine(tailIndent)
        hasher.combine(lineBreakMode)
        hasher.combine(hyphenationFactor)
        return hasher.finalize()
    }
}

#if canImport(Foundation)
extension NSParagraphStyle: NSCopying, NSMutableCopying {}
#endif

open class NSMutableParagraphStyle: NSParagraphStyle, @unchecked Sendable {
    public override init() { super.init() }

    open override var alignment: NSTextAlignment {
        get { super.alignment } set { super.alignment = newValue }
    }
    open override var lineSpacing: CGFloat {
        get { super.lineSpacing } set { super.lineSpacing = newValue }
    }
    open override var paragraphSpacing: CGFloat {
        get { super.paragraphSpacing } set { super.paragraphSpacing = newValue }
    }
    open override var paragraphSpacingBefore: CGFloat {
        get { super.paragraphSpacingBefore } set { super.paragraphSpacingBefore = newValue }
    }
    open override var lineHeightMultiple: CGFloat {
        get { super.lineHeightMultiple } set { super.lineHeightMultiple = newValue }
    }
    open override var minimumLineHeight: CGFloat {
        get { super.minimumLineHeight } set { super.minimumLineHeight = newValue }
    }
    open override var maximumLineHeight: CGFloat {
        get { super.maximumLineHeight } set { super.maximumLineHeight = newValue }
    }
    open override var firstLineHeadIndent: CGFloat {
        get { super.firstLineHeadIndent } set { super.firstLineHeadIndent = newValue }
    }
    open override var headIndent: CGFloat {
        get { super.headIndent } set { super.headIndent = newValue }
    }
    open override var tailIndent: CGFloat {
        get { super.tailIndent } set { super.tailIndent = newValue }
    }
    open override var lineBreakMode: NSLineBreakMode {
        get { super.lineBreakMode } set { super.lineBreakMode = newValue }
    }
    open override var hyphenationFactor: Float {
        get { super.hyphenationFactor } set { super.hyphenationFactor = newValue }
    }

    open func setParagraphStyle(_ obj: NSParagraphStyle) {
        _copyParagraphAttributes(from: obj)
    }
}
