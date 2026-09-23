// Auto Layout's visual format language:
// `NSLayoutConstraint.constraints(withVisualFormat:options:metrics:views:)`.
//
// Every rule below is MEASURED on the iOS 26.1 simulator
// (Tools/oracle2/podsurfaceprobe "## vfl"; ORStackView 2.0.0 builds its top
// constraint this way):
//   * A connection between two views makes ONE constraint per predicate whose
//     FIRST item is the later view: H `later.leading REL earlier.trailing + c`,
//     V `later.top REL earlier.bottom + c`.
//   * Leading superview `|`: `view.leading REL super.leading + c`; trailing
//     `|`: `super.trailing REL view.trailing + c` (first item the superview).
//   * The standard spacing `-` is 8 between siblings; next to `|` it is the
//     superview's layoutMarginsGuide edge with constant 0. No dash is 0.
//   * `[view(pred)]` sizes the view along the orientation: against a constant
//     (second item nil, attribute notAnAttribute) or another view's same
//     dimension. A view's size constraints follow its leading connection.
//   * `@p` sets the priority (default required); `==` is the default relation.
//   * An unknown view or metric name raises NSInvalidArgumentException.
//   * The default direction (NSLayoutFormatDirectionLeadingToTrailing = 0) uses
//     leading/trailing; left-to-right / right-to-left use left/right.
// The alignment options (NSLayoutFormatAlignAll…) are not measured and trap.

#if canImport(ObjectiveC) && canImport(Foundation)
import class Foundation.NSNumber
import class Foundation.NSException
import struct Foundation.NSExceptionName
#endif

extension NSLayoutConstraint {
    public struct FormatOptions: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let alignAllLeft = FormatOptions(rawValue: 1 << 1)
        public static let alignAllRight = FormatOptions(rawValue: 1 << 2)
        public static let alignAllTop = FormatOptions(rawValue: 1 << 3)
        public static let alignAllBottom = FormatOptions(rawValue: 1 << 4)
        public static let alignAllLeading = FormatOptions(rawValue: 1 << 5)
        public static let alignAllTrailing = FormatOptions(rawValue: 1 << 6)
        public static let alignAllCenterX = FormatOptions(rawValue: 1 << 9)
        public static let alignAllCenterY = FormatOptions(rawValue: 1 << 10)
        public static let alignAllLastBaseline = FormatOptions(rawValue: 1 << 11)
        public static let alignAllFirstBaseline = FormatOptions(rawValue: 1 << 12)
        public static let alignmentMask = FormatOptions(rawValue: 0xFFFF)
        public static let directionLeadingToTrailing = FormatOptions([])
        public static let directionLeftToRight = FormatOptions(rawValue: 1 << 16)
        public static let directionRightToLeft = FormatOptions(rawValue: 2 << 16)
        public static let directionMask = FormatOptions(rawValue: 0x3 << 16)
        public static let spacingEdgeToEdge = FormatOptions([])
        public static let spacingBaselineToBaseline = FormatOptions(rawValue: 1 << 19)
        public static let spacingMask = FormatOptions(rawValue: 0x1 << 19)
    }

    public class func constraints(withVisualFormat format: String, options opts: FormatOptions = [],
                                  metrics: [String: Any]?, views: [String: Any]) -> [NSLayoutConstraint] {
        precondition(opts.intersection(.alignmentMask).isEmpty,
                     "NSLayoutConstraint visual format: alignment options are not implemented (unmeasured)")
        precondition(opts.intersection(.spacingMask).isEmpty,
                     "NSLayoutConstraint visual format: baseline-to-baseline spacing is not implemented (unmeasured)")
        var parser = _VisualFormatParser(format: format, metrics: metrics ?? [:], views: views,
                                         direction: opts.intersection(.directionMask))
        return parser.parse()
    }
}

private struct _VisualFormatParser {
    struct Predicate {
        var relation: NSLayoutConstraint.Relation = .equal
        var constant: CGFloat = 0
        var view: AnyObject?
        var priority: Float = 1000
    }
    enum Connection {
        case none             // adjacent: 0
        case standard         // "-"
        case predicates([Predicate])
    }

