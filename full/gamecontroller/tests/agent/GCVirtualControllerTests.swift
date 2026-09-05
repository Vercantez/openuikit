import Foundation
import Dispatch
import GameController

func testVirtualControllerFailClosed() {
    final class Box: @unchecked Sendable {
        var error: (any Error)?
        var count = 0
    }
    let box = Box()
    let virtualConfig = GCVirtualController.Configuration()
    virtualConfig.elements = [GCInputButtonA, GCInputDirectionPad]
    virtualConfig.isHidden = true
    let virtual = GCVirtualController(configuration: virtualConfig)
    precondition(virtual.controller == nil)
    let virtualGate = DispatchSemaphore(value: 0)
    virtual.connect { error in
        box.error = error
        box.count += 1
        virtualGate.signal()
    }
    precondition(box.count == 0)
    precondition(box.error == nil)
    precondition(virtualGate.wait(timeout: .now() + 2) == .success)
    precondition(box.count == 1)
    precondition(box.error != nil)
    virtual.setValue(0.5, forButtonElement: GCInputButtonA)
    virtual.setPosition(CGPoint(x: 0.2, y: -0.3), forDirectionPadElement: GCInputDirectionPad)
    virtual.updateConfiguration(forElement: GCInputButtonA) { config in
        config.isHidden = true
        config.actsAsTouchpad = true
        return config
    }
    virtual.disconnect()
    _ = GCVirtualController.self
    _ = GCVirtualController.Configuration.self
    _ = GCVirtualController.ElementConfiguration.self
}
