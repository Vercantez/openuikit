import Foundation
import SwiftData

@Model public final class PortableMetric: Equatable {
    public var account: String = ""
    public var count: Int = 0
    public var date: Date = Date(timeIntervalSince1970: 0)

    public init(account: String, count: Int, date: Date) {
        self.account = account
        self.count = count
        self.date = date
    }
}

private struct MetricsQuery {
    @Query(sort: \PortableMetric.count, order: .reverse)
    var values: [PortableMetric]
}

@main
private enum SwiftDataHostRuntime {
    static func main() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PortableMetric.self,
            configurations: configuration
        )
        let context = ModelContext(container)

        let zero = Date(timeIntervalSince1970: 0)
        let one = PortableMetric(account: "one", count: 4, date: zero)
        let two = PortableMetric(account: "two", count: 9, date: zero.addingTimeInterval(1))
        let three = PortableMetric(account: "one", count: 6, date: zero.addingTimeInterval(2))
        context.insert(one)
        context.insert(two)
        context.insert(three)
        context.insert(one)
        precondition(context.hasChanges)
        precondition(context.insertedModelsArray.count == 3)
        try context.save()
        precondition(!context.hasChanges)

        let selectedAccount = "one"
        let cutoff = zero.addingTimeInterval(1)
        var descriptor = FetchDescriptor<PortableMetric>(
            predicate: #Predicate {
                $0.account == selectedAccount && $0.date >= cutoff
            },
            sortBy: [SortDescriptor(\PortableMetric.count, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let filtered = try context.fetch(descriptor)
        precondition(filtered.count == 1)
        precondition(filtered[0] === three)

        one.count = 11
        let descending = try context.fetch(FetchDescriptor<PortableMetric>(
            sortBy: [SortDescriptor(\PortableMetric.count, order: .reverse)]
        ))
        precondition(descending.map(\.count) == [11, 9, 6])

        context.delete(two)
        precondition(context.deletedModelsArray.count == 1)
        let remainingCount = try context.fetchCount(FetchDescriptor<PortableMetric>())
        precondition(remainingCount == 2)
        precondition(context.model(for: three.persistentModelID) === three)
        try context.save()
        precondition(!context.hasChanges)

        let transient = PortableMetric(account: "transient", count: 100, date: zero)
        context.insert(transient)
        context.rollback()
        let countAfterInsertRollback = try context.fetchCount(
            FetchDescriptor<PortableMetric>()
        )
        precondition(countAfterInsertRollback == 2)
        context.delete(three)
        context.rollback()
        precondition(context.model(for: three.persistentModelID) === three)

        SwiftDataPortable.installDefaultContainer(container)
        precondition(MetricsQuery().values.map(\.count) == [11, 6])

        do {
            _ = try ModelContainer(
                for: PortableMetric.self,
                configurations: ModelConfiguration()
            )
            preconditionFailure("durable configuration unexpectedly succeeded")
        } catch SwiftDataError.unsupportedPersistentStore {
            // The Linux runtime must never pretend that durable writes worked.
        }

        precondition(!SwiftDataPortable.supportsDurableStorage)
        precondition(!SwiftDataPortable.supportsCloudKit)
        SwiftDataPortable.reportVolatileFallback()
        SwiftDataPortable.reportVolatileFallback()
        print(
            "SWIFTDATA_HOST_RUNTIME_OK models=2 predicate=filtered " +
            "sort=descending query=live rollback=restored durable=fail-closed macro=attached"
        )
    }
}
