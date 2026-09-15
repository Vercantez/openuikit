import WidgetKit
import Foundation

private struct _ControlBodyProbeAction {}

private struct _ControlBodyProbeIntent: ControlConfigurationIntent {}

/// The four Control Center template/configuration types publish
/// `Body == Never` because Linux has no Control Center presentation host;
/// their `body` getters stay deliberately fatal (fail-closed) and therefore
/// stay `declared` rather than `implemented`. The `Body` aliases themselves
/// are safely testable type identity and are pinned here.
func testControlWidgetBodyAliasesAreNever() {
    typealias Button = ControlWidgetButton<
        Text, ControlWidgetButtonDefaultActionLabel, _ControlBodyProbeAction
    >
    typealias Toggle = ControlWidgetToggle<
        Text, ControlWidgetToggleDefaultLabel, _ControlBodyProbeAction
    >
    typealias StaticConfig = StaticControlConfiguration<Button>
    typealias IntentConfig = AppIntentControlConfiguration<_ControlBodyProbeIntent, Button>
    precondition(Button.Body.self == Never.self)
    precondition(Toggle.Body.self == Never.self)
    precondition(StaticConfig.Body.self == Never.self)
    precondition(IntentConfig.Body.self == Never.self)
}

/// `NSUserActivityTypeLiveActivity` payload pinned by an Apple oracle probe
/// (Xcode 26.1 `import WidgetKit` program, macOS + iOS SDK builds).
func testNSUserActivityTypeLiveActivityPayload() {
    precondition(NSUserActivityTypeLiveActivity == "NSUserActivityTypeLiveActivity")
    precondition(NSUserActivityTypeLiveActivity.count == 30)
}
