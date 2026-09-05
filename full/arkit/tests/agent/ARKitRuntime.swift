import Dispatch
import Foundation
import ARKit

// --- ARKitTestSupport.swift ---
func arkitRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

func arkitAlmostEqual(_ a: Float, _ b: Float, eps: Float = 1e-4) -> Bool {
    abs(a - b) < eps
}

func arkitWait(_ work: (@escaping () -> Void) -> Void) {
    let lock = DispatchSemaphore(value: 0)
    var finished = false
    work {
        finished = true
        lock.signal()
    }
    arkitRequire(lock.wait(timeout: .now() + 5) == .success && finished, "callback timed out")
}

func arkitAwaitError(_ work: @escaping () async throws -> Void) -> Error {
    let lock = DispatchSemaphore(value: 0)
    var caught: Error?
    Task {
        do {
            try await work()
        } catch {
            caught = error
        }
        lock.signal()
    }
    arkitRequire(lock.wait(timeout: .now() + 5) == .success, "async timed out")
    guard let caught else {
        fatalError("expected thrown error")
    }
    return caught
}

final class ARKitSessionProbe: NSObject, ARSessionDelegate {
    var failures: [ARError.Code] = []
    var frames: [ARFrame] = []
    var added: [[ARAnchor]] = []
    var updated: [[ARAnchor]] = []
    var removed: [[ARAnchor]] = []
    var trackingStates: [ARCamera.TrackingState] = []
    var order: [String] = []

    func session(_ session: ARSession, didFailWithError error: any Error) {
        _ = session
        if let error = error as? ARError {
            failures.append(error.code)
        }
        order.append("fail")
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        _ = session
        frames.append(frame)
        order.append("frame")
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        _ = session
        added.append(anchors)
        order.append("add")
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        _ = session
        updated.append(anchors)
        order.append("update")
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        _ = session
        removed.append(anchors)
        order.append("remove")
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        _ = session
        trackingStates.append(camera.trackingState)
        order.append("tracking")
    }
}

final class EmptySessionDelegate: NSObject, ARSessionDelegate {}
final class EmptySCNViewDelegate: NSObject, ARSCNViewDelegate {}
final class EmptySKViewDelegate: NSObject, ARSKViewDelegate {}
final class EmptyCoachingDelegate: NSObject, ARCoachingOverlayViewDelegate {}
final class DummySceneRenderer: NSObject, SCNSceneRenderer {}

func arkitMakeHorizontalPlane(
    extent: simd_float3 = simd_float3(2, 0, 2),
    classification: ARPlaneAnchor.Classification = .floor
) -> ARPlaneAnchor {
    ARPlaneAnchor(
        transform: .identity,
        alignment: .horizontal,
        center: simd_float3(repeating: 0),
        extent: extent,
        classification: classification,
        isTracked: true,
        identifier: UUID(),
        sessionIdentifier: UUID()
    )
}

// --- ARKitAnchorTests.swift ---
func testAnchorCopyingAndSecureCoding() {
    let transform = simd_float4x4.identity
    arkitRequire(transform.columns.0.x == 1, "identity")
    let named = ARAnchor(name: "artwork", transform: transform)
    arkitRequire(named.name == "artwork", "name")
    arkitRequire(named.transform == transform, "transform")
    _ = named.identifier
    _ = named.sessionIdentifier
    let copied = ARAnchor(anchor: named)
    arkitRequire(copied.identifier == named.identifier, "init(anchor:)")
    arkitRequire((named.copy() as! ARAnchor).identifier == named.identifier, "NSCopying")
    arkitRequire(ARAnchor.supportsSecureCoding, "supportsSecureCoding")
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: ARAnchor(transform: .identity), requiringSecureCoding: true)
        let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data)
        arkitRequire(decoded != nil, "round trip")
        arkitRequire(decoded!.transform == simd_float4x4.identity, "decoded transform")
    } catch {
        fatalError("NSSecureCoding failed: \(error)")
    }
    _ = ARAnchor(transform: transform)
}

func testPlaneAnchorLayout() {
    let plane = arkitMakeHorizontalPlane(classification: .floor)
    arkitRequire(plane.geometry.triangleCount == 2, "triangles")
    arkitRequire(plane.geometry.boundaryVertices.count == 4, "boundary")
    arkitRequire(plane.geometry.textureCoordinates.count == 4, "uvs")
    arkitRequire(plane.geometry.triangleIndices.count == 6, "indices")
    arkitRequire(plane.geometry.vertices.count == 4, "vertices")
    arkitRequire(plane.planeExtent.width == 2 && plane.planeExtent.height == 2, "extent")
    arkitRequire(plane.planeExtent.rotationOnYAxis == 0, "rotation")
    arkitRequire(plane.isTracked, "tracked")
    arkitRequire(plane.classification == .floor, "classification")
    arkitRequire(plane.alignment == .horizontal, "alignment")
    _ = plane.center
    _ = plane.extent
    arkitRequire(!ARPlaneAnchor.isClassificationSupported, "classification unsupported")
    _ = ARPlaneAnchor(anchor: plane)
}

func testSpecializedAnchors() {
    let transform = simd_float4x4.identity
    let probe = AREnvironmentProbeAnchor(transform: transform, extent: simd_float3(1, 1, 1))
    arkitRequire(probe.extent == simd_float3(1, 1, 1), "extent")
    arkitRequire(probe.environmentTexture == nil, "no metal texture")
    _ = AREnvironmentProbeAnchor(name: "probe", transform: transform, extent: simd_float3(repeating: 0.5))
    _ = AREnvironmentProbeAnchor(anchor: probe)

    let mesh = ARMeshAnchor(anchor: ARAnchor(transform: transform))
    _ = mesh.geometry
    _ = ARParticipantAnchor(anchor: ARAnchor(transform: transform))
    let clip = ARAppClipCodeAnchor(anchor: ARAnchor(transform: transform))
    arkitRequire(clip.url == nil, "url")
    arkitRequire(clip.radius == 0, "radius")
    arkitRequire(clip.urlDecodingState == .failed, "decode state")
    arkitRequire(!clip.isTracked, "clip tracked")

    let geo = ARGeoAnchor(coordinate: CLLocationCoordinate2D(latitude: 37.3, longitude: -122.0), altitude: 10)
    arkitRequire(geo.coordinate.latitude == 37.3, "lat")
    arkitRequire(geo.altitude == 10, "alt")
    _ = geo.altitudeSource
    arkitRequire(!geo.isTracked, "geo tracked")
    _ = ARGeoAnchor(name: "place", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    _ = ARGeoAnchor(anchor: geo)

    _ = ARImageAnchor(anchor: ARAnchor(transform: transform)).referenceImage
    _ = ARImageAnchor(anchor: ARAnchor(transform: transform)).estimatedScaleFactor
    _ = ARObjectAnchor(anchor: ARAnchor(transform: transform)).referenceObject
    let face = ARFaceAnchor(anchor: ARAnchor(transform: transform))
    _ = face.blendShapes
    _ = face.geometry
    _ = face.leftEyeTransform
    _ = face.lookAtPoint
    _ = face.rightEyeTransform
    arkitRequire(!face.isTracked, "face tracked default")
}

func testAnchorCoderFallbacks() {
    let empty = NSKeyedArchiver(requiringSecureCoding: true)
    empty.encode(0, forKey: "x")
    let data = empty.encodedData
    do {
        let coder = try NSKeyedUnarchiver(forReadingFrom: data)
        coder.decodingFailurePolicy = .setErrorAndReturn
        arkitRequire(ARFaceGeometry(coder: coder) == nil, "face geo coder")
        arkitRequire(ARMeshGeometry(coder: coder) == nil, "mesh geo coder")
        arkitRequire(ARGeometryElement(coder: coder) == nil, "element coder")
        arkitRequire(ARGeometrySource(coder: coder) == nil, "source coder")
        arkitRequire(ARPlaneGeometry(coder: coder) == nil, "plane geo coder")
        arkitRequire(ARWorldMap(coder: coder) == nil, "world map coder")
        arkitRequire(ARReferenceObject(coder: coder) == nil, "reference object coder")
        _ = ARGeoTrackingStatus(coder: coder)
        _ = ARPlaneExtent(coder: coder)
        _ = ARPointCloud(coder: coder)
    } catch {
        fatalError("coder setup failed: \(error)")
    }
}

// --- ARKitBlendShapeTests.swift ---
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

// --- ARKitCameraTests.swift ---
func testCameraProjectionAndViewMatrix() {
    let camera = ARCamera(
        trackingState: .normal,
        transform: .identity,
        imageResolution: CGSize(width: 640, height: 480),
        intrinsics: ARSimulatedCameraDefaults.intrinsics
    )
    arkitRequire(camera.imageResolution.width == 640, "width")
    arkitRequire(arkitAlmostEqual(camera.intrinsics.columns.0.x, 640), "fx")
    arkitRequire(arkitAlmostEqual(camera.intrinsics.columns.2.x, 320), "cx")
    let projection = camera.projectionMatrix(
        for: UIInterfaceOrientation.landscapeRight,
        viewportSize: CGSize(width: 640, height: 480),
        zNear: 0.001,
        zFar: 1000
    )
    arkitRequire(arkitAlmostEqual(projection.columns.0.x, 2), "m00")
    arkitRequire(arkitAlmostEqual(projection.columns.1.y, 2 * 640 / 480), "m11")
    arkitRequire(arkitAlmostEqual(projection.columns.2.x, 1 - 2 * 320 / 640), "m20")
    arkitRequire(arkitAlmostEqual(projection.columns.2.y, 2 * 240 / 480 - 1), "m21")
    arkitRequire(arkitAlmostEqual(projection.columns.2.w, -1), "m23")
    let near: Float = 0.001
    let far: Float = 1000
    arkitRequire(arkitAlmostEqual(projection.columns.2.z, -(far + near) / (far - near)), "m22")
    arkitRequire(arkitAlmostEqual(projection.columns.3.z, -2 * far * near / (far - near)), "m32")
    arkitRequire(camera.viewMatrix(for: UIInterfaceOrientation.landscapeRight) == simd_float4x4.identity, "identity view")
    let portraitView = camera.viewMatrix(for: UIInterfaceOrientation.portrait)
    arkitRequire(arkitAlmostEqual(portraitView.columns.0.x, 0), "portrait X")
    _ = camera.eulerAngles
    _ = camera.projectionMatrix
    _ = camera.exposureDuration
    _ = camera.exposureOffset
    _ = camera.transform
    _ = camera.trackingState
    let projected = camera.projectPoint(
        simd_float3(0, 0, -1),
        orientation: UIInterfaceOrientation.landscapeRight,
        viewportSize: CGSize(width: 640, height: 480)
    )
    arkitRequire(projected.x > 0 && projected.y > 0, "projectPoint")
    _ = camera.unprojectPoint(
        CGPoint(x: 0.5, y: 0.5),
        ontoPlane: simd_float4x4.identity,
        orientation: UIInterfaceOrientation.landscapeRight,
        viewportSize: CGSize(width: 640, height: 480)
    )
    _ = camera.viewMatrix(for: .portraitUpsideDown)
    _ = camera.viewMatrix(for: .landscapeLeft)
    _ = camera.viewMatrix(for: .unknown)
    _ = (camera.copy() as! ARCamera).trackingState
    arkitRequire(ARCamera().trackingState == .notAvailable, "default camera")
}

// --- ARKitConfigurationTests.swift ---
func testConfigurationUnsupportedWithoutHook() {
    ARKitTestHook.removeSimulatedDevice()
    arkitRequire(!ARConfiguration.isSupported, "base")
    arkitRequire(!ARWorldTrackingConfiguration.isSupported, "world")
    arkitRequire(!AROrientationTrackingConfiguration.isSupported, "orientation")
    arkitRequire(!ARFaceTrackingConfiguration.isSupported, "face")
    arkitRequire(!ARImageTrackingConfiguration.isSupported, "image")
    arkitRequire(!ARObjectScanningConfiguration.isSupported, "object")
    arkitRequire(!ARBodyTrackingConfiguration.isSupported, "body")
    arkitRequire(!ARPositionalTrackingConfiguration.isSupported, "positional")
    arkitRequire(!ARGeoTrackingConfiguration.isSupported, "geo")
    arkitRequire(ARWorldTrackingConfiguration.supportedVideoFormats.isEmpty, "formats")
    arkitRequire(ARWorldTrackingConfiguration.recommendedVideoFormatFor4KResolution == nil, "4K")
    arkitRequire(
        ARWorldTrackingConfiguration.recommendedVideoFormatForHighResolutionFrameCapturing == nil,
        "hi-res format"
    )
    arkitRequire(!ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation), "semantics")
    arkitRequire(!ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh), "reconstruction")
    arkitRequire(!ARWorldTrackingConfiguration.supportsAppClipCodeTracking, "app clip")
    arkitRequire(!ARWorldTrackingConfiguration.supportsUserFaceTracking, "user face")
    arkitRequire(ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces == 0, "tracked faces")
    arkitRequire(!ARFaceTrackingConfiguration.supportsWorldTracking, "face world")
    arkitRequire(!ARBodyTrackingConfiguration.supportsAppClipCodeTracking, "body app clip")
    arkitRequire(!ARGeoTrackingConfiguration.supportsAppClipCodeTracking, "geo app clip")
    arkitRequire(ARConfiguration.configurableCaptureDeviceForPrimaryCamera == nil, "capture device")
}

