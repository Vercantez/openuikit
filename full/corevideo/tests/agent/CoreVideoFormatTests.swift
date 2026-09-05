import CoreVideo
import Foundation

func testCFormatDescriptionRegistry() {
    let bgra = CVPixelFormatDescriptionCreateWithPixelFormatType(nil, kCVPixelFormatType_32BGRA)
    precondition(bgra != nil)
    let all = CVPixelFormatDescriptionArrayCreateWithAllPixelFormatTypes(nil)
    precondition((all as NSArray?)?.count ?? 0 >= 1)
    let extra = NSMutableDictionary()
    extra[kCVPixelFormatName] = "probe" as NSString
    extra[kCVPixelFormatConstant] = NSNumber(value: kCVPixelFormatType_24RGB)
    CVPixelFormatDescriptionRegisterDescriptionWithPixelFormatType(extra, kCVPixelFormatType_24RGB)
    precondition(
        CVPixelFormatDescriptionCreateWithPixelFormatType(nil, kCVPixelFormatType_24RGB) != nil
    )
}

func testSwiftFormatDescription() {
    let description = CVPixelFormatDescription(
        pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
        name: "BGRA",
        components: [.rgb, .alpha],
        componentRange: .full,
        planeConfiguration: .nonPlanar(
            .init(bitsPerBlock: 32, bitsPerComponent: 8)
        )
    )
    precondition(description.name == "BGRA")
    precondition(description.pixelFormatType.rawValue == kCVPixelFormatType_32BGRA)
    precondition(description.components.contains(.rgb))
    precondition(description.componentRange == .full)
    switch description.planeConfiguration {
    case .nonPlanar(let layout):
        precondition(layout.bitsPerBlock == 32)
    case .planar:
        preconditionFailure("expected packed")
    }
}

func testFormatOptionSetAlgebra() {
    var components = CVPixelFormatDescription.Components()
    precondition(components.isEmpty)
    _ = components.insert(.rgb)
    precondition(components.contains(.rgb))
    precondition(components.union(.alpha).contains(.alpha))
    precondition(components.intersection(.rgb) == .rgb)
    _ = components.symmetricDifference(.yCbCr)
    components.formUnion(.grayscale)
    components.formIntersection([.rgb, .grayscale])
    components.formSymmetricDifference(.senselArray)
    _ = components.remove(.senselArray)
    _ = components.update(with: .rgb)
    components.subtract(.grayscale)
    precondition(CVPixelFormatDescription.Components.rgb.isSubset(of: [.rgb, .alpha]))
    precondition(([.rgb, .alpha] as CVPixelFormatDescription.Components).isSuperset(of: .rgb))
    precondition(CVPixelFormatDescription.Components.rgb.isStrictSubset(of: [.rgb, .alpha]))
    precondition(
        ([.rgb, .alpha] as CVPixelFormatDescription.Components).isStrictSuperset(of: .rgb)
    )
    precondition(CVPixelFormatDescription.Components.rgb.isDisjoint(with: .alpha))
    precondition(CVPixelFormatDescription.Components(arrayLiteral: .rgb) == .rgb)
    precondition(CVPixelFormatDescription.Components([.alpha]) == .alpha)
    precondition(CVPixelFormatDescription.Components.rgb != .alpha)
    var hasher = Hasher()
    components.hash(into: &hasher)
    _ = components.hashValue

    var compat = CVPixelFormatDescription.Compatibility()
    precondition(compat.isEmpty)
    _ = compat.insert(.cgImage)
    precondition(compat.contains(.cgImage))
    precondition(compat.union(.cgBitmapContext).contains(.cgBitmapContext))
    precondition(compat.intersection(.cgImage) == .cgImage)
    _ = compat.symmetricDifference(.metalTexture)
    compat.formUnion(.ioSurfaceCoreAnimation)
    compat.formIntersection([.cgImage, .ioSurfaceCoreAnimation])
    compat.formSymmetricDifference(.metalTexture)
    _ = compat.remove(.metalTexture)
    _ = compat.update(with: .cgImage)
    compat.subtract([])
    precondition(CVPixelFormatDescription.Compatibility.cgImage.isSubset(of: [.cgImage, .metalTexture]))
    precondition(
        ([.cgImage, .metalTexture] as CVPixelFormatDescription.Compatibility).isSuperset(of: .cgImage)
    )
    precondition(
        CVPixelFormatDescription.Compatibility.cgImage.isStrictSubset(of: [.cgImage, .metalTexture])
    )
    precondition(
        ([.cgImage, .metalTexture] as CVPixelFormatDescription.Compatibility)
            .isStrictSuperset(of: .cgImage)
    )
    precondition(CVPixelFormatDescription.Compatibility.cgImage.isDisjoint(with: .metalTexture))
    precondition(CVPixelFormatDescription.Compatibility(arrayLiteral: .cgImage) == .cgImage)
    precondition(CVPixelFormatDescription.Compatibility([.metalTexture]) == .metalTexture)
    compat.hash(into: &hasher)
    _ = compat.hashValue
}

