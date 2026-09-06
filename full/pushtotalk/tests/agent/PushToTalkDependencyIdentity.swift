import Foundation
import PushToTalk

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public PushToTalk APIs.
func pushToTalkDependencyIdentityProbe() {
    let domain: String = PTChannelErrorDomain
    precondition(domain == "PTChannelErrorDomain")

    let info: [String: Any] = ["foundation": UUID().uuidString]
    let error = PTChannelError(.channelNotFound, userInfo: info)
    precondition(error.userInfo["foundation"] as? String == info["foundation"] as? String)
    let ns = error as NSError
    precondition(ns.domain == PTChannelErrorDomain)
    precondition(ns.code == PTChannelError.Code.channelNotFound.rawValue)

    let name = "identity-channel"
    let descriptor = PTChannelDescriptor(name: name, image: nil)
    precondition(descriptor.name == name)

    let participant = PTParticipant(name: "identity-user", image: nil)
    precondition(participant.name == "identity-user")

    let instantiation = PTInstantiationError(
        .invalidPlatform,
        userInfo: ["uuid": UUID().uuidString]
    )
    precondition(instantiation.errorCode == 1)
    let instantiationNS = instantiation as NSError
    precondition(instantiationNS.domain == PTInstantiationErrorDomain)
}
