import Foundation

// SDK declarations supply the configuration surface. Sampling conventions and
// gradient-state behavior are still oracle questions, so encoding stays closed.
open class MPSNNResizeBilinear: MPSCNNKernel {
    public private(set) var resizeWidth: Int = 0
    public private(set) var resizeHeight: Int = 0
    public private(set) var alignCorners: Bool = false

    public required init(device: any MTLDevice) { super.init(device: device) }

    public init(device: any MTLDevice, resizeWidth: Int, resizeHeight: Int, alignCorners: Bool) {
        precondition(resizeWidth > 0 && resizeHeight > 0, "Resize dimensions must be positive")
        self.resizeWidth = resizeWidth
        self.resizeHeight = resizeHeight
        self.alignCorners = alignCorners
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) { return nil }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = super.copy(with: zone, device: device)
        copied.resizeWidth = resizeWidth
        copied.resizeHeight = resizeHeight
        copied.alignCorners = alignCorners
        return copied
    }
}

open class MPSNNCropAndResizeBilinear: MPSCNNKernel {
    public private(set) var resizeWidth: Int = 0
    public private(set) var resizeHeight: Int = 0
    public private(set) var numberOfRegions: Int = 0
    private var regionStorage: UnsafeMutablePointer<MPSRegion>
    public var regions: UnsafePointer<MPSRegion> { UnsafePointer(regionStorage) }

    public required init(device: any MTLDevice) {
        regionStorage = .allocate(capacity: 1)
        super.init(device: device)
    }

    public init(
        device: any MTLDevice, resizeWidth: Int, resizeHeight: Int,
        numberOfRegions: Int, regions: UnsafePointer<MPSRegion>
    ) {
        precondition(resizeWidth > 0 && resizeHeight > 0 && numberOfRegions > 0,
                     "Crop dimensions and region count must be positive")
        for index in 0..<numberOfRegions {
            let region = regions[index]
            precondition(region.origin.x.isFinite && region.origin.y.isFinite && region.origin.z.isFinite
                && region.size.width.isFinite && region.size.height.isFinite && region.size.depth.isFinite
                && region.size.width > 0 && region.size.height > 0 && region.size.depth > 0,
                "Crop regions must have finite coordinates and positive sizes")
        }
        self.resizeWidth = resizeWidth
        self.resizeHeight = resizeHeight
        self.numberOfRegions = numberOfRegions
        self.regionStorage = .allocate(capacity: numberOfRegions)
        // Caller storage may expire immediately. The two-region lifetime test
        // mutates and releases the input, then checks both retained regions.
        self.regionStorage.initialize(from: regions, count: numberOfRegions)
        super.init(device: device)
    }

    public override init?(coder aDecoder: NSCoder, device: any MTLDevice) { return nil }

    deinit {
        regionStorage.deinitialize(count: numberOfRegions)
        regionStorage.deallocate()
    }

    open override func copy(with zone: NSZone? = nil, device: (any MTLDevice)?) -> Self {
        let copied = super.copy(with: zone, device: device)
        copied.regionStorage.deallocate()
        copied.regionStorage = .allocate(capacity: max(numberOfRegions, 1))
        copied.regionStorage.initialize(from: regions, count: numberOfRegions)
        copied.resizeWidth = resizeWidth
        copied.resizeHeight = resizeHeight
        copied.numberOfRegions = numberOfRegions
        return copied
    }
}
