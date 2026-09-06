#if HTTPCOOKIE_PORT
import Foundation
#else
import FoundationEssentials
import COpenURLTransport

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("Foundation URL loading requires the ObjectiveC NSObject substrate")
#endif
#endif

#if !HTTPCOOKIE_PORT
public let NSURLErrorDomain = "NSURLErrorDomain"
public let NSURLErrorFailingURLErrorKey = "NSErrorFailingURLKey"
public let NSURLErrorFailingURLStringErrorKey = "NSErrorFailingURLStringKey"

private func _isHTTPTokenByte(_ byte: UInt8) -> Bool {
    (byte >= 48 && byte <= 57) || (byte >= 65 && byte <= 90)
        || (byte >= 97 && byte <= 122)
        || [33, 35, 36, 37, 38, 39, 42, 43, 45, 46, 94, 95, 96, 124, 126]
            .contains(byte)
}

public struct URLError: Error, CustomNSError, Sendable, Equatable {
    public struct Code: RawRepresentable, Hashable, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let unknown = Self(rawValue: -1)
        public static let cancelled = Self(rawValue: -999)
        public static let badURL = Self(rawValue: -1000)
        public static let timedOut = Self(rawValue: -1001)
        public static let unsupportedURL = Self(rawValue: -1002)
        public static let cannotFindHost = Self(rawValue: -1003)
        public static let cannotConnectToHost = Self(rawValue: -1004)
        public static let networkConnectionLost = Self(rawValue: -1005)
        public static let dnsLookupFailed = Self(rawValue: -1006)
        public static let httpTooManyRedirects = Self(rawValue: -1007)
        public static let resourceUnavailable = Self(rawValue: -1008)
        public static let notConnectedToInternet = Self(rawValue: -1009)
        public static let redirectToNonExistentLocation = Self(rawValue: -1010)
        public static let badServerResponse = Self(rawValue: -1011)
        public static let userCancelledAuthentication = Self(rawValue: -1012)
        public static let userAuthenticationRequired = Self(rawValue: -1013)
        public static let zeroByteResource = Self(rawValue: -1014)
        public static let cannotDecodeRawData = Self(rawValue: -1015)
        public static let cannotDecodeContentData = Self(rawValue: -1016)
        public static let cannotParseResponse = Self(rawValue: -1017)
        public static let dataLengthExceedsMaximum = Self(rawValue: -1103)
        public static let appTransportSecurityRequiresSecureConnection = Self(rawValue: -1022)
        public static let secureConnectionFailed = Self(rawValue: -1200)
        public static let serverCertificateHasBadDate = Self(rawValue: -1201)
        public static let serverCertificateUntrusted = Self(rawValue: -1202)
        public static let serverCertificateHasUnknownRoot = Self(rawValue: -1203)
        public static let serverCertificateNotYetValid = Self(rawValue: -1204)
        public static let clientCertificateRejected = Self(rawValue: -1205)
        public static let clientCertificateRequired = Self(rawValue: -1206)
        public static let cannotLoadFromNetwork = Self(rawValue: -2000)
    }

    public let code: Code
    public let failureURL: URL?
    private let detail: String?

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.failureURL = userInfo[NSURLErrorFailingURLErrorKey] as? URL
        self.detail = userInfo[NSLocalizedFailureReasonErrorKey] as? String
    }

    internal init(_ code: Code, url: URL? = nil, detail: String? = nil) {
        self.code = code
        self.failureURL = url
        self.detail = detail
    }

    public static var errorDomain: String { NSURLErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] {
        var result: [String: Any] = [:]
        if let failureURL {
            result[NSURLErrorFailingURLErrorKey] = failureURL
            result[NSURLErrorFailingURLStringErrorKey] = failureURL.absoluteString
        }
        if let detail { result[NSLocalizedFailureReasonErrorKey] = detail }
        return result
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.code == rhs.code && lhs.failureURL == rhs.failureURL
    }
}

open class HTTPURLResponse: URLResponse, @unchecked Sendable {
    public let statusCode: Int
    public let allHeaderFields: [AnyHashable: Any]
    public let httpVersion: String?

    public init?(
        url: URL,
        statusCode: Int,
        httpVersion: String?,
        headerFields: [String: String]?
    ) {
        self.statusCode = statusCode
        self.httpVersion = httpVersion
        self.allHeaderFields = Dictionary(
            uniqueKeysWithValues: (headerFields ?? [:]).map {
                (AnyHashable($0.key), $0.value as Any)
            }
        )
        let contentType = Self._header("Content-Type", in: headerFields ?? [:])
        let metadata = Self._contentMetadata(contentType)
        let length = Int(Self._header("Content-Length", in: headerFields ?? [:]) ?? "") ?? -1
        super.init(
            url: url,
            mimeType: metadata.mimeType,
            expectedContentLength: length,
            textEncodingName: metadata.encoding
        )
    }

    open func value(forHTTPHeaderField field: String) -> String? {
        for (key, value) in allHeaderFields where
            String(describing: key).caseInsensitiveCompare(field) == .orderedSame {
            return String(describing: value)
        }
        return nil
    }

    open override var suggestedFilename: String? {
        if value(forHTTPHeaderField: "Content-Disposition") != nil {
            if let fromHeader = Self._contentDispositionFilename(self), !fromHeader.isEmpty {
                return fromHeader
            }
            // MEASURED 2026-09-06: Content-Disposition without a filename
            // yields "Unknown", not the URL's last path component.
            return "Unknown"
        }
        let base = super.suggestedFilename ?? "Unknown"
        if base == "Unknown" { return base }
        // MEASURED 2026-09-06 Apple HTTPURLResponse.suggestedFilename on macOS 26:
        // text/html on b.txt → b.txt.html; application/json on data → data.json;
        // image/png on photo.jpg → photo.jpg.png. Append the MIME's preferred
        // extension when it is not already the last path extension.
        guard let ext = Self._extension(forMIME: mimeType) else { return base }
        let current: String?
        if let dot = base.lastIndex(of: "."), dot != base.startIndex {
            current = String(base[base.index(after: dot)...])
        } else {
            current = nil
        }
        if current?.lowercased() == ext { return base }
        return base + "." + ext
    }

    open class func localizedString(forStatusCode statusCode: Int) -> String {
        // MEASURED 2026-09-06 Apple HTTPURLResponse.localizedString on macOS 26.
        switch statusCode {
        case 100: return "continue"
        case 101: return "switching protocols"
        case 200: return "no error"
        case 201: return "created"
        case 204: return "no content"
        case 206: return "partial content"
        case 300: return "multiple choices"
        case 301: return "moved permanently"
        case 302: return "found"
        case 303: return "see other"
        case 304: return "not modified"
        case 307: return "temporarily redirected"
        case 308: return "redirected"
        case 400: return "bad request"
        case 401: return "unauthorized"
        case 403: return "forbidden"
        case 404: return "not found"
        case 405: return "method not allowed"
        case 408: return "request timed out"
        case 409: return "conflict"
        case 410: return "no longer exists"
        case 500: return "internal server error"
        case 501: return "unimplemented"
        case 502: return "bad gateway"
        case 503: return "service unavailable"
        case 504: return "gateway timed out"
        case 400...499: return "client error"
        default: return "server response"
        }
    }

