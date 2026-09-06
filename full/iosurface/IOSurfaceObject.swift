import Foundation

final class IOSurfaceComponentLayout {
    var name: IOSurfaceComponentName
    var type: IOSurfaceComponentType
    var range: IOSurfaceComponentRange
    var bitDepth: Int
    var bitOffset: Int

    init(
        name: IOSurfaceComponentName,
        type: IOSurfaceComponentType,
        range: IOSurfaceComponentRange,
        bitDepth: Int,
        bitOffset: Int
    ) {
        self.name = name
        self.type = type
        self.range = range
        self.bitDepth = bitDepth
        self.bitOffset = bitOffset
    }
}

final class IOSurfacePlaneLayout {
    var width: Int
    var height: Int
    var bytesPerRow: Int
    var offset: Int
    var bytesPerElement: Int
    var elementWidth: Int
    var elementHeight: Int
    var components: [IOSurfaceComponentLayout]

    init(
        width: Int,
        height: Int,
        bytesPerRow: Int,
        offset: Int,
        bytesPerElement: Int,
        elementWidth: Int,
        elementHeight: Int,
        components: [IOSurfaceComponentLayout]
    ) {
        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow
        self.offset = offset
        self.bytesPerElement = bytesPerElement
        self.elementWidth = elementWidth
        self.elementHeight = elementHeight
        self.components = components
    }
}

final class IOSurfaceStorage: @unchecked Sendable {
    let surfaceID: IOSurfaceID
    let width: Int
    let height: Int
    let pixelFormat: OSType
    let bytesPerElement: Int
    let bytesPerRow: Int
    let elementWidth: Int
    let elementHeight: Int
    let allocationSize: Int
    let allowsPixelSizeCasting: Bool
    let cacheMode: Int
    let name: String?
    let isPlanar: Bool
    let subsampling: IOSurfaceSubsampling
    let planes: [IOSurfacePlaneLayout]
    let bytes: UnsafeMutableRawPointer
    let lock = NSLock()
    var seed: UInt32 = 0
    var lockCount: Int = 0
    var writeLockCount: Int = 0
    var localUseCount: Int32 = 0
    var purgeability: IOSurfacePurgeabilityState = []
    var attachments: [String: any Sendable] = [:]

    init(
        surfaceID: IOSurfaceID,
        width: Int,
        height: Int,
        pixelFormat: OSType,
        bytesPerElement: Int,
        bytesPerRow: Int,
        elementWidth: Int,
        elementHeight: Int,
        allocationSize: Int,
        allowsPixelSizeCasting: Bool,
        cacheMode: Int,
        name: String?,
        isPlanar: Bool,
        subsampling: IOSurfaceSubsampling,
        planes: [IOSurfacePlaneLayout]
    ) {
        self.surfaceID = surfaceID
        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat
        self.bytesPerElement = bytesPerElement
        self.bytesPerRow = bytesPerRow
        self.elementWidth = elementWidth
        self.elementHeight = elementHeight
        self.allocationSize = allocationSize
        self.allowsPixelSizeCasting = allowsPixelSizeCasting
        self.cacheMode = cacheMode
        self.name = name
        self.isPlanar = isPlanar
        self.subsampling = subsampling
        self.planes = planes
        self.bytes = UnsafeMutableRawPointer.allocate(
            byteCount: max(allocationSize, 1),
            alignment: iosurfaceAllocAlignment
        )
        self.bytes.initializeMemory(as: UInt8.self, repeating: 0, count: max(allocationSize, 1))
    }

    deinit {
        bytes.deallocate()
    }
}

private final class IOSurfaceWeakBox {
    weak var value: IOSurface?

    init(_ value: IOSurface) {
        self.value = value
    }
}

enum IOSurfaceRegistry {
    private static let lock = NSLock()
    private static var nextID: UInt32 = 1
    private static var table: [UInt32: [IOSurfaceWeakBox]] = [:]

