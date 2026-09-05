import CFNetwork
import CoreFoundation
import Foundation
#if canImport(Glibc)
import Glibc
#endif

final class CallbackCounter {
    var value = 0
}

func cfDataFromUTF8(_ value: String) -> CFData {
    Array(value.utf8).withUnsafeBufferPointer { buffer in
        CFDataCreate(nil, buffer.baseAddress, CFIndex(buffer.count))!
    }
}

func cfDataBytes(_ data: CFData) -> [UInt8] {
    let length = Int(CFDataGetLength(data))
    guard length > 0, let pointer = CFDataGetBytePtr(data) else { return [] }
    return Array(UnsafeBufferPointer(start: pointer, count: length))
}

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("CFNetworkRuntime: \(message)")
    }
}

func swiftString(_ value: CFString) -> String {
    let length = Int(CFStringGetLength(value))
    var buffer = [CChar](repeating: 0, count: max(16, length * 4 + 1))
    require(
        CFStringGetCString(
            value,
            &buffer,
            CFIndex(buffer.count),
            CFStringBuiltInEncodings.UTF8.rawValue
        ),
        "CFString conversion"
    )
    return String(cString: buffer)
}

func cfString(_ value: String) -> CFString {
    value.withCString { CFStringCreateWithCString(nil, $0, CFStringBuiltInEncodings.UTF8.rawValue)! }
}

func testCFHTTPAuthenticationCreateFromResponse() {

    require(CFHTTPAuthenticationGetTypeID() != CFNetServiceGetTypeID(), "auth vs service type ID")
    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Basic realm=\"test\", charset=\"UTF-8\"")
    )
    let auth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(CFHTTPAuthenticationIsValid(auth, nil), "basic auth valid")
    require(swiftString(CFHTTPAuthenticationCopyMethod(auth).takeRetainedValue()) == "Basic", "method")
    require(swiftString(CFHTTPAuthenticationCopyRealm(auth).takeRetainedValue()) == "test", "realm")
}

func testCFHTTPAuthenticationAppliesToRequest() {

    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Basic realm=\"test\", charset=\"UTF-8\"")
    )
    let auth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(CFHTTPAuthenticationRequiresUserNameAndPassword(auth), "requires user/password")
    require(!CFHTTPAuthenticationRequiresAccountDomain(auth), "basic does not need domain")
    require(!CFHTTPAuthenticationRequiresOrderedRequests(auth), "basic unordered")
    require(CFArrayGetCount(CFHTTPAuthenticationCopyDomains(auth).takeRetainedValue()) == 0, "no domains")
    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    require(CFHTTPAuthenticationAppliesToRequest(auth, request), "applies without domain list")
}

func testCFHTTPMessageApplyCredentials() {

    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Basic realm=\"test\", charset=\"UTF-8\"")
    )
    let auth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    var streamError = CFStreamError(domain: 0, error: 0)
    require(
        CFHTTPMessageApplyCredentials(
            request,
            auth,
            cfString("user"),
            cfString("secret"),
            &streamError
        ),
        "apply basic credentials"
    )
    let usernameValue = cfString("user")
    let passwordValue = cfString("secret")
    var keyCallbacks = kCFTypeDictionaryKeyCallBacks
    var valueCallbacks = kCFTypeDictionaryValueCallBacks
    let dictionary = CFDictionaryCreateMutable(nil, 0, &keyCallbacks, &valueCallbacks)!
    CFDictionarySetValue(
        dictionary,
        Unmanaged.passUnretained(kCFHTTPAuthenticationUsername).toOpaque(),
        Unmanaged.passUnretained(usernameValue).toOpaque()
    )
    CFDictionarySetValue(
        dictionary,
        Unmanaged.passUnretained(kCFHTTPAuthenticationPassword).toOpaque(),
        Unmanaged.passUnretained(passwordValue).toOpaque()
    )
    require(
        CFHTTPMessageApplyCredentialDictionary(request, auth, dictionary, &streamError),
        "apply credential dictionary"
    )
}

