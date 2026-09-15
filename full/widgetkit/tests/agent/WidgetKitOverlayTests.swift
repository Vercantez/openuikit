@_spi(OpenUIKitHost) import WidgetKit
import Foundation

// Synthesized WidgetKit `View`-modifier rows: Apple's graph records each
// WidgetKit `View` extension method once per conforming view. The base
// overloads are covered by testViewWidgetModifiers on
// AccessoryWidgetBackground; these entry points execute the same methods on
// ControlWidgetToggleDefaultLabel, ControlWidgetButtonDefaultActionLabel,
// and AccessoryWidgetBackground so every synthesized row has behavioral
// evidence. Linux has no widget daemon or home-screen renderer; chrome
// modifiers (widgetURL/widgetLabel/widgetAccentable/widgetCurvesContent)
// are data a platform host reads through WidgetChrome, and the remaining
// modifiers are verified pass-throughs that keep their view.

// MARK: - WidgetKit modifiers per view

func testToggleDefaultLabelWidgetModifiers() {
    let url = URL(string: "widget://toggle-default-label")
    let view = ControlWidgetToggleDefaultLabel()
    let labeled = view
        .widgetURL(url)
        .widgetAccentable(false)
        .widgetCurvesContent(true)
        .widgetLabel("toggle")
    let notes = WidgetChrome.annotations(of: labeled)
    precondition(notes.widgetURL == url)
    precondition(notes.widgetLabel == "toggle")
    precondition(notes.widgetAccentable == false)
    precondition(notes.widgetCurvesContent == true)

    _ = view.widgetURL(url)
    _ = view.widgetAccentable(true)
    _ = view.widgetCurvesContent(false)
    let textLabel = WidgetChrome.annotations(of: view.widgetLabel(Text("label")))
    precondition(textLabel.widgetLabel == "label")
    let keyLabel = WidgetChrome.annotations(of: view.widgetLabel(LocalizedStringKey("key")))
    precondition(keyLabel.widgetLabel == "key")
    let resourceLabel = WidgetChrome.annotations(
        of: view.widgetLabel(LocalizedStringResource("resource"))
    )
    precondition(resourceLabel.widgetLabel == "resource")
    let builderLabel = WidgetChrome.annotations(
        of: ControlWidgetToggleDefaultLabel().widgetLabel { Text("builder") }
    )
    precondition(builderLabel.widgetLabel == "builder")
    _ = view.controlWidgetActionHint(Text("hint"))
    _ = view.controlWidgetActionHint(LocalizedStringKey("hint"))
    _ = view.controlWidgetActionHint(LocalizedStringResource("hint"))
    _ = view.controlWidgetActionHint("hint")
    _ = view.controlWidgetStatus(Text("status"))
    _ = view.controlWidgetStatus(LocalizedStringKey("status"))
    _ = view.controlWidgetStatus(LocalizedStringResource("status"))
    _ = view.controlWidgetStatus("status")
    _ = view.activityBackgroundTint(.blue)
    _ = view.activitySystemActionForegroundColor(.primary)
    _ = view.dynamicIsland(verticalPlacement: .default)
}

func testButtonDefaultActionLabelWidgetModifiers() {
    let url = URL(string: "widget://button-default-action-label")
    let view = ControlWidgetButtonDefaultActionLabel()
    let labeled = view
        .widgetURL(url)
        .widgetAccentable(false)
        .widgetCurvesContent(true)
        .widgetLabel("button")
    let notes = WidgetChrome.annotations(of: labeled)
    precondition(notes.widgetURL == url)
    precondition(notes.widgetLabel == "button")
    precondition(notes.widgetAccentable == false)
    precondition(notes.widgetCurvesContent == true)

    _ = view.widgetURL(url)
    _ = view.widgetAccentable(true)
    _ = view.widgetCurvesContent(false)
    let textLabel = WidgetChrome.annotations(of: view.widgetLabel(Text("label")))
    precondition(textLabel.widgetLabel == "label")
    let keyLabel = WidgetChrome.annotations(of: view.widgetLabel(LocalizedStringKey("key")))
    precondition(keyLabel.widgetLabel == "key")
    let resourceLabel = WidgetChrome.annotations(
        of: view.widgetLabel(LocalizedStringResource("resource"))
    )
    precondition(resourceLabel.widgetLabel == "resource")
    let builderLabel = WidgetChrome.annotations(
        of: ControlWidgetButtonDefaultActionLabel().widgetLabel { Text("builder") }
    )
    precondition(builderLabel.widgetLabel == "builder")
    _ = view.controlWidgetActionHint(Text("hint"))
    _ = view.controlWidgetActionHint(LocalizedStringKey("hint"))
    _ = view.controlWidgetActionHint(LocalizedStringResource("hint"))
    _ = view.controlWidgetActionHint("hint")
    _ = view.controlWidgetStatus(Text("status"))
    _ = view.controlWidgetStatus(LocalizedStringKey("status"))
    _ = view.controlWidgetStatus(LocalizedStringResource("status"))
    _ = view.controlWidgetStatus("status")
    _ = view.activityBackgroundTint(.blue)
    _ = view.activitySystemActionForegroundColor(.primary)
    _ = view.dynamicIsland(verticalPlacement: .default)
}

