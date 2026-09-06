@_exported import Foundation

/// Chrome/WebExtensions match-pattern and `manifest.json` validation used by
/// `WKWebExtension`. Documented against
/// https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Match_patterns
/// and Chromium `manifest_version` 2/3. This is not an extension process.

internal struct WKPortableParsedMatchPattern {
    var scheme: String
    var host: String
    var path: String
    var matchesAllURLSchemes: Bool
}

internal enum WKPortableMatchPatternParseError: Error {
    case invalidScheme
    case invalidHost
    case invalidPath
}

internal func WKPortableParseMatchPattern(_ string: String) throws -> WKPortableParsedMatchPattern {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed == "<all_urls>" {
        return WKPortableParsedMatchPattern(
            scheme: "*",
            host: "*",
            path: "/*",
            matchesAllURLSchemes: true
        )
    }
    guard let colon = trimmed.firstIndex(of: ":") else {
        throw WKPortableMatchPatternParseError.invalidScheme
    }
    let scheme = String(trimmed[..<colon])
    guard WKPortableMatchPatternSchemeAllowed(scheme) else {
        throw WKPortableMatchPatternParseError.invalidScheme
    }
    var rest = String(trimmed[trimmed.index(after: colon)...])
    guard rest.hasPrefix("//") else {
        throw WKPortableMatchPatternParseError.invalidScheme
    }
    rest.removeFirst(2)
    if WKPortableEqualsIgnoreASCIICase(scheme, "file") {
        let path = rest.hasPrefix("/") ? rest : "/" + rest
        guard path.hasPrefix("/") else {
            throw WKPortableMatchPatternParseError.invalidPath
        }
        return WKPortableParsedMatchPattern(
            scheme: scheme,
            host: "",
            path: path,
            matchesAllURLSchemes: false
        )
    }
    guard let slash = rest.firstIndex(of: "/") else {
        throw WKPortableMatchPatternParseError.invalidPath
    }
    let host = String(rest[..<slash])
    let path = String(rest[slash...])
    try WKPortableValidateMatchPatternHost(host)
    guard path.hasPrefix("/") else {
        throw WKPortableMatchPatternParseError.invalidPath
    }
    return WKPortableParsedMatchPattern(
        scheme: scheme,
        host: host,
        path: path,
        matchesAllURLSchemes: false
    )
}

internal func WKPortableParseMatchPattern(
    scheme: String,
    host: String,
    path: String
) throws -> WKPortableParsedMatchPattern {
    guard WKPortableMatchPatternSchemeAllowed(scheme) else {
        throw WKPortableMatchPatternParseError.invalidScheme
    }
    if WKPortableEqualsIgnoreASCIICase(scheme, "file") {
        guard host.isEmpty, path.hasPrefix("/") else {
            throw host.isEmpty
                ? WKPortableMatchPatternParseError.invalidPath
                : WKPortableMatchPatternParseError.invalidHost
        }
        return WKPortableParsedMatchPattern(
            scheme: scheme,
            host: "",
            path: path,
            matchesAllURLSchemes: false
        )
    }
    try WKPortableValidateMatchPatternHost(host)
    guard path.hasPrefix("/") else {
        throw WKPortableMatchPatternParseError.invalidPath
    }
    return WKPortableParsedMatchPattern(
        scheme: scheme,
        host: host,
        path: path,
        matchesAllURLSchemes: false
    )
}

private func WKPortableMatchPatternSchemeAllowed(_ scheme: String) -> Bool {
    if scheme == "*" { return true }
    if WKPortableEqualsIgnoreASCIICase(scheme, "http") { return true }
    if WKPortableEqualsIgnoreASCIICase(scheme, "https") { return true }
    if WKPortableEqualsIgnoreASCIICase(scheme, "file") { return true }
    if WKPortableEqualsIgnoreASCIICase(scheme, "ftp") { return true }
    if WKPortableEqualsIgnoreASCIICase(scheme, "ws") { return true }
    if WKPortableEqualsIgnoreASCIICase(scheme, "wss") { return true }
    guard !scheme.isEmpty else { return false }
    return scheme.allSatisfy { character in
        (character >= "a" && character <= "z")
            || (character >= "A" && character <= "Z")
            || (character >= "0" && character <= "9")
            || character == "+" || character == "." || character == "-"
    }
}

