//===----------------------------------------------------------------------===//
// Portable WidgetKit
//
// Widget presentation is host-driven on Linux, but timelines are real data,
// providers execute in-process, reload requests are durable process state, and
// configuration metadata remains inspectable.  The implementation never
// pretends that an Apple widget daemon accepted a request.
//===----------------------------------------------------------------------===//

@_exported import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(AppIntents)
@_exported import AppIntents
#endif
#if canImport(Intents)
@preconcurrency import Intents
#endif
#if canImport(SwiftUI)
@_exported import SwiftUI
#endif

// MARK: - Timeline values

public struct TimelineEntryRelevance: Codable, Hashable, Sendable {
    public var score: Float
    public var duration: TimeInterval

    public init(score: Float, duration: TimeInterval = 0) {
        self.score = score
        self.duration = duration
    }
}

public protocol TimelineEntry {
    var date: Date { get }
    var relevance: TimelineEntryRelevance? { get }
}

public extension TimelineEntry {
    var relevance: TimelineEntryRelevance? { nil }
}

public struct TimelineReloadPolicy: Equatable, Sendable {
    @_spi(OpenUIKitHost)
    public enum PortableKind: Equatable, Sendable {
        case atEnd
        case never
        case after(Date)
    }

    @_spi(OpenUIKitHost)
    public let portableKind: PortableKind

    private init(_ kind: PortableKind) {
        portableKind = kind
    }

    public static let atEnd = Self(.atEnd)
    public static let never = Self(.never)

    public static func after(_ date: Date) -> Self {
        Self(.after(date))
    }
}

public struct Timeline<EntryType: TimelineEntry>: @unchecked Sendable {
    public let entries: [EntryType]
    public let policy: TimelineReloadPolicy

    public init(entries: [EntryType], policy: TimelineReloadPolicy) {
        self.entries = entries
        self.policy = policy
    }
}

// MARK: - Context and families

public enum WidgetFamily: Int, CaseIterable, Sendable,
    CustomStringConvertible, CustomDebugStringConvertible
{
    case systemSmall = 0
    case systemMedium = 1
    case systemLarge = 2
    case systemExtraLarge = 3
    case accessoryCircular = 5
    case accessoryRectangular = 6
    case accessoryInline = 7
    case accessoryCorner = 8

    public var description: String {
        switch self {
        case .systemSmall: "systemSmall"
        case .systemMedium: "systemMedium"
        case .systemLarge: "systemLarge"
        case .systemExtraLarge: "systemExtraLarge"
        case .accessoryCircular: "accessoryCircular"
        case .accessoryRectangular: "accessoryRectangular"
        case .accessoryInline: "accessoryInline"
        case .accessoryCorner: "accessoryCorner"
        }
    }

    public var debugDescription: String { description }
}

/// Home Screen / Today View families on iPhoneOS 26.1.
/// `accessoryCorner` is in the TBD export (watchOS) but not in the iPhoneOS
/// public graph, so it is omitted from the default supported-family list.
/// Cited: Apple WidgetFamily + HIG Widgets; iPhoneOS 26.1 public-surface.tsv.
public extension WidgetFamily {
    static let portableHomeScreenFamilies: [WidgetFamily] = [
        .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
        .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ]
}

/// Named device classes for the Home Screen canvas sizes Apple publishes
/// for widgets. Accessory (Lock Screen) point sizes are not in that table;
/// hosts must pass `TimelineProviderContext.displaySize` for those families.
/// Cited: Apple Human Interface Guidelines, Widgets
/// (developer.apple.com/design/human-interface-guidelines/widgets)
/// and WidgetFamily documentation. Values are logical points.
@_spi(OpenUIKitHost)
public enum WidgetCanvasDevice: String, Sendable {
    /// iPhone SE (3rd gen) class, 375-pt-wide logical canvas.
    case iPhoneSE375
    /// iPhone 14 Pro / 15 Pro / 16 class, 393-pt-wide logical canvas.
    case iPhone393
    /// iPhone 14 Pro Max / Plus class, 430-pt-wide logical canvas.
    case iPhone430
}

@_spi(OpenUIKitHost)
public extension WidgetFamily {
    /// Home Screen canvas for `device`, from Apple's HIG Widgets size table.
    /// Returns `nil` for accessory families (no HIG point table in the seed).
    ///
    /// HIG rows used here (points):
    /// - SE 375: small 155×155, medium 329×155, large 329×345
    /// - 393-pt iPhone: small 158×158, medium 338×158, large 338×354
    /// - 430-pt iPhone: small 170×170, medium 364×170, large 364×382
    /// Extra-large (iPad) and accessory families are not in that phone table;
    /// this method returns nil and the host must pass `displaySize`.
    func portableCanvasSize(for device: WidgetCanvasDevice) -> CGSize? {
        switch self {
        case .systemSmall:
            switch device {
            case .iPhoneSE375: return CGSize(width: 155, height: 155)
            case .iPhone393: return CGSize(width: 158, height: 158)
            case .iPhone430: return CGSize(width: 170, height: 170)
            }
        case .systemMedium:
            switch device {
            case .iPhoneSE375: return CGSize(width: 329, height: 155)
            case .iPhone393: return CGSize(width: 338, height: 158)
            case .iPhone430: return CGSize(width: 364, height: 170)
            }
        case .systemLarge:
            switch device {
            case .iPhoneSE375: return CGSize(width: 329, height: 345)
            case .iPhone393: return CGSize(width: 338, height: 354)
            case .iPhone430: return CGSize(width: 364, height: 382)
            }
        case .systemExtraLarge, .accessoryCircular, .accessoryRectangular,
             .accessoryInline, .accessoryCorner:
            return nil
        }
    }
}

