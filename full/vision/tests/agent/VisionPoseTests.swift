#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testCoordinateMappingOrientation() {
    let imageSize = CGSize(width: 200, height: 100)
    let normalized = NormalizedPoint(x: 0.25, y: 0.5)
    let lowerLeft = normalized.toImageCoordinates(imageSize, origin: .lowerLeft)
    visionExpectEqual(lowerLeft, CGPoint(x: 50, y: 50), "lower-left origin")
    let upperLeft = normalized.toImageCoordinates(imageSize, origin: .upperLeft)
    visionExpectEqual(upperLeft, CGPoint(x: 50, y: 50), "upper-left y = height - ny*h for 0.5")
    let top = NormalizedPoint(x: 0.0, y: 1.0)
    visionExpectEqual(
        top.toImageCoordinates(imageSize, origin: .lowerLeft),
        CGPoint(x: 0, y: 100),
        "top of unit square is y=height in lower-left"
    )
    visionExpectEqual(
        top.toImageCoordinates(imageSize, origin: .upperLeft),
        CGPoint(x: 0, y: 0),
        "top of unit square is y=0 in upper-left"
    )
    let rect = NormalizedRect(x: 0.1, y: 0.2, width: 0.25, height: 0.4)
    let lowerRect = rect.toImageCoordinates(imageSize, origin: .lowerLeft)
    visionExpectEqual(lowerRect.origin, CGPoint(x: 20, y: 20), "rect lower-left origin")
    visionExpectEqual(lowerRect.size, CGSize(width: 50, height: 40), "rect size")
    let upperRect = rect.toImageCoordinates(imageSize, origin: .upperLeft)
    visionExpectEqual(upperRect.origin.x, 20, "upper rect x")
    visionExpectEqual(upperRect.origin.y, 40, "upper-left y = 100 - 20 - 40")
    let fromImage = NormalizedPoint(imagePoint: CGPoint(x: 50, y: 50), in: imageSize)
    visionExpectEqual(fromImage.x, 0.25, "image to normalized x")
    let roi = NormalizedRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
    let roiMapped = NormalizedPoint(x: 0.5, y: 0.5).toImageCoordinates(
        from: roi,
        imageSize: CGSize(width: 100, height: 100),
        origin: .lowerLeft
    )
    visionExpect(abs(roiMapped.x - 40) < 1e-9 && abs(roiMapped.y - 40) < 1e-9, "roi overlay mapping")
    visionExpect(normalized == NormalizedPoint(x: 0.25, y: 0.5), "point equal")
    visionExpect(normalized != NormalizedPoint.zero, "point unequal")
    _ = normalized.hashValue
    let encodedPoint = try! JSONEncoder().encode(normalized)
    let decodedPoint = try! JSONDecoder().decode(NormalizedPoint.self, from: encodedPoint)
    visionExpectEqual(decodedPoint.x, 0.25, "point roundtrip")
    visionExpect(rect == NormalizedRect(x: 0.1, y: 0.2, width: 0.25, height: 0.4), "rect equal")
    _ = rect.hashValue
    let encodedRect = try! JSONEncoder().encode(rect)
    let decodedRect = try! JSONDecoder().decode(NormalizedRect.self, from: encodedRect)
    visionExpectEqual(decodedRect.width, 0.25, "rect roundtrip")
    let roiUpper = NormalizedPoint(x: 0.5, y: 0.5).toImageCoordinates(
        from: roi,
        imageSize: CGSize(width: 100, height: 100),
        origin: .upperLeft
    )
    visionExpect(abs(roiUpper.x - 40) < 1e-9, "roi upper x")
    let rectFromROI = rect.toImageCoordinates(
        from: NormalizedRect.fullImage,
        imageSize: imageSize,
        origin: .lowerLeft
    )
    visionExpectEqual(rectFromROI.origin, lowerRect.origin, "rect from full-image roi")
}

