@_spi(OpenUIKitHost) import MultipeerConnectivity
import Foundation

func testMCPeerIDDisplayName() {
    let peer = MCPeerID(displayName: "linux-peer")
    precondition(peer.displayName == "linux-peer")
    precondition(peer === peer)
    let other = MCPeerID(displayName: "linux-peer")
    precondition(peer !== other)
    precondition(type(of: peer) == MCPeerID.self)
}

func testMCPeerIDSecureCodingFailsClosed() {
    let peer = MCPeerID(displayName: "archive-peer")
    precondition(MCPeerID.supportsSecureCoding)
    let coder = NSKeyedArchiver(requiringSecureCoding: true)
    peer.encode(with: coder)
    let data = coder.encodedData
    let decoder = try! NSKeyedUnarchiver(forReadingFrom: data)
    decoder.requiresSecureCoding = true
    precondition(MCPeerID(coder: decoder) == nil)
}