    static func allocateID() -> UInt32 {
        lock.lock()
        defer { lock.unlock() }
        let id = nextID
        nextID &+= 1
        if nextID == 0 {
            nextID = 1
        }
        return id
    }

    static func register(_ surface: IOSurface) {
        lock.lock()
        table[surface.storage.surfaceID, default: []].append(IOSurfaceWeakBox(surface))
        lock.unlock()
    }

    static func lookup(_ id: IOSurfaceID) -> IOSurface? {
        lock.lock()
        defer { lock.unlock() }
        guard var list = table[id] else { return nil }
        list = list.filter { $0.value != nil }
        table[id] = list
        return list.first?.value
    }
}

struct IOSurfacePackedFormat {
    var bytesPerElement: Int
    var names: [IOSurfaceComponentName]
    var subsampling: IOSurfaceSubsampling
    var planeCount: Int
}

func iosurfaceKnownFormat(_ pixelFormat: OSType) -> IOSurfacePackedFormat? {
    switch pixelFormat {
    case 0x4247_5241, 0x0000_0020, 0x4142_4752, 0x5247_4241:
        let names: [IOSurfaceComponentName]
        switch pixelFormat {
        case 0x4247_5241:
            names = [.blue, .green, .red, .alpha]
        case 0x4142_4752:
            names = [.alpha, .blue, .green, .red]
        case 0x5247_4241:
            names = [.red, .green, .blue, .alpha]
        default:
            names = [.alpha, .red, .green, .blue]
        }
        return IOSurfacePackedFormat(
            bytesPerElement: 4,
            names: names,
            subsampling: .subsamplingNone,
            planeCount: 1
        )
    case 0x3432_3076, 0x3432_3066:
        return IOSurfacePackedFormat(
            bytesPerElement: 1,
            names: [.luma],
            subsampling: .subsampling420,
            planeCount: 2
        )
    default:
        return nil
    }
}

func iosurfaceComponents(
    names: [IOSurfaceComponentName],
    bitDepth: Int
) -> [IOSurfaceComponentLayout] {
    names.enumerated().map { index, name in
        IOSurfaceComponentLayout(
            name: name,
            type: .unsignedInteger,
            range: .fullRange,
            bitDepth: bitDepth,
            bitOffset: index * bitDepth
        )
    }
}

