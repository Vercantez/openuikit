import Foundation
import ARKit

func testSkeletonJointNameValues() {
    arkitRequire(ARSkeleton.JointName.root.rawValue == "root", "root")
    arkitRequire(ARSkeleton.JointName.head.rawValue == "head_joint", "head")
    arkitRequire(ARSkeleton.JointName.leftShoulder.rawValue == "left_shoulder_1_joint", "leftShoulder")
    arkitRequire(ARSkeleton.JointName.rightShoulder.rawValue == "right_shoulder_1_joint", "rightShoulder")
    arkitRequire(ARSkeleton.JointName.leftHand.rawValue == "left_hand_joint", "leftHand")
    arkitRequire(ARSkeleton.JointName.rightHand.rawValue == "right_hand_joint", "rightHand")
    arkitRequire(ARSkeleton.JointName.leftFoot.rawValue == "left_foot_joint", "leftFoot")
    arkitRequire(ARSkeleton.JointName.rightFoot.rawValue == "right_foot_joint", "rightFoot")
    arkitRequire(ARSkeleton.JointName(rawValue: "head_joint") == .head, "init rawValue")
    arkitRequire(ARSkeleton.JointName.root != .head, "inequality")
    arkitRequire(ARSkeleton.JointName(VNRecognizedPointKey(rawValue: "head")) == nil, "Vision map fail-closed")
    _ = ARSkeleton.JointName.head.hashValue
    var hasher = Hasher()
    ARSkeleton.JointName.root.hash(into: &hasher)
}

func testSkeletonDefinitionAndTransforms() {
    let body3D = ARSkeletonDefinition.defaultBody3D
    arkitRequire(body3D.jointCount == 8, "3d joint count")
    arkitRequire(body3D.jointNames.contains("head_joint"), "jointNames")
    arkitRequire(body3D.index(for: .head) >= 0, "index(for:)")
    arkitRequire(body3D.parentIndices.count == 8, "parentIndices")
    arkitRequire(body3D.neutralBodySkeleton3D == nil, "no Apple rest pose")
    arkitRequire(ARSkeletonDefinition.defaultBody2D.jointCount == 8, "2d joint count")

    let skeleton = ARSkeleton3D()
    arkitRequire(!skeleton.isJointTracked(0), "isJointTracked")
    arkitRequire(skeleton.localTransform(for: .head) == nil, "localTransform")
    arkitRequire(skeleton.modelTransform(for: .root) == nil, "modelTransform")
    arkitRequire(skeleton.jointLocalTransforms.isEmpty, "jointLocalTransforms")
    arkitRequire(skeleton.jointModelTransforms.isEmpty, "jointModelTransforms")
    arkitRequire(skeleton.definition.jointCount == 8, "definition")
    arkitRequire(ARSkeleton2D().landmark(for: .root) == nil, "2d landmark")
    arkitRequire(ARSkeleton2D().jointLandmarks.isEmpty, "jointLandmarks")
    _ = ARBody2D().skeleton
    _ = ARBodyAnchor(anchor: ARAnchor(transform: .identity)).skeleton
    _ = ARBodyAnchor(anchor: ARAnchor(transform: .identity)).estimatedScaleFactor
}
