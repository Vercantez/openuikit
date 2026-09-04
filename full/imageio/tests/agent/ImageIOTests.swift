import Foundation
import ImageIO

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

private func sampleImage() -> CGImage {
    let image = CGImage(width: 2, height: 1)
    image.pixels = [255, 0, 0, 255, 0, 255, 0, 255]
    return image
}

private func encodedSample(_ type: CFString) -> Data {
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(data, type, 1, nil) else {
        fatalError("destination \(type)")
    }
    CGImageDestinationAddImage(dest, sampleImage(), nil)
    require(CGImageDestinationFinalize(dest), "finalize \(type)")
    return data as Data
}

func testSourceStatusRawValues() {
    require(CGImageSourceStatus.statusUnexpectedEOF.rawValue == -5, "eof")
    require(CGImageSourceStatus.statusInvalidData.rawValue == -4, "invalid")
    require(CGImageSourceStatus.statusUnknownType.rawValue == -3, "unknown")
    require(CGImageSourceStatus.statusReadingHeader.rawValue == -2, "header")
    require(CGImageSourceStatus.statusIncomplete.rawValue == -1, "incomplete")
    require(CGImageSourceStatus.statusComplete.rawValue == 0, "complete")
    require(CGImageSourceStatus(rawValue: 0) == .statusComplete, "init complete")
    require(CGImageSourceStatus(rawValue: 99) == nil, "init unknown")
    require(CGImageSourceStatus.statusComplete != .statusInvalidData, "neq")
    var hasher = Hasher()
    CGImageSourceStatus.statusComplete.hash(into: &hasher)
    require(CGImageSourceStatus.statusComplete.hashValue == CGImageSourceStatus.statusComplete.hashValue, "hashValue")
}

func testOrientationRawValues() {
    require(CGImagePropertyOrientation.up.rawValue == 1, "up")
    require(CGImagePropertyOrientation.upMirrored.rawValue == 2, "upMirrored")
    require(CGImagePropertyOrientation.down.rawValue == 3, "down")
    require(CGImagePropertyOrientation.downMirrored.rawValue == 4, "downMirrored")
    require(CGImagePropertyOrientation.leftMirrored.rawValue == 5, "leftMirrored")
    require(CGImagePropertyOrientation.right.rawValue == 6, "right")
    require(CGImagePropertyOrientation.rightMirrored.rawValue == 7, "rightMirrored")
    require(CGImagePropertyOrientation.left.rawValue == 8, "left")
    require(CGImagePropertyOrientation(rawValue: 6) == .right, "init")
    require(CGImagePropertyOrientation.up != .down, "neq")
    var hasher = Hasher()
    CGImagePropertyOrientation.up.hash(into: &hasher)
    _ = CGImagePropertyOrientation.up.hashValue
}

func testMetadataEnums() {
    require(CGImageMetadataType.invalid.rawValue == -1, "invalid")
    require(CGImageMetadataType.default.rawValue == 0, "default")
    require(CGImageMetadataType.string.rawValue == 1, "string")
    require(CGImageMetadataType.arrayUnordered.rawValue == 2, "unordered")
    require(CGImageMetadataType.arrayOrdered.rawValue == 3, "ordered")
    require(CGImageMetadataType.alternateArray.rawValue == 4, "alt array")
    require(CGImageMetadataType.alternateText.rawValue == 5, "alt text")
    require(CGImageMetadataType.structure.rawValue == 6, "structure")
    require(CGImageMetadataType(rawValue: 1) == .string, "init")
    require(CGImageMetadataErrors.unknown.rawValue == 0, "unknown")
    require(CGImageMetadataErrors.unsupportedFormat.rawValue == 1, "unsupported")
    require(CGImageMetadataErrors.badArgument.rawValue == 2, "bad")
    require(CGImageMetadataErrors.conflictingArguments.rawValue == 3, "conflict")
    require(CGImageMetadataErrors.prefixConflict.rawValue == 4, "prefix")
    require(CGImageMetadataErrors(rawValue: 4) == .prefixConflict, "err init")
    require(CGImageMetadataErrors.unknown != .badArgument, "neq")
    require(CGImageMetadataType.string != .structure, "type neq")
    var hasher = Hasher()
    CGImageMetadataType.string.hash(into: &hasher)
    CGImageMetadataErrors.unknown.hash(into: &hasher)
    _ = CGImageMetadataType.string.hashValue
    _ = CGImageMetadataErrors.unknown.hashValue
}