private func WKPortableValidateMatchPatternHost(_ host: String) throws {
    if host == "*" { return }
    if host.hasPrefix("*.") {
        let suffix = String(host.dropFirst(2))
        guard !suffix.isEmpty, !suffix.contains("*"), suffix.contains(".") || suffix.count > 0 else {
            throw WKPortableMatchPatternParseError.invalidHost
        }
        if suffix.hasPrefix(".") || suffix.hasSuffix(".") {
            throw WKPortableMatchPatternParseError.invalidHost
        }
        return
    }
    guard !host.isEmpty, !host.contains("*") else {
        throw WKPortableMatchPatternParseError.invalidHost
    }
}

internal func WKPortableGlobMatch(pattern: String, value: String) -> Bool {
    var dp = Array(repeating: false, count: value.count + 1)
    dp[0] = true
    for token in pattern {
            var next = Array(repeating: false, count: value.count + 1)
        if token == "*" {
            var any = false
            for valueIndex in 0...value.count {
                any = any || dp[valueIndex]
                next[valueIndex] = any
            }
        } else {
            for valueIndex in 0..<value.count {
                if dp[valueIndex] {
                    let character = value[value.index(value.startIndex, offsetBy: valueIndex)]
                    if character == token {
                        next[valueIndex + 1] = true
                    }
                }
            }
        }
        dp = next
    }
    return dp[value.count]
}

internal func WKPortableMatchPatternMatchesURL(
    _ pattern: WKPortableParsedMatchPattern,
    url: URL,
    ignoreSchemes: Bool,
    ignorePaths: Bool
) -> Bool {
    guard let urlScheme = url.scheme else { return false }
    if !ignoreSchemes {
        if pattern.matchesAllURLSchemes {
            let allowed = WKPortableEqualsIgnoreASCIICase(urlScheme, "http")
                || WKPortableEqualsIgnoreASCIICase(urlScheme, "https")
                || WKPortableEqualsIgnoreASCIICase(urlScheme, "file")
                || WKPortableEqualsIgnoreASCIICase(urlScheme, "ftp")
                || WKPortableEqualsIgnoreASCIICase(urlScheme, "ws")
                || WKPortableEqualsIgnoreASCIICase(urlScheme, "wss")
            if !allowed { return false }
        } else if pattern.scheme == "*" {
            let allowed = WKPortableEqualsIgnoreASCIICase(urlScheme, "http")
                || WKPortableEqualsIgnoreASCIICase(urlScheme, "https")
            if !allowed { return false }
        } else if !WKPortableEqualsIgnoreASCIICase(pattern.scheme, urlScheme) {
            return false
        }
    }
    if pattern.scheme != "*" && WKPortableEqualsIgnoreASCIICase(pattern.scheme, "file") {
        // file hosts are empty; path glob against the URL path.
    } else if pattern.host != "*" {
        let urlHost = url.host ?? ""
        if pattern.host.hasPrefix("*.") {
            let suffix = String(pattern.host.dropFirst(2))
            let hostMatches = WKPortableEqualsIgnoreASCIICase(urlHost, suffix)
                || (urlHost.count > suffix.count
                    && urlHost.hasSuffix(suffix)
                    && urlHost.dropLast(suffix.count).last == ".")
            if !hostMatches { return false }
        } else if !WKPortableEqualsIgnoreASCIICase(pattern.host, urlHost) {
            return false
        }
    }
    if ignorePaths { return true }
    let urlPath = url.path.isEmpty ? "/" : url.path
    return WKPortableGlobMatch(pattern: pattern.path, value: urlPath)
}

internal struct WKPortableWebExtensionState {
    var manifest: [String: Any]
    var manifestVersion: Double
    var defaultLocale: Locale?
    var displayName: String?
    var displayShortName: String?
    var displayVersion: String?
    var displayDescription: String?
    var displayActionLabel: String?
    var version: String?
    var hasBackgroundContent: Bool
    var hasPersistentBackgroundContent: Bool
    var hasCommands: Bool
    var hasContentModificationRules: Bool
    var hasInjectedContent: Bool
    var hasOptionsPage: Bool
    var hasOverrideNewTabPage: Bool
    var requestedPermissions: Set<String>
    var optionalPermissions: Set<String>
    var requestedMatchPatternStrings: [String]
    var optionalMatchPatternStrings: [String]
}