func iosurfaceBuildStorage(from raw: [String: Any]) -> IOSurfaceStorage? {
    let width = iosurfaceInt(raw[IOSurfacePropertyKey.width.rawValue]) ?? 0
    let height = iosurfaceInt(raw[IOSurfacePropertyKey.height.rawValue]) ?? 0
    let requestedAlloc = iosurfaceInt(raw[IOSurfacePropertyKey.allocSize.rawValue]) ?? 0
    if width <= 0 && height <= 0 && requestedAlloc <= 0 {
        return nil
    }
    if width < 0 || height < 0 {
        return nil
    }
    if width > iosurfaceLinuxMaxDimension || height > iosurfaceLinuxMaxDimension {
        return nil
    }

    let pixelFormat = iosurfaceUInt32(raw[IOSurfacePropertyKey.pixelFormat.rawValue]) ?? 0
    let known = iosurfaceKnownFormat(pixelFormat)
    let explicitPlanes = iosurfaceParsePlaneInfo(raw[IOSurfacePropertyKey.planeInfo.rawValue])
    let bytesPerElement = iosurfaceInt(raw[IOSurfacePropertyKey.bytesPerElement.rawValue])
        ?? known?.bytesPerElement
        ?? (width > 0 ? 4 : 1)
    let elementWidth = max(1, iosurfaceInt(raw[IOSurfacePropertyKey.elementWidth.rawValue]) ?? 1)
    let elementHeight = max(1, iosurfaceInt(raw[IOSurfacePropertyKey.elementHeight.rawValue]) ?? 1)
    let cacheMode = iosurfaceInt(raw[IOSurfacePropertyKey.cacheMode.rawValue]) ?? kIOSurfaceDefaultCache
    let allowsCasting = iosurfaceBool(raw[IOSurfacePropertyKey.pixelSizeCastingAllowed.rawValue]) ?? true
    let name = raw[IOSurfacePropertyKey.name.rawValue] as? String
        ?? (raw[IOSurfacePropertyKey.name.rawValue] as? NSString).map { $0 as String }

    let planes: [IOSurfacePlaneLayout]
    let isPlanar: Bool
    let subsampling: IOSurfaceSubsampling

    if !explicitPlanes.isEmpty {
        isPlanar = explicitPlanes.count > 1
        planes = explicitPlanes
        subsampling = iosurfaceSubsampling(
            from: raw[kIOSurfaceSubsampling as String],
            fallback: known?.subsampling ?? (isPlanar ? .subsamplingUnknown : .subsamplingNone)
        )
    } else if known?.planeCount == 2, width > 0, height > 0 {
        isPlanar = true
        subsampling = .subsampling420
        let yRow = iosurfaceAlignUp(
            iosurfaceInt(raw[IOSurfacePropertyKey.bytesPerRow.rawValue]) ?? width,
            iosurfaceBytesPerRowAlignment
        )
        let uvWidth = max(1, (width + 1) / 2)
        let uvHeight = max(1, (height + 1) / 2)
        let uvRow = iosurfaceAlignUp(uvWidth * 2, iosurfaceBytesPerRowAlignment)
        let ySize = yRow * height
        let uvSize = uvRow * uvHeight
        planes = [
            IOSurfacePlaneLayout(
                width: width,
                height: height,
                bytesPerRow: yRow,
                offset: 0,
                bytesPerElement: 1,
                elementWidth: 1,
                elementHeight: 1,
                components: iosurfaceComponents(names: [.luma], bitDepth: 8)
            ),
            IOSurfacePlaneLayout(
                width: uvWidth,
                height: uvHeight,
                bytesPerRow: uvRow,
                offset: ySize,
                bytesPerElement: 2,
                elementWidth: 2,
                elementHeight: 1,
                components: iosurfaceComponents(names: [.chromaBlue, .chromaRed], bitDepth: 8)
            ),
        ]
        _ = uvSize
    } else {
        isPlanar = false
        subsampling = known?.subsampling ?? .subsamplingNone
        let row = iosurfaceAlignUp(
            iosurfaceInt(raw[IOSurfacePropertyKey.bytesPerRow.rawValue])
                ?? max(width, 0) * max(bytesPerElement, 1),
            iosurfaceBytesPerRowAlignment
        )
        let names = known?.names ?? [.unknown]
        let bitDepth = max(1, (bytesPerElement * 8) / max(names.count, 1))
        planes = [
            IOSurfacePlaneLayout(
                width: max(width, 0),
                height: max(height, 0),
                bytesPerRow: max(row, 0),
                offset: iosurfaceInt(raw[IOSurfacePropertyKey.offset.rawValue]) ?? 0,
                bytesPerElement: bytesPerElement,
                elementWidth: elementWidth,
                elementHeight: elementHeight,
                components: iosurfaceComponents(names: names, bitDepth: bitDepth)
            )
        ]
    }

    let computedSize: Int
    if let last = planes.last {
        computedSize = last.offset + max(last.bytesPerRow, 0) * max(last.height, 0)
    } else {
        computedSize = 0
    }
    let allocationSize = max(requestedAlloc, computedSize, 1)
    let bytesPerRow = planes.first?.bytesPerRow
        ?? iosurfaceAlignUp(max(width, 0) * max(bytesPerElement, 1), iosurfaceBytesPerRowAlignment)

    return IOSurfaceStorage(
        surfaceID: IOSurfaceRegistry.allocateID(),
        width: width,
        height: height,
        pixelFormat: pixelFormat,
        bytesPerElement: bytesPerElement,
        bytesPerRow: bytesPerRow,
        elementWidth: elementWidth,
        elementHeight: elementHeight,
        allocationSize: allocationSize,
        allowsPixelSizeCasting: allowsCasting,
        cacheMode: cacheMode,
        name: name,
        isPlanar: isPlanar,
        subsampling: subsampling,
        planes: planes
    )
}

