import Foundation

open class VNRecognizedPointsObservation: VNObservation {
    var pointsByKey: [VNRecognizedPointKey: VNRecognizedPoint]
    var groupMembership: [VNRecognizedPointGroupKey: [VNRecognizedPointKey]]

    public var availableKeys: [VNRecognizedPointKey] { Array(pointsByKey.keys) }
    public var availableGroupKeys: [VNRecognizedPointGroupKey] { Array(groupMembership.keys) }

    public init(
        points: [VNRecognizedPointKey: VNRecognizedPoint] = [:],
        groups: [VNRecognizedPointGroupKey: [VNRecognizedPointKey]] = [:],
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.pointsByKey = points
        self.groupMembership = groups
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        pointsByKey = [:]
        groupMembership = [:]
        super.init(coder: coder)
    }

    public func recognizedPoint(forKey pointKey: VNRecognizedPointKey) throws -> VNRecognizedPoint {
        guard let point = pointsByKey[pointKey] else {
            throw vnMakeError(.invalidArgument, description: "unknown recognized point key")
        }
        return point
    }

    public func recognizedPoints(
        forGroupKey groupKey: VNRecognizedPointGroupKey
    ) throws -> [VNRecognizedPointKey: VNRecognizedPoint] {
        if groupKey == .all {
            return pointsByKey
        }
        guard let keys = groupMembership[groupKey] else {
            throw vnMakeError(.invalidArgument, description: "unknown recognized point group")
        }
        var output: [VNRecognizedPointKey: VNRecognizedPoint] = [:]
        for key in keys {
            if let point = pointsByKey[key] {
                output[key] = point
            }
        }
        return output
    }

    public func keypointsMultiArray() throws -> MLMultiArray {
        var floats: [Float] = []
        for key in availableKeys.sorted(by: { $0.rawValue < $1.rawValue }) {
            let point = pointsByKey[key]!
            floats.append(Float(point.x))
            floats.append(Float(point.y))
            floats.append(point.confidence)
        }
        return MLMultiArray(
            shape: [availableKeys.count, 3],
            data: floats.withUnsafeBufferPointer { Data(buffer: $0) }
        )
    }
}

open class VNRecognizedPoints3DObservation: VNObservation {
    var pointsByKey: [VNRecognizedPointKey: VNRecognizedPoint3D] = [:]
    var groupMembership: [VNRecognizedPointGroupKey: [VNRecognizedPointKey]] = [:]

    public var availableKeys: [VNRecognizedPointKey] { Array(pointsByKey.keys) }
    public var availableGroupKeys: [VNRecognizedPointGroupKey] { Array(groupMembership.keys) }

    public init(
        points: [VNRecognizedPointKey: VNRecognizedPoint3D] = [:],
        groups: [VNRecognizedPointGroupKey: [VNRecognizedPointKey]] = [:],
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.pointsByKey = points
        self.groupMembership = groups
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        pointsByKey = [:]
        groupMembership = [:]
        super.init(coder: coder)
    }

    public func recognizedPoint(forKey pointKey: VNRecognizedPointKey) throws -> VNRecognizedPoint3D {
        guard let point = pointsByKey[pointKey] else {
            throw vnMakeError(.invalidArgument, description: "unknown 3D point key")
        }
        return point
    }

    public func recognizedPoints(
        forGroupKey groupKey: VNRecognizedPointGroupKey
    ) throws -> [VNRecognizedPointKey: VNRecognizedPoint3D] {
        if groupKey == .all || groupKey == .point3DGroupKeyAll {
            return pointsByKey
        }
        guard let keys = groupMembership[groupKey] else {
            throw vnMakeError(.invalidArgument, description: "unknown 3D point group")
        }
        var output: [VNRecognizedPointKey: VNRecognizedPoint3D] = [:]
        for key in keys {
            if let point = pointsByKey[key] {
                output[key] = point
            }
        }
        return output
    }
}

