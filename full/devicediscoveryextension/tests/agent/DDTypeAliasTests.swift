import DeviceDiscoveryExtension
import Foundation

func testDDErrorHandlerTypealias() {
    var captured: (any Error)? = DDError(.unsupported)
    let handler: DDErrorHandler = { error in
        captured = error
    }
    handler(DDError(.missingEntitlement))
    let typed = captured as? DDError
    ddExpect(typed?.code == .missingEntitlement, "handler stored error")
    handler(nil)
    ddExpect(captured == nil, "nil success path")
}

func testDDEventHandlerTypealias() {
    let device = DDDevice(
        displayName: "Z",
        category: .hifiSpeaker,
        protocolType: UTType("public.item"),
        identifier: "z"
    )
    var seen: DDDeviceEvent?
    let handler: DDEventHandler = { event in
        seen = event
    }
    let event = DDDeviceEvent(eventType: .deviceFound, device: device)
    handler(event)
    ddExpect(seen === event, "same event")
}

func testDDErrorOutTypealias() {
    var boxed: NSError? = DDError(.permission) as NSError
    let passed: DDErrorOutType = withUnsafeMutablePointer(to: &boxed) { $0 }
    ddExpect(passed.pointee?.domain == DDErrorDomain, "out pointer domain")
    ddExpect(passed.pointee?.code == DDError.Code.permission.rawValue, "out pointer code")
    passed.pointee = nil
    ddExpect(boxed == nil, "cleared through alias")
}
