public protocol NEAppPushDelegate: NSObjectProtocol {
    func appPushManager(
        _ manager: NEAppPushManager,
        didReceiveIncomingCallWithUserInfo userInfo: [AnyHashable: Any]
    )
}

open class NEAppPushManager: NSObject {
    open class func loadAllFromPreferences(
        completionHandler: @escaping ([NEAppPushManager]?, (any Error)?) -> Void
    ) {
        completionHandler(nil, _NEHostBoundary.appPushError(.configurationInvalid))
    }

    open var isActive: Bool { false }
    public weak var delegate: (any NEAppPushDelegate)?
    open var isEnabled = false
    open var localizedDescription: String?
    open var matchEthernet = false
    open var matchPrivateLTENetworks: [NEPrivateLTENetwork] = []
    open var matchSSIDs: [String] = []
    open var providerBundleIdentifier: String?
    open var providerConfiguration: [String: Any] = [:]

    open func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        completionHandler(_NEHostBoundary.appPushError(.configurationNotLoaded))
    }

    open func saveToPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        completionHandler(_NEHostBoundary.appPushError(.configurationInvalid))
    }

    open func removeFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        completionHandler(_NEHostBoundary.appPushError(.configurationInvalid))
    }
}

open class NEAppPushProvider: NEProvider {
    open var providerConfiguration: [String: Any]? { nil }

    open func start() {}

    open func start(completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(_NEHostBoundary.appPushError(.inactiveSession))
    }

    open func stop(with reason: NEProviderStopReason) async {
        _ = reason
    }

    open func handleTimerEvent() {}

    open func reportIncomingCall(userInfo: [AnyHashable: Any] = [:]) {
        _ = userInfo
    }

    open func reportPushToTalkMessage(userInfo: [AnyHashable: Any] = [:]) {
        _ = userInfo
    }

    open func unmatchEthernet() {}
}

@MainActor
open class NEAppExtensionConfiguration: NSObject {}

public struct NEURLFilterPrefilter: Sendable {
    public enum PrefilterData: Sendable {
        case smallFilter(Data)
        case temporaryFilepath(URL)
    }

    public let data: PrefilterData
    public let tag: String
    public let bitCount: Int
    public let hashCount: Int
    public let murmurSeed: UInt32

    public init(
        data: PrefilterData,
        tag: String,
        bitCount: Int,
        hashCount: Int,
        murmurSeed: UInt32
    ) {
        self.data = data
        self.tag = tag
        self.bitCount = bitCount
        self.hashCount = hashCount
        self.murmurSeed = murmurSeed
    }
}

open class NEURLFilter: NSObject {
    public enum Verdict: Int, Sendable, Hashable {
        case unknown = 0
        case allow = 1
        case deny = 2
    }

    open class func verdict(for url: URL) async -> Verdict {
        _ = url
        return .unknown
    }
}

open class NEURLFilterManager: NSObject {
    public enum Error: Int, Swift.Error, Hashable, Sendable, LocalizedError {
        case unknown = 0
        case configurationInvalid = 1
        case configurationDisabled = 2
        case configurationStale = 3
        case configurationCannotBeRemoved = 4
        case configurationPermissionDenied = 5
        case configurationInternalError = 6
        case configurationNotLoaded = 7
        case configurationUnchanged = 8
        case internalError = 9
        case extensionNotFound = 10
        case extensionCancelled = 11
        case extensionFailedToLoad = 12
        case serverSetupIncomplete = 13

        public var errorDescription: String? { _NEHostBoundary.description }
        public var failureReason: String? { errorDescription }
        public var recoverySuggestion: String? { nil }
        public var helpAnchor: String? { nil }
    }

    public enum Status: Int, Sendable, Hashable {
        case invalid = 0
        case stopped = 1
        case starting = 2
        case running = 3
        case stopping = 4
    }

    private static let _shared = NEURLFilterManager()
    public static var shared: NEURLFilterManager { _shared }

    open var pirServerURL: URL? { nil }
    open var shouldFailClosed = true
    open var appBundleIdentifier: String? { nil }
    open var pirAuthenticationToken: String? { nil }
    open var prefilterFetchInterval: TimeInterval = 0
    open var pirPrivacyPassIssuerURL: URL? { nil }
    open var controlProviderBundleIdentifier: String? { nil }
    open var isEnabled = false

    open var lastDisconnectError: Error? {
        get async { .configurationNotLoaded }
    }

    open var status: Status {
        get async { .invalid }
    }

    open func resetPIRCache() async throws {
        throw Error.configurationInvalid
    }

    open func setConfiguration(
        pirServerURL: URL,
        pirPrivacyPassIssuerURL: URL?,
        pirAuthenticationToken: String,
        controlProviderBundleIdentifier: String
    ) throws {
        _ = (pirServerURL, pirPrivacyPassIssuerURL, pirAuthenticationToken, controlProviderBundleIdentifier)
        throw Error.configurationInvalid
    }

    open func saveToPreferences() async throws {
        throw Error.configurationPermissionDenied
    }

    open func loadFromPreferences() async throws {
        throw Error.configurationNotLoaded
    }

    open func refreshPIRParameters() async throws {
        throw Error.serverSetupIncomplete
    }

    open func removeFromPreferences() async throws {
        throw Error.configurationCannotBeRemoved
    }

    open func handleConfigChange() -> any AsyncSequence<Bool, Never> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    open func handleStatusChange() -> any AsyncSequence<Status, Never> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

@MainActor
public class NEURLFilterControlProviderConfiguration: NEAppExtensionConfiguration {}

public protocol NEURLFilterControlProvider {
    func fetchPrefilter(existingPrefilterTag: String?) async throws -> NEURLFilterPrefilter?
    func start() async throws
    func stop(reason: NEProviderStopReason) async throws
}
