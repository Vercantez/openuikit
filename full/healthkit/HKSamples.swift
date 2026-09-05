import Foundation

open class HKSource: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let name: String
    public let bundleIdentifier: String

    public init(name: String, bundleIdentifier: String) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        super.init()
    }

    public class func `default`() -> HKSource {
        HKSource(name: "linux", bundleIdentifier: Bundle.main.bundleIdentifier ?? "org.openuikit.healthkit")
    }

    public required init?(coder: NSCoder) {
        self.name = (coder.decodeObject(of: NSString.self, forKey: "name") as String?) ?? ""
        self.bundleIdentifier =
            (coder.decodeObject(of: NSString.self, forKey: "bundleIdentifier") as String?) ?? ""
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(name as NSString, forKey: "name")
        coder.encode(bundleIdentifier as NSString, forKey: "bundleIdentifier")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKSource(name: name, bundleIdentifier: bundleIdentifier)
    }
}

open class HKSourceRevision: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let source: HKSource
    public let version: String?
    public let productType: String?
    public let operatingSystemVersion: OperatingSystemVersion

    public convenience init(
        source: HKSource,
        version: String?
    ) {
        self.init(source: source, version: version, productType: nil)
    }

    public init(
        source: HKSource,
        version: String?,
        productType: String? = nil,
        operatingSystemVersion: OperatingSystemVersion = OperatingSystemVersion(majorVersion: 0, minorVersion: 0, patchVersion: 0)
    ) {
        self.source = source
        self.version = version
        self.productType = productType
        self.operatingSystemVersion = operatingSystemVersion
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.source = HKSource.default()
        self.version = nil
        self.productType = nil
        self.operatingSystemVersion = OperatingSystemVersion(majorVersion: 0, minorVersion: 0, patchVersion: 0)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(version as NSString?, forKey: "version")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKSourceRevision(
            source: source,
            version: version,
            productType: productType,
            operatingSystemVersion: operatingSystemVersion
        )
    }
}

open class HKDevice: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let name: String?
    public let manufacturer: String?
    public let model: String?
    public let hardwareVersion: String?
    public let firmwareVersion: String?
    public let softwareVersion: String?
    public let localIdentifier: String?
    public let udiDeviceIdentifier: String?

    public init(
        name: String?,
        manufacturer: String?,
        model: String?,
        hardwareVersion: String?,
        firmwareVersion: String?,
        softwareVersion: String?,
        localIdentifier: String?,
        udiDeviceIdentifier: String?
    ) {
        self.name = name
        self.manufacturer = manufacturer
        self.model = model
        self.hardwareVersion = hardwareVersion
        self.firmwareVersion = firmwareVersion
        self.softwareVersion = softwareVersion
        self.localIdentifier = localIdentifier
        self.udiDeviceIdentifier = udiDeviceIdentifier
        super.init()
    }

    public class func local() -> HKDevice {
        HKDevice(
            name: "linux",
            manufacturer: nil,
            model: nil,
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: nil,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }

    public required init?(coder: NSCoder) {
        self.name = nil
        self.manufacturer = nil
        self.model = nil
        self.hardwareVersion = nil
        self.firmwareVersion = nil
        self.softwareVersion = nil
        self.localIdentifier = nil
        self.udiDeviceIdentifier = nil
        super.init()
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any {
        HKDevice(
            name: name,
            manufacturer: manufacturer,
            model: model,
            hardwareVersion: hardwareVersion,
            firmwareVersion: firmwareVersion,
            softwareVersion: softwareVersion,
            localIdentifier: localIdentifier,
            udiDeviceIdentifier: udiDeviceIdentifier
        )
    }
}

open class HKObject: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public private(set) var uuid: UUID
    public private(set) var sourceRevision: HKSourceRevision
    public let device: HKDevice?
    public let metadata: [String: Any]?

    public init(
        uuid: UUID = UUID(),
        sourceRevision: HKSourceRevision = HKSourceRevision(source: .default(), version: nil),
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.uuid = uuid
        self.sourceRevision = sourceRevision
        self.device = device
        self.metadata = metadata
        super.init()
    }

    func replaceIdentity(uuid: UUID, sourceRevision: HKSourceRevision) {
        self.uuid = uuid
        self.sourceRevision = sourceRevision
    }

    public var source: HKSource { sourceRevision.source }

    public required init?(coder: NSCoder) {
        self.uuid = UUID()
        self.sourceRevision = HKSourceRevision(source: .default(), version: nil)
        self.device = nil
        self.metadata = nil
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(uuid.uuidString as NSString, forKey: "uuid")
    }
}