func testAnimationStatusRawValues() {
    require(CGImageAnimationStatus.parameterError.rawValue == -22140, "param")
    require(CGImageAnimationStatus.corruptInputImage.rawValue == -22141, "corrupt")
    require(CGImageAnimationStatus.unsupportedFormat.rawValue == -22142, "unsupported")
    require(CGImageAnimationStatus.incompleteInputImage.rawValue == -22143, "incomplete")
    require(CGImageAnimationStatus.allocationFailure.rawValue == -22144, "alloc")
    require(CGImageAnimationStatus(rawValue: -22140) == .parameterError, "init")
    require(CGImageAnimationStatus.parameterError != .allocationFailure, "neq")
    var hasher = Hasher()
    CGImageAnimationStatus.parameterError.hash(into: &hasher)
    _ = CGImageAnimationStatus.parameterError.hashValue
}

func testTGACompression() {
    require(CGImagePropertyTGACompression.tgaCompressionNone.rawValue == 0, "none")
    require(CGImagePropertyTGACompression.tgaCompressionRLE.rawValue == 1, "rle")
    require(CGImagePropertyTGACompression(rawValue: 1) == .tgaCompressionRLE, "init")
    require(
        CGImagePropertyTGACompression.tgaCompressionNone != .tgaCompressionRLE,
        "neq"
    )
    var hasher = Hasher()
    CGImagePropertyTGACompression.tgaCompressionNone.hash(into: &hasher)
    _ = CGImagePropertyTGACompression.tgaCompressionNone.hashValue
}

func testPNGRoundtrip() {
    let data = encodedSample("public.png")
    guard let source = CGImageSourceCreateWithData(data, nil) else { fatalError("png source") }
    require(CGImageSourceGetType(source) == "public.png", "type")
    require(CGImageSourceGetCount(source) == 1, "count")
    require(CGImageSourceGetStatus(source) == .statusComplete, "status")
    require(CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete, "idx status")
    require(CGImageSourceGetPrimaryImageIndex(source) == 0, "primary")
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("png image")
    }
    require(image.width == 2 && image.height == 1, "size")
    require(image.pixels[0] == 255 && image.pixels[1] == 0 && image.pixels[2] == 0, "red")
    require(image.pixels[4] == 0 && image.pixels[5] == 255, "green")
}

func testBMPRoundtrip() {
    let data = encodedSample("com.microsoft.bmp")
    guard let source = CGImageSourceCreateWithData(data, nil) else { fatalError("bmp source") }
    require(CGImageSourceGetType(source) == "com.microsoft.bmp", "type")
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("bmp image")
    }
    require(image.width == 2 && image.height == 1, "size")
    require(image.pixels[0] == 255 && image.pixels[4] == 0, "pixels")
}

func testInvalidDataFailsClosed() {
    require(CGImageSourceCreateWithData(Data(), nil) == nil, "empty")
    require(CGImageSourceCreateWithData(Data([0, 1, 2, 3]), nil) == nil, "garbage")
    require(CGImageSourceCreateWithData(Data([0xff, 0xd8, 0xff]), nil) == nil, "jpeg stub")
}

