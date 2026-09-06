import Foundation
import AVRouting

final class RoutingRecordingDelegate: NSObject, AVCustomRoutingControllerDelegate, @unchecked Sendable {
    var handledEvents: [AVCustomRoutingEvent] = []
    var handleResult = false
    var timedOut: [AVCustomRoutingEvent] = []
    var selected: [AVCustomRoutingActionItem] = []

    func customRoutingController(
        _ controller: AVCustomRoutingController,
        handle event: AVCustomRoutingEvent,
        completionHandler: @escaping (Bool) -> Void
    ) {
        handledEvents.append(event)
        completionHandler(handleResult)
    }

    func customRoutingController(
        _ controller: AVCustomRoutingController,
        eventDidTimeOut event: AVCustomRoutingEvent
    ) {
        timedOut.append(event)
    }

    func customRoutingController(
        _ controller: AVCustomRoutingController,
        didSelect customActionItem: AVCustomRoutingActionItem
    ) {
        selected.append(customActionItem)
    }
}

func testCustomRoutingControllerDelegateConformance() {
    let delegate = RoutingRecordingDelegate()
    let asProtocol: any AVCustomRoutingControllerDelegate = delegate
    let controller = AVCustomRoutingController()
    controller.delegate = asProtocol
    precondition(controller.delegate === delegate)
    let asObject: NSObject = delegate
    precondition(asObject === delegate)
}

func testCustomRoutingControllerDelegateHandleCompletion() {
    let delegate = RoutingRecordingDelegate()
    delegate.handleResult = true
    let controller = AVCustomRoutingController()
    let route = AVCustomDeviceRoute()
    let event = AVCustomRoutingEvent(reason: .activate, route: route)
    var completions: [Bool] = []
    delegate.customRoutingController(controller, handle: event) { success in
        completions.append(success)
    }
    precondition(delegate.handledEvents.count == 1)
    precondition(delegate.handledEvents[0] === event)
    precondition(completions == [true])

    delegate.handleResult = false
    delegate.customRoutingController(controller, handle: event) { success in
        completions.append(success)
    }
    precondition(completions == [true, false])
    precondition(delegate.handledEvents.count == 2)
}

func testCustomRoutingControllerDelegateEventDidTimeOut() {
    let delegate = RoutingRecordingDelegate()
    let controller = AVCustomRoutingController()
    let event = AVCustomRoutingEvent(reason: .deactivate, route: AVCustomDeviceRoute())
    precondition(delegate.timedOut.isEmpty)
    delegate.customRoutingController(controller, eventDidTimeOut: event)
    precondition(delegate.timedOut.count == 1)
    precondition(delegate.timedOut[0] === event)
    controller.delegate = delegate
    precondition(delegate.timedOut.count == 1)
}

func testCustomRoutingControllerDelegateDidSelect() {
    let delegate = RoutingRecordingDelegate()
    let controller = AVCustomRoutingController()
    let item = AVCustomRoutingActionItem()
    item.overrideTitle = "Pair"
    precondition(delegate.selected.isEmpty)
    delegate.customRoutingController(controller, didSelect: item)
    precondition(delegate.selected.count == 1)
    precondition(delegate.selected[0] === item)
    precondition(delegate.selected[0].overrideTitle == "Pair")
}

final class RoutingDefaultDelegate: NSObject, AVCustomRoutingControllerDelegate, @unchecked Sendable {
    func customRoutingController(
        _ controller: AVCustomRoutingController,
        handle event: AVCustomRoutingEvent,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(false)
    }
}

func testCustomRoutingControllerDelegateOptionalDefaults() {
    let delegate = RoutingDefaultDelegate()
    let controller = AVCustomRoutingController()
    let event = AVCustomRoutingEvent(reason: .reactivate, route: AVCustomDeviceRoute())
    let item = AVCustomRoutingActionItem()
    delegate.customRoutingController(controller, eventDidTimeOut: event)
    delegate.customRoutingController(controller, didSelect: item)
    var called = false
    delegate.customRoutingController(controller, handle: event) { success in
        called = true
        precondition(success == false)
    }
    precondition(called)
}
