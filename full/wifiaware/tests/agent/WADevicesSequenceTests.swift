@_spi(OpenUIKitHost) import WiFiAware
import Dispatch
import Foundation

private func waExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private final class WABox<T>: @unchecked Sendable {
    var value: T?
    var error: (any Error)?
}

private func waAwait<T: Sendable>(_ body: @escaping @Sendable () async throws -> T) -> T {
    let box = WABox<T>()
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        do {
            box.value = try await body()
        } catch {
            box.error = error
        }
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + 5) == .success, "async timeout")
    if let error = box.error {
        fatalError("\(error)")
    }
    return box.value!
}

private struct ThrowingEmptySequence: AsyncSequence, Sendable {
    typealias Element = Int
    typealias Failure = Error

    struct AsyncIterator: AsyncIteratorProtocol {
        mutating func next() async throws -> Int? { nil }
    }

    func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
}

func testDevicesSequenceIterator() {
    let seq = WAPairedDevice.allDevices
    let _: WAPairedDevice.DevicesSequence.Element? = waAwait { try await seq.current() }
    let yielded = waAwait { () async throws -> Int in
        var count = 0
        for try await value in seq {
            count += 1
            waExpect(value.isEmpty, "sequence yields empty snapshot")
        }
        return count
    }
    waExpect(yielded == 1, "sequence yields once")
    _ = waAwait { () async throws -> Int in
        var iterator = seq.makeAsyncIterator()
        let _: WAPairedDevice.DevicesSequence.AsyncIterator.Element? = try await iterator.next()
        let second = try await iterator.next()
        waExpect(second == nil, "iterator finishes")
        let isolated: WAPairedDevice.DevicesSequence.AsyncIterator.Element? =
            try await iterator.next(isolation: nil)
        waExpect(isolated == nil, "next(isolation:) after finish")
        let _: WAPairedDevice.DevicesSequence.AsyncIterator.Failure.Type = Error.self
        let _: WAPairedDevice.DevicesSequence.AsyncIterator = iterator
        return 0
    }
}

func testDevicesSequenceContainsReduce() {
    let seq = WAPairedDevice.allDevices
    waExpect(waAwait { try await seq.contains([:]) }, "contains empty snapshot")
    waExpect(waAwait { try await seq.contains(where: { $0.isEmpty }) }, "contains(where:)")
    waExpect(waAwait { try await seq.allSatisfy({ $0.isEmpty }) }, "allSatisfy")
    waExpect(waAwait { try await seq.first(where: { $0.isEmpty }) } == [:], "first(where:)")
    waExpect(waAwait { try await seq.min(by: { _, _ in true }) } == [:], "min")
    waExpect(waAwait { try await seq.max(by: { _, _ in false }) } == [:], "max")
    let reduced = waAwait {
        try await seq.reduce(0) { partial, snapshot in
            partial + snapshot.count
        }
    }
    waExpect(reduced == 0, "reduce")
    let into = waAwait {
        try await seq.reduce(into: 0) { partial, snapshot in
            partial += snapshot.count
        }
    }
    waExpect(into == 0, "reduce(into:)")
}

func testDevicesSequenceMapFilterPrefix() {
    let seq = WAPairedDevice.allDevices
    let mapped = waAwait { () async throws -> Int in
        var count = 0
        for try await value in seq.map({ $0.count }) {
            count += 1
            waExpect(value == 0, "map count")
        }
        return count
    }
    waExpect(mapped == 1, "nonthrowing map")
    let throwingMapped = waAwait { () async throws -> Int in
        var count = 0
        for try await value in seq.map({ snapshot -> Int in
            if snapshot.count < 0 { throw WAError.error(try JSONDecoder().decode(WAError.ErrorDetails.self, from: Data("{}".utf8))) }
            return snapshot.count
        }) {
            count += 1
            waExpect(value == 0, "throwing map count")
        }
        return count
    }
    waExpect(throwingMapped == 1, "throwing map")
    let compact = waAwait { () async throws -> Int in
        var count = 0
        for try await _ in seq.compactMap({ $0.isEmpty ? Optional<Int>.none : 1 }) {
            count += 1
        }
        return count
    }
    waExpect(compact == 0, "compactMap")
    let throwingCompact = waAwait { () async throws -> Int in
        var count = 0
        for try await _ in seq.compactMap({ snapshot -> Int? in
            if snapshot.count < 0 {
                throw WAError.error(
                    try JSONDecoder().decode(WAError.ErrorDetails.self, from: Data("{}".utf8))
                )
            }
            return nil
        }) {
            count += 1
        }
        return count
    }
    waExpect(throwingCompact == 0, "throwing compactMap")
    let filtered = waAwait { () async throws -> Int in
        var count = 0
        for try await _ in seq.filter({ !$0.isEmpty }) {
            count += 1
        }
        return count
    }
    waExpect(filtered == 0, "filter")
    let prefixCount = waAwait { () async throws -> Int in
        var count = 0
        for try await _ in seq.prefix(2) {
            count += 1
        }
        return count
    }
    waExpect(prefixCount == 1, "prefix")
    let prefixWhile = waAwait { () async throws -> Int in
        var count = 0
        for try await _ in try seq.prefix(while: { $0.isEmpty }) {
            count += 1
        }
        return count
    }
    waExpect(prefixWhile == 1, "prefix(while:)")
    let dropCount = waAwait { () async throws -> Int in
        var count = 0
        for try await _ in seq.dropFirst() {
            count += 1
        }
        return count
    }
    waExpect(dropCount == 0, "dropFirst")
    let droppedWhile = waAwait { () async throws -> Int in
        var count = 0
        for try await _ in seq.drop(while: { $0.isEmpty }) {
            count += 1
        }
        return count
    }
    waExpect(droppedWhile == 0, "drop(while:)")
}

func testDevicesSequenceFlatMap() {
    let seq = WAPairedDevice.allDevices
    let neverInner = waAwait { () async throws -> Int in
        var count = 0
        for try await _ in seq.flatMap({ snapshot -> AsyncStream<WAPairedDevice.ID> in
            AsyncStream { continuation in
                for id in snapshot.keys {
                    continuation.yield(id)
                }
                continuation.finish()
            }
        }) {
            count += 1
        }
        return count
    }
    waExpect(neverInner == 0, "flatMap AsyncStream Failure == Never")
    let throwingInner = waAwait { () async throws -> Int in
        var count = 0
        for try await _ in seq.flatMap({ _ in ThrowingEmptySequence() }) {
            count += 1
        }
        return count
    }
    waExpect(throwingInner == 0, "flatMap Failure == Error")
    let throwingTransform = waAwait { () async throws -> Int in
        var count = 0
        for try await _ in seq.flatMap({ snapshot -> ThrowingEmptySequence in
            _ = snapshot
            return ThrowingEmptySequence()
        }) {
            count += 1
        }
        return count
    }
    waExpect(throwingTransform == 0, "throwing flatMap")
}
