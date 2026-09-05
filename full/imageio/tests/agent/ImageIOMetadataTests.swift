import Foundation
import ImageIO

func testMetadataTagTree() {
    let metadata = CGImageMetadataCreateMutable()
    imageioRequire(
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
    imageioRequire(CGImageMetadataTagCopyName(tag) == "UserComment", "name")
    imageioRequire(CGImageMetadataTagCopyNamespace(tag) == kCGImageMetadataNamespaceExif, "ns")
    imageioRequire(CGImageMetadataTagCopyPrefix(tag) == kCGImageMetadataPrefixExif, "prefix")
    imageioRequire(CGImageMetadataTagGetType(tag) == .string, "type")
    imageioRequire((CGImageMetadataTagCopyValue(tag) as? String) == "hello", "value")
    imageioRequire(CGImageMetadataTagCopyQualifiers(tag) == nil, "qualifiers")
    imageioRequire(CGImageMetadataSetTagWithPath(metadata, nil, "exif:UserComment", tag), "set")
    imageioRequire(
        CGImageMetadataCopyStringValueWithPath(metadata, nil, "exif:UserComment") == "hello",
        "string"
    )
    imageioRequire(CGImageMetadataCopyTagWithPath(metadata, nil, "exif:UserComment") === tag, "copy")
    imageioRequire(CGImageMetadataSetValueWithPath(metadata, nil, "plain", "value"), "set value")
    imageioRequire(
        CGImageMetadataSetValueMatchingImageProperty(
            metadata, kCGImagePropertyExifDictionary, kCGImagePropertyPixelWidth, "2"
        ),
        "matching"
    )
    imageioRequire(
        CGImageMetadataCopyTagMatchingImageProperty(
            metadata, kCGImagePropertyExifDictionary, kCGImagePropertyPixelWidth
        ) != nil,
        "match copy"
    )
    guard let copy = CGImageMetadataCreateMutableCopy(metadata) else { fatalError("copy") }
    imageioRequire(CGImageMetadataRemoveTagWithPath(copy, nil, "plain"), "remove")
    imageioRequire(CGImageMetadataCopyTagWithPath(copy, nil, "plain") == nil, "removed")
    imageioRequire(CGImageMetadataCopyTags(metadata)?.count == 3, "tags")
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
    imageioRequire(seen == ["a"], "stop after false")
}

func testMetadataNamespaceConflict() {
    let metadata = CGImageMetadataCreateMutable()
    imageioRequire(
        CGImageMetadataRegisterNamespaceForPrefix(metadata, "http://a.example", "x", nil),
        "first"
    )
    var boxed: Unmanaged<CFError>?
    let ok = withUnsafeMutablePointer(to: &boxed) { pointer in
        CGImageMetadataRegisterNamespaceForPrefix(metadata, "http://b.example", "x", pointer)
    }
    imageioRequire(!ok, "conflict")
    imageioRequire(boxed != nil, "error")
    boxed?.release()
}

func testMetadataXMPRoundtrip() {
    let metadata = CGImageMetadataCreateMutable()
    imageioRequire(
        CGImageMetadataRegisterNamespaceForPrefix(
            metadata, kCGImageMetadataNamespaceExif, kCGImageMetadataPrefixExif, nil
        ),
        "register"
    )
    imageioRequire(
        CGImageMetadataSetValueWithPath(metadata, nil, "exif:UserComment", "hello"),
        "set"
    )
    guard let xmp = CGImageMetadataCreateXMPData(metadata, nil) else { fatalError("xmp") }
    imageioRequire(!xmp.isEmpty, "bytes")
    guard let parsed = CGImageMetadataCreateFromXMPData(xmp) else { fatalError("parse") }
    imageioRequire(
        CGImageMetadataCopyStringValueWithPath(parsed, nil, "exif:UserComment") == "hello",
        "value"
    )
}
