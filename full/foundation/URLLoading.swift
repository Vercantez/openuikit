// The Foundation URL-loading value types required at the framework boundary.
//
// URLRequest and URLResponse are the value boundary used by the concrete
// URLSession transport in URLSession.swift. They stay separate so WebKit and
// other first-party frameworks can exchange request metadata without owning
// the transport state machine.

#if URLCOMPONENTS_PORT
import Foundation
#else
import FoundationEssentials

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("Foundation.URLResponse requires the ObjectiveC NSObject substrate")
#endif
#endif

public struct URLRequest: Hashable, @unchecked Sendable {
    public enum CachePolicy: UInt, Sendable {
        case useProtocolCachePolicy = 0
        case reloadIgnoringLocalCacheData = 1
        case reloadIgnoringLocalAndRemoteCacheData = 4
        case returnCacheDataElseLoad = 2
        case returnCacheDataDontLoad = 3
        case reloadRevalidatingCacheData = 5
    }

    public var url: URL?
    public var cachePolicy: CachePolicy
    private var storedTimeoutInterval: TimeInterval
    internal private(set) var timeoutIntervalWasSet: Bool
    public var timeoutInterval: TimeInterval {
        get { storedTimeoutInterval }
        set {
            storedTimeoutInterval = newValue
            timeoutIntervalWasSet = true
        }
    }
    public var mainDocumentURL: URL?
    public var httpMethod: String?
    public var httpBody: Data?
    public var httpBodyStream: InputStream?
    public var httpShouldHandleCookies: Bool
    public var httpShouldUsePipelining: Bool
    public var allowsCellularAccess: Bool

    private var headerFields: [String: String]

    public init(
        url: URL,
        cachePolicy: CachePolicy = .useProtocolCachePolicy,
        timeoutInterval: TimeInterval = 60
    ) {
        self.url = url
        self.cachePolicy = cachePolicy
        self.storedTimeoutInterval = timeoutInterval
        self.timeoutIntervalWasSet = false
        self.mainDocumentURL = nil
        self.httpMethod = "GET"
        self.httpBody = nil
        self.httpBodyStream = nil
        self.httpShouldHandleCookies = true
        self.httpShouldUsePipelining = false
        self.allowsCellularAccess = true
        self.headerFields = [:]
    }

    public var allHTTPHeaderFields: [String: String]? {
        get { headerFields.isEmpty ? nil : headerFields }
        set { headerFields = newValue ?? [:] }
    }

    public func value(forHTTPHeaderField field: String) -> String? {
        let folded = field.lowercased()
        return headerFields.first { $0.key.lowercased() == folded }?.value
    }

    public mutating func setValue(_ value: String?, forHTTPHeaderField field: String) {
        // MEASURED 2026-09-06 Apple URLRequest on macOS 26:
        // setValue("one", "Content-Type") then setValue("two", "content-type")
        // keeps the original key casing (`Content-Type=two`). Replacing the
        // key with the new spelling would mismatch.
        let folded = field.lowercased()
        if let key = headerFields.keys.first(where: { $0.lowercased() == folded }) {
            if let value {
                headerFields[key] = value
            } else {
                headerFields.removeValue(forKey: key)
            }
            return
        }
        if let value {
            headerFields[field] = value
        }
    }

    public mutating func addValue(_ value: String, forHTTPHeaderField field: String) {
        if let existing = self.value(forHTTPHeaderField: field) {
            setValue("\(existing),\(value)", forHTTPHeaderField: field)
        } else {
            setValue(value, forHTTPHeaderField: field)
        }
    }

