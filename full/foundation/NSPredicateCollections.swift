// Canonical predicate and reference-dictionary identities used by first-party
// frameworks in Linux-hosted Mach-O guests.
//
// Predicates implement constant, block, and the Apple-oracled format grammar
// (comparisons, string operators including [c], IN, BETWEEN, AND/OR/NOT, SELF,
// variables, TRUEPREDICATE/FALSEPREDICATE, and key paths). Unsupported syntax
// fails closed. Dictionaries implement real key copying, equality, mutation,
// and copying; persistence and fast enumeration remain later Foundation work.

#if FOUNDATION_CANONICAL_CONTRACTS_HOST
import Foundation
#else
#if FOUNDATION_GUEST_SERVICES_HOST
import Foundation
#else
import FoundationEssentials
import ObjectiveC
#endif
import Synchronization

// MARK: - Predicate AST

private enum _FoundationCompoundLogic {
    case not, and, or
}

private enum _FoundationPredicateOperator {
    case equal, notEqual
    case greaterThan, greaterThanOrEqual
    case lessThan, lessThanOrEqual
    case beginsWith, endsWith, contains, like, matches
    case `in`, between
}

private enum _FoundationExpression {
    case keyPath(String)
    case evaluatedObject
    case variable(String)
    case constant(Any?)
    case aggregate([_FoundationExpression])
}

private struct _FoundationComparison {
    var op: _FoundationPredicateOperator
    var left: _FoundationExpression
    var right: _FoundationExpression
    var caseInsensitive: Bool
}

private enum _FoundationPredicateKind {
    case constant(Bool)
    case block((Any?, [String: Any]?) -> Bool)
    case comparison(_FoundationComparison)
    case compound(_FoundationCompoundLogic, [NSPredicate])
}

private enum _FoundationPredicateArchiveTransport {
    private enum Snapshot: Sendable {
        case constant(Bool)
        case unsupported
    }

    private struct State: Sendable {
        var snapshots: [ObjectIdentifier: Snapshot] = [:]
        var order: [ObjectIdentifier] = []
    }

    private static let capacity = 64
    private static let state = Mutex(State())

    static func storeConstant(_ value: Bool, for coder: NSCoder) {
        store(.constant(value), for: coder)
    }

    static func storeUnsupported(for coder: NSCoder) {
        store(.unsupported, for: coder)
    }

    static func constant(for coder: NSCoder) -> Bool? {
        state.withLock { state in
            guard case .constant(let value) =
                    state.snapshots[ObjectIdentifier(coder)] else {
                return nil
            }
            return value
        }
    }

    private static func store(_ snapshot: Snapshot, for coder: NSCoder) {
        let identifier = ObjectIdentifier(coder)
        state.withLock { state in
            state.snapshots[identifier] = snapshot
            state.order.removeAll { $0 == identifier }
            state.order.append(identifier)
            while state.order.count > capacity {
                let evicted = state.order.removeFirst()
                state.snapshots.removeValue(forKey: evicted)
            }
        }
    }
}

// MARK: - Format interpolation

private func _foundationInterpolatePredicateFormat(
    _ format: String,
    arguments: [Any]?
) -> String? {
    var result = ""
    var argIndex = 0
    var index = format.startIndex
    while index < format.endIndex {
        let character = format[index]
        if character == "%" {
            let next = format.index(after: index)
            guard next < format.endIndex else { return nil }
            switch format[next] {
            case "%":
                result.append("%")
                index = format.index(after: next)
            case "@":
                guard let arguments, argIndex < arguments.count else { return nil }
                result.append(
                    _foundationFormatPredicateArgument(arguments[argIndex])
                )
                argIndex += 1
                index = format.index(after: next)
            default:
                return nil
            }
            continue
        }
        result.append(character)
        index = format.index(after: index)
    }
    return result
}

private func _foundationFormatPredicateArgument(_ value: Any) -> String {
    if let string = value as? String {
        return "\"\(string)\""
    }
    if let string = value as? NSString {
        return "\"\(string.description)\""
    }
    if let number = value as? Int { return String(number) }
    if let number = value as? Int64 { return String(number) }
    if let number = value as? Double { return String(number) }
    if let number = value as? Bool { return number ? "1" : "0" }
    if let number = value as? NSNumber { return number.stringValue }
    return "\"\(String(describing: value))\""
}

// MARK: - Parser

private struct _FoundationPredicateFormatParser {
    let source: String
    var index: String.Index

    init(source: String) {
        self.source = source
        self.index = source.startIndex
    }

    mutating func parseTop() -> _FoundationPredicateKind? {
        guard let kind = parseOr() else { return nil }
        skip()
        guard index >= source.endIndex else { return nil }
        return kind
    }

    mutating func parseOr() -> _FoundationPredicateKind? {
        guard let first = parseAnd() else { return nil }
        var terms: [NSPredicate] = []
        while takeKeyword("OR") {
            if terms.isEmpty { terms.append(NSPredicate(kind: first)) }
            guard let next = parseAnd() else { return nil }
            terms.append(NSPredicate(kind: next))
        }
        return terms.isEmpty ? first : .compound(.or, terms)
    }