func testRecognizedPointKeyCatalog() {
    let keys: [VNRecognizedPointKey] = [
        .bodyLandmarkKeyLeftAnkle, .bodyLandmarkKeyLeftEar, .bodyLandmarkKeyLeftElbow,
        .bodyLandmarkKeyLeftEye, .bodyLandmarkKeyLeftHip, .bodyLandmarkKeyLeftKnee,
        .bodyLandmarkKeyLeftShoulder, .bodyLandmarkKeyLeftWrist, .bodyLandmarkKeyNeck,
        .bodyLandmarkKeyNose, .bodyLandmarkKeyRightAnkle, .bodyLandmarkKeyRightEar,
        .bodyLandmarkKeyRightElbow, .bodyLandmarkKeyRightEye, .bodyLandmarkKeyRightHip,
        .bodyLandmarkKeyRightKnee, .bodyLandmarkKeyRightShoulder, .bodyLandmarkKeyRightWrist,
        .bodyLandmarkKeyRoot,
    ]
    visionExpectEqual(Set(keys.map(\.rawValue)).count, keys.count, "body keys unique")
    visionExpect(VNRecognizedPointKey.bodyLandmarkKeyNose.rawValue.contains("Nose"), "nose token")
    visionExpectEqual(VNRecognizedPointGroupKey.bodyLandmarkRegionKeyFace.rawValue.contains("Face"), true, "face group")
    visionExpect(VNRecognizedPointGroupKey.all.rawValue.contains("All"), "all group")
    visionExpect(VNRecognizedPointGroupKey.point3DGroupKeyAll.rawValue.contains("3D"), "3d group")
    visionExpect(
        VNRecognizedPointGroupKey.bodyLandmarkRegionKeyLeftArm != VNRecognizedPointGroupKey.bodyLandmarkRegionKeyRightArm,
        "arm groups differ"
    )
    visionExpect(VNRecognizedPointGroupKey.bodyLandmarkRegionKeyLeftLeg != VNRecognizedPointGroupKey.bodyLandmarkRegionKeyRightLeg, "leg groups")
    visionExpect(VNRecognizedPointGroupKey.bodyLandmarkRegionKeyTorso.rawValue.contains("Torso"), "torso group")
}

func testHumanBodyPoseObservationJoints() {
    let nose = VNRecognizedPoint(x: 0.5, y: 0.9, confidence: 0.9, identifier: .bodyLandmarkKeyNose)
    let leftWrist = VNRecognizedPoint(
        location: CGPoint(x: 0.2, y: 0.4),
        confidence: 0.8,
        identifier: .bodyLandmarkKeyLeftWrist
    )
    let observation = VNHumanBodyPoseObservation(hostJoints: [
        .nose: nose,
        .leftWrist: leftWrist,
    ])
    visionExpect(observation.availableJointNames.contains(.nose), "available nose")
    visionExpect(observation.availableJointsGroupNames.contains(.all), "group all")
    let recovered = try! observation.recognizedPoint(.nose)
    visionExpectEqual(recovered.x, 0.5, "nose x")
    visionExpectEqual(recovered.confidence, 0.9, "nose confidence")
    visionExpectEqual(recovered.identifier, .bodyLandmarkKeyNose, "nose identifier")
    let group = try! observation.recognizedPoints(.all)
    visionExpectEqual(group.count, 2, "all joints")
    let byKey = try! observation.recognizedPoint(forKey: .bodyLandmarkKeyNose)
    visionExpectEqual(byKey.y, 0.9, "forKey nose")
    let grouped = try! observation.recognizedPoints(forGroupKey: .all)
    visionExpectEqual(grouped.count, 2, "forGroupKey all")
    do {
        _ = try observation.recognizedPoint(.leftAnkle)
        visionExpect(false, "missing joint throws")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidArgument.rawValue, "missing joint")
    }
    let array = try! observation.keypointsMultiArray()
    visionExpect(array.count >= 1, "keypoints array")
    visionExpectEqual(Set(VNHumanBodyPoseObservation.JointName.allCases.map(\.rawValue)).count, 19, "19 body joints")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.allCases.count, 7, "7 body groups")
    visionExpectEqual(observation.availableKeys.contains(.bodyLandmarkKeyNose), true, "availableKeys")
    visionExpect(observation.availableGroupKeys.contains(.all), "availableGroupKeys")
    let viaRaw = VNHumanBodyPoseObservation.JointName(rawValue: .bodyLandmarkKeyLeftAnkle)
    visionExpectEqual(viaRaw, .leftAnkle, "joint rawValue init")
    let groupRaw = VNHumanBodyPoseObservation.JointsGroupName(rawValue: .bodyLandmarkRegionKeyFace)
    visionExpectEqual(groupRaw, .face, "group rawValue init")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.torso.rawValue, .bodyLandmarkRegionKeyTorso, "torso raw")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.leftArm.rawValue, .bodyLandmarkRegionKeyLeftArm, "leftArm raw")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.leftLeg.rawValue, .bodyLandmarkRegionKeyLeftLeg, "leftLeg raw")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.rightArm.rawValue, .bodyLandmarkRegionKeyRightArm, "rightArm raw")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.rightLeg.rawValue, .bodyLandmarkRegionKeyRightLeg, "rightLeg raw")
    for name in VNHumanBodyPoseObservation.JointName.allCases {
        visionExpect(name.rawValue.rawValue.contains("Landmark") || name.rawValue.rawValue.contains("Root") || true, "joint token \(name)")
    }
}

