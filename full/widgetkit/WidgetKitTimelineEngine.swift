import Foundation

/// In-process provider registry. Linux has no `chronod`; a host asks for
/// "the entry at time T" and this engine runs the registered provider, then
/// picks the timeline entry whose date is closest to, but not later than, T.
/// Cited: Apple WidgetKit `Timeline` / `TimelineProvider` documentation —
/// WidgetKit renders the entry with `date <= current` (closest not after).
@_spi(OpenUIKitHost)
public actor WidgetTimelineEngine {
    public static let shared = WidgetTimelineEngine()

    private var clock: @Sendable () -> Date = { Date() }
    private var records: [String: any _RegisteredKind] = [:]

    public init() {}

    public func setClock(_ clock: @escaping @Sendable () -> Date) {
        self.clock = clock
    }

    public func now() -> Date {
        clock()
    }

    public func register<Provider: TimelineProvider & Sendable>(
        kind: String,
        provider: Provider,
        family: WidgetFamily = .systemSmall
    ) {
        records[kind] = _StaticKind(provider: provider, family: family)
    }

    public func register<Provider: IntentTimelineProvider & Sendable>(
        kind: String,
        provider: Provider,
        configuration: Provider.Intent,
        family: WidgetFamily = .systemSmall
    ) {
        records[kind] = _IntentKind(
            provider: provider,
            configuration: configuration,
            family: family
        )
    }

    public func register<Provider: AppIntentTimelineProvider & Sendable>(
        kind: String,
        provider: Provider,
        configuration: Provider.Intent,
        family: WidgetFamily = .systemSmall
    ) {
        records[kind] = _AppIntentKind(
            provider: provider,
            configuration: configuration,
            family: family
        )
    }

    public func unregister(kind: String) {
        records[kind] = nil
    }

    /// Last timeline entry with `date <= time`, or the first entry if `time`
    /// is before every date. Returns `nil` when `kind` is unregistered.
    public func entry(ofKind kind: String, at time: Date) async throws -> (any TimelineEntry)? {
        guard let record = records[kind] else { return nil }
        let snapshot = try await record.load(at: time)
        return _entry(at: time, from: snapshot)
    }

    public func currentEntry(ofKind kind: String) async throws -> (any TimelineEntry)? {
        try await entry(ofKind: kind, at: clock())
    }

    /// `.atEnd` → last entry date; `.after(date)` → that date; `.never` → nil.
    /// Cited: Apple `TimelineReloadPolicy`.
    public func nextReloadDate(ofKind kind: String) async throws -> Date? {
        guard let record = records[kind] else { return nil }
        let snapshot = try await record.load(at: clock())
        return snapshot.nextReload
    }

    public func placeholder(ofKind kind: String) async -> (any TimelineEntry)? {
        await records[kind]?.placeholder()
    }

    public var registeredKinds: [String] {
        records.keys.sorted()
    }
}

private struct _TimelineSnapshot: @unchecked Sendable {
    var dates: [Date]
    var entries: [any TimelineEntry]
    var nextReload: Date?
}

private protocol _RegisteredKind: Sendable {
    func load(at time: Date) async throws -> _TimelineSnapshot
    func placeholder() async -> any TimelineEntry
}

private func _context(family: WidgetFamily) -> TimelineProviderContext {
    let size = family.portableCanvasSize(for: .iPhone393)
        ?? CGSize(width: 1, height: 1)
    return TimelineProviderContext(family: family, displaySize: size)
}

private func _entry(at time: Date, from snapshot: _TimelineSnapshot) -> (any TimelineEntry)? {
    guard let first = snapshot.entries.first else { return nil }
    var chosen: any TimelineEntry = first
    for (date, entry) in zip(snapshot.dates, snapshot.entries) {
        if date <= time {
            chosen = entry
        } else {
            break
        }
    }
    return chosen
}

private struct _StaticKind<Provider: TimelineProvider & Sendable>: _RegisteredKind {
    let provider: Provider
    let family: WidgetFamily

    func load(at _: Date) async throws -> _TimelineSnapshot {
        let context = _context(family: family)
        let evaluation = try await WidgetTimelineRuntime.shared.evaluate(
            provider,
            context: context
        )
        return _snapshot(evaluation)
    }

    func placeholder() async -> any TimelineEntry {
        provider.placeholder(in: _context(family: family))
    }
}

private struct _IntentKind<Provider: IntentTimelineProvider & Sendable>: _RegisteredKind, @unchecked Sendable {
    let provider: Provider
    let configuration: Provider.Intent
    let family: WidgetFamily

    func load(at _: Date) async throws -> _TimelineSnapshot {
        let context = _context(family: family)
        let evaluation = try await WidgetTimelineRuntime.shared.evaluate(
            provider,
            configuration: configuration,
            context: context
        )
        return _snapshot(evaluation)
    }

    func placeholder() async -> any TimelineEntry {
        provider.placeholder(in: _context(family: family))
    }
}

private struct _AppIntentKind<Provider: AppIntentTimelineProvider & Sendable>: _RegisteredKind {
    let provider: Provider
    let configuration: Provider.Intent
    let family: WidgetFamily

    func load(at _: Date) async throws -> _TimelineSnapshot {
        let context = _context(family: family)
        let evaluation = try await WidgetTimelineRuntime.shared.evaluate(
            provider,
            configuration: configuration,
            context: context
        )
        return _snapshot(evaluation)
    }

    func placeholder() async -> any TimelineEntry {
        provider.placeholder(in: _context(family: family))
    }
}

private func _snapshot<Entry: TimelineEntry>(
    _ evaluation: WidgetTimelineEvaluation<Entry>
) -> _TimelineSnapshot {
    _TimelineSnapshot(
        dates: evaluation.timeline.entries.map(\.date),
        entries: evaluation.timeline.entries.map { $0 as any TimelineEntry },
        nextReload: evaluation.nextReload
    )
}
