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

public class CIFilter: NSObject, NSSecureCoding, @unchecked Sendable {
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
        switch name {
        case "CILinearGradient", "CISmoothLinearGradient":
            let color0 = (inputs[kCIInputColor0Key] as? CIColor) ?? .black
            let color1 = (inputs[kCIInputColor1Key] as? CIColor) ?? .clear
            let point0 = ciPoint(inputs[kCIInputPoint0Key], fallback: .zero)
            let point1 = ciPoint(inputs[kCIInputPoint1Key], fallback: CGPoint(x: 0, y: 1))
            return CIImage(
                node: .gradient(
                    color0: color0,
                    color1: color1,
                    point0: point0,
                    point1: point1,
                    extent: .infinite
                )
            )
        case "CIConstantColorGenerator":
            return CIImage(color: (inputs[kCIInputColorKey] as? CIColor) ?? .white)
        default:
            return nil
        }
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
    }

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
        if name == "CILinearGradient" || name == "CISmoothLinearGradient" {
            inputs[kCIInputColor0Key] = CIColor.black
            inputs[kCIInputColor1Key] = CIColor.clear
            inputs[kCIInputPoint0Key] = CIVector(x: 0, y: 0)
            inputs[kCIInputPoint1Key] = CIVector(x: 0, y: 1)
        }
        if name == "CIConstantColorGenerator" {
            inputs[kCIInputColorKey] = CIColor.white
        }
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
        ]
        attrs["CISmoothLinearGradient"] = [
            kCIAttributeFilterName: "CISmoothLinearGradient",
            kCIAttributeFilterDisplayName: "Smooth Linear Gradient",
            kCIAttributeFilterCategories: [kCICategoryGradient, kCICategoryGenerator, kCICategoryStillImage],
        ]
        attrs["CIConstantColorGenerator"] = [
            kCIAttributeFilterName: "CIConstantColorGenerator",
            kCIAttributeFilterDisplayName: "Constant Color",
            kCIAttributeFilterCategories: [kCICategoryGenerator, kCICategoryStillImage],
        ]
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

