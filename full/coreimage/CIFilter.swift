import Foundation

public protocol CIFilterConstructor {
    func filter(withName name: String) -> CIFilter?
}

public protocol CIFilterProtocol {
    var outputImage: CIImage? { get }
    static func customAttributes() -> [String: Any]?
}

extension CIFilterProtocol {
    public static func customAttributes() -> [String: Any]? { nil }
}

public class CIFilter: NSObject, NSSecureCoding, CIFilterProtocol, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public var name: String
    public private(set) var attributes: [String: Any]
    var inputs: [String: Any] = [:]

    public var inputKeys: [String] {
        (attributes["inputKeys"] as? [String]) ?? Array(inputs.keys).sorted()
    }

    public var outputKeys: [String] {
        (attributes["outputKeys"] as? [String]) ?? [kCIOutputImageKey]
    }

    public var outputImage: CIImage? {
        ciApplyNamedFilter(name, inputs: inputs)
    }

    public override init() {
        self.name = "CIFilter"
        self.attributes = [
            kCIAttributeFilterName: "CIFilter",
            kCIAttributeFilterDisplayName: "Filter",
            "inputKeys": [kCIInputImageKey],
            "outputKeys": [kCIOutputImageKey],
        ]
        super.init()
    }

    public init(name: String, attributes: [String: Any] = [:]) {
        self.name = name
        var merged = attributes
        merged[kCIAttributeFilterName] = name
        self.attributes = merged
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public func setDefaults() {
        inputs.removeAll()
        CIFilterRegistry.shared.applyDefaults(name, to: self)
    }

#if os(Linux)
    public func setValue(_ value: Any?, forKey key: String) {
        if key == kCIOutputImageKey { return }
        if let value {
            inputs[key] = value
        } else {
            inputs.removeValue(forKey: key)
        }
    }

    public func value(forKey key: String) -> Any? {
        if key == kCIOutputImageKey { return outputImage }
        if key == "inputKeys" { return inputKeys }
        if key == "outputKeys" { return outputKeys }
        if key == "attributes" { return attributes }
        return inputs[key]
    }
#else
    public override func setValue(_ value: Any?, forKey key: String) {
        if key == kCIOutputImageKey { return }
        if let value {
            inputs[key] = value
        } else {
            inputs.removeValue(forKey: key)
        }
    }

    public override func value(forKey key: String) -> Any? {
        if key == kCIOutputImageKey { return outputImage }
        if key == "inputKeys" { return inputKeys }
        if key == "outputKeys" { return outputKeys }
        if key == "attributes" { return attributes }
        return inputs[key]
    }
#endif

    func setInputImage(_ image: CIImage) {
        inputs[kCIInputImageKey] = image
    }

    public class func filterNames(inCategory category: String?) -> [String] {
        filterNames(inCategories: category.map { [$0] })
    }

    public class func filterNames(inCategories categories: [String]?) -> [String] {
        let registered = CIFilterRegistry.shared.names
        guard let categories, !categories.isEmpty else { return registered }
        return registered.filter { name in
            let attrs = CIFilterRegistry.shared.attributes(for: name)
            let cats = attrs[kCIAttributeFilterCategories] as? [String] ?? []
            return categories.contains(where: { cats.contains($0) })
        }
    }

    public convenience init?(name: String) {
        guard CIFilterRegistry.shared.names.contains(name) else { return nil }
        self.init(name: name, attributes: CIFilterRegistry.shared.attributes(for: name))
        CIFilterRegistry.shared.applyDefaults(name, to: self)
    }

    public convenience init?(name: String, withInputParameters params: [String: Any]?) {
        self.init(name: name)
        if let params {
            inputs.merge(params) { _, new in new }
        }
    }

    public convenience init?(imageData data: Data, options: [CIRAWFilterOption: Any]? = [:]) {
        _ = (data, options)
        return nil
    }

    public convenience init?(imageURL url: URL, options: [CIRAWFilterOption: Any]? = [:]) {
        _ = (url, options)
        return nil
    }

    public class func localizedName(forFilterName filterName: String) -> String? {
        CIFilterRegistry.shared.attributes(for: filterName)[kCIAttributeFilterDisplayName] as? String
            ?? filterName
    }

    public class func localizedName(forCategory category: String) -> String {
        category
    }

    public class func localizedDescription(forFilterName filterName: String) -> String? {
        CIFilterRegistry.shared.attributes(for: filterName)[kCIAttributeDescription] as? String
    }

    public class func localizedReferenceDocumentation(forFilterName filterName: String) -> URL? {
        _ = filterName
        return nil
    }

    public class func registerName(
        _ name: String,
        constructor anObject: any CIFilterConstructor,
        classAttributes attributes: [String: Any] = [:]
    ) {
        CIFilterRegistry.shared.register(name: name, constructor: anObject, attributes: attributes)
    }

    public class func serializedXMP(from filters: [CIFilter], inputImageExtent extent: CGRect) -> Data? {
        _ = (filters, extent)
        return nil
    }

    public class func filterArray(
        fromSerializedXMP xmpData: Data,
        inputImageExtent extent: CGRect,
        error outError: NSErrorPointer
    ) -> [CIFilter] {
        _ = (xmpData, extent)
        outError?.pointee = NSError(domain: "CIFilter", code: 1)
        return []
    }

    public class func supportedRawCameraModels() -> [String]! {
        []
    }

    public static func linearGradient() -> CILinearGradient {
        CILinearGradient()
    }

    public static func smoothLinearGradient() -> CILinearGradient {
        CILinearGradient()
    }
}