    private static func _contentDispositionFilename(_ response: HTTPURLResponse) -> String? {
        guard let header = response.value(forHTTPHeaderField: "Content-Disposition") else {
            return nil
        }
        var filename: String?
        var encoded: String?
        let pieces = header.split(separator: ";", omittingEmptySubsequences: true)
        for piece in pieces.dropFirst() {
            let text = String(piece).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let equal = text.firstIndex(of: "=") else { continue }
            let key = text[..<equal].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            var value = String(text[text.index(after: equal)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
                value = String(value.dropFirst().dropLast())
            }
            if key == "filename*" {
                encoded = _rfc5987(value)
            } else if key == "filename" {
                filename = value
            }
        }
        let chosen = encoded ?? filename
        if let chosen, !chosen.isEmpty { return chosen }
        if pieces.count >= 1 { return nil }
        return nil
    }

    private static func _rfc5987(_ value: String) -> String? {
        // charset''percent-encoded. MEASURED filename*=UTF-8''na%20me.txt → "na me.txt"
        guard let first = value.firstIndex(of: "'"),
              let second = value[value.index(after: first)...].firstIndex(of: "'") else {
            return nil
        }
        let encoded = String(value[value.index(after: second)...])
        return encoded.removingPercentEncoding ?? encoded
    }

    private static func _extension(forMIME mime: String?) -> String? {
        switch mime {
        case "text/html": return "html"
        case "application/json": return "json"
        case "image/png": return "png"
        case "application/pdf": return "pdf"
        default: return nil
        }
    }

    private static func _header(_ name: String, in fields: [String: String]) -> String? {
        fields.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    private static func _contentMetadata(_ value: String?) -> (mimeType: String?, encoding: String?) {
        guard let value else { return (nil, nil) }
        let pieces = value.split(separator: ";", omittingEmptySubsequences: true)
        let mime = pieces.first.map {
            String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        var encoding: String?
        for piece in pieces.dropFirst() {
            let text = String(piece).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let equal = text.firstIndex(of: "=") else { continue }
            let key = text[..<equal].trimmingCharacters(in: .whitespacesAndNewlines)
            if key.caseInsensitiveCompare("charset") == .orderedSame {
                encoding = String(text[text.index(after: equal)...])
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
            }
        }
        return (mime?.isEmpty == false ? mime : nil, encoding)
    }
}
#endif

public struct HTTPCookiePropertyKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let name = Self(rawValue: "Name")
    public static let value = Self(rawValue: "Value")
    public static let originURL = Self(rawValue: "OriginURL")
    public static let version = Self(rawValue: "Version")
    public static let domain = Self(rawValue: "Domain")
    public static let path = Self(rawValue: "Path")
    public static let secure = Self(rawValue: "Secure")
    public static let expires = Self(rawValue: "Expires")
    public static let comment = Self(rawValue: "Comment")
    public static let commentURL = Self(rawValue: "CommentURL")
    public static let discard = Self(rawValue: "Discard")
    public static let maximumAge = Self(rawValue: "Max-Age")
    public static let port = Self(rawValue: "Port")
}

open class HTTPCookie: NSObject, @unchecked Sendable {
    public let properties: [HTTPCookiePropertyKey: Any]?
    public let name: String
    public let value: String
    public let domain: String
    public let path: String
    public let expiresDate: Date?
    public let isSecure: Bool
    public let isHTTPOnly: Bool
    public let isSessionOnly: Bool
    fileprivate let creationDate: Date

    public init?(properties: [HTTPCookiePropertyKey: Any]) {
        guard let name = properties[.name] as? String,
              let value = properties[.value] as? String,
              !name.isEmpty else { return nil }
        let originURL = properties[.originURL] as? URL
        guard let rawDomain = (properties[.domain] as? String) ?? originURL?.host,
              !rawDomain.isEmpty else { return nil }
        let rawPath = (properties[.path] as? String) ?? "/"
        // MEASURED 2026-09-05 Apple HTTPCookie(properties:) on macOS:
        // path "no-slash" is stored as-is (FoundationHTTPCookieOracle
        // init.relative-path). A leading-slash requirement would reject
        // a cookie Apple accepts.

        var expiration = properties[.expires] as? Date
        if expiration == nil, let text = properties[.expires] as? String {
            expiration = _HTTPDateParser.parse(text)
        }
        if let maximumAge = Self._integer(properties[.maximumAge]) {
            expiration = Date().addingTimeInterval(TimeInterval(maximumAge))
        }

        self.properties = properties
        self.name = name
        self.value = value
        self.domain = rawDomain.lowercased()
        self.path = rawPath
        self.expiresDate = expiration
        self.isSecure = Self._truth(properties[.secure])
        self.isHTTPOnly = properties.keys.contains {
            $0.rawValue.caseInsensitiveCompare("HttpOnly") == .orderedSame
        }
        self.isSessionOnly = expiration == nil
        self.creationDate = Date()
        super.init()
    }

    fileprivate func matches(_ url: URL) -> Bool {
        guard domainMatches(url) else { return false }
        let requestPath = url.path.isEmpty ? "/" : url.path
        let pathMatches = requestPath == path || requestPath.hasPrefix(
            path.hasSuffix("/") ? path : path + "/"
        )
        let secureMatches = !isSecure || url.scheme?.lowercased() == "https"
        return pathMatches && secureMatches && !isExpired
    }

    fileprivate func domainMatches(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        let domainMatches: Bool
        if domain.hasPrefix(".") {
            let suffix = String(domain.dropFirst())
            domainMatches = host == suffix || host.hasSuffix("." + suffix)
        } else {
            domainMatches = host == domain
        }
        return domainMatches
    }

    fileprivate var isExpired: Bool { expiresDate.map { $0 <= Date() } ?? false }

    public class func requestHeaderFields(with cookies: [HTTPCookie]) -> [String: String] {
        guard !cookies.isEmpty else { return [:] }
        // MEASURED 2026-09-05 Apple HTTPCookie.requestHeaderFields:
        // input order is preserved (`c=3; b=2; a=1` for [c,b,a] even though
        // / is shorter than /a/b). Path-length sorting would mismatch.
        return ["Cookie": cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")]
    }

    public class func cookies(
        withResponseHeaderFields headerFields: [String: String],
        for URL: URL
    ) -> [HTTPCookie] {
        headerFields.compactMap { key, value in
            guard key.caseInsensitiveCompare("Set-Cookie") == .orderedSame else { return nil }
            return _responseCookie(value, for: URL)
        }
    }

    fileprivate class func _responseCookie(_ line: String, for url: URL) -> HTTPCookie? {
        let pieces = line.split(separator: ";", omittingEmptySubsequences: false)
        guard let first = pieces.first, let equals = first.firstIndex(of: "=") else { return nil }
        let name = String(first[..<equals]).trimmingCharacters(in: .whitespacesAndNewlines)
        let value = String(first[first.index(after: equals)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let host = url.host?.lowercased() else { return nil }

        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: host,
            .path: _defaultPath(for: url),
            .originURL: url,
        ]
        for rawPiece in pieces.dropFirst() {
            let piece = String(rawPiece).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !piece.isEmpty else { continue }
            let split = piece.firstIndex(of: "=")
            let key = String(split.map { piece[..<$0] } ?? piece[...]).lowercased()
            let attribute = split.map {
                String(piece[piece.index(after: $0)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            switch key {
            case "domain":
                if var domain = attribute?.lowercased(), !domain.isEmpty {
                    if !domain.hasPrefix(".") { domain = "." + domain }
                    let suffix = String(domain.dropFirst())
                    guard host == suffix || host.hasSuffix("." + suffix) else { return nil }
                    properties[.domain] = domain
                }
            case "path":
                if let attribute, attribute.hasPrefix("/") { properties[.path] = attribute }
            case "secure": properties[.secure] = true
            case "httponly": properties[HTTPCookiePropertyKey(rawValue: "HttpOnly")] = true
            case "expires": if let attribute { properties[.expires] = attribute }
            case "max-age": if let attribute { properties[.maximumAge] = attribute }
            default: continue
            }
        }
        return HTTPCookie(properties: properties)
    }

    private class func _defaultPath(for url: URL) -> String {
        let path = url.path
        guard path.hasPrefix("/"), path != "/", let slash = path.lastIndex(of: "/") else {
            return "/"
        }
        let prefix = String(path[..<slash])
        return prefix.isEmpty ? "/" : prefix
    }

    private class func _truth(_ value: Any?) -> Bool {
        if let value = value as? Bool { return value }
        if let value = value as? String {
            return value.isEmpty || value.caseInsensitiveCompare("TRUE") == .orderedSame
        }
        return false
    }

    private class func _integer(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? String { return Int(value) }
        if let value = value as? NSNumber { return value.intValue }
        return nil
    }
}

private enum _HTTPDateParser {
    static func parse(_ source: String) -> Date? {
        let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if let comma = text.firstIndex(of: ",") {
            let tail = text[text.index(after: comma)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if tail.contains("-") { return parseRFC850(tail) }
            return parseIMF(tail)
        }
        return parseASCTime(text)
    }

    private static func parseIMF(_ text: String) -> Date? {
        let fields = text.split(whereSeparator: { $0 == " " || $0 == "\t" })
        guard fields.count >= 5,
              let day = Int(fields[0]), let month = month(fields[1]),
              let year = Int(fields[2]), let time = time(fields[3]) else { return nil }
        return date(year, month, day, time)
    }

    private static func parseRFC850(_ text: String) -> Date? {
        let fields = text.split(whereSeparator: { $0 == " " || $0 == "\t" })
        guard fields.count >= 3 else { return nil }
        let dateFields = fields[0].split(separator: "-")
        guard dateFields.count == 3,
              let day = Int(dateFields[0]), let month = month(dateFields[1]),
              let shortYear = Int(dateFields[2]), let time = time(fields[1]) else { return nil }
        let year = shortYear >= 70 ? 1900 + shortYear : 2000 + shortYear
        return date(year, month, day, time)
    }

    private static func parseASCTime(_ text: String) -> Date? {
        let fields = text.split(whereSeparator: { $0 == " " || $0 == "\t" })
        guard fields.count >= 5, let month = month(fields[1]),
              let day = Int(fields[2]), let time = time(fields[3]),
              let year = Int(fields[4]) else { return nil }
        return date(year, month, day, time)
    }

    private static func month<S: StringProtocol>(_ text: S) -> Int? {
        let names = ["jan", "feb", "mar", "apr", "may", "jun",
                     "jul", "aug", "sep", "oct", "nov", "dec"]
        guard let index = names.firstIndex(of: text.lowercased()) else { return nil }
        return index + 1
    }

    private static func time<S: StringProtocol>(_ text: S) -> (Int, Int, Int)? {
        let fields = text.split(separator: ":")
        guard fields.count == 3, let hour = Int(fields[0]),
              let minute = Int(fields[1]), let second = Int(fields[2]) else { return nil }
        return (hour, minute, second)
    }

    private static func date(
        _ year: Int, _ month: Int, _ day: Int, _ time: (Int, Int, Int)
    ) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = time.0
        components.minute = time.1
        components.second = time.2
        return calendar.date(from: components)
    }
}

open class HTTPCookieStorage: NSObject, @unchecked Sendable {
    public enum AcceptPolicy: UInt, Sendable {
        case always
        case never
        case onlyFromMainDocumentDomain
    }

    public static let shared = HTTPCookieStorage()

    private let lock = NSLock()
    private var storedCookies: [HTTPCookie] = []
    private var storedPolicy: AcceptPolicy = .always

    open var cookieAcceptPolicy: AcceptPolicy {
        get { lock.withLock { storedPolicy } }
        set { lock.withLock { storedPolicy = newValue } }
    }

    open var cookies: [HTTPCookie]? {
        lock.withLock {
            _removeExpired()
            return storedCookies
        }
    }

    open func setCookie(_ cookie: HTTPCookie) {
        lock.withLock {
            guard storedPolicy != .never else { return }
            storedCookies.removeAll {
                $0.name == cookie.name && $0.domain == cookie.domain && $0.path == cookie.path
            }
            if cookie.expiresDate.map({ $0 <= Date() }) != true {
                storedCookies.append(cookie)
            }
        }
    }

    open func deleteCookie(_ cookie: HTTPCookie) {
        lock.withLock {
            storedCookies.removeAll {
                $0.name == cookie.name && $0.domain == cookie.domain && $0.path == cookie.path
            }
        }
    }

    open func removeCookies(since date: Date) {
        lock.withLock { storedCookies.removeAll { $0.creationDate >= date } }
    }

    open func cookies(for URL: URL) -> [HTTPCookie]? {
        lock.withLock {
            _removeExpired()
            return storedCookies.filter { $0.matches(URL) }
        }
    }

    open func setCookies(_ cookies: [HTTPCookie], for URL: URL?, mainDocumentURL: URL?) {
        let policy = cookieAcceptPolicy
        guard policy != .never else { return }
        if policy == .onlyFromMainDocumentDomain, let URL, let mainDocumentURL,
           URL.host?.lowercased() != mainDocumentURL.host?.lowercased() { return }
        for cookie in cookies where URL.map({ cookie.domainMatches($0) }) ?? true {
            setCookie(cookie)
        }
    }

    private func _removeExpired() {
        let now = Date()
        storedCookies.removeAll { $0.expiresDate.map { $0 <= now } ?? false }
    }
}

#if !HTTPCOOKIE_PORT
open class CachedURLResponse: NSObject, @unchecked Sendable {
    public let response: URLResponse
    public let data: Data
    public let userInfo: [AnyHashable: Any]?
    public let storagePolicy: URLCache.StoragePolicy

    public init(
        response: URLResponse,
        data: Data,
        userInfo: [AnyHashable: Any]? = nil,
        storagePolicy: URLCache.StoragePolicy = .allowed
    ) {
        self.response = response
        self.data = data
        self.userInfo = userInfo
        self.storagePolicy = storagePolicy
        super.init()
    }
}

open class URLCache: NSObject, @unchecked Sendable {
    public enum StoragePolicy: UInt, Sendable {
        case allowed = 0
        case allowedInMemoryOnly = 1
        case notAllowed = 2
    }

    private struct Entry {
        let response: CachedURLResponse
        var access: UInt64
    }

    private static let sharedLock = NSLock()
    private nonisolated(unsafe) static var sharedStorage = URLCache(
        memoryCapacity: 4 * 1024 * 1024,
        diskCapacity: 20 * 1024 * 1024
    )

    open class var shared: URLCache {
        get { sharedLock.withLock { sharedStorage } }
        set { sharedLock.withLock { sharedStorage = newValue } }
    }

    private let lock = NSLock()
    private var entries: [URLRequest: Entry] = [:]
    private var clock: UInt64 = 0
    private var storedMemoryCapacity: Int
    private var storedDiskCapacity: Int
    private var memoryUsage = 0

    open var memoryCapacity: Int {
        get { lock.withLock { storedMemoryCapacity } }
        set { lock.withLock { storedMemoryCapacity = max(0, newValue); _evict() } }
    }
    open var diskCapacity: Int {
        get { lock.withLock { storedDiskCapacity } }
        set { lock.withLock { storedDiskCapacity = max(0, newValue) } }
    }
    open var currentMemoryUsage: Int { lock.withLock { memoryUsage } }
    open var currentDiskUsage: Int { 0 }

    public init(memoryCapacity: Int, diskCapacity: Int, diskPath: String? = nil) {
        self.storedMemoryCapacity = max(0, memoryCapacity)
        self.storedDiskCapacity = max(0, diskCapacity)
        super.init()
    }

    open func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        lock.withLock {
            guard var entry = entries[request] else { return nil }
            clock &+= 1
            entry.access = clock
            entries[request] = entry
            return entry.response
        }
    }

    open func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        guard cachedResponse.storagePolicy != .notAllowed else { return }
        lock.withLock {
            guard cachedResponse.data.count <= storedMemoryCapacity else { return }
            if let old = entries.removeValue(forKey: request) {
                memoryUsage -= old.response.data.count
            }
            clock &+= 1
            entries[request] = Entry(response: cachedResponse, access: clock)
            memoryUsage += cachedResponse.data.count
            _evict()
        }
    }

    open func removeCachedResponse(for request: URLRequest) {
        lock.withLock {
            if let old = entries.removeValue(forKey: request) {
                memoryUsage -= old.response.data.count
            }
        }
    }

    open func removeAllCachedResponses() {
        lock.withLock {
            entries.removeAll(keepingCapacity: false)
            memoryUsage = 0
        }
    }

    open func removeCachedResponses(since date: Date) {
        removeAllCachedResponses()
    }

    private func _evict() {
        while memoryUsage > storedMemoryCapacity, let victim = entries.min(by: {
            $0.value.access < $1.value.access
        }) {
            entries.removeValue(forKey: victim.key)
            memoryUsage -= victim.value.response.data.count
        }
    }
}

public protocol URLProtocolClient: AnyObject {
    func urlProtocol(
        _ protocol: URLProtocol,
        wasRedirectedTo request: URLRequest,
        redirectResponse: URLResponse
    )
    func urlProtocol(
        _ protocol: URLProtocol,
        cachedResponseIsValid cachedResponse: CachedURLResponse
    )
    func urlProtocol(
        _ protocol: URLProtocol,
        didReceive response: URLResponse,
        cacheStoragePolicy policy: URLCache.StoragePolicy
    )
    func urlProtocol(_ protocol: URLProtocol, didLoad data: Data)
    func urlProtocolDidFinishLoading(_ protocol: URLProtocol)
    func urlProtocol(_ protocol: URLProtocol, didFailWithError error: any Error)
}

public extension URLProtocolClient {
    func urlProtocol(
        _ protocol: URLProtocol,
        wasRedirectedTo request: URLRequest,
        redirectResponse: URLResponse
    ) {}
    func urlProtocol(
        _ protocol: URLProtocol,
        cachedResponseIsValid cachedResponse: CachedURLResponse
    ) {}
}

open class URLProtocol: NSObject, @unchecked Sendable {
    public let request: URLRequest
    public let cachedResponse: CachedURLResponse?
    public private(set) weak var client: (any URLProtocolClient)?

    public required init(
        request: URLRequest,
        cachedResponse: CachedURLResponse?,
        client: (any URLProtocolClient)?
    ) {
        self.request = request
        self.cachedResponse = cachedResponse
        self.client = client
        super.init()
    }

    open class func canInit(with request: URLRequest) -> Bool { false }
    open class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    open class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool { a == b }
    open func startLoading() {}
    open func stopLoading() {}

    private static let registryLock = NSLock()
    private static var registeredTypes: [URLProtocol.Type] = []

    open class func registerClass(_ protocolClass: AnyClass) -> Bool {
        guard let type = protocolClass as? URLProtocol.Type else { return false }
        return registryLock.withLock {
            if registeredTypes.contains(where: { $0 == type }) { return false }
            registeredTypes.append(type)
            return true
        }
    }

    open class func unregisterClass(_ protocolClass: AnyClass) {
        guard let type = protocolClass as? URLProtocol.Type else { return }
        registryLock.withLock {
            registeredTypes.removeAll { $0 == type }
        }
    }

    fileprivate static func _registered() -> [URLProtocol.Type] {
        registryLock.withLock { registeredTypes }
    }
}

public enum URLSessionResponseDisposition: Int, Sendable {
    case cancel = 0
    case allow = 1
    case becomeDownload = 2
    case becomeStream = 3
}

public enum URLSessionAuthChallengeDisposition: Int, Sendable {
    case useCredential = 0
    case performDefaultHandling = 1
    case cancelAuthenticationChallenge = 2
    case rejectProtectionSpace = 3
}

public protocol URLSessionDelegate: AnyObject, Sendable {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?)
}

public extension URLSessionDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {}
}

public protocol URLSessionTaskDelegate: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    )
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    )
}