    mutating func parseAnd() -> _FoundationPredicateKind? {
        guard let first = parseNot() else { return nil }
        var terms: [NSPredicate] = []
        while takeKeyword("AND") {
            if terms.isEmpty { terms.append(NSPredicate(kind: first)) }
            guard let next = parseNot() else { return nil }
            terms.append(NSPredicate(kind: next))
        }
        return terms.isEmpty ? first : .compound(.and, terms)
    }

    mutating func parseNot() -> _FoundationPredicateKind? {
        if takeKeyword("NOT") {
            guard let inner = parseNot() else { return nil }
            return .compound(.not, [NSPredicate(kind: inner)])
        }
        if takeSymbol("(") {
            guard let inner = parseOr() else { return nil }
            guard takeSymbol(")") else { return nil }
            return inner
        }
        return parseComparison()
    }

    mutating func parseComparison() -> _FoundationPredicateKind? {
        if takeKeyword("TRUEPREDICATE") { return .constant(true) }
        if takeKeyword("FALSEPREDICATE") { return .constant(false) }
        guard let left = parseExpression() else { return nil }
        if takeKeyword("BEGINSWITH") {
            return parseStringOperator(.beginsWith, left: left)
        }
        if takeKeyword("ENDSWITH") {
            return parseStringOperator(.endsWith, left: left)
        }
        if takeKeyword("CONTAINS") {
            return parseStringOperator(.contains, left: left)
        }
        if takeKeyword("LIKE") {
            return parseStringOperator(.like, left: left)
        }
        if takeKeyword("MATCHES") {
            return parseStringOperator(.matches, left: left)
        }
        if takeKeyword("IN") {
            guard let right = parseExpression() else { return nil }
            return .comparison(
                _FoundationComparison(
                    op: .in, left: left, right: right, caseInsensitive: false
                )
            )
        }
        if takeKeyword("BETWEEN") {
            guard let right = parseExpression() else { return nil }
            return .comparison(
                _FoundationComparison(
                    op: .between, left: left, right: right, caseInsensitive: false
                )
            )
        }
        let op: _FoundationPredicateOperator
        if takeSymbol("==") { op = .equal }
        else if takeSymbol("!=") { op = .notEqual }
        else if takeSymbol(">=") { op = .greaterThanOrEqual }
        else if takeSymbol("<=") { op = .lessThanOrEqual }
        else if takeSymbol(">") { op = .greaterThan }
        else if takeSymbol("<") { op = .lessThan }
        else { return nil }
        guard let right = parseExpression() else { return nil }
        return .comparison(
            _FoundationComparison(
                op: op, left: left, right: right, caseInsensitive: false
            )
        )
    }

    mutating func parseStringOperator(
        _ op: _FoundationPredicateOperator,
        left: _FoundationExpression
    ) -> _FoundationPredicateKind? {
        guard let caseInsensitive = takeCaseModifier() else { return nil }
        guard let right = parseExpression() else { return nil }
        return .comparison(
            _FoundationComparison(
                op: op,
                left: left,
                right: right,
                caseInsensitive: caseInsensitive
            )
        )
    }

    mutating func parseExpression() -> _FoundationExpression? {
        skip()
        if let string = takeString() { return .constant(string) }
        if takeSymbol("{") { return parseAggregateBody() }
        if takeSymbol("$") {
            guard let name = takeIdentifier() else { return nil }
            return .variable(name)
        }
        if let number = takeNumber() { return number }
        if takeKeyword("YES") || takeKeyword("TRUE") { return .constant(1) }
        if takeKeyword("NO") || takeKeyword("FALSE") { return .constant(0) }
        if takeKeyword("SELF") { return .evaluatedObject }
        guard let path = takeKeyPath() else { return nil }
        switch path {
        case "AND", "OR", "NOT", "IN", "BETWEEN",
             "BEGINSWITH", "ENDSWITH", "CONTAINS", "LIKE", "MATCHES",
             "TRUEPREDICATE", "FALSEPREDICATE", "YES", "NO", "TRUE", "FALSE",
             "SELF":
            return nil
        default:
            return .keyPath(path)
        }
    }

    mutating func parseAggregateBody() -> _FoundationExpression? {
        skip()
        if takeSymbol("}") { return .aggregate([]) }
        var items: [_FoundationExpression] = []
        while true {
            guard let item = parseExpression() else { return nil }
            items.append(item)
            skip()
            if takeSymbol("}") { return .aggregate(items) }
            guard takeSymbol(",") else { return nil }
        }
    }

    mutating func takeCaseModifier() -> Bool? {
        skip()
        guard takeSymbol("[") else { return false }
        skip()
        guard index < source.endIndex, source[index] == "c" else { return nil }
        let afterC = source.index(after: index)
        guard afterC < source.endIndex, source[afterC] == "]" else { return nil }
        index = source.index(after: afterC)
        return true
    }

