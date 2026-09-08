@_spi(OpenUIKitHost) import WidgetKit
import Foundation

private struct _HostAction {}

private struct _ControlIntent: ControlConfigurationIntent {}

private struct _BoolValueProvider: ControlValueProvider {
    var previewValue: Bool { true }
    func currentValue() async throws -> Bool {
        throw NSError(domain: "WidgetKit", code: 1)
    }
}

private struct _IntentValueProvider: AppIntentControlValueProvider {
    func previewValue(configuration: _ControlIntent) -> Int { 7 }
    func currentValue(configuration: _ControlIntent) async throws -> Int {
        throw NSError(domain: "WidgetKit", code: 1)
    }
}

private struct _PushHandler: ControlPushHandler {
    init() {}
    func pushTokensDidChange(controls: [ControlInfo]) {
        _ = controls
    }
}

private final class _ControlValueResult<Value>: @unchecked Sendable {
    var value: Value?
    var error: NSError?
}

private func _waitForControlValue(
    timeout: TimeInterval = 2,
    _ operation: @escaping @Sendable () async -> Void
) {
    let finished = _ControlValueResult<Bool>()
    Task.detached {
        await operation()
        finished.value = true
    }
    let deadline = Date().addingTimeInterval(timeout)
    while finished.value == nil, Date() < deadline {
        Thread.sleep(forTimeInterval: 0.001)
    }
    precondition(finished.value == true, "control value operation timed out")
}

func testWidgetPreviewContextStoresFamily() {
    let preview = WidgetPreviewContext(family: .systemLarge)
    precondition(preview.family == .systemLarge)
    precondition(WidgetPreviewContext(family: .accessoryInline).family == .accessoryInline)
}

func testControlInfoHashable() {
    let first = ControlInfo(kind: "toggle", pushInfo: ControlPushInfo(token: Data([1])))
    let second = ControlInfo(kind: "toggle", pushInfo: ControlPushInfo(token: Data([1])))
    let third = ControlInfo(kind: "button")
    precondition(first == second)
    precondition(first != third)
    precondition(first.hashValue == second.hashValue)
    precondition(first.kind == "toggle")
    precondition(first.pushInfo?.token.count == 1)
    precondition(first.id == "toggle")
    precondition(first.configurationIntent(of: String.self) == nil)
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = hasher.finalize()
}

func testControlPushInfoToken() {
    let info = ControlPushInfo(token: Data([9, 8, 7]))
    precondition(info.token == Data([9, 8, 7]))
    precondition(ControlPushInfo().token.isEmpty)
}

func testControlWidgetButtonStoresTitle() {
    let titled = ControlWidgetButton(
        "Lights",
        action: _HostAction(),
        actionLabel: { _ in Text("busy") }
    )
    precondition(ControlWidgetPortable.template(of: titled).role == "button")
    precondition(ControlWidgetPortable.template(of: titled).title == "Lights")

    let keyed = ControlWidgetButton(
        LocalizedStringKey("key-title"),
        action: _HostAction(),
        actionLabel: { _ in Text("busy") }
    )
    precondition(ControlWidgetPortable.template(of: keyed).title == "key-title")

    let resourced = ControlWidgetButton(
        LocalizedStringResource("resource-title"),
        action: _HostAction(),
        actionLabel: { _ in Text("busy") }
    )
    precondition(ControlWidgetPortable.template(of: resourced).title == "resource-title")

    let labeled = ControlWidgetButton(action: _HostAction(), label: { Text("label-only") })
    precondition(ControlWidgetPortable.template(of: labeled).title == "label-only")

    let full = ControlWidgetButton(
        action: _HostAction(),
        label: { Text("full") },
        actionLabel: { _ in Text("busy") }
    )
    precondition(ControlWidgetPortable.template(of: full).title == "full")
    _ = ControlWidgetButtonDefaultActionLabel().body
}

