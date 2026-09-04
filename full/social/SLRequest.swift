import Foundation

#if canImport(Accounts)
import Accounts
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Social-network HTTP request builder.
///
/// Linux does not sign OAuth and does not perform network I/O.
/// `preparedURLRequest()` returns nil when `account` is non-nil.
/// `perform(handler:)` hops once onto a private queue and delivers a
/// fail-closed `NSError` with no `HTTPURLResponse`.

open class SLRequest: NSObject {
    private let storedServiceType: String?
    private let storedRequestMethod: SLRequestMethod
    private let storedURL: URL?
    private let storedParameters: [AnyHashable: Any]
    private var storedAccount: ACAccount?
    private var multipartParts: [MultipartPart] = []

    public init!(
        forServiceType serviceType: String!,
        requestMethod: SLRequestMethod,
        url: URL!,
        parameters: [AnyHashable: Any]!
    ) {
        self.storedServiceType = serviceType
        self.storedRequestMethod = requestMethod
        self.storedURL = url
        if let parameters {
            self.storedParameters = parameters
        } else {
            self.storedParameters = [:]
        }
        super.init()
    }

    /// Swift 3 renamed this to `url:`. Kept as a declaration for the pinned
    /// synthesized identifier; Swift 6 cannot call an obsoleted-in-Swift-3 API.
    @available(swift, obsoleted: 3, renamed: "init(forServiceType:requestMethod:url:parameters:)")
    public init!(
        forServiceType serviceType: String!,
        requestMethod: SLRequestMethod,
        URL url: URL!,
        parameters: [AnyHashable: Any]!
    ) {
        self.storedServiceType = serviceType
        self.storedRequestMethod = requestMethod
        self.storedURL = url
        if let parameters {
            self.storedParameters = parameters
        } else {
            self.storedParameters = [:]
        }
        super.init()
    }

    open var account: ACAccount! {
        get { storedAccount }
        set { storedAccount = newValue }
    }

    open var requestMethod: SLRequestMethod { storedRequestMethod }

    open var url: URL! { storedURL }

    open var parameters: [AnyHashable: Any]! { storedParameters }

    open func addMultipartData(
        _ data: Data!,
        withName name: String!,
        type: String!,
        filename: String!
    ) {
        guard let data, let name, let type else { return }
        guard socialMultipartMetadataIsSafe(name),
              socialMultipartMetadataIsSafe(type),
              filename == nil || socialMultipartMetadataIsSafe(filename!)
        else {
            return
        }
        multipartParts.append(
            MultipartPart(data: data, name: name, type: type, filename: filename)
        )
    }

    open func preparedURLRequest() -> URLRequest! {
        if storedAccount != nil {
            return nil
        }
        guard let storedURL else {
            return nil
        }
        for (key, _) in storedParameters {
            let keyText = String(describing: key)
            if !socialMultipartMetadataIsSafe(keyText) {
                return nil
            }
        }
        if !multipartParts.isEmpty {
            return preparedMultipartRequest(baseURL: storedURL)
        }
        return preparedURLEncodedRequest(baseURL: storedURL)
    }

    open func perform(handler: SLRequestHandler!) {
        guard let handler else { return }
        let error = socialFailClosedError(.appleServiceUnavailable)
        socialDeliverPerform {
            handler(nil, nil, error)
        }
    }

    private func preparedURLEncodedRequest(baseURL: URL) -> URLRequest! {
        var items: [URLQueryItem] = []
        for (key, value) in storedParameters {
            guard let encoded = socialEncodeParameterValue(value) else {
                return nil
            }
            items.append(URLQueryItem(name: String(describing: key), value: encoded))
        }
        var request = URLRequest(url: baseURL)
        request.httpMethod = socialHTTPMethod(storedRequestMethod)
        switch storedRequestMethod {
        case .GET, .DELETE:
            guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
                return nil
            }
            if !items.isEmpty {
                components.queryItems = (components.queryItems ?? []) + items
            }
            guard let url = components.url else { return nil }
            request.url = url
        case .POST, .PUT:
            if !items.isEmpty {
                let encoded = items.map { item in
                    let name = socialPercentEncode(item.name)
                    let value = socialPercentEncode(item.value ?? "")
                    return "\(name)=\(value)"
                }.joined(separator: "&")
                request.httpBody = Data(encoded.utf8)
                request.setValue(
                    "application/x-www-form-urlencoded",
                    forHTTPHeaderField: "Content-Type"
                )
            }
        }
        return request
    }

    private func preparedMultipartRequest(baseURL: URL) -> URLRequest! {
        for (key, _) in storedParameters {
            if !socialMultipartMetadataIsSafe(String(describing: key)) {
                return nil
            }
        }
        for part in multipartParts {
            if !socialMultipartMetadataIsSafe(part.name)
                || !socialMultipartMetadataIsSafe(part.type)
                || (part.filename.map(socialMultipartMetadataIsSafe) == false)
            {
                return nil
            }
        }
        let corpus = socialMultipartCorpus(parameters: storedParameters, parts: multipartParts)
        let boundary = socialMakeCollisionCheckedBoundary(corpus: corpus)
        var body = Data()
        func append(_ text: String) {
            body.append(Data(text.utf8))
        }
        for (key, value) in storedParameters {
            let name = String(describing: key)
            guard let encoded = socialEncodeParameterValue(value) else {
                return nil
            }
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            append("\(encoded)\r\n")
        }
        for part in multipartParts {
            append("--\(boundary)\r\n")
            var disposition = "Content-Disposition: form-data; name=\"\(part.name)\""
            if let filename = part.filename {
                disposition += "; filename=\"\(filename)\""
            }
            append("\(disposition)\r\n")
            append("Content-Type: \(part.type)\r\n\r\n")
            body.append(part.data)
            append("\r\n")
        }
        append("--\(boundary)--\r\n")
        var request = URLRequest(url: baseURL)
        request.httpMethod = socialHTTPMethod(storedRequestMethod)
        request.httpBody = body
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        return request
    }
}

private func socialHTTPMethod(_ method: SLRequestMethod) -> String {
    switch method {
    case .GET: return "GET"
    case .POST: return "POST"
    case .DELETE: return "DELETE"
    case .PUT: return "PUT"
    }
}

private func socialEncodeParameterValue(_ value: Any) -> String? {
    if let text = value as? String {
        return text
    }
    if let number = value as? NSNumber {
        return number.stringValue
    }
    return nil
}

private func socialPercentEncode(_ value: String) -> String {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "&+=")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
}

extension SLRequest {
    @_spi(OpenUIKitHost)
    public var isolatedHostMultipartPartCount: Int { multipartParts.count }

    @_spi(OpenUIKitHost)
    public var isolatedHostServiceType: String? { storedServiceType }
}
