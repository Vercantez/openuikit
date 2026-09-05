// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// The API combination in this fixture is derived from Mozilla Focus's exact
// BlockzillaPackage/Sources/Licenses target at pinned revision
// a2832521c1daa0c23419c73705ae043ed60c9791. No Focus source is copied here;
// the companion proof script compiles the byte-exact upstream sources.

import XCTest
#if os(Linux)
@preconcurrency @testable import SwiftUI
#else
@testable import SwiftUI
#endif
#if os(Linux)
@preconcurrency import OpenUIKit
#else
import OpenUIKit
#endif

private struct LicensesFixture: View {
    let libraries: [String]

    var body: some View {
        List {
            ForEach(libraries, id: \.self) { library in
                NavigationLink {
                    ScrollView {
                        Text("body-\(library)")
                            .padding()
                    }
                    .navigationBarTitle(library)
                } label: {
                    Text(library)
                }
            }
        }
        .navigationBarTitle("Open source licenses")
    }
}

private struct NavigationMetadataOwnershipFixture: View {
    let suppliesMetadata: Bool

    @ViewBuilder var body: some View {
        if suppliesMetadata {
            Text("owned")
                .navigationBarTitle("SwiftUI owner")
                .navigationBarBackButtonHidden(true)
        } else {
            Text("plain")
        }
    }
}

#if !os(Linux)
@MainActor
#endif
final class SwiftUILicensesTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OpenUIKitRuntime.animationTime = 0
    }

    override func tearDown() {
        OpenUIKitRuntime.animationTime = 0
        super.tearDown()
    }

    func testListPreservesRowsAndOwnsScrollableContentGeometry() throws {
        let controller = UIHostingController(
            rootView: LicensesFixture(
                libraries: ["Alpha", "Beta", "Gamma", "Delta", "Epsilon"]
            )
        )
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 240, height: 132)
        host.layoutIfNeeded()

        let list = try XCTUnwrap(
            descendant(host, identifier: "SwiftUI.List") as? UIScrollView
        )
        let links = descendants(list).compactMap { $0 as? UIControl }.filter {
            $0.accessibilityIdentifier == "SwiftUI.NavigationLink"
        }
        let labels = descendants(list).compactMap { $0 as? UILabel }.filter {
            $0.accessibilityIdentifier == "SwiftUI.Text"
        }

        XCTAssertEqual(list.frame, host.bounds)
        XCTAssertEqual(list.contentSize, CGSize(width: 240, height: 220))
        XCTAssertEqual(links.map(\.frame.origin.y), [0, 44, 88, 132, 176])
        XCTAssertEqual(links.map(\.frame.height), [44, 44, 44, 44, 44])
        XCTAssertEqual(labels.map(\.text), ["Alpha", "Beta", "Gamma", "Delta", "Epsilon"])
        XCTAssertEqual(labels.map(\.frame.origin.x), [16, 16, 16, 16, 16])
        XCTAssertEqual(
            descendants(list).filter {
                $0.accessibilityIdentifier == "SwiftUI.NavigationLink.disclosure"
            }.count,
            5
        )
    }

    func testRootNavigationBarTitleConfiguresHostingController() throws {
        let controller = UIHostingController(
            rootView: LicensesFixture(libraries: ["Alpha"])
        )
        _ = try XCTUnwrap(controller.view)

        XCTAssertEqual(controller.title, "Open source licenses")
        XCTAssertEqual(controller.navigationItem.title, "Open source licenses")
    }

    func testRootWithoutNavigationMetadataPreservesUIKitOwnedTitle() throws {
        let controller = UIHostingController(rootView: Text("plain"))
        controller.title = "UIKit owner"
        controller.navigationItem.hidesBackButton = true
        let host = try XCTUnwrap(controller.view)
        host.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        host.layoutIfNeeded()

        XCTAssertEqual(controller.title, "UIKit owner")
        XCTAssertTrue(controller.navigationItem.hidesBackButton)
    }

    func testNavigationMetadataClearsOnlyValuesStillOwnedBySwiftUI() throws {
        let controller = UIHostingController(
            rootView: NavigationMetadataOwnershipFixture(suppliesMetadata: true)
        )
        _ = try XCTUnwrap(controller.view)

        XCTAssertEqual(controller.title, "SwiftUI owner")
        XCTAssertTrue(controller.navigationItem.hidesBackButton)

        controller.rootView = NavigationMetadataOwnershipFixture(suppliesMetadata: false)
        XCTAssertNil(controller.title)
        XCTAssertFalse(controller.navigationItem.hidesBackButton)

        controller.rootView = NavigationMetadataOwnershipFixture(suppliesMetadata: true)
        controller.title = "UIKit replacement"
        controller.navigationItem.hidesBackButton = false
        controller.rootView = NavigationMetadataOwnershipFixture(suppliesMetadata: false)

        XCTAssertEqual(controller.title, "UIKit replacement")
        XCTAssertFalse(controller.navigationItem.hidesBackButton)
    }

    func testNavigationLinkPushesFreshTitledScrollableDestinationViaRealTouch() throws {
        let hostController = UIHostingController(
            rootView: LicensesFixture(libraries: ["Alpha", "Beta"])
        )
        let navigation = UINavigationController(rootViewController: hostController)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 240, height: 220))
        window.rootViewController = navigation
        window.layoutIfNeeded()
        navigation.view.layoutIfNeeded()
        hostController.view.layoutIfNeeded()

        let link = try XCTUnwrap(
            descendant(hostController.view, identifier: "SwiftUI.NavigationLink")
                as? UIControl
        )
        let point = link.convert(
            CGPoint(x: link.bounds.midX, y: link.bounds.midY),
            to: window
        )
        XCTAssertTrue(window.hitTest(point, with: nil) === link)
        window.sendTouch(.began, at: point, timestamp: 0)
        window.sendTouch(.ended, at: point, timestamp: 0.05)
        window.tick(timestamp: 1)

        XCTAssertEqual(navigation.viewControllers.count, 2)
        let destination = try XCTUnwrap(navigation.topViewController)
        XCTAssertFalse(destination === hostController)
        XCTAssertEqual(destination.title, "Alpha")
        XCTAssertEqual(destination.navigationItem.title, "Alpha")

        let destinationView = try XCTUnwrap(destination.view)
        destinationView.layoutIfNeeded()
        let scroll = try XCTUnwrap(
            descendant(destinationView, identifier: "SwiftUI.ScrollView") as? UIScrollView
        )
        let body = try XCTUnwrap(
            descendants(scroll).compactMap { $0 as? UILabel }.first
        )
        XCTAssertEqual(body.text, "body-Alpha")
    }

    private func descendant(_ root: UIView, identifier: String) -> UIView? {
        descendants(root).first { $0.accessibilityIdentifier == identifier }
    }

    private func descendants(_ root: UIView) -> [UIView] {
        root.subviews.flatMap { [$0] + descendants($0) }
    }
}