internal func WKPortableLoadWebExtension(
    resourceBaseURL: URL
) throws -> WKPortableWebExtensionState {
    let manifestURL = resourceBaseURL.appendingPathComponent("manifest.json")
    guard FileManager.default.fileExists(atPath: manifestURL.path) else {
        throw WKWebExtension.Error(
            .resourceNotFound,
            userInfo: ["WKPortableOperation": "manifest.json"]
        )
    }
    guard let data = try? Data(contentsOf: manifestURL) else {
        throw WKWebExtension.Error(
            .invalidArchive,
            userInfo: ["WKPortableOperation": "manifest.json"]
        )
    }
    let json: Any
    do {
        json = try JSONSerialization.jsonObject(with: data, options: [])
    } catch {
        throw WKWebExtension.Error(.invalidManifest)
    }
    guard var object = json as? [String: Any] else {
        throw WKWebExtension.Error(.invalidManifest)
    }
    if let localeName = object["default_locale"] as? String, !localeName.isEmpty {
        let messagesURL = resourceBaseURL
            .appendingPathComponent("_locales")
            .appendingPathComponent(localeName)
            .appendingPathComponent("messages.json")
        if let messagesData = try? Data(contentsOf: messagesURL),
           let messagesJSON = try? JSONSerialization.jsonObject(with: messagesData),
           let messages = messagesJSON as? [String: Any] {
            object = WKPortableSubstituteManifestMessages(object, messages: messages) as? [String: Any] ?? object
        }
    }
    return try WKPortableValidateManifestObject(object)
}

private func WKPortableSubstituteManifestMessages(
    _ value: Any,
    messages: [String: Any]
) -> Any {
    if let string = value as? String {
        return WKPortableReplaceMessagePlaceholders(string, messages: messages)
    }
    if let array = value as? [Any] {
        return array.map { WKPortableSubstituteManifestMessages($0, messages: messages) }
    }
    if let object = value as? [String: Any] {
        var result: [String: Any] = [:]
        for (key, child) in object {
            result[key] = WKPortableSubstituteManifestMessages(child, messages: messages)
        }
        return result
    }
    return value
}

private func WKPortableReplaceMessagePlaceholders(
    _ string: String,
    messages: [String: Any]
) -> String {
    var result = string
    var search = result.startIndex
    while search < result.endIndex,
          let open = result[search...].range(of: "__MSG_") {
        guard let close = result[open.upperBound...].range(of: "__") else { break }
        let key = String(result[open.upperBound..<close.lowerBound])
        let replacement: String
        if let entry = messages[key] as? [String: Any],
           let message = entry["message"] as? String {
            replacement = message
        } else if let message = messages[key] as? String {
            replacement = message
        } else {
            search = close.upperBound
            continue
        }
        result.replaceSubrange(open.lowerBound..<close.upperBound, with: replacement)
        search = result.index(open.lowerBound, offsetBy: replacement.count)
    }
    return result
}

