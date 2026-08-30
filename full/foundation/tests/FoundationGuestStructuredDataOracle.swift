import Foundation

private func field(_ label: String, _ value: Any) {
    print("\(label)=\(value)")
}

private func rangeText(_ range: NSRange) -> String {
    if range.location == NSNotFound { return "not-found" }
    return "\(range.location):\(range.length)"
}

private enum PlainError: Error { case broken }

private enum CorpusCustomError: Int, CustomNSError, LocalizedError {
    case denied = 7
    static let errorDomain = "Corpus.Custom"
    var errorCode: Int { rawValue }
    var errorUserInfo: [String: Any] {
        [NSLocalizedFailureReasonErrorKey: "policy denied"]
    }
    var errorDescription: String? { "custom description" }
}

private struct CorpusRecoverableError: RecoverableError, LocalizedError {
    var recoveryOptions: [String] { ["Retry", "Cancel"] }
    var errorDescription: String? { "recoverable description" }
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        recoveryOptionIndex == 0
    }
}

private func numberOracle() throws {
    let boolean: NSNumber = true
    let integer: NSNumber = -7
    let floating: NSNumber = 1.25
    field("number.bool", "\(boolean.boolValue):\(boolean.intValue):\(boolean.stringValue)")
    field("number.integer", "\(integer.int64Value):\(integer.doubleValue):\(integer.stringValue)")
    field("number.floating", "\(floating.floatValue):\(floating.doubleValue):\(floating.stringValue)")
    field("number.uint-max", NSNumber(value: UInt64.max).stringValue)
    field("number.uint-max-int", NSNumber(value: UInt64.max).int64Value)
    field("number.negative-uint", NSNumber(value: -1).uint64Value)
    field("number.narrow-unsigned", NSNumber(value: 256).uint8Value)
    field("number.narrow-signed", NSNumber(value: 128).int8Value)
    field("number.nan-int", NSNumber(value: Double.nan).intValue)
    field("number.infinity-int", NSNumber(value: Double.infinity).intValue)
    field("number.equal-cross-kind", NSNumber(value: 1).isEqual(to: NSNumber(value: 1.0)))
    field("number.equal-bool", NSNumber(value: true).isEqual(to: NSNumber(value: 1)))
    field("number.compare", NSNumber(value: 1).compare(NSNumber(value: 2)).rawValue)
    let swiftInteger: Any = 3
    let objectNumber: Any = NSNumber(value: 4)
    let fractionalNumber: Any = NSNumber(value: 1.5)
    field("number.bridge.to-object", (swiftInteger as? NSNumber)?.intValue ?? -1)
    field("number.bridge.to-value", objectNumber as? Int ?? -1)
    field("number.bridge.reject-fraction", fractionalNumber as? Int == nil)
    let data = try JSONSerialization.data(
        withJSONObject: [
            "bool": NSNumber(value: true),
            "float": NSNumber(value: 1.5),
            "int": NSNumber(value: -2),
        ],
        options: .sortedKeys
    )
    field("number.json", String(data: data, encoding: .utf8)!)
}

private func jsonOracle() throws {
    let source = Data(
        "{\"s\":\"x\",\"i\":7,\"d\":1.25,\"b\":true,\"n\":null,\"a\":[1,\"z\"]}".utf8
    )
    let decoded = try JSONSerialization.jsonObject(
        with: source,
        options: [.mutableContainers, .mutableLeaves]
    ) as! [String: Any]
    field("json.string", decoded["s"] as! String)
    field("json.integer", decoded["i"] as! Int)
    field("json.double", decoded["d"] as! Double)
    field("json.bool", decoded["b"] as! Bool)
    field("json.null", decoded["n"] is NSNull)
    let array = decoded["a"] as! [Any]
    field("json.array", "\(array[0] as! Int):\(array[1] as! String)")

    var mutable = decoded
    mutable["added"] = 9
    field("json.mutable", mutable["added"] as! Int)

    let object: [String: Any] = [
        "z": "https://example.test/a/b",
        "a": [true, NSNull(), 2],
    ]
    let sorted = try JSONSerialization.data(
        withJSONObject: object,
        options: [.sortedKeys, .withoutEscapingSlashes]
    )
    field("json.sorted", String(data: sorted, encoding: .utf8)!)
    let pretty = try JSONSerialization.data(
        withJSONObject: ["b": 2, "a": 1],
        options: [.sortedKeys, .prettyPrinted]
    )
    field(
        "json.pretty",
        String(data: pretty, encoding: .utf8)!
            .replacingOccurrences(of: "\n", with: "|")
            .replacingOccurrences(of: " ", with: "·")
    )
    field("json.valid.object", JSONSerialization.isValidJSONObject(object))
    field("json.valid.scalar", JSONSerialization.isValidJSONObject("x"))
    field("json.valid.nan", JSONSerialization.isValidJSONObject(["x": Double.nan]))

    let fragment = try JSONSerialization.jsonObject(
        with: Data("17".utf8),
        options: .fragmentsAllowed
    )
    field("json.fragment", fragment as! Int)
    do {
        _ = try JSONSerialization.jsonObject(with: Data("17".utf8))
        field("json.fragment-error", "missing")
    } catch {
        let error = error as NSError
        field("json.fragment-error", "\(error.domain):\(error.code)")
    }
    do {
        _ = try JSONSerialization.jsonObject(with: Data("{".utf8))
        field("json.syntax-error", "missing")
    } catch {
        let error = error as NSError
        field("json.syntax-error", "\(error.domain):\(error.code)")
        field("json.syntax-debug", error.userInfo[NSDebugDescriptionErrorKey] != nil)
    }
}

