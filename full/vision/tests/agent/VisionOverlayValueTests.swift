#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testOverlayFaceAndDocumentValues() {
    let region = FaceObservation.Landmarks2D.Region(
        points: [NormalizedPoint(x: 0.2, y: 0.8)],
        pointsClassification: .closedPath,
        precisionEstimatesPerPoint: [0.7]
    )
    visionExpectEqual(region.pointsClassification, .closedPath, "points classification")
    visionExpectEqual(region.pointsInImageCoordinates(CGSize(width: 50, height: 50)).first, CGPoint(x: 10, y: 40), "region image")
    visionExpectEqual(region.points.count, 1, "region points")
    visionExpectEqual(region.precisionEstimatesPerPoint, [0.7], "precision")
    visionExpect(region.originatingRequestDescriptor == nil, "region descriptor")
    visionExpectEqual(region.description.contains("Region"), true, "region description")
    visionExpectEqual(FaceObservation.Landmarks2D.Region.PointsClassification.openPath.rawValue, "openPath", "openPath")
    visionExpectEqual(FaceObservation.Landmarks2D.Region.PointsClassification.disconnected.rawValue, "disconnected", "disconnected")
    let encodedRegion = try! JSONEncoder().encode(region)
    let decodedRegion = try! JSONDecoder().decode(FaceObservation.Landmarks2D.Region.self, from: encodedRegion)
    visionExpectEqual(decodedRegion.points.first?.x, 0.2, "region roundtrip")
    _ = region.hashValue
    visionExpect(region == decodedRegion, "region equal")

    let landmarks = FaceObservation.Landmarks2D(
        allPoints: region,
        faceContour: region,
        innerLips: region,
        leftEye: region,
        leftEyebrow: region,
        leftPupil: region,
        medianLine: region,
        nose: region,
        noseCrest: region,
        outerLips: region,
        rightEye: region,
        rightEyebrow: region,
        rightPupil: region
    )
    visionExpectEqual(landmarks.leftEye.points.count, 1, "left eye stored")
    visionExpectEqual(landmarks.rightPupil.points.count, 1, "right pupil")
    visionExpectEqual(landmarks.rightEye.points.count, 1, "right eye")
    visionExpectEqual(landmarks.leftEyebrow.points.count, 1, "left eyebrow")
    visionExpectEqual(landmarks.rightEyebrow.points.count, 1, "right eyebrow")
    visionExpectEqual(landmarks.leftPupil.points.count, 1, "left pupil")
    visionExpectEqual(landmarks.innerLips.points.count, 1, "inner lips")
    visionExpectEqual(landmarks.outerLips.points.count, 1, "outer lips")
    visionExpectEqual(landmarks.nose.points.count, 1, "nose")
    visionExpectEqual(landmarks.noseCrest.points.count, 1, "nose crest")
    visionExpectEqual(landmarks.medianLine.points.count, 1, "median")
    visionExpectEqual(landmarks.faceContour.points.count, 1, "face contour")
    visionExpectEqual(landmarks.allPoints.points.count, 1, "all points")
    visionExpectEqual(landmarks.description.contains("Landmarks"), true, "landmarks description")
    visionExpect(landmarks.originatingRequestDescriptor == nil, "landmarks descriptor")
    let encodedLandmarks = try! JSONEncoder().encode(landmarks)
    let decodedLandmarks = try! JSONDecoder().decode(FaceObservation.Landmarks2D.self, from: encodedLandmarks)
    visionExpectEqual(decodedLandmarks.nose.points.count, 1, "landmarks roundtrip")
    _ = landmarks.hashValue

    let quality = FaceObservation.CaptureQuality(score: 0.6)
    visionExpectEqual(quality.score, 0.6, "capture quality")
    visionExpectEqual(quality.description.contains("0.6") || quality.description.contains("Capture"), true, "quality description")
    visionExpect(quality.originatingRequestDescriptor == nil, "quality descriptor")
    let encodedQuality = try! JSONEncoder().encode(quality)
    let decodedQuality = try! JSONDecoder().decode(FaceObservation.CaptureQuality.self, from: encodedQuality)
    visionExpectEqual(decodedQuality.score, 0.6, "quality roundtrip")
    _ = quality.hashValue

    let face = FaceObservation(boundingBox: NormalizedRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4))
    visionExpectEqual(face.roll.value, 0, "default roll")
    visionExpectEqual(face.pitch.value, 0, "default pitch")
    visionExpectEqual(face.yaw.value, 0, "default yaw")
    visionExpect(face.landmarks == nil, "constructed face has no landmarks")
    visionExpect(face.captureQuality == nil, "no capture quality")
    visionExpectEqual(face.boundingBox.width, 0.3, "face bbox")
    visionExpectEqual(face.confidence, 1, "face confidence")
    visionExpectEqual(face.description.contains("Face"), true, "face description")
    visionExpect(face.uuid != UUID(), "face uuid")
    visionExpect(face.timeRange == nil, "face timeRange")
    visionExpect(face.originatingRequestDescriptor == nil, "face descriptor")
    _ = face.hashValue
    visionExpect(face == face, "face equal")
    let viaRevision = FaceObservation(boundingBox: .fullImage, revision: .revision3)
    visionExpectEqual(viaRevision.boundingBox, .fullImage, "revision init")

    let vnFace = VNFaceObservation(
        boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
        roll: NSNumber(value: 0.1),
        yaw: NSNumber(value: -0.2),
        pitch: NSNumber(value: 0.05),
        landmarks: VNFaceLandmarks2D(leftEye: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.2, y: 0.8)]))
    )
    let fromVN = FaceObservation(vnFace)
    visionExpectEqual(fromVN.yaw.value, -0.2, "from vn yaw")
    visionExpectEqual(fromVN.landmarks?.leftEye.points.count, 1, "from vn landmarks")

    let quad = [
        NormalizedPoint(x: 0, y: 1),
        NormalizedPoint(x: 1, y: 1),
        NormalizedPoint(x: 1, y: 0),
        NormalizedPoint(x: 0, y: 0),
    ]
    let contour = ContoursObservation.Contour(points: quad, indexPath: IndexPath(index: 0))
    let text = DocumentObservation.Container.Text(
        transcript: "Invoice 42",
        detectedData: [],
        textAlignment: .leading,
        boundingRegion: contour,
        lines: [
            RecognizedTextObservation(
                topLeft: quad[0],
                topRight: quad[1],
                bottomRight: quad[2],
                bottomLeft: quad[3],
                candidates: [RecognizedText(string: "Invoice 42", confidence: 0.8)]
            )
        ],
        words: []
    )
    visionExpectEqual(text.transcript, "Invoice 42", "document text")
    visionExpectEqual(text.boundingRegion(for: text.transcript.startIndex..<text.transcript.endIndex)?.pointCount, 4, "range region")
    visionExpectEqual(text.boundingRegion.pointCount, 4, "text boundingRegion")
    visionExpectEqual(text.textAlignment, .leading, "alignment leading")
    visionExpectEqual(text.detectedData.count, 0, "detectedData")
    visionExpectEqual(text.lines.count, 1, "lines")
    visionExpectEqual(text.words?.count, 0, "words")
    visionExpectEqual(DocumentObservation.Container.Text.Alignment.center.rawValue, "center", "center")
    visionExpectEqual(DocumentObservation.Container.Text.Alignment.trailing.rawValue, "trailing", "trailing")
    let encodedAlign = try! JSONEncoder().encode(DocumentObservation.Container.Text.Alignment.leading)
    visionExpect(try! JSONDecoder().decode(DocumentObservation.Container.Text.Alignment.self, from: encodedAlign) == .leading, "align roundtrip")

    let match = DocumentObservation.Container.DataDetectorMatch(
        boundingRegion: contour,
        match: DataDetector.Match(matchType: "number", matchedString: "42")
    )
    visionExpectEqual(match.match.matchedString, "42", "detector match")
    visionExpectEqual(match.boundingRegion.pointCount, 4, "match region")
    _ = match.hashValue
    visionExpect(match == match, "match equal")

    let nested = DocumentObservation.Container()
    let cell = DocumentObservation.Container.Table.Cell(columnRange: 0...0, rowRange: 0...0, content: nested)
    visionExpectEqual(cell.content.text.transcript, "", "cell content")
    visionExpectEqual(cell.columnRange, 0...0, "columnRange")
    let table = DocumentObservation.Container.Table(boundingRegion: contour, rows: [[cell]], columns: [[cell]])
    visionExpectEqual(table.cell(row: 0, col: 0)?.rowRange, 0...0, "table cell")
    visionExpect(table.cell(row: 3, col: 0) == nil, "missing cell")
    visionExpectEqual(table.rows.count, 1, "rows")
    visionExpectEqual(table.columns.count, 1, "columns")
    visionExpectEqual(table.boundingRegion.pointCount, 4, "table region")

    let listItem = DocumentObservation.Container.List.Item(
        itemString: "A",
        markerType: .bullet,
        markerString: "•",
        content: nested
    )
    visionExpectEqual(listItem.itemString, "A", "itemString")
    visionExpectEqual(listItem.markerString, "•", "markerString")
    visionExpectEqual(listItem.content.text.transcript, "", "item content")
    let list = DocumentObservation.Container.List(boundingRegion: contour, items: [listItem])
    visionExpectEqual(list.items.first?.markerType, .bullet, "list marker")
    visionExpectEqual(list.boundingRegion.pointCount, 4, "list region")
    visionExpectEqual(Set(DocumentObservation.Container.List.Marker.allCases).count, 7, "marker catalog")
    visionExpectEqual(DocumentObservation.Container.List.Marker.lowercaseLatin.rawValue, "lowercaseLatin", "lower")
    visionExpectEqual(DocumentObservation.Container.List.Marker.uppercaseLatin.rawValue, "uppercaseLatin", "upper")
    visionExpectEqual(DocumentObservation.Container.List.Marker.compositeDecimal.rawValue, "compositeDecimal", "composite")
    visionExpectEqual(DocumentObservation.Container.List.Marker.decorativeDecimal.rawValue, "decorativeDecimal", "decorative")
    visionExpectEqual(DocumentObservation.Container.List.Marker.hyphen.rawValue, "hyphen", "hyphen")
    visionExpectEqual(DocumentObservation.Container.List.Marker.decimal.rawValue, "decimal", "decimal")
    let encodedMarker = try! JSONEncoder().encode(DocumentObservation.Container.List.Marker.bullet)
    visionExpect(try! JSONDecoder().decode(DocumentObservation.Container.List.Marker.self, from: encodedMarker) == .bullet, "marker roundtrip")

    let container = DocumentObservation.Container(
        boundingRegion: contour,
        text: text,
        paragraphs: [text],
        lists: [list],
        title: text,
        tables: [table],
        barcodes: []
    )
    visionExpectEqual(container.paragraphs.count, 1, "paragraphs")
    visionExpectEqual(container.lists.count, 1, "lists")
    visionExpectEqual(container.title?.transcript, "Invoice 42", "title")
    visionExpectEqual(container.tables.count, 1, "tables")
    visionExpectEqual(container.barcodes.count, 0, "barcodes")
    visionExpectEqual(container.text.transcript, "Invoice 42", "container text")
    visionExpectEqual(container.boundingRegion.pointCount, 4, "container region")
    _ = container.hashValue

    let document = DocumentObservation(document: container)
    visionExpectEqual(document.document.text.transcript, "Invoice 42", "document observation")
    visionExpectEqual(document.confidence, 1, "document confidence")
    visionExpectEqual(document.description.contains("Invoice"), true, "document description")
    visionExpect(document.uuid != UUID(), "document uuid")
    visionExpect(document.timeRange == nil, "document timeRange")
    visionExpect(document.originatingRequestDescriptor == nil, "document descriptor")
    _ = document.hashValue
    visionExpect(document == document, "document equal")
}

