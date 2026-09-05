import XCTest

/// Linux 6.2.4 swift-corelibs-xctest discovers methods as
/// `(T) -> () throws -> Void`. The SwiftUI test tree is `@MainActor` and
/// that cast traps at process start (Linux trial 2026-09-05). Package.swift
/// therefore compiles only this stub into SwiftUITests on Linux; Darwin still
/// runs the full suite.
final class SwiftUILinuxStubTests: XCTestCase {
    func testSwiftUISuiteIsHostedOnDarwinXCTest() {
        XCTAssertTrue(true)
    }
}
