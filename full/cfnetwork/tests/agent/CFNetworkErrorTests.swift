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

func testCFNetworkErrorRawValues() {

    let pairs: [(CFNetworkErrors, Int32)] = [
        (.cfHostErrorHostNotFound, 1),
        (.cfHostErrorUnknown, 2),
        (.cfsocksErrorUnknownClientVersion, 100),
        (.cfsocksErrorUnsupportedServerVersion, 101),
        (.cfsocks4ErrorRequestFailed, 110),
        (.cfsocks4ErrorIdentdFailed, 111),
        (.cfsocks4ErrorIdConflict, 112),
        (.cfsocks4ErrorUnknownStatusCode, 113),
        (.cfsocks5ErrorBadState, 120),
        (.cfsocks5ErrorBadResponseAddr, 121),
        (.cfsocks5ErrorBadCredentials, 122),
        (.cfsocks5ErrorUnsupportedNegotiationMethod, 123),
        (.cfsocks5ErrorNoAcceptableMethod, 124),
        (.cfftpErrorUnexpectedStatusCode, 200),
        (.cfErrorHTTPAuthenticationTypeUnsupported, 300),
        (.cfErrorHTTPBadCredentials, 301),
        (.cfErrorHTTPConnectionLost, 302),
        (.cfErrorHTTPParseFailure, 303),
        (.cfErrorHTTPRedirectionLoopDetected, 304),
        (.cfErrorHTTPBadURL, 305),
        (.cfErrorHTTPProxyConnectionFailure, 306),
        (.cfErrorHTTPBadProxyCredentials, 307),
        (.cfErrorPACFileError, 308),
        (.cfErrorPACFileAuth, 309),
        (.cfErrorHTTPSProxyConnectionFailure, 310),
        (.cfStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod, 311),
        (.cfurlErrorBackgroundSessionInUseByAnotherProcess, -996),
        (.cfurlErrorBackgroundSessionWasDisconnected, -997),
        (.cfurlErrorUnknown, -998),
        (.cfurlErrorCancelled, -999),
        (.cfurlErrorBadURL, -1000),
        (.cfurlErrorTimedOut, -1001),
        (.cfurlErrorUnsupportedURL, -1002),
        (.cfurlErrorCannotFindHost, -1003),
        (.cfurlErrorCannotConnectToHost, -1004),
        (.cfurlErrorNetworkConnectionLost, -1005),
        (.cfurlErrorDNSLookupFailed, -1006),
        (.cfurlErrorHTTPTooManyRedirects, -1007),
        (.cfurlErrorResourceUnavailable, -1008),
        (.cfurlErrorNotConnectedToInternet, -1009),
        (.cfurlErrorRedirectToNonExistentLocation, -1010),
        (.cfurlErrorBadServerResponse, -1011),
        (.cfurlErrorUserCancelledAuthentication, -1012),
        (.cfurlErrorUserAuthenticationRequired, -1013),
        (.cfurlErrorZeroByteResource, -1014),
        (.cfurlErrorCannotDecodeRawData, -1015),
        (.cfurlErrorCannotDecodeContentData, -1016),
        (.cfurlErrorCannotParseResponse, -1017),
        (.cfurlErrorInternationalRoamingOff, -1018),
        (.cfurlErrorCallIsActive, -1019),
        (.cfurlErrorDataNotAllowed, -1020),
        (.cfurlErrorRequestBodyStreamExhausted, -1021),
        (.cfurlErrorAppTransportSecurityRequiresSecureConnection, -1022),
        (.cfurlErrorFileDoesNotExist, -1100),
        (.cfurlErrorFileIsDirectory, -1101),
        (.cfurlErrorNoPermissionsToReadFile, -1102),
        (.cfurlErrorDataLengthExceedsMaximum, -1103),
        (.cfurlErrorFileOutsideSafeArea, -1104),
        (.cfurlErrorSecureConnectionFailed, -1200),
        (.cfurlErrorServerCertificateHasBadDate, -1201),
        (.cfurlErrorServerCertificateUntrusted, -1202),
        (.cfurlErrorServerCertificateHasUnknownRoot, -1203),
        (.cfurlErrorServerCertificateNotYetValid, -1204),
        (.cfurlErrorClientCertificateRejected, -1205),
        (.cfurlErrorClientCertificateRequired, -1206),
        (.cfurlErrorCannotLoadFromNetwork, -2000),
        (.cfurlErrorCannotCreateFile, -3000),
        (.cfurlErrorCannotOpenFile, -3001),
        (.cfurlErrorCannotCloseFile, -3002),
        (.cfurlErrorCannotWriteToFile, -3003),
        (.cfurlErrorCannotRemoveFile, -3004),
        (.cfurlErrorCannotMoveFile, -3005),
        (.cfurlErrorDownloadDecodingFailedMidStream, -3006),
        (.cfurlErrorDownloadDecodingFailedToComplete, -3007),
        (.cfhttpCookieCannotParseCookieFile, -4000),
        (.cfNetServiceErrorUnknown, -72000),
        (.cfNetServiceErrorCollision, -72001),
        (.cfNetServiceErrorNotFound, -72002),
        (.cfNetServiceErrorInProgress, -72003),
        (.cfNetServiceErrorBadArgument, -72004),
        (.cfNetServiceErrorCancel, -72005),
        (.cfNetServiceErrorInvalid, -72006),
        (.cfNetServiceErrorTimeout, -72007),
        (.cfNetServiceErrorDNSServiceFailure, -73000),
    ]
    for (error, raw) in pairs {
        require(error.rawValue == raw, "CFNetworkErrors raw \(raw)")
        require(CFNetworkErrors(rawValue: raw) == error, "CFNetworkErrors init \(raw)")
    }
    require(CFNetworkErrors(rawValue: 0) == nil, "unknown error raw value")
    require(
        Set(CFNetworkErrors.allCases.map(\.rawValue)).count == CFNetworkErrors.allCases.count,
        "unique error codes"
    )
}

func testCFNetworkErrorHashable() {

    require(CFNetworkErrors.cfurlErrorCancelled != .cfurlErrorBadURL, "error inequality")
    require(CFNetworkErrors.cfurlErrorCancelled == .cfurlErrorCancelled, "error equality")
    var hasher = Hasher()
    CFNetworkErrors.cfurlErrorTimedOut.hash(into: &hasher)
    _ = hasher.finalize()
    require(
        CFNetworkErrors.cfurlErrorTimedOut.hashValue == CFNetworkErrors.cfurlErrorTimedOut.hashValue,
        "error hashValue"
    )
}
