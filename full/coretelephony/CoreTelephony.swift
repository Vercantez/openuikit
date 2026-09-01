import Foundation

/// Linux has no baseband radio, SIM, or Apple cellular-plan daemon.
/// Query APIs return empty or unknown values. Service APIs fail closed
/// instead of fabricating carrier identity, tokens, or plan success.
struct CoreTelephonyUnsupportedError: Error, Equatable, LocalizedError, Sendable {
    var errorDescription: String? {
        "CoreTelephony has no cellular hardware or Apple cellular-plan service on this host"
    }
}

// MARK: - C error surface (CoreTelephonyDefines.h)

/// No error domain. Public C enum `kCTErrorDomainNoError`.
public var kCTErrorDomainNoError: Int { 0 }

/// POSIX error domain. Public C enum `kCTErrorDomainPOSIX`.
public var kCTErrorDomainPOSIX: Int { 1 }

/// Mach error domain. Public C enum `kCTErrorDomainMach`.
public var kCTErrorDomainMach: Int { 2 }

/// Bridged `CTError` C structure. Values are integers, not a Swift `Error`.
public struct CTError: Sendable, BitwiseCopyable {
    public var domain: Int32
    public var error: Int32

    public init() {
        domain = 0
        error = 0
    }

    public init(domain: Int32, error: Int32) {
        self.domain = domain
        self.error = error
    }
}

// MARK: - Call state constants (CTCall.h, deprecated iOS 10)
//
// String payloads are provisional (identifier-equal) until an Apple-oracle
// dump confirms the exact bytes. Clients should compare against these
// constants, not against hardcoded literals.

/// Dialing state string compared against `CTCall.callState`.
public let CTCallStateDialing = "CTCallStateDialing"

/// Incoming state string compared against `CTCall.callState`.
public let CTCallStateIncoming = "CTCallStateIncoming"

/// Connected state string compared against `CTCall.callState`.
public let CTCallStateConnected = "CTCallStateConnected"

/// Disconnected state string compared against `CTCall.callState`.
public let CTCallStateDisconnected = "CTCallStateDisconnected"

// MARK: - Radio access technology constants (CTTelephonyNetworkInfo.h)

public let CTRadioAccessTechnologyGPRS = "CTRadioAccessTechnologyGPRS"
public let CTRadioAccessTechnologyEdge = "CTRadioAccessTechnologyEdge"
public let CTRadioAccessTechnologyWCDMA = "CTRadioAccessTechnologyWCDMA"
public let CTRadioAccessTechnologyHSDPA = "CTRadioAccessTechnologyHSDPA"
public let CTRadioAccessTechnologyHSUPA = "CTRadioAccessTechnologyHSUPA"
public let CTRadioAccessTechnologyCDMA1x = "CTRadioAccessTechnologyCDMA1x"
public let CTRadioAccessTechnologyCDMAEVDORev0 = "CTRadioAccessTechnologyCDMAEVDORev0"
public let CTRadioAccessTechnologyCDMAEVDORevA = "CTRadioAccessTechnologyCDMAEVDORevA"
public let CTRadioAccessTechnologyCDMAEVDORevB = "CTRadioAccessTechnologyCDMAEVDORevB"
public let CTRadioAccessTechnologyeHRPD = "CTRadioAccessTechnologyeHRPD"
public let CTRadioAccessTechnologyLTE = "CTRadioAccessTechnologyLTE"
public let CTRadioAccessTechnologyNRNSA = "CTRadioAccessTechnologyNRNSA"
public let CTRadioAccessTechnologyNR = "CTRadioAccessTechnologyNR"

/// Posted when the subscriber carrier token is refreshed.
public let CTSubscriberTokenRefreshed = "CTSubscriberTokenRefreshed"

extension NSNotification.Name {
    /// Deprecated in iOS 12; renamed to `CTServiceRadioAccessTechnologyDidChange`.
    /// Raw value is provisional until an Apple-oracle dump confirms the bytes.
    public static let CTRadioAccessTechnologyDidChange = NSNotification.Name(
        "CTRadioAccessTechnologyDidChangeNotification"
    )

    /// Posted when any service's radio access technology changes.
    /// Raw value is provisional until an Apple-oracle dump confirms the bytes.
    public static let CTServiceRadioAccessTechnologyDidChange = NSNotification.Name(
        "CTServiceRadioAccessTechnologyDidChangeNotification"
    )
}
