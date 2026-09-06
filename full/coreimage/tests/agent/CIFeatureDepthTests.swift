import CoreImage
import Foundation

func testCIFaceFeatureStoredGeometry() {
    let face = CIFaceFeature(bounds: CGRect(x: 4, y: 5, width: 10, height: 12))
    precondition(face.bounds.origin.x == 4)
    precondition(face.bounds.height == 12)
    precondition(face.type == CIFeatureTypeFace)
    face.hasFaceAngle = true
    face.faceAngle = 12.5
    precondition(face.hasFaceAngle)
    precondition(face.faceAngle == 12.5)
    face.hasMouthPosition = true
    face.mouthPosition = CGPoint(x: 9, y: 8)
    precondition(face.hasMouthPosition)
    precondition(face.mouthPosition.x == 9)
    face.hasRightEyePosition = true
    face.rightEyePosition = CGPoint(x: 12, y: 14)
    precondition(face.hasRightEyePosition)
    precondition(face.rightEyePosition.y == 14)
    face.leftEyeClosed = true
    face.rightEyeClosed = true
    precondition(face.leftEyeClosed)
    precondition(face.rightEyeClosed)
    face.hasTrackingID = true
    face.trackingID = 7
    precondition(face.hasTrackingID)
    precondition(face.trackingID == 7)
    face.hasTrackingFrameCount = true
    face.trackingFrameCount = 3
    precondition(face.hasTrackingFrameCount)
    precondition(face.trackingFrameCount == 3)
}

func testCIRectangleFeatureCornersFromBounds() {
    let rect = CIRectangleFeature(bounds: CGRect(x: 1, y: 2, width: 4, height: 6))
    precondition(type(of: rect) == CIRectangleFeature.self)
    precondition(rect.bounds.width == 4)
    precondition(rect.topLeft.x == 1 && rect.topLeft.y == 8)
    precondition(rect.topRight.x == 5 && rect.topRight.y == 8)
    precondition(rect.bottomLeft.x == 1 && rect.bottomLeft.y == 2)
    precondition(rect.bottomRight.x == 5 && rect.bottomRight.y == 2)
}

func testCITextFeatureCornersAndSubfeatures() {
    let text = CITextFeature(bounds: CGRect(x: 0, y: 0, width: 8, height: 4))
    precondition(type(of: text) == CITextFeature.self)
    precondition(text.bounds.width == 8)
    precondition(text.topLeft.x == 0 && text.topLeft.y == 4)
    precondition(text.topRight.x == 8 && text.topRight.y == 4)
    precondition(text.bottomLeft.x == 0 && text.bottomLeft.y == 0)
    precondition(text.bottomRight.x == 8 && text.bottomRight.y == 0)
    let child = CITextFeature(bounds: CGRect(x: 1, y: 1, width: 2, height: 1))
    text.subFeatures = [child]
    precondition((text.subFeatures?.count ?? 0) == 1)
}

func testCIQRCodeFeatureMessageCornersAndCoder() {
    let qr = CIQRCodeFeature(bounds: CGRect(x: 2, y: 3, width: 6, height: 6))
    precondition(type(of: qr) == CIQRCodeFeature.self)
    precondition(qr.bounds.origin.y == 3)
    precondition(qr.topLeft.x == 2 && qr.topLeft.y == 9)
    precondition(qr.topRight.x == 8 && qr.topRight.y == 9)
    precondition(qr.bottomLeft.x == 2 && qr.bottomLeft.y == 3)
    precondition(qr.bottomRight.x == 8 && qr.bottomRight.y == 3)
    qr.messageString = "HELLO"
    precondition(qr.messageString == "HELLO")
    qr.symbolDescriptor = CIQRCodeDescriptor(
        payload: Data([0x40, 0x14]),
        symbolVersion: 1,
        maskPattern: 0,
        errorCorrectionLevel: .levelM
    )
    precondition(qr.symbolDescriptor?.symbolVersion == 1)
    precondition(CIQRCodeFeature(coder: NSCoder()) == nil)
}
