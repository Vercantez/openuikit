// View-module tests: frame <-> center/bounds math, incl. non-identity
// transforms, validated against golden/transforms.layout.json (real UIKit).
import XCTest
import Foundation
@testable import OpenUIKit

// XCTest re-exports Foundation/CoreGraphics on Darwin; pin the portable types.
private typealias CGAffineTransform = OpenUIKit.CGAffineTransform

final class ViewGeometryTests: XCTestCase {

    // MARK: identity frame math

    func testFrameFromCenterAndBounds() {
        let v = UIView()
        v.bounds = CGRect(x: 0, y: 0, width: 80, height: 60)
        v.center = CGPoint(x: 100, y: 50)
        XCTAssertEqual(v.frame, CGRect(x: 60, y: 20, width: 80, height: 60))
    }

    func testSetFrameSetsCenterAndBounds() {
        let v = UIView(frame: CGRect(x: 40, y: 40, width: 80, height: 60))
        XCTAssertEqual(v.center, CGPoint(x: 80, y: 70))
        XCTAssertEqual(v.bounds.size, CGSize(width: 80, height: 60))
        XCTAssertEqual(v.bounds.origin, .zero)
    }

    func testBoundsOriginDoesNotAffectFrame() {
        let v = UIView(frame: CGRect(x: 10, y: 20, width: 30, height: 40))
        v.bounds.origin = CGPoint(x: 5, y: 7)
        XCTAssertEqual(v.frame, CGRect(x: 10, y: 20, width: 30, height: 40))
    }

    // MARK: transformed frame math (frame = bbox of transformed bounds about center)

    func testRotated45FrameIsBBox() {
        // Mirrors golden/transforms.layout.json path "0".
        let v = UIView(frame: CGRect(x: 40, y: 40, width: 80, height: 60))
        v.transform = CGAffineTransform(a: 0.7071, b: 0.7071, c: -0.7071, d: 0.7071, tx: 0, ty: 0)
        let f = v.frame
        XCTAssertEqual(f.origin.x, 30.503, accuracy: 0.0015)
        XCTAssertEqual(f.origin.y, 20.503, accuracy: 0.0015)
        XCTAssertEqual(f.width, 98.994, accuracy: 0.0015)
        XCTAssertEqual(f.height, 98.994, accuracy: 0.0015)
        // Center and bounds are untouched by the transform.
        XCTAssertEqual(v.center, CGPoint(x: 80, y: 70))
        XCTAssertEqual(v.bounds.size, CGSize(width: 80, height: 60))
    }

    func testScaledFrame() {
        // Mirrors golden/transforms.layout.json path "1".
        let v = UIView(frame: CGRect(x: 160, y: 40, width: 80, height: 60))
        v.transform = CGAffineTransform(scaleX: 1.5, y: 0.5)
        XCTAssertEqual(v.frame, CGRect(x: 140, y: 55, width: 120, height: 30))
    }

    func testTranslatedFrame() {
        // Mirrors golden/transforms.layout.json path "2".
        let v = UIView(frame: CGRect(x: 40, y: 140, width: 80, height: 60))
        v.transform = CGAffineTransform(translationX: 30, y: 10)
        XCTAssertEqual(v.frame, CGRect(x: 70, y: 150, width: 80, height: 60))
    }

    func testSetFrameWithNonIdentityTransformSetsBoundsSizeAndCenter() {
        // Matches the oracle's observed behavior: the assigned rect's size
        // becomes bounds.size and its midpoint becomes center; reading frame
        // back then reports the transformed bbox.
        let v = UIView()
        v.transform = CGAffineTransform(rotationAngle: .pi / 2)
        v.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        XCTAssertEqual(v.bounds.size, CGSize(width: 100, height: 50))
        XCTAssertEqual(v.center, CGPoint(x: 50, y: 25))
        let f = v.frame
        XCTAssertEqual(f.origin.x, 25, accuracy: 1e-9)
        XCTAssertEqual(f.origin.y, -25, accuracy: 1e-9)
        XCTAssertEqual(f.width, 50, accuracy: 1e-9)
        XCTAssertEqual(f.height, 100, accuracy: 1e-9)
    }

