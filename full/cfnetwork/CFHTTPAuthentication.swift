import CoreFoundation
import Foundation

public func CFHTTPAuthenticationGetTypeID() -> CFTypeID {
    CFNetworkTypeID.httpAuthentication
}

public func CFHTTPAuthenticationCreateFromResponse(
    _ alloc: CFAllocator?,
    _ response: CFHTTPMessage
) -> Unmanaged<CFHTTPAuthentication> {
    _ = alloc
    let header =
        CFHTTPMessageCopyHeaderFieldValue(response, cfString("WWW-Authenticate"))?
        .takeRetainedValue()
        ?? CFHTTPMessageCopyHeaderFieldValue(response, cfString("Proxy-Authenticate"))?
        .takeRetainedValue()
    let raw = header.map(swiftString) ?? ""
    let parsed = cfParseAuthenticateHeader(raw)
    let scheme = parsed.scheme
    let isBasic = scheme.compare("Basic", options: [.caseInsensitive, .literal]) == .orderedSame
    let isDigest = scheme.compare("Digest", options: [.caseInsensitive, .literal]) == .orderedSame
    let supported = (isBasic && !raw.isEmpty) || (isDigest && parsed.nonce != nil)
    return cfRetain(
        CFHTTPAuthentication(
            scheme: scheme.isEmpty ? "Basic" : scheme,
            realm: parsed.realm,
            domains: parsed.domains,
            nonce: parsed.nonce,
            opaque: parsed.opaque,
            qopOptions: parsed.qopOptions,
            algorithm: parsed.algorithm,
            stale: parsed.stale,
            charset: parsed.charset,
            isValidAuthentication: supported,
            requiresUserPassword: true,
            requiresAccountDomain: scheme.compare("NTLM", options: [.caseInsensitive, .literal])
                == .orderedSame,
            requiresOrderedRequests: isDigest
                || scheme.compare("NTLM", options: [.caseInsensitive, .literal]) == .orderedSame
        )
    )
}

public func CFHTTPAuthenticationIsValid(
    _ auth: CFHTTPAuthentication,
    _ error: UnsafeMutablePointer<CFStreamError>?
) -> Bool {
    auth.lock.lock()
    defer { auth.lock.unlock() }
    if auth.isValidAuthentication {
        return true
    }
    cfWriteStreamError(
        error,
        domain: kCFStreamErrorDomainHTTP,
        code: CFStreamErrorHTTPAuthentication.typeUnsupported.rawValue
    )
    return false
}

public func CFHTTPAuthenticationAppliesToRequest(
    _ auth: CFHTTPAuthentication,
    _ request: CFHTTPMessage
) -> Bool {
    auth.lock.lock()
    let domains = auth.domains
    auth.lock.unlock()
    guard !domains.isEmpty else { return true }
    guard let url = CFHTTPMessageCopyRequestURL(request)?.takeRetainedValue() else {
        return false
    }
    let host = CFURLCopyHostName(url).map(swiftString) ?? ""
    let path = CFURLCopyPath(url).map(swiftString) ?? "/"
    return domains.contains { domain in
        if domain.hasPrefix("/") {
            return path == domain || path.hasPrefix(domain.hasSuffix("/") ? domain : domain + "/")
        }
        return host.compare(domain, options: [.caseInsensitive, .literal]) == .orderedSame
            || host.lowercased().hasSuffix("." + domain.lowercased())
    }
}

public func CFHTTPAuthenticationCopyMethod(
    _ auth: CFHTTPAuthentication
) -> Unmanaged<CFString> {
    auth.lock.lock()
    defer { auth.lock.unlock() }
    return cfRetain(cfString(auth.scheme))
}

public func CFHTTPAuthenticationCopyRealm(
    _ auth: CFHTTPAuthentication
) -> Unmanaged<CFString> {
    auth.lock.lock()
    defer { auth.lock.unlock() }
    return cfRetain(cfString(auth.realm ?? ""))
}