    mutating func takeString() -> String? {
        skip()
        guard index < source.endIndex else { return nil }
        let quote = source[index]
        guard quote == "\"" || quote == "'" else { return nil }
        index = source.index(after: index)
        var result = ""
        while index < source.endIndex {
            let character = source[index]
            if character == "\\" {
                let next = source.index(after: index)
                guard next < source.endIndex else { return nil }
                result.append(source[next])
                index = source.index(after: next)
                continue
            }
            if character == quote {
                index = source.index(after: index)
                return result
            }
            result.append(character)
            index = source.index(after: index)
        }
        return nil
    }

    mutating func takeNumber() -> _FoundationExpression? {
        skip()
        guard index < source.endIndex, source[index].isNumber else { return nil }
        let start = index
        while index < source.endIndex, source[index].isNumber {
            index = source.index(after: index)
        }
        var isReal = false
        if index < source.endIndex, source[index] == "." {
            let next = source.index(after: index)
            if next < source.endIndex, source[next].isNumber {
                isReal = true
                index = next
                while index < source.endIndex, source[index].isNumber {
                    index = source.index(after: index)
                }
            }
        }
        let text = String(source[start..<index])
        if isReal {
            guard let value = Double(text) else { return nil }
            return .constant(value)
        }
        guard let value = Int(text) else { return nil }
        return .constant(value)
    }

    mutating func takeKeyPath() -> String? {
        guard let first = takeIdentifier() else { return nil }
        var parts = [first]
        while takeSymbol(".") {
            guard let next = takeIdentifier() else { return nil }
            parts.append(next)
        }
        return parts.joined(separator: ".")
    }

    mutating func takeIdentifier() -> String? {
        skip()
        guard index < source.endIndex else { return nil }
        let first = source[index]
        guard first.isLetter || first == "_" else { return nil }
        let start = index
        index = source.index(after: index)
        while index < source.endIndex {
            let character = source[index]
            if character.isLetter || character.isNumber || character == "_" {
                index = source.index(after: index)
            } else {
                break
            }
        }
        return String(source[start..<index])
    }

    mutating func takeKeyword(_ word: String) -> Bool {
        skip()
        guard let end = source.index(
            index, offsetBy: word.count, limitedBy: source.endIndex
        ), source[index..<end] == word else { return false }
        if end < source.endIndex {
            let next = source[end]
            if next.isLetter || next.isNumber || next == "_" { return false }
        }
        index = end
        return true
    }

    mutating func takeSymbol(_ symbol: String) -> Bool {
        skip()
        guard let end = source.index(
            index, offsetBy: symbol.count, limitedBy: source.endIndex
        ), source[index..<end] == symbol else { return false }
        index = end
        return true
    }

    mutating func skip() {
        while index < source.endIndex, source[index].isWhitespace {
            index = source.index(after: index)
        }
    }
}

private func _parseFoundationPredicateFormat(
    _ format: String
) -> _FoundationPredicateKind? {
    var parser = _FoundationPredicateFormatParser(source: format)
    return parser.parseTop()
}

// MARK: - Evaluation

private func _foundationPredicateUnwrap(_ value: Any?) -> Any? {
    guard let value else { return nil }
    if value is NSNull { return nil }
    let mirror = Mirror(reflecting: value)
    if mirror.displayStyle == .optional {
        guard let child = mirror.children.first else { return nil }
        return _foundationPredicateUnwrap(child.value)
    }
    return value
}

private func _foundationPredicateStrictString(_ value: Any?) -> String? {
    let value = _foundationPredicateUnwrap(value)
    if let string = value as? String { return string }
    if let string = value as? NSString { return string.description }
    return nil
}

private func _foundationPredicateIsNumeric(_ value: Any) -> Bool {
    value is Int || value is Int8 || value is Int16 || value is Int32
        || value is Int64 || value is UInt || value is UInt8 || value is UInt16
        || value is UInt32 || value is UInt64 || value is Double || value is Float
        || value is Bool || value is NSNumber
}

private func _foundationPredicateDouble(_ value: Any?) -> Double? {
    let value = _foundationPredicateUnwrap(value)
    switch value {
    case let number as Double: return number
    case let number as Float: return Double(number)
    case let number as Int: return Double(number)
    case let number as Int8: return Double(number)
    case let number as Int16: return Double(number)
    case let number as Int32: return Double(number)
    case let number as Int64: return Double(number)
    case let number as UInt: return Double(number)
    case let number as UInt8: return Double(number)
    case let number as UInt16: return Double(number)
    case let number as UInt32: return Double(number)
    case let number as UInt64: return Double(number)
    case let number as Bool: return number ? 1 : 0
    case let number as NSNumber: return number.doubleValue
    default: return nil
    }
}

private func _foundationPredicateArray(_ value: Any?) -> [Any]? {
    let value = _foundationPredicateUnwrap(value)
    if let array = value as? [Any] { return array }
    if let array = value as? [String] { return array }
    if let array = value as? [Int] { return array }
    if let array = value as? [Double] { return array }
    if let array = value as? NSArray {
        return (0..<array.count).map { array.object(at: $0) }
    }
    return nil
}

