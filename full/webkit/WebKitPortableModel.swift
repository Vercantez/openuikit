@_exported import Foundation

// Portable WebKit helpers that do not need a Web Content process.
//
// Measured / cited:
// - Navigation tracking order is Apple's WKNavigationDelegate overview:
//   didStartProvisionalNavigation → (redirect) → didCommit → didFinish
//   (https://developer.apple.com/documentation/webkit/wknavigationdelegate).
//   didStart is "after provisional approval … before it receives a response"
//   (webView(_:didStartProvisionalNavigation:)). didCommit is "after … decidePolicyFor
//   navigationResponse … immediately before it starts to update the main frame"
//   (webView(_:didCommit:)).
// - estimatedProgress is documented as 0.0...1.0 on WKWebView. Open-source
//   WebKit uses initialProgressValue = 0.1 at provisional start
//   (Source/WebKit/UIProcess/API/Cocoa/WKWebView.mm).
// - Content-blocker JSON schema: Apple "Creating a content blocker"
//   (https://developer.apple.com/documentation/safariservices/creating-a-content-blocker):
//   array of {trigger, action}; trigger requires url-filter string; action requires
//   type in {block, block-cookies, css-display-none, ignore-previous-rules, make-https};
//   css-display-none requires selector; if-domain mutually exclusive with unless-domain
//   (same for top-url / frame-url pairs).
// - evaluateJavaScript: non-literal scripts fail closed with
//   WKError.javaScriptExceptionOccurred (WKErrorCode = 4 in WKError.h). Literals
//   (string / number / bool / null) resolve to that value because they need no engine.

internal func WKPortableASCIILower(_ character: Character) -> Character {
    guard let ascii = character.asciiValue, ascii >= 65, ascii <= 90 else {
        return character
    }
    return Character(UnicodeScalar(ascii + 32))
}

internal func WKPortableEqualsIgnoreASCIICase(_ left: String, _ right: String) -> Bool {
    guard left.count == right.count else { return false }
    return zip(left, right).allSatisfy { WKPortableASCIILower($0) == WKPortableASCIILower($1) }
}

internal func WKPortableHasPrefixIgnoreASCIICase(_ value: String, _ prefix: String) -> Bool {
    guard value.count >= prefix.count else { return false }
    return WKPortableEqualsIgnoreASCIICase(String(value.prefix(prefix.count)), prefix)
}

/// First index of `needle` in `haystack`. ASCII case folding only; no
/// `_StringProcessing` `ranges(of:)`.
internal func WKPortableFirstIndex(
    ofNeedle needle: String,
    in haystack: String,
    from start: String.Index? = nil
) -> String.Index? {
    guard !needle.isEmpty else { return start ?? haystack.startIndex }
    var index = start ?? haystack.startIndex
    while index < haystack.endIndex {
        var hay = index
        var matched = true
        for expected in needle {
            guard hay < haystack.endIndex else {
                matched = false
                break
            }
            if WKPortableASCIILower(haystack[hay]) != WKPortableASCIILower(expected) {
                matched = false
                break
            }
            hay = haystack.index(after: hay)
        }
        if matched { return index }
        index = haystack.index(after: index)
    }
    return nil
}

/// Document title from an HTML string. Looks for the first `<title…>…</title>`
/// pair (ASCII case-insensitive). Unknown markup stays `nil` so callers can
/// keep WKWebView's empty-string default rather than invent a title.
internal func WKPortableHTMLTitle(_ html: String) -> String? {
    guard let open = WKPortableFirstIndex(ofNeedle: "<title", in: html) else {
        return nil
    }
    var cursor = html.index(open, offsetBy: 6)
    while cursor < html.endIndex, html[cursor] != ">" {
        cursor = html.index(after: cursor)
    }
    guard cursor < html.endIndex else { return nil }
    let innerStart = html.index(after: cursor)
    guard let close = WKPortableFirstIndex(ofNeedle: "</title>", in: html, from: innerStart)
    else {
        return nil
    }
    let inner = String(html[innerStart..<close])
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return inner
}

