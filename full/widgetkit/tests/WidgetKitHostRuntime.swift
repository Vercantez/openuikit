import Foundation
import Intents
import SwiftUI
@_spi(OpenUIKitHost) import WidgetKit

private struct TestIntent: WidgetConfigurationIntent {}

private struct TestEntry: TimelineEntry, Sendable {
    let date: Date
    let value: Int
}

private struct TestProvider: AppIntentTimelineProvider, Sendable {
    func placeholder(in _: Context) -> TestEntry {
        TestEntry(date: Date(timeIntervalSinceReferenceDate: 10), value: 0)
    }

    func snapshot(for _: TestIntent, in _: Context) async -> TestEntry {
        TestEntry(date: Date(timeIntervalSinceReferenceDate: 20), value: 1)
    }

    func timeline(for _: TestIntent, in _: Context) async -> Timeline<TestEntry> {
        Timeline(
            entries: [
                TestEntry(date: Date(timeIntervalSinceReferenceDate: 100), value: 1),
                TestEntry(date: Date(timeIntervalSinceReferenceDate: 200), value: 2),
            ],
            policy: .after(Date(timeIntervalSinceReferenceDate: 300))
        )
    }
}

private struct DuplicateProvider: AppIntentTimelineProvider, Sendable {
    func placeholder(in _: Context) -> TestEntry {
        TestEntry(date: Date(timeIntervalSinceReferenceDate: 10), value: 0)
    }

    func snapshot(for _: TestIntent, in _: Context) async -> TestEntry {
        placeholder(
            in: TimelineProviderContext(
                family: .systemSmall,
                displaySize: CGSize(width: 1, height: 1)
            )
        )
    }

    func timeline(for _: TestIntent, in _: Context) async -> Timeline<TestEntry> {
        let date = Date(timeIntervalSinceReferenceDate: 100)
        return Timeline(
            entries: [
                TestEntry(date: date, value: 1),
                TestEntry(date: date, value: 2),
            ],
            policy: .atEnd
        )
    }
}

private final class LegacyIntent: INIntent, @unchecked Sendable {}

private struct LegacyProvider: IntentTimelineProvider, Sendable {
    func placeholder(in _: Context) -> TestEntry {
        TestEntry(date: Date(timeIntervalSinceReferenceDate: 10), value: 0)
    }

    func getSnapshot(
        for _: LegacyIntent,
        in _: Context,
        completion: @escaping (TestEntry) -> Void
    ) {
        completion(TestEntry(date: Date(timeIntervalSinceReferenceDate: 20), value: 1))
    }

    func getTimeline(
        for _: LegacyIntent,
        in _: Context,
        completion: @escaping (Timeline<TestEntry>) -> Void
    ) {
        completion(
            Timeline(
                entries: [
                    TestEntry(
                        date: Date(timeIntervalSinceReferenceDate: 100),
                        value: 1
                    )
                ],
                policy: .atEnd
            )
        )
    }
}

@main
private struct WidgetKitHostRuntime {
    @MainActor
    static func main() async throws {
        precondition(WidgetKitPortable.presentationCapability == .hostDriven)
        precondition(WidgetKitPortable.reloadCapability == .processLocal)

        let context = TimelineProviderContext(
            family: .systemMedium,
            displaySize: CGSize(width: 364, height: 170)
        )
        precondition(context.family == .systemMedium)
        precondition(context.displaySize == CGSize(width: 364, height: 170))
        precondition(!context.isPreview)

        let evaluation = try await WidgetTimelineRuntime.shared.evaluate(
            TestProvider(),
            configuration: TestIntent(),
            context: context
        )
        precondition(evaluation.timeline.entries.map(\.value) == [1, 2])
        precondition(
            evaluation.nextReload
                == Date(timeIntervalSinceReferenceDate: 300)
        )
        let evaluationCount = await WidgetTimelineRuntime.shared.evaluationCount
        precondition(evaluationCount == 1)

        do {
            _ = try await WidgetTimelineRuntime.shared.evaluate(
                DuplicateProvider(),
                configuration: TestIntent(),
                context: context
            )
            preconditionFailure("duplicate timeline dates must fail closed")
        } catch WidgetTimelineRuntimeError.duplicateEntryDate(let date) {
            precondition(date == Date(timeIntervalSinceReferenceDate: 100))
        }

        let center = WidgetCenter()
        center.installCurrentConfigurations([
            WidgetInfo(kind: "account", family: .systemSmall),
            WidgetInfo(kind: "timeline", family: .systemMedium),
        ])
        let configurations = try await center.currentConfigurations()
        precondition(configurations.map(\.kind) == ["account", "timeline"])
        center.reloadTimelines(ofKind: "account")
        center.reloadAllTimelines()
        let requests = center.drainReloadRequests()
        precondition(requests.map(\.sequence) == [1, 2])
        precondition(requests[0].scope == .kind("account"))
        precondition(requests[1].scope == .all)
        precondition(center.drainReloadRequests().isEmpty)

        let configuration = AppIntentConfiguration(
            kind: "portable.account",
            intent: TestIntent.self,
            provider: TestProvider()
        ) { entry in
            Text("\(entry.value)")
        }
        .configurationDisplayName("Account")
        .description("Account status")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
        let descriptor = WidgetKitPortable.descriptor(of: configuration)
        precondition(descriptor.kind == "portable.account")
        precondition(descriptor.displayName == "Account")
        precondition(descriptor.description == "Account status")
        precondition(descriptor.supportedFamilies == [.systemSmall, .systemMedium])
        precondition(descriptor.contentMarginsDisabled)
        precondition(!descriptor.containerBackgroundRemovable)

        let legacyConfiguration = IntentConfiguration(
            kind: "portable.note",
            intent: LegacyIntent.self,
            provider: LegacyProvider()
        ) { entry in
            Text("\(entry.value)")
        }
        .configurationDisplayName("Note")
        let legacyDescriptor = WidgetKitPortable.descriptor(
            of: legacyConfiguration
        )
        precondition(legacyDescriptor.kind == "portable.note")
        precondition(legacyDescriptor.displayName == "Note")

        print(
            "WIDGETKIT_HOST_OK timeline=validated,scheduled "
                + "providers=app-intent,sirikit reload=process-local,ordered "
                + "configuration=retained presentation=host-driven"
        )
    }
}