public struct TimelineProviderContext: Sendable {
    @dynamicMemberLookup
    public struct EnvironmentVariants: Sendable {
        public init() {}

        public subscript<T>(
            dynamicMember keyPath: WritableKeyPath<EnvironmentValues, T>
        ) -> [T]? {
            nil
        }

        public subscript<T>(
            _ keyPath: WritableKeyPath<EnvironmentValues, T>
        ) -> [T]? {
            nil
        }
    }

    public let environmentVariants: EnvironmentVariants
    public let family: WidgetFamily
    public let isPreview: Bool
    public let displaySize: CGSize

    @_spi(OpenUIKitHost)
    public init(
        family: WidgetFamily,
        isPreview: Bool = false,
        displaySize: CGSize
    ) {
        self.environmentVariants = EnvironmentVariants()
        self.family = family
        self.isPreview = isPreview
        self.displaySize = displaySize
    }
}

public protocol TimelineProvider {
    associatedtype Entry: TimelineEntry
    typealias Context = TimelineProviderContext

    func placeholder(in context: Context) -> Entry
    func getSnapshot(
        in context: Context,
        completion: @escaping @Sendable (Entry) -> Void
    )
    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<Entry>) -> Void
    )
}

/// The SiriKit-backed provider route used by widgets that predate AppIntents.
/// Generated intent subclasses remain the application's canonical types; this
/// protocol only drives their timelines.
public protocol IntentTimelineProvider {
    associatedtype Entry: TimelineEntry
    associatedtype Intent: INIntent
    typealias Context = TimelineProviderContext

    func placeholder(in context: Context) -> Entry
    func getSnapshot(
        for configuration: Intent,
        in context: Context,
        completion: @escaping (Entry) -> Void
    )
    func getTimeline(
        for configuration: Intent,
        in context: Context,
        completion: @escaping (Timeline<Entry>) -> Void
    )
}

public protocol AppIntentTimelineProvider {
    associatedtype Entry: TimelineEntry
    associatedtype Intent: WidgetConfigurationIntent
    typealias Context = TimelineProviderContext

    func recommendations() -> [AppIntentRecommendation<Intent>]
    func placeholder(in context: Context) -> Entry
    func snapshot(for configuration: Intent, in context: Context) async -> Entry
    func timeline(
        for configuration: Intent,
        in context: Context
    ) async -> Timeline<Entry>
}

public extension AppIntentTimelineProvider {
    func recommendations() -> [AppIntentRecommendation<Intent>] { [] }

    func relevance() async -> WidgetRelevance<Intent> {
        WidgetRelevance()
    }
}

public extension TimelineProvider {
    func relevance() async -> WidgetRelevance<Void> {
        WidgetRelevance()
    }
}

public extension IntentTimelineProvider {
    func recommendations() -> [IntentRecommendation<Intent>] { [] }

    func relevance() async -> WidgetRelevance<Intent> {
        WidgetRelevance()
    }
}

public struct AppIntentRecommendation<Intent: WidgetConfigurationIntent>:
    @unchecked Sendable
{
    public let intent: Intent
    public let description: Text

    public init(intent: Intent, description: Text) {
        self.intent = intent
        self.description = description
    }

    public init(intent: Intent, description: LocalizedStringKey) {
        self.init(intent: intent, description: Text(description))
    }

    @_disfavoredOverload
    public init<S: StringProtocol>(intent: Intent, description: S) {
        self.init(intent: intent, description: Text(String(description)))
    }
}

// MARK: - Executable provider runtime

@_spi(OpenUIKitHost)
public enum WidgetTimelineRuntimeError: Error, Equatable, Sendable {
    case emptyTimeline
    case entriesOutOfOrder
    case duplicateEntryDate(Date)
    case reloadDateBeforeLastEntry(Date)
}

@_spi(OpenUIKitHost)
public struct WidgetTimelineEvaluation<Entry: TimelineEntry>: @unchecked Sendable {
    public let timeline: Timeline<Entry>
    public let nextReload: Date?

    public init(timeline: Timeline<Entry>, nextReload: Date?) {
        self.timeline = timeline
        self.nextReload = nextReload
    }
}

