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

    func testBundleNamedImageDoesNotPretendToDecodeAssetsCarOrVectors() {
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
