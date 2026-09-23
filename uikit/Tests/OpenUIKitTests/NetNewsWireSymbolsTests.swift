import XCTest
@testable import OpenUIKit

/// The SF Symbols NetNewsWire's Assets.swift force-unwraps
/// (`RSImage(symbol: "text.page")!` at :47, among 41) were not in the
/// harvested ink tables, so `UIImage(systemName:)` returned nil and the app
/// trapped at launch. Harvested on iOS 26.1 (Tools/oracle2/symbolinkprobe,
/// names.txt extended; merge_symbols.py checked every previously stored mask
/// re-harvested byte-identically and the default/body aliases hold).
@MainActor
final class NetNewsWireSymbolsTests: XCTestCase {
    func testNetNewsWireSymbolsResolveOnTheIOSCut() {
        let savedCut = OpenUIKitRuntime.systemFontCut
        let savedScale = OpenUIKitRuntime.imageScreenScale
        defer {
            OpenUIKitRuntime.systemFontCut = savedCut
            OpenUIKitRuntime.imageScreenScale = savedScale
        }
        OpenUIKitRuntime.systemFontCut = .iOS
        let names = ["text.page", "text.page.fill", "text.page.slash", "text.pad.header",
                     "document.on.document", "doc.plaintext", "doc.plaintext.fill", "doc.richtext",
                     "sun.max.fill", "largecircle.fill.circle", "arrowtriangle.down.circle",
                     "arrowtriangle.up.circle", "chevron.down.circle", "square.and.pencil",
                     "folder.badge.plus", "gearshape.2", "bubbles.and.sparkles", "at",
                     "arrow.turn.down.left", "line.horizontal.3.decrease.circle",
                     "line.horizontal.3.decrease.circle.fill", "bell.badge", "arrow.up.right"]
        for scale in [CGFloat(2), 3] {
            OpenUIKitRuntime.imageScreenScale = scale
            for name in names {
                XCTAssertNotNil(UIImage(systemName: name), "\(name) @\(scale)x")
            }
        }
    }
}
