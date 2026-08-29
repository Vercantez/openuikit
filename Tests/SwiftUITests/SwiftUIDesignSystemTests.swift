// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// The API combinations in these fixtures are derived from Mozilla Focus's
// seven BlockzillaPackage/Sources/DesignSystem Swift files at pinned revision
// a2832521c1daa0c23419c73705ae043ed60c9791.  No Focus source is copied here;
// scripts/prove_focus_designsystem_swiftui.sh is the byte-exact source gate.

import XCTest
@testable import SwiftUI
import OpenUIKit

private enum DesignSystemRow: String, CaseIterable {
    case first
    case second
    case third

    var color: UIColor {
        switch self {
        case .first: return .red
        case .second: return .green
        case .third: return .blue
        }
    }
}

private struct DesignSystemRowsFixture: View {
    var body: some View {
        NavigationView {
            Form {
                ForEach(DesignSystemRow.allCases, id: \.self) { row in
                    HStack {
                        Text(row.rawValue)
                        Spacer()
                        Color(row.color)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .navigationTitle("Palette")
        }
    }
}

private struct UIKitImageFixture: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: 22, height: 22)
    }
}

private struct UIKitFontFixture: View {
    let font: UIFont

    var body: some View {
        Text("Bridged font")
            .font(Font(font as SwiftUI.CTFont))
    }
}

private struct RoundedOverlayFixture: View {
    var body: some View {
        HStack {
            Color(UIColor.red)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 2)
                )
        }
    }
}

@MainActor
final class SwiftUIDesignSystemTests: XCTestCase {
    private var savedResourceRoot = ""
    private var savedBackend: RenderBackend = .swift
    private var savedCompositor: RenderCompositor = .renderPass

    override func setUp() {
        super.setUp()
        savedResourceRoot = OpenUIKitRuntime.resourceRoot
        savedBackend = OpenUIKitRuntime.renderBackend
        savedCompositor = OpenUIKitRuntime.compositor

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        OpenUIKitRuntime.resourceRoot = root
            .appendingPathComponent("Sources/OpenUIKit/Resources").path
        OpenUIKitRuntime.renderBackend = .swift
        OpenUIKitRuntime.compositor = .renderPass
    }

    override func tearDown() {
        OpenUIKitRuntime.resourceRoot = savedResourceRoot
        OpenUIKitRuntime.renderBackend = savedBackend
        OpenUIKitRuntime.compositor = savedCompositor
        super.tearDown()
    }

    func testFormExpandsForEachInStableRowOrderUnderNavigationTitle() throws {
        let controller = UIHostingController(rootView: DesignSystemRowsFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 184)
        host.layoutIfNeeded()

        let navigation = try XCTUnwrap(descendant(host, identifier: "SwiftUI.NavigationView"))
        let title = try XCTUnwrap(
            descendant(navigation, identifier: "SwiftUI.NavigationTitle") as? UILabel
        )
        let form = try XCTUnwrap(descendant(navigation, identifier: "SwiftUI.Form"))
        let rows = descendants(form).filter {
            $0.accessibilityIdentifier?.hasPrefix("SwiftUI.Form.row.") == true
        }
        let labels = descendants(form).compactMap { $0 as? UILabel }.filter {
            $0.accessibilityIdentifier == "SwiftUI.Text"
        }

        XCTAssertEqual(title.text, "Palette")
        XCTAssertEqual(title.frame.height, 52, accuracy: 0.001)
        XCTAssertEqual(form.frame, CGRect(x: 0, y: 52, width: 240, height: 132))
        XCTAssertEqual(rows.map(\.frame.origin.y), [0, 44, 88])
        XCTAssertEqual(rows.map(\.frame.height), [44, 44, 44])
        XCTAssertEqual(labels.map(\.text), ["first", "second", "third"])

        let first = UIRenderer.render(host, scale: 1)
        let second = UIRenderer.render(host, scale: 1)
        XCTAssertEqual(first.pixels, second.pixels)
        XCTAssertEqual(alpha(first, x: 0, y: 0), 255)
    }

