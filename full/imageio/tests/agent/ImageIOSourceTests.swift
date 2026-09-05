import Foundation
import ImageIO

func testSourceCreateFromPNGData() {
    let png = imageioFixtureData("sample-2x1.png")
    guard let source = CGImageSourceCreateWithData(png, nil) else { fatalError("png source") }
    imageioRequire(CGImageSourceGetType(source) == "public.png", "type")
    imageioRequire(CGImageSourceGetCount(source) == 1, "count")
    imageioRequire(CGImageSourceGetStatus(source) == .statusComplete, "status")
    imageioRequire(CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete, "idx status")
    imageioRequire(CGImageSourceGetPrimaryImageIndex(source) == 0, "primary")
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("png image")
    }
    imageioRequire(image.width == 2 && image.height == 1, "size")
    imageioRequire(image.pixels[0] == 255 && image.pixels[1] == 0 && image.pixels[2] == 0, "red")
    imageioRequire(image.pixels[4] == 0 && image.pixels[5] == 255, "green")
}

func testSourceCreateFromJPEGData() {
    let jpeg = imageioEncodedSample("public.jpeg")
    guard let source = CGImageSourceCreateWithData(jpeg, nil) else { fatalError("jpeg source") }
    imageioRequire(CGImageSourceGetType(source) == "public.jpeg", "type")
    imageioRequire(CGImageSourceGetCount(source) == 1, "count")
    imageioRequire(CGImageSourceGetStatus(source) == .statusComplete, "status")
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("jpeg image")
    }
    imageioRequire(image.width == 2 && image.height == 1, "size")
}

