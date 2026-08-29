import Foundation
import XCTest
@testable import OpenUIKit

final class NamedAssetLoadingTests: XCTestCase {
    private var savedImageSearchPaths: [String] = []
    private var savedImageScale: CGFloat = 2

    override func setUp() {
        super.setUp()
        savedImageSearchPaths = OpenUIKitRuntime.imageSearchPaths
        savedImageScale = OpenUIKitRuntime.imageScreenScale
    }

    override func tearDown() {
        OpenUIKitRuntime.imageSearchPaths = savedImageSearchPaths
        OpenUIKitRuntime.imageScreenScale = savedImageScale
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
}
