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
    public var id: String { kind }

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

private final class _ControlCenterStorage: @unchecked Sendable {
    let lock = NSLock()
    var controls: [ControlInfo] = []
    var reloadKinds: [String] = []
    var reloadAllCount: UInt64 = 0

    func reset() {
        controls = []
        reloadKinds = []
        reloadAllCount = 0
    }
}

private enum _ControlCenterProcessLocal {
    static let storage = _ControlCenterStorage()
}

/// Process-local Control Center. Linux has no Control Center daemon; reload
/// requests are retained as host-visible work and never claimed as accepted.
public final class ControlCenter: @unchecked Sendable {
    public static let shared = ControlCenter()

    private let storage: _ControlCenterStorage

    public init() {
        storage = _ControlCenterProcessLocal.storage
    }

    public func reloadControls(ofKind kind: String) {
        storage.lock.lock()
        storage.reloadKinds.append(kind)
        storage.lock.unlock()
    }

    public func reloadAllControls() {
        storage.lock.lock()
        storage.reloadAllCount &+= 1
        storage.lock.unlock()
    }

    public func currentControls() async -> [ControlInfo] {
        portableCurrentControls()
    }

    @_spi(OpenUIKitHost)
    public func installCurrentControls(_ controls: [ControlInfo]) {
        storage.lock.lock()
        self.storage.controls = controls
        storage.lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public func portableCurrentControls() -> [ControlInfo] {
        storage.lock.lock()
        let snapshot = storage.controls
        storage.lock.unlock()
        return snapshot
    }

    @_spi(OpenUIKitHost)
    public func drainReloadKinds() -> [String] {
        storage.lock.lock()
        let kinds = storage.reloadKinds
        storage.reloadKinds.removeAll(keepingCapacity: true)
        storage.lock.unlock()
        return kinds
    }

    @_spi(OpenUIKitHost)
    public func drainReloadAllCount() -> UInt64 {
        storage.lock.lock()
        let count = storage.reloadAllCount
        storage.reloadAllCount = 0
        storage.lock.unlock()
        return count
    }

    @_spi(OpenUIKitHost)
    public func resetProcessLocalState() {
        storage.lock.lock()
        storage.reset()
        storage.lock.unlock()
    }
}

@_spi(OpenUIKitHost)
public struct ControlWidgetTemplateDescriptor: Equatable, Sendable {
    public var role: String
    public var title: String?
    public var isOn: Bool?
    public var privacySensitive: Bool
    public var disabled: Bool
    public var tinted: Bool

    public init(
        role: String,
        title: String? = nil,
        isOn: Bool? = nil,
        privacySensitive: Bool = false,
        disabled: Bool = false,
        tinted: Bool = false
    ) {
        self.role = role
        self.title = title
        self.isOn = isOn
        self.privacySensitive = privacySensitive
        self.disabled = disabled
        self.tinted = tinted
    }
}

@_spi(OpenUIKitHost)
public struct ControlWidgetConfigurationDescriptor: Equatable, Sendable {
    public var kind: String
    public var displayName: String?
    public var description: String?
    public var promptsForUserConfiguration: Bool
    public var previewValueDescription: String?

