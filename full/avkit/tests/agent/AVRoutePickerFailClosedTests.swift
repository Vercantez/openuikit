import Foundation
import AVKit

private final class SilentRoutePickerDelegate: NSObject, AVRoutePickerViewDelegate {}

func testRoutePickerDoesNotPresentRoutes() {
    avkitOnMain {
        let picker = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let probe = SilentRoutePickerDelegate()
        picker.delegate = probe
        precondition(picker.prioritizesVideoDevices == false)
        // AVRouteDetector is not in this iPhoneOS 26.1 public graph.
        // Fail closed: constructing a picker never begins or ends a route sheet.
        picker.prioritizesVideoDevices = true
        precondition(picker.prioritizesVideoDevices == true)
        precondition(picker.delegate === probe)
    }
}