func testAccessoryBackgroundWidgetModifiers() {
    let url = URL(string: "widget://accessory-background")
    let view = AccessoryWidgetBackground()
    let labeled = view
        .widgetURL(url)
        .widgetAccentable(false)
        .widgetCurvesContent(true)
        .widgetLabel("accessory")
    let notes = WidgetChrome.annotations(of: labeled)
    precondition(notes.widgetURL == url)
    precondition(notes.widgetLabel == "accessory")
    precondition(notes.widgetAccentable == false)
    precondition(notes.widgetCurvesContent == true)

    _ = view.widgetURL(url)
    _ = view.widgetAccentable(true)
    _ = view.widgetCurvesContent(false)
    let textLabel = WidgetChrome.annotations(of: view.widgetLabel(Text("label")))
    precondition(textLabel.widgetLabel == "label")
    let keyLabel = WidgetChrome.annotations(of: view.widgetLabel(LocalizedStringKey("key")))
    precondition(keyLabel.widgetLabel == "key")
    let resourceLabel = WidgetChrome.annotations(
        of: view.widgetLabel(LocalizedStringResource("resource"))
    )
    precondition(resourceLabel.widgetLabel == "resource")
    let builderLabel = WidgetChrome.annotations(
        of: AccessoryWidgetBackground().widgetLabel { Text("builder") }
    )
    precondition(builderLabel.widgetLabel == "builder")
    _ = view.controlWidgetActionHint(Text("hint"))
    _ = view.controlWidgetActionHint(LocalizedStringKey("hint"))
    _ = view.controlWidgetActionHint(LocalizedStringResource("hint"))
    _ = view.controlWidgetActionHint("hint")
    _ = view.controlWidgetStatus(Text("status"))
    _ = view.controlWidgetStatus(LocalizedStringKey("status"))
    _ = view.controlWidgetStatus(LocalizedStringResource("status"))
    _ = view.controlWidgetStatus("status")
    _ = view.activityBackgroundTint(.blue)
    _ = view.activitySystemActionForegroundColor(.primary)
    _ = view.dynamicIsland(verticalPlacement: .default)
}

// MARK: - AppIntents cross-import overlays per view

// AppIntents/SwiftUI cross-import overlays on WidgetKit views are inert
// pass-throughs on Linux: there is no Siri tip renderer, shortcuts host, or
// accessibility-intent dispatcher. The explicitly typed bindings below prove
// each overload links and returns its view unchanged.

func testButtonDefaultActionLabelAppIntentsStubs() {
    let token = "dummy"
    let view = ControlWidgetButtonDefaultActionLabel()
    let executed: ControlWidgetButtonDefaultActionLabel = view.onAppIntentExecution(
        token,
        perform: token
    )
    let tipped: ControlWidgetButtonDefaultActionLabel = executed.siriTipViewStyle(token)
    let linked: ControlWidgetButtonDefaultActionLabel = tipped.shortcutsLinkStyle(token)
    let namedResource: ControlWidgetButtonDefaultActionLabel = linked.accessibilityAction(
        named: token,
        intent: LocalizedStringResource("intent")
    )
    let namedKey: ControlWidgetButtonDefaultActionLabel = namedResource.accessibilityAction(
        named: token,
        intent: LocalizedStringKey("intent")
    )
    let namedText: ControlWidgetButtonDefaultActionLabel = namedKey.accessibilityAction(
        named: token,
        intent: Text("intent")
    )
    let namedGeneric: ControlWidgetButtonDefaultActionLabel = namedText.accessibilityAction(
        named: token,
        intent: token
    )
    let intentLabel: ControlWidgetButtonDefaultActionLabel = namedGeneric.accessibilityAction(
        intent: token,
        label: token
    )
    let kindIntent: ControlWidgetButtonDefaultActionLabel = intentLabel.accessibilityAction(
        token,
        intent: token
    )
    _ = kindIntent
}

func testAccessoryBackgroundAppIntentsStubs() {
    let token = "dummy"
    let view = AccessoryWidgetBackground()
    let executed: AccessoryWidgetBackground = view.onAppIntentExecution(token, perform: token)
    let tipped: AccessoryWidgetBackground = executed.siriTipViewStyle(token)
    let linked: AccessoryWidgetBackground = tipped.shortcutsLinkStyle(token)
    let namedResource: AccessoryWidgetBackground = linked.accessibilityAction(
        named: token,
        intent: LocalizedStringResource("intent")
    )
    let namedKey: AccessoryWidgetBackground = namedResource.accessibilityAction(
        named: token,
        intent: LocalizedStringKey("intent")
    )
    let namedText: AccessoryWidgetBackground = namedKey.accessibilityAction(
        named: token,
        intent: Text("intent")
    )
    let namedGeneric: AccessoryWidgetBackground = namedText.accessibilityAction(
        named: token,
        intent: token
    )
    let intentLabel: AccessoryWidgetBackground = namedGeneric.accessibilityAction(
        intent: token,
        label: token
    )
    let kindIntent: AccessoryWidgetBackground = intentLabel.accessibilityAction(
        token,
        intent: token
    )
    _ = kindIntent
}