func testSourceCreateFromURL() {
    let png = imageioFixtureData("sample-2x1.png")
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("imageio-url-\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: url) }
    try! png.write(to: url)
    guard let fromURL = CGImageSourceCreateWithURL(url, nil) else { fatalError("url") }
    imageioRequire(CGImageSourceGetCount(fromURL) == 1, "url count")
    imageioRequire(CGImageSourceGetType(fromURL) == "public.png", "url type")
}

func testSourceCreateFromDataProvider() {
    let png = imageioFixtureData("sample-2x1.png")
    let provider = CGDataProvider(data: png)
    guard let fromProvider = CGImageSourceCreateWithDataProvider(provider, nil) else {
        fatalError("provider")
    }
    imageioRequire(CGImageSourceGetCount(fromProvider) == 1, "provider count")
    let incremental = CGImageSourceCreateIncremental(nil)
    CGImageSourceUpdateDataProvider(incremental, provider, true)
    imageioRequire(CGImageSourceGetStatus(incremental) == .statusComplete, "update provider")
}

func testSourceTypeIdentifiers() {
    let sourceTypes = CGImageSourceCopyTypeIdentifiers()
    imageioRequire(sourceTypes.contains { ($0 as? String) == "public.png" }, "png")
    imageioRequire(sourceTypes.contains { ($0 as? String) == "public.jpeg" }, "jpeg")
    imageioRequire(sourceTypes.contains { ($0 as? String) == "com.microsoft.bmp" }, "bmp")
    let destTypes = CGImageDestinationCopyTypeIdentifiers()
    imageioRequire(destTypes.contains { ($0 as? String) == "public.png" }, "dest png")
    imageioRequire(destTypes.contains { ($0 as? String) == "public.jpeg" }, "dest jpeg")
}

func testSourceAllowableTypes() {
    imageioRequire(CGImageSourceSetAllowableTypes(["public.png"]) == 0, "set")
    let png = imageioFixtureData("sample-2x1.png")
    imageioRequire(CGImageSourceCreateWithData(png, nil) != nil, "png still allowed")
    let bmp = imageioEncodedSample("com.microsoft.bmp")
    imageioRequire(CGImageSourceCreateWithData(bmp, nil) == nil, "bmp rejected")
    imageioRequire(CGImageSourceSetAllowableTypes([]) == -50, "empty")
    imageioRequire(
        CGImageSourceSetAllowableTypes([
            "public.png", "public.jpeg", "com.compuserve.gif", "com.microsoft.bmp",
        ]) == 0,
        "restore"
    )
    imageioRequire(CGImageSourceCreateWithData(bmp, nil) != nil, "bmp restored")
}

func testSourceInvalidDataStillReturnsSource() {
    // MEASURED 2026-09-05 Apple ImageIO: empty and garbage CreateWithData
    // still return a source (statusInvalidData, count 0, type nil).
    let empty = CGImageSourceCreateWithData(Data(), nil)
    imageioRequire(empty != nil, "empty src")
    imageioRequire(CGImageSourceGetStatus(empty!) == .statusInvalidData, "empty status")
    let garbage = CGImageSourceCreateWithData(Data([0, 1, 2, 3]), nil)
    imageioRequire(garbage != nil, "garbage src")
    imageioRequire(CGImageSourceGetStatus(garbage!) == .statusInvalidData, "garbage status")
    imageioRequire(CGImageSourceGetType(garbage!) == nil, "garbage type")
    imageioRequire(CGImageSourceGetCount(garbage!) == 0, "garbage count")
}

func testSourceIncrementalStatusProgression() {
    // MEASURED 2026-09-05: PNG type appears at 10 bytes. Incremental of a
    // typed prefix is statusIncomplete until UpdateData(..., true).
    let data = imageioFixtureData("sample-2x1.png")
    let source = CGImageSourceCreateIncremental(nil)
    imageioRequire(CGImageSourceGetStatus(source) == .statusInvalidData, "start")
    let prefix = Data(data.prefix(16))
    CGImageSourceUpdateData(source, prefix, false)
    imageioRequire(CGImageSourceGetType(source) == "public.png", "type from sig")
    imageioRequire(CGImageSourceGetStatus(source) == .statusIncomplete, "incomplete")
    CGImageSourceUpdateData(source, data, true)
    imageioRequire(CGImageSourceGetStatus(source) == .statusComplete, "complete")
    imageioRequire(CGImageSourceGetCount(source) == 1, "count")
    imageioRequire(CGImageSourceCreateImageAtIndex(source, 0, nil) != nil, "image")
}

func testSourceTruncatedPNGCreateWithData() {
    let data = imageioFixtureData("sample-2x1.png")
    let prefix = Data(data.prefix(16))
    guard let source = CGImageSourceCreateWithData(prefix, nil) else {
        fatalError("prefix src")
    }
    imageioRequire(CGImageSourceGetType(source) == "public.png", "type")
    imageioRequire(CGImageSourceGetStatus(source) == .statusComplete, "complete")
    imageioRequire(CGImageSourceCreateImageAtIndex(source, 0, nil) == nil, "no pixels")
}

func testSourcePNGPropertiesIHDRPHYS() {
    // MEASURED 2026-09-05 Apple ImageIO on probe-png-chunks.png (2×1 RGB):
    // pHYs 5669 ppm → DPIWidth/Height=144 because 5669*0.0254=143.9926,
    // rounded to 144. gAMA 45455 → Gamma=0.45455. tEXt Title=Hello →
    // {PNG}.Title and {IPTC}.ObjectName.
    let png = imageioFixtureData("probe-png-chunks.png")
    guard let source = CGImageSourceCreateWithData(png, nil) else {
        fatalError("chunk source")
    }
    imageioRequire(CGImageSourceGetType(source) == "public.png", "type")
    guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else {
        fatalError("props")
    }
    imageioRequire(imageioInt(props[kCGImagePropertyPixelWidth]) == 2, "width")
    imageioRequire(imageioInt(props[kCGImagePropertyPixelHeight]) == 1, "height")
    imageioRequire(imageioDouble(props[kCGImagePropertyDPIWidth]) == 144, "dpi w")
    imageioRequire(imageioDouble(props[kCGImagePropertyDPIHeight]) == 144, "dpi h")
    let pngDict = props[kCGImagePropertyPNGDictionary] as? [CFString: Any]
    imageioRequire(pngDict != nil, "png dict")
    imageioRequire((pngDict?[kCGImagePropertyPNGTitle] as? String) == "Hello", "title")
    let gamma = imageioDouble(pngDict?[kCGImagePropertyPNGGamma])
    imageioRequire(gamma != nil && abs(gamma! - 0.45455) < 0.00001, "gamma")
    imageioRequire(imageioInt(pngDict?[kCGImagePropertyPNGXPixelsPerMeter]) == 5669, "xppm")
    let iptc = props[kCGImagePropertyIPTCDictionary] as? [CFString: Any]
    imageioRequire((iptc?[kCGImagePropertyIPTCObjectName] as? String) == "Hello", "iptc")
    imageioRequire(CGImageSourceCopyPropertiesAtIndex(source, 9, nil) == nil, "oob")
    imageioRequire(CGImageSourceCopyProperties(source, nil) != nil, "container")
}

func testSourceJPEGPropertiesJFIFEXIF() {
    // MEASURED 2026-09-05: JPEG orientation 6 lands in TIFFOrientation and
    // the source Orientation key. Fixture is SOI+JFIF+Exif APP1+SOF 8×4.
    let jpeg = imageioFixtureData("jfif-exif-orientation6.jpg")
    guard let source = CGImageSourceCreateWithData(jpeg, nil) else {
        fatalError("jpeg source")
    }
    imageioRequire(CGImageSourceGetType(source) == "public.jpeg", "type")
    guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else {
        fatalError("props")
    }
    imageioRequire(imageioInt(props[kCGImagePropertyPixelWidth]) == 8, "width")
    imageioRequire(imageioInt(props[kCGImagePropertyPixelHeight]) == 4, "height")
    imageioRequire(imageioInt(props[kCGImagePropertyOrientation]) == 6, "orientation")
    let jfif = props[kCGImagePropertyJFIFDictionary] as? [CFString: Any]
    imageioRequire(jfif != nil, "jfif")
    imageioRequire(imageioInt(jfif?[kCGImagePropertyJFIFDensityUnit]) == 1, "unit")
    imageioRequire(imageioInt(jfif?[kCGImagePropertyJFIFXDensity]) == 72, "xden")
    let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
    imageioRequire(imageioInt(tiff?[kCGImagePropertyTIFFOrientation]) == 6, "tiff ori")
}

func testSourceGIFLoopCountFromFixture() {
    // MEASURED 2026-09-05: NETSCAPE loop field 3 → LoopCount 4 (field+1; 0 stays 0).
    let gif = imageioFixtureData("netscape-loop3.gif")
    let source = CGImageSourceCreateIncremental(nil)
    CGImageSourceUpdateData(source, gif, true)
    imageioRequire(CGImageSourceGetType(source) == "com.compuserve.gif", "type")
    guard let props = CGImageSourceCopyProperties(source, nil) else { fatalError("props") }
    let gifDict = props[kCGImagePropertyGIFDictionary] as? [CFString: Any]
    imageioRequire(imageioInt(gifDict?[kCGImagePropertyGIFLoopCount]) == 4, "loop")
}

func testSourceRemoveCacheAndMetadataAtIndex() {
    let data = imageioFixtureData("sample-2x1.png")
    guard let source = CGImageSourceCreateWithData(data, nil) else { fatalError("source") }
    CGImageSourceRemoveCacheAtIndex(source, 0)
    imageioRequire(CGImageSourceCreateImageAtIndex(source, 0, nil) != nil, "still present")
    imageioRequire(CGImageSourceCopyMetadataAtIndex(source, 0, nil) != nil, "metadata shell")
    imageioRequire(CGImageSourceCopyMetadataAtIndex(source, 9, nil) == nil, "oob")
}

func testSourceAuxiliaryDataAbsent() {
    let data = imageioFixtureData("sample-2x1.png")
    guard let source = CGImageSourceCreateWithData(data, nil) else { fatalError("source") }
    imageioRequire(
        CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeHDRGainMap)
            == nil,
        "aux"
    )
}
