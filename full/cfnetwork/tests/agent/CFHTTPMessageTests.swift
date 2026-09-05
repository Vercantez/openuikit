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

func testCFHTTPMessageCreateRequest() {

    require(CFHTTPMessageGetTypeID() != CFHostGetTypeID(), "distinct type IDs")
    let url = CFURLCreateWithString(nil, cfString("http://example.com/path?q=1"), nil)!
    let request = CFHTTPMessageCreateRequest(
        nil,
        cfString("POST"),
        url,
        kCFHTTPVersion1_1
    ).takeRetainedValue()
    require(CFHTTPMessageIsRequest(request), "request flag")
    require(CFHTTPMessageIsHeaderComplete(request), "request headers complete")
    require(swiftString(CFHTTPMessageCopyVersion(request).takeRetainedValue()) == "HTTP/1.1", "version")
    require(
        swiftString(CFHTTPMessageCopyRequestMethod(request)!.takeRetainedValue()) == "POST",
        "method"
    )
    require(CFHTTPMessageCopyRequestURL(request) != nil, "request URL")
}

func testCFHTTPMessageHeadersAndBody() {

    let url = CFURLCreateWithString(nil, cfString("http://example.com/path?q=1"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("POST"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(request, cfString("Content-Type"), cfString("text/plain"))
    CFHTTPMessageSetHeaderFieldValue(request, cfString("X-Test"), cfString("one"))
    require(
        swiftString(CFHTTPMessageCopyHeaderFieldValue(request, cfString("content-type"))!.takeRetainedValue())
            == "text/plain",
        "header lookup is case-insensitive"
    )
    let body = cfDataFromUTF8("hello")
    CFHTTPMessageSetBody(request, body)
    let allHeaders = CFHTTPMessageCopyAllHeaderFields(request)!.takeRetainedValue()
    require(CFDictionaryGetCount(allHeaders) >= 2, "header dictionary")
    let serialized = CFHTTPMessageCopySerializedMessage(request)!.takeRetainedValue()
    let serializedBytes = cfDataBytes(serialized)
    let serializedText = String(bytes: serializedBytes, encoding: .utf8)!
    require(serializedText.hasPrefix("POST /path?q=1 HTTP/1.1\r\n"), "serialized start line")
    require(serializedText.contains("Content-Type: text/plain"), "serialized header")
    require(serializedText.hasSuffix("hello"), "serialized body")
}

func testCFHTTPMessageAppendBytes() {

    let empty = CFHTTPMessageCreateEmpty(nil, false).takeRetainedValue()
    require(!CFHTTPMessageIsHeaderComplete(empty), "empty is incomplete")
    let wire = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nX-Fold: foo\r\n\tbar\r\n\r\nxyz"
    for byte in Array(wire.utf8) {
        var current = byte
        require(CFHTTPMessageAppendBytes(empty, &current, 1), "incremental RFC 7230 append")
    }
    require(CFHTTPMessageIsHeaderComplete(empty), "parsed headers complete")
    require(CFHTTPMessageGetResponseStatusCode(empty) == 200, "parsed status")
    require(
        swiftString(CFHTTPMessageCopyHeaderFieldValue(empty, cfString("Content-Type"))!.takeRetainedValue())
            == "text/plain",
        "parsed header"
    )
    require(
        swiftString(CFHTTPMessageCopyHeaderFieldValue(empty, cfString("X-Fold"))!.takeRetainedValue())
            == "foo bar",
        "obs-fold unfolded"
    )
    let parsedBody = CFHTTPMessageCopyBody(empty)!.takeRetainedValue()
    require(CFDataGetLength(parsedBody) == 3, "parsed body length")

    let lfOnly = CFHTTPMessageCreateEmpty(nil, true).takeRetainedValue()
    let lfWire = "GET /star HTTP/1.0\nHost: example.com\n\n"
    require(
        lfWire.withCString { pointer in
            CFHTTPMessageAppendBytes(
                lfOnly,
                UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self),
                CFIndex(lfWire.utf8.count)
            )
        },
        "LF terminator"
    )
    require(CFHTTPMessageIsHeaderComplete(lfOnly), "LF headers complete")
    require(
        swiftString(CFHTTPMessageCopyRequestMethod(lfOnly)!.takeRetainedValue()) == "GET",
        "LF method"
    )
}

func testCFHTTPMessageSerializedRoundTrip() {

    let url = CFURLCreateWithString(nil, cfString("http://example.com/path?q=1"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("POST"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    CFHTTPMessageSetHeaderFieldValue(request, cfString("Content-Type"), cfString("text/plain"))
    CFHTTPMessageSetBody(request, cfDataFromUTF8("hello"))
    let serialized = CFHTTPMessageCopySerializedMessage(request)!.takeRetainedValue()
    let serializedBytes = cfDataBytes(serialized)
    let roundTrip = CFHTTPMessageCreateEmpty(nil, true).takeRetainedValue()
    let appendedRoundTrip = serializedBytes.withUnsafeBufferPointer { buffer in
        CFHTTPMessageAppendBytes(roundTrip, buffer.baseAddress!, CFIndex(buffer.count))
    }
    require(appendedRoundTrip, "round-trip append")
    let again = CFHTTPMessageCopySerializedMessage(roundTrip)!.takeRetainedValue()
    require(cfDataBytes(again) == serializedBytes, "serialize parse serialize is byte-exact")
}

func testCFHTTPMessageCreateResponse() {

    let response = CFHTTPMessageCreateResponse(
        nil,
        401,
        cfString("Unauthorized"),
        kCFHTTPVersion1_1
    ).takeRetainedValue()
    require(!CFHTTPMessageIsRequest(response), "response flag")
    require(CFHTTPMessageGetResponseStatusCode(response) == 401, "status code")
    require(
        swiftString(CFHTTPMessageCopyResponseStatusLine(response)!.takeRetainedValue())
            == "HTTP/1.1 401 Unauthorized",
        "status line"
    )
}

func testCFHTTPMessageCreateCopy() {

    let url = CFURLCreateWithString(nil, cfString("http://example.com/"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    let copy = CFHTTPMessageCreateCopy(nil, request).takeRetainedValue()
    require(copy != request, "copy is a distinct object")
    require(CFHTTPMessageIsRequest(copy), "copy remains a request")
    require(copy.hashValue == copy.hashValue, "message hashValue")
    var messageHasher = Hasher()
    copy.hash(into: &messageHasher)
    _ = messageHasher.finalize()
    require(copy == copy, "message equality")
}

func testCFHTTPMessageAddAuthentication() {

    let url = CFURLCreateWithString(nil, cfString("http://example.com/secret"), nil)!
    let request = CFHTTPMessageCreateRequest(nil, cfString("GET"), url, kCFHTTPVersion1_1)
        .takeRetainedValue()
    let added = CFHTTPMessageAddAuthentication(
        request,
        nil,
        cfString("user"),
        cfString("pass"),
        kCFHTTPAuthenticationSchemeBasic,
        false
    )
    require(added, "basic authentication added")
    let authorization = swiftString(
        CFHTTPMessageCopyHeaderFieldValue(request, cfString("Authorization"))!.takeRetainedValue()
    )
    require(authorization.hasPrefix("Basic "), "authorization prefix")
    let negotiateRejected = CFHTTPMessageAddAuthentication(
        request,
        nil,
        cfString("user"),
        cfString("pass"),
        kCFHTTPAuthenticationSchemeNegotiate,
        false
    )
    require(!negotiateRejected, "Negotiate authentication fail-closed")
}
