import CoreVideo
import Foundation

func testPoolCreateAndAllocate() {
    var pool: CVPixelBufferPool?
    let poolAttrs: NSDictionary = [kCVPixelBufferPoolMinimumBufferCountKey: 1]
    let pbAttrs: NSDictionary = [
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey: 8,
        kCVPixelBufferHeightKey: 8,
    ]
    precondition(CVPixelBufferPoolCreate(nil, poolAttrs, pbAttrs, &pool) == kCVReturnSuccess)
    guard let pool else { preconditionFailure("pool") }
    precondition(CVPixelBufferPoolGetAttributes(pool) != nil)
    precondition(CVPixelBufferPoolGetPixelBufferAttributes(pool) != nil)
    var pooled: CVPixelBuffer?
    precondition(CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pooled) == kCVReturnSuccess)
    precondition(CVPixelBufferGetWidth(pooled!) == 8)
    var missing: CVPixelBufferPool?
    precondition(
        CVPixelBufferPoolCreate(nil, nil, nil, &missing) == kCVReturnInvalidPixelBufferAttributes
    )
}

func testPoolThresholdAndFlush() {
    var pool: CVPixelBufferPool?
    let poolAttrs: NSDictionary = [
        kCVPixelBufferPoolMinimumBufferCountKey: 1,
        kCVPixelBufferPoolAllocationThresholdKey: 1,
    ]
    let pbAttrs: NSDictionary = [
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey: 8,
        kCVPixelBufferHeightKey: 8,
    ]
    precondition(CVPixelBufferPoolCreate(nil, poolAttrs, pbAttrs, &pool) == kCVReturnSuccess)
    var first: CVPixelBuffer?
    precondition(CVPixelBufferPoolCreatePixelBuffer(nil, pool!, &first) == kCVReturnSuccess)
    var limited: CVPixelBuffer?
    let aux: NSDictionary = [kCVPixelBufferPoolAllocationThresholdKey: 1]
    let limitedStatus = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
        nil,
        pool!,
        aux,
        &limited
    )
    precondition(
        limitedStatus == kCVReturnWouldExceedAllocationThreshold
            || limitedStatus == kCVReturnSuccess
    )
    CVPixelBufferPoolFlush(pool!, .excessBuffers)
    CVPixelBufferPoolFlush(pool!, [])
}

func testPoolIdentityHashable() {
    var first: CVPixelBufferPool?
    var second: CVPixelBufferPool?
    let attrs: NSDictionary = [
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
        kCVPixelBufferWidthKey: 4,
        kCVPixelBufferHeightKey: 4,
    ]
    precondition(CVPixelBufferPoolCreate(nil, nil, attrs, &first) == kCVReturnSuccess)
    precondition(CVPixelBufferPoolCreate(nil, nil, attrs, &second) == kCVReturnSuccess)
    precondition(first! == first!)
    precondition(first! != second!)
    var hasher = Hasher()
    first!.hash(into: &hasher)
    _ = first!.hashValue
}