private func _foundationPredicateEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
    let left = _foundationPredicateUnwrap(lhs)
    let right = _foundationPredicateUnwrap(rhs)
    if left == nil && right == nil { return true }
    guard let left, let right else { return false }
    if let leftString = _foundationPredicateStrictString(left),
       let rightString = _foundationPredicateStrictString(right) {
        return leftString == rightString
    }
    if _foundationPredicateIsNumeric(left),
       _foundationPredicateIsNumeric(right),
       let leftNumber = _foundationPredicateDouble(left),
       let rightNumber = _foundationPredicateDouble(right) {
        return leftNumber == rightNumber
    }
    if let object = left as? NSObject { return object.isEqual(right) }
    if let object = right as? NSObject { return object.isEqual(left) }
    return false
}

private func _foundationPredicateCompare(
    _ lhs: Any?,
    _ rhs: Any?
) -> ComparisonResult? {
    let left = _foundationPredicateUnwrap(lhs)
    let right = _foundationPredicateUnwrap(rhs)
    if let left, let right,
       _foundationPredicateIsNumeric(left),
       _foundationPredicateIsNumeric(right),
       let leftNumber = _foundationPredicateDouble(left),
       let rightNumber = _foundationPredicateDouble(right) {
        if leftNumber < rightNumber { return .orderedAscending }
        if leftNumber > rightNumber { return .orderedDescending }
        return .orderedSame
    }
    if let leftString = _foundationPredicateStrictString(left),
       let rightString = _foundationPredicateStrictString(right) {
        if leftString < rightString { return .orderedAscending }
        if leftString > rightString { return .orderedDescending }
        return .orderedSame
    }
    return nil
}

private func _foundationLike(_ value: String, pattern: String) -> Bool {
    let haystack = Array(value)
    let needle = Array(pattern)
    var vi = 0
    var pi = 0
    var star = -1
    var match = 0
    while vi < haystack.count {
        if pi < needle.count && (needle[pi] == "?" || needle[pi] == haystack[vi]) {
            vi += 1
            pi += 1
        } else if pi < needle.count && needle[pi] == "*" {
            star = pi
            pi += 1
            match = vi
        } else if star != -1 {
            pi = star + 1
            match += 1
            vi = match
        } else {
            return false
        }
    }
    while pi < needle.count && needle[pi] == "*" { pi += 1 }
    return pi == needle.count
}

private func _foundationPredicateStringOp(
    _ lhs: Any?,
    _ rhs: Any?,
    caseInsensitive: Bool,
    _ body: (String, String) -> Bool
) -> Bool {
    guard var left = _foundationPredicateStrictString(lhs),
          var right = _foundationPredicateStrictString(rhs) else {
        return false
    }
    if caseInsensitive {
        left = left.lowercased()
        right = right.lowercased()
    }
    return body(left, right)
}

private func _evaluateFoundationExpression(
    _ expression: _FoundationExpression,
    object: Any?,
    bindings: [String: Any]?
) -> Any? {
    switch expression {
    case .evaluatedObject:
        return object
    case .keyPath(let path):
        return _foundationPredicateValue(forKeyPath: path, object: object)
    case .variable(let name):
        return bindings?[name]
    case .constant(let value):
        return value
    case .aggregate(let items):
        return items.map {
            _evaluateFoundationExpression($0, object: object, bindings: bindings)
                as Any
        }
    }
}

private func _evaluateFoundationComparison(
    _ comparison: _FoundationComparison,
    object: Any?,
    bindings: [String: Any]?
) -> Bool {
    let left = _evaluateFoundationExpression(
        comparison.left, object: object, bindings: bindings
    )
    let right = _evaluateFoundationExpression(
        comparison.right, object: object, bindings: bindings
    )
    switch comparison.op {
    case .equal:
        return _foundationPredicateEqual(left, right)
    case .notEqual:
        return !_foundationPredicateEqual(left, right)
    case .greaterThan:
        return _foundationPredicateCompare(left, right) == .orderedDescending
    case .greaterThanOrEqual:
        guard let order = _foundationPredicateCompare(left, right) else { return false }
        return order != .orderedAscending
    case .lessThan:
        return _foundationPredicateCompare(left, right) == .orderedAscending
    case .lessThanOrEqual:
        guard let order = _foundationPredicateCompare(left, right) else { return false }
        return order != .orderedDescending
    case .beginsWith:
        return _foundationPredicateStringOp(
            left, right, caseInsensitive: comparison.caseInsensitive, { $0.hasPrefix($1) }
        )
    case .endsWith:
        return _foundationPredicateStringOp(
            left, right, caseInsensitive: comparison.caseInsensitive, { $0.hasSuffix($1) }
        )
    case .contains:
        return _foundationPredicateStringOp(
            left, right, caseInsensitive: comparison.caseInsensitive, { $0.contains($1) }
        )
    case .like:
        return _foundationPredicateStringOp(
            left, right, caseInsensitive: comparison.caseInsensitive, _foundationLike
        )
    case .matches:
        guard let value = _foundationPredicateStrictString(left),
              let pattern = _foundationPredicateStrictString(right) else {
            return false
        }
        var options: String.CompareOptions = .regularExpression
        if comparison.caseInsensitive { options.insert(.caseInsensitive) }
        return value.range(of: pattern, options: options) != nil
    case .in:
        guard let items = _foundationPredicateArray(right) else { return false }
        return items.contains { _foundationPredicateEqual(left, $0) }
    case .between:
        guard let items = _foundationPredicateArray(right), items.count == 2 else {
            return false
        }
        guard let lower = _foundationPredicateCompare(items[0], left),
              let upper = _foundationPredicateCompare(left, items[1]) else {
            return false
        }
        return lower != .orderedDescending && upper != .orderedDescending
    }
}

