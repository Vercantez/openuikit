import Foundation
import AVRouting

func testCustomDeviceRouteIsNSObjectSubclass() {
    let route = AVCustomDeviceRoute()
    let asObject: NSObject = route
    precondition(asObject === route)
    let same = route
    precondition(route == same)
    precondition(route === same)
    let other = AVCustomDeviceRoute()
    precondition(route !== other)
    precondition(route != other)
}

func testCustomDeviceRouteBluetoothIdentifierNilByDefault() {
    let route = AVCustomDeviceRoute()
    precondition(route.bluetoothIdentifier == nil)
    let again = AVCustomDeviceRoute(bluetoothIdentifier: nil)
    precondition(again.bluetoothIdentifier == nil)
}

func testCustomDeviceRouteBluetoothIdentifierStored() {
    let uuid = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
    let route = AVCustomDeviceRoute(bluetoothIdentifier: uuid)
    precondition(route.bluetoothIdentifier == uuid)
    precondition(route.bluetoothIdentifier?.uuidString == "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
    let other = UUID()
    let otherRoute = AVCustomDeviceRoute(bluetoothIdentifier: uuid)
    precondition(otherRoute.bluetoothIdentifier == uuid)
    precondition(otherRoute.bluetoothIdentifier != other)
}

func testCustomDeviceRouteNetworkEndpointAlwaysNil() {
    let empty = AVCustomDeviceRoute()
    precondition(empty.networkEndpoint == nil)
    let tagged = AVCustomDeviceRoute(bluetoothIdentifier: UUID())
    precondition(tagged.networkEndpoint == nil)
}
