import Foundation
import Translation

private func failingBatch() -> TranslationSession.BatchResponse {
    let session = TranslationSession(
        installedSource: translationEnglish(),
        target: translationFrench()
    )
    return session.translate(
        batch: [TranslationSession.Request(sourceText: "Hello", clientIdentifier: "seq")]
    )
}

func testBatchResponseType() {
    let batch = failingBatch()
    precondition(type(of: batch) == TranslationSession.BatchResponse.self)
}

func testBatchResponseElement() {
    _ = TranslationSession.BatchResponse.Element.self
    precondition(TranslationSession.BatchResponse.Element.self == TranslationSession.Response.self)
}

func testBatchResponseMakeAsyncIterator() {
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = failingBatch().makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponseAsyncIteratorType() {
    let iterator = failingBatch().makeAsyncIterator()
    precondition(type(of: iterator) == TranslationSession.BatchResponse.AsyncIterator.self)
}

func testBatchResponseAsyncIteratorElement() {
    _ = TranslationSession.BatchResponse.AsyncIterator.Element.self
    precondition(
        TranslationSession.BatchResponse.AsyncIterator.Element.self
            == TranslationSession.Response.self
    )
}

func testBatchResponseNext() {
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = failingBatch().makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
    switch translationAwait({ () async throws -> TranslationSession.Response? in
        var iterator = failingBatch().makeAsyncIterator()
        do {
            _ = try await iterator.next()
            preconditionFailure("first next must throw")
        } catch {
            precondition(TranslationError.notInstalled ~= error)
        }
        return try await iterator.next()
    }) {
    case .success(let value):
        precondition(value == nil)
    case .failure(let error):
        preconditionFailure("second next must return nil, got \(error)")
    }
}

func testBatchResponseProtocolNext() {
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = failingBatch().makeAsyncIterator()
            return try await iterator.next() as TranslationSession.Response?
        },
        .notInstalled
    )
}

func testBatchResponseNextIsolation() {
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = failingBatch().makeAsyncIterator()
            return try await iterator.next(isolation: nil)
        },
        .notInstalled
    )
}

func testBatchResponseAllSatisfy() {
    translationExpectError(
        translationAwait { try await failingBatch().allSatisfy { !$0.sourceText.isEmpty } },
        .notInstalled
    )
}

func testBatchResponseCompactMap() {
    let mapped = failingBatch().compactMap { $0.clientIdentifier }
    translationExpectError(
        translationAwait { () async throws -> String? in
            var iterator = mapped.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponseThrowingCompactMap() {
    let mapped = failingBatch().compactMap { (response) async throws -> String? in
        response.clientIdentifier
    }
    translationExpectError(
        translationAwait { () async throws -> String? in
            var iterator = mapped.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponseMap() {
    let mapped = failingBatch().map { $0.sourceText }
    translationExpectError(
        translationAwait { () async throws -> String? in
            var iterator = mapped.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponseThrowingMap() {
    let mapped = failingBatch().map { (response) async throws -> String in
        response.sourceText
    }
    translationExpectError(
        translationAwait { () async throws -> String? in
            var iterator = mapped.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponseMaxBy() {
    translationExpectError(
        translationAwait {
            try await failingBatch().max(by: { $0.sourceText < $1.sourceText })
        },
        .notInstalled
    )
}

func testBatchResponseMinBy() {
    translationExpectError(
        translationAwait {
            try await failingBatch().min(by: { $0.sourceText < $1.sourceText })
        },
        .notInstalled
    )
}

func testBatchResponseDropWhile() {
    let dropped = failingBatch().drop(while: { $0.sourceText.isEmpty })
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = dropped.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponseFirstWhere() {
    translationExpectError(
        translationAwait {
            try await failingBatch().first(where: { $0.clientIdentifier != nil })
        },
        .notInstalled
    )
}

func testBatchResponseFilter() {
    let filtered = failingBatch().filter { !$0.sourceText.isEmpty }
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = filtered.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponsePrefixWhile() {
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            let prefixed = try failingBatch().prefix(while: { !$0.sourceText.isEmpty })
            var iterator = prefixed.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponsePrefix() {
    let prefixed = failingBatch().prefix(1)
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = prefixed.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponseReduceInto() {
    translationExpectError(
        translationAwait {
            try await failingBatch().reduce(into: 0) { partial, _ in
                partial += 1
            }
        },
        .notInstalled
    )
}

func testBatchResponseReduce() {
    translationExpectError(
        translationAwait {
            try await failingBatch().reduce(0) { partial, _ in partial + 1 }
        },
        .notInstalled
    )
}

func testBatchResponseThrowingFlatMap() {
    let flattened = failingBatch().flatMap { response in
        AsyncThrowingStream<String, Error> { continuation in
            continuation.yield(response.sourceText)
            continuation.finish()
        }
    }
    translationExpectError(
        translationAwait { () async throws -> String? in
            var iterator = flattened.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponseFlatMapMatchingFailure() {
    let flattened = failingBatch().flatMap { (response: TranslationSession.Response) async throws -> AsyncStream<String> in
        if response.sourceText.isEmpty {
            throw TranslationError.nothingToTranslate
        }
        return AsyncStream { continuation in
            continuation.yield(response.sourceText)
            continuation.finish()
        }
    }
    translationExpectError(
        translationAwait { () async throws -> String? in
            var iterator = flattened.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}

func testBatchResponseContainsWhere() {
    translationExpectError(
        translationAwait {
            try await failingBatch().contains(where: { $0.sourceText == "Hello" })
        },
        .notInstalled
    )
}

func testBatchResponseDropFirst() {
    let dropped = failingBatch().dropFirst()
    let droppedTwo = failingBatch().dropFirst(2)
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = dropped.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
    translationExpectError(
        translationAwait { () async throws -> TranslationSession.Response? in
            var iterator = droppedTwo.makeAsyncIterator()
            return try await iterator.next()
        },
        .notInstalled
    )
}
