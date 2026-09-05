import Foundation
import ShazamKit

private func emptyResults() -> SHSession.Results {
    SHSession().results
}

private func emptySlices() -> SHSignature.Slices {
    try! SHSignature(dataRepresentation: Data([0x50])).slices(from: 0, duration: 0)
}

private func neverFailingResults(_ value: String) -> AsyncStream<String> {
    AsyncStream { continuation in
        continuation.yield(value)
        continuation.finish()
    }
}

func testSessionResultsMap() {
    _ = emptyResults().map { (_: SHSession.Result) async -> Int in 0 }
}

func testSessionResultsThrowingMap() {
    _ = emptyResults().map { (_: SHSession.Result) async throws -> Int in 0 }
}

func testSessionResultsCompactMap() {
    _ = emptyResults().compactMap { (_: SHSession.Result) async -> Int? in nil }
}

func testSessionResultsThrowingCompactMap() {
    _ = emptyResults().compactMap { (_: SHSession.Result) async throws -> Int? in nil }
}

func testSessionResultsFilter() {
    _ = emptyResults().filter { _ in false }
}

func testSessionResultsDropWhile() {
    _ = emptyResults().drop(while: { _ in false })
}

func testSessionResultsDropFirst() {
    _ = emptyResults().dropFirst()
    _ = emptyResults().dropFirst(2)
}

func testSessionResultsPrefix() {
    _ = emptyResults().prefix(1)
}

func testSessionResultsPrefixWhile() {
    _ = emptyResults().prefix(while: { _ in true })
}

func testSessionResultsThrowingFlatMap() {
    _ = emptyResults().flatMap { (_: SHSession.Result) async throws -> AsyncStream<Int> in
        AsyncStream { $0.finish() }
    }
}

func testSessionResultsFlatMapMatchingFailure() {
    _ = emptyResults().flatMap { (_: SHSession.Result) async -> AsyncStream<Int> in
        AsyncStream { $0.finish() }
    }
}

func testSessionResultsFlatMapNeverSegment() {
    _ = emptyResults().flatMap { _ in neverFailingResults("x") }
}

func testSessionResultsFlatMapNeverNever() {
    _ = emptyResults().flatMap { _ in neverFailingResults("y") }
}

func testSignatureSlicesMap() {
    _ = emptySlices().map { (_: SHSignature) async -> Int in 0 }
}

func testSignatureSlicesThrowingMap() {
    _ = emptySlices().map { (_: SHSignature) async throws -> Int in 0 }
}

func testSignatureSlicesCompactMap() {
    _ = emptySlices().compactMap { (_: SHSignature) async -> Int? in nil }
}

func testSignatureSlicesThrowingCompactMap() {
    _ = emptySlices().compactMap { (_: SHSignature) async throws -> Int? in nil }
}

func testSignatureSlicesFilter() {
    _ = emptySlices().filter { _ in true }
}

func testSignatureSlicesDropWhile() {
    _ = emptySlices().drop(while: { _ in false })
}

func testSignatureSlicesDropFirst() {
    _ = emptySlices().dropFirst(1)
}

func testSignatureSlicesPrefix() {
    _ = emptySlices().prefix(3)
}

func testSignatureSlicesPrefixWhile() {
    _ = try! emptySlices().prefix(while: { _ in false })
}

func testSignatureSlicesThrowingFlatMap() {
    _ = emptySlices().flatMap { (_: SHSignature) async throws -> AsyncStream<Int> in
        AsyncStream { $0.finish() }
    }
}

func testSignatureSlicesFlatMapMatchingFailure() {
    _ = emptySlices().flatMap { (_: SHSignature) async throws -> AsyncThrowingStream<Int, Error> in
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
}

func testSignatureSlicesFlatMapNeverSegment() {
    _ = emptySlices().flatMap { (_: SHSignature) async -> AsyncStream<Int> in
        AsyncStream { $0.finish() }
    }
}
