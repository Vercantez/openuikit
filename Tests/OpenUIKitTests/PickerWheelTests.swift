// UIPickerView wheel tests. Owner: controls module (controls2).
//
// These replay REAL UIKit's own numbers. Every expectation below was read
// off a Mac Catalyst iOS 26.1 picker through the offscreen oracle — the
// private `UIPickerTableViewTitledCell` frames, `rowSize(forComponent:)`,
// the band views' heights and the selection indicator's frame — and is
// reproduced from the law documented in Sources/OpenUIKit/UIPickerView.swift.
//
// This is the picker's ONLY oracle coverage, on purpose: an offscreen
// capture of a real UIPickerView is a translucent wash rather than a picture
// of the control (the reasons are spelled out in UIPickerView.swift's
// header), so there is no golden scene. The table below covers |d| up to 4
// over thirteen picker configurations to 5e-4 pt, which is tighter than a
// pixel golden of this control could be.

import XCTest
@testable import OpenUIKit

private typealias CGFloat = OpenUIKit.CGFloat
private typealias CGPoint = OpenUIKit.CGPoint
private typealias CGSize = OpenUIKit.CGSize
private typealias CGRect = OpenUIKit.CGRect

/// The tests only need a class to hold the delegate; OpenUIKit has no
/// NSObject and the protocols are `AnyObject`-bound.
@MainActor
private class NSObjectStandIn {}

