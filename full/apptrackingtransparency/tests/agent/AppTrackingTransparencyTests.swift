import Foundation
@_spi(OpenUIKitHost) import AppTrackingTransparency

/// Linux fail-closed `ATTrackingManager.AuthorizationStatus` surface.
/// Raw values 0...3 match the public sequential `NS_ENUM`; tracking is
/// never authorized on Linux.

func testAuthorizationStatusRawValues() {
    typealias Status = ATTrackingManager.AuthorizationStatus
    let table: [(Status, UInt)] = [
        (.notDetermined, 0),
        (.restricted, 1),
        (.denied, 2),
        (.authorized, 3),
    ]
    precondition(Status.self == ATTrackingManager.AuthorizationStatus.self)
    for (status, raw) in table {
        precondition(status.rawValue == raw)
        precondition(Status(rawValue: raw) == status)
    }
}

func testAuthorizedCaseConstructible() {
    let status = ATTrackingManager.AuthorizationStatus.authorized
    precondition(status.rawValue == 3)
    precondition(status == ATTrackingManager.AuthorizationStatus(rawValue: 3))
    precondition(ATTrackingManager.trackingAuthorizationStatus != status)
}

func testDeniedCaseFailClosed() {
    let status = ATTrackingManager.AuthorizationStatus.denied
    precondition(status.rawValue == 2)
    precondition(status == ATTrackingManager.AuthorizationStatus(rawValue: 2))
    precondition(ATTrackingManager.trackingAuthorizationStatus == status)
}

func testNotDeterminedCaseConstructible() {
    let status = ATTrackingManager.AuthorizationStatus.notDetermined
    precondition(status.rawValue == 0)
    precondition(status == ATTrackingManager.AuthorizationStatus(rawValue: 0))
    precondition(ATTrackingManager.trackingAuthorizationStatus != status)
}

func testRestrictedCaseConstructible() {
    let status = ATTrackingManager.AuthorizationStatus.restricted
    precondition(status.rawValue == 1)
    precondition(status == ATTrackingManager.AuthorizationStatus(rawValue: 1))
    precondition(ATTrackingManager.trackingAuthorizationStatus != status)
}

func testManagerIdentity() {
    let manager = ATTrackingManager()
    let asObject: NSObject = manager
    precondition(asObject === manager)
    precondition(type(of: manager) == ATTrackingManager.self)
}

func testTrackingStatusAlwaysDenied() {
    precondition(ATTrackingManager.trackingAuthorizationStatus == .denied)
    precondition(ATTrackingManager.trackingAuthorizationStatus.rawValue == 2)
    precondition(ATTrackingManager.trackingAuthorizationStatus != .authorized)
    precondition(ATTrackingManager.trackingAuthorizationStatus != .notDetermined)
    precondition(ATTrackingManager.trackingAuthorizationStatus != .restricted)
}

func testRequestCallbackDeliversDenied() async {
    let status = await withCheckedContinuation { continuation in
        ATTrackingManager.requestTrackingAuthorization(completionHandler: { result in
            continuation.resume(returning: result)
        })
    }
    precondition(status == .denied)
    precondition(status.rawValue == 2)
}

func testRequestAsyncOverlayDenied() async {
    let status = await ATTrackingManager.requestTrackingAuthorization()
    precondition(status == .denied)
    precondition(ATTrackingManager.trackingAuthorizationStatus == .denied)
}

func testStatusInequality() {
    typealias Status = ATTrackingManager.AuthorizationStatus
    precondition(Status.notDetermined != Status.denied)
    precondition(Status.restricted != Status.authorized)
    precondition(!(Status.denied != Status.denied))
    precondition(Status.denied == Status(rawValue: 2))
}

func testStatusHashValue() {
    typealias Status = ATTrackingManager.AuthorizationStatus
    precondition(Status.denied.hashValue == Status.denied.hashValue)
    let fromRaw = Status(rawValue: 2)!
    precondition(Status.denied.hashValue == fromRaw.hashValue)
    var seen: Set<Int> = []
    for status in [Status.notDetermined, .restricted, .denied, .authorized] {
        seen.insert(status.hashValue)
    }
    precondition(!seen.isEmpty)
}

func testStatusHashInto() {
    typealias Status = ATTrackingManager.AuthorizationStatus
    var hasher = Hasher()
    Status.denied.hash(into: &hasher)
    Status.authorized.hash(into: &hasher)
    _ = hasher.finalize()
    var set: Set<Status> = []
    for status in [Status.notDetermined, .restricted, .denied, .authorized] {
        set.insert(status)
    }
    precondition(set.count == 4)
    precondition(set.contains(.denied))
}

func testStatusRawValueInit() {
    typealias Status = ATTrackingManager.AuthorizationStatus
    precondition(Status(rawValue: 0) == .notDetermined)
    precondition(Status(rawValue: 1) == .restricted)
    precondition(Status(rawValue: 2) == .denied)
    precondition(Status(rawValue: 3) == .authorized)
    precondition(Status(rawValue: 4) == nil)
    precondition(Status(rawValue: 99) == nil)
}