func iosurfaceParsePlaneInfo(_ value: Any?) -> [IOSurfacePlaneLayout] {
    let items: [Any]
    if let array = value as? [Any] {
        items = array
    } else if let array = value as? NSArray {
        items = array as [AnyObject] as [Any]
    } else {
        return []
    }
    var offset = 0
    var planes: [IOSurfacePlaneLayout] = []
    for item in items {
        let dict: [String: Any]
        if let typed = item as? [String: Any] {
            dict = typed
        } else if let ns = item as? NSDictionary {
            var converted: [String: Any] = [:]
            ns.enumerateKeysAndObjects { key, object, _ in
                converted[iosurfaceKeyString(key)] = object
            }
            dict = converted
        } else {
            continue
        }
        let width = iosurfaceInt(dict[IOSurfacePropertyKey.planeWidth.rawValue]) ?? 0
        let height = iosurfaceInt(dict[IOSurfacePropertyKey.planeHeight.rawValue]) ?? 0
        let bpe = iosurfaceInt(dict[IOSurfacePropertyKey.planeBytesPerElement.rawValue]) ?? 1
        let row = iosurfaceAlignUp(
            iosurfaceInt(dict[IOSurfacePropertyKey.planeBytesPerRow.rawValue]) ?? width * bpe,
            iosurfaceBytesPerRowAlignment
        )
        let planeOffset = iosurfaceInt(dict[IOSurfacePropertyKey.planeOffset.rawValue]) ?? offset
        let names = iosurfaceIntArray(dict[kIOSurfacePlaneComponentNames as String]).compactMap {
            IOSurfaceComponentName(rawValue: Int32($0))
        }
        let types = iosurfaceIntArray(dict[kIOSurfacePlaneComponentTypes as String])
        let ranges = iosurfaceIntArray(dict[kIOSurfacePlaneComponentRanges as String])
        let depths = iosurfaceIntArray(dict[kIOSurfacePlaneComponentBitDepths as String])
        let bitOffsets = iosurfaceIntArray(dict[kIOSurfacePlaneComponentBitOffsets as String])
        var components: [IOSurfaceComponentLayout] = []
        if names.isEmpty {
            components = iosurfaceComponents(names: [.unknown], bitDepth: 8)
        } else {
            for index in names.indices {
                components.append(
                    IOSurfaceComponentLayout(
                        name: names[index],
                        type: index < types.count
                            ? (IOSurfaceComponentType(rawValue: Int32(types[index])) ?? .unknown)
                            : .unsignedInteger,
                        range: index < ranges.count
                            ? (IOSurfaceComponentRange(rawValue: Int32(ranges[index])) ?? .unknown)
                            : .fullRange,
                        bitDepth: index < depths.count ? depths[index] : 8,
                        bitOffset: index < bitOffsets.count ? bitOffsets[index] : index * 8
                    )
                )
            }
        }
        planes.append(
            IOSurfacePlaneLayout(
                width: width,
                height: height,
                bytesPerRow: row,
                offset: planeOffset,
                bytesPerElement: bpe,
                elementWidth: iosurfaceInt(dict[IOSurfacePropertyKey.planeElementWidth.rawValue]) ?? 1,
                elementHeight: iosurfaceInt(dict[IOSurfacePropertyKey.planeElementHeight.rawValue]) ?? 1,
                components: components
            )
        )
        offset = planeOffset + row * max(height, 0)
    }
    return planes
}

