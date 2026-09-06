import XCTest
import Glean

final class GleanTests: XCTestCase {
    func testInitializeAndCustomURL() {
        // Focus AppDelegate.swift:361 initialize; NavigationPath.swift:102 handleCustomUrl.
        let glean = Glean.shared
        glean.initialize(
            uploadEnabled: true,
            configuration: Configuration(channel: "release"),
            buildInfo: GleanMetrics.GleanBuild.info
        )
        XCTAssertTrue(glean.initialized)
        XCTAssertEqual(glean.configuration?.channel, "release")
        let url = URL(string: "focus-glean-settings://glean?logPings=true")!
        glean.handleCustomUrl(url: url)
        XCTAssertEqual(glean.lastCustomURL, url)
        glean.setUploadEnabled(false)
        XCTAssertFalse(glean.uploadEnabled)
    }

    func testFocusMetricShapes() {
        GleanMetrics.SettingsScreen.setAsDefaultBrowserPressed.add()
        XCTAssertEqual(GleanMetrics.SettingsScreen.setAsDefaultBrowserPressed.testGetValue(), 1)
        GleanMetrics.Search.defaultEngine.set("Google")
        XCTAssertEqual(GleanMetrics.Search.defaultEngine.testGetValue(), "Google")
        GleanMetrics.Shortcuts.shortcutsOnHomeNumber.set(4)
        XCTAssertEqual(GleanMetrics.Shortcuts.shortcutsOnHomeNumber.testGetValue(), 4)
        GleanMetrics.BrowserSearch.inContent["google.in-content.sap.none"].add()
        XCTAssertEqual(GleanMetrics.BrowserSearch.inContent["google.in-content.sap.none"].testGetValue(), 1)
        GleanMetrics.ShowSearchSuggestions.changedFromSettings.record(.init(isEnabled: true))
        XCTAssertEqual(GleanMetrics.ShowSearchSuggestions.changedFromSettings.testGetCount(), 1)
        GleanMetrics.Webview.fail.record()
        XCTAssertEqual(GleanMetrics.Webview.fail.testGetCount(), 1)
        GleanMetrics.TrackingProtection.trackerSettingChanged.record(
            .init(isEnabled: false, sourceOfChange: "panel", trackerChanged: "ads")
        )
        XCTAssertEqual(GleanMetrics.TrackingProtection.trackerSettingChanged.testGetCount(), 1)
    }
}
