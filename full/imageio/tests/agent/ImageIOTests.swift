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
    let empty = CGImageSourceCreateWithData(Data(), nil)
    require(empty != nil, "empty src")
    require(CGImageSourceGetStatus(empty!) == .statusInvalidData, "empty status")
    let garbage = CGImageSourceCreateWithData(Data([0, 1, 2, 3]), nil)
    require(garbage != nil, "garbage src")
    require(CGImageSourceGetStatus(garbage!) == .statusInvalidData, "garbage status")
    require(CGImageSourceGetType(garbage!) == nil, "garbage type")
    require(CGImageSourceGetCount(garbage!) == 0, "garbage count")
}

func testIncrementalPNG() {
    let data = encodedSample("public.png")
    let source = CGImageSourceCreateIncremental(nil)
    require(CGImageSourceGetStatus(source) == .statusInvalidData, "start")
    let prefix = Data(data.prefix(16))
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
    require(kCGImageSourceShouldCache == "kCGImageSourceShouldCache", "cache")
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
    require(image!.width == 2 && image!.height == 1, "full size")
    // MEASURED 2026-09-05: 2×1 maxPixel 1 → 1×1 (half-to-even of 1*1/2).
    require(thumb!.width == 1 && thumb!.height == 1, "thumb size")
}

func testGIFTypeAndLoopFromIncremental() {
    // GIF89a 1×1 with NETSCAPE loop field 3. MEASURED 2026-09-05 Apple
    // ImageIO reports LoopCount 4 (field + 1). Pixel decode is CQuartz-only.
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
    require((gifDict?[kCGImagePropertyGIFLoopCount] as? Int) == 4, "loop")
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

func testPNGChunkProperties() {
    // MEASURED 2026-09-05 Apple ImageIO on this exact 2×1 RGB PNG
    // (IHDR, pHYs 5669 ppm, gAMA 45455, tEXt Title=Hello):
    // PixelWidth=2 PixelHeight=1 DPIWidth/Height=144 Gamma=0.45455
    // {PNG}.Title=Hello {IPTC}.ObjectName=Hello, no HasAlpha.
    let png: [UInt8] = [
        137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82,0,0,0,2,0,0,0,1,8,2,0,0,0,
        123,64,232,221,0,0,0,9,112,72,89,115,0,0,22,37,0,0,22,37,1,73,82,36,240,
        0,0,0,4,103,65,77,65,0,0,177,143,11,252,97,5,0,0,0,11,116,69,88,116,84,
        105,116,108,101,0,72,101,108,108,111,205,207,192,207,0,0,0,18,73,68,65,
        84,120,1,1,7,0,248,255,0,255,0,0,0,255,0,7,255,1,255,197,14,226,106,0,0,
        0,0,73,69,78,68,174,66,96,130,
    ]
    guard let source = CGImageSourceCreateWithData(Data(png), nil) else {
        fatalError("chunk source")
    }
    require(CGImageSourceGetType(source) == "public.png", "type")
    require(CGImageSourceGetCount(source) == 1, "count")
    guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else {
        fatalError("props")
    }
    require((props[kCGImagePropertyPixelWidth] as? Int) == 2, "width")
    require((props[kCGImagePropertyPixelHeight] as? Int) == 1, "height")
    require((props[kCGImagePropertyDPIWidth] as? Double) == 144
        || (props[kCGImagePropertyDPIWidth] as? Int) == 144, "dpi w")
    require((props[kCGImagePropertyDPIHeight] as? Double) == 144
        || (props[kCGImagePropertyDPIHeight] as? Int) == 144, "dpi h")
    let pngDict = props[kCGImagePropertyPNGDictionary] as? [CFString: Any]
    require(pngDict != nil, "png dict")
    require((pngDict?[kCGImagePropertyPNGTitle] as? String) == "Hello", "title")
    let gamma = pngDict?[kCGImagePropertyPNGGamma]
    if let g = gamma as? Double {
        require(abs(g - 0.45455) < 0.00001, "gamma")
    } else if let g = gamma as? NSNumber {
        require(abs(g.doubleValue - 0.45455) < 0.00001, "gamma n")
    } else {
        fatalError("gamma missing")
    }
    require((pngDict?[kCGImagePropertyPNGXPixelsPerMeter] as? Int) == 5669, "xppm")
    let iptc = props[kCGImagePropertyIPTCDictionary] as? [CFString: Any]
    require((iptc?[kCGImagePropertyIPTCObjectName] as? String) == "Hello", "iptc")
}

func testThumbnailMaxPixelRounding() {
    // 2×1 encoded PNG; scale like the 16×12 Apple table (max / long side).
    let data = encodedSample("public.png")
    guard let source = CGImageSourceCreateWithData(data, nil) else { fatalError("src") }
    let opts: CFDictionary = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: 8,
    ]
    let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, opts)
    require(thumb != nil, "thumb")
    require(thumb!.width == 2 && thumb!.height == 1, "no upscale")
}

func testTruncatedPNGCreateWithData() {
    let data = encodedSample("public.png")
    let prefix = Data(data.prefix(16))
    guard let source = CGImageSourceCreateWithData(prefix, nil) else {
        fatalError("prefix src")
    }
    require(CGImageSourceGetType(source) == "public.png", "type")
    require(CGImageSourceGetStatus(source) == .statusComplete, "complete")
    require(CGImageSourceCreateImageAtIndex(source, 0, nil) == nil, "no pixels")
}

func testXMPRoundtrip() {
    let metadata = CGImageMetadataCreateMutable()
    require(
        CGImageMetadataRegisterNamespaceForPrefix(
            metadata, kCGImageMetadataNamespaceExif, kCGImageMetadataPrefixExif, nil
        ),
        "register"
    )
    require(CGImageMetadataSetValueWithPath(metadata, nil, "exif:UserComment", "hello"), "set")
    guard let xmp = CGImageMetadataCreateXMPData(metadata, nil) else { fatalError("xmp") }
    require(!xmp.isEmpty, "bytes")
    guard let parsed = CGImageMetadataCreateFromXMPData(xmp) else { fatalError("parse") }
    require(
        CGImageMetadataCopyStringValueWithPath(parsed, nil, "exif:UserComment") == "hello",
        "value"
    )
}

