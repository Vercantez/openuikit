import Foundation
import Dispatch
import GameController

func testNotificationNameConstants() {
    precondition(NSNotification.Name.GCControllerDidBecomeCurrent.rawValue == "GCControllerDidBecomeCurrentNotification")
    precondition(NSNotification.Name.GCControllerDidConnect.rawValue == "GCControllerDidConnectNotification")
    precondition(NSNotification.Name.GCControllerDidDisconnect.rawValue == "GCControllerDidDisconnectNotification")
    precondition(NSNotification.Name.GCControllerDidStopBeingCurrent.rawValue == "GCControllerDidStopBeingCurrentNotification")
    precondition(NSNotification.Name.GCControllerUserCustomizationsDidChange.rawValue == "GCControllerUserCustomizationsDidChangeNotification")
    precondition(NSNotification.Name.GCKeyboardDidConnect.rawValue == "GCKeyboardDidConnectNotification")
    precondition(NSNotification.Name.GCKeyboardDidDisconnect.rawValue == "GCKeyboardDidDisconnectNotification")
    precondition(NSNotification.Name.GCMouseDidBecomeCurrent.rawValue == "GCMouseDidBecomeCurrentNotification")
    precondition(NSNotification.Name.GCMouseDidConnect.rawValue == "GCMouseDidConnectNotification")
    precondition(NSNotification.Name.GCMouseDidDisconnect.rawValue == "GCMouseDidDisconnectNotification")
    precondition(NSNotification.Name.GCMouseDidStopBeingCurrent.rawValue == "GCMouseDidStopBeingCurrentNotification")
}
