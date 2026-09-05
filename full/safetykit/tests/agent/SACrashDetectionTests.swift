import Foundation
import SafetyKit

private final class RecordingCrashDelegate: NSObject, SACrashDetectionDelegate {
    var events: [SACrashDetectionEvent] = []

    func crashDetectionManager(
        _ crashDetectionManager: SACrashDetectionManager,
        didDetect event: SACrashDetectionEvent
    ) {
        _ = crashDetectionManager
        events.append(event)
    }
}

private final class EmptyCrashDelegate: NSObject, SACrashDetectionDelegate {}

func testSACrashDetectionEventResponseRawValues() {
    typealias Response = SACrashDetectionEvent.Response
    precondition(Response.attempted.rawValue == 0)
    precondition(Response.disabled.rawValue == 1)
    precondition(Response(rawValue: 0) == .attempted)
    precondition(Response(rawValue: 1) == .disabled)
    precondition(Response(rawValue: 2) == nil)
    precondition(Response(rawValue: -1) == nil)
}

func testSACrashDetectionEventResponseInequality() {
    precondition(SACrashDetectionEvent.Response.attempted != .disabled)
    precondition(!(SACrashDetectionEvent.Response.disabled != .disabled))
}

func testSACrashDetectionEventResponseHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    SACrashDetectionEvent.Response.attempted.hash(into: &hasherA)
    SACrashDetectionEvent.Response.attempted.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        SACrashDetectionEvent.Response.attempted.hashValue !=
            SACrashDetectionEvent.Response.disabled.hashValue
    )
}

func testSACrashDetectionEventHostMakeStoresProperties() {
    let date = Date(timeIntervalSince1970: 42)
    let event = SACrashDetectionEvent.host_makeEvent(date: date, response: .attempted)
    precondition(type(of: event) == SACrashDetectionEvent.self)
    let asObject: NSObject = event
    precondition(asObject === event)
}

func testSACrashDetectionEventDate() {
    let date = Date(timeIntervalSince1970: 1_234)
    let event = SACrashDetectionEvent.host_makeEvent(date: date, response: .disabled)
    precondition(event.date == date)
    precondition(event.date.timeIntervalSince1970 == 1_234)
}

func testSACrashDetectionEventResponseProperty() {
    let attempted = SACrashDetectionEvent.host_makeEvent(date: Date(), response: .attempted)
    precondition(attempted.response == .attempted)
    let disabled = SACrashDetectionEvent.host_makeEvent(date: Date(), response: .disabled)
    precondition(disabled.response == .disabled)
}

func testSACrashDetectionEventLocation() {
    let withoutLocation = SACrashDetectionEvent.host_makeEvent(
        date: Date(),
        response: .attempted,
        location: nil
    )
    precondition(withoutLocation.location == nil)

    let coordinate = CLLocation(latitude: 37.334, longitude: -122.009)
    let withLocation = SACrashDetectionEvent.host_makeEvent(
        date: Date(),
        response: .attempted,
        location: coordinate
    )
    precondition(withLocation.location === coordinate)
    precondition(withLocation.location?.latitude == 37.334)
    precondition(withLocation.location?.longitude == -122.009)
}

func testSACrashDetectionEventInitCoder() {
    let date = Date(timeIntervalSince1970: 99)
    let original = SACrashDetectionEvent.host_makeEvent(
        date: date,
        response: .disabled,
        location: CLLocation(latitude: 1.5, longitude: 2.5)
    )
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: SACrashDetectionEvent.self,
        from: data
    )
    precondition(decoded != nil)
    precondition(decoded?.date == date)
    precondition(decoded?.response == .disabled)
    precondition(decoded?.location?.latitude == 1.5)
    precondition(decoded?.location?.longitude == 2.5)

    let empty = NSKeyedUnarchiver(forReadingWith: Data())
    empty.requiresSecureCoding = true
    precondition(SACrashDetectionEvent(coder: empty) == nil)
}

func testSACrashDetectionManagerConstructible() {
    let manager = SACrashDetectionManager()
    precondition(type(of: manager) == SACrashDetectionManager.self)
    let asObject: NSObject = manager
    precondition(asObject === manager)
}

func testSACrashDetectionManagerIsAvailableFalse() {
    precondition(SACrashDetectionManager.isAvailable == false)
}

func testSACrashDetectionManagerAuthorizationStatusNotDetermined() {
    let manager = SACrashDetectionManager()
    precondition(manager.authorizationStatus == .notDetermined)
    manager.requestAuthorization { _, _ in }
    precondition(manager.authorizationStatus == .notDetermined)
}

func testSACrashDetectionManagerRequestAuthorizationFailClosed() {
    let manager = SACrashDetectionManager()
    var calls = 0
    var status: SAAuthorizationStatus?
    var error: (any Error)?
    manager.requestAuthorization { receivedStatus, receivedError in
        calls += 1
        status = receivedStatus
        error = receivedError
    }
    precondition(calls == 1)
    precondition(status == .notDetermined)
    let saError = error as? SAError
    precondition(saError?.code == .notAllowed)
    precondition(saError?.errorCode == 2)
    precondition(SAError.Code.notAllowed ~= (error!))
}

func testSACrashDetectionManagerDelegateRoundTrip() {
    let manager = SACrashDetectionManager()
    precondition(manager.delegate == nil)
    let delegate = RecordingCrashDelegate()
    manager.delegate = delegate
    precondition(manager.delegate === delegate)
    manager.delegate = nil
    precondition(manager.delegate == nil)
}

func testSACrashDetectionDelegateConformance() {
    let empty: any SACrashDetectionDelegate = EmptyCrashDelegate()
    let recording: any SACrashDetectionDelegate = RecordingCrashDelegate()
    _ = (empty, recording)
}

func testSACrashDetectionDelegateDidDetect() {
    let manager = SACrashDetectionManager()
    let delegate = RecordingCrashDelegate()
    manager.delegate = delegate
    let event = SACrashDetectionEvent.host_makeEvent(date: Date(), response: .attempted)
    manager.requestAuthorization { _, _ in }
    precondition(delegate.events.isEmpty)
    manager.host_deliverDetectedEvent(event)
    precondition(delegate.events.count == 1)
    precondition(delegate.events[0] === event)
}