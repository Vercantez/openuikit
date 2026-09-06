import Foundation
import Dispatch
import Matter

func testClusterBridgedDeviceBasicInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    _ = MTRClusterBridgedDeviceBasic(device: device, endpoint: 1, queue: DispatchQueue.global())
}

