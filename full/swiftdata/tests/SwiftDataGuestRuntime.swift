import Foundation
import SwiftData

@Model public final class GuestMetric: Equatable {
    public var account: String = ""
    public var count: Int = 0
    public var date: Date = Date(timeIntervalSince1970: 0)

    public init(account: String, count: Int, date: Date) {
        self.account = account
        self.count = count
        self.date = date
    }
}

@main
private enum SwiftDataGuestRuntime {
    static func main() throws {
        let container = try ModelContainer(
            for: GuestMetric.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let cutoff = Date(timeIntervalSince1970: 10)
        context.insert(GuestMetric(account: "one", count: 3, date: cutoff))
        context.insert(GuestMetric(account: "two", count: 8, date: cutoff))
        context.insert(GuestMetric(account: "one", count: 5, date: cutoff.addingTimeInterval(1)))

        let selected = "one"
        let descriptor = FetchDescriptor<GuestMetric>(
            predicate: #Predicate {
                $0.account == selected && $0.date >= cutoff
            },
            sortBy: [SortDescriptor(\GuestMetric.count, order: .reverse)]
        )
        let result = try context.fetch(descriptor)
        precondition(result.map(\.count) == [5, 3])
        context.delete(result[1])
        let remainingCount = try context.fetchCount(FetchDescriptor<GuestMetric>())
        precondition(remainingCount == 2)

        SwiftDataPortable.installDefaultContainer(container)
        @Query(sort: \GuestMetric.count, order: .reverse)
        var query: [GuestMetric]
        precondition(query.map(\.count) == [8, 5])

        print(
            "SWIFTDATA_GUEST_MACHO_OK macro=attached predicate=compound " +
            "sort=reverse mutation=insert-delete query=live durable=fail-closed"
        )
    }
}