    let chars: [Character]
    let format: String
    let metrics: [String: Any]
    let views: [String: Any]
    let direction: NSLayoutConstraint.FormatOptions
    var i = 0
    var vertical = false
    var result: [NSLayoutConstraint] = []

    init(format: String, metrics: [String: Any], views: [String: Any],
         direction: NSLayoutConstraint.FormatOptions) {
        self.format = format
        chars = Array(format.filter { !$0.isWhitespace })
        self.metrics = metrics
        self.views = views
        self.direction = direction
    }

    /// UIKit raises NSInvalidArgumentException (MEASURED: an unknown view
    /// name); where Objective-C exceptions exist, so does this.
    func fail(_ why: String) -> Never {
#if canImport(ObjectiveC) && canImport(Foundation)
        NSException(name: .invalidArgumentException,
                    reason: "Unable to parse constraint format: \(why)\n\(format)", userInfo: nil).raise()
#endif
        fatalError("NSInvalidArgumentException: Unable to parse constraint format: \(why)\n\(format)")
    }

    var peek: Character? { i < chars.count ? chars[i] : nil }
    mutating func eat(_ c: Character) -> Bool {
        if peek == c { i += 1; return true }
        return false
    }

    var leadingAttribute: NSLayoutConstraint.Attribute {
        if vertical { return .top }
        if direction == .directionLeftToRight { return .left }
        if direction == .directionRightToLeft { return .right }
        return .leading
    }
    var trailingAttribute: NSLayoutConstraint.Attribute {
        if vertical { return .bottom }
        if direction == .directionLeftToRight { return .right }
        if direction == .directionRightToLeft { return .left }
        return .trailing
    }
    var dimension: NSLayoutConstraint.Attribute { vertical ? .height : .width }

    mutating func identifier() -> String {
        let start = i
        while let c = peek, c.isLetter || c.isNumber || c == "_" { i += 1 }
        if start == i { fail("Expected a view or metric name") }
        return String(chars[start..<i])
    }

    mutating func number() -> CGFloat? {
        let start = i
        if peek == "-" || peek == "+" { i += 1 }
        while let c = peek, c.isNumber || c == "." { i += 1 }
        let text = String(chars[start..<i])
        guard !text.isEmpty, let value = Double(text) else { i = start; return nil }
        return CGFloat(value)
    }

    mutating func metricValue(_ name: String) -> CGFloat {
        guard let raw = metrics[name] else { fail("Unknown metric '\(name)'") }
        switch raw {
        case let v as CGFloat: return v
        case let v as Double: return CGFloat(v)
        case let v as Float: return CGFloat(v)
        case let v as Int: return CGFloat(v)
        default:
#if canImport(ObjectiveC) && canImport(Foundation)
            if let n = raw as? NSNumber { return CGFloat(n.doubleValue) }
#endif
            fail("Metric '\(name)' is not a number")
        }
    }

    mutating func view(named name: String) -> AnyObject {
        guard let v = views[name] else { fail("\(name) is not a key in the views dictionary") }
        return v as AnyObject
    }

    /// constant | metricName | viewName (a view only where `allowView`).
    mutating func predicate(allowView: Bool) -> Predicate {
        var p = Predicate()
        if eat("=") { guard eat("=") else { fail("Expected '=='") }; p.relation = .equal }
        else if eat("<") { guard eat("=") else { fail("Expected '<='") }; p.relation = .lessThanOrEqual }
        else if eat(">") { guard eat("=") else { fail("Expected '>='") }; p.relation = .greaterThanOrEqual }
        if let n = number() {
            p.constant = n
        } else {
            let name = identifier()
            if metrics[name] != nil {
                p.constant = metricValue(name)
            } else if allowView, views[name] != nil {
                p.view = view(named: name)
            } else {
                fail(allowView ? "\(name) is not a key in the views dictionary" : "Unknown metric '\(name)'")
            }
        }
        if eat("@") {
            if let n = number() { p.priority = Float(n) }
            else { p.priority = Float(metricValue(identifier())) }
        }
        return p
    }

    /// `(pred, pred…)` or a bare number / metric.
    mutating func predicateList(allowView: Bool) -> [Predicate] {
        if eat("(") {
            var list = [predicate(allowView: allowView)]
            while eat(",") { list.append(predicate(allowView: allowView)) }
            guard eat(")") else { fail("Expected ')'") }
            return list
        }
        return [predicate(allowView: allowView)]
    }

