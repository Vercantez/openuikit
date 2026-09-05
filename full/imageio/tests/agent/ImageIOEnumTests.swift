import Foundation
import ImageIO

func testSourceStatusRawValues() {
    imageioRequire(CGImageSourceStatus.statusUnexpectedEOF.rawValue == -5, "eof")
    imageioRequire(CGImageSourceStatus.statusInvalidData.rawValue == -4, "invalid")
    imageioRequire(CGImageSourceStatus.statusUnknownType.rawValue == -3, "unknown")
    imageioRequire(CGImageSourceStatus.statusReadingHeader.rawValue == -2, "header")
    imageioRequire(CGImageSourceStatus.statusIncomplete.rawValue == -1, "incomplete")
    imageioRequire(CGImageSourceStatus.statusComplete.rawValue == 0, "complete")
    imageioRequire(CGImageSourceStatus(rawValue: 0) == .statusComplete, "init complete")
    imageioRequire(CGImageSourceStatus(rawValue: 99) == nil, "init unknown")
    imageioRequire(CGImageSourceStatus.statusComplete != .statusInvalidData, "neq")
    var hasher = Hasher()
    CGImageSourceStatus.statusComplete.hash(into: &hasher)
    imageioRequire(
        CGImageSourceStatus.statusComplete.hashValue == CGImageSourceStatus.statusComplete.hashValue,
        "hashValue"
    )
}

func testOrientationRawValues() {
    imageioRequire(CGImagePropertyOrientation.up.rawValue == 1, "up")
    imageioRequire(CGImagePropertyOrientation.upMirrored.rawValue == 2, "upMirrored")
    imageioRequire(CGImagePropertyOrientation.down.rawValue == 3, "down")
    imageioRequire(CGImagePropertyOrientation.downMirrored.rawValue == 4, "downMirrored")
    imageioRequire(CGImagePropertyOrientation.leftMirrored.rawValue == 5, "leftMirrored")
    imageioRequire(CGImagePropertyOrientation.right.rawValue == 6, "right")
    imageioRequire(CGImagePropertyOrientation.rightMirrored.rawValue == 7, "rightMirrored")
    imageioRequire(CGImagePropertyOrientation.left.rawValue == 8, "left")
    imageioRequire(CGImagePropertyOrientation(rawValue: 6) == .right, "init")
    imageioRequire(CGImagePropertyOrientation.up != .down, "neq")
    var hasher = Hasher()
    CGImagePropertyOrientation.up.hash(into: &hasher)
    _ = CGImagePropertyOrientation.up.hashValue
}

func testMetadataEnums() {
    imageioRequire(CGImageMetadataType.invalid.rawValue == -1, "invalid")
    imageioRequire(CGImageMetadataType.default.rawValue == 0, "default")
    imageioRequire(CGImageMetadataType.string.rawValue == 1, "string")
    imageioRequire(CGImageMetadataType.arrayUnordered.rawValue == 2, "unordered")
    imageioRequire(CGImageMetadataType.arrayOrdered.rawValue == 3, "ordered")
    imageioRequire(CGImageMetadataType.alternateArray.rawValue == 4, "alt array")
    imageioRequire(CGImageMetadataType.alternateText.rawValue == 5, "alt text")
    imageioRequire(CGImageMetadataType.structure.rawValue == 6, "structure")
    imageioRequire(CGImageMetadataType(rawValue: 1) == .string, "init")
    imageioRequire(CGImageMetadataErrors.unknown.rawValue == 0, "unknown")
    imageioRequire(CGImageMetadataErrors.unsupportedFormat.rawValue == 1, "unsupported")
    imageioRequire(CGImageMetadataErrors.badArgument.rawValue == 2, "bad")
    imageioRequire(CGImageMetadataErrors.conflictingArguments.rawValue == 3, "conflict")
    imageioRequire(CGImageMetadataErrors.prefixConflict.rawValue == 4, "prefix")
    imageioRequire(CGImageMetadataErrors(rawValue: 4) == .prefixConflict, "err init")
    imageioRequire(CGImageMetadataErrors.unknown != .badArgument, "neq")
    imageioRequire(CGImageMetadataType.string != .structure, "type neq")
    var hasher = Hasher()
    CGImageMetadataType.string.hash(into: &hasher)
    CGImageMetadataErrors.unknown.hash(into: &hasher)
    _ = CGImageMetadataType.string.hashValue
    _ = CGImageMetadataErrors.unknown.hashValue
}