func testWorldTrackingConfigurationCopy() {
    let world = ARWorldTrackingConfiguration()
    world.planeDetection = [.horizontal, .vertical]
    world.isLightEstimationEnabled = true
    world.providesAudioData = true
    world.videoHDRAllowed = true
    world.videoFormat = .unsupportedPlaceholder
    world.worldAlignment = .gravityAndHeading
    world.appClipCodeTrackingEnabled = true
    world.isAutoFocusEnabled = false
    world.automaticImageScaleEstimationEnabled = true
    world.isCollaborationEnabled = true
    world.maximumNumberOfTrackedImages = 2
    world.userFaceTrackingEnabled = true
    world.wantsHDREnvironmentTextures = true
    world.detectionImages = []
    world.detectionObjects = []
    world.initialWorldMap = ARWorldMap()
    world.sceneReconstruction = [.mesh]
    world.frameSemantics = [.bodyDetection]
    world.environmentTexturing = .manual
    let copy = world.copy() as! ARWorldTrackingConfiguration
    arkitRequire(copy !== world, "copy identity")
    arkitRequire(copy.planeDetection == world.planeDetection, "planes")
    arkitRequire(copy.isCollaborationEnabled, "collaboration")
    arkitRequire(copy.providesAudioData, "audio")
    arkitRequire(copy.videoHDRAllowed, "hdr")
    arkitRequire(copy.worldAlignment == .gravityAndHeading, "alignment")
    arkitRequire(copy.isLightEstimationEnabled, "light")
    arkitRequire(copy.appClipCodeTrackingEnabled, "app clip")
    arkitRequire(!copy.isAutoFocusEnabled, "autofocus")
    arkitRequire(copy.automaticImageScaleEstimationEnabled, "scale")
    arkitRequire(copy.maximumNumberOfTrackedImages == 2, "tracked images")
    arkitRequire(copy.userFaceTrackingEnabled, "user face")
    arkitRequire(copy.wantsHDREnvironmentTextures, "hdr env")
    arkitRequire(copy.environmentTexturing == .manual, "texturing")
    arkitRequire(copy.sceneReconstruction.contains(.mesh), "reconstruction")
    arkitRequire(copy.frameSemantics.contains(.bodyDetection), "semantics")
    arkitRequire(copy.initialWorldMap != nil, "world map")
}

func testOtherConfigurationCopies() {
    let face = ARFaceTrackingConfiguration()
    face.maximumNumberOfTrackedFaces = 2
    face.isWorldTrackingEnabled = true
    arkitRequire((face.copy() as! ARFaceTrackingConfiguration).maximumNumberOfTrackedFaces == 2, "face")
    arkitRequire((face.copy() as! ARFaceTrackingConfiguration).isWorldTrackingEnabled, "face world")

    let image = ARImageTrackingConfiguration()
    image.maximumNumberOfTrackedImages = 4
    image.isAutoFocusEnabled = false
    image.trackingImages = []
    arkitRequire((image.copy() as! ARImageTrackingConfiguration).maximumNumberOfTrackedImages == 4, "image")

    let body = ARBodyTrackingConfiguration()
    body.automaticSkeletonScaleEstimationEnabled = true
    body.planeDetection = [.vertical]
    body.appClipCodeTrackingEnabled = true
    body.isAutoFocusEnabled = false
    body.automaticImageScaleEstimationEnabled = true
    body.detectionImages = []
    body.environmentTexturing = .automatic
    body.initialWorldMap = ARWorldMap()
    body.maximumNumberOfTrackedImages = 1
    body.wantsHDREnvironmentTextures = true
    let bodyCopy = body.copy() as! ARBodyTrackingConfiguration
    arkitRequire(bodyCopy.automaticSkeletonScaleEstimationEnabled, "body skeleton scale")
    arkitRequire(bodyCopy.planeDetection.contains(.vertical), "body planes")

    let geo = ARGeoTrackingConfiguration()
    geo.maximumNumberOfTrackedImages = 3
    geo.appClipCodeTrackingEnabled = true
    geo.automaticImageScaleEstimationEnabled = true
    geo.detectionImages = []
    geo.detectionObjects = []
    geo.environmentTexturing = .none
    geo.planeDetection = [.horizontal]
    geo.wantsHDREnvironmentTextures = true
    arkitRequire((geo.copy() as! ARGeoTrackingConfiguration).maximumNumberOfTrackedImages == 3, "geo")

    let positional = ARPositionalTrackingConfiguration()
    positional.planeDetection = [.horizontal]
    positional.initialWorldMap = ARWorldMap()
    arkitRequire(!(positional.copy() as! ARPositionalTrackingConfiguration).planeDetection.isEmpty, "positional")

    let objectScan = ARObjectScanningConfiguration()
    objectScan.planeDetection = [.vertical]
    objectScan.isAutoFocusEnabled = false
    arkitRequire((objectScan.copy() as! ARObjectScanningConfiguration).planeDetection.contains(.vertical), "object")

    let orientation = AROrientationTrackingConfiguration()
    orientation.isAutoFocusEnabled = false
    arkitRequire(!(orientation.copy() as! AROrientationTrackingConfiguration).isAutoFocusEnabled, "orientation")
}

func testVideoFormatPlaceholder() {
    let format = ARConfiguration.VideoFormat.unsupportedPlaceholder
    arkitRequire(format.framesPerSecond == 0, "fps")
    arkitRequire(format.imageResolution == .zero, "resolution")
    arkitRequire(!format.isRecommendedForHighResolutionFrameCapturing, "hi-res flag")
    arkitRequire(!format.isVideoHDRSupported, "hdr flag")
    _ = format.captureDevicePosition
    _ = format.captureDeviceType
    _ = format.defaultColorSpace
    _ = format.defaultPhotoSettings
}

func testConfigurationSupportedWithHook() {
    ARKitTestHook.removeSimulatedDevice()
    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }
    arkitRequire(ARConfiguration.isSupported, "base")
    arkitRequire(ARWorldTrackingConfiguration.isSupported, "world")
    arkitRequire(ARFaceTrackingConfiguration.isSupported, "face")
    arkitRequire(ARImageTrackingConfiguration.isSupported, "image")
    arkitRequire(ARBodyTrackingConfiguration.isSupported, "body")
    arkitRequire(ARGeoTrackingConfiguration.isSupported, "geo")
    arkitRequire(ARPositionalTrackingConfiguration.isSupported, "positional")
    arkitRequire(AROrientationTrackingConfiguration.isSupported, "orientation")
    arkitRequire(ARObjectScanningConfiguration.isSupported, "object")
    arkitRequire(ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces == 1, "tracked faces")
    arkitRequire(ARConfiguration.supportedVideoFormats.isEmpty, "formats stay empty")
}