internal func WKPortableValidateManifestObject(
    _ object: [String: Any]
) throws -> WKPortableWebExtensionState {
    guard let versionNumber = object["manifest_version"] as? Int
            ?? (object["manifest_version"] as? Double).map({ Int($0) })
    else {
        throw WKWebExtension.Error(.invalidManifest)
    }
    let manifestVersion = Double(versionNumber)
    guard versionNumber == 2 || versionNumber == 3 else {
        throw WKWebExtension.Error(.unsupportedManifestVersion)
    }
    guard let name = object["name"] as? String, !name.isEmpty else {
        throw WKWebExtension.Error(.invalidManifestEntry, userInfo: ["key": "name"])
    }
    guard let version = object["version"] as? String, !version.isEmpty else {
        throw WKWebExtension.Error(.invalidManifestEntry, userInfo: ["key": "version"])
    }
    let requested = try WKPortableStringList(object["permissions"], key: "permissions")
    let optional = try WKPortableStringList(object["optional_permissions"], key: "optional_permissions")
    let hostPermissions = try WKPortableStringList(object["host_permissions"], key: "host_permissions")
    var requestedPatterns: [String] = []
    var optionalPatterns: [String] = []
    var requestedPermissionNames: Set<String> = []
    var optionalPermissionNames: Set<String> = []
    for item in requested {
        if WKPortableLooksLikeMatchPattern(item) {
            _ = try WKPortableParseMatchPattern(item)
            requestedPatterns.append(item)
        } else {
            requestedPermissionNames.insert(item)
        }
    }
    for item in optional {
        if WKPortableLooksLikeMatchPattern(item) {
            _ = try WKPortableParseMatchPattern(item)
            optionalPatterns.append(item)
        } else {
            optionalPermissionNames.insert(item)
        }
    }
    for item in hostPermissions {
        _ = try WKPortableParseMatchPattern(item)
        requestedPatterns.append(item)
    }

    var hasInjected = false
    if let scripts = object["content_scripts"] {
        guard let entries = scripts as? [Any], !entries.isEmpty else {
            throw WKWebExtension.Error(.invalidManifestEntry, userInfo: ["key": "content_scripts"])
        }
        for entry in entries {
            guard let script = entry as? [String: Any],
                  let matches = script["matches"] as? [Any], !matches.isEmpty
            else {
                throw WKWebExtension.Error(.invalidManifestEntry, userInfo: ["key": "content_scripts"])
            }
            for match in matches {
                guard let pattern = match as? String else {
                    throw WKWebExtension.Error(.invalidManifestEntry, userInfo: ["key": "content_scripts"])
                }
                _ = try WKPortableParseMatchPattern(pattern)
                requestedPatterns.append(pattern)
            }
            hasInjected = true
        }
    }

    var hasBackground = false
    var persistentBackground = false
    if let background = object["background"] {
        guard let backgroundObject = background as? [String: Any] else {
            throw WKWebExtension.Error(.invalidBackgroundPersistence)
        }
        if versionNumber == 2 {
            if let scripts = backgroundObject["scripts"] as? [Any], !scripts.isEmpty {
                hasBackground = scripts.allSatisfy { $0 is String }
            }
            if let page = backgroundObject["page"] as? String, !page.isEmpty {
                hasBackground = true
            }
            if let persistent = backgroundObject["persistent"] as? Bool {
                persistentBackground = persistent
            } else {
                persistentBackground = hasBackground
            }
        } else {
            if let worker = backgroundObject["service_worker"] as? String, !worker.isEmpty {
                hasBackground = true
            }
            if backgroundObject["persistent"] as? Bool == true {
                throw WKWebExtension.Error(.invalidBackgroundPersistence)
            }
            persistentBackground = false
        }
        if !hasBackground {
            throw WKWebExtension.Error(.invalidManifestEntry, userInfo: ["key": "background"])
        }
    }

    if let rules = object["declarative_net_request"] {
        guard let ruleObject = rules as? [String: Any],
              let resources = ruleObject["rule_resources"] as? [Any]
        else {
            throw WKWebExtension.Error(.invalidDeclarativeNetRequestEntry)
        }
        _ = resources
    }

    if let icons = object["icons"] {
        guard let iconObject = icons as? [String: Any],
              iconObject.values.allSatisfy({ $0 is String })
        else {
            throw WKWebExtension.Error(.invalidManifestEntry, userInfo: ["key": "icons"])
        }
    }

    let action = (object["action"] as? [String: Any])
        ?? (object["browser_action"] as? [String: Any])
    let actionLabel = action?["default_title"] as? String
    let optionsPage = (object["options_ui"] as? [String: Any])?["page"] as? String
        ?? object["options_page"] as? String
    let chromeURLOverrides = object["chrome_url_overrides"] as? [String: Any]
    let hasNewTab = (chromeURLOverrides?["newtab"] as? String)?.isEmpty == false

    let description = object["description"] as? String
    let shortName = object["short_name"] as? String
    let localeName = object["default_locale"] as? String
    let commands = object["commands"] as? [String: Any]
    let hasDNR = object["declarative_net_request"] != nil
        || requestedPermissionNames.contains("declarativeNetRequest")

    return WKPortableWebExtensionState(
        manifest: object,
        manifestVersion: manifestVersion,
        defaultLocale: localeName.map { Locale(identifier: $0) },
        displayName: name,
        displayShortName: shortName,
        displayVersion: version,
        displayDescription: description,
        displayActionLabel: actionLabel,
        version: version,
        hasBackgroundContent: hasBackground,
        hasPersistentBackgroundContent: persistentBackground,
        hasCommands: commands.map { !$0.isEmpty } ?? false,
        hasContentModificationRules: hasDNR,
        hasInjectedContent: hasInjected,
        hasOptionsPage: optionsPage.map { !$0.isEmpty } ?? false,
        hasOverrideNewTabPage: hasNewTab,
        requestedPermissions: requestedPermissionNames,
        optionalPermissions: optionalPermissionNames,
        requestedMatchPatternStrings: requestedPatterns,
        optionalMatchPatternStrings: optionalPatterns
    )
}