func testIncrementalPNG() {
    let data = encodedSample("public.png")
    let source = CGImageSourceCreateIncremental(nil)
    require(CGImageSourceGetStatus(source) == .statusInvalidData, "start")
    let prefix = Data(data.prefix(8))
    CGImageSourceUpdateData(source, prefix, false)
    require(CGImageSourceGetType(source) == "public.png", "type from sig")
    require(CGImageSourceGetStatus(source) == .statusIncomplete, "incomplete")
    CGImageSourceUpdateData(source, data, true)
    require(CGImageSourceGetStatus(source) == .statusComplete, "complete")
    require(CGImageSourceGetCount(source) == 1, "count")
    require(CGImageSourceCreateImageAtIndex(source, 0, nil) != nil, "image")
}

func testCopyProperties() {
    let data = encodedSample("public.png")
    guard let source = CGImageSourceCreateWithData(data, nil) else { fatalError("source") }
    guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else {
        fatalError("props")
    }
    require((props[kCGImagePropertyPixelWidth] as? Int) == 2, "width")
    require((props[kCGImagePropertyPixelHeight] as? Int) == 1, "height")
    require((props[kCGImagePropertyOrientation] as? UInt32) == 1, "orientation")
    require(props[kCGImagePropertyPNGDictionary] != nil, "png dict")
    require(CGImageSourceCopyPropertiesAtIndex(source, 9, nil) == nil, "oob")
    require(CGImageSourceCopyProperties(source, nil) != nil, "container")
}

func testDestinationURL() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("imageio-host-\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: url) }
    guard let dest = CGImageDestinationCreateWithURL(url, "public.png", 1, nil) else {
        fatalError("url dest")
    }
    CGImageDestinationSetProperties(dest, [kCGImageDestinationLossyCompressionQuality: 1.0])
    CGImageDestinationAddImage(dest, sampleImage(), nil)
    require(CGImageDestinationFinalize(dest), "finalize")
    guard let source = CGImageSourceCreateWithURL(url, nil) else { fatalError("url source") }
    require(CGImageSourceGetCount(source) == 1, "count")
}

func testDestinationConsumer() {
    let consumer = CGDataConsumer()
    guard let dest = CGImageDestinationCreateWithDataConsumer(
        consumer, "com.microsoft.bmp", 1, nil
    ) else { fatalError("consumer dest") }
    CGImageDestinationAddImage(dest, sampleImage(), nil)
    require(CGImageDestinationFinalize(dest), "finalize")
    require(!consumer.bytes.isEmpty, "bytes")
    require(CGImageSourceCreateWithData(consumer.bytes, nil) != nil, "reload")
}

func testDestinationUnsupportedType() {
    let data = NSMutableData()
    require(CGImageDestinationCreateWithData(data, "public.jpeg", 1, nil) == nil, "jpeg")
    require(CGImageDestinationCreateWithData(data, "public.png", 0, nil) == nil, "count")
}

func testMetadataTags() {
    let metadata = CGImageMetadataCreateMutable()
    require(
        CGImageMetadataRegisterNamespaceForPrefix(
            metadata, kCGImageMetadataNamespaceExif, kCGImageMetadataPrefixExif, nil
        ),
        "register"
    )
    guard let tag = CGImageMetadataTagCreate(
        kCGImageMetadataNamespaceExif,
        kCGImageMetadataPrefixExif,
        "UserComment",
        .string,
        "hello"
    ) else { fatalError("tag") }
    require(CGImageMetadataTagCopyName(tag) == "UserComment", "name")
    require(CGImageMetadataTagCopyNamespace(tag) == kCGImageMetadataNamespaceExif, "ns")
    require(CGImageMetadataTagCopyPrefix(tag) == kCGImageMetadataPrefixExif, "prefix")
    require(CGImageMetadataTagGetType(tag) == .string, "type")
    require((CGImageMetadataTagCopyValue(tag) as? String) == "hello", "value")
    require(CGImageMetadataTagCopyQualifiers(tag) == nil, "qualifiers")
    require(CGImageMetadataSetTagWithPath(metadata, nil, "exif:UserComment", tag), "set")
    require(
        CGImageMetadataCopyStringValueWithPath(metadata, nil, "exif:UserComment") == "hello",
        "string"
    )
    require(CGImageMetadataCopyTagWithPath(metadata, nil, "exif:UserComment") === tag, "copy")
    require(CGImageMetadataSetValueWithPath(metadata, nil, "plain", "value"), "set value")
    require(
        CGImageMetadataSetValueMatchingImageProperty(
            metadata, kCGImagePropertyExifDictionary, kCGImagePropertyPixelWidth, "2"
        ),
        "matching"
    )
    require(
        CGImageMetadataCopyTagMatchingImageProperty(
            metadata, kCGImagePropertyExifDictionary, kCGImagePropertyPixelWidth
        ) != nil,
        "match copy"
    )
    guard let copy = CGImageMetadataCreateMutableCopy(metadata) else { fatalError("copy") }
    require(CGImageMetadataRemoveTagWithPath(copy, nil, "plain"), "remove")
    require(CGImageMetadataCopyTagWithPath(copy, nil, "plain") == nil, "removed")
    require(CGImageMetadataCopyTags(metadata)?.count == 3, "tags")
}

