import CoreFoundation
import Foundation

public func CFHTTPMessageGetTypeID() -> CFTypeID {
    CFNetworkTypeID.httpMessage
}

public func CFHTTPMessageCreateEmpty(
    _ alloc: CFAllocator?,
    _ isRequest: Bool
) -> Unmanaged<CFHTTPMessage> {
    _ = alloc
    return cfRetain(
        CFHTTPMessage(
            isRequestMessage: isRequest,
            headerComplete: false,
            httpVersion: "HTTP/1.1"
        )
    )
}

public func CFHTTPMessageCreateRequest(
    _ alloc: CFAllocator?,
    _ requestMethod: CFString,
    _ url: CFURL,
    _ httpVersion: CFString
) -> Unmanaged<CFHTTPMessage> {
    _ = alloc
    return cfRetain(
        CFHTTPMessage(
            isRequestMessage: true,
            headerComplete: true,
            httpVersion: swiftString(httpVersion),
            method: swiftString(requestMethod),
            url: url
        )
    )
}

public func CFHTTPMessageCreateResponse(
    _ alloc: CFAllocator?,
    _ statusCode: CFIndex,
    _ statusDescription: CFString?,
    _ httpVersion: CFString
) -> Unmanaged<CFHTTPMessage> {
    _ = alloc
    let reason: String
    if let statusDescription {
        reason = swiftString(statusDescription)
    } else {
        reason = CFHTTPMessage.defaultReason(for: statusCode)
    }
    return cfRetain(
        CFHTTPMessage(
            isRequestMessage: false,
            headerComplete: true,
            httpVersion: swiftString(httpVersion),
            statusCode: statusCode,
            statusReason: reason
        )
    )
}

public func CFHTTPMessageCreateCopy(
    _ alloc: CFAllocator?,
    _ message: CFHTTPMessage
) -> Unmanaged<CFHTTPMessage> {
    _ = alloc
    message.lock.lock()
    defer { message.lock.unlock() }
    let copy = CFHTTPMessage(
        isRequestMessage: message.isRequestMessage,
        headerComplete: message.headerComplete,
        httpVersion: message.httpVersion,
        method: message.method,
        url: message.url,
        statusCode: message.statusCode,
        statusReason: message.statusReason
    )
    copy.headers = message.headers
    copy.body = message.body.map(cfDataCopy)
    copy.parseBuffer = message.parseBuffer
    return cfRetain(copy)
}

public func CFHTTPMessageIsRequest(_ message: CFHTTPMessage) -> Bool {
    message.lock.lock()
    defer { message.lock.unlock() }
    return message.isRequestMessage
}

public func CFHTTPMessageIsHeaderComplete(_ message: CFHTTPMessage) -> Bool {
    message.lock.lock()
    defer { message.lock.unlock() }
    return message.headerComplete
}

public func CFHTTPMessageCopyVersion(_ message: CFHTTPMessage) -> Unmanaged<CFString> {
    message.lock.lock()
    defer { message.lock.unlock() }
    return cfRetain(cfString(message.httpVersion))
}

public func CFHTTPMessageCopyRequestMethod(
    _ request: CFHTTPMessage
) -> Unmanaged<CFString>? {
    request.lock.lock()
    defer { request.lock.unlock() }
    guard request.isRequestMessage, let method = request.method else { return nil }
    return cfRetain(cfString(method))
}

public func CFHTTPMessageCopyRequestURL(_ request: CFHTTPMessage) -> Unmanaged<CFURL>? {
    request.lock.lock()
    defer { request.lock.unlock() }
    guard request.isRequestMessage, let url = request.url else { return nil }
    return cfRetain(url)
}

public func CFHTTPMessageGetResponseStatusCode(_ response: CFHTTPMessage) -> CFIndex {
    response.lock.lock()
    defer { response.lock.unlock() }
    return response.isRequestMessage ? 0 : response.statusCode
}

public func CFHTTPMessageCopyResponseStatusLine(
    _ response: CFHTTPMessage
) -> Unmanaged<CFString>? {
    response.lock.lock()
    defer { response.lock.unlock() }
    guard !response.isRequestMessage else { return nil }
    let reason = response.statusReason ?? CFHTTPMessage.defaultReason(for: response.statusCode)
    let line = "\(response.httpVersion) \(response.statusCode) \(reason)"
    return cfRetain(cfString(line))
}

public func CFHTTPMessageSetHeaderFieldValue(
    _ message: CFHTTPMessage,
    _ headerField: CFString,
    _ value: CFString?
) {
    let name = swiftString(headerField)
    message.lock.lock()
    defer { message.lock.unlock() }
    message.headers.removeAll {
        $0.name.compare(name, options: [.caseInsensitive, .literal]) == .orderedSame
    }
    if let value {
        message.headers.append((name: name, value: swiftString(value)))
    }
}

