@_exported import Foundation
@preconcurrency import Dispatch

// MARK: - Public constants
//
// `MCErrorDomain` matches the pinned dotnet/macios `[ErrorDomain ("MCErrorDomain")]`
// annotation. `kMCSessionMinimumNumberOfPeers == 2` and
// `kMCSessionMaximumNumberOfPeers == 8` match that binding's documented field
// values. None of these were measured on a Darwin MultipeerConnectivity runtime
// in this promotion.

public let MCErrorDomain = "MCErrorDomain"

public let kMCSessionMinimumNumberOfPeers: Int = 2
public let kMCSessionMaximumNumberOfPeers: Int = 8

// MARK: - Enums
//
// Raw values follow the pinned dotnet/macios `Native` enumerations in
// `src/MultipeerConnectivity/Enums.cs` (declaration order). Darwin numeric ABI
// was not re-observed here.

public enum MCEncryptionPreference: Int, Sendable, Hashable {
    case optional = 0
    case required = 1
    case none = 2
}

public enum MCSessionSendDataMode: Int, Sendable, Hashable {
    case reliable = 0
    case unreliable = 1
}

public enum MCSessionState: Int, Sendable, Hashable {
    case notConnected = 0
    case connecting = 1
    case connected = 2
}

// MARK: - Error overlay

public struct MCError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 0
        case notConnected = 1
        case invalidParameter = 2
        case unsupported = 3
        case timedOut = 4
        case cancelled = 5
        case unavailable = 6
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MCErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var unknown: Code { .unknown }
    public static var notConnected: Code { .notConnected }
    public static var invalidParameter: Code { .invalidParameter }
    public static var unsupported: Code { .unsupported }
    public static var timedOut: Code { .timedOut }
    public static var cancelled: Code { .cancelled }
    public static var unavailable: Code { .unavailable }

    public static func == (lhs: MCError, rhs: MCError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MCError.Code {
    public static func ~= (match: MCError.Code, error: any Error) -> Bool {
        if let typed = error as? MCError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == MCErrorDomain && nsError.code == match.rawValue
    }
}

func mcNSError(_ code: MCError.Code, userInfo: [String: Any]? = nil) -> NSError {
    NSError(domain: MCErrorDomain, code: code.rawValue, userInfo: userInfo)
}

// MARK: - Completion delivery
//
// Advertiser/browser start failures, resource-send completions, and nearby
// connection-data continuations hop once onto this serial queue with `async`,
// never `sync`. Exactly-once is one scheduled block plus a per-invocation flag.

private struct MCUncheckedWork: @unchecked Sendable {
    let body: () -> Void
}

final class MCOnceFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var delivered = false

    func take() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if delivered {
            return false
        }
        delivered = true
        return true
    }
}

let mcCompletionQueue = DispatchQueue(
    label: "MultipeerConnectivity.completion",
    qos: .utility
)

/// Linux host-test control. Hidden from ordinary `import MultipeerConnectivity`
/// clients and absent from the pinned Apple surface.
@_spi(OpenUIKitHost)
public enum MultipeerConnectivityHostControl {
    public static func enqueueCompletionProbe(
        _ body: @escaping @Sendable () -> Void
    ) {
        mcCompletionQueue.async(execute: body)
    }
}

func mcDeliver(_ body: @escaping () -> Void) {
    let once = MCOnceFlag()
    let work = MCUncheckedWork(body: body)
    mcCompletionQueue.async {
        guard once.take() else { return }
        work.body()
    }
}
