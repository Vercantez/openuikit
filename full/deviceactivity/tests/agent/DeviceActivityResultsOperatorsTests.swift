import DeviceActivity
import Foundation

private final class DeviceActivityAsyncProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var outcome: Result<Void, Error>?

    func finish(_ result: Result<Void, Error>) {
        lock.lock()
        outcome = result
        lock.unlock()
    }

    func snapshot() -> Result<Void, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return outcome
    }
}

/// Runs an async value-type operation on Swift's cooperative executor while the
/// top-level acceptance entry point remains synchronous. The bounded poll does
/// not depend on a main dispatch queue or run loop.
private func deviceActivityRunAsync(
    timeout: TimeInterval = 5,
    _ operation: @escaping @Sendable () async throws -> Void
) {
    let probe = DeviceActivityAsyncProbe()
    Task.detached {
        do {
            try await operation()
            probe.finish(.success(()))
        } catch {
            probe.finish(.failure(error))
        }
    }
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if let result = probe.snapshot() {
            if case .failure(let error) = result {
                fatalError("async DeviceActivity probe failed: \(error)")
            }
            return
        }
        Thread.sleep(forTimeInterval: 0.001)
    }
    fatalError("async DeviceActivity probe timed out")
}

func testDeviceActivityResultsAsyncIteration() {
    deviceActivityRunAsync {
        var iterator = DeviceActivityResults([4, 5]).makeAsyncIterator()
        deviceActivityRequire(await iterator.next(isolation: nil) == 4, "isolated next")
        deviceActivityRequire(await iterator.next() == 5, "next")
        deviceActivityRequire(await iterator.next() == nil, "exhausted")
    }
}

func testDeviceActivityResultsAsyncMapAndCompactMap() {
    deviceActivityRunAsync {
        let mapped = DeviceActivityResults([1, 2, 3]).map { value async in value * 2 }
        var mappedIterator = mapped.makeAsyncIterator()
        deviceActivityRequire(await mappedIterator.next() == 2, "map")

        let throwingMapped = DeviceActivityResults([2]).map { value async throws in value + 1 }
        var throwingMapIterator = throwingMapped.makeAsyncIterator()
        deviceActivityRequire(try await throwingMapIterator.next() == 3, "throwing map")

        let compacted = DeviceActivityResults([2, 3]).compactMap {
            value async in value.isMultiple(of: 2) ? value : nil
        }
        var compactIterator = compacted.makeAsyncIterator()
        deviceActivityRequire(await compactIterator.next() == 2, "compactMap")

        let throwingCompacted = DeviceActivityResults([3]).compactMap {
            value async throws in Optional(value)
        }
        var throwingCompactIterator = throwingCompacted.makeAsyncIterator()
        deviceActivityRequire(try await throwingCompactIterator.next() == 3, "throwing compactMap")
    }
}

func testDeviceActivityResultsAsyncSelection() {
    deviceActivityRunAsync {
        let values = DeviceActivityResults([1, 2, 3, 4])
        deviceActivityRequire(await values.contains(where: { $0 == 3 }), "contains where")
        deviceActivityRequire(await values.allSatisfy({ $0 > 0 }), "all satisfy")
        deviceActivityRequire(await values.first(where: { $0.isMultiple(of: 2) }) == 2, "first")
        deviceActivityRequire(await DeviceActivityResults([1, 2]).contains(2), "contains")
    }
}

func testDeviceActivityResultsAsyncReduction() {
    deviceActivityRunAsync {
        let values = DeviceActivityResults([1, 2, 3])
        let sum = await values.reduce(0) { $0 + $1 }
        deviceActivityRequire(sum == 6, "reduce")
        let collected = await values.reduce(into: [Int]()) { $0.append($1) }
        deviceActivityRequire(collected == [1, 2, 3], "reduce into")
    }
}

func testDeviceActivityResultsAsyncBounds() {
    deviceActivityRunAsync {
        let values = DeviceActivityResults([3, 1, 2])
        deviceActivityRequire(await values.min() == 1, "min")
        deviceActivityRequire(await values.max() == 3, "max")
        deviceActivityRequire(await values.min(by: { $0 < $1 }) == 1, "min by")
        deviceActivityRequire(await values.max(by: { $0 < $1 }) == 3, "max by")
    }
}

func testDeviceActivityResultsAsyncPrefixes() {
    deviceActivityRunAsync {
        var prefix = DeviceActivityResults([1, 2, 3]).prefix(2).makeAsyncIterator()
        deviceActivityRequire(await prefix.next() == 1, "prefix first")
        deviceActivityRequire(await prefix.next() == 2, "prefix second")
        deviceActivityRequire(await prefix.next() == nil, "prefix exhausted")

        var dropped = DeviceActivityResults([1, 2, 3]).dropFirst(2).makeAsyncIterator()
        deviceActivityRequire(await dropped.next() == 3, "dropFirst")
    }
}

func testDeviceActivityResultsAsyncPredicatedSequences() {
    deviceActivityRunAsync {
        var filtered = DeviceActivityResults([1, 2, 3]).filter { $0 > 1 }.makeAsyncIterator()
        deviceActivityRequire(await filtered.next() == 2, "filter")

        var dropped = DeviceActivityResults([1, 2, 3]).drop(while: { $0 < 3 }).makeAsyncIterator()
        deviceActivityRequire(await dropped.next() == 3, "drop while")

        var prefix = DeviceActivityResults([1, 2, 3]).prefix(while: { $0 < 3 }).makeAsyncIterator()
        deviceActivityRequire(await prefix.next() == 1, "prefix while")
        deviceActivityRequire(await prefix.next() == 2, "prefix while second")
        deviceActivityRequire(await prefix.next() == nil, "prefix while exhausted")
    }
}

func testDeviceActivityResultsAsyncFlatMap() {
    deviceActivityRunAsync {
        let values = DeviceActivityResults([1, 2])
        let flattened = values.flatMap { value async in
            DeviceActivityResults([value, value * 10])
        }
        var iterator = flattened.makeAsyncIterator()
        deviceActivityRequire(await iterator.next() == 1, "flatMap first")
        deviceActivityRequire(await iterator.next() == 10, "flatMap nested")

        let throwing = values.flatMap { value async throws in
            DeviceActivityResults([value + 1])
        }
        var throwingIterator = throwing.makeAsyncIterator()
        deviceActivityRequire(try await throwingIterator.next() == 2, "throwing flatMap")
    }
}