open class VNHumanBodyPoseObservation: VNRecognizedPointsObservation {
    public struct JointName: RawRepresentable, Hashable, Sendable {
        public let rawValue: VNRecognizedPointKey
        public init(rawValue: VNRecognizedPointKey) { self.rawValue = rawValue }
        public static let leftAnkle = JointName(rawValue: .bodyLandmarkKeyLeftAnkle)
        public static let leftEar = JointName(rawValue: .bodyLandmarkKeyLeftEar)
        public static let leftElbow = JointName(rawValue: .bodyLandmarkKeyLeftElbow)
        public static let leftEye = JointName(rawValue: .bodyLandmarkKeyLeftEye)
        public static let leftHip = JointName(rawValue: .bodyLandmarkKeyLeftHip)
        public static let leftKnee = JointName(rawValue: .bodyLandmarkKeyLeftKnee)
        public static let leftShoulder = JointName(rawValue: .bodyLandmarkKeyLeftShoulder)
        public static let leftWrist = JointName(rawValue: .bodyLandmarkKeyLeftWrist)
        public static let neck = JointName(rawValue: .bodyLandmarkKeyNeck)
        public static let nose = JointName(rawValue: .bodyLandmarkKeyNose)
        public static let rightAnkle = JointName(rawValue: .bodyLandmarkKeyRightAnkle)
        public static let rightEar = JointName(rawValue: .bodyLandmarkKeyRightEar)
        public static let rightElbow = JointName(rawValue: .bodyLandmarkKeyRightElbow)
        public static let rightEye = JointName(rawValue: .bodyLandmarkKeyRightEye)
        public static let rightHip = JointName(rawValue: .bodyLandmarkKeyRightHip)
        public static let rightKnee = JointName(rawValue: .bodyLandmarkKeyRightKnee)
        public static let rightShoulder = JointName(rawValue: .bodyLandmarkKeyRightShoulder)
        public static let rightWrist = JointName(rawValue: .bodyLandmarkKeyRightWrist)
        public static let root = JointName(rawValue: .bodyLandmarkKeyRoot)

        public static let allCases: [JointName] = [
            .root, .neck, .nose, .leftEye, .rightEye, .leftEar, .rightEar,
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist,
            .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
        ]
    }

    public struct JointsGroupName: RawRepresentable, Hashable, Sendable {
        public let rawValue: VNRecognizedPointGroupKey
        public init(rawValue: VNRecognizedPointGroupKey) { self.rawValue = rawValue }
        public static let all = JointsGroupName(rawValue: .all)
        public static let face = JointsGroupName(rawValue: .bodyLandmarkRegionKeyFace)
        public static let leftArm = JointsGroupName(rawValue: .bodyLandmarkRegionKeyLeftArm)
        public static let leftLeg = JointsGroupName(rawValue: .bodyLandmarkRegionKeyLeftLeg)
        public static let rightArm = JointsGroupName(rawValue: .bodyLandmarkRegionKeyRightArm)
        public static let rightLeg = JointsGroupName(rawValue: .bodyLandmarkRegionKeyRightLeg)
        public static let torso = JointsGroupName(rawValue: .bodyLandmarkRegionKeyTorso)

        public static let allCases: [JointsGroupName] = [
            .all, .face, .torso, .leftArm, .rightArm, .leftLeg, .rightLeg,
        ]
    }

    public var availableJointNames: [JointName] {
        availableKeys.compactMap { key in JointName.allCases.first { $0.rawValue == key } }
    }

    public var availableJointsGroupNames: [JointsGroupName] {
        JointsGroupName.allCases.filter { group in
            group == .all || availableGroupKeys.contains(group.rawValue)
        }
    }

    public func recognizedPoint(_ jointName: JointName) throws -> VNRecognizedPoint {
        try recognizedPoint(forKey: jointName.rawValue)
    }

