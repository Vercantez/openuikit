// The Foundation URL-loading value types required at the framework boundary.
//
// This is deliberately not URLSession.  URLRequest is a value describing a
// request, and URLResponse is immutable response metadata.  Neither type sends
// bytes, resolves a host, owns a cache, or claims that a transport exists.
// Keeping that line explicit lets first-party modules such as WebKit exchange
// honest request/response state before a Linux networking stack is connected.

import FoundationEssentials

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("Foundation.URLResponse requires the ObjectiveC NSObject substrate")
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
    public var timeoutInterval: TimeInterval
    public var mainDocumentURL: URL?
    public var httpMethod: String?
    public var httpBody: Data?
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
        self.timeoutInterval = timeoutInterval
        self.mainDocumentURL = nil
        self.httpMethod = "GET"
        self.httpBody = nil
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
        let folded = field.lowercased()
        if let key = headerFields.keys.first(where: { $0.lowercased() == folded }) {
            headerFields.removeValue(forKey: key)
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