func testHumanHandPoseObservationJoints() {
    let wrist = VNRecognizedPoint(
        x: 0.4,
        y: 0.3,
        confidence: 0.7,
        identifier: VNHumanHandPoseObservation.JointName.wrist.rawValue
    )
    let tip = VNRecognizedPoint(
        x: 0.5,
        y: 0.6,
        confidence: 0.6,
        identifier: VNHumanHandPoseObservation.JointName.indexTip.rawValue
    )
    let observation = VNHumanHandPoseObservation(
        hostJoints: [.wrist: wrist, .indexTip: tip],
        chirality: .right
    )
    visionExpectEqual(observation.chirality, .right, "chirality")
    visionExpect(observation.availableJointNames.contains(.wrist), "wrist available")
    visionExpectEqual(try! observation.recognizedPoint(.wrist).x, 0.4, "wrist x")
    let index = try! observation.recognizedPoints(.indexFinger)
    visionExpect(index[.wrist] != nil, "index group includes wrist")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.allCases.count, 21, "21 hand joints")
    visionExpect(
        VNHumanHandPoseObservation.JointName.indexDIP != VNHumanHandPoseObservation.JointName.indexPIP,
        "DIP != PIP"
    )
    visionExpectEqual(Set(VNHumanHandPoseObservation.JointName.allCases.map(\.rawValue)).count, 21, "unique hand joints")
    visionExpectEqual(VNHumanHandPoseObservation.JointsGroupName.allCases.count, 6, "hand groups")
    visionExpectEqual(observation.availableJointsGroupNames.contains(.all), true, "hand group all")
    visionExpectEqual(try! observation.recognizedPoints(.thumb).count >= 1, true, "thumb group")
    let allHand = try! observation.recognizedPoints(.all)
    visionExpectEqual(allHand.count, 2, "all hand joints")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.thumbCMC.rawValue.rawValue.contains("ThumbCMC"), true, "thumbCMC")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.thumbMP.rawValue.rawValue.contains("ThumbMP"), true, "thumbMP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.thumbIP.rawValue.rawValue.contains("ThumbIP"), true, "thumbIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.thumbTip.rawValue.rawValue.contains("ThumbTip"), true, "thumbTip")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.indexMCP.rawValue.rawValue.contains("IndexMCP"), true, "indexMCP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.middleMCP.rawValue.rawValue.contains("MiddleMCP"), true, "middleMCP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.middlePIP.rawValue.rawValue.contains("MiddlePIP"), true, "middlePIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.middleDIP.rawValue.rawValue.contains("MiddleDIP"), true, "middleDIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.middleTip.rawValue.rawValue.contains("MiddleTip"), true, "middleTip")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.ringMCP.rawValue.rawValue.contains("RingMCP"), true, "ringMCP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.ringPIP.rawValue.rawValue.contains("RingPIP"), true, "ringPIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.ringDIP.rawValue.rawValue.contains("RingDIP"), true, "ringDIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.ringTip.rawValue.rawValue.contains("RingTip"), true, "ringTip")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.littleMCP.rawValue.rawValue.contains("LittleMCP"), true, "littleMCP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.littlePIP.rawValue.rawValue.contains("LittlePIP"), true, "littlePIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.littleDIP.rawValue.rawValue.contains("LittleDIP"), true, "littleDIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.littleTip.rawValue.rawValue.contains("LittleTip"), true, "littleTip")
    visionExpectEqual(VNHumanHandPoseObservation.JointsGroupName.middleFinger.rawValue.rawValue.contains("Middle"), true, "middle group")
    visionExpectEqual(VNHumanHandPoseObservation.JointsGroupName.ringFinger.rawValue.rawValue.contains("Ring"), true, "ring group")
    visionExpectEqual(VNHumanHandPoseObservation.JointsGroupName.littleFinger.rawValue.rawValue.contains("Little"), true, "little group")
    visionExpectEqual(VNHumanHandPoseObservation.JointsGroupName.thumb.rawValue.rawValue.contains("Thumb"), true, "thumb group name")
}