public extension URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {}
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(request)
    }
}

public protocol URLSessionDataDelegate: URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    )
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSessionResponseDisposition) -> Void
    )
}

public extension URLSessionDataDelegate {
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {}
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSessionResponseDisposition) -> Void
    ) {
        completionHandler(.allow)
    }
}

public protocol URLSessionDownloadDelegate: URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    )
}

public extension URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {}
}

open class URLProtectionSpace: NSObject, @unchecked Sendable {
    open var host: String
    open var port: Int
    open var `protocol`: String?
    open var realm: String?
    open var authenticationMethod: String

    public init(
        host: String,
        port: Int,
        protocol: String?,
        realm: String?,
        authenticationMethod: String?
    ) {
        self.host = host
        self.port = port
        self.protocol = `protocol`
        self.realm = realm
        self.authenticationMethod = authenticationMethod ?? NSURLAuthenticationMethodDefault
        super.init()
    }
}

public let NSURLAuthenticationMethodDefault = "NSURLAuthenticationMethodDefault"
public let NSURLAuthenticationMethodHTTPBasic = "NSURLAuthenticationMethodHTTPBasic"
public let NSURLAuthenticationMethodHTTPDigest = "NSURLAuthenticationMethodHTTPDigest"
public let NSURLAuthenticationMethodNTLM = "NSURLAuthenticationMethodNTLM"
public let NSURLAuthenticationMethodNegotiate = "NSURLAuthenticationMethodNegotiate"
public let NSURLAuthenticationMethodClientCertificate = "NSURLAuthenticationMethodClientCertificate"
public let NSURLAuthenticationMethodServerTrust = "NSURLAuthenticationMethodServerTrust"

