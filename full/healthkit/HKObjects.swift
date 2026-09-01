import Foundation

open class HKSource: NSObject, NSCopying {
    public let name: String
    public let bundleIdentifier: String

    init(name: String, bundleIdentifier: String) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        super.init()
    }

    public convenience init?(coder: NSCoder) {
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKSource(name: name, bundleIdentifier: bundleIdentifier)
    }

    open class func `default`() -> HKSource {
        let bundle = Bundle.main.bundleIdentifier ?? "org.openuikit.healthkit.linux"
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Linux"
        return HKSource(name: name, bundleIdentifier: bundle)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? HKSource else { return false }
        return bundleIdentifier == other.bundleIdentifier
    }

    public override var hash: Int { bundleIdentifier.hashValue }
}

open class HKSourceRevision: NSObject, NSCopying {
    public let source: HKSource
    public let version: String?
    public let productType: String?
    public let operatingSystemVersion: OperatingSystemVersion

    public init(source: HKSource, version: String?) {
        self.source = source
        self.version = version
        self.productType = nil
        self.operatingSystemVersion = HKSourceRevisionAnyOperatingSystem
        super.init()
    }

    public init(
        source: HKSource,
        version: String?,
        productType: String?,
        operatingSystemVersion: OperatingSystemVersion
    ) {
        self.source = source
        self.version = version
        self.productType = productType
        self.operatingSystemVersion = operatingSystemVersion
        super.init()
    }

    public convenience init?(coder: NSCoder) {
        return nil
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

open class HKDevice: NSObject, NSCopying {
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
        udiDeviceIdentifier UDIDeviceIdentifier: String?
    ) {
        self.name = name
        self.manufacturer = manufacturer
        self.model = model
        self.hardwareVersion = hardwareVersion
        self.firmwareVersion = firmwareVersion
        self.softwareVersion = softwareVersion
        self.localIdentifier = localIdentifier
        self.udiDeviceIdentifier = UDIDeviceIdentifier
        super.init()
    }

    public convenience init(
        name: String?,
        manufacturer: String?,
        model: String?,
        hardwareVersion: String?,
        firmwareVersion: String?,
        softwareVersion: String?,
        localIdentifier: String?,
        UDIDeviceIdentifier: String?
    ) {
        self.init(
            name: name,
            manufacturer: manufacturer,
            model: model,
            hardwareVersion: hardwareVersion,
            firmwareVersion: firmwareVersion,
            softwareVersion: softwareVersion,
            localIdentifier: localIdentifier,
            udiDeviceIdentifier: UDIDeviceIdentifier
        )
    }

    public convenience init?(coder: NSCoder) {
        return nil
    }

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

    open class func local() -> HKDevice {
        HKDevice(
            name: "Linux",
            manufacturer: nil,
            model: nil,
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: nil,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }
}

open class HKObject: NSObject {
    public let uuid: UUID
    public let device: HKDevice?
    public let metadata: [String: Any]?
    public let sourceRevision: HKSourceRevision

    public var source: HKSource { sourceRevision.source }

    init(
        uuid: UUID = UUID(),
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil,
        sourceRevision: HKSourceRevision = HKSourceRevision(source: .default(), version: nil)
    ) {
        self.uuid = uuid
        self.device = device
        self.metadata = metadata
        self.sourceRevision = sourceRevision
        super.init()
    }

    public convenience init?(coder: NSCoder) {
        return nil
    }
}

open class HKSample: HKObject {
    public let startDate: Date
    public let endDate: Date
    public let sampleType: HKSampleType

    public var hasUndeterminedDuration: Bool { false }

    init(
        sampleType: HKSampleType,
        start startDate: Date,
        end endDate: Date,
        device: HKDevice? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.sampleType = sampleType
        self.startDate = startDate
        self.endDate = endDate
        super.init(device: device, metadata: metadata)
    }
}

open class HKQuantitySample: HKSample {
    public let quantity: HKQuantity
    public let quantityType: HKQuantityType
    public var count: Int { 1 }

    public convenience init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        start startDate: Date,
        end endDate: Date
    ) {
        self.init(
            type: quantityType,
            quantity: quantity,
            start: startDate,
            end: endDate,
            device: nil,
            metadata: nil
        )
    }

    public convenience init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        startDate: Date,
        endDate: Date
    ) {
        self.init(
            type: quantityType,
            quantity: quantity,
            start: startDate,
            end: endDate,
            device: nil,
            metadata: nil
        )
    }

    public convenience init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        start startDate: Date,
        end endDate: Date,
        metadata: [String: Any]?
    ) {
        self.init(
            type: quantityType,
            quantity: quantity,
            start: startDate,
            end: endDate,
            device: nil,
            metadata: metadata
        )
    }

    public convenience init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        startDate: Date,
        endDate: Date,
        metadata: [String: Any]?
    ) {
        self.init(
            type: quantityType,
            quantity: quantity,
            start: startDate,
            end: endDate,
            device: nil,
            metadata: metadata
        )
    }

    public convenience init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        startDate: Date,
        endDate: Date,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(
            type: quantityType,
            quantity: quantity,
            start: startDate,
            end: endDate,
            device: device,
            metadata: metadata
        )
    }

    public init(
        type quantityType: HKQuantityType,
        quantity: HKQuantity,
        start startDate: Date,
        end endDate: Date,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.quantity = quantity
        self.quantityType = quantityType
        super.init(
            sampleType: quantityType,
            start: startDate,
            end: endDate,
            device: device,
            metadata: metadata
        )
    }
}

