import CoreVideo
import Foundation

func testCVImageSize() {
    let size = CVImageSize(width: 4, height: 8)
    precondition(size.width == 4 && size.height == 8)
    precondition(CVImageSize.zero == CVImageSize(width: 0, height: 0))
    let rounded = CVImageSize(CGSize(width: 3.9, height: 2.2), rounded: .down)
    precondition(rounded.width == 3 && rounded.height == 2)
    let cg = CGSize(size)
    precondition(cg.width == 4)
    precondition(size != .zero)
    var hasher = Hasher()
    size.hash(into: &hasher)
    _ = size.hashValue
}

func testCVPixelFormatTypeOverlay() {
    let format = CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA)
    precondition(format.rawValue == kCVPixelFormatType_32BGRA)
    precondition(format.isCompressionAvailable == false)
    let _: CVPixelFormatType.RawValue = format.rawValue
    precondition(format != CVPixelFormatType(rawValue: 32))
    var hasher = Hasher()
    format.hash(into: &hasher)
    _ = format.hashValue
}

func testCVPixelBufferPadding() {
    let padding = CVPixelBufferPadding(left: 1, right: 2, top: 3, bottom: 4)
    precondition(padding.left == 1 && padding.bottom == 4)
    precondition(CVPixelBufferPadding.zero.left == 0)
    precondition(padding != .zero)
    var hasher = Hasher()
    padding.hash(into: &hasher)
    _ = padding.hashValue
}

func testCVPixelBufferPlaneProperties() {
    let props = CVPixelBufferPlaneProperties(
        size: CVImageSize(width: 8, height: 4),
        bytesPerRow: 32
    )
    precondition(props.size.width == 8 && props.bytesPerRow == 32)
    precondition(
        props != CVPixelBufferPlaneProperties(size: .zero, bytesPerRow: 0)
    )
    var hasher = Hasher()
    props.hash(into: &hasher)
    _ = props.hashValue
}

func testOriginPosition() {
    precondition(CVImageBufferOriginPosition.topLeft != .bottomLeft)
    var hasher = Hasher()
    CVImageBufferOriginPosition.topLeft.hash(into: &hasher)
    _ = CVImageBufferOriginPosition.topLeft.hashValue
}

func testCreationAttributes() {
    var attributes = CVPixelBufferCreationAttributes(
        pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
        size: CVImageSize(width: 8, height: 8),
        compatibility: [.cgImage],
        bytesPerRowAlignment: 16,
        planeAlignment: 16,
        extendedPixels: .zero
    )
    attributes.backing = .memory
    precondition(attributes.backing == .memory)
    precondition(attributes.compatibility.contains(.cgImage))
    precondition(attributes.bytesPerRowAlignment == 16)
    precondition(attributes.planeAlignment == 16)
    precondition(attributes.extendedPixels == .zero)
    precondition(CVPixelBufferCreationAttributes.Backing.memory != .ioSurface)
    precondition(
        CVPixelBufferCreationAttributes.Backing.ioSurfaceWithProperties(["a": 1])
            != .memory
    )
    let fromAttrs = CVPixelBufferCreationAttributes(
        CVPixelBufferAttributes(
            pixelFormatTypes: [attributes.pixelFormatType],
            size: attributes.size
        )
    )
    precondition(fromAttrs != nil)
    precondition(attributes != fromAttrs)
}

func testPixelBufferAttributes() {
    var attributes = CVPixelBufferAttributes(rawAttributes: ["Width": 8])
    precondition(attributes.rawAttributes["Width"] as? Int == 8)
    attributes = CVPixelBufferAttributes(
        pixelFormatTypes: [CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA)],
        size: CVImageSize(width: 8, height: 8),
        compatibility: [.metalTexture],
        bytesPerRowAlignment: 16,
        planeAlignment: 8,
        extendedPixels: .zero
    )
    attributes.pixelFormatType = CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA)
    attributes.size = CVImageSize(width: 8, height: 8)
    attributes.compatibility = [.cgImage]
    attributes.extendedPixels = .zero
    attributes.backing = .memory
    attributes.bytesPerRowAlignment = 32
    attributes.planeAlignment = 16
    _ = attributes[dynamicMember: \CVPixelBufferCreationAttributes.pixelFormatType]
    let merged = CVPixelBufferAttributes(merging: [attributes])
    precondition(merged != nil)
    let fromCreation = CVPixelBufferAttributes(
        CVPixelBufferCreationAttributes(
            pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
            size: CVImageSize(width: 4, height: 4)
        )
    )
    precondition(fromCreation.pixelFormatTypes?.first?.rawValue == kCVPixelFormatType_32BGRA)
}