    public func recognizedPoints(_ jointsGroupName: JointsGroupName) throws -> [JointName: VNRecognizedPoint] {
        let mapped = try recognizedPoints(forGroupKey: jointsGroupName.rawValue)
        var output: [JointName: VNRecognizedPoint] = [:]
        for (key, point) in mapped {
            if let name = JointName.allCases.first(where: { $0.rawValue == key }) {
                output[name] = point
            }
        }
        return output
    }

    @_spi(OpenUIKitHost)
    public convenience init(hostJoints joints: [JointName: VNRecognizedPoint], confidence: VNConfidence = 1) {
        var points: [VNRecognizedPointKey: VNRecognizedPoint] = [:]
        for (name, point) in joints {
            points[name.rawValue] = point
        }
        var groups: [VNRecognizedPointGroupKey: [VNRecognizedPointKey]] = [:]
        groups[JointsGroupName.all.rawValue] = Array(points.keys)
        groups[JointsGroupName.face.rawValue] = [
            JointName.nose, .leftEye, .rightEye, .leftEar, .rightEar,
        ].map(\.rawValue)
        groups[JointsGroupName.torso.rawValue] = [
            JointName.root, .neck, .leftShoulder, .rightShoulder, .leftHip, .rightHip,
        ].map(\.rawValue)
        groups[JointsGroupName.leftArm.rawValue] = [
            JointName.leftShoulder, .leftElbow, .leftWrist,
        ].map(\.rawValue)
        groups[JointsGroupName.rightArm.rawValue] = [
            JointName.rightShoulder, .rightElbow, .rightWrist,
        ].map(\.rawValue)
        groups[JointsGroupName.leftLeg.rawValue] = [
            JointName.leftHip, .leftKnee, .leftAnkle,
        ].map(\.rawValue)
        groups[JointsGroupName.rightLeg.rawValue] = [
            JointName.rightHip, .rightKnee, .rightAnkle,
        ].map(\.rawValue)
        self.init(points: points, groups: groups, confidence: confidence)
    }
}

open class VNHumanHandPoseObservation: VNRecognizedPointsObservation {
    public struct JointName: RawRepresentable, Hashable, Sendable {
        public let rawValue: VNRecognizedPointKey
        public init(rawValue: VNRecognizedPointKey) { self.rawValue = rawValue }
        public static let wrist = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameWrist"))
        public static let thumbCMC = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameThumbCMC"))
        public static let thumbMP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameThumbMP"))
        public static let thumbIP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameThumbIP"))
        public static let thumbTip = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameThumbTip"))
        public static let indexMCP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameIndexMCP"))
        public static let indexPIP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameIndexPIP"))
        public static let indexDIP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameIndexDIP"))
        public static let indexTip = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameIndexTip"))
        public static let middleMCP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameMiddleMCP"))
        public static let middlePIP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameMiddlePIP"))
        public static let middleDIP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameMiddleDIP"))
        public static let middleTip = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameMiddleTip"))
        public static let ringMCP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameRingMCP"))
        public static let ringPIP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameRingPIP"))
        public static let ringDIP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameRingDIP"))
        public static let ringTip = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameRingTip"))
        public static let littleMCP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameLittleMCP"))
        public static let littlePIP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameLittlePIP"))
        public static let littleDIP = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameLittleDIP"))
        public static let littleTip = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointNameLittleTip"))

        public static let allCases: [JointName] = [
            .wrist,
            .thumbCMC, .thumbMP, .thumbIP, .thumbTip,
            .indexMCP, .indexPIP, .indexDIP, .indexTip,
            .middleMCP, .middlePIP, .middleDIP, .middleTip,
            .ringMCP, .ringPIP, .ringDIP, .ringTip,
            .littleMCP, .littlePIP, .littleDIP, .littleTip,
        ]
    }