/// Executes providers without an Apple widget daemon.  The runtime validates
/// ordering and computes the next host wake-up rather than silently accepting
/// malformed timelines that WidgetKit itself would reject or reschedule.
@_spi(OpenUIKitHost)
public actor WidgetTimelineRuntime {
    public static let shared = WidgetTimelineRuntime()

    public private(set) var evaluationCount: UInt64 = 0

    public init() {}

    public func evaluate<Provider: AppIntentTimelineProvider & Sendable>(
        _ provider: Provider,
        configuration: Provider.Intent,
        context: TimelineProviderContext
    ) async throws -> WidgetTimelineEvaluation<Provider.Entry> {
        let timeline = await provider.timeline(
            for: configuration,
            in: context
        )
        evaluationCount &+= 1
        return try validate(timeline)
    }

    public func snapshot<Provider: AppIntentTimelineProvider & Sendable>(
        _ provider: Provider,
        configuration: Provider.Intent,
        context: TimelineProviderContext
    ) async -> Provider.Entry {
        await provider.snapshot(for: configuration, in: context)
    }

    public func evaluate<Provider: TimelineProvider & Sendable>(
        _ provider: Provider,
        context: TimelineProviderContext
    ) async throws -> WidgetTimelineEvaluation<Provider.Entry> {
        let timeline: Timeline<Provider.Entry> = await withCheckedContinuation { continuation in
            provider.getTimeline(in: context) { value in
                continuation.resume(returning: value)
            }
        }
        evaluationCount &+= 1
        return try validate(timeline)
    }

    public func snapshot<Provider: TimelineProvider & Sendable>(
        _ provider: Provider,
        context: TimelineProviderContext
    ) async -> Provider.Entry {
        await withCheckedContinuation { continuation in
            provider.getSnapshot(in: context) { entry in
                continuation.resume(returning: entry)
            }
        }
    }

    public func evaluate<Provider: IntentTimelineProvider & Sendable>(
        _ provider: Provider,
        configuration: Provider.Intent,
        context: TimelineProviderContext
    ) async throws -> WidgetTimelineEvaluation<Provider.Entry> {
        let timeline: Timeline<Provider.Entry> = await withCheckedContinuation { continuation in
            provider.getTimeline(for: configuration, in: context) { value in
                continuation.resume(returning: value)
            }
        }
        evaluationCount &+= 1
        return try validate(timeline)
    }

    private func validate<Entry: TimelineEntry>(
        _ timeline: Timeline<Entry>
    ) throws -> WidgetTimelineEvaluation<Entry> {
        guard let first = timeline.entries.first,
              let last = timeline.entries.last else {
            throw WidgetTimelineRuntimeError.emptyTimeline
        }

        var previous = first.date
        for entry in timeline.entries.dropFirst() {
            if entry.date < previous {
                throw WidgetTimelineRuntimeError.entriesOutOfOrder
            }
            if entry.date == previous {
                throw WidgetTimelineRuntimeError.duplicateEntryDate(entry.date)
            }
            previous = entry.date
        }

        let nextReload: Date?
        switch timeline.policy.portableKind {
        case .atEnd:
            nextReload = last.date
        case .never:
            nextReload = nil
        case .after(let date):
            guard date >= last.date else {
                throw WidgetTimelineRuntimeError.reloadDateBeforeLastEntry(date)
            }
            nextReload = date
        }
        return WidgetTimelineEvaluation(
            timeline: timeline,
            nextReload: nextReload
        )
    }
}

// MARK: - Process-local WidgetCenter

public struct WidgetInfo: Hashable, Identifiable, @unchecked Sendable,
    CustomDebugStringConvertible
{
    public let configuration: INIntent?
    public let family: WidgetFamily
    public let kind: String
    public var id: WidgetInfo { self }

    @_spi(OpenUIKitHost)
    public init(
        kind: String,
        family: WidgetFamily,
        configuration: INIntent? = nil
    ) {
        self.kind = kind
        self.family = family
        self.configuration = configuration
    }

    public func widgetConfigurationIntent<Intent>(of intentType: Intent.Type) -> Intent? {
        _ = intentType
        return nil
    }

    public static func == (lhs: WidgetInfo, rhs: WidgetInfo) -> Bool {
        lhs.kind == rhs.kind
            && lhs.family == rhs.family
            && lhs.configuration === rhs.configuration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(family)
        if let configuration {
            hasher.combine(ObjectIdentifier(configuration))
        }
    }

    public var debugDescription: String {
        "WidgetInfo(kind: \(kind), family: \(family))"
    }
}

@_spi(OpenUIKitHost)
public struct WidgetReloadRequest: Equatable, Sendable {
    public enum Scope: Equatable, Sendable {
        case kind(String)
        case all
    }

    public let sequence: UInt64
    public let scope: Scope
}

private final class _WidgetCenterStorage: @unchecked Sendable {
    let lock = NSLock()
    var configurations: [WidgetInfo] = []
    var requests: [WidgetReloadRequest] = []
    var nextSequence: UInt64 = 1
}

/// Linux has no `chronod`; reloads are retained as process-local host work.
/// Hosts can drain those requests through the SPI instead of receiving a false
/// success from a no-op.
public final class WidgetCenter: @unchecked Sendable {
    public static let shared = WidgetCenter()

    public struct UserInfoKey: Sendable {
        public static let kind = "kind"
        public static let family = "family"
        public static let activityID = "activityID"
    }

    private let storage: _WidgetCenterStorage

    public init() {
        storage = _WidgetCenterStorage()
    }

    public func invalidateConfigurationRecommendations() {}

    public func invalidateRelevance(ofKind kind: String) {
        _ = kind
    }

    public var currentPushInfo: WidgetPushInfo? {
        get async { nil }
    }

    public func getCurrentConfigurations(
        _ completion: @escaping @Sendable (Result<[WidgetInfo], any Error>) -> Void
    ) {
        completion(.success(currentConfigurationsSnapshot()))
    }