func testMutablePixelBuffer() {
    var buffer = try! CVMutablePixelBuffer(
        CVPixelBufferCreationAttributes(
            pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
            size: CVImageSize(width: 4, height: 4)
        )
    )
    let _: CVMutablePixelBuffer.Buffer = buffer.withUnsafeBuffer { $0 }
    precondition(buffer.size == CVImageSize(width: 4, height: 4))
    precondition(buffer.pixelFormatType.rawValue == kCVPixelFormatType_32BGRA)
    precondition(buffer.isPlanar == false)
    precondition(buffer.planeCount == 1)
    precondition(buffer.extendedPixels == .zero)
    precondition(buffer.originPosition == .topLeft)
    precondition(buffer.colorSpace == nil)
    precondition(buffer.displaySize.width == 4)
    precondition(buffer.encodedSize.height == 4)
    precondition(buffer.cleanRect.width == 4)
    precondition(buffer.planeProperties.count == 1)
    precondition(buffer.creationAttributes.size.width == 4)
    precondition(
        buffer.isCompatibleWith(
            CVPixelBufferCreationAttributes(
                pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
                size: CVImageSize(width: 4, height: 4)
            )
        )
    )
    precondition(
        buffer.isCompatibleWith(
            CVPixelBufferAttributes(
                pixelFormatTypes: [CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA)],
                size: CVImageSize(width: 4, height: 4)
            )
        )
    )
    buffer.accessUnsafeRawPlaneBytes { planes in
        precondition(planes.count == 1)
        precondition(planes[0].bytes.count >= 16)
    }
    buffer.accessUnsafeMutableRawPlaneBytes { planes in
        precondition(planes.count == 1)
        planes[0].bytes.storeBytes(of: UInt32(1), as: UInt32.self)
    }
    precondition(buffer.fillExtendedPixels())
    precondition(buffer.withUnsafeBackingIOSurfaceIfPresent { _ in 1 } == nil)
    do {
        _ = try CVMutablePixelBuffer(
            CVPixelBufferCreationAttributes(
                pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
                size: CVImageSize(width: 2, height: 2),
                backing: .ioSurface
            )
        )
        preconditionFailure("ioSurface backing must fail closed")
    } catch {
        precondition((error as? CVError) == .unsupported)
    }
    do {
        _ = try CVMutablePixelBuffer(
            unsafeBacking: IOSurface(),
            matching: CVPixelBufferCreationAttributes(
                pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
                size: CVImageSize(width: 2, height: 2)
            )
        )
        preconditionFailure("unsafeBacking must fail closed")
    } catch {
        precondition((error as? CVError) == .unsupported)
    }
    var created: CVPixelBuffer?
    precondition(
        CVPixelBufferCreate(nil, 2, 2, kCVPixelFormatType_32BGRA, nil, &created)
            == kCVReturnSuccess
    )
    _ = CVMutablePixelBuffer(unsafeBuffer: created!)
}

func testReadOnlyPixelBuffer() {
    let mutable = try! CVMutablePixelBuffer(
        CVPixelBufferCreationAttributes(
            pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
            size: CVImageSize(width: 4, height: 4)
        )
    )
    let readonly = CVReadOnlyPixelBuffer(mutable)
    let _: CVReadOnlyPixelBuffer.Buffer = readonly.withUnsafeBuffer { $0 }
    precondition(readonly.size.width == 4)
    precondition(readonly.isPlanar == false)
    precondition(readonly.planeCount == 1)
    precondition(readonly.colorSpace == nil)
    precondition(readonly.displaySize.width == 4)
    precondition(readonly.encodedSize.height == 4)
    precondition(readonly.originPosition == .topLeft)
    precondition(readonly.cleanRect.width == 4)
    precondition(readonly.extendedPixels == .zero)
    precondition(readonly.pixelFormatType.rawValue == kCVPixelFormatType_32BGRA)
    precondition(readonly.planeProperties.count == 1)
    precondition(readonly.creationAttributes.size.width == 4)
    precondition(
        readonly.isCompatibleWith(
            CVPixelBufferCreationAttributes(
                pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
                size: CVImageSize(width: 4, height: 4)
            )
        )
    )
    precondition(
        readonly.isCompatibleWith(
            CVPixelBufferAttributes(
                pixelFormatTypes: [CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA)],
                size: CVImageSize(width: 4, height: 4)
            )
        )
    )
    readonly.accessUnsafeRawPlaneBytes { planes in
        precondition(planes.count == 1)
    }
    precondition(readonly.withUnsafeBackingIOSurfaceIfPresent { _ in 1 } == nil)
    var created: CVPixelBuffer?
    precondition(
        CVPixelBufferCreate(nil, 2, 2, kCVPixelFormatType_32BGRA, nil, &created)
            == kCVReturnSuccess
    )
    _ = CVReadOnlyPixelBuffer(unsafeBuffer: created!)
}

