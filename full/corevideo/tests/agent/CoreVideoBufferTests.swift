import CoreVideo
import Foundation

private func makeBGRA(_ width: Int = 16, _ height: Int = 8) -> CVPixelBuffer {
    var buffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, nil, &buffer)
    precondition(status == kCVReturnSuccess)
    return buffer!
}

func testBufferAttachments() {
    let buffer = makeBGRA()
    CVBufferSetAttachment(
        buffer,
        kCVImageBufferYCbCrMatrixKey,
        kCVImageBufferYCbCrMatrix_ITU_R_709_2,
        .shouldPropagate
    )
    precondition(CVBufferHasAttachment(buffer, kCVImageBufferYCbCrMatrixKey))
    var mode = CVAttachmentMode.shouldNotPropagate
    let copied = CVBufferCopyAttachment(buffer, kCVImageBufferYCbCrMatrixKey, &mode)
    precondition(mode == .shouldPropagate)
    precondition((copied as? NSString) as String? == (kCVImageBufferYCbCrMatrix_ITU_R_709_2 as String))
    let got = CVBufferGetAttachment(buffer, kCVImageBufferYCbCrMatrixKey, &mode)
    precondition(got != nil)
    CVBufferSetAttachments(
        buffer,
        [kCVImageBufferColorPrimariesKey: kCVImageBufferColorPrimaries_ITU_R_709_2] as NSDictionary,
        .shouldNotPropagate
    )
    let propagated = CVBufferCopyAttachments(buffer, .shouldPropagate)
    precondition(propagated != nil)
    let nonPropagated = CVBufferGetAttachments(buffer, .shouldNotPropagate)
    precondition(nonPropagated != nil)
    let dest = makeBGRA()
    CVBufferPropagateAttachments(buffer, dest)
    precondition(CVBufferHasAttachment(dest, kCVImageBufferYCbCrMatrixKey))
    CVBufferRemoveAttachment(buffer, kCVImageBufferYCbCrMatrixKey)
    precondition(!CVBufferHasAttachment(buffer, kCVImageBufferYCbCrMatrixKey))
    CVBufferRemoveAllAttachments(buffer)
    precondition(CVBufferCopyAttachments(buffer, .shouldNotPropagate) == nil)
}

func testPixelBufferCreatePacked() {
    var buffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(nil, 16, 8, kCVPixelFormatType_32BGRA, nil, &buffer)
    precondition(status == kCVReturnSuccess)
    guard let buffer else { preconditionFailure("buffer") }
    precondition(CVPixelBufferGetWidth(buffer) == 16)
    precondition(CVPixelBufferGetHeight(buffer) == 8)
    precondition(CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA)
    precondition(CVPixelBufferIsPlanar(buffer) == false)
    precondition(CVPixelBufferGetPlaneCount(buffer) == 0)
    precondition(CVPixelBufferGetBytesPerRow(buffer) >= 16 * 4)
    precondition(CVPixelBufferGetDataSize(buffer) > 0)
    var rejected: CVPixelBuffer?
    precondition(
        CVPixelBufferCreate(nil, 0, 8, kCVPixelFormatType_32BGRA, nil, &rejected)
            == kCVReturnInvalidSize
    )
}

func testPixelBufferCreatePlanar() {
    var yuv: CVPixelBuffer?
    precondition(
        CVPixelBufferCreate(
            nil,
            32,
            16,
            kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            nil,
            &yuv
        ) == kCVReturnSuccess
    )
    precondition(CVPixelBufferIsPlanar(yuv!) == true)
    precondition(CVPixelBufferGetPlaneCount(yuv!) == 2)
    precondition(CVPixelBufferGetWidthOfPlane(yuv!, 0) == 32)
    precondition(CVPixelBufferGetHeightOfPlane(yuv!, 0) == 16)
    precondition(CVPixelBufferGetWidthOfPlane(yuv!, 1) == 16)
    precondition(CVPixelBufferGetHeightOfPlane(yuv!, 1) == 8)
    precondition(CVPixelBufferGetBytesPerRowOfPlane(yuv!, 0) >= 32)
    precondition(CVPixelBufferGetBaseAddressOfPlane(yuv!, 0) != nil)
    precondition(CVPixelBufferGetBaseAddressOfPlane(yuv!, 1) != nil)
}

func testPixelBufferLockAndBytes() {
    let buffer = makeBGRA()
    precondition(CVPixelBufferLockBaseAddress(buffer, []) == kCVReturnSuccess)
    guard let base = CVPixelBufferGetBaseAddress(buffer) else { preconditionFailure("base") }
    base.storeBytes(of: UInt32(0xAABB_CCDD), as: UInt32.self)
    precondition(base.load(as: UInt32.self) == 0xAABB_CCDD)
    precondition(CVPixelBufferUnlockBaseAddress(buffer, []) == kCVReturnSuccess)
    precondition(CVPixelBufferLockBaseAddress(buffer, .readOnly) == kCVReturnSuccess)
    precondition(CVPixelBufferUnlockBaseAddress(buffer, .readOnly) == kCVReturnSuccess)
}

func testPixelBufferCreateWithBytes() {
    let width = 4
    let height = 2
    let row = 16
    let storage = UnsafeMutableRawPointer.allocate(byteCount: row * height, alignment: 16)
    storage.initializeMemory(as: UInt8.self, repeating: 7, count: row * height)
    var buffer: CVPixelBuffer?
    let status = CVPixelBufferCreateWithBytes(
        nil,
        width,
        height,
        kCVPixelFormatType_32BGRA,
        storage,
        row,
        { _, pointer in
            pointer?.deallocate()
        },
        nil,
        nil,
        &buffer
    )
    precondition(status == kCVReturnSuccess)
    precondition(CVPixelBufferGetBytesPerRow(buffer!) == row)
}

