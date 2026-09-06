import Foundation
import ContactProvider

final class RecordingContentObserver: ContactItemContentObserver {
    var enumerated: [[ContactItem]] = []
    var finishedPages: [ContactItemPage] = []
    var finishedMarkers: [Data] = []
    var errors: [String] = []
    var suggestedPageSize: Int = 50

    func didEnumerate(_ items: [ContactItem]) {
        enumerated.append(items)
    }

    func didFinishEnumeratingPage(upTo nextPage: ContactItemPage) {
        finishedPages.append(nextPage)
    }

    func didFinishEnumeratingContent(upTo generationMarker: Data) {
        finishedMarkers.append(generationMarker)
    }

    func didFinishEnumeratingContentWithError(_ error: any Error) {
        errors.append(String(describing: error))
    }
}

final class RecordingChangeObserver: ContactItemChangeObserver {
    var updates: [[ContactItem]] = []
    var deletions: [[ContactItem.Identifier]] = []
    var finishedAnchors: [(ContactItemSyncAnchor, Bool)] = []
    var errors: [String] = []
    var suggestedBatchSize: Int = 25

    func didUpdate(_ items: [ContactItem]) {
        updates.append(items)
    }

    func didDelete(_ identifiers: [ContactItem.Identifier]) {
        deletions.append(identifiers)
    }

    func didFinishEnumeratingChanges(upTo syncAnchor: ContactItemSyncAnchor, moreComing: Bool) {
        finishedAnchors.append((syncAnchor, moreComing))
    }

    func didFinishEnumeratingChangesWithError(_ error: any Error) {
        errors.append(String(describing: error))
    }
}

final class ProbeEnumerator: ContactItemEnumerator {
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

final class ProbeEnumerating: ContactItemEnumerating {
    let boxed = ProbeEnumerator()
    var lastCollection: ContactItem.Identifier?

    func enumerator(for collection: ContactItem.Identifier) -> any ContactItemEnumerator {
        lastCollection = collection
        return boxed
    }
}

func testContactItemEnumeratorConformance() {
    let enumerator: any ContactItemEnumerator = ProbeEnumerator()
    precondition(enumerator is ProbeEnumerator)
}

func testContactItemEnumeratingConformance() {
    let enumerating: any ContactItemEnumerating = ProbeEnumerating()
    precondition(enumerating is ProbeEnumerating)
}

func testEnumeratorForCollection() {
    let host = ProbeEnumerating()
    let enumerator = host.enumerator(for: .rootContainer)
    precondition(host.lastCollection == ContactItem.Identifier.rootContainer)
    precondition(enumerator is ProbeEnumerator)
    let other = ContactItem.Identifier("folder")
    _ = host.enumerator(for: other)
    precondition(host.lastCollection == other)
}

func testContentObserverConformance() {
    let observer: any ContactItemContentObserver = RecordingContentObserver()
    precondition(observer.suggestedPageSize == 50)
}

func testContentObserverDidEnumerate() {
    let observer = RecordingContentObserver()
    let contact = CNMutableContact()
    let item = ContactItem.contact(contact, ContactItem.Identifier("one"))
    observer.didEnumerate([item])
    observer.didEnumerate([])
    precondition(observer.enumerated.count == 2)
    precondition(observer.enumerated[0].count == 1)
    precondition(observer.enumerated[1].isEmpty)
}

func testContentObserverDidFinishPage() {
    let observer = RecordingContentObserver()
    let next = ContactItemPage(generationMarker: Data([0x01]), offset: 10)
    observer.didFinishEnumeratingPage(upTo: next)
    precondition(observer.finishedPages.count == 1)
    precondition(observer.finishedPages[0] == next)
}

func testContentObserverDidFinishContent() {
    let observer = RecordingContentObserver()
    let marker = Data("generation".utf8)
    observer.didFinishEnumeratingContent(upTo: marker)
    precondition(observer.finishedMarkers == [marker])
}

func testContentObserverDidFinishContentWithError() {
    let observer = RecordingContentObserver()
    observer.didFinishEnumeratingContentWithError(ContactProviderError.pageExpired)
    precondition(observer.errors.count == 1)
    precondition(observer.errors[0].contains("pageExpired"))
}

func testContentObserverSuggestedPageSize() {
    let observer = RecordingContentObserver()
    precondition(observer.suggestedPageSize == 50)
    observer.suggestedPageSize = 8
    let asProtocol: any ContactItemContentObserver = observer
    precondition(asProtocol.suggestedPageSize == 8)
}

func testChangeObserverConformance() {
    let observer: any ContactItemChangeObserver = RecordingChangeObserver()
    precondition(observer.suggestedBatchSize == 25)
}

func testChangeObserverDidUpdate() {
    let observer = RecordingChangeObserver()
    let item = ContactItem.contact(CNMutableContact(), ContactItem.Identifier("updated"))
    observer.didUpdate([item])
    precondition(observer.updates.count == 1)
    precondition(observer.updates[0].count == 1)
}

func testChangeObserverDidDelete() {
    let observer = RecordingChangeObserver()
    observer.didDelete([.rootContainer, ContactItem.Identifier("gone")])
    precondition(observer.deletions.count == 1)
    precondition(observer.deletions[0].count == 2)
    precondition(observer.deletions[0][0] == .rootContainer)
}

func testChangeObserverDidFinishChanges() {
    let observer = RecordingChangeObserver()
    let anchor = ContactItemSyncAnchor(generationMarker: Data([0x02]), offset: 4)
    observer.didFinishEnumeratingChanges(upTo: anchor, moreComing: true)
    observer.didFinishEnumeratingChanges(upTo: anchor, moreComing: false)
    precondition(observer.finishedAnchors.count == 2)
    precondition(observer.finishedAnchors[0].0 == anchor)
    precondition(observer.finishedAnchors[0].1 == true)
    precondition(observer.finishedAnchors[1].1 == false)
}

func testChangeObserverDidFinishChangesWithError() {
    let observer = RecordingChangeObserver()
    observer.didFinishEnumeratingChangesWithError(ContactProviderError.changeAnchorExpired)
    precondition(observer.errors.count == 1)
    precondition(observer.errors[0].contains("changeAnchorExpired"))
}

func testChangeObserverSuggestedBatchSize() {
    let observer = RecordingChangeObserver()
    precondition(observer.suggestedBatchSize == 25)
    observer.suggestedBatchSize = 3
    let asProtocol: any ContactItemChangeObserver = observer
    precondition(asProtocol.suggestedBatchSize == 3)
}