    public static func == (lhs: URLRequest, rhs: URLRequest) -> Bool {
        lhs.url == rhs.url
            && lhs.cachePolicy == rhs.cachePolicy
            && lhs.timeoutInterval == rhs.timeoutInterval
            && lhs.mainDocumentURL == rhs.mainDocumentURL
            && lhs.httpMethod == rhs.httpMethod
            && lhs.httpBody == rhs.httpBody
            && lhs.httpBodyStream === rhs.httpBodyStream
            && lhs.httpShouldHandleCookies == rhs.httpShouldHandleCookies
            && lhs.httpShouldUsePipelining == rhs.httpShouldUsePipelining
            && lhs.allowsCellularAccess == rhs.allowsCellularAccess
            && lhs._normalizedHeaders == rhs._normalizedHeaders
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(cachePolicy)
        hasher.combine(timeoutInterval)
        hasher.combine(mainDocumentURL)
        hasher.combine(httpMethod)
        hasher.combine(httpBody)
        if let httpBodyStream {
            hasher.combine(ObjectIdentifier(httpBodyStream))
        }
        hasher.combine(httpShouldHandleCookies)
        hasher.combine(httpShouldUsePipelining)
        hasher.combine(allowsCellularAccess)
        let normalized = _normalizedHeaders
        for key in normalized.keys.sorted() {
            hasher.combine(key)
            hasher.combine(normalized[key])
        }
    }

    private var _normalizedHeaders: [String: String] {
        Dictionary(
            uniqueKeysWithValues: headerFields.map {
                ($0.key.lowercased(), $0.value)
            }
        )
    }
}

open class URLResponse: NSObject, @unchecked Sendable {
    open private(set) var url: URL?
    open private(set) var mimeType: String?
    open private(set) var expectedContentLength: Int64
    open private(set) var textEncodingName: String?

    public override init() {
        self.url = nil
        self.mimeType = nil
        self.expectedContentLength = -1
        self.textEncodingName = nil
        super.init()
    }

    public init(
        url: URL,
        mimeType: String?,
        expectedContentLength length: Int,
        textEncodingName name: String?
    ) {
        self.url = url
        self.mimeType = mimeType
        self.expectedContentLength = Int64(length)
        self.textEncodingName = name
        super.init()
    }

    open var suggestedFilename: String? {
        guard let name = url?.lastPathComponent, !name.isEmpty else {
            return "Unknown"
        }
        return name
    }
}

public struct URLQueryItem: Hashable, Equatable, Sendable {
    public var name: String
    public var value: String?

    public init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
}

public struct URLComponents: Hashable, Equatable, Sendable {
    public var scheme: String?
    public var port: Int?
    fileprivate var encodedUser: String?
    fileprivate var encodedPassword: String?
    fileprivate var encodedHost: String?
    fileprivate var encodedPath: String = ""
    fileprivate var encodedQuery: String?
    fileprivate var encodedFragment: String?

    public init() {}

    public init?(url: URL, resolvingAgainstBaseURL: Bool) {
        let source = resolvingAgainstBaseURL ? url.absoluteString : url.relativeString
        self.init(string: source)
    }

    public init?(string: String) {
        self.init(string: string, encodingInvalidCharacters: true)
    }

    public init?(string: String, encodingInvalidCharacters: Bool) {
        guard let parsed = _URLComponentsParser.parse(
            string, encodingInvalidCharacters: encodingInvalidCharacters
        ) else { return nil }
        self = parsed
    }

    public var user: String? {
        get { encodedUser.map(_percentDecode) }
        set { encodedUser = newValue.map { _percentEncode($0, allowed: _URLEncodeSet.user) } }
    }
    public var password: String? {
        get { encodedPassword.map(_percentDecode) }
        set { encodedPassword = newValue.map { _percentEncode($0, allowed: _URLEncodeSet.user) } }
    }
    public var host: String? {
        get { encodedHost.map { _idnaDecode(_percentDecode($0)) } }
        set { encodedHost = newValue.map { _percentEncode($0, allowed: _URLEncodeSet.host) } }
    }
    public var path: String {
        get { _percentDecode(encodedPath) }
        set { encodedPath = _percentEncode(newValue, allowed: _URLEncodeSet.path) }
    }
    public var query: String? {
        get { encodedQuery.map(_percentDecode) }
        set { encodedQuery = newValue.map { _percentEncode($0, allowed: _URLEncodeSet.query) } }
    }
    public var fragment: String? {
        get { encodedFragment.map(_percentDecode) }
        set { encodedFragment = newValue.map { _percentEncode($0, allowed: _URLEncodeSet.fragment) } }
    }

