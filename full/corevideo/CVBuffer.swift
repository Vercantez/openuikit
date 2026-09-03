import Foundation

public final class CVMetalBufferCache: @unchecked Sendable {}
public final class CVMetalTextureCache: @unchecked Sendable {}
public final class CVOpenGLESTextureCache: @unchecked Sendable {}

struct _CVPlane {
    var width: Int
    var height: Int
    var bytesPerRow: Int
    var offset: Int
}

final class _CVPixelStorage {
    var pixelFormat: OSType
    var width: Int
    var height: Int
    var extraLeft: Int
    var extraRight: Int
    var extraTop: Int
    var extraBottom: Int
    var bytesPerRowAlignment: Int
    var planeAlignment: Int
    var isPlanar: Bool
    var planes: [_CVPlane]
    var dataSize: Int
    var headerSize: Int
    var owned: UnsafeMutableRawPointer?
    var externalBase: UnsafeMutableRawPointer?
    var releaseBytes: CVPixelBufferReleaseBytesCallback?
    var releasePlanar: CVPixelBufferReleasePlanarBytesCallback?
    var releaseRefCon: UnsafeMutableRawPointer?
    var creationAttributes: NSMutableDictionary
    var lockCount: Int = 0
    var originFlipped: Bool = false

    init(
        pixelFormat: OSType,
        width: Int,
        height: Int,
        extraLeft: Int,
        extraRight: Int,
        extraTop: Int,
        extraBottom: Int,
        bytesPerRowAlignment: Int,
        planeAlignment: Int,
        isPlanar: Bool,
        planes: [_CVPlane],
        dataSize: Int,
        headerSize: Int,
        owned: UnsafeMutableRawPointer?,
        externalBase: UnsafeMutableRawPointer?,
        releaseBytes: CVPixelBufferReleaseBytesCallback?,
        releasePlanar: CVPixelBufferReleasePlanarBytesCallback?,
        releaseRefCon: UnsafeMutableRawPointer?,
        creationAttributes: NSMutableDictionary
    ) {
        self.pixelFormat = pixelFormat
        self.width = width
        self.height = height
        self.extraLeft = extraLeft
        self.extraRight = extraRight
        self.extraTop = extraTop
        self.extraBottom = extraBottom
        self.bytesPerRowAlignment = bytesPerRowAlignment
        self.planeAlignment = planeAlignment
        self.isPlanar = isPlanar
        self.planes = planes
        self.dataSize = dataSize
        self.headerSize = headerSize
        self.owned = owned
        self.externalBase = externalBase
        self.releaseBytes = releaseBytes
        self.releasePlanar = releasePlanar
        self.releaseRefCon = releaseRefCon
        self.creationAttributes = creationAttributes
    }

    deinit {
        if let releaseBytes, let externalBase {
            releaseBytes(releaseRefCon, UnsafeRawPointer(externalBase))
        }
        if let releasePlanar {
            releasePlanar(releaseRefCon, UnsafeRawPointer(externalBase), 0, 0, nil)
        }
        if let owned {
            owned.deallocate()
        }
    }

    var base: UnsafeMutableRawPointer? { owned ?? externalBase }

    func planeAddress(_ index: Int) -> UnsafeMutableRawPointer? {
        guard isPlanar, planes.indices.contains(index), let base else { return nil }
        return base.advanced(by: planes[index].offset)
    }
}

open class CVBuffer: Hashable, @unchecked Sendable {
    let lock = NSLock()
    var propagated: NSMutableDictionary = [:]
    var nonPropagated: NSMutableDictionary = [:]
    var pixels: _CVPixelStorage?