func testOverlayPoseValueTypes() {
    let joint = Joint(location: NormalizedPoint(x: 0.5, y: 0.5), confidence: 0.9, jointName: "wrist")
    let other = Joint(location: NormalizedPoint(x: 0.5, y: 0.6), confidence: 0.8, jointName: "indexTip")
    visionExpect(abs(joint.distance(to: other) - 0.1) < 1e-9, "joint distance")
    let hand = HumanHandPoseObservation(joints: [.wrist: joint, .indexTip: other], chirality: .left)
    visionExpectEqual(hand.chirality, .left, "overlay chirality")
    visionExpectEqual(hand.joint(for: .wrist)?.confidence, 0.9, "hand joint")
    visionExpect(hand.allJoints(in: .indexFinger)[.indexTip] != nil, "index group")
    visionExpect(hand.availableJointNames.contains(.wrist), "available joints")
    do {
        _ = try hand.keypoints
        visionExpect(false, "keypoints fail closed")
    } catch {
        visionExpect(true, "keypoints throw")
    }

    let bodyJoint = Joint(location: NormalizedPoint(x: 0.5, y: 0.9), confidence: 1, jointName: "nose")
    let body = HumanBodyPoseObservation(joints: [.nose: bodyJoint, .leftWrist: joint])
    visionExpectEqual(body.joint(for: .nose)?.location.y, 0.9, "body nose")
    visionExpect(body.allJoints(in: .face)[.nose] != nil, "face group")
    visionExpectEqual(HumanBodyPoseObservation.JointName.allCases.contains(.root), true, "body cases")

    let animal = AnimalBodyPoseObservation(joints: [
        .nose: Joint(location: NormalizedPoint(x: 0.4, y: 0.8), confidence: 1, jointName: "nose"),
        .tailTop: Joint(location: NormalizedPoint(x: 0.8, y: 0.3), confidence: 0.4, jointName: "tailTop"),
    ])
    visionExpect(animal.allJoints(in: .tail)[.tailTop] != nil, "animal tail group")
    visionExpectEqual(AnimalBodyPoseObservation.JointsGroupName.allCases.count, 5, "animal groups")

    let j3d = Joint3D(
        position: simd_float4x4.translation(x: 0, y: 1, z: 0),
        localPosition: .identity,
        identifer: "root",
        parentJoint: "root"
    )
    visionExpectEqual(j3d.identifier, "root", "identifer spelling")
    let pose3d = HumanBodyPose3DObservation(
        joints: [.root: j3d],
        imagePoints: [.root: NormalizedPoint(x: 0.5, y: 0.1)],
        bodyHeight: 1.7,
        heightEstimationTechnique: .measured
    )
    visionExpectEqual(pose3d.bodyHeight, 1.7, "overlay body height")
    visionExpectEqual(pose3d.parentJointName(for: .leftWrist), .leftElbow, "overlay parent")
    visionExpectEqual(pose3d.pointInImage(for: .root)?.y, 0.1, "overlay image point")
    visionExpectEqual(pose3d.cameraRelativePosition(for: .root).columns.3.y, 1, "3d position")
    visionExpectEqual(Set(HumanBodyPoseObservation.JointName.allCases).count, 19, "overlay body joints")
    visionExpectEqual(HumanBodyPoseObservation.JointsGroupName.allCases.count, 6, "overlay body groups")
    visionExpectEqual(body.availableJointNames.contains(.nose), true, "overlay available")
    visionExpect(body.availableJointsGroupNames.contains(.torso), "overlay torso group")
    visionExpect(body.leftHand == nil, "leftHand")
    visionExpect(body.rightHand == nil, "rightHand")
    visionExpectEqual(body.description.contains("HumanBody"), true, "body description")
    visionExpect(body.uuid != UUID(), "body uuid")
    visionExpect(body.timeRange == nil, "body timeRange")
    visionExpect(body.originatingRequestDescriptor == nil, "body descriptor")
    visionExpectEqual(body.joint(for: .leftWrist)?.jointName, "wrist", "leftWrist overlay")
    visionExpect(body.allJoints(in: .torso)[.nose] == nil, "nose not torso")
    visionExpect(body.allJoints(in: .leftArm)[.leftWrist] != nil, "leftWrist in leftArm")
    visionExpect(body.allJoints(in: .rightArm).isEmpty, "empty rightArm")
    visionExpect(body.allJoints(in: .leftLeg).isEmpty, "empty leftLeg")
    visionExpect(body.allJoints(in: .rightLeg).isEmpty, "empty rightLeg")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightAnkle.rawValue, "rightAnkle", "rightAnkle")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightElbow.rawValue, "rightElbow", "rightElbow")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightWrist.rawValue, "rightWrist", "rightWrist")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftShoulder.rawValue, "leftShoulder", "leftShoulder")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightShoulder.rawValue, "rightShoulder", "rightShoulder")
    visionExpectEqual(HumanBodyPoseObservation.JointName.neck.rawValue, "neck", "neck")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftEar.rawValue, "leftEar", "leftEar")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftEye.rawValue, "leftEye", "leftEye")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftHip.rawValue, "leftHip", "leftHip")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftKnee.rawValue, "leftKnee", "leftKnee")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightEar.rawValue, "rightEar", "rightEar")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightEye.rawValue, "rightEye", "rightEye")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightHip.rawValue, "rightHip", "rightHip")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftAnkle.rawValue, "leftAnkle", "leftAnkle")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftElbow.rawValue, "leftElbow", "leftElbow")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftWrist.rawValue, "leftWrist", "leftWrist")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightKnee.rawValue, "rightKnee", "rightKnee")
    visionExpectEqual(HumanHandPoseObservation.JointName.allCases.count, 21, "overlay hand joints")
    visionExpectEqual(HumanHandPoseObservation.JointsGroupName.allCases.count, 5, "overlay hand groups")
    visionExpectEqual(hand.availableJointsGroupNames.contains(.thumb), true, "hand thumb group")
    visionExpectEqual(hand.description.contains("Hand"), true, "hand description")
    visionExpectEqual(HumanHandPoseObservation.Chirality.right.rawValue, "right", "right chirality")
    visionExpect(hand.allJoints(in: .thumb)[.wrist] != nil, "thumb includes wrist")
    visionExpect(hand.allJoints(in: .middleFinger)[.wrist] != nil, "middle includes wrist")
    visionExpect(hand.allJoints(in: .ringFinger)[.wrist] != nil, "ring includes wrist")
    visionExpect(hand.allJoints(in: .littleFinger)[.wrist] != nil, "little includes wrist")
    visionExpectEqual(HumanHandPoseObservation.JointName.ringDIP.rawValue, "ringDIP", "ringDIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.ringMCP.rawValue, "ringMCP", "ringMCP")
    visionExpectEqual(HumanHandPoseObservation.JointName.ringPIP.rawValue, "ringPIP", "ringPIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.ringTip.rawValue, "ringTip", "ringTip")
    visionExpectEqual(HumanHandPoseObservation.JointName.thumbIP.rawValue, "thumbIP", "thumbIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.thumbMP.rawValue, "thumbMP", "thumbMP")
    visionExpectEqual(HumanHandPoseObservation.JointName.indexDIP.rawValue, "indexDIP", "indexDIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.indexMCP.rawValue, "indexMCP", "indexMCP")
    visionExpectEqual(HumanHandPoseObservation.JointName.indexPIP.rawValue, "indexPIP", "indexPIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.thumbCMC.rawValue, "thumbCMC", "thumbCMC")
    visionExpectEqual(HumanHandPoseObservation.JointName.thumbTip.rawValue, "thumbTip", "thumbTip")
    visionExpectEqual(HumanHandPoseObservation.JointName.littleDIP.rawValue, "littleDIP", "littleDIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.littleMCP.rawValue, "littleMCP", "littleMCP")
    visionExpectEqual(HumanHandPoseObservation.JointName.littlePIP.rawValue, "littlePIP", "littlePIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.littleTip.rawValue, "littleTip", "littleTip")
    visionExpectEqual(HumanHandPoseObservation.JointName.middleDIP.rawValue, "middleDIP", "middleDIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.middleMCP.rawValue, "middleMCP", "middleMCP")
    visionExpectEqual(HumanHandPoseObservation.JointName.middlePIP.rawValue, "middlePIP", "middlePIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.middleTip.rawValue, "middleTip", "middleTip")
    visionExpectEqual(Set(AnimalBodyPoseObservation.JointName.allCases).count, 25, "overlay animal joints")
    visionExpect(animal.availableJointNames.contains(.nose), "animal available")
    visionExpect(animal.availableJointsGroupNames.contains(.head), "animal head group")
    visionExpectEqual(animal.description.contains("Animal"), true, "animal description")
    visionExpect(animal.allJoints(in: .head)[.nose] != nil, "animal head")
    visionExpect(animal.allJoints(in: .trunk)[.nose] != nil, "nose in trunk")
    visionExpect(animal.allJoints(in: .forelegs).isEmpty, "empty forelegs")
    visionExpect(animal.allJoints(in: .hindlegs).isEmpty, "empty hindlegs")
    visionExpectEqual(j3d.localPosition, simd_float4x4.identity, "joint3d local")
    visionExpectEqual(j3d.parentJoint, "root", "joint3d parent")
    visionExpectEqual(pose3d.availableJointNames.contains(.root), true, "3d overlay available")
    visionExpect(pose3d.availableJointsGroupNames.contains(.head), "3d overlay groups")
    visionExpectEqual(pose3d.heightEstimationTechnique, .measured, "technique")
    visionExpectEqual(pose3d.cameraOriginMatrix, .identity, "overlay camera")
    visionExpectEqual(pose3d.joint(for: .root)?.identifier, "root", "3d joint for")
    visionExpectEqual(HumanBodyPose3DObservation.EstimationTechnique.reference.rawValue, "reference", "reference technique")
    visionExpectEqual(pose3d.parentJointName(for: .root), .root, "root parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .spine), .root, "spine parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .centerShoulder), .spine, "centerShoulder parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .centerHead), .centerShoulder, "centerHead parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .topHead), .centerHead, "topHead parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .leftElbow), .leftShoulder, "leftElbow parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .leftShoulder), .centerShoulder, "leftShoulder parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .rightShoulder), .centerShoulder, "rightShoulder parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .rightElbow), .rightShoulder, "rightElbow parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .leftHip), .root, "leftHip parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .rightHip), .root, "rightHip parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .leftKnee), .leftHip, "leftKnee parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .rightKnee), .rightHip, "rightKnee parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .leftAnkle), .leftKnee, "leftAnkle parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .rightAnkle), .rightKnee, "rightAnkle parent overlay")
    visionExpectEqual(Set(HumanBodyPose3DObservation.JointName.allCases).count, 17, "overlay 3d joints")
    visionExpectEqual(HumanBodyPose3DObservation.JointsGroupName.allCases.count, 6, "overlay 3d groups")
    let encodedJoint = try! JSONEncoder().encode(joint)
    let decodedJoint = try! JSONDecoder().decode(Joint.self, from: encodedJoint)
    visionExpectEqual(decodedJoint.jointName, "wrist", "joint roundtrip")
    visionExpectEqual(joint.description, "wrist", "joint description")
    visionExpectEqual(joint.location.x, 0.5, "joint location")
    let vnBody = VNHumanBodyPoseObservation(hostJoints: [
        .nose: VNRecognizedPoint(x: 0.5, y: 0.9, confidence: 1, identifier: .bodyLandmarkKeyNose)
    ])
    let fromVNBody = HumanBodyPoseObservation(vnBody)
    visionExpectEqual(fromVNBody.joint(for: .nose)?.location.y, 0.9, "from vn body")
}

func testOverlayTextAndClassification() {
    let text = RecognizedText(string: "Hi", confidence: 0.7)
    visionExpectEqual(text.boundingBox(for: text.string.startIndex..<text.string.endIndex) == nil, true, "no layout")
    let observation = RecognizedTextObservation(
        topLeft: NormalizedPoint(x: 0, y: 1),
        topRight: NormalizedPoint(x: 1, y: 1),
        bottomRight: NormalizedPoint(x: 1, y: 0),
        bottomLeft: NormalizedPoint(x: 0, y: 0),
        candidates: [text, RecognizedText(string: "HI", confidence: 0.2)]
    )
    visionExpectEqual(observation.topCandidates(1).first?.string, "Hi", "overlay candidates")
    visionExpectEqual(observation.transcript, "Hi", "transcript")
    let classification = ClassificationObservation(identifier: "dog", confidence: 0.3)
    visionExpectEqual(classification.hasMinimumRecall(0.2, forPrecision: 0.9), false, "no curve")
    visionExpectEqual(text.string, "Hi", "text string")
    visionExpectEqual(text.confidence, 0.7, "text confidence")
    visionExpectEqual(text.description, "Hi", "text description")
    visionExpectEqual(observation.topLeft.y, 1, "topLeft")
    visionExpectEqual(observation.topRight.x, 1, "topRight")
    visionExpectEqual(observation.bottomRight.y, 0, "bottomRight")
    visionExpectEqual(observation.bottomLeft.x, 0, "bottomLeft")
    visionExpectEqual(observation.isTitle, false, "isTitle")
    visionExpectEqual(observation.textDirection, .leftToRight, "direction")
    visionExpectEqual(observation.boundingBox.width, 1, "overlay bbox")
    visionExpectEqual(classification.identifier, "dog", "class id")
    visionExpectEqual(classification.hasPrecisionRecallCurve, false, "class curve")
    visionExpectEqual(classification.hasMinimumPrecision(0.9, forRecall: 0.1), false, "class precision")
    visionExpectEqual(RecognizedTextObservation.Direction.rightToLeft.rawValue, "rightToLeft", "rtl")
    visionExpectEqual(RecognizedTextObservation.Direction.topToBottom.rawValue, "topToBottom", "ttb")
    visionExpectEqual(RecognizedTextObservation.Direction.bottomToTop.rawValue, "bottomToTop", "btt")
}

func testRevisionConstantsCatalog() {
    visionExpectEqual(VNDetectFaceLandmarksRequestRevision1, 1, "fl1")
    visionExpectEqual(VNDetectFaceLandmarksRequestRevision2, 2, "fl2")
    visionExpectEqual(VNDetectFaceLandmarksRequestRevision3, 3, "fl3")
    visionExpectEqual(VNDetectFaceCaptureQualityRequestRevision1, 1, "fcq1")
    visionExpectEqual(VNDetectFaceCaptureQualityRequestRevision2, 2, "fcq2")
    visionExpectEqual(VNDetectFaceCaptureQualityRequestRevision3, 3, "fcq3")
    visionExpectEqual(VNDetectHorizonRequestRevision1, 1, "horizon")
    visionExpectEqual(VNDetectTextRectanglesRequestRevision1, 1, "text rect")
    visionExpectEqual(VNDetectTrajectoriesRequestRevision1, 1, "traj")
    visionExpectEqual(VNCalculateImageAestheticsScoresRequestRevision1, 1, "aesthetics")
    visionExpectEqual(VNGenerateForegroundInstanceMaskRequestRevision1, 1, "fg mask")
    visionExpectEqual(VNGenerateObjectnessBasedSaliencyImageRequestRevision1, 1, "obj1")
    visionExpectEqual(VNGenerateObjectnessBasedSaliencyImageRequestRevision2, 2, "obj2")
    visionExpectEqual(VNGenerateOpticalFlowRequestRevision1, 1, "of1")
    visionExpectEqual(VNGenerateOpticalFlowRequestRevision2, 2, "of2")
    visionExpectEqual(VNGeneratePersonInstanceMaskRequestRevision1, 1, "person mask")
    visionExpectEqual(VNGeneratePersonSegmentationRequestRevision1, 1, "person seg")
    visionExpectEqual(VNRecognizeAnimalsRequestRevision1, 1, "animals1")
    visionExpectEqual(VNRecognizeAnimalsRequestRevision2, 2, "animals2")
    visionExpectEqual(VNTrackHomographicImageRegistrationRequestRevision1, 1, "track homo")
    visionExpectEqual(VNTrackOpticalFlowRequestRevision1, 1, "track of")
    visionExpectEqual(VNTrackRectangleRequestRevision1, 1, "track rect")
    visionExpectEqual(VNTrackTranslationalImageRegistrationRequestRevision1, 1, "track trans")
}
