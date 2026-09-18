import Foundation
import ContactProvider

final class AsyncNoopEnumerator: ContactItemEnumerator {
    func enumerateContent(
        in page: ContactItemPage,
        for observer: any ContactItemContentObserver
    ) async {
        _ = page
        _ = observer
    }

    func enumerateChanges(
        startingAt syncAnchor: ContactItemSyncAnchor,
        for observer: any ContactItemChangeObserver
    ) async {
        _ = syncAnchor
        _ = observer
    }

    func invalidate() async {}
}

final class AsyncNoopContentObserver: ContactItemContentObserver {
    var suggestedPageSize: Int { 10 }
    func didEnumerate(_ items: [ContactItem]) {}
    func didFinishEnumeratingPage(upTo nextPage: ContactItemPage) {}
    func didFinishEnumeratingContent(upTo generationMarker: Data) {}
    func didFinishEnumeratingContentWithError(_ error: any Error) {}
}

final class AsyncNoopChangeObserver: ContactItemChangeObserver {
    var suggestedBatchSize: Int { 10 }
    func didUpdate(_ items: [ContactItem]) {}
    func didDelete(_ identifiers: [ContactItem.Identifier]) {}
    func didFinishEnumeratingChanges(upTo syncAnchor: ContactItemSyncAnchor, moreComing: Bool) {}
    func didFinishEnumeratingChangesWithError(_ error: any Error) {}
}

final class AsyncNoopExtension: ContactProviderExtension {
    let boxed = AsyncNoopEnumerator()
    func configure(for domain: any ContactProviderDomain) {}
    func enumerator(for collection: ContactItem.Identifier) -> any ContactItemEnumerator {
        boxed
    }
    func invalidate() async throws {}
}

func testAsyncEnumerateContentCompletes() async {
    let enumerator = AsyncNoopEnumerator()
    await enumerator.enumerateContent(in: .initialPage, for: AsyncNoopContentObserver())
}

func testAsyncEnumerateChangesCompletes() async {
    let enumerator = AsyncNoopEnumerator()
    let anchor = ContactItemSyncAnchor(generationMarker: Data(), offset: 0)
    await enumerator.enumerateChanges(startingAt: anchor, for: AsyncNoopChangeObserver())
}

func testAsyncEnumeratorInvalidateCompletes() async {
    let enumerator = AsyncNoopEnumerator()
    await enumerator.invalidate()
}

func testAsyncManagerEnableThrows() async {
    let manager = try! ContactProviderManager()
    do {
        try await manager.enable()
        preconditionFailure("expected featureNotAvailable")
    } catch let error as ContactProviderError {
        precondition(error == .featureNotAvailable)
    } catch {
        preconditionFailure("expected ContactProviderError")
    }
}

func testAsyncManagerDisableThrows() async {
    let manager = try! ContactProviderManager()
    do {
        try await manager.disable()
        preconditionFailure("expected featureNotAvailable")
    } catch let error as ContactProviderError {
        precondition(error == .featureNotAvailable)
    } catch {
        preconditionFailure("expected ContactProviderError")
    }
}

func testAsyncManagerSignalEnumeratorThrows() async {
    let manager = try! ContactProviderManager()
    do {
        try await manager.signalEnumerator(for: .rootContainer)
        preconditionFailure("expected featureNotAvailable")
    } catch let error as ContactProviderError {
        precondition(error == .featureNotAvailable)
    } catch {
        preconditionFailure("expected ContactProviderError")
    }
}

func testAsyncManagerInvalidateThrows() async {
    let manager = try! ContactProviderManager()
    do {
        try await manager.invalidate()
        preconditionFailure("expected featureNotAvailable")
    } catch let error as ContactProviderError {
        precondition(error == .featureNotAvailable)
    } catch {
        preconditionFailure("expected ContactProviderError")
    }
}

func testAsyncManagerResetThrows() async {
    let manager = try! ContactProviderManager()
    do {
        try await manager.reset()
        preconditionFailure("expected featureNotAvailable")
    } catch let error as ContactProviderError {
        precondition(error == .featureNotAvailable)
    } catch {
        preconditionFailure("expected ContactProviderError")
    }
}

func testAsyncExtensionInvalidateCompletes() async {
    let ext = AsyncNoopExtension()
    try! await ext.invalidate()
}