public func CFHTTPMessageCopyHeaderFieldValue(
    _ message: CFHTTPMessage,
    _ headerField: CFString
) -> Unmanaged<CFString>? {
    let name = swiftString(headerField)
    message.lock.lock()
    defer { message.lock.unlock() }
    guard let header = message.headers.last(where: {
        $0.name.compare(name, options: [.caseInsensitive, .literal]) == .orderedSame
    }) else {
        return nil
    }
    return cfRetain(cfString(header.value))
}

public func CFHTTPMessageCopyAllHeaderFields(
    _ message: CFHTTPMessage
) -> Unmanaged<CFDictionary>? {
    message.lock.lock()
    defer { message.lock.unlock() }
    let dictionary = cfMutableDictionary()
    for header in message.headers {
        cfDictionarySet(dictionary, key: cfString(header.name), value: cfString(header.value))
    }
    return cfRetain(dictionary)
}

public func CFHTTPMessageSetBody(_ message: CFHTTPMessage, _ bodyData: CFData) {
    message.lock.lock()
    defer { message.lock.unlock() }
    message.body = cfDataCopy(bodyData)
}

public func CFHTTPMessageCopyBody(_ message: CFHTTPMessage) -> Unmanaged<CFData>? {
    message.lock.lock()
    defer { message.lock.unlock() }
    guard let body = message.body else { return nil }
    return cfRetain(cfDataCopy(body))
}

public func CFHTTPMessageCopySerializedMessage(
    _ message: CFHTTPMessage
) -> Unmanaged<CFData>? {
    message.lock.lock()
    defer { message.lock.unlock() }
    guard message.headerComplete else { return nil }
    var lines: [String] = []
    if message.isRequestMessage {
        let method = message.method ?? "GET"
        let uri: String
        if let url = message.url {
            uri = cfRequestURI(from: url)
        } else {
            uri = "/"
        }
        lines.append("\(method) \(uri) \(message.httpVersion)")
    } else {
        let reason = message.statusReason ?? CFHTTPMessage.defaultReason(for: message.statusCode)
        lines.append("\(message.httpVersion) \(message.statusCode) \(reason)")
    }
    for header in message.headers {
        lines.append("\(header.name): \(header.value)")
    }
    var bytes = Array((lines.joined(separator: "\r\n") + "\r\n\r\n").utf8)
    if let body = message.body {
        bytes.append(contentsOf: cfDataBytes(body))
    }
    return cfRetain(cfDataFromBytes(bytes))
}

public func CFHTTPMessageAppendBytes(
    _ message: CFHTTPMessage,
    _ newBytes: UnsafePointer<UInt8>,
    _ numBytes: CFIndex
) -> Bool {
    guard numBytes >= 0 else { return false }
    message.lock.lock()
    defer { message.lock.unlock() }
    if numBytes > 0 {
        message.parseBuffer.append(contentsOf: UnsafeBufferPointer(start: newBytes, count: Int(numBytes)))
    }
    if message.headerComplete {
        if numBytes > 0 {
            let extra = cfDataFromBytes(
                Array(UnsafeBufferPointer(start: newBytes, count: Int(numBytes)))
            )
            if let existing = message.body {
                var combined = cfDataBytes(existing)
                combined.append(contentsOf: cfDataBytes(extra))
                message.body = cfDataFromBytes(combined)
            } else {
                message.body = extra
            }
        }
        return true
    }
    guard let headerEnd = cfFindHeaderTerminator(message.parseBuffer) else {
        return true
    }
    let headerBytes = Array(message.parseBuffer[..<headerEnd])
    let bodyBytes = Array(message.parseBuffer[headerEnd...])
    guard cfParseHTTPHeaders(headerBytes, into: message) else {
        return false
    }
    message.headerComplete = true
    message.parseBuffer = []
    if !bodyBytes.isEmpty {
        message.body = cfDataFromBytes(bodyBytes)
    }
    return true
}

public func CFHTTPMessageAddAuthentication(
    _ request: CFHTTPMessage,
    _ authenticationFailureResponse: CFHTTPMessage?,
    _ username: CFString,
    _ password: CFString,
    _ authenticationScheme: CFString?,
    _ forProxy: Bool
) -> Bool {
    let scheme: String
    if let authenticationScheme {
        scheme = swiftString(authenticationScheme)
    } else if let authenticationFailureResponse {
        let auth = CFHTTPAuthenticationCreateFromResponse(nil, authenticationFailureResponse)
            .takeRetainedValue()
        auth.lock.lock()
        scheme = auth.scheme
        auth.lock.unlock()
    } else {
        scheme = "Basic"
    }
    guard scheme.compare("Basic", options: [.caseInsensitive, .literal]) == .orderedSame else {
        return false
    }
    let token = Data("\(swiftString(username)):\(swiftString(password))".utf8)
        .base64EncodedString()
    let headerName = forProxy ? "Proxy-Authorization" : "Authorization"
    CFHTTPMessageSetHeaderFieldValue(request, cfString(headerName), cfString("Basic \(token)"))
    return true
}