/// Generated `CILinearGradient` filter surface. Kept from the original
/// CoreImage slice and wired through `CIFilter` so `createCGImage` still
/// rasterizes a deterministic CPU linear gradient.
public final class CILinearGradient: CIFilter, @unchecked Sendable {
    public var color0: CIColor = .black
    public var color1: CIColor = .clear
    public var point0: CGPoint = .zero
    public var point1 = CGPoint(x: 0, y: 1)

    public override init() {
        super.init(
            name: "CILinearGradient",
            attributes: [
                kCIAttributeFilterDisplayName: "Linear Gradient",
                kCIAttributeFilterCategories: [kCICategoryGradient, kCICategoryGenerator, kCICategoryStillImage],
                kCIAttributeFilterName: "CILinearGradient",
                "inputKeys": [kCIInputColor0Key, kCIInputColor1Key, kCIInputPoint0Key, kCIInputPoint1Key],
                "outputKeys": [kCIOutputImageKey],
            ]
        )
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public override var outputImage: CIImage? {
        CIImage(
            node: .gradient(
                color0: color0,
                color1: color1,
                point0: point0,
                point1: point1,
                extent: .infinite
            )
        )
    }

    func applyParameters(_ params: [String: Any]) {
        if let color = params[kCIInputColor0Key] as? CIColor { color0 = color }
        if let color = params[kCIInputColor1Key] as? CIColor { color1 = color }
        if let point = params[kCIInputPoint0Key] as? CIVector { point0 = point.cgPointValue }
        if let point = params[kCIInputPoint1Key] as? CIVector { point1 = point.cgPointValue }
        if let point = params[kCIInputPoint0Key] as? CGPoint { point0 = point }
        if let point = params[kCIInputPoint1Key] as? CGPoint { point1 = point }
    }
}

final class CIFilterRegistry {
    static let shared = CIFilterRegistry()

    private var constructors: [String: any CIFilterConstructor] = [:]
    private var attrs: [String: [String: Any]] = [:]

    private init() {
        attrs["CILinearGradient"] = [
            kCIAttributeFilterName: "CILinearGradient",
            kCIAttributeFilterDisplayName: "Linear Gradient",
            kCIAttributeFilterCategories: [kCICategoryGradient, kCICategoryGenerator, kCICategoryStillImage],
            "inputKeys": [kCIInputColor0Key, kCIInputColor1Key, kCIInputPoint0Key, kCIInputPoint1Key],
            "outputKeys": [kCIOutputImageKey],
        ]
        attrs["CISmoothLinearGradient"] = [
            kCIAttributeFilterName: "CISmoothLinearGradient",
            kCIAttributeFilterDisplayName: "Smooth Linear Gradient",
            kCIAttributeFilterCategories: [kCICategoryGradient, kCICategoryGenerator, kCICategoryStillImage],
            "inputKeys": [kCIInputColor0Key, kCIInputColor1Key, kCIInputPoint0Key, kCIInputPoint1Key],
            "outputKeys": [kCIOutputImageKey],
        ]
        attrs["CIConstantColorGenerator"] = [
            kCIAttributeFilterName: "CIConstantColorGenerator",
            kCIAttributeFilterDisplayName: "Constant Color",
            kCIAttributeFilterCategories: [kCICategoryGenerator, kCICategoryStillImage],
            "inputKeys": [kCIInputColorKey],
            "outputKeys": [kCIOutputImageKey],
        ]
        ciInstallBuiltinFilters(self)
    }

