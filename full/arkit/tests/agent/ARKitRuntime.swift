import Foundation
import ARKit

private final class SessionProbe: NSObject, ARSessionDelegate {
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

private func almostEqual(_ a: Float, _ b: Float, eps: Float = 1e-4) -> Bool {
    abs(a - b) < eps
}

private func runDepthPassExercises() async {
    require(!ARKitTestHook.isSimulatedDeviceInstalled, "hook starts off")

    let camera = ARCamera(
        trackingState: .normal,
        transform: .identity,
        imageResolution: CGSize(width: 640, height: 480),
        intrinsics: ARSimulatedCameraDefaults.intrinsics
    )
    require(camera.imageResolution.width == 640, "simulated image width")
    require(almostEqual(camera.intrinsics.columns.0.x, 640), "fx")
    require(almostEqual(camera.intrinsics.columns.2.x, 320), "cx")
    let projection = camera.projectionMatrix(
        for: UIInterfaceOrientation.landscapeRight,
        viewportSize: CGSize(width: 640, height: 480),
        zNear: 0.001,
        zFar: 1000
    )
    require(almostEqual(projection.columns.0.x, 2), "pinhole m00 = 2 fx / w")
    require(almostEqual(projection.columns.1.y, 2 * 640 / 480), "pinhole m11 = 2 fy / h")
    require(almostEqual(projection.columns.2.x, 1 - 2 * 320 / 640), "pinhole m20")
    require(almostEqual(projection.columns.2.y, 2 * 240 / 480 - 1), "pinhole m21")
    require(almostEqual(projection.columns.2.w, -1), "pinhole perspective w")
    let near: Float = 0.001
    let far: Float = 1000
    require(almostEqual(projection.columns.2.z, -(far + near) / (far - near)), "pinhole m22")
    require(almostEqual(projection.columns.3.z, -2 * far * near / (far - near)), "pinhole m32")
    require(camera.viewMatrix(for: UIInterfaceOrientation.landscapeRight) == simd_float4x4.identity, "identity view")
    let portraitView = camera.viewMatrix(for: UIInterfaceOrientation.portrait)
    require(almostEqual(portraitView.columns.0.x, 0), "portrait rotates X")
    require(almostEqual(portraitView.columns.0.y, -1) || almostEqual(portraitView.columns.0.y, 1), "portrait Y")
    _ = camera.eulerAngles
    _ = camera.projectionMatrix
    _ = camera.exposureDuration
    _ = camera.exposureOffset
    let projected = camera.projectPoint(simd_float3(0, 0, -1), orientation: UIInterfaceOrientation.landscapeRight, viewportSize: CGSize(width: 640, height: 480))
    require(projected.x > 0 && projected.y > 0, "projectPoint in view")
    let unprojected = camera.unprojectPoint(
        CGPoint(x: 0.5, y: 0.5),
        ontoPlane: simd_float4x4.identity,
        orientation: UIInterfaceOrientation.landscapeRight,
        viewportSize: CGSize(width: 640, height: 480)
    )
    _ = unprojected
    let queryDown = ARRaycastQuery(
        origin: simd_float3(0, 1, 0),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneGeometry,
        alignment: .horizontal
    )
    let plane = ARPlaneAnchor(
        transform: .identity,
        alignment: .horizontal,
        center: simd_float3(repeating: 0),
        extent: simd_float3(2, 0, 2),
        classification: .floor,
        isTracked: true,
        identifier: UUID(),
        sessionIdentifier: UUID()
    )
    require(plane.geometry.vertexCount == 4, "plane quad vertices")
    require(plane.geometry.triangleCount == 2, "two triangles")
    require(plane.geometry.boundaryVertices.count == 4, "boundary")
    require(plane.geometry.textureCoordinates.count == 4, "uvs")
    require(plane.geometry.triangleIndices.count == 6, "indices")
    require(plane.planeExtent.width == 2 && plane.planeExtent.height == 2, "extent")
    require(plane.isTracked, "simulated plane tracked")
    require(plane.classification == .floor, "classification stored")
    require(plane.alignment == .horizontal, "alignment")
    _ = plane.center
    _ = ARPlaneAnchor.Classification.wall
    _ = ARPlaneAnchor.Classification.ceiling
    _ = ARPlaneAnchor.Classification.table
    _ = ARPlaneAnchor.Classification.seat
    _ = ARPlaneAnchor.Classification.window
    _ = ARPlaneAnchor.Classification.door
    _ = ARPlaneAnchor.Classification.none(.unknown)
    require(ARPlaneAnchor.Classification.wall != .floor, "classification inequality")

    let mathSession = ARSession()
    mathSession.add(anchor: plane)
    let rayHits = mathSession.raycast(queryDown)
    require(rayHits.count == 1, "one plane hit")
    require(almostEqual(rayHits[0].worldTransform.columns.3.y, 0), "hit y")
    require(rayHits[0].target == .existingPlaneGeometry, "target type")
    require(rayHits[0].anchor?.identifier == plane.identifier, "hit plane")

    let miss = ARRaycastQuery(
        origin: simd_float3(10, 1, 10),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneGeometry,
        alignment: .horizontal
    )
    require(mathSession.raycast(miss).isEmpty, "outside extent")
    let infinite = ARRaycastQuery(
        origin: simd_float3(10, 1, 10),
        direction: simd_float3(0, -1, 0),
        allowing: .existingPlaneInfinite,
        alignment: .horizontal
    )
    require(!mathSession.raycast(infinite).isEmpty, "infinite plane")

    let estimated = ARRaycastQuery(
        origin: simd_float3(0, 2, 0),
        direction: simd_float3(0, -1, 0),
        allowing: .estimatedPlane,
        alignment: .horizontal
    )
    let estimatedHits = mathSession.raycast(estimated)
    require(estimatedHits.contains { $0.target == .estimatedPlane }, "estimated y=0")

    let frameForHit = ARFrame(anchors: [plane], camera: camera, timestamp: 1)
    let extentHits = frameForHit.hitTest(
        CGPoint(x: 0.5, y: 0.5),
        types: ARHitTestResult.ResultType([.existingPlaneUsingExtent, .existingPlaneUsingGeometry, .existingPlane])
    )
    _ = extentHits
    let estimatedHit = frameForHit.hitTest(
        CGPoint(x: 0.5, y: 0.5),
        types: ARHitTestResult.ResultType([.estimatedHorizontalPlane, .estimatedVerticalPlane, .featurePoint])
    )
    _ = estimatedHit
    _ = frameForHit.displayTransform(for: UIInterfaceOrientation.portrait, viewportSize: CGSize(width: 100, height: 200))
    _ = frameForHit.displayTransform(for: UIInterfaceOrientation.portraitUpsideDown, viewportSize: CGSize.zero)
    _ = frameForHit.displayTransform(for: UIInterfaceOrientation.landscapeLeft, viewportSize: CGSize.zero)
    _ = frameForHit.displayTransform(for: UIInterfaceOrientation.landscapeRight, viewportSize: CGSize.zero)
    _ = frameForHit.displayTransform(for: UIInterfaceOrientation.unknown, viewportSize: CGSize.zero)
    _ = frameForHit.capturedImage.width
    _ = frameForHit.cameraGrainTexture
    _ = frameForHit.capturedDepthData
    _ = frameForHit.estimatedDepthData
    _ = frameForHit.segmentationBuffer
    _ = frameForHit.sceneDepth
    _ = frameForHit.smoothedSceneDepth
    _ = frameForHit.exifData
    _ = frameForHit.detectedBody
    _ = frameForHit.lightEstimate
    _ = frameForHit.rawFeaturePoints
    _ = frameForHit.geoTrackingStatus
    _ = frameForHit.worldMappingStatus
    _ = frameForHit.timestamp
    _ = frameForHit.cameraGrainIntensity
    _ = frameForHit.capturedDepthDataTimestamp
    _ = frameForHit.anchors

    ARKitTestHook.installSimulatedDevice(cameraAuthorized: false)
    require(ARWorldTrackingConfiguration.isSupported, "hook enables isSupported")
    require(ARConfiguration.isSupported, "base isSupported")
    require(ARFaceTrackingConfiguration.isSupported, "face isSupported")
    require(ARImageTrackingConfiguration.isSupported, "image isSupported")
    require(ARBodyTrackingConfiguration.isSupported, "body isSupported")
    require(ARGeoTrackingConfiguration.isSupported, "geo isSupported")
    require(ARPositionalTrackingConfiguration.isSupported, "positional isSupported")
    require(AROrientationTrackingConfiguration.isSupported, "orientation isSupported")
    require(ARObjectScanningConfiguration.isSupported, "object scanning isSupported")
    let unauthorized = ARSession()
    let unauthorizedProbe = SessionProbe()
    unauthorized.delegate = unauthorizedProbe
    unauthorized.run(ARWorldTrackingConfiguration())
    require(unauthorizedProbe.failures == [.cameraUnauthorized], "cameraUnauthorized")
    require(unauthorized.currentFrame == nil, "no frame when unauthorized")
    ARKitTestHook.removeSimulatedDevice()

    ARKitTestHook.installSimulatedDevice()
    defer { ARKitTestHook.removeSimulatedDevice() }

    require(ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces == 1, "tracked faces with hook")
    require(ARConfiguration.configurableCaptureDeviceForPrimaryCamera == nil, "no capture device")
    require(ARConfiguration.supportedVideoFormats.isEmpty, "formats stay empty")

    let world = ARWorldTrackingConfiguration()
    world.planeDetection = [.horizontal]
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
    let worldCopy = world.copy() as! ARWorldTrackingConfiguration
    require(worldCopy.planeDetection == world.planeDetection, "world copy planes")
    require(worldCopy.isCollaborationEnabled, "world copy collaboration")
    require(worldCopy.providesAudioData, "world copy audio")
    require(worldCopy.videoHDRAllowed, "world copy hdr")
    require(worldCopy.worldAlignment == .gravityAndHeading, "world copy alignment")

    let face = ARFaceTrackingConfiguration()
    face.maximumNumberOfTrackedFaces = 2
    face.isWorldTrackingEnabled = true
    require((face.copy() as! ARFaceTrackingConfiguration).maximumNumberOfTrackedFaces == 2, "face copy")
    let image = ARImageTrackingConfiguration()
    image.maximumNumberOfTrackedImages = 4
    image.isAutoFocusEnabled = false
    require((image.copy() as! ARImageTrackingConfiguration).maximumNumberOfTrackedImages == 4, "image copy")
    let body = ARBodyTrackingConfiguration()
    body.automaticSkeletonScaleEstimationEnabled = true
    body.planeDetection = [.vertical]
    require((body.copy() as! ARBodyTrackingConfiguration).automaticSkeletonScaleEstimationEnabled, "body copy")
    let geo = ARGeoTrackingConfiguration()
    geo.maximumNumberOfTrackedImages = 3
    require((geo.copy() as! ARGeoTrackingConfiguration).maximumNumberOfTrackedImages == 3, "geo copy")
    let positional = ARPositionalTrackingConfiguration()
    positional.planeDetection = [.horizontal]
    require(!(positional.copy() as! ARPositionalTrackingConfiguration).planeDetection.isEmpty, "positional copy")
    let objectScan = ARObjectScanningConfiguration()
    objectScan.planeDetection = [.vertical]
    require((objectScan.copy() as! ARObjectScanningConfiguration).planeDetection.contains(.vertical), "object scan copy")
    let orientation = AROrientationTrackingConfiguration()
    orientation.isAutoFocusEnabled = false
    require(!(orientation.copy() as! AROrientationTrackingConfiguration).isAutoFocusEnabled, "orientation copy")

    let format = ARConfiguration.VideoFormat.unsupportedPlaceholder
    _ = format.captureDevicePosition
    _ = format.captureDeviceType
    _ = format.defaultColorSpace
    _ = format.defaultPhotoSettings
    _ = format.framesPerSecond
    _ = format.imageResolution
    _ = format.isRecommendedForHighResolutionFrameCapturing
    _ = format.isVideoHDRSupported

    let session = ARSession()
    let probe = SessionProbe()
    session.delegate = probe
    let userAnchor = ARAnchor(name: "pin", transform: .identity)
    session.add(anchor: userAnchor)
    session.run(world, options: [.resetTracking, .removeExistingAnchors])
    require(probe.failures.isEmpty, "simulated run succeeds")
    require(session.currentFrame != nil, "simulated frame")
    require(session.currentFrame!.camera.trackingState == .normal, "normal tracking")
    require(almostEqual(Float(session.currentFrame!.camera.imageResolution.width), 640), "frame resolution")
    require(session.currentFrame!.anchors.contains { $0 is ARPlaneAnchor }, "plane anchor added")
    require(probe.order.first == "frame", "frame callback first")
    require(probe.order.contains("add"), "didAdd fired")
    require(probe.trackingStates.contains(.normal), "tracking state callback")
    require(session.currentFrame!.lightEstimate?.ambientIntensity == 1000, "simulated light")

    let sessionHits = session.raycast(queryDown)
    require(!sessionHits.isEmpty, "session raycast simulated plane")
    var trackedResults: [[ARRaycastResult]] = []
    let tracked = session.trackedRaycast(queryDown) { trackedResults.append($0) }
    require(tracked != nil, "tracked raycast exists while running")
    require(!trackedResults.isEmpty, "tracked handler fired")
    tracked?.stopTracking()

    let addedLater = ARAnchor(name: "later", transform: .identity)
    session.add(anchor: addedLater)
    require(session.currentFrame!.anchors.contains { $0.name == "later" }, "user anchor in frame")
    require(addedLater.identifier != userAnchor.identifier, "distinct anchors")
    session.remove(anchor: addedLater)
    require(!session.currentFrame!.anchors.contains { $0.name == "later" }, "removed from frame")
    require(probe.removed.contains { $0.contains { $0.name == "later" } }, "didRemove")

    session.setWorldOrigin(relativeTransform: simd_float4x4.translation(simd_float3(1, 0, 0)))
    require(session.currentFrame != nil, "frame after origin")

    do {
        _ = try NSKeyedArchiver.archivedData(withRootObject: userAnchor, requiringSecureCoding: true)
        let data = try NSKeyedArchiver.archivedData(withRootObject: ARAnchor(transform: .identity), requiringSecureCoding: true)
        let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data)
        require(decoded != nil, "anchor round trip")
        require(decoded!.transform == simd_float4x4.identity, "decoded transform")
    } catch {
        fatalError("NSSecureCoding failed: \(error)")
    }

