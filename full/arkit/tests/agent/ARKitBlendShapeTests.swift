import Foundation
import ARKit

func testBlendShapeLocationValues() {
    let pairs: [(ARFaceAnchor.BlendShapeLocation, String)] = [
        (.browDownLeft, "browDown_L"),
        (.browDownRight, "browDown_R"),
        (.browInnerUp, "browInnerUp"),
        (.browOuterUpLeft, "browOuterUp_L"),
        (.browOuterUpRight, "browOuterUp_R"),
        (.cheekPuff, "cheekPuff"),
        (.cheekSquintLeft, "cheekSquint_L"),
        (.cheekSquintRight, "cheekSquint_R"),
        (.eyeBlinkLeft, "eyeBlink_L"),
        (.eyeBlinkRight, "eyeBlink_R"),
        (.eyeLookDownLeft, "eyeLookDown_L"),
        (.eyeLookDownRight, "eyeLookDown_R"),
        (.eyeLookInLeft, "eyeLookIn_L"),
        (.eyeLookInRight, "eyeLookIn_R"),
        (.eyeLookOutLeft, "eyeLookOut_L"),
        (.eyeLookOutRight, "eyeLookOut_R"),
        (.eyeLookUpLeft, "eyeLookUp_L"),
        (.eyeLookUpRight, "eyeLookUp_R"),
        (.eyeSquintLeft, "eyeSquint_L"),
        (.eyeSquintRight, "eyeSquint_R"),
        (.eyeWideLeft, "eyeWide_L"),
        (.eyeWideRight, "eyeWide_R"),
        (.jawForward, "jawForward"),
        (.jawLeft, "jawLeft"),
        (.jawOpen, "jawOpen"),
        (.jawRight, "jawRight"),
        (.mouthClose, "mouthClose"),
        (.mouthDimpleLeft, "mouthDimple_L"),
        (.mouthDimpleRight, "mouthDimple_R"),
        (.mouthFrownLeft, "mouthFrown_L"),
        (.mouthFrownRight, "mouthFrown_R"),
        (.mouthFunnel, "mouthFunnel"),
        (.mouthLeft, "mouthLeft"),
        (.mouthLowerDownLeft, "mouthLowerDown_L"),
        (.mouthLowerDownRight, "mouthLowerDown_R"),
        (.mouthPressLeft, "mouthPress_L"),
        (.mouthPressRight, "mouthPress_R"),
        (.mouthPucker, "mouthPucker"),
        (.mouthRight, "mouthRight"),
        (.mouthRollLower, "mouthRollLower"),
        (.mouthRollUpper, "mouthRollUpper"),
        (.mouthShrugLower, "mouthShrugLower"),
        (.mouthShrugUpper, "mouthShrugUpper"),
        (.mouthSmileLeft, "mouthSmile_L"),
        (.mouthSmileRight, "mouthSmile_R"),
        (.mouthStretchLeft, "mouthStretch_L"),
        (.mouthStretchRight, "mouthStretch_R"),
        (.mouthUpperUpLeft, "mouthUpperUp_L"),
        (.mouthUpperUpRight, "mouthUpperUp_R"),
        (.noseSneerLeft, "noseSneer_L"),
        (.noseSneerRight, "noseSneer_R"),
        (.tongueOut, "tongueOut"),
    ]
    arkitRequire(pairs.count == 52, "blend shape count")
    for (location, raw) in pairs {
        arkitRequire(location.rawValue == raw, raw)
        arkitRequire(ARFaceAnchor.BlendShapeLocation(rawValue: raw) == location, "round trip \(raw)")
    }
    arkitRequire(ARFaceAnchor.BlendShapeLocation.jawOpen != .jawLeft, "inequality")
    _ = ARFaceAnchor.BlendShapeLocation.eyeBlinkLeft.hashValue
    var hasher = Hasher()
    ARFaceAnchor.BlendShapeLocation.tongueOut.hash(into: &hasher)
}