func testFormatComponentsAndCompatibility() {
    var components = CVPixelFormatDescription.Components()
    _ = components.insert(.rgb)
    components.formUnion(.alpha)
    precondition(components.contains(.yCbCr) == false)
    precondition(CVPixelFormatDescription.Components.grayscale.rawValue != 0)
    precondition(CVPixelFormatDescription.Components.senselArray.rawValue != 0)
    let _: CVPixelFormatDescription.Components.RawValue = components.rawValue
    let _: CVPixelFormatDescription.Components.Element = .rgb
    let _: CVPixelFormatDescription.Components.ArrayLiteralElement = .alpha
    var compat = CVPixelFormatDescription.Compatibility(rawValue: 0)
    _ = compat.insert(.cgImage)
    compat.formUnion(.cgBitmapContext)
    compat.formUnion(.metalTexture)
    compat.formUnion(.ioSurfaceCoreAnimation)
    precondition(compat.contains(.cgImage))
    let _: CVPixelFormatDescription.Compatibility.RawValue = compat.rawValue
    let _: CVPixelFormatDescription.Compatibility.Element = .cgImage
    let _: CVPixelFormatDescription.Compatibility.ArrayLiteralElement = .metalTexture
    precondition(
        CVPixelFormatDescription.Compatibility(arrayLiteral: .cgImage).contains(.cgImage)
    )
}

func testFormatLayoutAndRange() {
    let layout = CVPixelFormatDescription.PixelLayout(
        blockSize: CVImageSize(width: 1, height: 1),
        bitsPerBlock: 32,
        bitsPerComponent: 8,
        blockAlignment: .init(horizontal: 1, vertical: 1),
        subsampling: .init(horizontal: 1, vertical: 1),
        blackBlock: Data([0, 0, 0, 0]),
        fillExtendedPixels: { _ in },
        cgBitmapInfo: CGBitmapInfo(rawValue: 0)
    )
    precondition(layout.blockSize.width == 1)
    precondition(layout.bitsPerBlock == 32)
    precondition(layout.bitsPerComponent == 8)
    precondition(layout.blockAlignment.horizontal == 1)
    precondition(layout.subsampling.vertical == 1)
    precondition(layout.blackBlock?.count == 4)
    precondition(layout.fillExtendedPixels != nil)
    precondition(layout.cgBitmapInfo?.rawValue == 0)
    precondition(layout == layout)
    let other = CVPixelFormatDescription.PixelLayout(bitsPerBlock: 16)
    precondition(layout != other)
    precondition(CVPixelFormatDescription.ComponentRange.full != .video)
    precondition(CVPixelFormatDescription.ComponentRange.wide != .full)
    var hasher = Hasher()
    CVPixelFormatDescription.ComponentRange.full.hash(into: &hasher)
    _ = CVPixelFormatDescription.ComponentRange.full.hashValue
    let dimensions = CVPixelFormatDescription.Dimensions(horizontal: 2, vertical: 3)
    precondition(dimensions.horizontal == 2 && dimensions.vertical == 3)
    dimensions.hash(into: &hasher)
    _ = dimensions.hashValue
    precondition(dimensions == CVPixelFormatDescription.Dimensions(horizontal: 2, vertical: 3))
}

func testFormatRegistry() {
    let registry = CVPixelFormatDescription.Registry.shared
    let description = CVPixelFormatDescription(
        pixelFormatType: CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA),
        name: "BGRA",
        components: [.rgb, .alpha],
        planeConfiguration: .nonPlanar(.init(bitsPerBlock: 32, bitsPerComponent: 8))
    )
    registry.register(description)
    precondition(registry[CVPixelFormatType(rawValue: kCVPixelFormatType_32BGRA)] != nil)
    precondition(!registry.formatDescriptions.isEmpty)
}

func testColorCodePoints() {
    precondition(
        CVColorPrimariesGetIntegerCodePointForString(kCVImageBufferColorPrimaries_ITU_R_709_2) == 1
    )
    precondition(
        CVColorPrimariesGetIntegerCodePointForString(kCVImageBufferColorPrimaries_EBU_3213) == 5
    )
    precondition(CVColorPrimariesGetIntegerCodePointForString(nil) == 0)
    precondition(
        CVColorPrimariesGetStringForIntegerCodePoint(1)?.takeUnretainedValue() as String?
            == (kCVImageBufferColorPrimaries_ITU_R_709_2 as String)
            || CVColorPrimariesGetStringForIntegerCodePoint(1) != nil
    )
    precondition(
        CVTransferFunctionGetIntegerCodePointForString(
            kCVImageBufferTransferFunction_ITU_R_709_2
        ) == 1
    )
    precondition(CVTransferFunctionGetStringForIntegerCodePoint(16) != nil)
    precondition(
        CVYCbCrMatrixGetIntegerCodePointForString(kCVImageBufferYCbCrMatrix_ITU_R_709_2) == 1
    )
    precondition(CVYCbCrMatrixGetStringForIntegerCodePoint(6) != nil)
}

func testFourCharCodeString() {
    precondition(
        (CVPixelFormatTypeCopyFourCharCodeString(kCVPixelFormatType_32BGRA) as String) == "BGRA"
    )
    _ = CVPixelFormatTypeCopyFourCharCodeString(32)
}

func testCompressedFormatsUnavailable() {
    precondition(CVIsCompressedPixelFormatAvailable(kCVPixelFormatType_Lossless_32BGRA) == false)
    precondition(CVIsCompressedPixelFormatAvailable(kCVPixelFormatType_Lossy_32BGRA) == false)
    var rejected: CVPixelBuffer?
    precondition(
        CVPixelBufferCreate(nil, 8, 8, kCVPixelFormatType_Lossless_32BGRA, nil, &rejected)
            == kCVReturnInvalidPixelFormat
    )
}
