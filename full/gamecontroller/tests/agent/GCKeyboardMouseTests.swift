import Foundation
import Dispatch
import GameController

func testCoalescedKeyboardAndMouse() {
    GCSimulatedInput.reset()
    precondition(GCKeyboard.coalesced == nil)
    precondition(GCMouse.current == nil)
    precondition(GCMouse.mice().isEmpty)

    let keyboard = GCSimulatedInput.makeKeyboard()
    GCSimulatedInput.attachKeyboard(keyboard)
    precondition(GCKeyboard.coalesced === keyboard)
    precondition(keyboard.productCategory == GCProductCategoryKeyboard)
    precondition(keyboard.vendorName == "Simulated Keyboard")
    _ = keyboard.physicalInputProfile
    let keyInput = keyboard.keyboardInput!
    _ = keyInput.button(forKeyCode: .keyA)
    GCSimulatedInput.pressKey(keyboard, .keyA, pressed: true)
    precondition(keyInput.isAnyKeyPressed)
    keyInput.keyChangedHandler = { _, _, _, _ in }
    GCSimulatedInput.pressKey(keyboard, .keyA, pressed: false)
    _ = GCKeyboard.self
    _ = GCKeyboardInput.self

    let mouse = GCSimulatedInput.makeMouse()
    GCSimulatedInput.attachMouse(mouse)
    precondition(GCMouse.current === mouse)
    precondition(GCMouse.mice().contains(where: { $0 === mouse }))
    let mouseInput = mouse.mouseInput!
    _ = mouseInput.leftButton
    _ = mouseInput.middleButton
    _ = mouseInput.rightButton
    _ = mouseInput.auxiliaryButtons
    _ = mouseInput.scroll
    mouseInput.mouseMovedHandler = { _, _, _ in }
    GCSimulatedInput.moveMouse(mouse, deltaX: 3, deltaY: -4)
    mouseInput.leftButton.setValue(1)
    precondition(mouseInput.leftButton.isPressed)
    let cursor = GCDeviceCursor()
    cursor.setValueForXAxis(0.1, yAxis: 0.2)
    _ = GCMouse.self
    _ = GCMouseInput.self
    _ = GCDeviceCursor.self

    GCSimulatedInput.detachKeyboard(keyboard)
    GCSimulatedInput.detachMouse(mouse)
    GCSimulatedInput.reset()
}