    var names: [String] { attrs.keys.sorted() }

    func attributes(for name: String) -> [String: Any] {
        attrs[name] ?? [:]
    }

    func register(name: String, constructor: any CIFilterConstructor, attributes: [String: Any]) {
        constructors[name] = constructor
        var merged = attributes
        merged[kCIAttributeFilterName] = name
        attrs[name] = merged
    }

    func registerBuiltin(name: String, display: String, categories: [String], inputKeys: [String]) {
        attrs[name] = [
            kCIAttributeFilterName: name,
            kCIAttributeFilterDisplayName: display,
            kCIAttributeFilterCategories: categories,
            "inputKeys": inputKeys,
            "outputKeys": [kCIOutputImageKey],
        ]
    }

    func applyDefaults(_ name: String, to filter: CIFilter) {
        switch name {
        case "CILinearGradient", "CISmoothLinearGradient":
            filter.inputs[kCIInputColor0Key] = CIColor.black
            filter.inputs[kCIInputColor1Key] = CIColor.clear
            filter.inputs[kCIInputPoint0Key] = CIVector(x: 0, y: 0)
            filter.inputs[kCIInputPoint1Key] = CIVector(x: 0, y: 1)
        case "CIConstantColorGenerator":
            filter.inputs[kCIInputColorKey] = CIColor.white
        case "CIGaussianBlur":
            filter.inputs[kCIInputRadiusKey] = Float(10)
        case "CIColorControls":
            filter.inputs[kCIInputSaturationKey] = Float(1)
            filter.inputs[kCIInputBrightnessKey] = Float(0)
            filter.inputs[kCIInputContrastKey] = Float(1)
        case "CISepiaTone":
            filter.inputs[kCIInputIntensityKey] = Float(1)
        case "CIColorMatrix":
            filter.inputs["inputRVector"] = CIVector(x: 1, y: 0, z: 0, w: 0)
            filter.inputs["inputGVector"] = CIVector(x: 0, y: 1, z: 0, w: 0)
            filter.inputs["inputBVector"] = CIVector(x: 0, y: 0, z: 1, w: 0)
            filter.inputs["inputAVector"] = CIVector(x: 0, y: 0, z: 0, w: 1)
            filter.inputs["inputBiasVector"] = CIVector(x: 0, y: 0, z: 0, w: 0)
        case "CIExposureAdjust":
            filter.inputs[kCIInputEVKey] = Float(0)
        case "CIVibrance":
            filter.inputs[kCIInputAmountKey] = Float(0)
        case "CIHueAdjust":
            filter.inputs[kCIInputAngleKey] = Float(0)
        case "CIAffineTransform":
            filter.inputs[kCIInputTransformKey] = CIVector(cgAffineTransform: .identity)
        case "CIQRCodeGenerator":
            filter.inputs["inputCorrectionLevel"] = "M"
        case "CICode128BarcodeGenerator":
            filter.inputs["inputQuietSpace"] = Float(10)
            filter.inputs["inputBarcodeHeight"] = Float(32)
        default:
            break
        }
    }

    func make(name: String) -> CIFilter? {
        if name == "CILinearGradient" || name == "CISmoothLinearGradient" {
            let filter = CILinearGradient()
            filter.name = name
            return filter
        }
        if name == "CIConstantColorGenerator" {
            return CIConstantColorGenerator()
        }
        return constructors[name]?.filter(withName: name)
    }
}

final class CIConstantColorGenerator: CIFilter, @unchecked Sendable {
    var color: CIColor = .white

    override init() {
        super.init(
            name: "CIConstantColorGenerator",
            attributes: [
                kCIAttributeFilterDisplayName: "Constant Color",
                kCIAttributeFilterCategories: [kCICategoryGenerator],
                "inputKeys": [kCIInputColorKey],
                "outputKeys": [kCIOutputImageKey],
            ]
        )
    }

    required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    override var outputImage: CIImage? {
        CIImage(color: color)
    }
}

extension CIFilter {
    /// Factory used by `init?(name:)` after the convenience path.
    static func makeRegistered(name: String) -> CIFilter? {
        CIFilterRegistry.shared.make(name: name)
    }
}

func ciPoint(_ value: Any?, fallback: CGPoint) -> CGPoint {
    if let vector = value as? CIVector { return vector.cgPointValue }
    if let point = value as? CGPoint { return point }
    return fallback
}