private func _evaluateFoundationPredicateKind(
    _ kind: _FoundationPredicateKind,
    object: Any?,
    bindings: [String: Any]?
) -> Bool {
    switch kind {
    case .constant(let value):
        return value
    case .block(let evaluator):
        return evaluator(object, bindings)
    case .comparison(let comparison):
        return _evaluateFoundationComparison(
            comparison, object: object, bindings: bindings
        )
    case .compound(let logic, let subpredicates):
        switch logic {
        case .and:
            return subpredicates.allSatisfy {
                $0.evaluate(with: object, substitutionVariables: bindings)
            }
        case .or:
            return subpredicates.contains {
                $0.evaluate(with: object, substitutionVariables: bindings)
            }
        case .not:
            guard let inner = subpredicates.first else { return true }
            return !inner.evaluate(with: object, substitutionVariables: bindings)
        }
    }
}

// MARK: - Format printing

private func _foundationFormatConstant(_ value: Any?) -> String {
    guard let value else { return "nil" }
    if let string = value as? String { return "\"\(string)\"" }
    if let string = value as? NSString { return "\"\(string.description)\"" }
    if let number = value as? Int { return String(number) }
    if let number = value as? Int64 { return String(number) }
    if let number = value as? Double { return String(number) }
    if let number = value as? Bool { return number ? "1" : "0" }
    if let number = value as? NSNumber { return number.stringValue }
    return "\"\(String(describing: value))\""
}

private func _foundationFormatExpression(_ expression: _FoundationExpression) -> String {
    switch expression {
    case .keyPath(let path):
        return path
    case .evaluatedObject:
        return "SELF"
    case .variable(let name):
        return "$\(name)"
    case .constant(let value):
        return _foundationFormatConstant(value)
    case .aggregate(let items):
        let body = items.map(_foundationFormatExpression).joined(separator: ", ")
        return "{\(body)}"
    }
}

private func _foundationFormatOperator(
    _ op: _FoundationPredicateOperator,
    caseInsensitive: Bool
) -> String {
    let token: String
    switch op {
    case .equal: token = "=="
    case .notEqual: token = "!="
    case .greaterThan: token = ">"
    case .greaterThanOrEqual: token = ">="
    case .lessThan: token = "<"
    case .lessThanOrEqual: token = "<="
    case .beginsWith: token = "BEGINSWITH"
    case .endsWith: token = "ENDSWITH"
    case .contains: token = "CONTAINS"
    case .like: token = "LIKE"
    case .matches: token = "MATCHES"
    case .in: token = "IN"
    case .between: token = "BETWEEN"
    }
    switch op {
    case .beginsWith, .endsWith, .contains, .like, .matches:
        return caseInsensitive ? "\(token)[c]" : token
    default:
        return token
    }
}

private func _foundationFormatKind(_ kind: _FoundationPredicateKind) -> String {
    switch kind {
    case .constant(true):
        return "TRUEPREDICATE"
    case .constant(false):
        return "FALSEPREDICATE"
    case .block:
        return "BLOCKPREDICATE"
    case .comparison(let comparison):
        let op = _foundationFormatOperator(
            comparison.op, caseInsensitive: comparison.caseInsensitive
        )
        return "\(_foundationFormatExpression(comparison.left)) \(op) \(_foundationFormatExpression(comparison.right))"
    case .compound(let logic, let subpredicates):
        let parts = subpredicates.map(\.predicateFormat)
        switch logic {
        case .and:
            return parts.joined(separator: " AND ")
        case .or:
            return parts.joined(separator: " OR ")
        case .not:
            return "NOT \(parts.first ?? "TRUEPREDICATE")"
        }
    }
}

// MARK: - KVC

private func _foundationPredicateValue(forKey key: String, object: Any) -> Any? {
    if let dictionary = object as? [String: Any] { return dictionary[key] }
    if let dictionary = object as? NSDictionary { return dictionary.object(forKey: key) }
    let mirror = Mirror(reflecting: object)
    var current: Mirror? = mirror
    while let layer = current {
        for child in layer.children {
            if child.label == key {
                return _foundationPredicateUnwrap(child.value)
            }
        }
        current = layer.superclassMirror
    }
    #if FOUNDATION_GUEST_SERVICES_HOST
    if let object = object as? NSObject {
        return object.value(forKey: key)
    }
    #else
    if let object = object as? NSObject,
       object.responds(to: Selector("valueForKey:")) {
        return object.value(forKey: key)
    }
    #endif
    return nil
}