public func CFHTTPAuthenticationCopyDomains(
    _ auth: CFHTTPAuthentication
) -> Unmanaged<CFArray> {
    auth.lock.lock()
    defer { auth.lock.unlock() }
    return cfRetain(cfStringArray(auth.domains))
}

public func CFHTTPAuthenticationRequiresUserNameAndPassword(
    _ auth: CFHTTPAuthentication
) -> Bool {
    auth.lock.lock()
    defer { auth.lock.unlock() }
    return auth.requiresUserPassword
}

public func CFHTTPAuthenticationRequiresAccountDomain(
    _ auth: CFHTTPAuthentication
) -> Bool {
    auth.lock.lock()
    defer { auth.lock.unlock() }
    return auth.requiresAccountDomain
}

public func CFHTTPAuthenticationRequiresOrderedRequests(
    _ auth: CFHTTPAuthentication
) -> Bool {
    auth.lock.lock()
    defer { auth.lock.unlock() }
    return auth.requiresOrderedRequests
}

func cfApplyDigestAuthorization(
    _ request: CFHTTPMessage,
    auth: CFHTTPAuthentication,
    username: String,
    password: String,
    forProxy: Bool,
    error: UnsafeMutablePointer<CFStreamError>?
) -> Bool {
    request.lock.lock()
    let method = request.method ?? "GET"
    let uri = cfHTTPMessageRequestTarget(request)
    let entityBody = request.body.map(cfDataBytes) ?? []
    request.lock.unlock()

    auth.lock.lock()
    defer { auth.lock.unlock() }
    guard auth.isValidAuthentication, let nonce = auth.nonce, !nonce.isEmpty else {
        cfWriteStreamError(
            error,
            domain: kCFStreamErrorDomainHTTP,
            code: CFStreamErrorHTTPAuthentication.typeUnsupported.rawValue
        )
        return false
    }
    let realm = auth.realm ?? ""
    let algorithm = auth.algorithm
    let hasher: (String) -> String
    let sess: Bool
    switch algorithm.uppercased() {
    case "MD5":
        hasher = cfDigestHexMD5
        sess = false
    case "MD5-SESS":
        hasher = cfDigestHexMD5
        sess = true
    case "SHA-256":
        hasher = cfDigestHexSHA256
        sess = false
    case "SHA-256-SESS":
        hasher = cfDigestHexSHA256
        sess = true
    default:
        cfWriteStreamError(
            error,
            domain: kCFStreamErrorDomainHTTP,
            code: CFStreamErrorHTTPAuthentication.typeUnsupported.rawValue
        )
        return false
    }

    let qop = cfSelectDigestQOP(auth.qopOptions)
    auth.nonceCount += 1
    let nc = String(format: "%08x", auth.nonceCount)
    let cnonce: String
    if qop != nil || sess {
        cnonce = cfRandomNonceHex()
    } else {
        cnonce = ""
    }

    var ha1 = hasher("\(username):\(realm):\(password)")
    if sess {
        ha1 = hasher("\(ha1):\(nonce):\(cnonce)")
    }
    let ha2: String
    if qop == "auth-int" {
        let bodyDigest: String
        switch algorithm.uppercased() {
        case "SHA-256", "SHA-256-SESS":
            bodyDigest = cfDigestHexSHA256(entityBody)
        default:
            bodyDigest = cfDigestHexMD5(entityBody)
        }
        ha2 = hasher("\(method):\(uri):\(bodyDigest)")
    } else {
        ha2 = hasher("\(method):\(uri)")
    }
    let response: String
    if let qop {
        response = hasher("\(ha1):\(nonce):\(nc):\(cnonce):\(qop):\(ha2)")
    } else {
        response = hasher("\(ha1):\(nonce):\(ha2)")
    }

    var parts: [String] = [
        "username=\(cfQuoteAuth(username))",
        "realm=\(cfQuoteAuth(realm))",
        "nonce=\(cfQuoteAuth(nonce))",
        "uri=\(cfQuoteAuth(uri))",
        "response=\(cfQuoteAuth(response))",
    ]
    if algorithm.uppercased() != "MD5" {
        parts.append("algorithm=\(algorithm)")
    } else {
        parts.append("algorithm=MD5")
    }
    if let qop {
        parts.append("qop=\(qop)")
        parts.append("nc=\(nc)")
        parts.append("cnonce=\(cfQuoteAuth(cnonce))")
    }
    if let opaque = auth.opaque {
        parts.append("opaque=\(cfQuoteAuth(opaque))")
    }
    let headerName = forProxy ? "Proxy-Authorization" : "Authorization"
    let value = "Digest " + parts.joined(separator: ", ")
    CFHTTPMessageSetHeaderFieldValue(request, cfString(headerName), cfString(value))
    return true
}

