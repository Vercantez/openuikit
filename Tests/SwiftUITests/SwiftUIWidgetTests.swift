// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// WidgetFixture's composition is derived from Mozilla Focus's
// BlockzillaPackage/Sources/Widget/SearchWidgetView.swift at pinned revision
// a2832521c1daa0c23419c73705ae043ed60c9791.

import XCTest
@testable import SwiftUI
import OpenUIKit

private extension Gradient {
    static let widgetFixture = Gradient(colors: [.red, .blue])
}

private extension Image {
    static let fixtureSearch = Image(systemName: "magnifyingglass")
}

/// The Focus widget's production composition, with inline colors so the
/// renderer test does not confuse asset lookup with SwiftUI composition.
private struct WidgetFixture: View {
    let title: String
    let padding: Bool
    let background: Bool
    let imageBundle: Bundle?

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.white)

                Spacer()

                Image.fixtureSearch
                    .foregroundColor(.white)
                    .frame(height: 18)
            }
            Spacer()
            HStack {
                Spacer()
                Image("small-tick", bundle: imageBundle)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .frame(height: 22)
            }
        }
        .padding(.all, padding ? 10 : 0)
        .background(
            background ? LinearGradient(
                gradient: .widgetFixture,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ) : nil
        )
    }
}

@MainActor
final class SwiftUIWidgetTests: XCTestCase {
    private var savedResourceRoot = ""
    private var savedImagePaths: [String] = []
    private var savedBackend: RenderBackend = .swift
    private var savedCompositor: RenderCompositor = .renderPass
    private var fixtureImageBundle: Bundle?

    override func setUp() {
        super.setUp()
        savedResourceRoot = OpenUIKitRuntime.resourceRoot
        savedImagePaths = OpenUIKitRuntime.imageSearchPaths
        savedBackend = OpenUIKitRuntime.renderBackend
        savedCompositor = OpenUIKitRuntime.compositor

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        OpenUIKitRuntime.resourceRoot = root
            .appendingPathComponent("Sources/OpenUIKit/Resources").path
        OpenUIKitRuntime.imageSearchPaths = [
            root.appendingPathComponent("fixtures/realapp/assets").path
        ]
        fixtureImageBundle = Bundle(
            path: root.appendingPathComponent("fixtures/realapp/assets").path
        )
        OpenUIKitRuntime.renderBackend = .swift
        OpenUIKitRuntime.compositor = .renderPass
        UIImage.clearNamedCache()
    }

    override func tearDown() {
        OpenUIKitRuntime.resourceRoot = savedResourceRoot
        OpenUIKitRuntime.imageSearchPaths = savedImagePaths
        OpenUIKitRuntime.renderBackend = savedBackend
        OpenUIKitRuntime.compositor = savedCompositor
        UIImage.clearNamedCache()
        fixtureImageBundle = nil
        super.tearDown()
    }

    func testHostingControllerBuildsDeterministicOpenUIKitHierarchyAndLayout() throws {
        let controller = UIHostingController(
            rootView: WidgetFixture(
                title: "Search in Focus",
                padding: true,
                background: true,
                imageBundle: fixtureImageBundle
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 135, height: 135)
        host.layoutIfNeeded()

        let gradient = try XCTUnwrap(
            host.subviews.first { $0.accessibilityIdentifier == "SwiftUI.LinearGradient" }
                as? UIGradientView
        )
        let label = try XCTUnwrap(
            host.subviews.first { $0.accessibilityIdentifier == "SwiftUI.Text" } as? UILabel
        )
        let search = try XCTUnwrap(
            host.subviews.first {
                $0.accessibilityIdentifier == "SwiftUI.Image.systemName.magnifyingglass"
            }
        )
        let logo = try XCTUnwrap(
            host.subviews.first { $0.accessibilityIdentifier == "SwiftUI.Image.named.small-tick" }
                as? UIImageView
        )

        XCTAssertEqual(gradient.frame, CGRect(x: 0, y: 0, width: 135, height: 135))
        XCTAssertEqual(gradient.startPoint, CGPoint(x: 0, y: 0))
        XCTAssertEqual(gradient.endPoint, CGPoint(x: 1, y: 1))
        XCTAssertEqual(label.text, "Search in Focus")
        XCTAssertEqual(label.font.weight, .medium)
        XCTAssertEqual(label.minimumScaleFactor, 0.8)
        XCTAssertTrue(label.adjustsFontSizeToFitWidth)
        XCTAssertEqual(label.textColor, .white)
        XCTAssertGreaterThanOrEqual(label.frame.minX, 10)
        XCTAssertGreaterThanOrEqual(label.frame.minY, 10)
        XCTAssertEqual(search.frame.height, 18, accuracy: 0.001)
        XCTAssertGreaterThan(search.frame.width, 0)
        XCTAssertLessThanOrEqual(search.frame.maxX, 125.001)
        XCTAssertEqual(logo.frame.height, 22, accuracy: 0.001)
        XCTAssertLessThanOrEqual(logo.frame.maxX, 125.001)
        XCTAssertLessThanOrEqual(logo.frame.maxY, 125.001)
        XCTAssertNotNil(logo.image, "OpenUIKit loose-image lookup must feed named SwiftUI Image")
    }

    func testHierarchyRendersByteIdenticallyAcrossRepeatedPasses() throws {
        let controller = UIHostingController(
            rootView: WidgetFixture(
                title: "Search",
                padding: true,
                background: true,
                imageBundle: fixtureImageBundle
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 135, height: 135)
        host.layoutIfNeeded()

        let first = UIRenderer.render(host, scale: 1)
        let second = UIRenderer.render(host, scale: 1)
        XCTAssertEqual(first.width, 135)
        XCTAssertEqual(first.height, 135)
        XCTAssertEqual(first.pixels, second.pixels)

        let visibleChannels = stride(from: 3, to: first.pixels.count, by: 4)
            .filter { first.pixels[$0] > 0 }
            .count
        XCTAssertGreaterThan(visibleChannels, 15_000, "gradient should cover the widget surface")
    }

    func testRootViewMutationRebuildsAndOptionalBackgroundCanDisappear() throws {
        let controller = UIHostingController(
            rootView: WidgetFixture(
                title: "First",
                padding: true,
                background: true,
                imageBundle: fixtureImageBundle
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 135, height: 135)
        host.layoutIfNeeded()
        XCTAssertTrue(host.subviews.contains {
            $0.accessibilityIdentifier == "SwiftUI.LinearGradient"
        })

        controller.rootView = WidgetFixture(
            title: "Second",
            padding: false,
            background: false,
            imageBundle: fixtureImageBundle
        )
        host.layoutIfNeeded()
        XCTAssertFalse(host.subviews.contains {
            $0.accessibilityIdentifier == "SwiftUI.LinearGradient"
        })
        let label = try XCTUnwrap(host.subviews.first {
            $0.accessibilityIdentifier == "SwiftUI.Text"
        } as? UILabel)
        XCTAssertEqual(label.text, "Second")
        XCTAssertEqual(label.frame.minX, 0, accuracy: 0.001)
    }

    func testPreviewFrameAndRoundedClipSyntaxAffectHost() throws {
        let content = WidgetFixture(
            title: "Search",
            padding: true,
            background: true,
            imageBundle: fixtureImageBundle
        )
            .previewLayout(.sizeThatFits)
            .frame(width: 135, height: 135)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        let controller = UIHostingController(rootView: content)
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 135, height: 135)
        host.layoutIfNeeded()

        XCTAssertTrue(host.clipsToBounds)
        XCTAssertEqual(host.layer.cornerRadius, 20)
    }
}
