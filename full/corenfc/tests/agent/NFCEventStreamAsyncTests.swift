import CoreNFC

// Async terminal probes for the suspending Swift standard library
// AsyncSequence operators available on CardSession.EventStream. The sealed
// runner awaits top-level `func test*() async`, so these call the real
// operators directly with `await`. Every probe completes in-process on this
// Linux host: EventStream.Iterator.next() throws
// CardSession.Error.systemNotAvailable on its first call (no NFC controller
// exists), which each terminal operator propagates without ever suspending
// on hardware. Closures are spelled `throws` so the `try` is required and no
// warnings-as-errors diagnostic fires.

func testEventStreamAsyncAllSatisfy() async {
    let stream = CardSession.EventStream()
    do {
        _ = try await stream.allSatisfy { (_: CardSession.Event) throws -> Bool in true }
        preconditionFailure("allSatisfy must propagate the fail-closed throw")
    } catch let error as CardSession.Error {
        precondition(error == .systemNotAvailable)
    } catch {
        preconditionFailure("unexpected error from allSatisfy: \(error)")
    }
}

func testEventStreamAsyncContains() async {
    let stream = CardSession.EventStream()
    do {
        _ = try await stream.contains { (_: CardSession.Event) throws -> Bool in true }
        preconditionFailure("contains(where:) must propagate the fail-closed throw")
    } catch let error as CardSession.Error {
        precondition(error == .systemNotAvailable)
    } catch {
        preconditionFailure("unexpected error from contains(where:): \(error)")
    }
}

func testEventStreamAsyncFirst() async {
    let stream = CardSession.EventStream()
    do {
        _ = try await stream.first { (_: CardSession.Event) throws -> Bool in true }
        preconditionFailure("first(where:) must propagate the fail-closed throw")
    } catch let error as CardSession.Error {
        precondition(error == .systemNotAvailable)
    } catch {
        preconditionFailure("unexpected error from first(where:): \(error)")
    }
}

func testEventStreamAsyncMin() async {
    let stream = CardSession.EventStream()
    do {
        _ = try await stream.min { (_: CardSession.Event, _: CardSession.Event) throws -> Bool in true }
        preconditionFailure("min(by:) must propagate the fail-closed throw")
    } catch let error as CardSession.Error {
        precondition(error == .systemNotAvailable)
    } catch {
        preconditionFailure("unexpected error from min(by:): \(error)")
    }
}

func testEventStreamAsyncMax() async {
    let stream = CardSession.EventStream()
    do {
        _ = try await stream.max { (_: CardSession.Event, _: CardSession.Event) throws -> Bool in false }
        preconditionFailure("max(by:) must propagate the fail-closed throw")
    } catch let error as CardSession.Error {
        precondition(error == .systemNotAvailable)
    } catch {
        preconditionFailure("unexpected error from max(by:): \(error)")
    }
}

func testEventStreamAsyncReduce() async {
    let stream = CardSession.EventStream()
    do {
        _ = try await stream.reduce(0) { (count: Int, _: CardSession.Event) throws -> Int in count + 1 }
        preconditionFailure("reduce must propagate the fail-closed throw")
    } catch let error as CardSession.Error {
        precondition(error == .systemNotAvailable)
    } catch {
        preconditionFailure("unexpected error from reduce: \(error)")
    }
}

func testEventStreamAsyncReduceInto() async {
    let stream = CardSession.EventStream()
    do {
        _ = try await stream.reduce(into: 0) { (count: inout Int, _: CardSession.Event) throws -> Void in count += 1 }
        preconditionFailure("reduce(into:) must propagate the fail-closed throw")
    } catch let error as CardSession.Error {
        precondition(error == .systemNotAvailable)
    } catch {
        preconditionFailure("unexpected error from reduce(into:): \(error)")
    }
}

func testEventStreamAsyncIteratorNextIsolation() async {
    var iterator = CardSession.EventStream().makeAsyncIterator()
    do {
        _ = try await iterator.next(isolation: nil)
        preconditionFailure("next(isolation:) must throw fail-closed")
    } catch let error as CardSession.Error {
        precondition(error == .systemNotAvailable)
    } catch {
        preconditionFailure("unexpected error from next(isolation:): \(error)")
    }
}
