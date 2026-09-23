import Foundation
import WidgetKit
import XCTest

/// NetNewsWire Shared/Widget/WidgetDataEncoder.swift:102-120. MEASURED
/// iPhone 16 / iOS 26.1 for an app with no widget extension:
/// Tools/oracle2/widgetcenterprobe/transcript-ios26.1.txt.
final class WidgetCenterTests: XCTestCase {
    func testNoWidgetsInstalledContract() async throws {
        XCTAssertTrue(WidgetCenter.shared === WidgetCenter.shared)
        WidgetCenter.shared.reloadTimelines(ofKind: "com.ranchero.NetNewsWire.UnreadWidget")
        WidgetCenter.shared.reloadAllTimelines()
        let delivered = expectation(description: "configurations")
        nonisolated(unsafe) var count = -1
        nonisolated(unsafe) var onMain = true
        WidgetCenter.shared.getCurrentConfigurations { result in
            if case .success(let infos) = result { count = infos.count }
            onMain = Thread.isMainThread
            delivered.fulfill()
        }
        await fulfillment(of: [delivered], timeout: 2)
        XCTAssertEqual(count, 0)
        XCTAssertFalse(onMain)
        let infos = try await WidgetCenter.shared.currentConfigurations()
        XCTAssertEqual(infos.count, 0)
    }
}
