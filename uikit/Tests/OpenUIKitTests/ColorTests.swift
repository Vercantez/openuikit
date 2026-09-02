// Tests for the color module: SystemColors table + UIColor dynamic behavior.
// Ground truth: golden/system_colors.json (real UIKit, dumped by the oracle).
// Tests MAY use Foundation (the library must not).

import Foundation
import XCTest

@testable import OpenUIKit

@MainActor
final class ColorTests: XCTestCase {
    /// Repo root derived from this file's path: Tests/OpenUIKitTests/ColorTests.swift
    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // OpenUIKitTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // repo root
        .path

    /// golden/system_colors.json parsed with Foundation (independent of MiniJSON).
    static let golden: [String: [String: [Double]]] = {
        let url = URL(fileURLWithPath: repoRoot + "/golden/system_colors.json")
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let table = obj as? [String: [String: [Double]]] else {
            return [:]
        }
        return table
    }()

    override class func setUp() {
        super.setUp()
        // Point the library at the vendored resources via an absolute path so
        // the tests are independent of the test runner's cwd. (The library's
        // supported default is a repo-root cwd with the relative default path.)
        OpenUIKitRuntime.resourceRoot = repoRoot + "/Sources/OpenUIKit/Resources"
    }

    private func assertResolves(
        _ color: UIColor, name: String, style: UIUserInterfaceStyle,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let styleKey = style == .dark ? "dark" : "light"
        guard let expected = Self.golden[styleKey]?[name] else {
            XCTFail("golden/system_colors.json missing \(styleKey).\(name)", file: file, line: line)
            return
        }
        let c = color.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: style))
        XCTAssertEqual(Double(c.red), expected[0], accuracy: 1e-9, "\(name) \(styleKey) red", file: file, line: line)
        XCTAssertEqual(Double(c.green), expected[1], accuracy: 1e-9, "\(name) \(styleKey) green", file: file, line: line)
        XCTAssertEqual(Double(c.blue), expected[2], accuracy: 1e-9, "\(name) \(styleKey) blue", file: file, line: line)
        XCTAssertEqual(Double(c.alpha), expected[3], accuracy: 1e-9, "\(name) \(styleKey) alpha", file: file, line: line)
    }

    func testGoldenTableLoaded() {
        XCTAssertNotNil(Self.golden["light"], "golden/system_colors.json must load")
        XCTAssertNotNil(Self.golden["dark"])
    }

    /// 12 semantic colors x both styles, against golden/system_colors.json.
    func testSemanticColorsMatchGolden() {
        let cases: [(String, UIColor)] = [
            ("label", .label),
            ("secondaryLabel", .secondaryLabel),
            ("systemBackground", .systemBackground),
            ("secondarySystemBackground", .secondarySystemBackground),
            ("systemBlue", .systemBlue),
            ("systemRed", .systemRed),
            ("systemGreen", .systemGreen),
            ("systemGray", .systemGray),
            ("systemGray6", .systemGray6),
            ("separator", .separator),
            ("link", .link),
            ("tintColor", .tintColor),
        ]
        for (name, color) in cases {
            assertResolves(color, name: name, style: .light)
            assertResolves(color, name: name, style: .dark)
        }
    }

    /// Every name in the golden table must resolve exactly (both styles).
    func testAllGoldenNamesResolve() {
        for styleKey in ["light", "dark"] {
            let style: UIUserInterfaceStyle = styleKey == "dark" ? .dark : .light
            guard let names = Self.golden[styleKey]?.keys else {
                XCTFail("missing \(styleKey) table"); continue
            }
            for name in names.sorted() {
                assertResolves(UIColor(semantic: name), name: name, style: style)
            }
        }
    }

    func testUnspecifiedStyleResolvesAsLight() {
        let unspec = UIColor.label.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .unspecified))
        let light = UIColor.label.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .light))
        XCTAssertEqual(unspec, light)
    }

    func testUnknownNameResolvesToMagenta() {
        let c = UIColor(semantic: "definitelyNotAColor")
            .resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .light))
        XCTAssertEqual(c, CGColor(red: 1, green: 0, blue: 1, alpha: 1))
    }

    func testLightAndDarkDiffer() {
        // Sanity: dynamic colors actually change with style.
        for color in [UIColor.label, .systemBackground, .systemGray6] {
            let l = color.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .light))
            let d = color.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .dark))
            XCTAssertNotEqual(l, d)
        }
    }

    func testWithAlphaComponentOnFixedColor() {
        let c = UIColor.red.withAlphaComponent(0.25)
            .resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .light))
        XCTAssertEqual(c, CGColor(red: 1, green: 0, blue: 0, alpha: 0.25))
    }

    /// withAlphaComponent on a semantic color stays dynamic: RGB still follows
    /// the trait collection, only alpha is overridden.
    func testWithAlphaComponentOnSemanticColorStaysDynamic() {
        let half = UIColor.label.withAlphaComponent(0.5)
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let base = UIColor.label.resolvedCGColor(with: traits)
            let c = half.resolvedCGColor(with: traits)
            XCTAssertEqual(c.red, base.red)
            XCTAssertEqual(c.green, base.green)
            XCTAssertEqual(c.blue, base.blue)
            XCTAssertEqual(Double(c.alpha), 0.5, accuracy: 1e-12)
        }
    }

    func testDynamicProviderColor() {
        let color = UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        }
        let l = color.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .light))
        let d = color.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .dark))
        XCTAssertEqual(l, CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        XCTAssertEqual(d, CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    }

    func testDynamicProviderCanWrapSemanticColors() {
        // Provider returning semantic colors must resolve them through the
        // same traits it was given.
        let color = UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor.systemBackground : UIColor.label
        }
        assertResolves(color, name: "label", style: .light)
        let dark = color.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .dark))
        let expected = UIColor.systemBackground
            .resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .dark))
        XCTAssertEqual(dark, expected)
    }

    func testWithAlphaComponentOnDynamicProviderColor() {
        let color = UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        }.withAlphaComponent(0.3)
        let d = color.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .dark))
        XCTAssertEqual(d.red, 1)
        XCTAssertEqual(Double(d.alpha), 0.3, accuracy: 1e-12)
    }

    /// `cgColor` and `resolvedColor` follow UITraitCollection.current.
    func testTraitCollectionCurrentBehavior() {
        let saved = UITraitCollection.current
        defer { UITraitCollection.current = saved }

        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light)
        let lightResolved = UIColor.label.cgColor
        XCTAssertEqual(
            lightResolved,
            UIColor.label.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .light)))

        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark)
        let darkResolved = UIColor.label.cgColor
        XCTAssertEqual(
            darkResolved,
            UIColor.label.resolvedCGColor(with: UITraitCollection(userInterfaceStyle: .dark)))
        XCTAssertNotEqual(lightResolved, darkResolved)

        // resolvedColor snapshots: the returned color is fixed and no longer
        // tracks the current traits.
        let snapshot = UIColor.label.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light)
        XCTAssertEqual(snapshot.cgColor, darkResolved)

        // == compares through .current: label equals its dark snapshot only in dark.
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark)
        XCTAssertTrue(UIColor.label == snapshot)
        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light)
        XCTAssertFalse(UIColor.label == snapshot)
    }
}