open class URLCredential: NSObject, @unchecked Sendable {
    public enum Persistence: UInt, Sendable {
        case none = 0
        case forSession = 1
        case permanent = 2
        case synchronizable = 3
    }

    open var user: String?
    open var password: String?
    open var persistence: Persistence

    public init(user: String, password: String, persistence: Persistence) {
        self.user = user
        self.password = password
        self.persistence = persistence
        super.init()
    }
}

open class URLAuthenticationChallenge: NSObject, @unchecked Sendable {
    open var protectionSpace: URLProtectionSpace
    open var proposedCredential: URLCredential?
    open var previousFailureCount: Int
    open var failureResponse: URLResponse?
    open var error: (any Error)?

    public init(
        protectionSpace: URLProtectionSpace,
        proposedCredential: URLCredential?,
        previousFailureCount: Int,
        failureResponse: URLResponse?,
        error: (any Error)?,
        sender: Any? = nil
    ) {
        self.protectionSpace = protectionSpace
        self.proposedCredential = proposedCredential
        self.previousFailureCount = previousFailureCount
        self.failureResponse = failureResponse
        self.error = error
        super.init()
        _ = sender
    }
}

open class URLSessionConfiguration: NSObject, @unchecked Sendable {
    open var requestCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    open var timeoutIntervalForRequest: TimeInterval = 60
    open var timeoutIntervalForResource: TimeInterval = 7 * 24 * 60 * 60
    open var httpCookieStorage: HTTPCookieStorage? = .shared
    open var urlCache: URLCache? = .shared
    open var protocolClasses: [AnyClass]? = []
    open var httpShouldSetCookies: Bool = true
    open var httpAdditionalHeaders: [AnyHashable: Any]?
    // MEASURED 2026-09-06 Apple URLSessionConfiguration.default on macOS 26:
    // waitsForConnectivity=false, httpMaximumConnectionsPerHost=6,
    // httpCookieAcceptPolicy rawValue 2 (onlyFromMainDocumentDomain).
    open var waitsForConnectivity: Bool = false
    open var httpMaximumConnectionsPerHost: Int = 6
    open var httpCookieAcceptPolicy: HTTPCookieStorage.AcceptPolicy = .onlyFromMainDocumentDomain
    open var httpShouldUsePipelining: Bool = false
    open var allowsCellularAccess: Bool = true
    open var allowsExpensiveNetworkAccess: Bool = true
    open var allowsConstrainedNetworkAccess: Bool = true
    open var identifier: String?
    open var isDiscretionary: Bool = false
    open var sessionSendsLaunchEvents: Bool = false
    fileprivate var isBackground: Bool = false
    private let ephemeralStorage: Bool

    private init(ephemeral: Bool) {
        self.ephemeralStorage = ephemeral
        super.init()
        if ephemeral {
            urlCache = URLCache(memoryCapacity: 512_000, diskCapacity: 0)
            httpCookieStorage = HTTPCookieStorage()
        }
    }

    open class var `default`: URLSessionConfiguration {
        URLSessionConfiguration(ephemeral: false)
    }

    open class var ephemeral: URLSessionConfiguration {
        URLSessionConfiguration(ephemeral: true)
    }

    open class func background(withIdentifier identifier: String) -> URLSessionConfiguration {
        // MEASURED 2026-09-06 Apple URLSessionConfiguration.background(withIdentifier:)
        // succeeds and stores the identifier. nsurlsessiond is not present on
        // the guest; using the session fail-closes with URLError.cannotLoadFromNetwork.
        let result = URLSessionConfiguration(ephemeral: true)
        result.identifier = identifier
        result.isBackground = true
        result.sessionSendsLaunchEvents = true
        return result
    }

