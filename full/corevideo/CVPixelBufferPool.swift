import Foundation

open class CVPixelBufferPool: Hashable, @unchecked Sendable {
    public static func == (lhs: CVPixelBufferPool, rhs: CVPixelBufferPool) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    let lock = NSLock()
    let poolAttributes: NSDictionary
    let pixelBufferAttributes: NSDictionary
    var freeBuffers: [CVPixelBuffer] = []
    var allocatedCount: Int = 0
    let minimumBufferCount: Int
    let allocationThreshold: Int?

    init(
        poolAttributes: NSDictionary,
        pixelBufferAttributes: NSDictionary
    ) {
        self.poolAttributes = poolAttributes
        self.pixelBufferAttributes = pixelBufferAttributes
        self.minimumBufferCount = _cvInt(poolAttributes, kCVPixelBufferPoolMinimumBufferCountKey) ?? 0
        self.allocationThreshold = _cvInt(poolAttributes, kCVPixelBufferPoolAllocationThresholdKey)
    }
}

public func CVPixelBufferPoolCreate(
    _ allocator: CFAllocator?,
    _ poolAttributes: CFDictionary?,
    _ pixelBufferAttributes: CFDictionary?,
    _ poolOut: UnsafeMutablePointer<CVPixelBufferPool?>
) -> CVReturn {
    _ = allocator
    guard let pixelBufferAttributes else {
        poolOut.pointee = nil
        return kCVReturnInvalidPixelBufferAttributes
    }
    let pool = CVPixelBufferPool(
        poolAttributes: (poolAttributes as NSDictionary?) ?? NSDictionary(),
        pixelBufferAttributes: pixelBufferAttributes as NSDictionary
    )
    poolOut.pointee = pool
    return kCVReturnSuccess
}

public func CVPixelBufferPoolGetAttributes(_ pool: CVPixelBufferPool) -> CFDictionary? {
    pool.poolAttributes
}

public func CVPixelBufferPoolGetPixelBufferAttributes(_ pool: CVPixelBufferPool) -> CFDictionary? {
    pool.pixelBufferAttributes
}

public func CVPixelBufferPoolCreatePixelBuffer(
    _ allocator: CFAllocator?,
    _ pixelBufferPool: CVPixelBufferPool,
    _ pixelBufferOut: UnsafeMutablePointer<CVPixelBuffer?>
) -> CVReturn {
    CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
        allocator,
        pixelBufferPool,
        nil,
        pixelBufferOut
    )
}

public func CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
    _ allocator: CFAllocator?,
    _ pixelBufferPool: CVPixelBufferPool,
    _ auxAttributes: CFDictionary?,
    _ pixelBufferOut: UnsafeMutablePointer<CVPixelBuffer?>
) -> CVReturn {
    pixelBufferPool.lock.lock()
    defer { pixelBufferPool.lock.unlock() }
    if let recycled = pixelBufferPool.freeBuffers.popLast() {
        pixelBufferOut.pointee = recycled
        return kCVReturnSuccess
    }
    let threshold =
        _cvInt(auxAttributes as NSDictionary?, kCVPixelBufferPoolAllocationThresholdKey)
        ?? pixelBufferPool.allocationThreshold
    if let threshold, pixelBufferPool.allocatedCount >= threshold {
        pixelBufferOut.pointee = nil
        return kCVReturnWouldExceedAllocationThreshold
    }
    let attrs = pixelBufferPool.pixelBufferAttributes
    let width = _cvInt(attrs, kCVPixelBufferWidthKey) ?? 0
    let height = _cvInt(attrs, kCVPixelBufferHeightKey) ?? 0
    let format = (attrs.object(forKey: kCVPixelBufferPixelFormatTypeKey) as? NSNumber)?.uint32Value
        ?? kCVPixelFormatType_32BGRA
    var created: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        allocator,
        width,
        height,
        format,
        attrs,
        &created
    )
    guard status == kCVReturnSuccess, let created else {
        pixelBufferOut.pointee = nil
        return status == kCVReturnSuccess ? kCVReturnPoolAllocationFailed : status
    }
    pixelBufferPool.allocatedCount += 1
    pixelBufferOut.pointee = created
    return kCVReturnSuccess
}

public func CVPixelBufferPoolFlush(
    _ pool: CVPixelBufferPool,
    _ options: CVPixelBufferPoolFlushFlags
) {
    pool.lock.lock()
    defer { pool.lock.unlock() }
    if options.contains(.excessBuffers) {
        let keep = pool.minimumBufferCount
        if pool.freeBuffers.count > keep {
            pool.freeBuffers.removeFirst(pool.freeBuffers.count - keep)
        }
    } else {
        pool.freeBuffers.removeAll()
    }
}
