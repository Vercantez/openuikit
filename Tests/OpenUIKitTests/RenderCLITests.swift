// Tests for the rendercli module (Sources/openrender): drives the built
// openrender binary end-to-end and checks scene interpretation, the layout
// dump format, PNG output, warnings, and exit codes.
// Tests MAY use Foundation (only the library targets may not).

import Foundation
import XCTest

final class RenderCLITests: XCTestCase {
    /// Directory containing the built products (the openrender binary).
    private var productsDirectory: URL {
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("cannot locate products directory")
    }

    private struct CLIResult {
        var exitCode: Int32
        var stdout: String
        var stderr: String
    }

    @discardableResult
    private func runCLI(_ arguments: [String]) throws -> CLIResult {
        let p = Process()
        p.executableURL = productsDirectory.appendingPathComponent("openrender")
        p.arguments = arguments
        let outPipe = Pipe(), errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe
        try p.run()
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return CLIResult(exitCode: p.terminationStatus,
                         stdout: String(data: outData, encoding: .utf8) ?? "",
                         stderr: String(data: errData, encoding: .utf8) ?? "")
    }

    private func makeTempDir() throws -> URL {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("rendercli-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir
    }

    private func writeScene(_ scene: [String: Any], name: String, in dir: URL) throws -> URL {
        let url = dir.appendingPathComponent("\(name).json")
        let data = try JSONSerialization.data(withJSONObject: scene)
        try data.write(to: url)
        return url
    }

    private func loadLayout(_ dir: URL, _ name: String) throws -> [String: [String: Any]] {
        let data = try Data(contentsOf: dir.appendingPathComponent("\(name).layout.json"))
        let obj = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let views = try XCTUnwrap(obj["views"] as? [[String: Any]])
        var byPath: [String: [String: Any]] = [:]
        for v in views { byPath[try XCTUnwrap(v["path"] as? String)] = v }
        return byPath
    }

    private func frame(_ entry: [String: Any]?) throws -> [Double] {
        try XCTUnwrap(entry?["frame"] as? [Double])
    }

    // MARK: - Tests

    func testGeometrySceneLayoutAndPNG() throws {
        let dir = try makeTempDir()
        let scene: [String: Any] = [
            "name": "t_geom",
            "size": [40, 30],
            "scale": 2,
            "style": "light",
            "root": [
                "class": "UIView",
                "backgroundColor": "#FFFFFF",
                "subviews": [
                    ["class": "UIView", "frame": [2, 3, 10, 8], "backgroundColor": "#FF0000"],
                    ["class": "UIView", "frame": [5, 5, 20, 10], "backgroundColor": "rgba(0,0,1,1)",
                     "subviews": [
                        ["class": "UIView", "frame": [1, 1, 4, 4], "backgroundColor": "#00FF00"],
                     ]],
                    // 45-degree rotation: frame becomes the transformed bbox.
                    ["class": "UIView", "frame": [10, 10, 8, 6],
                     "backgroundColor": "#000000",
                     "transform": [0.7071, 0.7071, -0.7071, 0.7071, 0, 0]],
                ],
            ],
        ]
        let sceneFile = try writeScene(scene, name: "t_geom", in: dir)
        let res = try runCLI(["render", dir.path, sceneFile.path])
        XCTAssertEqual(res.exitCode, 0)
        XCTAssertTrue(res.stdout.contains("rendered t_geom"), "stdout: \(res.stdout)")

        let byPath = try loadLayout(dir, "t_geom")
        // Root mirrors the oracle quirk: frame stays (0,0,0,0).
        XCTAssertEqual(try frame(byPath[""]), [0, 0, 0, 0])
        XCTAssertEqual(byPath[""]?["class"] as? String, "UIView")
        XCTAssertNil(byPath[""]?["intrinsic"], "plain UIView must not emit intrinsic")
        XCTAssertEqual(try frame(byPath["0"]), [2, 3, 10, 8])
        XCTAssertEqual(try frame(byPath["1"]), [5, 5, 20, 10])
        XCTAssertEqual(try frame(byPath["1.0"]), [1, 1, 4, 4])
        // Rotated 8x6 about center (14, 13): bbox ~ 9.899 x 9.899, 3-decimal rounded.
        let f2 = try frame(byPath["2"])
        XCTAssertEqual(f2[0], 9.05, accuracy: 0.001)
        XCTAssertEqual(f2[1], 8.05, accuracy: 0.001)
        XCTAssertEqual(f2[2], 9.899, accuracy: 0.001)
        XCTAssertEqual(f2[3], 9.899, accuracy: 0.001)

        // PNG: signature and IHDR dimensions = size * scale.
        let png = try Data(contentsOf: dir.appendingPathComponent("t_geom.png"))
        XCTAssertEqual(Array(png.prefix(8)), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        func be32(_ o: Int) -> UInt32 {
            (UInt32(png[o]) << 24) | (UInt32(png[o + 1]) << 16) | (UInt32(png[o + 2]) << 8) | UInt32(png[o + 3])
        }
        XCTAssertEqual(be32(16), 80)  // width px
        XCTAssertEqual(be32(20), 60)  // height px
    }

    func testLabelEmitsIntrinsicAndSizeThatFits() throws {
        let dir = try makeTempDir()
        let scene: [String: Any] = [
            "name": "t_label",
            "size": [100, 40],
            "root": [
                "class": "UIView",
                "subviews": [
                    ["class": "UILabel", "frame": [5, 5, 0, 0], "text": "Hi", "sizeToFit": true],
                ],
            ],
        ]
        let sceneFile = try writeScene(scene, name: "t_label", in: dir)
        let res = try runCLI(["render", dir.path, sceneFile.path])
        XCTAssertEqual(res.exitCode, 0)

        let byPath = try loadLayout(dir, "t_label")
        let label = try XCTUnwrap(byPath["0"])
        XCTAssertEqual(label["class"] as? String, "UILabel")
        XCTAssertEqual((label["intrinsic"] as? [Double])?.count, 2)
        XCTAssertEqual((label["sizeThatFits200"] as? [Double])?.count, 2)
        // sizeToFit preserved the origin.
        let f = try frame(byPath["0"])
        XCTAssertEqual(f[0], 5)
        XCTAssertEqual(f[1], 5)
        XCTAssertGreaterThan(f[2], 0, "sizeToFit should have grown the label")
    }

    func testUnsupportedClassWarnsAndSubstitutesUIView() throws {
        let dir = try makeTempDir()
        let scene: [String: Any] = [
            "name": "t_button",
            "size": [60, 40],
            "root": [
                "class": "UIView",
                "subviews": [
                    ["class": "UIButton", "frame": [1, 2, 30, 20], "title": "Tap"],
                ],
            ],
        ]
        let sceneFile = try writeScene(scene, name: "t_button", in: dir)
        let res = try runCLI(["render", dir.path, sceneFile.path])
        XCTAssertEqual(res.exitCode, 0)
        XCTAssertTrue(res.stderr.contains("UIButton"), "stderr should warn about UIButton: \(res.stderr)")

        let byPath = try loadLayout(dir, "t_button")
        // Substituted view keeps common props but reports as UIView, no intrinsic.
        XCTAssertEqual(byPath["0"]?["class"] as? String, "UIView")
        XCTAssertEqual(try frame(byPath["0"]), [1, 2, 30, 20])
        XCTAssertNil(byPath["0"]?["intrinsic"])
    }

    func testMissingSceneFileFailsWithExit1() throws {
        let dir = try makeTempDir()
        let res = try runCLI(["render", dir.path, dir.appendingPathComponent("nope.json").path])
        XCTAssertEqual(res.exitCode, 1)
        XCTAssertTrue(res.stdout.contains("FAIL"), "stdout: \(res.stdout)")
    }

    func testUsageWithoutArgsExits1() throws {
        let res = try runCLI([])
        XCTAssertEqual(res.exitCode, 1)
        XCTAssertTrue(res.stdout.contains("usage:"))
    }

    func testMatchesGoldenLayoutForBoxesBasic() throws {
        // Full-fidelity check against the real-UIKit golden layout dump,
        // when running from the repo checkout (fixtures + golden present).
        let cwd = FileManager.default.currentDirectoryPath
        let sceneFile = URL(fileURLWithPath: cwd).appendingPathComponent("fixtures/scenes/boxes_basic.json")
        let goldenFile = URL(fileURLWithPath: cwd).appendingPathComponent("golden/boxes_basic.layout.json")
        guard FileManager.default.fileExists(atPath: sceneFile.path),
              FileManager.default.fileExists(atPath: goldenFile.path) else {
            throw XCTSkip("repo fixtures/golden not reachable from test cwd")
        }
        let dir = try makeTempDir()
        let res = try runCLI(["render", dir.path, sceneFile.path])
        XCTAssertEqual(res.exitCode, 0)

        let ours = try loadLayout(dir, "boxes_basic")
        let goldenData = try Data(contentsOf: goldenFile)
        let golden = try XCTUnwrap(try JSONSerialization.jsonObject(with: goldenData) as? [String: Any])
        let goldenViews = try XCTUnwrap(golden["views"] as? [[String: Any]])
        XCTAssertEqual(goldenViews.count, ours.count)
        for gv in goldenViews {
            let path = try XCTUnwrap(gv["path"] as? String)
            let entry = try XCTUnwrap(ours[path], "missing path \(path)")
            XCTAssertEqual(entry["class"] as? String, gv["class"] as? String, "path \(path)")
            let gf = try XCTUnwrap(gv["frame"] as? [Double])
            let of = try frame(entry)
            for i in 0..<4 {
                XCTAssertEqual(of[i], gf[i], accuracy: 0.5, "path \(path) frame[\(i)]")
            }
        }
    }
}
