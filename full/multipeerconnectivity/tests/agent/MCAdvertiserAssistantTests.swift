@_spi(OpenUIKitHost) import MultipeerConnectivity
import Foundation

private final class AssistantRecordingDelegate: NSObject, MCAdvertiserAssistantDelegate {
    var willPresent = 0
    var didDismiss = 0

    func advertiserAssistantWillPresentInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        _ = advertiserAssistant
        willPresent += 1
    }

    func advertiserAssistantDidDismissInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        _ = advertiserAssistant
        didDismiss += 1
    }
}

func testMCAdvertiserAssistantConfiguration() {
    let peer = MCPeerID(displayName: "assistant")
    let session = MCSession(peer: peer)
    let assistant = MCAdvertiserAssistant(
        serviceType: "ou-xfer",
        discoveryInfo: ["role": "host"],
        session: session
    )
    precondition(assistant.session === session)
    precondition(assistant.serviceType == "ou-xfer")
    precondition(assistant.discoveryInfo?["role"] == "host")
    precondition(assistant.delegate == nil)
    let probe = AssistantRecordingDelegate()
    assistant.delegate = probe
    precondition(assistant.delegate === probe)
}

func testMCAdvertiserAssistantStartStopInert() {
    let peer = MCPeerID(displayName: "assistant")
    let session = MCSession(peer: peer)
    let assistant = MCAdvertiserAssistant(
        serviceType: "ou-xfer",
        discoveryInfo: nil,
        session: session
    )
    let probe = AssistantRecordingDelegate()
    assistant.delegate = probe
    assistant.start()
    assistant.stop()
    precondition(probe.willPresent == 0)
    precondition(probe.didDismiss == 0)
    precondition(session.connectedPeers.isEmpty)
}

func testMCAdvertiserAssistantWillPresentInvitation() {
    let peer = MCPeerID(displayName: "assistant")
    let session = MCSession(peer: peer)
    let assistant = MCAdvertiserAssistant(
        serviceType: "ou-xfer",
        discoveryInfo: nil,
        session: session
    )
    let probe = AssistantRecordingDelegate()
    let asExistential: any MCAdvertiserAssistantDelegate = probe
    asExistential.advertiserAssistantWillPresentInvitation(assistant)
    precondition(probe.willPresent == 1)
    assistant.start()
    precondition(probe.willPresent == 1)
}

func testMCAdvertiserAssistantDidDismissInvitation() {
    let peer = MCPeerID(displayName: "assistant")
    let session = MCSession(peer: peer)
    let assistant = MCAdvertiserAssistant(
        serviceType: "ou-xfer",
        discoveryInfo: nil,
        session: session
    )
    let probe = AssistantRecordingDelegate()
    let asExistential: any MCAdvertiserAssistantDelegate = probe
    asExistential.advertiserAssistantDidDismissInvitation(assistant)
    precondition(probe.didDismiss == 1)
    assistant.start()
    precondition(probe.didDismiss == 1)
}