func testPropertyKeyPayloads() {
    // MEASURED 2026-09-05 Apple ImageIO CFString payloads (macOS 26.1).
    let keys: [(CFString, CFString)] = [
        (kCFErrorDomainCGImageMetadata, "kCFErrorDomainCGImageMetadata"),
        (kCGComputeHDRStats, "kCGComputeHDRStats"),
        (kCGImageAnimationDelayTime, "DelayTime"),
        (kCGImageAnimationLoopCount, "LoopCount"),
        (kCGImageAnimationStartIndex, "StartIndex"),
        (kCGImageAuxiliaryDataInfoColorSpace, "kCGImageAuxiliaryDataInfoColorSpace"),
        (kCGImageAuxiliaryDataInfoData, "kCGImageAuxiliaryDataInfoData"),
        (kCGImageAuxiliaryDataInfoDataDescription, "kCGImageAuxiliaryDataInfoDataDescription"),
        (kCGImageAuxiliaryDataInfoMetadata, "kCGImageAuxiliaryDataInfoMetadata"),
        (kCGImageAuxiliaryDataTypeDepth, "kCGImageAuxiliaryDataTypeDepth"),
        (kCGImageAuxiliaryDataTypeDisparity, "kCGImageAuxiliaryDataTypeDisparity"),
        (kCGImageAuxiliaryDataTypeHDRGainMap, "kCGImageAuxiliaryDataTypeHDRGainMap"),
        (kCGImageAuxiliaryDataTypeISOGainMap, "kCGImageAuxiliaryDataTypeISOGainMap"),
        (kCGImageAuxiliaryDataTypePortraitEffectsMatte, "kCGImageAuxiliaryDataTypePortraitEffectsMatte"),
        (kCGImageAuxiliaryDataTypeSemanticSegmentationGlassesMatte, "kCGImageAuxiliaryDataTypeSemanticSegmentationGlassesMatte"),
        (kCGImageAuxiliaryDataTypeSemanticSegmentationHairMatte, "kCGImageAuxiliaryDataTypeSemanticSegmentationHairMatte"),
        (kCGImageAuxiliaryDataTypeSemanticSegmentationSkinMatte, "kCGImageAuxiliaryDataTypeSemanticSegmentationSkinMatte"),
        (kCGImageAuxiliaryDataTypeSemanticSegmentationSkyMatte, "kCGImageAuxiliaryDataTypeSemanticSegmentationSkyMatte"),
        (kCGImageAuxiliaryDataTypeSemanticSegmentationTeethMatte, "kCGImageAuxiliaryDataTypeSemanticSegmentationTeethMatte"),
        (kCGImageDestinationBackgroundColor, "kCGImageDestinationBackgroundColor"),
        (kCGImageDestinationDateTime, "kCGImageDestinationDateTime"),
        (kCGImageDestinationEmbedThumbnail, "kCGImageDestinationEmbedThumbnail"),
        (kCGImageDestinationEncodeAlternateColorSpace, "kCGImageDestinationEncodeAlternateColorSpace"),
        (kCGImageDestinationEncodeBaseColorSpace, "kCGImageDestinationEncodeBaseColorSpace"),
        (kCGImageDestinationEncodeBaseIsSDR, "kCGImageDestinationEncodeBaseIsSDR"),
        (kCGImageDestinationEncodeBasePixelFormatRequest, "kCGImageDestinationEncodeBasePixelFormatRequest"),
        (kCGImageDestinationEncodeGainMapPixelFormatRequest, "kCGImageDestinationEncodeGainMapPixelFormatRequest"),
        (kCGImageDestinationEncodeGainMapSubsampleFactor, "kCGImageDestinationEncodeGainMapSubsampleFactor"),
        (kCGImageDestinationEncodeGenerateGainMapWithBaseImage, "kCGImageDestinationEncodeGenerateGainMapWithBaseImage"),
        (kCGImageDestinationEncodeIsBaseImage, "kCGImageDestinationEncodeIsBaseImage"),
        (kCGImageDestinationEncodeRequest, "kCGImageDestinationEncodeRequest"),
        (kCGImageDestinationEncodeRequestOptions, "kCGImageDestinationEncodeRequestOptions"),
        (kCGImageDestinationEncodeToISOGainmap, "kCGImageDestinationEncodeToISOGainmap"),
        (kCGImageDestinationEncodeToISOHDR, "kCGImageDestinationEncodeToISOHDR"),
        (kCGImageDestinationEncodeToSDR, "kCGImageDestinationEncodeToSDR"),
        (kCGImageDestinationEncodeTonemapMode, "kCGImageDestinationEncodeTonemapMode"),
        (kCGImageDestinationImageMaxPixelSize, "kCGImageDestinationImageMaxPixelSize"),
        (kCGImageDestinationLossyCompressionQuality, "kCGImageDestinationLossyCompressionQuality"),
        (kCGImageDestinationMergeMetadata, "kCGImageDestinationMergeMetadata"),
        (kCGImageDestinationMetadata, "kCGImageDestinationMetadata"),
        (kCGImageDestinationOptimizeColorForSharing, "kCGImageDestinationOptimizeColorForSharing"),
        (kCGImageDestinationOrientation, "kCGImageDestinationOrientation"),
        (kCGImageDestinationPreserveGainMap, "kCGImageDestinationPreserveGainMap"),
        (kCGImageMetadataEnumerateRecursively, "kCGImageMetadataEnumerateRecursively"),
        (kCGImageMetadataNamespaceDublinCore, "http://purl.org/dc/elements/1.1/"),
        (kCGImageMetadataNamespaceExif, "http://ns.adobe.com/exif/1.0/"),
        (kCGImageMetadataNamespaceExifAux, "http://ns.adobe.com/exif/1.0/aux/"),
        (kCGImageMetadataNamespaceExifEX, "http://cipa.jp/exif/1.0/"),
        (kCGImageMetadataNamespaceIPTCCore, "http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/"),
        (kCGImageMetadataNamespaceIPTCExtension, "http://iptc.org/std/Iptc4xmpExt/2008-02-29/"),
        (kCGImageMetadataNamespacePhotoshop, "http://ns.adobe.com/photoshop/1.0/"),
        (kCGImageMetadataNamespaceTIFF, "http://ns.adobe.com/tiff/1.0/"),
        (kCGImageMetadataNamespaceXMPBasic, "http://ns.adobe.com/xap/1.0/"),
        (kCGImageMetadataNamespaceXMPRights, "http://ns.adobe.com/xap/1.0/rights/"),
        (kCGImageMetadataPrefixDublinCore, "dc"),
        (kCGImageMetadataPrefixExif, "exif"),
        (kCGImageMetadataPrefixExifAux, "aux"),
        (kCGImageMetadataPrefixExifEX, "exifEX"),
        (kCGImageMetadataPrefixIPTCCore, "Iptc4xmpCore"),
        (kCGImageMetadataPrefixIPTCExtension, "Iptc4xmpExt"),
        (kCGImageMetadataPrefixPhotoshop, "photoshop"),
        (kCGImageMetadataPrefixTIFF, "tiff"),
        (kCGImageMetadataPrefixXMPBasic, "xmp"),
        (kCGImageMetadataPrefixXMPRights, "xmpRights"),
        (kCGImageMetadataShouldExcludeGPS, "kCGImageMetadataShouldExcludeGPS"),
        (kCGImageMetadataShouldExcludeXMP, "kCGImageMetadataShouldExcludeXMP"),
        (kCGImageProperty8BIMDictionary, "{8BIM}"),
        (kCGImageProperty8BIMLayerNames, "LayerNames"),
        (kCGImageProperty8BIMVersion, "Version"),
        (kCGImagePropertyAPNGCanvasPixelHeight, "CanvasPixelHeight"),
        (kCGImagePropertyAPNGCanvasPixelWidth, "CanvasPixelWidth"),
        (kCGImagePropertyAPNGDelayTime, "DelayTime"),
        (kCGImagePropertyAPNGFrameInfoArray, "FrameInfo"),
        (kCGImagePropertyAPNGLoopCount, "LoopCount"),
        (kCGImagePropertyAPNGUnclampedDelayTime, "UnclampedDelayTime"),
        (kCGImagePropertyASTCBlockSize, "kCGImagePropertyASTCBlockSize"),
        (kCGImagePropertyASTCBlockSize4x4, "kCGImagePropertyASTCBlockSize4x4"),
        (kCGImagePropertyASTCBlockSize8x8, "kCGImagePropertyASTCBlockSize8x8"),
        (kCGImagePropertyASTCEncoder, "kCGImagePropertyASTCEncoder"),
        (kCGImagePropertyAVISDictionary, "{AVIS}"),
        (kCGImagePropertyAuxiliaryData, "AuxiliaryData"),
        (kCGImagePropertyAuxiliaryDataType, "AuxiliaryDataType"),
        (kCGImagePropertyBCEncoder, "kCGImagePropertyBCEncoder"),
        (kCGImagePropertyBCFormat, "kCGImagePropertyBCFormat"),
        (kCGImagePropertyBytesPerRow, "BytesPerRow"),
        (kCGImagePropertyCIFFCameraSerialNumber, "CameraSerialNumber"),
        (kCGImagePropertyCIFFContinuousDrive, "ContinuousDrive"),
        (kCGImagePropertyCIFFDescription, "Description"),
        (kCGImagePropertyCIFFDictionary, "{CIFF}"),
        (kCGImagePropertyCIFFFirmware, "Firmware"),
        (kCGImagePropertyCIFFFlashExposureComp, "FlashExposureComp"),
        (kCGImagePropertyCIFFFocusMode, "FocusMode"),
        (kCGImagePropertyCIFFImageFileName, "ImageFileName"),
        (kCGImagePropertyCIFFImageName, "ImageName"),
        (kCGImagePropertyCIFFImageSerialNumber, "ImageSerialNumber"),
        (kCGImagePropertyCIFFLensMaxMM, "LensMaxMM"),
        (kCGImagePropertyCIFFLensMinMM, "LensMinMM"),
        (kCGImagePropertyCIFFLensModel, "LensModel"),
        (kCGImagePropertyCIFFMeasuredEV, "MeasuredEV"),
        (kCGImagePropertyCIFFMeteringMode, "MeteringMode"),
        (kCGImagePropertyCIFFOwnerName, "OwnerName"),
        (kCGImagePropertyCIFFRecordID, "RecordID"),
        (kCGImagePropertyCIFFReleaseMethod, "ReleaseMethod"),
        (kCGImagePropertyCIFFReleaseTiming, "ReleaseTiming"),
        (kCGImagePropertyCIFFSelfTimingTime, "SelfTimingTime"),
        (kCGImagePropertyCIFFShootingMode, "ShootingMode"),
        (kCGImagePropertyCIFFWhiteBalanceIndex, "WhiteBalanceIndex"),
        (kCGImagePropertyColorModel, "ColorModel"),
        (kCGImagePropertyColorModelCMYK, "CMYK"),
        (kCGImagePropertyColorModelGray, "Gray"),
        (kCGImagePropertyColorModelLab, "Lab"),
        (kCGImagePropertyColorModelRGB, "RGB"),
        (kCGImagePropertyDNGActiveArea, "ActiveArea"),
        (kCGImagePropertyDNGAnalogBalance, "AnalogBalance"),
        (kCGImagePropertyDNGAntiAliasStrength, "AntiAliasStrength"),
        (kCGImagePropertyDNGAsShotICCProfile, "AsShotICCProfile"),
        (kCGImagePropertyDNGAsShotNeutral, "AsShotNeutral"),
        (kCGImagePropertyDNGAsShotPreProfileMatrix, "AsShotPreProfileMatrix"),
        (kCGImagePropertyDNGAsShotProfileName, "AsShotProfileName"),
        (kCGImagePropertyDNGAsShotWhiteXY, "AsShotWhiteXY"),
        (kCGImagePropertyDNGBackwardVersion, "DNGBackwardVersion"),
        (kCGImagePropertyDNGBaselineExposure, "BaselineExposure"),
        (kCGImagePropertyDNGBaselineExposureOffset, "BaselineExposureOffset"),
        (kCGImagePropertyDNGBaselineNoise, "BaselineNoise"),
        (kCGImagePropertyDNGBaselineSharpness, "BaselineSharpness"),
        (kCGImagePropertyDNGBayerGreenSplit, "BayerGreenSplit"),
        (kCGImagePropertyDNGBestQualityScale, "BestQualityScale"),
        (kCGImagePropertyDNGBlackLevel, "BlackLevel"),
        (kCGImagePropertyDNGBlackLevelDeltaH, "BlackLevelDeltaH"),
        (kCGImagePropertyDNGBlackLevelDeltaV, "BlackLevelDeltaV"),
        (kCGImagePropertyDNGBlackLevelRepeatDim, "BlackLevelRepeatDim"),
        (kCGImagePropertyDNGCFALayout, "CFALayout"),
        (kCGImagePropertyDNGCFAPlaneColor, "CFAPlaneColor"),
        (kCGImagePropertyDNGCalibrationIlluminant1, "CalibrationIlluminant1"),
        (kCGImagePropertyDNGCalibrationIlluminant2, "CalibrationIlluminant2"),
        (kCGImagePropertyDNGCameraCalibration1, "CameraCalibration1"),
        (kCGImagePropertyDNGCameraCalibration2, "CameraCalibration2"),
        (kCGImagePropertyDNGCameraCalibrationSignature, "CameraCalibrationSignature"),
        (kCGImagePropertyDNGCameraSerialNumber, "CameraSerialNumber"),
        (kCGImagePropertyDNGChromaBlurRadius, "ChromaBlurRadius"),
        (kCGImagePropertyDNGColorMatrix1, "ColorMatrix1"),
        (kCGImagePropertyDNGColorMatrix2, "ColorMatrix2"),
        (kCGImagePropertyDNGColorimetricReference, "ColorimetricReference"),
        (kCGImagePropertyDNGCurrentICCProfile, "CurrentICCProfile"),
        (kCGImagePropertyDNGCurrentPreProfileMatrix, "CurrentPreProfileMatrix"),
        (kCGImagePropertyDNGDefaultBlackRender, "DefaultBlackRender"),
        (kCGImagePropertyDNGDefaultCropOrigin, "DefaultCropOrigin"),
        (kCGImagePropertyDNGDefaultCropSize, "DefaultCropSize"),
        (kCGImagePropertyDNGDefaultScale, "DefaultScale"),
        (kCGImagePropertyDNGDefaultUserCrop, "DefaultUserCrop"),
        (kCGImagePropertyDNGDictionary, "{DNG}"),
        (kCGImagePropertyDNGExtraCameraProfiles, "ExtraCameraProfiles"),
        (kCGImagePropertyDNGFixVignetteRadial, "FixVignetteRadial"),
        (kCGImagePropertyDNGForwardMatrix1, "ForwardMatrix1"),
        (kCGImagePropertyDNGForwardMatrix2, "ForwardMatrix2"),
        (kCGImagePropertyDNGLensInfo, "LensInfo"),
        (kCGImagePropertyDNGLinearResponseLimit, "LinearResponseLimit"),
        (kCGImagePropertyDNGLinearizationTable, "LinearizationTable"),
        (kCGImagePropertyDNGLocalizedCameraModel, "LocalizedCameraModel"),
        (kCGImagePropertyDNGMakerNoteSafety, "MakerNoteSafety"),
        (kCGImagePropertyDNGMaskedAreas, "MaskedAreas"),
        (kCGImagePropertyDNGNewRawImageDigest, "NewRawImageDigest"),
        (kCGImagePropertyDNGNoiseProfile, "NoiseProfile"),
        (kCGImagePropertyDNGNoiseReductionApplied, "NoiseReductionApplied"),
        (kCGImagePropertyDNGOpcodeList1, "OpcodeList1"),
        (kCGImagePropertyDNGOpcodeList2, "DNGOpcodeList2"),
        (kCGImagePropertyDNGOpcodeList3, "DNGOpcodeList3"),
        (kCGImagePropertyDNGOriginalBestQualityFinalSize, "OriginalBestQualityFinalSize"),
        (kCGImagePropertyDNGOriginalDefaultCropSize, "OriginalDefaultCropSize"),
        (kCGImagePropertyDNGOriginalDefaultFinalSize, "OriginalDefaultFinalSize"),
        (kCGImagePropertyDNGOriginalRawFileData, "OriginalRawFileData"),
        (kCGImagePropertyDNGOriginalRawFileDigest, "OriginalRawFileDigest"),
        (kCGImagePropertyDNGOriginalRawFileName, "OriginalRawFileName"),
        (kCGImagePropertyDNGPreviewApplicationName, "PreviewApplicationName"),
        (kCGImagePropertyDNGPreviewApplicationVersion, "PreviewApplicationVersion"),
        (kCGImagePropertyDNGPreviewColorSpace, "PreviewColorSpace"),
        (kCGImagePropertyDNGPreviewDateTime, "PreviewDateTime"),
        (kCGImagePropertyDNGPreviewSettingsDigest, "PreviewSettingsDigest"),
        (kCGImagePropertyDNGPreviewSettingsName, "PreviewSettingsName"),
        (kCGImagePropertyDNGPrivateData, "DNGPrivateData"),
        (kCGImagePropertyDNGProfileCalibrationSignature, "ProfileCalibrationSignature"),
        (kCGImagePropertyDNGProfileCopyright, "ProfileCopyright"),
        (kCGImagePropertyDNGProfileEmbedPolicy, "ProfileEmbedPolicy"),
        (kCGImagePropertyDNGProfileHueSatMapData1, "ProfileHueSatMapData1"),
        (kCGImagePropertyDNGProfileHueSatMapData2, "ProfileHueSatMapData2"),
        (kCGImagePropertyDNGProfileHueSatMapDims, "ProfileHueSatMapDims"),
        (kCGImagePropertyDNGProfileHueSatMapEncoding, "ProfileHueSatMapEncoding"),
        (kCGImagePropertyDNGProfileLookTableData, "ProfileLookTableData"),
        (kCGImagePropertyDNGProfileLookTableDims, "ProfileLookTableDims"),
        (kCGImagePropertyDNGProfileLookTableEncoding, "ProfileLookTableEncoding"),
        (kCGImagePropertyDNGProfileName, "DNGProfileName"),
        (kCGImagePropertyDNGProfileToneCurve, "ProfileToneCurve"),
        (kCGImagePropertyDNGRawDataUniqueID, "DNGRawDataUniqueID"),
        (kCGImagePropertyDNGRawImageDigest, "RawImageDigest"),
        (kCGImagePropertyDNGRawToPreviewGain, "RawToPreviewGain"),
        (kCGImagePropertyDNGReductionMatrix1, "ReductionMatrix1"),
        (kCGImagePropertyDNGReductionMatrix2, "ReductionMatrix2"),
        (kCGImagePropertyDNGRowInterleaveFactor, "RowInterleaveFactor"),
        (kCGImagePropertyDNGShadowScale, "ShadowScale"),
        (kCGImagePropertyDNGSubTileBlockSize, "SubTileBlockSize"),
        (kCGImagePropertyDNGUniqueCameraModel, "UniqueCameraModel"),
        (kCGImagePropertyDNGVersion, "DNGVersion"),
        (kCGImagePropertyDNGWarpFisheye, "WarpFisheye"),
        (kCGImagePropertyDNGWarpRectilinear, "WarpRectilinear"),
        (kCGImagePropertyDNGWhiteLevel, "WhiteLevel"),
        (kCGImagePropertyDPIHeight, "DPIHeight"),
        (kCGImagePropertyDPIWidth, "DPIWidth"),
        (kCGImagePropertyDepth, "Depth"),
        (kCGImagePropertyEncoder, "kCGImagePropertyEncoder"),
        (kCGImagePropertyExifApertureValue, "ApertureValue"),
        (kCGImagePropertyExifAuxDictionary, "{ExifAux}"),
        (kCGImagePropertyExifAuxFirmware, "Firmware"),
        (kCGImagePropertyExifAuxFlashCompensation, "FlashCompensation"),
        (kCGImagePropertyExifAuxImageNumber, "ImageNumber"),
        (kCGImagePropertyExifAuxLensID, "LensID"),
        (kCGImagePropertyExifAuxLensInfo, "LensInfo"),
        (kCGImagePropertyExifAuxLensModel, "LensModel"),
        (kCGImagePropertyExifAuxLensSerialNumber, "LensSerialNumber"),
        (kCGImagePropertyExifAuxOwnerName, "OwnerName"),
        (kCGImagePropertyExifAuxSerialNumber, "SerialNumber"),
        (kCGImagePropertyExifBodySerialNumber, "BodySerialNumber"),
        (kCGImagePropertyExifBrightnessValue, "BrightnessValue"),
        (kCGImagePropertyExifCFAPattern, "CFAPattern"),
        (kCGImagePropertyExifCameraOwnerName, "CameraOwnerName"),
        (kCGImagePropertyExifColorSpace, "ColorSpace"),
        (kCGImagePropertyExifComponentsConfiguration, "ComponentsConfiguration"),
        (kCGImagePropertyExifCompositeImage, "CompositeImage"),
        (kCGImagePropertyExifCompressedBitsPerPixel, "CompressedBitsPerPixel"),
        (kCGImagePropertyExifContrast, "Contrast"),
        (kCGImagePropertyExifCustomRendered, "CustomRendered"),
        (kCGImagePropertyExifDateTimeDigitized, "DateTimeDigitized"),
        (kCGImagePropertyExifDateTimeOriginal, "DateTimeOriginal"),
        (kCGImagePropertyExifDeviceSettingDescription, "DeviceSettingDescription"),
        (kCGImagePropertyExifDictionary, "{Exif}"),
        (kCGImagePropertyExifDigitalZoomRatio, "DigitalZoomRatio"),
        (kCGImagePropertyExifExposureBiasValue, "ExposureBiasValue"),
        (kCGImagePropertyExifExposureIndex, "ExposureIndex"),
        (kCGImagePropertyExifExposureMode, "ExposureMode"),
        (kCGImagePropertyExifExposureProgram, "ExposureProgram"),
        (kCGImagePropertyExifExposureTime, "ExposureTime"),
        (kCGImagePropertyExifFNumber, "FNumber"),
        (kCGImagePropertyExifFileSource, "FileSource"),
        (kCGImagePropertyExifFlash, "Flash"),
        (kCGImagePropertyExifFlashEnergy, "FlashEnergy"),
        (kCGImagePropertyExifFlashPixVersion, "FlashPixVersion"),
        (kCGImagePropertyExifFocalLenIn35mmFilm, "FocalLenIn35mmFilm"),
        (kCGImagePropertyExifFocalLength, "FocalLength"),
        (kCGImagePropertyExifFocalPlaneResolutionUnit, "FocalPlaneResolutionUnit"),
        (kCGImagePropertyExifFocalPlaneXResolution, "FocalPlaneXResolution"),
        (kCGImagePropertyExifFocalPlaneYResolution, "FocalPlaneYResolution"),
        (kCGImagePropertyExifGainControl, "GainControl"),
        (kCGImagePropertyExifGamma, "Gamma"),
        (kCGImagePropertyExifISOSpeed, "ISOSpeed"),
        (kCGImagePropertyExifISOSpeedLatitudeyyy, "ISOSpeedLatitudeyyy"),
        (kCGImagePropertyExifISOSpeedLatitudezzz, "ISOSpeedLatitudezzz"),
        (kCGImagePropertyExifISOSpeedRatings, "ISOSpeedRatings"),
        (kCGImagePropertyExifImageUniqueID, "ImageUniqueID"),
        (kCGImagePropertyExifLensMake, "LensMake"),
        (kCGImagePropertyExifLensModel, "LensModel"),
        (kCGImagePropertyExifLensSerialNumber, "LensSerialNumber"),
        (kCGImagePropertyExifLensSpecification, "LensSpecification"),
        (kCGImagePropertyExifLightSource, "LightSource"),
        (kCGImagePropertyExifMakerNote, "MakerNote"),
        (kCGImagePropertyExifMaxApertureValue, "MaxApertureValue"),
        (kCGImagePropertyExifMeteringMode, "MeteringMode"),
        (kCGImagePropertyExifOECF, "OECF"),
        (kCGImagePropertyExifOffsetTime, "OffsetTime"),
        (kCGImagePropertyExifOffsetTimeDigitized, "OffsetTimeDigitized"),
        (kCGImagePropertyExifOffsetTimeOriginal, "OffsetTimeOriginal"),
        (kCGImagePropertyExifPixelXDimension, "PixelXDimension"),
        (kCGImagePropertyExifPixelYDimension, "PixelYDimension"),
        (kCGImagePropertyExifRecommendedExposureIndex, "RecommendedExposureIndex"),
        (kCGImagePropertyExifRelatedSoundFile, "RelatedSoundFile"),
        (kCGImagePropertyExifSaturation, "Saturation"),
        (kCGImagePropertyExifSceneCaptureType, "SceneCaptureType"),
        (kCGImagePropertyExifSceneType, "SceneType"),
        (kCGImagePropertyExifSensingMethod, "SensingMethod"),
        (kCGImagePropertyExifSensitivityType, "SensitivityType"),
        (kCGImagePropertyExifSharpness, "Sharpness"),
        (kCGImagePropertyExifShutterSpeedValue, "ShutterSpeedValue"),
        (kCGImagePropertyExifSourceExposureTimesOfCompositeImage, "SourceExposureTimesOfCompositeImage"),
        (kCGImagePropertyExifSourceImageNumberOfCompositeImage, "SourceImageNumberOfCompositeImage"),
        (kCGImagePropertyExifSpatialFrequencyResponse, "SpatialFrequencyResponse"),
        (kCGImagePropertyExifSpectralSensitivity, "SpectralSensitivity"),
        (kCGImagePropertyExifStandardOutputSensitivity, "StandardOutputSensitivity"),
        (kCGImagePropertyExifSubjectArea, "SubjectArea"),
        (kCGImagePropertyExifSubjectDistRange, "SubjectDistRange"),
        (kCGImagePropertyExifSubjectDistance, "SubjectDistance"),
        (kCGImagePropertyExifSubjectLocation, "SubjectLocation"),
        (kCGImagePropertyExifSubsecTime, "SubsecTime"),
        (kCGImagePropertyExifSubsecTimeDigitized, "SubsecTimeDigitized"),
        (kCGImagePropertyExifSubsecTimeOrginal, "SubsecTimeOriginal"),
        (kCGImagePropertyExifSubsecTimeOriginal, "SubsecTimeOriginal"),
        (kCGImagePropertyExifUserComment, "UserComment"),
        (kCGImagePropertyExifVersion, "ExifVersion"),
        (kCGImagePropertyExifWhiteBalance, "WhiteBalance"),
        (kCGImagePropertyFileContentsDictionary, "{FileContents}"),
        (kCGImagePropertyFileSize, "FileSize"),
        (kCGImagePropertyGIFCanvasPixelHeight, "CanvasPixelHeight"),
        (kCGImagePropertyGIFCanvasPixelWidth, "CanvasPixelWidth"),
        (kCGImagePropertyGIFDelayTime, "DelayTime"),
        (kCGImagePropertyGIFDictionary, "{GIF}"),
        (kCGImagePropertyGIFFrameInfoArray, "FrameInfo"),
        (kCGImagePropertyGIFHasGlobalColorMap, "HasGlobalColorMap"),
        (kCGImagePropertyGIFImageColorMap, "ImageColorMap"),
        (kCGImagePropertyGIFLoopCount, "LoopCount"),
        (kCGImagePropertyGIFUnclampedDelayTime, "UnclampedDelayTime"),
        (kCGImagePropertyGPSAltitude, "Altitude"),
        (kCGImagePropertyGPSAltitudeRef, "AltitudeRef"),
        (kCGImagePropertyGPSAreaInformation, "AreaInformation"),
        (kCGImagePropertyGPSDOP, "DOP"),
        (kCGImagePropertyGPSDateStamp, "DateStamp"),
        (kCGImagePropertyGPSDestBearing, "DestBearing"),
        (kCGImagePropertyGPSDestBearingRef, "DestBearingRef"),
        (kCGImagePropertyGPSDestDistance, "DestDistance"),
        (kCGImagePropertyGPSDestDistanceRef, "DestDistanceRef"),
        (kCGImagePropertyGPSDestLatitude, "DestLatitude"),
        (kCGImagePropertyGPSDestLatitudeRef, "DestLatitudeRef"),
        (kCGImagePropertyGPSDestLongitude, "DestLongitude"),
        (kCGImagePropertyGPSDestLongitudeRef, "DestLongitudeRef"),
        (kCGImagePropertyGPSDictionary, "{GPS}"),
        (kCGImagePropertyGPSDifferental, "Differential"),
        (kCGImagePropertyGPSHPositioningError, "HPositioningError"),
        (kCGImagePropertyGPSImgDirection, "ImgDirection"),
        (kCGImagePropertyGPSImgDirectionRef, "ImgDirectionRef"),
        (kCGImagePropertyGPSLatitude, "Latitude"),
        (kCGImagePropertyGPSLatitudeRef, "LatitudeRef"),
        (kCGImagePropertyGPSLongitude, "Longitude"),
        (kCGImagePropertyGPSLongitudeRef, "LongitudeRef"),
        (kCGImagePropertyGPSMapDatum, "MapDatum"),
        (kCGImagePropertyGPSMeasureMode, "MeasureMode"),
        (kCGImagePropertyGPSProcessingMethod, "ProcessingMethod"),
        (kCGImagePropertyGPSSatellites, "Satellites"),
        (kCGImagePropertyGPSSpeed, "Speed"),
        (kCGImagePropertyGPSSpeedRef, "SpeedRef"),
        (kCGImagePropertyGPSStatus, "Status"),
        (kCGImagePropertyGPSTimeStamp, "TimeStamp"),
        (kCGImagePropertyGPSTrack, "Track"),
        (kCGImagePropertyGPSTrackRef, "TrackRef"),
        (kCGImagePropertyGPSVersion, "GPSVersion"),
        (kCGImagePropertyGroupImageBaseline, "GroupImageBaseline"),
        (kCGImagePropertyGroupImageDisparityAdjustment, "GroupImageDisparityAdjustment"),
        (kCGImagePropertyGroupImageIndexLeft, "GroupImageIndexLeft"),
        (kCGImagePropertyGroupImageIndexMonoscopic, "GroupImageIndexMonoscopic"),
        (kCGImagePropertyGroupImageIndexRight, "GroupImageIndexRight"),
        (kCGImagePropertyGroupImageIsAlternateImage, "GroupImageIsAlternateImage"),
        (kCGImagePropertyGroupImageIsLeftImage, "GroupImageIsLeftImage"),
        (kCGImagePropertyGroupImageIsMonoscopicImage, "GroupImageIsMonoscopicImage"),
        (kCGImagePropertyGroupImageIsRightImage, "GroupImageIsRightImage"),
        (kCGImagePropertyGroupImageStereoAggressors, "GroupImageStereoAggressors"),
        (kCGImagePropertyGroupImagesAlternate, "GroupImages"),
        (kCGImagePropertyGroupIndex, "GroupIndex"),
        (kCGImagePropertyGroupMonoscopicImageLocation, "GroupImageIndexMonoscopicImageLocation"),
        (kCGImagePropertyGroupType, "GroupType"),
        (kCGImagePropertyGroupTypeAlternate, "Alternate"),
        (kCGImagePropertyGroupTypeStereoPair, "StereoPair"),
        (kCGImagePropertyGroups, "{Groups}"),
        (kCGImagePropertyHEICSCanvasPixelHeight, "CanvasPixelHeight"),
        (kCGImagePropertyHEICSCanvasPixelWidth, "CanvasPixelWidth"),
        (kCGImagePropertyHEICSDelayTime, "DelayTime"),
        (kCGImagePropertyHEICSDictionary, "{HEICS}"),
        (kCGImagePropertyHEICSFrameInfoArray, "FrameInfo"),
        (kCGImagePropertyHEICSLoopCount, "LoopCount"),
        (kCGImagePropertyHEICSUnclampedDelayTime, "UnclampedDelayTime"),
        (kCGImagePropertyHEIFDictionary, "{HEIF}"),
        (kCGImagePropertyHasAlpha, "HasAlpha"),
        (kCGImagePropertyHeight, "Height"),
        (kCGImagePropertyIPTCActionAdvised, "ActionAdvised"),
        (kCGImagePropertyIPTCByline, "Byline"),
        (kCGImagePropertyIPTCBylineTitle, "BylineTitle"),
        (kCGImagePropertyIPTCCaptionAbstract, "Caption/Abstract"),
        (kCGImagePropertyIPTCCategory, "Category"),
        (kCGImagePropertyIPTCCity, "City"),
        (kCGImagePropertyIPTCContact, "Contact"),
        (kCGImagePropertyIPTCContactInfoAddress, "CiAdrExtadr"),
        (kCGImagePropertyIPTCContactInfoCity, "CiAdrCity"),
        (kCGImagePropertyIPTCContactInfoCountry, "CiAdrCtry"),
        (kCGImagePropertyIPTCContactInfoEmails, "CiEmailWork"),
        (kCGImagePropertyIPTCContactInfoPhones, "CiTelWork"),
        (kCGImagePropertyIPTCContactInfoPostalCode, "CiAdrPcode"),
        (kCGImagePropertyIPTCContactInfoStateProvince, "CiAdrRegion"),
        (kCGImagePropertyIPTCContactInfoWebURLs, "CiUrlWork"),
        (kCGImagePropertyIPTCContentLocationCode, "ContentLocationCode"),
        (kCGImagePropertyIPTCContentLocationName, "ContentLocationName"),
        (kCGImagePropertyIPTCCopyrightNotice, "CopyrightNotice"),
        (kCGImagePropertyIPTCCountryPrimaryLocationCode, "Country/PrimaryLocationCode"),
        (kCGImagePropertyIPTCCountryPrimaryLocationName, "Country/PrimaryLocationName"),
        (kCGImagePropertyIPTCCreatorContactInfo, "CreatorContactInfo"),
        (kCGImagePropertyIPTCCredit, "Credit"),
        (kCGImagePropertyIPTCDateCreated, "DateCreated"),
        (kCGImagePropertyIPTCDictionary, "{IPTC}"),
        (kCGImagePropertyIPTCDigitalCreationDate, "DigitalCreationDate"),
        (kCGImagePropertyIPTCDigitalCreationTime, "DigitalCreationTime"),
        (kCGImagePropertyIPTCEditStatus, "EditStatus"),
        (kCGImagePropertyIPTCEditorialUpdate, "EditorialUpdate"),
        (kCGImagePropertyIPTCExpirationDate, "ExpirationDate"),
        (kCGImagePropertyIPTCExpirationTime, "ExpirationTime"),
        (kCGImagePropertyIPTCExtAboutCvTerm, "AboutCvTerm"),
        (kCGImagePropertyIPTCExtAboutCvTermCvId, "AboutCvTermCvId"),
        (kCGImagePropertyIPTCExtAboutCvTermId, "AboutCvTermId"),
        (kCGImagePropertyIPTCExtAboutCvTermName, "AboutCvTermName"),
        (kCGImagePropertyIPTCExtAboutCvTermRefinedAbout, "AboutCvTermRefinedAbout"),
        (kCGImagePropertyIPTCExtAddlModelInfo, "AddlModelInfo"),
        (kCGImagePropertyIPTCExtArtworkCircaDateCreated, "ArtworkCircaDateCreated"),
        (kCGImagePropertyIPTCExtArtworkContentDescription, "ArtworkContentDescription"),
        (kCGImagePropertyIPTCExtArtworkContributionDescription, "ArtworkContributionDescription"),
        (kCGImagePropertyIPTCExtArtworkCopyrightNotice, "ArtworkCopyrightNotice"),
        (kCGImagePropertyIPTCExtArtworkCopyrightOwnerID, "ArtworkCopyrightOwnerID"),
        (kCGImagePropertyIPTCExtArtworkCopyrightOwnerName, "ArtworkCopyrightOwnerName"),
        (kCGImagePropertyIPTCExtArtworkCreator, "ArtworkCreator"),
        (kCGImagePropertyIPTCExtArtworkCreatorID, "ArtworkCreatorID"),
        (kCGImagePropertyIPTCExtArtworkDateCreated, "ArtworkDateCreated"),
        (kCGImagePropertyIPTCExtArtworkLicensorID, "ArtworkLicensorID"),
        (kCGImagePropertyIPTCExtArtworkLicensorName, "ArtworkLicensorName"),
        (kCGImagePropertyIPTCExtArtworkOrObject, "ArtworkOrObject"),
        (kCGImagePropertyIPTCExtArtworkPhysicalDescription, "ArtworkPhysicalDescription"),
        (kCGImagePropertyIPTCExtArtworkSource, "ArtworkSource"),
        (kCGImagePropertyIPTCExtArtworkSourceInvURL, "ArtworkSourceInvURL"),
        (kCGImagePropertyIPTCExtArtworkSourceInventoryNo, "ArtworkSourceInventoryNo"),
        (kCGImagePropertyIPTCExtArtworkStylePeriod, "ArtworkStylePeriod"),
        (kCGImagePropertyIPTCExtArtworkTitle, "ArtworkTitle"),
        (kCGImagePropertyIPTCExtAudioBitrate, "AudioBitrate"),
        (kCGImagePropertyIPTCExtAudioBitrateMode, "AudioBitrateMode"),
        (kCGImagePropertyIPTCExtAudioChannelCount, "AudioChannelCount"),
        (kCGImagePropertyIPTCExtCircaDateCreated, "CircaDateCreated"),
        (kCGImagePropertyIPTCExtContainerFormat, "ContainerFormat"),
        (kCGImagePropertyIPTCExtContainerFormatIdentifier, "ContainerFormatIdentifier"),
        (kCGImagePropertyIPTCExtContainerFormatName, "ContainerFormatName"),
        (kCGImagePropertyIPTCExtContributor, "Contributor"),
        (kCGImagePropertyIPTCExtContributorIdentifier, "ContributorIdentifier"),
        (kCGImagePropertyIPTCExtContributorName, "ContributorName"),
        (kCGImagePropertyIPTCExtContributorRole, "ContributorRole"),
        (kCGImagePropertyIPTCExtControlledVocabularyTerm, "ControlledVocabularyTerm"),
        (kCGImagePropertyIPTCExtCopyrightYear, "CopyrightYear"),
        (kCGImagePropertyIPTCExtCreator, "Creator"),
        (kCGImagePropertyIPTCExtCreatorIdentifier, "CreatorIdentifier"),
        (kCGImagePropertyIPTCExtCreatorName, "CreatorName"),
        (kCGImagePropertyIPTCExtCreatorRole, "CreatorRole"),
        (kCGImagePropertyIPTCExtDataOnScreen, "DataOnScreen"),
        (kCGImagePropertyIPTCExtDataOnScreenRegion, "DataOnScreenRegion"),
        (kCGImagePropertyIPTCExtDataOnScreenRegionD, "DataOnScreenRegionD"),
        (kCGImagePropertyIPTCExtDataOnScreenRegionH, "DataOnScreenRegionH"),
        (kCGImagePropertyIPTCExtDataOnScreenRegionText, "DataOnScreenRegionText"),
        (kCGImagePropertyIPTCExtDataOnScreenRegionUnit, "DataOnScreenRegionUnit"),
        (kCGImagePropertyIPTCExtDataOnScreenRegionW, "DataOnScreenRegionW"),
        (kCGImagePropertyIPTCExtDataOnScreenRegionX, "DataOnScreenRegionX"),
        (kCGImagePropertyIPTCExtDataOnScreenRegionY, "DataOnScreenRegionY"),
        (kCGImagePropertyIPTCExtDigitalImageGUID, "DigitalImageGUID"),
        (kCGImagePropertyIPTCExtDigitalSourceFileType, "DigitalSourceFileType"),
        (kCGImagePropertyIPTCExtDigitalSourceType, "DigitalSourceType"),
        (kCGImagePropertyIPTCExtDopesheet, "Dopesheet"),
        (kCGImagePropertyIPTCExtDopesheetLink, "DopesheetLink"),
        (kCGImagePropertyIPTCExtDopesheetLinkLink, "DopesheetLinkLink"),
        (kCGImagePropertyIPTCExtDopesheetLinkLinkQualifier, "DopesheetLinkLinkQualifier"),
        (kCGImagePropertyIPTCExtEmbdEncRightsExpr, "EmbdEncRightsExpr"),
        (kCGImagePropertyIPTCExtEmbeddedEncodedRightsExpr, "EmbeddedEncodedRightsExpr"),
        (kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprLangID, "EmbeddedEncodedRightsExprLangID"),
        (kCGImagePropertyIPTCExtEmbeddedEncodedRightsExprType, "EmbeddedEncodedRightsExprType"),
        (kCGImagePropertyIPTCExtEpisode, "Episode"),
        (kCGImagePropertyIPTCExtEpisodeIdentifier, "EpisodeIdentifier"),
        (kCGImagePropertyIPTCExtEpisodeName, "EpisodeName"),
        (kCGImagePropertyIPTCExtEpisodeNumber, "EpisodeNumber"),
        (kCGImagePropertyIPTCExtEvent, "Event"),
        (kCGImagePropertyIPTCExtExternalMetadataLink, "ExternalMetadataLink"),
        (kCGImagePropertyIPTCExtFeedIdentifier, "FeedIdentifier"),
        (kCGImagePropertyIPTCExtGenre, "Genre"),
        (kCGImagePropertyIPTCExtGenreCvId, "GenreCvId"),
        (kCGImagePropertyIPTCExtGenreCvTermId, "GenreCvTermId"),
        (kCGImagePropertyIPTCExtGenreCvTermName, "GenreCvTermName"),
        (kCGImagePropertyIPTCExtGenreCvTermRefinedAbout, "GenreCvTermRefinedAbout"),
        (kCGImagePropertyIPTCExtHeadline, "Headline"),
        (kCGImagePropertyIPTCExtIPTCLastEdited, "IPTCLastEdited"),
        (kCGImagePropertyIPTCExtLinkedEncRightsExpr, "LinkedEncRightsExpr"),
        (kCGImagePropertyIPTCExtLinkedEncodedRightsExpr, "LinkedEncodedRightsExpr"),
        (kCGImagePropertyIPTCExtLinkedEncodedRightsExprLangID, "LinkedEncodedRightsExprLangID"),
        (kCGImagePropertyIPTCExtLinkedEncodedRightsExprType, "LinkedEncodedRightsExprType"),
        (kCGImagePropertyIPTCExtLocationCity, "City"),
        (kCGImagePropertyIPTCExtLocationCountryCode, "CountryCode"),
        (kCGImagePropertyIPTCExtLocationCountryName, "CountryName"),
        (kCGImagePropertyIPTCExtLocationCreated, "LocationCreated"),
        (kCGImagePropertyIPTCExtLocationGPSAltitude, "GPSAltitude"),
        (kCGImagePropertyIPTCExtLocationGPSLatitude, "GPSLatitude"),
        (kCGImagePropertyIPTCExtLocationGPSLongitude, "GPSLongitude"),
        (kCGImagePropertyIPTCExtLocationIdentifier, "Identifier"),
        (kCGImagePropertyIPTCExtLocationLocationId, "LocationId"),
        (kCGImagePropertyIPTCExtLocationLocationName, "LocationName"),
        (kCGImagePropertyIPTCExtLocationProvinceState, "ProvinceState"),
        (kCGImagePropertyIPTCExtLocationShown, "LocationShown"),
        (kCGImagePropertyIPTCExtLocationSublocation, "Sublocation"),
        (kCGImagePropertyIPTCExtLocationWorldRegion, "WorldRegion"),
        (kCGImagePropertyIPTCExtMaxAvailHeight, "MaxAvailHeight"),
        (kCGImagePropertyIPTCExtMaxAvailWidth, "MaxAvailWidth"),
        (kCGImagePropertyIPTCExtModelAge, "ModelAge"),
        (kCGImagePropertyIPTCExtOrganisationInImageCode, "OrganisationInImageCode"),
        (kCGImagePropertyIPTCExtOrganisationInImageName, "OrganisationInImageName"),
        (kCGImagePropertyIPTCExtPersonHeard, "PersonHeard"),
        (kCGImagePropertyIPTCExtPersonHeardIdentifier, "PersonHeardIdentifier"),
        (kCGImagePropertyIPTCExtPersonHeardName, "PersonHeardName"),
        (kCGImagePropertyIPTCExtPersonInImage, "PersonInImage"),
        (kCGImagePropertyIPTCExtPersonInImageCharacteristic, "PersonInImageCharacteristic"),
        (kCGImagePropertyIPTCExtPersonInImageCvTermCvId, "PersonInImageCvTermCvId"),
        (kCGImagePropertyIPTCExtPersonInImageCvTermId, "PersonInImageCvTermId"),
        (kCGImagePropertyIPTCExtPersonInImageCvTermName, "PersonInImageCvTermName"),
        (kCGImagePropertyIPTCExtPersonInImageCvTermRefinedAbout, "PersonInImageCvTermRefinedAbout"),
        (kCGImagePropertyIPTCExtPersonInImageDescription, "PersonInImageDescription"),
        (kCGImagePropertyIPTCExtPersonInImageId, "PersonInImageId"),
        (kCGImagePropertyIPTCExtPersonInImageName, "PersonInImageName"),
        (kCGImagePropertyIPTCExtPersonInImageWDetails, "PersonInImageWDetails"),
        (kCGImagePropertyIPTCExtProductInImage, "ProductInImage"),
        (kCGImagePropertyIPTCExtProductInImageDescription, "ProductInImageDescription"),
        (kCGImagePropertyIPTCExtProductInImageGTIN, "ProductInImageGTIN"),
        (kCGImagePropertyIPTCExtProductInImageName, "ProductInImageName"),
        (kCGImagePropertyIPTCExtPublicationEvent, "PublicationEvent"),
        (kCGImagePropertyIPTCExtPublicationEventDate, "PublicationEventDate"),
        (kCGImagePropertyIPTCExtPublicationEventIdentifier, "PublicationEventIdentifier"),
        (kCGImagePropertyIPTCExtPublicationEventName, "PublicationEventName"),
        (kCGImagePropertyIPTCExtRating, "Rating"),
        (kCGImagePropertyIPTCExtRatingRatingRegion, "RatingRatingRegion"),
        (kCGImagePropertyIPTCExtRatingRegionCity, "RatingRegionCity"),
        (kCGImagePropertyIPTCExtRatingRegionCountryCode, "RatingRegionCountryCode"),
        (kCGImagePropertyIPTCExtRatingRegionCountryName, "RatingRegionCountryName"),
        (kCGImagePropertyIPTCExtRatingRegionGPSAltitude, "RatingRegionGPSAltitude"),
        (kCGImagePropertyIPTCExtRatingRegionGPSLatitude, "RatingRegionGPSLatitude"),
        (kCGImagePropertyIPTCExtRatingRegionGPSLongitude, "RatingRegionGPSLongitude"),
        (kCGImagePropertyIPTCExtRatingRegionIdentifier, "RatingRegionIdentifier"),
        (kCGImagePropertyIPTCExtRatingRegionLocationId, "RatingRegionLocationId"),
        (kCGImagePropertyIPTCExtRatingRegionLocationName, "RatingRegionLocationName"),
        (kCGImagePropertyIPTCExtRatingRegionProvinceState, "RatingRegionProvinceState"),
        (kCGImagePropertyIPTCExtRatingRegionSublocation, "RatingRegionSublocation"),
        (kCGImagePropertyIPTCExtRatingRegionWorldRegion, "RatingRegionWorldRegion"),
        (kCGImagePropertyIPTCExtRatingScaleMaxValue, "RatingScaleMaxValue"),
        (kCGImagePropertyIPTCExtRatingScaleMinValue, "RatingScaleMinValue"),
        (kCGImagePropertyIPTCExtRatingSourceLink, "RatingSourceLink"),
        (kCGImagePropertyIPTCExtRatingValue, "RatingValue"),
        (kCGImagePropertyIPTCExtRatingValueLogoLink, "RatingValueLogoLink"),
        (kCGImagePropertyIPTCExtRegistryEntryRole, "RegistryEntryRole"),
        (kCGImagePropertyIPTCExtRegistryID, "RegistryID"),
        (kCGImagePropertyIPTCExtRegistryItemID, "RegistryItemID"),
        (kCGImagePropertyIPTCExtRegistryOrganisationID, "RegistryOrganisationID"),
        (kCGImagePropertyIPTCExtReleaseReady, "ReleaseReady"),
        (kCGImagePropertyIPTCExtSeason, "Season"),
        (kCGImagePropertyIPTCExtSeasonIdentifier, "SeasonIdentifier"),
        (kCGImagePropertyIPTCExtSeasonName, "SeasonName"),
        (kCGImagePropertyIPTCExtSeasonNumber, "SeasonNumber"),
        (kCGImagePropertyIPTCExtSeries, "Series"),
        (kCGImagePropertyIPTCExtSeriesIdentifier, "SeriesIdentifier"),
        (kCGImagePropertyIPTCExtSeriesName, "SeriesName"),
        (kCGImagePropertyIPTCExtShownEvent, "ShownEvent"),
        (kCGImagePropertyIPTCExtShownEventIdentifier, "ShownEventIdentifier"),
        (kCGImagePropertyIPTCExtShownEventName, "ShownEventName"),
        (kCGImagePropertyIPTCExtStorylineIdentifier, "StorylineIdentifier"),
        (kCGImagePropertyIPTCExtStreamReady, "StreamReady"),
        (kCGImagePropertyIPTCExtStylePeriod, "StylePeriod"),
        (kCGImagePropertyIPTCExtSupplyChainSource, "SupplyChainSource"),
        (kCGImagePropertyIPTCExtSupplyChainSourceIdentifier, "SupplyChainSourceIdentifier"),
        (kCGImagePropertyIPTCExtSupplyChainSourceName, "SupplyChainSourceName"),
        (kCGImagePropertyIPTCExtTemporalCoverage, "TemporalCoverage"),
        (kCGImagePropertyIPTCExtTemporalCoverageFrom, "TemporalCoverageFrom"),
        (kCGImagePropertyIPTCExtTemporalCoverageTo, "TemporalCoverageTo"),
        (kCGImagePropertyIPTCExtTranscript, "Transcript"),
        (kCGImagePropertyIPTCExtTranscriptLink, "TranscriptLink"),
        (kCGImagePropertyIPTCExtTranscriptLinkLink, "TranscriptLinkLink"),
        (kCGImagePropertyIPTCExtTranscriptLinkLinkQualifier, "TranscriptLinkLinkQualifier"),
        (kCGImagePropertyIPTCExtVideoBitrate, "VideoBitrate"),
        (kCGImagePropertyIPTCExtVideoBitrateMode, "VideoBitrateMode"),
        (kCGImagePropertyIPTCExtVideoDisplayAspectRatio, "VideoDisplayAspectRatio"),
        (kCGImagePropertyIPTCExtVideoEncodingProfile, "VideoEncodingProfile"),
        (kCGImagePropertyIPTCExtVideoShotType, "VideoShotType"),
        (kCGImagePropertyIPTCExtVideoShotTypeIdentifier, "VideoShotTypeIdentifier"),
        (kCGImagePropertyIPTCExtVideoShotTypeName, "VideoShotTypeName"),
        (kCGImagePropertyIPTCExtVideoStreamsCount, "VideoStreamsCount"),
        (kCGImagePropertyIPTCExtVisualColor, "VisualColor"),
        (kCGImagePropertyIPTCExtWorkflowTag, "WorkflowTag"),
        (kCGImagePropertyIPTCExtWorkflowTagCvId, "WorkflowTagCvId"),
        (kCGImagePropertyIPTCExtWorkflowTagCvTermId, "WorkflowTagCvTermId"),
        (kCGImagePropertyIPTCExtWorkflowTagCvTermName, "WorkflowTagCvTermName"),
        (kCGImagePropertyIPTCExtWorkflowTagCvTermRefinedAbout, "WorkflowTagCvTermRefinedAbout"),
        (kCGImagePropertyIPTCFixtureIdentifier, "FixtureIdentifier"),
        (kCGImagePropertyIPTCHeadline, "Headline"),
        (kCGImagePropertyIPTCImageOrientation, "ImageOrientation"),
        (kCGImagePropertyIPTCImageType, "ImageType"),
        (kCGImagePropertyIPTCKeywords, "Keywords"),
        (kCGImagePropertyIPTCLanguageIdentifier, "LanguageIdentifier"),
        (kCGImagePropertyIPTCObjectAttributeReference, "ObjectAttributeReference"),
        (kCGImagePropertyIPTCObjectCycle, "ObjectCycle"),
        (kCGImagePropertyIPTCObjectName, "ObjectName"),
        (kCGImagePropertyIPTCObjectTypeReference, "ObjectTypeReference"),
        (kCGImagePropertyIPTCOriginalTransmissionReference, "OriginalTransmissionReference"),
        (kCGImagePropertyIPTCOriginatingProgram, "OriginatingProgram"),
        (kCGImagePropertyIPTCProgramVersion, "ProgramVersion"),
        (kCGImagePropertyIPTCProvinceState, "Province/State"),
        (kCGImagePropertyIPTCReferenceDate, "ReferenceDate"),
        (kCGImagePropertyIPTCReferenceNumber, "ReferenceNumber"),
        (kCGImagePropertyIPTCReferenceService, "ReferenceService"),
        (kCGImagePropertyIPTCReleaseDate, "ReleaseDate"),
        (kCGImagePropertyIPTCReleaseTime, "ReleaseTime"),
        (kCGImagePropertyIPTCRightsUsageTerms, "UsageTerms"),
        (kCGImagePropertyIPTCScene, "Scene"),
        (kCGImagePropertyIPTCSource, "Source"),
        (kCGImagePropertyIPTCSpecialInstructions, "SpecialInstructions"),
        (kCGImagePropertyIPTCStarRating, "StarRating"),
        (kCGImagePropertyIPTCSubLocation, "SubLocation"),
        (kCGImagePropertyIPTCSubjectReference, "SubjectReference"),
        (kCGImagePropertyIPTCSupplementalCategory, "SupplementalCategory"),
        (kCGImagePropertyIPTCTimeCreated, "TimeCreated"),
        (kCGImagePropertyIPTCUrgency, "Urgency"),
        (kCGImagePropertyIPTCWriterEditor, "Writer/Editor"),
        (kCGImagePropertyImageCount, "ImageCount"),
        (kCGImagePropertyImageIndex, "ImageIndex"),
        (kCGImagePropertyImages, "Images"),
        (kCGImagePropertyIsFloat, "IsFloat"),
        (kCGImagePropertyIsIndexed, "IsIndexed"),
        (kCGImagePropertyJFIFDensityUnit, "DensityUnit"),
        (kCGImagePropertyJFIFDictionary, "{JFIF}"),
        (kCGImagePropertyJFIFIsProgressive, "IsProgressive"),
        (kCGImagePropertyJFIFVersion, "JFIFVersion"),
        (kCGImagePropertyJFIFXDensity, "XDensity"),
        (kCGImagePropertyJFIFYDensity, "YDensity"),
        (kCGImagePropertyMakerAppleDictionary, "{MakerApple}"),
        (kCGImagePropertyMakerCanonAspectRatioInfo, "AspectRatioInfo"),
        (kCGImagePropertyMakerCanonCameraSerialNumber, "CameraSerialNumber"),
        (kCGImagePropertyMakerCanonContinuousDrive, "ContinuousDrive"),
        (kCGImagePropertyMakerCanonDictionary, "{MakerCanon}"),
        (kCGImagePropertyMakerCanonFirmware, "Firmware"),
        (kCGImagePropertyMakerCanonFlashExposureComp, "FlashExposureComp"),
        (kCGImagePropertyMakerCanonImageSerialNumber, "ImageSerialNumber"),
        (kCGImagePropertyMakerCanonLensModel, "LensModel"),
        (kCGImagePropertyMakerCanonOwnerName, "OwnerName"),
        (kCGImagePropertyMakerFujiDictionary, "{MakerFuji}"),
        (kCGImagePropertyMakerMinoltaDictionary, "{MakerMinolta}"),
        (kCGImagePropertyMakerNikonCameraSerialNumber, "CameraSerialNumber"),
        (kCGImagePropertyMakerNikonColorMode, "ColorMode"),
        (kCGImagePropertyMakerNikonDictionary, "{MakerNikon}"),
        (kCGImagePropertyMakerNikonDigitalZoom, "DigitalZoom"),
        (kCGImagePropertyMakerNikonFlashExposureComp, "FlashExposureComp"),
        (kCGImagePropertyMakerNikonFlashSetting, "FlashSetting"),
        (kCGImagePropertyMakerNikonFocusDistance, "FocusDistance"),
        (kCGImagePropertyMakerNikonFocusMode, "FocusMode"),
        (kCGImagePropertyMakerNikonISOSelection, "ISOSelection"),
        (kCGImagePropertyMakerNikonISOSetting, "ISOSetting"),
        (kCGImagePropertyMakerNikonImageAdjustment, "ImageAdjustment"),
        (kCGImagePropertyMakerNikonLensAdapter, "LensAdapter"),
        (kCGImagePropertyMakerNikonLensInfo, "LensInfo"),
        (kCGImagePropertyMakerNikonLensType, "LensType"),
        (kCGImagePropertyMakerNikonQuality, "Quality"),
        (kCGImagePropertyMakerNikonSharpenMode, "SharpenMode"),
        (kCGImagePropertyMakerNikonShootingMode, "ShootingMode"),
        (kCGImagePropertyMakerNikonShutterCount, "ShutterCount"),
        (kCGImagePropertyMakerNikonWhiteBalanceMode, "WhiteBalanceMode"),
        (kCGImagePropertyMakerOlympusDictionary, "{MakerOlympus}"),
        (kCGImagePropertyMakerPentaxDictionary, "{MakerPentax}"),
        (kCGImagePropertyNamedColorSpace, "NamedColorSpace"),
        (kCGImagePropertyOpenEXRAspectRatio, "AspectRatio"),
        (kCGImagePropertyOpenEXRCompression, "Compression"),
        (kCGImagePropertyOpenEXRDictionary, "{EXR}"),
        (kCGImagePropertyOrientation, "Orientation"),
        (kCGImagePropertyPNGAuthor, "Author"),
        (kCGImagePropertyPNGChromaticities, "Chromaticities"),
        (kCGImagePropertyPNGComment, "Comment"),
        (kCGImagePropertyPNGCompressionFilter, "kCGImagePropertyPNGCompressionFilter"),
        (kCGImagePropertyPNGCopyright, "Copyright"),
        (kCGImagePropertyPNGCreationTime, "Creation Time"),
        (kCGImagePropertyPNGDescription, "Description"),
        (kCGImagePropertyPNGDictionary, "{PNG}"),
        (kCGImagePropertyPNGDisclaimer, "Disclaimer"),
        (kCGImagePropertyPNGGamma, "Gamma"),
        (kCGImagePropertyPNGInterlaceType, "InterlaceType"),
        (kCGImagePropertyPNGModificationTime, "ModificationTime"),
        (kCGImagePropertyPNGPixelsAspectRatio, "PixelAspectRatio"),
        (kCGImagePropertyPNGSoftware, "Software"),
        (kCGImagePropertyPNGSource, "Source"),
        (kCGImagePropertyPNGTitle, "Title"),
        (kCGImagePropertyPNGTransparency, "kCGImagePropertyPNGTransparency"),
        (kCGImagePropertyPNGWarning, "Warning"),
        (kCGImagePropertyPNGXPixelsPerMeter, "XPixelsPerMeter"),
        (kCGImagePropertyPNGYPixelsPerMeter, "YPixelsPerMeter"),
        (kCGImagePropertyPNGsRGBIntent, "sRGBIntent"),
        (kCGImagePropertyPVREncoder, "kCGImagePropertyPVREncoder"),
        (kCGImagePropertyPixelFormat, "PixelFormat"),
        (kCGImagePropertyPixelHeight, "PixelHeight"),
        (kCGImagePropertyPixelWidth, "PixelWidth"),
        (kCGImagePropertyPrimaryImage, "PrimaryImage"),
        (kCGImagePropertyProfileName, "ProfileName"),
        (kCGImagePropertyRawDictionary, "{Raw}"),
        (kCGImagePropertyTGACompression, "Compression"),
        (kCGImagePropertyTGADictionary, "{TGA}"),
        (kCGImagePropertyTIFFArtist, "Artist"),
        (kCGImagePropertyTIFFCompression, "Compression"),
        (kCGImagePropertyTIFFCopyright, "Copyright"),
        (kCGImagePropertyTIFFDateTime, "DateTime"),
        (kCGImagePropertyTIFFDictionary, "{TIFF}"),
        (kCGImagePropertyTIFFDocumentName, "DocumentName"),
        (kCGImagePropertyTIFFHostComputer, "HostComputer"),
        (kCGImagePropertyTIFFImageDescription, "ImageDescription"),
        (kCGImagePropertyTIFFMake, "Make"),
        (kCGImagePropertyTIFFModel, "Model"),
        (kCGImagePropertyTIFFOrientation, "Orientation"),
        (kCGImagePropertyTIFFPhotometricInterpretation, "PhotometricInterpretation"),
        (kCGImagePropertyTIFFPrimaryChromaticities, "PrimaryChromaticities"),
        (kCGImagePropertyTIFFResolutionUnit, "ResolutionUnit"),
        (kCGImagePropertyTIFFSoftware, "Software"),
        (kCGImagePropertyTIFFTileLength, "TileLength"),
        (kCGImagePropertyTIFFTileWidth, "TileWidth"),
        (kCGImagePropertyTIFFTransferFunction, "TransferFunction"),
        (kCGImagePropertyTIFFWhitePoint, "WhitePoint"),
        (kCGImagePropertyTIFFXPosition, "XPosition"),
        (kCGImagePropertyTIFFXResolution, "XResolution"),
        (kCGImagePropertyTIFFYPosition, "YPosition"),
        (kCGImagePropertyTIFFYResolution, "YResolution"),
        (kCGImagePropertyThumbnailImages, "ThumbnailImages"),
        (kCGImagePropertyWebPCanvasPixelHeight, "CanvasPixelHeight"),
        (kCGImagePropertyWebPCanvasPixelWidth, "CanvasPixelWidth"),
        (kCGImagePropertyWebPDelayTime, "DelayTime"),
        (kCGImagePropertyWebPDictionary, "{WebP}"),
        (kCGImagePropertyWebPFrameInfoArray, "FrameInfo"),
        (kCGImagePropertyWebPLoopCount, "LoopCount"),
        (kCGImagePropertyWebPUnclampedDelayTime, "UnclampedDelayTime"),
        (kCGImagePropertyWidth, "Width"),
        (kCGImageProviderPreferredTileHeight, "kCGImageProviderPreferredTileHeight"),
        (kCGImageProviderPreferredTileWidth, "kCGImageProviderPreferredTileWidth"),
        (kCGImageSourceCreateThumbnailFromImageAlways, "kCGImageSourceCreateThumbnailFromImageAlways"),
        (kCGImageSourceCreateThumbnailFromImageIfAbsent, "kCGImageSourceCreateThumbnailFromImageIfAbsent"),
        (kCGImageSourceCreateThumbnailWithTransform, "kCGImageSourceCreateThumbnailWithTransform"),
        (kCGImageSourceDecodeRequest, "kCGImageSourceDecodeRequest"),
        (kCGImageSourceDecodeRequestOptions, "kCGImageSourceDecodeRequestOptions"),
        (kCGImageSourceDecodeToHDR, "kCGImageSourceDecodeToHDR"),
        (kCGImageSourceDecodeToSDR, "kCGImageSourceDecodeToSDR"),
        (kCGImageSourceGenerateImageSpecificLumaScaling, "kCGImageSourceGenerateImageSpecificLumaScaling"),
        (kCGImageSourceShouldAllowFloat, "kCGImageSourceShouldAllowFloat"),
        (kCGImageSourceShouldCache, "kCGImageSourceShouldCache"),
        (kCGImageSourceShouldCacheImmediately, "kCGImageSourceShouldCacheImmediately"),
        (kCGImageSourceSubsampleFactor, "kCGImageSourceSubsampleFactor"),
        (kCGImageSourceThumbnailMaxPixelSize, "kCGImageSourceThumbnailMaxPixelSize"),
        (kCGImageSourceTypeIdentifierHint, "kCGImageSourceTypeIdentifierHint"),
        (kIIOCameraExtrinsics_CoordinateSystemID, "CoordinateSystemID"),
        (kIIOCameraExtrinsics_Position, "Position"),
        (kIIOCameraExtrinsics_Rotation, "Rotation"),
        (kIIOCameraModelType_GenericPinhole, "GenericPinhole"),
        (kIIOCameraModelType_SimplifiedPinhole, "SimplifiedPinhole"),
        (kIIOCameraModel_Intrinsics, "Intrinsics"),
        (kIIOCameraModel_ModelType, "ModelType"),
        (kIIOMetadata_CameraExtrinsicsKey, "CameraExtrinsics"),
        (kIIOMetadata_CameraModelKey, "CameraModel"),
        (kIIOMonoscopicImageLocation_Center, "Center"),
        (kIIOMonoscopicImageLocation_Left, "Left"),
        (kIIOMonoscopicImageLocation_Right, "Right"),
        (kIIOMonoscopicImageLocation_Unspecified, "Unspecified"),
        (kIIOStereoAggressors_Severity, "Severity"),
        (kIIOStereoAggressors_SubTypeURI, "SubTypeURI"),
        (kIIOStereoAggressors_Type, "Type")
    ]
    for (key, expected) in keys {
        require(key == expected, expected)
    }
    require(keys.count == 750, "count")
}

func testPNGFilterMacros() {
    // MEASURED 2026-09-05 Apple ImageIO Int32 macros.
    require(IIO_HAS_IOSURFACE == 1, "IIO_HAS_IOSURFACE")
    require(IMAGEIO_PNG_FILTER_AVG == 64, "IMAGEIO_PNG_FILTER_AVG")
    require(IMAGEIO_PNG_FILTER_NONE == 8, "IMAGEIO_PNG_FILTER_NONE")
    require(IMAGEIO_PNG_FILTER_PAETH == 128, "IMAGEIO_PNG_FILTER_PAETH")
    require(IMAGEIO_PNG_FILTER_SUB == 16, "IMAGEIO_PNG_FILTER_SUB")
    require(IMAGEIO_PNG_FILTER_UP == 32, "IMAGEIO_PNG_FILTER_UP")
    require(IMAGEIO_PNG_NO_FILTERS == 0, "IMAGEIO_PNG_NO_FILTERS")
}
