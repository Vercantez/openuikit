#if URLCOMPONENTS_PORT
import URLComponentsPort
import Foundation
private typealias TestComponents = URLComponentsPort.URLComponents
private typealias TestQueryItem = URLComponentsPort.URLQueryItem
#else
import Foundation
private typealias TestComponents = URLComponents
private typealias TestQueryItem = URLQueryItem
#endif

private func emit(_ key: String, _ value: Any) {
    print("\(key)\t\(value)")
}

private func describe(_ c: TestComponents?) -> String {
    guard let c else { return "nil" }
    func opt(_ v: String?) -> String { v ?? "nil" }
    func optI(_ v: Int?) -> String { v.map(String.init) ?? "nil" }
    return [
        "scheme=\(opt(c.scheme))",
        "user=\(opt(c.user))",
        "password=\(opt(c.password))",
        "host=\(opt(c.host))",
        "port=\(optI(c.port))",
        "path=\(c.path)",
        "query=\(opt(c.query))",
        "fragment=\(opt(c.fragment))",
        "peHost=\(opt(c.percentEncodedHost))",
        "pePath=\(c.percentEncodedPath)",
        "peQuery=\(opt(c.percentEncodedQuery))",
        "peFragment=\(opt(c.percentEncodedFragment))",
        "string=\(opt(c.string))",
    ].joined(separator: ";")
}

private func describeItems(_ items: [TestQueryItem]?) -> String {
    guard let items else { return "nil" }
    return items.map { "\($0.name)=\($0.value ?? "nil")" }.joined(separator: "&")
}

// MEASURED 2026-09-06 Apple Foundation URLComponents on macOS 26.
for (label, sample) in [
    ("http-host", "http://example.com"),
    ("full", "https://user:pass@example.com:8080/path/to?q=1&b=2#frag"),
    ("slash-path", "http://example.com/"),
    ("relative", "/relative/path?x=1"),
    ("ipv6", "http://[::1]:8080/foo"),
    ("pct-space-path", "http://example.com/a%20b"),
    ("cafe-path", "http://example.com/café"),
    ("query-space", "http://example.com?q=hello%20world"),
    ("query-plus", "http://example.com?q=hello+world"),
    ("empty-query", "http://example.com?"),
    ("empty-frag", "http://example.com#"),
    ("user-only", "http://user@example.com"),
    ("user-empty-pass", "http://user:@example.com"),
    ("empty-user-pass", "http://:pass@example.com"),
    ("port-0", "http://example.com:0/"),
    ("file", "file:///tmp/foo"),
    ("pct-slash-path", "http://example.com/path%2Fname"),
    ("space-host", "http://ex ample.com"),
    ("bare-words", "not a url"),
    ("empty", ""),
    ("scheme-only", "http://"),
    ("dup-query", "http://example.com/a?b=1&b=2"),
    ("query-eq", "http://example.com/?="),
    ("query-name", "http://example.com/?a"),
    ("query-empty-val", "http://example.com/?a="),
    ("query-empty-name", "http://example.com/?=b"),
    ("mailto", "mailto:foo@example.com"),
    ("net-path", "//example.com/path"),
    ("scheme-case", "HTTP://EXAMPLE.COM/FOO"),
    ("query-amp", "http://example.com?q=%26"),
    ("idn-puny", "http://xn--fsq.com"),
    ("idn-unicode", "http://例子.测试"),
    ("zone-id", "http://[fe80::1%25en0]/"),
] {
    let parsed = TestComponents(string: sample)
    emit("parse.\(label)", describe(parsed))
    if let parsed {
        emit("parse.\(label).items", describeItems(parsed.queryItems))
    }
}

emit("encInv.cafe.true", describe(TestComponents(string: "http://example.com/café", encodingInvalidCharacters: true)))
emit("encInv.cafe.false", describe(TestComponents(string: "http://example.com/café", encodingInvalidCharacters: false)))

let rel = URL(string: "/rel/path?x=1", relativeTo: URL(string: "http://example.com/base/")!)!
emit("url.rel.false", describe(TestComponents(url: rel, resolvingAgainstBaseURL: false)))
emit("url.rel.true", describe(TestComponents(url: rel, resolvingAgainstBaseURL: true)))

private var empty = TestComponents()
emit("empty", describe(empty))
empty.scheme = "https"
empty.host = "example.com"
empty.path = "/foo"
empty.query = "a=1"
empty.fragment = "z"
emit("built", describe(empty))
empty.path = "foo"
emit("built.barePath", describe(empty))

private var q = TestComponents()
q.scheme = "http"
q.host = "example.com"
q.path = "/"
q.queryItems = [TestQueryItem(name: "k", value: "hello world")]
emit("qi.space", "query=\(q.query ?? "nil");peQuery=\(q.percentEncodedQuery ?? "nil");string=\(q.string ?? "nil")")
q.queryItems = [TestQueryItem(name: "k", value: "a&b=c")]
emit("qi.amp-eq", "query=\(q.query ?? "nil");peQuery=\(q.percentEncodedQuery ?? "nil")")
q.queryItems = [TestQueryItem(name: "k", value: "+")]
emit("qi.plus", "peQuery=\(q.percentEncodedQuery ?? "nil")")
q.queryItems = [TestQueryItem(name: "a", value: nil)]
emit("qi.nilValue", "query=\(q.query ?? "nil");items=\(describeItems(q.queryItems));string=\(q.string ?? "nil")")
q.queryItems = []
emit("qi.empty", "query=\(q.query ?? "nil");string=\(q.string ?? "nil")")
q.queryItems = nil
emit("qi.nil", "query=\(q.query ?? "nil");string=\(q.string ?? "nil")")
q.percentEncodedQueryItems = [TestQueryItem(name: "a%20b", value: "c%26d")]
emit("peqi", "query=\(q.query ?? "nil");peQuery=\(q.percentEncodedQuery ?? "nil");items=\(describeItems(q.queryItems))")

q.host = "café.com"
emit("host.cafe", "host=\(q.host ?? "nil");peHost=\(q.percentEncodedHost ?? "nil");string=\(q.string ?? "nil")")
q.host = "example.com"
q.user = "u ser"
q.password = "p@ss"
q.path = "/"
emit("userinfo", "peUser=\(q.percentEncodedUser ?? "nil");pePassword=\(q.percentEncodedPassword ?? "nil");string=\(q.string ?? "nil")")

q = TestComponents()
q.scheme = "http"
q.percentEncodedHost = "[::1]"
q.path = "/"
emit("host.ipv6", describe(q))

private var encodeMap: [String] = []
q = TestComponents()
q.scheme = "http"
q.host = "h"
q.path = "/"
for code in 32..<127 {
    let ch = String(UnicodeScalar(code)!)
    q.queryItems = [TestQueryItem(name: "k", value: ch)]
    let pe = q.percentEncodedQuery ?? ""
    let encoded = pe.hasPrefix("k=") ? String(pe.dropFirst(2)) : pe
    if encoded != ch {
        encodeMap.append(String(format: "%02X->%@", code, encoded))
    }
}
emit("qi.encodeMap", encodeMap.joined(separator: ";"))
