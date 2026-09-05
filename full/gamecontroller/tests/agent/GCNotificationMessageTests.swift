import Foundation
import Dispatch
import GameController

func testTypedNotificationMessages() {
    func onMain(_ body: @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(body)
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated(body)
            }
        }
    }

    GCSimulatedInput.reset()
    let snapshot = GCController.withExtendedGamepad()
    let connect = GCController.DidConnectMessage(controller: snapshot)
    precondition(connect.controller === snapshot)
    precondition(GCController.DidConnectMessage.name == Notification.Name.GCControllerDidConnect)

    let keyboard = GCSimulatedInput.makeKeyboard()
    let mouse = GCSimulatedInput.makeMouse()

    onMain {
        let note = Notification(name: .GCControllerDidConnect, object: snapshot)
        _ = GCController.DidConnectMessage.makeMessage(note)
        _ = GCController.DidConnectMessage.makeNotification(connect)
        let disc = GCController.DidDisconnectMessage(controller: snapshot)
        _ = disc.controller
        _ = GCController.DidDisconnectMessage.name
        _ = GCController.DidDisconnectMessage.makeMessage(Notification(name: .GCControllerDidDisconnect, object: snapshot))
        _ = GCController.DidDisconnectMessage.makeNotification(disc)
        let become = GCController.DidBecomeCurrentMessage(controller: snapshot)
        _ = become.controller
        _ = GCController.DidBecomeCurrentMessage.name
        _ = GCController.DidBecomeCurrentMessage.makeMessage(Notification(name: .GCControllerDidBecomeCurrent, object: snapshot))
        _ = GCController.DidBecomeCurrentMessage.makeNotification(become)
        let stop = GCController.DidStopBeingCurrentMessage(controller: snapshot)
        _ = stop.controller
        _ = GCController.DidStopBeingCurrentMessage.name
        _ = GCController.DidStopBeingCurrentMessage.makeMessage(Notification(name: .GCControllerDidStopBeingCurrent, object: snapshot))
        _ = GCController.DidStopBeingCurrentMessage.makeNotification(stop)

        let kConn = GCKeyboard.DidConnectMessage(keyboard: keyboard)
        _ = kConn.keyboard
        _ = GCKeyboard.DidConnectMessage.name
        _ = GCKeyboard.DidConnectMessage.makeMessage(Notification(name: .GCKeyboardDidConnect, object: keyboard))
        _ = GCKeyboard.DidConnectMessage.makeNotification(kConn)
        let kDisc = GCKeyboard.DidDisconnectMessage(keyboard: keyboard)
        _ = kDisc.keyboard
        _ = GCKeyboard.DidDisconnectMessage.name
        _ = GCKeyboard.DidDisconnectMessage.makeMessage(Notification(name: .GCKeyboardDidDisconnect, object: keyboard))
        _ = GCKeyboard.DidDisconnectMessage.makeNotification(kDisc)

        let mConn = GCMouse.DidConnectMessage(mouse: mouse)
        _ = mConn.mouse
        _ = GCMouse.DidConnectMessage.name
        _ = GCMouse.DidConnectMessage.makeMessage(Notification(name: .GCMouseDidConnect, object: mouse))
        _ = GCMouse.DidConnectMessage.makeNotification(mConn)
        let mDisc = GCMouse.DidDisconnectMessage(mouse: mouse)
        _ = mDisc.mouse
        _ = GCMouse.DidDisconnectMessage.name
        _ = GCMouse.DidDisconnectMessage.makeMessage(Notification(name: .GCMouseDidDisconnect, object: mouse))
        _ = GCMouse.DidDisconnectMessage.makeNotification(mDisc)
        let mBecome = GCMouse.DidBecomeCurrentMessage(mouse: mouse)
        _ = mBecome.mouse
        _ = GCMouse.DidBecomeCurrentMessage.name
        _ = GCMouse.DidBecomeCurrentMessage.makeMessage(Notification(name: .GCMouseDidBecomeCurrent, object: mouse))
        _ = GCMouse.DidBecomeCurrentMessage.makeNotification(mBecome)
        let mStop = GCMouse.DidStopBeingCurrentMessage(mouse: mouse)
        _ = mStop.mouse
        _ = GCMouse.DidStopBeingCurrentMessage.name
        _ = GCMouse.DidStopBeingCurrentMessage.makeMessage(Notification(name: .GCMouseDidStopBeingCurrent, object: mouse))
        _ = GCMouse.DidStopBeingCurrentMessage.makeNotification(mStop)
    }
    GCSimulatedInput.reset()
}