    fileprivate func copied() -> URLSessionConfiguration {
        let result = URLSessionConfiguration(ephemeral: ephemeralStorage)
        result.requestCachePolicy = requestCachePolicy
        result.timeoutIntervalForRequest = timeoutIntervalForRequest
        result.timeoutIntervalForResource = timeoutIntervalForResource
        result.httpCookieStorage = httpCookieStorage
        result.urlCache = urlCache
        result.protocolClasses = protocolClasses
        result.httpShouldSetCookies = httpShouldSetCookies
        result.httpAdditionalHeaders = httpAdditionalHeaders
        result.waitsForConnectivity = waitsForConnectivity
        result.httpMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
        result.httpCookieAcceptPolicy = httpCookieAcceptPolicy
        result.httpShouldUsePipelining = httpShouldUsePipelining
        result.allowsCellularAccess = allowsCellularAccess
        result.allowsExpensiveNetworkAccess = allowsExpensiveNetworkAccess
        result.allowsConstrainedNetworkAccess = allowsConstrainedNetworkAccess
        result.identifier = identifier
        result.isDiscretionary = isDiscretionary
        result.sessionSendsLaunchEvents = sessionSendsLaunchEvents
        result.isBackground = isBackground
        return result
    }
}

private final class _URLProtocolLoader: NSObject, URLProtocolClient, @unchecked Sendable {
    typealias Output = (Data, URLResponse, URLCache.StoragePolicy)

    private let lock = NSLock()
    private var continuation: CheckedContinuation<Output, any Error>?
    private var protocolInstance: URLProtocol?
    private var response: URLResponse?
    private var data = Data()
    private var storagePolicy: URLCache.StoragePolicy = .notAllowed
    private var terminal = false

    func load(
        _ type: URLProtocol.Type,
        request: URLRequest,
        cachedResponse: CachedURLResponse?
    ) async throws -> Output {
        let canonical = type.canonicalRequest(for: request)
        let instance = type.init(request: canonical, cachedResponse: cachedResponse, client: self)
        lock.withLock { protocolInstance = instance }
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Output, any Error>) in
                let shouldStart = lock.withLock {
                    guard !terminal else { return false }
                    self.continuation = continuation
                    return true
                }
                if shouldStart {
                    instance.startLoading()
                } else {
                    continuation.resume(throwing: URLError(.cancelled))
                }
            }
        }, onCancel: { self.cancel() })
    }

    func cancel() {
        let state = lock.withLock { () -> (URLProtocol?, CheckedContinuation<Output, any Error>?) in
            guard !terminal else { return (nil, nil) }
            terminal = true
            let saved = continuation
            continuation = nil
            return (protocolInstance, saved)
        }
        state.0?.stopLoading()
        state.1?.resume(throwing: URLError(.cancelled))
    }

    func urlProtocol(
        _ protocol: URLProtocol,
        wasRedirectedTo request: URLRequest,
        redirectResponse: URLResponse
    ) {
        let saved = lock.withLock { () -> CheckedContinuation<Output, any Error>? in
            guard !terminal else { return nil }
            terminal = true
            let result = continuation
            continuation = nil
            return result
        }
        saved?.resume(throwing: URLError(
            .unsupportedURL,
            url: request.url,
            detail: "URLProtocol redirect callbacks are not implemented"
        ))
    }

    func urlProtocol(
        _ protocol: URLProtocol,
        cachedResponseIsValid cachedResponse: CachedURLResponse
    ) {}

    func urlProtocol(
        _ protocol: URLProtocol,
        didReceive response: URLResponse,
        cacheStoragePolicy policy: URLCache.StoragePolicy
    ) {
        lock.withLock {
            guard !terminal else { return }
            self.response = response
            self.storagePolicy = policy
        }
    }

    func urlProtocol(_ protocol: URLProtocol, didLoad data: Data) {
        lock.withLock {
            guard !terminal else { return }
            self.data.append(data)
        }
    }

    func urlProtocolDidFinishLoading(_ protocol: URLProtocol) {
        let completion = lock.withLock { () -> (CheckedContinuation<Output, any Error>?, Output?) in
            guard !terminal else { return (nil, nil) }
            terminal = true
            let saved = continuation
            continuation = nil
            guard let response else { return (saved, nil) }
            return (saved, (data, response, storagePolicy))
        }
        if let output = completion.1 {
            completion.0?.resume(returning: output)
        } else {
            completion.0?.resume(throwing: URLError(.badServerResponse))
        }
    }

    func urlProtocol(_ protocol: URLProtocol, didFailWithError error: any Error) {
        let saved = lock.withLock { () -> CheckedContinuation<Output, any Error>? in
            guard !terminal else { return nil }
            terminal = true
            let result = continuation
            continuation = nil
            return result
        }
        saved?.resume(throwing: error)
    }
}

private struct _TransportResult: @unchecked Sendable {
    let data: Data
    let effectiveURL: URL
    let statusCode: Int
    let headerPairs: [(String, String)]
    let httpVersion: String?
}

private final class _URLTransportOperation: @unchecked Sendable {
    private let raw: UnsafeMutableRawPointer

    init?() {
        guard let raw = openui_url_transport_v1_create() else { return nil }
        self.raw = raw
    }

    deinit { openui_url_transport_v1_destroy(raw) }
    func cancel() { openui_url_transport_v1_cancel(raw) }

    func perform(
        url: URL,
        method: String,
        headers: Data,
        body: Data,
        requestTimeout: TimeInterval,
        resourceTimeout: TimeInterval
    ) throws -> _TransportResult {
        let urlBytes = Data(url.absoluteString.utf8)
        let methodBytes = Data(method.utf8)
        var response = openui_url_transport_response_v1()
        defer { openui_url_transport_v1_release_response(&response) }

        let result: Int32 = urlBytes.withUnsafeBytes { urlBuffer in
            methodBytes.withUnsafeBytes { methodBuffer in
                headers.withUnsafeBytes { headerBuffer in
                    body.withUnsafeBytes { bodyBuffer in
                        var request = openui_url_transport_request_v1()
                        request.abi_version = UInt32(OPENUI_URL_TRANSPORT_ABI_VERSION)
                        request.struct_size = UInt32(MemoryLayout<openui_url_transport_request_v1>.size)
                        request.url_bytes = urlBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
                        request.url_count = UInt64(urlBuffer.count)
                        request.method_bytes = methodBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
                        request.method_count = UInt64(methodBuffer.count)
                        request.header_bytes = headerBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
                        request.header_count = UInt64(headerBuffer.count)
                        request.body_bytes = bodyBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
                        request.body_count = UInt64(bodyBuffer.count)
                        request.connect_timeout_milliseconds = Self._milliseconds(requestTimeout)
                        request.total_timeout_milliseconds = Self._milliseconds(resourceTimeout)
                        request.maximum_response_header_bytes = UInt64(OPENUI_URL_TRANSPORT_MAX_RESPONSE_HEADER_BYTES)
                        request.maximum_response_body_bytes = UInt64(OPENUI_URL_TRANSPORT_MAX_RESPONSE_BODY_BYTES)
                        return openui_url_transport_v1_perform(raw, &request, &response)
                    }
                }
            }
        }
        guard result == 0, response.transport_error == 0 else {
            let detail = Self._string(response.error_message_bytes, response.error_message_count)
            throw URLError(Self._errorCode(response.transport_error), url: url, detail: detail)
        }
        guard response.body_count <= UInt64(Int.max),
              response.header_count <= UInt64(Int.max),
              response.effective_url_count <= UInt64(Int.max) else {
            throw URLError(.dataLengthExceedsMaximum, url: url)
        }
        let data = Self._data(response.body_bytes, response.body_count)
        let headerData = Self._data(response.header_bytes, response.header_count)
        let effectiveString = Self._string(
            response.effective_url_bytes,
            response.effective_url_count
        ) ?? url.absoluteString
        guard let effectiveURL = URL(string: effectiveString) else {
            throw URLError(.cannotParseResponse, url: url)
        }
        let parsed = try Self._headers(headerData)
        return _TransportResult(
            data: data,
            effectiveURL: effectiveURL,
            statusCode: Int(response.status_code),
            headerPairs: parsed.pairs,
            httpVersion: parsed.version
        )
    }

    private static func _milliseconds(_ interval: TimeInterval) -> UInt64 {
        guard interval > 0, interval.isFinite else { return 0 }
        let value = interval * 1_000
        return value >= Double(UInt64.max) ? UInt64.max : UInt64(max(1, value))
    }

    private static func _data(_ pointer: UnsafeMutablePointer<UInt8>?, _ count: UInt64) -> Data {
        guard count > 0, let pointer else { return Data() }
        return Data(bytes: pointer, count: Int(count))
    }

