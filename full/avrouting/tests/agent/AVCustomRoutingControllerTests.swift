import Foundation
import AVRouting

func testCustomRoutingControllerIsNSObjectSubclass() {
    let controller = AVCustomRoutingController()
    let asObject: NSObject = controller
    precondition(asObject === controller)
    let other = AVCustomRoutingController()
    precondition(controller !== other)
    precondition(controller != other)
}

func testCustomRoutingControllerAuthorizedRoutesAlwaysEmpty() {
    let controller = AVCustomRoutingController()
    precondition(controller.authorizedRoutes.isEmpty)
    let route = AVCustomDeviceRoute(bluetoothIdentifier: UUID())
    controller.setActive(true, for: route)
    precondition(controller.authorizedRoutes.isEmpty)
    controller.knownRouteIPs = [
        AVCustomRoutingPartialIP(address: Data([10, 0, 0, 0]), mask: Data([255, 0, 0, 0]))
    ]
    precondition(controller.authorizedRoutes.isEmpty)
}

func testCustomRoutingControllerKnownRouteIPsRoundTrip() {
    let controller = AVCustomRoutingController()
    precondition(controller.knownRouteIPs.isEmpty)
    let first = AVCustomRoutingPartialIP(address: Data([192, 168, 0, 0]), mask: Data([255, 255, 0, 0]))
    let second = AVCustomRoutingPartialIP(address: Data([10, 0, 0, 0]), mask: Data([255, 0, 0, 0]))
    controller.knownRouteIPs = [first, second]
    precondition(controller.knownRouteIPs.count == 2)
    precondition(controller.knownRouteIPs[0] === first)
    precondition(controller.knownRouteIPs[1] === second)
    controller.knownRouteIPs = []
    precondition(controller.knownRouteIPs.isEmpty)
}

func testCustomRoutingControllerCustomActionItemsRoundTrip() {
    let controller = AVCustomRoutingController()
    precondition(controller.customActionItems.isEmpty)
    let item = AVCustomRoutingActionItem()
    item.overrideTitle = "Setup"
    controller.customActionItems = [item]
    precondition(controller.customActionItems.count == 1)
    precondition(controller.customActionItems[0] === item)
    precondition(controller.customActionItems[0].overrideTitle == "Setup")
    controller.customActionItems = [item, AVCustomRoutingActionItem()]
    precondition(controller.customActionItems.count == 2)
}

func testCustomRoutingControllerDelegateWeak() {
    let controller = AVCustomRoutingController()
    precondition(controller.delegate == nil)
    do {
        let delegate = RoutingRecordingDelegate()
        controller.delegate = delegate
        precondition(controller.delegate === delegate)
        controller.delegate = nil
        precondition(controller.delegate == nil)
        controller.delegate = delegate
        precondition(controller.delegate === delegate)
    }
    precondition(controller.delegate == nil)
}

func testCustomRoutingControllerSetActiveProcessLocal() {
    let controller = AVCustomRoutingController()
    let route = AVCustomDeviceRoute()
    precondition(!controller.isRouteActive(route))
    controller.setActive(true, for: route)
    precondition(controller.isRouteActive(route))
    controller.setActive(true, for: route)
    precondition(controller.isRouteActive(route))
    controller.setActive(false, for: route)
    precondition(!controller.isRouteActive(route))
    let other = AVCustomDeviceRoute()
    controller.setActive(true, for: route)
    precondition(!controller.isRouteActive(other))
    precondition(controller.isRouteActive(route))
}

func testCustomRoutingControllerIsRouteActiveIndependentIdentities() {
    let controller = AVCustomRoutingController()
    let a = AVCustomDeviceRoute(bluetoothIdentifier: UUID())
    let b = AVCustomDeviceRoute(bluetoothIdentifier: a.bluetoothIdentifier)
    controller.setActive(true, for: a)
    precondition(controller.isRouteActive(a))
    precondition(!controller.isRouteActive(b))
}

func testCustomRoutingControllerInvalidateAuthorizationClearsActive() {
    let controller = AVCustomRoutingController()
    let route = AVCustomDeviceRoute()
    let other = AVCustomDeviceRoute()
    controller.setActive(true, for: route)
    controller.setActive(true, for: other)
    controller.invalidateAuthorization(for: route)
    precondition(!controller.isRouteActive(route))
    precondition(controller.isRouteActive(other))
    controller.invalidateAuthorization(for: route)
    precondition(!controller.isRouteActive(route))
}

func testCustomRoutingControllerAuthorizedRoutesDidChangeName() {
    let name = AVCustomRoutingController.authorizedRoutesDidChange
    precondition(name.rawValue == "AVCustomRoutingControllerAuthorizedRoutesDidChangeNotification")
    precondition(name == NSNotification.Name("AVCustomRoutingControllerAuthorizedRoutesDidChangeNotification"))
    let other = NSNotification.Name("AVCustomRoutingControllerActiveRoutesDidChangeNotification")
    precondition(name != other)

    let controller = AVCustomRoutingController()
    final class PostCounter: NSObject {
        var count = 0
    }
    let counter = PostCounter()
    let observer = NotificationCenter.default.addObserver(
        forName: AVCustomRoutingController.authorizedRoutesDidChange,
        object: controller,
        queue: nil
    ) { _ in
        counter.count += 1
    }
    let route = AVCustomDeviceRoute()
    controller.setActive(true, for: route)
    controller.invalidateAuthorization(for: route)
    controller.customActionItems = [AVCustomRoutingActionItem()]
    controller.knownRouteIPs = [
        AVCustomRoutingPartialIP(address: Data([1, 2, 3, 4]), mask: Data([255, 255, 255, 255]))
    ]
    NotificationCenter.default.removeObserver(observer)
    precondition(counter.count == 0)
}