    func testSettingCenterMovesFrameOnly() {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        v.center = CGPoint(x: 100, y: 100)
        XCTAssertEqual(v.frame, CGRect(x: 95, y: 95, width: 10, height: 10))
        XCTAssertEqual(v.bounds, CGRect(x: 0, y: 0, width: 10, height: 10))
    }

    // MARK: golden fixture round-trip

    /// Builds the transforms fixture hierarchy with OUR UIView and asserts the
    /// resulting frames reproduce golden/transforms.layout.json (real UIKit).
    func testGoldenTransformsLayout() throws {
        let root = try Self.repoRoot()
        let fixtureURL = root.appendingPathComponent("fixtures/scenes/transforms.json")
        let goldenURL = root.appendingPathComponent("golden/transforms.layout.json")

        let scene = try JSONSerialization.jsonObject(
            with: Data(contentsOf: fixtureURL)) as! [String: Any]
        let golden = try JSONSerialization.jsonObject(
            with: Data(contentsOf: goldenURL)) as! [String: Any]

        let sz = (scene["size"] as! [Any]).map(Self.cg)
        let rootJ = scene["root"] as! [String: Any]
        let rootView = Self.buildPlainView(rootJ)
        rootView.frame = CGRect(x: 0, y: 0, width: sz[0], height: sz[1])
        rootView.layoutIfNeeded()

        var byPath: [String: UIView] = ["": rootView]
        func index(_ v: UIView, _ path: String) {
            for (i, s) in v.subviews.enumerated() {
                let p = path.isEmpty ? "\(i)" : "\(path).\(i)"
                byPath[p] = s
                index(s, p)
            }
        }
        index(rootView, "")

        var checked = 0
        for entry in golden["views"] as! [[String: Any]] {
            let path = entry["path"] as! String
            // The oracle's root-frame dump has a known quirk (frame recorded
            // before assignment); subview frames are the ground truth here.
            if path.isEmpty { continue }
            let expected = (entry["frame"] as! [Any]).map(Self.cg)
            let v = try XCTUnwrap(byPath[path], "missing view at path \(path)")
            let f = v.frame
            XCTAssertEqual(f.origin.x, expected[0], accuracy: 0.0015, "x at \(path)")
            XCTAssertEqual(f.origin.y, expected[1], accuracy: 0.0015, "y at \(path)")
            XCTAssertEqual(f.width, expected[2], accuracy: 0.0015, "w at \(path)")
            XCTAssertEqual(f.height, expected[3], accuracy: 0.0015, "h at \(path)")
            checked += 1
        }
        XCTAssertEqual(checked, 3, "expected 3 subview entries in the golden dump")
    }

    // MARK: helpers

    fileprivate static func cg(_ v: Any) -> CGFloat {
        if let d = v as? Double { return d }
        if let i = v as? Int { return CGFloat(i) }
        return 0
    }

    /// Builds a plain-UIView hierarchy from scene JSON (frame + transform +
    /// subviews only — enough for geometry fixtures).
    static func buildPlainView(_ j: [String: Any]) -> UIView {
        let v = UIView()
        if let f = j["frame"] as? [Any], f.count == 4 {
            let c = f.map(cg)
            v.frame = CGRect(x: c[0], y: c[1], width: c[2], height: c[3])
        }
        if let subs = j["subviews"] as? [[String: Any]] {
            for s in subs { v.addSubview(buildPlainView(s)) }
        }
        // Scene spec: transform is applied AFTER the frame is set.
        if let t = j["transform"] as? [Any], t.count == 6 {
            let c = t.map(cg)
            v.transform = CGAffineTransform(a: c[0], b: c[1], c: c[2], d: c[3],
                                            tx: c[4], ty: c[5])
        }
        return v
    }

    static func repoRoot() throws -> URL {
        // Tests/OpenUIKitTests/<file> → repo root is two levels up.
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // Tests/OpenUIKitTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // repo root
        guard FileManager.default.fileExists(
            atPath: url.appendingPathComponent("golden").path) else {
            throw XCTSkip("golden/ directory not found next to test sources")
        }
        return url
    }
}