    public init(
        kind: String,
        displayName: String? = nil,
        description: String? = nil,
        promptsForUserConfiguration: Bool = false,
        previewValueDescription: String? = nil
    ) {
        self.kind = kind
        self.displayName = displayName
        self.description = description
        self.promptsForUserConfiguration = promptsForUserConfiguration
        self.previewValueDescription = previewValueDescription
    }
}

protocol _PortableControlTemplateProvider {
    var _portableTemplate: ControlWidgetTemplateDescriptor { get }
}

protocol _PortableControlConfigurationProvider {
    var _portableControlDescriptor: ControlWidgetConfigurationDescriptor { get }
}

public struct _ModifiedControlWidgetTemplate<Base>: ControlWidgetTemplate {
    public let base: Base
    @_spi(OpenUIKitHost) public let portableTemplate: ControlWidgetTemplateDescriptor
    public typealias Body = Never
    public var body: Never {
        fatalError("Control widgets are host-driven")
    }
}

extension _ModifiedControlWidgetTemplate: _PortableControlTemplateProvider {
    var _portableTemplate: ControlWidgetTemplateDescriptor { portableTemplate }
}

public struct _ModifiedControlWidgetConfiguration<Base>: ControlWidgetConfiguration {
    public let base: Base
    @_spi(OpenUIKitHost) public let portableDescriptor: ControlWidgetConfigurationDescriptor
    public typealias Body = Never
    public var body: Never {
        fatalError("Control configurations are host-driven")
    }
}

extension _ModifiedControlWidgetConfiguration: _PortableControlConfigurationProvider {
    var _portableControlDescriptor: ControlWidgetConfigurationDescriptor {
        portableDescriptor
    }
}

private func _portableControlTemplate<T>(_ value: T) -> ControlWidgetTemplateDescriptor {
    if let provider = value as? any _PortableControlTemplateProvider {
        return provider._portableTemplate
    }
    return ControlWidgetTemplateDescriptor(role: String(reflecting: T.self))
}

private func _portableControlDescriptor<T>(_ value: T) -> ControlWidgetConfigurationDescriptor {
    if let provider = value as? any _PortableControlConfigurationProvider {
        return provider._portableControlDescriptor
    }
    return ControlWidgetConfigurationDescriptor(kind: String(reflecting: T.self))
}

@_spi(OpenUIKitHost)
public enum ControlWidgetPortable {
    public static func template<T>(of value: T) -> ControlWidgetTemplateDescriptor {
        _portableControlTemplate(value)
    }

    public static func descriptor<T>(of value: T) -> ControlWidgetConfigurationDescriptor {
        _portableControlDescriptor(value)
    }
}

@_spi(OpenUIKitHost)
public enum ControlValueHost {
    public static func preview<Provider: ControlValueProvider>(
        _ provider: Provider
    ) -> Provider.Value {
        provider.previewValue
    }

    public static func preview<Provider: AppIntentControlValueProvider>(
        _ provider: Provider,
        configuration: Provider.Configuration
    ) -> Provider.Value {
        provider.previewValue(configuration: configuration)
    }
}

public protocol ControlWidgetTemplate {
    associatedtype Body: ControlWidgetTemplate
    var body: Body { get }
}

extension Never: ControlWidgetTemplate {}

public protocol ControlWidgetConfiguration {
    associatedtype Body: ControlWidgetConfiguration
    var body: Body { get }
}

extension Never: ControlWidgetConfiguration {}

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
        var descriptor = _portableControlTemplate(self)
        descriptor.privacySensitive = sensitive
        return _ModifiedControlWidgetTemplate(base: self, portableTemplate: descriptor)
    }

    func tint(_ tint: Color?) -> some ControlWidgetTemplate {
        var descriptor = _portableControlTemplate(self)
        descriptor.tinted = tint != nil
        return _ModifiedControlWidgetTemplate(base: self, portableTemplate: descriptor)
    }

    func disabled(_ disabled: Bool) -> some ControlWidgetTemplate {
        var descriptor = _portableControlTemplate(self)
        descriptor.disabled = disabled
        return _ModifiedControlWidgetTemplate(base: self, portableTemplate: descriptor)
    }
}

public extension ControlWidgetConfiguration {
    func promptsForUserConfiguration() -> some ControlWidgetConfiguration {
        var descriptor = _portableControlDescriptor(self)
        descriptor.promptsForUserConfiguration = true
        return _ModifiedControlWidgetConfiguration(base: self, portableDescriptor: descriptor)
    }

    func description(_ description: LocalizedStringResource) -> some ControlWidgetConfiguration {
        var descriptor = _portableControlDescriptor(self)
        descriptor.description = description.key
        return _ModifiedControlWidgetConfiguration(base: self, portableDescriptor: descriptor)
    }

    func displayName(_ displayName: LocalizedStringResource) -> some ControlWidgetConfiguration {
        var descriptor = _portableControlDescriptor(self)
        descriptor.displayName = displayName.key
        return _ModifiedControlWidgetConfiguration(base: self, portableDescriptor: descriptor)
    }

    func pushHandler(_ pushHandlerType: any ControlPushHandler.Type) -> some ControlWidgetConfiguration {
        _ = pushHandlerType
        return _ModifiedControlWidgetConfiguration(
            base: self,
            portableDescriptor: _portableControlDescriptor(self)
        )
    }
}

@resultBuilder
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

