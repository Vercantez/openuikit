import Foundation
import ARKit

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
