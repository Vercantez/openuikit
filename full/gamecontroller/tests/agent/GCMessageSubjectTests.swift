import Foundation
import Dispatch
import GameController

func testNotificationMessageSubjects() {
    GCSimulatedInput.reset()
    let snapshot = GCController.withExtendedGamepad()
    let keyboard = GCSimulatedInput.makeKeyboard()
    let mouse = GCSimulatedInput.makeMouse()

    typealias ControllerConnectSubject = GCController.DidConnectMessage.Subject
    typealias ControllerDisconnectSubject = GCController.DidDisconnectMessage.Subject
    typealias ControllerBecomeCurrentSubject = GCController.DidBecomeCurrentMessage.Subject
    typealias ControllerStopCurrentSubject = GCController.DidStopBeingCurrentMessage.Subject
    precondition(ControllerConnectSubject.self == GCController.self)
    precondition(ControllerDisconnectSubject.self == GCController.self)
    precondition(ControllerBecomeCurrentSubject.self == GCController.self)
    precondition(ControllerStopCurrentSubject.self == GCController.self)
    let connect = GCController.DidConnectMessage(controller: snapshot)
    let connectSubject: ControllerConnectSubject = connect.controller
    precondition(connectSubject === snapshot)

    typealias KeyboardConnectSubject = GCKeyboard.DidConnectMessage.Subject
    typealias KeyboardDisconnectSubject = GCKeyboard.DidDisconnectMessage.Subject
    precondition(KeyboardConnectSubject.self == GCKeyboard.self)
    precondition(KeyboardDisconnectSubject.self == GCKeyboard.self)
    let keyboardConnect = GCKeyboard.DidConnectMessage(keyboard: keyboard)
    let keyboardSubject: KeyboardConnectSubject = keyboardConnect.keyboard
    precondition(keyboardSubject === keyboard)

    typealias MouseConnectSubject = GCMouse.DidConnectMessage.Subject
    typealias MouseDisconnectSubject = GCMouse.DidDisconnectMessage.Subject
    typealias MouseBecomeCurrentSubject = GCMouse.DidBecomeCurrentMessage.Subject
    typealias MouseStopCurrentSubject = GCMouse.DidStopBeingCurrentMessage.Subject
    precondition(MouseConnectSubject.self == GCMouse.self)
    precondition(MouseDisconnectSubject.self == GCMouse.self)
    precondition(MouseBecomeCurrentSubject.self == GCMouse.self)
    precondition(MouseStopCurrentSubject.self == GCMouse.self)
    let mouseConnect = GCMouse.DidConnectMessage(mouse: mouse)
    let mouseSubject: MouseConnectSubject = mouseConnect.mouse
    precondition(mouseSubject === mouse)
    GCSimulatedInput.reset()
}