func testPixelBufferCreateWithPlanarBytes() {
    let yRow = 32
    let uvRow = 32
    let yHeight = 16
    let total = yRow * yHeight + uvRow * 8
    let storage = UnsafeMutableRawPointer.allocate(byteCount: total, alignment: 16)
    storage.initializeMemory(as: UInt8.self, repeating: 16, count: total)
    var bases: [UnsafeMutableRawPointer?] = [storage, storage.advanced(by: yRow * yHeight)]
    var widths: [Int] = [32, 16]
    var heights: [Int] = [16, 8]
    var rows: [Int] = [yRow, uvRow]
    var buffer: CVPixelBuffer?
    let status = bases.withUnsafeMutableBufferPointer { basePtr in
        widths.withUnsafeMutableBufferPointer { widthPtr in
            heights.withUnsafeMutableBufferPointer { heightPtr in
                rows.withUnsafeMutableBufferPointer { rowPtr in
                    CVPixelBufferCreateWithPlanarBytes(
                        nil,
                        32,
                        16,
                        kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                        storage,
                        total,
                        2,
                        basePtr.baseAddress!,
                        widthPtr.baseAddress!,
                        heightPtr.baseAddress!,
                        rowPtr.baseAddress!,
                        nil,
                        nil,
                        nil,
                        &buffer
                    )
                }
            }
        }
    }
    precondition(status == kCVReturnSuccess)
    storage.deallocate()
}

func testPixelBufferExtendedPixels() {
    let attrs: NSDictionary = [
        kCVPixelBufferExtendedPixelsLeftKey: 2,
        kCVPixelBufferExtendedPixelsRightKey: 2,
        kCVPixelBufferExtendedPixelsTopKey: 1,
        kCVPixelBufferExtendedPixelsBottomKey: 1,
    ]
    var buffer: CVPixelBuffer?
    precondition(
        CVPixelBufferCreate(nil, 8, 8, kCVPixelFormatType_32BGRA, attrs, &buffer)
            == kCVReturnSuccess
    )
    var left = 0
    var right = 0
    var top = 0
    var bottom = 0
    CVPixelBufferGetExtendedPixels(buffer!, &left, &right, &top, &bottom)
    precondition(left == 2 && right == 2 && top == 1 && bottom == 1)
    precondition(CVPixelBufferFillExtendedPixels(buffer!) == kCVReturnSuccess)
}

func testPixelBufferIOSurfaceFailClosed() {
    var surfaceOut: Unmanaged<CVPixelBuffer>?
    precondition(
        CVPixelBufferCreateWithIOSurface(nil, IOSurface(), nil, &surfaceOut)
            == kCVReturnUnsupported
    )
    let buffer = makeBGRA()
    precondition(CVPixelBufferGetIOSurface(buffer) == nil)
}

func testPixelBufferCompatibilityAndResolved() {
    let buffer = makeBGRA()
    let attrs = CVPixelBufferCopyCreationAttributes(buffer)
    precondition((attrs as NSDictionary).object(forKey: kCVPixelBufferWidthKey) != nil)
    precondition(CVPixelBufferIsCompatibleWithAttributes(buffer, attrs))
    var resolved: CFDictionary?
    precondition(
        CVPixelBufferCreateResolvedAttributesDictionary(nil, nil, &resolved)
            == kCVReturnSuccess
    )
    precondition(resolved != nil)
    var out: CFDictionary?
    precondition(
        CVPixelBufferCreateResolvedAttributesDictionary(nil, [attrs] as NSArray, &out)
            == kCVReturnSuccess
    )
}

func testImageBufferQueries() {
    let buffer = makeBGRA()
    let encoded = CVImageBufferGetEncodedSize(buffer)
    precondition(encoded.width == 16 && encoded.height == 8)
    let display = CVImageBufferGetDisplaySize(buffer)
    precondition(display.width == 16)
    let clean = CVImageBufferGetCleanRect(buffer)
    precondition(clean.width == 16)
    precondition(CVImageBufferIsFlipped(buffer) == false)
    precondition(CVImageBufferGetColorSpace(buffer) == nil)
    precondition(CVImageBufferCreateColorSpaceFromAttachments(NSDictionary()) == nil)
}

func testBufferIdentityHashable() {
    let a = makeBGRA()
    let b = makeBGRA()
    precondition(a == a)
    precondition(a != b)
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = a.hashValue
}

func testTypealiases() {
    let _: CVImageBuffer.Type = CVBuffer.self
    let _: CVPixelBuffer.Type = CVBuffer.self
    let _: CVMetalBuffer.Type = CVBuffer.self
    let _: CVMetalTexture.Type = CVBuffer.self
    let _: CVOpenGLESTexture.Type = CVBuffer.self
    let _: CVOptionFlags = 1
    let _: CVReturn = kCVReturnSuccess
    let _: CVFillExtendedPixelsCallBack = { _, _ in true }
    let _: CVPixelBufferReleaseBytesCallback = { _, _ in }
    let _: CVPixelBufferReleasePlanarBytesCallback = { _, _, _, _, _ in }
    precondition(CVBuffer.OriginPosition.topLeft == CVImageBufferOriginPosition.topLeft)
    let size: CVBuffer.Size = CVImageSize(width: 1, height: 1)
    precondition(size.width == 1)
    let padding: CVBuffer.Padding = .zero
    precondition(padding.left == 0)
    let planes: CVBuffer.PlaneProperties = CVPixelBufferPlaneProperties(
        size: size,
        bytesPerRow: 4
    )
    precondition(planes.bytesPerRow == 4)
}