open class HKCategorySample: HKSample {
    public let categoryType: HKCategoryType
    public let value: Int

    public convenience init(
        type: HKCategoryType,
        value: Int,
        start startDate: Date,
        end endDate: Date
    ) {
        self.init(type: type, value: value, start: startDate, end: endDate, device: nil, metadata: nil)
    }

    public convenience init(
        type: HKCategoryType,
        value: Int,
        startDate: Date,
        endDate: Date
    ) {
        self.init(type: type, value: value, start: startDate, end: endDate, device: nil, metadata: nil)
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
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.categoryType = type
        self.value = value
        super.init(sampleType: type, start: startDate, end: endDate, device: device, metadata: metadata)
    }
}

open class HKCorrelation: HKSample {
    public let correlationType: HKCorrelationType
    public let objects: Set<HKSample>

    public convenience init(
        type correlationType: HKCorrelationType,
        start startDate: Date,
        end endDate: Date,
        objects: Set<HKSample>
    ) {
        self.init(
            type: correlationType,
            start: startDate,
            end: endDate,
            objects: objects,
            device: nil,
            metadata: nil
        )
    }

    public convenience init(
        type correlationType: HKCorrelationType,
        startDate: Date,
        endDate: Date,
        objects: Set<HKSample>
    ) {
        self.init(
            type: correlationType,
            start: startDate,
            end: endDate,
            objects: objects,
            device: nil,
            metadata: nil
        )
    }

    public convenience init(
        type correlationType: HKCorrelationType,
        start startDate: Date,
        end endDate: Date,
        objects: Set<HKSample>,
        metadata: [String: Any]?
    ) {
        self.init(
            type: correlationType,
            start: startDate,
            end: endDate,
            objects: objects,
            device: nil,
            metadata: metadata
        )
    }

    public convenience init(
        type correlationType: HKCorrelationType,
        startDate: Date,
        endDate: Date,
        objects: Set<HKSample>,
        metadata: [String: Any]?
    ) {
        self.init(
            type: correlationType,
            start: startDate,
            end: endDate,
            objects: objects,
            device: nil,
            metadata: metadata
        )
    }

    public convenience init(
        type correlationType: HKCorrelationType,
        startDate: Date,
        endDate: Date,
        objects: Set<HKSample>,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.init(
            type: correlationType,
            start: startDate,
            end: endDate,
            objects: objects,
            device: device,
            metadata: metadata
        )
    }

    public init(
        type correlationType: HKCorrelationType,
        start startDate: Date,
        end endDate: Date,
        objects: Set<HKSample>,
        device: HKDevice?,
        metadata: [String: Any]?
    ) {
        self.correlationType = correlationType
        self.objects = objects
        super.init(
            sampleType: correlationType,
            start: startDate,
            end: endDate,
            device: device,
            metadata: metadata
        )
    }

    open func objects(for objectType: HKObjectType) -> Set<HKSample> {
        Set(objects.filter { $0.sampleType.identifier == objectType.identifier })
    }
}

open class HKDeletedObject: NSObject {
    public let uuid: UUID
    public let metadata: [String: Any]?

    init(uuid: UUID, metadata: [String: Any]? = nil) {
        self.uuid = uuid
        self.metadata = metadata
        super.init()
    }

    public convenience init?(coder: NSCoder) {
        return nil
    }
}

open class HKBiologicalSexObject: NSObject {
    public let biologicalSex: HKBiologicalSex
    init(biologicalSex: HKBiologicalSex) {
        self.biologicalSex = biologicalSex
        super.init()
    }
    public convenience init?(coder: NSCoder) { nil }
}

open class HKBloodTypeObject: NSObject {
    public let bloodType: HKBloodType
    init(bloodType: HKBloodType) {
        self.bloodType = bloodType
        super.init()
    }
    public convenience init?(coder: NSCoder) { nil }
}

open class HKFitzpatrickSkinTypeObject: NSObject {
    public let skinType: HKFitzpatrickSkinType
    init(skinType: HKFitzpatrickSkinType) {
        self.skinType = skinType
        super.init()
    }
    public convenience init?(coder: NSCoder) { nil }
}

open class HKWheelchairUseObject: NSObject {
    public let wheelchairUse: HKWheelchairUse
    init(wheelchairUse: HKWheelchairUse) {
        self.wheelchairUse = wheelchairUse
        super.init()
    }
    public convenience init?(coder: NSCoder) { nil }
}

open class HKActivityMoveModeObject: NSObject {
    public let activityMoveMode: HKActivityMoveMode
    init(activityMoveMode: HKActivityMoveMode) {
        self.activityMoveMode = activityMoveMode
        super.init()
    }
    public convenience init?(coder: NSCoder) { nil }
}

open class HKQueryAnchor: NSObject, NSCopying {
    public convenience init(fromValue value: Int) {
        self.init()
    }

    public convenience init?(coder: NSCoder) { nil }

    public func copy(with zone: NSZone? = nil) -> Any {
        HKQueryAnchor()
    }
}
