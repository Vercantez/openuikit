#if canImport(Foundation)
import Foundation
import XCTest
@testable import OpenUIKit

/// UIKit's `UIImage(named:)` resolves in the MAIN BUNDLE. With no
/// host-configured search paths, the port used to search nothing, so every
/// app-catalog lookup failed (NetNewsWire Assets.swift:43 traps on it).
@MainActor
final class NamedImageMainBundleTests: XCTestCase {
    func testNamedSearchesTheMainBundleUnlessTheHostConfiguredRoots() {
        let saved = OpenUIKitRuntime.imageSearchPaths
        defer { OpenUIKitRuntime.imageSearchPaths = saved; UIImage.clearNamedCache() }

        OpenUIKitRuntime.imageSearchPaths = []
        XCTAssertEqual(UIImage._namedSearchPaths, [Bundle.main.resourcePath!])

        OpenUIKitRuntime.imageSearchPaths = ["/host/root"]
        XCTAssertEqual(UIImage._namedSearchPaths, ["/host/root"])
    }
}
#endif