    private static func _string(
        _ pointer: UnsafeMutablePointer<UInt8>?, _ count: UInt64
    ) -> String? {
        guard count > 0, count <= UInt64(Int.max), let pointer else { return nil }
        return String(decoding: UnsafeBufferPointer(start: pointer, count: Int(count)), as: UTF8.self)
    }

    private static func _headers(_ data: Data) throws -> (pairs: [(String, String)], version: String?) {
        guard let decoded = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotParseResponse, detail: "response headers are not UTF-8")
        }
        let text = decoded.replacingOccurrences(of: "\r\n", with: "\n")
        let blocks = text.components(separatedBy: "\n\n").filter {
            $0.split(separator: "\n", maxSplits: 1).first?.hasPrefix("HTTP/") == true
        }
        guard let final = blocks.last else {
            throw URLError(.cannotParseResponse, detail: "missing HTTP status line")
        }
        let lines = final.split(separator: "\n", omittingEmptySubsequences: true)
        guard let status = lines.first.map(String.init) else {
            throw URLError(.cannotParseResponse, detail: "missing HTTP status line")
        }
        let statusFields = status.split(separator: " ", omittingEmptySubsequences: true)
        guard statusFields.count >= 2, statusFields[0].hasPrefix("HTTP/"),
              Int(statusFields[1]) != nil else {
            throw URLError(.cannotParseResponse, detail: "malformed HTTP status line")
        }
        let version = String(statusFields[0])
        var pairs: [(String, String)] = []
        for raw in lines.dropFirst() {
            let line = String(raw)
            if line.first?.isWhitespace == true {
                guard let last = pairs.indices.last else {
                    throw URLError(.cannotParseResponse, detail: "orphaned folded HTTP header")
                }
                pairs[last].1 += " " + line.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                guard let colon = line.firstIndex(of: ":") else {
                    throw URLError(.cannotParseResponse, detail: "malformed HTTP header")
                }
                let name = String(line[..<colon])
                guard !name.isEmpty, name.utf8.allSatisfy(_isHTTPTokenByte) else {
                    throw URLError(.cannotParseResponse, detail: "malformed HTTP header name")
                }
                let value = String(line[line.index(after: colon)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                pairs.append((name, value))
            }
        }
        return (pairs, version)
    }

    private static func _errorCode(_ transport: Int32) -> URLError.Code {
        switch transport {
        case 1: return .badURL
        case 2: return .unsupportedURL
        case 3: return .cannotFindHost
        case 4: return .cannotConnectToHost
        case 5: return .timedOut
        case 6: return .networkConnectionLost
        case 7: return .secureConnectionFailed
        case 8: return .cannotDecodeContentData
        case 9: return .networkConnectionLost
        case 10: return .resourceUnavailable
        case 11: return .cancelled
        case 12: return .badURL
        case 13: return .cannotLoadFromNetwork
        case 15: return .dataLengthExceedsMaximum
        default: return .unknown
        }
    }
}

open class URLSessionTask: NSObject, @unchecked Sendable {
    public enum State: Int, Sendable {
        case running = 0
        case suspended = 1
        case canceling = 2
        case completed = 3
    }

    public static let defaultPriority: Float = 0.5
    public static let lowPriority: Float = 0.25
    public static let highPriority: Float = 0.75

    open private(set) var taskIdentifier: Int
    open private(set) var originalRequest: URLRequest?
    open private(set) var currentRequest: URLRequest?
    open private(set) var response: URLResponse?
    open private(set) var error: (any Error)?
    open private(set) var countOfBytesReceived: Int64 = 0
    open private(set) var countOfBytesSent: Int64 = 0
    open private(set) var countOfBytesExpectedToReceive: Int64 = 0
    open private(set) var countOfBytesExpectedToSend: Int64 = 0
    open var taskDescription: String?
    open var priority: Float = URLSessionTask.defaultPriority
    private let lock = NSLock()
    private var storedState: State = .suspended
    fileprivate weak var session: URLSession?
    fileprivate var completion: (@Sendable (Data?, URLResponse?, (any Error)?) -> Void)?
    fileprivate var downloadCompletion: (@Sendable (URL?, URLResponse?, (any Error)?) -> Void)?
    private var work: Task<Void, Never>?

    // MEASURED 2026-09-06 Apple URLSessionTask on macOS 26: new tasks are
    // State.suspended (rawValue 1), priority 0.5, byte counts 0.
    fileprivate init(session: URLSession, request: URLRequest, identifier: Int) {
        self.session = session
        self.originalRequest = request
        self.currentRequest = request
        self.taskIdentifier = identifier
        super.init()
    }

    open var state: State { lock.withLock { storedState } }

    open func resume() {
        let shouldStart = lock.withLock { () -> Bool in
            guard storedState == .suspended else { return false }
            storedState = .running
            return true
        }
        guard shouldStart else { return }
        work = Task { [weak self] in
            guard let self else { return }
            await self.session?._performTask(self)
        }
    }

    open func suspend() {
        lock.withLock {
            if storedState == .running { storedState = .suspended }
        }
        work?.cancel()
    }

    open func cancel() {
        lock.withLock { storedState = .canceling }
        work?.cancel()
        let cancelled = URLError(.cancelled, url: originalRequest?.url)
        finish(data: nil, response: nil, file: nil, error: cancelled)
    }

    fileprivate func finish(
        data: Data?, response: URLResponse?, file: URL?, error: (any Error)?
    ) {
        // `var`, not `let`: the x86 verify box's toolchain refuses initialising a
        // `let` from inside the `withLock` closure ("cannot assign to value:
        // 'handler' is a 'let' constant", verify82) although Swift 6.2.4 on the
        // Mac and in the Docker leg accepted it.
        var handler: (@Sendable (Data?, URLResponse?, (any Error)?) -> Void)? = nil
        var downloadHandler: (@Sendable (URL?, URLResponse?, (any Error)?) -> Void)? = nil
        lock.withLock {
            storedState = .completed
            self.response = response
            self.error = error
            if let data { countOfBytesReceived = Int64(data.count) }
            if let response = response as? HTTPURLResponse {
                countOfBytesExpectedToReceive = response.expectedContentLength
            }
            handler = completion
            downloadHandler = downloadCompletion
            completion = nil
            downloadCompletion = nil
        }
        session?._onDelegateQueue {
            handler?(data, response, error)
            downloadHandler?(file, response, error)
            if let session = self.session {
                if let dataTask = self as? URLSessionDataTask,
                   let dataDelegate = session.delegate as? URLSessionDataDelegate {
                    if let response {
                        dataDelegate.urlSession(
                            session, dataTask: dataTask, didReceive: response
                        ) { _ in }
                    }
                    if let data, error == nil {
                        dataDelegate.urlSession(session, dataTask: dataTask, didReceive: data)
                    }
                }
                if let downloadTask = self as? URLSessionDownloadTask,
                   let downloadDelegate = session.delegate as? URLSessionDownloadDelegate,
                   let file, error == nil {
                    downloadDelegate.urlSession(
                        session, downloadTask: downloadTask, didFinishDownloadingTo: file
                    )
                }
                if let taskDelegate = session.delegate as? URLSessionTaskDelegate {
                    taskDelegate.urlSession(session, task: self, didCompleteWithError: error)
                }
            }
        }
    }
}

open class URLSessionDataTask: URLSessionTask, @unchecked Sendable {}
open class URLSessionUploadTask: URLSessionDataTask, @unchecked Sendable {}
open class URLSessionDownloadTask: URLSessionTask, @unchecked Sendable {}
open class URLSessionStreamTask: URLSessionTask, @unchecked Sendable {}

open class URLSession: NSObject, @unchecked Sendable {
    public typealias ResponseDisposition = URLSessionResponseDisposition
    public typealias AuthChallengeDisposition = URLSessionAuthChallengeDisposition

    public static let shared = URLSession(configuration: URLSessionConfiguration.default)

    open private(set) var configuration: URLSessionConfiguration
    open private(set) var delegate: (any URLSessionDelegate)?
    open private(set) var delegateQueue: OperationQueue
    private let taskLock = NSLock()
    private var nextTaskIdentifier = 1
    private var invalidated = false

