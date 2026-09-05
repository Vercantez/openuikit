import Foundation
import Dispatch
import GameController

func testVirtualControllerFailClosed() {
    let virtualConfig = GCVirtualController.Configuration()
    virtualConfig.elements = [GCInputButtonA, GCInputDirectionPad]
    virtualConfig.isHidden = true
    let virtual = GCVirtualController(configuration: virtualConfig)
    precondition(virtual.controller == nil)
    let virtualGate = DispatchSemaphore(value: 0)
    var virtualError: (any Error)?
    var virtualCount = 0
    virtual.connect { error in
        virtualError = error
        virtualCount += 1
        virtualGate.signal()
    }
    precondition(virtualCount == 0)
    precondition(virtualError == nil)
    precondition(virtualGate.wait(timeout: .now() + 2) == .success)
    precondition(virtualCount == 1)
    precondition(virtualError != nil)
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