func testMetadataEnumerate() {
    let metadata = CGImageMetadataCreateMutable()
    _ = CGImageMetadataSetValueWithPath(metadata, nil, "a", "1")
    _ = CGImageMetadataSetValueWithPath(metadata, nil, "b", "2")
    var seen: [CFString] = []
    CGImageMetadataEnumerateTagsUsingBlock(metadata, nil, nil) { path, _ in
        seen.append(path)
        return path != "a"
    }
    require(seen == ["a"], "stop after false")
}

func testMetadataNamespaceConflict() {
    let metadata = CGImageMetadataCreateMutable()
    require(
        CGImageMetadataRegisterNamespaceForPrefix(metadata, "http://a.example", "x", nil),
        "first"
    )
    var boxed: Unmanaged<CFError>?
    let ok = withUnsafeMutablePointer(to: &boxed) { pointer in
        CGImageMetadataRegisterNamespaceForPrefix(metadata, "http://b.example", "x", pointer)
    }
    require(!ok, "conflict")
    require(boxed != nil, "error")
    boxed?.release()
}

func testMetadataXMPFailClosed() {
    require(CGImageMetadataCreateFromXMPData(Data("<x:xmpmeta/>".utf8)) == nil, "parse")
    require(CGImageMetadataCreateXMPData(CGImageMetadataCreateMutable(), nil) == nil, "write")
}

func testAnimatePNG() {
    let data = encodedSample("public.png")
    var calls = 0
    let status = CGAnimateImageDataWithBlock(data, nil) { index, image, stop in
        calls += 1
        require(index == 0, "index")
        require(image.width == 2, "width")
        stop.pointee = true
    }
    require(status == 0, "status")
    require(calls == 1, "calls")
    let missing = URL(fileURLWithPath: "/tmp/imageio-missing-\(UUID().uuidString).png")
    let urlStatus = CGAnimateImageAtURLWithBlock(missing, nil) { _, _, _ in
        fatalError("must not run")
    }
    require(urlStatus == CGImageAnimationStatus.parameterError.rawValue, "missing url")
}

func testTypeIdentifiers() {
    let sourceTypes = CGImageSourceCopyTypeIdentifiers()
    require(sourceTypes.contains { ($0 as? String) == "public.png" }, "png")
    require(sourceTypes.contains { ($0 as? String) == "com.microsoft.bmp" }, "bmp")
    let destTypes = CGImageDestinationCopyTypeIdentifiers()
    require(destTypes.contains { ($0 as? String) == "public.png" }, "dest png")
    require(!destTypes.contains { ($0 as? String) == "public.jpeg" }, "no jpeg dest")
}

func testTypeIDs() {
    require(CGImageSourceGetTypeID() != 0, "source")
    require(CGImageDestinationGetTypeID() != 0, "dest")
    require(CGImageMetadataGetTypeID() != 0, "meta")
    require(CGImageMetadataTagGetTypeID() != 0, "tag")
    require(CGImageSourceGetTypeID() != CGImageDestinationGetTypeID(), "distinct")
}

