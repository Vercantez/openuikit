import Foundation
import OpenCoreGraphics

public class CIFilter: NSObject, @unchecked Sendable {
    public var name: String
    var inputs: [String: Any] = [:]

    public var outputImage: CIImage? { produceOutput() }

    public override init() {
        self.name = "CIFilter"
        super.init()
    }

    public init?(name: String) {
        guard CIFilter.known.contains(name) else { return nil }
        self.name = name
        super.init()
        if name == "CIGaussianBlur" {
            inputs[kCIInputRadiusKey] = Float(10)
        }
    }

    public convenience init?(name: String, parameters params: [String: Any]?) {
        self.init(name: name)
        if let params {
            inputs.merge(params) { _, new in new }
        }
    }

    // Darwin NSObject has KVC; swift-corelibs NSObject does not
    // (same gap as UIVisualEffect, measured 2026-09-04 in Docker;
    // uikit-linux 6.2.4 `swift build --build-tests` after merging
    // linux-xctest onto main's CoreImage: override does not match).
#if canImport(ObjectiveC)
    public override func setValue(_ value: Any?, forKey key: String) {
        applyValue(value, forKey: key)
    }

    public override func value(forKey key: String) -> Any? {
        lookupValue(forKey: key)
    }
#else
    public func setValue(_ value: Any?, forKey key: String) {
        applyValue(value, forKey: key)
    }

    public func value(forKey key: String) -> Any? {
        lookupValue(forKey: key)
    }
#endif

    private func applyValue(_ value: Any?, forKey key: String) {
        if let value {
            inputs[key] = value
        } else {
            inputs.removeValue(forKey: key)
        }
    }

    private func lookupValue(forKey key: String) -> Any? {
        if key == kCIOutputImageKey { return outputImage }
        return inputs[key]
    }

    public func setDefaults() {
        inputs.removeAll()
        if name == "CIGaussianBlur" {
            inputs[kCIInputRadiusKey] = Float(10)
        }
    }

    public class func filterNames(inCategory category: String?) -> [String] {
        _ = category
        return Array(known)
    }

    public static func gaussianBlur() -> CIGaussianBlurFilter {
        CIGaussianBlurFilter()
    }

    public static func qrCodeGenerator() -> CIQRCodeGeneratorFilter {
        CIQRCodeGeneratorFilter()
    }

    public static func constantColorGenerator() -> CIFilter {
        CIFilter(name: "CIConstantColorGenerator")!
    }

    private static let known: Set<String> = [
        "CIGaussianBlur",
        "CIQRCodeGenerator",
        "CIConstantColorGenerator",
    ]

    fileprivate func produceOutput() -> CIImage? {
        switch name {
        case "CIGaussianBlur":
            guard let input = inputs[kCIInputImageKey] as? CIImage else { return nil }
            let radius = ciRadius(inputs[kCIInputRadiusKey])
            return CIImage(node: .blurred(input, radius: radius))
        case "CIConstantColorGenerator":
            let color = (inputs[kCIInputColorKey] as? CIColor) ?? .white
            return CIImage(color: color)
        default:
            return nil
        }
    }
}

public final class CIGaussianBlurFilter: CIFilter, @unchecked Sendable {
    public var inputImage: CIImage? {
        get { inputs[kCIInputImageKey] as? CIImage }
        set { setValue(newValue, forKey: kCIInputImageKey) }
    }

    public var radius: Float {
        get { (inputs[kCIInputRadiusKey] as? Float) ?? 10 }
        set { setValue(newValue, forKey: kCIInputRadiusKey) }
    }

    public override init() {
        super.init()
        name = "CIGaussianBlur"
        inputs[kCIInputRadiusKey] = Float(10)
    }
}

public final class CIQRCodeGeneratorFilter: CIFilter, @unchecked Sendable {
    public var message: Data {
        get { (inputs["inputMessage"] as? Data) ?? Data() }
        set { setValue(newValue, forKey: "inputMessage") }
    }

    public var correctionLevel: String {
        get { (inputs["inputCorrectionLevel"] as? String) ?? "M" }
        set { setValue(newValue, forKey: "inputCorrectionLevel") }
    }

    public override init() {
        super.init()
        name = "CIQRCodeGenerator"
        inputs["inputCorrectionLevel"] = "M"
    }
}

func ciRadius(_ value: Any?) -> CGFloat {
    if let value = value as? Float { return CGFloat(value) }
    if let value = value as? Double { return CGFloat(value) }
    if let value = value as? CGFloat { return value }
    if let value = value as? Int { return CGFloat(value) }
    // Linux 6.2.4 CGFloat has no NSNumber truncating: (Darwin Foundation).
    // MEASURED uikit-linux swift build --build-tests after merging
    // linux-xctest onto main's CoreImage: same initializer miss as ImageIO.
    if let value = value as? NSNumber { return CGFloat(value.doubleValue) }
    return 10
}
