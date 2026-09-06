import Foundation
import WebKit

private func wkPatternMain<T>(_ body: @escaping @MainActor () throws -> T) -> T {
    do {
        return try MainActor.assumeIsolated { try body() }
    } catch {
        fatalError("WebKit match-pattern test failed: \(error)")
    }
}

func testMatchPatternParsesChromeFormat() {
    wkPatternMain {
        let pattern = try WKWebExtension.MatchPattern(string: "*://example.com/*")
        precondition(pattern.scheme == "*")
        precondition(pattern.host == "example.com")
        precondition(pattern.path == "/*")
        precondition(pattern.string == "*://example.com/*")
        precondition(!pattern.matchesAllHosts)
        precondition(!pattern.matchesAllURLs)
        let fromParts = try WKWebExtension.MatchPattern(scheme: "https", host: "example.com", path: "/foo*")
        precondition(fromParts.host == "example.com")
        let all = WKWebExtension.MatchPattern.allURLs()
        precondition(all.matchesAllURLs)
        precondition(all.string == "<all_urls>")
        let hosts = WKWebExtension.MatchPattern.allHostsAndSchemes()
        precondition(hosts.matchesAllHosts)
        WKWebExtension.MatchPattern.registerCustomURLScheme("app")
        _ = pattern.hash
        let duplicate = try WKWebExtension.MatchPattern(string: "*://example.com/*")
        precondition(pattern.isEqual(duplicate))
    }
}

func testMatchPatternMatchesURLsAndWildcards() {
    wkPatternMain {
        let exact = try WKWebExtension.MatchPattern(string: "*://example.com/*")
        precondition(exact.matches(URL(string: "https://example.com/foo")!))
        precondition(exact.matches(URL(string: "http://example.com/")!))
        precondition(!exact.matches(URL(string: "https://other.com/foo")!))
        precondition(!exact.matches(URL(string: "file:///tmp/x")!))
        let subdomain = try WKWebExtension.MatchPattern(string: "*://*.example.com/*")
        precondition(subdomain.matches(URL(string: "https://www.example.com/a")!))
        precondition(subdomain.matches(URL(string: "https://example.com/")!))
        precondition(!subdomain.matches(URL(string: "https://notexample.com/")!))
        let allHTTP = try WKWebExtension.MatchPattern(string: "*://*/*")
        precondition(allHTTP.matches(URL(string: "https://anywhere.invalid/x")!))
        precondition(!allHTTP.matches(URL(string: "file:///tmp/x")!))
        let allURLs = try WKWebExtension.MatchPattern(string: "<all_urls>")
        precondition(allURLs.matches(URL(string: "https://anywhere.invalid/x")!))
        precondition(allURLs.matches(URL(string: "file:///tmp/x")!))
        let file = try WKWebExtension.MatchPattern(string: "file:///*")
        precondition(file.matches(URL(string: "file:///tmp/x")!))
    }
}

func testMatchPatternOptionsAndErrors() {
    wkPatternMain {
        let pattern = try WKWebExtension.MatchPattern(string: "https://example.com/foo")
        let otherHost = URL(string: "http://example.com/foo")!
        precondition(!pattern.matches(otherHost))
        precondition(pattern.matches(otherHost, options: .ignoreSchemes))
        let otherPath = URL(string: "https://example.com/bar")!
        precondition(pattern.matches(otherPath, options: .ignorePaths))
        let other = try WKWebExtension.MatchPattern(string: "https://example.com/foo")
        precondition(pattern.matches(other))
        let wildcard = try WKWebExtension.MatchPattern(string: "*://example.com/*")
        precondition(
            pattern.matches(wildcard, options: .matchBidirectionally)
                || other.matches(pattern, options: .matchBidirectionally)
        )
        var options = WKWebExtension.MatchPattern.Options.ignoreSchemes
        options.formUnion(.ignorePaths)
        _ = options.intersection(.matchBidirectionally)
        _ = options.contains(.ignoreSchemes)
        _ = options != []
        _ = options == .ignoreSchemes
        precondition(WKWebExtension.MatchPattern.Options.ignoreSchemes.rawValue != 0)
        precondition(WKWebExtension.MatchPattern.Options.ignorePaths.rawValue != 0)
        precondition(WKWebExtension.MatchPattern.Options.matchBidirectionally.rawValue != 0)
        do {
            _ = try WKWebExtension.MatchPattern(string: "nocolon")
            fatalError("expected invalid scheme")
        } catch let error as WKWebExtension.MatchPattern.Error {
            precondition(error.code == .invalidScheme)
            precondition(WKWebExtension.MatchPattern.Error.invalidScheme ~= error)
        }
        do {
            _ = try WKWebExtension.MatchPattern(string: "https://ex.com")
            fatalError("expected invalid path")
        } catch let error as WKWebExtension.MatchPattern.Error {
            precondition(error.code == .invalidPath)
        }
        do {
            _ = try WKWebExtension.MatchPattern(scheme: "https", host: "", path: "/")
            fatalError("expected invalid host")
        } catch let error as WKWebExtension.MatchPattern.Error {
            precondition(error.code == .invalidHost)
        }
        precondition(WKWebExtension.MatchPattern.Error.Code.unknown.rawValue == 1)
        precondition(WKWebExtension.MatchPattern.Error.Code.invalidScheme.rawValue == 2)
        precondition(WKWebExtension.MatchPattern.Error.Code.invalidHost.rawValue == 3)
        precondition(WKWebExtension.MatchPattern.Error.Code.invalidPath.rawValue == 4)
        precondition(WKWebExtension.MatchPattern.errorDomain == "WKWebExtensionMatchPatternErrorDomain")
        precondition(WKWebExtension.MatchPattern.Error.errorDomain == WKWebExtension.MatchPattern.errorDomain)
        let encoded = WKWebExtension.MatchPattern.Error(.unknown)
        _ = encoded.errorCode
        _ = encoded.errorUserInfo
        _ = encoded.localizedDescription
        _ = encoded.hashValue
        precondition(encoded == WKWebExtension.MatchPattern.Error(.unknown))
        precondition(encoded != WKWebExtension.MatchPattern.Error(.invalidHost))
    }
}