    public func currentConfigurations() async throws -> [WidgetInfo] {
        currentConfigurationsSnapshot()
    }

    public func reloadTimelines(ofKind kind: String) {
        record(.kind(kind))
    }

    public func reloadAllTimelines() {
        record(.all)
    }

    @_spi(OpenUIKitHost)
    public func installCurrentConfigurations(_ configurations: [WidgetInfo]) {
        storage.lock.lock()
        storage.configurations = configurations
        storage.lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public func drainReloadRequests() -> [WidgetReloadRequest] {
        storage.lock.lock()
        let requests = storage.requests
        storage.requests.removeAll(keepingCapacity: true)
        storage.lock.unlock()
        return requests
    }

    private func currentConfigurationsSnapshot() -> [WidgetInfo] {
        storage.lock.lock()
        let result = storage.configurations
        storage.lock.unlock()
        return result
    }

    private func record(_ scope: WidgetReloadRequest.Scope) {
        storage.lock.lock()
        let request = WidgetReloadRequest(
            sequence: storage.nextSequence,
            scope: scope
        )
        storage.nextSequence &+= 1
        storage.requests.append(request)
        storage.lock.unlock()
    }
}

// MARK: - Configuration model

@_spi(OpenUIKitHost)
public struct WidgetConfigurationDescriptor: Equatable, Sendable {
    public var kind: String
    public var displayName: String?
    public var description: String?
    public var supportedFamilies: [WidgetFamily]
    public var contentMarginsDisabled: Bool
    public var containerBackgroundRemovable: Bool

    public init(
        kind: String,
        displayName: String? = nil,
        description: String? = nil,
        supportedFamilies: [WidgetFamily] = WidgetFamily.portableHomeScreenFamilies,
        contentMarginsDisabled: Bool = false,
        containerBackgroundRemovable: Bool = true
    ) {
        self.kind = kind
        self.displayName = displayName
        self.description = description
        self.supportedFamilies = supportedFamilies
        self.contentMarginsDisabled = contentMarginsDisabled
        self.containerBackgroundRemovable = containerBackgroundRemovable
    }
}

@_spi(OpenUIKitHost)
public enum WidgetKitPortable {
    public enum PresentationCapability: String, Sendable {
        case hostDriven
    }

    public enum ReloadCapability: String, Sendable {
        case processLocal
    }

    public static let presentationCapability = PresentationCapability.hostDriven
    public static let reloadCapability = ReloadCapability.processLocal

    @_spi(OpenUIKitHost)
    @MainActor
    public static func descriptor<T>(
        of configuration: T
    ) -> WidgetConfigurationDescriptor {
        _portableWidgetDescriptor(configuration)
    }
}

#if !canImport(SwiftUI) || OPENUIKIT_PORTABLE_SWIFTUI
@MainActor
public protocol WidgetConfiguration {
    associatedtype Body: WidgetConfiguration
    @WidgetConfigurationBuilder var body: Body { get }
}

extension Never: WidgetConfiguration {}

@MainActor
@resultBuilder
public enum WidgetConfigurationBuilder {
    public static func buildExpression<Content: WidgetConfiguration>(
        _ content: Content
    ) -> Content {
        content
    }

    public static func buildBlock<Content: WidgetConfiguration>(
        _ content: Content
    ) -> Content {
        content
    }
}

@MainActor
public protocol Widget {
    associatedtype Body: WidgetConfiguration
    @WidgetConfigurationBuilder var body: Body { get }
}

@MainActor
public protocol WidgetBundle {
    associatedtype Body: Widget
    @WidgetBundleBuilder var body: Body { get }
    static func main()
}

public extension WidgetBundle {
    static func main() {}
}

public extension Widget {
    static func main() {}
}

@MainActor
@resultBuilder
public enum WidgetBundleBuilder {
    public static func buildExpression<Content: Widget>(_ content: Content) -> Content {
        content
    }

    public static func buildBlock<Content: Widget>(_ content: Content) -> Content {
        content
    }

    public static func buildBlock<First: Widget, Second: Widget>(
        _ first: First,
        _ second: Second
    ) -> _WidgetBundlePair<First, Second> {
        _WidgetBundlePair(first: first, second: second)
    }

    public static func buildBlock<First: Widget, Second: Widget, Third: Widget>(
        _ first: First,
        _ second: Second,
        _ third: Third
    ) -> _WidgetBundlePair<_WidgetBundlePair<First, Second>, Third> {
        _WidgetBundlePair(
            first: _WidgetBundlePair(first: first, second: second),
            second: third
        )
    }

    public static func buildBlock<
        First: Widget, Second: Widget, Third: Widget, Fourth: Widget
    >(
        _ first: First,
        _ second: Second,
        _ third: Third,
        _ fourth: Fourth
    ) -> _WidgetBundlePair<
        _WidgetBundlePair<_WidgetBundlePair<First, Second>, Third>, Fourth
    > {
        _WidgetBundlePair(
            first: _WidgetBundlePair(
                first: _WidgetBundlePair(first: first, second: second),
                second: third
            ),
            second: fourth
        )
    }