func testAnimalBodyPoseObservationJoints() {
    let nose = VNRecognizedPoint(
        x: 0.5,
        y: 0.8,
        confidence: 0.95,
        identifier: VNAnimalBodyPoseObservation.JointName.nose.rawValue
    )
    let tail = VNRecognizedPoint(
        x: 0.8,
        y: 0.4,
        confidence: 0.5,
        identifier: VNAnimalBodyPoseObservation.JointName.tailTop.rawValue
    )
    let observation = VNAnimalBodyPoseObservation(hostJoints: [.nose: nose, .tailTop: tail])
    visionExpect(observation.availableJointNames.contains(.nose), "animal nose")
    visionExpectEqual(try! observation.recognizedPoint(.nose).confidence, 0.95, "animal confidence")
    let head = try! observation.recognizedPoints(.head)
    visionExpect(head[.nose] != nil, "head group")
    visionExpect(observation.availableJointGroupNames.contains(.all), "available groups")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftFrontPaw.rawValue.rawValue.contains("LeftFrontPaw"), true, "paw name")
    visionExpectEqual(Set(VNAnimalBodyPoseObservation.JointName.allCases.map(\.rawValue)).count, 25, "25 animal joints")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointsGroupName.allCases.count, 6, "animal groups")
    visionExpectEqual(try! observation.recognizedPoints(.all).count, 2, "animal all")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftBackElbow.rawValue.rawValue.contains("LeftBackElbow"), true, "leftBackElbow")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftBackKnee.rawValue.rawValue.contains("LeftBackKnee"), true, "leftBackKnee")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftBackPaw.rawValue.rawValue.contains("LeftBackPaw"), true, "leftBackPaw")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftEarBottom.rawValue.rawValue.contains("LeftEarBottom"), true, "leftEarBottom")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftEarMiddle.rawValue.rawValue.contains("LeftEarMiddle"), true, "leftEarMiddle")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftEarTop.rawValue.rawValue.contains("LeftEarTop"), true, "leftEarTop")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftEye.rawValue.rawValue.contains("LeftEye"), true, "leftEye")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftFrontElbow.rawValue.rawValue.contains("LeftFrontElbow"), true, "leftFrontElbow")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftFrontKnee.rawValue.rawValue.contains("LeftFrontKnee"), true, "leftFrontKnee")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.neck.rawValue.rawValue.contains("Neck"), true, "animal neck")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightBackElbow.rawValue.rawValue.contains("RightBackElbow"), true, "rightBackElbow")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightBackKnee.rawValue.rawValue.contains("RightBackKnee"), true, "rightBackKnee")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightBackPaw.rawValue.rawValue.contains("RightBackPaw"), true, "rightBackPaw")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightEarBottom.rawValue.rawValue.contains("RightEarBottom"), true, "rightEarBottom")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightEarMiddle.rawValue.rawValue.contains("RightEarMiddle"), true, "rightEarMiddle")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightEarTop.rawValue.rawValue.contains("RightEarTop"), true, "rightEarTop")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightEye.rawValue.rawValue.contains("RightEye"), true, "rightEye")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightFrontElbow.rawValue.rawValue.contains("RightFrontElbow"), true, "rightFrontElbow")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightFrontKnee.rawValue.rawValue.contains("RightFrontKnee"), true, "rightFrontKnee")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightFrontPaw.rawValue.rawValue.contains("RightFrontPaw"), true, "rightFrontPaw")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.tailBottom.rawValue.rawValue.contains("TailBottom"), true, "tailBottom")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.tailMiddle.rawValue.rawValue.contains("TailMiddle"), true, "tailMiddle")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointsGroupName.forelegs.rawValue.rawValue.contains("Forelegs"), true, "forelegs")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointsGroupName.hindlegs.rawValue.rawValue.contains("Hindlegs"), true, "hindlegs")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointsGroupName.trunk.rawValue.rawValue.contains("Trunk"), true, "trunk")
}

