import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

open class NEFilterVerdict: NSObject, NSCopying {
    open var shouldReport = false

    func populateVerdictCopy(_ copy: NEFilterVerdict) {
        copy.shouldReport = shouldReport
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEFilterVerdict()
        populateVerdictCopy(copy)
        return copy
    }
}

open class NEFilterNewFlowVerdict: NEFilterVerdict {
    open class func allow() -> NEFilterNewFlowVerdict { NEFilterNewFlowVerdict() }
    open class func drop() -> NEFilterNewFlowVerdict { NEFilterNewFlowVerdict() }
    open class func needRules() -> NEFilterNewFlowVerdict { NEFilterNewFlowVerdict() }

    open class func filterDataVerdict(
        withFilterInbound filterInbound: Bool,
        peekInboundBytes: Int,
        filterOutbound: Bool,
        peekOutboundBytes: Int
    ) -> NEFilterNewFlowVerdict {
        _ = (filterInbound, peekInboundBytes, filterOutbound, peekOutboundBytes)
        return NEFilterNewFlowVerdict()
    }

    open class func remediateVerdict(
        withRemediationURLMapKey remediationURLMapKey: String,
        remediationButtonTextMapKey: String
    ) -> NEFilterNewFlowVerdict {
        _ = (remediationURLMapKey, remediationButtonTextMapKey)
        return NEFilterNewFlowVerdict()
    }

    open class func urlAppendStringVerdict(withMapKey urlAppendMapKey: String) -> NEFilterNewFlowVerdict {
        _ = urlAppendMapKey
        return NEFilterNewFlowVerdict()
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEFilterNewFlowVerdict()
        populateVerdictCopy(copy)
        return copy
    }
}

open class NEFilterDataVerdict: NEFilterVerdict {
    let passBytes: Int
    let peekBytes: Int

    public init(passBytes: Int, peekBytes: Int) {
        self.passBytes = passBytes
        self.peekBytes = peekBytes
        super.init()
    }

    open class func allow() -> NEFilterDataVerdict {
        NEFilterDataVerdict(passBytes: 0, peekBytes: 0)
    }

    open class func drop() -> NEFilterDataVerdict {
        NEFilterDataVerdict(passBytes: 0, peekBytes: 0)
    }

    open class func needRules() -> NEFilterDataVerdict {
        NEFilterDataVerdict(passBytes: 0, peekBytes: 0)
    }

    open class func remediateVerdict(
        withRemediationURLMapKey remediationURLMapKey: String?,
        remediationButtonTextMapKey: String?
    ) -> NEFilterDataVerdict {
        _ = (remediationURLMapKey, remediationButtonTextMapKey)
        return NEFilterDataVerdict(passBytes: 0, peekBytes: 0)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEFilterDataVerdict(passBytes: passBytes, peekBytes: peekBytes)
        populateVerdictCopy(copy)
        return copy
    }
}

open class NEFilterControlVerdict: NEFilterVerdict {
    open class func allow(withUpdateRules updateRules: Bool) -> NEFilterControlVerdict {
        _ = updateRules
        return NEFilterControlVerdict()
    }

    open class func drop(withUpdateRules updateRules: Bool) -> NEFilterControlVerdict {
        _ = updateRules
        return NEFilterControlVerdict()
    }

    open class func updateRules() -> NEFilterControlVerdict { NEFilterControlVerdict() }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEFilterControlVerdict()
        populateVerdictCopy(copy)
        return copy
    }
}

open class NEFilterRemediationVerdict: NEFilterVerdict {
    open class func allow() -> NEFilterRemediationVerdict { NEFilterRemediationVerdict() }
    open class func drop() -> NEFilterRemediationVerdict { NEFilterRemediationVerdict() }
    open class func needRules() -> NEFilterRemediationVerdict { NEFilterRemediationVerdict() }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEFilterRemediationVerdict()
        populateVerdictCopy(copy)
        return copy
    }
}

open class NEFilterFlow: NSObject, NSCopying {
    private let flowIdentifier: UUID

    public override init() {
        flowIdentifier = UUID()
        super.init()
    }

    init(copiedIdentifier: UUID) {
        flowIdentifier = copiedIdentifier
        super.init()
    }

    open var url: URL? { nil }
    open var direction: NETrafficDirection { .any }
    open var identifier: UUID { flowIdentifier }
    open var sourceAppIdentifier: String? { nil }
    open var sourceAppUniqueIdentifier: Data? { nil }
    open var sourceAppVersion: String? { nil }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NEFilterFlow(copiedIdentifier: flowIdentifier)
    }
}

open class NEFilterBrowserFlow: NEFilterFlow {
    open var parentURL: URL? { nil }
    open var request: URLRequest? { nil }
    open var response: URLResponse? { nil }