    public static func buildBlock<
        First: Widget, Second: Widget, Third: Widget, Fourth: Widget,
        Fifth: Widget
    >(
        _ first: First,
        _ second: Second,
        _ third: Third,
        _ fourth: Fourth,
        _ fifth: Fifth
    ) -> _WidgetBundlePair<
        _WidgetBundlePair<
            _WidgetBundlePair<_WidgetBundlePair<First, Second>, Third>, Fourth
        >,
        Fifth
    > {
        _WidgetBundlePair(
            first: _WidgetBundlePair(
                first: _WidgetBundlePair(
                    first: _WidgetBundlePair(first: first, second: second),
                    second: third
                ),
                second: fourth
            ),
            second: fifth
        )
    }
}

@MainActor
public struct _WidgetBundlePair<First: Widget, Second: Widget>: Widget {
    public let first: First
    public let second: Second

    public var body: some WidgetConfiguration {
        first.body
    }
}
#endif

@MainActor
public struct StaticConfiguration<Content: View>: @unchecked Sendable {
    @_spi(OpenUIKitHost) public let portableDescriptor: WidgetConfigurationDescriptor
    private let content: (Any) -> Content

    public init<Provider: TimelineProvider>(
        kind: String,
        provider: Provider,
        @ViewBuilder content: @escaping (Provider.Entry) -> Content
    ) {
        portableDescriptor = WidgetConfigurationDescriptor(kind: kind)
        self.content = { value in content(value as! Provider.Entry) }
        _ = provider
    }
}

@MainActor
public struct AppIntentConfiguration<Intent, Content>: @unchecked Sendable
    where Intent: WidgetConfigurationIntent, Content: View
{
    @_spi(OpenUIKitHost) public let portableDescriptor: WidgetConfigurationDescriptor
    private let content: (Any) -> Content

    public init<Provider: AppIntentTimelineProvider>(
        kind: String,
        intent: Intent.Type = Intent.self,
        provider: Provider,
        @ViewBuilder content: @escaping (Provider.Entry) -> Content
    ) where Intent == Provider.Intent {
        portableDescriptor = WidgetConfigurationDescriptor(kind: kind)
        self.content = { value in content(value as! Provider.Entry) }
        _ = intent
        _ = provider
    }
}

@MainActor
public struct IntentConfiguration<Intent, Content>: @unchecked Sendable
    where Intent: INIntent, Content: View
{
    @_spi(OpenUIKitHost) public let portableDescriptor: WidgetConfigurationDescriptor
    private let content: (Any) -> Content

    public init<Provider: IntentTimelineProvider>(
        kind: String,
        intent: Intent.Type,
        provider: Provider,
        @ViewBuilder content: @escaping (Provider.Entry) -> Content
    ) where Intent == Provider.Intent {
        portableDescriptor = WidgetConfigurationDescriptor(kind: kind)
        self.content = { value in content(value as! Provider.Entry) }
        _ = intent
        _ = provider
    }
}

@MainActor
public struct _ModifiedWidgetConfiguration<Base>: @unchecked Sendable {
    public let base: Base
    @_spi(OpenUIKitHost) public let portableDescriptor: WidgetConfigurationDescriptor

    init(base: Base, descriptor: WidgetConfigurationDescriptor) {
        self.base = base
        portableDescriptor = descriptor
    }
}

#if !canImport(SwiftUI) || OPENUIKIT_PORTABLE_SWIFTUI
extension StaticConfiguration: WidgetConfiguration {
    public typealias Body = Never
    public var body: Never { fatalError("Widget configurations are host-driven") }
}

extension AppIntentConfiguration: WidgetConfiguration {
    public typealias Body = Never
    public var body: Never { fatalError("Widget configurations are host-driven") }
}

extension IntentConfiguration: WidgetConfiguration {
    public typealias Body = Never
    public var body: Never { fatalError("Widget configurations are host-driven") }
}

extension _ModifiedWidgetConfiguration: WidgetConfiguration
    where Base: WidgetConfiguration
{
    public typealias Body = Never
    public var body: Never { fatalError("Widget configurations are host-driven") }
}

public extension WidgetConfiguration {
    func configurationDisplayName(_ value: String) -> some WidgetConfiguration {
        var descriptor = _portableWidgetDescriptor(self)
        descriptor.displayName = value
        return _ModifiedWidgetConfiguration(base: self, descriptor: descriptor)
    }

    func description(_ value: String) -> some WidgetConfiguration {
        var descriptor = _portableWidgetDescriptor(self)
        descriptor.description = value
        return _ModifiedWidgetConfiguration(base: self, descriptor: descriptor)
    }

    func supportedFamilies(_ families: [WidgetFamily]) -> some WidgetConfiguration {
        var descriptor = _portableWidgetDescriptor(self)
        descriptor.supportedFamilies = families
        return _ModifiedWidgetConfiguration(base: self, descriptor: descriptor)
    }

    func contentMarginsDisabled() -> some WidgetConfiguration {
        var descriptor = _portableWidgetDescriptor(self)
        descriptor.contentMarginsDisabled = true
        return _ModifiedWidgetConfiguration(base: self, descriptor: descriptor)
    }

    func containerBackgroundRemovable(
        _ isRemovable: Bool = true
    ) -> some WidgetConfiguration {
        var descriptor = _portableWidgetDescriptor(self)
        descriptor.containerBackgroundRemovable = isRemovable
        return _ModifiedWidgetConfiguration(base: self, descriptor: descriptor)
    }