    func testUIKitImageInitializerPreservesPixelsAndResizableFrame() throws {
        let bitmap = Bitmap(width: 2, height: 2)
        bitmap.pixels = [
            255, 0, 0, 255, 0, 255, 0, 255,
            0, 0, 255, 255, 255, 255, 255, 255,
        ]
        let image = UIImage(bitmap: bitmap)
        let controller = UIHostingController(rootView: UIKitImageFixture(image: image))
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        host.layoutIfNeeded()

        let imageView = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.Image.uiImage") as? UIImageView
        )
        XCTAssertTrue(imageView.image === image)
        XCTAssertEqual(imageView.frame, CGRect(x: 11, y: 11, width: 22, height: 22))

        let first = UIRenderer.render(host, scale: 1)
        let second = UIRenderer.render(host, scale: 1)
        XCTAssertEqual(first.pixels, second.pixels)
        XCTAssertGreaterThan(alpha(first, x: 21, y: 21), 0)
    }

    func testCTFontBridgePreservesUIKitPointSizeWeightAndDesign() throws {
        let font = UIFont.systemFont(ofSize: 14, weight: .light)
        let controller = UIHostingController(rootView: UIKitFontFixture(font: font))
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 180, height: 44)
        host.layoutIfNeeded()

        let label = try XCTUnwrap(descendant(host, identifier: "SwiftUI.Text") as? UILabel)
        XCTAssertEqual(label.font.pointSize, 14, accuracy: 0.001)
        XCTAssertEqual(label.font.weight, .light)
        XCTAssertEqual(label.font.design, .default)

        let rendered = UIRenderer.render(host, scale: 1)
        let visiblePixels = stride(from: 3, to: rendered.pixels.count, by: 4)
            .filter { rendered.pixels[$0] > 0 }
            .count
        XCTAssertGreaterThan(visiblePixels, 20)
    }

    func testRoundedClipAndStrokeOverlayRenderDeterministically() throws {
        let controller = UIHostingController(rootView: RoundedOverlayFixture())
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        host.layoutIfNeeded()

        let clip = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.ClipRoundedRectangle")
        )
        let stroke = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.RoundedRectangle.stroke")
        )
        XCTAssertEqual(clip.frame.size, CGSize(width: 44, height: 44))
        XCTAssertEqual(clip.layer.cornerRadius, 12, accuracy: 0.001)
        XCTAssertEqual(stroke.frame.size, CGSize(width: 44, height: 44))
        XCTAssertEqual(stroke.layer.cornerRadius, 12, accuracy: 0.001)
        XCTAssertEqual(stroke.layer.borderWidth, 2, accuracy: 0.001)

        let first = UIRenderer.render(host, scale: 1)
        let second = UIRenderer.render(host, scale: 1)
        XCTAssertEqual(first.pixels, second.pixels)
        XCTAssertEqual(rgba(first, x: 22, y: 30), [255, 0, 0, 255])
        XCTAssertEqual(alpha(first, x: 59, y: 59), 0)
        XCTAssertGreaterThan(alpha(first, x: 1, y: 30), 0)
    }

    private func descendant(_ root: UIView, identifier: String) -> UIView? {
        descendants(root).first { $0.accessibilityIdentifier == identifier }
    }

    private func descendants(_ root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }

    private func alpha(_ bitmap: Bitmap, x: Int, y: Int) -> Int {
        Int(bitmap.pixels[(y * bitmap.width + x) * 4 + 3])
    }

    private func rgba(_ bitmap: Bitmap, x: Int, y: Int) -> [Int] {
        let offset = (y * bitmap.width + x) * 4
        return (0..<4).map { Int(bitmap.pixels[offset + $0]) }
    }
}