func iosurfaceIntArray(_ value: Any?) -> [Int] {
    if let array = value as? [Int] {
        return array
    }
    if let array = value as? [NSNumber] {
        return array.map { $0.intValue }
    }
    if let array = value as? NSArray {
        return array.compactMap { iosurfaceInt($0) }
    }
    return []
}

func iosurfaceSubsampling(from value: Any?, fallback: IOSurfaceSubsampling) -> IOSurfaceSubsampling {
    guard let number = iosurfaceInt(value) else { return fallback }
    return IOSurfaceSubsampling(rawValue: Int32(number)) ?? fallback
}

func iosurfaceDictionary(_ properties: CFDictionary) -> [String: Any] {
    var raw: [String: Any] = [:]
    properties.enumerateKeysAndObjects { key, value, _ in
        raw[iosurfaceKeyString(key)] = value
    }
    return raw
}

func iosurfaceDictionary(_ properties: [IOSurfacePropertyKey: any Sendable]) -> [String: Any] {
    var raw: [String: Any] = [:]
    for (key, value) in properties {
        raw[key.rawValue] = value
    }
    return raw
}

/// Toll-free-bridged CF type / ObjC class. On Linux they are the same object.
public typealias IOSurfaceRef = IOSurface

open class IOSurface: NSObject, NSSecureCoding, @unchecked Sendable {
    let storage: IOSurfaceStorage

    public static var supportsSecureCoding: Bool { true }

    public init?(properties: [IOSurfacePropertyKey: any Sendable]) {
        guard let storage = iosurfaceBuildStorage(from: iosurfaceDictionary(properties)) else {
            return nil
        }
        self.storage = storage
        super.init()
        IOSurfaceRegistry.register(self)
    }

    public init(_ obj: IOSurface) {
        self.storage = obj.storage
        super.init()
        IOSurfaceRegistry.register(self)
    }

    init?(cfProperties: CFDictionary) {
        guard let storage = iosurfaceBuildStorage(from: iosurfaceDictionary(cfProperties)) else {
            return nil
        }
        self.storage = storage
        super.init()
        IOSurfaceRegistry.register(self)
    }

    public required init?(coder: NSCoder) {
        let width = Int(coder.decodeInt64(forKey: IOSurfacePropertyKey.width.rawValue))
        let height = Int(coder.decodeInt64(forKey: IOSurfacePropertyKey.height.rawValue))
        let allocSize = Int(coder.decodeInt64(forKey: IOSurfacePropertyKey.allocSize.rawValue))
        if width <= 0 && height <= 0 && allocSize <= 0 {
            return nil
        }
        var raw: [String: Any] = [
            IOSurfacePropertyKey.width.rawValue: width,
            IOSurfacePropertyKey.height.rawValue: height,
            IOSurfacePropertyKey.allocSize.rawValue: allocSize,
            IOSurfacePropertyKey.pixelFormat.rawValue:
                UInt32(truncatingIfNeeded: coder.decodeInt64(forKey: IOSurfacePropertyKey.pixelFormat.rawValue)),
            IOSurfacePropertyKey.bytesPerRow.rawValue:
                Int(coder.decodeInt64(forKey: IOSurfacePropertyKey.bytesPerRow.rawValue)),
            IOSurfacePropertyKey.bytesPerElement.rawValue:
                Int(coder.decodeInt64(forKey: IOSurfacePropertyKey.bytesPerElement.rawValue)),
        ]
        if let name = coder.decodeObject(of: NSString.self, forKey: IOSurfacePropertyKey.name.rawValue) {
            raw[IOSurfacePropertyKey.name.rawValue] = name as String
        }
        guard let storage = iosurfaceBuildStorage(from: raw) else {
            return nil
        }
        if let data = coder.decodeObject(of: NSData.self, forKey: "IOSurfacePixelBytes") as Data? {
            let count = min(data.count, storage.allocationSize)
            data.copyBytes(to: storage.bytes.assumingMemoryBound(to: UInt8.self), count: count)
        }
        self.storage = storage
        super.init()
        IOSurfaceRegistry.register(self)
    }