func testEqualityAndHash() {
    let a = CGImageSourceCreateIncremental(nil)
    let b = CGImageSourceCreateIncremental(nil)
    require(a == a, "source eq")
    require(a != b, "source neq")
    require(a.hashValue == a.hashValue, "source hash")
    var hasher = Hasher()
    a.hash(into: &hasher)
    let destData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(destData, "public.png", 1, nil) else {
        fatalError("dest")
    }
    require(dest == dest, "dest eq")
    guard let dest2 = CGImageDestinationCreateWithData(NSMutableData(), "public.png", 1, nil) else {
        fatalError("dest2")
    }
    require(dest != dest2, "dest neq")
    dest.hash(into: &hasher)
    _ = dest.hashValue
    let meta = CGImageMetadataCreateMutable()
    let meta2 = CGImageMetadataCreateMutable()
    require(meta == meta, "meta eq")
    require(meta != meta2, "meta neq")
    meta.hash(into: &hasher)
    _ = meta.hashValue
    guard let tag = CGImageMetadataTagCreate("ns", "p", "n", .string, "v") else {
        fatalError("tag")
    }
    require(tag == tag, "tag eq")
    guard let tag2 = CGImageMetadataTagCreate("ns", "p", "n", .string, "v") else {
        fatalError("tag2")
    }
    require(tag != tag2, "tag neq")
    tag.hash(into: &hasher)
    _ = tag.hashValue
}

func testKnownPropertyKeys() {
    require(kCGImagePropertyPixelWidth == "PixelWidth", "width")
    require(kCGImagePropertyPixelHeight == "PixelHeight", "height")
    require(kCGImagePropertyOrientation == "Orientation", "orientation")
    require(kCGImagePropertyGIFDictionary == "{GIF}", "gif")
    require(kCGImagePropertyPNGDictionary == "{PNG}", "png")
    require(kCGImagePropertyJFIFDictionary == "{JFIF}", "jfif")
    require(kCGImagePropertyTIFFDictionary == "{TIFF}", "tiff")
    require(kCGImagePropertyExifDictionary == "{Exif}", "exif")
    require(kCGImagePropertyColorModelRGB == "RGB", "rgb")
    require(kCGImageSourceShouldCache == "ShouldCache", "cache")
    require(kCFErrorDomainCGImageMetadata == "kCFErrorDomainCGImageMetadata", "domain")
}

func testCopyImageSource() {
    let png = encodedSample("public.png")
    guard let source = CGImageSourceCreateWithData(png, nil) else { fatalError("source") }
    let destData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(destData, "public.png", 1, nil) else {
        fatalError("dest")
    }
    var boxed: Unmanaged<CFError>?
    let copied = withUnsafeMutablePointer(to: &boxed) { pointer in
        CGImageDestinationCopyImageSource(dest, source, nil, pointer)
    }
    require(copied, "copy")
    require(boxed == nil, "no error")
    require(CGImageDestinationFinalize(dest), "finalize")
    require(destData as Data == png, "bytes")
}

func testAuxiliaryDataAbsent() {
    let data = encodedSample("public.png")
    guard let source = CGImageSourceCreateWithData(data, nil) else { fatalError("source") }
    require(
        CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeHDRGainMap)
            == nil,
        "aux"
    )
    let destData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(destData, "public.png", 1, nil) else {
        fatalError("dest")
    }
    CGImageDestinationAddImage(dest, sampleImage(), nil)
    CGImageDestinationAddAuxiliaryDataInfo(dest, kCGImageAuxiliaryDataTypeHDRGainMap, [:])
    require(CGImageDestinationFinalize(dest), "finalize still works")
}

func testThumbnailIsSourceImage() {
    let data = encodedSample("public.png")
    guard let source = CGImageSourceCreateWithData(data, nil) else { fatalError("source") }
    let options: CFDictionary = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: 1,
    ]
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options)
    require(image != nil && thumb != nil, "present")
    require(image === thumb, "same bitmap")
}