open class HKSample: HKObject, @unchecked Sendable {
    public let sampleType: HKSampleType
    public let startDate: Date
    public let endDate: Date
    public var hasUndeterminedDuration: Bool { false }

    public init(
        type: HKSampleType,
        start startDate: Date,
        end endDate: Date,
        uuid: UUID = UUID(),
        sourceRevision: HKSourceRevision = HKSourceRevision(source: .default(), version: nil),
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.sampleType = type
        self.startDate = startDate
        self.endDate = endDate
        super.init(uuid: uuid, sourceRevision: sourceRevision, device: device, metadata: metadata)
    }

    public required init?(coder: NSCoder) {
        self.sampleType = HKSampleType(identifier: "")
        self.startDate = Date()
        self.endDate = Date()
        super.init(coder: coder)
    }
}

open class HKQuantitySample: HKSample, @unchecked Sendable {
    public let quantityType: HKQuantityType
    public let quantity: HKQuantity
    public var count: Int { 1 }

    public convenience init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        start startDate: Date,
        end endDate: Date
    ) {
        self.init(type: quantityType, quantity: quantity, start: startDate, end: endDate, device: nil, metadata: nil)
    }

    public convenience init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        startDate: Date,
        endDate: Date
    ) {
        self.init(type: quantityType, quantity: quantity, start: startDate, end: endDate)
    }

    public convenience init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        start startDate: Date,
        end endDate: Date,
        metadata: [String: Any]?
    ) {
        self.init(type: quantityType, quantity: quantity, start: startDate, end: endDate, device: nil, metadata: metadata)
    }

    public convenience init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        startDate: Date,
        endDate: Date,
        metadata: [String: Any]?
    ) {
        self.init(type: quantityType, quantity: quantity, start: startDate, end: endDate, metadata: metadata)
    }

    public convenience init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        startDate: Date,
        endDate: Date,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(type: quantityType, quantity: quantity, start: startDate, end: endDate, device: device, metadata: metadata)
    }

    public init(
        type: HKQuantityType,
        quantity: HKQuantity,
        start startDate: Date,
        end endDate: Date,
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.quantityType = type
        self.quantity = quantity
        super.init(
            type: type,
            start: startDate,
            end: endDate,
            device: device,
            metadata: metadata
        )
    }

    public required init?(coder: NSCoder) {
        self.quantityType = HKQuantityType(identifier: "")
        self.quantity = HKQuantity(unit: .count(), doubleValue: 0)
        super.init(coder: coder)
    }
}

open class HKCategorySample: HKSample, @unchecked Sendable {
    public let categoryType: HKCategoryType
    public let value: Int

    public convenience init(
        type: HKCategoryType,
        value: Int,
        startDate: Date,
        endDate: Date
    ) {
        self.init(type: type, value: value, start: startDate, end: endDate)
    }

    public convenience init(
        type: HKCategoryType,
        value: Int,
        startDate: Date,
        endDate: Date,
        metadata: [String: Any]?
    ) {
        self.init(type: type, value: value, start: startDate, end: endDate, metadata: metadata)
    }

    public convenience init(
        type: HKCategoryType,
        value: Int,
        start startDate: Date,
        end endDate: Date,
        metadata: [String: Any]?
    ) {
        self.init(type: type, value: value, start: startDate, end: endDate, device: nil, metadata: metadata)
    }

    public convenience init(
        type: HKCategoryType,
        value: Int,
        startDate: Date,
        endDate: Date,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(type: type, value: value, start: startDate, end: endDate, device: device, metadata: metadata)
    }

