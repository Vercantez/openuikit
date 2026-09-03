#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(AppIntents)
import AppIntents
#endif
import Foundation

// MARK: - Control Center (no Control Center daemon on Linux)

public struct ControlPushInfo: Hashable, Sendable {
    public var token: Data

    public init(token: Data = Data()) {
        self.token = token
    }
}

public struct ControlInfo: Hashable, Identifiable, @unchecked Sendable {
    public let kind: String
    public let pushInfo: ControlPushInfo?
    public var id: ControlInfo { self }

    public init(kind: String, pushInfo: ControlPushInfo? = nil) {
        self.kind = kind
        self.pushInfo = pushInfo
    }

    public func configurationIntent<Intent>(of intentType: Intent.Type) -> Intent? {
        _ = intentType
        return nil
    }
}

public protocol ControlPushHandler {
    init()
    func pushTokensDidChange(controls: [ControlInfo])
}

public final class ControlCenter: @unchecked Sendable {
    public static let shared = ControlCenter()

    private let lock = NSLock()
    private var controls: [ControlInfo] = []

    public init() {}

    public func reloadControls(ofKind kind: String) {
        _ = kind
    }

    public func reloadAllControls() {}

    public func currentControls() async -> [ControlInfo] {
        currentControlsSnapshot()
    }

    @_spi(OpenUIKitHost)
    public func installCurrentControls(_ controls: [ControlInfo]) {
        lock.lock()
        self.controls = controls
        lock.unlock()
    }

    private func currentControlsSnapshot() -> [ControlInfo] {
        lock.lock()
        let snapshot = controls
        lock.unlock()
        return snapshot
    }
}

@MainActor
public protocol ControlWidgetTemplate {
    associatedtype Body: ControlWidgetTemplate
    var body: Body { get }
}

extension Never: ControlWidgetTemplate {}

@MainActor
public protocol ControlWidgetConfiguration {
    associatedtype Body: ControlWidgetConfiguration
    var body: Body { get }
}

extension Never: ControlWidgetConfiguration {}

@MainActor
public protocol ControlWidget {
    associatedtype Body: ControlWidgetConfiguration
    var body: Body { get }
    static func main()
}

public extension ControlWidget {
    static func main() {}
}

public extension ControlWidgetTemplate {
    func privacySensitive(_ sensitive: Bool = true) -> some ControlWidgetTemplate {
        _ = sensitive
        return self
    }

    func tint(_ tint: Color?) -> some ControlWidgetTemplate {
        _ = tint
        return self
    }

    func disabled(_ disabled: Bool) -> some ControlWidgetTemplate {
        _ = disabled
        return self
    }
}

public extension ControlWidgetConfiguration {
    func promptsForUserConfiguration() -> some ControlWidgetConfiguration {
        self
    }

    func description(_ description: LocalizedStringResource) -> some ControlWidgetConfiguration {
        _ = description
        return self
    }

    func displayName(_ displayName: LocalizedStringResource) -> some ControlWidgetConfiguration {
        _ = displayName
        return self
    }

    func pushHandler(_ pushHandlerType: any ControlPushHandler.Type) -> some ControlWidgetConfiguration {
        _ = pushHandlerType
        return self
    }
}

@resultBuilder
@MainActor
public enum ControlWidgetTemplateBuilder {
    public static func buildBlock<Content: ControlWidgetTemplate>(_ content: Content) -> Content {
        content
    }

    public static func buildExpression<Content: ControlWidgetTemplate>(_ content: Content) -> Content {
        content
    }
}

public struct ControlWidgetButtonDefaultActionLabel: View {
    public init() {}
    public var body: some View { EmptyView() }
}

public struct ControlWidgetToggleDefaultLabel: View {
    public init() {}
    public var body: some View { EmptyView() }
}

@MainActor
public struct ControlWidgetButton<Label: View, ActionLabel: View, Action>: ControlWidgetTemplate {
    public typealias Body = Never
    public var body: Never {
        fatalError("Control widgets are host-driven")
    }

    public init(
        action: Action,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder actionLabel: @escaping (Bool) -> ActionLabel
    ) {
        _ = action
        _ = label
        _ = actionLabel
    }

    public init(
        action: Action,
        @ViewBuilder label: @escaping () -> Label
    ) where ActionLabel == ControlWidgetButtonDefaultActionLabel {
        self.init(
            action: action,
            label: label,
            actionLabel: { _ in ControlWidgetButtonDefaultActionLabel() }
        )
    }

