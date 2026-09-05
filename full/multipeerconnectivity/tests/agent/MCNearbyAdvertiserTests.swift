@_spi(OpenUIKitHost) import MultipeerConnectivity
import Foundation

private final class AdvertiserRecordingDelegate: NSObject, MCNearbyServiceAdvertiserDelegate {
    var startErrors: [any Error] = []
    var invitations: [(MCPeerID, Data?)] = []
    var invitationAccepts: [Bool] = []

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        _ = advertiser
        invitations.append((peerID, context))
        invitationHandler(false, nil)
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        _ = advertiser
        startErrors.append(error)
    }
}

func testMCNearbyServiceAdvertiserConfiguration() {
    let peer = MCPeerID(displayName: "advertiser")
    let info = ["k": "v"]
    let advertiser = MCNearbyServiceAdvertiser(
        peer: peer,
        discoveryInfo: info,
        serviceType: "ou-xfer"
    )
    precondition(advertiser.myPeerID === peer)
    precondition(advertiser.discoveryInfo?["k"] == "v")
    precondition(advertiser.serviceType == "ou-xfer")
    precondition(advertiser.delegate == nil)
    let probe = AdvertiserRecordingDelegate()
    advertiser.delegate = probe
    precondition(advertiser.delegate === probe)
}

func testMCNearbyServiceAdvertiserStartFailsUnavailable() {
    let peer = MCPeerID(displayName: "advertiser")
    let advertiser = MCNearbyServiceAdvertiser(
        peer: peer,
        discoveryInfo: nil,
        serviceType: "ou-xfer"
    )
    let probe = AdvertiserRecordingDelegate()
    advertiser.delegate = probe
    advertiser.startAdvertisingPeer()
    precondition(probe.startErrors.count == 1)
    precondition(MCError.Code.unavailable ~= probe.startErrors[0])
    advertiser.stopAdvertisingPeer()
    precondition(probe.startErrors.count == 1)
}

func testMCNearbyServiceAdvertiserInvitationHandler() {
    let peer = MCPeerID(displayName: "advertiser")
    let remote = MCPeerID(displayName: "invitee")
    let advertiser = MCNearbyServiceAdvertiser(
        peer: peer,
        discoveryInfo: nil,
        serviceType: "ou-xfer"
    )
    let probe = AdvertiserRecordingDelegate()
    let asExistential: any MCNearbyServiceAdvertiserDelegate = probe
    asExistential.advertiser(
        advertiser,
        didReceiveInvitationFromPeer: remote,
        withContext: Data([3]),
        invitationHandler: { accept, session in
            probe.invitationAccepts.append(accept)
            precondition(session == nil)
        }
    )
    precondition(probe.invitations.count == 1)
    precondition(probe.invitations[0].0 === remote)
    precondition(probe.invitations[0].1 == Data([3]))
    precondition(probe.invitationAccepts == [false])
    advertiser.startAdvertisingPeer()
    precondition(probe.invitations.count == 1)
}