    public override init() {
        super.init()
    }

    override init(copiedIdentifier: UUID) {
        super.init(copiedIdentifier: copiedIdentifier)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NEFilterBrowserFlow(copiedIdentifier: identifier)
    }
}

open class NEFilterSocketFlow: NEFilterFlow {
    open var localEndpoint: NWEndpoint? { nil }
    open var remoteEndpoint: NWEndpoint? { nil }
    open var remoteHostname: String? { nil }
    open var socketFamily: Int32 { 0 }
    open var socketProtocol: Int32 { 0 }
    open var socketType: Int32 { 0 }
    open var localFlowEndpoint: NWEndpoint? { localEndpoint }
    open var remoteFlowEndpoint: NWEndpoint? { remoteEndpoint }

    public override init() {
        super.init()
    }

    override init(copiedIdentifier: UUID) {
        super.init(copiedIdentifier: copiedIdentifier)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NEFilterSocketFlow(copiedIdentifier: identifier)
    }
}

open class NEFilterReport: NSObject, NSCopying {
    public enum Event: Int, Sendable, Hashable {
        case newFlow = 1
        case dataDecision = 2
        case flowClosed = 3
    }

    open var action: NEFilterAction { .invalid }
    open var bytesInboundCount: Int { 0 }
    open var bytesOutboundCount: Int { 0 }
    open var event: Event { .newFlow }
    open var flow: NEFilterFlow? { nil }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NEFilterReport()
    }
}

open class NEFilterProviderConfiguration: NSObject, NSCopying {
    open var filterBrowsers = false
    open var filterSockets = false
    open var identityReference: Data?
    open var organization: String?
    open var passwordReference: Data?
    open var serverAddress: String?
    open var username: String?
    open var vendorConfiguration: [String: Any]?

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEFilterProviderConfiguration()
        copy.filterBrowsers = filterBrowsers
        copy.filterSockets = filterSockets
        copy.identityReference = identityReference
        copy.organization = organization
        copy.passwordReference = passwordReference
        copy.serverAddress = serverAddress
        copy.username = username
        copy.vendorConfiguration = _NECopiedDictionary(vendorConfiguration)
        return copy
    }
}

open class NEFilterManager: NSObject {
    private static let _shared = NEFilterManager()

    open class func shared() -> NEFilterManager { _shared }

    open var isEnabled = false
    open var localizedDescription: String?
    open var providerConfiguration: NEFilterProviderConfiguration?

    open func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEFilterErrorDomain,
                code: NEFilterManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func saveToPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEFilterErrorDomain,
                code: NEFilterManagerError.configurationPermissionDenied.rawValue
            )
        )
    }

    open func removeFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEFilterErrorDomain,
                code: NEFilterManagerError.configurationCannotBeRemoved.rawValue
            )
        )
    }
}

open class NEFilterProvider: NEProvider {
    open var filterConfiguration: NEFilterProviderConfiguration {
        NEFilterProviderConfiguration()
    }

    open func startFilter(completionHandler: @escaping ((any Error)?) -> Void) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEFilterErrorDomain,
                code: NEFilterManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func stopFilter(with reason: NEProviderStopReason) async {
        _ = reason
    }

    open func handle(_ report: NEFilterReport) {
        _ = report
    }
}

open class NEFilterDataProvider: NEFilterProvider {
    open func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        _ = flow
        return .drop()
    }

    open func handleInboundData(
        from flow: NEFilterFlow,
        readBytesStartOffset offset: Int,
        readBytes: Data
    ) -> NEFilterDataVerdict {
        _ = (flow, offset, readBytes)
        return .drop()
    }

    open func handleOutboundData(
        from flow: NEFilterFlow,
        readBytesStartOffset offset: Int,
        readBytes: Data
    ) -> NEFilterDataVerdict {
        _ = (flow, offset, readBytes)
        return .drop()
    }

    open func handleInboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        _ = flow
        return .drop()
    }

    open func handleOutboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        _ = flow
        return .drop()
    }

    open func handleRemediation(for flow: NEFilterFlow) -> NEFilterRemediationVerdict {
        _ = flow
        return .drop()
    }

    open func handleRulesChanged() {}
}

open class NEFilterControlProvider: NEFilterProvider {
    open var urlAppendStringMap: [String: String]?
    open var remediationMap: [String: [String: NSObject]]?

    open func handleNewFlow(_ flow: NEFilterFlow) async -> NEFilterControlVerdict {
        _ = flow
        return .drop(withUpdateRules: false)
    }

    open func handleRemediation(for flow: NEFilterFlow) async -> NEFilterControlVerdict {
        _ = flow
        return .drop(withUpdateRules: false)
    }

    open func notifyRulesChanged() {}
}