    open func encode(with coder: NSCoder) {
        coder.encode(Int64(storage.width), forKey: IOSurfacePropertyKey.width.rawValue)
        coder.encode(Int64(storage.height), forKey: IOSurfacePropertyKey.height.rawValue)
        coder.encode(Int64(storage.allocationSize), forKey: IOSurfacePropertyKey.allocSize.rawValue)
        coder.encode(Int64(storage.pixelFormat), forKey: IOSurfacePropertyKey.pixelFormat.rawValue)
        coder.encode(Int64(storage.bytesPerRow), forKey: IOSurfacePropertyKey.bytesPerRow.rawValue)
        coder.encode(Int64(storage.bytesPerElement), forKey: IOSurfacePropertyKey.bytesPerElement.rawValue)
        if let name = storage.name {
            coder.encode(name as NSString, forKey: IOSurfacePropertyKey.name.rawValue)
        }
        let buffer = UnsafeRawBufferPointer(start: storage.bytes, count: storage.allocationSize)
        coder.encode(Data(buffer), forKey: "IOSurfacePixelBytes")
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? IOSurface else { return false }
        return storage.surfaceID == other.storage.surfaceID
    }

    open override var hash: Int {
        Int(storage.surfaceID)
    }

    public var allocationSize: Int { storage.allocationSize }
    public var width: Int { storage.width }
    public var height: Int { storage.height }
    public var pixelFormat: OSType { storage.pixelFormat }
    public var bytesPerRow: Int { storage.bytesPerRow }
    public var bytesPerElement: Int { storage.bytesPerElement }
    public var elementWidth: Int { storage.elementWidth }
    public var elementHeight: Int { storage.elementHeight }
    public var surfaceID: UInt32 { storage.surfaceID }
    public var planeCount: Int { storage.isPlanar ? storage.planes.count : 0 }
    public var allowsPixelSizeCasting: Bool { storage.allowsPixelSizeCasting }
    public var baseAddress: UnsafeMutableRawPointer { storage.bytes }

    public var seed: UInt32 {
        storage.lock.lock()
        defer { storage.lock.unlock() }
        return storage.seed
    }

    public var localUseCount: Int32 {
        storage.lock.lock()
        defer { storage.lock.unlock() }
        return storage.localUseCount
    }

    public var isInUse: Bool {
        storage.lock.lock()
        defer { storage.lock.unlock() }
        return storage.localUseCount > 0 || storage.lockCount > 0
    }

    public func widthOfPlane(at planeIndex: Int) -> Int {
        storage.planes[checkedPlane: planeIndex]?.width ?? storage.width
    }

    public func heightOfPlane(at planeIndex: Int) -> Int {
        storage.planes[checkedPlane: planeIndex]?.height ?? storage.height
    }

    public func bytesPerRowOfPlane(at planeIndex: Int) -> Int {
        storage.planes[checkedPlane: planeIndex]?.bytesPerRow ?? storage.bytesPerRow
    }

    public func bytesPerElementOfPlane(at planeIndex: Int) -> Int {
        storage.planes[checkedPlane: planeIndex]?.bytesPerElement ?? storage.bytesPerElement
    }

    public func elementWidthOfPlane(at planeIndex: Int) -> Int {
        storage.planes[checkedPlane: planeIndex]?.elementWidth ?? storage.elementWidth
    }

    public func elementHeightOfPlane(at planeIndex: Int) -> Int {
        storage.planes[checkedPlane: planeIndex]?.elementHeight ?? storage.elementHeight
    }

    public func baseAddressOfPlane(at planeIndex: Int) -> UnsafeMutableRawPointer {
        let offset = storage.planes[checkedPlane: planeIndex]?.offset ?? 0
        return storage.bytes.advanced(by: min(max(offset, 0), storage.allocationSize))
    }

