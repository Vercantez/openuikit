import Foundation
@_spi(OpenUIKitHost) import ManagedAppDistribution

func testCurrentDistributorSingleton() {
    let a = ManagedAppLibrary.currentDistributor
    let b = ManagedAppLibrary.currentDistributor
    precondition(a === b)
}

func testAvailableAppsType() {
    let apps = ManagedAppLibrary.currentDistributor.availableApps
    _ = apps.makeAsyncIterator()
}

func testCatalogFailClosedDeviceNotManaged() {
    let snapshot = ManagedAppLibrary.currentDistributor._catalogSnapshot()
    switch snapshot {
    case .failure(.deviceNotManaged):
        break
    default:
        preconditionFailure("Linux catalog must fail closed as deviceNotManaged")
    }
}

func testManagedAppsMakeAsyncIterator() {
    let iterator = ManagedAppLibrary.currentDistributor.availableApps.makeAsyncIterator()
    _ = iterator
}

func testManagedAppsElementTypealias() {
    let sample: ManagedAppLibrary.ManagedApps.Element = .failure(.deviceNotManaged)
    switch sample {
    case .failure(.deviceNotManaged):
        break
    default:
        preconditionFailure("unexpected element")
    }
}

func testAsyncIteratorElementTypealias() {
    let sample: ManagedAppLibrary.ManagedApps.AsyncIterator.Element = .success([])
    switch sample {
    case .success(let apps):
        precondition(apps.isEmpty)
    default:
        preconditionFailure("unexpected element")
    }
}

func testAsyncIteratorFailureIsNever() {
    let never: ManagedAppLibrary.ManagedApps.AsyncIterator.Failure.Type = Never.self
    precondition(never == Never.self)
}

/// Runs one asynchronous operation on the cooperative executor while keeping
/// the sealed test entry point synchronous. The bounded condition wait avoids
/// depending on a main run loop and turns scheduler failure into a test failure.
private final class LibraryAwaitBox<T: Sendable>: @unchecked Sendable {
    let condition = NSCondition()
    var result: Result<T, any Error>?

    func complete(_ value: Result<T, any Error>) {
        condition.lock()
        result = value
        condition.signal()
        condition.unlock()
    }
}

private func awaitLibraryValue<T: Sendable>(
    _ operation: @escaping @Sendable () async throws -> T
) -> Result<T, any Error> {
    let box = LibraryAwaitBox<T>()
    Task.detached {
        let value: Result<T, any Error>
        do {
            value = .success(try await operation())
        } catch {
            value = .failure(error)
        }
        box.complete(value)
    }
    box.condition.lock()
    let deadline = Date(timeIntervalSinceNow: 5)
    while box.result == nil && box.condition.wait(until: deadline) {}
    let value = box.result
    box.condition.unlock()
    precondition(value != nil, "async iterator did not finish before deadline")
    return value!
}

func testAsyncIteratorNextFailClosedThenFinishes() {
    let result = awaitLibraryValue {
        var iterator = ManagedAppLibrary.currentDistributor.availableApps.makeAsyncIterator()
        let first = try await iterator.next()
        let second = try await iterator.next()
        return (first, second)
    }
    switch result {
    case .success(let (first, second)):
        guard case .failure(.deviceNotManaged)? = first else {
            preconditionFailure("first catalog value must fail closed")
        }
        precondition(second == nil)
    case .failure(let error):
        preconditionFailure("Never-failing iterator threw: \(error)")
    }
}

func testAsyncIteratorNextIsolationFailClosedThenFinishes() {
    let result = awaitLibraryValue {
        var iterator = ManagedAppLibrary.currentDistributor.availableApps.makeAsyncIterator()
        let first = await iterator.next(isolation: nil)
        let second = await iterator.next(isolation: nil)
        return (first, second)
    }
    switch result {
    case .success(let (first, second)):
        guard case .failure(.deviceNotManaged)? = first else {
            preconditionFailure("first isolated catalog value must fail closed")
        }
        precondition(second == nil)
    case .failure(let error):
        preconditionFailure("Never-failing isolated iterator threw: \(error)")
    }
}
