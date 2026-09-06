import Foundation
import AVRouting

func testCustomRoutingPartialIPIsNSObjectSubclass() {
    let ip = AVCustomRoutingPartialIP(address: Data([10, 0, 0, 0]), mask: Data([255, 0, 0, 0]))
    let asObject: NSObject = ip
    precondition(asObject === ip)
    let other = AVCustomRoutingPartialIP(address: Data([10, 0, 0, 0]), mask: Data([255, 0, 0, 0]))
    precondition(ip !== other)
    precondition(ip != other)
}

func testCustomRoutingPartialIPInitCopiesAddressAndMask() {
    var address = Data([192, 168, 1, 0])
    var mask = Data([255, 255, 255, 0])
    let ip = AVCustomRoutingPartialIP(address: address, mask: mask)
    precondition(ip.address == Data([192, 168, 1, 0]))
    precondition(ip.mask == Data([255, 255, 255, 0]))
    address[0] = 10
    mask[0] = 0
    precondition(ip.address == Data([192, 168, 1, 0]))
    precondition(ip.mask == Data([255, 255, 255, 0]))
}

func testCustomRoutingPartialIPAddressGetter() {
    let ip = AVCustomRoutingPartialIP(
        address: Data([0x20, 0x01, 0x0d, 0xb8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        mask: Data(repeating: 0xFF, count: 8) + Data(repeating: 0, count: 8)
    )
    precondition(ip.address.count == 16)
    precondition(ip.address[0] == 0x20)
    precondition(ip.address[1] == 0x01)
    let empty = AVCustomRoutingPartialIP(address: Data(), mask: Data())
    precondition(ip.address != empty.address)
}

func testCustomRoutingPartialIPMaskGetter() {
    let ip = AVCustomRoutingPartialIP(
        address: Data([172, 16, 0, 0]),
        mask: Data([255, 240, 0, 0])
    )
    precondition(ip.mask == Data([255, 240, 0, 0]))
    precondition(ip.mask.count == 4)
    let other = AVCustomRoutingPartialIP(address: Data([172, 16, 0, 0]), mask: Data([255, 255, 0, 0]))
    precondition(ip.mask != other.mask)
}