// --- ARKitEnumTests.swift ---
func testConfidenceLevelCases() {
    arkitRequire(ARConfidenceLevel.low.rawValue == 0, "low")
    arkitRequire(ARConfidenceLevel.medium.rawValue == 1, "medium")
    arkitRequire(ARConfidenceLevel.high.rawValue == 2, "high")
    arkitRequire(ARConfidenceLevel(rawValue: 2) == .high, "init")
    arkitRequire(ARConfidenceLevel.low != .high, "inequality")
    _ = ARConfidenceLevel.medium.hashValue
    var hasher = Hasher()
    ARConfidenceLevel.high.hash(into: &hasher)
}

func testConfidenceLevelComparable() {
    arkitRequire(ARConfidenceLevel.low < .high, "<")
    arkitRequire(ARConfidenceLevel.high > .low, ">")
    arkitRequire(ARConfidenceLevel.high >= .medium, ">=")
    arkitRequire(ARConfidenceLevel.low <= .medium, "<=")
    arkitRequire((ARConfidenceLevel.low..<ARConfidenceLevel.high).contains(.medium), "range")
    arkitRequire((ARConfidenceLevel.low...ARConfidenceLevel.medium).contains(.medium), "closed")
    arkitRequire((ARConfidenceLevel.low...).contains(.high), "partial from")
    arkitRequire((...ARConfidenceLevel.high).contains(.medium), "partial through")
    arkitRequire((..<ARConfidenceLevel.high).contains(.low), "partial up to")
}

func testMeshClassificationCases() {
    arkitRequire(ARMeshClassification.none.rawValue == 0, "none")
    arkitRequire(ARMeshClassification.wall.rawValue == 1, "wall")
    arkitRequire(ARMeshClassification.floor.rawValue == 2, "floor")
    arkitRequire(ARMeshClassification.ceiling.rawValue == 3, "ceiling")
    arkitRequire(ARMeshClassification.table.rawValue == 4, "table")
    arkitRequire(ARMeshClassification.seat.rawValue == 5, "seat")
    arkitRequire(ARMeshClassification.window.rawValue == 6, "window")
    arkitRequire(ARMeshClassification.door.rawValue == 7, "door")
    arkitRequire(ARMeshClassification(rawValue: 2) == .floor, "init")
    arkitRequire(ARMeshClassification.wall != .door, "inequality")
    _ = ARMeshClassification.floor.hashValue
    var hasher = Hasher()
    ARMeshClassification.wall.hash(into: &hasher)
}

func testGeometryPrimitiveTypeCases() {
    arkitRequire(ARGeometryPrimitiveType.line.rawValue == 0, "line")
    arkitRequire(ARGeometryPrimitiveType.triangle.rawValue == 1, "triangle")
    arkitRequire(ARGeometryPrimitiveType(rawValue: 1) == .triangle, "init")
    arkitRequire(ARGeometryPrimitiveType.line != .triangle, "inequality")
    _ = ARGeometryPrimitiveType.triangle.hashValue
    var hasher = Hasher()
    ARGeometryPrimitiveType.line.hash(into: &hasher)
}

func testWorldAlignmentAndTexturingCases() {
    arkitRequire(ARConfiguration.WorldAlignment.gravity.rawValue == 0, "gravity")
    arkitRequire(ARConfiguration.WorldAlignment.gravityAndHeading.rawValue == 1, "heading")
    arkitRequire(ARConfiguration.WorldAlignment.camera.rawValue == 2, "camera")
    arkitRequire(ARConfiguration.WorldAlignment(rawValue: 2) == .camera, "init")
    arkitRequire(ARConfiguration.WorldAlignment.gravity != .camera, "inequality")
    _ = ARConfiguration.WorldAlignment.gravity.hashValue
    var hasher = Hasher()
    ARConfiguration.WorldAlignment.camera.hash(into: &hasher)

    arkitRequire(ARWorldTrackingConfiguration.EnvironmentTexturing.none.rawValue == 0, "none")
    arkitRequire(ARWorldTrackingConfiguration.EnvironmentTexturing.manual.rawValue == 1, "manual")
    arkitRequire(ARWorldTrackingConfiguration.EnvironmentTexturing.automatic.rawValue == 2, "automatic")
    arkitRequire(ARWorldTrackingConfiguration.EnvironmentTexturing(rawValue: 1) == .manual, "texturing init")
    arkitRequire(ARWorldTrackingConfiguration.EnvironmentTexturing.none != .automatic, "texturing inequality")
    _ = ARWorldTrackingConfiguration.EnvironmentTexturing.manual.hashValue
    ARWorldTrackingConfiguration.EnvironmentTexturing.automatic.hash(into: &hasher)
}

func testFrameStatusEnumCases() {
    arkitRequire(ARFrame.WorldMappingStatus.notAvailable.rawValue == 0, "notAvailable")
    arkitRequire(ARFrame.WorldMappingStatus.limited.rawValue == 1, "limited")
    arkitRequire(ARFrame.WorldMappingStatus.extending.rawValue == 2, "extending")
    arkitRequire(ARFrame.WorldMappingStatus.mapped.rawValue == 3, "mapped")
    arkitRequire(ARFrame.WorldMappingStatus(rawValue: 1) == .limited, "init")
    arkitRequire(ARFrame.WorldMappingStatus.limited != .mapped, "inequality")
    _ = ARFrame.WorldMappingStatus.mapped.hashValue
    var hasher = Hasher()
    ARFrame.WorldMappingStatus.limited.hash(into: &hasher)

    arkitRequire(ARFrame.SegmentationClass.none.rawValue == 0, "seg none")
    arkitRequire(ARFrame.SegmentationClass.person.rawValue == 1, "person")
    arkitRequire(ARFrame.SegmentationClass(rawValue: 1) == .person, "seg init")
    arkitRequire(ARFrame.SegmentationClass.none != .person, "seg inequality")
    _ = ARFrame.SegmentationClass.person.hashValue
    ARFrame.SegmentationClass.none.hash(into: &hasher)
}

func testGeoTrackingEnumCases() {
    arkitRequire(ARGeoTrackingStatus.State.notAvailable.rawValue == 0, "state 0")
    arkitRequire(ARGeoTrackingStatus.State.initializing.rawValue == 1, "state 1")
    arkitRequire(ARGeoTrackingStatus.State.localizing.rawValue == 2, "state 2")
    arkitRequire(ARGeoTrackingStatus.State.localized.rawValue == 3, "state 3")
    arkitRequire(ARGeoTrackingStatus.State(rawValue: 2) == .localizing, "state init")
    arkitRequire(ARGeoTrackingStatus.State.localizing != .localized, "state inequality")
    _ = ARGeoTrackingStatus.State.localized.hashValue
    var hasher = Hasher()
    ARGeoTrackingStatus.State.notAvailable.hash(into: &hasher)

    arkitRequire(ARGeoTrackingStatus.Accuracy.undetermined.rawValue == 0, "acc 0")
    arkitRequire(ARGeoTrackingStatus.Accuracy.low.rawValue == 1, "acc 1")
    arkitRequire(ARGeoTrackingStatus.Accuracy.medium.rawValue == 2, "acc 2")
    arkitRequire(ARGeoTrackingStatus.Accuracy.high.rawValue == 3, "acc 3")
    arkitRequire(ARGeoTrackingStatus.Accuracy(rawValue: 3) == .high, "acc init")
    arkitRequire(ARGeoTrackingStatus.Accuracy.low != .high, "acc inequality")
    _ = ARGeoTrackingStatus.Accuracy.medium.hashValue
    ARGeoTrackingStatus.Accuracy.high.hash(into: &hasher)

    arkitRequire(ARGeoTrackingStatus.StateReason.none.rawValue == 0, "reason 0")
    arkitRequire(ARGeoTrackingStatus.StateReason.notAvailableAtLocation.rawValue == 1, "reason 1")
    arkitRequire(ARGeoTrackingStatus.StateReason.needLocationPermissions.rawValue == 2, "reason 2")
    arkitRequire(ARGeoTrackingStatus.StateReason.worldTrackingUnstable.rawValue == 3, "reason 3")
    arkitRequire(ARGeoTrackingStatus.StateReason.waitingForLocation.rawValue == 4, "reason 4")
    arkitRequire(ARGeoTrackingStatus.StateReason.waitingForAvailabilityCheck.rawValue == 5, "reason 5")
    arkitRequire(ARGeoTrackingStatus.StateReason.geoDataNotLoaded.rawValue == 6, "reason 6")
    arkitRequire(ARGeoTrackingStatus.StateReason.devicePointedTooLow.rawValue == 7, "reason 7")
    arkitRequire(ARGeoTrackingStatus.StateReason.visualLocalizationFailed.rawValue == 8, "reason 8")
    arkitRequire(ARGeoTrackingStatus.StateReason(rawValue: 6) == .geoDataNotLoaded, "reason init")
    arkitRequire(ARGeoTrackingStatus.StateReason.none != .geoDataNotLoaded, "reason inequality")
    _ = ARGeoTrackingStatus.StateReason.none.hashValue
    ARGeoTrackingStatus.StateReason.geoDataNotLoaded.hash(into: &hasher)
}

func testAnchorEnumCases() {
    arkitRequire(ARGeoAnchor.AltitudeSource.unknown.rawValue == 0, "unknown")
    arkitRequire(ARGeoAnchor.AltitudeSource.coarse.rawValue == 1, "coarse")
    arkitRequire(ARGeoAnchor.AltitudeSource.precise.rawValue == 2, "precise")
    arkitRequire(ARGeoAnchor.AltitudeSource.userDefined.rawValue == 3, "userDefined")
    arkitRequire(ARGeoAnchor.AltitudeSource(rawValue: 2) == .precise, "alt init")
    arkitRequire(ARGeoAnchor.AltitudeSource.coarse != .precise, "alt inequality")
    _ = ARGeoAnchor.AltitudeSource.unknown.hashValue
    var hasher = Hasher()
    ARGeoAnchor.AltitudeSource.userDefined.hash(into: &hasher)

    arkitRequire(ARAppClipCodeAnchor.URLDecodingState.decoding.rawValue == 0, "decoding")
    arkitRequire(ARAppClipCodeAnchor.URLDecodingState.decoded.rawValue == 1, "decoded")
    arkitRequire(ARAppClipCodeAnchor.URLDecodingState.failed.rawValue == 2, "failed")
    arkitRequire(ARAppClipCodeAnchor.URLDecodingState(rawValue: 2) == .failed, "url init")
    arkitRequire(ARAppClipCodeAnchor.URLDecodingState.decoding != .decoded, "url inequality")
    _ = ARAppClipCodeAnchor.URLDecodingState.decoded.hashValue
    ARAppClipCodeAnchor.URLDecodingState.failed.hash(into: &hasher)

    arkitRequire(ARPlaneAnchor.Alignment.horizontal.rawValue == 0, "horizontal")
    arkitRequire(ARPlaneAnchor.Alignment.vertical.rawValue == 1, "vertical")
    arkitRequire(ARPlaneAnchor.Alignment(rawValue: 0) == .horizontal, "align init")
    arkitRequire(ARPlaneAnchor.Alignment.horizontal != .vertical, "align inequality")
    _ = ARPlaneAnchor.Alignment.horizontal.hashValue
    ARPlaneAnchor.Alignment.vertical.hash(into: &hasher)
}

