import Foundation
import ShazamKit

private func asyncAwaitEmptySlices() -> SHSignature.Slices {
    try! SHSignature(dataRepresentation: Data([0xA0])).slices(from: 0, duration: 0)
}

private func asyncAwaitEmptyResults() -> SHSession.Results {
    SHSession().results
}

private func asyncAwaitQuerySignature(_ bytes: [UInt8] = [0xA1, 0xB2]) -> SHSignature {
    try! SHSignature(dataRepresentation: Data(bytes))
}

func testSHMediaItemFetchFailClosed() async {
    do {
        _ = try await SHMediaItem.fetch(shazamID: "123456789")
        preconditionFailure("fetch must fail closed without the Apple catalog")
    } catch {
        precondition(SHError.Code.mediaItemFetchFailed ~= error, "expected mediaItemFetchFailed, got \(error)")
    }
}

func testSHMediaLibraryAddFailClosed() async {
    do {
        try await SHMediaLibrary.default.add([SHMediaItem(properties: [.title: "Nope"])])
        preconditionFailure("add must fail closed without the media library daemon")
    } catch {
        precondition(SHError.Code.mediaLibrarySyncFailed ~= error, "expected mediaLibrarySyncFailed, got \(error)")
    }
}

func testSHLibraryAddItemsFailClosed() async {
    do {
        try await SHLibrary.default.addItems([SHMediaItem(properties: [.title: "Nope"])])
        preconditionFailure("addItems must fail closed without the media library daemon")
    } catch {
        precondition(SHError.Code.mediaLibrarySyncFailed ~= error, "expected mediaLibrarySyncFailed, got \(error)")
    }
}

func testSHLibraryRemoveItemsFailClosed() async {
    do {
        try await SHLibrary.default.removeItems([SHMediaItem(properties: [.title: "Nope"])])
        preconditionFailure("removeItems must fail closed without the media library daemon")
    } catch {
        precondition(SHError.Code.mediaLibrarySyncFailed ~= error, "expected mediaLibrarySyncFailed, got \(error)")
    }
}

func testSHManagedSessionPrepareAsync() async {
    let session = SHManagedSession()
    precondition(session.state == .idle)
    await session.prepare()
    precondition(session.state == .prerecording)
}

func testSHManagedSessionResultAsync() async {
    let session = SHManagedSession()
    let outcome = await session.result()
    if case .error(let error, _) = outcome {
        precondition(SHError.Code.matchAttemptFailed ~= error, "expected matchAttemptFailed, got \(error)")
    } else {
        preconditionFailure("default managed session must fail closed with matchAttemptFailed")
    }
    precondition(session.state == .idle)
}

func testSHSessionResultFromAppleCatalogAsync() async {
    let outcome = await SHSession().result(from: asyncAwaitQuerySignature())
    if case .error(let error, let query) = outcome {
        precondition(SHError.Code.matchAttemptFailed ~= error, "expected matchAttemptFailed, got \(error)")
        precondition(query.dataRepresentation == Data([0xA1, 0xB2]))
    } else {
        preconditionFailure("Apple catalog result must fail closed")
    }
}

func testSHSessionResultFromCustomCatalogHitAsync() async {
    let signature = asyncAwaitQuerySignature([0x0D])
    let item = SHMediaItem(properties: [.title: "Async Hit"])
    let catalog = SHCustomCatalog()
    try! catalog.addReferenceSignature(signature, representing: [item])
    let outcome = await SHSession(catalog: catalog).result(from: signature)
    if case .match(let match) = outcome {
        precondition(match.mediaItems.first?.title == "Async Hit")
    } else {
        preconditionFailure("custom catalog hit must produce a match")
    }
}

