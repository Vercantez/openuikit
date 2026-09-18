import Foundation
import ManagedAppDistribution

// In-process AsyncSequence coverage for the fail-closed managed-apps
// catalog. Linux is not an MDM device: every sequence yields one
// `.failure(.deviceNotManaged)` snapshot and then ends. No call below
// suspends on hardware, a daemon, or the network, so each test completes
// immediately under the sealed runner's timeout.

func testAsyncIteratorNext() async {
    var iterator = ManagedAppLibrary.currentDistributor.availableApps.makeAsyncIterator()
    do {
        let first = try await iterator.next()
        switch first {
        case .some(.failure(.deviceNotManaged)):
            break
        default:
            preconditionFailure("first next() must be fail-closed deviceNotManaged")
        }
        let second = try await iterator.next()
        precondition(second == nil, "sequence must end after one snapshot")
    } catch {
        preconditionFailure("fail-closed next() must not throw: \(error)")
    }
}

func testAsyncIteratorNextIsolation() async {
    var iterator = ManagedAppLibrary.currentDistributor.availableApps.makeAsyncIterator()
    let first = await iterator.next(isolation: nil)
    switch first {
    case .some(.failure(.deviceNotManaged)):
        break
    default:
        preconditionFailure("first next(isolation:) must be fail-closed deviceNotManaged")
    }
    let second = await iterator.next(isolation: nil)
    precondition(second == nil, "sequence must end after one snapshot")
}

func testAsyncSequenceMap() async {
    let apps = ManagedAppLibrary.currentDistributor.availableApps
    let mappedCount = await apps.map { $0 }.reduce(0) { count, _ in count + 1 }
    precondition(mappedCount == 1, "map must preserve the single fail-closed element")
    let firstMapped = await apps.map { $0 }.first(where: { _ in true })
    switch firstMapped {
    case .some(.failure(.deviceNotManaged)):
        break
    default:
        preconditionFailure("mapped element must stay fail-closed deviceNotManaged")
    }
    do {
        let throwingMapped = apps.map { (element: ManagedAppLibrary.ManagedApps.Element) throws -> ManagedAppLibrary.ManagedApps.Element in element }
        let throwingCount = try await throwingMapped.reduce(0) { count, _ in count + 1 }
        precondition(throwingCount == 1, "throwing map must preserve the single element")
    } catch {
        preconditionFailure("throwing map over a fail-closed sequence must not throw: \(error)")
    }
}

func testAsyncSequenceCompactMap() async {
    let apps = ManagedAppLibrary.currentDistributor.availableApps
    let kept = await apps.compactMap { _ in 1 }.reduce(0) { count, _ in count + 1 }
    precondition(kept == 1, "compactMap keeping values must preserve the element")
    let dropped = await apps.compactMap { _ -> Int? in nil }.reduce(0) { count, _ in count + 1 }
    precondition(dropped == 0, "compactMap returning nil must drop the element")
    do {
        let throwingKept = apps.compactMap { (_: ManagedAppLibrary.ManagedApps.Element) throws -> Int? in 1 }
        let throwingCount = try await throwingKept.reduce(0) { count, _ in count + 1 }
        precondition(throwingCount == 1, "throwing compactMap must preserve the element")
    } catch {
        preconditionFailure("throwing compactMap over a fail-closed sequence must not throw: \(error)")
    }
}

func testAsyncSequenceFlatMap() async {
    let apps = ManagedAppLibrary.currentDistributor.availableApps
    let flattened = apps.flatMap { (_: ManagedAppLibrary.ManagedApps.Element) -> ManagedAppLibrary.ManagedApps in apps }
    let flattenedCount = await flattened.reduce(0) { count, _ in count + 1 }
    precondition(flattenedCount == 1, "flatMap over one snapshot of one snapshot must yield one element")
    let firstFlattened = await apps
        .flatMap { (_: ManagedAppLibrary.ManagedApps.Element) -> ManagedAppLibrary.ManagedApps in apps }
        .first(where: { _ in true })
    switch firstFlattened {
    case .some(.failure(.deviceNotManaged)):
        break
    default:
        preconditionFailure("flattened element must stay fail-closed deviceNotManaged")
    }
    do {
        let throwingFlattened = apps.flatMap { (_: ManagedAppLibrary.ManagedApps.Element) throws -> ManagedAppLibrary.ManagedApps in apps }
        let throwingCount = try await throwingFlattened.reduce(0) { count, _ in count + 1 }
        precondition(throwingCount == 1, "throwing flatMap must yield one element")
    } catch {
        preconditionFailure("throwing flatMap over a fail-closed sequence must not throw: \(error)")
    }
}

