import Foundation
import ImageIO

func testDestinationPNGByteLevelRoundtrip() {
    let expected = imageioFixtureData("sample-2x1.png")
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(data, "public.png", 1, nil) else {
        fatalError("dest")
    }
    CGImageDestinationAddImage(dest, imageioSampleImage(), nil)
    imageioRequire(CGImageDestinationFinalize(dest), "finalize")
    let encoded = data as Data
    imageioRequire(encoded == expected, "png bytes match fixture")
    guard let source = CGImageSourceCreateWithData(encoded, nil) else { fatalError("reread") }
    imageioRequire(CGImageSourceGetType(source) == "public.png", "type")
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("image")
    }
    imageioRequire(image.width == 2 && image.height == 1, "size")
    imageioRequire(image.pixels[0] == 255 && image.pixels[4] == 0, "pixels")
}

func testDestinationJPEGReRead() {
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(data, "public.jpeg", 1, nil) else {
        fatalError("jpeg dest")
    }
    CGImageDestinationAddImage(dest, imageioSolidImage(width: 8, height: 8, rgba: [255, 0, 0, 255]), nil)
    imageioRequire(CGImageDestinationFinalize(dest), "finalize")
    let encoded = data as Data
    imageioRequire(encoded.count >= 4 && encoded[0] == 0xff && encoded[1] == 0xd8, "soi")
    guard let source = CGImageSourceCreateWithData(encoded, nil) else { fatalError("reread") }
    imageioRequire(CGImageSourceGetType(source) == "public.jpeg", "type")
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("jpeg image")
    }
    imageioRequire(image.width == 8 && image.height == 8, "size")
    imageioRequire(image.pixels[0] > 200 && image.pixels[1] < 40 && image.pixels[2] < 40, "red")
}

func testDestinationPNGGradientByteLevel() {
    let expected = imageioFixtureData("gradient-16x12.png")
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(data, "public.png", 1, nil) else {
        fatalError("dest")
    }
    CGImageDestinationAddImage(dest, imageioGradient16x12(), nil)
    imageioRequire(CGImageDestinationFinalize(dest), "finalize")
    imageioRequire(data as Data == expected, "gradient png bytes")
    guard let source = CGImageSourceCreateWithData(expected, nil) else { fatalError("src") }
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("image")
    }
    imageioRequire(image.width == 16 && image.height == 12, "size")
    imageioRequire(image.pixels[0] == 0 && image.pixels[1] == 0 && image.pixels[2] == 128, "00")
    let last = (15 * 4)
    imageioRequire(image.pixels[last] == 240 && image.pixels[last + 2] == 128, "x15")
}

func testDestinationURL() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("imageio-host-\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: url) }
    guard let dest = CGImageDestinationCreateWithURL(url, "public.png", 1, nil) else {
        fatalError("url dest")
    }
    CGImageDestinationSetProperties(dest, [kCGImageDestinationLossyCompressionQuality: 1.0])
    CGImageDestinationAddImage(dest, imageioSampleImage(), nil)
    imageioRequire(CGImageDestinationFinalize(dest), "finalize")
    guard let source = CGImageSourceCreateWithURL(url, nil) else { fatalError("url source") }
    imageioRequire(CGImageSourceGetCount(source) == 1, "count")
}

func testDestinationConsumer() {
    let consumer = CGDataConsumer()
    guard let dest = CGImageDestinationCreateWithDataConsumer(
        consumer, "com.microsoft.bmp", 1, nil
    ) else { fatalError("consumer dest") }
    CGImageDestinationAddImage(dest, imageioSampleImage(), nil)
    imageioRequire(CGImageDestinationFinalize(dest), "finalize")
    imageioRequire(!consumer.bytes.isEmpty, "bytes")
    imageioRequire(CGImageSourceCreateWithData(consumer.bytes, nil) != nil, "reload")
}

func testDestinationUnsupportedType() {
    let data = NSMutableData()
    imageioRequire(CGImageDestinationCreateWithData(data, "public.heic", 1, nil) == nil, "heic")
    imageioRequire(CGImageDestinationCreateWithData(data, "public.png", 0, nil) == nil, "count")
}

func testDestinationCopyImageSource() {
    let png = imageioFixtureData("sample-2x1.png")
    guard let source = CGImageSourceCreateWithData(png, nil) else { fatalError("source") }
    let destData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(destData, "public.png", 1, nil) else {
        fatalError("dest")
    }
    var boxed: Unmanaged<CFError>?
    let copied = withUnsafeMutablePointer(to: &boxed) { pointer in
        CGImageDestinationCopyImageSource(dest, source, nil, pointer)
    }
    imageioRequire(copied, "copy")
    imageioRequire(boxed == nil, "no error")
    imageioRequire(CGImageDestinationFinalize(dest), "finalize")
    imageioRequire(destData as Data == png, "bytes")
}

func testDestinationAddImageFromSource() {
    let png = imageioFixtureData("sample-2x1.png")
    guard let source = CGImageSourceCreateWithData(png, nil) else { fatalError("source") }
    let destData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(destData, "public.png", 1, nil) else {
        fatalError("dest")
    }
    CGImageDestinationAddImageFromSource(dest, source, 0, nil)
    imageioRequire(CGImageDestinationFinalize(dest), "finalize")
    imageioRequire(CGImageSourceCreateWithData(destData as Data, nil) != nil, "reload")
}

func testDestinationAddImageAndMetadata() {
    let destData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(destData, "public.png", 1, nil) else {
        fatalError("dest")
    }
    CGImageDestinationAddImageAndMetadata(
        dest, imageioSampleImage(), CGImageMetadataCreateMutable(), nil
    )
    imageioRequire(CGImageDestinationFinalize(dest), "finalize")
}

func testDestinationAddAuxiliaryDataInfo() {
    let destData = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(destData, "public.png", 1, nil) else {
        fatalError("dest")
    }
    CGImageDestinationAddImage(dest, imageioSampleImage(), nil)
    CGImageDestinationAddAuxiliaryDataInfo(dest, kCGImageAuxiliaryDataTypeHDRGainMap, [:])
    imageioRequire(CGImageDestinationFinalize(dest), "finalize still works")
}

func testBMPRoundtrip() {
    let data = imageioEncodedSample("com.microsoft.bmp")
    guard let source = CGImageSourceCreateWithData(data, nil) else { fatalError("bmp source") }
    imageioRequire(CGImageSourceGetType(source) == "com.microsoft.bmp", "type")
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("bmp image")
    }
    imageioRequire(image.width == 2 && image.height == 1, "size")
    imageioRequire(image.pixels[0] == 255 && image.pixels[4] == 0, "pixels")
}