func testSHSessionResultFromCustomCatalogMissAsync() async {
    let catalog = SHCustomCatalog()
    try! catalog.addReferenceSignature(asyncAwaitQuerySignature([0x01]), representing: [
        SHMediaItem(properties: [.title: "Other"]),
    ])
    let query = asyncAwaitQuerySignature([0x02])
    let outcome = await SHSession(catalog: catalog).result(from: query)
    if case .noMatch(let returned) = outcome {
        precondition(returned.dataRepresentation == query.dataRepresentation)
    } else {
        preconditionFailure("custom catalog miss must produce noMatch")
    }
}

func testSessionResultsIteratorNextAsync() async {
    var iterator = asyncAwaitEmptyResults().makeAsyncIterator()
    let value = await iterator.next()
    precondition(value == nil)
}

func testSessionResultsIteratorNextIsolationAsync() async {
    var iterator = asyncAwaitEmptyResults().makeAsyncIterator()
    let value = await iterator.next(isolation: nil)
    precondition(value == nil)
}

func testSignatureSlicesIteratorNextAsync() async {
    var iterator = asyncAwaitEmptySlices().makeAsyncIterator()
    do {
        let value = try await iterator.next()
        precondition(value == nil)
    } catch {
        preconditionFailure("empty slices iterator must return nil, got \(error)")
    }
}

func testSignatureSlicesIteratorNextIsolationAsync() async {
    var iterator = asyncAwaitEmptySlices().makeAsyncIterator()
    do {
        let value = try await iterator.next(isolation: nil)
        precondition(value == nil)
    } catch {
        preconditionFailure("empty slices iterator must return nil, got \(error)")
    }
}

func testSessionResultsAllSatisfyAsync() async {
    let satisfied = await asyncAwaitEmptyResults().allSatisfy { _ in true }
    precondition(satisfied)
}

func testSignatureSlicesAllSatisfyAsync() async {
    let satisfied = try! await asyncAwaitEmptySlices().allSatisfy { _ in true }
    precondition(satisfied)
}

func testSessionResultsMaxAsync() async {
    let winner = await asyncAwaitEmptyResults().max { _, _ in false }
    precondition(winner == nil)
}

func testSignatureSlicesMaxAsync() async {
    let winner = try! await asyncAwaitEmptySlices().max { _, _ in false }
    precondition(winner == nil)
}

func testSessionResultsMinAsync() async {
    let winner = await asyncAwaitEmptyResults().min { _, _ in false }
    precondition(winner == nil)
}

func testSignatureSlicesMinAsync() async {
    let winner = try! await asyncAwaitEmptySlices().min { _, _ in false }
    precondition(winner == nil)
}

func testSessionResultsFirstWhereAsync() async {
    let found = await asyncAwaitEmptyResults().first { _ in true }
    precondition(found == nil)
}

func testSignatureSlicesFirstWhereAsync() async {
    let found = try! await asyncAwaitEmptySlices().first { _ in true }
    precondition(found == nil)
}

func testSessionResultsReduceIntoAsync() async {
    let total = await asyncAwaitEmptyResults().reduce(into: 0) { count, _ in count += 1 }
    precondition(total == 0)
}

func testSignatureSlicesReduceIntoAsync() async {
    let total = try! await asyncAwaitEmptySlices().reduce(into: 0) { count, _ in count += 1 }
    precondition(total == 0)
}

func testSessionResultsReduceAsync() async {
    let total = await asyncAwaitEmptyResults().reduce(0) { count, _ in count + 1 }
    precondition(total == 0)
}

func testSignatureSlicesReduceAsync() async {
    let total = try! await asyncAwaitEmptySlices().reduce(0) { count, _ in count + 1 }
    precondition(total == 0)
}

func testSessionResultsContainsWhereAsync() async {
    let found = await asyncAwaitEmptyResults().contains { _ in true }
    precondition(!found)
}

func testSignatureSlicesContainsWhereAsync() async {
    let found = try! await asyncAwaitEmptySlices().contains { _ in true }
    precondition(!found)
}

func testSignatureSlicesContainsAsync() async {
    let found = try! await asyncAwaitEmptySlices().contains(asyncAwaitQuerySignature([0x0E]))
    precondition(!found)
}