@MainActor
private final class Source: NSObjectStandIn, UIPickerViewDataSource, UIPickerViewDelegate {
    var components = 1
    var rows = 9
    var rowH: CGFloat = 32
    func numberOfComponents(in pickerView: UIPickerView) -> Int { components }
    func pickerView(_ p: UIPickerView, numberOfRowsInComponent component: Int) -> Int { rows }
    func pickerView(_ p: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? { "R\(row)" }
    func pickerView(_ p: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { rowH }
}

@MainActor
final class PickerWheelTests: XCTestCase {

    private func makePicker(height: CGFloat, rowHeight: CGFloat,
                            rows: Int = 21, selected: Int = 10)
        -> (UIPickerView, Source) {
        let src = Source()
        src.rows = rows
        src.rowH = rowHeight
        let pv = UIPickerView(frame: CGRect(x: 0, y: 0, width: 320, height: height))
        pv.dataSource = src
        pv.delegate = src
        pv.reloadAllComponents()
        pv.selectRow(selected, inComponent: 0, animated: false)
        pv.layoutIfNeeded()
        return (pv, src)
    }

    /// N (rows per revolution) and R (wheel radius) at every probed picker
    /// height and row height. `tableHeight` is `H + 75` in all thirteen.
    func testMeasuredWheelParameters() {
        // (pickerHeight, rowHeight, tableHeight, N, R)
        let cases: [(CGFloat, CGFloat, CGFloat, Int, CGFloat)] = [
            (120, 32, 195, 13, 65.17395),
            (150, 32, 225, 15, 75.20071),
            (180, 32, 255, 16, 85.22748),
            (216, 32, 291, 19, 97.25958),
            (250, 32, 325, 21, 108.62325),
            (300, 32, 375, 24, 125.33452),
            (400, 32, 475, 30, 158.75706),
            (500, 32, 575, 36, 192.17959),
            (216, 20, 291, 30, 97.25959),
            (216, 26, 291, 23, 97.25959),
            (216, 44, 291, 14, 97.25959),
            (216, 60, 291, 10, 97.25958),
        ]
        for (h, rowH, tableH, n, r) in cases {
            let w = UIPickerView.Wheel(pickerHeight: h, rowHeight: rowH)
            XCTAssertEqual(w.tableHeight, tableH, "H=\(h)")
            XCTAssertEqual(w.rowsPerRevolution, n, "H=\(h) rowH=\(rowH)")
            XCTAssertEqual(w.radius, r, accuracy: 1e-4, "H=\(h) rowH=\(rowH)")
        }
    }

    /// Real UIKit's own cell frames for the reference configuration
    /// (320x216, 32 pt rows, 9 rows, row 4 selected), converted to picker
    /// coordinates: the selected cell sits at y 92 with height 32 and the
    /// rest follow the wheel.
    func testMeasuredCellFramesReferenceConfiguration() {
        // (offset from the selected row, cell top, cell height)
        let expected: [(Int, CGFloat, CGFloat)] = [
            (-4, 9.788761923584701, 7.855535588505575),
            (-3, 17.826363649004733, 17.50234105991767),
            (-2, 35.635679900665565, 25.252496300684598),
            (-1, 61.28678902654953, 30.266151734420305),
            (0, 92.0, 32.0),
            (1, 124.44705923903015, 30.266151734420305),
            (2, 155.11182379864982, 25.252496300684584),
            (3, 180.6712952910776, 17.502341059917654),
            (4, 198.35570248790972, 7.855535588505575),
        ]
        let wheel = UIPickerView.Wheel(pickerHeight: 216, rowHeight: 32)
        XCTAssertEqual(wheel.maxVisibleOffset, 4)
        for (d, top, height) in expected {
            guard let r = wheel.rowRect(offset: d, x: 9, width: 302) else {
                return XCTFail("row \(d) should be visible")
            }
            XCTAssertEqual(r.minY, top, accuracy: 5e-4, "row \(d) top")
            XCTAssertEqual(r.height, height, accuracy: 5e-4, "row \(d) height")
        }
        XCTAssertNil(wheel.rowRect(offset: 5, x: 9, width: 302),
                     "row 5 is past the wheel's edge (5*beta > 90 degrees)")
    }

    /// The same for a 44 pt row height, where the wheel gets coarser
    /// (N = 14) and only |d| <= 3 survives.
    func testMeasuredCellFramesTallRows() {
        let expected: [(Int, CGFloat, CGFloat)] = [
            (-3, 8.283455572641287, 9.79092109407783),
            (-2, 18.242616280102567, 27.433551281784275),
            (-1, 45.97933050662755, 39.64263018770643),
            (0, 86.0, 44.0),
            (1, 130.378039305666, 39.64263018770646),
            (2, 170.3238324381132, 27.433551281784275),
            (3, 197.9256233332809, 9.790921094077817),
        ]
        let wheel = UIPickerView.Wheel(pickerHeight: 216, rowHeight: 44)
        for (d, top, height) in expected {
            guard let r = wheel.rowRect(offset: d, x: 9, width: 302) else {
                return XCTFail("row \(d) should be visible")
            }
            XCTAssertEqual(r.minY, top, accuracy: 5e-4, "row \(d) top")
            XCTAssertEqual(r.height, height, accuracy: 5e-4, "row \(d) height")
        }
    }

    /// Measured band heights (rowHeight + 2) and tops, at every probed row
    /// height for a 216 pt picker.
    func testMeasuredSelectionBand() {
        let cases: [(CGFloat, CGFloat, CGFloat)] = [
            (20, 97, 22), (26, 94, 28), (32, 91, 34), (44, 85, 46), (60, 77, 62),
        ]
        for (rowH, top, height) in cases {
            let (pv, src) = makePicker(height: 216, rowHeight: rowH)
            defer { withExtendedLifetime(src) {} }   // delegate is weak
            let band = pv.selectionBandRect()
            XCTAssertEqual(band.minY, top, "rowH=\(rowH)")
            XCTAssertEqual(band.height, height, "rowH=\(rowH)")
            XCTAssertEqual(band.minX, 9, "rowH=\(rowH)")
            XCTAssertEqual(band.width, 302, "rowH=\(rowH)")
        }
    }

    /// `rowSize(forComponent:)` at 320 pt wide, 1…5 components — measured.
    func testMeasuredComponentWidths() {
        let widths: [CGFloat] = [302, 148, 97, 71, 56]
        for (i, expected) in widths.enumerated() {
            let src = Source()
            src.components = i + 1
            let pv = UIPickerView(frame: CGRect(x: 0, y: 0, width: 320, height: 216))
            pv.dataSource = src
            pv.delegate = src
            pv.reloadAllComponents()
            pv.layoutIfNeeded()
            XCTAssertEqual(pv.rowSize(forComponent: 0),
                           CGSize(width: expected, height: 32),
                           "\(i + 1) components")
        }
    }

    func testSizeThatFitsAndIntrinsic() {
        let (pv, src) = makePicker(height: 216, rowHeight: 32)
        defer { withExtendedLifetime(src) {} }   // delegate is weak
        XCTAssertEqual(pv.sizeThatFits(CGSize(width: 320, height: 0)),
                       CGSize(width: 320, height: 216))
        XCTAssertEqual(pv.intrinsicContentSize, CGSize(width: 320, height: 216))
    }

    func testSelectionRoundTripAndDelegateCallback() {
        @MainActor
        final class Recorder: NSObjectStandIn, UIPickerViewDataSource, UIPickerViewDelegate {
            var picked: [(Int, Int)] = []
            func numberOfComponents(in pickerView: UIPickerView) -> Int { 2 }
            func pickerView(_ p: UIPickerView, numberOfRowsInComponent c: Int) -> Int { 5 }
            func pickerView(_ p: UIPickerView, titleForRow row: Int,
                            forComponent component: Int) -> String? { "R\(row)" }
            func pickerView(_ p: UIPickerView, didSelectRow row: Int, inComponent c: Int) {
                picked.append((row, c))
            }
        }
        let rec = Recorder()
        let pv = UIPickerView(frame: CGRect(x: 0, y: 0, width: 320, height: 216))
        pv.dataSource = rec
        pv.delegate = rec
        pv.reloadAllComponents()
        XCTAssertEqual(pv.numberOfComponents, 2)
        XCTAssertEqual(pv.numberOfRows(inComponent: 1), 5)
        pv.selectRow(3, inComponent: 1, animated: false)
        XCTAssertEqual(pv.selectedRow(inComponent: 1), 3)
        XCTAssertEqual(rec.picked.count, 1)
        XCTAssertEqual(rec.picked[0].0, 3)
        XCTAssertEqual(rec.picked[0].1, 1)
        // Out of range clamps, exactly like UIKit.
        pv.selectRow(99, inComponent: 1, animated: false)
        XCTAssertEqual(pv.selectedRow(inComponent: 1), 4)
    }

    /// The selected row is centred and the visible rows straddle it, in the
    /// laid-out view (not just in the Wheel arithmetic).
    func testLaidOutRowsMatchTheWheel() {
        let (pv, src) = makePicker(height: 216, rowHeight: 32, rows: 21, selected: 10)
        defer { withExtendedLifetime(src) {} }   // delegate is weak
        let labels = pv.subviews.compactMap { $0 as? UILabel }.filter { !$0.isHidden }
        XCTAssertEqual(labels.count, 9, "|d| <= 4 for N = 19")
        guard let selected = labels.first(where: { $0.text == "R10" }) else {
            return XCTFail("selected row missing")
        }
        // Title inset 9 pt inside a 302 pt component that starts at x = 9.
        XCTAssertEqual(selected.frame.minX, 18)
        XCTAssertEqual(selected.frame.width, 284)
        XCTAssertEqual(selected.frame.midY, 108, accuracy: 1e-6)
        XCTAssertEqual(selected.font.pointSize, 23.5)
        XCTAssertEqual(selected.alpha, 1)
        guard let neighbour = labels.first(where: { $0.text == "R11" }) else {
            return XCTFail("neighbour row missing")
        }
        XCTAssertEqual(neighbour.font.pointSize, 21)
        XCTAssertEqual(neighbour.alpha, 0.447)
        XCTAssertEqual(neighbour.frame.height, 30.266151734420305, accuracy: 5e-4)
    }
}
