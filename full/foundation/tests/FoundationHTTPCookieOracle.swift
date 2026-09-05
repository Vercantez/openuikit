#if HTTPCOOKIE_PORT
import HTTPCookiePort
import Foundation
private typealias TestCookie = HTTPCookiePort.HTTPCookie
private typealias TestStorage = HTTPCookiePort.HTTPCookieStorage
private typealias TestKey = HTTPCookiePort.HTTPCookiePropertyKey
#else
import Foundation
private typealias TestCookie = HTTPCookie
private typealias TestStorage = HTTPCookieStorage
private typealias TestKey = HTTPCookiePropertyKey
#endif

private func emit(_ key: String, _ value: Any) {
    print("\(key)\t\(value)")
}

private func describe(_ cookie: TestCookie?, includeExpires: Bool = true) -> String {
    guard let cookie else { return "nil" }
    var parts = [
        "name=\(cookie.name)",
        "value=\(cookie.value)",
        "domain=\(cookie.domain)",
        "path=\(cookie.path)",
        "secure=\(cookie.isSecure)",
        "httpOnly=\(cookie.isHTTPOnly)",
        "session=\(cookie.isSessionOnly)",
    ]
    // Max-Age is relative to Date(), so the absolute expires wall-clock is
    // not a stable golden. Absolute Expires: dates are.
    if includeExpires, let expires = cookie.expiresDate {
        parts.append("expires=\(expires.timeIntervalSince1970)")
    }
    return parts.joined(separator: ";")
}

private let origin = URL(string: "https://www.example.test/account/login")!

// Construction from properties (Hackers NetworkManagerTests).
for (label, properties) in [
    ("host", [
        TestKey.domain: "example.test",
        TestKey.path: "/secure",
        TestKey.name: "host",
        TestKey.value: "one",
    ] as [TestKey: Any]),
    ("dot-domain", [
        TestKey.domain: ".example.test",
        TestKey.path: "/",
        TestKey.name: "domain",
        TestKey.value: "two",
    ] as [TestKey: Any]),
    ("missing-name", [
        TestKey.domain: "example.test",
        TestKey.path: "/",
        TestKey.value: "x",
    ] as [TestKey: Any]),
    ("relative-path", [
        TestKey.domain: "example.test",
        TestKey.path: "no-slash",
        TestKey.name: "bad",
        TestKey.value: "x",
    ] as [TestKey: Any]),
] {
    emit("init.\(label)", describe(TestCookie(properties: properties)))
}

// Set-Cookie parsing (RFC 6265 subset Apple implements).
private let headers: [(String, [String: String])] = [
    ("basic", ["Set-Cookie": "id=abc; Path=/; Domain=example.test"]),
    ("httponly-secure", ["Set-Cookie": "sid=1; Path=/account; Secure; HttpOnly"]),
    ("max-age", ["Set-Cookie": "tmp=1; Max-Age=60; Path=/"]),
    ("expires-imf", ["Set-Cookie": "old=1; Expires=Wed, 21 Oct 2015 07:28:00 GMT; Path=/"]),
    ("ignore-other", ["X-Other": "id=abc"]),
    ("default-path", ["Set-Cookie": "p=1"]),
]
for (label, fields) in headers {
    let cookies = TestCookie.cookies(withResponseHeaderFields: fields, for: origin)
    if cookies.isEmpty {
        emit("parse.\(label)", "empty")
    } else {
        for (index, cookie) in cookies.enumerated() {
            emit(
                "parse.\(label).\(index)",
                describe(cookie, includeExpires: label != "max-age")
            )
        }
    }
}

private let jar = TestStorage.shared
private let hostOnly = TestCookie(properties: [
    .domain: "example.test", .path: "/secure", .name: "ouik-sf-host", .value: "one",
])!
private let domain = TestCookie(properties: [
    .domain: ".example.test", .path: "/", .name: "ouik-sf-domain", .value: "two",
])!
private let expired = TestCookie(properties: [
    .domain: "example.test", .path: "/", .name: "ouik-sf-expired", .value: "gone",
    .expires: Date(timeIntervalSince1970: 1),
])!
for cookie in [hostOnly, domain, expired] { jar.deleteCookie(cookie) }
jar.setCookie(hostOnly)
jar.setCookie(domain)
jar.setCookie(expired)
private func prefixed(_ cookies: [TestCookie]?) -> String {
    (cookies ?? []).filter { $0.name.hasPrefix("ouik-sf-") }.map(\.name).sorted().joined(separator: ",")
}
emit(
    "store.expired-dropped",
    jar.cookies?.contains(where: { $0.name == "ouik-sf-expired" }) == true
)
emit(
    "store.https-secure-child",
    prefixed(jar.cookies(for: URL(string: "https://example.test/secure/child")!))
)
emit(
    "store.subdomain",
    prefixed(jar.cookies(for: URL(string: "https://sub.example.test/secure/child")!))
)
emit(
    "store.path-miss",
    prefixed(jar.cookies(for: URL(string: "https://example.test/other")!))
)

private let header = TestCookie.requestHeaderFields(with: [domain, hostOnly])
emit("header.cookie", header["Cookie"] ?? "")

private let replaceURL = URL(string: "https://replace.test/")!
if let old = TestCookie(properties: [
    .domain: "replace.test", .path: "/", .name: "ouik-sf-value", .value: "old",
]) {
    jar.deleteCookie(old)
    jar.setCookie(old)
}
if let gone = TestCookie(properties: [
    .domain: "replace.test", .path: "/", .name: "ouik-sf-value", .value: "deleted",
    .expires: Date(timeIntervalSince1970: 1),
]) {
    jar.setCookies([gone], for: replaceURL, mainDocumentURL: replaceURL)
}
emit(
    "store.replace-expired-deletes",
    prefixed(jar.cookies(for: replaceURL)).isEmpty
)
for cookie in jar.cookies ?? [] where cookie.name.hasPrefix("ouik-sf-") {
    jar.deleteCookie(cookie)
}
