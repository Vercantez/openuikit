@_spi(OpenUIKitHost) import GroupActivities
import Foundation

struct ProbeActivity: GroupActivity, Equatable {
    var label: String

    var metadata: GroupActivityMetadata {
        get async { GroupActivityMetadata() }
    }
}

struct ProbeMessage: Codable, Equatable {
    var text: String
}

struct ProbeMessageIdentity: CustomMessageIdentifiable {
    static var messageIdentifier: String { "probe.message" }
}

func gaRequire(_ value: Bool, _ message: String) {
    if !value {
        fatalError(message)
    }
}

func gaHostError(_ error: (any Error)?) -> GroupActivitiesHostError {
    guard let typed = error as? GroupActivitiesHostError else {
        fatalError("expected GroupActivitiesHostError, got \(String(describing: error))")
    }
    return typed
}

func gaMakeSession(
    label: String = "probe",
    id: UUID = UUID(),
    locallyInitiated: Bool = true
) -> GroupSession<ProbeActivity> {
    GroupSession<ProbeActivity>.makeHostSession(
        activity: ProbeActivity(label: label),
        id: id,
        locallyInitiated: locallyInitiated
    )
}

func testHostErrorCodes() {
    gaRequire(GroupActivitiesHostError.errorDomain == "GroupActivities.GroupActivitiesHostError", "domain")
    gaRequire(GroupActivitiesHostError.sharePlayUnavailable.code == 1, "sharePlay")
    gaRequire(GroupActivitiesHostError.sessionLeft.code == 2, "left")
    gaRequire(GroupActivitiesHostError.sessionEnded.code == 3, "ended")
    gaRequire(GroupActivitiesHostError.nearbyUnavailable.code == 4, "nearby")
    gaRequire(GroupActivitiesHostError.journalUnavailable.code == 5, "journal")
    gaRequire(GroupActivitiesHostError.messengerUnavailable.code == 6, "messenger")
    gaRequire(GroupActivitiesHostError.sharePlayUnavailable.errorCode == 1, "errorCode")
    gaRequire(GroupActivitiesHostError.sharePlayUnavailable.errorUserInfo.isEmpty, "userInfo")
    gaRequire(GroupActivitiesHostError.sharePlayUnavailable.failureReason != nil, "reason")
    gaRequire(
        GroupActivitiesHostError.sharePlayUnavailable.errorDescription
            == GroupActivitiesHostError.sharePlayUnavailable.failureReason,
        "description"
    )
    gaRequire(
        GroupActivitiesHostError.sharePlayUnavailable != .sessionLeft,
        "distinct errors"
    )
}