func testAnimationStatusRawValues() {
    imageioRequire(CGImageAnimationStatus.parameterError.rawValue == -22140, "param")
    imageioRequire(CGImageAnimationStatus.corruptInputImage.rawValue == -22141, "corrupt")
    imageioRequire(CGImageAnimationStatus.unsupportedFormat.rawValue == -22142, "unsupported")
    imageioRequire(CGImageAnimationStatus.incompleteInputImage.rawValue == -22143, "incomplete")
    imageioRequire(CGImageAnimationStatus.allocationFailure.rawValue == -22144, "alloc")
    imageioRequire(CGImageAnimationStatus(rawValue: -22140) == .parameterError, "init")
    imageioRequire(CGImageAnimationStatus.parameterError != .allocationFailure, "neq")
    var hasher = Hasher()
    CGImageAnimationStatus.parameterError.hash(into: &hasher)
    _ = CGImageAnimationStatus.parameterError.hashValue
}

func testTGACompression() {
    imageioRequire(CGImagePropertyTGACompression.tgaCompressionNone.rawValue == 0, "none")
    imageioRequire(CGImagePropertyTGACompression.tgaCompressionRLE.rawValue == 1, "rle")
    imageioRequire(CGImagePropertyTGACompression(rawValue: 1) == .tgaCompressionRLE, "init")
    imageioRequire(
        CGImagePropertyTGACompression.tgaCompressionNone != .tgaCompressionRLE,
        "neq"
    )
    var hasher = Hasher()
    CGImagePropertyTGACompression.tgaCompressionNone.hash(into: &hasher)
    _ = CGImagePropertyTGACompression.tgaCompressionNone.hashValue
}

func testTypeIDs() {
    imageioRequire(CGImageSourceGetTypeID() != 0, "source")
    imageioRequire(CGImageDestinationGetTypeID() != 0, "dest")
    imageioRequire(CGImageMetadataGetTypeID() != 0, "meta")
    imageioRequire(CGImageMetadataTagGetTypeID() != 0, "tag")
    imageioRequire(CGImageSourceGetTypeID() != CGImageDestinationGetTypeID(), "distinct")
}

func testEqualityAndHash() {
    let a = CGImageSourceCreateIncremental(nil)
    let b = CGImageSourceCreateIncremental(nil)
    imageioRequire(a == a, "source eq")
    imageioRequire(a != b, "source neq")
    imageioRequire(a.hashValue == a.hashValue, "source hash")
    var hasher = Hasher()
    a.hash(into: &hasher)
    let destData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(destData, "public.png", 1, nil) else {
        fatalError("dest")
    }
    imageioRequire(dest == dest, "dest eq")
    guard let dest2 = CGImageDestinationCreateWithData(NSMutableData(), "public.png", 1, nil) else {
        fatalError("dest2")
    }
    imageioRequire(dest != dest2, "dest neq")
    dest.hash(into: &hasher)
    _ = dest.hashValue
    let meta = CGImageMetadataCreateMutable()
    let meta2 = CGImageMetadataCreateMutable()
    imageioRequire(meta == meta, "meta eq")
    imageioRequire(meta != meta2, "meta neq")
    meta.hash(into: &hasher)
    _ = meta.hashValue
    guard let tag = CGImageMetadataTagCreate("ns", "p", "n", .string, "v") else {
        fatalError("tag")
    }
    imageioRequire(tag == tag, "tag eq")
    guard let tag2 = CGImageMetadataTagCreate("ns", "p", "n", .string, "v") else {
        fatalError("tag2")
    }
    imageioRequire(tag != tag2, "tag neq")
    tag.hash(into: &hasher)
    _ = tag.hashValue
}

func testPNGFilterMacros() {
    // MEASURED 2026-09-05 Apple ImageIO Int32 macros.
    imageioRequire(IIO_HAS_IOSURFACE == 1, "IIO_HAS_IOSURFACE")
    imageioRequire(IMAGEIO_PNG_FILTER_AVG == 64, "IMAGEIO_PNG_FILTER_AVG")
    imageioRequire(IMAGEIO_PNG_FILTER_NONE == 8, "IMAGEIO_PNG_FILTER_NONE")
    imageioRequire(IMAGEIO_PNG_FILTER_PAETH == 128, "IMAGEIO_PNG_FILTER_PAETH")
    imageioRequire(IMAGEIO_PNG_FILTER_SUB == 16, "IMAGEIO_PNG_FILTER_SUB")
    imageioRequire(IMAGEIO_PNG_FILTER_UP == 32, "IMAGEIO_PNG_FILTER_UP")
    imageioRequire(IMAGEIO_PNG_NO_FILTERS == 0, "IMAGEIO_PNG_NO_FILTERS")
}
