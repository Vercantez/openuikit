@_spi(OpenUIKitHost) import GroupActivities
import Foundation

func testSceneAssociationBehaviorValues() {
    gaRequire(SceneAssociationBehavior.none == .none, "none")
    gaRequire(SceneAssociationBehavior.default == .default, "default")
    gaRequire(
        SceneAssociationBehavior.content("alpha") == .content("alpha"),
        "content identity"
    )
    gaRequire(SceneAssociationBehavior.none != .default, "none != default")
    gaRequire(SceneAssociationBehavior.content("a") != .content("b"), "content !=")
    gaRequire(SceneAssociationBehavior.content("a") != .none, "content != none")
}

func testSceneAssociationBehaviorHashable() {
    var hasher = Hasher()
    SceneAssociationBehavior.default.hash(into: &hasher)
    gaRequire(
        SceneAssociationBehavior.default.hashValue == SceneAssociationBehavior.default.hashValue,
        "hashValue"
    )
}

func testActivationResultCases() {
    let cases: [GroupActivityActivationResult] = [
        .activationDisabled,
        .activationPreferred,
        .cancelled,
    ]
    gaRequire(Set(cases).count == 3, "three results")
    gaRequire(GroupActivityActivationResult.activationDisabled == .activationDisabled, "==")
    gaRequire(
        GroupActivityActivationResult.activationPreferred != .cancelled,
        "activation !="
    )
    var hasher = Hasher()
    GroupActivityActivationResult.cancelled.hash(into: &hasher)
    gaRequire(
        GroupActivityActivationResult.cancelled.hashValue
            == GroupActivityActivationResult.cancelled.hashValue,
        "hashValue"
    )
}

func testSharingResultCases() {
    gaRequire(GroupActivitySharingResult.success == .success, "success")
    gaRequire(GroupActivitySharingResult.cancelled == .cancelled, "cancelled")
    gaRequire(GroupActivitySharingResult.success != .cancelled, "sharing !=")
    var hasher = Hasher()
    GroupActivitySharingResult.success.hash(into: &hasher)
    gaRequire(
        GroupActivitySharingResult.success.hashValue
            == GroupActivitySharingResult.success.hashValue,
        "hashValue"
    )
}

func testDeliveryModeCases() {
    gaRequire(GroupSessionMessenger.DeliveryMode.reliable == .reliable, "reliable")
    gaRequire(GroupSessionMessenger.DeliveryMode.unreliable == .unreliable, "unreliable")
    gaRequire(
        GroupSessionMessenger.DeliveryMode.reliable != .unreliable,
        "delivery !="
    )
    var hasher = Hasher()
    GroupSessionMessenger.DeliveryMode.reliable.hash(into: &hasher)
    gaRequire(
        GroupSessionMessenger.DeliveryMode.reliable.hashValue
            == GroupSessionMessenger.DeliveryMode.reliable.hashValue,
        "hashValue"
    )
}

func testCustomMessageIdentifiable() {
    gaRequire(ProbeMessageIdentity.messageIdentifier == "probe.message", "identifier")
}
