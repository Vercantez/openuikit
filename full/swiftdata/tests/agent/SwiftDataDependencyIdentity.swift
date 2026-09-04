import Foundation
import SwiftData

/// Future clean EC2 probe. Isolated Linux hosts typecheck Foundation
/// values through public SwiftData APIs; this file is not compiled by the
/// sealed host gate and must not justify public substitutes for
/// Foundation-owned types.
func swiftDataDependencyIdentityProbe() throws {
    let now = Date(timeIntervalSince1970: 100)
    let configuration = ModelConfiguration("identity", isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: AgentNote.self,
        configurations: configuration
    )
    let context = ModelContext(container)
    let note = AgentNote(title: now.description, count: 2)
    context.insert(note)
    let descriptor = FetchDescriptor<AgentNote>()
    let fetched = try context.fetch(descriptor)
    precondition(fetched.contains { $0.title == note.title })
    _ = Foundation.URL.self
    _ = Foundation.UUID.self
    _ = configuration.url
}
