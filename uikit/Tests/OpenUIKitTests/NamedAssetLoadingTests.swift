import Foundation
import XCTest
@testable import OpenUIKit

final class NamedAssetLoadingTests: XCTestCase {
    private var savedImageSearchPaths: [String] = []
    private var savedImageScale: CGFloat = 2
    private var savedAssetIdiom: UIUserInterfaceIdiom = .phone
    private var savedTraits = UITraitCollection.current

    override func setUp() {
        super.setUp()
        savedImageSearchPaths = OpenUIKitRuntime.imageSearchPaths
        savedImageScale = OpenUIKitRuntime.imageScreenScale
        savedAssetIdiom = OpenUIKitRuntime.assetCatalogIdiom
        savedTraits = UITraitCollection.current
    }

    override func tearDown() {
        OpenUIKitRuntime.imageSearchPaths = savedImageSearchPaths
        OpenUIKitRuntime.imageScreenScale = savedImageScale
        OpenUIKitRuntime.assetCatalogIdiom = savedAssetIdiom
        UITraitCollection.current = savedTraits
        UIImage.clearNamedCache()
        super.tearDown()
    }

    private func withTempDirectory(_ body: (String) throws -> Void) rethrows {
        let path = NSTemporaryDirectory()
            + "openuikit-named-assets-\(UInt32.random(in: 0...UInt32.max))"
        try? FileManager.default.createDirectory(atPath: path,
                                                 withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: path) }
        try body(path)
    }

    private func makeBundle(at path: String) -> Bundle {
        try! FileManager.default.createDirectory(atPath: path,
                                                 withIntermediateDirectories: true)
        return Bundle(path: path)!
    }

    private func makeStructuredBundle(at path: String) -> Bundle {
        let resources = path + "/Contents/Resources"
        try! FileManager.default.createDirectory(atPath: resources,
                                                 withIntermediateDirectories: true)
        let info = #"""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
          "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
          <key>CFBundleIdentifier</key><string>org.openuikit.asset-tests</string>
          <key>CFBundleName</key><string>AssetTests</string>
          <key>CFBundlePackageType</key><string>BNDL</string>
        </dict></plist>
        """#
        try! Data(info.utf8).write(
            to: URL(fileURLWithPath: path + "/Contents/Info.plist")
        )
        return Bundle(path: path)!
    }

    private func writeImage(width: Int, height: Int, red: UInt8, to path: String) {
        let bitmap = Bitmap(width: width, height: height)
        for offset in stride(from: 0, to: bitmap.pixels.count, by: 4) {
            bitmap.pixels[offset] = red
            bitmap.pixels[offset + 3] = 255
        }
        let data = ImageCodec.encodePNG(bitmap)!
        FileManager.default.createFile(atPath: path, contents: Data(data))
    }

    private func indexedPayload(
        at resourceRoot: String,
        id: Character,
        red: UInt8,
        ext: String = ".png"
    ) -> [String: Any] {
        let sha = String(repeating: String(id), count: 64)
        let directory = resourceRoot + "/OpenUIKit/AssetCatalogs/Resources/"
            + String(sha.prefix(2))
        try! FileManager.default.createDirectory(
            atPath: directory, withIntermediateDirectories: true
        )
        let bitmap = Bitmap(width: 4, height: 4)
        for offset in stride(from: 0, to: bitmap.pixels.count, by: 4) {
            bitmap.pixels[offset] = red
            bitmap.pixels[offset + 3] = 255
        }
        let bytes = ImageCodec.encodePNG(bitmap)!
        try! Data(bytes).write(
            to: URL(fileURLWithPath: directory + "/" + sha + ext)
        )
        return [
            "sha256": sha,
            "bytes": bytes.count,
            "ext": ext,
            "filename": "fixture-\(id)\(ext)",
            "file": String(sha.prefix(2)) + "/" + sha + ext,
        ]
    }

    private func indexedPayload(
        at resourceRoot: String,
        id: Character,
        bytes: [UInt8],
        ext: String
    ) -> [String: Any] {
        let sha = String(repeating: String(id), count: 64)
        let directory = resourceRoot + "/OpenUIKit/AssetCatalogs/Resources/"
            + String(sha.prefix(2))
        try! FileManager.default.createDirectory(
            atPath: directory, withIntermediateDirectories: true
        )
        try! Data(bytes).write(
            to: URL(fileURLWithPath: directory + "/" + sha + ext)
        )
        return [
            "sha256": sha,
            "bytes": bytes.count,
            "ext": ext,
            "filename": "fixture-\(id)\(ext)",
            "file": String(sha.prefix(2)) + "/" + sha + ext,
        ]
    }

    private func pdfStream(
        _ bytes: [UInt8], dictionary: String = ""
    ) -> [UInt8] {
        var result = Array("<< /Length \(bytes.count)".utf8)
        if !dictionary.isEmpty {
            result.append(contentsOf: Array(" \(dictionary)".utf8))
        }
        result.append(contentsOf: Array(" >>\nstream\n".utf8))
        result.append(contentsOf: bytes)
        result.append(contentsOf: Array("\nendstream".utf8))
        return result
    }

    /// Build a traditional-xref PDF without relying on a host PDF framework.
    /// Object array element zero becomes object 1, and so on.
    private func makePDF(_ objects: [[UInt8]], root: Int = 1) -> [UInt8] {
        var bytes = Array("%PDF-1.7\n".utf8)
        var offsets = [0]
        for (index, object) in objects.enumerated() {
            offsets.append(bytes.count)
            bytes.append(contentsOf: Array("\(index + 1) 0 obj\n".utf8))
            bytes.append(contentsOf: object)
            bytes.append(contentsOf: Array("\nendobj\n".utf8))
        }
        let xrefOffset = bytes.count
        bytes.append(contentsOf: Array("xref\n0 \(objects.count + 1)\n".utf8))
        bytes.append(contentsOf: Array("0000000000 65535 f \n".utf8))
        for offset in offsets.dropFirst() {
            let digits = String(offset)
            let field = String(repeating: "0", count: 10 - digits.count) + digits
            bytes.append(contentsOf: Array("\(field) 00000 n \n".utf8))
        }
        bytes.append(contentsOf: Array(
            "trailer\n<< /Size \(objects.count + 1) /Root \(root) 0 R >>\n"
                .utf8
        ))
        bytes.append(contentsOf: Array(
            "startxref\n\(xrefOffset)\n%%EOF\n".utf8
        ))
        return bytes
    }

    private func singlePagePDF(
        mediaBox: String,
        resources: String = "<< >>",
        content: [UInt8],
        contentDictionary: String = "",
        extraObjects: [[UInt8]] = []
    ) -> [UInt8] {
        makePDF([
            Array("<< /Type /Catalog /Pages 2 0 R >>".utf8),
            Array("<< /Type /Pages /Kids [3 0 R] /Count 1 >>".utf8),
            Array(("<< /Type /Page /Parent 2 0 R /MediaBox "
                + mediaBox + " /Resources " + resources
                + " /Contents 4 0 R >>").utf8),
            pdfStream(content, dictionary: contentDictionary),
        ] + extraObjects)
    }

    private func rgba(_ bitmap: Bitmap, x: Int, y: Int) -> [UInt8] {
        let offset = (y * bitmap.width + x) * 4
        return Array(bitmap.pixels[offset..<(offset + 4)])
    }

    private func imageVariant(
        _ payload: [String: Any],
        idiom: String = "universal",
        appearance: String = "any",
        scale: Int? = nil,
        resizing: Any = NSNull(),
        screenWidth: Any = NSNull()
    ) -> [String: Any] {
        [
            "payload": payload,
            "idiom": idiom,
            "appearance": appearance,
            "scale": scale as Any? ?? NSNull(),
            "screen_width": screenWidth,
            "language_direction": NSNull(),
            "height_class": NSNull(),
            "resizing": resizing,
        ]
    }

    private func imageRecord(
        _ variants: [[String: Any]],
        type: String = "imageset",
        intent: String? = nil
    ) -> [String: Any] {
        var properties: [String: Any] = [:]
        if let intent { properties["template-rendering-intent"] = intent }
        return ["type": type, "properties": properties,
                "variants": variants]
    }

    private func colorVariant(
        idiom: String = "universal",
        appearance: String = "any",
        native: [Double],
        srgb: [Double],
        space: String,
        platform: Any = NSNull()
    ) -> [String: Any] {
        [
            "idiom": idiom,
            "appearance": appearance,
            "native": native,
            "srgb": srgb,
            "color_space": space,
            "conversion": "test",
            "encodings": [:],
            "platform": platform,
        ]
    }

    private func writeIndex(
        at resourceRoot: String,
        assets: [String: Any],
        unresolved: [String: Any] = [:],
        collisions: [String: Any] = [:]
    ) {
        let directory = resourceRoot + "/OpenUIKit/AssetCatalogs"
        try! FileManager.default.createDirectory(
            atPath: directory, withIntermediateDirectories: true
        )
        let index: [String: Any] = [
            "format": "openuikit-xcassets-index",
            "version": 1,
            "app": "OpenUIKitTests",
            "catalogs": ["Assets.xcassets"],
            "resources_dir": "Resources",
            "assets": assets,
            "unresolved": unresolved,
            "collisions": collisions,
            "folder_orphans": [],
            "stats": [:],
        ]
        let data = try! JSONSerialization.data(
            withJSONObject: index, options: [.sortedKeys]
        )
        try! data.write(to: URL(fileURLWithPath: directory + "/index.json"))
    }

    func testBundleNamedImageUsesOnlyTheSelectedBundleAndTraitScale() {
        withTempDirectory { root in
            let first = makeBundle(at: root + "/First.bundle")
            let second = makeBundle(at: root + "/Second.bundle")
            writeImage(width: 12, height: 8, red: 10,
                       to: first.bundlePath + "/icon.png")
            writeImage(width: 24, height: 16, red: 20,
                       to: first.bundlePath + "/icon@2x.png")
            writeImage(width: 7, height: 5, red: 200,
                       to: second.bundlePath + "/icon.png")
            writeImage(width: 3, height: 3, red: 255,
                       to: second.bundlePath + "/global-only.png")

            // An explicit bundle must not fall through to the process-global
            // paths merely because another bundle contains the same name.
            OpenUIKitRuntime.imageSearchPaths = [second.bundlePath]

            let oneXTraits = UITraitCollection(userInterfaceStyle: .light,
                                               displayScale: 1)
            let twoXTraits = UITraitCollection(userInterfaceStyle: .dark,
                                               displayScale: 2)
            let oneX = UIImage(named: "icon", in: first,
                               compatibleWith: oneXTraits)
            let twoX = UIImage(named: "icon", in: first,
                               compatibleWith: twoXTraits)
            let otherBundle = UIImage(named: "icon", in: second,
                                      compatibleWith: twoXTraits)

            XCTAssertEqual(oneX?.scale, 1)
            XCTAssertEqual(oneX?.bitmap.width, 12)
            XCTAssertEqual(oneX?.bitmap.pixels.first, 10)
            XCTAssertEqual(twoX?.scale, 2)
            XCTAssertEqual(twoX?.size, CGSize(width: 12, height: 8))
            XCTAssertEqual(twoX?.bitmap.pixels.first, 20)
            XCTAssertEqual(otherBundle?.bitmap.width, 7)
            XCTAssertEqual(otherBundle?.bitmap.pixels.first, 200)
            XCTAssertNil(UIImage(named: "global-only", in: first,
                                 compatibleWith: nil))
            XCTAssertNil(UIImage(named: "../Second.bundle/icon", in: first,
                                 compatibleWith: nil))
            XCTAssertNil(UIImage(named: "/absolute/icon", in: first,
                                 compatibleWith: nil))
        }
    }

    func testNamedImageBoundsPathologicalTraitScalesWithoutTrapping() {
        withTempDirectory { root in
            let bundle = makeBundle(at: root + "/Scale.bundle")
            writeImage(width: 8, height: 6, red: 10,
                       to: bundle.bundlePath + "/icon.png")
            writeImage(width: 24, height: 18, red: 30,
                       to: bundle.bundlePath + "/icon@3x.png")

            let huge = UITraitCollection(userInterfaceStyle: .light,
                                         displayScale: .greatestFiniteMagnitude)
            let nan = UITraitCollection(userInterfaceStyle: .light,
                                        displayScale: .nan)
            let infinity = UITraitCollection(userInterfaceStyle: .light,
                                             displayScale: .infinity)

            XCTAssertEqual(UIImage(named: "icon", in: bundle,
                                   compatibleWith: huge)?.scale, 3)
            XCTAssertEqual(UIImage(named: "icon", in: bundle,
                                   compatibleWith: nan)?.scale, 1)
            XCTAssertEqual(UIImage(named: "icon", in: bundle,
                                   compatibleWith: infinity)?.scale, 1)
        }
    }

    func testImageLiteralUsesUIKitNamedResourceLookup() {
        withTempDirectory { root in
            writeImage(width: 6, height: 4, red: 77,
                       to: root + "/literal.png")
            OpenUIKitRuntime.imageSearchPaths = [root]
            OpenUIKitRuntime.imageScreenScale = 1

            let image: UIImage = #imageLiteral(resourceName: "literal")

            XCTAssertEqual(image.size, CGSize(width: 6, height: 4))
            XCTAssertEqual(image.bitmap.pixels.first, 77)
        }
    }

    func testStructuredBundleDoesNotFallThroughOutsideItsResourceDirectory() {
        withTempDirectory { root in
            let bundle = makeStructuredBundle(at: root + "/Structured.bundle")
            guard let resourcePath = bundle.resourcePath,
                  resourcePath != bundle.bundlePath else {
                XCTFail("test fixture did not create a structured bundle")
                return
            }
            writeImage(width: 4, height: 4, red: 40,
                       to: resourcePath + "/inside.png")
            writeImage(width: 5, height: 5, red: 50,
                       to: bundle.bundlePath + "/outside.png")

            XCTAssertEqual(UIImage(named: "inside", in: bundle,
                                   compatibleWith: nil)?.bitmap.width, 4)
            XCTAssertNil(UIImage(named: "outside", in: bundle,
                                 compatibleWith: nil))
        }
    }

    func testBundleNamedImageDoesNotPretendToDecodeAssetsCarOrLooseVectors() {
        withTempDirectory { root in
            let bundle = makeBundle(at: root + "/Compiled.bundle")
            FileManager.default.createFile(atPath: bundle.bundlePath + "/Assets.car",
                                           contents: Data([0, 1, 2, 3]))
            FileManager.default.createFile(atPath: bundle.bundlePath + "/logo.pdf",
                                           contents: Data("%PDF-placeholder".utf8))
            XCTAssertNil(UIImage(named: "logo", in: bundle, compatibleWith: nil))
        }
    }

    func testBundleNamedColorReadsFocusStyleHexAndDarkDecimalComponents() {
        withTempDirectory { root in
            let bundle = makeBundle(at: root + "/Colors.bundle")
            let colorset = bundle.bundlePath
                + "/Colors.xcassets/Above.colorset"
            try! FileManager.default.createDirectory(atPath: colorset,
                                                     withIntermediateDirectories: true)
            let contents = #"""
            {
              "colors" : [
                {
                  "color" : {
                    "color-space" : "srgb",
                    "components" : {
                      "alpha" : "1.000", "blue" : "0xFE",
                      "green" : "0xFB", "red" : "0xFB"
                    }
                  },
                  "idiom" : "universal"
                },
                {
                  "appearances" : [
                    { "appearance" : "luminosity", "value" : "dark" }
                  ],
                  "color" : {
                    "color-space" : "srgb",
                    "components" : {
                      "alpha" : "1.000", "blue" : "0.365",
                      "green" : "0.145", "red" : "0.180"
                    }
                  },
                  "idiom" : "universal"
                }
              ],
              "info" : { "author" : "xcode", "version" : 1 }
            }
            """#
            try! Data(contents.utf8).write(
                to: URL(fileURLWithPath: colorset + "/Contents.json")
            )

            let color = UIColor(named: "Above", in: bundle,
                                compatibleWith: nil)
            let light = color?.resolvedCGColor(with: UITraitCollection(
                userInterfaceStyle: .light
            ))
            let dark = color?.resolvedCGColor(with: UITraitCollection(
                userInterfaceStyle: .dark
            ))

            XCTAssertEqual(light?.red ?? -1, 251.0 / 255.0, accuracy: 0.0001)
            XCTAssertEqual(light?.green ?? -1, 251.0 / 255.0, accuracy: 0.0001)
            XCTAssertEqual(light?.blue ?? -1, 254.0 / 255.0, accuracy: 0.0001)
            XCTAssertEqual(dark?.red ?? -1, 0.180, accuracy: 0.0001)
            XCTAssertEqual(dark?.green ?? -1, 0.145, accuracy: 0.0001)
            XCTAssertEqual(dark?.blue ?? -1, 0.365, accuracy: 0.0001)
            XCTAssertNil(UIColor(named: "Missing", in: bundle,
                                 compatibleWith: nil))
        }
    }

    func testBundleNamedColorRejectsUnsupportedCompiledP3AndAppearanceAssets() {
        withTempDirectory { root in
            let bundle = makeBundle(at: root + "/Unsupported.bundle")
            let colorset = bundle.bundlePath + "/Brand.colorset"
            try! FileManager.default.createDirectory(atPath: colorset,
                                                     withIntermediateDirectories: true)
            let p3 = #"""
            { "colors": [{ "idiom": "universal", "color": {
              "color-space": "display-p3",
              "components": { "red": "1", "green": "0", "blue": "0", "alpha": "1" }
            }}] }
            """#
            try! Data(p3.utf8).write(
                to: URL(fileURLWithPath: colorset + "/Contents.json")
            )
            FileManager.default.createFile(atPath: bundle.bundlePath + "/Assets.car",
                                           contents: Data([0, 1, 2, 3]))

            let contrastSet = bundle.bundlePath + "/Contrast.colorset"
            try! FileManager.default.createDirectory(atPath: contrastSet,
                                                     withIntermediateDirectories: true)
            let contrast = #"""
            { "colors": [{ "idiom": "universal",
              "appearances": [{ "appearance": "contrast", "value": "high" }],
              "color": { "color-space": "srgb",
                "components": {
                  "red": "1", "green": "0", "blue": "0", "alpha": "1"
                }
              }
            }] }
            """#
            try! Data(contrast.utf8).write(
                to: URL(fileURLWithPath: contrastSet + "/Contents.json")
            )

            XCTAssertNil(UIColor(named: "Brand", in: bundle,
                                 compatibleWith: nil))
            XCTAssertNil(UIColor(named: "Contrast", in: bundle,
                                 compatibleWith: nil))
            XCTAssertNil(UIColor(named: "OnlyInAssetsCar", in: bundle,
                                 compatibleWith: nil))

            let escapedSet = root + "/Escaped.colorset"
            try! FileManager.default.createDirectory(atPath: escapedSet,
                                                     withIntermediateDirectories: true)
            let escaped = #"""
            { "colors": [{ "idiom": "universal", "color": {
              "color-space": "srgb",
              "components": { "red": "1", "green": "0", "blue": "0", "alpha": "1" }
            }}] }
            """#
            try! Data(escaped.utf8).write(
                to: URL(fileURLWithPath: escapedSet + "/Contents.json")
            )
            XCTAssertNil(UIColor(named: "../Escaped", in: bundle,
                                 compatibleWith: nil))

            let invalidAlphaSet = bundle.bundlePath + "/InvalidAlpha.colorset"
            try! FileManager.default.createDirectory(atPath: invalidAlphaSet,
                                                     withIntermediateDirectories: true)
            let invalidAlpha = #"""
            { "colors": [{ "idiom": "universal", "color": {
              "color-space": "srgb",
              "components": {
                "red": "1", "green": "0", "blue": "0", "alpha": "garbage"
              }
            }}] }
            """#
            try! Data(invalidAlpha.utf8).write(
                to: URL(fileURLWithPath: invalidAlphaSet + "/Contents.json")
            )
            XCTAssertNil(UIColor(named: "InvalidAlpha", in: bundle,
                                 compatibleWith: nil))
        }
    }


    func testNamedColorIgnoresGamutQualifiedEntriesRegardlessOfOrder() {
        withTempDirectory { root in
            let bundle = makeBundle(at: root + "/Gamut.bundle")
            let orderedSet = bundle.bundlePath + "/Ordered.colorset"
            try! FileManager.default.createDirectory(atPath: orderedSet,
                                                     withIntermediateDirectories: true)
            let ordered = #"""
            { "colors": [
              { "idiom": "universal", "display-gamut": "display-P3",
                "color": { "color-space": "srgb", "components": {
                  "red": "1", "green": "0", "blue": "0", "alpha": "1"
                }}},
              { "idiom": "universal",
                "color": { "color-space": "srgb", "components": {
                  "red": "0", "green": "1", "blue": "0", "alpha": "1"
                }}}
            ] }
            """#
            try! Data(ordered.utf8).write(
                to: URL(fileURLWithPath: orderedSet + "/Contents.json")
            )

            let onlySet = bundle.bundlePath + "/OnlyGamut.colorset"
            try! FileManager.default.createDirectory(atPath: onlySet,
                                                     withIntermediateDirectories: true)
            let only = #"""
            { "colors": [{ "idiom": "universal", "display-gamut": "display-P3",
              "color": { "color-space": "srgb", "components": {
                "red": "1", "green": "0", "blue": "0", "alpha": "1"
              }}}] }
            """#
            try! Data(only.utf8).write(
                to: URL(fileURLWithPath: onlySet + "/Contents.json")
            )

            let color = UIColor(named: "Ordered", in: bundle,
                                compatibleWith: nil)?.resolvedCGColor(
                                    with: UITraitCollection(userInterfaceStyle: .light)
                                )
            XCTAssertEqual(color?.red ?? -1, 0, accuracy: 0.0001)
            XCTAssertEqual(color?.green ?? -1, 1, accuracy: 0.0001)
            XCTAssertNil(UIColor(named: "OnlyGamut", in: bundle,
                                 compatibleWith: nil))
        }
    }

    func testMaterializedIndexMatchesMeasuredImageResolutionAndMetadata() {
        withTempDirectory { root in
            let bundle = makeBundle(at: root + "/Indexed.bundle")
            let resources = bundle.bundlePath
            let phone1 = indexedPayload(at: resources, id: "1", red: 11)
            let universal2 = indexedPayload(at: resources, id: "2", red: 22)
            let phone3 = indexedPayload(at: resources, id: "3", red: 33)
            let phoneAny2 = indexedPayload(at: resources, id: "4", red: 44)
            let scaleless = indexedPayload(at: resources, id: "5", red: 55)
            let collision = indexedPayload(at: resources, id: "6", red: 66)
            let above3 = indexedPayload(at: resources, id: "7", red: 73)
            let jpg = indexedPayload(at: resources, id: "8", red: 88,
                                     ext: ".jpg")
            let jpeg = indexedPayload(at: resources, id: "9", red: 99,
                                      ext: ".jpeg")

            let ranked = imageRecord([
                imageVariant(universal2, idiom: "universal",
                             appearance: "light", scale: 2),
                imageVariant(phone3, idiom: "iphone",
                             appearance: "light", scale: 3),
                imageVariant(scaleless, idiom: "iphone",
                             appearance: "light"),
                imageVariant(phone1, idiom: "iphone",
                             appearance: "light", scale: 1),
                imageVariant(phoneAny2, idiom: "iphone",
                             appearance: "any", scale: 2),
            ], intent: "template")
            let losing = imageRecord([
                imageVariant(collision, idiom: "universal",
                             appearance: "any", scale: 2),
            ])
            writeIndex(
                at: resources,
                assets: [
                    "Ranked": ranked,
                    "Above": imageRecord([
                        imageVariant(above3, idiom: "iphone",
                                     appearance: "light", scale: 3),
                    ]),
                    "ScaleLess": imageRecord([
                        imageVariant(scaleless, idiom: "universal",
                                     appearance: "any"),
                    ]),
                    "JPG": imageRecord([imageVariant(jpg, scale: 2)],
                                       intent: "original"),
                    "JPEG": imageRecord([imageVariant(jpeg, scale: 2)]),
                ],
                collisions: [
                    "Ranked": [[
                        "contents": "Other.xcassets/Ranked.imageset/Contents.json",
                        "record": losing,
                    ]],
                ]
            )

            let light2 = UITraitCollection(userInterfaceStyle: .light,
                                           displayScale: 2)
            let light3 = UITraitCollection(userInterfaceStyle: .light,
                                           displayScale: 3)
            let dark2 = UITraitCollection(userInterfaceStyle: .dark,
                                          displayScale: 2)
            OpenUIKitRuntime.assetCatalogIdiom = .phone

            let below = UIImage(named: "Ranked", in: bundle,
                                compatibleWith: light2)
            XCTAssertEqual(below?.bitmap.pixels.first, 11,
                           "largest scale below must beat 3x and scaleless")
            XCTAssertEqual(below?.scale, 1)
            XCTAssertEqual(below?.renderingMode, .alwaysTemplate)
            XCTAssertEqual(UIImage(named: "Ranked", in: bundle,
                                   compatibleWith: light3)?.bitmap.pixels.first, 33)
            XCTAssertEqual(UIImage(named: "Ranked", in: bundle,
                                   compatibleWith: dark2)?.bitmap.pixels.first, 44,
                           "appearance any is the fallback, never light")
            XCTAssertEqual(UIImage(named: "Above", in: bundle,
                                   compatibleWith: light2)?.bitmap.pixels.first, 73)

            OpenUIKitRuntime.assetCatalogIdiom = .pad
            XCTAssertEqual(UIImage(named: "Ranked", in: bundle,
                                   compatibleWith: light2)?.bitmap.pixels.first, 22,
                           "universal is used only after exact idiom misses")
            XCTAssertEqual(UIImage(named: "ScaleLess", in: bundle,
                                   compatibleWith: light2)?.scale, 2)
            XCTAssertEqual(UIImage(named: "JPG", in: bundle,
                                   compatibleWith: light2)?.renderingMode,
                           .alwaysOriginal)
            XCTAssertEqual(UIImage(named: "JPEG", in: bundle,
                                   compatibleWith: light2)?.bitmap.pixels.first, 99)
        }
    }

    func testIndexedPDFRasterizesAtTraitScaleWithPDFOrientationAndMetadata() {
        withTempDirectory { root in
            let bundle = makeBundle(at: root + "/PDF.bundle")
            let lightContent = Array(#"""
            /DeviceRGB cs
            1 0 0 scn 10 20 2 1 re f
            0 1 0 scn 10 21 1 1 re f
            0 0 1 scn 12 21 1 1 re f
            """#.utf8)
            let darkContent = Array(
                "/DeviceRGB cs 1 0 1 scn 10 20 3 2 re f\n".utf8
            )
            let lightPDF = singlePagePDF(
                mediaBox: "[10 20 13 22]", content: lightContent
            )
            let darkPDF = singlePagePDF(
                mediaBox: "[10 20 13 22]", content: darkContent
            )
            let light = indexedPayload(
                at: bundle.bundlePath, id: "a", bytes: lightPDF, ext: ".pdf"
            )
            let dark = indexedPayload(
                at: bundle.bundlePath, id: "b", bytes: darkPDF, ext: ".pdf"
            )
            writeIndex(at: bundle.bundlePath, assets: [
                "Vector": imageRecord([
                    imageVariant(light, appearance: "any"),
                    imageVariant(dark, appearance: "dark"),
                ], intent: "template"),
            ])

            let lightTraits = UITraitCollection(
                userInterfaceStyle: .light, displayScale: 2
            )
            let image = UIImage(
                named: "Vector", in: bundle, compatibleWith: lightTraits
            )
            XCTAssertEqual(image?.scale, 2)
            XCTAssertEqual(image?.size, CGSize(width: 3, height: 2))
            XCTAssertEqual(image?.bitmap.width, 6)
            XCTAssertEqual(image?.bitmap.height, 4)
            XCTAssertEqual(image?.renderingMode, .alwaysTemplate)
            if let bitmap = image?.bitmap {
                XCTAssertEqual(rgba(bitmap, x: 0, y: 0), [0, 255, 0, 255],
                               "PDF top-left must map to bitmap row zero")
                XCTAssertEqual(rgba(bitmap, x: 3, y: 0), [0, 0, 0, 0])
                XCTAssertEqual(rgba(bitmap, x: 5, y: 0), [0, 0, 255, 255])
                XCTAssertEqual(rgba(bitmap, x: 0, y: 3), [255, 0, 0, 255],
                               "PDF bottom-left must map to the last row")
                XCTAssertEqual(rgba(bitmap, x: 5, y: 3), [0, 0, 0, 0])
            }

            let darkTraits = UITraitCollection(
                userInterfaceStyle: .dark, displayScale: 3
            )
            let darkImage = UIImage(
                named: "Vector", in: bundle, compatibleWith: darkTraits
            )
            XCTAssertEqual(darkImage?.scale, 3,
                           "a scaleless vector rasterizes at requested scale")
            XCTAssertEqual(darkImage?.bitmap.width, 9)
            XCTAssertEqual(darkImage?.bitmap.pixels.prefix(4), [255, 0, 255, 255])
            XCTAssertEqual(darkImage?.renderingMode, .alwaysTemplate)
        }
    }

    func testPDFFlateContentUsesThePageStreamRatherThanUnrelatedObjects() {
        // zlib-compressed `/DeviceRGB ...` content. Keeping the bytes fixed
        // makes the runtime test independent of Foundation or host libz.
        let flate: [UInt8] = [
            120, 218, 211, 119, 73, 45, 203, 76, 78, 13, 114, 119, 82,
            72, 46, 86, 48, 80, 48, 4, 226, 226, 228, 60, 5, 67, 3, 5,
            35, 16, 207, 80, 161, 40, 85, 33, 141, 11, 0, 214, 56, 9, 210,
        ]
        let pdf = singlePagePDF(
            mediaBox: "[10 20 12 21]", content: flate,
            contentDictionary: "/Filter /FlateDecode",
            extraObjects: [
                pdfStream(Array("unsupported-op\n".utf8),
                          dictionary: "/Filter /LZWDecode"),
            ]
        )
        let bitmap = ImageCodec.decodePDF(pdf, scale: 1)
        XCTAssertEqual(bitmap?.width, 2)
        XCTAssertEqual(bitmap?.height, 1)
        if let bitmap {
            XCTAssertEqual(rgba(bitmap, x: 0, y: 0), [0, 255, 0, 255])
            XCTAssertEqual(rgba(bitmap, x: 1, y: 0), [0, 0, 0, 0])
        }
    }

    func testPDFRasterImageXObjectFlateAndImageSoftMask() {
        let imageFlate: [UInt8] = [
            120, 218, 251, 207, 192, 192, 240, 159, 1, 0, 7, 254, 1, 255,
        ]
        let alphaFlate: [UInt8] = [
            120, 218, 251, 239, 0, 0, 2, 64, 1, 64,
        ]
        let pdf = singlePagePDF(
            mediaBox: "[0 0 2 1]",
            resources: "<< /XObject << /Im 5 0 R >> >>",
            content: Array("q 2 0 0 1 0 0 cm /Im Do Q\n".utf8),
            extraObjects: [
                pdfStream(imageFlate, dictionary:
                    "/Type /XObject /Subtype /Image /Width 2 /Height 1 "
                    + "/BitsPerComponent 8 /ColorSpace /DeviceRGB "
                    + "/Filter /FlateDecode /SMask 6 0 R"),
                pdfStream(alphaFlate, dictionary:
                    "/Type /XObject /Subtype /Image /Width 2 /Height 1 "
                    + "/BitsPerComponent 8 /ColorSpace /DeviceGray "
                    + "/Filter /FlateDecode"),
            ]
        )
        let bitmap = ImageCodec.decodePDF(pdf, scale: 1)
        if let bitmap {
            XCTAssertEqual(rgba(bitmap, x: 0, y: 0), [255, 0, 0, 255])
            let second = rgba(bitmap, x: 1, y: 0)
            XCTAssertEqual(Array(second.prefix(3)), [0, 255, 0])
            XCTAssertEqual(second[3], 64)
        } else {
            XCTFail("bounded Flate image XObject should render")
        }
    }

    func testPDFLuminosityAndAlphaSoftMasksIncludingTransferFunction() {
        let luminosity = makePDF([
            Array("<< /Type /Catalog /Pages 2 0 R >>".utf8),
            Array("<< /Type /Pages /Kids [3 0 R] /Count 1 >>".utf8),
            Array(("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 2 1] "
                + "/Resources << /ExtGState << /E1 << /SMask "
                + "<< /Type /Mask /S /Luminosity /G 5 0 R >> >> >> >> "
                + "/Contents 4 0 R >>").utf8),
            pdfStream(Array("/E1 gs 1 0 0 rg 0 0 2 1 re f\n".utf8)),
            pdfStream(Array(
                "0.5 g 0 0 1 1 re f 1 g 1 0 1 1 re f\n".utf8
            ), dictionary:
                "/Type /XObject /Subtype /Form /BBox [0 0 2 1] "
                + "/Resources << >> /Group << /Type /Group "
                + "/S /Transparency /CS /DeviceGray >>"),
        ])
        if let bitmap = ImageCodec.decodePDF(luminosity, scale: 1) {
            let left = rgba(bitmap, x: 0, y: 0)
            XCTAssertEqual(Array(left.prefix(3)), [255, 0, 0])
            XCTAssertEqual(left[3], 128, accuracy: 2)
            XCTAssertEqual(rgba(bitmap, x: 1, y: 0), [255, 0, 0, 255])
        } else {
            XCTFail("luminosity soft-mask group should render")
        }

        let alphaTransfer = makePDF([
            Array("<< /Type /Catalog /Pages 2 0 R >>".utf8),
            Array("<< /Type /Pages /Kids [3 0 R] /Count 1 >>".utf8),
            Array(("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 2 1] "
                + "/Resources << /ExtGState << /E1 << /SMask "
                + "<< /Type /Mask /S /Alpha /G 5 0 R /TR 6 0 R >> >> >> >> "
                + "/Contents 4 0 R >>").utf8),
            pdfStream(Array("/E1 gs 0 0 1 rg 0 0 2 1 re f\n".utf8)),
            pdfStream(Array("1 g 0 0 1 1 re f\n".utf8), dictionary:
                "/Type /XObject /Subtype /Form /BBox [0 0 2 1] "
                + "/Resources << >> /Group << /Type /Group "
                + "/S /Transparency /CS /DeviceGray >>"),
            pdfStream(Array("{ 0 gt { 0.25 } { 0 } ifelse }".utf8),
                      dictionary:
                "/FunctionType 4 /Domain [0 1] /Range [0 1]"),
        ])
        if let bitmap = ImageCodec.decodePDF(alphaTransfer, scale: 1) {
            let left = rgba(bitmap, x: 0, y: 0)
            XCTAssertEqual(Array(left.prefix(3)), [0, 0, 255])
            XCTAssertEqual(left[3], 64, accuracy: 2)
            XCTAssertEqual(rgba(bitmap, x: 1, y: 0), [0, 0, 0, 0])
        } else {
            XCTFail("alpha soft-mask transfer function should render")
        }
    }

    func testPDFAxialPatternRunsBoundedType4CalculatorFunction() {
        let resources = #"""
        << /Pattern << /P1 << /Type /Pattern /PatternType 2
          /Shading << /ShadingType 2 /ColorSpace /DeviceRGB
            /Coords [0 0 2 0] /Function 5 0 R /Domain [0 1]
            /Extend [true true] >> >> >> >>
        """#
        let pdf = singlePagePDF(
            mediaBox: "[0 0 2 1]", resources: resources,
            content: Array("/Pattern cs /P1 scn 0 0 2 1 re f\n".utf8),
            extraObjects: [
                pdfStream(Array("{ dup 0 mul 0 }".utf8), dictionary:
                    "/FunctionType 4 /Domain [0 1] "
                    + "/Range [0 1 0 1 0 1]"),
            ]
        )
        if let bitmap = ImageCodec.decodePDF(pdf, scale: 2) {
            let left = rgba(bitmap, x: 0, y: 0)
            let right = rgba(bitmap, x: bitmap.width - 1, y: 0)
            XCTAssertGreaterThan(right[0], left[0])
            XCTAssertEqual(left[1], 0)
            XCTAssertEqual(left[2], 0)
            XCTAssertEqual(right[3], 255)
        } else {
            XCTFail("measured axial-pattern calculator subset should render")
        }
    }

    func testPDFMalformedUnsupportedAndRecursiveInputsFailClosed() {
        let unknownOperator = singlePagePDF(
            mediaBox: "[0 0 1 1]", content: Array("BT\n".utf8)
        )
        XCTAssertNil(ImageCodec.decodePDF(unknownOperator, scale: 1))

        let unsupportedFilter = singlePagePDF(
            mediaBox: "[0 0 1 1]", content: [0, 1, 2, 3],
            contentDictionary: "/Filter /LZWDecode"
        )
        XCTAssertNil(ImageCodec.decodePDF(unsupportedFilter, scale: 1))

        let valid = singlePagePDF(
            mediaBox: "[0 0 1 1]", content: Array("0 0 1 rg 0 0 1 1 re f\n".utf8)
        )
        XCTAssertNil(ImageCodec.decodePDF(Array(valid.dropLast(24)), scale: 1),
                     "truncated xref/trailer must not be scanned heuristically")

        let recursive = makePDF([
            Array("<< /Type /Catalog /Pages 2 0 R >>".utf8),
            Array("<< /Type /Pages /Kids [3 0 R] /Count 1 >>".utf8),
            Array(("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 1 1] "
                + "/Resources << /XObject << /Loop 5 0 R >> >> "
                + "/Contents 4 0 R >>").utf8),
            pdfStream(Array("/Loop Do\n".utf8)),
            pdfStream(Array("/Loop Do\n".utf8), dictionary:
                "/Type /XObject /Subtype /Form /BBox [0 0 1 1] "
                + "/Resources << /XObject << /Loop 5 0 R >> >>"),
        ])
        XCTAssertNil(ImageCodec.decodePDF(recursive, scale: 1))

        let multiplePages = makePDF([
            Array("<< /Type /Catalog /Pages 2 0 R >>".utf8),
            Array("<< /Type /Pages /Kids [3 0 R 5 0 R] /Count 2 >>".utf8),
            Array(("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 1 1] "
                + "/Resources << >> /Contents 4 0 R >>").utf8),
            pdfStream(Array("0 0 1 rg 0 0 1 1 re f\n".utf8)),
            Array(("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 1 1] "
                + "/Resources << >> /Contents 6 0 R >>").utf8),
            pdfStream(Array("1 0 0 rg 0 0 1 1 re f\n".utf8)),
        ])
        XCTAssertNil(ImageCodec.decodePDF(multiplePages, scale: 1),
                     "UIImage's vector payload contract is exactly one page")
    }

    func testIndexedImageNamedCacheSeparatesAppearanceAndClearsIndexState() {
        withTempDirectory { root in
            let light = indexedPayload(at: root, id: "a", red: 10)
            let dark = indexedPayload(at: root, id: "b", red: 20)
            writeIndex(at: root, assets: [
                "Themed": imageRecord([
                    imageVariant(light, appearance: "any", scale: 2),
                    imageVariant(dark, appearance: "dark", scale: 2),
                ], intent: "template"),
            ])
            OpenUIKitRuntime.imageSearchPaths = [root]
            OpenUIKitRuntime.imageScreenScale = 2
            OpenUIKitRuntime.assetCatalogIdiom = .phone
            UITraitCollection.current = UITraitCollection(
                userInterfaceStyle: .light, displayScale: 2
            )
            XCTAssertEqual(UIImage.named("Themed")?.bitmap.pixels.first, 10)
            XCTAssertEqual(UIImage(named: "Themed")?.renderingMode,
                           .alwaysTemplate)

            // Appearance is part of the UIImage cache key.
            UITraitCollection.current = UITraitCollection(
                userInterfaceStyle: .dark, displayScale: 2
            )
            XCTAssertEqual(UIImage.named("Themed")?.bitmap.pixels.first, 20)

            let replacement = indexedPayload(at: root, id: "c", red: 30)
            writeIndex(at: root, assets: [
                "Themed": imageRecord([
                    imageVariant(replacement, appearance: "dark", scale: 2),
                ]),
            ])
            XCTAssertEqual(UIImage.named("Themed")?.bitmap.pixels.first, 20)
            UIImage.clearNamedCache()
            XCTAssertEqual(UIImage.named("Themed")?.bitmap.pixels.first, 30,
                           "clearing named images must also clear parsed indexes")
        }
    }

    func testIndexedColorsPreserveDynamicAppearanceSpaceAndPlatformRules() {
        withTempDirectory { root in
            let bundle = makeBundle(at: root + "/Colors.bundle")
            let reference: [String: Any] = [
                "idiom": "universal", "appearance": "any",
                "srgb": NSNull(), "reference": "labelColor",
                "platform": NSNull(),
            ]
            writeIndex(at: bundle.bundlePath, assets: [
                "Dynamic": [
                    "type": "colorset", "properties": [:],
                    "variants": [
                        colorVariant(native: [0.1, 0.2, 0.3, 0.4],
                                     srgb: [0.9, 0.9, 0.9, 0.9],
                                     space: "srgb"),
                        colorVariant(appearance: "dark",
                                     native: [0.8, 0.7, 0.6, 0.5],
                                     srgb: [0.2, 0.3, 0.4, 0.5],
                                     space: "display-p3", platform: "ios"),
                    ],
                ],
                "Extended": [
                    "type": "colorset", "properties": [:],
                    "variants": [colorVariant(
                        native: [1.2, -0.1, 0.5, 0.75],
                        srgb: [1, 0, 0.5, 0.75], space: "extended-srgb"
                    )],
                ],
                "Gray": [
                    "type": "colorset", "properties": [:],
                    "variants": [colorVariant(
                        native: [0.9, 0.4],
                        srgb: [0.902873, 0.902873, 0.902873, 0.4],
                        space: "gray-gamma-22"
                    )],
                ],
                "Platform": [
                    "type": "colorset", "properties": [:],
                    "variants": [
                        colorVariant(native: [1, 0, 0, 1],
                                     srgb: [1, 0, 0, 1], space: "srgb"),
                        colorVariant(native: [0, 1, 0, 1],
                                     srgb: [0, 1, 0, 1], space: "srgb",
                                     platform: "ios"),
                    ],
                ],
                "MacOnly": [
                    "type": "colorset", "properties": [:],
                    "variants": [colorVariant(
                        native: [1, 0, 0, 1], srgb: [1, 0, 0, 1],
                        space: "srgb", platform: "osx"
                    )],
                ],
                "Reference": [
                    "type": "colorset", "properties": [:],
                    "variants": [reference],
                ],
            ])

            let lightTraits = UITraitCollection(userInterfaceStyle: .light)
            let darkTraits = UITraitCollection(userInterfaceStyle: .dark)
            let dynamic = UIColor(named: "Dynamic", in: bundle,
                                  compatibleWith: lightTraits)
            let light = dynamic?.resolvedCGColor(with: lightTraits)
            let dark = dynamic?.resolvedCGColor(with: darkTraits)
            XCTAssertEqual(light?.red ?? -1, 0.1, accuracy: 0.000001)
            XCTAssertEqual(light?.alpha ?? -1, 0.4, accuracy: 0.000001)
            XCTAssertEqual(dark?.red ?? -1, 0.2, accuracy: 0.000001,
                           "Display-P3 reports the indexed sRGB conversion")
            XCTAssertEqual(dark?.green ?? -1, 0.3, accuracy: 0.000001)

            let extended = UIColor(named: "Extended", in: bundle,
                                   compatibleWith: lightTraits)?.cgColor
            XCTAssertEqual(extended?.red ?? -1, 1.2, accuracy: 0.000001)
            XCTAssertEqual(extended?.green ?? 1, -0.1, accuracy: 0.000001)
            let gray = UIColor(named: "Gray", in: bundle,
                               compatibleWith: lightTraits)?.cgColor
            XCTAssertEqual(gray?.red ?? -1, 0.9, accuracy: 0.000001)
            XCTAssertEqual(gray?.green ?? -1, 0.9, accuracy: 0.000001)
            XCTAssertEqual(gray?.blue ?? -1, 0.9, accuracy: 0.000001)
            XCTAssertEqual(gray?.alpha ?? -1, 0.4, accuracy: 0.000001)
            let platform = UIColor(named: "Platform", in: bundle,
                                   compatibleWith: lightTraits)?.cgColor
            XCTAssertEqual(platform?.green ?? -1, 1, accuracy: 0.000001)
            XCTAssertNil(UIColor(named: "MacOnly", in: bundle,
                                 compatibleWith: lightTraits))
            XCTAssertNil(UIColor(named: "Reference", in: bundle,
                                 compatibleWith: lightTraits))
        }
    }

    func testIndexRefusesUnsupportedUnresolvedMalformedAndUnsafeAssets() {
        withTempDirectory { root in
            let bundle = makeBundle(at: root + "/Refusal.bundle")
            let resources = bundle.bundlePath
            let vector = indexedPayload(at: resources, id: "d", red: 40,
                                        ext: ".pdf")
            let raster = indexedPayload(at: resources, id: "e", red: 50)
            let unresolvedPayload = indexedPayload(at: resources, id: "f", red: 60)
            writeImage(width: 3, height: 3, red: 200,
                       to: resources + "/Vector.png")
            writeImage(width: 3, height: 3, red: 201,
                       to: resources + "/AppIcon.png")
            writeImage(width: 3, height: 3, red: 202,
                       to: resources + "/Resizable.png")
            writeImage(width: 3, height: 3, red: 203,
                       to: resources + "/Qualified.png")
            writeImage(width: 3, height: 3, red: 204,
                       to: resources + "/Unresolved.png")
            writeImage(width: 3, height: 3, red: 205,
                       to: resources + "/Loose.png")
            writeIndex(at: resources, assets: [
                "Vector": imageRecord([imageVariant(vector, scale: 2)]),
                "AppIcon": imageRecord([imageVariant(raster, scale: 2)],
                                       type: "appiconset"),
                "Resizable": imageRecord([imageVariant(
                    raster, scale: 2, resizing: ["mode": "9-part"]
                )]),
                "Qualified": imageRecord([imageVariant(
                    raster, scale: 2, screenWidth: "4-inch"
                )]),
            ], unresolved: [
                "Unresolved": [
                    "type": ".brandassets",
                    "reason": "asset type outside the covered set",
                    "files": [unresolvedPayload],
                ],
            ])

            for blocked in [
                "Vector", "AppIcon", "Resizable", "Qualified", "Unresolved",
            ] {
                XCTAssertNil(UIImage(named: blocked, in: bundle,
                                     compatibleWith: nil), blocked)
            }
            XCTAssertEqual(UIImage(named: "Loose", in: bundle,
                                   compatibleWith: nil)?.bitmap.pixels.first, 205,
                           "a valid index with no such name permits legacy fallback")

            let malformed = makeBundle(at: root + "/Malformed.bundle")
            writeImage(width: 2, height: 2, red: 210,
                       to: malformed.bundlePath + "/Loose.png")
            let indexDirectory = malformed.bundlePath
                + "/OpenUIKit/AssetCatalogs"
            try! FileManager.default.createDirectory(
                atPath: indexDirectory, withIntermediateDirectories: true
            )
            try! Data("{ malformed".utf8).write(
                to: URL(fileURLWithPath: indexDirectory + "/index.json")
            )
            UIImage.clearNamedCache()
            XCTAssertNil(UIImage(named: "Loose", in: malformed,
                                 compatibleWith: nil))

            // Replacing a cached malformed index has no effect until the
            // application-resource cache boundary is cleared.
            writeIndex(at: malformed.bundlePath, assets: [:])
            XCTAssertNil(UIImage(named: "Loose", in: malformed,
                                 compatibleWith: nil))
            UIImage.clearNamedCache()
            XCTAssertEqual(UIImage(named: "Loose", in: malformed,
                                   compatibleWith: nil)?.bitmap.pixels.first, 210)

            var unsafe = raster
            unsafe["file"] = "../outside.png"
            writeIndex(at: malformed.bundlePath, assets: [
                "Unsafe": imageRecord([imageVariant(unsafe, scale: 2)]),
            ])
            UIImage.clearNamedCache()
            XCTAssertNil(UIImage(named: "Loose", in: malformed,
                                 compatibleWith: nil),
                         "one unsafe record invalidates the complete index")
        }
    }
}
