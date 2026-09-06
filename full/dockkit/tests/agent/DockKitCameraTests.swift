import Foundation
import DockKit

func testCameraInformationInit() {
    let device = AVCaptureDevice.DeviceType(rawValue: "builtInWideAngleCamera")
    let intrinsics = simd_float3x3(
        columns: (
            SIMD3<Float>(1, 0, 0),
            SIMD3<Float>(0, 1, 0),
            SIMD3<Float>(0, 0, 1)
        )
    )
    let info = DockAccessory.CameraInformation(
        captureDevice: device,
        cameraPosition: .front,
        orientation: .portrait,
        cameraIntrinsics: intrinsics,
        referenceDimensions: CGSize(width: 1920, height: 1080)
    )
    precondition(info.captureDevice == device)
    precondition(info.cameraPosition == .front)
    precondition(info.orientation == .portrait)
    precondition(info.cameraIntrinsics?.columns.0 == SIMD3<Float>(1, 0, 0))
    precondition(info.referenceDimensions?.width == 1920)
    precondition(info.referenceDimensions?.height == 1080)
}

func testCameraInformationNilIntrinsics() {
    let info = DockAccessory.CameraInformation(
        captureDevice: AVCaptureDevice.DeviceType(rawValue: "wide"),
        cameraPosition: .back,
        orientation: .unknown,
        cameraIntrinsics: nil,
        referenceDimensions: nil
    )
    precondition(info.cameraIntrinsics == nil)
    precondition(info.referenceDimensions == nil)
    precondition(info.cameraPosition == .back)
}

func testStateChangeProperties() {
    let identifier = DockAccessory.Identifier(
        name: "dock",
        uuid: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
        category: .trackingStand
    )
    let accessory = DockAccessory(identifier: identifier)
    let change = DockAccessory.StateChange(
        trackingButtonEnabled: true,
        state: .docked,
        accessory: accessory
    )
    precondition(change.trackingButtonEnabled)
    precondition(change.state == .docked)
    precondition(change.accessory == accessory)
}

func testStateChangeNilAccessory() {
    let change = DockAccessory.StateChange(
        trackingButtonEnabled: false,
        state: .undocked,
        accessory: nil
    )
    precondition(change.accessory == nil)
    precondition(change.state == .undocked)
    precondition(!change.trackingButtonEnabled)
}
