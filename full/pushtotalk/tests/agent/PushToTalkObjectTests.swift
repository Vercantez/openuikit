@_spi(OpenUIKitHost) import PushToTalk
import Foundation

func testPTChannelDescriptorInit() {
    let image = NSObject()
    let descriptor = PTChannelDescriptor(name: "Ops", image: image)
    precondition(descriptor.name == "Ops")
    precondition(descriptor.image === image)

    let namelessImage = PTChannelDescriptor(name: "Silent", image: nil)
    precondition(namelessImage.name == "Silent")
    precondition(namelessImage.image == nil)
}

func testPTParticipantInit() {
    let image = NSObject()
    let participant = PTParticipant(name: "Alex", image: image)
    precondition(participant.name == "Alex")
    precondition(participant.image === image)

    let noImage = PTParticipant(name: "Blair", image: nil)
    precondition(noImage.name == "Blair")
    precondition(noImage.image == nil)
}

func testPTPushResultLeaveChannel() {
    let result = PTPushResult.leaveChannel
    precondition(result.hostLeavesChannel)
    precondition(result.hostActiveParticipant == nil)
    precondition(PTPushResult.leaveChannel === result)
}

func testPTPushResultActiveRemoteParticipant() {
    let participant = PTParticipant(name: "Casey", image: nil)
    let result = PTPushResult.activeRemoteParticipant(participant)
    precondition(!result.hostLeavesChannel)
    precondition(result.hostActiveParticipant === participant)
    precondition(result !== PTPushResult.leaveChannel)
}