func testMutablePool() {
    let attributes = CVPixelBufferCreationAttributes(
        pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
        size: CVImageSize(width: 8, height: 8)
    )
    var configuration = CVMutablePixelBuffer.Pool.Configuration(
        ageOutDuration: 2,
        minimumBufferCount: 1
    )
    configuration.ageOutDuration = 2
    configuration.minimumBufferCount = 1
    precondition(configuration != CVMutablePixelBuffer.Pool.Configuration())
    let pool = try! CVMutablePixelBuffer.Pool(
        pixelBufferAttributes: attributes,
        configuration: configuration
    )
    precondition(pool.pixelBufferAttributes.size.width == 8)
    precondition(pool.minimumBufferCount == 1)
    let allocated = try! pool.makeMutablePixelBuffer(
        .init(allocationThreshold: 4)
    )
    precondition(allocated.size.width == 8)
    pool.flush(agedOutOnly: true)
    pool.flush(agedOutOnly: false)
    let allocation = CVMutablePixelBuffer.Pool.AllocationAttributes(allocationThreshold: 1)
    precondition(allocation.allocationThreshold == 1)
    precondition(allocation != CVMutablePixelBuffer.Pool.AllocationAttributes())
    var rawPool: CVPixelBufferPool?
    precondition(
        CVPixelBufferPoolCreate(
            nil,
            nil,
            [
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey: 4,
                kCVPixelBufferHeightKey: 4,
            ] as NSDictionary,
            &rawPool
        ) == kCVReturnSuccess
    )
    _ = CVMutablePixelBuffer.Pool(unsafePool: rawPool!)
}

func testBufferRepresentableProtocols() {
    let buffer = try! CVMutablePixelBuffer(
        CVPixelBufferCreationAttributes(
            pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
            size: CVImageSize(width: 2, height: 2)
        )
    )
    func useBuffer<T: CVBufferRepresentable>(_ value: T) {
        _ = value.withUnsafeBuffer { $0 }
    }
    func useImage<T: CVImageBufferRepresentable>(_ value: T) {
        _ = value.encodedSize
    }
    func usePixel<T: CVPixelBufferRepresentable>(_ value: T) {
        _ = value.planeCount
    }
    useBuffer(buffer)
    useImage(buffer)
    usePixel(buffer)
}

func testCVBufferNestedAttributes() {
    var nested = CVBuffer.Attributes(rawAttributes: [:])
    nested = CVBuffer.Attributes(
        pixelFormatTypes: [CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA)],
        size: CVImageSize(width: 4, height: 4)
    )
    nested.size = CVImageSize(width: 4, height: 4)
    nested.pixelFormatType = CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA)
    nested.extendedPixels = .zero
    nested.compatibility = []
    nested.backing = .memory
    nested.bytesPerRowAlignment = 16
    nested.planeAlignment = 16
    _ = CVBuffer.Attributes(merging: [nested])
    var creation = CVBuffer.CreationAttributes(
        pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
        size: CVImageSize(width: 4, height: 4)
    )
    creation.backing = .ioSurface
    precondition(creation.backing != .memory)
    creation.backing = .ioSurfaceWithProperties(["k": "v"])
    precondition(CVBuffer.CreationAttributes.Backing.memory != .ioSurface)
    _ = CVBuffer.Attributes(creation)
    _ = CVBuffer.CreationAttributes(nested)
}