private func _foundationPredicateValue(forKeyPath path: String, object: Any?) -> Any? {
    guard let object else { return nil }
    #if FOUNDATION_GUEST_SERVICES_HOST
    if let object = object as? NSObject {
        return object.value(forKeyPath: path)
    }
    #endif
    var current: Any? = object
    for key in path.split(separator: ".").map(String.init) {
        guard let value = current else { return nil }
        current = _foundationPredicateValue(forKey: key, object: value)
    }
    return current
}

#if !FOUNDATION_GUEST_SERVICES_HOST
public extension NSObject {
    func value(forKeyPath keyPath: String) -> Any? {
        _foundationPredicateValue(forKeyPath: keyPath, object: self)
    }
}
#endif

// MARK: - Predicate

/// A predicate with production constant, block, and format evaluation.
///
/// Format parsing covers the Apple-oracled grammar only. Unsupported syntax
/// fails closed. Block and format predicates do not round-trip through the
/// opaque guest coder; constant predicates do.
open class NSPredicate: NSObject, NSCopying, NSSecureCoding {
    fileprivate let kind: _FoundationPredicateKind

    open class var supportsSecureCoding: Bool { true }

    public init(value: Bool) {
        kind = .constant(value)
        super.init()
    }

    public init(
        block: @escaping (Any?, [String: Any]?) -> Bool
    ) {
        kind = .block(block)
        super.init()
    }

    fileprivate init(kind: _FoundationPredicateKind) {
        self.kind = kind
        super.init()
    }

    public convenience init(format predicateFormat: String) {
        self.init(format: predicateFormat, argumentArray: nil)
    }

    public convenience init(
        format predicateFormat: String,
        argumentArray arguments: [Any]?
    ) {
        guard let interpolated = _foundationInterpolatePredicateFormat(
            predicateFormat, arguments: arguments
        ), let kind = _parseFoundationPredicateFormat(interpolated) else {
            fatalError(
                "NSInvalidArgumentException: Unable to parse the format string \"\(predicateFormat)\""
            )
        }
        self.init(kind: kind)
    }

    public convenience init(format predicateFormat: String, _ args: CVarArg...) {
        self.init(
            format: predicateFormat,
            argumentArray: args.map { $0 as Any }
        )
    }

    public required init?(coder: NSCoder) {
        guard let value = _FoundationPredicateArchiveTransport.constant(
            for: coder
        ) else { return nil }
        kind = .constant(value)
        super.init()
    }

    open var predicateFormat: String {
        _foundationFormatKind(kind)
    }

    open func evaluate(with object: Any?) -> Bool {
        evaluate(with: object, substitutionVariables: nil)
    }

    open func evaluate(
        with object: Any?,
        substitutionVariables bindings: [String: Any]?
    ) -> Bool {
        _evaluateFoundationPredicateKind(kind, object: object, bindings: bindings)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }

    open override func copy() -> Any { copy(with: nil) }

    open func encode(with coder: NSCoder) {
        switch kind {
        case .constant(let value):
            _FoundationPredicateArchiveTransport.storeConstant(
                value,
                for: coder
            )
        default:
            _FoundationPredicateArchiveTransport.storeUnsupported(for: coder)
        }
    }
}

// MARK: - Compound predicate

open class NSCompoundPredicate: NSPredicate {
    public enum LogicalType: UInt, Sendable {
        case not = 0
        case and = 1
        case or = 2
    }

    public init(type: LogicalType, subpredicates: [NSPredicate]) {
        let logic: _FoundationCompoundLogic
        switch type {
        case .not: logic = .not
        case .and: logic = .and
        case .or: logic = .or
        }
        super.init(kind: .compound(logic, subpredicates))
    }

    public convenience init(andPredicateWithSubpredicates subpredicates: [NSPredicate]) {
        self.init(type: .and, subpredicates: subpredicates)
    }

    public convenience init(orPredicateWithSubpredicates subpredicates: [NSPredicate]) {
        self.init(type: .or, subpredicates: subpredicates)
    }

    public convenience init(notPredicateWithSubpredicate predicate: NSPredicate) {
        self.init(type: .not, subpredicates: [predicate])
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open var compoundPredicateType: LogicalType {
        guard case .compound(let logic, _) = kind else { return .and }
        switch logic {
        case .not: return .not
        case .and: return .and
        case .or: return .or
        }
    }

    open var subpredicates: [Any] {
        guard case .compound(_, let subpredicates) = kind else { return [] }
        return subpredicates
    }
}

// MARK: - Expression

open class NSExpression: NSObject {
    private enum Storage {
        case constant(Any?)
        case keyPath(String)
        case variable(String)
        case function(String, [NSExpression])
        case evaluatedObject
    }

    private let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
        super.init()
    }

    public convenience init(forConstantValue obj: Any?) {
        self.init(storage: .constant(obj))
    }

    public convenience init(forKeyPath keyPath: String) {
        self.init(storage: .keyPath(keyPath))
    }