    public var percentEncodedUser: String? {
        get { encodedUser }
        set { encodedUser = newValue.map { _percentEncode($0, allowed: _URLEncodeSet.user, keepEscapes: true) } }
    }
    public var percentEncodedPassword: String? {
        get { encodedPassword }
        set { encodedPassword = newValue.map { _percentEncode($0, allowed: _URLEncodeSet.user, keepEscapes: true) } }
    }
    public var percentEncodedHost: String? {
        get {
            guard let encodedHost else { return nil }
            return _percentEncode(
                _idnaDecode(_percentDecode(encodedHost)),
                allowed: _URLEncodeSet.host
            )
        }
        set {
            encodedHost = newValue.map {
                _percentEncode($0, allowed: _URLEncodeSet.host, keepEscapes: true)
            }
        }
    }
    public var percentEncodedPath: String {
        get { encodedPath }
        set { encodedPath = _percentEncode(newValue, allowed: _URLEncodeSet.path, keepEscapes: true) }
    }
    public var percentEncodedQuery: String? {
        get { encodedQuery }
        set { encodedQuery = newValue.map { _percentEncode($0, allowed: _URLEncodeSet.query, keepEscapes: true) } }
    }
    public var percentEncodedFragment: String? {
        get { encodedFragment }
        set { encodedFragment = newValue.map { _percentEncode($0, allowed: _URLEncodeSet.fragment, keepEscapes: true) } }
    }

    public var queryItems: [URLQueryItem]? {
        get { encodedQuery.map { _queryItems(fromEncoded: $0) } }
        set {
            encodedQuery = newValue.map { items in
                items.map { item in
                    let name = _percentEncode(item.name, allowed: _URLEncodeSet.queryItem)
                    guard let value = item.value else { return name }
                    return name + "=" + _percentEncode(value, allowed: _URLEncodeSet.queryItem)
                }.joined(separator: "&")
            }
        }
    }

    public var percentEncodedQueryItems: [URLQueryItem]? {
        get { encodedQuery.map { _queryItems(fromEncoded: $0, keepingEncoding: true) } }
        set {
            encodedQuery = newValue.map { items in
                items.map { item in
                    guard let value = item.value else { return item.name }
                    return item.name + "=" + value
                }.joined(separator: "&")
            }
        }
    }

    public var string: String? { _assemble() }

    public var url: URL? {
        guard let string else { return nil }
        return URL(string: string)
    }

    public func url(relativeTo base: URL?) -> URL? {
        guard let string else { return nil }
        return URL(string: string, relativeTo: base)
    }

    private var hasAuthority: Bool {
        encodedHost != nil || encodedUser != nil || encodedPassword != nil || port != nil
    }

    private func _assemble() -> String? {
        if hasAuthority, !encodedPath.isEmpty, !encodedPath.hasPrefix("/") { return nil }
        if let host, _containsSpace(host) { return nil }
        if let host, _containsColon(host), !host.hasPrefix("[") { return nil }

        var result = ""
        if let scheme {
            result += scheme
            result += ":"
        }
        if hasAuthority {
            result += "//"
            if let encodedUser {
                result += encodedUser
                if let encodedPassword {
                    result += ":"
                    result += encodedPassword
                }
                result += "@"
            } else if let encodedPassword {
                result += ":"
                result += encodedPassword
                result += "@"
            }
            result += _hostForURL()
            if let port {
                result += ":"
                result += String(port)
            }
        }
        result += encodedPath
        if let encodedQuery {
            result += "?"
            result += encodedQuery
        }
        if let encodedFragment {
            result += "#"
            result += encodedFragment
        }
        return result
    }

    private func _hostForURL() -> String {
        guard let encodedHost else { return "" }
        let unicode = _idnaDecode(_percentDecode(encodedHost))
        if unicode.hasPrefix("[") {
            return _percentEncode(unicode, allowed: _URLEncodeSet.host)
        }
        return _idnaEncode(unicode)
    }
}

