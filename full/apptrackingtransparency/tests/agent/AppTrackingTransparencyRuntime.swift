import AppTrackingTransparency
import Dispatch
import Foundation

func requireDenied(_ status: ATTrackingManager.AuthorizationStatus, _ label: String) {
    precondition(
        status == .denied,
        "\(label) must be denied, got \(status)"
    )
    precondition(status != .authorized, "\(label) must not be authorized")
    precondition(status != .notDetermined, "\(label) must not be pending")
    precondition(status != .restricted, "\(label) uses denied, not restricted")
}

func testAuthorizationStatusSurface() {
    let notDetermined = ATTrackingManager.AuthorizationStatus.notDetermined
    let restricted = ATTrackingManager.AuthorizationStatus.restricted
    let denied = ATTrackingManager.AuthorizationStatus.denied
    let authorized = ATTrackingManager.AuthorizationStatus.authorized

    precondition(notDetermined.rawValue == 0)
    precondition(restricted.rawValue == 1)
    precondition(denied.rawValue == 2)
    precondition(authorized.rawValue == 3)

    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 0) == .notDetermined)
    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 1) == .restricted)
    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 2) == .denied)
    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 3) == .authorized)
    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 4) == nil)
    precondition(ATTrackingManager.AuthorizationStatus(rawValue: 99) == nil)

    precondition(denied == .denied)
    precondition(denied != .authorized)
    precondition(denied != .restricted)
    precondition(denied != .notDetermined)
    precondition(!(denied != .denied))
    precondition(authorized != denied)

    var hasher = Hasher()
    denied.hash(into: &hasher)
    var hasher2 = Hasher()
    ATTrackingManager.AuthorizationStatus.denied.hash(into: &hasher2)
    precondition(hasher.finalize() == hasher2.finalize())

    let hashValue = denied.hashValue
    precondition(hashValue == ATTrackingManager.AuthorizationStatus.denied.hashValue)
    precondition(hashValue != authorized.hashValue)

    let unique = Set([notDetermined, restricted, denied, authorized, .denied])
    precondition(unique.count == 4)
}

func testTrackingAuthorizationStatusFailClosed() {
    let status = ATTrackingManager.trackingAuthorizationStatus
    requireDenied(status, "trackingAuthorizationStatus")
    precondition(status.rawValue == 2)
}

func testRequestTrackingAuthorizationCompletesDenied() {
    var callbacks = 0
    var received: ATTrackingManager.AuthorizationStatus?
    ATTrackingManager.requestTrackingAuthorization { status in
        callbacks += 1
        received = status
    }
    precondition(callbacks == 1, "completion must run exactly once")
    guard let received else {
        fatalError("completion did not deliver a status")
    }
    requireDenied(received, "requestTrackingAuthorization callback")
    precondition(received == ATTrackingManager.trackingAuthorizationStatus)
}

func testRequestTrackingAuthorizationAsyncFailClosed() async {
    let status = await ATTrackingManager.requestTrackingAuthorization()
    requireDenied(status, "requestTrackingAuthorization async")
    precondition(status == ATTrackingManager.trackingAuthorizationStatus)
}

func testManagerIdentity() {
    let manager: NSObject = ATTrackingManager()
    _ = String(describing: manager)
}

testAuthorizationStatusSurface()
testTrackingAuthorizationStatusFailClosed()
testRequestTrackingAuthorizationCompletesDenied()
testManagerIdentity()

let semaphore = DispatchSemaphore(value: 0)
Task {
    await testRequestTrackingAuthorizationAsyncFailClosed()
    semaphore.signal()
}
semaphore.wait()

print("APPTRACKINGTRANSPARENCY_AGENT_RUNTIME_OK")