    public convenience init(forVariable string: String) {
        self.init(storage: .variable(string))
    }

    public convenience init(
        forFunction name: String,
        arguments parameters: [NSExpression]
    ) {
        self.init(storage: .function(name, parameters))
    }

    public class func expressionForEvaluatedObject() -> NSExpression {
        NSExpression(storage: .evaluatedObject)
    }

    open var keyPath: String {
        guard case .keyPath(let path) = storage else { return "" }
        return path
    }

    open var constantValue: Any? {
        guard case .constant(let value) = storage else { return nil }
        return value
    }

    open func expressionValue(
        with object: Any?,
        context: NSMutableDictionary?
    ) -> Any? {
        switch storage {
        case .constant(let value):
            return value
        case .keyPath(let path):
            return _foundationPredicateValue(forKeyPath: path, object: object)
        case .variable(let name):
            return context?.object(forKey: name)
        case .evaluatedObject:
            return object
        case .function(let name, let arguments):
            return _evaluateFoundationFunction(
                name, arguments: arguments, object: object, context: context
            )
        }
    }
}

private func _evaluateFoundationFunction(
    _ name: String,
    arguments: [NSExpression],
    object: Any?,
    context: NSMutableDictionary?
) -> Any? {
    let values = arguments.map {
        $0.expressionValue(with: object, context: context)
    }
    switch name {
    case "add:to:":
        guard values.count >= 2 else { return nil }
        if let left = values[0] as? Int, let right = values[1] as? Int {
            return left + right
        }
        guard let left = _foundationPredicateDouble(values[0]),
              let right = _foundationPredicateDouble(values[1]) else {
            return nil
        }
        return left + right
    default:
        return nil
    }
}

// MARK: - Sort descriptor

/// The app-facing Foundation identity for an Objective-C key sort descriptor.
open class NSSortDescriptor: NSObject, @unchecked Sendable {
    public let key: String?
    public let ascending: Bool
    public let selector: Selector?
    private let capturedKeyPath: AnyKeyPath?

    public init(key: String?, ascending: Bool, selector: Selector?, keyPath: AnyKeyPath?) {
        self.key = key
        self.ascending = ascending
        self.selector = selector
        self.capturedKeyPath = keyPath
        super.init()
    }

    public convenience init(key: String?, ascending: Bool) {
        self.init(key: key, ascending: ascending, selector: nil, keyPath: nil)
    }

    public convenience init(key: String?, ascending: Bool, selector: Selector?) {
        self.init(key: key, ascending: ascending, selector: selector, keyPath: nil)
    }

    public convenience init<Root, Value>(
        keyPath: KeyPath<Root, Value>,
        ascending: Bool
    ) {
        self.init(
            key: keyPath._kvcKeyPathString,
            ascending: ascending,
            selector: nil,
            keyPath: keyPath
        )
    }

    open var keyPath: AnyKeyPath? { capturedKeyPath }

    open var reversedSortDescriptor: Any {
        NSSortDescriptor(
            key: key,
            ascending: !ascending,
            selector: selector,
            keyPath: capturedKeyPath
        )
    }

    open func compare(_ object1: Any, to object2: Any) -> ComparisonResult {
        let left: Any?
        let right: Any?
        if let key, !key.isEmpty {
            left = _foundationPredicateValue(forKeyPath: key, object: object1)
            right = _foundationPredicateValue(forKeyPath: key, object: object2)
        } else {
            left = object1
            right = object2
        }
        let raw = _foundationSortCompare(left, right, selector: selector)
        return ascending ? raw : _foundationReverseComparison(raw)
    }
}

private func _foundationReverseComparison(_ order: ComparisonResult) -> ComparisonResult {
    switch order {
    case .orderedAscending: return .orderedDescending
    case .orderedDescending: return .orderedAscending
    default: return .orderedSame
    }
}

private func _foundationSortCompare(
    _ lhs: Any?,
    _ rhs: Any?,
    selector: Selector?
) -> ComparisonResult {
    if let selector, NSStringFromSelector(selector) == "localizedStandardCompare:" {
        let left = _foundationPredicateStrictString(lhs) ?? ""
        let right = _foundationPredicateStrictString(rhs) ?? ""
        #if FOUNDATION_GUEST_SERVICES_HOST
        return left.localizedStandardCompare(right)
        #else
        if left == right { return .orderedSame }
        return left < right ? .orderedAscending : .orderedDescending
        #endif
    }
    if let order = _foundationPredicateCompare(lhs, rhs) {
        return order
    }
    let left = _foundationPredicateStrictString(lhs) ?? String(describing: lhs ?? "")
    let right = _foundationPredicateStrictString(rhs) ?? String(describing: rhs ?? "")
    if left == right { return .orderedSame }
    return left < right ? .orderedAscending : .orderedDescending
}

// MARK: - Reference dictionaries

private struct _FoundationDictionaryEntry: @unchecked Sendable {
    var key: Any
    var value: Any
}