func testControlWidgetToggleStoresIsOn() {
    let titled = ControlWidgetToggle(
        "Focus",
        isOn: true,
        action: _HostAction(),
        valueLabel: { on in Text(on ? "on" : "off") }
    )
    let descriptor = ControlWidgetPortable.template(of: titled)
    precondition(descriptor.role == "toggle")
    precondition(descriptor.title == "Focus")
    precondition(descriptor.isOn == true)

    let keyed = ControlWidgetToggle(
        LocalizedStringKey("toggle-key"),
        isOn: false,
        action: _HostAction(),
        valueLabel: { _ in Text("v") }
    )
    precondition(ControlWidgetPortable.template(of: keyed).title == "toggle-key")
    precondition(ControlWidgetPortable.template(of: keyed).isOn == false)

    let resourced = ControlWidgetToggle(
        LocalizedStringResource("toggle-resource"),
        isOn: true,
        action: _HostAction(),
        valueLabel: { _ in Text("v") }
    )
    precondition(ControlWidgetPortable.template(of: resourced).title == "toggle-resource")

    let labeled = ControlWidgetToggle(
        isOn: false,
        action: _HostAction(),
        label: { Text("label-toggle") }
    )
    precondition(ControlWidgetPortable.template(of: labeled).title == "label-toggle")

    let full = ControlWidgetToggle(
        isOn: true,
        action: _HostAction(),
        label: { Text("full-toggle") },
        valueLabel: { _ in Text("v") }
    )
    precondition(ControlWidgetPortable.template(of: full).isOn == true)
    _ = ControlWidgetToggleDefaultLabel().body
}

func testControlValueProviderPreview() {
    let provider = _BoolValueProvider()
    precondition(ControlValueHost.preview(provider) == true)
    precondition(provider.previewValue == true)
}

func testAppIntentControlValueProviderPreview() {
    let provider = _IntentValueProvider()
    precondition(ControlValueHost.preview(provider, configuration: _ControlIntent()) == 7)
}

func testControlValueProviderCurrentValueFailure() {
    let result = _ControlValueResult<Bool>()
    _waitForControlValue {
        do {
            result.value = try await _BoolValueProvider().currentValue()
        } catch {
            result.error = error as NSError
        }
    }
    precondition(result.value == nil)
    precondition(result.error?.domain == "WidgetKit")
    precondition(result.error?.code == 1)
}

func testAppIntentControlValueProviderCurrentValueFailure() {
    let result = _ControlValueResult<Int>()
    _waitForControlValue {
        do {
            result.value = try await _IntentValueProvider().currentValue(
                configuration: _ControlIntent()
            )
        } catch {
            result.error = error as NSError
        }
    }
    precondition(result.value == nil)
    precondition(result.error?.domain == "WidgetKit")
    precondition(result.error?.code == 1)
}

func testStaticControlConfigurationKind() {
    let plain = StaticControlConfiguration(kind: "plain.control") {
        ControlWidgetButton("Go", action: _HostAction(), actionLabel: { _ in Text("busy") })
    }
    precondition(ControlWidgetPortable.descriptor(of: plain).kind == "plain.control")

    let provided = StaticControlConfiguration(
        kind: "preview.control",
        provider: _BoolValueProvider()
    ) { value in
        ControlWidgetToggle(
            "Flag",
            isOn: value,
            action: _HostAction(),
            valueLabel: { _ in Text("v") }
        )
    }
    precondition(ControlWidgetPortable.descriptor(of: provided).kind == "preview.control")
    precondition(ControlWidgetPortable.descriptor(of: provided).previewValueDescription == "true")
}

func testAppIntentControlConfigurationKind() {
    let plain = AppIntentControlConfiguration(
        kind: "app.control",
        intent: _ControlIntent.self
    ) { _ in
        ControlWidgetButton("Go", action: _HostAction(), actionLabel: { _ in Text("busy") })
    }
    precondition(ControlWidgetPortable.descriptor(of: plain).kind == "app.control")

    let provided = AppIntentControlConfiguration(
        kind: "app.preview",
        provider: _IntentValueProvider()
    ) { value in
        ControlWidgetToggle(
            "Count",
            isOn: value > 0,
            action: _HostAction(),
            valueLabel: { _ in Text("v") }
        )
    }
    precondition(ControlWidgetPortable.descriptor(of: provided).kind == "app.preview")
}

func testControlWidgetMain() {
    struct ProbeControl: ControlWidget {
        var body: some ControlWidgetConfiguration {
            StaticControlConfiguration(kind: "probe.control") {
                ControlWidgetButton("Go", action: _HostAction(), actionLabel: { _ in Text("busy") })
            }
        }
    }
    ProbeControl.main()
    _ = ProbeControl().body
}