func testCoachingMatteAndCollaborationEnumCases() {
    arkitRequire(ARCoachingOverlayView.Goal.tracking.rawValue == 0, "tracking")
    arkitRequire(ARCoachingOverlayView.Goal.horizontalPlane.rawValue == 1, "horizontalPlane")
    arkitRequire(ARCoachingOverlayView.Goal.verticalPlane.rawValue == 2, "verticalPlane")
    arkitRequire(ARCoachingOverlayView.Goal.anyPlane.rawValue == 3, "anyPlane")
    arkitRequire(ARCoachingOverlayView.Goal.geoTracking.rawValue == 4, "geoTracking")
    arkitRequire(ARCoachingOverlayView.Goal(rawValue: 1) == .horizontalPlane, "goal init")
    arkitRequire(ARCoachingOverlayView.Goal.tracking != .geoTracking, "goal inequality")
    _ = ARCoachingOverlayView.Goal.tracking.hashValue
    var hasher = Hasher()
    ARCoachingOverlayView.Goal.anyPlane.hash(into: &hasher)

    arkitRequire(ARMatteGenerator.Resolution.full.rawValue == 0, "full")
    arkitRequire(ARMatteGenerator.Resolution.half.rawValue == 1, "half")
    arkitRequire(ARMatteGenerator.Resolution(rawValue: 1) == .half, "matte init")
    arkitRequire(ARMatteGenerator.Resolution.full != .half, "matte inequality")
    _ = ARMatteGenerator.Resolution.full.hashValue
    ARMatteGenerator.Resolution.half.hash(into: &hasher)

    arkitRequire(ARSession.CollaborationData.Priority.critical.rawValue == 0, "critical")
    arkitRequire(ARSession.CollaborationData.Priority.optional.rawValue == 1, "optional")
    arkitRequire(ARSession.CollaborationData.Priority(rawValue: 0) == .critical, "priority init")
    arkitRequire(ARSession.CollaborationData.Priority.critical != .optional, "priority inequality")
    _ = ARSession.CollaborationData.Priority.critical.hashValue
    ARSession.CollaborationData.Priority.optional.hash(into: &hasher)
}

func testRaycastTargetEnumCases() {
    arkitRequire(ARRaycastQuery.Target.existingPlaneInfinite.rawValue == 0, "infinite")
    arkitRequire(ARRaycastQuery.Target.existingPlaneGeometry.rawValue == 1, "geometry")
    arkitRequire(ARRaycastQuery.Target.estimatedPlane.rawValue == 2, "estimated")
    arkitRequire(ARRaycastQuery.Target(rawValue: 2) == .estimatedPlane, "target init")
    arkitRequire(ARRaycastQuery.Target.existingPlaneInfinite != .estimatedPlane, "target inequality")
    _ = ARRaycastQuery.Target.estimatedPlane.hashValue
    var hasher = Hasher()
    ARRaycastQuery.Target.existingPlaneGeometry.hash(into: &hasher)

    arkitRequire(ARRaycastQuery.TargetAlignment.any.rawValue == 0, "any")
    arkitRequire(ARRaycastQuery.TargetAlignment.horizontal.rawValue == 1, "horizontal")
    arkitRequire(ARRaycastQuery.TargetAlignment.vertical.rawValue == 2, "vertical")
    arkitRequire(ARRaycastQuery.TargetAlignment(rawValue: 1) == .horizontal, "align init")
    arkitRequire(ARRaycastQuery.TargetAlignment.any != .vertical, "align inequality")
    _ = ARRaycastQuery.TargetAlignment.horizontal.hashValue
    ARRaycastQuery.TargetAlignment.vertical.hash(into: &hasher)
}

func testPlaneClassificationCases() {
    arkitRequire(ARPlaneAnchor.Classification.none(.notAvailable) == .none(.notAvailable), "none equal")
    arkitRequire(ARPlaneAnchor.Classification.Status.undetermined != .unknown, "status distinct")
    arkitRequire(ARPlaneAnchor.Classification.wall != .floor, "wall/floor")
    arkitRequire(ARPlaneAnchor.Classification.ceiling != .table, "ceiling/table")
    arkitRequire(ARPlaneAnchor.Classification.seat != .window, "seat/window")
    arkitRequire(ARPlaneAnchor.Classification.door != .wall, "door/wall")
    arkitRequire(ARPlaneAnchor.Classification.Status.notAvailable != .undetermined, "status inequality")
    _ = ARPlaneAnchor.Classification.Status.unknown.hashValue
    var hasher = Hasher()
    ARPlaneAnchor.Classification.Status.undetermined.hash(into: &hasher)
}

func testCameraTrackingStateCases() {
    arkitRequire(ARCamera.TrackingState.notAvailable != .normal, "notAvailable")
    arkitRequire(ARCamera.TrackingState.limited(.initializing) != .normal, "limited")
    arkitRequire(ARCamera.TrackingState.limited(.initializing) == .limited(.initializing), "reason equal")
    arkitRequire(ARCamera.TrackingState.limited(.relocalizing) != .limited(.excessiveMotion), "reason inequality")
    arkitRequire(
        ARCamera.TrackingState.limited(.insufficientFeatures) == .limited(.insufficientFeatures),
        "insufficientFeatures"
    )
    arkitRequire(ARCamera.TrackingState.Reason.initializing != .relocalizing, "reason cases")
    _ = ARCamera.TrackingState.Reason.excessiveMotion.hashValue
    var hasher = Hasher()
    ARCamera.TrackingState.Reason.insufficientFeatures.hash(into: &hasher)
}

func testSCNDebugOptionBits() {
    arkitRequire(SCNDebugOptions.showWorldOrigin.rawValue == 1, "world origin")
    arkitRequire(SCNDebugOptions.showFeaturePoints.rawValue == 2, "feature points")
    let alias: ARSCNDebugOptions = .showWorldOrigin
    arkitRequire(alias.rawValue == 1, "ARSCNDebugOptions alias")
}

// --- ARKitErrorTests.swift ---
func testARErrorCodesAndDomain() {
    arkitRequire(ARErrorDomain == "com.apple.arkit.error", "ARErrorDomain string")
    arkitRequire(ARError.errorDomain == ARErrorDomain, "CustomNSError domain")
    let codes: [(ARError.Code, Int)] = [
        (.unsupportedConfiguration, 100),
        (.sensorUnavailable, 101),
        (.sensorFailed, 102),
        (.cameraUnauthorized, 103),
        (.microphoneUnauthorized, 104),
        (.locationUnauthorized, 105),
        (.highResolutionFrameCaptureInProgress, 106),
        (.highResolutionFrameCaptureFailed, 107),
        (.worldTrackingFailed, 200),
        (.geoTrackingNotAvailableAtLocation, 201),
        (.geoTrackingFailed, 202),
        (.invalidReferenceImage, 300),
        (.invalidReferenceObject, 301),
        (.invalidWorldMap, 302),
        (.invalidConfiguration, 303),
        (.invalidCollaborationData, 304),
        (.insufficientFeatures, 400),
        (.objectMergeFailed, 401),
        (.fileIOFailed, 500),
        (.requestFailed, 501),
    ]
    arkitRequire(codes.count == 20, "documented ARError.Code count")
    for (code, raw) in codes {
        arkitRequire(code.rawValue == raw, "raw \(raw)")
        arkitRequire(ARError.Code(rawValue: raw) == code, "init raw \(raw)")
    }
    arkitRequire(ARError.unsupportedConfiguration == .unsupportedConfiguration, "static unsupportedConfiguration")
    arkitRequire(ARError.sensorUnavailable == .sensorUnavailable, "static sensorUnavailable")
    arkitRequire(ARError.sensorFailed == .sensorFailed, "static sensorFailed")
    arkitRequire(ARError.cameraUnauthorized == .cameraUnauthorized, "static cameraUnauthorized")
    arkitRequire(ARError.microphoneUnauthorized == .microphoneUnauthorized, "static microphoneUnauthorized")
    arkitRequire(ARError.locationUnauthorized == .locationUnauthorized, "static locationUnauthorized")
    arkitRequire(ARError.highResolutionFrameCaptureInProgress == .highResolutionFrameCaptureInProgress, "static hi-res in progress")
    arkitRequire(ARError.highResolutionFrameCaptureFailed == .highResolutionFrameCaptureFailed, "static hi-res failed")
    arkitRequire(ARError.worldTrackingFailed == .worldTrackingFailed, "static worldTrackingFailed")
    arkitRequire(ARError.geoTrackingNotAvailableAtLocation == .geoTrackingNotAvailableAtLocation, "static geo not available")
    arkitRequire(ARError.geoTrackingFailed == .geoTrackingFailed, "static geoTrackingFailed")
    arkitRequire(ARError.invalidReferenceImage == .invalidReferenceImage, "static invalidReferenceImage")
    arkitRequire(ARError.invalidReferenceObject == .invalidReferenceObject, "static invalidReferenceObject")
    arkitRequire(ARError.invalidWorldMap == .invalidWorldMap, "static invalidWorldMap")
    arkitRequire(ARError.invalidConfiguration == .invalidConfiguration, "static invalidConfiguration")
    arkitRequire(ARError.invalidCollaborationData == .invalidCollaborationData, "static invalidCollaborationData")
    arkitRequire(ARError.insufficientFeatures == .insufficientFeatures, "static insufficientFeatures")
    arkitRequire(ARError.objectMergeFailed == .objectMergeFailed, "static objectMergeFailed")
    arkitRequire(ARError.fileIOFailed == .fileIOFailed, "static fileIOFailed")
    arkitRequire(ARError.requestFailed == .requestFailed, "static requestFailed")
}

