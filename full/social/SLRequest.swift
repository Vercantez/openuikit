import Foundation
import FoundationNetworking

/// Signed-account social HTTP request.
///
/// Construction, parameter encoding, multipart bookkeeping, and
/// `preparedURLRequest()` assembly are local. OAuth signing and network
/// I/O are fail-closed: `account` never authorizes a call, and
/// `perform(handler:)` does not send.
open class SLRequest: NSObject {
    public struct MultipartPart: Equatable {
        public var data: Data
        public var name: String
        public var type: String?
        public var filename: String?
    }

    public private(set) var portableServiceType: String?
    open private(set) var requestMethod: SLRequestMethod
    open private(set) var url: URL!
    open private(set) var parameters: [AnyHashable: Any]!
    open var account: ACAccount!
    public private(set) var portableMultipartParts: [MultipartPart] = []

    public init?(
        forServiceType serviceType: String?,
        requestMethod: SLRequestMethod,
        url: URL?,
        parameters: [AnyHashable: Any]?
    ) {
        guard let url else { return nil }
        portableServiceType = serviceType
        self.requestMethod = requestMethod
        self.url = url
        self.parameters = parameters
        super.init()
    }

    public convenience init?(
        forServiceType serviceType: String?,
        requestMethod: SLRequestMethod,
        URL url: URL?,
        parameters: [AnyHashable: Any]?
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
        portableMultipartParts.append(
            MultipartPart(data: data, name: name, type: type, filename: filename)
        )
    }

    /// Builds an unsigned `URLRequest`.
    ///
    /// GET/DELETE encode parameters in the query string. POST/PUT encode
    /// parameters in the body as `application/x-www-form-urlencoded`, or as
    /// `multipart/form-data` when multipart parts exist. No OAuth headers
    /// are added, even if `account` is non-nil.
    open func preparedURLRequest() -> URLRequest! {
        guard let url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = Self.httpMethodName(requestMethod)

        let items = queryItems()
        let useMultipart =
            !portableMultipartParts.isEmpty
            && (requestMethod == .POST || requestMethod == .PUT)

        switch requestMethod {
        case .GET, .DELETE:
            if !items.isEmpty {
                request.url = Self.urlByAppendingQueryItems(items, to: url)
            }
        case .POST, .PUT:
            if useMultipart {
                let boundary = "SocialLinuxBoundary"
                request.setValue(
                    "multipart/form-data; boundary=\(boundary)",
                    forHTTPHeaderField: "Content-Type"
                )
                request.httpBody = Self.multipartBody(
                    boundary: boundary,
                    parameters: items,
                    parts: portableMultipartParts
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
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._*")
        let encoded =
            string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
        return encoded.replacingOccurrences(of: " ", with: "+")
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

    private static func multipartBody(
        boundary: String,
        parameters: [URLQueryItem],
        parts: [MultipartPart]
    ) -> Data {
        var body = Data()
        let crlf = "\r\n"
        for item in parameters {
            body.append(Data("--\(boundary)\(crlf)".utf8))
            body.append(
                Data(
                    "Content-Disposition: form-data; name=\"\(item.name)\"\(crlf)\(crlf)"
                        .utf8
                )
            )
            body.append(Data((item.value ?? "").utf8))
            body.append(Data(crlf.utf8))
        }
        for part in parts {
            body.append(Data("--\(boundary)\(crlf)".utf8))
            var disposition = "Content-Disposition: form-data; name=\"\(part.name)\""
            if let filename = part.filename {
                disposition += "; filename=\"\(filename)\""
            }
            body.append(Data("\(disposition)\(crlf)".utf8))
            if let type = part.type {
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