public typealias NSURLComponents = URLComponents

private enum _URLEncodeSet {
    // MEASURED 2026-09-06 Apple CharacterSet.url*Allowed inventories (ASCII).
    // RFC 3986 unreserved + sub-delims, then the documented extras per component.
    static let user: Set<UInt8> = _unreserved.union(_subDelims)
    static let host: Set<UInt8> = user.union([0x3A, 0x5B, 0x5D])
    static let path: Set<UInt8> = user.union([0x3A, 0x40, 0x2F])
    static let query: Set<UInt8> = path.union([0x3F])
    static let fragment: Set<UInt8> = query
    // MEASURED 2026-09-06 Apple URLComponents.queryItems encoding: urlQueryAllowed
    // minus "&" (0x26) and "=" (0x3D). qi.encodeMap in the carried golden.
    static let queryItem: Set<UInt8> = query.subtracting([0x26, 0x3D])

    private static let _unreserved: Set<UInt8> = {
        var set: Set<UInt8> = [0x2D, 0x2E, 0x5F, 0x7E]
        for b in 0x30...0x39 { set.insert(UInt8(b)) }
        for b in 0x41...0x5A { set.insert(UInt8(b)) }
        for b in 0x61...0x7A { set.insert(UInt8(b)) }
        return set
    }()
    private static let _subDelims: Set<UInt8> = [
        0x21, 0x24, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x3B, 0x3D,
    ]
}

private enum _URLComponentsParser {
    static func parse(
        _ string: String, encodingInvalidCharacters: Bool
    ) -> URLComponents? {
        var rest = string[...]
        var encodedFragment: String?
        if let hash = rest.firstIndex(of: "#") {
            let raw = String(rest[rest.index(after: hash)...])
            rest = rest[..<hash]
            guard let encoded = encode(
                raw, allowed: _URLEncodeSet.fragment, encodingInvalid: encodingInvalidCharacters
            ) else { return nil }
            encodedFragment = encoded
        }

        var encodedQuery: String?
        if let question = rest.firstIndex(of: "?") {
            let raw = String(rest[rest.index(after: question)...])
            rest = rest[..<question]
            guard let encoded = encode(
                raw, allowed: _URLEncodeSet.query, encodingInvalid: encodingInvalidCharacters
            ) else { return nil }
            encodedQuery = encoded
        }

        var scheme: String?
        if let colon = rest.firstIndex(of: ":"), _isScheme(rest[..<colon]) {
            scheme = String(rest[..<colon])
            rest = rest[rest.index(after: colon)...]
        }

        var encodedUser: String?
        var encodedPassword: String?
        var encodedHost: String?
        var port: Int?
        if rest.hasPrefix("//") {
            rest = rest.dropFirst(2)
            let authEnd = rest.firstIndex(of: "/") ?? rest.endIndex
            let authority = rest[..<authEnd]
            rest = rest[authEnd...]
            if authority.firstIndex(of: " ") != nil { return nil }

            var hostport = authority
            if let at = authority.lastIndex(of: "@") {
                let userinfo = authority[..<at]
                hostport = authority[authority.index(after: at)...]
                if let colon = userinfo.firstIndex(of: ":") {
                    guard let user = encode(
                        String(userinfo[..<colon]),
                        allowed: _URLEncodeSet.user,
                        encodingInvalid: encodingInvalidCharacters
                    ) else { return nil }
                    guard let password = encode(
                        String(userinfo[userinfo.index(after: colon)...]),
                        allowed: _URLEncodeSet.user,
                        encodingInvalid: encodingInvalidCharacters
                    ) else { return nil }
                    encodedUser = user
                    encodedPassword = password
                } else {
                    guard let user = encode(
                        String(userinfo),
                        allowed: _URLEncodeSet.user,
                        encodingInvalid: encodingInvalidCharacters
                    ) else { return nil }
                    encodedUser = user
                }
            }

            if hostport.hasPrefix("[") {
                guard let close = hostport.firstIndex(of: "]") else { return nil }
                let hostRaw = String(hostport[...close])
                let after = hostport[hostport.index(after: close)...]
                guard let encoded = encode(
                    hostRaw, allowed: _URLEncodeSet.host, encodingInvalid: encodingInvalidCharacters
                ) else { return nil }
                encodedHost = encoded
                if after.hasPrefix(":") {
                    let portRaw = String(after.dropFirst())
                    guard let value = Int(portRaw) else { return nil }
                    port = value
                } else if !after.isEmpty {
                    return nil
                }
            } else if let colon = hostport.lastIndex(of: ":"),
                      hostport[hostport.index(after: colon)...].allSatisfy({ $0.isASCII && $0.isNumber }) {
                guard let encoded = encode(
                    String(hostport[..<colon]),
                    allowed: _URLEncodeSet.host,
                    encodingInvalid: encodingInvalidCharacters
                ) else { return nil }
                encodedHost = encoded
                port = Int(hostport[hostport.index(after: colon)...])
            } else {
                guard let encoded = encode(
                    String(hostport),
                    allowed: _URLEncodeSet.host,
                    encodingInvalid: encodingInvalidCharacters
                ) else { return nil }
                encodedHost = encoded
            }
        }

        let pathRaw = String(rest)
        guard let encodedPath = encode(
            pathRaw, allowed: _URLEncodeSet.path, encodingInvalid: encodingInvalidCharacters
        ) else { return nil }

        var result = URLComponents()
        result.scheme = scheme
        result.encodedUser = encodedUser
        result.encodedPassword = encodedPassword
        result.encodedHost = encodedHost
        result.port = port
        result.encodedPath = encodedPath
        result.encodedQuery = encodedQuery
        result.encodedFragment = encodedFragment
        return result
    }