    public init(
        type: HKCategoryType,
        value: Int,
        start startDate: Date,
        end endDate: Date,
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.categoryType = type
        self.value = value
        super.init(
            type: type,
            start: startDate,
            end: endDate,
            device: device,
            metadata: metadata
        )
    }

    public required init?(coder: NSCoder) {
        self.categoryType = HKCategoryType(identifier: "")
        self.value = HKCategoryValue.notApplicable.rawValue
        super.init(coder: coder)
    }
}

open class HKCorrelation: HKSample, @unchecked Sendable {
    public let correlationType: HKCorrelationType
    public let objects: Set<HKSample>

    public convenience init(
        type correlationType: HKCorrelationType,
        startDate: Date,
        endDate: Date,
        objects: Set<HKSample>
    ) {
        self.init(type: correlationType, start: startDate, end: endDate, objects: objects)
    }

    public convenience init(
        type correlationType: HKCorrelationType,
        startDate: Date,
        endDate: Date,
        objects: Set<HKSample>,
        metadata: [String: Any]?
    ) {
        self.init(type: correlationType, start: startDate, end: endDate, objects: objects, metadata: metadata)
    }

    public convenience init(
        type correlationType: HKCorrelationType,
        start startDate: Date,
        end endDate: Date,
        objects: Set<HKSample>,
        metadata: [String: Any]?
    ) {
        self.init(type: correlationType, start: startDate, end: endDate, objects: objects, device: nil, metadata: metadata)
    }

    public convenience init(
        type correlationType: HKCorrelationType,
        startDate: Date,
        endDate: Date,
        objects: Set<HKSample>,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(type: correlationType, start: startDate, end: endDate, objects: objects, device: device, metadata: metadata)
    }

    public init(
        type: HKCorrelationType,
        start startDate: Date,
        end endDate: Date,
        objects: Set<HKSample>,
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.correlationType = type
        self.objects = objects
        super.init(
            type: type,
            start: startDate,
            end: endDate,
            device: device,
            metadata: metadata
        )
    }

    public required init?(coder: NSCoder) {
        self.correlationType = HKCorrelationType(identifier: "")
        self.objects = []
        super.init(coder: coder)
    }

    public func objects(for objectType: HKObjectType) -> Set<HKSample> {
        Set(objects.filter { $0.sampleType.identifier == objectType.identifier })
    }
}

open class HKDeletedObject: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let uuid: UUID
    public let metadata: [String: Any]?

    public init(uuid: UUID, metadata: [String: Any]? = nil) {
        self.uuid = uuid
        self.metadata = metadata
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.uuid = UUID()
        self.metadata = nil
        super.init()
    }

    public func encode(with coder: NSCoder) {}
}

open class HKSeriesSample: HKSample, @unchecked Sendable {
    public var count: Int { 0 }

    public override init(
        type: HKSampleType,
        start startDate: Date,
        end endDate: Date,
        uuid: UUID = UUID(),
        sourceRevision: HKSourceRevision = HKSourceRevision(source: .default(), version: nil),
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        super.init(
            type: type,
            start: startDate,
            end: endDate,
            uuid: uuid,
            sourceRevision: sourceRevision,
            device: device,
            metadata: metadata
        )
    }

    public required init?(coder: NSCoder) { super.init(coder: coder) }
}

open class HKCumulativeQuantitySample: HKQuantitySample, @unchecked Sendable {}
open class HKDiscreteQuantitySample: HKQuantitySample, @unchecked Sendable {}
open class HKCumulativeQuantitySeriesSample: HKCumulativeQuantitySample, @unchecked Sendable {}
open class HKDocumentSample: HKSample, @unchecked Sendable {
    public override init(
        type: HKSampleType,
        start startDate: Date,
        end endDate: Date,
        uuid: UUID = UUID(),
        sourceRevision: HKSourceRevision = HKSourceRevision(source: .default(), version: nil),
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        super.init(type: type, start: startDate, end: endDate, uuid: uuid, sourceRevision: sourceRevision, device: device, metadata: metadata)
    }

    public required init?(coder: NSCoder) { super.init(coder: coder) }
}
