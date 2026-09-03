import CoreFoundation
import Foundation
#if canImport(Glibc)
import Glibc
#endif

public func CFNetworkCopySystemProxySettings() -> Unmanaged<CFDictionary>? {
    let dictionary = cfMutableDictionary()
    let http = cfParseProxyEnvironment("http_proxy") ?? cfParseProxyEnvironment("HTTP_PROXY")
    let https = cfParseProxyEnvironment("https_proxy") ?? cfParseProxyEnvironment("HTTPS_PROXY")
    let all = cfParseProxyEnvironment("all_proxy") ?? cfParseProxyEnvironment("ALL_PROXY")
    let chosen = http ?? all
    if let chosen {
        cfDictionarySet(dictionary, key: kCFNetworkProxiesHTTPEnable, value: cfBoolean(true))
        cfDictionarySet(dictionary, key: kCFNetworkProxiesHTTPProxy, value: cfString(chosen.host))
        cfDictionarySet(dictionary, key: kCFNetworkProxiesHTTPPort, value: cfNumber(chosen.port))
    } else {
        cfDictionarySet(dictionary, key: kCFNetworkProxiesHTTPEnable, value: cfBoolean(false))
    }
    _ = https
    cfDictionarySet(dictionary, key: kCFNetworkProxiesProxyAutoConfigEnable, value: cfBoolean(false))
    return cfRetain(dictionary)
}

public func CFNetworkCopyProxiesForURL(
    _ url: CFURL,
    _ proxySettings: CFDictionary
) -> Unmanaged<CFArray> {
    let absolute = cfURLString(url)
    if cfShouldBypassProxy(absolute) {
        return cfRetain(cfProxyArray(type: kCFProxyTypeNone, host: nil, port: nil))
    }
    let enablePointer = CFDictionaryGetValue(
        proxySettings,
        Unmanaged.passUnretained(kCFNetworkProxiesHTTPEnable).toOpaque()
    )
    let enabled: Bool
    if let enablePointer {
        let cfb = Unmanaged<CFBoolean>.fromOpaque(enablePointer).takeUnretainedValue()
        enabled = CFBooleanGetValue(cfb)
    } else {
        enabled = false
    }
    guard enabled else {
        return cfRetain(cfProxyArray(type: kCFProxyTypeNone, host: nil, port: nil))
    }
    let hostPointer = CFDictionaryGetValue(
        proxySettings,
        Unmanaged.passUnretained(kCFNetworkProxiesHTTPProxy).toOpaque()
    )
    let portPointer = CFDictionaryGetValue(
        proxySettings,
        Unmanaged.passUnretained(kCFNetworkProxiesHTTPPort).toOpaque()
    )
    let host = hostPointer.map { Unmanaged<CFString>.fromOpaque($0).takeUnretainedValue() }
    var port = 80
    if let portPointer {
        let number = Unmanaged<CFNumber>.fromOpaque(portPointer).takeUnretainedValue()
        var stored = 0
        if CFNumberGetValue(number, .nsIntegerType, &stored) {
            port = stored
        }
    }
    let scheme = CFURLCopyScheme(url).map(swiftString)?.lowercased() ?? "http"
    let type: CFString
    switch scheme {
    case "https":
        type = kCFProxyTypeHTTPS
    case "ftp":
        type = kCFProxyTypeFTP
    default:
        type = kCFProxyTypeHTTP
    }
    return cfRetain(cfProxyArray(type: type, host: host, port: port))
}

public func CFNetworkCopyProxiesForAutoConfigurationScript(
    _ proxyAutoConfigurationScript: CFString,
    _ targetURL: CFURL,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Unmanaged<CFArray>? {
    _ = proxyAutoConfigurationScript
    _ = targetURL
    error?.pointee = cfRetain(cfNetworkError(.cfErrorPACFileError))
    return nil
}

public func CFNetworkExecuteProxyAutoConfigurationScript(
    _ proxyAutoConfigurationScript: CFString,
    _ targetURL: CFURL,
    _ cb: CFProxyAutoConfigurationResultCallback,
    _ clientContext: UnsafeMutablePointer<CFStreamClientContext>
) -> CFRunLoopSource {
    _ = proxyAutoConfigurationScript
    _ = targetURL
    if let retain = clientContext.pointee.retain, let info = clientContext.pointee.info {
        _ = retain(info)
    }
    cb(
        cfClientInfoPointer(clientContext.pointee.info),
        cfEmptyArray(),
        cfNetworkError(.cfErrorPACFileError)
    )
    if let release = clientContext.pointee.release, let info = clientContext.pointee.info {
        release(info)
    }
    return cfInertRunLoopSource()
}

public func CFNetworkExecuteProxyAutoConfigurationURL(
    _ proxyAutoConfigURL: CFURL,
    _ targetURL: CFURL,
    _ cb: CFProxyAutoConfigurationResultCallback,
    _ clientContext: UnsafeMutablePointer<CFStreamClientContext>
) -> CFRunLoopSource {
    _ = proxyAutoConfigURL
    _ = targetURL
    if let retain = clientContext.pointee.retain, let info = clientContext.pointee.info {
        _ = retain(info)
    }
    cb(
        cfClientInfoPointer(clientContext.pointee.info),
        cfEmptyArray(),
        cfNetworkError(.cfErrorPACFileError)
    )
    if let release = clientContext.pointee.release, let info = clientContext.pointee.info {
        release(info)
    }
    return cfInertRunLoopSource()
}

private struct ParsedProxy {
    var host: String
    var port: Int
}

private func cfParseProxyEnvironment(_ name: String) -> ParsedProxy? {
    guard let raw = getenv(name).map({ String(cString: $0) }), !raw.isEmpty else {
        return nil
    }
    var value = raw
    if let parsed = URL(string: value), let host = parsed.host {
        let port = parsed.port ?? (parsed.scheme == "https" ? 443 : 80)
        return ParsedProxy(host: host, port: port)
    }
    if let schemeRange = value.range(of: "://") {
        value = String(value[schemeRange.upperBound...])
    }
    if let at = value.firstIndex(of: "@") {
        value = String(value[value.index(after: at)...])
    }
    if let slash = value.firstIndex(of: "/") {
        value = String(value[..<slash])
    }
    let parts = value.split(separator: ":", maxSplits: 1)
    guard let host = parts.first, !host.isEmpty else { return nil }
    let port = parts.count == 2 ? Int(parts[1]) ?? 80 : 80
    return ParsedProxy(host: String(host), port: port)
}

private func cfShouldBypassProxy(_ absolute: String) -> Bool {
    let noProxy = getenv("no_proxy").map { String(cString: $0) }
        ?? getenv("NO_PROXY").map { String(cString: $0) }
        ?? ""
    guard !noProxy.isEmpty, let host = URL(string: absolute)?.host?.lowercased() else {
        return false
    }
    let tokens = noProxy.split(separator: ",").map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    return tokens.contains { token in
        if token == "*" { return true }
        if token.hasPrefix(".") {
            return host.hasSuffix(token) || host == String(token.dropFirst())
        }
        return host == token || host.hasSuffix("." + token)
    }
}

private func cfProxyArray(type: CFString, host: CFString?, port: Int?) -> CFArray {
    let entry = cfMutableDictionary()
    cfDictionarySet(entry, key: kCFProxyTypeKey, value: type)
    if let host {
        cfDictionarySet(entry, key: kCFProxyHostNameKey, value: host)
    }
    if let port {
        cfDictionarySet(entry, key: kCFProxyPortNumberKey, value: cfNumber(port))
    }
    let array = cfMutableArray()
    cfArrayAppend(array, entry)
    return array
}
