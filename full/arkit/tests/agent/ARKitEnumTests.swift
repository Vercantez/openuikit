import Foundation
import ARKit

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