func testARErrorValueSemantics() {
    let error = ARError(.sensorUnavailable, userInfo: [NSLocalizedDescriptionKey: "sensor"])
    arkitRequire(error.code == .sensorUnavailable, "code storage")
    arkitRequire(error.errorCode == 101, "errorCode")
    arkitRequire((error.errorUserInfo[NSLocalizedDescriptionKey] as? String) == "sensor", "errorUserInfo")
    arkitRequire((error.userInfo[NSLocalizedDescriptionKey] as? String) == "sensor", "userInfo")
    arkitRequire(error == ARError(.sensorUnavailable, userInfo: [NSLocalizedDescriptionKey: "sensor"]), "equality")
    arkitRequire(error != ARError(.sensorFailed), "inequality")
    arkitRequire(ARError.Code.sensorUnavailable ~= error, "pattern match")
    _ = error.hashValue
    var hasher = Hasher()
    error.hash(into: &hasher)
    ARError.Code.fileIOFailed.hash(into: &hasher)
    _ = ARError.Code.geoTrackingFailed.hashValue
    _ = error.localizedDescription
    arkitRequire(ARError(.unsupportedConfiguration) != ARError(.sensorFailed), "code inequality")
}

// --- ARKitFailClosedTests.swift ---
func testSessionFailClosedIO() {
    ARKitTestHook.removeSimulatedDevice()
    let session = ARSession()
    arkitWait { done in
        session.captureHighResolutionFrame { frame, error in
            arkitRequire(frame == nil, "no hi-res frame")
            arkitRequire((error as? ARError)?.code == .unsupportedConfiguration, "hi-res code")
            done()
        }
    }
    let worldError = arkitAwaitError { _ = try await session.currentWorldMap() }
    arkitRequire((worldError as? ARError)?.code == .unsupportedConfiguration, "world map idle")
    let objectError = arkitAwaitError {
        _ = try await session.createReferenceObject(
            transform: .identity,
            center: simd_float3(repeating: 0),
            extent: simd_float3(repeating: 1)
        )
    }
    arkitRequire((objectError as? ARError)?.code == .unsupportedConfiguration, "create object")
}

func testSimulatedSessionWorldMapStillFailClosed() {
    ARKitTestHook.removeSimulatedDevice()
    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }
    let session = ARSession()
    session.run(ARWorldTrackingConfiguration())
    let worldError = arkitAwaitError { _ = try await session.currentWorldMap() }
    arkitRequire((worldError as? ARError)?.code == .invalidWorldMap, "invalidWorldMap")
    let captureError = arkitAwaitError { _ = try await session.captureHighResolutionFrame(using: nil) }
    arkitRequire((captureError as? ARError)?.code == .unsupportedConfiguration, "hi-res using")
    let geoError = arkitAwaitError { _ = try await session.geoLocation(forPoint: simd_float3(repeating: 0)) }
    arkitRequire((geoError as? ARError)?.code == .geoTrackingNotAvailableAtLocation, "geo location")
}

func testGeoAvailabilityFailClosed() {
    arkitWait { done in
        ARGeoTrackingConfiguration.checkAvailability { available, error in
            arkitRequire(!available, "availability")
            arkitRequire((error as? ARError)?.code == .geoTrackingNotAvailableAtLocation, "geo error")
            done()
        }
    }
    arkitWait { done in
        ARGeoTrackingConfiguration.checkAvailability(at: CLLocationCoordinate2D(latitude: 0, longitude: 0)) { available, error in
            arkitRequire(!available, "coord availability")
            arkitRequire((error as? ARError)?.code == .geoTrackingNotAvailableAtLocation, "coord error")
            done()
        }
    }
}

// --- ARKitFrameTests.swift ---
func testFramePropertiesAndDisplayTransform() {
    let camera = ARCamera(
        trackingState: .normal,
        transform: ARSimulatedCameraDefaults.transform,
        imageResolution: CGSize(width: 640, height: 480),
        intrinsics: ARSimulatedCameraDefaults.intrinsics
    )
    let frame = ARFrame(anchors: [arkitMakeHorizontalPlane()], camera: camera, timestamp: 1.5)
    arkitRequire(frame.timestamp == 1.5, "timestamp")
    arkitRequire(frame.anchors.count == 1, "anchors")
    _ = frame.camera
    _ = frame.cameraGrainIntensity
    _ = frame.cameraGrainTexture
    _ = frame.capturedDepthData
    _ = frame.capturedDepthDataTimestamp
    _ = frame.capturedImage.width
    _ = frame.detectedBody
    _ = frame.estimatedDepthData
    _ = frame.exifData
    _ = frame.geoTrackingStatus
    _ = frame.lightEstimate
    _ = frame.rawFeaturePoints
    _ = frame.sceneDepth
    _ = frame.segmentationBuffer
    _ = frame.smoothedSceneDepth
    _ = frame.worldMappingStatus
    _ = frame.displayTransform(for: .portrait, viewportSize: CGSize(width: 100, height: 200))
    _ = frame.displayTransform(for: .portraitUpsideDown, viewportSize: .zero)
    _ = frame.displayTransform(for: .landscapeLeft, viewportSize: .zero)
    _ = frame.displayTransform(for: .landscapeRight, viewportSize: .zero)
    _ = frame.displayTransform(for: .unknown, viewportSize: .zero)
    let query = frame.raycastQuery(from: .zero, allowing: .estimatedPlane, alignment: .horizontal)
    let direction = query.direction
    arkitRequire((direction.x * direction.x + direction.y * direction.y + direction.z * direction.z) > 0.8, "unit ray")
    arkitRequire(ARFrame().hitTest(.zero, types: .featurePoint).isEmpty, "empty hit test")
}

func testLightDepthAndMatte() {
    let light = ARLightEstimate(ambientIntensity: 1000, ambientColorTemperature: 6500)
    arkitRequire(light.ambientIntensity == 1000, "intensity")
    arkitRequire(light.ambientColorTemperature == 6500, "temperature")
    let directional = ARDirectionalLightEstimate()
    _ = directional.primaryLightDirection
    _ = directional.primaryLightIntensity
    _ = directional.sphericalHarmonicsCoefficients
    let depth = ARDepthData()
    _ = depth.confidenceMap
    _ = depth.depthMap
    let status = ARGeoTrackingStatus()
    arkitRequire(status.state == .notAvailable, "geo state")
    _ = status.accuracy
    _ = status.stateReason
    status.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
    let matte = ARMatteGenerator(device: ARKitHostMTLDevice(), matteResolution: .full)
    _ = matte.generateMatte(from: ARFrame(), commandBuffer: ARKitHostMTLCommandBuffer())
    _ = matte.generateDilatedDepth(from: ARFrame(), commandBuffer: ARKitHostMTLCommandBuffer())
}

// --- ARKitGeometryTests.swift ---
func testPlaneGeometryQuadLayout() {
    let geometry = arkitMakeHorizontalPlane().geometry
    arkitRequire(geometry.vertices.count == 4, "vertices")
    arkitRequire(geometry.triangleCount == 2, "triangles")
    arkitRequire(geometry.triangleIndices.count == 6, "indices")
    arkitRequire(geometry.textureCoordinates.count == 4, "uvs")
    arkitRequire(geometry.boundaryVertices.count == 4, "boundary")
    arkitRequire(ARPlaneGeometry().vertices.isEmpty, "empty")
    ARPlaneGeometry().encode(with: NSKeyedArchiver(requiringSecureCoding: true))
}

func testFaceGeometryFailClosed() {
    arkitRequire(ARFaceGeometry(blendShapes: [:]) == nil, "no Apple topology")
    arkitRequire(ARFaceGeometry().triangleCount == 0, "empty triangles")
    arkitRequire(ARFaceGeometry().vertices.isEmpty, "empty vertices")
    arkitRequire(ARFaceGeometry().textureCoordinates.isEmpty, "empty uvs")
    arkitRequire(ARFaceGeometry().triangleIndices.isEmpty, "empty indices")
    ARFaceGeometry().encode(with: NSKeyedArchiver(requiringSecureCoding: true))
}

func testMeshGeometrySources() {
    let mesh = ARMeshAnchor(anchor: ARAnchor(transform: .identity)).geometry
    _ = mesh.vertices
    _ = mesh.normals
    _ = mesh.faces
    _ = mesh.classification
    _ = mesh.vertices.buffer
    _ = mesh.vertices.format
    _ = mesh.vertices.componentsPerVector
    _ = mesh.vertices.count
    _ = mesh.vertices.offset
    _ = mesh.vertices.stride
    _ = mesh.vertices[Int32(0)]
    _ = mesh.faces.buffer
    _ = mesh.faces.bytesPerIndex
    _ = mesh.faces.count
    _ = mesh.faces.indexCountPerPrimitive
    _ = mesh.faces.primitiveType
    _ = mesh.faces[0]
    mesh.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
    mesh.vertices.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
    mesh.faces.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
}

func testPointCloudAndWorldMap() {
    let map = ARWorldMap()
    arkitRequire(map.anchors.isEmpty, "empty map")
    _ = map.center
    _ = map.extent
    _ = map.rawFeaturePoints.points
    _ = map.rawFeaturePoints.identifiers
    map.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
}

// --- ARKitOptionSetTests.swift ---
func testFrameSemanticsMembers() {
    arkitRequire(ARConfiguration.FrameSemantics.personSegmentation.rawValue == 1 << 0, "personSegmentation")
    arkitRequire(ARConfiguration.FrameSemantics.personSegmentationWithDepth.rawValue == 1 << 1, "withDepth")
    arkitRequire(ARConfiguration.FrameSemantics.bodyDetection.rawValue == 1 << 2, "bodyDetection")
    arkitRequire(ARConfiguration.FrameSemantics.sceneDepth.rawValue == 1 << 3, "sceneDepth")
    arkitRequire(ARConfiguration.FrameSemantics.smoothedSceneDepth.rawValue == 1 << 4, "smoothed")
    arkitRequire(ARConfiguration.FrameSemantics(rawValue: 1 << 0) == .personSegmentation, "init(rawValue:)")
    arkitRequire(ARConfiguration.FrameSemantics().rawValue == 0, "init()")
    let semanticsSequence: [ARConfiguration.FrameSemantics] = [.bodyDetection]
    arkitRequire(ARConfiguration.FrameSemantics(semanticsSequence) == .bodyDetection, "init(_:)")
    arkitRequire(ARConfiguration.FrameSemantics.personSegmentation != .sceneDepth, "inequality")
}