private func cfSelectDigestQOP(_ options: [String]) -> String? {
    let lowered = options.map { $0.lowercased() }
    if lowered.contains("auth") { return "auth" }
    if lowered.contains("auth-int") { return "auth-int" }
    return nil
}

private func cfRandomNonceHex() -> String {
    var bytes = [UInt8](repeating: 0, count: 16)
    for index in bytes.indices {
        bytes[index] = UInt8.random(in: 0...255)
    }
    return cfHexLower(bytes)
}

private func cfQuoteAuth(_ value: String) -> String {
    let escaped = value.replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
}

private func cfParseAuthenticateHeader(_ raw: String) -> (
    scheme: String,
    realm: String?,
    domains: [String],
    nonce: String?,
    opaque: String?,
    qopOptions: [String],
    algorithm: String,
    stale: Bool,
    charset: String?
) {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
        return ("", nil, [], nil, nil, [], "MD5", false, nil)
    }
    let schemeEnd = trimmed.firstIndex(where: { $0 == " " || $0 == "\t" }) ?? trimmed.endIndex
    let scheme = String(trimmed[..<schemeEnd])
    let remainder = schemeEnd == trimmed.endIndex
        ? ""
        : String(trimmed[trimmed.index(after: schemeEnd)...])
    let parameters = cfParseAuthParameters(remainder)
    let domain = parameters["domain"] ?? ""
    let domains = domain.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    let qop = parameters["qop"] ?? ""
    let qopOptions = qop.split(separator: ",").map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
    }.filter { !$0.isEmpty }
    let algorithm = parameters["algorithm"] ?? "MD5"
    let stale = (parameters["stale"] ?? "").lowercased() == "true"
    return (
        scheme,
        parameters["realm"],
        domains,
        parameters["nonce"],
        parameters["opaque"],
        qopOptions,
        algorithm,
        stale,
        parameters["charset"]
    )
}

private func cfParseAuthParameters(_ raw: String) -> [String: String] {
    var result: [String: String] = [:]
    var index = raw.startIndex
    while index < raw.endIndex {
        while index < raw.endIndex && (raw[index] == "," || raw[index].isWhitespace) {
            index = raw.index(after: index)
        }
        guard index < raw.endIndex else { break }
        let keyStart = index
        while index < raw.endIndex && raw[index] != "=" && raw[index] != "," {
            index = raw.index(after: index)
        }
        let key = raw[keyStart..<index]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard index < raw.endIndex, raw[index] == "=" else { continue }
        index = raw.index(after: index)
        while index < raw.endIndex && raw[index].isWhitespace {
            index = raw.index(after: index)
        }
        let value: String
        if index < raw.endIndex && raw[index] == "\"" {
            index = raw.index(after: index)
            var chars: [Character] = []
            while index < raw.endIndex {
                if raw[index] == "\\" {
                    index = raw.index(after: index)
                    if index < raw.endIndex {
                        chars.append(raw[index])
                        index = raw.index(after: index)
                    }
                } else if raw[index] == "\"" {
                    index = raw.index(after: index)
                    break
                } else {
                    chars.append(raw[index])
                    index = raw.index(after: index)
                }
            }
            value = String(chars)
        } else {
            let valueStart = index
            while index < raw.endIndex && raw[index] != "," {
                index = raw.index(after: index)
            }
            value = raw[valueStart..<index].trimmingCharacters(in: .whitespaces)
        }
        if !key.isEmpty {
            result[key] = value
        }
    }
    return result
}
