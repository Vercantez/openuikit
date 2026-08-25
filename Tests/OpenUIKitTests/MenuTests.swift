// Menus & actions (M13). Owner: menus module.
//
// The menu platter has NO fixture scene — iOS 26 draws it in the render
// server and `drawHierarchy` returns it blank, so no scene renderer can be
// compared against it (the full argument is in the header of
// Sources/OpenUIKit/UIContextMenu.swift). These tests are the substitute
// gate, and every expected number in them is a MEASUREMENT:
//
//   - the layout numbers are read off `Tools/oracle2/menuprobe`'s dumps of
//     the real private view tree (frames in window coordinates);
//   - the pixel numbers are read off the real DEVICE FRAMEBUFFER
//     (`xcrun simctl io screenshot`) of the same menus over known bases.
//
// So a regression in the menu's geometry or in its platter fill/shadow fails
// here exactly as a fixture diff would.
import XCTest
@testable import OpenUIKit

private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect

@MainActor
final class MenuLayoutTests: XCTestCase {

    private func action(_ title: String, subtitle: String? = nil,
                        state: UIMenuElement.State = .off,
                        attributes: UIMenuElement.Attributes = []) -> UIAction {
        UIAction(title: title, subtitle: subtitle, attributes: attributes,
                 state: state) { _ in }
    }

    /// menuprobe `three_light`: platter (40, 120, 250, 146); cells at y 130 /
    /// 172 / 214, each 42 tall; labels at x 68, width 194, y +10.667, box
    /// 20.333.
    func testThreePlainRowsMatchTheProbedPlatter() {
        let menu = UIMenu(children: [action("Copy"), action("Duplicate"),
                                     action("Delete", attributes: .destructive)])
        let l = UIMenuLayout.layout(menu)
        XCTAssertEqual(l.size.width, 250)
        XCTAssertEqual(l.size.height, 146, accuracy: 0.01)
        XCTAssertEqual(l.rows.count, 3)
        for (i, row) in l.rows.enumerated() {
            XCTAssertEqual(row.frame.minY, 10 + 42 * CGFloat(i), accuracy: 0.01)
            XCTAssertEqual(row.frame.height, 42, accuracy: 0.01)
            XCTAssertEqual(row.titleFrame.minX, 28)
            XCTAssertEqual(row.titleFrame.width, 194)
            XCTAssertEqual(row.titleFrame.minY - row.frame.minY, 10 + 2.0 / 3.0, accuracy: 0.01)
            XCTAssertEqual(row.titleFrame.height, 20 + 1.0 / 3.0, accuracy: 0.01)
        }
    }

    /// menuprobe `one_light`: platter height 62 = 10 + 42 + 10.
    func testSingleRowPlatterHeight() {
        let l = UIMenuLayout.layout(UIMenu(children: [action("Copy")]))
        XCTAssertEqual(l.size.height, 62, accuracy: 0.01)
    }