public func CFHTTPMessageApplyCredentials(
    _ request: CFHTTPMessage,
    _ auth: CFHTTPAuthentication,
    _ username: CFString?,
    _ password: CFString?,
    _ error: UnsafeMutablePointer<CFStreamError>?
) -> Bool {
    auth.lock.lock()
    let scheme = auth.scheme
    let valid = auth.isValidAuthentication
    auth.lock.unlock()
    guard valid else {
        cfWriteStreamError(
            error,
            domain: kCFStreamErrorDomainHTTP,
            code: CFStreamErrorHTTPAuthentication.typeUnsupported.rawValue
        )
        return false
    }
    guard scheme.compare("Basic", options: [.caseInsensitive, .literal]) == .orderedSame else {
        cfWriteStreamError(
            error,
            domain: kCFStreamErrorDomainHTTP,
            code: CFStreamErrorHTTPAuthentication.typeUnsupported.rawValue
        )
        return false
    }
    guard let username, let password else {
        cfWriteStreamError(
            error,
            domain: kCFStreamErrorDomainHTTP,
            code: CFStreamErrorHTTPAuthentication.badUserName.rawValue
        )
        return false
    }
    return CFHTTPMessageAddAuthentication(
        request,
        nil,
        username,
        password,
        kCFHTTPAuthenticationSchemeBasic,
        false
    )
}

public func CFHTTPMessageApplyCredentialDictionary(
    _ request: CFHTTPMessage,
    _ auth: CFHTTPAuthentication,
    _ dict: CFDictionary,
    _ error: UnsafeMutablePointer<CFStreamError>?
) -> Bool {
    let usernamePointer = CFDictionaryGetValue(
        dict,
        Unmanaged.passUnretained(kCFHTTPAuthenticationUsername).toOpaque()
    )
    let passwordPointer = CFDictionaryGetValue(
        dict,
        Unmanaged.passUnretained(kCFHTTPAuthenticationPassword).toOpaque()
    )
    guard let usernamePointer, let passwordPointer else {
        cfWriteStreamError(
            error,
            domain: kCFStreamErrorDomainHTTP,
            code: CFStreamErrorHTTPAuthentication.badUserName.rawValue
        )
        return false
    }
    let username = Unmanaged<CFString>.fromOpaque(usernamePointer).takeUnretainedValue()
    let password = Unmanaged<CFString>.fromOpaque(passwordPointer).takeUnretainedValue()
    return CFHTTPMessageApplyCredentials(request, auth, username, password, error)
}

extension CFHTTPMessage {
    static func defaultReason(for status: CFIndex) -> String {
        switch status {
        case 200: return "OK"
        case 201: return "Created"
        case 204: return "No Content"
        case 301: return "Moved Permanently"
        case 302: return "Found"
        case 304: return "Not Modified"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 407: return "Proxy Authentication Required"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
}

private func cfFindHeaderTerminator(_ buffer: [UInt8]) -> Int? {
    guard buffer.count >= 4 else { return nil }
    for index in 0...(buffer.count - 4) {
        if buffer[index] == 13,
           buffer[index + 1] == 10,
           buffer[index + 2] == 13,
           buffer[index + 3] == 10
        {
            return index + 4
        }
    }
    return nil
}

private func cfParseHTTPHeaders(_ bytes: [UInt8], into message: CFHTTPMessage) -> Bool {
    guard let text = String(bytes: bytes, encoding: .utf8) else { return false }
    let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        .trimmingCharacters(in: CharacterSet(charactersIn: "\n"))
    let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    guard let start = lines.first, !start.isEmpty else { return false }
    let parts = start.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: false)
        .map(String.init)
    guard parts.count >= 2 else { return false }
    if parts[0].hasPrefix("HTTP/") {
        message.isRequestMessage = false
        message.httpVersion = parts[0]
        message.statusCode = CFIndex(parts[1]) ?? 0
        message.statusReason = parts.count > 2 ? parts[2] : CFHTTPMessage.defaultReason(
            for: message.statusCode
        )
    } else {
        message.isRequestMessage = true
        message.method = parts[0]
        message.httpVersion = parts.count > 2 ? parts[2] : "HTTP/1.1"
        let uri = parts[1]
        message.url = cfURLFromString(uri) ?? cfURLFromString("http://localhost\(uri.hasPrefix("/") ? uri : "/" + uri)")
    }
    message.headers = []
    for line in lines.dropFirst() {
        if line.isEmpty { continue }
        guard let separator = line.firstIndex(of: ":") else { return false }
        let name = String(line[..<separator]).trimmingCharacters(in: .whitespaces)
        let value = String(line[line.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
        message.headers.append((name: name, value: value))
    }
    return true
}
