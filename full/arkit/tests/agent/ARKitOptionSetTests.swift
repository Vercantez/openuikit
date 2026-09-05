import Foundation
import ARKit

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