    public init(
        configuration: URLSessionConfiguration,
        delegate: (any URLSessionDelegate)? = nil,
        delegateQueue queue: OperationQueue? = nil
    ) {
        self.configuration = configuration.copied()
        self.delegate = delegate
        self.delegateQueue = queue ?? OperationQueue()
        super.init()
    }

    public func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> (Data, URLResponse) {
        if taskLock.withLock({ invalidated }) {
            throw URLError(.cancelled, url: request.url)
        }
        if configuration.isBackground {
            throw URLError(
                .cannotLoadFromNetwork,
                url: request.url,
                detail: "background URLSession is not available"
            )
        }
        var request = try _prepared(request)
        let originalRequest = request
        let policy = request.cachePolicy == .useProtocolCachePolicy
            ? configuration.requestCachePolicy : request.cachePolicy
        let cached = configuration.urlCache?.cachedResponse(for: request)
        if policy == .useProtocolCachePolicy || policy == .returnCacheDataElseLoad
            || policy == .returnCacheDataDontLoad,
           let cached { return (cached.data, cached.response) }
        if policy == .returnCacheDataDontLoad {
            throw URLError(.resourceUnavailable, url: request.url)
        }

        if let protocolType = _protocolType(for: request) {
            let loader = _URLProtocolLoader()
            let output = try await loader.load(protocolType, request: request, cachedResponse: cached)
            if output.2 != .notAllowed, _isCacheable(request, output.1) {
                configuration.urlCache?.storeCachedResponse(
                    CachedURLResponse(response: output.1, data: output.0, storagePolicy: output.2),
                    for: originalRequest
                )
            }
            return (output.0, output.1)
        }

        let redirectDelegate = delegate ?? (self.delegate as? URLSessionTaskDelegate)
        var redirectCount = 0
        while true {
            request = _requestByAddingCookies(request)
            let result = try await _performHost(request)
            let fields = _combinedHeaderFields(result.headerPairs)
            guard let response = HTTPURLResponse(
                url: result.effectiveURL,
                statusCode: result.statusCode,
                httpVersion: result.httpVersion,
                headerFields: fields
            ) else { throw URLError(.cannotParseResponse, url: request.url) }

            _storeResponseCookies(result.headerPairs, for: result.effectiveURL)
            if let redirected = _followRedirect(
                from: request,
                response: response,
                headerPairs: result.headerPairs,
                redirectDelegate: redirectDelegate
            ) {
                redirectCount += 1
                guard redirectCount <= 20 else {
                    throw URLError(.httpTooManyRedirects, url: request.url)
                }
                request = redirected
                continue
            }

            if _isCacheable(originalRequest, response),
               !_headerContains("Cache-Control", token: "no-store", in: result.headerPairs) {
                configuration.urlCache?.storeCachedResponse(
                    CachedURLResponse(response: response, data: result.data),
                    for: originalRequest
                )
            }
            return (result.data, response)
        }
    }