func testGIFTypeAndLoopFromIncremental() {
    // GIF89a 1x1 with NETSCAPE loop count 3. Pixel decode is CQuartz-only;
    // the container type and loop count are parsed from the byte stream.
    let gif: [UInt8] = [
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x21, 0xFF, 0x0B,
        0x4E, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2E, 0x30,
        0x03, 0x01, 0x03, 0x00, 0x00,
        0x3B,
    ]
    let source = CGImageSourceCreateIncremental(nil)
    CGImageSourceUpdateData(source, Data(gif), true)
    require(CGImageSourceGetType(source) == "com.compuserve.gif", "type")
    guard let props = CGImageSourceCopyProperties(source, nil) else { fatalError("props") }
    let gifDict = props[kCGImagePropertyGIFDictionary] as? [CFString: Any]
    require((gifDict?[kCGImagePropertyGIFLoopCount] as? Int) == 3, "loop")
}

func testCreateWithURLAndProvider() {
    let png = encodedSample("public.png")
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("imageio-provider-\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: url) }
    try! png.write(to: url)
    guard let fromURL = CGImageSourceCreateWithURL(url, nil) else { fatalError("url") }
    require(CGImageSourceGetCount(fromURL) == 1, "url count")
    let provider = CGDataProvider(data: png)
    guard let fromProvider = CGImageSourceCreateWithDataProvider(provider, nil) else {
        fatalError("provider")
    }
    require(CGImageSourceGetCount(fromProvider) == 1, "provider count")
    let incremental = CGImageSourceCreateIncremental(nil)
    CGImageSourceUpdateDataProvider(incremental, provider, true)
    require(CGImageSourceGetStatus(incremental) == .statusComplete, "update provider")
}

func testRemoveCacheAndMetadataAtIndex() {
    let data = encodedSample("public.png")
    guard let source = CGImageSourceCreateWithData(data, nil) else { fatalError("source") }
    CGImageSourceRemoveCacheAtIndex(source, 0)
    require(CGImageSourceCreateImageAtIndex(source, 0, nil) != nil, "still present")
    require(CGImageSourceCopyMetadataAtIndex(source, 0, nil) != nil, "metadata shell")
    require(CGImageSourceCopyMetadataAtIndex(source, 9, nil) == nil, "oob")
}

func testAddImageFromSource() {
    let png = encodedSample("public.png")
    guard let source = CGImageSourceCreateWithData(png, nil) else { fatalError("source") }
    let destData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(destData, "public.png", 1, nil) else {
        fatalError("dest")
    }
    CGImageDestinationAddImageFromSource(dest, source, 0, nil)
    require(CGImageDestinationFinalize(dest), "finalize")
    require(CGImageSourceCreateWithData(destData as Data, nil) != nil, "reload")
}

func testAddImageAndMetadata() {
    let destData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(destData, "public.png", 1, nil) else {
        fatalError("dest")
    }
    CGImageDestinationAddImageAndMetadata(dest, sampleImage(), CGImageMetadataCreateMutable(), nil)
    require(CGImageDestinationFinalize(dest), "finalize")
}

func testAllowableTypes() {
    require(CGImageSourceSetAllowableTypes(["public.png"]) == 0, "set")
    let png = encodedSample("public.png")
    require(CGImageSourceCreateWithData(png, nil) != nil, "png still allowed")
    let bmp = encodedSample("com.microsoft.bmp")
    require(CGImageSourceCreateWithData(bmp, nil) == nil, "bmp rejected")
    require(CGImageSourceSetAllowableTypes([]) == -50, "empty")
    require(
        CGImageSourceSetAllowableTypes([
            "public.png", "public.jpeg", "com.compuserve.gif", "com.microsoft.bmp",
        ]) == 0,
        "restore"
    )
    require(CGImageSourceCreateWithData(bmp, nil) != nil, "bmp restored")
}