private func _foundationDictionaryKeysEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    if let object = lhs as? NSObject, object.isEqual(rhs) {
        return true
    }
    if let object = rhs as? NSObject, object.isEqual(lhs) {
        return true
    }
    if let lhs = lhs as? AnyHashable,
       let rhs = rhs as? AnyHashable {
        return lhs == rhs
    }
    if Mirror(reflecting: lhs).displayStyle == .class,
       Mirror(reflecting: rhs).displayStyle == .class {
        return ObjectIdentifier(lhs as AnyObject)
            == ObjectIdentifier(rhs as AnyObject)
    }
    return false
}

// Decode the complete plist value graph, independent of any application's schema.
private enum _FoundationPlistValue: Decodable {
    case string(String), bool(Bool), integer(Int64), real(Double), data(Data), date(Date)
    case array([Self]), dictionary([String: Self])
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Int64.self) { self = .integer(value) }
        else if let value = try? container.decode(Double.self) { self = .real(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode(Data.self) { self = .data(value) }
        else if let value = try? container.decode(Date.self) { self = .date(value) }
        else if let value = try? container.decode([Self].self) { self = .array(value) }
        else { self = .dictionary(try container.decode([String: Self].self)) }
    }
    var object: Any {
        switch self {
        case .string(let value): return value
        case .bool(let value): return value
        case .integer(let value): return value
        case .real(let value): return value
        case .data(let value): return value
        case .date(let value): return value
        case .array(let value): return value.map(\.object)
        case .dictionary(let value): return value.mapValues(\.object)
        }
    }
}

/// Immutable reference dictionary base for the Foundation class cluster.
open class NSDictionary: NSObject, NSCopying, @unchecked Sendable {
    fileprivate let entries: Mutex<[_FoundationDictionaryEntry]>

    public override init() {
        entries = Mutex([])
        super.init()
    }

    fileprivate init(entries: [_FoundationDictionaryEntry]) {
        self.entries = Mutex(entries)
        super.init()
    }

    public convenience init(dictionary: [AnyHashable: Any]) {
        self.init(entries: dictionary.map { _FoundationDictionaryEntry(key: $0.key, value: $0.value) })
    }
    public convenience init?(contentsOfFile path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let decoded = try? PropertyListDecoder().decode([String: _FoundationPlistValue].self, from: data)
        else { return nil }
        self.init(dictionary: decoded.reduce(into: [AnyHashable: Any]()) { $0[$1.key] = $1.value.object })
    }
    @objc
    open subscript(key: String) -> Any? { object(forKey: key) }

    open var count: Int { entries.withLock { $0.count } }

    open var allKeys: [Any] {
        entries.withLock { $0.map(\.key) }
    }

    open var allValues: [Any] {
        entries.withLock { $0.map(\.value) }
    }

    open func object(forKey aKey: Any) -> Any? {
        entries.withLock { entries in
            entries.first {
                _foundationDictionaryKeysEqual($0.key, aKey)
            }?.value
        }
    }

    open subscript(key: any NSCopying) -> Any? {
        object(forKey: key)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }

    open override func copy() -> Any { copy(with: nil) }
}

/// Mutable Foundation reference dictionary with copied keys and retained
/// values. Individual operations are synchronized so concurrent framework
/// bookkeeping cannot corrupt its storage.
open class NSMutableDictionary: NSDictionary, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public init(capacity numItems: Int) {
        precondition(
            numItems >= 0,
            "NSMutableDictionary capacity must be nonnegative"
        )
        super.init()
    }

    open func setObject(_ anObject: Any, forKey aKey: any NSCopying) {
        entries.withLock { entries in
            if let index = entries.firstIndex(where: {
                _foundationDictionaryKeysEqual($0.key, aKey)
            }) {
                entries[index].value = anObject
                return
            }
            entries.append(
                _FoundationDictionaryEntry(
                    key: aKey.copy(with: nil),
                    value: anObject
                )
            )
        }
    }

    open func removeObject(forKey aKey: Any) {
        entries.withLock { entries in
            entries.removeAll {
                _foundationDictionaryKeysEqual($0.key, aKey)
            }
        }
    }

    open func removeAllObjects() {
        entries.withLock { $0.removeAll(keepingCapacity: false) }
    }

    open override subscript(key: any NSCopying) -> Any? {
        get { object(forKey: key) }
        set {
            if let newValue {
                setObject(newValue, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }

    /// String-keyed assignment, as `NSMutableDictionary.subscript(key: Any)`
    /// allows on Apple (`Thread.current.threadDictionary["k"] = v`, Signal,
    /// Telegram). A string key is stored as the string value.
    @objc
    open override subscript(key: String) -> Any? {
        get { object(forKey: key) }
        set {
            guard let newValue else {
                removeObject(forKey: key)
                return
            }
            entries.withLock { entries in
                if let index = entries.firstIndex(where: {
                    _foundationDictionaryKeysEqual($0.key, key)
                }) {
                    entries[index].value = newValue
                } else {
                    entries.append(_FoundationDictionaryEntry(key: key, value: newValue))
                }
            }
        }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NSDictionary(entries: entries.withLock { $0 })
    }
}
#endif
