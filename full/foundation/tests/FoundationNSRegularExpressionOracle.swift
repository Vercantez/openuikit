#if NSREGULAREXPRESSION_PORT
import NSRegularExpressionPort
import Foundation
private typealias TestRegularExpression = NSRegularExpressionPort.NSRegularExpression
#else
import Foundation
private typealias TestRegularExpression = NSRegularExpression
#endif

private func emit(_ key: String, _ value: Any) {
    print("\(key)\t\(value)")
}

private func rangeText(_ range: NSRange) -> String {
    if range.location == NSNotFound { return "not-found" }
    return "\(range.location):\(range.length)"
}

private func matchText(
    _ expression: TestRegularExpression,
    _ string: String
) -> String {
    let range = NSRange(location: 0, length: string.utf16.count)
    let matches = expression.matches(in: string, range: range)
    return matches.map { match in
        (0..<match.numberOfRanges).map { index in
            rangeText(match.range(at: index))
        }.joined(separator: "/")
    }.joined(separator: ";")
}

private struct Case {
    var name: String
    var pattern: String
    var text: String
    var options: TestRegularExpression.Options
    var template: String?
}

private let cases: [Case] = [
    Case(name: "anchor", pattern: "^a.c$", text: "abc", options: [], template: nil),
    Case(name: "dot", pattern: "^a.c$", text: "aXc", options: [], template: nil),
    Case(name: "class-digit", pattern: "\\d+", text: "ab12cd34", options: [], template: "$0"),
    Case(name: "class-upper", pattern: "[A-Z]+", text: "abCD12", options: [], template: nil),
    Case(name: "groups", pattern: "(a+)(b+)", text: "aaabbb", options: [], template: "$2-$1"),
    Case(name: "quant", pattern: "a{2,4}", text: "aaaaa", options: [], template: "X"),
    Case(name: "optional", pattern: "a?", text: "b", options: [], template: "|"),
    Case(name: "lookahead", pattern: "(?=x)x", text: "ax", options: [], template: "Y"),
    Case(name: "neg-lookahead", pattern: "(?!x)a", text: "xa", options: [], template: nil),
    Case(name: "named", pattern: "(?<word>[0-9]+)", text: "id=42", options: [], template: "<$1>"),
    Case(name: "insensitive", pattern: "hello", text: "HELLO", options: [.caseInsensitive], template: "x"),
    Case(name: "dotall", pattern: "a.b", text: "a\nb", options: [.dotMatchesLineSeparators], template: nil),
    Case(name: "anchors-lines", pattern: "^b", text: "a\nb", options: [.anchorsMatchLines], template: nil),
    Case(name: "literal", pattern: "a+b", text: "a+b aaab", options: [.ignoreMetacharacters], template: nil),
    Case(name: "unicode", pattern: "🙂+", text: "x🙂🙂y", options: [], template: "*"),
    Case(name: "alt", pattern: "cat|dog", text: "a dog and a cat", options: [], template: "pet"),
]

for item in cases {
    let expression = try TestRegularExpression(pattern: item.pattern, options: item.options)
    let range = NSRange(location: 0, length: item.text.utf16.count)
    emit("re.\(item.name).groups", expression.numberOfCaptureGroups)
    emit("re.\(item.name).count", expression.numberOfMatches(in: item.text, range: range))
    emit("re.\(item.name).matches", matchText(expression, item.text))
    if item.name == "named" {
        let match = expression.firstMatch(in: item.text, range: range)!
        emit("re.named.word", rangeText(match.range(withName: "word")))
        emit("re.named.missing", rangeText(match.range(withName: "nope")))
    }
    if let template = item.template {
        emit(
            "re.\(item.name).replace",
            expression.stringByReplacingMatches(
                in: item.text,
                range: range,
                withTemplate: template
            )
        )
    }
}

emit("re.escaped-pattern", TestRegularExpression.escapedPattern(for: "a+b/c-d"))
emit("re.escaped-template", TestRegularExpression.escapedTemplate(for: "$1\\x"))

do {
    _ = try TestRegularExpression(pattern: "(")
    emit("re.syntax-error", "missing")
} catch {
    let error = error as NSError
    emit("re.syntax-error", "\(error.domain):\(error.code)")
}
