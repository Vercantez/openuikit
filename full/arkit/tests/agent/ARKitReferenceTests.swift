import Foundation
import ARKit

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
