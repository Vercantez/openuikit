import Foundation
import Accessibility

func testHearingDeviceFailClosed() {
    precondition(AXMFiHearingDevice.pairedDeviceIdentifiers().isEmpty)
    precondition(AXMFiHearingDevice.streamingEar().isEmpty)
    precondition(AXMFiHearingDevice.supportsBidirectionalStreaming() == false)
    precondition(
        AXMFiHearingDevice.pairedUUIDsDidChangeNotification.rawValue
            == "AXMFiHearingDevicePairedUUIDsDidChangeNotification"
    )
    precondition(
        AXMFiHearingDevice.streamingEarDidChangeNotification.rawValue
            == "AXMFiHearingDeviceStreamingEarDidChangeNotification"
    )
}
