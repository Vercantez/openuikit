@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
func testFilterVerdicts() {

let allow = NEFilterNewFlowVerdict.allow()
allow.shouldReport = true
precondition(allow.shouldReport)
_ = NEFilterNewFlowVerdict.drop()
_ = NEFilterNewFlowVerdict.needRules()
_ = NEFilterNewFlowVerdict.filterDataVerdict(
    withFilterInbound: true,
    peekInboundBytes: 64,
    filterOutbound: true,
    peekOutboundBytes: 64
)
_ = NEFilterDataVerdict.allow()
_ = NEFilterDataVerdict.drop()
_ = NEFilterDataVerdict(passBytes: 16, peekBytes: 32)
_ = NEFilterControlVerdict.drop(withUpdateRules: false)
_ = NEFilterRemediationVerdict.drop()

let flow = NEFilterFlow()
precondition(flow.direction == .any)
let provider = NEFilterDataProvider()
precondition(provider.handleNewFlow(flow) !== allow)
let dataVerdict = provider.handleInboundData(
    from: flow,
    readBytesStartOffset: 0,
    readBytes: Data([0x00])
)
_ = dataVerdict
provider.handleRulesChanged()

let report = NEFilterReport()
precondition(report.action == .invalid)
precondition(report.event == .newFlow)
provider.handle(report)
}

func testFilterProviderSurface() {
let browser = NEFilterBrowserFlow()
_ = browser.parentURL
_ = browser.request
_ = browser.response
let socket = NEFilterSocketFlow()
_ = socket.localEndpoint
_ = socket.remoteEndpoint
_ = socket.remoteHostname
_ = socket.socketFamily
_ = socket.socketProtocol
_ = socket.socketType
_ = socket.localFlowEndpoint
_ = socket.remoteFlowEndpoint
let filterFlow = NEFilterFlow()
_ = filterFlow.url
_ = filterFlow.sourceAppIdentifier
_ = filterFlow.sourceAppUniqueIdentifier
_ = filterFlow.sourceAppVersion
let report = NEFilterReport()
_ = report.bytesInboundCount
_ = report.bytesOutboundCount
_ = report.flow
NEFilterManager.shared().localizedDescription = "filter"
let filterConfig = NEFilterProviderConfiguration()
filterConfig.filterBrowsers = true
filterConfig.identityReference = Data([0x03])
filterConfig.passwordReference = Data([0x04])
filterConfig.serverAddress = "filter.example.invalid"
filterConfig.username = "filter"
filterConfig.vendorConfiguration = ["v": "1"]
let filterProvider = NEFilterProvider()
_ = filterProvider.filterConfiguration
let dataProvider = NEFilterDataProvider()
_ = dataProvider.handleInboundDataComplete(for: filterFlow)
_ = dataProvider.handleOutboundDataComplete(for: filterFlow)
_ = dataProvider.handleOutboundData(from: filterFlow, readBytesStartOffset: 0, readBytes: Data())
_ = dataProvider.handleRemediation(for: filterFlow)
let control = NEFilterControlProvider()
control.urlAppendStringMap = ["a": "b"]
control.remediationMap = ["r": ["k": "v" as NSString]]
control.notifyRulesChanged()
_ = NEFilterControlVerdict.allow(withUpdateRules: true)
_ = NEFilterControlVerdict.updateRules()
_ = NEFilterDataVerdict.allow()
_ = NEFilterDataVerdict.drop()
_ = NEFilterDataVerdict.needRules()
_ = NEFilterDataVerdict.remediateVerdict(
    withRemediationURLMapKey: "u",
    remediationButtonTextMapKey: "b"
)
_ = NEFilterNewFlowVerdict.urlAppendStringVerdict(withMapKey: "m")
_ = NEFilterNewFlowVerdict.drop()
_ = NEFilterNewFlowVerdict.filterDataVerdict(
    withFilterInbound: false,
    peekInboundBytes: 1,
    filterOutbound: false,
    peekOutboundBytes: 1
)
_ = NEFilterNewFlowVerdict.needRules()
_ = NEFilterNewFlowVerdict.remediateVerdict(
    withRemediationURLMapKey: "u",
    remediationButtonTextMapKey: "b"
)
_ = NEFilterRemediationVerdict.allow()
_ = NEFilterRemediationVerdict.needRules()
}
