import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if SOCIAL_STANDALONE_TEST_FIXTURES
/// standalone-unit-fixture-only. Not production Social ABI.
/// The explicit fixture flag takes precedence over `canImport(Accounts)` so
/// Apple-host isolated tests do not import the deprecated system Accounts
/// module. This type is not `Accounts.ACAccount` identity evidence.
open class ACAccount: NSObject {
    public override init() {
        super.init()
    }
}
#elseif canImport(Accounts)
import Accounts
#else
#error(
    "Social requires the Accounts module for SLRequest.account. Accounts is not staged in the shared platform. This is an integration blocker. Isolated tests must compile with -D SOCIAL_STANDALONE_TEST_FIXTURES; that configuration is standalone-unit-fixture-only. Social.ACAccount is forbidden as production ABI."
)
#endif

/// Completion callback for `SLRequest.perform(handler:)`.
///
/// On this host the handler is invoked synchronously with `nil` data, `nil`
/// response, and a host-only error. The request is never sent.
public typealias SLRequestHandler = (Data?, HTTPURLResponse?, (any Error)?) -> Void

/// Signed-account social HTTP request.
///
/// Construction, parameter encoding, multipart bookkeeping, and unsigned
/// `preparedURLRequest()` assembly (when `account` is nil) are local. If
/// `account` is non-nil and no OAuth signer exists, `preparedURLRequest()`
/// returns nil. `perform(handler:)` never networks.
open class SLRequest: NSObject {
    @_spi(OpenUIKitHost)
    public struct MultipartPart: Equatable {
        public var data: Data
        public var name: String
        public var type: String?
        public var filename: String?
    }

    @_spi(OpenUIKitHost)
    public private(set) var hostServiceType: String?

    open private(set) var requestMethod: SLRequestMethod
    open private(set) var url: URL!
    open private(set) var parameters: [AnyHashable: Any]!
    open var account: ACAccount!

    @_spi(OpenUIKitHost)
    public private(set) var hostMultipartParts: [MultipartPart] = []

    /// Ordered boundary candidates for isolated tests. Each candidate is
    /// collision-checked against parameter names/values and part metadata/data.
    /// Production uses `nil` and generates UUID candidates; every returned
    /// boundary has been collision-tested. Never returns an unchecked fallback.
    @_spi(OpenUIKitHost)
    nonisolated(unsafe) public static var hostMultipartBoundaryCandidates: [String]? = nil

    @_spi(OpenUIKitHost)
    public static func hostResetMultipartBoundaryCandidates() {
        hostMultipartBoundaryCandidates = nil
    }

    public init!(
        forServiceType serviceType: String!,
        requestMethod: SLRequestMethod,
        url: URL!,
        parameters: [AnyHashable: Any]!
    ) {
        guard let url else { return nil }
        hostServiceType = serviceType
        self.requestMethod = requestMethod
        self.url = url
        self.parameters = parameters
        super.init()
    }

    public convenience init!(
        forServiceType serviceType: String!,
        requestMethod: SLRequestMethod,
        URL url: URL!,
        parameters: [AnyHashable: Any]!
    ) {
        self.init(
            forServiceType: serviceType,
            requestMethod: requestMethod,
            url: url,
            parameters: parameters
        )
    }

    open func addMultipartData(
        _ data: Data!,
        withName name: String!,
        type: String!,
        filename: String!
    ) {
        guard let data, let name, !name.isEmpty else { return }
        guard Self.isSafeMultipartToken(name) else { return }
        if let type, !Self.isSafeMultipartToken(type) { return }
        if let filename, !Self.isSafeMultipartToken(filename) { return }
        hostMultipartParts.append(
            MultipartPart(data: data, name: name, type: type, filename: filename)
        )
    }

    /// Builds an unsigned `URLRequest` when no account is attached.
    ///
    /// GET/DELETE encode parameters in the query string. POST/PUT encode
    /// parameters in the body as `application/x-www-form-urlencoded`, or as
    /// `multipart/form-data` when multipart parts exist.
    ///
    /// If `account` is non-nil, returns nil: no OAuth signer/token backend
    /// exists on this host, so an unsigned request would be dishonest.
    open func preparedURLRequest() -> URLRequest! {
        if account != nil {
            return nil
        }
        guard let url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = Self.httpMethodName(requestMethod)

        let items = queryItems()
        let useMultipart =
            !hostMultipartParts.isEmpty
            && (requestMethod == .POST || requestMethod == .PUT)

        switch requestMethod {
        case .GET, .DELETE:
            if !items.isEmpty {
                request.url = Self.urlByAppendingQueryItems(items, to: url)
            }
        case .POST, .PUT:
            if useMultipart {
                let boundary = Self.multipartBoundary(
                    parameters: items,
                    parts: hostMultipartParts
                )
                request.setValue(
                    "multipart/form-data; boundary=\(boundary)",
                    forHTTPHeaderField: "Content-Type"
                )
                request.httpBody = Self.multipartBody(
                    boundary: boundary,
                    parameters: items,
                    parts: hostMultipartParts
                )
            } else if !items.isEmpty {
                let encoded = items.map {
                    "\(Self.formEncode($0.name))=\(Self.formEncode($0.value ?? ""))"
                }.joined(separator: "&")
                request.setValue(
                    "application/x-www-form-urlencoded",
                    forHTTPHeaderField: "Content-Type"
                )
                request.httpBody = encoded.data(using: .utf8)
            }
        }
        return request
    }

