import Foundation
import Assignables

func assignablesExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("Assignables test failed: \(message)")
    }
}

func assignablesMakeDocument(_ id: String = "doc-1") -> AssignableDocument {
    try! AssignableDocument(id: id, partData: [:])
}

func assignablesPageID(_ raw: String) -> AssignableDocument.Page.ID {
    try! JSONDecoder().decode(AssignableDocument.Page.ID.self, from: Data("\"\(raw)\"".utf8))
}

func assignablesWorkPageID(_ raw: String) -> AssignedWorkDocument.Page.ID {
    try! JSONDecoder().decode(AssignedWorkDocument.Page.ID.self, from: Data("\"\(raw)\"".utf8))
}

/// Runs one structured-concurrency operation from the sealed synchronous runner.
/// The bounded condition wait cannot depend on a main run loop.
final class AssignablesAsyncResult<Value: Sendable>: @unchecked Sendable {
    let condition = NSCondition()
    var result: Result<Value, any Error>?

    func complete(_ value: Result<Value, any Error>) {
        condition.lock()
        result = value
        condition.signal()
        condition.unlock()
    }
}

func assignablesAwait<Value: Sendable>(
    _ operation: @escaping @Sendable () async throws -> Value
) -> Result<Value, any Error> {
    let state = AssignablesAsyncResult<Value>()
    Task.detached {
        let result: Result<Value, any Error>
        do { result = .success(try await operation()) }
        catch { result = .failure(error) }
        state.complete(result)
    }
    state.condition.lock()
    let deadline = Date(timeIntervalSinceNow: 5)
    while state.result == nil && state.condition.wait(until: deadline) {}
    let result = state.result
    state.condition.unlock()
    guard let result else { fatalError("Assignables async test timed out") }
    return result
}