func testCFHTTPAuthenticationDigest() {

    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Digest realm=\"test\", nonce=\"abc\", domain=\"example.com /digest\"")
    )
    let digest = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    var streamError = CFStreamError(domain: 0, error: 0)
    require(CFHTTPAuthenticationIsValid(digest, &streamError), "digest is valid")
    require(CFHTTPAuthenticationRequiresOrderedRequests(digest), "digest is ordered")
    require(
        CFArrayGetCount(CFHTTPAuthenticationCopyDomains(digest).takeRetainedValue()) == 2,
        "digest domains"
    )
    let digestURL = CFURLCreateWithString(nil, cfString("http://example.com/digest"), nil)!
    let digestRequest = CFHTTPMessageCreateRequest(nil, cfString("GET"), digestURL, kCFHTTPVersion1_1)
        .takeRetainedValue()
    require(
        CFHTTPMessageApplyCredentials(
            digestRequest,
            digest,
            cfString("user"),
            cfString("secret"),
            &streamError
        ),
        "apply digest credentials"
    )
    let digestHeader = swiftString(
        CFHTTPMessageCopyHeaderFieldValue(digestRequest, cfString("Authorization"))!.takeRetainedValue()
    )
    require(digestHeader.hasPrefix("Digest "), "digest prefix")
    require(digestHeader.contains("response=\"ec6458ea81d81a4ae02cc6a0f78cc718\""), "RFC 7616 MD5 response")
    require(digestHeader.contains("uri=\"/digest\""), "digest uri")
    require(
        CFHTTPMessageAddAuthentication(
            digestRequest,
            response,
            cfString("user"),
            cfString("secret"),
            kCFHTTPAuthenticationSchemeDigest,
            false
        ),
        "AddAuthentication digest"
    )

    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Digest realm=\"test\", nonce=\"abc\", algorithm=SHA-256")
    )
    let shaAuth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    let shaRequest = CFHTTPMessageCreateRequest(nil, cfString("GET"), digestURL, kCFHTTPVersion1_1)
        .takeRetainedValue()
    require(
        CFHTTPMessageApplyCredentials(
            shaRequest,
            shaAuth,
            cfString("user"),
            cfString("secret"),
            &streamError
        ),
        "apply SHA-256 digest"
    )
    let shaHeader = swiftString(
        CFHTTPMessageCopyHeaderFieldValue(shaRequest, cfString("Authorization"))!.takeRetainedValue()
    )
    require(
        shaHeader.contains("response=\"b66cc11abd401777adfdaaf45b4cc8e65918912262b063c4ccc9eaa9f6a93358\""),
        "RFC 7616 SHA-256 response"
    )
}

func testCFHTTPAuthenticationUnsupportedScheme() {

    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Negotiate realm=\"test\"")
    )
    let negotiate = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    var streamError = CFStreamError(domain: 0, error: 0)
    require(!CFHTTPAuthenticationIsValid(negotiate, &streamError), "Negotiate fail-closed")
    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    require(
        !CFHTTPMessageApplyCredentials(
            request,
            negotiate,
            cfString("user"),
            cfString("secret"),
            &streamError
        ),
        "Negotiate apply fail-closed"
    )
    require(
        streamError.domain == CFIndex(kCFStreamErrorDomainHTTP),
        "unsupported scheme error domain"
    )
    require(
        streamError.error == CFStreamErrorHTTPAuthentication.typeUnsupported.rawValue,
        "unsupported scheme error code"
    )
}

func testCFHTTPAuthenticationHashable() {

    let response = CFHTTPMessageCreateResponse(nil, 401, nil, kCFHTTPVersion1_1).takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(
        response,
        cfString("WWW-Authenticate"),
        cfString("Basic realm=\"test\"")
    )
    let auth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(auth.hashValue == auth.hashValue, "auth hashValue")
    var authHasher = Hasher()
    auth.hash(into: &authHasher)
    _ = authHasher.finalize()
    let otherAuth = CFHTTPAuthenticationCreateFromResponse(nil, response).takeRetainedValue()
    require(auth != otherAuth, "auth identity inequality")
    require(auth == auth, "auth equality")
}
