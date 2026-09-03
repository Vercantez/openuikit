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
    let supported = scheme.compare("Basic", options: [.caseInsensitive, .literal]) == .orderedSame
    return cfRetain(
        CFHTTPAuthentication(
            scheme: scheme.isEmpty ? "Basic" : scheme,
            realm: parsed.realm,
            domains: parsed.domains,
            isValidAuthentication: supported && !raw.isEmpty,
            requiresUserPassword: true,
            requiresAccountDomain: scheme.compare("NTLM", options: [.caseInsensitive, .literal])
                == .orderedSame,
            requiresOrderedRequests: scheme.compare("Digest", options: [.caseInsensitive, .literal])
                == .orderedSame
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
    return domains.contains { domain in
        host.compare(domain, options: [.caseInsensitive, .literal]) == .orderedSame
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

private func cfParseAuthenticateHeader(_ raw: String) -> (
    scheme: String, realm: String?, domains: [String]
) {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return ("", nil, []) }
    let pieces = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
    let scheme = pieces.first.map(String.init) ?? ""
    var realm: String?
    var domains: [String] = []
    if pieces.count == 2 {
        let parameters = String(pieces[1]).split(separator: ",")
        for parameter in parameters {
            let item = parameter.trimmingCharacters(in: .whitespaces)
            let parts = item.split(separator: "=", maxSplits: 1).map {
                $0.trimmingCharacters(in: CharacterSet(charactersIn: " \t\""))
            }
            guard parts.count == 2 else { continue }
            if parts[0].lowercased() == "realm" {
                realm = parts[1]
            } else if parts[0].lowercased() == "domain" {
                domains = parts[1].split(separator: " ").map(String.init)
            }
        }
    }
    return (scheme, realm, domains)
}