    public struct JointsGroupName: RawRepresentable, Hashable, Sendable {
        public let rawValue: VNRecognizedPointGroupKey
        public init(rawValue: VNRecognizedPointGroupKey) { self.rawValue = rawValue }
        public static let all = JointsGroupName(rawValue: .all)
        public static let thumb = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanHandPoseObservationJointsGroupNameThumb"))
        public static let indexFinger = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanHandPoseObservationJointsGroupNameIndexFinger"))
        public static let middleFinger = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanHandPoseObservationJointsGroupNameMiddleFinger"))
        public static let ringFinger = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanHandPoseObservationJointsGroupNameRingFinger"))
        public static let littleFinger = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanHandPoseObservationJointsGroupNameLittleFinger"))

        public static let allCases: [JointsGroupName] = [
            .all, .thumb, .indexFinger, .middleFinger, .ringFinger, .littleFinger,
        ]
    }

    public let chirality: VNChirality

    public var availableJointNames: [JointName] {
        availableKeys.compactMap { key in JointName.allCases.first { $0.rawValue == key } }
    }

    public var availableJointsGroupNames: [JointsGroupName] {
        JointsGroupName.allCases.filter { group in
            group == .all || availableGroupKeys.contains(group.rawValue)
        }
    }

    public func recognizedPoint(_ jointName: JointName) throws -> VNRecognizedPoint {
        try recognizedPoint(forKey: jointName.rawValue)
    }

    public func recognizedPoints(_ jointsGroupName: JointsGroupName) throws -> [JointName: VNRecognizedPoint] {
        let mapped = try recognizedPoints(forGroupKey: jointsGroupName.rawValue)
        var output: [JointName: VNRecognizedPoint] = [:]
        for (key, point) in mapped {
            if let name = JointName.allCases.first(where: { $0.rawValue == key }) {
                output[name] = point
            }
        }
        return output
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostJoints joints: [JointName: VNRecognizedPoint],
        chirality: VNChirality = .unknown,
        confidence: VNConfidence = 1
    ) {
        var points: [VNRecognizedPointKey: VNRecognizedPoint] = [:]
        for (name, point) in joints {
            points[name.rawValue] = point
        }
        var groups: [VNRecognizedPointGroupKey: [VNRecognizedPointKey]] = [:]
        groups[JointsGroupName.all.rawValue] = Array(points.keys)
        groups[JointsGroupName.thumb.rawValue] = [JointName.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip].map(\.rawValue)
        groups[JointsGroupName.indexFinger.rawValue] = [JointName.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip].map(\.rawValue)
        groups[JointsGroupName.middleFinger.rawValue] = [JointName.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip].map(\.rawValue)
        groups[JointsGroupName.ringFinger.rawValue] = [JointName.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip].map(\.rawValue)
        groups[JointsGroupName.littleFinger.rawValue] = [JointName.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip].map(\.rawValue)
        self.init(points: points, groups: groups, chirality: chirality, confidence: confidence)
    }

    public init(
        points: [VNRecognizedPointKey: VNRecognizedPoint] = [:],
        groups: [VNRecognizedPointGroupKey: [VNRecognizedPointKey]] = [:],
        chirality: VNChirality = .unknown,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.chirality = chirality
        super.init(points: points, groups: groups, confidence: confidence, uuid: uuid)
    }

    public required init?(coder: NSCoder) {
        chirality = .unknown
        super.init(coder: coder)
    }
}