public struct ControlWidgetButton<Label: View, ActionLabel: View, Action>: ControlWidgetTemplate {
    public typealias Body = Never
    public var body: Never {
        fatalError("Control widgets are host-driven")
    }

    @_spi(OpenUIKitHost) public let portableTemplate: ControlWidgetTemplateDescriptor

    public init(
        action: Action,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder actionLabel: @escaping (Bool) -> ActionLabel
    ) {
        let built = label()
        let title: String?
        if let text = built as? Text {
            title = text.content
        } else {
            title = nil
        }
        _ = action
        _ = actionLabel
        portableTemplate = ControlWidgetTemplateDescriptor(role: "button", title: title)
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
            label: { Text(titleResource.key) },
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

extension ControlWidgetButton: _PortableControlTemplateProvider {
    var _portableTemplate: ControlWidgetTemplateDescriptor { portableTemplate }
}

public struct ControlWidgetToggle<Label: View, ValueLabel: View, Action>: ControlWidgetTemplate {
    public typealias Body = Never
    public var body: Never {
        fatalError("Control widgets are host-driven")
    }

    @_spi(OpenUIKitHost) public let portableTemplate: ControlWidgetTemplateDescriptor

    public init(
        isOn: Bool,
        action: Action,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder valueLabel: @escaping (Bool) -> ValueLabel
    ) {
        let built = label()
        let title: String?
        if let text = built as? Text {
            title = text.content
        } else {
            title = nil
        }
        _ = action
        _ = valueLabel
        portableTemplate = ControlWidgetTemplateDescriptor(
            role: "toggle",
            title: title,
            isOn: isOn
        )
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
            label: { Text(titleResource.key) },
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

extension ControlWidgetToggle: _PortableControlTemplateProvider {
    var _portableTemplate: ControlWidgetTemplateDescriptor { portableTemplate }
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

public struct StaticControlConfiguration<Content: ControlWidgetTemplate>: ControlWidgetConfiguration {
    public typealias Body = Never
    public var body: Never {
        fatalError("Control configurations are host-driven")
    }

    @_spi(OpenUIKitHost) public let portableDescriptor: ControlWidgetConfigurationDescriptor

    public init(kind: String, @ControlWidgetTemplateBuilder content: @escaping () -> Content) {
        portableDescriptor = ControlWidgetConfigurationDescriptor(kind: kind)
        _ = content
    }

    public init<Provider: ControlValueProvider>(
        kind: String,
        provider: Provider,
        @ControlWidgetTemplateBuilder content: @escaping (Provider.Value) -> Content
    ) {
        portableDescriptor = ControlWidgetConfigurationDescriptor(
            kind: kind,
            previewValueDescription: String(describing: provider.previewValue)
        )
        _ = content
    }
}

extension StaticControlConfiguration: _PortableControlConfigurationProvider {
    var _portableControlDescriptor: ControlWidgetConfigurationDescriptor {
        portableDescriptor
    }
}

public struct AppIntentControlConfiguration<
    Configuration: ControlConfigurationIntent,
    Content: ControlWidgetTemplate
>: ControlWidgetConfiguration {
    public typealias Body = Never
    public var body: Never {
        fatalError("Control configurations are host-driven")
    }

    @_spi(OpenUIKitHost) public let portableDescriptor: ControlWidgetConfigurationDescriptor

    public init(
        kind: String,
        intent: Configuration.Type = Configuration.self,
        @ControlWidgetTemplateBuilder content: @escaping (Configuration) -> Content
    ) {
        portableDescriptor = ControlWidgetConfigurationDescriptor(kind: kind)
        _ = intent
        _ = content
    }

    public init<Provider: AppIntentControlValueProvider>(
        kind: String,
        provider: Provider,
        @ControlWidgetTemplateBuilder content: @escaping (Provider.Value) -> Content
    ) where Provider.Configuration == Configuration {
        portableDescriptor = ControlWidgetConfigurationDescriptor(
            kind: kind,
            previewValueDescription: String(describing: Provider.Value.self)
        )
        _ = provider
        _ = content
    }
}

extension AppIntentControlConfiguration: _PortableControlConfigurationProvider {
    var _portableControlDescriptor: ControlWidgetConfigurationDescriptor {
        portableDescriptor
    }
}