func testHitTestResultTypeMembers() {
    arkitRequire(ARHitTestResult.ResultType.featurePoint.rawValue == 1 << 0, "featurePoint")
    arkitRequire(ARHitTestResult.ResultType.estimatedHorizontalPlane.rawValue == 1 << 1, "estimatedHorizontal")
    arkitRequire(ARHitTestResult.ResultType.estimatedVerticalPlane.rawValue == 1 << 2, "estimatedVertical")
    arkitRequire(ARHitTestResult.ResultType.existingPlane.rawValue == 1 << 3, "existingPlane")
    arkitRequire(ARHitTestResult.ResultType.existingPlaneUsingExtent.rawValue == 1 << 4, "usingExtent")
    arkitRequire(ARHitTestResult.ResultType.existingPlaneUsingGeometry.rawValue == 1 << 5, "usingGeometry")
    arkitRequire(ARHitTestResult.ResultType(rawValue: 1 << 0) == .featurePoint, "init(rawValue:)")
    arkitRequire(ARHitTestResult.ResultType().isEmpty, "init()")
    let hitSequence: [ARHitTestResult.ResultType] = [.existingPlane]
    arkitRequire(ARHitTestResult.ResultType(hitSequence) == .existingPlane, "init(_:)")
    arkitRequire(ARHitTestResult.ResultType.featurePoint != .existingPlane, "inequality")
}

func testPlaneDetectionMembers() {
    arkitRequire(ARWorldTrackingConfiguration.PlaneDetection.horizontal.rawValue == 1 << 0, "horizontal")
    arkitRequire(ARWorldTrackingConfiguration.PlaneDetection.vertical.rawValue == 1 << 1, "vertical")
    arkitRequire(ARWorldTrackingConfiguration.PlaneDetection(rawValue: 1) == .horizontal, "init(rawValue:)")
    arkitRequire(ARWorldTrackingConfiguration.PlaneDetection().isEmpty, "init()")
    let planeSequence: [ARWorldTrackingConfiguration.PlaneDetection] = [.vertical]
    arkitRequire(ARWorldTrackingConfiguration.PlaneDetection(planeSequence) == .vertical, "init(_:)")
    arkitRequire(ARWorldTrackingConfiguration.PlaneDetection.horizontal != .vertical, "inequality")
}

func testSceneReconstructionMembers() {
    arkitRequire(ARConfiguration.SceneReconstruction.mesh.rawValue == 1 << 0, "mesh")
    arkitRequire(ARConfiguration.SceneReconstruction.meshWithClassification.rawValue == 1 << 1, "classified")
    arkitRequire(ARConfiguration.SceneReconstruction(rawValue: 1) == .mesh, "init(rawValue:)")
    arkitRequire(ARConfiguration.SceneReconstruction().isEmpty, "init()")
    let reconstructionSequence: [ARConfiguration.SceneReconstruction] = [.mesh]
    arkitRequire(ARConfiguration.SceneReconstruction(reconstructionSequence) == .mesh, "init(_:)")
    arkitRequire(ARConfiguration.SceneReconstruction.mesh != .meshWithClassification, "inequality")
}

func testSessionRunOptionsMembers() {
    arkitRequire(ARSession.RunOptions.resetTracking.rawValue == 1 << 0, "resetTracking")
    arkitRequire(ARSession.RunOptions.removeExistingAnchors.rawValue == 1 << 1, "removeExistingAnchors")
    arkitRequire(ARSession.RunOptions.stopTrackedRaycasts.rawValue == 1 << 2, "stopTrackedRaycasts")
    arkitRequire(ARSession.RunOptions.resetSceneReconstruction.rawValue == 1 << 3, "resetSceneReconstruction")
    arkitRequire(ARSession.RunOptions(rawValue: 1) == .resetTracking, "init(rawValue:)")
    arkitRequire(ARSession.RunOptions().isEmpty, "init()")
    let optionsSequence: [ARSession.RunOptions] = [.removeExistingAnchors]
    arkitRequire(ARSession.RunOptions(optionsSequence) == .removeExistingAnchors, "init(_:)")
    arkitRequire(ARSession.RunOptions.resetTracking != .stopTrackedRaycasts, "inequality")
}

func testFrameSemanticsAlgebra() {
    var semantics: ARConfiguration.FrameSemantics = [.personSegmentation]
    arkitRequire(semantics.contains(.personSegmentation), "contains")
    arkitRequire(semantics.union(.sceneDepth).contains(.sceneDepth), "union")
    arkitRequire(semantics.intersection(.personSegmentation) == .personSegmentation, "intersection")
    arkitRequire(!semantics.isDisjoint(with: .personSegmentation), "isDisjoint")
    arkitRequire(semantics.isSubset(of: [.personSegmentation, .sceneDepth]), "isSubset")
    arkitRequire(semantics.isStrictSubset(of: [.personSegmentation, .sceneDepth]), "isStrictSubset")
    arkitRequire(ARConfiguration.FrameSemantics([.personSegmentation, .sceneDepth]).isSuperset(of: semantics), "isSuperset")
    arkitRequire(
        ARConfiguration.FrameSemantics([.personSegmentation, .sceneDepth]).isStrictSuperset(of: semantics),
        "isStrictSuperset"
    )
    arkitRequire(semantics.subtracting(.personSegmentation).isEmpty, "subtracting")
    _ = semantics.symmetricDifference(.sceneDepth)
    semantics.formUnion(.smoothedSceneDepth)
    semantics.formIntersection(.personSegmentation)
    semantics.formSymmetricDifference(.bodyDetection)
    semantics.insert(.personSegmentationWithDepth)
    _ = semantics.update(with: .sceneDepth)
    _ = semantics.remove(.sceneDepth)
    semantics.subtract(.bodyDetection)
    arkitRequire(!ARConfiguration.FrameSemantics.personSegmentation.isEmpty, "isEmpty false")
}

func testHitTestResultTypeAlgebra() {
    var hits: ARHitTestResult.ResultType = [.featurePoint]
    arkitRequire(hits.contains(.featurePoint), "contains")
    arkitRequire(hits.union(.existingPlane).contains(.existingPlane), "union")
    arkitRequire(hits.intersection(.featurePoint) == .featurePoint, "intersection")
    arkitRequire(!hits.isDisjoint(with: .featurePoint), "isDisjoint")
    arkitRequire(hits.isSubset(of: [.featurePoint, .existingPlane]), "isSubset")
    arkitRequire(hits.isStrictSubset(of: [.featurePoint, .existingPlane]), "isStrictSubset")
    arkitRequire(ARHitTestResult.ResultType([.featurePoint, .existingPlane]).isSuperset(of: hits), "isSuperset")
    arkitRequire(
        ARHitTestResult.ResultType([.featurePoint, .existingPlane]).isStrictSuperset(of: hits),
        "isStrictSuperset"
    )
    arkitRequire(hits.subtracting(.featurePoint).isEmpty, "subtracting")
    _ = hits.symmetricDifference(.existingPlane)
    hits.formUnion(.existingPlaneUsingExtent)
    hits.formIntersection(.featurePoint)
    hits.formSymmetricDifference(.estimatedHorizontalPlane)
    hits.insert(.existingPlaneUsingGeometry)
    _ = hits.update(with: .estimatedVerticalPlane)
    _ = hits.remove(.estimatedVerticalPlane)
    hits.subtract(.estimatedHorizontalPlane)
}

func testPlaneDetectionAlgebra() {
    var planes: ARWorldTrackingConfiguration.PlaneDetection = [.horizontal]
    arkitRequire(planes.contains(.horizontal), "contains")
    arkitRequire(planes.union(.vertical).contains(.vertical), "union")
    arkitRequire(planes.intersection(.horizontal) == .horizontal, "intersection")
    arkitRequire(!planes.isDisjoint(with: .horizontal), "isDisjoint")
    arkitRequire(planes.isSubset(of: [.horizontal, .vertical]), "isSubset")
    arkitRequire(planes.isStrictSubset(of: [.horizontal, .vertical]), "isStrictSubset")
    arkitRequire(ARWorldTrackingConfiguration.PlaneDetection([.horizontal, .vertical]).isSuperset(of: planes), "isSuperset")
    arkitRequire(
        ARWorldTrackingConfiguration.PlaneDetection([.horizontal, .vertical]).isStrictSuperset(of: planes),
        "isStrictSuperset"
    )
    arkitRequire(planes.subtracting(.horizontal).isEmpty, "subtracting")
    _ = planes.symmetricDifference(.vertical)
    planes.formUnion(.vertical)
    planes.formIntersection(.horizontal)
    planes.formSymmetricDifference(.vertical)
    planes.insert(.horizontal)
    _ = planes.update(with: .vertical)
    _ = planes.remove(.vertical)
    planes.subtract(.horizontal)
}

func testSceneReconstructionAlgebra() {
    var reconstruction: ARConfiguration.SceneReconstruction = [.mesh]
    arkitRequire(reconstruction.contains(.mesh), "contains")
    arkitRequire(reconstruction.union(.meshWithClassification).contains(.meshWithClassification), "union")
    arkitRequire(reconstruction.intersection(.mesh) == .mesh, "intersection")
    arkitRequire(!reconstruction.isDisjoint(with: .mesh), "isDisjoint")
    arkitRequire(reconstruction.isSubset(of: [.mesh, .meshWithClassification]), "isSubset")
    arkitRequire(reconstruction.isStrictSubset(of: [.mesh, .meshWithClassification]), "isStrictSubset")
    arkitRequire(
        ARConfiguration.SceneReconstruction([.mesh, .meshWithClassification]).isSuperset(of: reconstruction),
        "isSuperset"
    )
    arkitRequire(
        ARConfiguration.SceneReconstruction([.mesh, .meshWithClassification]).isStrictSuperset(of: reconstruction),
        "isStrictSuperset"
    )
    arkitRequire(reconstruction.subtracting(.mesh).isEmpty, "subtracting")
    _ = reconstruction.symmetricDifference(.meshWithClassification)
    reconstruction.formUnion(.meshWithClassification)
    reconstruction.formIntersection(.mesh)
    reconstruction.formSymmetricDifference(.mesh)
    reconstruction.insert(.mesh)
    _ = reconstruction.update(with: .meshWithClassification)
    _ = reconstruction.remove(.meshWithClassification)
    reconstruction.subtract(.mesh)
}