open class VNAnimalBodyPoseObservation: VNRecognizedPointsObservation {
    public struct JointName: RawRepresentable, Hashable, Sendable {
        public let rawValue: VNRecognizedPointKey
        public init(rawValue: VNRecognizedPointKey) { self.rawValue = rawValue }
        public static let leftBackElbow = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameLeftBackElbow"))
        public static let leftBackKnee = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameLeftBackKnee"))
        public static let leftBackPaw = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameLeftBackPaw"))
        public static let leftEarBottom = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameLeftEarBottom"))
        public static let leftEarMiddle = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameLeftEarMiddle"))
        public static let leftEarTop = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameLeftEarTop"))
        public static let leftEye = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameLeftEye"))
        public static let leftFrontElbow = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameLeftFrontElbow"))
        public static let leftFrontKnee = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameLeftFrontKnee"))
        public static let leftFrontPaw = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameLeftFrontPaw"))
        public static let neck = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameNeck"))
        public static let nose = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameNose"))
        public static let rightBackElbow = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameRightBackElbow"))
        public static let rightBackKnee = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameRightBackKnee"))
        public static let rightBackPaw = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameRightBackPaw"))
        public static let rightEarBottom = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameRightEarBottom"))
        public static let rightEarMiddle = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameRightEarMiddle"))
        public static let rightEarTop = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameRightEarTop"))
        public static let rightEye = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameRightEye"))
        public static let rightFrontElbow = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameRightFrontElbow"))
        public static let rightFrontKnee = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameRightFrontKnee"))
        public static let rightFrontPaw = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameRightFrontPaw"))
        public static let tailBottom = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameTailBottom"))
        public static let tailMiddle = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameTailMiddle"))
        public static let tailTop = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointNameTailTop"))

        public static let allCases: [JointName] = [
            .nose, .neck, .leftEye, .rightEye,
            .leftEarTop, .leftEarMiddle, .leftEarBottom,
            .rightEarTop, .rightEarMiddle, .rightEarBottom,
            .leftFrontElbow, .leftFrontKnee, .leftFrontPaw,
            .rightFrontElbow, .rightFrontKnee, .rightFrontPaw,
            .leftBackElbow, .leftBackKnee, .leftBackPaw,
            .rightBackElbow, .rightBackKnee, .rightBackPaw,
            .tailTop, .tailMiddle, .tailBottom,
        ]
    }

    public struct JointsGroupName: RawRepresentable, Hashable, Sendable {
        public let rawValue: VNRecognizedPointGroupKey
        public init(rawValue: VNRecognizedPointGroupKey) { self.rawValue = rawValue }
        public static let all = JointsGroupName(rawValue: .all)
        public static let forelegs = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNAnimalBodyPoseObservationJointsGroupNameForelegs"))
        public static let head = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNAnimalBodyPoseObservationJointsGroupNameHead"))
        public static let hindlegs = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNAnimalBodyPoseObservationJointsGroupNameHindlegs"))
        public static let tail = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNAnimalBodyPoseObservationJointsGroupNameTail"))
        public static let trunk = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNAnimalBodyPoseObservationJointsGroupNameTrunk"))

        public static let allCases: [JointsGroupName] = [.all, .head, .trunk, .forelegs, .hindlegs, .tail]
    }

    public var availableJointNames: [JointName] {
        availableKeys.compactMap { key in JointName.allCases.first { $0.rawValue == key } }
    }

    public var availableJointGroupNames: [JointsGroupName] {
        JointsGroupName.allCases.filter { group in
            group == .all || availableGroupKeys.contains(group.rawValue)
        }
    }

    public func recognizedPoint(_ jointName: JointName) throws -> VNRecognizedPoint {
        try recognizedPoint(forKey: jointName.rawValue)
    }

    public func recognizedPoints(_ jointsGroupName: JointsGroupName) throws -> [JointName: VNRecognizedPoint] {
        let mapped = try recognizedPoints(forGroupKey: jointsGroupName.rawValue)
        var output: [JointName: VNRecognizedPoint] = [:]
        for (key, point) in mapped {
            if let name = JointName.allCases.first(where: { $0.rawValue == key }) {
                output[name] = point
            }
        }
        return output
    }