    public init(
        _ titleResource: LocalizedStringResource,
        action: Action,
        @ViewBuilder actionLabel: @escaping (Bool) -> ActionLabel
    ) where Label == Text {
        self.init(
            action: action,
            label: { Text(String(describing: titleResource)) },
            actionLabel: actionLabel
        )
    }

    public init(
        _ titleKey: LocalizedStringKey,
        action: Action,
        @ViewBuilder actionLabel: @escaping (Bool) -> ActionLabel
    ) where Label == Text {
        self.init(
            action: action,
            label: { Text(titleKey) },
            actionLabel: actionLabel
        )
    }

    public init(
        _ title: some StringProtocol,
        action: Action,
        @ViewBuilder actionLabel: @escaping (Bool) -> ActionLabel
    ) where Label == Text {
        self.init(
            action: action,
            label: { Text(String(title)) },
            actionLabel: actionLabel
        )
    }
}

@MainActor
public struct ControlWidgetToggle<Label: View, ValueLabel: View, Action>: ControlWidgetTemplate {
    public typealias Body = Never
    public var body: Never {
        fatalError("Control widgets are host-driven")
    }

    public init(
        isOn: Bool,
        action: Action,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder valueLabel: @escaping (Bool) -> ValueLabel
    ) {
        _ = isOn
        _ = action
        _ = label
        _ = valueLabel
    }

    public init(
        isOn: Bool,
        action: Action,
        @ViewBuilder label: @escaping () -> Label
    ) where ValueLabel == ControlWidgetToggleDefaultLabel {
        self.init(
            isOn: isOn,
            action: action,
            label: label,
            valueLabel: { _ in ControlWidgetToggleDefaultLabel() }
        )
    }

    public init(
        _ titleResource: LocalizedStringResource,
        isOn: Bool,
        action: Action,
        @ViewBuilder valueLabel: @escaping (Bool) -> ValueLabel
    ) where Label == Text {
        self.init(
            isOn: isOn,
            action: action,
            label: { Text(String(describing: titleResource)) },
            valueLabel: valueLabel
        )
    }

    public init(
        _ titleKey: LocalizedStringKey,
        isOn: Bool,
        action: Action,
        @ViewBuilder valueLabel: @escaping (Bool) -> ValueLabel
    ) where Label == Text {
        self.init(
            isOn: isOn,
            action: action,
            label: { Text(titleKey) },
            valueLabel: valueLabel
        )
    }

    public init(
        _ title: some StringProtocol,
        isOn: Bool,
        action: Action,
        @ViewBuilder valueLabel: @escaping (Bool) -> ValueLabel
    ) where Label == Text {
        self.init(
            isOn: isOn,
            action: action,
            label: { Text(String(title)) },
            valueLabel: valueLabel
        )
    }
}

public protocol ControlValueProvider {
    associatedtype Value
    var previewValue: Value { get }
    func currentValue() async throws -> Value
}

public protocol AppIntentControlValueProvider {
    associatedtype Value
    associatedtype Configuration: ControlConfigurationIntent
    func previewValue(configuration: Configuration) -> Value
    func currentValue(configuration: Configuration) async throws -> Value
}

@MainActor
public struct StaticControlConfiguration<Content: ControlWidgetTemplate>: ControlWidgetConfiguration {
    public typealias Body = Never
    public var body: Never {
        fatalError("Control configurations are host-driven")
    }

    public init(kind: String, @ControlWidgetTemplateBuilder content: @escaping () -> Content) {
        _ = kind
        _ = content
    }

    public init<Provider: ControlValueProvider>(
        kind: String,
        provider: Provider,
        @ControlWidgetTemplateBuilder content: @escaping (Provider.Value) -> Content
    ) {
        _ = kind
        _ = provider
        _ = content
    }
}

@MainActor
public struct AppIntentControlConfiguration<
    Configuration: ControlConfigurationIntent,
    Content: ControlWidgetTemplate
>: ControlWidgetConfiguration {
    public typealias Body = Never
    public var body: Never {
        fatalError("Control configurations are host-driven")
    }

    public init(
        kind: String,
        intent: Configuration.Type = Configuration.self,
        @ControlWidgetTemplateBuilder content: @escaping (Configuration) -> Content
    ) {
        _ = kind
        _ = intent
        _ = content
    }

    public init<Provider: AppIntentControlValueProvider>(
        kind: String,
        provider: Provider,
        @ControlWidgetTemplateBuilder content: @escaping (Provider.Value) -> Content
    ) where Provider.Configuration == Configuration {
        _ = kind
        _ = provider
        _ = content
    }
}