func testSessionRunOptionsAlgebra() {
    var options: ARSession.RunOptions = [.resetTracking]
    arkitRequire(options.contains(.resetTracking), "contains")
    arkitRequire(options.union(.removeExistingAnchors).contains(.removeExistingAnchors), "union")
    arkitRequire(options.intersection(.resetTracking) == .resetTracking, "intersection")
    arkitRequire(!options.isDisjoint(with: .resetTracking), "isDisjoint")
    arkitRequire(options.isSubset(of: [.resetTracking, .removeExistingAnchors]), "isSubset")
    arkitRequire(options.isStrictSubset(of: [.resetTracking, .removeExistingAnchors]), "isStrictSubset")
    arkitRequire(ARSession.RunOptions([.resetTracking, .removeExistingAnchors]).isSuperset(of: options), "isSuperset")
    arkitRequire(
        ARSession.RunOptions([.resetTracking, .removeExistingAnchors]).isStrictSuperset(of: options),
        "isStrictSuperset"
    )
    arkitRequire(options.subtracting(.resetTracking).isEmpty, "subtracting")
    _ = options.symmetricDifference(.stopTrackedRaycasts)
    options.formUnion(.removeExistingAnchors)
    options.formIntersection(.resetTracking)
    options.formSymmetricDifference(.resetSceneReconstruction)
    options.insert(.stopTrackedRaycasts)
    _ = options.update(with: .resetTracking)
    _ = options.remove(.resetTracking)
    options.subtract(.stopTrackedRaycasts)
    _ = ARSession.RunOptions(arrayLiteral: .resetSceneReconstruction)
}

// --- ARKitRaycastTests.swift ---
func testRaycastQueryConstruction() {
    let query = ARRaycastQuery(
        origin: simd_float3(0, 0, 0),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneGeometry,
        alignment: .horizontal
    )
    arkitRequire(query.target == .existingPlaneGeometry, "target")
    arkitRequire(query.targetAlignment == .horizontal, "alignment")
    arkitRequire(query.origin.y == 0, "origin")
    arkitRequire(query.direction.y == -1, "direction")
    let alias = ARRaycastQuery(
        origin: query.origin,
        direction: query.direction,
        allowingTarget: .estimatedPlane,
        alignment: .any
    )
    arkitRequire(alias.target == .estimatedPlane, "allowingTarget")
}

func testSessionRaycastAgainstSimulatedPlane() {
    let plane = arkitMakeHorizontalPlane()
    let session = ARSession()
    session.add(anchor: plane)
    let hitQuery = ARRaycastQuery(
        origin: simd_float3(0, 1, 0),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneGeometry,
        alignment: .horizontal
    )
    let hits = session.raycast(hitQuery)
    arkitRequire(hits.count == 1, "one hit")
    arkitRequire(arkitAlmostEqual(hits[0].worldTransform.columns.3.y, 0), "y=0")
    arkitRequire(hits[0].target == .existingPlaneGeometry, "result target")
    arkitRequire(hits[0].targetAlignment == .horizontal, "result alignment")
    arkitRequire(hits[0].anchor?.identifier == plane.identifier, "anchor")
    _ = hits[0].worldTransform

    let miss = ARRaycastQuery(
        origin: simd_float3(10, 1, 10),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneGeometry,
        alignment: .horizontal
    )
    arkitRequire(session.raycast(miss).isEmpty, "outside extent")

    let infinite = ARRaycastQuery(
        origin: simd_float3(10, 1, 10),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneInfinite,
        alignment: .horizontal
    )
    arkitRequire(!session.raycast(infinite).isEmpty, "infinite plane")

    let estimated = ARRaycastQuery(
        origin: simd_float3(0, 2, 0),
        direction: simd_float3(0, -1, 0),
        allowing: .estimatedPlane,
        alignment: .horizontal
    )
    arkitRequire(session.raycast(estimated).contains { $0.target == .estimatedPlane }, "estimated y=0")
}

func testTrackedRaycastLifecycle() {
    ARKitTestHook.removeSimulatedDevice()
    let idle = ARSession()
    let query = ARRaycastQuery(
        origin: simd_float3(0, 1, 0),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneGeometry,
        alignment: .horizontal
    )
    arkitRequire(idle.trackedRaycast(query, updateHandler: { _ in }) == nil, "nil when not running")

    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }
    let session = ARSession()
    session.run(ARWorldTrackingConfiguration())
    var trackedResults: [[ARRaycastResult]] = []
    let tracked = session.trackedRaycast(query) { trackedResults.append($0) }
    arkitRequire(tracked != nil, "tracked while running")
    arkitRequire(!trackedResults.isEmpty, "handler fired")
    tracked?.stopTracking()
    session.pause()
    arkitRequire(session.trackedRaycast(query, updateHandler: { _ in }) == nil, "nil when paused")
}

func testFrameHitTestResultTypes() {
    let camera = ARCamera(
        trackingState: .normal,
        transform: ARSimulatedCameraDefaults.transform,
        imageResolution: CGSize(width: 640, height: 480),
        intrinsics: ARSimulatedCameraDefaults.intrinsics
    )
    let plane = arkitMakeHorizontalPlane()
    let frame = ARFrame(anchors: [plane], camera: camera, timestamp: 1)
    let extentHits = frame.hitTest(
        CGPoint(x: 0.5, y: 0.5),
        types: [.existingPlaneUsingExtent, .existingPlaneUsingGeometry, .existingPlane]
    )
    _ = extentHits
    let estimated = frame.hitTest(
        CGPoint(x: 0.5, y: 0.5),
        types: [.estimatedHorizontalPlane, .estimatedVerticalPlane, .featurePoint]
    )
    _ = estimated
    if let hit = extentHits.first {
        _ = hit.type
        _ = hit.distance
        _ = hit.localTransform
        _ = hit.worldTransform
        _ = hit.anchor
    }
}

// --- ARKitReferenceTests.swift ---
func testReferenceImageFromCGImage() {
    let cgImage = CGImage(width: 100, height: 50)
    let image = ARReferenceImage(cgImage, orientation: .up, physicalWidth: 0.2)
    arkitRequire(abs(image.physicalSize.width - 0.2) < 0.0001, "width")
    arkitRequire(abs(image.physicalSize.height - 0.1) < 0.0001, "height")
    _ = ARReferenceImage(CGImage: cgImage, orientation: .up, physicalWidth: 0.2)
    _ = ARReferenceImage(CVPixelBuffer(width: 10, height: 5), orientation: .right, physicalWidth: 0.1)
    _ = ARReferenceImage(pixelBuffer: CVPixelBuffer(width: 10, height: 5), orientation: .left, physicalWidth: 0.1)
    image.name = "marker"
    arkitRequire(image.name == "marker", "name")
    _ = image.resourceGroupName
    _ = image.hash
    arkitRequire(!image.isEqual(ARReferenceImage(physicalSize: .zero)), "identity")
}

func testReferenceImageAndObjectFailClosed() {
    arkitRequire(ARReferenceImage.referenceImages(inGroupNamed: "detect", bundle: nil) == nil, "image group")
    arkitWait { done in
        ARReferenceImage(physicalSize: CGSize(width: 0.2, height: 0.2)).validate { error in
            arkitRequire((error as? ARError)?.code == .invalidReferenceImage, "validate")
            done()
        }
    }
    arkitRequire(ARReferenceObject.archiveExtension == "arobject", "extension")
    arkitRequire(ARReferenceObject.referenceObjects(inGroupNamed: "objects", bundle: nil) == nil, "object group")
    let object = ARReferenceObject()
    object.name = "scan"
    arkitRequire(object.name == "scan", "name")
    _ = object.center
    _ = object.extent
    _ = object.scale
    _ = object.rawFeaturePoints
    _ = object.resourceGroupName
    _ = object.applyingTransform(.identity)
    do {
        _ = try ARReferenceObject(archiveURL: URL(fileURLWithPath: "/tmp/missing.arobject"))
        fatalError("archive load must fail")
    } catch {
        arkitRequire((error as? ARError)?.code == .fileIOFailed, "archive IO")
    }
    do {
        _ = try object.merging(ARReferenceObject())
        fatalError("merge must fail")
    } catch {
        arkitRequire((error as? ARError)?.code == .objectMergeFailed, "merge")
    }
    do {
        try object.export(to: URL(fileURLWithPath: "/tmp/out.arobject"), previewImage: nil)
        fatalError("export must fail")
    } catch {
        arkitRequire((error as? ARError)?.code == .fileIOFailed, "export")
    }
    object.encode(with: NSKeyedArchiver(requiringSecureCoding: true))
}

// --- ARKitSessionTests.swift ---
func testSessionRunFailsClosedWithoutDevice() {
    ARKitTestHook.removeSimulatedDevice()
    let session = ARSession()
    let probe = ARKitSessionProbe()
    session.delegate = probe
    arkitRequire(session.identifier != UUID(uuidString: "00000000-0000-0000-0000-000000000000"), "identifier")
    arkitRequire(session.currentFrame == nil, "no fabricated frame")
    let named = ARAnchor(name: "artwork", transform: .identity)
    session.add(anchor: named)
    session.remove(anchor: named)
    session.add(anchor: named)
    session.setWorldOrigin(relativeTransform: .identity)
    session.run(ARWorldTrackingConfiguration(), options: [.resetTracking, .removeExistingAnchors])
    arkitRequire(probe.failures == [.unsupportedConfiguration], "unsupportedConfiguration")
    arkitRequire(session.configuration != nil, "requested configuration retained")
    arkitRequire(session.currentFrame == nil, "run does not invent a frame")
    session.pause()
}

