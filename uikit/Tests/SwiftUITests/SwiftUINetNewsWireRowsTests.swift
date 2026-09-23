// SwiftUI rows NetNewsWire's iOS target needs (Settings, About, Activity and
// Error logs, Dinosaurs, CloudKit and account stats). Expected values are
// MEASURED on iPhone 16 / iOS 26.1: uikit/Tools/oracle2/nnwswiftuiprobe/
// transcript-ios26.1.txt.

import XCTest
#if os(Linux)
@preconcurrency @testable import OpenUIKit
#else
@testable import OpenUIKit
#endif
#if os(Linux)
@preconcurrency @testable import SwiftUI
#else
@testable import SwiftUI
#endif

private struct SheetItem: Identifiable {
    let id: Int
}

private struct SheetItemFixture: View {
    let item: Binding<SheetItem?>
    var body: some View {
        Text(verbatim: "Root")
            .sheet(item: item) { value in
                Text(verbatim: "Item \(value.id)")
            }
    }
}

private struct TitledFixture: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Color.red.frame(height: 10).scenePadding(.horizontal)
                LabeledContent {
                    Text(verbatim: "Value")
                } label: {
                    Text("Label", comment: "LabeledContent label")
                }
                Section {
                    Text(verbatim: "Row")
                } header: {
                    Text(verbatim: "Header")
                } footer: {
                    Text(verbatim: "Footer")
                }
            }
            .navigationTitle(Text(verbatim: "Title"))
            .navigationSubtitle(Text(verbatim: "Subtitle"))
        }
    }
}

private final class ChangeCounter {
    var count = 0
}

private struct Feedish: Identifiable {
    let id: String
    let name: String
}

private struct PickerListFixture: View {
    let threshold: Int
    let selection: Binding<Int>
    let counter: ChangeCounter
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: selection) {
                ForEach([3, 6, 12, 24], id: \.self) { month in
                    Text("\(month) months", comment: "threshold").tag(month)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: threshold) {
                counter.count += 1
            }
            List([Feedish(id: "b", name: "Beta"), Feedish(id: "a", name: "Alpha")], id: \.id) { feed in
                Text(verbatim: feed.name)
            }
        }
    }
}

@MainActor
final class SwiftUINetNewsWireRowsTests: XCTestCase {
    private var savedCut = OpenUIKitRuntime.systemFontCut

    override func setUp() {
        super.setUp()
        // The measurements are iOS 26.1 values: resolve on the iOS cut.
        savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
    }

    override func tearDown() {
        OpenUIKitRuntime.systemFontCut = savedCut
        super.tearDown()
    }