    @_spi(OpenUIKitHost)
    public convenience init(hostJoints joints: [JointName: VNRecognizedPoint], confidence: VNConfidence = 1) {
        var points: [VNRecognizedPointKey: VNRecognizedPoint] = [:]
        for (name, point) in joints {
            points[name.rawValue] = point
        }
        var groups: [VNRecognizedPointGroupKey: [VNRecognizedPointKey]] = [:]
        groups[JointsGroupName.all.rawValue] = Array(points.keys)
        groups[JointsGroupName.head.rawValue] = [
            JointName.nose, .neck, .leftEye, .rightEye,
            .leftEarTop, .leftEarMiddle, .leftEarBottom,
            .rightEarTop, .rightEarMiddle, .rightEarBottom,
        ].map(\.rawValue)
        groups[JointsGroupName.trunk.rawValue] = [JointName.neck, .nose].map(\.rawValue)
        groups[JointsGroupName.forelegs.rawValue] = [
            JointName.leftFrontElbow, .leftFrontKnee, .leftFrontPaw,
            .rightFrontElbow, .rightFrontKnee, .rightFrontPaw,
        ].map(\.rawValue)
        groups[JointsGroupName.hindlegs.rawValue] = [
            JointName.leftBackElbow, .leftBackKnee, .leftBackPaw,
            .rightBackElbow, .rightBackKnee, .rightBackPaw,
        ].map(\.rawValue)
        groups[JointsGroupName.tail.rawValue] = [JointName.tailTop, .tailMiddle, .tailBottom].map(\.rawValue)
        self.init(points: points, groups: groups, confidence: confidence)
    }
}

open class VNHumanBodyPose3DObservation: VNObservation {
    public enum HeightEstimation: Int, CaseIterable, Sendable {
        case reference = 0
        case measured = 1
    }

    public struct JointName: RawRepresentable, Hashable, Sendable {
        public let rawValue: VNRecognizedPointKey
        public init(rawValue: VNRecognizedPointKey) { self.rawValue = rawValue }
        public static let centerHead = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameCenterHead"))
        public static let centerShoulder = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameCenterShoulder"))
        public static let leftAnkle = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameLeftAnkle"))
        public static let leftElbow = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameLeftElbow"))
        public static let leftHip = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameLeftHip"))
        public static let leftKnee = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameLeftKnee"))
        public static let leftShoulder = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameLeftShoulder"))
        public static let leftWrist = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameLeftWrist"))
        public static let rightAnkle = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameRightAnkle"))
        public static let rightElbow = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameRightElbow"))
        public static let rightHip = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameRightHip"))
        public static let rightKnee = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameRightKnee"))
        public static let rightShoulder = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameRightShoulder"))
        public static let rightWrist = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameRightWrist"))
        public static let root = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameRoot"))
        public static let spine = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameSpine"))
        public static let topHead = JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointNameTopHead"))

        public static let allCases: [JointName] = [
            .root, .spine, .centerShoulder, .centerHead, .topHead,
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist,
            .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
        ]
    }

