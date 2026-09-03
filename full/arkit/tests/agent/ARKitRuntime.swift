import Foundation
import ARKit

private final class SessionProbe: NSObject, ARSessionDelegate {
    var failures: [ARError.Code] = []

    func session(_ session: ARSession, didFailWithError error: any Error) {
        _ = session
        if let error = error as? ARError {
            failures.append(error.code)
        }
    }
}

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

private func requireUnsupported(_ error: Error, file: StaticString = #file, line: UInt = #line) {
    guard let error = error as? ARError else {
        fatalError("expected ARError at \(file):\(line)")
    }
    require(error.code == .unsupportedConfiguration, "expected unsupportedConfiguration")
    require(error.errorCode == ARError.unsupportedConfiguration.rawValue, "errorCode mismatch")
    require(ARError.errorDomain == ARErrorDomain, "error domain mismatch")
    require(ARErrorDomain == "com.apple.arkit.error", "ARErrorDomain string mismatch")
}

func runARKitRuntime() async {
        require(ARErrorDomain == ARError.errorDomain, "domain property mismatch")
        let sensor = ARError(.sensorUnavailable)
        require(sensor.code == .sensorUnavailable, "code storage")
        require(sensor.errorCode == 101, "sensorUnavailable raw value")
        require(ARError.cameraUnauthorized.rawValue == 103, "cameraUnauthorized raw value")
        require(ARError.worldTrackingFailed.rawValue == 200, "worldTrackingFailed raw value")
        require(ARError.invalidWorldMap.rawValue == 302, "invalidWorldMap raw value")
        require(ARError.fileIOFailed.rawValue == 500, "fileIOFailed raw value")
        require(ARError(.unsupportedConfiguration) == ARError(.unsupportedConfiguration), "error equality")
        require(ARError.Code.unsupportedConfiguration ~= ARError(.unsupportedConfiguration), "pattern match")
        require(ARError.Code.sensorFailed ~= ARError(.sensorFailed), "sensorFailed match")
        _ = ARError(.requestFailed).localizedDescription
        _ = ARError(.requestFailed).hashValue
        _ = ARError.Code.geoTrackingFailed.hashValue

        require(!ARConfiguration.isSupported, "base configuration must be unsupported")
        require(!ARWorldTrackingConfiguration.isSupported, "world tracking unsupported")
        require(!AROrientationTrackingConfiguration.isSupported, "orientation tracking unsupported")
        require(!ARFaceTrackingConfiguration.isSupported, "face tracking unsupported")
        require(!ARImageTrackingConfiguration.isSupported, "image tracking unsupported")
        require(!ARObjectScanningConfiguration.isSupported, "object scanning unsupported")
        require(!ARBodyTrackingConfiguration.isSupported, "body tracking unsupported")
        require(!ARPositionalTrackingConfiguration.isSupported, "positional tracking unsupported")
        require(!ARGeoTrackingConfiguration.isSupported, "geo tracking unsupported")
        require(ARWorldTrackingConfiguration.supportedVideoFormats.isEmpty, "no video formats")
        require(ARWorldTrackingConfiguration.recommendedVideoFormatFor4KResolution == nil, "no 4K format")
        require(
            ARWorldTrackingConfiguration.recommendedVideoFormatForHighResolutionFrameCapturing == nil,
            "no hi-res format"
        )
        require(
            !ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation),
            "frame semantics unsupported"
        )
        require(
            !ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh),
            "scene reconstruction unsupported"
        )
        require(!ARWorldTrackingConfiguration.supportsAppClipCodeTracking, "app clip tracking")
        require(!ARWorldTrackingConfiguration.supportsUserFaceTracking, "user face tracking")
        require(ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces == 0, "no tracked faces")
        require(!ARFaceTrackingConfiguration.supportsWorldTracking, "face world tracking")
        require(!ARBodyTrackingConfiguration.supportsAppClipCodeTracking, "body app clip")
        require(!ARGeoTrackingConfiguration.supportsAppClipCodeTracking, "geo app clip")
        require(!ARPlaneAnchor.isClassificationSupported, "plane classification")

        let world = ARWorldTrackingConfiguration()
        world.planeDetection = [.horizontal, .vertical]
        require(world.planeDetection.contains(.horizontal), "horizontal plane flag")
        require(world.planeDetection.contains(.vertical), "vertical plane flag")
        require(!world.planeDetection.isEmpty, "plane detection nonempty")
        require(world.planeDetection.isSuperset(of: .horizontal), "superset")
        let subtracted = world.planeDetection.subtracting(.vertical)
        require(subtracted == .horizontal, "subtracting vertical")
        world.environmentTexturing = .none
        world.isLightEstimationEnabled = true
        world.worldAlignment = .gravity
        world.sceneReconstruction = []
        require(world.sceneReconstruction.isEmpty, "no scene reconstruction")
        world.frameSemantics = [.bodyDetection]
        require(!ARWorldTrackingConfiguration.supportsFrameSemantics(world.frameSemantics), "semantics")
        let copied = world.copy() as! ARWorldTrackingConfiguration
        require(copied.planeDetection == world.planeDetection, "configuration copy")
        require(copied !== world, "copy identity")

        var options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        options.formUnion(.stopTrackedRaycasts)
        require(options.contains(.resetTracking), "reset tracking option")
        require(options.contains(.removeExistingAnchors), "remove anchors option")
        options.subtract(.stopTrackedRaycasts)
        require(!options.contains(.stopTrackedRaycasts), "subtracted raycast option")
        _ = ARSession.RunOptions()
        _ = ARSession.RunOptions(arrayLiteral: .resetSceneReconstruction)
        _ = ARSession.RunOptions([.resetTracking, .removeExistingAnchors])

        var hitTypes: ARHitTestResult.ResultType = [.featurePoint, .existingPlaneUsingExtent]
        require(hitTypes.contains(.featurePoint), "feature point hit type")
        hitTypes.formIntersection(.featurePoint)
        require(hitTypes == .featurePoint, "intersection")

        var semantics = ARConfiguration.FrameSemantics.personSegmentation
        semantics.formUnion(.sceneDepth)
        require(semantics.contains(.personSegmentation), "person segmentation bit")
        require(!semantics.isDisjoint(with: .sceneDepth), "not disjoint")

        var reconstruction: ARConfiguration.SceneReconstruction = [.mesh]
        reconstruction.insert(.meshWithClassification)
        require(reconstruction.contains(.meshWithClassification), "mesh classification bit")

        require(ARConfiguration.WorldAlignment.gravity.rawValue == 0, "gravity alignment")
        require(ARConfiguration.WorldAlignment(rawValue: 2) == .camera, "camera alignment")
        require(ARWorldTrackingConfiguration.EnvironmentTexturing(rawValue: 1) == .manual, "manual texturing")
        require(ARRaycastQuery.Target(rawValue: 2) == .estimatedPlane, "estimated plane target")
        require(ARRaycastQuery.TargetAlignment(rawValue: 1) == .horizontal, "horizontal alignment")
        require(ARCoachingOverlayView.Goal(rawValue: 1) == .horizontalPlane, "coaching goal")
        require(ARConfidenceLevel.low < ARConfidenceLevel.high, "confidence order")
        require((ARConfidenceLevel.low...ARConfidenceLevel.high).contains(.medium), "confidence range")
        require(ARMeshClassification(rawValue: 2) == .floor, "mesh floor")
        require(ARGeometryPrimitiveType.triangle.rawValue == 1, "triangle primitive")
        require(ARFrame.WorldMappingStatus.notAvailable.rawValue == 0, "world mapping")
        require(ARFrame.SegmentationClass.person.rawValue == 1, "segmentation class")
        require(ARGeoTrackingStatus.State.notAvailable.rawValue == 0, "geo state")
        require(ARGeoTrackingStatus.Accuracy.undetermined.rawValue == 0, "geo accuracy")
        require(ARGeoAnchor.AltitudeSource.unknown.rawValue == 0, "altitude source")
        require(ARAppClipCodeAnchor.URLDecodingState.failed.rawValue == 2, "app clip decode")
        require(ARMatteGenerator.Resolution.half.rawValue == 1, "matte resolution")
        require(ARSession.CollaborationData.Priority.critical.rawValue == 0, "collaboration priority")
        require(ARPlaneAnchor.Alignment.horizontal.rawValue == 0, "plane alignment")

        let shapes: [ARFaceAnchor.BlendShapeLocation] = [
            .browDownLeft, .browDownRight, .browInnerUp, .browOuterUpLeft, .browOuterUpRight,
            .cheekPuff, .cheekSquintLeft, .cheekSquintRight,
            .eyeBlinkLeft, .eyeBlinkRight, .eyeLookDownLeft, .eyeLookDownRight,
            .eyeLookInLeft, .eyeLookInRight, .eyeLookOutLeft, .eyeLookOutRight,
            .eyeLookUpLeft, .eyeLookUpRight, .eyeSquintLeft, .eyeSquintRight,
            .eyeWideLeft, .eyeWideRight,
            .jawForward, .jawLeft, .jawOpen, .jawRight,
            .mouthClose, .mouthDimpleLeft, .mouthDimpleRight, .mouthFrownLeft, .mouthFrownRight,
            .mouthFunnel, .mouthLeft, .mouthLowerDownLeft, .mouthLowerDownRight,
            .mouthPressLeft, .mouthPressRight, .mouthPucker, .mouthRight,
            .mouthRollLower, .mouthRollUpper, .mouthShrugLower, .mouthShrugUpper,
            .mouthSmileLeft, .mouthSmileRight, .mouthStretchLeft, .mouthStretchRight,
            .mouthUpperUpLeft, .mouthUpperUpRight, .noseSneerLeft, .noseSneerRight, .tongueOut,
        ]
        require(shapes.count == 52, "blend shape count")
        require(ARFaceAnchor.BlendShapeLocation.eyeBlinkLeft.rawValue == "eyeBlink_L", "blend raw value")
        require(
            ARFaceAnchor.BlendShapeLocation(rawValue: "eyeBlink_L") == .eyeBlinkLeft,
            "blend shape round trip"
        )

        require(ARSkeleton.JointName.head.rawValue == "head_joint", "head joint")
        require(ARSkeleton.JointName.root.rawValue == "root", "root joint")
        require(ARSkeleton.JointName.leftHand.rawValue == "left_hand_joint", "left hand")
        require(ARSkeleton.JointName.rightFoot.rawValue == "right_foot_joint", "right foot")
        require(ARSkeletonDefinition.defaultBody3D.jointCount == 8, "default skeleton joints")
        require(ARSkeletonDefinition.defaultBody3D.index(for: .head) >= 0, "head index")
        require(ARSkeletonDefinition.defaultBody2D.jointCount == 8, "2d skeleton")
        let skeleton = ARSkeleton3D()
        require(!skeleton.isJointTracked(0), "no tracked joints")
        require(skeleton.localTransform(for: .head) == nil, "no 3d joint transform")
        require(ARSkeleton2D().landmark(for: .root) == nil, "no 2d landmark")

        let transform = simd_float4x4.identity
        require(transform.columns.0.x == 1, "identity matrix")
        let namedAnchor = ARAnchor(name: "artwork", transform: transform)
        require(namedAnchor.name == "artwork", "anchor name")
        require(namedAnchor.transform == transform, "anchor transform")
        let copiedAnchor = ARAnchor(anchor: namedAnchor)
        require(copiedAnchor.identifier == namedAnchor.identifier, "anchor copy identifier")
        require((namedAnchor.copy() as! ARAnchor).identifier == namedAnchor.identifier, "nscopying")
        require(ARAnchor.supportsSecureCoding, "anchor coding flag")

        let probe = AREnvironmentProbeAnchor(transform: transform, extent: simd_float3(1, 1, 1))
        require(probe.extent == simd_float3(1, 1, 1), "probe extent")
        _ = AREnvironmentProbeAnchor(name: "probe", transform: transform, extent: simd_float3(repeating: 0.5))

        let query = ARRaycastQuery(
            origin: simd_float3(0, 0, 0),
            direction: simd_float3(0, -1, 0),
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        )
        require(query.target == .existingPlaneGeometry, "query target")
        require(query.targetAlignment == .horizontal, "query alignment")
        let query2 = ARRaycastQuery(
            origin: query.origin,
            direction: query.direction,
            allowingTarget: .estimatedPlane,
            alignment: .any
        )
        require(query2.target == .estimatedPlane, "allowingTarget alias")

        let session = ARSession()
        let delegate = SessionProbe()
        session.delegate = delegate
        require(session.identifier != UUID(uuidString: "00000000-0000-0000-0000-000000000000"), "session id")
        require(session.currentFrame == nil, "no fabricated frame")
        session.add(anchor: namedAnchor)
        session.remove(anchor: namedAnchor)
        session.add(anchor: namedAnchor)
        require(session.raycast(query).isEmpty, "raycast empty")
        require(session.trackedRaycast(query, updateHandler: { _ in }) == nil, "no tracked raycast")
        session.setWorldOrigin(relativeTransform: transform)

        session.run(world, options: [.resetTracking, .removeExistingAnchors])
        require(delegate.failures == [.unsupportedConfiguration], "run must fail closed")
        require(session.configuration != nil, "requested configuration retained")
        require(session.currentFrame == nil, "run does not invent a frame")
        session.pause()

        let capture = await withCheckedContinuation { continuation in
            session.captureHighResolutionFrame { frame, error in
                continuation.resume(returning: (frame, error))
            }
        }
        require(capture.0 == nil, "no high-res frame")
        requireUnsupported(capture.1!)

        do {
            _ = try await session.currentWorldMap()
            fatalError("currentWorldMap must fail closed")
        } catch {
            requireUnsupported(error)
        }
        do {
            _ = try await session.createReferenceObject(
                transform: transform,
                center: simd_float3(repeating: 0),
                extent: simd_float3(repeating: 1)
            )
            fatalError("createReferenceObject must fail closed")
        } catch {
            requireUnsupported(error)
        }

        let geoAvailable = await withCheckedContinuation { continuation in
            ARGeoTrackingConfiguration.checkAvailability { available, error in
                continuation.resume(returning: (available, error))
            }
        }
        require(geoAvailable.0 == false, "geo availability")
        require((geoAvailable.1 as? ARError)?.code == .geoTrackingNotAvailableAtLocation, "geo error")

        let coaching = ARCoachingOverlayView()
        coaching.goal = .horizontalPlane
        coaching.session = session
        coaching.setActive(true, animated: false)
        require(!coaching.isActive, "coaching stays inactive")
        require(coaching.goal == .horizontalPlane, "coaching goal stored")

        require(ARReferenceObject.archiveExtension == "arobject", "archive extension")
        require(ARReferenceImage.referenceImages(inGroupNamed: "detect", bundle: nil) == nil, "no image group")
        require(ARReferenceObject.referenceObjects(inGroupNamed: "objects", bundle: nil) == nil, "no object group")
        do {
            _ = try ARReferenceObject(archiveURL: URL(fileURLWithPath: "/tmp/missing.arobject"))
            fatalError("archive load must fail closed")
        } catch {
            require((error as? ARError)?.code == .fileIOFailed, "archive file IO")
        }
        do {
            _ = try ARReferenceObject().merging(ARReferenceObject())
            fatalError("merge must fail closed")
        } catch {
            require((error as? ARError)?.code == .objectMergeFailed, "merge failure")
        }

        let validated = await withCheckedContinuation { continuation in
            ARReferenceImage(physicalSize: CGSize(width: 0.2, height: 0.2)).validate { error in
                continuation.resume(returning: error)
            }
        }
        require((validated as? ARError)?.code == .invalidReferenceImage, "image validation")

        let faceGeometry = ARFaceGeometry(blendShapes: [:])
        require(faceGeometry == nil, "no Apple face topology")
        require(ARFaceGeometry().triangleCount == 0, "empty face geometry")
        require(ARPlaneGeometry().vertices.isEmpty, "empty plane geometry")
        require(ARWorldMap().anchors.isEmpty, "empty world map")
        require(ARGeoTrackingStatus().state == .notAvailable, "geo status")
        require(ARCamera().trackingState == .notAvailable, "camera tracking")
        require(ARFrame().hitTest(.zero, types: .featurePoint).isEmpty, "frame hit test")
        let frameQuery = ARFrame().raycastQuery(
            from: .zero,
            allowing: .estimatedPlane,
            alignment: .horizontal
        )
        require(frameQuery.direction == simd_float3(0, 0, -1), "fallback ray direction")

        let classification = ARPlaneAnchor.Classification.none(.notAvailable)
        require(classification == .none(.notAvailable), "plane classification none")
        require(ARPlaneAnchor.Classification.Status.undetermined != .unknown, "status distinct")
        require(ARCamera.TrackingState.limited(.initializing) != .normal, "tracking state")
        require(
            ARCamera.TrackingState.limited(.insufficientFeatures)
                == .limited(.insufficientFeatures),
            "limited reason"
        )

        print("ARKIT_AGENT_RUNTIME_OK")
}

let _arkitRuntimeLock = DispatchSemaphore(value: 0)
Task {
    await runARKitRuntime()
    _arkitRuntimeLock.signal()
}
_arkitRuntimeLock.wait()