func testControlWidgetConfigurationMetadata() {
    let configured = StaticControlConfiguration(kind: "meta.control") {
        ControlWidgetButton("Go", action: _HostAction(), actionLabel: { _ in Text("busy") })
    }
    .displayName(LocalizedStringResource("Display"))
    .description(LocalizedStringResource("Describe"))
    .promptsForUserConfiguration()
    .pushHandler(_PushHandler.self)
    let descriptor = ControlWidgetPortable.descriptor(of: configured)
    precondition(descriptor.kind == "meta.control")
    precondition(descriptor.displayName == "Display")
    precondition(descriptor.description == "Describe")
    precondition(descriptor.promptsForUserConfiguration)

    let app = AppIntentControlConfiguration(
        kind: "meta.app",
        intent: _ControlIntent.self
    ) { _ in
        ControlWidgetToggle("T", isOn: false, action: _HostAction(), valueLabel: { _ in Text("v") })
    }
    .displayName(LocalizedStringResource("AppDisplay"))
    .description(LocalizedStringResource("AppDescribe"))
    .promptsForUserConfiguration()
    .pushHandler(_PushHandler.self)
    let appDescriptor = ControlWidgetPortable.descriptor(of: app)
    precondition(appDescriptor.displayName == "AppDisplay")
    precondition(appDescriptor.promptsForUserConfiguration)
}

func testControlWidgetTemplateModifiers() {
    let button = ControlWidgetButton(
        "Go",
        action: _HostAction(),
        actionLabel: { _ in Text("busy") }
    )
    .privacySensitive(true)
    .disabled(true)
    .tint(.blue)
    let descriptor = ControlWidgetPortable.template(of: button)
    precondition(descriptor.privacySensitive)
    precondition(descriptor.disabled)
    precondition(descriptor.tinted)

    let toggle = ControlWidgetToggle(
        "T",
        isOn: true,
        action: _HostAction(),
        valueLabel: { _ in Text("v") }
    )
    .privacySensitive(false)
    .disabled(false)
    .tint(nil)
    let toggleDescriptor = ControlWidgetPortable.template(of: toggle)
    precondition(!toggleDescriptor.privacySensitive)
    precondition(!toggleDescriptor.disabled)
    precondition(!toggleDescriptor.tinted)
}

func testWidgetHostRegistryInstallsConfigurations() {
    WidgetHostRegistry.shared.reset()
    let descriptor = WidgetConfigurationDescriptor(
        kind: "account",
        displayName: "Account",
        supportedFamilies: [.systemSmall, .systemMedium],
        promptsForUserConfiguration: true
    )
    WidgetHostRegistry.shared.install(descriptor)
    precondition(WidgetHostRegistry.shared.descriptor(ofKind: "account")?.displayName == "Account")
    let configs = WidgetCenter.shared.portableCurrentConfigurations()
    precondition(configs.map(\.kind) == ["account", "account"])
    precondition(configs.map(\.family) == [.systemSmall, .systemMedium])
    WidgetHostRegistry.shared.reset()
    precondition(WidgetCenter.shared.portableCurrentConfigurations().isEmpty)
}

func testWidgetTimelineReloadPolicies() {
    struct Entry: TimelineEntry {
        var date: Date
    }
    let last = Date(timeIntervalSinceReferenceDate: 20)
    let atEnd = Timeline(
        entries: [
            Entry(date: Date(timeIntervalSinceReferenceDate: 10)),
            Entry(date: last),
        ],
        policy: .atEnd
    )
    let never = Timeline(entries: [Entry(date: last)], policy: .never)
    let afterDate = Date(timeIntervalSinceReferenceDate: 40)
    let after = Timeline(entries: [Entry(date: last)], policy: .after(afterDate))
    do {
        let atEndEval = try WidgetTimelineValidation.evaluate(atEnd)
        let neverEval = try WidgetTimelineValidation.evaluate(never)
        let afterEval = try WidgetTimelineValidation.evaluate(after)
        precondition(atEndEval.nextReload == last)
        precondition(neverEval.nextReload == nil)
        precondition(afterEval.nextReload == afterDate)
    } catch {
        preconditionFailure("reload policy timelines must validate")
    }
}

func testControlPushHandlerType() {
    let handler = _PushHandler()
    handler.pushTokensDidChange(controls: [
        ControlInfo(kind: "x", pushInfo: ControlPushInfo(token: Data())),
    ])
}