    public func lock(
        options: IOSurfaceLockOptions = [],
        seed: UnsafeMutablePointer<UInt32>?
    ) -> kern_return_t {
        storage.lock.lock()
        seed?.pointee = storage.seed
        storage.lockCount += 1
        if !options.contains(.readOnly) {
            storage.writeLockCount += 1
        }
        storage.lock.unlock()
        return kIOSurfaceSuccess
    }

    public func unlock(
        options: IOSurfaceLockOptions = [],
        seed: UnsafeMutablePointer<UInt32>?
    ) -> kern_return_t {
        storage.lock.lock()
        if storage.lockCount > 0 {
            storage.lockCount -= 1
        }
        if !options.contains(.readOnly), storage.writeLockCount > 0 {
            storage.writeLockCount -= 1
            if storage.writeLockCount == 0 {
                storage.seed &+= 1
            }
        }
        seed?.pointee = storage.seed
        storage.lock.unlock()
        return kIOSurfaceSuccess
    }

    public func incrementUseCount() {
        storage.lock.lock()
        storage.localUseCount += 1
        storage.lock.unlock()
    }

    public func decrementUseCount() {
        storage.lock.lock()
        if storage.localUseCount > 0 {
            storage.localUseCount -= 1
        }
        storage.lock.unlock()
    }

    public func setAttachment(_ anObject: any Sendable, forKey key: String) {
        storage.lock.lock()
        storage.attachments[key] = anObject
        storage.lock.unlock()
    }

    public func attachment(forKey key: String) -> (any Sendable)? {
        storage.lock.lock()
        defer { storage.lock.unlock() }
        return storage.attachments[key]
    }

    public func removeAttachment(forKey key: String) {
        storage.lock.lock()
        storage.attachments.removeValue(forKey: key)
        storage.lock.unlock()
    }

    public func allAttachments() -> [String: any Sendable]? {
        storage.lock.lock()
        defer { storage.lock.unlock() }
        if storage.attachments.isEmpty {
            return nil
        }
        var copy: [String: any Sendable] = [:]
        for (key, value) in storage.attachments {
            copy[key] = value
        }
        return copy
    }

    public func setAllAttachments(_ dict: [String: any Sendable]) {
        storage.lock.lock()
        storage.attachments = dict
        storage.lock.unlock()
    }

    public func removeAllAttachments() {
        storage.lock.lock()
        storage.attachments.removeAll()
        storage.lock.unlock()
    }

    public func setPurgeable(
        _ newState: IOSurfacePurgeabilityState,
        oldState: UnsafeMutablePointer<IOSurfacePurgeabilityState>?
    ) -> kern_return_t {
        storage.lock.lock()
        oldState?.pointee = storage.purgeability
        if newState != .purgeableKeepCurrent {
            storage.purgeability = IOSurfacePurgeabilityState(rawValue: newState.rawValue)
            if newState == .purgeableEmpty {
                storage.bytes.initializeMemory(
                    as: UInt8.self,
                    repeating: 0,
                    count: storage.allocationSize
                )
            }
        }
        storage.lock.unlock()
        return kIOSurfaceSuccess
    }

    func componentCount(planeIndex: Int) -> Int {
        storage.planes[checkedPlane: planeIndex]?.components.count ?? 0
    }

    func component(_ planeIndex: Int, _ componentIndex: Int) -> IOSurfaceComponentLayout? {
        guard let plane = storage.planes[checkedPlane: planeIndex] else { return nil }
        guard componentIndex >= 0, componentIndex < plane.components.count else { return nil }
        return plane.components[componentIndex]
    }
}

private extension Array where Element == IOSurfacePlaneLayout {
    subscript(checkedPlane index: Int) -> IOSurfacePlaneLayout? {
        if isEmpty { return nil }
        if index >= 0, index < count { return self[index] }
        return self[0]
    }
}