    func configurationDisplayName(_ key: LocalizedStringKey) -> some WidgetConfiguration {
        configurationDisplayName(String(describing: key))
    }

    func configurationDisplayName(_ resource: LocalizedStringResource) -> some WidgetConfiguration {
        configurationDisplayName(resource.key)
    }

    func configurationDisplayName(_ text: Text) -> some WidgetConfiguration {
        configurationDisplayName(String(describing: text))
    }

    func configurationDisplayName<S: StringProtocol>(_ value: S) -> some WidgetConfiguration {
        configurationDisplayName(String(value))
    }

    func description(_ key: LocalizedStringKey) -> some WidgetConfiguration {
        description(String(describing: key))
    }

    func description(_ resource: LocalizedStringResource) -> some WidgetConfiguration {
        description(resource.key)
    }

    func description(_ text: Text) -> some WidgetConfiguration {
        description(String(describing: text))
    }

    func promptsForUserConfiguration() -> some WidgetConfiguration {
        _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func pushHandler(_ pushHandlerType: any WidgetPushHandler.Type) -> some WidgetConfiguration {
        _ = pushHandlerType
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func associatedKind(_ associatedKind: String?) -> some WidgetConfiguration {
        _ = associatedKind
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func disfavoredLocations(
        _ locations: [WidgetLocation],
        for families: [WidgetFamily]
    ) -> some WidgetConfiguration {
        _ = locations
        _ = families
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func supportedMountingStyles(_ styles: [WidgetMountingStyle]) -> some WidgetConfiguration {
        _ = styles
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func onBackgroundURLSessionEvents(
        matching matchingString: String,
        _ urlSessionEvent: @escaping (String, @escaping () -> Void) -> Void
    ) -> some WidgetConfiguration {
        _ = matchingString
        _ = urlSessionEvent
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func onBackgroundURLSessionEvents(
        matching matchingBlock: ((String) -> Bool)? = nil,
        _ urlSessionEvent: @escaping (String, @escaping () -> Void) -> Void
    ) -> some WidgetConfiguration {
        _ = matchingBlock
        _ = urlSessionEvent
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func supplementalActivityFamilies(_ families: [ActivityFamily]) -> some WidgetConfiguration {
        _ = families
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func backgroundTask<D: Sendable, R: Sendable>(
        _ task: BackgroundTask<D, R>,
        action: @escaping (D) async -> R
    ) -> some WidgetConfiguration {
        _ = task
        _ = action
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }
}
#else
extension StaticConfiguration: SwiftUI.WidgetConfiguration {
    public typealias Body = Never
    public var body: Never { fatalError("Widget configurations are host-driven") }
}

extension AppIntentConfiguration: SwiftUI.WidgetConfiguration {
    public typealias Body = Never
    public var body: Never { fatalError("Widget configurations are host-driven") }
}

extension IntentConfiguration: SwiftUI.WidgetConfiguration {
    public typealias Body = Never
    public var body: Never { fatalError("Widget configurations are host-driven") }
}

extension _ModifiedWidgetConfiguration: SwiftUI.WidgetConfiguration
    where Base: SwiftUI.WidgetConfiguration
{
    public typealias Body = Never
    public var body: Never { fatalError("Widget configurations are host-driven") }
}

public extension SwiftUI.WidgetConfiguration {
    func configurationDisplayName(_ value: String) -> some SwiftUI.WidgetConfiguration {
        var descriptor = _portableWidgetDescriptor(self)
        descriptor.displayName = value
        return _ModifiedWidgetConfiguration(base: self, descriptor: descriptor)
    }

    func description(_ value: String) -> some SwiftUI.WidgetConfiguration {
        var descriptor = _portableWidgetDescriptor(self)
        descriptor.description = value
        return _ModifiedWidgetConfiguration(base: self, descriptor: descriptor)
    }

    func supportedFamilies(_ families: [WidgetFamily]) -> some SwiftUI.WidgetConfiguration {
        var descriptor = _portableWidgetDescriptor(self)
        descriptor.supportedFamilies = families
        return _ModifiedWidgetConfiguration(base: self, descriptor: descriptor)
    }

    func contentMarginsDisabled() -> some SwiftUI.WidgetConfiguration {
        var descriptor = _portableWidgetDescriptor(self)
        descriptor.contentMarginsDisabled = true
        return _ModifiedWidgetConfiguration(base: self, descriptor: descriptor)
    }

    func containerBackgroundRemovable(
        _ isRemovable: Bool = true
    ) -> some SwiftUI.WidgetConfiguration {
        var descriptor = _portableWidgetDescriptor(self)
        descriptor.containerBackgroundRemovable = isRemovable
        return _ModifiedWidgetConfiguration(base: self, descriptor: descriptor)
    }

    func configurationDisplayName(_ key: LocalizedStringKey) -> some SwiftUI.WidgetConfiguration {
        configurationDisplayName(String(describing: key))
    }

    func configurationDisplayName(_ resource: LocalizedStringResource) -> some SwiftUI.WidgetConfiguration {
        configurationDisplayName(String(describing: resource))
    }

    func configurationDisplayName(_ text: Text) -> some SwiftUI.WidgetConfiguration {
        configurationDisplayName(String(describing: text))
    }

    func configurationDisplayName<S: StringProtocol>(_ value: S) -> some SwiftUI.WidgetConfiguration {
        configurationDisplayName(String(value))
    }

    func description(_ key: LocalizedStringKey) -> some SwiftUI.WidgetConfiguration {
        description(String(describing: key))
    }

    func description(_ resource: LocalizedStringResource) -> some SwiftUI.WidgetConfiguration {
        description(String(describing: resource))
    }

    func description(_ text: Text) -> some SwiftUI.WidgetConfiguration {
        description(String(describing: text))
    }

    func promptsForUserConfiguration() -> some SwiftUI.WidgetConfiguration {
        _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func pushHandler(_ pushHandlerType: any WidgetPushHandler.Type) -> some SwiftUI.WidgetConfiguration {
        _ = pushHandlerType
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func associatedKind(_ associatedKind: String?) -> some SwiftUI.WidgetConfiguration {
        _ = associatedKind
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func disfavoredLocations(
        _ locations: [WidgetLocation],
        for families: [WidgetFamily]
    ) -> some SwiftUI.WidgetConfiguration {
        _ = locations
        _ = families
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func supportedMountingStyles(_ styles: [WidgetMountingStyle]) -> some SwiftUI.WidgetConfiguration {
        _ = styles
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func onBackgroundURLSessionEvents(
        matching matchingString: String,
        _ urlSessionEvent: @escaping (String, @escaping () -> Void) -> Void
    ) -> some SwiftUI.WidgetConfiguration {
        _ = matchingString
        _ = urlSessionEvent
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func onBackgroundURLSessionEvents(
        matching matchingBlock: ((String) -> Bool)? = nil,
        _ urlSessionEvent: @escaping (String, @escaping () -> Void) -> Void
    ) -> some SwiftUI.WidgetConfiguration {
        _ = matchingBlock
        _ = urlSessionEvent
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func supplementalActivityFamilies(_ families: [ActivityFamily]) -> some SwiftUI.WidgetConfiguration {
        _ = families
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }

    func backgroundTask<D: Sendable, R: Sendable>(
        _ task: BackgroundTask<D, R>,
        action: @escaping (D) async -> R
    ) -> some SwiftUI.WidgetConfiguration {
        _ = task
        _ = action
        return _ModifiedWidgetConfiguration(base: self, descriptor: _portableWidgetDescriptor(self))
    }
}

public extension SwiftUI.WidgetBundle {
    static func main() {}
}

public extension SwiftUI.Widget {
    static func main() {}
}
#endif

@MainActor
private func _portableWidgetDescriptor<T>(_ value: T) -> WidgetConfigurationDescriptor {
    if let configuration = value as? any _PortableConfigurationDescriptorProvider {
        return configuration._portableDescriptor
    }
    return WidgetConfigurationDescriptor(kind: String(reflecting: T.self))
}

@MainActor
protocol _PortableConfigurationDescriptorProvider {
    var _portableDescriptor: WidgetConfigurationDescriptor { get }
}

extension ActivityConfiguration: _PortableConfigurationDescriptorProvider {
    var _portableDescriptor: WidgetConfigurationDescriptor {
        portableDescriptor
    }
}

extension StaticConfiguration: _PortableConfigurationDescriptorProvider {
    var _portableDescriptor: WidgetConfigurationDescriptor {
        portableDescriptor
    }
}

extension AppIntentConfiguration: _PortableConfigurationDescriptorProvider {
    var _portableDescriptor: WidgetConfigurationDescriptor {
        portableDescriptor
    }
}

extension IntentConfiguration: _PortableConfigurationDescriptorProvider {
    var _portableDescriptor: WidgetConfigurationDescriptor {
        portableDescriptor
    }
}

extension _ModifiedWidgetConfiguration: _PortableConfigurationDescriptorProvider {
    var _portableDescriptor: WidgetConfigurationDescriptor {
        portableDescriptor
    }
}

// MARK: - SwiftUI widget environment

public struct WidgetRenderingMode: Equatable, Sendable,
    CustomStringConvertible
{
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let fullColor = Self(0)
    public static let accented = Self(1)
    public static let vibrant = Self(2)

    public var description: String {
        switch rawValue {
        case 0: "fullColor"
        case 1: "accented"
        default: "vibrant"
        }
    }
}

private enum _WidgetFamilyEnvironmentKey: EnvironmentKey {
    static let defaultValue = WidgetFamily.systemSmall
}

private enum _WidgetRenderingModeEnvironmentKey: EnvironmentKey {
    static let defaultValue = WidgetRenderingMode.fullColor
}

private enum _WidgetMarginsEnvironmentKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

public extension EnvironmentValues {
    var widgetFamily: WidgetFamily {
        get { self[_WidgetFamilyEnvironmentKey.self] }
        set { self[_WidgetFamilyEnvironmentKey.self] = newValue }
    }

    var widgetRenderingMode: WidgetRenderingMode {
        get { self[_WidgetRenderingModeEnvironmentKey.self] }
        set { self[_WidgetRenderingModeEnvironmentKey.self] = newValue }
    }

    var widgetContentMargins: EdgeInsets {
        get { self[_WidgetMarginsEnvironmentKey.self] }
        set { self[_WidgetMarginsEnvironmentKey.self] = newValue }
    }

    var showsWidgetContainerBackground: Bool {
        get { self[_ShowsWidgetContainerBackgroundKey.self] }
        set { self[_ShowsWidgetContainerBackgroundKey.self] = newValue }
    }

    var showsWidgetLabel: Bool {
        get { self[_ShowsWidgetLabelKey.self] }
        set { self[_ShowsWidgetLabelKey.self] = newValue }
    }

    var levelOfDetail: LevelOfDetail {
        get { self[_LevelOfDetailEnvironmentKey.self] }
        set { self[_LevelOfDetailEnvironmentKey.self] = newValue }
    }

    var activityFamily: ActivityFamily {
        get { self[_ActivityFamilyEnvironmentKey.self] }
        set { self[_ActivityFamilyEnvironmentKey.self] = newValue }
    }

    var isActivityFullscreen: Bool {
        get { self[_IsActivityFullscreenKey.self] }
        set { self[_IsActivityFullscreenKey.self] = newValue }
    }

    var isActivityUpdateReduced: Bool {
        get { self[_IsActivityUpdateReducedKey.self] }
        set { self[_IsActivityUpdateReducedKey.self] = newValue }
    }

    var supportedActivityFamilies: Set<ActivityFamily> {
        get { self[_SupportedActivityFamiliesEnvironmentKey.self] }
        set { self[_SupportedActivityFamiliesEnvironmentKey.self] = newValue }
    }
}

private enum _ShowsWidgetContainerBackgroundKey: EnvironmentKey {
    static let defaultValue = true
}

private enum _ShowsWidgetLabelKey: EnvironmentKey {
    static let defaultValue = false
}

private enum _IsActivityFullscreenKey: EnvironmentKey {
    static let defaultValue = false
}

private enum _IsActivityUpdateReducedKey: EnvironmentKey {
    static let defaultValue = false
}

private enum _LevelOfDetailEnvironmentKey: EnvironmentKey {
    static let defaultValue = LevelOfDetail.default
}

private enum _ActivityFamilyEnvironmentKey: EnvironmentKey {
    static let defaultValue = ActivityFamily.small
}

private enum _SupportedActivityFamiliesEnvironmentKey: EnvironmentKey {
    static let defaultValue = Set<ActivityFamily>()
}

public extension View {
    func widgetURL(_ url: URL?) -> some View {
        _ = url
        return self
    }

    func widgetAccentable(_ accentable: Bool = true) -> some View {
        _ = accentable
        return self
    }

    func widgetCurvesContent(_ curves: Bool = true) -> some View {
        _ = curves
        return self
    }

    func widgetLabel<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        _ = label
        return self
    }

    func widgetLabel(_ title: Text) -> some View {
        _ = title
        return self
    }

    func widgetLabel(_ titleKey: LocalizedStringKey) -> some View {
        _ = titleKey
        return self
    }

    func widgetLabel(_ title: LocalizedStringResource) -> some View {
        _ = title
        return self
    }

    func widgetLabel<S: StringProtocol>(_ title: S) -> some View {
        _ = title
        return self
    }

    func controlWidgetActionHint(_ hint: Text) -> some View {
        _ = hint
        return self
    }

    func controlWidgetActionHint(_ hintKey: LocalizedStringKey) -> some View {
        _ = hintKey
        return self
    }

    func controlWidgetActionHint(_ hint: LocalizedStringResource) -> some View {
        _ = hint
        return self
    }

    func controlWidgetActionHint<S: StringProtocol>(_ hint: S) -> some View {
        _ = hint
        return self
    }

    func controlWidgetStatus(_ status: Text) -> some View {
        _ = status
        return self
    }

    func controlWidgetStatus(_ statusKey: LocalizedStringKey) -> some View {
        _ = statusKey
        return self
    }

    func controlWidgetStatus(_ status: LocalizedStringResource) -> some View {
        _ = status
        return self
    }

    func controlWidgetStatus<S: StringProtocol>(_ status: S) -> some View {
        _ = status
        return self
    }

    func activityBackgroundTint(_ color: Color?) -> some View {
        _ = color
        return self
    }

    func activitySystemActionForegroundColor(_ color: Color?) -> some View {
        _ = color
        return self
    }

    func dynamicIsland(verticalPlacement: DynamicIslandExpandedRegionVerticalPlacement) -> some View {
        _ = verticalPlacement
        return self
    }
}

public extension Image {
    func widgetAccentedRenderingMode(_ renderingMode: WidgetAccentedRenderingMode?) -> some View {
        _ = renderingMode
        return self
    }
}

#if !canImport(SwiftUI) || OPENUIKIT_PORTABLE_SWIFTUI
public struct ContainerBackgroundPlacement: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }
    public static let widget = Self(0)
}

public extension View {
    func containerBackground<Style>(
        _ style: Style,
        for placement: ContainerBackgroundPlacement
    ) -> some View {
        _ = style
        _ = placement
        return self
    }

    func containerBackground<Background: View>(
        for placement: ContainerBackgroundPlacement,
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Background
    ) -> some View {
        _ = placement
        _ = alignment
        _ = content
        return self
    }
}
#else
public extension SwiftUI.ContainerBackgroundPlacement {
    static var widget: SwiftUI.ContainerBackgroundPlacement {
        fatalError("Widget container placement is host-driven")
    }
}
#endif

public struct AccessoryWidgetBackground: View {
    public init() {}
    public var body: some View { Color.clear }
}