    private static func encode(
        _ raw: String, allowed: Set<UInt8>, encodingInvalid: Bool
    ) -> String? {
        if !encodingInvalid, !_isEncodedOrAllowed(raw, allowed: allowed) {
            return nil
        }
        return _percentEncode(raw, allowed: allowed, keepEscapes: true)
    }

    private static func _isScheme(_ text: Substring) -> Bool {
        guard let first = text.first, first.isASCII, first.isLetter else { return false }
        for ch in text {
            guard ch.isASCII else { return false }
            if ch.isLetter || ch.isNumber || ch == "+" || ch == "-" || ch == "." { continue }
            return false
        }
        return true
    }
}

private func _percentEncode(
    _ string: String, allowed: Set<UInt8>, keepEscapes: Bool = false
) -> String {
    let bytes = Array(string.utf8)
    var output: [UInt8] = []
    output.reserveCapacity(bytes.count)
    let hex = Array("0123456789ABCDEF".utf8)
    var index = 0
    while index < bytes.count {
        if keepEscapes, bytes[index] == 0x25, index + 2 < bytes.count,
           _foundationURLHex(bytes[index + 1]) != nil,
           _foundationURLHex(bytes[index + 2]) != nil {
            output.append(bytes[index])
            output.append(bytes[index + 1])
            output.append(bytes[index + 2])
            index += 3
            continue
        }
        let byte = bytes[index]
        if allowed.contains(byte) {
            output.append(byte)
        } else {
            output.append(0x25)
            output.append(hex[Int(byte >> 4)])
            output.append(hex[Int(byte & 0x0F)])
        }
        index += 1
    }
    return String(decoding: output, as: UTF8.self)
}

private func _percentDecode(_ string: String) -> String {
    let bytes = Array(string.utf8)
    var output: [UInt8] = []
    output.reserveCapacity(bytes.count)
    var index = 0
    while index < bytes.count {
        if bytes[index] == 0x25, index + 2 < bytes.count,
           let high = _foundationURLHex(bytes[index + 1]),
           let low = _foundationURLHex(bytes[index + 2]) {
            output.append((high << 4) | low)
            index += 3
        } else {
            output.append(bytes[index])
            index += 1
        }
    }
    return String(decoding: output, as: UTF8.self)
}

