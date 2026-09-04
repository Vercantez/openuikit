import Foundation

open class ARReferenceImage: NSObject {
    public var name: String?
    public var physicalSize: CGSize { _physicalSize }
    public var resourceGroupName: String? { _resourceGroupName }

    private let _physicalSize: CGSize
    private let _resourceGroupName: String?
    private let identity = UUID()

    public init(physicalSize: CGSize, resourceGroupName: String? = nil) {
        self._physicalSize = physicalSize
        self._resourceGroupName = resourceGroupName
        super.init()
    }

    public class func referenceImages(inGroupNamed name: String, bundle: Bundle?) -> Set<ARReferenceImage>? {
        _ = (name, bundle)
        return nil
    }

    public func validate(completionHandler: @escaping ((any Error)?) -> Void) {
        completionHandler(ARError(.invalidReferenceImage))
    }

    public override var hash: Int { identity.hashValue }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ARReferenceImage else { return false }
        return identity == other.identity
    }
}

open class ARReferenceObject: NSObject, NSSecureCoding {
    public static let archiveExtension = "arobject"

    public var name: String?
    public var center: simd_float3 { simd_float3(repeating: 0) }
    public var extent: simd_float3 { simd_float3(repeating: 0) }
    public var scale: simd_float3 { simd_float3(1, 1, 1) }
    public var rawFeaturePoints: ARPointCloud { _rawFeaturePoints }
    public var resourceGroupName: String? { _resourceGroupName }

    private let _rawFeaturePoints = ARPointCloud()
    private let _resourceGroupName: String?
    private let identity = UUID()

    public static var supportsSecureCoding: Bool { true }

    public override init() {
        self._resourceGroupName = nil
        super.init()
    }

    public init(archiveURL url: URL) throws {
        _ = url
        throw ARError(.fileIOFailed)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }

    public class func referenceObjects(inGroupNamed name: String, bundle: Bundle?) -> Set<ARReferenceObject>? {
        _ = (name, bundle)
        return nil
    }

    public func applyingTransform(_ transform: simd_float4x4) -> ARReferenceObject {
        _ = transform
        return self
    }

    public func merging(_ object: ARReferenceObject) throws -> ARReferenceObject {
        _ = object
        throw ARError(.objectMergeFailed)
    }

    public override var hash: Int { identity.hashValue }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ARReferenceObject else { return false }
        return identity == other.identity
    }
}

open class ARWorldMap: NSObject, NSSecureCoding {
    public var anchors: [ARAnchor]
    public var center: simd_float3 { simd_float3(repeating: 0) }
    public var extent: simd_float3 { simd_float3(repeating: 0) }
    public var rawFeaturePoints: ARPointCloud { _rawFeaturePoints }

    private let _rawFeaturePoints = ARPointCloud()

    public static var supportsSecureCoding: Bool { true }

    public override init() {
        self.anchors = []
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }
}
