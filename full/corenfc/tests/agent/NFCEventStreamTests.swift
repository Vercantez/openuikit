import CoreNFC

// Synchronous construction probes for the lazy (non-suspending) Swift
// standard library AsyncSequence combinators available on
// CardSession.EventStream. Each test calls exactly one overload, forced by
// the annotated lazy-sequence type; no iteration happens here because
// iteration would require suspension and live NFC hardware, both of which stay
// fail-closed on this Linux host.

func testEventStreamMap() {
    let stream = CardSession.EventStream()
    let mapped: AsyncMapSequence<CardSession.EventStream, Int> = stream.map { _ in 0 }
    _ = mapped
}

func testEventStreamThrowingMap() {
    let stream = CardSession.EventStream()
    let mapped: AsyncThrowingMapSequence<CardSession.EventStream, Int> = stream.map { (_: CardSession.Event) throws -> Int in 0 }
    _ = mapped
}

func testEventStreamCompactMap() {
    let stream = CardSession.EventStream()
    let mapped: AsyncCompactMapSequence<CardSession.EventStream, Int> = stream.compactMap { _ in 0 }
    _ = mapped
}

func testEventStreamThrowingCompactMap() {
    let stream = CardSession.EventStream()
    let mapped: AsyncThrowingCompactMapSequence<CardSession.EventStream, Int> = stream.compactMap { (_: CardSession.Event) throws -> Int? in 0 }
    _ = mapped
}

func testEventStreamFilter() {
    let stream = CardSession.EventStream()
    let filtered: AsyncFilterSequence<CardSession.EventStream> = stream.filter { _ in true }
    _ = filtered
}

func testEventStreamPrefixCount() {
    let stream = CardSession.EventStream()
    let prefixed: AsyncPrefixSequence<CardSession.EventStream> = stream.prefix(2)
    _ = prefixed
}

func testEventStreamPrefixWhile() {
    let stream = CardSession.EventStream()
    let predicate: @Sendable (CardSession.Event) async -> Bool = { _ in true }
    // Non-throwing prefix(while:) is rethrows in this SDK, so the call is
    // marked try!; with a non-throwing predicate it never throws at runtime.
    let prefixed: AsyncPrefixWhileSequence<CardSession.EventStream> = try! stream.prefix(while: predicate)
    _ = prefixed
}

func testEventStreamDropWhile() {
    let stream = CardSession.EventStream()
    let predicate: @Sendable (CardSession.Event) async -> Bool = { _ in false }
    let dropped: AsyncDropWhileSequence<CardSession.EventStream> = stream.drop(while: predicate)
    _ = dropped
}

func testEventStreamDropFirst() {
    let stream = CardSession.EventStream()
    let dropped: AsyncDropFirstSequence<CardSession.EventStream> = stream.dropFirst(1)
    _ = dropped
}

func testEventStreamFlatMap() {
    let stream = CardSession.EventStream()
    let flat: AsyncFlatMapSequence<CardSession.EventStream, CardSession.EventStream> = stream.flatMap { _ in CardSession.EventStream() }
    _ = flat
}

func testEventStreamThrowingFlatMap() {
    let stream = CardSession.EventStream()
    let flat: AsyncThrowingFlatMapSequence<CardSession.EventStream, CardSession.EventStream> = stream.flatMap { (_: CardSession.Event) throws -> CardSession.EventStream in CardSession.EventStream() }
    _ = flat
}

func testEventStreamFlatMapNeverFailureSegment() {
    let stream = CardSession.EventStream()
    // SegmentOfResult.Failure == Never selects the Never-constrained flatMap
    // overload (SIL: $sScisE7flatMap...s5NeverO7FailureRtd__lF). Construction
    // stays synchronous; the @Sendable async transform never runs here because
    // iteration would require suspension and live NFC hardware.
    let flat: AsyncFlatMapSequence<CardSession.EventStream, AsyncStream<CardSession.Event>> = stream.flatMap { _ in AsyncStream<CardSession.Event> { _ in } }
    _ = flat
}