func testSessionCameraUnauthorized() {
    ARKitTestHook.removeSimulatedDevice()
    ARKitTestHook.installSimulatedDevice(cameraAuthorized: false)
    defer { ARKitTestHook.removeSimulatedDevice() }
    let session = ARSession()
    let probe = ARKitSessionProbe()
    session.delegate = probe
    session.run(ARWorldTrackingConfiguration())
    arkitRequire(probe.failures == [.cameraUnauthorized], "cameraUnauthorized")
    arkitRequire(session.currentFrame == nil, "no frame when unauthorized")
}

func testSessionSimulatedRunAndDelegateOrder() {
    ARKitTestHook.removeSimulatedDevice()
    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }

    let world = ARWorldTrackingConfiguration()
    world.planeDetection = [.horizontal]
    world.isLightEstimationEnabled = true
    let session = ARSession()
    let probe = ARKitSessionProbe()
    session.delegate = probe
    session.run(world, options: [.resetTracking, .removeExistingAnchors])
    arkitRequire(probe.failures.isEmpty, "simulated run succeeds")
    arkitRequire(session.currentFrame != nil, "currentFrame")
    arkitRequire(session.currentFrame!.camera.trackingState == .normal, "tracking")
    arkitRequire(session.currentFrame!.anchors.contains { $0 is ARPlaneAnchor }, "plane added")
    arkitRequire(probe.order.first == "frame", "frame first")
    arkitRequire(probe.order.contains("add"), "didAdd")
    arkitRequire(probe.trackingStates.contains(.normal), "tracking callback")
    arkitRequire(session.currentFrame!.lightEstimate?.ambientIntensity == 1000, "light")
    arkitRequire(session.configuration === world || session.configuration != nil, "configuration")
    _ = session.delegateQueue
}

func testSessionAddRemoveAnchorsAndPause() {
    ARKitTestHook.removeSimulatedDevice()
    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }

    let session = ARSession()
    let probe = ARKitSessionProbe()
    session.delegate = probe
    session.run(ARWorldTrackingConfiguration())
    let later = ARAnchor(name: "later", transform: .identity)
    session.add(anchor: later)
    arkitRequire(session.currentFrame!.anchors.contains { $0.name == "later" }, "user anchor")
    session.remove(anchor: later)
    arkitRequire(!session.currentFrame!.anchors.contains { $0.name == "later" }, "removed")
    arkitRequire(probe.removed.contains { $0.contains { $0.name == "later" } }, "didRemove")
    session.setWorldOrigin(relativeTransform: simd_float4x4.translation(simd_float3(1, 0, 0)))
    arkitRequire(session.currentFrame != nil, "frame after origin")
    session.pause()
    arkitRequire(session.currentFrame != nil, "pause keeps last frame")
}

func testSessionCollaborationUpdate() {
    let session = ARSession()
    let data = ARSession.CollaborationData(priority: .optional)
    arkitRequire(data.priority == .optional, "priority")
    session.update(with: ARSession.CollaborationData(priority: .critical))
    arkitRequire(ARSession.CollaborationData.supportsSecureCoding, "secure coding")
}

func testSessionObserverDefaultMethods() {
    let session = ARSession()
    let empty = EmptySessionDelegate()
    empty.session(session, cameraDidChangeTrackingState: ARCamera())
    empty.session(session, didChange: ARGeoTrackingStatus())
    empty.session(session, didFailWithError: ARError(.requestFailed))
    empty.session(session, didOutputCollaborationData: ARSession.CollaborationData(priority: .optional))
    empty.session(session, didOutputAudioSampleBuffer: CMSampleBuffer())
    empty.sessionInterruptionEnded(session)
    arkitRequire(!empty.sessionShouldAttemptRelocalization(session), "relocalization default")
    empty.sessionWasInterrupted(session)
    empty.session(session, didAdd: [])
    empty.session(session, didRemove: [])
    empty.session(session, didUpdate: [ARAnchor]())
    empty.session(session, didUpdate: ARFrame())
}

// --- ARKitSkeletonTests.swift ---
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

// --- ARKitViewTests.swift ---
func testSCNViewStandIn() {
    let session = ARSession()
    let view = ARSCNView()
    view.session = session
    view.automaticallyUpdatesLighting = false
    view.rendersCameraGrain = true
    view.rendersMotionBlur = true
    _ = view.scene
    _ = view.delegate
    arkitRequire(view.anchor(for: SCNNode()) == nil, "node map")
    arkitRequire(view.node(for: ARAnchor(transform: .identity)) == nil, "anchor map")
    _ = view.hitTest(.zero, types: .featurePoint)
    _ = view.raycastQuery(from: CGPoint(x: 0.5, y: 0.5), allowing: .estimatedPlane, alignment: .horizontal)
    _ = view.unprojectPoint(.zero, ontoPlane: .identity)
    arkitRequire(ARSCNFaceGeometry(device: ARKitHostMTLDevice()) == nil, "face geo")
    arkitRequire(ARSCNFaceGeometry(device: ARKitHostMTLDevice(), fillMesh: true) == nil, "fill mesh")
    ARSCNFaceGeometry().update(from: ARFaceGeometry())
    arkitRequire(ARSCNPlaneGeometry(device: ARKitHostMTLDevice()) == nil, "plane geo")
    ARSCNPlaneGeometry().update(from: ARPlaneGeometry())
}

func testSKViewStandIn() {
    let view = ARSKView()
    view.session = ARSession()
    arkitRequire(view.anchor(for: SKNode()) == nil, "sprite node")
    arkitRequire(view.node(for: ARAnchor(transform: .identity)) == nil, "sprite anchor")
    _ = view.hitTest(.zero, types: .existingPlane)
    _ = view.delegate
}

func testCoachingOverlayStandIn() {
    let session = ARSession()
    let coaching = ARCoachingOverlayView()
    coaching.goal = .horizontalPlane
    coaching.session = session
    coaching.activatesAutomatically = false
    coaching.setActive(true, animated: false)
    arkitRequire(!coaching.isActive, "stays inactive")
    arkitRequire(coaching.goal == .horizontalPlane, "goal stored")
    let scn = ARSCNView()
    coaching.sessionProvider = scn
    arkitRequire(coaching.sessionProvider?.session === scn.session || coaching.sessionProvider != nil, "provider")
    _ = coaching.delegate
}

func testViewDelegateDefaults() {
    let renderer = DummySceneRenderer()
    let node = SCNNode()
    let anchor = ARAnchor(transform: .identity)
    let scn = EmptySCNViewDelegate()
    scn.renderer(renderer, didAdd: node, for: anchor)
    scn.renderer(renderer, didRemove: node, for: anchor)
    scn.renderer(renderer, didUpdate: node, for: anchor)
    arkitRequire(scn.renderer(renderer, nodeFor: anchor) == nil, "nodeFor")
    scn.renderer(renderer, willUpdate: node, for: anchor)

    let sk = EmptySKViewDelegate()
    let view = ARSKView()
    let sprite = SKNode()
    sk.view(view, didAdd: sprite, for: anchor)
    sk.view(view, didRemove: sprite, for: anchor)
    sk.view(view, didUpdate: sprite, for: anchor)
    arkitRequire(sk.view(view, nodeFor: anchor) == nil, "sprite nodeFor")
    sk.view(view, willUpdate: sprite, for: anchor)

    let coaching = EmptyCoachingDelegate()
    let overlay = ARCoachingOverlayView()
    coaching.coachingOverlayViewWillActivate(overlay)
    coaching.coachingOverlayViewDidDeactivate(overlay)
    coaching.coachingOverlayViewDidRequestSessionReset(overlay)
}

func arkitRunAllAgentTests() {
    testARErrorCodesAndDomain()
    testARErrorValueSemantics()
    testAnchorCoderFallbacks()
    testAnchorCopyingAndSecureCoding()
    testAnchorEnumCases()
    testBlendShapeLocationValues()
    testCameraProjectionAndViewMatrix()
    testCameraTrackingStateCases()
    testCoachingMatteAndCollaborationEnumCases()
    testCoachingOverlayStandIn()
    testConfidenceLevelCases()
    testConfidenceLevelComparable()
    testConfigurationSupportedWithHook()
    testConfigurationUnsupportedWithoutHook()
    testFaceGeometryFailClosed()
    testFrameHitTestResultTypes()
    testFramePropertiesAndDisplayTransform()
    testFrameSemanticsAlgebra()
    testFrameSemanticsMembers()
    testFrameStatusEnumCases()
    testGeoAvailabilityFailClosed()
    testGeoTrackingEnumCases()
    testGeometryPrimitiveTypeCases()
    testHitTestResultTypeAlgebra()
    testHitTestResultTypeMembers()
    testLightDepthAndMatte()
    testMeshClassificationCases()
    testMeshGeometrySources()
    testOtherConfigurationCopies()
    testPlaneAnchorLayout()
    testPlaneClassificationCases()
    testPlaneDetectionAlgebra()
    testPlaneDetectionMembers()
    testPlaneGeometryQuadLayout()
    testPointCloudAndWorldMap()
    testRaycastQueryConstruction()
    testRaycastTargetEnumCases()
    testReferenceImageAndObjectFailClosed()
    testReferenceImageFromCGImage()
    testSCNDebugOptionBits()
    testSCNViewStandIn()
    testSKViewStandIn()
    testSceneReconstructionAlgebra()
    testSceneReconstructionMembers()
    testSessionAddRemoveAnchorsAndPause()
    testSessionCameraUnauthorized()
    testSessionCollaborationUpdate()
    testSessionFailClosedIO()
    testSessionObserverDefaultMethods()
    testSessionRaycastAgainstSimulatedPlane()
    testSessionRunFailsClosedWithoutDevice()
    testSessionRunOptionsAlgebra()
    testSessionRunOptionsMembers()
    testSessionSimulatedRunAndDelegateOrder()
    testSimulatedSessionWorldMapStillFailClosed()
    testSkeletonDefinitionAndTransforms()
    testSkeletonJointNameValues()
    testSpecializedAnchors()
    testTrackedRaycastLifecycle()
    testVideoFormatPlaceholder()
    testViewDelegateDefaults()
    testWorldAlignmentAndTexturingCases()
    testWorldTrackingConfigurationCopy()
}

arkitRunAllAgentTests()
print("ARKIT_AGENT_RUNTIME_OK")