    /// After a `|` or `]`: nothing, `-`, or `-pred-`.
    mutating func connection() -> Connection? {
        guard eat("-") else {
            if peek == "[" || peek == "|" { return Connection.none }
            return nil
        }
        if peek == "[" || peek == "|" { return .standard }
        let list = predicateList(allowView: false)
        guard eat("-") else { fail("Expected '-' after the connection predicate") }
        return .predicates(list)
    }

    mutating func emit(first: AnyObject, _ a1: NSLayoutConstraint.Attribute,
                       second: AnyObject?, _ a2: NSLayoutConstraint.Attribute, _ p: Predicate) {
        let c = NSLayoutConstraint(item: first, attribute: a1, relatedBy: p.relation,
                                   toItem: second, attribute: a2, multiplier: 1, constant: p.constant)
        c.priority = UILayoutPriority(rawValue: p.priority)
        result.append(c)
    }

    /// `earlier` nil = the superview (leading `|`).
    mutating func connect(_ connection: Connection, from earlier: AnyObject?, to later: AnyObject,
                          superview: UIView?) {
        guard let earlier else {
            guard let superview else { fail("Unable to interpret '|' because the view has no superview") }
            switch connection {
            case .standard:
                emit(first: later, leadingAttribute, second: superview.layoutMarginsGuide, leadingAttribute, Predicate())
            case .none:
                emit(first: later, leadingAttribute, second: superview, leadingAttribute, Predicate())
            case .predicates(let list):
                for p in list { emit(first: later, leadingAttribute, second: superview, leadingAttribute, p) }
            }
            return
        }
        switch connection {
        case .standard:
            var p = Predicate(); p.constant = 8
            emit(first: later, leadingAttribute, second: earlier, trailingAttribute, p)
        case .none:
            emit(first: later, leadingAttribute, second: earlier, trailingAttribute, Predicate())
        case .predicates(let list):
            for p in list { emit(first: later, leadingAttribute, second: earlier, trailingAttribute, p) }
        }
    }

    mutating func connectToTrailingSuperview(_ connection: Connection, from view: AnyObject, superview: UIView?) {
        guard let superview else { fail("Unable to interpret '|' because the view has no superview") }
        switch connection {
        case .standard:
            emit(first: superview.layoutMarginsGuide, trailingAttribute, second: view, trailingAttribute, Predicate())
        case .none:
            emit(first: superview, trailingAttribute, second: view, trailingAttribute, Predicate())
        case .predicates(let list):
            for p in list { emit(first: superview, trailingAttribute, second: view, trailingAttribute, p) }
        }
    }

    mutating func parse() -> [NSLayoutConstraint] {
        if chars.count >= 2, chars[1] == ":" {
            switch chars[0] {
            case "H": vertical = false
            case "V": vertical = true
            default: fail("Expected 'H:' or 'V:'")
            }
            i = 2
        }
        var previous: AnyObject?
        var pending: Connection?
        var sawLeadingSuperview = false
        var superview: UIView?
        if eat("|") {
            sawLeadingSuperview = true
            guard let c = connection() else { fail("Expected a view after '|'") }
            pending = c
        }
        while eat("[") {
            let name = identifier()
            let v = view(named: name)
            if superview == nil { superview = (v as? UIView)?.superview }
            if let c = pending {
                connect(c, from: previous, to: v, superview: previous == nil && sawLeadingSuperview ? superview : nil)
            }
            if eat("(") {
                i -= 1
                for p in predicateList(allowView: true) {
                    emit(first: v, dimension, second: p.view, p.view == nil ? .notAnAttribute : dimension, p)
                }
            }
            guard eat("]") else { fail("Expected ']'") }
            previous = v
            pending = connection()
            if pending == nil { break }
            if peek == "|" {
                i += 1
                connectToTrailingSuperview(pending!, from: v, superview: superview)
                pending = nil
                break
            }
        }
        if previous == nil { fail("A visual format must contain a view") }
        if i != chars.count { fail("Unexpected '\(chars[i])'") }
        return result
    }
}
