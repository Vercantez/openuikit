import Foundation
import AVRouting

func testCustomRoutingActionItemIsNSObjectSubclass() {
    let item = AVCustomRoutingActionItem()
    let asObject: NSObject = item
    precondition(asObject === item)
    let other = AVCustomRoutingActionItem()
    precondition(item !== other)
    precondition(item != other)
}

func testCustomRoutingActionItemOverrideTitleRoundTrip() {
    let item = AVCustomRoutingActionItem()
    precondition(item.overrideTitle == nil)
    item.overrideTitle = "AirPlay Speaker"
    precondition(item.overrideTitle == "AirPlay Speaker")
    item.overrideTitle = ""
    precondition(item.overrideTitle == "")
    item.overrideTitle = nil
    precondition(item.overrideTitle == nil)
}

func testCustomRoutingActionItemTypeRoundTrip() {
    let item = AVCustomRoutingActionItem()
    precondition(item.type.identifier.isEmpty)
    let speaker = UTType(identifier: "com.example.speaker")
    item.type = speaker
    precondition(item.type == speaker)
    precondition(item.type.identifier == "com.example.speaker")
    item.type = UTType(identifier: "public.item")
    precondition(item.type.identifier == "public.item")
    precondition(item.type != speaker)
}