private func _isEncodedOrAllowed(_ string: String, allowed: Set<UInt8>) -> Bool {
    let bytes = Array(string.utf8)
    var index = 0
    while index < bytes.count {
        if bytes[index] == 0x25 {
            guard index + 2 < bytes.count,
                  _foundationURLHex(bytes[index + 1]) != nil,
                  _foundationURLHex(bytes[index + 2]) != nil else {
                return false
            }
            index += 3
            continue
        }
        if !allowed.contains(bytes[index]) { return false }
        index += 1
    }
    return true
}

private func _foundationURLHex(_ byte: UInt8) -> UInt8? {
    switch byte {
    case 0x30...0x39: return byte - 0x30
    case 0x41...0x46: return byte - 0x41 + 10
    case 0x61...0x66: return byte - 0x61 + 10
    default: return nil
    }
}

private func _queryItems(fromEncoded query: String, keepingEncoding: Bool = false) -> [URLQueryItem] {
    if query.isEmpty { return [] }
    var items: [URLQueryItem] = []
    var remaining = query[...]
    while true {
        let piece: Substring
        if let amp = remaining.firstIndex(of: "&") {
            piece = remaining[..<amp]
            remaining = remaining[remaining.index(after: amp)...]
        } else {
            piece = remaining
            remaining = remaining[remaining.endIndex...]
        }
        if let equal = piece.firstIndex(of: "=") {
            let name = String(piece[..<equal])
            let value = String(piece[piece.index(after: equal)...])
            items.append(URLQueryItem(
                name: keepingEncoding ? name : _percentDecode(name),
                value: keepingEncoding ? value : _percentDecode(value)
            ))
        } else {
            let name = String(piece)
            items.append(URLQueryItem(
                name: keepingEncoding ? name : _percentDecode(name),
                value: nil
            ))
        }
        if remaining.isEmpty && query.last != "&" { break }
        if remaining.isEmpty { break }
    }
    return items
}

private func _containsSpace(_ string: String) -> Bool {
    string.firstIndex(of: " ") != nil
}

private func _containsColon(_ string: String) -> Bool {
    string.firstIndex(of: ":") != nil
}

// MEASURED 2026-09-06 Apple URLComponents host: unicode host + punycode in
// string/url (café.com → xn--caf-dma.com; xn--fsq.com parses as 例.com).
// RFC 3492 punycode, one label at a time; ASCII labels are unchanged.
private func _idnaEncode(_ host: String) -> String {
    if host.hasPrefix("[") { return host }
    var labels: [String] = []
    var remaining = host[...]
    while true {
        let label: Substring
        if let dot = remaining.firstIndex(of: ".") {
            label = remaining[..<dot]
            remaining = remaining[remaining.index(after: dot)...]
        } else {
            label = remaining
            remaining = remaining[remaining.endIndex...]
        }
        labels.append(_idnaEncodeLabel(String(label)))
        if remaining.isEmpty { break }
    }
    // Preserve a trailing dot if the source had one.
    if host.hasSuffix(".") { return labels.joined(separator: ".") + "." }
    return labels.joined(separator: ".")
}

private func _idnaDecode(_ host: String) -> String {
    if host.hasPrefix("[") { return host }
    var labels: [String] = []
    var remaining = host[...]
    while true {
        let label: Substring
        if let dot = remaining.firstIndex(of: ".") {
            label = remaining[..<dot]
            remaining = remaining[remaining.index(after: dot)...]
        } else {
            label = remaining
            remaining = remaining[remaining.endIndex...]
        }
        labels.append(_idnaDecodeLabel(String(label)))
        if remaining.isEmpty { break }
    }
    if host.hasSuffix(".") { return labels.joined(separator: ".") + "." }
    return labels.joined(separator: ".")
}

private func _idnaEncodeLabel(_ label: String) -> String {
    if label.utf8.allSatisfy({ $0 < 128 }) { return label }
    return "xn--" + _Punycode.encode(label)
}

