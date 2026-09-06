import CoreImage
import Foundation

func testCIFilterXMPRoundTrip() {
    guard let exposure = CIFilter(name: "CIExposureAdjust") else {
        preconditionFailure("CIExposureAdjust")
    }
    exposure.setValue(Float(1.5), forKey: kCIInputEVKey)
    let extent = CGRect(x: 0, y: 0, width: 8, height: 8)
    guard let data = CIFilter.serializedXMP(from: [exposure], inputImageExtent: extent) else {
        preconditionFailure("serializedXMP")
    }
    let xml = String(data: data, encoding: .utf8) ?? ""
    precondition(xml.contains("CIExposureAdjust"))
    precondition(xml.contains("inputEV"))
    var error: NSError?
    let restored = CIFilter.filterArray(fromSerializedXMP: data, inputImageExtent: extent, error: &error)
    precondition(restored.count == 1)
    precondition(restored[0].name == "CIExposureAdjust")
    precondition((restored[0].value(forKey: kCIInputEVKey) as? Float) == 1.5)
    precondition(error == nil)

    var parseError: NSError?
    let empty = CIFilter.filterArray(
        fromSerializedXMP: Data("not-xmp".utf8),
        inputImageExtent: extent,
        error: &parseError
    )
    precondition(empty.isEmpty)
    precondition(parseError?.domain == "CIFilter")
    precondition(parseError?.code == 1)
}

func testCIFilterRAWInitializersFailClosed() {
    precondition(CIFilter(imageData: Data([0xFF, 0xD8]), options: [:]) == nil)
    precondition(CIFilter(imageURL: URL(fileURLWithPath: "/tmp/none.dng"), options: [:]) == nil)
    precondition(CIFilter(coder: NSCoder()) == nil)
}

final class CIDepthPassConstructor: CIFilterConstructor {
    func filter(withName name: String) -> CIFilter? {
        guard name == "CIDepthPassProbe" else { return nil }
        return CIFilter(
            name: "CIDepthPassProbe",
            attributes: [
                kCIAttributeFilterName: "CIDepthPassProbe",
                kCIAttributeFilterDisplayName: "Depth Pass Probe",
                "inputKeys": [kCIInputAmountKey],
                "outputKeys": [kCIOutputImageKey],
            ]
        )
    }
}

func testCIFilterConstructorAndProtocol() {
    let constructor = CIDepthPassConstructor()
    CIFilter.registerName(
        "CIDepthPassProbe",
        constructor: constructor,
        classAttributes: [
            kCIAttributeFilterDisplayName: "Depth Pass Probe",
            "inputKeys": [kCIInputAmountKey],
            "outputKeys": [kCIOutputImageKey],
        ]
    )
    precondition(CIFilter.filterNames(inCategories: nil).contains("CIDepthPassProbe"))
    precondition(constructor.filter(withName: "CIDepthPassProbe")?.name == "CIDepthPassProbe")
    precondition(constructor.filter(withName: "missing") == nil)
    precondition(CIFilter(name: "CIDepthPassProbe") != nil)
    precondition(CILinearGradient.customAttributes() == nil)
}
