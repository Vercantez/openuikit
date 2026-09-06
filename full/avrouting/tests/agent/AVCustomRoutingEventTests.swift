import Foundation
import AVRouting

func testCustomRoutingEventIsNSObjectSubclass() {
    let route = AVCustomDeviceRoute()
    let event = AVCustomRoutingEvent(reason: .activate, route: route)
    let asObject: NSObject = event
    precondition(asObject === event)
    let other = AVCustomRoutingEvent(reason: .activate, route: route)
    precondition(event !== other)
    precondition(event != other)
}

func testCustomRoutingEventReasonStored() {
    let route = AVCustomDeviceRoute()
    let activate = AVCustomRoutingEvent(reason: .activate, route: route)
    precondition(activate.reason == .activate)
    let deactivate = AVCustomRoutingEvent(reason: .deactivate, route: route)
    precondition(deactivate.reason == .deactivate)
    let reactivate = AVCustomRoutingEvent(reason: .reactivate, route: route)
    precondition(reactivate.reason == .reactivate)
    precondition(activate.reason != deactivate.reason)
}

func testCustomRoutingEventRouteIdentity() {
    let route = AVCustomDeviceRoute(bluetoothIdentifier: UUID())
    let event = AVCustomRoutingEvent(reason: .activate, route: route)
    precondition(event.route === route)
    precondition(event.route.bluetoothIdentifier == route.bluetoothIdentifier)
    let other = AVCustomDeviceRoute()
    let otherEvent = AVCustomRoutingEvent(reason: .deactivate, route: other)
    precondition(otherEvent.route === other)
    precondition(otherEvent.route !== route)
}