private func WKPortableStringList(_ value: Any?, key: String) throws -> [String] {
    guard let value else { return [] }
    guard let array = value as? [Any] else {
        throw WKWebExtension.Error(.invalidManifestEntry, userInfo: ["key": key])
    }
    var result: [String] = []
    for item in array {
        guard let string = item as? String, !string.isEmpty else {
            throw WKWebExtension.Error(.invalidManifestEntry, userInfo: ["key": key])
        }
        result.append(string)
    }
    return result
}

private func WKPortableLooksLikeMatchPattern(_ value: String) -> Bool {
    value == "<all_urls>" || value.contains("://")
}

internal func WKPortableParsePostMessage(_ source: String) -> (name: String, body: Any)? {
    let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
    let prefix = "window.webkit.messageHandlers."
    guard trimmed.hasPrefix(prefix) else { return nil }
    let rest = String(trimmed.dropFirst(prefix.count))
    guard let dot = rest.range(of: ".postMessage("), rest.hasSuffix(")") else { return nil }
    let name = String(rest[..<dot.lowerBound])
    guard !name.isEmpty else { return nil }
    let argument = String(rest[dot.upperBound..<rest.index(before: rest.endIndex)])
        .trimmingCharacters(in: .whitespacesAndNewlines)
    switch WKPortableJavaScriptLiteral(argument) {
    case .value(let value):
        return (name, value)
    case .notLiteral:
        return nil
    }
}

internal enum WKPortableJSDialog {
    case alert(String)
    case confirm(String)
    case prompt(String, String?)
}

internal func WKPortableParseJSDialog(_ source: String) -> WKPortableJSDialog? {
    let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
    if let message = WKPortableParseJSCall(trimmed, name: "alert", arguments: 1) {
        return .alert(message[0])
    }
    if let message = WKPortableParseJSCall(trimmed, name: "confirm", arguments: 1) {
        return .confirm(message[0])
    }
    if let message = WKPortableParseJSCall(trimmed, name: "prompt", arguments: 2) {
        return .prompt(message[0], message[1])
    }
    if let message = WKPortableParseJSCall(trimmed, name: "prompt", arguments: 1) {
        return .prompt(message[0], nil)
    }
    return nil
}

private func WKPortableParseJSCall(
    _ source: String,
    name: String,
    arguments: Int
) -> [String]? {
    guard source.hasPrefix(name + "("), source.hasSuffix(")") else { return nil }
    let inner = String(source.dropFirst(name.count + 1).dropLast())
        .trimmingCharacters(in: .whitespacesAndNewlines)
    if arguments == 1 {
        switch WKPortableJavaScriptLiteral(inner) {
        case .value(let value):
            return [String(describing: value)]
        case .notLiteral:
            return nil
        }
    }
    guard let comma = WKPortableSplitTopLevelComma(inner) else { return nil }
    switch (WKPortableJavaScriptLiteral(comma.0), WKPortableJavaScriptLiteral(comma.1)) {
    case (.value(let first), .value(let second)):
        return [String(describing: first), String(describing: second)]
    default:
        return nil
    }
}

private func WKPortableSplitTopLevelComma(_ source: String) -> (String, String)? {
    var depth = 0
    var inString: Character?
    var escaped = false
    for index in source.indices {
        let character = source[index]
        if let quote = inString {
            if escaped {
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == quote {
                inString = nil
            }
            continue
        }
        if character == "\"" || character == "'" {
            inString = character
            continue
        }
        if character == "(" { depth += 1 }
        if character == ")" { depth -= 1 }
        if character == ",", depth == 0 {
            let left = String(source[..<index]).trimmingCharacters(in: .whitespacesAndNewlines)
            let right = String(source[source.index(after: index)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (left, right)
        }
    }
    return nil
}