    /// Never sends. Invokes `handler` synchronously with a fail-closed error.
    open func perform(handler: SLRequestHandler!) {
        guard let handler else { return }
        handler(nil, nil, SocialServiceError.accountServiceUnavailable)
    }

    private func queryItems() -> [URLQueryItem] {
        guard let parameters else { return [] }
        return parameters.keys
            .map { key -> (String, String) in
                let value = parameters[key]
                return (Self.stringify(key), Self.stringify(value))
            }
            .sorted { $0.0 < $1.0 }
            .map { URLQueryItem(name: $0.0, value: $0.1) }
    }

    private static func httpMethodName(_ method: SLRequestMethod) -> String {
        switch method {
        case .GET: return "GET"
        case .POST: return "POST"
        case .DELETE: return "DELETE"
        case .PUT: return "PUT"
        }
    }

    private static func stringify(_ value: Any?) -> String {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        case let value?:
            return String(describing: value)
        case nil:
            return ""
        }
    }

    private static func formEncode(_ string: String) -> String {
        // application/x-www-form-urlencoded: percent-encode first so literal
        // `+` becomes %2B, then turn %20 into `+` for spaces. `+` is not in
        // the allowed set, so an already space-substituted string is never
        // re-encoded with `+` treated as unreserved.
        let allowed = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._*"
        )
        let encoded = string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
        return encoded.replacingOccurrences(of: "%20", with: "+")
    }

    private static func isSafeMultipartToken(_ string: String) -> Bool {
        !string.isEmpty
            && !string.contains(where: { character in
                character == "\r" || character == "\n" || character == "\""
            })
    }

    /// Multipart `Content-Disposition` field names, including parameter keys.
    private static func multipartFieldName(_ string: String) -> String? {
        isSafeMultipartToken(string) ? string : nil
    }

    private static func urlByAppendingQueryItems(
        _ items: [URLQueryItem],
        to url: URL
    ) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return url
        }
        var existing = components.queryItems ?? []
        existing.append(contentsOf: items)
        components.queryItems = existing
        return components.url ?? url
    }

    private static func multipartHaystack(
        parameters: [URLQueryItem],
        parts: [MultipartPart]
    ) -> Data {
        var haystack = Data()
        for item in parameters {
            haystack.append(Data(item.name.utf8))
            if let value = item.value {
                haystack.append(Data(value.utf8))
            }
        }
        for part in parts {
            haystack.append(part.data)
            haystack.append(Data(part.name.utf8))
            if let type = part.type {
                haystack.append(Data(type.utf8))
            }
            if let filename = part.filename {
                haystack.append(Data(filename.utf8))
            }
        }
        return haystack
    }

    private static func isCollisionFreeBoundary(_ boundary: String, haystack: Data) -> Bool {
        guard isSafeMultipartToken(boundary) else { return false }
        return haystack.range(of: Data(boundary.utf8)) == nil
    }

    /// Yields injected test candidates first, then UUID candidates forever.
    /// Every value still has to pass `isCollisionFreeBoundary`.
    private static func multipartBoundaryCandidateSource() -> AnyIterator<String> {
        let forced = hostMultipartBoundaryCandidates ?? []
        var forcedIndex = 0
        var attempt = 0
        return AnyIterator {
            if forcedIndex < forced.count {
                let candidate = forced[forcedIndex]
                forcedIndex += 1
                return candidate
            }
            let token = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            let boundary = "Boundary\(token)\(attempt)"
            attempt += 1
            return boundary
        }
    }

    private static func multipartBoundary(
        parameters: [URLQueryItem],
        parts: [MultipartPart]
    ) -> String {
        let haystack = multipartHaystack(parameters: parameters, parts: parts)
        let candidates = multipartBoundaryCandidateSource()
        while let candidate = candidates.next() {
            if isCollisionFreeBoundary(candidate, haystack: haystack) {
                return candidate
            }
        }
        fatalError("Social multipart boundary generation produced no candidate")
    }

    private static func multipartBody(
        boundary: String,
        parameters: [URLQueryItem],
        parts: [MultipartPart]
    ) -> Data {
        var body = Data()
        let crlf = "\r\n"
        for item in parameters {
            guard let name = multipartFieldName(item.name) else { continue }
            body.append(Data("--\(boundary)\(crlf)".utf8))
            body.append(
                Data(
                    "Content-Disposition: form-data; name=\"\(name)\"\(crlf)\(crlf)"
                        .utf8
                )
            )
            body.append(Data((item.value ?? "").utf8))
            body.append(Data(crlf.utf8))
        }
        for part in parts {
            guard let name = multipartFieldName(part.name) else { continue }
            body.append(Data("--\(boundary)\(crlf)".utf8))
            var disposition = "Content-Disposition: form-data; name=\"\(name)\""
            if let filename = part.filename, isSafeMultipartToken(filename) {
                disposition += "; filename=\"\(filename)\""
            }
            body.append(Data("\(disposition)\(crlf)".utf8))
            if let type = part.type, isSafeMultipartToken(type) {
                body.append(Data("Content-Type: \(type)\(crlf)".utf8))
            }
            body.append(Data(crlf.utf8))
            body.append(part.data)
            body.append(Data(crlf.utf8))
        }
        body.append(Data("--\(boundary)--\(crlf)".utf8))
        return body
    }
}