private func _idnaDecodeLabel(_ label: String) -> String {
    let lower = label.lowercased()
    guard lower.hasPrefix("xn--") else { return label }
    let encoded = String(lower.dropFirst(4))
    return _Punycode.decode(encoded) ?? label
}

private enum _Punycode {
    private static let base = 36
    private static let tmin = 1
    private static let tmax = 26
    private static let skew = 38
    private static let damp = 700
    private static let initialBias = 72
    private static let initialN = 128

    static func encode(_ input: String) -> String {
        let scalars = Array(input.unicodeScalars.map { Int($0.value) })
        var output: [UInt8] = []
        for value in scalars where value < 128 {
            output.append(UInt8(value))
        }
        let basicCount = output.count
        if basicCount > 0 { output.append(0x2D) }
        var n = initialN
        var delta = 0
        var bias = initialBias
        var handled = basicCount
        while handled < scalars.count {
            var minimum = Int.max
            for value in scalars where value >= n && value < minimum { minimum = value }
            delta += (minimum - n) * (handled + 1)
            n = minimum
            for value in scalars {
                if value < n {
                    delta += 1
                } else if value == n {
                    var q = delta
                    var k = base
                    while true {
                        let t = threshold(k, bias: bias)
                        if q < t { break }
                        output.append(encodeDigit(t + ((q - t) % (base - t))))
                        q = (q - t) / (base - t)
                        k += base
                    }
                    output.append(encodeDigit(q))
                    bias = adapt(
                        delta: delta, firstTime: handled == basicCount, numpoints: handled + 1
                    )
                    delta = 0
                    handled += 1
                }
            }
            delta += 1
            n += 1
        }
        return String(decoding: output, as: UTF8.self)
    }

    static func decode(_ input: String) -> String? {
        let bytes = Array(input.utf8)
        var output: [Int] = []
        var inIndex = 0
        if let lastHyphen = bytes.lastIndex(of: 0x2D) {
            for byte in bytes[..<lastHyphen] {
                guard byte < 128 else { return nil }
                output.append(Int(byte))
            }
            inIndex = lastHyphen + 1
        }
        var n = initialN
        var i = 0
        var bias = initialBias
        while inIndex < bytes.count {
            let oldi = i
            var w = 1
            var k = base
            while true {
                guard inIndex < bytes.count, let digit = decodeDigit(bytes[inIndex]) else {
                    return nil
                }
                inIndex += 1
                i += digit * w
                let t = threshold(k, bias: bias)
                if digit < t { break }
                w *= base - t
                k += base
            }
            bias = adapt(delta: i - oldi, firstTime: oldi == 0, numpoints: output.count + 1)
            n += i / (output.count + 1)
            i = i % (output.count + 1)
            output.insert(n, at: i)
            i += 1
        }
        var result = ""
        for value in output {
            guard let scalar = UnicodeScalar(value) else { return nil }
            result.append(Character(scalar))
        }
        return result
    }

    private static func threshold(_ k: Int, bias: Int) -> Int {
        if k <= bias { return tmin }
        if k >= bias + tmax { return tmax }
        return k - bias
    }

    private static func adapt(delta: Int, firstTime: Bool, numpoints: Int) -> Int {
        var delta = firstTime ? delta / damp : delta / 2
        delta += delta / numpoints
        var k = 0
        while delta > ((base - tmin) * tmax) / 2 {
            delta /= base - tmin
            k += base
        }
        return k + ((base - tmin + 1) * delta) / (delta + skew)
    }

    private static func encodeDigit(_ digit: Int) -> UInt8 {
        UInt8(digit < 26 ? digit + 97 : digit + 22)
    }

    private static func decodeDigit(_ byte: UInt8) -> Int? {
        if byte >= 48 && byte <= 57 { return Int(byte - 22) }
        if byte >= 97 && byte <= 122 { return Int(byte - 97) }
        if byte >= 65 && byte <= 90 { return Int(byte - 65) }
        return nil
    }
}