    public static func == (left: CVBuffer, right: CVBuffer) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public func CVBufferSetAttachment(
    _ buffer: CVBuffer,
    _ key: CFString,
    _ value: CFTypeRef,
    _ attachmentMode: CVAttachmentMode
) {
    buffer.lock.lock()
    defer { buffer.lock.unlock() }
    let store: NSMutableDictionary
    switch attachmentMode {
    case .shouldPropagate:
        store = buffer.propagated
        buffer.nonPropagated.removeObject(forKey: key)
    case .shouldNotPropagate:
        store = buffer.nonPropagated
        buffer.propagated.removeObject(forKey: key)
    }
    store[key] = value
}

public func CVBufferSetAttachments(
    _ buffer: CVBuffer,
    _ theAttachments: CFDictionary,
    _ attachmentMode: CVAttachmentMode
) {
    let dict = theAttachments as NSDictionary
    dict.enumerateKeysAndObjects { key, value, _ in
        guard let key = key as? NSString else { return }
        CVBufferSetAttachment(buffer, key, value as AnyObject, attachmentMode)
    }
}

public func CVBufferRemoveAttachment(_ buffer: CVBuffer, _ key: CFString) {
    buffer.lock.lock()
    defer { buffer.lock.unlock() }
    buffer.propagated.removeObject(forKey: key)
    buffer.nonPropagated.removeObject(forKey: key)
}

public func CVBufferRemoveAllAttachments(_ buffer: CVBuffer) {
    buffer.lock.lock()
    defer { buffer.lock.unlock() }
    buffer.propagated.removeAllObjects()
    buffer.nonPropagated.removeAllObjects()
}

public func CVBufferHasAttachment(_ buffer: CVBuffer, _ key: CFString) -> Bool {
    buffer.lock.lock()
    defer { buffer.lock.unlock() }
    return buffer.propagated.object(forKey: key) != nil
        || buffer.nonPropagated.object(forKey: key) != nil
}

public func CVBufferCopyAttachment(
    _ buffer: CVBuffer,
    _ key: CFString,
    _ attachmentMode: UnsafeMutablePointer<CVAttachmentMode>?
) -> CFTypeRef? {
    buffer.lock.lock()
    defer { buffer.lock.unlock() }
    if let value = buffer.propagated.object(forKey: key) as? AnyObject {
        attachmentMode?.pointee = .shouldPropagate
        return value
    }
    if let value = buffer.nonPropagated.object(forKey: key) as? AnyObject {
        attachmentMode?.pointee = .shouldNotPropagate
        return value
    }
    return nil
}

public func CVBufferGetAttachment(
    _ buffer: CVBuffer,
    _ key: CFString,
    _ attachmentMode: UnsafeMutablePointer<CVAttachmentMode>?
) -> Unmanaged<CFTypeRef>? {
    guard let value = CVBufferCopyAttachment(buffer, key, attachmentMode) else { return nil }
    return Unmanaged.passUnretained(value)
}

public func CVBufferCopyAttachments(
    _ buffer: CVBuffer,
    _ attachmentMode: CVAttachmentMode
) -> CFDictionary? {
    buffer.lock.lock()
    defer { buffer.lock.unlock() }
    switch attachmentMode {
    case .shouldPropagate:
        return buffer.propagated.count == 0 ? nil : _cvCopyDictionary(buffer.propagated)
    case .shouldNotPropagate:
        return buffer.nonPropagated.count == 0 ? nil : _cvCopyDictionary(buffer.nonPropagated)
    }
}

public func CVBufferGetAttachments(
    _ buffer: CVBuffer,
    _ attachmentMode: CVAttachmentMode
) -> CFDictionary? {
    CVBufferCopyAttachments(buffer, attachmentMode)
}

public func CVBufferPropagateAttachments(
    _ sourceBuffer: CVBuffer,
    _ destinationBuffer: CVBuffer
) {
    guard let copy = CVBufferCopyAttachments(sourceBuffer, .shouldPropagate) else { return }
    CVBufferSetAttachments(destinationBuffer, copy, .shouldPropagate)
}

func _cvAlign(_ value: Int, _ alignment: Int) -> Int {
    let align = max(alignment, 1)
    return (value + align - 1) / align * align
}

struct _CVFormatLayout {
    var isPlanar: Bool
    var planes: [(widthDiv: Int, heightDiv: Int, bytesPerPixel: Int)]
}

func _cvLayout(for pixelFormat: OSType) -> _CVFormatLayout? {
    if _cvIsCompressedPixelFormat(pixelFormat) { return nil }
    switch pixelFormat {
    case kCVPixelFormatType_32ARGB, kCVPixelFormatType_32BGRA, kCVPixelFormatType_32ABGR,
        kCVPixelFormatType_32RGBA, kCVPixelFormatType_30RGB, kCVPixelFormatType_ARGB2101010LEPacked:
        return _CVFormatLayout(isPlanar: false, planes: [(1, 1, 4)])
    case kCVPixelFormatType_24RGB, kCVPixelFormatType_24BGR:
        return _CVFormatLayout(isPlanar: false, planes: [(1, 1, 3)])
    case kCVPixelFormatType_16BE555, kCVPixelFormatType_16LE555, kCVPixelFormatType_16LE5551,
        kCVPixelFormatType_16BE565, kCVPixelFormatType_16LE565, kCVPixelFormatType_16Gray,
        kCVPixelFormatType_OneComponent16, kCVPixelFormatType_OneComponent16Half,
        kCVPixelFormatType_DepthFloat16, kCVPixelFormatType_DisparityFloat16,
        kCVPixelFormatType_TwoComponent8:
        return _CVFormatLayout(isPlanar: false, planes: [(1, 1, 2)])
    case kCVPixelFormatType_OneComponent8, kCVPixelFormatType_8Indexed,
        kCVPixelFormatType_8IndexedGray_WhiteIsZero:
        return _CVFormatLayout(isPlanar: false, planes: [(1, 1, 1)])
    case kCVPixelFormatType_48RGB, kCVPixelFormatType_32AlphaGray:
        return _CVFormatLayout(isPlanar: false, planes: [(1, 1, 6)])
    case kCVPixelFormatType_64ARGB, kCVPixelFormatType_64RGBALE, kCVPixelFormatType_64RGBAHalf,
        kCVPixelFormatType_OneComponent32Float, kCVPixelFormatType_TwoComponent16,
        kCVPixelFormatType_TwoComponent16Half, kCVPixelFormatType_DepthFloat32,
        kCVPixelFormatType_DisparityFloat32:
        return _CVFormatLayout(isPlanar: false, planes: [(1, 1, 8)])
    case kCVPixelFormatType_TwoComponent32Float, kCVPixelFormatType_128RGBAFloat:
        return _CVFormatLayout(isPlanar: false, planes: [(1, 1, 16)])
    case kCVPixelFormatType_422YpCbCr8, kCVPixelFormatType_422YpCbCr8_yuvs,
        kCVPixelFormatType_422YpCbCr8FullRange:
        return _CVFormatLayout(isPlanar: false, planes: [(1, 1, 2)])
    case kCVPixelFormatType_444YpCbCr8:
        return _CVFormatLayout(isPlanar: false, planes: [(1, 1, 3)])
    case kCVPixelFormatType_4444YpCbCrA8, kCVPixelFormatType_4444YpCbCrA8R,
        kCVPixelFormatType_4444AYpCbCr8:
        return _CVFormatLayout(isPlanar: false, planes: [(1, 1, 4)])
    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
        return _CVFormatLayout(isPlanar: true, planes: [(1, 1, 1), (2, 2, 2)])
    case kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange,
        kCVPixelFormatType_422YpCbCr8BiPlanarFullRange:
        return _CVFormatLayout(isPlanar: true, planes: [(1, 1, 1), (2, 1, 2)])
    case kCVPixelFormatType_444YpCbCr8BiPlanarVideoRange,
        kCVPixelFormatType_444YpCbCr8BiPlanarFullRange:
        return _CVFormatLayout(isPlanar: true, planes: [(1, 1, 1), (1, 1, 2)])
    case kCVPixelFormatType_420YpCbCr8Planar, kCVPixelFormatType_420YpCbCr8PlanarFullRange:
        return _CVFormatLayout(isPlanar: true, planes: [(1, 1, 1), (2, 2, 1), (2, 2, 1)])
    case kCVPixelFormatType_420YpCbCr8VideoRange_8A_TriPlanar:
        return _CVFormatLayout(isPlanar: true, planes: [(1, 1, 1), (2, 2, 2), (1, 1, 1)])
    default:
        return nil
    }
}

func _cvInt(_ dictionary: NSDictionary?, _ key: CFString) -> Int? {
    (dictionary?.object(forKey: key) as? NSNumber)?.intValue
}

func _cvBool(_ dictionary: NSDictionary?, _ key: CFString) -> Bool? {
    (dictionary?.object(forKey: key) as? NSNumber)?.boolValue
}

func _cvBuildPixelStorage(
    width: Int,
    height: Int,
    pixelFormat: OSType,
    attributes: NSDictionary?,
    externalBase: UnsafeMutableRawPointer?,
    externalBytesPerRow: Int?,
    releaseBytes: CVPixelBufferReleaseBytesCallback?,
    releasePlanar: CVPixelBufferReleasePlanarBytesCallback?,
    releaseRefCon: UnsafeMutableRawPointer?,
    outStorage: inout _CVPixelStorage?
) -> CVReturn {
    guard width > 0, height > 0 else { return kCVReturnInvalidSize }
    guard let layout = _cvLayout(for: pixelFormat) else { return kCVReturnInvalidPixelFormat }

    let extraLeft = max(0, _cvInt(attributes, kCVPixelBufferExtendedPixelsLeftKey) ?? 0)
    let extraRight = max(0, _cvInt(attributes, kCVPixelBufferExtendedPixelsRightKey) ?? 0)
    let extraTop = max(0, _cvInt(attributes, kCVPixelBufferExtendedPixelsTopKey) ?? 0)
    let extraBottom = max(0, _cvInt(attributes, kCVPixelBufferExtendedPixelsBottomKey) ?? 0)
    let rowAlign = max(1, _cvInt(attributes, kCVPixelBufferBytesPerRowAlignmentKey) ?? 16)
    let planeAlign = max(1, _cvInt(attributes, kCVPixelBufferPlaneAlignmentKey) ?? 16)

    let headerSize: Int
    if layout.isPlanar {
        headerSize = layout.planes.count <= 2
            ? MemoryLayout<CVPlanarPixelBufferInfo_YCbCrBiPlanar>.stride
            : MemoryLayout<CVPlanarPixelBufferInfo_YCbCrPlanar>.stride
    } else {
        headerSize = 0
    }

    var planes: [_CVPlane] = []
    var cursor = _cvAlign(headerSize, planeAlign)
    for desc in layout.planes {
        let planeWidth = max(1, (width + extraLeft + extraRight) / desc.widthDiv)
        let planeHeight = max(1, (height + extraTop + extraBottom) / desc.heightDiv)
        let minRow: Int
        if let externalBytesPerRow, !layout.isPlanar {
            minRow = externalBytesPerRow
        } else {
            minRow = planeWidth * desc.bytesPerPixel
        }
        let bytesPerRow = _cvAlign(minRow, rowAlign)
        planes.append(
            _CVPlane(
                width: width / desc.widthDiv,
                height: height / desc.heightDiv,
                bytesPerRow: bytesPerRow,
                offset: cursor
            )
        )
        cursor = _cvAlign(cursor + bytesPerRow * planeHeight, planeAlign)
    }

    let creation = NSMutableDictionary()
    creation[kCVPixelBufferPixelFormatTypeKey] = _cvNumber(pixelFormat)
    creation[kCVPixelBufferWidthKey] = _cvNumber(width)
    creation[kCVPixelBufferHeightKey] = _cvNumber(height)
    if extraLeft != 0 { creation[kCVPixelBufferExtendedPixelsLeftKey] = _cvNumber(extraLeft) }
    if extraRight != 0 { creation[kCVPixelBufferExtendedPixelsRightKey] = _cvNumber(extraRight) }
    if extraTop != 0 { creation[kCVPixelBufferExtendedPixelsTopKey] = _cvNumber(extraTop) }
    if extraBottom != 0 {
        creation[kCVPixelBufferExtendedPixelsBottomKey] = _cvNumber(extraBottom)
    }
    creation[kCVPixelBufferBytesPerRowAlignmentKey] = _cvNumber(rowAlign)
    creation[kCVPixelBufferPlaneAlignmentKey] = _cvNumber(planeAlign)

    let owned: UnsafeMutableRawPointer?
    if externalBase == nil {
        let bytes = max(cursor, 1)
        let memory = UnsafeMutableRawPointer.allocate(byteCount: bytes, alignment: 16)
        memory.initializeMemory(as: UInt8.self, repeating: 0, count: bytes)
        owned = memory
    } else {
        owned = nil
    }

    let storage = _CVPixelStorage(
        pixelFormat: pixelFormat,
        width: width,
        height: height,
        extraLeft: extraLeft,
        extraRight: extraRight,
        extraTop: extraTop,
        extraBottom: extraBottom,
        bytesPerRowAlignment: rowAlign,
        planeAlignment: planeAlign,
        isPlanar: layout.isPlanar,
        planes: planes,
        dataSize: cursor,
        headerSize: headerSize,
        owned: owned,
        externalBase: externalBase,
        releaseBytes: releaseBytes,
        releasePlanar: releasePlanar,
        releaseRefCon: releaseRefCon,
        creationAttributes: creation
    )

    if layout.isPlanar, let base = storage.base {
        if planes.count == 2 {
            var info = CVPlanarPixelBufferInfo_YCbCrBiPlanar(
                componentInfoY: CVPlanarComponentInfo(
                    offset: Int32(planes[0].offset),
                    rowBytes: UInt32(planes[0].bytesPerRow)
                ),
                componentInfoCbCr: CVPlanarComponentInfo(
                    offset: Int32(planes[1].offset),
                    rowBytes: UInt32(planes[1].bytesPerRow)
                )
            )
            withUnsafeBytes(of: &info) { raw in
                base.copyMemory(from: raw.baseAddress!, byteCount: raw.count)
            }
        } else if planes.count >= 3 {
            var info = CVPlanarPixelBufferInfo_YCbCrPlanar(
                componentInfoY: CVPlanarComponentInfo(
                    offset: Int32(planes[0].offset),
                    rowBytes: UInt32(planes[0].bytesPerRow)
                ),
                componentInfoCb: CVPlanarComponentInfo(
                    offset: Int32(planes[1].offset),
                    rowBytes: UInt32(planes[1].bytesPerRow)
                ),
                componentInfoCr: CVPlanarComponentInfo(
                    offset: Int32(planes[2].offset),
                    rowBytes: UInt32(planes[2].bytesPerRow)
                )
            )
            withUnsafeBytes(of: &info) { raw in
                base.copyMemory(from: raw.baseAddress!, byteCount: raw.count)
            }
        }
    }

    outStorage = storage
    return kCVReturnSuccess
}

public func CVPixelBufferCreate(
    _ allocator: CFAllocator?,
    _ width: Int,
    _ height: Int,
    _ pixelFormatType: OSType,
    _ pixelBufferAttributes: CFDictionary?,
    _ pixelBufferOut: UnsafeMutablePointer<CVPixelBuffer?>
) -> CVReturn {
    _ = allocator
    var storage: _CVPixelStorage?
    let status = _cvBuildPixelStorage(
        width: width,
        height: height,
        pixelFormat: pixelFormatType,
        attributes: pixelBufferAttributes as NSDictionary?,
        externalBase: nil,
        externalBytesPerRow: nil,
        releaseBytes: nil,
        releasePlanar: nil,
        releaseRefCon: nil,
        outStorage: &storage
    )
    guard status == kCVReturnSuccess, let storage else {
        pixelBufferOut.pointee = nil
        return status
    }
    let buffer = CVBuffer()
    buffer.pixels = storage
    pixelBufferOut.pointee = buffer
    return kCVReturnSuccess
}

public func CVPixelBufferCreateWithBytes(
    _ allocator: CFAllocator?,
    _ width: Int,
    _ height: Int,
    _ pixelFormatType: OSType,
    _ baseAddress: UnsafeMutableRawPointer,
    _ bytesPerRow: Int,
    _ releaseCallback: CVPixelBufferReleaseBytesCallback?,
    _ releaseRefCon: UnsafeMutableRawPointer?,
    _ pixelBufferAttributes: CFDictionary?,
    _ pixelBufferOut: UnsafeMutablePointer<CVPixelBuffer?>
) -> CVReturn {
    _ = allocator
    var storage: _CVPixelStorage?
    let status = _cvBuildPixelStorage(
        width: width,
        height: height,
        pixelFormat: pixelFormatType,
        attributes: pixelBufferAttributes as NSDictionary?,
        externalBase: baseAddress,
        externalBytesPerRow: bytesPerRow,
        releaseBytes: releaseCallback,
        releasePlanar: nil,
        releaseRefCon: releaseRefCon,
        outStorage: &storage
    )
    guard status == kCVReturnSuccess, let storage else {
        pixelBufferOut.pointee = nil
        return status
    }
    if storage.isPlanar {
        pixelBufferOut.pointee = nil
        return kCVReturnInvalidPixelFormat
    }
    storage.planes[0].bytesPerRow = bytesPerRow
    storage.planes[0].offset = 0
    storage.headerSize = 0
    let buffer = CVBuffer()
    buffer.pixels = storage
    pixelBufferOut.pointee = buffer
    return kCVReturnSuccess
}

public func CVPixelBufferCreateWithPlanarBytes(
    _ allocator: CFAllocator?,
    _ width: Int,
    _ height: Int,
    _ pixelFormatType: OSType,
    _ dataPtr: UnsafeMutableRawPointer?,
    _ dataSize: Int,
    _ numberOfPlanes: Int,
    _ planeBaseAddress: UnsafeMutablePointer<UnsafeMutableRawPointer?>,
    _ planeWidth: UnsafeMutablePointer<Int>,
    _ planeHeight: UnsafeMutablePointer<Int>,
    _ planeBytesPerRow: UnsafeMutablePointer<Int>,
    _ releaseCallback: CVPixelBufferReleasePlanarBytesCallback?,
    _ releaseRefCon: UnsafeMutableRawPointer?,
    _ pixelBufferAttributes: CFDictionary?,
    _ pixelBufferOut: UnsafeMutablePointer<CVPixelBuffer?>
) -> CVReturn {
    _ = allocator
    _ = dataSize
    var storage: _CVPixelStorage?
    let status = _cvBuildPixelStorage(
        width: width,
        height: height,
        pixelFormat: pixelFormatType,
        attributes: pixelBufferAttributes as NSDictionary?,
        externalBase: dataPtr ?? planeBaseAddress.pointee,
        externalBytesPerRow: nil,
        releaseBytes: nil,
        releasePlanar: releaseCallback,
        releaseRefCon: releaseRefCon,
        outStorage: &storage
    )
    guard status == kCVReturnSuccess, let storage else {
        pixelBufferOut.pointee = nil
        return status
    }
    guard storage.isPlanar, storage.planes.count == numberOfPlanes else {
        pixelBufferOut.pointee = nil
        return kCVReturnInvalidPixelFormat
    }
    for index in 0..<numberOfPlanes {
        storage.planes[index].width = planeWidth[index]
        storage.planes[index].height = planeHeight[index]
        storage.planes[index].bytesPerRow = planeBytesPerRow[index]
        if let plane = planeBaseAddress[index], let base = storage.base {
            storage.planes[index].offset = plane - base
        }
    }
    let buffer = CVBuffer()
    buffer.pixels = storage
    pixelBufferOut.pointee = buffer
    return kCVReturnSuccess
}

public func CVPixelBufferCreateWithIOSurface(
    _ allocator: CFAllocator?,
    _ surface: IOSurfaceRef,
    _ pixelBufferAttributes: CFDictionary?,
    _ pixelBufferOut: UnsafeMutablePointer<Unmanaged<CVPixelBuffer>?>
) -> CVReturn {
    _ = allocator
    _ = surface
    _ = pixelBufferAttributes
    pixelBufferOut.pointee = nil
    return kCVReturnUnsupported
}

public func CVPixelBufferGetIOSurface(_ pixelBuffer: CVPixelBuffer?) -> Unmanaged<IOSurfaceRef>? {
    _ = pixelBuffer
    return nil
}

public func CVPixelBufferLockBaseAddress(
    _ pixelBuffer: CVPixelBuffer,
    _ lockFlags: CVPixelBufferLockFlags
) -> CVReturn {
    _ = lockFlags
    guard pixelBuffer.pixels != nil else { return kCVReturnInvalidArgument }
    pixelBuffer.lock.lock()
    pixelBuffer.pixels?.lockCount += 1
    pixelBuffer.lock.unlock()
    return kCVReturnSuccess
}

public func CVPixelBufferUnlockBaseAddress(
    _ pixelBuffer: CVPixelBuffer,
    _ unlockFlags: CVPixelBufferLockFlags
) -> CVReturn {
    _ = unlockFlags
    pixelBuffer.lock.lock()
    defer { pixelBuffer.lock.unlock() }
    guard let pixels = pixelBuffer.pixels, pixels.lockCount > 0 else {
        return kCVReturnError
    }
    pixels.lockCount -= 1
    return kCVReturnSuccess
}

public func CVPixelBufferGetWidth(_ pixelBuffer: CVPixelBuffer) -> Int {
    pixelBuffer.pixels?.width ?? 0
}

public func CVPixelBufferGetHeight(_ pixelBuffer: CVPixelBuffer) -> Int {
    pixelBuffer.pixels?.height ?? 0
}

public func CVPixelBufferGetPixelFormatType(_ pixelBuffer: CVPixelBuffer) -> OSType {
    pixelBuffer.pixels?.pixelFormat ?? 0
}

public func CVPixelBufferIsPlanar(_ pixelBuffer: CVPixelBuffer) -> Bool {
    pixelBuffer.pixels?.isPlanar ?? false
}

public func CVPixelBufferGetPlaneCount(_ pixelBuffer: CVPixelBuffer) -> Int {
    guard let pixels = pixelBuffer.pixels, pixels.isPlanar else { return 0 }
    return pixels.planes.count
}

public func CVPixelBufferGetDataSize(_ pixelBuffer: CVPixelBuffer) -> Int {
    pixelBuffer.pixels?.dataSize ?? 0
}

public func CVPixelBufferGetBytesPerRow(_ pixelBuffer: CVPixelBuffer) -> Int {
    pixelBuffer.pixels?.planes.first?.bytesPerRow ?? 0
}

public func CVPixelBufferGetBaseAddress(_ pixelBuffer: CVPixelBuffer) -> UnsafeMutableRawPointer? {
    pixelBuffer.pixels?.base
}

public func CVPixelBufferGetWidthOfPlane(_ pixelBuffer: CVPixelBuffer, _ planeIndex: Int) -> Int {
    guard let pixels = pixelBuffer.pixels, pixels.isPlanar,
        pixels.planes.indices.contains(planeIndex)
    else { return 0 }
    return pixels.planes[planeIndex].width
}

public func CVPixelBufferGetHeightOfPlane(_ pixelBuffer: CVPixelBuffer, _ planeIndex: Int) -> Int {
    guard let pixels = pixelBuffer.pixels, pixels.isPlanar,
        pixels.planes.indices.contains(planeIndex)
    else { return 0 }
    return pixels.planes[planeIndex].height
}

public func CVPixelBufferGetBytesPerRowOfPlane(_ pixelBuffer: CVPixelBuffer, _ planeIndex: Int) -> Int {
    guard let pixels = pixelBuffer.pixels, pixels.isPlanar,
        pixels.planes.indices.contains(planeIndex)
    else { return 0 }
    return pixels.planes[planeIndex].bytesPerRow
}

public func CVPixelBufferGetBaseAddressOfPlane(
    _ pixelBuffer: CVPixelBuffer,
    _ planeIndex: Int
) -> UnsafeMutableRawPointer? {
    pixelBuffer.pixels?.planeAddress(planeIndex)
}

public func CVPixelBufferGetExtendedPixels(
    _ pixelBuffer: CVPixelBuffer,
    _ extraColumnsOnLeft: UnsafeMutablePointer<Int>?,
    _ extraColumnsOnRight: UnsafeMutablePointer<Int>?,
    _ extraRowsOnTop: UnsafeMutablePointer<Int>?,
    _ extraRowsOnBottom: UnsafeMutablePointer<Int>?
) {
    let pixels = pixelBuffer.pixels
    extraColumnsOnLeft?.pointee = pixels?.extraLeft ?? 0
    extraColumnsOnRight?.pointee = pixels?.extraRight ?? 0
    extraRowsOnTop?.pointee = pixels?.extraTop ?? 0
    extraRowsOnBottom?.pointee = pixels?.extraBottom ?? 0
}

public func CVPixelBufferFillExtendedPixels(_ pixelBuffer: CVPixelBuffer) -> CVReturn {
    guard let pixels = pixelBuffer.pixels else { return kCVReturnInvalidArgument }
    if pixels.extraLeft == 0, pixels.extraRight == 0, pixels.extraTop == 0, pixels.extraBottom == 0 {
        return kCVReturnSuccess
    }
    // Edge replication for packed 32-bit formats; other formats stay fail-closed.
    guard !pixels.isPlanar, pixels.planes.first?.bytesPerRow != nil,
        [kCVPixelFormatType_32BGRA, kCVPixelFormatType_32ARGB, kCVPixelFormatType_32RGBA,
            kCVPixelFormatType_32ABGR].contains(pixels.pixelFormat),
        let base = pixels.base
    else {
        return kCVReturnSuccess
    }
    let bytesPerPixel = 4
    let rowBytes = pixels.planes[0].bytesPerRow
    let width = pixels.width
    let height = pixels.height
    for row in 0..<height {
        let rowPtr = base.advanced(by: (row + pixels.extraTop) * rowBytes)
        let origin = rowPtr.advanced(by: pixels.extraLeft * bytesPerPixel)
        for col in 0..<pixels.extraLeft {
            origin.copyMemory(
                from: origin,
                byteCount: bytesPerPixel
            )
            origin.advanced(by: -(col + 1) * bytesPerPixel)
                .copyMemory(from: origin, byteCount: bytesPerPixel)
        }
        let last = origin.advanced(by: (width - 1) * bytesPerPixel)
        for col in 0..<pixels.extraRight {
            last.advanced(by: (col + 1) * bytesPerPixel)
                .copyMemory(from: last, byteCount: bytesPerPixel)
        }
    }
    _ = rowBytes
    return kCVReturnSuccess
}

public func CVPixelBufferCopyCreationAttributes(_ pixelBuffer: CVPixelBuffer) -> CFDictionary {
    if let attributes = pixelBuffer.pixels?.creationAttributes {
        return _cvCopyDictionary(attributes)
    }
    return NSDictionary()
}

public func CVPixelBufferIsCompatibleWithAttributes(
    _ pixelBuffer: CVPixelBuffer,
    _ attributes: CFDictionary?
) -> Bool {
    guard let attributes = attributes as NSDictionary? else { return true }
    guard let pixels = pixelBuffer.pixels else { return false }
    if let width = _cvInt(attributes, kCVPixelBufferWidthKey), width != pixels.width {
        return false
    }
    if let height = _cvInt(attributes, kCVPixelBufferHeightKey), height != pixels.height {
        return false
    }
    if let format = attributes.object(forKey: kCVPixelBufferPixelFormatTypeKey) as? NSNumber,
        format.uint32Value != pixels.pixelFormat
    {
        return false
    }
    return true
}

public func CVPixelBufferCreateResolvedAttributesDictionary(
    _ allocator: CFAllocator?,
    _ attributes: CFArray?,
    _ resolvedDictionaryOut: UnsafeMutablePointer<CFDictionary?>
) -> CVReturn {
    _ = allocator
    let merged = NSMutableDictionary()
    if let attributes = attributes as NSArray? {
        for case let dict as NSDictionary in attributes {
            dict.enumerateKeysAndObjects { key, value, _ in
                if let key = key as? NSString {
                    merged[key] = value
                }
            }
        }
    }
    resolvedDictionaryOut.pointee = merged
    return kCVReturnSuccess
}

public func CVImageBufferGetEncodedSize(_ imageBuffer: CVImageBuffer) -> CGSize {
    CGSize(
        width: CGFloat(CVPixelBufferGetWidth(imageBuffer)),
        height: CGFloat(CVPixelBufferGetHeight(imageBuffer))
    )
}

public func CVImageBufferGetDisplaySize(_ imageBuffer: CVImageBuffer) -> CGSize {
    if let dict = CVBufferCopyAttachment(imageBuffer, kCVImageBufferDisplayDimensionsKey, nil)
        as? NSDictionary
    {
        let width = (dict.object(forKey: kCVImageBufferDisplayWidthKey) as? NSNumber)?.doubleValue
        let height = (dict.object(forKey: kCVImageBufferDisplayHeightKey) as? NSNumber)?.doubleValue
        if let width, let height {
            return CGSize(width: width, height: height)
        }
    }
    return CVImageBufferGetEncodedSize(imageBuffer)
}

public func CVImageBufferGetCleanRect(_ imageBuffer: CVImageBuffer) -> CGRect {
    let width = CVPixelBufferGetWidth(imageBuffer)
    let height = CVPixelBufferGetHeight(imageBuffer)
    var left = 0
    var right = 0
    var top = 0
    var bottom = 0
    CVPixelBufferGetExtendedPixels(imageBuffer, &left, &right, &top, &bottom)
    if let dict = CVBufferCopyAttachment(imageBuffer, kCVImageBufferCleanApertureKey, nil)
        as? NSDictionary
    {
        let w = (dict.object(forKey: kCVImageBufferCleanApertureWidthKey) as? NSNumber)?.doubleValue
            ?? Double(width)
        let h = (dict.object(forKey: kCVImageBufferCleanApertureHeightKey) as? NSNumber)?.doubleValue
            ?? Double(height)
        let x = (dict.object(forKey: kCVImageBufferCleanApertureHorizontalOffsetKey) as? NSNumber)?
            .doubleValue ?? 0
        let y = (dict.object(forKey: kCVImageBufferCleanApertureVerticalOffsetKey) as? NSNumber)?
            .doubleValue ?? 0
        return CGRect(x: x, y: y, width: w, height: h)
    }
    return CGRect(x: 0, y: 0, width: width, height: height)
}

public func CVImageBufferIsFlipped(_ imageBuffer: CVImageBuffer) -> Bool {
    imageBuffer.pixels?.originFlipped ?? false
}

public func CVImageBufferGetColorSpace(_ imageBuffer: CVImageBuffer) -> Unmanaged<CGColorSpace>? {
    _ = imageBuffer
    return nil
}

public func CVImageBufferCreateColorSpaceFromAttachments(
    _ attachments: CFDictionary
) -> Unmanaged<CGColorSpace>? {
    _ = attachments
    return nil
}