internal enum WKPortableJSLiteralResult {
    case value(Any)
    case notLiteral
}

/// Parses a JavaScript *literal* (string / number / bool / null) after
/// trimming ASCII whitespace. Anything else is `notLiteral` so evaluateJavaScript
/// can fail closed with `WKError.javaScriptExceptionOccurred`.
internal func WKPortableJavaScriptLiteral(_ source: String) -> WKPortableJSLiteralResult {
    let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return .notLiteral }

    if trimmed == "null" { return .value(NSNull()) }
    if trimmed == "true" { return .value(true) }
    if trimmed == "false" { return .value(false) }

    if let stringValue = WKPortableJSQuotedString(trimmed) {
        return .value(stringValue)
    }
    if let number = WKPortableJSNumber(trimmed) {
        return .value(number)
    }
    if let json = WKPortableJSONLiteral(trimmed) {
        return .value(json)
    }
    return .notLiteral
}

/// JSON object/array literals. Used by the documented evaluateJavaScript /
/// callAsyncJavaScript evaluator; anything that is not a JSON value or a
/// JS primitive literal fails closed.
private func WKPortableJSONLiteral(_ trimmed: String) -> Any? {
    guard let first = trimmed.first, first == "{" || first == "[" else { return nil }
    guard let data = trimmed.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [])
}

private func WKPortableJSQuotedString(_ trimmed: String) -> String? {
    guard let first = trimmed.first, first == "\"" || first == "'" else { return nil }
    var result = ""
    var index = trimmed.index(after: trimmed.startIndex)
    var escaped = false
    while index < trimmed.endIndex {
        let character = trimmed[index]
        if escaped {
            switch character {
            case "n": result.append("\n")
            case "t": result.append("\t")
            case "r": result.append("\r")
            case "\\": result.append("\\")
            case "\"": result.append("\"")
            case "'": result.append("'")
            default: result.append(character)
            }
            escaped = false
        } else if character == "\\" {
            escaped = true
        } else if character == first {
            let after = trimmed.index(after: index)
            guard after == trimmed.endIndex else { return nil }
            return result
        } else {
            result.append(character)
        }
        index = trimmed.index(after: index)
    }
    return nil
}

private func WKPortableJSNumber(_ trimmed: String) -> Any? {
    var body = trimmed
    var negative = false
    if body.first == "-" {
        negative = true
        body.removeFirst()
    }
    guard !body.isEmpty else { return nil }
    var sawDigit = false
    var sawDot = false
    var sawExp = false
    var index = body.startIndex
    while index < body.endIndex {
        let character = body[index]
        if character >= "0" && character <= "9" {
            sawDigit = true
        } else if character == ".", !sawDot, !sawExp {
            sawDot = true
        } else if (character == "e" || character == "E"), !sawExp, sawDigit {
            sawExp = true
            let next = body.index(after: index)
            if next < body.endIndex {
                let sign = body[next]
                if sign == "+" || sign == "-" {
                    index = next
                }
            }
        } else {
            return nil
        }
        index = body.index(after: index)
    }
    guard sawDigit else { return nil }
    let signed = (negative ? "-" : "") + body
    if !sawDot && !sawExp, let intValue = Int(signed) {
        return intValue
    }
    return Double(signed)
}

private let WKPortableResourceTypes: Set<String> = [
    "document", "top-document", "child-document", "image", "style-sheet",
    "script", "font", "raw", "svg-document", "media", "popup", "ping",
    "fetch", "websocket", "csp-report", "other",
]
private let WKPortableLoadTypes: Set<String> = ["first-party", "third-party"]
private let WKPortableLoadContexts: Set<String> = ["top-frame", "child-frame"]
private let WKPortableActionTypes: Set<String> = [
    "block", "block-cookies", "css-display-none", "ignore-previous-rules", "make-https",
]
private let WKPortableTriggerKeys: Set<String> = [
    "url-filter", "url-filter-is-case-sensitive", "if-domain", "unless-domain",
    "resource-type", "load-type", "if-top-url", "unless-top-url",
    "if-frame-url", "unless-frame-url", "load-context",
]
private let WKPortableActionKeys: Set<String> = ["type", "selector"]

