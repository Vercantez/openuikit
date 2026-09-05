@_spi(OpenUIKitHost) import CoreMotion
import Foundation
import Glibc

func testAcceleration() {
    let accel = CMAcceleration(x: 1, y: -2, z: 3)
    precondition(accel.x == 1 && accel.y == -2 && accel.z == 3)
    precondition(CMAcceleration() == CMAcceleration(x: 0, y: 0, z: 0))
}

func testRotationRate() {
    let gyro = CMRotationRate(x: 0.1, y: 0.2, z: 0.3)
    precondition(gyro.x == 0.1 && gyro.y == 0.2 && gyro.z == 0.3)
    precondition(CMRotationRate() == CMRotationRate(x: 0, y: 0, z: 0))
}

func testMagneticField() {
    let field = CMMagneticField(x: 4, y: 5, z: 6)
    precondition(field.x == 4 && field.y == 5 && field.z == 6)
    precondition(CMMagneticField() == CMMagneticField(x: 0, y: 0, z: 0))
}

func testCalibratedMagneticField() {
    let field = CMMagneticField(x: 4, y: 5, z: 6)
    let calibrated = CMCalibratedMagneticField(field: field, accuracy: .medium)
    precondition(calibrated.field == field)
    precondition(calibrated.accuracy == .medium)
    precondition(CMCalibratedMagneticField().accuracy == .uncalibrated)
}

func testQuaternion() {
    let identity = CMQuaternion()
    precondition(identity.x == 0 && identity.y == 0 && identity.z == 0 && identity.w == 1)
    let custom = CMQuaternion(x: 0, y: 0, z: 0, w: 1)
    precondition(custom == identity)
}

func testRotationMatrix() {
    let matrix = CMRotationMatrix()
    precondition(matrix.m11 == 1 && matrix.m22 == 1 && matrix.m33 == 1)
    precondition(matrix.m12 == 0 && matrix.m13 == 0 && matrix.m21 == 0)
    precondition(matrix.m23 == 0 && matrix.m31 == 0 && matrix.m32 == 0)
    let named = CMRotationMatrix(
        m11: 1, m12: 0, m13: 0,
        m21: 0, m22: 1, m23: 0,
        m31: 0, m32: 0, m33: 1
    )
    precondition(named == matrix)
}

func testAttitudeReferenceFrameAlgebra() {
    var frames: CMAttitudeReferenceFrame = []
    precondition(frames.isEmpty)
    frames.insert(.xArbitraryZVertical)
    precondition(frames.contains(.xArbitraryZVertical))
    precondition(!frames.contains(.xTrueNorthZVertical))
    frames.formUnion(.xMagneticNorthZVertical)
    precondition(frames.isSuperset(of: .xArbitraryZVertical))
    precondition(frames.isSubset(of: [
        .xArbitraryZVertical, .xMagneticNorthZVertical, .xTrueNorthZVertical
    ]))
    let intersection = frames.intersection(.xMagneticNorthZVertical)
    precondition(intersection == .xMagneticNorthZVertical)
    frames.subtract(.xArbitraryZVertical)
    precondition(frames == .xMagneticNorthZVertical)
    let corrected: CMAttitudeReferenceFrame = [
        .xArbitraryCorrectedZVertical, .xTrueNorthZVertical
    ]
    precondition(corrected.contains(.xTrueNorthZVertical))
    precondition(!corrected.isDisjoint(with: .xTrueNorthZVertical))
    precondition(corrected.isStrictSuperset(of: .xTrueNorthZVertical))
    precondition(
        CMAttitudeReferenceFrame.xArbitraryZVertical.isStrictSubset(
            of: corrected.union(.xArbitraryZVertical)
        )
    )
    _ = corrected.symmetricDifference(.xTrueNorthZVertical)
    frames.formIntersection(.xMagneticNorthZVertical)
    frames.formSymmetricDifference(.xTrueNorthZVertical)
    var copy = CMAttitudeReferenceFrame(arrayLiteral: .xArbitraryZVertical)
    _ = copy.update(with: .xArbitraryZVertical)
    _ = copy.remove(.xArbitraryZVertical)
    precondition(copy.isEmpty)
    let sequenced = CMAttitudeReferenceFrame([.xArbitraryZVertical, .xTrueNorthZVertical])
    precondition(sequenced.contains(.xTrueNorthZVertical))
    _ = CMAttitudeReferenceFrame.xArbitraryZVertical.subtracting(.xArbitraryZVertical)
    precondition(CMAttitudeReferenceFrame().isEmpty)
    precondition(CMMotionManager.availableAttitudeReferenceFrames().isEmpty)
}

func testAttitudeMath() {
    let identity = CoreMotionHostControl.makeAttitude(quaternion: CMQuaternion())
    precondition(identity.roll == 0)
    precondition(identity.pitch == 0)
    precondition(identity.yaw == 0)
    let im = identity.rotationMatrix
    precondition(im.m11 == 1 && im.m22 == 1 && im.m33 == 1)

    let angle = Double.pi / 5
    let half = angle / 2
    let qz = CMQuaternion(x: 0, y: 0, z: sin(half), w: cos(half))
    let yawed = CoreMotionHostControl.makeAttitude(quaternion: qz)
    precondition(abs(yawed.yaw - angle) < 1e-9)
    precondition(abs(yawed.roll) < 1e-9)
    precondition(abs(yawed.pitch) < 1e-9)

    let inverse = CoreMotionHostControl.makeAttitude(quaternion: qz)
    yawed.multiply(byInverseOf: inverse)
    precondition(abs(yawed.quaternion.x) < 1e-9)
    precondition(abs(yawed.quaternion.y) < 1e-9)
    precondition(abs(yawed.quaternion.z) < 1e-9)
    precondition(abs(yawed.quaternion.w - 1) < 1e-9)

    let decoded = coreMotionArchiveRoundTrip(identity)
    precondition(decoded.quaternion.w == 1)
}

private func abs(_ value: Double) -> Double {
    value < 0 ? -value : value
}
