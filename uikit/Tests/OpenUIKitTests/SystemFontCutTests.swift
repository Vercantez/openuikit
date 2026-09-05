// The two cuts of San Francisco. Owner: text module.
//
// Mac Catalyst resolves `UIFont.systemFont` to `.SFNS-*` and iOS to
// `.SFUI-*`; below 20 pt the iOS cut is spaced tighter by a per-size
// constant. golden/font_metrics.json is the Catalyst dump (`oracle
// fontmetrics`); golden/font_metrics_ios.json is the SAME dump re-taken on
// iOS 26.1 (Tools/oracle2/fontprobe, scripts/font_probe_sim.sh). Both must
// be reproduced EXACTLY by the engine under the corresponding cut.
import Foundation
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class SystemFontCutTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TextTestSupport.configureResourceRoot()
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = .macOS
        super.tearDown()
    }

    func fonts(_ file: String) throws -> [[String: Any]] {
        let json = try TextTestSupport.loadJSON(file)
        return try XCTUnwrap(json["fonts"] as? [[String: Any]])
    }

    /// The default cut is the macOS one — it is what the vendored metrics
    /// table describes and what the rasterizer's SFNS.ttf draws, so every
    /// Catalyst-rendered golden keeps working with no host configuration.
    func testDefaultCutIsMacOS() {
        XCTAssertEqual(OpenUIKitRuntime.systemFontCut, .macOS)
        XCTAssertEqual(FontEngine.cutDelta(for: .systemFont(ofSize: 17, weight: .semibold)), 0,
                       accuracy: 1e-12)
    }

    /// Under the iOS cut, EVERY advance of EVERY vendored font entry must
    /// equal the value real iOS reports (432 entries x 95 glyphs).
    func testEveryAdvanceMatchesTheIOSDump() throws {
        OpenUIKitRuntime.systemFontCut = .iOS
        var checked = 0
        for entry in try fonts("golden/font_metrics_ios.json") {
            let id = try XCTUnwrap(entry["id"] as? String)
            let font = try XCTUnwrap(TextTestSupport.font(fromID: id))
            for (ch, gold) in try XCTUnwrap(entry["advances"] as? [String: Double]) {
                let scalar = try XCTUnwrap(ch.unicodeScalars.first)
                XCTAssertEqual(FontEngine.advance(of: scalar, font: font), gold,
                               accuracy: 1e-9, "\(id) advance '\(ch)'")
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 40_000, "expected 432 fonts x 95 glyphs")
    }

    /// Pair kerning is IDENTICAL between the cuts: the Catalyst-derived
    /// kerning table plus the iOS advances reproduces the iOS string widths
    /// exactly. (If kerning differed, this would drift per kern pair.)
    func testStringWidthsMatchTheIOSDump() throws {
        OpenUIKitRuntime.systemFontCut = .iOS
        var checked = 0
        for entry in try fonts("golden/font_metrics_ios.json") {
            let id = try XCTUnwrap(entry["id"] as? String)
            let font = try XCTUnwrap(TextTestSupport.font(fromID: id))
            for (s, gold) in try XCTUnwrap(entry["stringWidths"] as? [String: Double]) {
                XCTAssertEqual(FontEngine.measure(s, font: font), gold,
                               accuracy: 0.01, "\(id) '\(s)'")
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 2000, "expected all 432 fonts x ~6 strings")
    }

    /// Switching the cut must not disturb the macOS numbers.
    func testMacOSCutStillMatchesTheCatalystDump() throws {
        OpenUIKitRuntime.systemFontCut = .iOS
        OpenUIKitRuntime.systemFontCut = .macOS
        for entry in try fonts("golden/font_metrics.json") {
            let id = try XCTUnwrap(entry["id"] as? String)
            guard id == "system-semibold-17.0" || id == "italic-regular-12.0"
                || id == "mono-regular-15.0" else { continue }
            let font = try XCTUnwrap(TextTestSupport.font(fromID: id))
            for (ch, gold) in try XCTUnwrap(entry["advances"] as? [String: Double]) {
                let scalar = try XCTUnwrap(ch.unicodeScalars.first)
                XCTAssertEqual(FontEngine.advance(of: scalar, font: font), gold,
                               accuracy: 1e-9, "\(id) advance '\(ch)'")
            }
        }
    }

    /// The delta is zero where the measurement says it is: monospaced at
    /// every size (SF Mono has no optical-size axis) and every size >= 20 pt
    /// (where SF switches from the Text face to Display).
    func testDeltaIsZeroForMonoAndAtDisplaySizes() {
        OpenUIKitRuntime.systemFontCut = .iOS
        for size in stride(from: 8.0, through: 40.0, by: 0.5) {
            XCTAssertEqual(FontEngine.cutDelta(for: .monospacedSystemFont(ofSize: size,
                                                                         weight: .regular)),
                           0, accuracy: 1e-12, "mono \(size)")
            if size >= 20 {
                XCTAssertEqual(FontEngine.cutDelta(for: .systemFont(ofSize: size)), 0,
                               accuracy: 1e-12, "system \(size)")
            } else {
                XCTAssertGreaterThan(FontEngine.cutDelta(for: .systemFont(ofSize: size)), 0,
                                     "system \(size)")
            }
        }
    }

    /// The exact case that broke `alert_dark`: the alert title is 17 pt
    /// semibold, and real iOS lays "Delete File?" out 3.69 pt narrower than
    /// Catalyst does — enough to move the "?" clean off its golden ink.
    /// (91.99417626857758 is CTLineGetTypographicBounds in the simulator;
    /// Tools/oracle2/alerttextprobe.)
    func testAlertTitleWidthMatchesRealIOS() {
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        OpenUIKitRuntime.systemFontCut = .macOS
        XCTAssertEqual(FontEngine.measure("Delete File?", font: font),
                       95.679723177948, accuracy: 1e-6)
        OpenUIKitRuntime.systemFontCut = .iOS
        XCTAssertEqual(FontEngine.measure("Delete File?", font: font),
                       91.99417626857758, accuracy: 1e-6)
    }

    /// A UILabel must pick the cut up through the normal measurement path
    /// (this is what actually moves glyphs in a render).
    func testLabelIntrinsicSizeFollowsTheCut() {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.text = "Delete File?"
        OpenUIKitRuntime.systemFontCut = .macOS
        let mac = label.intrinsicContentSize.width
        OpenUIKitRuntime.systemFontCut = .iOS
        let ios = label.intrinsicContentSize.width
        // 11 advances x T(17) = 37 font units = 3.378 pt, then each width is
        // ceiled to the 0.5 pt device pixel (96.0 vs 92.0).
        XCTAssertEqual(mac - ios, 11 * 37 * 17 / 2048, accuracy: 0.75)
        XCTAssertLessThan(ios, mac)
    }
}