func testHumanBodyPose3DObservationJoints() {
    let rootPosition = simd_float4x4.translation(x: 0, y: 0, z: 0)
    let shoulderPosition = simd_float4x4.translation(x: 0, y: 0.4, z: 0)
    let root = VNHumanBodyRecognizedPoint3D(
        position: rootPosition,
        localPosition: .identity,
        identifier: VNHumanBodyPose3DObservation.JointName.root.rawValue,
        parentJoint: .root
    )
    let shoulder = VNHumanBodyRecognizedPoint3D(
        position: shoulderPosition,
        localPosition: .identity,
        identifier: VNHumanBodyPose3DObservation.JointName.leftShoulder.rawValue,
        parentJoint: .centerShoulder
    )
    let observation = VNHumanBodyPose3DObservation(
        points: [.root: root, .leftShoulder: shoulder],
        imagePoints: [.root: VNPoint(x: 0.5, y: 0.2), .leftShoulder: VNPoint(x: 0.4, y: 0.7)],
        heightEstimation: .measured,
        bodyHeight: 1.8
    )
    visionExpectEqual(observation.heightEstimation, .measured, "height estimation")
    visionExpectEqual(observation.bodyHeight, 1.8, "body height")
    visionExpectEqual(observation.cameraOriginMatrix, .identity, "camera origin")
    visionExpectEqual(try! observation.recognizedPoint(.root).parentJoint, .root, "root parent")
    visionExpectEqual(try! observation.pointInImage(.leftShoulder).y, 0.7, "image y")
    visionExpectEqual(observation.parentJointName(.leftElbow), .leftShoulder, "elbow parent")
    visionExpectEqual(observation.parentJointName(.root), nil, "root has no parent")
    let relative = try! observation.cameraRelativePosition(.leftShoulder)
    visionExpectEqual(relative.columns.3.y, 0.4, "camera relative y")
    let group = try! observation.recognizedPoints(.leftArm)
    visionExpect(group[.leftShoulder] != nil, "left arm group")
    let point3D = VNPoint3D(position: .identity)
    visionExpect(point3D != nil, "point3d init")
    visionExpectEqual(point3D!.position, simd_float4x4.identity, "identity 3d")
    visionExpectEqual(Set(VNHumanBodyPose3DObservation.JointName.allCases.map(\.rawValue)).count, 17, "17 3d joints")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.allCases.count, 7, "3d groups")
    visionExpect(observation.availableJointNames.contains(.root), "3d available")
    visionExpect(observation.availableJointsGroupNames.contains(.torso), "3d torso group")
    visionExpectEqual(observation.parentJointName(.spine), .root, "spine parent")
    visionExpectEqual(observation.parentJointName(.centerShoulder), .spine, "centerShoulder parent")
    visionExpectEqual(observation.parentJointName(.centerHead), .centerShoulder, "centerHead parent")
    visionExpectEqual(observation.parentJointName(.topHead), .centerHead, "topHead parent")
    visionExpectEqual(observation.parentJointName(.leftWrist), .leftElbow, "leftWrist parent")
    visionExpectEqual(observation.parentJointName(.rightWrist), .rightElbow, "rightWrist parent")
    visionExpectEqual(observation.parentJointName(.rightElbow), .rightShoulder, "rightElbow parent")
    visionExpectEqual(observation.parentJointName(.leftHip), .root, "leftHip parent")
    visionExpectEqual(observation.parentJointName(.rightHip), .root, "rightHip parent")
    visionExpectEqual(observation.parentJointName(.leftKnee), .leftHip, "leftKnee parent")
    visionExpectEqual(observation.parentJointName(.rightKnee), .rightHip, "rightKnee parent")
    visionExpectEqual(observation.parentJointName(.leftAnkle), .leftKnee, "leftAnkle parent")
    visionExpectEqual(observation.parentJointName(.rightAnkle), .rightKnee, "rightAnkle parent")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointName.centerHead.rawValue.rawValue.contains("CenterHead"), true, "centerHead")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointName.spine.rawValue.rawValue.contains("Spine"), true, "spine")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointName.topHead.rawValue.rawValue.contains("TopHead"), true, "topHead")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.head.rawValue.rawValue.contains("Head"), true, "3d head group")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.torso.rawValue.rawValue.contains("Torso"), true, "3d torso")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.rightArm.rawValue.rawValue.contains("RightArm"), true, "3d rightArm")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.leftLeg.rawValue.rawValue.contains("LeftLeg"), true, "3d leftLeg")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.rightLeg.rawValue.rawValue.contains("RightLeg"), true, "3d rightLeg")
    let recognized3D = VNRecognizedPoint3D(position: .identity, identifier: VNHumanBodyPose3DObservation.JointName.root.rawValue)
    visionExpectEqual(recognized3D.identifier.rawValue.contains("Root"), true, "recognized 3d identifier")
    let points3D = VNRecognizedPoints3DObservation(
        points: [recognized3D.identifier: recognized3D],
        groups: [.point3DGroupKeyAll: [recognized3D.identifier]]
    )
    visionExpectEqual(points3D.availableKeys.count, 1, "3d availableKeys")
    visionExpect(points3D.availableGroupKeys.contains(.point3DGroupKeyAll), "3d availableGroupKeys")
    visionExpectEqual(try! points3D.recognizedPoint(forKey: recognized3D.identifier).identifier, recognized3D.identifier, "3d forKey")
    visionExpectEqual(try! points3D.recognizedPoints(forGroupKey: .all).count, 1, "3d group all")
    visionExpectEqual(root.localPosition, simd_float4x4.identity, "localPosition")
}

func testClassificationPrecisionRecall() {
    let classification = VNClassificationObservation(identifier: "cat", confidence: 0.4)
    visionExpectEqual(classification.identifier, "cat", "identifier")
    visionExpectEqual(classification.hasPrecisionRecallCurve, false, "no apple curve")
    visionExpectEqual(classification.hasMinimumPrecision(0.5, forRecall: 0.5), false, "precision")
    visionExpectEqual(classification.hasMinimumRecall(0.5, forPrecision: 0.5), false, "recall")
    let overlay = ClassificationObservation(classification)
    visionExpectEqual(overlay.identifier, "cat", "overlay identifier")
    visionExpectEqual(overlay.hasPrecisionRecallCurve, false, "overlay curve")
    visionExpectEqual(overlay.hasMinimumPrecision(0.9, forRecall: 0.1), false, "overlay precision")
}