    public struct JointsGroupName: RawRepresentable, Hashable, Sendable {
        public let rawValue: VNRecognizedPointGroupKey
        public init(rawValue: VNRecognizedPointGroupKey) { self.rawValue = rawValue }
        public static let all = JointsGroupName(rawValue: .all)
        public static let head = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanBodyPose3DObservationJointsGroupNameHead"))
        public static let leftArm = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanBodyPose3DObservationJointsGroupNameLeftArm"))
        public static let leftLeg = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanBodyPose3DObservationJointsGroupNameLeftLeg"))
        public static let rightArm = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanBodyPose3DObservationJointsGroupNameRightArm"))
        public static let rightLeg = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanBodyPose3DObservationJointsGroupNameRightLeg"))
        public static let torso = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "VNHumanBodyPose3DObservationJointsGroupNameTorso"))

        public static let allCases: [JointsGroupName] = [.all, .head, .torso, .leftArm, .rightArm, .leftLeg, .rightLeg]
    }

    public let heightEstimation: HeightEstimation
    public let bodyHeight: Float
    public let cameraOriginMatrix: simd_float4x4
    var points3D: [JointName: VNHumanBodyRecognizedPoint3D]
    var imagePoints: [JointName: VNPoint]

    public var availableJointNames: [JointName] { Array(points3D.keys) }
    public var availableJointsGroupNames: [JointsGroupName] { JointsGroupName.allCases }

    public init(
        points: [JointName: VNHumanBodyRecognizedPoint3D] = [:],
        imagePoints: [JointName: VNPoint] = [:],
        heightEstimation: HeightEstimation = .reference,
        bodyHeight: Float = 0,
        cameraOriginMatrix: simd_float4x4 = .identity,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.points3D = points
        self.imagePoints = imagePoints
        self.heightEstimation = heightEstimation
        self.bodyHeight = bodyHeight
        self.cameraOriginMatrix = cameraOriginMatrix
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        points3D = [:]
        imagePoints = [:]
        heightEstimation = .reference
        bodyHeight = 0
        cameraOriginMatrix = .identity
        super.init(coder: coder)
    }

    public func recognizedPoint(_ jointName: JointName) throws -> VNHumanBodyRecognizedPoint3D {
        guard let point = points3D[jointName] else {
            throw vnMakeError(.invalidArgument, description: "unknown 3D joint")
        }
        return point
    }

    public func recognizedPoints(_ jointsGroupName: JointsGroupName) throws -> [JointName: VNHumanBodyRecognizedPoint3D] {
        let names = Self.jointNames(in: jointsGroupName)
        var output: [JointName: VNHumanBodyRecognizedPoint3D] = [:]
        for name in names {
            if let point = points3D[name] {
                output[name] = point
            }
        }
        return output
    }

    public func pointInImage(_ jointName: JointName) throws -> VNPoint {
        guard let point = imagePoints[jointName] else {
            throw vnMakeError(.invalidArgument, description: "unknown 3D joint image point")
        }
        return point
    }

    public func parentJointName(_ jointName: JointName) -> JointName? {
        Self.parent(of: jointName)
    }

    public func cameraRelativePosition(_ jointName: JointName) throws -> simd_float4x4 {
        try recognizedPoint(jointName).position
    }

    static func jointNames(in group: JointsGroupName) -> [JointName] {
        switch group {
        case .all:
            return JointName.allCases
        case .head:
            return [.topHead, .centerHead]
        case .torso:
            return [.root, .spine, .centerShoulder, .leftHip, .rightHip]
        case .leftArm:
            return [.leftShoulder, .leftElbow, .leftWrist]
        case .rightArm:
            return [.rightShoulder, .rightElbow, .rightWrist]
        case .leftLeg:
            return [.leftHip, .leftKnee, .leftAnkle]
        case .rightLeg:
            return [.rightHip, .rightKnee, .rightAnkle]
        default:
            return []
        }
    }

    static func parent(of joint: JointName) -> JointName? {
        switch joint {
        case .root: return nil
        case .spine: return .root
        case .centerShoulder: return .spine
        case .centerHead, .leftShoulder, .rightShoulder: return .centerShoulder
        case .topHead: return .centerHead
        case .leftElbow: return .leftShoulder
        case .leftWrist: return .leftElbow
        case .rightElbow: return .rightShoulder
        case .rightWrist: return .rightElbow
        case .leftHip: return .root
        case .rightHip: return .root
        case .leftKnee: return .leftHip
        case .leftAnkle: return .leftKnee
        case .rightKnee: return .rightHip
        case .rightAnkle: return .rightKnee
        default: return .root
        }
    }
}

open class VNHumanBodyRecognizedPoint3D: VNRecognizedPoint3D {
    public let localPosition: simd_float4x4
    public let parentJoint: VNHumanBodyPose3DObservation.JointName

    public init(
        position: simd_float4x4,
        localPosition: simd_float4x4,
        identifier: VNRecognizedPointKey,
        parentJoint: VNHumanBodyPose3DObservation.JointName
    ) {
        self.localPosition = localPosition
        self.parentJoint = parentJoint
        super.init(position: position, identifier: identifier)
    }

    public required init?(coder: NSCoder) {
        localPosition = .identity
        parentJoint = .root
        super.init(coder: coder)
    }
}
