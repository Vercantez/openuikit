import Foundation

public class MDLMeshBufferMap: NSObject {
    private var storage: UnsafeMutableRawPointer
    private let owned: Bool
    private let deallocator: (() -> Void)?
    let byteCount: Int

    public var bytes: UnsafeMutableRawPointer { storage }

    public init(bytes: UnsafeMutableRawPointer, deallocator: (() -> Void)? = nil) {
        self.storage = bytes
        self.owned = false
        self.deallocator = deallocator
        self.byteCount = 0
        super.init()
    }

    init(copying data: Data) {
        let count = max(data.count, 1)
        let pointer = UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 16)
        data.copyBytes(to: pointer.assumingMemoryBound(to: UInt8.self), count: data.count)
        self.storage = pointer
        self.owned = true
        self.deallocator = nil
        self.byteCount = data.count
        super.init()
    }

    deinit {
        if owned {
            storage.deallocate()
        }
        deallocator?()
    }
}

public class MDLMeshBufferZoneDefault: NSObject, MDLMeshBufferZone {
    public private(set) var allocator: any MDLMeshBufferAllocator
    public private(set) var capacity: UInt

    public init(allocator: any MDLMeshBufferAllocator, capacity: UInt) {
        self.allocator = allocator
        self.capacity = capacity
        super.init()
    }
}

public class MDLMeshBufferData: NSObject, MDLMeshBuffer {
    public private(set) var allocator: any MDLMeshBufferAllocator
    public private(set) var type: MDLMeshBufferType
    public private(set) var zone: any MDLMeshBufferZone
    private var storage: Data

    public var data: Data { storage }
    public var length: UInt { UInt(storage.count) }

    public init(type: MDLMeshBufferType, data: Data?) {
        let allocator = MDLMeshBufferDataAllocator()
        self.allocator = allocator
        self.type = type
        self.storage = data ?? Data()
        self.zone = MDLMeshBufferZoneDefault(allocator: allocator, capacity: UInt((data ?? Data()).count))
        super.init()
        allocator.note(self)
    }

    public init(type: MDLMeshBufferType, length: UInt) {
        let allocator = MDLMeshBufferDataAllocator()
        self.allocator = allocator
        self.type = type
        self.storage = Data(count: Int(length))
        self.zone = MDLMeshBufferZoneDefault(allocator: allocator, capacity: length)
        super.init()
        allocator.note(self)
    }

    init(type: MDLMeshBufferType, data: Data, allocator: any MDLMeshBufferAllocator, zone: any MDLMeshBufferZone) {
        self.allocator = allocator
        self.type = type
        self.storage = data
        self.zone = zone
        super.init()
    }

    public func fill(_ data: Data, offset: UInt) {
        let start = Int(offset)
        if start > storage.count {
            storage.append(Data(count: start - storage.count))
        }
        let end = start + data.count
        if end > storage.count {
            storage.append(Data(count: end - storage.count))
        }
        storage.replaceSubrange(start..<end, with: data)
    }

    public func map() -> MDLMeshBufferMap {
        MDLMeshBufferMap(copying: storage)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        MDLMeshBufferData(type: type, data: storage, allocator: allocator, zone: self.zone)
    }
}

public class MDLMeshBufferDataAllocator: NSObject, MDLMeshBufferAllocator {
    func note(_ buffer: MDLMeshBufferData) {}

    public func newBuffer(_ length: UInt, type: MDLMeshBufferType) -> any MDLMeshBuffer {
        MDLMeshBufferData(type: type, data: Data(count: Int(length)), allocator: self, zone: MDLMeshBufferZoneDefault(allocator: self, capacity: length))
    }

    public func newBuffer(from zone: (any MDLMeshBufferZone)?, data: Data, type: MDLMeshBufferType) -> (any MDLMeshBuffer)? {
        let resolved = zone ?? MDLMeshBufferZoneDefault(allocator: self, capacity: UInt(data.count))
        return MDLMeshBufferData(type: type, data: data, allocator: self, zone: resolved)
    }

    public func newBuffer(from zone: (any MDLMeshBufferZone)?, length: UInt, type: MDLMeshBufferType) -> (any MDLMeshBuffer)? {
        let resolved = zone ?? MDLMeshBufferZoneDefault(allocator: self, capacity: length)
        return MDLMeshBufferData(type: type, data: Data(count: Int(length)), allocator: self, zone: resolved)
    }

    public func newBuffer(with data: Data, type: MDLMeshBufferType) -> any MDLMeshBuffer {
        MDLMeshBufferData(type: type, data: data, allocator: self, zone: MDLMeshBufferZoneDefault(allocator: self, capacity: UInt(data.count)))
    }

    public func newZone(_ capacity: UInt) -> any MDLMeshBufferZone {
        MDLMeshBufferZoneDefault(allocator: self, capacity: capacity)
    }

    public func newZoneForBuffers(withSize sizes: [NSNumber], andType types: [NSNumber]) -> any MDLMeshBufferZone {
        let total = sizes.reduce(0) { $0 + $1.uintValue }
        return MDLMeshBufferZoneDefault(allocator: self, capacity: total)
    }
}

func mdlDefaultAllocator(_ allocator: (any MDLMeshBufferAllocator)?) -> any MDLMeshBufferAllocator {
    allocator ?? MDLMeshBufferDataAllocator()
}

func mdlBufferData(_ buffer: any MDLMeshBuffer) -> Data {
    if let dataBuffer = buffer as? MDLMeshBufferData {
        return dataBuffer.data
    }
    let mapped = buffer.map()
    return Data(bytes: mapped.bytes, count: Int(buffer.length))
}
