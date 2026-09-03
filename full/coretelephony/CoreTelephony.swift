import Dispatch
import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// Linux overlay of Apple's `CTError` C structure. Domain values follow the
/// pinned `dotnet/macios` `CTErrorDomain` explicit raw values
/// (`NoError = 0`, `Posix = 1`, `Mach = 2`). Apple runtime ABI is otherwise
/// unobserved in this environment.
public struct CTError: Sendable {
    public var domain: Int32
    public var error: Int32

    public init() {
        self.domain = Int32(kCTErrorDomainNoError)
        self.error = 0
    }

    public init(domain: Int32, error: Int32) {
        self.domain = domain
        self.error = error
    }
}

/// Public C enum imported as `Int` getters. Values match macios
/// `CTErrorDomain` (`NoError = 0`).
public var kCTErrorDomainNoError: Int { 0 }

/// Public C enum imported as `Int` getters. Values match macios
/// `CTErrorDomain` (`Posix = 1`).
public var kCTErrorDomainPOSIX: Int { 1 }

/// Public C enum imported as `Int` getters. Values match macios
/// `CTErrorDomain` (`Mach = 2`).
public var kCTErrorDomainMach: Int { 2 }

/// Sequential `NS_ENUM(NSUInteger)` matching macios `CTCellularDataRestrictedState`.
public enum CTCellularDataRestrictedState: UInt, Sendable, Hashable {
    case restrictedStateUnknown = 0
    case restricted = 1
    case notRestricted = 2
}

/// Sequential `NS_ENUM(NSInteger)` matching macios `CTCellularPlanCapability`.
public enum CTCellularPlanCapability: Int, Sendable, Hashable {
    case dataOnly = 0
    case dataAndVoice = 1
}

/// Sequential `NS_ENUM(NSUInteger)` matching macios
/// `CTCellularPlanProvisioningAddPlanResult` case order. The Swift overlay
/// uses `UInt` (`init?(rawValue: UInt)`); macios binds the same cases as
/// `long`.
public enum CTCellularPlanProvisioningAddPlanResult: UInt, Sendable, Hashable {
    case unknown = 0
    case fail = 1
    case success = 2
    case cancel = 3
}

public typealias CellularDataRestrictionDidUpdateNotifier =
    (CTCellularDataRestrictedState) -> Void

// MARK: - Call / RAT / notification / token string constants
//
// Exact Apple string payloads are unobserved here. macios loads them with
// `Dlfcn` / `[Field]` from the Apple dylib. These compile with provisional
// values equal to the public symbol names and are coverage-`declared`.

public let CTCallStateConnected: String = "CTCallStateConnected"
public let CTCallStateDialing: String = "CTCallStateDialing"
public let CTCallStateDisconnected: String = "CTCallStateDisconnected"
public let CTCallStateIncoming: String = "CTCallStateIncoming"

public let CTRadioAccessTechnologyCDMA1x: String = "CTRadioAccessTechnologyCDMA1x"
public let CTRadioAccessTechnologyCDMAEVDORev0: String = "CTRadioAccessTechnologyCDMAEVDORev0"
public let CTRadioAccessTechnologyCDMAEVDORevA: String = "CTRadioAccessTechnologyCDMAEVDORevA"
public let CTRadioAccessTechnologyCDMAEVDORevB: String = "CTRadioAccessTechnologyCDMAEVDORevB"
public let CTRadioAccessTechnologyEdge: String = "CTRadioAccessTechnologyEdge"
public let CTRadioAccessTechnologyGPRS: String = "CTRadioAccessTechnologyGPRS"
public let CTRadioAccessTechnologyHSDPA: String = "CTRadioAccessTechnologyHSDPA"
public let CTRadioAccessTechnologyHSUPA: String = "CTRadioAccessTechnologyHSUPA"
public let CTRadioAccessTechnologyLTE: String = "CTRadioAccessTechnologyLTE"
public let CTRadioAccessTechnologyNR: String = "CTRadioAccessTechnologyNR"
public let CTRadioAccessTechnologyNRNSA: String = "CTRadioAccessTechnologyNRNSA"
public let CTRadioAccessTechnologyWCDMA: String = "CTRadioAccessTechnologyWCDMA"
public let CTRadioAccessTechnologyeHRPD: String = "CTRadioAccessTechnologyeHRPD"

public let CTSubscriberTokenRefreshed: String = "CTSubscriberTokenRefreshed"

extension NSNotification.Name {
    public static let CTRadioAccessTechnologyDidChange = NSNotification.Name(
        "CTRadioAccessTechnologyDidChange"
    )
    public static let CTServiceRadioAccessTechnologyDidChange = NSNotification.Name(
        "CTServiceRadioAccessTechnologyDidChange"
    )
}

/// Fail-closed `NSError` for eSIM / plan / token APIs. This is not an Apple
/// `NSError` domain; `kCTErrorDomain*` are C `Int` enums, not `NSError` domains.
internal func coreTelephonyUnavailableError(_ message: String) -> NSError {
    NSError(
        domain: NSPOSIXErrorDomain,
        code: Int(EPERM),
        userInfo: [NSLocalizedDescriptionKey: message]
    )
}

internal func coreTelephonyHop(_ body: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        body()
    }
}