    private func rgba255(_ color: UIColor, _ style: UIUserInterfaceStyle) -> [Int] {
        let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a].map { Int(($0 * 255).rounded()) }
    }

    func testNamedColorsAreTheMeasuredSystemColors() {
        // (name, Color, light RGBA, dark RGBA) from UIColor(Color) on iOS 26.1.
        let rows: [(String, Color, [Int], [Int])] = [
            ("red", .red, [255, 56, 60, 255], [255, 66, 69, 255]),
            ("orange", .orange, [255, 141, 40, 255], [255, 146, 48, 255]),
            ("yellow", .yellow, [255, 204, 0, 255], [255, 214, 0, 255]),
            ("green", .green, [52, 199, 89, 255], [48, 209, 88, 255]),
            ("mint", .mint, [0, 200, 179, 255], [0, 218, 195, 255]),
            ("teal", .teal, [0, 195, 208, 255], [0, 210, 224, 255]),
            ("cyan", .cyan, [0, 192, 232, 255], [60, 211, 254, 255]),
            ("blue", .blue, [0, 136, 255, 255], [0, 145, 255, 255]),
            ("indigo", .indigo, [97, 85, 245, 255], [109, 124, 255, 255]),
            ("purple", .purple, [203, 48, 224, 255], [219, 52, 242, 255]),
            ("pink", .pink, [255, 45, 85, 255], [255, 55, 95, 255]),
            ("brown", .brown, [172, 127, 94, 255], [183, 138, 102, 255]),
            ("gray", .gray, [142, 142, 147, 255], [142, 142, 147, 255]),
        ]
        for (name, color, light, dark) in rows {
            XCTAssertEqual(rgba255(UIColor(color), .light), light, "Color.\(name) light")
            XCTAssertEqual(rgba255(UIColor(color), .dark), dark, "Color.\(name) dark")
        }
    }

    func testColorStaticsAreNonisolatedValues() {
        // NetNewsWire AccountType+Helpers.swift returns `.orange` from a
        // nonisolated computed property typed Color.
        func logColor() -> Color { .orange }
        XCTAssertEqual(logColor(), Color.orange)
    }

    func testLinkAndAnyShapeStyleResolve() {
        XCTAssertEqual(rgba255(LinkShapeStyle.link._openResolvedForegroundColor().resolve(), .light),
                       [0, 122, 255, 255])
        XCTAssertEqual(rgba255(LinkShapeStyle.link._openResolvedForegroundColor().resolve(), .dark),
                       [9, 132, 255, 255])
        let secondary = AnyShapeStyle(.secondary)._openResolvedForegroundColor().resolve()
        XCTAssertEqual(rgba255(secondary, .light), [60, 60, 67, 153])
        XCTAssertEqual(rgba255(AnyShapeStyle(Color.orange)._openResolvedForegroundColor().resolve(), .light),
                       [255, 141, 40, 255])
    }

    func testSystemTextStyleWithDesignAndWeight() {
        let mono = Font.system(.body, design: .monospaced).weight(.medium).resolve(weight: nil)
        XCTAssertEqual(mono.pointSize, 17)
        XCTAssertEqual(mono.weight, .medium)
        XCTAssertEqual(mono.design, .monospaced)
        XCTAssertEqual(Font.system(.body), Font.body)
        XCTAssertEqual(Font.system(.headline, design: .monospaced).resolve(weight: nil).weight, .semibold)
    }

    func testTextWithCommentShowsTheKey() {
        XCTAssertEqual(Text("Open Settings", comment: "Open Settings button").content, "Open Settings")
        let months = 3
        XCTAssertEqual(Text("\(months) months", comment: "threshold").content, "3 months")
    }

    func testRoleValuesAndCloseButtonGlyph() {
        XCTAssertNotEqual(ButtonRole.close, ButtonRole.cancel)
        XCTAssertNotEqual(VerticalAlignment.firstTextBaseline, .center)
        XCTAssertNotEqual(VerticalAlignment.lastTextBaseline, .firstTextBaseline)
        XCTAssertTrue(EnabledTextSelectability.allowsSelection)
        XCTAssertFalse(DisabledTextSelectability.allowsSelection)
        let close = Button(role: .close) {}
        XCTAssertEqual(close.role, .close)
        guard case .system(let name) = close.label.source else {
            return XCTFail("close button label is not a system symbol")
        }
        XCTAssertEqual(name, "xmark")
    }

    func testNavigationSubtitleScenePaddingLabeledContentAndSectionBuilders() throws {
        let controller = UIHostingController(rootView: TitledFixture())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        let navigation = try XCTUnwrap(
            controller.children.compactMap { $0 as? UINavigationController }.first
        )
        let top = try XCTUnwrap(navigation.topViewController)
        XCTAssertEqual(top.title, "Title")
        XCTAssertEqual(top.navigationItem.subtitle, "Subtitle")

        top.view.layoutIfNeeded()
        let views = descendants(top.view)
        let red = try XCTUnwrap(views.first { $0.backgroundColor == UIColor.systemRed })
        let redFrame = red.convert(red.bounds, to: nil)
        XCTAssertEqual(redFrame.minX, 16, accuracy: 0.01)
        XCTAssertEqual(redFrame.width, 361, accuracy: 0.01)

        let labels = views.compactMap { $0 as? UILabel }
        let label = try XCTUnwrap(labels.first { $0.text == "Label" })
        let value = try XCTUnwrap(labels.first { $0.text == "Value" })
        XCTAssertEqual(value.textColor, UIColor.secondaryLabel)
        XCTAssertGreaterThan(value.convert(value.bounds, to: nil).minX,
                             label.convert(label.bounds, to: nil).maxX)
        for text in ["Header", "Row", "Footer"] {
            XCTAssertTrue(labels.contains { $0.text == text }, text)
        }
    }

    func testSheetItemPresentsWhileItemIsSet() throws {
        var item: SheetItem?
        let binding = Binding<SheetItem?>(get: { item }, set: { item = $0 })
        let controller = UIHostingController(rootView: SheetItemFixture(item: binding))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()
        XCTAssertNil(controller.presentedViewController)

        item = SheetItem(id: 7)
        controller.rootView = SheetItemFixture(item: binding)
        controller.view.layoutIfNeeded()
        let presented = try XCTUnwrap(controller.presentedViewController)
        presented.view.layoutIfNeeded()
        XCTAssertTrue(descendants(presented.view).contains { ($0 as? UILabel)?.text == "Item 7" })

        item = nil
        controller.rootView = SheetItemFixture(item: binding)
        controller.view.layoutIfNeeded()
        window.tick(timestamp: 10)
        XCTAssertNil(controller.presentedViewController)
    }

    func testSegmentedPickerListDataAndZeroArgumentOnChange() throws {
        var selected = 6
        let binding = Binding<Int>(get: { selected }, set: { selected = $0 })
        let counter = ChangeCounter()
        let controller = UIHostingController(
            rootView: PickerListFixture(threshold: 3, selection: binding, counter: counter))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        let segmented = try XCTUnwrap(descendants(controller.view).compactMap { $0 as? UISegmentedControl }.first)
        XCTAssertEqual(segmented.numberOfSegments, 4)
        XCTAssertEqual((0..<4).map { segmented.titleForSegment(at: $0) },
                       ["3 months", "6 months", "12 months", "24 months"])
        XCTAssertEqual(segmented.selectedSegmentIndex, 1)
        XCTAssertEqual(segmented.frame.width, 393, accuracy: 0.01)
        XCTAssertEqual(segmented.frame.height, 31, accuracy: 0.01)
        segmented.selectedSegmentIndex = 3
        segmented.sendActions(for: .valueChanged)
        XCTAssertEqual(selected, 24)

        let texts = descendants(controller.view).compactMap { ($0 as? UILabel)?.text }
        let beta = try XCTUnwrap(texts.firstIndex(of: "Beta"))
        let alpha = try XCTUnwrap(texts.firstIndex(of: "Alpha"))
        XCTAssertLessThan(beta, alpha, "rows keep the data order")

        XCTAssertEqual(counter.count, 0)
        controller.rootView = PickerListFixture(threshold: 6, selection: binding, counter: counter)
        controller.view.layoutIfNeeded()
        window.tick(timestamp: 1)
        XCTAssertEqual(counter.count, 1)
    }

    private func descendants(_ root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }
}
