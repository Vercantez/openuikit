import Foundation
import SwiftData

/// Schema-v1-style local runtime probe. The sealed schema-v2 gate compiles
/// `*Tests.swift` plus generated load-smoke instead of this file.
func swiftDataRuntimeProbe() throws {
    let container = try ModelContainer(
        for: AgentNote.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    context.insert(AgentNote(title: "runtime", count: 1))
    try context.save()
    precondition(try context.fetchCount(FetchDescriptor<AgentNote>()) == 1)
    precondition(!SwiftDataPortable.supportsDurableStorage)
}