func testAsyncSequenceFilterTransforms() async {
    let apps = ManagedAppLibrary.currentDistributor.availableApps
    let kept = await apps.filter { _ in true }.reduce(0) { count, _ in count + 1 }
    precondition(kept == 1, "filter keeping everything must preserve the element")
    let removed = await apps.filter { _ in false }.reduce(0) { count, _ in count + 1 }
    precondition(removed == 0, "filter rejecting everything must drop the element")
    let prefixed = await apps.prefix(2).reduce(0) { count, _ in count + 1 }
    precondition(prefixed == 1, "prefix(2) over one element must keep it")
    let prefixZero = await apps.prefix(0).reduce(0) { count, _ in count + 1 }
    precondition(prefixZero == 0, "prefix(0) must keep nothing")
    let droppedFirst = await apps.dropFirst(1).reduce(0) { count, _ in count + 1 }
    precondition(droppedFirst == 0, "dropFirst(1) over one element must drop it")
    let dropWhileFalse = await apps.drop(while: { _ in false }).reduce(0) { count, _ in count + 1 }
    precondition(dropWhileFalse == 1, "drop(while:) with a false predicate must keep the element")
    let dropWhileTrue = await apps.drop(while: { _ in true }).reduce(0) { count, _ in count + 1 }
    precondition(dropWhileTrue == 0, "drop(while:) with a true predicate must drop the element")
    let prefixWhileTrue = await apps.prefix(while: { _ in true }).reduce(0) { count, _ in count + 1 }
    precondition(prefixWhileTrue == 1, "prefix(while:) with a true predicate must keep the element")
    let prefixWhileFalse = await apps.prefix(while: { _ in false }).reduce(0) { count, _ in count + 1 }
    precondition(prefixWhileFalse == 0, "prefix(while:) with a false predicate must keep nothing")
}

func testAsyncSequenceSearch() async {
    let apps = ManagedAppLibrary.currentDistributor.availableApps
    let found = await apps.first(where: { _ in true })
    switch found {
    case .some(.failure(.deviceNotManaged)):
        break
    default:
        preconditionFailure("first(where:) must find the fail-closed snapshot")
    }
    let missing = await apps.first(where: { _ in false })
    precondition(missing == nil, "first(where:) with a false predicate must find nothing")
    let containsTrue = await apps.contains(where: { _ in true })
    precondition(containsTrue, "contains(where:) must see the fail-closed snapshot")
    let containsFalse = await apps.contains(where: { _ in false })
    precondition(!containsFalse, "contains(where:) with a false predicate must be false")
    let containsSnapshot = await apps.contains(.failure(.deviceNotManaged))
    precondition(containsSnapshot, "contains must see the fail-closed snapshot")
    let allTrue = await apps.allSatisfy { _ in true }
    precondition(allTrue, "allSatisfy with a true predicate must be true")
    let allFalse = await apps.allSatisfy { _ in false }
    precondition(!allFalse, "allSatisfy with a false predicate must be false")
}

func testAsyncSequenceAggregation() async {
    let apps = ManagedAppLibrary.currentDistributor.availableApps
    let total = await apps.reduce(0) { count, _ in count + 1 }
    precondition(total == 1, "reduce must visit the single fail-closed element")
    let totalInto = await apps.reduce(into: 0) { count, _ in count += 1 }
    precondition(totalInto == 1, "reduce(into:) must visit the single fail-closed element")
    let minimum = await apps.min(by: { _, _ in true })
    switch minimum {
    case .some(.failure(.deviceNotManaged)):
        break
    default:
        preconditionFailure("min(by:) over one snapshot must return it")
    }
    let maximum = await apps.max(by: { _, _ in true })
    switch maximum {
    case .some(.failure(.deviceNotManaged)):
        break
    default:
        preconditionFailure("max(by:) over one snapshot must return it")
    }
}