    public func data(
        from url: URL,
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> (Data, URLResponse) {
        try await data(for: URLRequest(url: url), delegate: delegate)
    }

    public func upload(
        for request: URLRequest,
        from bodyData: Data,
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> (Data, URLResponse) {
        var request = request
        request.httpBody = bodyData
        return try await data(for: request, delegate: delegate)
    }

    public func upload(
        for request: URLRequest,
        fromFile fileURL: URL,
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> (Data, URLResponse) {
        let body = try Data(contentsOf: fileURL)
        return try await upload(for: request, from: body, delegate: delegate)
    }

    public func download(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> (URL, URLResponse) {
        let (data, response) = try await self.data(for: request, delegate: delegate)
        return (try _writeDownload(data), response)
    }

    public func download(
        from url: URL,
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> (URL, URLResponse) {
        try await download(for: URLRequest(url: url), delegate: delegate)
    }

    open func dataTask(with request: URLRequest) -> URLSessionDataTask {
        _makeDataTask(request, completion: nil)
    }

    open func dataTask(with url: URL) -> URLSessionDataTask {
        dataTask(with: URLRequest(url: url))
    }

    open func dataTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTask {
        _makeDataTask(request, completion: completionHandler)
    }

    open func dataTask(
        with url: URL,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDataTask {
        dataTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }

    open func uploadTask(with request: URLRequest, from bodyData: Data) -> URLSessionUploadTask {
        var request = request
        request.httpBody = bodyData
        return _makeUploadTask(request, completion: nil)
    }

    open func uploadTask(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionUploadTask {
        var request = request
        request.httpBody = bodyData
        return _makeUploadTask(request, completion: completionHandler)
    }

    open func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask {
        var request = request
        request.httpBody = try? Data(contentsOf: fileURL)
        return _makeUploadTask(request, completion: nil)
    }

    open func downloadTask(with request: URLRequest) -> URLSessionDownloadTask {
        _makeDownloadTask(request, completion: nil)
    }

    open func downloadTask(with url: URL) -> URLSessionDownloadTask {
        downloadTask(with: URLRequest(url: url))
    }

    open func downloadTask(
        with request: URLRequest,
        completionHandler: @escaping @Sendable (URL?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDownloadTask {
        _makeDownloadTask(request, completion: completionHandler)
    }

    open func downloadTask(
        with url: URL,
        completionHandler: @escaping @Sendable (URL?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionDownloadTask {
        downloadTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }

    open func streamTask(withHostName hostname: String, port: Int) -> URLSessionStreamTask {
        let url = URL(string: "http://\(hostname):\(port)/") ?? URL(string: "http://localhost/")!
        let task = URLSessionStreamTask(session: self, request: URLRequest(url: url), identifier: _nextID())
        task.completion = { _, _, error in
            _ = error
        }
        return task
    }

    open func finishTasksAndInvalidate() {
        taskLock.withLock { invalidated = true }
    }

    open func invalidateAndCancel() {
        taskLock.withLock { invalidated = true }
        _onDelegateQueue {
            self.delegate?.urlSession(self, didBecomeInvalidWithError: nil)
        }
    }

    fileprivate func _performTask(_ task: URLSessionTask?) async {
        guard let task, let request = task.originalRequest else { return }
        if task is URLSessionStreamTask {
            let error = URLError(
                .unsupportedURL,
                url: request.url,
                detail: "URLSessionStreamTask is not implemented"
            )
            task.finish(data: nil, response: nil, file: nil, error: error)
            return
        }
        do {
            let (data, response) = try await data(for: request)
            var file: URL?
            if task is URLSessionDownloadTask {
                file = try _writeDownload(data)
            }
            task.finish(data: data, response: response, file: file, error: nil)
        } catch {
            task.finish(data: nil, response: nil, file: nil, error: error)
        }
    }

    fileprivate func _onDelegateQueue(_ body: @escaping () -> Void) {
        // Guest OperationQueue is an inline stub (OpenUIKit). Deliver on this
        // thread so completion-handler tests stay synchronous.
        body()
    }

    private func _nextID() -> Int {
        taskLock.withLock {
            let value = nextTaskIdentifier
            nextTaskIdentifier += 1
            return value
        }
    }

    private func _makeDataTask(
        _ request: URLRequest,
        completion: (@Sendable (Data?, URLResponse?, (any Error)?) -> Void)?
    ) -> URLSessionDataTask {
        let task = URLSessionDataTask(session: self, request: request, identifier: _nextID())
        task.completion = completion
        return task
    }

    private func _makeUploadTask(
        _ request: URLRequest,
        completion: (@Sendable (Data?, URLResponse?, (any Error)?) -> Void)?
    ) -> URLSessionUploadTask {
        let task = URLSessionUploadTask(session: self, request: request, identifier: _nextID())
        task.completion = completion
        return task
    }

    private func _makeDownloadTask(
        _ request: URLRequest,
        completion: (@Sendable (URL?, URLResponse?, (any Error)?) -> Void)?
    ) -> URLSessionDownloadTask {
        let task = URLSessionDownloadTask(session: self, request: request, identifier: _nextID())
        task.downloadCompletion = completion
        return task
    }

    private func _writeDownload(_ data: Data) throws -> URL {
        let url = URL(fileURLWithPath: "/tmp/\(UUID().uuidString)", isDirectory: false)
        try data.write(to: url)
        return url
    }

    private func _prepared(_ source: URLRequest) throws -> URLRequest {
        guard source.url != nil else { throw URLError(.badURL) }
        var request = source
        for (rawKey, rawValue) in configuration.httpAdditionalHeaders ?? [:] {
            let key = String(describing: rawKey)
            if request.value(forHTTPHeaderField: key) == nil {
                request.setValue(String(describing: rawValue), forHTTPHeaderField: key)
            }
        }
        return request
    }

    private func _protocolType(for request: URLRequest) -> URLProtocol.Type? {
        var candidates: [URLProtocol.Type] = []
        for candidate in configuration.protocolClasses ?? [] {
            if let type = candidate as? URLProtocol.Type { candidates.append(type) }
        }
        candidates.append(contentsOf: URLProtocol._registered())
        for type in candidates {
            if type.canInit(with: request) { return type }
        }
        return nil
    }

    private func _performHost(_ request: URLRequest) async throws -> _TransportResult {
        guard let url = request.url else { throw URLError(.badURL) }
        let urlBytes = Array(url.absoluteString.utf8)
        guard !urlBytes.isEmpty,
              urlBytes.count <= Int(OPENUI_URL_TRANSPORT_MAX_URL_BYTES),
              !urlBytes.contains(0), !urlBytes.contains(10), !urlBytes.contains(13),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              url.host?.isEmpty == false else {
            throw URLError(.unsupportedURL, url: url)
        }
        guard let operation = _URLTransportOperation() else {
            throw URLError(.cannotLoadFromNetwork, url: url)
        }
        let method = request.httpMethod ?? "GET"
        let methodBytes = Array(method.utf8)
        guard !methodBytes.isEmpty,
              methodBytes.count <= Int(OPENUI_URL_TRANSPORT_MAX_METHOD_BYTES),
              methodBytes.allSatisfy(_isHTTPTokenByte) else {
            throw URLError(.badURL, url: url, detail: "invalid HTTP method")
        }
        let headers = try _headerBlock(request.allHTTPHeaderFields ?? [:], url: url)
        let body = try _body(request)
        let requestTimeout = request.timeoutIntervalWasSet
            ? request.timeoutInterval : configuration.timeoutIntervalForRequest
        let resourceTimeout = configuration.timeoutIntervalForResource
        let task = Task.detached {
            if Task.isCancelled { throw URLError(.cancelled, url: url) }
            return try operation.perform(
                url: url,
                method: method,
                headers: headers,
                body: body,
                requestTimeout: requestTimeout,
                resourceTimeout: resourceTimeout
            )
        }
        return try await withTaskCancellationHandler(operation: {
            try await task.value
        }, onCancel: {
            operation.cancel()
            task.cancel()
        })
    }

    private func _body(_ request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            guard body.count <= Int(OPENUI_URL_TRANSPORT_MAX_REQUEST_BODY_BYTES) else {
                throw URLError(.dataLengthExceedsMaximum, url: request.url)
            }
            return body
        }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var result = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16 * 1024)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: 16 * 1024)
            if count < 0 { throw stream.streamError ?? URLError(.cannotDecodeContentData) }
            if count == 0 { break }
            guard result.count <= Int(OPENUI_URL_TRANSPORT_MAX_REQUEST_BODY_BYTES) - count else {
                throw URLError(.dataLengthExceedsMaximum, url: request.url)
            }
            result.append(buffer, count: count)
        }
        return result
    }

    private func _headerBlock(_ fields: [String: String], url: URL) throws -> Data {
        var result = Data()
        for key in fields.keys.sorted(by: { $0.lowercased() < $1.lowercased() }) {
            guard let value = fields[key], !key.isEmpty,
                  key.utf8.allSatisfy(_isHTTPTokenByte),
                  value.utf8.allSatisfy({ $0 == 9 || ($0 >= 32 && $0 != 127) }) else {
                throw URLError(.badURL, url: url, detail: "malformed HTTP header")
            }
            let line = Data("\(key): \(value)\r\n".utf8)
            guard result.count <= Int(OPENUI_URL_TRANSPORT_MAX_REQUEST_HEADER_BYTES) - line.count else {
                throw URLError(.dataLengthExceedsMaximum, url: url)
            }
            result.append(line)
        }
        return result
    }

    private func _requestByAddingCookies(_ source: URLRequest) -> URLRequest {
        guard configuration.httpShouldSetCookies, source.httpShouldHandleCookies,
              source.value(forHTTPHeaderField: "Cookie") == nil,
              let url = source.url,
              let cookies = configuration.httpCookieStorage?.cookies(for: url),
              !cookies.isEmpty else { return source }
        var request = source
        request.setValue(
            HTTPCookie.requestHeaderFields(with: cookies)["Cookie"],
            forHTTPHeaderField: "Cookie"
        )
        return request
    }

    private func _storeResponseCookies(_ pairs: [(String, String)], for url: URL) {
        guard configuration.httpShouldSetCookies, let storage = configuration.httpCookieStorage else { return }
        let cookies = pairs.compactMap { name, value in
            name.caseInsensitiveCompare("Set-Cookie") == .orderedSame
                ? HTTPCookie._responseCookie(value, for: url) : nil
        }
        storage.setCookies(cookies, for: url, mainDocumentURL: url)
    }

    private func _followRedirect(
        from source: URLRequest,
        response: HTTPURLResponse,
        headerPairs: [(String, String)],
        redirectDelegate: (any URLSessionTaskDelegate)?
    ) -> URLRequest? {
        guard let next = _redirectRequest(
            from: source, response: response, headerPairs: headerPairs
        ) else { return nil }
        guard let redirectDelegate else { return next }
        let observed = _makeDataTask(source, completion: nil)
        var chosen: URLRequest? = next
        redirectDelegate.urlSession(
            self,
            task: observed,
            willPerformHTTPRedirection: response,
            newRequest: next,
            completionHandler: { chosen = $0 }
        )
        return chosen
    }

    private func _redirectRequest(
        from source: URLRequest,
        response: HTTPURLResponse,
        headerPairs: [(String, String)]
    ) -> URLRequest? {
        guard [301, 302, 303, 307, 308].contains(response.statusCode),
              let currentURL = source.url,
              let location = _header("Location", in: headerPairs),
              let nextURL = URL(string: location, relativeTo: currentURL)?.absoluteURL else {
            return nil
        }
        var request = source
        let method = (source.httpMethod ?? "GET").uppercased()
        if response.statusCode == 303 && method != "HEAD"
            || (response.statusCode == 301 || response.statusCode == 302) && method == "POST" {
            request.httpMethod = "GET"
            request.httpBody = nil
            request.httpBodyStream = nil
            request.setValue(nil, forHTTPHeaderField: "Content-Type")
            request.setValue(nil, forHTTPHeaderField: "Content-Length")
        }
        if currentURL.scheme?.lowercased() != nextURL.scheme?.lowercased()
            || currentURL.host?.lowercased() != nextURL.host?.lowercased()
            || currentURL.port != nextURL.port {
            request.setValue(nil, forHTTPHeaderField: "Authorization")
        }
        request.setValue(nil, forHTTPHeaderField: "Cookie")
        request.url = nextURL
        return request
    }

    private func _combinedHeaderFields(_ pairs: [(String, String)]) -> [String: String] {
        var fields: [String: String] = [:]
        for (name, value) in pairs {
            if let key = fields.keys.first(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
                fields[key] = fields[key].map { $0 + ", " + value } ?? value
            } else {
                fields[name] = value
            }
        }
        return fields
    }

    private func _header(_ name: String, in pairs: [(String, String)]) -> String? {
        pairs.last { $0.0.caseInsensitiveCompare(name) == .orderedSame }?.1
    }

    private func _headerContains(
        _ name: String, token: String, in pairs: [(String, String)]
    ) -> Bool {
        pairs.contains {
            $0.0.caseInsensitiveCompare(name) == .orderedSame
                && $0.1.lowercased().split(separator: ",").contains {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines) == token.lowercased()
                }
        }
    }

    private func _isCacheable(_ request: URLRequest, _ response: URLResponse) -> Bool {
        guard (request.httpMethod ?? "GET").uppercased() == "GET" else { return false }
        if let response = response as? HTTPURLResponse {
            return (200 ... 299).contains(response.statusCode)
        }
        return true
    }
}
#endif
