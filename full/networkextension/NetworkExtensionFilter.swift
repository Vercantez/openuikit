import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

open class NEFilterVerdict: NSObject {
    open var shouldReport = false
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
}

open class NEFilterDataVerdict: NEFilterVerdict {
    public init(passBytes: Int, peekBytes: Int) {
        _ = (passBytes, peekBytes)
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
}

open class NEFilterRemediationVerdict: NEFilterVerdict {
    open class func allow() -> NEFilterRemediationVerdict { NEFilterRemediationVerdict() }
    open class func drop() -> NEFilterRemediationVerdict { NEFilterRemediationVerdict() }
    open class func needRules() -> NEFilterRemediationVerdict { NEFilterRemediationVerdict() }
}

open class NEFilterFlow: NSObject {
    private let flowIdentifier = UUID()

    open var url: URL? { nil }
    open var direction: NETrafficDirection { .any }
    open var identifier: UUID { flowIdentifier }
    open var sourceAppIdentifier: String? { nil }
    open var sourceAppUniqueIdentifier: Data? { nil }
    open var sourceAppVersion: String? { nil }
}

open class NEFilterBrowserFlow: NEFilterFlow {
    open var parentURL: URL? { nil }
    open var request: URLRequest? { nil }
    open var response: URLResponse? { nil }
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
}

open class NEFilterReport: NSObject {
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
}

open class NEFilterProviderConfiguration: NSObject {
    open var filterBrowsers = false
    open var filterSockets = false
    open var identityReference: Data?
    open var organization: String?
    open var passwordReference: Data?
    open var serverAddress: String?
    open var username: String?
    open var vendorConfiguration: [String: Any]?
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