/// Validates Safari/WebKit content-blocker JSON. Returns nil when the payload
/// matches Apple's documented schema; otherwise a compile-failed WKError.
internal func WKPortableValidateContentRuleList(
    _ encoded: String,
    identifier: String
) -> WKError? {
    let fail = WKError(
        code: .contentRuleListStoreCompileFailed,
        operation: "compileContentRuleList(\(identifier))"
    )
    guard let payload = encoded.data(using: .utf8) else { return fail }
    let json: Any
    do {
        json = try JSONSerialization.jsonObject(with: payload, options: [])
    } catch {
        return fail
    }
    guard let rules = json as? [Any], !rules.isEmpty else { return fail }
    for rule in rules {
        guard let object = rule as? [String: Any],
              let trigger = object["trigger"] as? [String: Any],
              let action = object["action"] as? [String: Any]
        else {
            return fail
        }
        for key in trigger.keys where !WKPortableTriggerKeys.contains(key) {
            return fail
        }
        for key in action.keys where !WKPortableActionKeys.contains(key) {
            return fail
        }
        guard let filter = trigger["url-filter"] as? String, !filter.isEmpty else {
            return fail
        }
        _ = filter
        if let caseSensitive = trigger["url-filter-is-case-sensitive"],
           !(caseSensitive is Bool) {
            return fail
        }
        if trigger["if-domain"] != nil && trigger["unless-domain"] != nil {
            return fail
        }
        if trigger["if-top-url"] != nil && trigger["unless-top-url"] != nil {
            return fail
        }
        if trigger["if-frame-url"] != nil && trigger["unless-frame-url"] != nil {
            return fail
        }
        if let domains = trigger["if-domain"] ?? trigger["unless-domain"] {
            guard WKPortableStringArray(domains) != nil else { return fail }
        }
        if let urls = trigger["if-top-url"] ?? trigger["unless-top-url"]
            ?? trigger["if-frame-url"] ?? trigger["unless-frame-url"] {
            guard WKPortableStringArray(urls) != nil else { return fail }
        }
        if let resources = trigger["resource-type"] {
            guard let values = WKPortableStringArray(resources),
                  values.allSatisfy({ WKPortableResourceTypes.contains($0) })
            else { return fail }
        }
        if let loads = trigger["load-type"] {
            guard let values = WKPortableStringArray(loads),
                  values.allSatisfy({ WKPortableLoadTypes.contains($0) })
            else { return fail }
        }
        if let contexts = trigger["load-context"] {
            guard let values = WKPortableStringArray(contexts),
                  values.allSatisfy({ WKPortableLoadContexts.contains($0) })
            else { return fail }
        }
        guard let type = action["type"] as? String,
              WKPortableActionTypes.contains(type)
        else {
            return fail
        }
        if type == "css-display-none" {
            guard let selector = action["selector"] as? String, !selector.isEmpty else {
                return fail
            }
        }
    }
    return nil
}

private func WKPortableStringArray(_ value: Any) -> [String]? {
    guard let values = value as? [Any], !values.isEmpty else { return nil }
    var result: [String] = []
    result.reserveCapacity(values.count)
    for item in values {
        guard let string = item as? String else { return nil }
        result.append(string)
    }
    return result
}

internal func WKPortableIsNetworkURL(_ url: URL?) -> Bool {
    guard let scheme = url?.scheme else { return false }
    return WKPortableEqualsIgnoreASCIICase(scheme, "http")
        || WKPortableEqualsIgnoreASCIICase(scheme, "https")
}

internal func WKPortableCanShowMIMEType(_ mimeType: String) -> Bool {
    if WKPortableHasPrefixIgnoreASCIICase(mimeType, "text/") { return true }
    if WKPortableHasPrefixIgnoreASCIICase(mimeType, "image/") { return true }
    return WKPortableEqualsIgnoreASCIICase(mimeType, "application/xhtml+xml")
        || WKPortableEqualsIgnoreASCIICase(mimeType, "application/json")
}