    do {
        _ = try await session.currentWorldMap()
        fatalError("world map must fail closed while simulated")
    } catch {
        require((error as? ARError)?.code == .invalidWorldMap, "invalidWorldMap while running")
    }
    do {
        _ = try await session.captureHighResolutionFrame(using: nil)
        fatalError("hi-res must fail")
    } catch {
        requireUnsupported(error)
    }
    do {
        _ = try await session.geoLocation(forPoint: simd_float3(repeating: 0))
        fatalError("geo location must fail")
    } catch {
        require((error as? ARError)?.code == .geoTrackingNotAvailableAtLocation, "geo fail")
    }

    session.pause()
    require(session.currentFrame != nil, "pause keeps last frame")
    require(session.trackedRaycast(queryDown, updateHandler: { _ in }) == nil, "tracked nil when paused")

    let cgImage = CGImage(width: 100, height: 50)
    let refImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: 0.2)
    require(abs(refImage.physicalSize.width - 0.2) < 0.0001, "physical width")
    require(abs(refImage.physicalSize.height - 0.1) < 0.0001, "physical height from aspect")
    _ = ARReferenceImage(CGImage: cgImage, orientation: .up, physicalWidth: 0.2)
    _ = ARReferenceImage(CVPixelBuffer(width: 10, height: 5), orientation: .right, physicalWidth: 0.1)
    _ = ARReferenceImage(pixelBuffer: CVPixelBuffer(width: 10, height: 5), orientation: .left, physicalWidth: 0.1)
    refImage.name = "marker"
    require(refImage.name == "marker", "image name")
    _ = refImage.resourceGroupName
    _ = refImage.hash
    require(!refImage.isEqual(ARReferenceImage(physicalSize: .zero)), "image identity")

    let object = ARReferenceObject()
    object.name = "scan"
    require(object.name == "scan", "object name")
    _ = object.center
    _ = object.extent
    _ = object.scale
    _ = object.rawFeaturePoints
    _ = object.resourceGroupName
    _ = object.applyingTransform(.identity)
    do {
        try object.export(to: URL(fileURLWithPath: "/tmp/out.arobject"), previewImage: nil)
        fatalError("export fail closed")
    } catch {
        require((error as? ARError)?.code == .fileIOFailed, "export file IO")
    }

    let scn = ARSCNView()
    scn.session = session
    scn.automaticallyUpdatesLighting = false
    scn.rendersCameraGrain = true
    scn.rendersMotionBlur = true
    _ = scn.scene
    _ = scn.delegate
    require(scn.anchor(for: SCNNode()) == nil, "no scene node map")
    require(scn.node(for: userAnchor) == nil, "no node")
    _ = scn.hitTest(.zero, types: .featurePoint)
    _ = scn.raycastQuery(from: CGPoint(x: 0.5, y: 0.5), allowing: .estimatedPlane, alignment: .horizontal)
    _ = scn.unprojectPoint(.zero, ontoPlane: .identity)
    require(SCNDebugOptions.showWorldOrigin.rawValue == 1, "world origin bit")
    require(SCNDebugOptions.showFeaturePoints.rawValue == 2, "feature points bit")
    require(ARSCNFaceGeometry(device: ARKitHostMTLDevice()) == nil, "no metal face geo")
    require(ARSCNFaceGeometry(device: ARKitHostMTLDevice(), fillMesh: true) == nil, "no fill mesh")
    ARSCNFaceGeometry().update(from: ARFaceGeometry())
    require(ARSCNPlaneGeometry(device: ARKitHostMTLDevice()) == nil, "no metal plane geo")
    ARSCNPlaneGeometry().update(from: ARPlaneGeometry())

    let sk = ARSKView()
    sk.session = session
    require(sk.anchor(for: SKNode()) == nil, "no sprite node")
    require(sk.node(for: userAnchor) == nil, "no sprite for anchor")
    _ = sk.hitTest(.zero, types: .existingPlane)
    _ = sk.delegate

    let geoAnchor = ARGeoAnchor(coordinate: CLLocationCoordinate2D(latitude: 37.3, longitude: -122.0), altitude: 10)
    require(geoAnchor.coordinate.latitude == 37.3, "geo lat")
    require(geoAnchor.altitude == 10, "geo alt")
    _ = ARGeoAnchor(name: "place", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    _ = geoAnchor.altitudeSource
    ARGeoTrackingConfiguration.checkAvailability(at: CLLocationCoordinate2D(latitude: 0, longitude: 0)) { available, error in
        require(!available, "coord availability")
        require((error as? ARError)?.code == .geoTrackingNotAvailableAtLocation, "coord error")
    }

    let depth = ARDepthData()
    _ = depth.confidenceMap
    _ = depth.depthMap
    let probeAnchor = AREnvironmentProbeAnchor(transform: .identity, extent: simd_float3(1, 1, 1))
    require(probeAnchor.environmentTexture == nil, "no metal env texture")
    let mesh = ARMeshAnchor(anchor: ARAnchor(transform: .identity))
    _ = mesh.geometry.vertices
    _ = mesh.geometry.normals
    _ = mesh.geometry.faces
    _ = mesh.geometry.classification
    _ = mesh.geometry.vertices.buffer
    _ = mesh.geometry.vertices.format
    _ = mesh.geometry.vertices.componentsPerVector
    _ = mesh.geometry.vertices.count
    _ = mesh.geometry.vertices.offset
    _ = mesh.geometry.vertices.stride
    _ = mesh.geometry.vertices[Int32(0)]
    _ = mesh.geometry.faces.buffer
    _ = mesh.geometry.faces.bytesPerIndex
    _ = mesh.geometry.faces.count
    _ = mesh.geometry.faces.indexCountPerPrimitive
    _ = mesh.geometry.faces.primitiveType
    _ = mesh.geometry.faces[0]
    let matte = ARMatteGenerator(device: ARKitHostMTLDevice(), matteResolution: .full)
    _ = matte.generateMatte(from: session.currentFrame ?? ARFrame(), commandBuffer: ARKitHostMTLCommandBuffer())
    _ = matte.generateDilatedDepth(from: session.currentFrame ?? ARFrame(), commandBuffer: ARKitHostMTLCommandBuffer())

    require(ARSkeleton.JointName(VNRecognizedPointKey(rawValue: "head")) == nil, "vision joint map fail closed")
    require(ARSkeleton.JointName.root != .head, "joint inequality")
    require(ARFaceAnchor.BlendShapeLocation.jawOpen != .jawLeft, "blend inequality")
    var planes: ARWorldTrackingConfiguration.PlaneDetection = [.horizontal]
    require(planes.isSubset(of: [.horizontal, .vertical]), "subset")
    require(planes.isStrictSubset(of: [.horizontal, .vertical]), "strict subset")
    require(planes.union(.vertical).contains(.vertical), "union")
    require(planes.intersection(.horizontal) == .horizontal, "intersection")
    _ = planes.symmetricDifference(.vertical)
    planes.formUnion(.vertical)
    planes.formIntersection(.horizontal)
    planes.formSymmetricDifference(.vertical)
    require(!planes.isStrictSuperset(of: [.horizontal, .vertical]), "strict superset")
    var hits: ARHitTestResult.ResultType = [.featurePoint]
    _ = hits.isSubset(of: [.featurePoint, .existingPlane])
    _ = hits.isStrictSubset(of: [.featurePoint, .existingPlane])
    _ = hits.union(.existingPlane)
    _ = hits.symmetricDifference(.existingPlane)
    hits.formUnion(.existingPlane)
    hits.formSymmetricDifference(.featurePoint)
    var options: ARSession.RunOptions = [.resetTracking]
    _ = options.isSubset(of: [.resetTracking, .removeExistingAnchors])
    _ = options.isStrictSubset(of: [.resetTracking, .removeExistingAnchors])
    _ = options.union(.removeExistingAnchors)
    _ = options.symmetricDifference(.stopTrackedRaycasts)
    options.formUnion(.removeExistingAnchors)
    options.formSymmetricDifference(.resetSceneReconstruction)
    var semantics: ARConfiguration.FrameSemantics = [.personSegmentation]
    _ = semantics.isSubset(of: [.personSegmentation, .sceneDepth])
    _ = semantics.isStrictSubset(of: [.personSegmentation, .sceneDepth])
    _ = semantics.union(.bodyDetection)
    _ = semantics.symmetricDifference(.sceneDepth)
    semantics.formUnion(.smoothedSceneDepth)
    semantics.formSymmetricDifference(.personSegmentationWithDepth)
    var reconstruction: ARConfiguration.SceneReconstruction = [.mesh]
    _ = reconstruction.isSubset(of: [.mesh, .meshWithClassification])
    _ = reconstruction.isStrictSubset(of: [.mesh, .meshWithClassification])
    _ = reconstruction.union(.meshWithClassification)
    _ = reconstruction.symmetricDifference(.mesh)
    reconstruction.formUnion(.meshWithClassification)
    reconstruction.formSymmetricDifference(.mesh)
    require(ARConfidenceLevel.high > .low, "confidence >")
    require(ARConfidenceLevel.high >= .medium, "confidence >=")
    require(ARConfidenceLevel.low <= .medium, "confidence <=")
    _ = ARConfidenceLevel.low..<ARConfidenceLevel.high
    _ = ARConfidenceLevel.low...
    _ = ...ARConfidenceLevel.high
    _ = ARConfidenceLevel.low...ARConfidenceLevel.medium
    _ = ..<ARConfidenceLevel.high
    require(ARError.unsupportedConfiguration != ARError.sensorFailed, "error code inequality")
    require(ARConfiguration.WorldAlignment.gravity != .camera, "alignment inequality")
    require(ARFrame.WorldMappingStatus.limited != .mapped, "mapping inequality")
    require(ARGeoTrackingStatus.State.localizing != .localized, "geo state inequality")
    session.update(with: ARSession.CollaborationData(priority: .optional))
    _ = session.delegateQueue
    let collab = ARSession.CollaborationData(priority: .critical)
    _ = collab.priority
    let body2d = ARBody2D()
    _ = body2d.skeleton
    _ = ARBodyAnchor(anchor: ARAnchor(transform: simd_float4x4.identity)).skeleton
    _ = ARImageAnchor(anchor: ARAnchor(transform: simd_float4x4.identity)).referenceImage
    _ = ARObjectAnchor(anchor: ARAnchor(transform: simd_float4x4.identity)).referenceObject
    _ = ARFaceAnchor(anchor: ARAnchor(transform: simd_float4x4.identity)).blendShapes
    _ = ARAppClipCodeAnchor(anchor: ARAnchor(transform: simd_float4x4.identity)).urlDecodingState
    _ = ARParticipantAnchor(anchor: ARAnchor(transform: simd_float4x4.identity))
    let directional = ARDirectionalLightEstimate()
    _ = directional.primaryLightDirection
    _ = directional.primaryLightIntensity
    _ = directional.sphericalHarmonicsCoefficients
    _ = ARWorldMap().center
    _ = ARWorldMap().extent
    _ = ARWorldMap().rawFeaturePoints
    _ = ARWorldMap().anchors
    let overlay = ARCoachingOverlayView()
    overlay.activatesAutomatically = false
    overlay.sessionProvider = scn
    _ = overlay.delegate
    require(ARGeoTrackingStatus.Accuracy.low != .high, "accuracy inequality")
    require(ARGeoTrackingStatus.StateReason.none != .geoDataNotLoaded, "reason inequality")
    require(ARMeshClassification.wall != .door, "mesh class inequality")
    require(ARGeometryPrimitiveType.line != .triangle, "primitive inequality")
    require(ARCoachingOverlayView.Goal.tracking != .geoTracking, "goal inequality")
    require(ARSession.CollaborationData.Priority.critical != .optional, "priority inequality")
    require(ARAppClipCodeAnchor.URLDecodingState.decoding != .decoded, "url state inequality")
    require(ARMatteGenerator.Resolution.full != .half, "matte inequality")
    require(ARRaycastQuery.Target.existingPlaneInfinite != .estimatedPlane, "target inequality")
    require(ARRaycastQuery.TargetAlignment.any != .vertical, "alignment inequality")
    require(ARWorldTrackingConfiguration.EnvironmentTexturing.none != .automatic, "texturing inequality")
    require(ARFrame.SegmentationClass.none != .person, "seg inequality")
    require(ARGeoAnchor.AltitudeSource.coarse != .precise, "altitude inequality")
    require(ARPlaneAnchor.Alignment.horizontal != .vertical, "plane align inequality")
    _ = ARConfidenceLevel.medium.hashValue
    var hasher = Hasher()
    ARError.Code.fileIOFailed.hash(into: &hasher)
    ARSkeleton.JointName.head.hash(into: &hasher)
    _ = hasher.finalize()
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
        require({
            let d = frameQuery.direction
            return (d.x * d.x + d.y * d.y + d.z * d.z) > 0.8
        }(), "fallback ray is unit length")

        let classification = ARPlaneAnchor.Classification.none(.notAvailable)
        require(classification == .none(.notAvailable), "plane classification none")
        require(ARPlaneAnchor.Classification.Status.undetermined != .unknown, "status distinct")
        require(ARCamera.TrackingState.limited(.initializing) != .normal, "tracking state")
        require(
            ARCamera.TrackingState.limited(.insufficientFeatures)
                == .limited(.insufficientFeatures),
            "limited reason"
        )

        await runDepthPassExercises()

        print("ARKIT_AGENT_RUNTIME_OK")
}

let _arkitRuntimeLock = DispatchSemaphore(value: 0)
Task {
    await runARKitRuntime()
    _arkitRuntimeLock.signal()
}
_arkitRuntimeLock.wait()
