import XCTest
import Sentry

final class SentryTests: XCTestCase {
    func testStartConfigureOptionsIsFailClosed() {
        // Focus AppDelegate.swift:333 SentrySDK.start { options in options.dsn = … }
        var seen: String?
        SentrySDK.start { options in
            options.dsn = "https://example.invalid/1"
            seen = options.dsn
        }
        XCTAssertEqual(seen, "https://example.invalid/1")
        XCTAssertFalse(SentrySDK.isEnabled)
    }

    func testCaptureAndConfigureScopeDoNotThrow() {
        // Focus InternalCrashReportingSettingsView.swift:12–21.
        XCTAssertEqual(SentrySDK.capture(message: "Test"), SentryId.empty)
        XCTAssertEqual(
            SentrySDK.capture(error: NSError(domain: "TestDomain", code: 42)),
            SentryId.empty
        )
        XCTAssertEqual(
            SentrySDK.capture(exception: NSException(name: .genericException, reason: "Test", userInfo: nil)),
            SentryId.empty
        )
        var scoped = false
        SentrySDK.configureScope { scope in
            scope.setTag(value: "v", key: "k")
            scoped = true
        }
        XCTAssertTrue(scoped)
        SentrySDK.crash()
    }
}