private func errorOracle() {
    let plain = NSError(domain: "D", code: 42)
    field("error.domain", plain.domain)
    field("error.code", plain.code)
    field("error.localized", plain.localizedDescription)
    field("error.description", plain.description)

    let detailed = NSError(
        domain: "D",
        code: 42,
        userInfo: [
            NSLocalizedDescriptionKey: "hello",
            NSLocalizedFailureReasonErrorKey: "because",
            NSLocalizedRecoverySuggestionErrorKey: "retry",
            NSLocalizedRecoveryOptionsErrorKey: ["Again", "Cancel"],
            NSHelpAnchorErrorKey: "help",
            NSFilePathErrorKey: "/tmp/file",
            NSUnderlyingErrorKey: plain,
            NSMultipleUnderlyingErrorsKey: [NSError(domain: "M", code: 1)],
        ]
    )
    field("error.detail.localized", detailed.localizedDescription)
    field("error.detail.reason", detailed.localizedFailureReason ?? "nil")
    field("error.detail.suggestion", detailed.localizedRecoverySuggestion ?? "nil")
    field("error.detail.options", detailed.localizedRecoveryOptions?.joined(separator: ",") ?? "nil")
    field("error.detail.help", detailed.helpAnchor ?? "nil")
    field("error.detail.path", detailed.userInfo[NSFilePathErrorKey] as? String ?? "nil")
    field("error.detail.underlying", detailed.underlyingErrors.count)
    field(
        "error.equal",
        plain == NSError(domain: "D", code: 42, userInfo: [:])
    )

    let cocoa = NSError(domain: NSCocoaErrorDomain, code: 3840)
    field("error.cocoa.localized", cocoa.localizedDescription)
    field("error.cocoa.reason", cocoa.localizedFailureReason ?? "nil")

    let plainBridge = PlainError.broken as NSError
    field("error.bridge.plain-domain-suffix", plainBridge.domain.hasSuffix("PlainError"))
    field("error.bridge.plain-code", plainBridge.code)
    let customBridge = CorpusCustomError.denied as NSError
    field("error.bridge.custom", "\(customBridge.domain):\(customBridge.code)")
    field("error.bridge.custom-localized", customBridge.localizedDescription)
    let existential: any Error = plain
    field("error.bridge.identity", (existential as NSError) === plain)
    let recoverable = CorpusRecoverableError() as NSError
    field("error.bridge.recoverable-localized", recoverable.localizedDescription)
    field(
        "error.bridge.recoverable-options",
        recoverable.localizedRecoveryOptions?.joined(separator: ",") ?? "nil"
    )
    field("error.bridge.recovery-attempter", recoverable.recoveryAttempter != nil)
}

private func regexOracle() throws {
    let text = "🙂 xx abc-42 AB-7\nzz"
    let full = NSRange(location: 0, length: text.utf16.count)
    let expression = try NSRegularExpression(
        pattern: "(?<word>[a-z]+)-(\\d+)",
        options: .caseInsensitive
    )
    field("regex.capture-count", expression.numberOfCaptureGroups)
    let matches = expression.matches(in: text, range: full)
    field("regex.match-count", matches.count)
    field("regex.result-type", matches[0].resultType.rawValue)
    for (index, match) in matches.enumerated() {
        field("regex.\(index).whole", rangeText(match.range))
        field("regex.\(index).one", rangeText(match.range(at: 1)))
        field("regex.\(index).name", rangeText(match.range(withName: "word")))
        field("regex.\(index).two", rangeText(match.range(at: 2)))
    }
    field(
        "regex.replace",
        expression.stringByReplacingMatches(
            in: text,
            range: full,
            withTemplate: "<$1:$2>"
        )
    )
    field(
        "regex.template",
        expression.replacementString(
            for: matches[0],
            in: text,
            offset: 0,
            template: "\\$:$0:$2"
        )
    )

    var callbacks: [String] = []
    expression.enumerateMatches(
        in: text,
        options: [.reportCompletion],
        range: full
    ) { result, flags, stop in
        if let result {
            callbacks.append(rangeText(result.range))
            stop.pointee = ObjCBool(callbacks.count == 1)
        } else if flags.contains(.completed) {
            callbacks.append("completed")
        }
    }
    field("regex.enumerate", callbacks.joined(separator: ","))

    let zero = try NSRegularExpression(pattern: "(?=a)|$")
    let zeroText = "aa"
    let zeroRange = NSRange(location: 0, length: zeroText.utf16.count)
    field(
        "regex.zero",
        zero.matches(in: zeroText, range: zeroRange)
            .map { rangeText($0.range) }
            .joined(separator: ",")
    )
    field(
        "regex.zero-replace",
        zero.stringByReplacingMatches(
            in: zeroText,
            range: zeroRange,
            withTemplate: "|"
        )
    )

    let literal = try NSRegularExpression(
        pattern: "a+b",
        options: .ignoreMetacharacters
    )
    field(
        "regex.literal",
        literal.numberOfMatches(
            in: "a+b aaab",
            range: NSRange(location: 0, length: 8)
        )
    )
    let dot = try NSRegularExpression(pattern: "a.*b", options: .dotMatchesLineSeparators)
    field(
        "regex.dotall",
        rangeText(dot.rangeOfFirstMatch(
            in: "a\nb",
            range: NSRange(location: 0, length: 3)
        ))
    )
    field("regex.escaped-pattern", NSRegularExpression.escapedPattern(for: "a+b/c-d"))
    field("regex.escaped-template", NSRegularExpression.escapedTemplate(for: "$1\\x"))

    do {
        _ = try NSRegularExpression(pattern: "(")
        field("regex.syntax-error", "missing")
    } catch {
        let error = error as NSError
        field("regex.syntax-error", "\(error.domain):\(error.code)")
    }
}

try numberOracle()
try jsonOracle()
errorOracle()
try regexOracle()
