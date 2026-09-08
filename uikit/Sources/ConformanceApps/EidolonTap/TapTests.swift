import Foundation
import XCTest
import UIKit
import RxSwift
import RxCocoa
import AppKit

final class EidolonRxCocoaTests: XCTestCase {
    @MainActor
    func testPinnedIOSOracle() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("fixtures/realapp/eidolon/tap-oracle.json"))
        let golden = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let expected = try XCTUnwrap(golden["rows"] as? [[String: Any]])
        let actual = eidolonTapScenarios()
        XCTAssertEqual(actual.count, expected.count)
        for (ours, ios) in zip(actual, expected) {
            XCTAssertEqual(NSDictionary(dictionary: ours), NSDictionary(dictionary: ios),
                           "Oracle case: \(ios["case"] ?? "unknown")")
        }
    }

    // Adding the UIKit overload must leave RxCocoa's existing AppKit overload
    // usable. No NSApplication or window is needed for this compile proof.
    @MainActor
    private func appKitTapStillTypechecks(_ button: NSButton) -> ControlEvent<Void> {
        button.rx.tap
    }
}