    /// menuprobe `titled`: a menu TITLE adds a 40.333 pt header (label at
    /// y 20, box 15.667) and the first cell then starts at 40.333 + 10;
    /// platter height 144.333.
    func testMenuTitleHeader() {
        let menu = UIMenu(title: "Actions", children: [action("Copy"), action("Paste")])
        let l = UIMenuLayout.layout(menu)
        XCTAssertEqual(l.size.height, 144 + 1.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(l.headerFrame?.height ?? 0, 40 + 1.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(l.rows[0].frame.minY, 50 + 1.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(l.separatorYs, [40 + 1.0 / 3.0])
    }

    /// menuprobe `subtitle`: a subtitled row is 58 tall, its subtitle box
    /// 15.667 starting 21 pt below the row's top (10.667 + 20.333 + 0.667).
    func testSubtitleRow() {
        let menu = UIMenu(children: [action("Copy", subtitle: "Copy this item"),
                                     action("Move", subtitle: "Move elsewhere")])
        let l = UIMenuLayout.layout(menu)
        XCTAssertEqual(l.size.height, 136, accuracy: 0.01)
        XCTAssertEqual(l.rows[0].frame.height, 58, accuracy: 0.01)
        let sub = try! XCTUnwrap(l.rows[0].subtitleFrame)
        XCTAssertEqual(sub.minY - l.rows[0].frame.minY, 31 + 2.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(sub.height, 15 + 2.0 / 3.0, accuracy: 0.01)
    }

    /// menuprobe `inline`: an inline section leaves a 21 pt gap — cells at
    /// 130 / 172 / 235 in a 167 pt platter.
    func testInlineSectionGap() {
        let menu = UIMenu(children: [
            action("Copy"), action("Duplicate"),
            UIMenu(options: .displayInline, children: [action("Delete")]),
        ])
        let l = UIMenuLayout.layout(menu)
        XCTAssertEqual(l.size.height, 167, accuracy: 0.01)
        XCTAssertEqual(l.rows.count, 3)
        XCTAssertEqual(l.rows[2].frame.minY - l.rows[1].frame.maxY, 21, accuracy: 0.01)
    }

    /// menuprobe `state`: ONE item checked moves EVERY title to inset 40.
    func testCheckColumnIsReservedForTheWholeMenu() {
        let menu = UIMenu(children: [action("Small"), action("Medium", state: .on),
                                     action("Large")])
        let l = UIMenuLayout.layout(menu)
        for row in l.rows {
            XCTAssertEqual(row.titleFrame.minX, 40)
            XCTAssertEqual(row.titleFrame.width, 182)
        }
        XCTAssertEqual(l.rows.map(\.showsCheck), [false, true, false])
        XCTAssertEqual(l.size.height, 146, accuracy: 0.01)
    }

    /// menuprobe `nested`: a submenu is a normal row carrying a chevron.
    func testSubmenuRowHasChevron() {
        let menu = UIMenu(children: [action("Copy"),
                                     UIMenu(title: "More", children: [action("Alpha")])])
        let l = UIMenuLayout.layout(menu)
        XCTAssertEqual(l.size.height, 104, accuracy: 0.01)
        XCTAssertEqual(l.rows.map(\.showsChevron), [false, true])
    }

    /// menuprobe `long`: a title too wide for the 194 pt column WRAPS (the
    /// platter never widens) and its row grows by the measured 22 pt pitch.
    func testLongTitleWrapsInsteadOfWideningThePlatter() {
        let menu = UIMenu(children: [
            action("A considerably longer menu item title"), action("Short"),
        ])
        let l = UIMenuLayout.layout(menu)
        XCTAssertEqual(l.size.width, 250)
        XCTAssertGreaterThan(l.rows[0].titleLines.count, 1)
        XCTAssertEqual(l.rows[0].frame.height,
                       20 + 1.0 / 3.0 + 22 * CGFloat(l.rows[0].titleLines.count - 1)
                           + 21 + 2.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(l.rows[1].frame.height, 42, accuracy: 0.01)
    }

    /// A hidden element contributes no row (UIKit's `.hidden` attribute).
    func testHiddenElementsAreDropped() {
        let menu = UIMenu(children: [action("Copy"),
                                     action("Secret", attributes: .hidden)])
        XCTAssertEqual(UIMenuLayout.layout(menu).rows.count, 1)
    }

    /// A synchronous deferred provider behaves like UIKit's (the async case
    /// is documented as unsupported).
    func testDeferredElementResolvesSynchronousProviders() {
        let deferred = UIDeferredMenuElement { completion in
            completion([UIAction(title: "Late") { _ in }])
        }
        let l = UIMenuLayout.layout(UIMenu(children: [deferred]))
        XCTAssertEqual(l.rows.count, 1)
        XCTAssertEqual(l.rows[0].element.title, "Late")
    }
}

// MARK: - Pixels (against the measured device framebuffer)

@MainActor
final class MenuRenderTests: XCTestCase {

    private var savedBackend: RenderBackend = CanvasBackendSelection.current
    override func setUp() {
        super.setUp()
        savedBackend = CanvasBackendSelection.current
    }
    override func tearDown() {
        CanvasBackendSelection.current = savedBackend
        super.tearDown()
    }

    private func px(_ b: Bitmap, _ x: Int, _ y: Int) -> Int {
        Int(b.pixels[(y * b.width + x) * 4])
    }

    /// Render a three-item menu anchored at (40, 120) over a base colour, at
    /// scale 1 — the same configuration menuprobe photographed.
    private func renderMenu(base: UIColor, dark: Bool = false) -> Bitmap {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 400))
        window.overrideUserInterfaceStyle = dark ? .dark : .light
        let backdrop = UIView(frame: window.bounds)
        backdrop.backgroundColor = base
        window.addSubview(backdrop)
        let source = UIView(frame: CGRect(x: 40, y: 120, width: 100, height: 44))
        window.addSubview(source)
        let menu = UIMenu(children: [
            UIAction(title: "Copy") { _ in },
            UIAction(title: "Duplicate") { _ in },
            UIAction(title: "Delete", attributes: .destructive) { _ in },
        ])
        _UIMenuPresentation.present(menu, from: source)
        window.layoutIfNeeded()
        defer { _UIMenuPresentation.active?.dismiss() }
        return UIRenderer.render(window, scale: 1)
    }

    /// MEASURED (framebuffer, light): the platter's interior reads 250 over a
    /// white base, 215 over 0.5 grey, 196 over 0.25 grey and 176 over black —
    /// the flat-colour fit in UIMenuMetrics. Tolerance 2 counts, the fit's own
    /// residual (max 1.1) plus rounding.
    func testPlatterFillOverKnownBasesMatchesTheFramebuffer() {
        CanvasBackendSelection.current = .swift
        for (base, expected) in [(UIColor(white: 1, alpha: 1), 250),
                                 (UIColor(white: 128.0 / 255, alpha: 1), 215),
                                 (UIColor(white: 64.0 / 255, alpha: 1), 196),
                                 (UIColor(white: 0, alpha: 1), 176)] {
            let bmp = renderMenu(base: base)
            // A point inside the platter but between two rows (no glyphs).
            let v = px(bmp, 40 + 230, 120 + 55)
            XCTAssertEqual(v, expected, accuracy: 2,
                           "platter fill over base \(base)")
        }
    }

    /// MEASURED (framebuffer, dark over black): 18. The dark fit's worst
    /// residual is here — 3.7 counts at a black base, because the dark blur
    /// is the less linear of the two (the fit and its residuals are quoted
    /// in UIMenuMetrics.platterFill). Tolerance is that residual plus
    /// rounding, and the fit is NOT bent to make this point exact.
    func testPlatterFillDark() {
        CanvasBackendSelection.current = .swift
        let bmp = renderMenu(base: UIColor(white: 0, alpha: 1), dark: true)
        XCTAssertEqual(px(bmp, 40 + 230, 120 + 55), 18, accuracy: 5)
    }

    /// MEASURED (framebuffer over white, 1 device pixel outside the platter
    /// at 3×): 243 beside, 247 above, 239 below — a symmetric blur pushed
    /// down. At scale 1 the same points are one POINT out; the tolerance is
    /// the wider one the resampling deserves.
    func testShadowProfileMatchesTheFramebuffer() {
        CanvasBackendSelection.current = .swift
        let bmp = renderMenu(base: UIColor(white: 1, alpha: 1))
        let l = UIMenuLayout.layout(UIMenu(children: [
            UIAction(title: "Copy") { _ in }, UIAction(title: "Duplicate") { _ in },
            UIAction(title: "Delete") { _ in },
        ]))
        let left = 40, top = 120
        let right = left + Int(l.size.width), bottom = top + Int(l.size.height)
        let side = px(bmp, left - 1, top + Int(l.size.height) / 2)
        let above = px(bmp, left + Int(l.size.width) / 2, top - 1)
        let below = px(bmp, left + Int(l.size.width) / 2, bottom + 1)
        XCTAssertEqual(side, 243, accuracy: 4, "shadow beside the platter")
        XCTAssertEqual(above, 247, accuracy: 4, "shadow above the platter")
        XCTAssertEqual(below, 239, accuracy: 4, "shadow below the platter")
        XCTAssertLessThan(above, 253, "there IS a shadow above")
        XCTAssertLessThan(below, above, "the shadow is pushed DOWN")
        // Far away it is gone (measured: 255 by ~40 pt out).
        XCTAssertEqual(px(bmp, right + 60, top + 40), 255, accuracy: 1)
    }

    /// The corner is round: a point just inside the platter's bounding-box
    /// corner is still the BASE colour, and the platter's own interior is
    /// reached only past the measured 32.5 pt radius.
    func testCornersAreRounded() {
        CanvasBackendSelection.current = .swift
        let bmp = renderMenu(base: UIColor(white: 1, alpha: 1))
        XCTAssertEqual(px(bmp, 41, 121), 255, accuracy: 3, "corner is cut away")
        XCTAssertEqual(px(bmp, 40 + 40, 120 + 40), 250, accuracy: 2, "inside the platter")
    }
}
